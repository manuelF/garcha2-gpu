module SCF_aux
contains

subroutine neighbour_list_2e(natom, ntatom, r, d)
   ! Makes neighbour list for 2e integrals in order to give it linear
   ! scaling. Also calculates distance.
   use garcha_mod, only: natomc, jatc, rmax, nshell, atmin, nnps, nnpp, nnpd, &
                         M, nuc
   implicit none
   integer         , intent(in)    :: natom, ntatom
   double precision, intent(in)    :: r(ntatom,3)
   double precision, intent(inout) :: d(natom,natom)
   integer          :: icount, jcount
   double precision :: rexp

   do icount = 1, natom
      natomc(icount) = 0
      do jcount = 1, natom
         d(icount,jcount) = (r(icount,1)-r(jcount,1))*(r(icount,1)-r(jcount,1))&
                          + (r(icount,2)-r(jcount,2))*(r(icount,2)-r(jcount,2))&
                          + (r(icount,3)-r(jcount,3))*(r(icount,3)-r(jcount,3))
         rexp = d(icount,jcount) * atmin(icount) * atmin(jcount) &
              / atmin(icount) + atmin(jcount)
         if (rexp .lt. rmax) then
            natomc(icount) = natomc(icount) +1
            jatc(natomc(icount),icount) = jcount
         endif
      enddo
   enddo

   do icount = 1, nshell(0)
     nnps(nuc(icount)) = icount
   enddo
   do icount = nshell(0) +1, nshell(0) + nshell(1), nshell(0) +1
     nnpp(nuc(icount)) = icount
   enddo
   do icount = nshell(0) + nshell(1) +1, M
     nnpd(nuc(icount)) = icount
   enddo
end subroutine neighbour_list_2e

subroutine seek_nan(vecToTest, vecStart, vecEnd, phrase)
    implicit none
    double precision , intent(in) :: vecToTest(*)     ! Vector to analize.
    integer          , intent(in) :: vecStart, vecEnd ! Vector range to analize.
    character (len=*), intent(in) :: phrase           ! Output phrase for NaN.
    integer :: iNick

    if (vecStart .gt. vecEnd) then
        write(*,*) "Error: vector start index greater than end index."
        write(*,*) phrase
        stop
    endif

    do iNick = vecStart, vecEnd
        if (vecToTest(iNick) .ne. vecToTest(iNick)) then
            write(*,*) "NaN found in: ", phrase, iNick
            stop
        end if
    enddo
end subroutine seek_nan

end module SCF_aux
