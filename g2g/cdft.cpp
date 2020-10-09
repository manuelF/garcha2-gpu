/* headers */
#include <iostream>
#include <fstream>
#include <stdexcept>
#include <fenv.h>
#include <signal.h>
#include <cassert>
#include "common.h"
#include "init.h"
#include "matrix.h"
#include "partition.h"

using namespace G2G;
extern Partition partition;

/* global variables */
namespace G2G {
  CDFTVars cdft_vars;

void Partition::cdft_copy_to_local(CDFTVars& cdft_cpy) {
    cdft_cpy.do_chrg = cdft_vars.do_chrg;
    cdft_cpy.do_spin = cdft_vars.do_spin;
    cdft_cpy.regions = cdft_vars.regions;
    cdft_cpy.max_nat = cdft_vars.max_nat;
    cdft_cpy.natom   = cdft_vars.natom;
    cdft_cpy.atoms   = cdft_vars.atoms;
    cdft_cpy.Vc      = cdft_vars.Vc;
    cdft_cpy.Vs      = cdft_vars.Vs;
}

void Partition::compute_Wmat_global(HostMatrix<double>& fort_Wmat) {
  int total_threads = G2G::cpu_threads + G2G::gpu_threads;

  std::vector< HostMatrix<double> > Wmat_threads;
  Wmat_threads.resize(total_threads);

#pragma omp parallel for num_threads(cpu_threads + gpu_threads)
  for (uint i = 0; i < work.size(); i++) {

#if GPU_KERNELS
    bool gpu_thread = false;
    if (i >= cpu_threads) {
      gpu_thread = true;
      cudaSetDevice(i - cpu_threads);
    }
#endif
    CDFTVars cdft_vars_local;

#pragma omp critical
    this->cdft_copy_to_local(cdft_vars_local);

    Wmat_threads[i].resize(fort_Wmat.width);
    Wmat_threads[i].zero();

    for (uint j = 0; j < work[i].size(); j++) {
      int ind = work[i][j];

      if (ind >= cubes.size()) {
        spheres[ind - cubes.size()]->calc_W_mat(Wmat_threads[i],
                                                cdft_vars_local);
      } else {
        cubes[ind]->calc_W_mat(Wmat_threads[i], cdft_vars_local);
      }
#if GPU_KERNELS
      if (gpu_thread) cudaDeviceSynchronize();
#endif
    }
  }
  
  // Reduces everything to the actual Wmat
  const int elements = fort_Wmat.width;
  double Wval = 0.0;
  for (uint k = 0; k < Wmat_threads.size(); k++) {
    for (int i = 0; i < elements; i++) {
      fort_Wmat(i) += Wmat_threads[k](i);
    }
  }    
}

}

extern "C" void g2g_cdft_init_(bool& do_c, bool& do_s, uint& regions,
                               uint& max_nat, unsigned int* natoms, 
                               unsigned int* at_list){
  cdft_vars.do_chrg = do_c;
  cdft_vars.do_spin = do_s;
  cdft_vars.regions = regions;

  cdft_vars.natom.resize(cdft_vars.regions);
  for (int i = 0; i < cdft_vars.regions; i++) {
    cdft_vars.natom(i) = natoms[i];
  }

  cdft_vars.atoms.resize(max_nat, cdft_vars.regions);
  // Substracts one from Frotran's indexes. This array is ordered 
  // in (atoms,regions) instead of (regions,atoms) since it is more
  // efficient this way for future calculations.
  for (int i = 0; i < cdft_vars.regions; i++) {
    for (int j = 0; j < cdft_vars.natom(i); j++) {
      cdft_vars.atoms(j,i) = at_list[i +j*regions] -1;
    }
  }
  cdft_vars.max_nat = max_nat;

  if (cdft_vars.do_chrg) cdft_vars.Vc.resize(cdft_vars.regions);
  if (cdft_vars.do_spin) cdft_vars.Vs.resize(cdft_vars.regions);
}

extern "C" void g2g_cdft_set_v_(double* Vc, double* Vs) {
  for (int i = 0; i < cdft_vars.regions; i++) {
    if (cdft_vars.do_chrg) cdft_vars.Vc(i) = Vc[i];
    if (cdft_vars.do_spin) cdft_vars.Vs(i) = Vs[i];
  }
}

extern "C" void g2g_cdft_finalise_() {
  cdft_vars.do_chrg = false;
  cdft_vars.do_spin = false;
  cdft_vars.regions = 0;
  cdft_vars.atoms.deallocate();
  cdft_vars.natom.deallocate();
  cdft_vars.Vc.deallocate();
  cdft_vars.Vs.deallocate();
}

// Calculates Wmatrix for mixed CDFT. fort_W MUST
// be a linear matrix, as Rho and Fock here.
extern "C" void g2g_cdft_w_(double* fort_W){
  HostMatrix<double> fort_Wmat;
  int matSize = fortran_vars.m * (fortran_vars.m + 1) / 2;
  fort_Wmat.resize(matSize);
  fort_Wmat.zero();

  partition.compute_Wmat_global(fort_Wmat);

  for (int i = 0; i < matSize; i++) {
    fort_W[i] += fort_Wmat.data[i];
  }
}