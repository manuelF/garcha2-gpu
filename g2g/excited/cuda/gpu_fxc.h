template<class T, bool compute_energy, bool compute_factor, bool lda>
__global__ void gpu_calc_FXC(uint points, T* dens, T* trad, G2G::vec_type<T,WIDTH>* dxyz,
                G2G::vec_type<T,WIDTH>* tradxyz, G2G::vec_type<T,2>* vsigma,
                G2G::vec_type<T,2>* v2rho2, G2G::vec_type<T,2>* v2rhosigma,
                G2G::vec_type<T,2>* v2sigma2, G2G::vec_type<T,2>* v3rho3,
                G2G::vec_type<T,2>* v3rho2sigma, G2G::vec_type<T,2>* v3rhosigma2,
                G2G::vec_type<T,2>* v3sigma3, 
                // OUTPUTS //
                T* dfac, T* tfac, G2G::vec_type<T,WIDTH>* dfacxyz, G2G::vec_type<T,WIDTH>* tfacxyz)
{
   uint idx = blockDim.x * blockIdx.x + threadIdx.x;

   if ( idx < points ) {
      // TRANSITION DENSITY
      double tr_dens[2], trgradX[2], trgradY[2], trgradZ[2];
      tr_dens[0]=trad[idx];
      trgradX[0]=tradxyz[idx].x;
      trgradY[0]=tradxyz[idx].y;
      trgradZ[0]=tradxyz[idx].z;
      tr_dens[1]=trad[idx];
      trgradX[1]=tradxyz[idx].x;
      trgradY[1]=tradxyz[idx].y;
      trgradZ[1]=tradxyz[idx].z;
      double gdensX, gdensY, gdensZ;
      gdensX = dxyz[idx].x*0.5f;
      gdensY = dxyz[idx].y*0.5f;
      gdensZ = dxyz[idx].z*0.5f;

      double grad_all[4], cont_grad[4];
      grad_all[0]=trgradX[0]*gdensX+trgradY[0]*gdensY+trgradZ[0]*gdensZ;
      grad_all[1]=trgradX[1]*gdensX+trgradY[1]*gdensY+trgradZ[1]*gdensZ;
      grad_all[2]=trgradX[0]*gdensX+trgradY[0]*gdensY+trgradZ[0]*gdensZ;
      grad_all[3]=trgradX[1]*gdensX+trgradY[1]*gdensY+trgradZ[1]*gdensZ;
      cont_grad[0]=trgradX[0]*trgradX[0]+trgradY[0]*trgradY[0]+trgradZ[0]*trgradZ[0];
      cont_grad[1]=trgradX[1]*trgradX[1]+trgradY[1]*trgradY[1]+trgradZ[1]*trgradZ[1];
      cont_grad[2]=trgradX[0]*trgradX[1]+trgradY[0]*trgradY[1]+trgradZ[0]*trgradZ[1];
      cont_grad[3]=cont_grad[2];
   
      // F NON CORE
      double coef[20];
      coef[0]=2.0f*(vsigma[idx].x*2.0f+vsigma[idx].y);
      coef[1]=v2rho2[idx].x*2.0f+v2rho2[idx].y;
      coef[2]=2.0f*(v2rhosigma[idx].x*4.0f+v2rhosigma[idx].y);
      coef[3]=2.0f*(v2rhosigma[idx].x*4.0f+v2rhosigma[idx].y);
      coef[4]=v2rhosigma[idx].y*2.0f;
      coef[5]=v2rhosigma[idx].y*2.0f;
      coef[6]=4.0f*(v2sigma2[idx].x*8.0f+v2sigma2[idx].y);
      coef[7]=2.0f*v2sigma2[idx].y*2.0f;
      coef[8]=2.0f*v2sigma2[idx].y*2.0f;
      coef[9]=v2sigma2[idx].y*4.0f;

      double coef1, cograd1;
      coef1=coef[0];
      cograd1=coef1*2.0f;
      double tr_dens1;
      coef1=coef[1];
      tr_dens1=coef1*tr_dens[0]*2.0f;

      double grad_all1;
      coef1=coef[2]+coef[3];
      tr_dens1=tr_dens1+coef1*grad_all[0];
      grad_all1=coef1*tr_dens[0];

      double grad_all2;
      coef1=coef[4]+coef[5];
      tr_dens1=tr_dens1+coef1*grad_all[2];
      grad_all2=coef1*tr_dens[0];

      coef1=coef[6];
      grad_all1=grad_all1+coef[6]*grad_all[0]*2.0f;
      coef1=coef[7]+coef[8];
      grad_all1=grad_all1+coef1*grad_all[2];
      grad_all2=grad_all2+coef1*grad_all[0];
      coef1=coef[9];
      grad_all2=grad_all2+coef1*grad_all[2]*2.0f;
  
      // --AB AND BA COMPONENTS--
      coef[10]=vsigma[idx].y*2.0f;
      coef[11]=v2rho2[idx].y;
      coef[12]=2.0f*v2rhosigma[idx].y;
      coef[13]=2.0f*v2rhosigma[idx].y;
      coef[14]=v2rhosigma[idx].y*2.0f;
      coef[15]=v2rhosigma[idx].y*2.0f;
      coef[16]=4.0f*v2sigma2[idx].y;
      coef[17]=2.0f*v2sigma2[idx].y*2.0f;
      coef[18]=2.0f*v2sigma2[idx].y*2.0f;
      coef[19]=v2sigma2[idx].y*4.0f;

      double cograd2, tr_dens2;
      coef1=coef[10]*2.0f;
      cograd2=coef1;
      coef1=coef[11]*2.0f;
      tr_dens1=tr_dens1+coef1*tr_dens[1];
      tr_dens2=coef1*tr_dens[0];

      double grad_all3;
      coef1=coef[12]*2.0f;
      tr_dens1=tr_dens1+coef1*grad_all[1];
      grad_all3=coef1*tr_dens[0];
      coef1=coef[13]*2.0f;
      tr_dens2=tr_dens2+coef1*grad_all[0];
      grad_all1=grad_all1+coef1*tr_dens[1];

      double grad_all4;
      coef1=coef[14]*2.0f;
      tr_dens1=tr_dens1+coef1*grad_all[3];
      grad_all4=coef1*tr_dens[0];
      coef1=coef[15]*2.0f;
      tr_dens2=tr_dens2+coef1*grad_all[2];
      grad_all2=grad_all2+coef1*tr_dens[1];

      coef1=coef[16]*2.0f;
      grad_all1=grad_all1+coef1*grad_all[1];
      grad_all3=grad_all3+coef1*grad_all[0];
      coef1=coef[17]*2.0f;
      grad_all1=grad_all1+coef1*grad_all[3];
      grad_all4=grad_all4+coef1*grad_all[0];
      coef1=coef[18]*2.0f;
      grad_all3=grad_all3+coef1*grad_all[2];
      grad_all2=grad_all2+coef1*grad_all[1];
      coef1=coef[19]*2.0f;
      grad_all2=grad_all2+coef1*grad_all[3];
      grad_all4=grad_all4+coef1*grad_all[2];

      // --BB COMPONENTS--
      coef[0]=2.0f*(vsigma[idx].x*2.0f+vsigma[idx].y);
      coef[1]=v2rho2[idx].x*2.0f+v2rho2[idx].y;
      coef[2]=2.0f*(v2rhosigma[idx].x*4.0f+v2rhosigma[idx].y);
      coef[3]=2.0f*(v2rhosigma[idx].x*4.0f+v2rhosigma[idx].y);
      coef[4]=v2rhosigma[idx].y*2.0f;
      coef[5]=v2rhosigma[idx].y*2.0f;
      coef[6]=4.0f*(v2sigma2[idx].x*8.0f+v2sigma2[idx].y);
      coef[7]=2.0f*v2sigma2[idx].y*2.0f;
      coef[8]=2.0f*v2sigma2[idx].y*2.0f;
      coef[9]=v2sigma2[idx].y*4.0f;

      coef1=coef[0];
      coef1=coef[1];
      tr_dens2=tr_dens2+coef1*tr_dens[1]*2.0f;
      coef1=coef[2]+coef[3];
      tr_dens2=tr_dens2+coef1*grad_all[1];
      grad_all3=grad_all3+coef1*tr_dens[1];
      coef1=coef[4]+coef[5];
      tr_dens2=tr_dens2+coef1*grad_all[3];
      grad_all4=grad_all4+coef1*tr_dens[1];
      coef1=coef[6];
      grad_all3=grad_all3+coef1*grad_all[1]*2.0f;
      coef1=coef[7]+coef[8];
      grad_all3=grad_all3+coef1*grad_all[3];
      grad_all4=grad_all4+coef1*grad_all[1];
      coef1=coef[9];
      grad_all4=grad_all4+coef1*grad_all[3]*2.0f;

      // CONTRACTION OF FNC
      double fncdens,fncdensX,fncdensY,fncdensZ;
      fncdens=tr_dens1;
      fncdensX=grad_all1*gdensX+grad_all2*gdensX+
               cograd1*trgradX[0]+cograd2*trgradX[1];
      fncdensY=grad_all1*gdensY+grad_all2*gdensY+
               cograd1*trgradY[0]+cograd2*trgradY[1];
      fncdensZ=grad_all1*gdensZ+grad_all2*gdensZ+
               cograd1*trgradZ[0]+cograd2*trgradZ[1];

      double fnctredX,fnctredY,fnctredZ;
      fnctredX=grad_all1*trgradX[0]+grad_all4*trgradX[1];
      fnctredY=grad_all1*trgradY[0]+grad_all4*trgradY[1];
      fnctredZ=grad_all1*trgradZ[0]+grad_all4*trgradZ[1];

      // F CORE
      coef[0]=2.0f*cont_grad[0];
      coef[1]=tr_dens[0]*tr_dens[0];
      coef[2]=2.0f*tr_dens[0]*grad_all[0];
      coef[3]=2.0f*grad_all[0]*tr_dens[0];
      coef[4]=grad_all[0]*tr_dens[0];
      coef[5]=tr_dens[0]*grad_all[0];
      coef[6]=4.0f*grad_all[0]*grad_all[0];
      coef[7]=2.0f*grad_all[0]*grad_all[0];
      coef[8]=2.0f*grad_all[0]*grad_all[0];
      coef[9]=grad_all[0]*grad_all[0];

      // EXCHANGE
      double Xtemp,Xtemp1;
      Xtemp=coef[0]*v2rhosigma[idx].x*4.0f;
      Xtemp1=coef[0]*2.0f*v2sigma2[idx].x*8.0f;
      Xtemp=Xtemp+coef[1]*v3rho3[idx].x*4.0f;
      Xtemp1=Xtemp1+coef[1]*2.0f*v3rho2sigma[idx].x*8.0f;
      Xtemp=Xtemp+coef[2]*v3rho2sigma[idx].x*8.0f;
      Xtemp1=Xtemp1+coef[2]*2.0f*v3rhosigma2[idx].x*16.0f;
      Xtemp=Xtemp+coef[3]*v3rho2sigma[idx].x*8.0f;
      Xtemp1=Xtemp1+coef[3]*2.0f*v3rhosigma2[idx].x*16.0f;
      Xtemp=Xtemp+coef[6]*v3rhosigma2[idx].x*16.0f;
      Xtemp1=Xtemp1+coef[6]*2.0f*v3sigma3[idx].x*32.0f;

      // CORRELATION
      double Ctemp,Ctemp1,Ctemp2;
      Ctemp=coef[0]*v2rhosigma[idx].y;
      Ctemp1=coef[0]*2.0f*v2sigma2[idx].y;
      Ctemp2=coef[0]*v2sigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[1]*v3rho3[idx].y;
      Ctemp1=Ctemp1+coef[1]*2.0f*v3rho2sigma[idx].y;
      Ctemp2=Ctemp2+coef[1]*v3rho2sigma[idx].y*2.0f;
      Ctemp=Ctemp+coef[2]*v3rho2sigma[idx].y;
      Ctemp1=Ctemp1+coef[2]*2.0f*v3rhosigma2[idx].y;
      Ctemp2=Ctemp2+coef[2]*v3rhosigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[3]*v3rho2sigma[idx].y;
      Ctemp1=Ctemp1+coef[3]*2.0f*v3rhosigma2[idx].y;
      Ctemp2=Ctemp2+coef[3]*v3rhosigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[4]*v3rho2sigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[4]*2.0f*v3rhosigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[4]*v3rhosigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[5]*v3rho2sigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[5]*2.0f*v3rhosigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[5]*v3rhosigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[6]*v3rhosigma2[idx].y;
      Ctemp1=Ctemp1+coef[6]*2.0f*v3sigma3[idx].y;
      Ctemp2=Ctemp2+coef[6]*v3sigma3[idx].y*2.0f;
      Ctemp=Ctemp+coef[7]*v3rhosigma2[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[7]*2.0f*v3sigma3[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[7]*v3sigma3[idx].y*4.0f;
      Ctemp=Ctemp+coef[8]*v3rhosigma2[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[8]*2.0f*v3sigma3[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[8]*v3sigma3[idx].y*4.0f;
      Ctemp=Ctemp+coef[9]*v3rhosigma2[idx].y*4.0f;
      Ctemp1=Ctemp1+coef[9]*2.0f*v3sigma3[idx].y*4.0f;
      Ctemp2=Ctemp2+coef[9]*v3sigma3[idx].y*8.0f;

      coef[0]=2.0f*cont_grad[1];
      coef[1]=tr_dens[1]*tr_dens[1];
      coef[2]=2.0f*tr_dens[1]*grad_all[1];
      coef[3]=2.0f*grad_all[1]*tr_dens[1];
      coef[4]=grad_all[1]*tr_dens[1];
      coef[5]=tr_dens[1]*grad_all[1];
      coef[6]=4.0f*grad_all[1]*grad_all[1];
      coef[7]=2.0f*grad_all[1]*grad_all[1];
      coef[8]=2.0f*grad_all[1]*grad_all[1];
      coef[9]=grad_all[1]*grad_all[1];

      Ctemp=Ctemp+coef[0]*v2rhosigma[idx].y;
      Ctemp1=Ctemp1+coef[0]*2.0f*v2sigma2[idx].y;
      Ctemp2=Ctemp2+coef[0]*v2sigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[1]*v3rho3[idx].y;
      Ctemp1=Ctemp1+coef[1]*2.0f*v3rho2sigma[idx].y;
      Ctemp2=Ctemp2+coef[1]*v3rho2sigma[idx].y*2.0f;
      Ctemp=Ctemp+coef[2]*v3rho2sigma[idx].y;
      Ctemp1=Ctemp1+coef[2]*2.0f*v3rhosigma2[idx].y;
      Ctemp2=Ctemp2+coef[2]*v3rhosigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[3]*v3rho2sigma[idx].y;
      Ctemp1=Ctemp1+coef[3]*2.0f*v3rhosigma2[idx].y;
      Ctemp2=Ctemp2+coef[3]*v3rhosigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[4]*v3rho2sigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[4]*2.0f*v3rhosigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[4]*v3rhosigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[5]*v3rho2sigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[5]*2.0f*v3rhosigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[5]*v3rhosigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[6]*v3rhosigma2[idx].y;
      Ctemp1=Ctemp1+coef[6]*2.0f*v3sigma3[idx].y;
      Ctemp2=Ctemp2+coef[6]*v3sigma3[idx].y*2.0f;
      Ctemp=Ctemp+coef[7]*v3rhosigma2[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[7]*2.0f*v3sigma3[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[7]*v3sigma3[idx].y*4.0f;
      Ctemp=Ctemp+coef[8]*v3rhosigma2[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[8]*2.0f*v3sigma3[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[8]*v3sigma3[idx].y*4.0f;
      Ctemp=Ctemp+coef[9]*v3rhosigma2[idx].y*4.0f;
      Ctemp1=Ctemp1+coef[9]*2.0f*v3sigma3[idx].y*4.0f;
      Ctemp2=Ctemp2+coef[9]*v3sigma3[idx].y*8.0f;

      coef[10]=cont_grad[2];
      coef[11]=tr_dens[0]*tr_dens[1];
      coef[12]=2.0f*tr_dens[0]*grad_all[1];
      coef[13]=2.0f*grad_all[0]*tr_dens[1];
      coef[14]=tr_dens[0]*grad_all[3];
      coef[15]=grad_all[2]*tr_dens[1];
      coef[16]=4.0f*grad_all[0]*grad_all[1];
      coef[17]=2.0f*grad_all[0]*grad_all[3];
      coef[18]=2.0f*grad_all[2]*grad_all[1];
      coef[19]=grad_all[2]*grad_all[3];

      Ctemp=Ctemp+coef[10]*v2rhosigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[10]*2.0f*v2sigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[10]*v2sigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[11]*v3rho3[idx].y;
      Ctemp1=Ctemp1+coef[11]*2.0f*v3rho2sigma[idx].y;
      Ctemp2=Ctemp2+coef[11]*v3rho2sigma[idx].y*2.0f;
      Ctemp=Ctemp+coef[12]*v3rho2sigma[idx].y;
      Ctemp1=Ctemp1+coef[12]*2.0f*v3rhosigma2[idx].y;
      Ctemp2=Ctemp2+coef[12]*v3rhosigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[13]*v3rho2sigma[idx].y;
      Ctemp1=Ctemp1+coef[13]*2.0f*v3rhosigma2[idx].y;
      Ctemp2=Ctemp2+coef[13]*v3rhosigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[14]*v3rho2sigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[14]*2.0f*v3rhosigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[14]*v3rhosigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[15]*v3rho2sigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[15]*2.0f*v3rhosigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[15]*v3rhosigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[16]*v3rhosigma2[idx].y;
      Ctemp1=Ctemp1+coef[16]*2.0f*v3sigma3[idx].y;
      Ctemp2=Ctemp2+coef[16]*v3sigma3[idx].y*2.0f;
      Ctemp=Ctemp+coef[17]*v3rhosigma2[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[17]*2.0f*v3sigma3[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[17]*v3sigma3[idx].y*4.0f;
      Ctemp=Ctemp+coef[18]*v3rhosigma2[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[18]*2.0f*v3sigma3[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[18]*v3sigma3[idx].y*4.0f;
      Ctemp=Ctemp+coef[19]*v3rhosigma2[idx].y*4.0f;
      Ctemp1=Ctemp1+coef[19]*2.0f*v3sigma3[idx].y*4.0f;
      Ctemp2=Ctemp2+coef[19]*v3sigma3[idx].y*8.0f;

      // **BA_TERM=AB_TERM**
      coef[10]=cont_grad[2];
      coef[11]=tr_dens[0]*tr_dens[1];
      coef[12]=2.0f*tr_dens[0]*grad_all[1];
      coef[13]=2.0f*grad_all[0]*tr_dens[1];
      coef[14]=tr_dens[0]*grad_all[3];
      coef[15]=grad_all[2]*tr_dens[1];
      coef[16]=4.0f*grad_all[0]*grad_all[1];
      coef[17]=2.0f*grad_all[0]*grad_all[3];
      coef[18]=2.0f*grad_all[2]*grad_all[1];
      coef[19]=grad_all[2]*grad_all[3];

      Ctemp=Ctemp+coef[10]*v2rhosigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[10]*2.0f*v2sigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[10]*v2sigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[11]*v3rho3[idx].y;
      Ctemp1=Ctemp1+coef[11]*2.0f*v3rho2sigma[idx].y;
      Ctemp2=Ctemp2+coef[11]*v3rho2sigma[idx].y*2.0f;
      Ctemp=Ctemp+coef[12]*v3rho2sigma[idx].y;
      Ctemp1=Ctemp1+coef[12]*2.0f*v3rhosigma2[idx].y;
      Ctemp2=Ctemp2+coef[12]*v3rhosigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[13]*v3rho2sigma[idx].y;
      Ctemp1=Ctemp1+coef[13]*2.0f*v3rhosigma2[idx].y;
      Ctemp2=Ctemp2+coef[13]*v3rhosigma2[idx].y*2.0f;
      Ctemp=Ctemp+coef[14]*v3rho2sigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[14]*2.0f*v3rhosigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[14]*v3rhosigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[15]*v3rho2sigma[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[15]*2.0f*v3rhosigma2[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[15]*v3rhosigma2[idx].y*4.0f;
      Ctemp=Ctemp+coef[16]*v3rhosigma2[idx].y;
      Ctemp1=Ctemp1+coef[16]*2.0f*v3sigma3[idx].y;
      Ctemp2=Ctemp2+coef[16]*v3sigma3[idx].y*2.0f;
      Ctemp=Ctemp+coef[17]*v3rhosigma2[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[17]*2.0f*v3sigma3[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[17]*v3sigma3[idx].y*4.0f;
      Ctemp=Ctemp+coef[18]*v3rhosigma2[idx].y*2.0f;
      Ctemp1=Ctemp1+coef[18]*2.0f*v3sigma3[idx].y*2.0f;
      Ctemp2=Ctemp2+coef[18]*v3sigma3[idx].y*4.0f;
      Ctemp=Ctemp+coef[19]*v3rhosigma2[idx].y*4.0f;
      Ctemp1=Ctemp1+coef[19]*2.0f*v3sigma3[idx].y*4.0f;
      Ctemp2=Ctemp2+coef[19]*v3sigma3[idx].y*8.0f;

      // CONTRACTION OF FC
      double fcdens,fcdensG1,fcdensG2,fcdgradX,fcdgradY,fcdgradZ;
      fcdens=Xtemp+Ctemp;
      fcdensG1=Xtemp1+Ctemp1;
      fcdensG2=Ctemp2;
      fcdgradX=fcdensG1*gdensX+fcdensG2*gdensX;
      fcdgradY=fcdensG1*gdensY+fcdensG2*gdensY;
      fcdgradZ=fcdensG1*gdensZ+fcdensG2*gdensZ;

      // DENSITY FACTOR
      dfac[idx]+=fcdens;
      dfacxyz[idx].x+=fnctredX+fcdgradX;
      dfacxyz[idx].y+=fnctredY+fcdgradY;
      dfacxyz[idx].z+=fnctredZ+fcdgradZ;

      // TRANSITION DENSITY FACTOR
      tfac[idx]=fncdens;
      tfacxyz[idx].x=fncdensX;
      tfacxyz[idx].y=fncdensY;
      tfacxyz[idx].z=fncdensZ;
   }
}