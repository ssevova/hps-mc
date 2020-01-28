C     This File is Automatically generated by ALOHA 
C     The process calculated in this file is: 
C     Epsilon(1,2,-1,-2)*P(-2,1)*P(-1,3)
C     
      SUBROUTINE VVS1_1(V2, S3, COUP, M1, W1,V1)
      IMPLICIT NONE
      COMPLEX*16 CI
      PARAMETER (CI=(0D0,1D0))
      COMPLEX*16 V2(*)
      COMPLEX*16 S3(*)
      REAL*8 P1(0:3)
      REAL*8 M1
      REAL*8 P3(0:3)
      REAL*8 W1
      COMPLEX*16 DENOM
      COMPLEX*16 COUP
      COMPLEX*16 V1(6)
      P3(0) = DBLE(S3(1))
      P3(1) = DBLE(S3(2))
      P3(2) = DIMAG(S3(2))
      P3(3) = DIMAG(S3(1))
      V1(1) = +V2(1)+S3(1)
      V1(2) = +V2(2)+S3(2)
      P1(0) = -DBLE(V1(1))
      P1(1) = -DBLE(V1(2))
      P1(2) = -DIMAG(V1(2))
      P1(3) = -DIMAG(V1(1))
      DENOM = COUP/(P1(0)**2-P1(1)**2-P1(2)**2-P1(3)**2 - M1 * (M1 -CI
     $ * W1))
      V1(3)= DENOM*CI * S3(3)*(P1(1)*(V2(6)*P3(2)-V2(5)*P3(3))+(P1(2)
     $ *(V2(4)*P3(3)-V2(6)*P3(1))+P1(3)*(V2(5)*P3(1)-V2(4)*P3(2))))
      V1(4)= DENOM*(-CI )* S3(3)*(P1(0)*(V2(5)*P3(3)-V2(6)*P3(2))
     $ +(P1(2)*(V2(6)*P3(0)-V2(3)*P3(3))+P1(3)*(V2(3)*P3(2)-V2(5)*P3(0)
     $ )))
      V1(5)= DENOM*(-CI )* S3(3)*(P1(0)*(V2(6)*P3(1)-V2(4)*P3(3))
     $ +(P1(1)*(V2(3)*P3(3)-V2(6)*P3(0))+P1(3)*(V2(4)*P3(0)-V2(3)*P3(1)
     $ )))
      V1(6)= DENOM*(-CI )* S3(3)*(P1(0)*(V2(4)*P3(2)-V2(5)*P3(1))
     $ +(P1(1)*(V2(5)*P3(0)-V2(3)*P3(2))+P1(2)*(V2(3)*P3(1)-V2(4)*P3(0)
     $ )))
      END


