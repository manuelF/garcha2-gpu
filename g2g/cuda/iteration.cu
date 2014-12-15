/* -*- mode: c -*- */
#include <fstream>
#include <iostream>
#include <map>
#include <math_constants.h>
#include <string>
#include <vector>

#include "../common.h"
#include "../init.h"
#include "cuda_extra.h"
#include "../matrix.h"
#include "../timer.h"
#include "../partition.h"
#include "../scalar_vector_types.h"
#include "../global_memory_pool.h"

namespace G2G {
#if FULL_DOUBLE
texture<int2, 2, cudaReadModeElementType> rmm_input_gpu_tex;
texture<int2, 2, cudaReadModeElementType> rmm_input_gpu_tex2;
texture<int2, cudaTextureType2D, cudaReadModeElementType> qmmm_str_tex;
#else
texture<float, 2, cudaReadModeElementType> rmm_input_gpu_tex;
texture<float, 2, cudaReadModeElementType> rmm_input_gpu_tex2;
texture<float, cudaTextureType2D, cudaReadModeElementType> qmmm_str_tex;
#endif
/** KERNELS **/
#include "gpu_variables.h"
#include "kernels/pot.h"
#include "kernels/pot_open.h"
#include "kernels/accumulate_point.h"
#include "kernels/energy.h"
#include "kernels/energy_open.h"
#include "kernels/energy_derivs.h"
#include "kernels/rmm.h"
#include "kernels/weight.h"
#include "kernels/functions.h"
#include "kernels/force.h"
#include "kernels/transpose.h"
#include "kernels/qmmm.h"

using std::cout;
using std::vector;
using std::endl;

// Host function to set the constant
void gpu_set_variables(void) {
  cudaMemcpyToSymbol(gpu_normalization_factor, &fortran_vars.normalization_factor, sizeof(fortran_vars.normalization_factor), 0, cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol(gpu_atoms, &fortran_vars.atoms, sizeof(fortran_vars.atoms), 0, cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol(gpu_Iexch, &fortran_vars.iexch, sizeof(fortran_vars.iexch), 0, cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol(gpu_m, &fortran_vars.m, sizeof(fortran_vars.m), 0, cudaMemcpyHostToDevice);
  cudaAssertNoError("set_gpu_variables");
}

template<class scalar_type>
void gpu_set_gamma_arrays() {

  // Cast STR/FAC to appropriate type (float/double)
  HostMatrix<scalar_type> h_str(880,22), h_fac(17);
  for (uint i = 0; i < 880; i++) {
    for (uint j = 0; j < 22; j++) {
      h_str(i,j) = fortran_vars.str(i,j);
    }
  }
  for (uint i = 0; i < 17; i++) {
    h_fac(i) = fortran_vars.fac(i);
  }

  qmmm_str_tex.normalized = false;
  qmmm_str_tex.filterMode = cudaFilterModePoint;
  cudaMallocArray(&gammaArray,&qmmm_str_tex.channelDesc,880,22);//GAMMA_LENGTH,6);
  cudaMemcpyToArray(gammaArray,0,0,h_str.data,sizeof(scalar_type)*880*22,cudaMemcpyHostToDevice);
  //scalar_type* d_str_ptr;
  //cudaMalloc((void**)&d_str_ptr,880*22*sizeof(scalar_type));
  // STR data host->device
  //cudaMemcpy(d_str_ptr,h_str.data,h_str.bytes(),cudaMemcpyHostToDevice);
  // STR device pointer h->d
  //cudaMemcpyToSymbol(gpu_str,&d_str_ptr,sizeof(gpu_str),0,cudaMemcpyHostToDevice);

  // FAC data h->d
  cudaMemcpyToSymbol(gpu_fac,h_fac.data,h_fac.bytes(),0,cudaMemcpyHostToDevice);

  /*scalar_type* d_gamma_ptr;
  cudaMalloc((void**)&d_gamma_ptr,GAMMA_LENGTH*6*sizeof(scalar_type));

  dim3 pg_threads(GAMMA_LENGTH,6);
  dim3 pg_blockSize(32,6);
  dim3 pg_gridSize(divUp(pg_threads,pg_blockSize));
  precompute_gamma<scalar_type><<<pg_gridSize,pg_blockSize>>>(GAMMA_LENGTH,GAMMA_INC,d_gamma_ptr);

  qmmm_F_values_tex.normalized = false;
  qmmm_F_values_tex.filterMode = cudaFilterModeLinear;
  cudaMallocArray(&gammaArray,&qmmm_F_values_tex.channelDesc,GAMMA_LENGTH,6);
  cudaMemcpyToArray(gammaArray,0,0,d_gamma_ptr,sizeof(scalar_type)*GAMMA_LENGTH*6,cudaMemcpyDeviceToDevice);
  cudaFree(d_gamma_ptr);
  // Don't need STR past this point if precomputing F(m,U)
  // Can free STR on-device here*/

  cudaAssertNoError("gpu_set_gamma_arrays");
}

template<class T> void gpu_set_atom_positions(const HostMatrix<T>& m) {
  cudaMemcpyToSymbol(gpu_atom_positions, m.data, m.bytes(), 0, cudaMemcpyHostToDevice);
}
template<class T, class U> void gpu_set_clatoms(const HostMatrix<T>& m_pos, const HostMatrix<U>& m_charge) {
  cudaMemcpyToSymbol(gpu_clatoms, &fortran_vars.clatoms, sizeof(fortran_vars.clatoms), 0, cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol(gpu_clatom_positions, m_pos.data, m_pos.bytes(), 0, cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol(gpu_clatom_charges, m_charge.data, m_charge.bytes(), 0, cudaMemcpyHostToDevice);
}

#if FULL_DOUBLE
template void gpu_set_gamma_arrays<double>( void );
#else
template void gpu_set_gamma_arrays<float>( void );
#endif
template void gpu_set_atom_positions<float3>(const HostMatrix<float3>& m);
template void gpu_set_atom_positions<double3>(const HostMatrix<double3>& m);
template void gpu_set_clatoms<float3,float>(const HostMatrix<float3>& m_pos, const HostMatrix<float>& m_charge);
template void gpu_set_clatoms<double3,double>(const HostMatrix<double3>& m_pos, const HostMatrix<double>& m_charge);
//template<class scalar_type,true> __global__ void gpu_update_rmm(scalar_type* factors, uint points, scalar_type* rmm, scalar_type* function_values, uint m);
//template<class scalar_type,false> __global__ void gpu_update_rmm(scalar_type* factors, uint points, scalar_type* rmm, scalar_type* function_values, uint m);

template<class scalar_type>
void PointGroup<scalar_type>::solve(Timers& timers, bool compute_rmm, bool lda, bool compute_forces,
    bool compute_energy, double& energy,double& energy_i, double& energy_c, double& energy_c1,
    double& energy_c2, double* fort_forces_ptr, bool open){
  if(open) {
    solve_opened(timers, compute_rmm, lda, compute_forces, compute_energy, energy, energy_i, energy_c, energy_c1,
        energy_c2, fort_forces_ptr);
  }
  else {
    solve_closed(timers, compute_rmm, lda, compute_forces, compute_energy, energy, fort_forces_ptr);
  }

}

template<class scalar_type>
void PointGroup<scalar_type>::solve_closed(Timers& timers, bool compute_rmm, bool lda, bool compute_forces, bool compute_energy, double& energy, double* fort_forces_ptr){
  //uint max_used_memory = 0;

  /*** Computo sobre cada cubo ****/
  CudaMatrix<scalar_type> point_weights_gpu;
  FortranMatrix<double> fort_forces(fort_forces_ptr, fortran_vars.atoms, 3, fortran_vars.max_atoms);

  /** Compute this group's functions **/
  timers.functions.start_and_sync();
  compute_functions(compute_forces, !lda);
  timers.functions.pause_and_sync();

  uint group_m = total_functions();

  timers.density.start_and_sync();
  /** Load points from group **/
  HostMatrix<scalar_type> point_weights_cpu(number_of_points, 1);

  uint i = 0;
  for (vector<Point>::const_iterator p = points.begin(); p != points.end(); ++p, ++i) {
    point_weights_cpu(i) = p->weight;
  }
  point_weights_gpu = point_weights_cpu;

  dim3 threadBlock, threadGrid;
  /* compute density/factors */

  const int block_height= divUp(group_m, 2*DENSITY_BLOCK_SIZE);

  threadBlock = dim3(DENSITY_BLOCK_SIZE,1,1); // Hay que asegurarse que la cantidad de funciones este en rango
  threadGrid = dim3(number_of_points,block_height,1);

  CudaMatrix<scalar_type> factors_gpu;

  CudaMatrix<scalar_type> partial_densities_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dxyz_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dd1_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dd2_gpu;

  partial_densities_gpu.resize(COALESCED_DIMENSION(number_of_points), block_height);
  dxyz_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height);
  dd1_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height );
  dd2_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height );

  const dim3 threadGrid_accumulate(divUp(number_of_points,DENSITY_ACCUM_BLOCK_SIZE),1,1);
  const dim3 threadBlock_accumulate(DENSITY_ACCUM_BLOCK_SIZE,1,1);

  if (compute_rmm || compute_forces)
    factors_gpu.resize(number_of_points);

  int transposed_width = COALESCED_DIMENSION(number_of_points);
  #define BLOCK_DIM 16
  dim3 transpose_grid(transposed_width / BLOCK_DIM, divUp((group_m),BLOCK_DIM));
  dim3 transpose_threads(BLOCK_DIM, BLOCK_DIM, 1);

  CudaMatrix<scalar_type> function_values_transposed;
  CudaMatrix<vec_type<scalar_type,4> > gradient_values_transposed;

  function_values_transposed.resize(group_m, COALESCED_DIMENSION(number_of_points));

  if (fortran_vars.do_forces || fortran_vars.gga)
      gradient_values_transposed.resize( group_m,COALESCED_DIMENSION(number_of_points));

  transpose<<<transpose_grid, transpose_threads>>> (function_values_transposed.data,
      function_values.data, COALESCED_DIMENSION(number_of_points), group_m);

  if (fortran_vars.do_forces || fortran_vars.gga)
    transpose<<<transpose_grid, transpose_threads>>> (gradient_values_transposed.data,
        gradient_values.data, COALESCED_DIMENSION(number_of_points), group_m );


  HostMatrix<scalar_type> rmm_input_cpu(COALESCED_DIMENSION(group_m), group_m+DENSITY_BLOCK_SIZE);
  get_rmm_input(rmm_input_cpu); //Achica la matriz densidad a la version reducida del grupo

  for (uint i=0; i<(group_m+DENSITY_BLOCK_SIZE); i++)
  {
    for(uint j=0; j<COALESCED_DIMENSION(group_m); j++)
    {
      if((i>=group_m) || (j>=group_m) || (j > i))
      {
        rmm_input_cpu.data[COALESCED_DIMENSION(group_m)*i+j]=0.0f;
      }
    }
  }


  /*
   **********************************************************************
   * Pasando RDM (rmm) a texturas
   **********************************************************************
   */

  //Comentado porque ahora vamos a hacer esto a mano por la textura
  // TODO: pasarlo a un metodo dentro de matrix.cpp
  //rmm_input_gpu = rmm_input_cpu; //Aca copia de CPU a GPU

  cudaArray* cuArray;
  cudaMallocArray(&cuArray, &rmm_input_gpu_tex.channelDesc, rmm_input_cpu.width, rmm_input_cpu.height);
  cudaMemcpyToArray(cuArray, 0, 0, rmm_input_cpu.data, sizeof(scalar_type)*rmm_input_cpu.width*rmm_input_cpu.height, cudaMemcpyHostToDevice);
  cudaBindTextureToArray(rmm_input_gpu_tex, cuArray);

  rmm_input_gpu_tex.normalized = false;

  if (compute_energy) {
    CudaMatrix<scalar_type> energy_gpu(number_of_points);
#define compute_parameters \
    energy_gpu.data,factors_gpu.data,point_weights_gpu.data,number_of_points,function_values_transposed.data,gradient_values_transposed.data,hessian_values_transposed.data,group_m,partial_densities_gpu.data,dxyz_gpu.data,dd1_gpu.data,dd2_gpu.data
#define accumulate_parameters \
    energy_gpu.data,factors_gpu.data,point_weights_gpu.data,number_of_points,block_height,partial_densities_gpu.data,dxyz_gpu.data,dd1_gpu.data,dd2_gpu.data
    if (compute_forces || compute_rmm) {
      if (lda)
      {
          gpu_compute_density<scalar_type, true, true, true><<<threadGrid, threadBlock>>>(compute_parameters);
          gpu_accumulate_point<scalar_type, true, true, true><<<threadGrid_accumulate, threadBlock_accumulate>>> (accumulate_parameters);
      }
      else
      {
          gpu_compute_density<scalar_type, true, true, false><<<threadGrid, threadBlock>>>(compute_parameters);
          gpu_accumulate_point<scalar_type, true, true, false><<<threadGrid_accumulate, threadBlock_accumulate>>> (accumulate_parameters);
      }
    }
    else {
      if (lda)
      {
          gpu_compute_density<scalar_type, true, false, true><<<threadGrid, threadBlock>>>(compute_parameters);
          gpu_accumulate_point<scalar_type, true, false, true><<<threadGrid_accumulate, threadBlock_accumulate>>> (accumulate_parameters);
      }
      else
      {
          gpu_compute_density<scalar_type, true, false, false><<<threadGrid, threadBlock>>>(compute_parameters);
          gpu_accumulate_point<scalar_type, true, false, false><<<threadGrid_accumulate, threadBlock_accumulate>>> (accumulate_parameters);
      }
    }
    cudaAssertNoError("compute_density");

    HostMatrix<scalar_type> energy_cpu(energy_gpu);
    for (uint i = 0; i < number_of_points; i++) {
      energy += energy_cpu(i);
    } // TODO: hacer con un kernel?
  }
  else {
#undef compute_parameters
#undef accumulate_parameters

#define compute_parameters \
    NULL,factors_gpu.data,point_weights_gpu.data,number_of_points,function_values_transposed.data,gradient_values_transposed.data,hessian_values_transposed.data,group_m,partial_densities_gpu.data,dxyz_gpu.data,dd1_gpu.data,dd2_gpu.data
#define accumulate_parameters \
    NULL,factors_gpu.data,point_weights_gpu.data,number_of_points,block_height,partial_densities_gpu.data,dxyz_gpu.data,dd1_gpu.data,dd2_gpu.data
    if (lda)
    {
        gpu_compute_density<scalar_type, false, true, true><<<threadGrid, threadBlock>>>(compute_parameters);
        gpu_accumulate_point<scalar_type, false, true, true><<<threadGrid_accumulate, threadBlock_accumulate>>>(accumulate_parameters);
    }
    else
    {
        gpu_compute_density<scalar_type, false, true, false><<<threadGrid, threadBlock>>>(compute_parameters);
        gpu_accumulate_point<scalar_type, false, true, false><<<threadGrid_accumulate, threadBlock_accumulate>>>(accumulate_parameters);
    }
    cudaAssertNoError("compute_density");
  }
#undef compute_parameters
#undef accumulate_parameters

  timers.density.pause_and_sync();

//************ Repongo los valores que puse a cero antes, para las fuerzas son necesarios (o por lo mens utiles)
  for (uint i=0; i<(group_m); i++) {
    for(uint j=0; j<(group_m); j++) {
      if((i>=group_m) || (j>=group_m) || (j > i))
      {
        rmm_input_cpu.data[COALESCED_DIMENSION(group_m)*i+j]=rmm_input_cpu.data[COALESCED_DIMENSION(group_m)*j+i] ;
      }
    }
  }

  cudaMemcpyToArray(cuArray, 0, 0,rmm_input_cpu.data,
      sizeof(scalar_type)*rmm_input_cpu.width*rmm_input_cpu.height, cudaMemcpyHostToDevice);

   dim3 threads;
  /* compute forces */
  if (compute_forces) {
    timers.density_derivs.start_and_sync();
    threads = dim3(number_of_points);
    threadBlock = dim3(DENSITY_DERIV_BLOCK_SIZE);
    threadGrid = divUp(threads, threadBlock);

    CudaMatrix<vec_type4> dd_gpu(COALESCED_DIMENSION(number_of_points), total_nucleii()); dd_gpu.zero();
    CudaMatrixUInt nuc_gpu(func2local_nuc);  // TODO: esto en realidad se podria guardar una sola vez durante su construccion

    gpu_compute_density_derivs<<<threadGrid, threadBlock>>>(
        function_values.data, gradient_values.data, nuc_gpu.data, dd_gpu.data, number_of_points, group_m, total_nucleii());
    cudaAssertNoError("density_derivs");
    timers.density_derivs.pause_and_sync();

    timers.forces.start_and_sync();
    CudaMatrix<vec_type4> forces_gpu(total_nucleii());

    threads = dim3(total_nucleii());
    threadBlock = dim3(FORCE_BLOCK_SIZE);
    threadGrid = divUp(threads, threadBlock);
    gpu_compute_forces<<<threadGrid, threadBlock>>>(
        number_of_points, factors_gpu.data, dd_gpu.data, forces_gpu.data, total_nucleii());
    cudaAssertNoError("forces");

    HostMatrix<vec_type4> forces_cpu(forces_gpu);

    for (uint i = 0; i < total_nucleii(); ++i) {
      vec_type4 atom_force = forces_cpu(i);
      uint global_nuc = local2global_nuc[i];
      fort_forces(global_nuc, 0) += atom_force.x;
      fort_forces(global_nuc, 1) += atom_force.y;
      fort_forces(global_nuc, 2) += atom_force.z;
    }
    timers.forces.pause_and_sync();
  }

  timers.rmm.start_and_sync();
  /* compute RMM */
  if (compute_rmm) {
    threadBlock = dim3(RMM_BLOCK_SIZE_XY, RMM_BLOCK_SIZE_XY);
    uint blocksPerRow = divUp(group_m, RMM_BLOCK_SIZE_XY);
    // Only use enough blocks for lower triangle
    threadGrid = dim3(blocksPerRow*(blocksPerRow+1)/2);

    CudaMatrix<scalar_type> rmm_output_gpu(COALESCED_DIMENSION(group_m), group_m);
    // For calls with a single block (pretty common with cubes) don't bother doing the arithmetic to get block position in the matrix
    if (blocksPerRow > 1) {
        gpu_update_rmm<scalar_type,true><<<threadGrid, threadBlock>>>(factors_gpu.data, number_of_points, rmm_output_gpu.data, function_values.data, group_m);
    } else {
        gpu_update_rmm<scalar_type,false><<<threadGrid, threadBlock>>>(factors_gpu.data, number_of_points, rmm_output_gpu.data, function_values.data, group_m);
    }
    cudaAssertNoError("update_rmm");

    /*** Contribute this RMM to the total RMM ***/
    HostMatrix<scalar_type> rmm_output_cpu(rmm_output_gpu);
    add_rmm_output(rmm_output_cpu);
  }
  timers.rmm.pause_and_sync();

  /* clear functions */
  if(!(this->inGlobal)) {
    function_values.deallocate();
    gradient_values.deallocate();
    hessian_values_transposed.deallocate();
  }
  //Deshago el bind de textura de rmm
  cudaUnbindTexture(rmm_input_gpu_tex); //Enroque el Unbind con el Free, asi parece mas logico. Nano
  cudaFreeArray(cuArray);
}

//======================
// OPENSHELL
//======================
template<class scalar_type>
void PointGroup<scalar_type>::solve_opened(Timers& timers, bool compute_rmm, bool lda, bool compute_forces, bool compute_energy, double& energy, double& energy_i, double& energy_c, double& energy_c1, double& energy_c2, double* fort_forces_ptr){

  /*** Computo sobre cada cubo ****/
  CudaMatrix<scalar_type> point_weights_gpu;
  FortranMatrix<double> fort_forces(fort_forces_ptr, fortran_vars.atoms, 3, fortran_vars.max_atoms);

  /** Compute this group's functions **/
  timers.functions.start_and_sync();
  compute_functions(compute_forces, !lda); //<<<<==========
  timers.functions.pause_and_sync();

  uint group_m = total_functions();

  timers.density.start_and_sync();
  /** Load points from group **/
  HostMatrix<scalar_type> point_weights_cpu(number_of_points, 1);

  uint i = 0;
  for (vector<Point>::const_iterator p = points.begin(); p != points.end(); ++p, ++i) {
    point_weights_cpu(i) = p->weight;
  }
  point_weights_gpu = point_weights_cpu;

//<<===========================>>//
  dim3 threadBlock, threadGrid;
  /* compute density/factors */

  const int block_height= divUp(group_m,2*DENSITY_BLOCK_SIZE);

  threadBlock = dim3(DENSITY_BLOCK_SIZE,1,1); // Hay que asegurarse que la cantidad de funciones este en rango
  threadGrid = dim3(number_of_points,block_height,1);

  CudaMatrix<scalar_type> factors_a_gpu;
  CudaMatrix<scalar_type> factors_b_gpu;

  /*
  dxyz_gpu; gradiente
  dd1_gpu;  hessiano ii
  dd2_gpu;  hessiano ij
  */

  CudaMatrix<scalar_type> partial_densities_a_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dxyz_a_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dd1_a_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dd2_a_gpu;

  CudaMatrix<scalar_type> partial_densities_b_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dxyz_b_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dd1_b_gpu;
  CudaMatrix<vec_type<scalar_type,4> > dd2_b_gpu;

  /*
   **********************************************************************
   * Transposiciones de matrices para la coalescencia mejorada en density
   **********************************************************************
   */

  CudaMatrix<scalar_type> function_values_transposed;
  CudaMatrix<vec_type<scalar_type,4> > gradient_values_transposed;

  int transposed_width = COALESCED_DIMENSION(number_of_points);

  function_values_transposed.resize(group_m, COALESCED_DIMENSION(number_of_points));
  if (fortran_vars.do_forces || fortran_vars.gga)
      gradient_values_transposed.resize( group_m,COALESCED_DIMENSION(number_of_points));

  #define BLOCK_DIM 16
  dim3 transpose_grid(transposed_width / BLOCK_DIM, divUp((group_m),BLOCK_DIM));
  dim3 transpose_threads(BLOCK_DIM, BLOCK_DIM, 1);

  transpose<<<transpose_grid, transpose_threads>>> (function_values_transposed.data, function_values.data,  COALESCED_DIMENSION(number_of_points),group_m   );
  if (fortran_vars.do_forces || fortran_vars.gga)
      transpose<<<transpose_grid, transpose_threads>>> (gradient_values_transposed.data, gradient_values.data, COALESCED_DIMENSION(number_of_points), group_m );

  partial_densities_a_gpu.resize(COALESCED_DIMENSION(number_of_points), block_height);
  dxyz_a_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height);
  dd1_a_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height );
  dd2_a_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height );

  partial_densities_b_gpu.resize(COALESCED_DIMENSION(number_of_points), block_height);
  dxyz_b_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height);
  dd1_b_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height );
  dd2_b_gpu.resize(COALESCED_DIMENSION(number_of_points),block_height );

  const dim3 threadGrid_accumulate(divUp(number_of_points,DENSITY_ACCUM_BLOCK_SIZE),1,1);
  const dim3 threadBlock_accumulate(DENSITY_ACCUM_BLOCK_SIZE,1,1);

  if (compute_rmm || compute_forces) {
  	factors_a_gpu.resize(number_of_points);
  	factors_b_gpu.resize(number_of_points);
  }

  HostMatrix<scalar_type> rmm_input_a_cpu(COALESCED_DIMENSION(group_m), group_m+DENSITY_BLOCK_SIZE);
  HostMatrix<scalar_type> rmm_input_b_cpu(COALESCED_DIMENSION(group_m), group_m+DENSITY_BLOCK_SIZE);
  get_rmm_input(rmm_input_a_cpu,rmm_input_b_cpu); //Achica las matrices densidad (Up,Down) a la version reducida del grupo

  for (uint i=0; i<(group_m+DENSITY_BLOCK_SIZE); i++) {
    for(uint j=0; j<COALESCED_DIMENSION(group_m); j++) {
      if((i>=group_m) || (j>=group_m) || (j > i)) {
        rmm_input_a_cpu.data[COALESCED_DIMENSION(group_m)*i+j]=0.0f;
        rmm_input_b_cpu.data[COALESCED_DIMENSION(group_m)*i+j]=0.0f;
      }
    }
  }

  /*
  **********************************************************************
  * Pasando RDM (rmm) a texturas/
  **********************************************************************
  */


  cudaArray* cuArray1;
  cudaArray* cuArray2;
  cudaMallocArray(&cuArray1, &rmm_input_gpu_tex.channelDesc, rmm_input_a_cpu.width,rmm_input_a_cpu.height);
  cudaMallocArray(&cuArray2, &rmm_input_gpu_tex2.channelDesc, rmm_input_b_cpu.width,rmm_input_b_cpu.height);
  cudaMemcpyToArray(cuArray1, 0, 0,rmm_input_a_cpu.data,sizeof(scalar_type)*rmm_input_a_cpu.width*rmm_input_a_cpu.height, cudaMemcpyHostToDevice);
  cudaMemcpyToArray(cuArray2, 0, 0,rmm_input_b_cpu.data,sizeof(scalar_type)*rmm_input_b_cpu.width*rmm_input_b_cpu.height, cudaMemcpyHostToDevice);
  cudaBindTextureToArray(rmm_input_gpu_tex, cuArray1);
  cudaBindTextureToArray(rmm_input_gpu_tex2, cuArray2);

  rmm_input_gpu_tex.normalized = false;
  rmm_input_gpu_tex2.normalized = false;

  if (compute_energy) {
    CudaMatrix<scalar_type> energy_gpu(number_of_points);
    CudaMatrix<scalar_type> energy_i_gpu(number_of_points);
    CudaMatrix<scalar_type> energy_c_gpu(number_of_points);
    CudaMatrix<scalar_type> energy_c1_gpu(number_of_points);
    CudaMatrix<scalar_type> energy_c2_gpu(number_of_points);

    if (compute_forces || compute_rmm) {
      gpu_compute_density_opened<scalar_type, true, true, false><<<threadGrid, threadBlock>>>(
             point_weights_gpu.data,number_of_points, function_values_transposed.data,
             gradient_values_transposed.data,hessian_values_transposed.data, group_m,
             partial_densities_a_gpu.data, dxyz_a_gpu.data, dd1_a_gpu.data, dd2_a_gpu.data,
             partial_densities_b_gpu.data, dxyz_b_gpu.data, dd1_b_gpu.data, dd2_b_gpu.data);

      gpu_accumulate_point_open<scalar_type, true, true, false><<<threadGrid_accumulate, threadBlock_accumulate>>> (
             energy_gpu.data,energy_i_gpu.data,energy_c_gpu.data,energy_c1_gpu.data,energy_c2_gpu.data,
             factors_a_gpu.data, factors_b_gpu.data, point_weights_gpu.data,number_of_points,block_height,
             partial_densities_a_gpu.data, dxyz_a_gpu.data, dd1_a_gpu.data, dd2_a_gpu.data,
             partial_densities_b_gpu.data, dxyz_b_gpu.data, dd1_b_gpu.data, dd2_b_gpu.data);
    }
    else {
      gpu_compute_density_opened<scalar_type, true, false, false><<<threadGrid, threadBlock>>>(
             point_weights_gpu.data,number_of_points, function_values_transposed.data,
             gradient_values_transposed.data,hessian_values_transposed.data, group_m,
             partial_densities_a_gpu.data, dxyz_a_gpu.data, dd1_a_gpu.data, dd2_a_gpu.data,
             partial_densities_b_gpu.data, dxyz_b_gpu.data, dd1_b_gpu.data, dd2_b_gpu.data);
      gpu_accumulate_point_open<scalar_type, true, false, false><<<threadGrid_accumulate, threadBlock_accumulate>>> (
             energy_gpu.data, energy_i_gpu.data,energy_c_gpu.data,energy_c1_gpu.data,energy_c2_gpu.data,
             factors_a_gpu.data, factors_b_gpu.data, point_weights_gpu.data,number_of_points,block_height,
             partial_densities_a_gpu.data, dxyz_a_gpu.data, dd1_a_gpu.data, dd2_a_gpu.data,
             partial_densities_b_gpu.data, dxyz_b_gpu.data, dd1_b_gpu.data, dd2_b_gpu.data);
    }
    cudaAssertNoError("compute_density");

    HostMatrix<scalar_type> energy_cpu(energy_gpu);
    HostMatrix<scalar_type> energy_i_cpu(energy_i_gpu);
    HostMatrix<scalar_type> energy_c_cpu(energy_c_gpu);
    HostMatrix<scalar_type> energy_c1_cpu(energy_c1_gpu);
    HostMatrix<scalar_type> energy_c2_cpu(energy_c2_gpu);
    for (uint i = 0; i < number_of_points; i++) {
      energy    += energy_cpu(i);
      energy_i  += energy_i_cpu(i);
      energy_c  += energy_c_cpu(i);
      energy_c1 += energy_c1_cpu(i);
      energy_c2 += energy_c2_cpu(i);
    } // TODO: hacer con un kernel?
  }
  else {
    gpu_compute_density_opened<scalar_type, false, true, false><<<threadGrid, threadBlock>>>(
           point_weights_gpu.data, number_of_points, function_values_transposed.data,
           gradient_values_transposed.data,hessian_values_transposed.data, group_m,
           partial_densities_a_gpu.data, dxyz_a_gpu.data, dd1_a_gpu.data, dd2_a_gpu.data,
           partial_densities_b_gpu.data, dxyz_b_gpu.data, dd1_b_gpu.data, dd2_b_gpu.data);
    gpu_accumulate_point_open<scalar_type, false, true, false><<<threadGrid_accumulate, threadBlock_accumulate>>> (
           NULL,NULL,NULL,NULL,NULL,
           factors_a_gpu.data, factors_b_gpu.data, point_weights_gpu.data,number_of_points,block_height,
           partial_densities_a_gpu.data, dxyz_a_gpu.data, dd1_a_gpu.data, dd2_a_gpu.data,
           partial_densities_b_gpu.data, dxyz_b_gpu.data, dd1_b_gpu.data, dd2_b_gpu.data);
    cudaAssertNoError("compute_density");
  }

  timers.density.pause_and_sync();

//************ Repongo los valores que puse a cero antes, para las fuerzas son necesarios (o por lo menos utiles)
  for (uint i=0; i<(group_m); i++) {
    for(uint j=0; j<(group_m); j++) {
      if((i>=group_m) || (j>=group_m) || (j > i)){
        rmm_input_a_cpu.data[COALESCED_DIMENSION(group_m)*i+j]=rmm_input_a_cpu.data[COALESCED_DIMENSION(group_m)*j+i] ;
        rmm_input_b_cpu.data[COALESCED_DIMENSION(group_m)*i+j]=rmm_input_b_cpu.data[COALESCED_DIMENSION(group_m)*j+i] ;
      }
    }
  }

  cudaMemcpyToArray(cuArray1, 0, 0,rmm_input_a_cpu.data,sizeof(scalar_type)*rmm_input_a_cpu.width*rmm_input_a_cpu.height, cudaMemcpyHostToDevice);
  cudaMemcpyToArray(cuArray2, 0, 0,rmm_input_b_cpu.data,sizeof(scalar_type)*rmm_input_b_cpu.width*rmm_input_b_cpu.height, cudaMemcpyHostToDevice);

//**********************************************

   dim3 threads;
  /* compute forces */

  if (compute_forces) {
    timers.density_derivs.start_and_sync();
    threads = dim3(number_of_points);
    threadBlock = dim3(DENSITY_DERIV_BLOCK_SIZE);
    threadGrid = divUp(threads, threadBlock);

    CudaMatrix<vec_type4> dd_gpu_a(COALESCED_DIMENSION(number_of_points), total_nucleii());
    CudaMatrix<vec_type4> dd_gpu_b(COALESCED_DIMENSION(number_of_points), total_nucleii());
    dd_gpu_a.zero();
    dd_gpu_b.zero();
    CudaMatrixUInt nuc_gpu(func2local_nuc);  // TODO: esto en realidad se podria guardar una sola vez durante su construccion

    // Kernel
    gpu_compute_density_derivs_open<<<threadGrid, threadBlock>>>(function_values.data, gradient_values.data, nuc_gpu.data, dd_gpu_a.data, dd_gpu_b.data, number_of_points, group_m, total_nucleii());

    cudaAssertNoError("density_derivs");
    timers.density_derivs.pause_and_sync();

    timers.forces.start_and_sync();
    CudaMatrix<vec_type4> forces_gpu_a(total_nucleii());
    CudaMatrix<vec_type4> forces_gpu_b(total_nucleii());

    threads = dim3(total_nucleii());
    threadBlock = dim3(FORCE_BLOCK_SIZE);
    threadGrid = divUp(threads, threadBlock);
    // Kernel
    gpu_compute_forces<<<threadGrid, threadBlock>>>(number_of_points, factors_a_gpu.data, dd_gpu_a.data, forces_gpu_a.data, total_nucleii());
    gpu_compute_forces<<<threadGrid, threadBlock>>>(number_of_points, factors_b_gpu.data, dd_gpu_b.data, forces_gpu_b.data, total_nucleii());

    cudaAssertNoError("forces");

    HostMatrix<vec_type4> forces_cpu_a(forces_gpu_a);
    HostMatrix<vec_type4> forces_cpu_b(forces_gpu_b);

    for (uint i = 0; i < total_nucleii(); ++i) {
      vec_type4 atom_force_a = forces_cpu_a(i);
      vec_type4 atom_force_b = forces_cpu_b(i);
      uint global_nuc = local2global_nuc[i];

      fort_forces(global_nuc, 0)=fort_forces(global_nuc, 0) + atom_force_a.x + atom_force_b.x;
      fort_forces(global_nuc, 1)=fort_forces(global_nuc, 1) + atom_force_a.y + atom_force_b.y;
      fort_forces(global_nuc, 2)=fort_forces(global_nuc, 2) + atom_force_a.z + atom_force_b.z;
    }

    timers.forces.pause_and_sync();
  }

  /* compute RMM */
  timers.rmm.start_and_sync();
  if (compute_rmm) {
	//cout<<"EMPEZANDO GPU_UPDATE_RMM"<<endl;
	//threads = dim3(group_m, group_m);
    	threadBlock = dim3(RMM_BLOCK_SIZE_XY, RMM_BLOCK_SIZE_XY);
    	//threadGrid = divUp(threads, threadBlock);
        uint blocksPerRow = divUp(group_m, RMM_BLOCK_SIZE_XY);
        // Only use enough blocks for lower triangle
        threadGrid = dim3(blocksPerRow*(blocksPerRow+1)/2);

    	CudaMatrix<scalar_type> rmm_output_a_gpu(COALESCED_DIMENSION(group_m), group_m);
    	CudaMatrix<scalar_type> rmm_output_b_gpu(COALESCED_DIMENSION(group_m), group_m);
    	// Kernel
//	cout<<"alpha"<<endl;
        // For calls with a single block (pretty common with cubes) don't bother doing the arithmetic to get block position in the matrix
        if (blocksPerRow > 1) {
	    gpu_update_rmm<scalar_type,true><<<threadGrid, threadBlock>>>(factors_a_gpu.data, number_of_points, rmm_output_a_gpu.data, function_values.data, group_m);
//	cout<<endl;
//        cout<<"beta"<<endl;
            gpu_update_rmm<scalar_type,true><<<threadGrid, threadBlock>>>(factors_b_gpu.data, number_of_points, rmm_output_b_gpu.data, function_values.data, group_m);
        } else {
	    gpu_update_rmm<scalar_type,false><<<threadGrid, threadBlock>>>(factors_a_gpu.data, number_of_points, rmm_output_a_gpu.data, function_values.data, group_m);
            gpu_update_rmm<scalar_type,false><<<threadGrid, threadBlock>>>(factors_b_gpu.data, number_of_points, rmm_output_b_gpu.data, function_values.data, group_m);
        }
    	//cout<<endl;
        cudaAssertNoError("update_rmm");

    	/*** Contribute this RMM to the total RMM ***/
    	HostMatrix<scalar_type> rmm_output_a_cpu(rmm_output_a_gpu);
    	HostMatrix<scalar_type> rmm_output_b_cpu(rmm_output_b_gpu);
    	//add_rmm_open_output(rmm_output_a_cpu,rmm_output_b_cpu);
    	add_rmm_output_a(rmm_output_a_cpu);
    	add_rmm_output_b(rmm_output_b_cpu);

    //CudaMatrix<scalar_type> rmm_output_a_gpu(COALESCED_DIMENSION(group_m), group_m);
//    CudaMatrix<scalar_type> rmm_output_b_gpu(COALESCED_DIMENSION(group_m), group_m);
//    gpu_update_rmm<scalar_type,true><<<threadGrid, threadBlock>>>(factors_a_gpu.data, number_of_points, rmm_output_a_gpu.data, function_values.data, group_m);
//    gpu_update_rmm<scalar_type,true><<<threadGrid, threadBlock>>>(factors_b_gpu.data, number_of_points, rmm_output_b_gpu.data, function_values.data, group_m);
//    cudaAssertNoError("update_rmm");

    /*** Contribute this RMM to the total RMM ***/
//    HostMatrix<scalar_type> rmm_output_a_cpu(rmm_output_a_gpu);
//    HostMatrix<scalar_type> rmm_output_b_cpu(rmm_output_b_gpu);
    //add_rmm_open_output(rmm_output_a_cpu,rmm_output_b_cpu);
//    add_rmm_output_a(rmm_output_a_cpu);
//    add_rmm_output_b(rmm_output_b_cpu);
  }
  timers.rmm.pause_and_sync();

  /* clear functions */
  if(!(this->inGlobal)) {
    function_values.deallocate();
    gradient_values.deallocate();
    hessian_values_transposed.deallocate();
  }

  //Deshago el bind de textura de rmm
  cudaUnbindTexture(rmm_input_gpu_tex); //Enroque el Unbind con el Free, asi parece mas logico. Nano
  cudaUnbindTexture(rmm_input_gpu_tex2); //Enroque el Unbind con el Free, asi parece mas logico. Nano
  cudaFreeArray(cuArray1);
  cudaFreeArray(cuArray2);
}

/*******************************
 * Cube Functions
 *******************************/

template<class scalar_type>
void PointGroup<scalar_type>::compute_functions(bool forces, bool gga)
{
  if(this->inGlobal) //Ya las tengo en memoria? entonces salgo porque ya estan las 3 calculadas
    return;

  if(0 == globalMemoryPool::tryAlloc(this->size_in_gpu())) //1 si hubo error, 0 si pude reservar la memoria
    this->inGlobal=true;
  CudaMatrix<vec_type4> points_position_gpu;
  CudaMatrix<vec_type2> factor_ac_gpu;
  CudaMatrixUInt nuc_gpu;
  CudaMatrixUInt contractions_gpu;

  /** Load points from group **/
  {
    HostMatrix<vec_type4> points_position_cpu(number_of_points, 1);
    uint i = 0;
    for (vector<Point>::const_iterator p = points.begin(); p != points.end(); ++p, ++i) {
      points_position_cpu(i) = vec_type4(p->position.x, p->position.y, p->position.z, 0);
    }
    points_position_gpu = points_position_cpu;
  }
  /* Load group functions */
  uint group_m = s_functions + p_functions * 3 + d_functions * 6;
  uint4 group_functions = make_uint4(s_functions, p_functions, d_functions, group_m);
  HostMatrix<vec_type2> factor_ac_cpu(COALESCED_DIMENSION(group_m), MAX_CONTRACTIONS);
  HostMatrixUInt nuc_cpu(group_m, 1), contractions_cpu(group_m, 1);

  // TODO: hacer que functions.h itere por total_small_functions()... asi puedo hacer que
  // func2global_nuc sea de tamaño total_functions() y directamente copio esa matriz aca y en otros lados

  uint ii = 0;
  for (uint i = 0; i < total_functions_simple(); ++i) {
    uint inc = small_function_type(i);

    uint func = local2global_func[i];
    uint this_nuc = func2global_nuc(i);
    uint this_cont = fortran_vars.contractions(func);

    for (uint j = 0; j < inc; j++) {
      nuc_cpu(ii) = this_nuc;
      contractions_cpu(ii) = this_cont;
      for (unsigned int k = 0; k < this_cont; k++)
        factor_ac_cpu(ii, k) = vec_type2(fortran_vars.a_values(func, k), fortran_vars.c_values(func, k));
      ii++;
    }
  }
  factor_ac_gpu = factor_ac_cpu;
  nuc_gpu = nuc_cpu;
  contractions_gpu = contractions_cpu;

  CudaMatrix<vec_type<scalar_type,4> > hessian_values;
  /** Compute Functions **/
  function_values.resize(COALESCED_DIMENSION(number_of_points), group_functions.w);
  if (fortran_vars.do_forces || fortran_vars.gga)
      gradient_values.resize(COALESCED_DIMENSION(number_of_points), group_functions.w);
  if (fortran_vars.gga)
      hessian_values.resize(COALESCED_DIMENSION(number_of_points), (group_functions.w) * 2);

  dim3 threads(number_of_points);
  dim3 threadBlock(FUNCTIONS_BLOCK_SIZE);
  dim3 threadGrid = divUp(threads, threadBlock);

 // cout << "points: " << threads.x << " " << threadGrid.x << " " << threadBlock.x << endl;
#define compute_functions_parameters \
  points_position_gpu.data,number_of_points,contractions_gpu.data,factor_ac_gpu.data,nuc_gpu.data,function_values.data,gradient_values.data,hessian_values.data,group_functions
  if (forces) {
    if (gga)
      gpu_compute_functions<scalar_type, true, true><<<threadGrid, threadBlock>>>(compute_functions_parameters);
    else
      gpu_compute_functions<scalar_type, true, false><<<threadGrid, threadBlock>>>(compute_functions_parameters);
  }
  else {
    if (gga)
      gpu_compute_functions<scalar_type, false, true><<<threadGrid, threadBlock>>>(compute_functions_parameters);
    else
      gpu_compute_functions<scalar_type, false, false><<<threadGrid, threadBlock>>>(compute_functions_parameters);
  }

  if (fortran_vars.gga) {
    int transposed_width = COALESCED_DIMENSION(number_of_points);
    #define BLOCK_DIM 16
    dim3 transpose_threads(BLOCK_DIM, BLOCK_DIM, 1);
    dim3 transpose_grid=dim3(transposed_width / BLOCK_DIM, divUp((group_m)*2, BLOCK_DIM), 1);

    hessian_values_transposed.resize((group_m) * 2, COALESCED_DIMENSION(number_of_points));
    transpose<<<transpose_grid, transpose_threads>>> (hessian_values_transposed.data,
        hessian_values.data, COALESCED_DIMENSION(number_of_points), (group_m)*2);
  }
  cudaAssertNoError("compute_functions");
}

/*******************************
 * Cube Weights
 *******************************/
template<class scalar_type>
void PointGroup<scalar_type>::compute_weights(void)
{
  CudaMatrix<vec_type4> point_positions_gpu;
  CudaMatrix<vec_type4> atom_position_rm_gpu;
  {
    HostMatrix<vec_type4> points_positions_cpu(number_of_points, 1);
		uint i = 0;
		for (vector<Point>::const_iterator p = points.begin(); p != points.end(); ++p, ++i) {
			points_positions_cpu(i) = vec_type4(p->position.x, p->position.y, p->position.z, p->atom);
		}
    point_positions_gpu = points_positions_cpu;

    HostMatrix<vec_type4> atom_position_rm_cpu(fortran_vars.atoms, 1);
    for (uint i = 0; i < fortran_vars.atoms; i++) {
      double3 atom_pos = fortran_vars.atom_positions(i);
      atom_position_rm_cpu(i) = vec_type4(atom_pos.x, atom_pos.y, atom_pos.z, fortran_vars.rm(i));
    }
    atom_position_rm_gpu = atom_position_rm_cpu;
  }

  CudaMatrixUInt nucleii_gpu(local2global_nuc);

  CudaMatrix<scalar_type> weights_gpu(number_of_points);
  dim3 threads(number_of_points);
  dim3 blockSize(WEIGHT_BLOCK_SIZE);
  dim3 gridSize = divUp(threads, blockSize);
  gpu_compute_weights<scalar_type><<<gridSize,blockSize>>>(
      number_of_points, point_positions_gpu.data, atom_position_rm_gpu.data, weights_gpu.data, nucleii_gpu.data, total_nucleii());
  cudaAssertNoError("compute_weights");

  #if REMOVE_ZEROS
  std::vector<Point> nonzero_points;
  uint nonzero_number_of_points = 0;
  #endif

  uint ceros = 0;

  HostMatrix<scalar_type> weights_cpu(weights_gpu);
  uint i = 0;
  for (vector<Point>::iterator p = points.begin(); p != points.end(); ++p, ++i) {
    p->weight *= weights_cpu(i);

    if (p->weight == 0.0) {
      ceros++;
    }
    #if REMOVE_ZEROS
    else {
      nonzero_points.push_back(*p);
      nonzero_number_of_points++;
    }
    #endif
  }

  //cout << "ceros: " << ceros << "/" << group.number_of_points << " (" << (ceros / (double)group.number_of_points) * 100 << "%)" << endl;

  #if REMOVE_ZEROS
  points = nonzero_points;
  number_of_points = nonzero_number_of_points;
  #endif
}

template class PointGroup<double>;
template class PointGroup<float>;

#define NUM_TERM_TYPES 6
#define MAX_TERM_TYPE 6

template <class scalar_type> void get_qmmm_forces(double* qm_forces, double* mm_forces)
{
  uint i,j,ni,nj;
  uint i_orbitals, j_orbitals;
  uint nuc_i,nuc_j;
  vec_type<double,3> A,B,AmB;
  double ai,aj;
  double dsq,ksi,zeta;
  uint num_terms=0, total_num_terms = 0;
  //std::list<uint> func_code, local_dens;
  std::vector<uint> func_code, local_dens;
  //std::vector<scalar_type> a_values1,a_values2;
  //std::vector<scalar_type> cc_values;
  std::vector<scalar_type> dens_values;
  //std::vector<uint> nuclei1, nuclei2;

  uint term_type_counts[NUM_TERM_TYPES];
  uint term_type_offsets[NUM_TERM_TYPES];
  term_type_offsets[0] = 0;
  uint i_begin, i_end, j_begin, j_end;
  uint tmp_ind = 0;
  uint s_start = 0, p_start = fortran_vars.s_funcs, d_start = fortran_vars.s_funcs + fortran_vars.p_funcs*3, m = fortran_vars.m;

  //                                       s-s        p-s        p-p        d-s        d-p        d-d
  uint i_begin_vals[MAX_TERM_TYPE]   = { s_start,   p_start,   p_start,   d_start,   d_start,   d_start};
  uint i_end_vals[MAX_TERM_TYPE]     = { p_start,   d_start,   d_start,   m,         m,         m      };
  uint j_begin_vals[MAX_TERM_TYPE]   = { s_start,   s_start,   p_start,   s_start,   p_start,   d_start};
  uint j_end_vals[MAX_TERM_TYPE]     = { p_start-1, p_start-1, d_start-1, p_start-1, d_start-1, m-1    };
  uint i_orbital_vals[MAX_TERM_TYPE] = { 1,         3,         3,         6,         6,         6      };
  uint j_orbital_vals[MAX_TERM_TYPE] = { 1,         1,         3,         1,         3,         6      };

  uint local_dens_ind, num_dens_terms = 0, total_dens_terms = 0;
  uint dens_counts[NUM_TERM_TYPES], dens_offsets[NUM_TERM_TYPES];
  dens_offsets[0] = 0;
  uint tmp_dens_ind = 0;
  //uint local_orbitals;

  Timer nuc,check,prep,kernel,down,reduce;
  nuc.start_and_sync();
  for (i = 0; i < fortran_vars.atoms; i++) {
    double3 qm_pos = fortran_vars.atom_positions(i);
    for (j = 0; j < fortran_vars.clatoms; j++) {
      double3 mm_pos = fortran_vars.clatom_positions(j);
      double3 diff = qm_pos - mm_pos;
      double dist = diff.x*diff.x + diff.y*diff.y + diff.z*diff.z;
      dist = sqrt(dist);

      double prefactor = -fortran_vars.clatom_charges(j) * (fortran_vars.atom_types(i)+1) / pow(dist,3.0);
      qm_forces[i + 0 * fortran_vars.atoms] += prefactor * (qm_pos.x - mm_pos.x);
      qm_forces[i + 1 * fortran_vars.atoms] += prefactor * (qm_pos.y - mm_pos.y);
      qm_forces[i + 2 * fortran_vars.atoms] += prefactor * (qm_pos.z - mm_pos.z);
      mm_forces[j + 0 * (fortran_vars.atoms+fortran_vars.clatoms)] -= prefactor * (qm_pos.x - mm_pos.x);
      mm_forces[j + 1 * (fortran_vars.atoms+fortran_vars.clatoms)] -= prefactor * (qm_pos.y - mm_pos.y);
      mm_forces[j + 2 * (fortran_vars.atoms+fortran_vars.clatoms)] -= prefactor * (qm_pos.z - mm_pos.z);
    }
  }
  nuc.pause();
  check.start();

  //uint last_code = 0;
  //uint last_dens = 0;
  for (uint current_term_type = 0; current_term_type < NUM_TERM_TYPES; current_term_type++) {

    term_type_counts[current_term_type] = 0;
    i_begin = i_begin_vals[current_term_type]; i_end = i_end_vals[current_term_type];
    j_begin = j_begin_vals[current_term_type]; j_end = j_end_vals[current_term_type];
    i_orbitals = i_orbital_vals[current_term_type];
    j_orbitals = j_orbital_vals[current_term_type];

    dens_counts[current_term_type] = 0;
    local_dens_ind = 0;

    //std::list<scalar_type> zetas;
    if (current_term_type > 0) {
      tmp_ind += COALESCED_DIMENSION(term_type_counts[current_term_type-1]);
      term_type_offsets[current_term_type] = tmp_ind;
      tmp_dens_ind += COALESCED_DIMENSION(dens_counts[current_term_type-1]);
      dens_offsets[current_term_type] = tmp_dens_ind;
    }

    // function i, center A
    for (i = i_begin; i < i_end; i += i_orbitals) {
      nuc_i = fortran_vars.nucleii(i) - 1;
      A = fortran_vars.atom_positions(nuc_i);
      // function j, center B
      for (j = j_begin; j <= ((i > j_end)? j_end : i); j += j_orbitals) {
        nuc_j = fortran_vars.nucleii(j) - 1;
        B = fortran_vars.atom_positions(nuc_j);
        AmB = A - B;
        dsq = length2(AmB);
        bool use_funcs = false;
        for (ni = 0; ni < fortran_vars.contractions(i); ni++) {
          for (nj = 0; nj < fortran_vars.contractions(j); nj++) {
            ai = fortran_vars.a_values(i,ni);
            aj = fortran_vars.a_values(j,nj);
            zeta = ai + aj;
            ksi = ai * aj / zeta;
            total_num_terms += (i==j)? i_orbitals*(i_orbitals+1)/2 : i_orbitals * j_orbitals;

            if (dsq*ksi < fortran_vars.rmax) {
              use_funcs = true;
              //local_orbitals = 0;
              //for (uint i_orbital = 0; i_orbital < i_orbitals; i_orbital++) {
              //  uint j_orbital_finish = (i==j)? i_orbital+1 : j_orbitals;
              //  for (uint j_orbital = 0; j_orbital < j_orbital_finish; j_orbital++) {
                  num_terms++;
                  term_type_counts[current_term_type]++;

                  // Encoding which two primitives this thread will calculate a force term for in one number
                  // TODO: Might need to rethink this, depending on how big func_code can get
                  uint this_func_code = nj;                                                                    // First, primitive # nj in the lowest part
                  this_func_code     += ni            * MAX_CONTRACTIONS;                                      // Primitive # ni after the space for nj
                  this_func_code     += (j/*+j_orbital*/) * MAX_CONTRACTIONS * MAX_CONTRACTIONS;                   // Function # j after space for primitives
                  this_func_code     += (i/*+i_orbital*/) * MAX_CONTRACTIONS * MAX_CONTRACTIONS * fortran_vars.m;  // Finally, function # i in the highest part

                  //last_code = this_func_code;
                  //last_dens = local_dens_ind;

                  //typename std::list<scalar_type>::iterator zeta_iter;
                  //typename std::list<uint>::iterator func_iter = func_code.begin(), dens_iter = local_dens.begin();
                  //std::advance(func_iter,term_type_offsets[current_term_type]);
                  //std::advance(dens_iter,term_type_offsets[current_term_type]);
                  //for (zeta_iter = zetas.begin(); zeta_iter != zetas.end(); ++zeta_iter,++func_iter,++dens_iter) {
                  //  if (zeta <= (*zeta_iter)) break;
                  //}
                  //zetas.insert(zeta_iter,zeta);
                  //func_code.insert(func_iter,this_func_code);
                  //local_dens.insert(dens_iter,local_dens_ind);

                  func_code.push_back(this_func_code);
                  local_dens.push_back(local_dens_ind);

              //    local_orbitals++;
              //    local_dens_ind++;

                  //uint dens_ind = (i+i_orbital) + (2*fortran_vars.m-((j+j_orbital)+1))*(j+j_orbital)/2;
                  //dens_values.push_back(fortran_vars.rmm_input_ndens1.data[dens_ind]);
              //  }
              //}
              //local_dens_ind -= local_orbitals;
            }
          }
        }
        for (uint i_orbital = 0; i_orbital < i_orbitals; i_orbital++) {
          uint j_orbital_finish = (i==j)? i_orbital+1 : j_orbitals;
          for (uint j_orbital = 0; j_orbital < j_orbital_finish; j_orbital++) { total_dens_terms++; }
        }
        if (use_funcs) {
          for (uint i_orbital = 0; i_orbital < i_orbitals; i_orbital++) {
            uint j_orbital_finish = (i==j)? i_orbital+1 : j_orbitals;
            for (uint j_orbital = 0; j_orbital < j_orbital_finish; j_orbital++) {
              num_dens_terms++;
              dens_counts[current_term_type]++;

              uint dens_ind = (i+i_orbital) + (2*fortran_vars.m-((j+j_orbital)+1))*(j+j_orbital)/2;
              dens_values.push_back(fortran_vars.rmm_input_ndens1.data[dens_ind]);
              local_dens_ind++;
            }
          }
        }
      }
    }
    /*typename std::list<scalar_type>::iterator zeta_iter;
    typename std::list<uint>::iterator func_iter = func_code.begin();
    std::advance(func_iter,term_type_offsets[current_term_type]);
    for (zeta_iter = zetas.begin(); zeta_iter != zetas.end(); ++zeta_iter,++func_iter) {
      uint code = (*func_iter);
      uint nj = code % MAX_CONTRACTIONS;
      code /= MAX_CONTRACTIONS;
      uint ni = code % MAX_CONTRACTIONS;
      code /= MAX_CONTRACTIONS;
      uint fj = code % fortran_vars.m;
      code /= fortran_vars.m;
      uint fi = code;
      cout << fi << " " << ni << " " << fj << " " << nj << " " << fortran_vars.a_values(fi,ni) << " " << fortran_vars.a_values(fj,nj) << " " << *zeta_iter << endl;
    }*/
    for (j = term_type_counts[current_term_type]; j < COALESCED_DIMENSION(term_type_counts[current_term_type]); j++) {
      func_code.push_back(func_code[term_type_offsets[current_term_type]]);
      local_dens.push_back(local_dens[term_type_offsets[current_term_type]]);
      //dens_values.push_back(dens_values[term_type_offsets[current_term_type]]);
    }
    for (j = dens_counts[current_term_type]; j < COALESCED_DIMENSION(dens_counts[current_term_type]); j++) {
      dens_values.push_back(dens_values[dens_offsets[current_term_type]]);
    }
  }
  check.pause();
  prep.start();

  std::cout << "[G2G_QMMM] Number of threads: " << num_terms << std::endl;
  std::cout << "[G2G_QMMM] Total Gaussian pairs: " << total_num_terms << std::endl;
  std::cout << "[G2G_QMMM] Number of significant density elements: " << num_dens_terms << std::endl;
  std::cout << "[G2G_QMMM] Total density elements: " << total_dens_terms << std::endl;

  // Pad the input so that out-of-range threads do a dummy calculation (same as the first thread), rather than branching and idling
  for (i = 0; i < QMMM_FORCES_BLOCK_SIZE - (term_type_counts[NUM_TERM_TYPES-1] % QMMM_FORCES_BLOCK_SIZE); i++) {
    //a_values1.push_back(a_values1[0]);
    //a_values2.push_back(a_values2[0]);
    //cc_values.push_back(cc_values[0]);
    //dens_values.push_back(dens_values[0]);
    //nuclei1.push_back(nuclei1[0]);
    //nuclei2.push_back(nuclei2[0]);
    func_code.push_back(func_code[term_type_offsets[NUM_TERM_TYPES-1]]);
    local_dens.push_back(local_dens[term_type_offsets[NUM_TERM_TYPES-1]]);
    //orbital1.push_back(orbital1[0]);
    //orbital2.push_back(orbital2[0]);
  }
  for (i = 0; i < QMMM_FORCES_BLOCK_SIZE - (dens_offsets[NUM_TERM_TYPES-1]+dens_counts[NUM_TERM_TYPES-1]) % QMMM_FORCES_BLOCK_SIZE; i++) {
    dens_values.push_back(dens_values[dens_offsets[NUM_TERM_TYPES-1]]);
  }

  //uint total_funcs = fortran_vars.s_funcs + fortran_vars.p_funcs + fortran_vars.d_funcs;
  HostMatrix<vec_type<scalar_type, 2> > factor_ac_cpu(COALESCED_DIMENSION(/*total_funcs*/fortran_vars.m), MAX_CONTRACTIONS);
  HostMatrixUInt nuc_cpu(/*total_funcs*/fortran_vars.m, 1);
  CudaMatrix<vec_type<scalar_type, 2> > factor_ac_gpu;
  CudaMatrixUInt nuc_gpu;

  // TODO: tried contracting the nuc / function value arrays to a size of total_funcs rather than m, seems to slow down the kernel
  // Doing this requires some more indexing math in the kernel, but need to test on bigger test case
  uint localfunc = 0, func = 0;
  while (func < fortran_vars.m) {
    nuc_cpu(localfunc) = fortran_vars.nucleii(func) - 1;
    for (uint k = 0; k < fortran_vars.contractions(func); k++) {
      factor_ac_cpu(localfunc, k) = vec_type<scalar_type, 2>(fortran_vars.a_values(func, k), fortran_vars.c_values(func, k));
    }
    //if (func < fortran_vars.s_funcs)                               { func += 1; }
    //else if (func < fortran_vars.s_funcs + fortran_vars.p_funcs*3) { func += 3; }
    //else                                                           { func += 6; }
    func++;
    localfunc++;
  }
  factor_ac_gpu = factor_ac_cpu;
  nuc_gpu = nuc_cpu;

  // Send forces input to device (a values, thread function #s, thread nuclei #s)
  CudaMatrix<scalar_type> /*dev_a_values1(a_values1), dev_a_values2(a_values2), dev_cc_values(cc_values),*/ dev_dens_values(dens_values);
  //std::vector<uint> func_codev, local_densv;
  //typename std::list<uint>::iterator iter;
  //for (iter = func_code.begin(); iter != func_code.end(); iter++) {
  //  func_codev.push_back(*iter);
  //}
  //for (iter = local_dens.begin(); iter != local_dens.end(); iter++) {
  //  local_densv.push_back(*iter);
  //}
  CudaMatrixUInt dev_func_code(func_code), dev_local_dens(local_dens)/*dev_orb1(orbital1), dev_orb2(orbital2),*/; // dev_nuclei1(nuclei1), dev_nuclei2(nuclei2);

  /*dim3 testThreads(100,6);
  dim3 testBlock(32,6);
  dim3 testGrid(divUp(testThreads,testBlock));
  gpu_test_fmu_tex<scalar_type><<<testGrid,testBlock>>>( 0.5,GAMMA_INC );*/

  // Allocate output arrays on device (forces)
  CudaMatrix<vec_type<scalar_type,3> > gpu_partial_mm_forces, gpu_partial_qm_forces;//, gpu_mm_forces, gpu_qm_forces;

  uint partial_forces_size = 0;
  uint force_offsets[NUM_TERM_TYPES];
  force_offsets[0] = 0;
  // Force arrays (probably) don't need to be padded for alignment as only one (well, three) threads per block write to them
  for (i = 0; i < NUM_TERM_TYPES; i++) {
    partial_forces_size += divUp(term_type_counts[i],QMMM_FORCES_BLOCK_SIZE);
    if (i+1<NUM_TERM_TYPES) { force_offsets[i+1] = partial_forces_size; }
  }
  gpu_partial_mm_forces.resize(COALESCED_DIMENSION(partial_forces_size), fortran_vars.clatoms);
  gpu_partial_qm_forces.resize(COALESCED_DIMENSION(partial_forces_size), fortran_vars.atoms);
  //gpu_mm_forces.resize(fortran_vars.clatoms,1);
  //gpu_qm_forces.resize(fortran_vars.atoms,1);

  cudaBindTextureToArray(qmmm_str_tex,gammaArray);

#define qmmm_parameters \
  term_type_counts[i], factor_ac_gpu.data, nuc_gpu.data, /*dev_a_values1.data+offset, dev_a_values2.data+offset, dev_cc_values.data+offset,*/\
  dev_dens_values.data+dens_offset, /*dev_orb1.data+offset, dev_orb2.data+offset,*/dev_func_code.data+offset,dev_local_dens.data+offset, /*dev_nuclei1.data+offset, dev_nuclei2.data+offset,*/ \
  gpu_partial_mm_forces.data+force_offset, gpu_partial_qm_forces.data+force_offset, COALESCED_DIMENSION(partial_forces_size)

  prep.pause_and_sync();
  kernel.start();
  cudaStream_t stream[NUM_TERM_TYPES];
  for (i = 0; i < NUM_TERM_TYPES; i++) {
    cudaStreamCreate(&stream[i]);
  }
  for (i = 0; i < NUM_TERM_TYPES; i++)
  {
    uint offset = term_type_offsets[i];
    uint dens_offset = dens_offsets[i];
    uint force_offset = force_offsets[i];
    dim3 threads = term_type_counts[i];
    dim3 blockSize(QMMM_FORCES_BLOCK_SIZE);
    dim3 gridSize = divUp(threads, blockSize);
    switch (i) {
      case 0: gpu_qmmm_forces<scalar_type,0><<<gridSize,blockSize,0,stream[i]>>>( qmmm_parameters ); break;
      case 1: gpu_qmmm_forces<scalar_type,1><<<gridSize,blockSize,0,stream[i]>>>( qmmm_parameters ); break;
      case 2: gpu_qmmm_forces<scalar_type,2><<<gridSize,blockSize,0,stream[i]>>>( qmmm_parameters ); break;
      case 3: gpu_qmmm_forces<scalar_type,3><<<gridSize,blockSize,0,stream[i]>>>( qmmm_parameters ); break;
      case 4: gpu_qmmm_forces<scalar_type,4><<<gridSize,blockSize,0,stream[i]>>>( qmmm_parameters ); break;
      case 5: gpu_qmmm_forces<scalar_type,5><<<gridSize,blockSize,0,stream[i]>>>( qmmm_parameters ); break;
    }
  }
  cudaDeviceSynchronize();
  for (i = 0; i < NUM_TERM_TYPES; i++) {
    cudaStreamDestroy(stream[i]);
  }
  kernel.pause();
  down.start();

  HostMatrix<vec_type<scalar_type,3> > cpu_partial_mm_forces(gpu_partial_mm_forces), cpu_partial_qm_forces(gpu_partial_qm_forces);//cpu_mm_forces(gpu_mm_forces), cpu_qm_forces(gpu_qm_forces);
  down.pause_and_sync();
  reduce.start();

  // TODO: need to think about how to accumulate individual force terms
  // Currently, we reduce on a per-block basis in the kernel, then accumulate the block results here on the host
  // Maybe we could skip the reduction in the kernel (will speed it up, but by how much?), and each thread writes its own term to global memory, followed by a second kernel
  // that reduces all the individual thread terms (this is basically how the XC code works)
  // However, not sure that the memory requirements of each thread saving its term will be OK
  // Alternative: keep the kernel reduction, and reduce the block results in another kernel (rather than here on the host)
  for (i = 0; i < fortran_vars.atoms; i++) {
    for (j = 0; j < partial_forces_size; j++) {
      qm_forces[i + 0 * fortran_vars.atoms] += cpu_partial_qm_forces(j,i).x;
      qm_forces[i + 1 * fortran_vars.atoms] += cpu_partial_qm_forces(j,i).y;
      qm_forces[i + 2 * fortran_vars.atoms] += cpu_partial_qm_forces(j,i).z;
    }
  }
  for (i = 0; i < fortran_vars.clatoms; i++) {
    for (j = 0; j < partial_forces_size; j++) {
      mm_forces[i + 0 * (fortran_vars.atoms+fortran_vars.clatoms)] += cpu_partial_mm_forces(j,i).x;
      mm_forces[i + 1 * (fortran_vars.atoms+fortran_vars.clatoms)] += cpu_partial_mm_forces(j,i).y;
      mm_forces[i + 2 * (fortran_vars.atoms+fortran_vars.clatoms)] += cpu_partial_mm_forces(j,i).z;
    }
  }
  reduce.pause();

  cout << "[G2G_QMMM] nuc-nuc: " << nuc << " overlap check: " << check << " kernel prep: " << prep << endl;
  cout << "[G2G_QMMM] kernel: " << kernel << " download: " << down << " reduction: " << reduce << endl;

  cudaUnbindTexture(qmmm_str_tex);

  cudaAssertNoError("qmmm");
}

template<class scalar_type>
void clean_gamma( void ) {
  //scalar_type* d_str_ptr;
  //cudaMemcpyFromSymbol(&d_str_ptr,gpu_str,sizeof(d_str_ptr));
  //cudaFree(d_str_ptr);
  cudaFreeArray(gammaArray);

  cudaAssertNoError("clean_gamma");
}
#if FULL_DOUBLE
template void get_qmmm_forces<double>(double* qm_forces, double* mm_forces);
template void clean_gamma<double>( void );
#else
template void get_qmmm_forces<float>(double* qm_forces, double* mm_forces);
template void clean_gamma<float>( void );
#endif

}
