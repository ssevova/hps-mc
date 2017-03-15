      logical function pass_point(p)
c************************************************************************
c     This function is called from sample to see if it needs to 
c     bother calculating the weight from all the different conficurations
c     You can either just return true, or have it call passcuts
c************************************************************************
      implicit none
c
c     Arguments
c
      double precision p
c
c     External
c
      logical passcuts
      external passcuts
c-----
c  Begin Code
c-----
      pass_point = .true.
c      pass_point = passcuts(p)
      end
C $B$ PASSCUTS $B$ !this is a tag for MadWeight
      LOGICAL FUNCTION PASSCUTS(P)
C $E$ PASSCUTS $E$ !this is a tag for MadWeight
C**************************************************************************
C     INPUT:
C            P(0:3,1)           MOMENTUM OF INCOMING PARTON
C            P(0:3,2)           MOMENTUM OF INCOMING PARTON
C            P(0:3,3)           MOMENTUM OF d
C            P(0:3,4)           MOMENTUM OF b
C            P(0:3,5)           MOMENTUM OF bbar
C            P(0:3,6)           MOMENTUM OF e+
C            P(0:3,7)           MOMENTUM OF ve
C            COMMON/JETCUTS/   CUTS ON JETS
C     OUTPUT:
C            TRUE IF EVENTS PASSES ALL CUTS LISTED
C**************************************************************************
      IMPLICIT NONE
c
c     Constants
c
      include 'genps.inc'
C
C     ARGUMENTS
C
      REAL*8 P(0:3,nexternal)

C
C     LOCAL
C
      LOGICAL FIRSTTIME,FIRSTTIME2,pass_bw,notgood,good,foundheavy
      LOGICAL DEBUG,LOOSEDEBUG
      integer i,j,njets,hardj1,hardj2
      REAL*8 XVAR,ptmax1,ptmax2,htj,tmp
      real*8 ptemp(0:3)
      real*8 pboost(0:3), plab(0:3, nexternal)

      logical xgoodf
      Real*8 efRatVal
      integer jf

C
C     PARAMETERS
C
      real*8 PI
      parameter( PI = 3.14159265358979323846d0 )
C
C     EXTERNAL
C
      REAL*8 R2,DOT,ET,RAP,DJ,SumDot,pt,ALPHAS,theta, thetax, thetay
      logical cut_bw,setclscales
      external R2,DOT,ET,RAP,DJ,SumDot,pt,ALPHAS,cut_bw,setclscales,theta
     &         , thetax, thetay
 
C
C     GLOBAL
C
      include 'run.inc'
      include 'cuts.inc'

      double precision ptjet(nexternal)
      double precision temp

      double precision etmin(nincoming+1:nexternal),etamax(nincoming+1:nexternal)
      double precision emin(nincoming+1:nexternal)
      double precision                    r2min(nincoming+1:nexternal,nincoming+1:nexternal)
      double precision s_min(nexternal,nexternal)
      double precision etmax(nincoming+1:nexternal),etamin(nincoming+1:nexternal)
      double precision emax(nincoming+1:nexternal)
      double precision r2max(nincoming+1:nexternal,nincoming+1:nexternal)
      double precision s_max(nexternal,nexternal)
      common/to_cuts/  etmin, emin, etamax, r2min, s_min,
     $     etmax, emax, etamin, r2max, s_max

      double precision ptjmin4(4),ptjmax4(4),htjmin4(2:4),htjmax4(2:4)
      logical jetor
      common/to_jet_cuts/ ptjmin4,ptjmax4,htjmin4,htjmax4,jetor


c
c     Special cuts
c

      integer        lbw(0:nexternal)  !Use of B.W.
      common /to_BW/ lbw
C
C     SPECIAL CUTS
C
C $B$ TO_SPECISA $B$ !this is a tag for MadWeight
      LOGICAL  IS_A_J(NEXTERNAL),IS_A_L(NEXTERNAL)
      LOGICAL  IS_A_B(NEXTERNAL),IS_A_A(NEXTERNAL),IS_A_ONIUM(NEXTERNAL)
      LOGICAL  IS_A_NU(NEXTERNAL),IS_HEAVY(NEXTERNAL)
      LOGICAL  IS_A_F(NEXTERNAL)
      COMMON /TO_SPECISA/IS_A_J,IS_A_A,IS_A_L,IS_A_B,IS_A_NU,IS_HEAVY,
     . IS_A_ONIUM, IS_A_F
C $E$ TO_SPECISA $E$ !this is a tag for MadWeight

      double precision xqcutij(nexternal,nexternal),xqcuti(nexternal)
      common/to_xqcuts/xqcutij,xqcuti

      include 'coupl.inc'
C
C
c
      DATA FIRSTTIME,FIRSTTIME2/.TRUE.,.TRUE./

c put momenta in common block for couplings.f
      double precision pp(0:3,max_particles)
      common /momenta_pp/pp

      integer nfpass
      logical onepass
      logical pairpass
      integer jpass(4), k

      DATA DEBUG/.false./
      DATA LOOSEDEBUG/.FALSE./

C-----
C  BEGIN CODE
C-----


      PASSCUTS=.TRUE.             !EVENT IS OK UNLESS OTHERWISE CHANGED
      IF (FIRSTTIME) THEN
         FIRSTTIME=.FALSE.
C $B$ S-DEL $B$ !this is a MadWeight tag
c      Preparation for reweighting by setting up clustering by diagrams
         call initcluster()
C $E$ S-DEL $E$ !this is a MadWeight tag

c
c
         write(*,'(a10,10i8)') 'Particle',(i,i=nincoming+1,nexternal)
         write(*,'(a10,10f8.1)') 'Et >',(etmin(i),i=nincoming+1,nexternal)
         write(*,'(a10,10f8.1)') 'E >',(emin(i),i=nincoming+1,nexternal)
         write(*,'(a10,10f8.1)') 'Eta <',(etamax(i),i=nincoming+1,nexternal)
         do j=nincoming+1,nexternal-1
            write(*,'(a,i2,a,10f8.1)') 'd R #',j,'  >',(-0.0,i=nincoming+1,j),
     &           (r2min(i,j),i=j+1,nexternal)
            do i=j+1,nexternal
               r2min(i,j)=r2min(i,j)*dabs(r2min(i,j))    !Since r2 returns distance squared
               r2max(i,j)=r2max(i,j)*dabs(r2max(i,j))
            enddo
         enddo
         do j=nincoming+1,nexternal-1
            write(*,'(a,i2,a,10f8.1)') 's min #',j,'>',
     &           (s_min(i,j),i=nincoming+1,nexternal)
         enddo
         write(*,'(a10,10f8.1)') 'xqcut: ',(xqcuti(i),i=nincoming+1,nexternal)
         do j=nincoming+1,nexternal-1
            write(*,'(a,i2,a,10f8.1)') 'xqcutij #',j,'>',
     &           (xqcutij(i,j),i=nincoming+1,nexternal)
         enddo

cc
cc     Set the strong coupling
cc
c         call set_ren_scale(P,scale)
c
cc     Check that the user funtions for setting the scales
cc     have been edited if the choice of an event-by-event
cc     scale choice has been made 
c
c         if(.not.fixed_ren_scale) then
c            if(scale.eq.0d0) then
c               write(6,*) 
c               write(6,*) '* >>>>>>>>>ERROR<<<<<<<<<<<<<<<<<<<<<<<*'
c               write(6,*) ' Dynamical renormalization scale choice '
c               write(6,*) ' selected but user subroutine' 
c               write(6,*) ' set_ren_scale not edited in file:setpara.f'
c               write(6,*) ' Switching to a fixed_ren_scale choice'
c               write(6,*) ' with scale=zmass'
c               scale=91.2d0
c               write(6,*) 'scale=',scale
c               fixed_ren_scale=.true.
c               call set_ren_scale(P,scale)
c            endif
c         endif
         
c         if(.not.fixed_fac_scale) then
c            call set_fac_scale(P,q2fact)
c            if(q2fact(1).eq.0d0.or.q2fact(2).eq.0d0) then
c               write(6,*) 
c               write(6,*) '* >>>>>>>>>ERROR<<<<<<<<<<<<<<<<<<<<<<<*'
c               write(6,*) ' Dynamical renormalization scale choice '
c               write(6,*) ' selected but user subroutine' 
c               write(6,*) ' set_fac_scale not edited in file:setpara.f'
c               write(6,*) ' Switching to a fixed_fac_scale choice'
c               write(6,*) ' with q2fact(i)=zmass**2'
c               fixed_fac_scale=.true.
c               q2fact(1)=91.2d0**2
c               q2fact(2)=91.2d0**2
c               write(6,*) 'scales=',q2fact(1),q2fact(2)
c            endif
c         endif

         if(fixed_ren_scale) then
            G = SQRT(4d0*PI*ALPHAS(scale))
            call setpara('param_card.dat',.false.)
         endif

c     Put momenta in the common block to zero to start
         do i=0,3
            do j=1,max_particles
               pp(i,j) = 0d0
            enddo
         enddo
         
      ENDIF
c
c     Make sure have reasonable 4-momenta
c
      if (p(0,1) .le. 0d0) then
         passcuts=.false.
         return
      endif

c     Also make sure there's no INF or NAN
      do i=1,nexternal
         do j=0,3
            if(p(j,i).gt.1d32.or.p(j,i).ne.p(j,i))then
               passcuts=.false.
               return
            endif
         enddo
      enddo
c
c     Limit S_hat
c
c      if (x1*x2*stot .gt. 500**2) then
c         passcuts=.false.
c         return
c      endif


C $B$ DESACTIVATE_CUT $E$ !This is a tag for MadWeight

      if(debug) write (*,*) '============================='
      if(debug) write (*,*) ' EVENT STARTS TO BE CHECKED  '
      if(debug) write (*,*) '============================='


c****************************************     
c     Special Fixed-Target cuts
c****************************************

c.....first boost
      pboost(0)=1d0
      pboost(1)=0d0
      pboost(2)=0d0
      pboost(3)=0d0
      if (xbk(2)*xbk(1) .gt. 0d0) then
         pboost(0)=ebeam(1)+ebeam(2)
         pboost(3)=   sqrt(ebeam(1)**2-mbeam(1)**2)
     $        - sqrt(ebeam(2)**2-mbeam(2)**2)
      endif

      do j=1,nexternal
         call boostx(p(0,j),pboost,plab(0,j))
      enddo

c      goto 777
c inclusive cuts for f's      
      xgoodf=.false.
      pairpass=.false.
c ....initialize nfpass
      nfpass=0
c....no pairs yet
      do k=1,4
         jpass(k)=0
      enddo

c      write(47,*) " --evt --"
      do i=nincoming+1,nexternal
         if(is_a_f(i)) then
c            write (47,*)" xef= " ,xef, " /  e=", plab(0,i)
c            if((theta(p(0,i)) .gt. xthetaf).and.
c     $         (thetax(p(0,i)) .gt. xthetaxfmin).and.
c     $         (thetax(p(0,i)) .lt. xthetaxfmax).and.
c     $         (thetay(p(0,i)) .gt. xthetayfmin).and.
c     $         (thetay(p(0,i)) .lt. xthetayfmax)) then
c               write (47,*)" xef= " ,xef, " /  e=", p(0,i)
c            endif
c...        Does it pass inclusive criteria?            
            if(
     $         (theta(plab(0,i)) .gt. xthetaf).and.
     $         (thetax(plab(0,i)) .gt. xthetaxfmin).and.
     $         (thetax(plab(0,i)) .lt. xthetaxfmax).and.
     $         (thetay(plab(0,i)) .gt. xthetayfmin).and.
     $         (thetay(plab(0,i)) .lt. xthetayfmax).and.
     $         (plab(0,i) .gt. xef)) then
               xgoodf=.true.               
c               write (47,*) "PASS!"
            endif

            onepass=.true.
c...        Does it pass exclusive criteria?
            if(plab(0,i) .lt. ef) then
               if(debug) write(*,*) "f too soft -> fails"
               onepass=.false.
            elseif(plab(0,i) .gt. efmax) then
               if(debug) write(*,*) "f too hard -> fails"
               onepass=.false.
            elseif(theta(plab(0,i)) .lt. thetafmin) then
               if(debug) write(*,*) "f small angle -> fails"
               onepass=.false.
            elseif(theta(plab(0,i)) .gt. thetafmax) then
               if(debug) write(*,*) "f large angle -> fails"
               onepass=.false.
            elseif(thetax(plab(0,i)) .lt. thetaxfmin) then
               if(debug) write(*,*) "f small x-angle -> fails"
               onepass=.false.
            elseif(thetax(plab(0,i)) .gt. thetaxfmax) then
               if(debug) write(*,*) "f large x-angle -> fails"
               onepass=.false.
               return
            elseif(thetay(plab(0,i)) .lt. thetayfmin) then
               if(debug) write(*,*) "f small y-angle -> fails"
               onepass=.false.
            elseif(thetay(plab(0,i)) .gt. thetayfmax) then
               if(debug) write(*,*) "f large y-angle -> fails"
               onepass=.false.
            endif

            if(onepass) then
               nfpass=nfpass+1
               if(debug) write(*,*) nfpass," pass so far: ", i 
            else
               goto 666
            endif

c...        Evaluate pair. criteria            
c...        Prepare for pair. criteria            
            jpass(nfpass)=i
            if(onepass.and.nfpass.gt.1.and.(.not.pairpass)) then
               do k=1,nfpass-1
                  jf=jpass(k)

                  if(debug) write(*,*) "Checking pair ", i," ", jf
                  pairpass=.true.
                  if(dSqrt(Sumdot(plab(0,i),plab(0,jf),+1d0)).lt.mmff)then
                     if(debug) write(*,*) "mmff too small -> fails"
                     pairpass=.false.
                  elseif(dSqrt(Sumdot(plab(0,i),plab(0,jf),+1d0)).gt.mmffmax)then
                     if(debug) write(*,*) "mmff too large -> fails"
                     pairpass=.false.
c...  etot(ij) cut?
                  elseif(plab(0,i)+plab(0,jf).lt.efTot) then
                     if(debug) write(*,*) "efTot too small -> fails"
                     pairpass=.false.
                  else
c...  eratio(ij) cut?
                     efRatVal=plab(0,i)/plab(0,jf)
                     if(efRatVal.gt.1) efRatVal=1d0/efRatVal
                     if(efRatVal.lt.efRat) then
                       if(debug) write(*,*) "efRatio too small -> fails"
                       pairpass=.false.
                     endif
                  endif
               enddo
            endif               ! Close pair criteria
 666        continue
         endif ! Close if is_a_f
      enddo ! Close loop over f's

c...  Check: were inclusive criteria satisfied?      
      if(.not. xgoodf) then
         if(debug) write(*,*) "no f pass inclusive -> fails"
         passcuts=.false.
         return
      endif

      if(nfpass.lt.2) then
         if(debug) write(*,*) "no two f pass 'exclusive' -> fails"
         passcuts=.false.
         return
      endif

      if(.not.pairpass) then
         if(debug) write(*,*) "no two f pass 'pair' -> fails"
         passcuts=.false.
         return
      endif


      if(debug) write(*,*) "777 pass so far" 
      

 777  continue

                  
c     
c     p_t min & max cuts
c     
      do i=nincoming+1,nexternal
         if(debug) write (*,*) 'pt(',i,')=',pt(plab(0,i)),'   ',etmin(i),':',etmax(i)
         notgood=(pt(plab(0,i)) .le. etmin(i)).or.
     &        (pt(plab(0,i)) .gt. etmax(i))
         if (notgood) then
            if(debug) write (*,*) i,' -> fails'
            passcuts=.false.
            return
         endif
      enddo
c
c    missing ET min & max cut 
c    nb: missing et simply defined as the sum over the neutrino's 4 momenta
c
c-- reset ptemp(0:3)
      do j=0,3
         ptemp(j)=0
      enddo
c-  sum over the momenta
      do i=nincoming+1,nexternal
         if(is_a_nu(i)) then            
         if(debug) write (*,*) i,' -> neutrino '
            do j=0,3
               ptemp(j)=ptemp(j)+plab(j,i)
            enddo
         endif
      enddo
c-  check the et
      if(debug.and.ptemp(0).eq.0d0) write (*,*) 'No et miss in event'
      if(debug.and.ptemp(0).gt.0d0) write (*,*) 'Et miss =',pt(ptemp(0)),'   ',misset,':',missetmax
      if(ptemp(0).gt.0d0) then
         notgood=(pt(ptemp(0)) .lt. misset).or.
     &        (pt(ptemp(0)) .gt. missetmax)
         if (notgood) then
            if(debug) write (*,*) ' missing et cut -> fails'
            passcuts=.false.
            return
         endif
      endif
c
c     pt cut on heavy particles
c     gives min(pt) for (at least) one heavy particle
c
      if(ptheavy.gt.0d0)then
         passcuts=.false.
         foundheavy=.false.
         do i=nincoming+1,nexternal
            if(is_heavy(i)) then            
               if(debug) write (*,*) i,' -> heavy '
               foundheavy=.true.
               if(pt(plab(0,i)).gt.ptheavy) passcuts=.true.
            endif
         enddo
         
         if(.not.passcuts.and.foundheavy)then
            if(debug) write (*,*) ' heavy particle cut -> fails'
            return
         else
            passcuts=.true.
         endif
      endif
c     
c     E min & max cuts
c     
      do i=nincoming+1,nexternal
         if(debug) write (*,*) 'plab(0,',i,')=',plab(0,i),'   ',emin(i),':',emax(i)
         notgood=(plab(0,i) .le. emin(i)).or.
     &        (plab(0,i) .gt. emax(i))
         if (notgood) then
            if(debug) write (*,*) i,' -> fails'
            passcuts=.false.
            return
         endif
      enddo
c     
c     Rapidity  min & max cuts
c     
      do i=nincoming+1,nexternal
         if(debug) write (*,*) 'abs(rap(',i,'))=',abs(rap(plab(0,i))),'   ',etamin(i),':',etamax(i)
         notgood=(abs(rap(plab(0,i))) .gt. etamax(i)).or.
     &        (abs(rap(plab(0,i))) .lt. etamin(i))
         if (notgood) then
            if(debug) write (*,*) i,' -> fails'
            passcuts=.false.
            return
         endif
      enddo
c     
c     DeltaR min & max cuts
c     
      do i=nincoming+1,nexternal-1
         do j=i+1,nexternal
            if(debug) write (*,*) 'r2(',i, ',' ,j,')=',dsqrt(r2(plab(0,i),plab(0,j)))
            if(debug) write (*,*) dsqrt(r2min(j,i)),dsqrt(r2max(j,i))
            if(r2min(j,i).gt.0.or.r2max(j,i).lt.1d2) then
               tmp=r2(plab(0,i),plab(0,j))
               notgood=(tmp .lt. r2min(j,i)).or.(tmp .gt. r2max(j,i))
               if (notgood) then
                  if(debug) write (*,*) i,j,' -> fails'
                  passcuts=.false.
                  return
               endif
            endif
         enddo
      enddo
c     
c     s-channel min & max invariant mass cuts
c     
      do i=nincoming+1,nexternal-1
         do j=i+1,nexternal
            if(debug) write (*,*) 's(',i,',',j,')=',dsqrt(Sumdot(plab(0,i),plab(0,j),+1d0))
            if(debug) write (*,*) dsqrt(s_min(j,i)),dsqrt(s_max(j,i))
            if(s_min(j,i).gt.0.or.s_max(j,i).lt.1d5) then
               tmp=SumDot(plab(0,i),plab(0,j),+1d0)
               notgood=(tmp .lt. s_min(j,i).or.tmp .gt. s_max(j,i)) 
               if (notgood) then
                  if(debug) write (*,*) i,j,' -> fails'
                  passcuts=.false.
                  return
               endif
            endif
         enddo
      enddo
C     $B$S-DEL$B$ This is a Tag for MadWeight
c     
c     B.W. phase space cuts
c     
      pass_bw=cut_bw(p)
      if (lbw(0) .eq. 1) then
         if ( pass_bw ) then
            passcuts=.false.
            return
         endif
      endif
C     $E$S-DEL$E$ This is a Tag for MadWeight

C     
C     maximal and minimal pt of the jets sorted by pt
c     
      njets=0

c- fill ptjet with the pt's of the jets.
      do i=nincoming+1,nexternal
         if(is_a_j(i)) then
            njets=njets+1
            ptjet(njets)=pt(plab(0,i))
         endif
      enddo
      if(debug) write (*,*) 'not yet ordered ',njets,'   ',ptjet

c- check existance of jets if jet cuts are on
      if(njets.lt.1.and.(htjmin.gt.0.or.ptj1min.gt.0).or.
     $     njets.lt.2.and.ptj2min.gt.0.or.
     $     njets.lt.3.and.ptj3min.gt.0.or.
     $     njets.lt.4.and.ptj4min.gt.0)then
         if(debug) write (*,*) i, ' too few jets -> fails'
         passcuts=.false.
         return
      endif

c - sort jet pts
      do i=1,njets-1
         do j=i+1,njets
            if(ptjet(j).gt.ptjet(i)) then
               temp=ptjet(i)
               ptjet(i)=ptjet(j)
               ptjet(j)=temp
            endif
         enddo
      enddo
      if(debug) write (*,*) 'ordered ',njets,'   ',ptjet
c
c     Use "and" or "or" prescriptions 
c     
      if(njets.gt.0) then

       notgood=.not.jetor
       if(debug) write (*,*) 'jetor :',jetor  
       if(debug) write (*,*) '0',notgood   
      
      do i=1,njets 
            if(debug) write (*,*) i,ptjet(i), '   ',ptjmin4(min(i,4)),':',ptjmax4(min(i,4))
         if(jetor) then     
c---  if one of the jets does not pass, the event is rejected
            notgood=notgood.or.(ptjet(i).gt.ptjmax4(min(i,4))).or.
     $           (ptjet(i).lt.ptjmin4(min(i,4)))
            if(debug) write (*,*) i,' notgood total:', notgood   
         else
c---  all cuts must fail to reject the event
            notgood=notgood.and.(ptjet(i).gt.ptjmax4(min(i,4))
     $              .or.(ptjet(i).lt.ptjmin4(min(i,4))))
            if(debug) write (*,*) i,' notgood total:', notgood   
         endif
      enddo


      if (notgood) then
         if(debug) write (*,*) i, ' multiple pt -> fails'
         passcuts=.false.
         return
      endif

c---------------------------
c      Ht cuts
C---------------------------
      
      htj=ptjet(1)
      do i=2,njets
         htj=htj+ptjet(i)
         if(debug) write (*,*) i, 'htj ',htj
         if(debug) write (*,*) 'htmin ',i,' ', htjmin4(min(i,4)),':',htjmax4(min(i,4))
         if(htj.lt.htjmin4(min(i,4)) .or. htj.gt.htjmax4(min(i,4))) then
            if(debug) write (*,*) i, ' ht -> fails'
            passcuts=.false.
            return
         endif
      enddo


      if(htj.lt.htjmin.or.htj.gt.htjmax)then
         if(debug) write (*,*) i, ' htj -> fails'
         passcuts=.false.
         return
      endif

      endif !if there are jets 
      
C>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>     
C     SPECIAL CUTS
C<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

C     REQUIRE AT LEAST ONE JET WITH PT>XPTJ
         
         IF(xptj.gt.0d0) THEN
            xvar=0
            do i=nincoming+1,nexternal
               if(is_a_j(i)) xvar=max(xvar,pt(plab(0,i)))
            enddo
            if (xvar .lt. xptj) then
               passcuts=.false.
               return
            endif
         ENDIF

C     REQUIRE AT LEAST ONE PHOTON WITH PT>XPTA
         
         IF(xpta.gt.0d0) THEN
            xvar=0
            do i=nincoming+1,nexternal
               if(is_a_a(i)) xvar=max(xvar,pt(plab(0,i)))
            enddo
            if (xvar .lt. xpta) then
               passcuts=.false.
               return
            endif
         ENDIF

C     REQUIRE AT LEAST ONE B  WITH PT>XPTB
         
         IF(xptb.gt.0d0) THEN
            xvar=0
            do i=nincoming+1,nexternal
               if(is_a_b(i)) xvar=max(xvar,pt(plab(0,i)))
            enddo
            if (xvar .lt. xptb) then
               passcuts=.false.
               return
            endif
         ENDIF

C     REQUIRE AT LEAST ONE LEPTON  WITH PT>XPTL
         
         IF(xptl.gt.0d0) THEN
            xvar=0
            do i=nincoming+1,nexternal
               if(is_a_l(i)) xvar=max(xvar,pt(plab(0,i)))
            enddo
            if (xvar .lt. xptl) then
               passcuts=.false.
               return
            endif
         ENDIF
C
C     WBF CUTS: TWO TYPES
C    
C     FIRST TYPE:  implemented by FM
C
C     1. FIND THE 2 HARDEST JETS
C     2. REQUIRE |RAP(J)|>XETAMIN
C     3. REQUIRE RAP(J1)*ETA(J2)<0
C
C     SECOND TYPE : added by Simon de Visscher 1-08-2007
C
C     1. FIND THE 2 HARDEST JETS
C     2. REQUIRE |RAP(J1)-RAP(J2)|>DELTAETA
C     3. REQUIRE RAP(J1)*RAP(J2)<0
C
C
         hardj1=0
         hardj2=0
         ptmax1=0d0
         ptmax2=0d0

C-- START IF AT LEAST ONE OF THE CUTS IS ACTIVATED
         
         IF(XETAMIN.GT.0D0.OR.DELTAETA.GT.0D0) THEN
            
C-- FIND THE HARDEST JETS

            do i=nincoming+1,nexternal
               if(is_a_j(i)) then
c                  write (*,*) i,pt(plab(0,i))
                  if(pt(plab(0,i)).gt.ptmax1) then
                     hardj2=hardj1
                     ptmax2=ptmax1
                     hardj1=i
                     ptmax1=pt(plab(0,i))
                  elseif(pt(plab(0,i)).gt.ptmax2) then
                     hardj2=i
                     ptmax2=pt(plab(0,i))
                  endif
c                  write (*,*) hardj1,hardj2,ptmax1,ptmax2
               endif
            enddo
            
C-- NOW APPLY THE CUT I            

            if (abs(rap(plab(0,hardj1))) .lt. xetamin
     &       .or.abs(rap(plab(0,hardj2))) .lt. xetamin
     &       .or.rap(plab(0,hardj1))*rap(plab(0,hardj2)) .gt.0d0) then
             passcuts=.false.
             return
            endif

            
C-- NOW APPLY THE CUT II
            
            if (abs(rap(plab(0,hardj1))-rap(plab(0,hardj2))) .lt. deltaeta) then
             passcuts=.false.
             return
            endif
         
c            write (*,*) hardj1,hardj2,rap(plab(0,hardj1)),rap(plab(0,hardj2))
         
         ENDIF

C...Set couplings if event passed cuts

      if(.not.fixed_ren_scale) then
         call set_ren_scale(P,scale)
         if(scale.gt.0) G = SQRT(4d0*PI*ALPHAS(scale))
      endif

      if(.not.fixed_fac_scale) then
         call set_fac_scale(P,q2fact)
      endif

C     $B$S-DEL$B$ This is a Tag for MadWeight
c
c     Here we cluster event and reset factorization and renormalization
c     scales on an event-by-event basis, as well as check xqcut for jets
c
      if(xqcut.gt.0d0.or.ickkw.gt.0.or.scale.eq.0.or.q2fact(1).eq.0)then
        if(.not.setclscales(p))then
         passcuts=.false.
         return
       endif
      endif
C     $E$S-DEL$E$ This is a Tag for MadWeight

c     Set couplings in model files
      if(.not.fixed_ren_scale.or..not.fixed_couplings) then
         if (.not.fixed_couplings)then
            do i=0,3
               do j=1,nexternal
                  pp(i,j)=p(i,j)
               enddo
            enddo
         endif
         call setpara('param_card.dat',.false.)
      endif

      IF (FIRSTTIME2) THEN
        FIRSTTIME2=.FALSE.
        write(6,*) 'alpha_s for scale ',scale,' is ', G**2/(16d0*atan(1d0))
      ENDIF

      if(debug) write (*,*) '============================='
      if(debug) write (*,*) ' EVENT PASSED THE CUTS       '
      if(debug) write (*,*) '  passcut=',passcuts
      if(debug) write (*,*) '============================='

      if(loosedebug) write (*,*) ' EVENT PASSED THE CUTS       '


      RETURN
      END

