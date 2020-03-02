!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
subroutine ehrendyn_step( step_back, propagator_id, time_value, time_step,     &
                        & nbasis, natoms, nucpos, nucvel, nucfor_ds,           &
                        & Sinv, Uinv, Linv, dens_oldi, dens_midi, dens_newo,   &
                        & fock_mid, dipmom, energy )
!------------------------------------------------------------------------------!
!
! All matrices must be in OM
!
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
   implicit none
   logical, intent(inout)    :: step_back
   integer, intent(in)       :: propagator_id
   LIODBLE , intent(in)       :: time_value
   LIODBLE , intent(in)       :: time_step
   integer, intent(in)       :: nbasis
   integer, intent(in)       :: natoms

   LIODBLE, intent(in)        :: nucpos(3, natoms)
   LIODBLE, intent(in)        :: nucvel(3, natoms)
   LIODBLE, intent(inout)     :: nucfor_ds(3, natoms)

   LIODBLE, intent(in)        :: Sinv(nbasis, nbasis)
   LIODBLE, intent(in)        :: Uinv(nbasis, nbasis)
   LIODBLE, intent(in)        :: Linv(nbasis, nbasis)

   complex(kind=8), intent(in)    :: dens_oldi(nbasis, nbasis)
   complex(kind=8), intent(in)    :: dens_midi(nbasis, nbasis)
   complex(kind=8), intent(out)   :: dens_newo(nbasis, nbasis)

   LIODBLE    , intent(inout) :: fock_mid(nbasis, nbasis)
   LIODBLE    , intent(inout) :: dipmom(3)
   LIODBLE    , intent(inout) :: energy

   complex(kind=8), allocatable   :: dens_old(:,:)
   complex(kind=8), allocatable   :: dens_mid(:,:)
   LIODBLE    , allocatable   :: fock0(:,:)
   LIODBLE                    :: dipmom0(3)
   LIODBLE                    :: energy0

   integer                   :: substep, substeps
   LIODBLE                    :: time, dt
   LIODBLE    , allocatable   :: Bmat(:,:)
   LIODBLE    , allocatable   :: Dmat(:,:)
   complex(kind=8), allocatable   :: Tmat(:,:)
   complex(kind=8), allocatable   :: dens_mao(:,:)

   integer, parameter :: propagator_id_verlet = 1
   integer, parameter :: propagator_id_magnus = 2

   allocate( Bmat(nbasis,nbasis), Dmat(nbasis,nbasis), Tmat(nbasis,nbasis) )
   allocate( dens_old(nbasis,nbasis), dens_mid(nbasis,nbasis) )
   allocate( dens_mao(nbasis,nbasis) )
   allocate( fock0(nbasis,nbasis) )

   dens_old   = dens_oldi
   dens_mid   = dens_midi
   fock0      = fock_mid
   dipmom0(:) = 0.0d0
   energy0    = energy

   time = time_value
   if (step_back) then
      substeps = 20
      dt = (-time_step) / ( (2.0d0)*(substeps) )
      dens_old = dens_mid
   else
      substeps = 0
      dt = time_step
   endif


   do substep = 0, substeps
      fock_mid = Fock0
      dipmom   = dipmom0
      energy   = energy0
      nucfor_ds(:,:) = 0.0d0

!     Preparing matrices (received in AO and returned in ON)
      call ehrendyn_prep( Nbasis, Natoms, time, .true., Uinv, Linv, Sinv, &
                        & dens_mid, fock_mid, Bmat, Dmat, Tmat, &
                        & nucpos, nucvel, nucfor_ds, dipmom, energy )

!     Density Propagation (works in ON)
      if (propagator_id==propagator_id_verlet) then
!         print*,'This is verlet!'
         call ehrenaux_verlet( nbasis, dt, Tmat, dens_old, dens_mid, dens_newo )

      else if (propagator_id==propagator_id_magnus) then
!         print*,'This is magnus!'
         call ehrenaux_magnus( nbasis, 20, dt, Tmat, dens_mid, dens_newo )

      else
         print*,'Unidentified substep!'; stop

      endif

      if (step_back) then
         step_back = .false.
         dt = (-2.0d0) * dt
         dens_old = dens_newo
      else
         dens_old = dens_mid
         dens_mid = dens_newo
      endif

   enddo

   deallocate( Bmat, Dmat, Tmat )
   deallocate( dens_old, dens_mid )
   deallocate( dens_mao )
   deallocate( fock0 )

end subroutine ehrendyn_step
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
