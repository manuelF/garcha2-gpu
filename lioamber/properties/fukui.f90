!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
!%% GET_SOFTNESS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
! Gets the molecule's global softness using the energy of HOMO/LUMO ALPHA/BETA !
! MOs. In a closed-shell context, enAH=enBH and enAL=enBL.                     !
subroutine get_softness(enAH, enAL, enBH, enBL, softness)

   implicit none
   LIODBLE, intent(in)  :: enAH, enAL, enBH, enBL
   LIODBLE, intent(out) :: softness

   softness = 4 / (enAH + enBH - enAL - enBL)
end subroutine get_softness

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
!%% FUKUI_CALC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
! Performs a closed-shell Fukui function calculation.                          !
subroutine fukui_calc_cs(fukuiRad, fukuiNeg, fukuiPos, coef, nOcc, NofM, Smat, &
                      ener)

   ! coef, nOcc      : MO basis coefficients and N° occupied MOs.     !
   ! enAlpha, enBeta : Alpha and Beta MO energies.                    !
   ! M, N, NofM, Smat: N° of basis functions, atoms, Nuclei belonging !
   !                   to each function M, overlap matrix.            !
   ! FukuiXXX        : Fukui function for radical attack (Rad),       !
   !                   electron loss (Pos) and electron gain (Neg).   !
   ! shapeX          : Shape factor for the MO of interest = Atomic   !
   !                   contributions to HOMO/LUMO MOs.                !
   ! nDegX, degMOX   : Degeneration of such MOs.                      !
   implicit none
   integer, intent(in)  :: NofM(:), nOcc
   LIODBLE, intent(in)  :: coef(:,:)  , Smat(:,:)  , ener(:) 
   LIODBLE, intent(out) :: fukuiRad(:), fukuiPos(:), fukuiNeg(:)

   integer :: ifunc, jfunc, korb, nDegH, nDegL, M, N, iatom
   LIODBLE :: dummy
   LIODBLE, allocatable :: shapeH(:), shapeL(:)
   integer, allocatable :: degMOH(:), degMOL(:)

   M = size(NofM,1)
   N = size(fukuiRad,1)

   ! Calculates MO degenerations and MOs with same energy.
   allocate(degMOH(M), degMOL(M))
   call get_degeneration(ener, nOcc   , M, nDegH, degMOH)
   call get_degeneration(ener, nOcc +1, M, nDegL, degMOL)

   ! Calculates shape factors and Spin-Polarized Fukui functions.
   allocate(shapeH(N), shapeL(N))
   shapeH = 0D0
   shapeL = 0D0

   do ifunc = 1, M
      iatom = NofM(ifunc)

      do jfunc = 1, M
         do korb = 1, nDegH
            dummy         = coef(ifunc, degMOH(korb)) *         &
                            coef(jfunc, degMOH(korb)) * Smat(ifunc,jfunc)
            shapeH(iatom) = shapeH(iatom) + dummy
         enddo
         do korb = 1, nDegL
            dummy         = coef(ifunc, degMOL(korb)) *         &
                            coef(jfunc, degMOL(korb)) * Smat(ifunc,jfunc)
            shapeL(iatom) = shapeL(iatom) + dummy
         enddo
       enddo
   enddo

   do iatom = 1, N
      fukuiNeg(iatom) = shapeH(iatom) / nDegH
      fukuiPos(iatom) = shapeL(iatom) / nDegL
      fukuiRad(iatom) = 0.5D0 * ( fukuiNeg(iatom) + fukuiPos(iatom) )
   enddo

   deallocate (degMOH, degMOL, shapeL, shapeH)
end subroutine fukui_calc_cs

!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
!%% FUKUI_CALC_OS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
! Performs an open-shell Fukui function calculation (Spin-Polarized Fukui).    !
subroutine fukui_calc_os(fukuiRad, fukuiNeg, fukuiPos, coefAlp, coefBet, &
                         nAlpha, nBeta, NofM, Smat, enAlpha, enBeta)

   ! coefAlp, coefBet: -> Alpha and Beta coefficients.                !
   ! nAlpha , nBeta  : N° occupied Alpha and Beta orbitals.           !
   ! enAlpha, enBeta : Alpha and Beta MO energies.                    !
   ! M, N, NofM, Smat: N° of basis functions, atoms, Nuclei belonging !
   !                   to each function M, overlap matrix.            !
   ! FukuiXXX        : Fukui function for radical attack (Rad),       !
   !                   electron loss (Pos) and electron gain (Neg).   !
   ! shapeXY         : Shape factor for the MO of interest = Atomic   !
   !                   contributions to HOMO/LUMO MOs.                !
   ! nDegXY, degMOXY : Degeneration of such MOs.                      !
   implicit none
   integer, intent(in)  :: NofM(M), nAlpha, nBeta
   LIODBLE, intent(in)  :: coefAlp(M,M), coefBet(M,M), Smat(M,M)
   LIODBLE, intent(in)  :: enAlpha(M)  , enBeta(M)
   LIODBLE, intent(out) :: fukuiRad(N) , fukuiPos(N) , fukuiNeg(N)
     
   integer :: ifunc, jfunc, korb, iatom, M, N
   integer :: nDegAH, nDegAL, nDegBH, nDegBL
   LIODBLE :: dummy
   LIODBLE, allocatable :: shapeAH(:), shapeAL(:), shapeBH(:), shapeBL(:)
   integer, allocatable :: degMOAH(:), degMOAL(:), degMOBH(:), degMOBL(:)

   M = size(NofM,1)
   N = size(fukuiRad,1)


   ! Calculates MO degenerations and MOs with same energy.
   allocate(degMOAH(M), degMOAL(M), degMOBH(M), degMOBL(M))
   call get_degeneration(enAlpha, nAlpha   , M, nDegAH, degMOAH)
   call get_degeneration(enAlpha, nAlpha +1, M, nDegAL, degMOAL)
   call get_degeneration(enBeta , nBeta    , M, nDegBH, degMOBH)
   call get_degeneration(enBeta , nBeta  +1, M, nDegBL, degMOBL)

   ! Calculates shape factors and Spin-Polarized Fukui functions.
   allocate(shapeAH(N), shapeAL(N), shapeBH(N), shapeBL(N))
   shapeAH = 0D0
   shapeAL = 0D0
   shapeBH = 0D0
   shapeBL = 0D0

   do ifunc = 1, M
      iatom = NofM(ifunc)

      do jfunc = 1, M
         do korb = 1, nDegAH
            dummy          = coefAlp(ifunc, degMOAH(korb)) *         &
                             coefAlp(jfunc, degMOAH(korb)) * Smat(ifunc,jfunc)
            shapeAH(iatom) = shapeAH(iatom) + dummy
         enddo
         do korb = 1, nDegAL
            dummy          = coefAlp(ifunc, degMOAL(korb)) *         &
                             coefAlp(jfunc, degMOAL(korb)) * Smat(ifunc,jfunc)
            shapeAL(iatom) = shapeAL(iatom) + dummy
         enddo
         do korb = 1, nDegBH
            dummy          = coefBet(ifunc, degMOBH(korb)) *         &
                             coefBet(jfunc, degMOBH(korb)) * Smat(ifunc,jfunc)
            shapeBH(iatom) = shapeBH(iatom) + dummy
         enddo
         do korb = 1, nDegBL
            dummy          = coefBet(ifunc, degMOBL(korb)) *         &
                             coefBet(jfunc, degMOBL(korb)) * Smat(ifunc,j)
            shapeBL(iatom) = shapeBL(iatom) + dummy
         enddo
      enddo
   enddo

   do iatom = 1, N
       fukuiNeg(iatom) = 0.5D0 * (shapeAH(iatom)/nDegAH + shapeBH(iatom)/nDegBH)
       fukuiPos(iatom) = 0.5D0 * (shapeAL(iatom)/nDegAL + shapeBL(iatom)/nDegBL)
       fukuiRad(iatom) = 0.5D0 * (fukuiNeg(iatom)       + fukuiPos(iatom)      )
   enddo 
        
   deallocate(degMOAH, degMOAL, degMOBH, degMOBL)
   deallocate(shapeAH, shapeAL, shapeBH, shapeBL)
end subroutine fukui_calc_os

! These routines are a general interface for property calculation
! and printing.
subroutine print_fukui_cs(coefs, nOcc, atom_of_func, Smat, Eorbs, atom_z)
   implicit none
   integer, intent(in)  :: atom_of_func(:), atom_z(:), nOcc
   LIODBLE, intent(in)  :: coefs(:,:), Smat(:,:), Eorbs(:) 

   LIODBLE, allocatable :: fukuin(:), fukuip(:), fukuim(:)
   LIODBLE :: softness


   call g2g_timer_sum_start("Fukui")
   allocate(fukuim(size(atom_z,1)), fukuin(size(atom_z,1)), &
            fukuip(size(atom_z,1)))

   call fukui_calc_cs(fukuin, fukuim, fukuip, coefs, nOcc, atom_of_func, Smat, &
                      Eorbs)
   call get_softness(Eorbs(nOcc-1), Eorbs(nOcc), Eorbs(nOcc-1), Eorbs(nOcc), &
                     softness)
   call write_fukui_core(fukuim, fukuip, fukuin, atom_z, softness)

   deallocate(fukuim, fukuin, fukuip)
   call g2g_timer_sum_pause("Fukui")

end subroutine print_fukui_cs

subroutine print_fukui_os(coefs, coefs_b, nOcc, nOcc_b, atom_of_func, Smat, &
                          Eorbs, Eorbs_b, atom_z)
   implicit none
   integer, intent(in)  :: atom_of_func(:), atom_z(:), nOcc, nOcc_b
   LIODBLE, intent(in)  :: coefs(:,:), coefs_b(:,:), Smat(:,:)
   LIODBLE, intent(in)  :: Eorbs(:), Eorbs_b(:)

   LIODBLE, allocatable :: fukuin(:), fukuip(:), fukuim(:)
   LIODBLE :: softness

   call g2g_timer_sum_start("Fukui")
   allocate(fukuim(size(atom_z,1)), fukuin(size(atom_z,1)), fukuip(size(atom_z,1)))

   call fukui_calc_os(coefs, coefs_b, nOcc, nOcc_b, atom_of_func, Smat, &
                      fukuim, fukuip, fukuin, Eorbs, Eorbs_b)
   call get_softness(Eorbs(nOcc-1), Eorbs(nOcc), Eorbs_b(nOcc_b-1),&
                     Eorbs(nOcc_b), softness)
   call write_fukui_core(fukuim, fukuip, fukuin, atom_z, softness)

   
   deallocate(fukuim, fukuin, fukuip)
   call g2g_timer_sum_pause("Fukui")

end subroutine print_fukui_os