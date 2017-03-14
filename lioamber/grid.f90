!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
!%% GRID.F90 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
! Dario Original - 12/February/1993                                            !
! This is a subroutine to generate and store angular grids points and weights  !
! for 50 and 116 angular points. Lebedev (Becke's method).                     !
!%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%!
subroutine gridlio
   use garcha_mod, only : e_, e_2, e3, Rm2, Nr, Nr2, wang, wang2, wang3, pi
   implicit none

   real*8, dimension(0:54) :: Rm2t, Nrt, Nr2t
   real*8 :: el, emgrid, p1, pi4, q1, r1, sq2, ssq3, u1, w1
   integer :: i, k

   ! Slater's radii
   data Rm2t /1.00, 0.35, 0.93, 1.45, 1.05, 0.85, 0.70, 0.65, 0.60, 0.50, 0.71,&
              3.60, 1.50, 1.25, 1.10, 1.00, 1.00, 1.00, 2.00, 2.20, 1.80, 1.60,&
              1.40, 1.35, 1.40, 1.40, 1.40, 1.35, 1.35, 1.35, 1.35, 1.30, 1.25,&
              1.15, 1.15, 1.15, 1.15, 2.35, 2.00, 1.80, 1.55, 1.45, 1.45, 1.35,&
              1.30, 1.35, 1.40, 1.60, 1.55, 1.55, 1.45, 1.45, 1.40, 1.40, 1.31/

   ! Number of shells for Least-Squares Fit
   data Nrt  /20, 20, 20, 25, 25, 25, 25, 25, 25, 25, 25, 30, 30, 30, 30, 30, &
              30, 30, 30, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, &
              35, 35, 35, 35, 35, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, &
              40, 40, 40, 40, 40, 40, 40/

   data Nr2t /30, 30, 30, 35, 35, 35, 35, 35, 35, 35, 35, 40, 40, 40, 40, 40, &
              40, 40, 40, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, &
              45, 45, 45, 45, 45, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, &
              50, 50, 50, 50, 50, 50, 50/

   do i = 0, 54
      Rm2(i) = Rm2t(i) / (2.D0*0.529177D0)
      Nr(i)  = Nrt(i)
      Nr2(i) = Nr2t(i)
   enddo

   pi4  = 4.D0 * pi
   sq2  = sqrt(0.5000000000000D0)
   ssq3 = 1.D0 / sqrt(3.D0)
   e_   = 0.0D0
   e_2  = 0.0D0
   e3   = 0.0D0
   


   ! Construction of angular grid #1 : 50 angular points per shell.
   ! Lebedev , Zh.Mat. Mat. Fiz. 15,1,48 (1975)
   emgrid = 0.904534033733D0
   el     = 0.301511344578D0
   
   do i = 1 , 6  ; wang(i) = 0.0126984126985D0 ; enddo
   do i = 7 , 18 ; wang(i) = 0.0225749559083D0 ; enddo
   do i = 19, 26 ; wang(i) = 0.02109375D0      ; enddo
   do i = 27, 50 ; wang(i) = 0.0201733355379D0 ; enddo
   wang = wang*pi4

   e_(1,3) =  1.D0 ; e_(2,3) = -1.D0 ; e_(3,2) =  1.D0
   e_(4,2) = -1.D0 ; e_(5,1) =  1.D0 ; e_(6,1) = -1.D0

   e_(7 ,1) =  sq2 ; e_(7 ,2) =  sq2 ; e_(8, 1) =  sq2
   e_(8 ,2) = -sq2 ; e_(9 ,1) = -sq2 ; e_(9, 2) = -sq2
   e_(10,1) = -sq2 ; e_(10,2) =  sq2 ; e_(11,1) =  sq2
   e_(11,3) =  sq2 ; e_(12,1) =  sq2 ; e_(12,3) = -sq2
   e_(13,1) = -sq2 ; e_(13,3) = -sq2 ; e_(14,1) = -sq2
   e_(14,3) =  sq2 ; e_(15,2) =  sq2 ; e_(15,3) =  sq2
   e_(16,2) =  sq2 ; e_(16,3) = -sq2 ; e_(17,2) = -sq2
   e_(17,3) = -sq2 ; e_(18,2) = -sq2 ; e_(18,3) =  sq2
 
   e_(19,1) =  ssq3 ; e_(19,2) =  ssq3 ; e_(19,3) =  ssq3
   e_(20,1) = -ssq3 ; e_(20,2) =  ssq3 ; e_(20,3) =  ssq3
   e_(21,1) = -ssq3 ; e_(21,2) = -ssq3 ; e_(21,3) =  ssq3
   e_(22,1) = -ssq3 ; e_(22,2) = -ssq3 ; e_(22,3) = -ssq3
   e_(23,1) =  ssq3 ; e_(23,2) = -ssq3 ; e_(23,3) = -ssq3
   e_(24,1) =  ssq3 ; e_(24,2) = -ssq3 ; e_(24,3) =  ssq3
   e_(25,1) =  ssq3 ; e_(25,2) =  ssq3 ; e_(25,3) = -ssq3
   e_(26,1) = -ssq3 ; e_(26,2) =  ssq3 ; e_(26,3) = -ssq3
 
   e_(27,1) =  el ; e_(27,2) =  el ; e_(27,3) =  emgrid
   e_(28,1) = -el ; e_(28,2) =  el ; e_(28,3) =  emgrid
   e_(29,1) = -el ; e_(29,2) = -el ; e_(29,3) =  emgrid
   e_(30,1) = -el ; e_(30,2) = -el ; e_(30,3) = -emgrid
   e_(31,1) =  el ; e_(31,2) = -el ; e_(31,3) = -emgrid
   e_(32,1) =  el ; e_(32,2) = -el ; e_(32,3) =  emgrid
   e_(33,1) =  el ; e_(33,2) =  el ; e_(33,3) = -emgrid
   e_(34,1) = -el ; e_(34,2) =  el ; e_(34,3) = -emgrid

   e_(35,1) =  el ; e_(35,2) =  emgrid ; e_(35,3) =  el
   e_(36,1) = -el ; e_(36,2) =  emgrid ; e_(36,3) =  el
   e_(37,1) = -el ; e_(37,2) = -emgrid ; e_(37,3) =  el
   e_(38,1) = -el ; e_(38,2) = -emgrid ; e_(38,3) = -el
   e_(39,1) =  el ; e_(39,2) = -emgrid ; e_(39,3) = -el
   e_(40,1) =  el ; e_(40,2) = -emgrid ; e_(40,3) =  el
   e_(41,1) =  el ; e_(41,2) =  emgrid ; e_(41,3) = -el
   e_(42,1) = -el ; e_(42,2) =  emgrid ; e_(42,3) = -el

   e_(43,1) =  emgrid ; e_(43,2) =  el; e_(43,3) =  el
   e_(44,1) = -emgrid ; e_(44,2) =  el; e_(44,3) =  el
   e_(45,1) = -emgrid ; e_(45,2) = -el; e_(45,3) =  el
   e_(46,1) = -emgrid ; e_(46,2) = -el; e_(46,3) = -el
   e_(47,1) =  emgrid ; e_(47,2) = -el; e_(47,3) = -el
   e_(48,1) =  emgrid ; e_(48,2) = -el; e_(48,3) =  el
   e_(49,1) =  emgrid ; e_(49,2) =  el; e_(49,3) = -el
   e_(50,1) = -emgrid ; e_(50,2) =  el; e_(50,3) = -el

   ! Construction of angular grid #2 : 116 angular points per shell.
   ! Lebedev , Zh.Mat. Mat. Fiz. 15,1,48 (1975)
   emgrid = 0.973314565209D0
   el     = 0.162263300152D0
   e_2    = 0.0D0

   do i = 1 , 12 ; wang2(i) = 0.00200918797730D0; enddo
   do i = 13, 20 ; wang2(i) = 0.00988550016044D0; enddo
   do i = 21, 44 ; wang2(i) = 0.00844068048232D0; enddo
   do i = 45, 68 ; wang2(i) = 0.00987390742389D0; enddo
   do i = 69, 92 ; wang2(i) = 0.0093573216900D0 ; enddo
   do i = 93, 116; wang2(i) = 0.00969499636166D0; enddo
   wang2 = wang2 * pi4
 
   e_2(1 ,1) =  sq2 ; e_2(1 ,2) =  sq2 ; e_2(2 ,1) =  sq2
   e_2(2 ,2) = -sq2 ; e_2(3 ,1) = -sq2 ; e_2(3 ,2) = -sq2
   e_2(4 ,1) = -sq2 ; e_2(4 ,2) =  sq2 ; e_2(5 ,1) =  sq2
   e_2(5 ,3) =  sq2 ; e_2(6 ,1) =  sq2 ; e_2(6 ,3) = -sq2
   e_2(7 ,1) = -sq2 ; e_2(7 ,3) = -sq2 ; e_2(8 ,1) = -sq2
   e_2(8 ,3) =  sq2 ; e_2(9 ,2) =  sq2 ; e_2(9 ,3) =  sq2
   e_2(10,2) =  sq2 ; e_2(10,3) = -sq2 ; e_2(11,2) = -sq2
   e_2(11,3) = -sq2 ; e_2(12,2) = -sq2 ; e_2(12,3) =  sq2

   e_2(13,1) =  ssq3 ; e_2(13,2) =  ssq3 ; e_2(13,3) =  ssq3
   e_2(14,1) = -ssq3 ; e_2(14,2) =  ssq3 ; e_2(14,3) =  ssq3
   e_2(15,1) = -ssq3 ; e_2(15,2) = -ssq3 ; e_2(15,3) =  ssq3
   e_2(16,1) = -ssq3 ; e_2(16,2) = -ssq3 ; e_2(16,3) = -ssq3
   e_2(17,1) =  ssq3 ; e_2(17,2) = -ssq3 ; e_2(17,3) = -ssq3
   e_2(18,1) =  ssq3 ; e_2(18,2) = -ssq3 ; e_2(18,3) =  ssq3
   e_2(19,1) =  ssq3 ; e_2(19,2) =  ssq3 ; e_2(19,3) = -ssq3
   e_2(20,1) = -ssq3 ; e_2(20,2) =  ssq3 ; e_2(20,3) = -ssq3

   e_2(21,1) =  el ; e_2(21,2) =  el ; e_2(21,3) =  emgrid
   e_2(22,1) = -el ; e_2(22,2) =  el ; e_2(22,3) =  emgrid
   e_2(23,1) = -el ; e_2(23,2) = -el ; e_2(23,3) =  emgrid
   e_2(24,1) = -el ; e_2(24,2) = -el ; e_2(24,3) = -emgrid
   e_2(25,1) =  el ; e_2(25,2) = -el ; e_2(25,3) = -emgrid
   e_2(26,1) =  el ; e_2(26,2) = -el ; e_2(26,3) =  emgrid
   e_2(27,1) =  el ; e_2(27,2) =  el ; e_2(27,3) = -emgrid
   e_2(28,1) = -el ; e_2(28,2) =  el ; e_2(28,3) = -emgrid

   e_2(29,1) =  el ; e_2(29,2) =  emgrid ; e_2(29,3) =  el
   e_2(30,1) = -el ; e_2(30,2) =  emgrid ; e_2(30,3) =  el
   e_2(31,1) = -el ; e_2(31,2) = -emgrid ; e_2(31,3) =  el
   e_2(32,1) = -el ; e_2(32,2) = -emgrid ; e_2(32,3) = -el
   e_2(33,1) =  el ; e_2(33,2) = -emgrid ; e_2(33,3) = -el
   e_2(34,1) =  el ; e_2(34,2) = -emgrid ; e_2(34,3) =  el
   e_2(35,1) =  el ; e_2(35,2) =  emgrid ; e_2(35,3) = -el
   e_2(36,1) = -el ; e_2(36,2) =  emgrid ; e_2(36,3) = -el

   e_2(37,1) =  emgrid ; e_2(37,2) =  el ; e_2(37,3) =  el
   e_2(38,1) = -emgrid ; e_2(38,2) =  el ; e_2(38,3) =  el
   e_2(39,1) = -emgrid ; e_2(39,2) = -el ; e_2(39,3) =  el
   e_2(40,1) = -emgrid ; e_2(40,2) = -el ; e_2(40,3) = -el
   e_2(41,1) =  emgrid ; e_2(41,2) = -el ; e_2(41,3) = -el
   e_2(42,1) =  emgrid ; e_2(42,2) = -el ; e_2(42,3) =  el
   e_2(43,1) =  emgrid ; e_2(43,2) =  el ; e_2(43,3) = -el
   e_2(44,1) = -emgrid ; e_2(44,2) =  el ; e_2(44,3) = -el

   emgrid = 0.840255982384D0
   el     = 0.383386152638D0
 
   e_2(45,1) =  el ; e_2(45,2) =  el ; e_2(45,3) =  emgrid
   e_2(46,1) = -el ; e_2(46,2) =  el ; e_2(46,3) =  emgrid
   e_2(47,1) = -el ; e_2(47,2) = -el ; e_2(47,3) =  emgrid
   e_2(48,1) = -el ; e_2(48,2) = -el ; e_2(48,3) = -emgrid
   e_2(49,1) =  el ; e_2(49,2) = -el ; e_2(49,3) = -emgrid
   e_2(50,1) =  el ; e_2(50,2) = -el ; e_2(50,3) =  emgrid
   e_2(51,1) =  el ; e_2(51,2) =  el ; e_2(51,3) = -emgrid
   e_2(52,1) = -el ; e_2(52,2) =  el ; e_2(52,3) = -emgrid

   e_2(53,1) =  el ; e_2(53,2) =  emgrid ; e_2(53,3) =  el
   e_2(54,1) = -el ; e_2(54,2) =  emgrid ; e_2(54,3) =  el
   e_2(55,1) = -el ; e_2(55,2) = -emgrid ; e_2(55,3) =  el
   e_2(56,1) = -el ; e_2(56,2) = -emgrid ; e_2(56,3) = -el
   e_2(57,1) =  el ; e_2(57,2) = -emgrid ; e_2(57,3) = -el
   e_2(58,1) =  el ; e_2(58,2) = -emgrid ; e_2(58,3) =  el
   e_2(59,1) =  el ; e_2(59,2) =  emgrid ; e_2(59,3) = -el
   e_2(60,1) = -el ; e_2(60,2) =  emgrid ; e_2(60,3) = -el

   e_2(61,1) =  emgrid ; e_2(61,2) =  el ; e_2(61,3) =  el
   e_2(62,1) = -emgrid ; e_2(62,2) =  el ; e_2(62,3) =  el
   e_2(63,1) = -emgrid ; e_2(63,2) = -el ; e_2(63,3) =  el
   e_2(64,1) = -emgrid ; e_2(64,2) = -el ; e_2(64,3) = -el
   e_2(65,1) =  emgrid ; e_2(65,2) = -el ; e_2(65,3) = -el
   e_2(66,1) =  emgrid ; e_2(66,2) = -el ; e_2(66,3) =  el
   e_2(67,1) =  emgrid ; e_2(67,2) =  el ; e_2(67,3) = -el
   e_2(68,1) = -emgrid ; e_2(68,2) =  el ; e_2(68,3) = -el

   emgrid = 0.238807866929D0
   el     = 0.686647945709D0

   e_2(69,1) =  el ; e_2(69,2) =  el ; e_2(69,3) =  emgrid
   e_2(70,1) = -el ; e_2(70,2) =  el ; e_2(70,3) =  emgrid
   e_2(71,1) = -el ; e_2(71,2) = -el ; e_2(71,3) =  emgrid
   e_2(72,1) = -el ; e_2(72,2) = -el ; e_2(72,3) = -emgrid
   e_2(73,1) =  el ; e_2(73,2) = -el ; e_2(73,3) = -emgrid
   e_2(74,1) =  el ; e_2(74,2) = -el ; e_2(74,3) =  emgrid
   e_2(75,1) =  el ; e_2(75,2) =  el ; e_2(75,3) = -emgrid
   e_2(76,1) = -el ; e_2(76,2) =  el ; e_2(76,3) = -emgrid

   e_2(77,1) =  el ; e_2(77,2) =  emgrid ; e_2(77,3) =  el
   e_2(78,1) = -el ; e_2(78,2) =  emgrid ; e_2(78,3) =  el
   e_2(79,1) = -el ; e_2(79,2) = -emgrid ; e_2(79,3) =  el
   e_2(80,1) = -el ; e_2(80,2) = -emgrid ; e_2(80,3) = -el
   e_2(81,1) =  el ; e_2(81,2) = -emgrid ; e_2(81,3) = -el
   e_2(82,1) =  el ; e_2(82,2) = -emgrid ; e_2(82,3) =  el
   e_2(83,1) =  el ; e_2(83,2) =  emgrid ; e_2(83,3) = -el
   e_2(84,1) = -el ; e_2(84,2) =  emgrid ; e_2(84,3) = -el

   e_2(85,1) =  emgrid ; e_2(85,2) =  el ; e_2(85,3) =  el
   e_2(86,1) = -emgrid ; e_2(86,2) =  el ; e_2(86,3) =  el
   e_2(87,1) = -emgrid ; e_2(87,2) = -el ; e_2(87,3) =  el
   e_2(88,1) = -emgrid ; e_2(88,2) = -el ; e_2(88,3) = -el
   e_2(89,1) =  emgrid ; e_2(89,2) = -el ; e_2(89,3) = -el
   e_2(90,1) =  emgrid ; e_2(90,2) = -el ; e_2(90,3) =  el
   e_2(91,1) =  emgrid ; e_2(91,2) =  el ; e_2(91,3) = -el
   e_2(92,1) = -emgrid ; e_2(92,2) =  el ; e_2(92,3) = -el

   p1 = 0.878158910604D0
   q1 = 0.478369028812D0

   e_2(93 ,1) =  p1 ; e_2(93 ,2) =  q1 ; e_2(94 ,1) =  p1
   e_2(94 ,2) = -q1 ; e_2(95 ,1) = -p1 ; e_2(95 ,2) = -q1
   e_2(96 ,1) = -p1 ; e_2(96 ,2) =  q1 ; e_2(97 ,1) =  p1
   e_2(97 ,3) =  q1 ; e_2(98 ,1) =  p1 ; e_2(98 ,3) = -q1
   e_2(99 ,1) = -p1 ; e_2(99 ,3) = -q1 ; e_2(100,1) = -p1
   e_2(100,3) =  q1 ; e_2(101,2) =  p1 ; e_2(101,3) =  q1
   e_2(102,2) =  p1 ; e_2(102,3) = -q1 ; e_2(103,2) = -p1
   e_2(103,3) = -q1 ; e_2(104,2) = -p1 ; e_2(104,3) =  q1
 
   e_2(105,1) =  q1 ; e_2(105,2) =  p1 ; e_2(106,1) =  q1
   e_2(106,2) = -p1 ; e_2(107,1) = -q1 ; e_2(107,2) = -p1
   e_2(108,1) = -q1 ; e_2(108,2) =  p1 ; e_2(109,1) =  q1
   e_2(109,3) =  p1 ; e_2(110,1) =  q1 ; e_2(110,3) = -p1
   e_2(111,1) = -q1 ; e_2(111,3) = -p1 ; e_2(112,1) = -q1
   e_2(112,3) =  p1 ; e_2(113,2) =  q1 ; e_2(113,3) =  p1
   e_2(114,2) =  q1 ; e_2(114,3) = -p1 ; e_2(115,2) = -q1
   e_2(115,3) = -p1 ; e_2(116,2) = -q1 ; e_2(116,3) =  p1

   ! Construction of angular grid #3 : 194 angular points per shell.
   ! Lebedev , Zh.Mat. Mat. Fiz. 16,2,293 (1976)
   do i = 1  , 6  ; wang3(i) = 0.00178234044724D0 ; enddo
   do i = 7  , 18 ; wang3(i) = 0.00571690594988D0 ; enddo
   do i = 19 , 26 ; wang3(i) = 0.00557338317884D0 ; enddo
   do i = 27 , 50 ; wang3(i) = 0.00551877146727D0 ; enddo
   do i = 51 , 74 ; wang3(i) = 0.00515823771181D0 ; enddo
   do i = 75 , 98 ; wang3(i) = 0.00560870408259D0 ; enddo
   do i = 99 , 122; wang3(i) = 0.00410677702817D0 ; enddo
   do i = 123, 146; wang3(i) = 0.00505184606462D0 ; enddo
   do i = 147, 194; wang3(i) = 0.00553024891623D0 ; enddo
   wang3 = wang3 * pi4
 
   e3(1,3) =  1.D0 ; e3(2,3)= -1.D0 ; e3(3,2) =  1.D0
   e3(4,2) = -1.D0 ; e3(5,1)=  1.D0 ; e3(6,1) = -1.D0

   e3(7 ,1) =  sq2 ; e3(7 ,2) =  sq2 ; e3(8 ,1) =  sq2
   e3(8 ,2) = -sq2 ; e3(9 ,1) = -sq2 ; e3(9 ,2) = -sq2
   e3(10,1) = -sq2 ; e3(10,2) =  sq2 ; e3(11,1) =  sq2
   e3(11,3) =  sq2 ; e3(12,1) =  sq2 ; e3(12,3) = -sq2
   e3(13,1) = -sq2 ; e3(13,3) = -sq2 ; e3(14,1) = -sq2
   e3(14,3) =  sq2 ; e3(15,2) =  sq2 ; e3(15,3) =  sq2
   e3(16,2) =  sq2 ; e3(16,3) = -sq2 ; e3(17,2) = -sq2
   e3(17,3) = -sq2 ; e3(18,2) = -sq2 ; e3(18,3) =  sq2

   e3(19,1) =  ssq3 ; e3(19,2) =  ssq3 ; e3(19,3) =  ssq3
   e3(20,1) = -ssq3 ; e3(20,2) =  ssq3 ; e3(20,3) =  ssq3
   e3(21,1) = -ssq3 ; e3(21,2) = -ssq3 ; e3(21,3) =  ssq3
   e3(22,1) = -ssq3 ; e3(22,2) = -ssq3 ; e3(22,3) = -ssq3
   e3(23,1) =  ssq3 ; e3(23,2) = -ssq3 ; e3(23,3) = -ssq3
   e3(24,1) =  ssq3 ; e3(24,2) = -ssq3 ; e3(24,3) =  ssq3
   e3(25,1) =  ssq3 ; e3(25,2) =  ssq3 ; e3(25,3) = -ssq3
   e3(26,1) = -ssq3 ; e3(26,2) =  ssq3 ; e3(26,3) = -ssq3

   emgrid = 0.777493219315D0
   el     = 0.444693317871D0

   e3(27,1) =  el ; e3(27,2) =  el ; e3(27,3) =  emgrid
   e3(28,1) = -el ; e3(28,2) =  el ; e3(28,3) =  emgrid
   e3(29,1) = -el ; e3(29,2) = -el ; e3(29,3) =  emgrid
   e3(30,1) = -el ; e3(30,2) = -el ; e3(30,3) = -emgrid
   e3(31,1) =  el ; e3(31,2) = -el ; e3(31,3) = -emgrid
   e3(32,1) =  el ; e3(32,2) = -el ; e3(32,3) =  emgrid
   e3(33,1) =  el ; e3(33,2) =  el ; e3(33,3) = -emgrid
   e3(34,1) = -el ; e3(34,2) =  el ; e3(34,3) = -emgrid

   e3(35,1) =  el ; e3(35,2) =  emgrid ; e3(35,3) =  el
   e3(36,1) = -el ; e3(36,2) =  emgrid ; e3(36,3) =  el
   e3(37,1) = -el ; e3(37,2) = -emgrid ; e3(37,3) =  el
   e3(38,1) = -el ; e3(38,2) = -emgrid ; e3(38,3) = -el
   e3(39,1) =  el ; e3(39,2) = -emgrid ; e3(39,3) = -el
   e3(40,1) =  el ; e3(40,2) = -emgrid ; e3(40,3) =  el
   e3(41,1) =  el ; e3(41,2) =  emgrid ; e3(41,3) = -el
   e3(42,1) = -el ; e3(42,2) =  emgrid ; e3(42,3) = -el

   e3(43,1) =  emgrid ; e3(43,2) =  el ; e3(43,3) =  el
   e3(44,1) = -emgrid ; e3(44,2) =  el ; e3(44,3) =  el
   e3(45,1) = -emgrid ; e3(45,2) = -el ; e3(45,3) =  el
   e3(46,1) = -emgrid ; e3(46,2) = -el ; e3(46,3) = -el
   e3(47,1) =  emgrid ; e3(47,2) = -el ; e3(47,3) = -el
   e3(48,1) =  emgrid ; e3(48,2) = -el ; e3(48,3) =  el
   e3(49,1) =  emgrid ; e3(49,2) =  el ; e3(49,3) = -el
   e3(50,1) = -emgrid ; e3(50,2) =  el ; e3(50,3) = -el

   emgrid = 0.912509096867D0
   el     = 0.289246562758D0

   e3(51,1) =  el ; e3(51,2) =  el ; e3(51,3) =  emgrid
   e3(52,1) = -el ; e3(52,2) =  el ; e3(52,3) =  emgrid
   e3(53,1) = -el ; e3(53,2) = -el ; e3(53,3) =  emgrid
   e3(54,1) = -el ; e3(54,2) = -el ; e3(54,3) = -emgrid
   e3(55,1) =  el ; e3(55,2) = -el ; e3(55,3) = -emgrid
   e3(56,1) =  el ; e3(56,2) = -el ; e3(56,3) =  emgrid
   e3(57,1) =  el ; e3(57,2) =  el ; e3(57,3) = -emgrid
   e3(58,1) = -el ; e3(58,2) =  el ; e3(58,3) = -emgrid

   e3(59,1) =  el ; e3(59,2) =  emgrid ; e3(59,3) =  el
   e3(60,1) = -el ; e3(60,2) =  emgrid ; e3(60,3) =  el
   e3(61,1) = -el ; e3(61,2) = -emgrid ; e3(61,3) =  el
   e3(62,1) = -el ; e3(62,2) = -emgrid ; e3(62,3) = -el
   e3(63,1) =  el ; e3(63,2) = -emgrid ; e3(63,3) = -el
   e3(64,1) =  el ; e3(64,2) = -emgrid ; e3(64,3) =  el
   e3(65,1) =  el ; e3(65,2) =  emgrid ; e3(65,3) = -el
   e3(66,1) = -el ; e3(66,2) =  emgrid ; e3(66,3) = -el

   e3(67,1) =  emgrid ; e3(67,2) =  el ; e3(67,3) =  el
   e3(68,1) = -emgrid ; e3(68,2) =  el ; e3(68,3) =  el
   e3(69,1) = -emgrid ; e3(69,2) = -el ; e3(69,3) =  el
   e3(70,1) = -emgrid ; e3(70,2) = -el ; e3(70,3) = -el
   e3(71,1) =  emgrid ; e3(71,2) = -el ; e3(71,3) = -el
   e3(72,1) =  emgrid ; e3(72,2) = -el ; e3(72,3) =  el
   e3(73,1) =  emgrid ; e3(73,2) =  el ; e3(73,3) = -el
   e3(74,1) = -emgrid ; e3(74,2) =  el ; e3(74,3) = -el

   emgrid = 0.314196994183D0
   el     = 0.671297344270D0

   e3(75,1) =  el ; e3(75,2) =  el ; e3(75,3) =  emgrid
   e3(76,1) = -el ; e3(76,2) =  el ; e3(76,3) =  emgrid
   e3(77,1) = -el ; e3(77,2) = -el ; e3(77,3) =  emgrid
   e3(78,1) = -el ; e3(78,2) = -el ; e3(78,3) = -emgrid
   e3(79,1) =  el ; e3(79,2) = -el ; e3(79,3) = -emgrid
   e3(80,1) =  el ; e3(80,2) = -el ; e3(80,3) =  emgrid
   e3(81,1) =  el ; e3(81,2) =  el ; e3(81,3) = -emgrid
   e3(82,1) = -el ; e3(82,2) =  el ; e3(82,3) = -emgrid

   e3(83,1) =  el ; e3(83,2) =  emgrid ; e3(83,3) =  el
   e3(84,1) = -el ; e3(84,2) =  emgrid ; e3(84,3) =  el
   e3(85,1) = -el ; e3(85,2) = -emgrid ; e3(85,3) =  el
   e3(86,1) = -el ; e3(86,2) = -emgrid ; e3(86,3) = -el
   e3(87,1) =  el ; e3(87,2) = -emgrid ; e3(87,3) = -el
   e3(88,1) =  el ; e3(88,2) = -emgrid ; e3(88,3) =  el
   e3(89,1) =  el ; e3(89,2) =  emgrid ; e3(89,3) = -el
   e3(90,1) = -el ; e3(90,2) =  emgrid ; e3(90,3) = -el

   e3(91,1) =  emgrid ; e3(91,2) =  el ; e3(91,3) =  el
   e3(92,1) = -emgrid ; e3(92,2) =  el ; e3(92,3) =  el
   e3(93,1) = -emgrid ; e3(93,2) = -el ; e3(93,3) =  el
   e3(94,1) = -emgrid ; e3(94,2) = -el ; e3(94,3) = -el
   e3(95,1) =  emgrid ; e3(95,2) = -el ; e3(95,3) = -el
   e3(96,1) =  emgrid ; e3(96,2) = -el ; e3(96,3) =  el
   e3(97,1) =  emgrid ; e3(97,2) =  el ; e3(97,3) = -el
   e3(98,1) = -emgrid ; e3(98,2) =  el ; e3(98,3) = -el

   emgrid = 0.982972302707D0
   el     = 0.129933544765D0

   e3(99 ,1) =  el ; e3(99 ,2) =  el ; e3(99 ,3) =  emgrid
   e3(100,1) = -el ; e3(100,2) =  el ; e3(100,3) =  emgrid
   e3(101,1) = -el ; e3(101,2) = -el ; e3(101,3) =  emgrid
   e3(102,1) = -el ; e3(102,2) = -el ; e3(102,3) = -emgrid
   e3(103,1) =  el ; e3(103,2) = -el ; e3(103,3) = -emgrid
   e3(104,1) =  el ; e3(104,2) = -el ; e3(104,3) =  emgrid
   e3(105,1) =  el ; e3(105,2) =  el ; e3(105,3) = -emgrid
   e3(106,1) = -el ; e3(106,2) =  el ; e3(106,3) = -emgrid

   e3(107,1) =  el ; e3(107,2) =  emgrid ; e3(107,3) =  el
   e3(108,1) = -el ; e3(108,2) =  emgrid ; e3(108,3) =  el
   e3(109,1) = -el ; e3(109,2) = -emgrid ; e3(109,3) =  el
   e3(110,1) = -el ; e3(110,2) = -emgrid ; e3(110,3) = -el
   e3(111,1) =  el ; e3(111,2) = -emgrid ; e3(111,3) = -el
   e3(112,1) =  el ; e3(112,2) = -emgrid ; e3(112,3) =  el
   e3(113,1) =  el ; e3(113,2) =  emgrid ; e3(113,3) = -el
   e3(114,1) = -el ; e3(114,2) =  emgrid ; e3(114,3) = -el

   e3(115,1) =  emgrid ; e3(115,2) =  el ; e3(115,3) =  el
   e3(116,1) = -emgrid ; e3(116,2) =  el ; e3(116,3) =  el
   e3(117,1) = -emgrid ; e3(117,2) = -el ; e3(117,3) =  el
   e3(118,1) = -emgrid ; e3(118,2) = -el ; e3(118,3) = -el
   e3(119,1) =  emgrid ; e3(119,2) = -el ; e3(119,3) = -el
   e3(120,1) =  emgrid ; e3(120,2) = -el ; e3(120,3) =  el
   e3(121,1) =  emgrid ; e3(121,2) =  el ; e3(121,3) = -el
   e3(122,1) = -emgrid ; e3(122,2) =  el ; e3(122,3) = -el

   p1 = 0.938319218138D0
   q1 = 0.345770219761D0

   e3(123,1) =  p1 ; e3(123,2) =  q1 ; e3(124,1) =  p1
   e3(124,2) = -q1 ; e3(125,1) = -p1 ; e3(125,2) = -q1
   e3(126,1) = -p1 ; e3(126,2) =  q1 ; e3(127,1) =  p1
   e3(127,3) =  q1 ; e3(128,1) =  p1 ; e3(128,3) = -q1
   e3(129,1) = -p1 ; e3(129,3) = -q1 ; e3(130,1) = -p1
   e3(130,3) =  q1 ; e3(131,2) =  p1 ; e3(131,3) =  q1
   e3(132,2) =  p1 ; e3(132,3) = -q1 ; e3(133,2) = -p1
   e3(133,3) = -q1 ; e3(134,2) = -p1 ; e3(134,3) =  q1
   e3(135,1) =  q1 ; e3(135,2) =  p1 ; e3(136,1) =  q1
   e3(136,2) = -p1 ; e3(137,1) = -q1 ; e3(137,2) = -p1
   e3(138,1) = -q1 ; e3(138,2) =  p1 ; e3(139,1) =  q1
   e3(139,3) =  p1 ; e3(140,1) =  q1 ; e3(140,3) = -p1
   e3(141,1) = -q1 ; e3(141,3) = -p1 ; e3(142,1) = -q1
   e3(142,3) =  p1 ; e3(143,2) =  q1 ; e3(143,3) =  p1
   e3(144,2) =  q1 ; e3(144,3) = -p1 ; e3(145,2) = -q1
   e3(145,3) = -p1 ; e3(146,2) = -q1 ; e3(146,3) =  p1

   r1 = 0.836036015482D0
   u1 = 0.159041710538D0
   w1 = 0.525118572443D0

   e3(147,1) =  r1 ; e3(147,2) =  u1 ; e3(147,3) =  w1
   e3(148,1) =  r1 ; e3(148,2) =  u1 ; e3(148,3) = -w1
   e3(149,1) =  r1 ; e3(149,2) = -u1 ; e3(149,3) =  w1
   e3(150,1) = -r1 ; e3(150,2) =  u1 ; e3(150,3) =  w1
   e3(151,1) =  r1 ; e3(151,2) = -u1 ; e3(151,3) = -w1
   e3(152,1) = -r1 ; e3(152,2) =  u1 ; e3(152,3) = -w1
   e3(153,1) = -r1 ; e3(153,2) = -u1 ; e3(153,3) =  w1
   e3(154,1) = -r1 ; e3(154,2) = -u1 ; e3(154,3) = -w1
   e3(155,1) =  r1 ; e3(155,2) =  w1 ; e3(155,3) =  u1
   e3(156,1) =  r1 ; e3(156,2) =  w1 ; e3(156,3) = -u1
   e3(157,1) =  r1 ; e3(157,2) = -w1 ; e3(157,3) =  u1
   e3(158,1) = -r1 ; e3(158,2) =  w1 ; e3(158,3) =  u1
   e3(159,1) =  r1 ; e3(159,2) = -w1 ; e3(159,3) = -u1
   e3(160,1) = -r1 ; e3(160,2) =  w1 ; e3(160,3) = -u1
   e3(161,1) = -r1 ; e3(161,2) = -w1 ; e3(161,3) =  u1
   e3(162,1) = -r1 ; e3(162,2) = -w1 ; e3(162,3) = -u1
 
   e3(163,1) =  u1 ; e3(163,2) =  r1 ; e3(163,3) =  w1
   e3(164,1) =  u1 ; e3(164,2) =  r1 ; e3(164,3) = -w1
   e3(165,1) =  u1 ; e3(165,2) = -r1 ; e3(165,3) =  w1
   e3(166,1) = -u1 ; e3(166,2) =  r1 ; e3(166,3) =  w1
   e3(167,1) =  u1 ; e3(167,2) = -r1 ; e3(167,3) = -w1
   e3(168,1) = -u1 ; e3(168,2) =  r1 ; e3(168,3) = -w1
   e3(169,1) = -u1 ; e3(169,2) = -r1 ; e3(169,3) =  w1
   e3(170,1) = -u1 ; e3(170,2) = -r1 ; e3(170,3) = -w1
   e3(171,1) =  u1 ; e3(171,2) =  w1 ; e3(171,3) =  r1
   e3(172,1) =  u1 ; e3(172,2) =  w1 ; e3(172,3) = -r1
   e3(173,1) =  u1 ; e3(173,2) = -w1 ; e3(173,3) =  r1
   e3(174,1) = -u1 ; e3(174,2) =  w1 ; e3(174,3) =  r1
   e3(175,1) =  u1 ; e3(175,2) = -w1 ; e3(175,3) = -r1
   e3(176,1) = -u1 ; e3(176,2) =  w1 ; e3(176,3) = -r1
   e3(177,1) = -u1 ; e3(177,2) = -w1 ; e3(177,3) =  r1
   e3(178,1) = -u1 ; e3(178,2) = -w1 ; e3(178,3) = -r1

   e3(179,1) =  w1 ; e3(179,2) =  u1 ; e3(179,3) =  r1
   e3(180,1) =  w1 ; e3(180,2) =  u1 ; e3(180,3) = -r1
   e3(181,1) =  w1 ; e3(181,2) = -u1 ; e3(181,3) =  r1
   e3(182,1) = -w1 ; e3(182,2) =  u1 ; e3(182,3) =  r1
   e3(183,1) =  w1 ; e3(183,2) = -u1 ; e3(183,3) = -r1
   e3(184,1) = -w1 ; e3(184,2) =  u1 ; e3(184,3) = -r1
   e3(185,1) = -w1 ; e3(185,2) = -u1 ; e3(185,3) =  r1
   e3(186,1) = -w1 ; e3(186,2) = -u1 ; e3(186,3) = -r1
 
   e3(187,1) =  w1 ; e3(187,2) =  r1 ; e3(187,3) =  u1
   e3(188,1) =  w1 ; e3(188,2) =  r1 ; e3(188,3) = -u1
   e3(189,1) =  w1 ; e3(189,2) = -r1 ; e3(189,3) =  u1
   e3(190,1) = -w1 ; e3(190,2) =  r1 ; e3(190,3) =  u1
   e3(191,1) =  w1 ; e3(191,2) = -r1 ; e3(191,3) = -u1
   e3(192,1) = -w1 ; e3(192,2) =  r1 ; e3(192,3) = -u1
   e3(193,1) = -w1 ; e3(193,2) = -r1 ; e3(193,3) =  u1
   e3(194,1) = -w1 ; e3(194,2) = -r1 ; e3(194,3) = -u1

end subroutine gridlio
