$FIXEDFORMLINESIZE: 132
C TGMET2013.FOR
C  Fortran source code to perform trip generation
C   for the Metrolina Travel Model 2013
C  Written previously for the Metrolina Travel Model 2004
C  Written originally 14 Mar 1995 as TGMET1.FOR and TGMET2.FOR for
C   the Dulles Model.  Revised 23 Jan 96 for the I-66 MIS and
C   Washington Western Bypass studies.  Revised 28 Mar 96 for the
C   Berks County Travel Model.

C  April 2013                   bill allen

C Developed originally in MS Fortran PowerStation 1.0.  Now being
C  compiled in Compaq Visual Fortran 6.6 (Standard Edition 6.6a).
C Check the following compiler settings:
C  under tab "Fortran":
C   General: Debugging Level=Full, Optimization Level=Full Optimization
C   Compatibility: Libraries, Other Run-Time Behaviour
C   Compilation Diagnostics: Undeclared Symbols, Uninitiated Variables
C   Listing Files: Source Listing, Source Map
C
C Or, use the following switches:
C  /check:bounds /compile_only /dbglibs /debug:full /fpscomp:general
C  /list:"Debug/" /nologo /optimize:4 /traceback /warn:argument_checking
C  /warn:declarations /warn:nofileopt /module:"Debug/" /object:"Debug/"
C  /pdbfile:"Debug/DF60.PDB"

c Program Limitations:
c - max. number of internal zones:              5,000
c - highest TAZ or ext station number:          30000 (MAXZONE)
c - max. number of external stations:             200
c - max. number of counties (as determined by first 2
c    digits of 5-digit TAZ):                       15
c - max. number of fields in zonal data file:     196
c - max. record length of zonal data file:      2,048 bytes
c - max. special generator zones:                  30
c - max. zones in the CBD:                        100
c - max. number of variables on the zonal S/E
c    file:					   50

C Modifications:
c 10 Jun 05  Revise E/I model to use parabolic function
c 14 Jun 05  Mod AT-based adjustment factors to shrink the cliffs
c 16 Jun 05  Mod AT-based adjustment factors for hwy assignment
c               calibration
c 22 Aug 05  Add switches to turn off GQ trips and non-resident NHB
c               trips (DO_GQ, DO_NONRES)
c 25 Aug 05  Edit BASVOL and BTHRUV arrays to reflect updated cordon
c		volume data; remove DISTCBDFILE (no longer used)
c Changes for 2013 version:
c            Change format of input S/E file.  Use flexible comma-
c		delimited format instead of DBF.
c	     Size/income seed now stratified by PUMA.
c	     Life cycle calculation now split by Uptown vs. rest of
c		region.
c 17 Sep 2015 corrected worker submodel interpolation

C--------------------------------------------------------------------
c Purpose codes:
c 1 HBW      8 NHBNWK         15 I/E MTrk
c 2 SCH      9 COM            16 I/E HTrk
c 3 HBU     10 Med Trk        17 E/I Work Auto
c 4 HBS     11 Hvy Trk        18 E/I NonWk Auto
c 5 HBO     12 I/E Work Auto  19 E/I COM
c 6 NHBJTW  13 I/E Nonwk Auto 20 E/I MTrk
c 7 NHBATW  14 I/E COM        21 E/I HTrk

      program TGMET

C  Initialize.

      implicit none

      INTEGER*4 ZONES,NSTA
      REAL*8    PROD,ATTR

c DUM_01 is a dummy variable needed in order to make the 
c  memory allocation for the PROD and ATTR variables in COMMON
c  be OK.  A stupid Fortran thing.

	INTEGER*4 DUM_01

      common /dattim/ yr,mon,day,hr,min,sec,hun,
     +                month(12),title(10),page

      common /rept/ tjointWIL(4,4,3),tjointSIL(5,4,3),tlife(3),
     + twkr(4),tinc(4),tsize(5),repo(8),zones,
     + xxfact(4,200),xxfile,totiiattr(11,4),tprod(21,4),
     + totextprod(21),totextattr(21),statripends(5,200),
     + regtot(5),purcode(21),totiiprod(11,4),DUM_01,prod(21,4),
     + attr(21,4),ttrip(21,4),nsta,fthruv(4,200)

      common /zd/ z(31,5000),intzones,begtr

      integer*2 zz,p,w,v,s,s2,i,j,k,m,n,l,istop,iz,t,c,
     + fil(5),atype,stat1,intzones,wr,ir,lr,sr,
     + lind,hind,begtr,endtr,p4,p5,
     + specgenzone(30,11),hdiff,incr,nfld,
     + totfil,bu,strlth,maxzone,tazpuma(5000),pumano,
     + zTAZ,zPOP_TOT,zPOP_HHS,zPOP_GRP,zHH,zMED_INC,zLOIND,zHIIND,
     + zRTL,zHWY,zLOSVC,zHISVC,zOFFGOV,zEDUC,zEMP_TOT,zSTU_K8,zSTU_HS,
     + zSTU_CU,zDORM,zAREA

      real*4 z,tinc,rinc(4),basvol(4,200),gqfact(8,2),yrl,
     + spct(5),ipct(4),csum,diff,siseed(4,5,15),ripct(4),bthruv(4,200),
     + rtot(5),negfac,sneg,incrat,joint(5,4),isum,y1,y4,y5,
     + size(5),income(4),regtotwkr,regavginc,life(3),wsum,sum,
     + perhh,sizinc(5,4),sizinclif(5,4,3),newtotwkr,copct(16,5,4),
     + cdiff(4),share(4),newtot,incdist(4,37),regtot,wfact,
     + sizedist(5,30),ratio,low,high,range,ctot(4),cfac,u(4),eu(4),
     + avg5per,extpctw,extpctn,wratio(4),eipsn,buck,
     + empfactor,empadjust,wkrdist(4,3,4,5),oldwkrhh,newwkrhh,
     + arate(11,16),lifedist(3,4,5),oldwrk(4),bthrup(4,200),
     + prate(8,5,3,4),tothh,sizinclifwkr(5,4,3,4),igroup(4),
     + pr1(8,5,3,2),pr2(8,5,3,2),acoefas(5,10),newwrk(4),ztotwkr,
     + tprod,wkrinclif(4,4,3),extvol(5,200),extw,extn,
     + tattr3(11,4),atfacta(11,5),npct(4),nhbtot,hbtot,nrtot,nhbadj,
     + tjointWIL,tjointSIL,tsize,tlife,tempp,tempa,
     + twkr,ttrip,atfactp(8,5),totiiprod,zdat(50),
     + pfact(8,4),tfactor(11),totiiattr,ld(3,4,5),
     + avg3wkr,sumeu,fthruv,extpctc,extpctm,extpcth,
     + totextprod,totextattr,extprod(5,200),
     + extattr(5,200),xxfact,statripends,iewrkavo,ienwkavo,
     + eiwrkavo,einwkavo,hh,hhpop,totemp,lcfac(3,4),lcf,
     + stavol(4,200),totext(5),dummy(5),extadj(5,2),qq,
     + ploind,phiind,prtl,phwy,plosvc,peduc  

      real*8 sattr(11,2),tattr1(11),tattr2(11),factor

      integer*4 yr,mon,day,hr,min,sec,hun,page,itaz,yi,
     + intinc(4),tazzone(30000),cbd(100),szinlfwk(5,4,3,4),
     + specgenprod(30,11),specgenattr(30,11),ihh,jj,thh,
     + uptown(100),hhno

      character*4 month,purcode,stitl(5)
      character*8 title,scard(10)
      character*16 verinfo,zname(50)
      character*80 list,names(5),control,pumafile,hhfile,
     + sefile,xvolfile,prodfile,attrfile,xxfile,distcorfile,
     + proddict,attrdict,xxdict,atfile,hhdict
      logical repo,savescr,do_gq,do_nonres
c      distcbdfile      

      namelist /files/ list,sefile,distcorfile,pumafile,hhfile,
     + xvolfile,xxfile,prodfile,attrfile,atfile
      namelist /parameters/ repo,begtr,endtr,
     +  empfactor,savescr,avg3wkr,avg5per,do_gq,do_nonres,
     +  tfactor,iewrkavo,ienwkavo,eiwrkavo,einwkavo,
     + zTAZ,zPOP_TOT,zPOP_HHS,zPOP_GRP,zHH,zMED_INC,zLOIND,zHIIND,
     + zRTL,zHWY,zLOSVC,zHISVC,zOFFGOV,zEDUC,zEMP_TOT,zSTU_K8,zSTU_HS,
     + zSTU_CU,zDORM,zAREA
     
      namelist /special/ specgenzone,specgenprod,specgenattr
      namelist /equiv/ cbd,uptown
      namelist /coeffs/ atfactp,atfacta,gqfact,acoefas,pfact,
     + extadj,prate,arate,siseed,basvol,bthruv

      equivalence (pr1,prate(1,1,1,1)),(pr2,prate(1,1,1,3))

c Sources for some key parameters:
c  - average persons/HH for 5+ persons/HH category: SizeModel.xls
c  - average workers/HH for 3+ workers/HH category:
c               TRACT_WORKERSHHSIZE.XLS
c  - average auto occupancy for external auto trips:
c               external station.xls

      data avg5per/5.54/,avg3wkr/3.255/,iewrkavo/1.182/,
     + ienwkavo/1.666/,eiwrkavo/1.172/,einwkavo/1.556/,totext/5*0.0/

      data repo/8*.true./,regtotwkr/0.0/,copct/320*0.0/,hhno/0/,
     + tsize,twkr/9*0.0/,igroup/0.10,0.15,0.25,0.50/,dummy/5*0.0/,
     + page/1/,empfactor/0.8746/,tinc/4*0.0/,tattr3/44*0.0/,
     + tjointWIL/48*0.0/,tjointSIL/60*0.0/,statripends/1000*0.0/
      data z/155000*0.0/,tprod/84*0.0/,savescr/.false./,tlife/3*0.0/,
     + regtot/5*0.0/,stitl/'  1 ','  2 ','  3 ','  4 ','  5+'/
      data month/'Jan ','Feb ','Mar ','Apr ','May ','Jun ','Jul ',
     + 'Aug ','Sep ','Oct ','Nov ','Dec '/,tattr1,tattr2/22*0.0/,
     + purcode/'HBW ','SCH ','HBU ','HBS ','HBO ','JTW ','ATW ','NWK ',
     +         'COM ','MTK ','HTK ','IEW ','IEN ','IEC ','IEM ','IEH ',
     +         'EIW ','EIN ','EIC ','EIM ','EIH '/,
     + names/'zonal socioeconomic data                        ',
     +       'external station growth factors                 ',
     +       'zonal distance to cordon                        ',
     +       'zonal distance to CBD                           ',
     +       'TAZ/PUMA equivalency                            '/
     + prod/84*0.0/,attr/84*0.0/,nhbtot,hbtot/2*0.0/,
     + tfactor/11*1.0/,specgenzone/330*0/,maxzone/30000/,
     + specgenprod/330*0/,specgenattr/330*0/,
     + totiiprod/44*0.0/,totiiattr/44*0.0/,totextprod/21*0.0/,
     + totextattr/21*0.0/,do_gq,do_nonres/2*.true./

C  'SISEED' array: regional base % of HH's by HH size, income
C   group, and PUMA, from the 2005-09 ACS Public Use Microdata Sample
C   (PUMS) files for Metrolina: (SizeIncomeSeed.xls).
C   List of PUMAs (2000 Census)			
C   1  370400 Cleveland, Rutherford, Polk, McDowell
C   2  370901 SW Mecklenburg
C   3  370902 NW Central Mecklenburg
C   4  370903 NE Central Mecklenburg
C   5  370904 E Mecklenburg
C   6  370905 S Mecklenburg
C   7  371000 N Mecklenburg
C   8  371100 Gaston, Lincoln
C   9  371200 Rowan
C  10  371300 Cabarrus
C  11  371400 Union
C  12  371500 Iredell
C  13  372500 Stanly, Montgomery, Anson
C  14  450500 York (SC)
C  15  451300 Lancaster, Chesterfield, Kershaw, Lee (SC)
C   Dimensions: SISEED(income, size, PUMA)            DATA OK
C            income:  1      2      3      4        PUMA  Size
      data siseed/0.092 , 0.089 , 0.066 , 0.031 ,  ! 1     1
     +            0.027 , 0.071 , 0.114 , 0.155 ,  ! 1     2
     +            0.015 , 0.016 , 0.043 , 0.081 ,  ! 1     3
     +            0.008 , 0.012 , 0.034 , 0.074 ,  ! 1     4
     +            0.008 , 0.008 , 0.021 , 0.035 ,  ! 1     5

     +            0.050 , 0.084 , 0.099 , 0.096 ,  ! 2     1
     +            0.018 , 0.040 , 0.079 , 0.193 ,  ! 2     2
     +            0.010 , 0.023 , 0.036 , 0.094 ,  ! 2     3
     +            0.010 , 0.017 , 0.035 , 0.050 ,  ! 2     4
     +            0.006 , 0.007 , 0.015 , 0.038 ,  ! 2     5

     +            0.062 , 0.079 , 0.101 , 0.042 ,  ! 3     1
     +            0.023 , 0.042 , 0.094 , 0.136 ,  ! 3     2
     +            0.010 , 0.032 , 0.053 , 0.082 ,  ! 3     3
     +            0.008 , 0.022 , 0.043 , 0.072 ,  ! 3     4
     +            0.006 , 0.016 , 0.031 , 0.046 ,  ! 3     5

     +            0.064 , 0.070 , 0.099 , 0.069 ,  ! 4     1
     +            0.018 , 0.032 , 0.083 , 0.184 ,  ! 4     2
     +            0.013 , 0.017 , 0.042 , 0.094 ,  ! 4     3
     +            0.005 , 0.007 , 0.023 , 0.082 ,  ! 4     4
     +            0.002 , 0.009 , 0.026 , 0.061 ,  ! 4     5

     +            0.084 , 0.082 , 0.126 , 0.114 ,  ! 5     1
     +            0.021 , 0.057 , 0.082 , 0.161 ,  ! 5     2
     +            0.008 , 0.022 , 0.038 , 0.069 ,  ! 5     3
     +            0.005 , 0.012 , 0.021 , 0.053 ,  ! 5     4
     +            0.002 , 0.008 , 0.012 , 0.023 ,  ! 5     5

     +            0.024 , 0.049 , 0.095 , 0.127 ,  ! 6     1
     +            0.007 , 0.015 , 0.051 , 0.282 ,  ! 6     2
     +            0.002 , 0.005 , 0.014 , 0.122 ,  ! 6     3
     +            0.000 , 0.006 , 0.007 , 0.128 ,  ! 6     4
     +            0.001 , 0.001 , 0.006 , 0.058 ,  ! 6     5

     +            0.029 , 0.044 , 0.079 , 0.095 ,  ! 7     1
     +            0.012 , 0.019 , 0.058 , 0.234 ,  ! 7     2
     +            0.007 , 0.009 , 0.029 , 0.133 ,  ! 7     3
     +            0.002 , 0.008 , 0.002 , 0.133 ,  ! 7     4
     +            0.002 , 0.004 , 0.010 , 0.073 ,  ! 7     5

     +            0.067 , 0.073 , 0.068 , 0.037 ,  ! 8     1
     +            0.022 , 0.056 , 0.097 , 0.185 ,  ! 8     2
     +            0.011 , 0.026 , 0.045 , 0.094 ,  ! 8     3
     +            0.007 , 0.012 , 0.034 , 0.092 ,  ! 8     4
     +            0.004 , 0.008 , 0.017 , 0.045 ,  ! 8     5

     +            0.063 , 0.081 , 0.066 , 0.040 ,  ! 9     1
     +            0.023 , 0.053 , 0.095 , 0.175 ,  ! 9     2
     +            0.014 , 0.020 , 0.042 , 0.108 ,  ! 9     3
     +            0.007 , 0.008 , 0.032 , 0.084 ,  ! 9     4
     +            0.006 , 0.009 , 0.021 , 0.053 ,  ! 9     5

     +            0.047 , 0.069 , 0.074 , 0.050 ,  !10     1
     +            0.017 , 0.035 , 0.081 , 0.199 ,  !10     2
     +            0.006 , 0.018 , 0.037 , 0.117 ,  !10     3
     +            0.003 , 0.007 , 0.029 , 0.118 ,  !10     4
     +            0.006 , 0.009 , 0.021 , 0.053 ,  !10     5

     +            0.038 , 0.037 , 0.054 , 0.040 ,  !11     1
     +            0.015 , 0.031 , 0.084 , 0.186 ,  !11     2
     +            0.009 , 0.010 , 0.040 , 0.135 ,  !11     3
     +            0.005 , 0.010 , 0.038 , 0.131 ,  !11     4
     +            0.007 , 0.010 , 0.027 , 0.093 ,  !11     5

     +            0.056 , 0.076 , 0.069 , 0.037 ,  !12     1
     +            0.025 , 0.048 , 0.101 , 0.186 ,  !12     2
     +            0.007 , 0.012 , 0.039 , 0.107 ,  !12     3
     +            0.005 , 0.014 , 0.023 , 0.110 ,  !12     4
     +            0.005 , 0.009 , 0.018 , 0.053 ,  !12     5

     +            0.089 , 0.077 , 0.075 , 0.025 ,  !13     1
     +            0.028 , 0.067 , 0.113 , 0.144 ,  !13     2
     +            0.015 , 0.021 , 0.050 , 0.085 ,  !13     3
     +            0.003 , 0.012 , 0.032 , 0.084 ,  !13     4
     +            0.005 , 0.014 , 0.020 , 0.041 ,  !13     5

     +            0.052 , 0.068 , 0.076 , 0.051 ,  !14     1
     +            0.018 , 0.041 , 0.093 , 0.203 ,  !14     2
     +            0.012 , 0.012 , 0.033 , 0.116 ,  !14     3
     +            0.005 , 0.012 , 0.030 , 0.102 ,  !14     4
     +            0.004 , 0.006 , 0.015 , 0.051 ,  !14     5

     +            0.093 , 0.081 , 0.056 , 0.036 ,  !15     1
     +            0.030 , 0.064 , 0.104 , 0.153 ,  !15     2
     +            0.016 , 0.020 , 0.048 , 0.081 ,  !15     3
     +            0.011 , 0.015 , 0.029 , 0.084 ,  !15     4
     +            0.006 , 0.013 , 0.018 , 0.042 /  !15     5
     
C  'GQFACT' array: GQPOP trip production modification factor by purpose,
C   depending on whether this zone has a college dormitory or not
C   Dimensions: GQFACT(purpose,D), where D=1 if a dorm zone, 2 if not
C       purpose:    HBW   SCH   HBU   HBS   HBO   JTW   ATW   NWK
      data gqfact /0.15, 0.00, 3.00, 1.00, 1.00, 0.10, 0.00, 0.50,
     +             0.00, 0.05, 0.25, 0.25, 0.25, 0.00, 0.00, 0.25/

C  'WKRDIST' array: regional base distribution of HHs by HH size,
C   income group, lifecycle, and no. of workers, from the
C   2000 Census Public Use Microdata Sample (PUMS) files for
C   Metrolina (XTABHH3.LIS).
C   Dimensions: WKRDIST(workers, life cycle, income, size)
C                                       DATA OK
C         workers:      0       1       2       3+    Size Inc Life
      data wkrdist /1.000 , 0.000 , 0.000 , 0.000 ,   !  1   1   1
     +              0.621 , 0.379 , 0.000 , 0.000 ,   !  1   1   2
     +              0.598 , 0.402 , 0.000 , 0.000 ,   !  1   1   3
     +              1.000 , 0.000 , 0.000 , 0.000 ,   !  1   2   1
     +              0.230 , 0.770 , 0.000 , 0.000 ,   !  1   2   2
     +              0.170 , 0.830 , 0.000 , 0.000 ,   !  1   2   3
     +              1.000 , 0.000 , 0.000 , 0.000 ,   !  1   3   1
     +              0.745 , 0.255 , 0.000 , 0.000 ,   !  1   3   2
     +              0.097 , 0.903 , 0.000 , 0.000 ,   !  1   3   3
     +              1.000 , 0.000 , 0.000 , 0.000 ,   !  1   4   1
     +              0.100 , 0.900 , 0.000 , 0.000 ,   !  1   4   2
     +              0.081 , 0.919 , 0.000 , 0.000 ,   !  1   4   3

     +              0.871 , 0.129 , 0.000 , 0.000 ,   !  2   1   1
     +              0.503 , 0.472 , 0.025 , 0.000 ,   !  2   1   2
     +              0.480 , 0.365 , 0.155 , 0.000 ,   !  2   1   3
     +              0.848 , 0.152 , 0.000 , 0.000 ,   !  2   2   1
     +              0.169 , 0.772 , 0.059 , 0.000 ,   !  2   2   2
     +              0.241 , 0.500 , 0.259 , 0.000 ,   !  2   2   3
     +              0.642 , 0.358 , 0.000 , 0.000 ,   !  2   3   1
     +              0.070 , 0.800 , 0.130 , 0.000 ,   !  2   3   2
     +              0.087 , 0.390 , 0.523 , 0.000 ,   !  2   3   3
     +              0.581 , 0.419 , 0.000 , 0.000 ,   !  2   4   1
     +              0.039 , 0.781 , 0.180 , 0.000 ,   !  2   4   2
     +              0.036 , 0.205 , 0.759 , 0.000 ,   !  2   4   3

     +              0.734 , 0.266 , 0.000 , 0.000 ,   !  3   1   1
     +              0.478 , 0.449 , 0.070 , 0.003 ,   !  3   1   2
     +              0.304 , 0.353 , 0.297 , 0.046 ,   !  3   1   3
     +              0.469 , 0.456 , 0.075 , 0.000 ,   !  3   2   1
     +              0.181 , 0.650 , 0.161 , 0.008 ,   !  3   2   2
     +              0.170 , 0.397 , 0.391 , 0.042 ,   !  3   2   3
     +              0.370 , 0.524 , 0.106 , 0.000 ,   !  3   3   1
     +              0.067 , 0.462 , 0.443 , 0.028 ,   !  3   3   2
     +              0.058 , 0.246 , 0.471 , 0.225 ,   !  3   3   3
     +              0.127 , 0.444 , 0.429 , 0.000 ,   !  3   4   1
     +              0.025 , 0.242 , 0.657 , 0.076 ,   !  3   4   2
     +              0.014 , 0.080 , 0.311 , 0.595 ,   !  3   4   3

     +              0.830 , 0.170 , 0.000 , 0.000 ,   !  4   1   1
     +              0.467 , 0.402 , 0.125 , 0.006 ,   !  4   1   2
     +              0.192 , 0.576 , 0.138 , 0.094 ,   !  4   1   3
     +              0.529 , 0.400 , 0.071 , 0.000 ,   !  4   2   1
     +              0.150 , 0.599 , 0.226 , 0.025 ,   !  4   2   2
     +              0.231 , 0.402 , 0.068 , 0.299 ,   !  4   2   3
     +              0.112 , 0.584 , 0.213 , 0.091 ,   !  4   3   1
     +              0.043 , 0.419 , 0.474 , 0.064 ,   !  4   3   2
     +              0.053 , 0.119 , 0.366 , 0.462 ,   !  4   3   3
     +              0.078 , 0.257 , 0.506 , 0.159 ,   !  4   4   1
     +              0.016 , 0.237 , 0.596 , 0.151 ,   !  4   4   2
     +              0.013 , 0.028 , 0.114 , 0.845 ,   !  4   4   3

     +              0.550 , 0.289 , 0.161 , 0.000 ,   !  5   1   1
     +              0.427 , 0.401 , 0.154 , 0.018 ,   !  5   1   2
     +              0.900 , 0.100 , 0.000 , 0.000 ,   !  5   1   3
     +              0.272 , 0.535 , 0.156 , 0.037 ,   !  5   2   1
     +              0.201 , 0.517 , 0.230 , 0.052 ,   !  5   2   2
     +              0.875 , 0.125 , 0.000 , 0.000 ,   !  5   2   3
     +              0.170 , 0.373 , 0.362 , 0.095 ,   !  5   3   1
     +              0.052 , 0.383 , 0.443 , 0.122 ,   !  5   3   2
     +              0.000 , 0.111 , 0.421 , 0.468 ,   !  5   3   3
     +              0.022 , 0.225 , 0.373 , 0.380 ,   !  5   4   1
     +              0.015 , 0.229 , 0.457 , 0.299 ,   !  5   4   2
     +              0.016 , 0.000 , 0.076 , 0.908 /   !  5   4   3

C  'LIFEDIST' array: regional base distribution of HHs by HH size,
C   income group, and life cycle, from the
C   2000 Census Public Use Microdata Sample (PUMS) files for
C   Metrolina (XTABHH3.LIS).
C   Dimensions: LIFEDIST(life cycle, income, size)
C                                       DATA OK
C         life cycle:   1       2       3
c                   Ret'd   Kids    No Ret or Kids    Size Inc
      data lifedist/0.538 , 0.000 , 0.462 ,           !  1   1
     +              0.370 , 0.000 , 0.630 ,           !  1   2
     +              0.134 , 0.000 , 0.866 ,           !  1   3
     +              0.127 , 0.000 , 0.873 ,           !  1   4
     +              0.329 , 0.317 , 0.354 ,           !  2   1
     +              0.435 , 0.191 , 0.374 ,           !  2   2
     +              0.308 , 0.133 , 0.559 ,           !  2   3
     +              0.143 , 0.026 , 0.831 ,           !  2   4
     +              0.063 , 0.863 , 0.074 ,           !  3   1
     +              0.144 , 0.760 , 0.096 ,           !  3   2
     +              0.120 , 0.738 , 0.142 ,           !  3   3
     +              0.089 , 0.653 , 0.258 ,           !  3   4
     +              0.048 , 0.898 , 0.054 ,           !  4   1
     +              0.056 , 0.919 , 0.025 ,           !  4   2
     +              0.042 , 0.923 , 0.035 ,           !  4   3
     +              0.034 , 0.897 , 0.069 ,           !  4   4
     +              0.040 , 0.960 , 0.000 ,           !  5   1
     +              0.051 , 0.939 , 0.010 ,           !  5   2
     +              0.070 , 0.913 , 0.017 ,           !  5   3
     +              0.077 , 0.890 , 0.033 /           !  5   4

C  'SIZEDIST' array: regional base HH size model.
C   (Derived from 2000 CTPP Table 1-62, SizeModel.xls).
C   Dimensions: SIZEDIST(size, avg size index)
C                                       DATA OK
C           HH size:    1     2     3     4     5+
      data sizedist/100.00,  0.00,  0.00,  0.00,  0.00,  ! 1.0
     +               90.03,  9.97,  0.00,  0.00,  0.00,  ! 1.1
     +               81.14, 17.38,  1.44,  0.04,  0.00,  ! 1.2
     +               75.71, 19.57,  3.38,  1.34,  0.00,  ! 1.3
     +               70.30, 21.75,  5.31,  2.64,  0.00,  ! 1.4
     +               65.52, 23.66,  6.42,  4.03,  0.37,  ! 1.5
     +               60.74, 25.57,  7.52,  5.43,  0.74,  ! 1.6
     +               55.97, 27.48,  8.63,  6.82,  1.10,  ! 1.7
     +               51.35, 30.72,  9.08,  6.10,  2.75,  ! 1.8
     +               45.49, 34.55,  9.98,  6.25,  3.73,  ! 1.9
     +               40.89, 36.51, 10.70,  7.59,  4.31,  ! 2.0
     +               37.84, 35.46, 12.92,  8.94,  4.84,  ! 2.1
     +               34.90, 35.18, 13.88, 10.25,  5.79,  ! 2.2
     +               31.90, 34.65, 15.37, 11.54,  6.54,  ! 2.3
     +               28.37, 34.97, 16.50, 12.65,  7.51,  ! 2.4
     +               25.14, 34.31, 18.20, 14.26,  8.09,  ! 2.5
     +               21.78, 34.48, 19.21, 15.79,  8.74,  ! 2.6
     +               19.47, 33.65, 19.68, 17.28,  9.92,  ! 2.7
     +               16.84, 33.09, 20.18, 18.67, 11.22,  ! 2.8
     +               15.93, 29.33, 22.03, 20.48, 12.23,  ! 2.9
     +               14.08, 28.38, 21.82, 21.98, 13.74,  ! 3.0
     +               12.29, 27.94, 21.33, 23.11, 15.33,  ! 3.1
     +               11.21, 25.73, 20.78, 25.43, 16.85,  ! 3.2
     +                9.87, 23.83, 22.30, 25.00, 19.00,  ! 3.3
     +                8.64, 22.63, 22.47, 24.37, 21.89,  ! 3.4
     +                7.62, 19.41, 24.96, 24.14, 23.87,  ! 3.5
     +                6.60, 16.19, 27.46, 23.91, 25.84,  ! 3.6
     +                5.59, 12.97, 29.94, 23.69, 27.81,  ! 3.7
     +                4.57,  9.74, 32.45, 23.46, 29.78,  ! 3.8
     +                3.55,  6.52, 34.94, 23.23, 31.76/  ! 3.9

C  'INCDIST' array: regional base HH income group model.
C   (Derived from 2000 CTPP Tables 1-66, 1-90, IncomeModel.xls).
C   Dimensions: INCDIST(income, mean income ratio index)
C                                       DATA OK
C   income group:       1      2      3      4         inc ratio
      data  incdist/ 66.00, 24.00, 10.00,  0.00,        ! 0.1
     +               56.00, 25.00, 15.00,  4.00,
     +               48.31, 25.40, 18.36,  7.93,
     +               38.49, 25.15, 21.50, 14.86,
     +               25.60, 26.91, 26.37, 21.12,        ! 0.5
     +               19.74, 24.25, 29.16, 26.85,
     +               13.14, 20.17, 30.15, 36.54,
     +               11.06, 17.22, 28.37, 43.35,
     +                9.19, 15.57, 27.00, 48.24,
     +                8.03, 13.13, 24.33, 54.51,        ! 1.0
     +                6.86, 10.22, 22.34, 60.58,
     +                5.82,  9.83, 21.53, 62.82,
     +                5.00,  8.18, 18.71, 68.11,
     +                4.72,  7.44, 17.13, 70.71,
     +                4.42,  7.41, 16.13, 72.04,        ! 1.5
     +                4.22,  7.00, 14.46, 74.32,
     +                3.90,  6.44, 14.47, 75.19,
     +                3.76,  5.87, 14.44, 75.93,
     +                3.65,  5.53, 14.29, 76.53,
     +                3.53,  5.19, 14.13, 77.15,        ! 2.0
     +                3.41,  4.84, 13.99, 77.76,
     +                3.02,  4.51, 13.79, 78.70,
     +                2.62,  4.17, 13.58, 79.63,
     +                2.47,  4.10, 13.19, 80.24,
     +                2.32,  4.03, 12.80, 80.85,        ! 2.5
     +                2.20,  3.99, 12.51, 81.30,
     +                2.08,  3.95, 12.22, 81.75,
     +                2.00,  3.97, 12.13, 81.91,
     +                1.92,  3.99, 12.03, 82.06,
     +                1.84,  3.99, 11.86, 82.32,        ! 3.0
     +                1.76,  3.98, 11.68, 82.58,
     +                1.41,  4.02, 11.63, 82.95,
     +                1.06,  4.05, 11.58, 83.32,
     +                0.70,  4.09, 11.52, 83.68,
     +                0.35,  4.12, 11.47, 84.05,        ! 3.5
     +                0.00,  4.16, 11.42, 84.42,
     +                0.00,  4.18, 11.32, 84.50/        ! 3.7

C  'PRATE' array: production model total person trip rates per HH
C   This is derived from the 2012 survey.
C   Dimensions:
C       PRATE(purpose, workers, lifecycle, income), for work-related
C       PRATE(purpose, size,    lifecycle, income), for non-work-related
C               (use "5" for the 2nd dimension, code as zeroes for
C               "workers=4", which doesn't exist)
C   Read the data into arrays PR1 and PR2 and equivalence them with
C   PRATE.                              DATA OK (2012 survey)        
c   PR1 is for incomes 1 and 2; PR2 is for incomes 3 and 4.
C     purpose:   HBW    SCH    HBU    HBS    HBO    JTW    ATW    NWK  !wsli
      data pr1/0.000, 0.000, 0.000, 0.800, 1.189, 0.000, 0.000, 0.538, !0111
     +         1.429, 0.000, 0.000, 1.610, 2.905, 0.000, 0.000, 0.585, !1211
     +         2.200, 0.000, 0.033, 2.240, 2.341, 0.000, 0.000, 0.613, !2311
     +         3.549, 0.000, 0.000, 2.558, 3.501, 0.000, 0.000, 0.613, !3411
     +         0.000, 2.016, 0.000, 3.239, 4.060, 0.000, 0.000, 0.613, !-511
     +         0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, !0121
     +         1.449, 1.582, 0.000, 0.337, 1.504, 0.400, 0.190, 0.422, !1221
     +         2.550, 1.689, 0.157, 1.406, 3.800, 1.055, 0.190, 1.795, !2321
     +         4.502, 2.825, 0.131, 1.511, 5.400, 1.055, 0.190, 1.948, !3421
     +         0.000, 4.046, 0.275, 1.995, 6.150, 0.000, 0.000, 2.300, !-521
     +         0.000, 0.000, 0.009, 0.700, 1.200, 0.000, 0.000, 0.616, !0131
     +         1.358, 0.000, 0.021, 1.416, 2.200, 0.329, 0.157, 0.926, !1231
     +         2.462, 0.000, 0.204, 1.675, 2.715, 0.329, 0.157, 0.926, !2331
     +         4.800, 0.000, 0.208, 2.106, 3.419, 0.329, 0.157, 0.926, !3431
     +         0.000, 0.000, 0.000, 1.000, 0.981, 0.000, 0.000, 0.926, !-531
     +         0.000, 0.000, 0.000, 0.896, 1.300, 0.000, 0.000, 1.000, !0112
     +         1.429, 0.000, 0.012, 1.610, 2.905, 0.400, 0.000, 1.400, !1212
     +         2.200, 0.000, 0.033, 2.240, 3.800, 0.410, 0.000, 2.312, !2312
     +         3.549, 0.100, 0.000, 2.558, 3.800, 0.256, 0.000, 2.312, !3412
     +         0.000, 2.016, 0.000, 5.000, 5.000, 0.000, 0.000, 2.312, !-512
     +         0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, !0122
     +         1.449, 1.582, 0.000, 0.387, 1.504, 0.490, 0.190, 1.000, !1222
     +         2.550, 1.689, 0.157, 1.406, 4.523, 1.055, 0.190, 2.025, !2322
     +         4.502, 2.825, 0.131, 1.511, 5.855, 1.055, 0.190, 2.701, !3422
     +         0.000, 4.046, 0.275, 1.995, 7.000, 0.000, 0.000, 4.100, !-522
     +         0.000, 0.000, 0.009, 0.780, 1.237, 0.000, 0.000, 1.080, !0132
     +         1.358, 0.000, 0.021, 1.416, 2.411, 0.329, 0.157, 1.180, !1232
     +         2.462, 0.000, 0.204, 1.675, 3.410, 0.550, 0.157, 2.109, !2332
     +         4.800, 0.000, 0.208, 2.106, 3.419, 0.530, 0.157, 2.109, !3432
     +         0.000, 0.000, 0.000, 1.700, 0.981, 0.000, 0.000, 2.109/ !-532
      data pr2/0.000, 0.000, 0.000, 0.896, 1.300, 0.000, 0.000, 1.000, !0113
     +         1.429, 0.000, 0.012, 1.610, 2.905, 0.400, 0.142, 1.400, !1213
     +         3.146, 0.188, 0.033, 2.500, 3.800, 0.410, 0.142, 2.312, !2313
     +         3.549, 0.209, 0.000, 2.558, 3.800, 0.256, 0.247, 2.312, !3413
     +         0.000, 2.016, 0.000, 5.000, 5.062, 0.000, 0.000, 2.312, !-513
     +         0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, !0123
     +         1.449, 1.582, 0.000, 0.700, 1.504, 0.490, 0.300, 1.829, !1223
     +         2.586, 1.689, 0.157, 1.406, 4.523, 1.055, 0.350, 2.025, !2323
     +         4.502, 2.825, 0.131, 1.511, 5.855, 1.055, 0.482, 2.701, !3423
     +         0.000, 4.046, 0.322, 1.995, 7.000, 0.000, 0.000, 4.100, !-523
     +         0.000, 0.000, 0.009, 0.780, 1.237, 0.000, 0.000, 1.080, !0133
     +         1.455, 0.000, 0.021, 1.416, 2.411, 0.329, 0.157, 1.180, !1233
     +         2.958, 0.000, 0.204, 1.675, 3.410, 0.550, 0.281, 2.109, !2333
     +         5.100, 0.000, 0.376, 2.106, 3.419, 0.530, 0.500, 2.109, !3433
     +         0.000, 0.000, 0.461, 2.200, 0.981, 0.000, 0.000, 2.109, !-533
     +         0.000, 0.000, 0.000, 0.896, 2.251, 0.000, 0.000, 1.418, !0114
     +         1.429, 0.000, 0.012, 1.610, 2.963, 0.407, 0.142, 1.400, !1214
     +         3.146, 0.209, 0.276, 2.500, 4.000, 0.593, 1.000, 2.471, !2314
     +         3.549, 0.209, 0.084, 2.558, 4.000, 0.427, 1.231, 2.471, !3414
     +         0.000, 2.679, 0.008, 5.300, 5.062, 0.000, 0.000, 3.900, !-514
     +         0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, !0124
     +         1.449, 1.582, 0.000, 0.700, 2.886, 0.578, 0.300, 1.829, !1224
     +         2.586, 1.689, 0.044, 1.406, 4.536, 1.099, 0.400, 2.025, !2324
     +         4.502, 2.825, 0.131, 1.511, 6.788, 1.163, 0.482, 2.701, !3424
     +         0.000, 4.046, 0.322, 1.995, 8.486, 0.000, 0.000, 4.100, !-524
     +         0.000, 0.000, 0.003, 0.780, 1.842, 0.000, 0.000, 1.250, !0134
     +         1.455, 0.000, 0.011, 1.416, 2.487, 0.363, 0.300, 1.400, !1234
     +         2.958, 0.000, 0.314, 1.675, 3.504, 0.829, 0.480, 2.109, !2334
     +         5.100, 0.000, 0.376, 2.106, 4.007, 0.989, 0.680, 2.109, !3434
     +         0.000, 0.000, 0.858, 2.200, 5.145, 0.000, 0.000, 2.109/ !-534

C  'ARATE' array: attraction model coefficients
C   This is derived from the 2012 survey.
C   Dimensions: ARATE(purpose, variable), where "variable" is:
C   1=HH, 2=POP_HHS, 3=LOIND emp, 4=HIIND emp, 5=RTL emp, 6=HWY emp
C   7=LOSVC emp, 8=HISVC emp, 9=OFFGOV emp, 10=EDUC emp, 11=STU_K8
c   enrollmt, 12=STU_HS enrollmt, 13=STU_CU enrollmt, 14=density
c   function, 15=median income, 16=CBD dummy.     

C  Also note that the NHB and Truck coefficients have already been cut
C   in half (from their originally calibrated values) to convert total
C   trip ends to true attractions.  See AttrResults.xls.
c  Note: the coefficients on income and on the density function ("dens")
c   have been modified.  See TGcheck.xls.  These coefficients were 
c   estimated using district-based data and needed to be adjusted in order
c   to be applied to zone-level data.  These rates have also been modified
c   in application so that the total A's match the total P's.

C  Purpose:
C       HBW   SCH   HBU   HBS   HBO   JTW   ATW   NWK   COM   MTK   HTK
      data arate/
     +0.000,0.000,0.000,0.472,1.687,0.000,0.000,0.538,0.146,0.099,0.038, !HH
     +0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000, !POP_HHS
     +0.710,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.454,0.266,0.139, !LOIND
     +0.710,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.454,0.266,0.139, !HIIND
     +1.591,0.000,0.000,2.469,2.731,0.200,0.553,2.299,0.501,0.253,0.065, !RTL
     +1.591,0.000,0.000,3.607,2.731,0.200,0.000,2.299,0.501,0.253,0.065, !HWY
     +0.597,0.000,0.000,0.000,0.000,0.050,0.542,0.000,0.454,0.068,0.009, !LOSVC
     +1.035,0.000,0.000,1.116,2.592,0.311,0.000,1.181,0.454,0.068,0.009, !HISVC
     +0.597,0.000,0.000,0.000,0.000,0.050,0.129,0.000,0.454,0.068,0.009, !OFFGOV
     +1.035,0.000,0.000,0.000,0.000,0.311,0.000,1.181,0.454,0.068,0.009, !EDUC
     +0.000,1.167,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000, !STUK8
     +0.000,2.965,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000, !STUHS
     +0.000,0.000,0.442,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000, !STUCU
     +0.000,0.000,0.000,0.000,0.093,0.045,0.000,0.050,0.000,0.000,0.000, !dens
     +0.000,0.000,0.000,0.000,0.000400,0.00,0.00,0.00,0.000,0.000,0.000, !medinc
     + 649.,    0,    0,-726.,    0,    0,    0,-342.,    0,    0,    0/ !cbd

C  'ATFACTP' array: adjustment factors for production model trip rates,
C   based on Area Type
C   Adjust so that the difference in factor between any
c     2 area types never exceeds 0.10.
C   Dimensions: ATFACTP(purpose, area type)
C  purpose:         HBW  SCH  HBU  HBS  HBO  JTW  ATW  NWK
      data atfactp/0.77,0.82,3.30,1.19,1.24,1.27,1.27,1.23,
     +             0.87,0.92,0.85,1.00,1.15,1.17,1.17,1.13,
     +             0.97,1.02,0.90,1.03,1.06,1.07,1.07,1.06,
     +             1.02,1.02,1.02,1.00,0.96,0.97,0.97,0.97,
     +             1.12,0.92,1.05,0.90,0.89,0.87,0.87,0.87/

C  'PFACT' array: adjustment factors for production model trip rates.
C   See TGcheck.xls.
C   Dimensions: PFACT(purpose,income).  
C  purpose:  HBW   SCH   HBU   HBS   HBO   JTW   ATW   NWK
      data pfact/
     +     0.887,0.793,1.016,1.297,1.060,0.730,0.733,0.926,  ! inc 1
     +     0.822,0.793,1.016,1.264,1.129,0.730,0.733,0.926,  ! inc 2
     +     0.718,0.793,1.016,0.931,0.830,0.730,0.733,0.926,  ! inc 3
     +     0.774,0.793,1.016,0.959,0.963,0.730,0.733,0.926/  ! inc 4

C  'ATFACTA' array: adjustment factors for attraction model trip rates,
C   based on Area Type
C   Dimensions: ATFACTA(purpose, area type)
C
C  purpose:    HBW  SCH  HBU  HBS  HBO  JTW  ATW  NWK  COM  MTK  HTK
      data atfacta/
     +        1.02,1.16,0.66,0.90,1.17,1.12,1.10,1.33,1.00,1.00,1.00,
     +        1.00,1.06,0.76,0.93,1.07,1.02,1.00,1.26,1.00,1.00,1.00,
     +        0.99,1.06,0.86,1.03,1.13,0.92,0.90,1.16,1.00,1.00,1.00,
     +        1.00,0.98,0.84,1.00,0.93,0.82,0.80,1.06,1.00,1.00,1.00,
     +        1.02,0.92,0.94,0.90,0.83,0.72,0.70,0.96,1.00,1.00,1.00/

C  'ACOEFAS' array: coefficients for submodel to split
C   Attractions by income.  Recalibrated from 2012 survey.
C   Dimensions: ACOEFAS[purpose (1-5), variable (1-10)]
c   Variables are: 1=bias 1, 2=bias 2, 3=bias 3, 4=CBD dummy (0/1),
c   5=% loind, 6=% hiind, 7=%rtl, 8=% hwy, 9=% losvc, 10=% educ.  
c   Purpose codes use the original codes, but codes 2 and 3 (SCH, 
c   HBU) aren't used -- they aren't split by income.
C
C         purpose:   HBW    SCH    HBU    HBS    HBO    var
      data acoefas/-0.66,  0.00,  0.00,  0.02, -0.07,  !1
     +             -0.67,  0.00,  0.00,  0.02, -0.08,  !2
     +             -0.70,  0.00,  0.00,  0.02, -0.05,  !3
     +             -0.71,  0.00,  0.00, -0.15,  0.20,  !4
     +              0.50,  0.00,  0.00,  1.50,  0.10,  !5
     +              1.70,  0.00,  0.00, -0.40,  0.00,  !6
     +              0.00,  0.00,  0.00, -0.90,  0.00,  !7
     +              0.00,  0.00,  0.00, -1.50,  0.00,  !8
     +              4.50,  0.00,  0.00,  0.70,  0.50,  !9
     +              1.50,  0.00,  0.00,  0.00,  0.00/  !10

C  'BASVOL' array: base (2010) 2-way daily (avg. weekday) volumes
C    at each external station, by vehicle type (1=auto, 2=COM, 3=MTrk,
c    4=HTrk).  Source: CDOT.  Updated 23 May 2013.    DATA OK
c         type:          Auto       COM       MTK       HTK
      data basvol /     729,       55,       55,       36,
     +                 1061,       80,       57,       21,
     +                  105,        8,       12,        0,
     +                  429,       32,       63,       11,
     +                 1690,      127,      134,       31,
     +                 1453,      109,       76,       63,
     +                 1061,       80,       57,       21,
     +                  183,       14,       28,        0,
     +                  673,       51,       20,       12,
     +                 8742,      489,     2632,      611,
     +                  671,       50,       56,       12,
     +                 9933,      748,      734,     2334,
     +                 2643,      199,      168,      313,
     +                  666,       50,       37,        4,
     +                  851,       64,      132,       83,
     +                  248,       19,       36,       18,
     +                 3208,      349,      863,      332,
     +                  294,       22,       19,        7,
     +                 2333,      354,      809,      163,
     +                  707,       53,       38,        6,
     +                 4820,      362,      301,       59,
     +                26973,     2030,     1177,     8066,
     +                 4598,      454,      974,      300,
     +                 2163,      163,      213,       31,
     +                 1556,      100,       39,        5,
     +                 2088,      135,       77,       77,
     +                 2441,      184,      175,       72,
     +                 1427,      107,      116,       81,
     +                 8170,      519,      265,      226,
     +                 8659,      652,      434,      148,
     +                 3851,      488,      547,      247,
     +                18683,     1406,      972,     1988,
     +                 4205,      317,      163,      133,
     +                 3883,      292,      483,      198,
     +                  670,       50,       40,       10,
     +                31181,     2347,     1603,    11683,
     +                 2742,      206,      114,       45,
     +                  756,       49,       28,       28,
     +                 1176,       88,      134,       45,
     +                21039,     1584,      949,     3067,
     +                 3623,      273,      256,      106,
     +                 8262,      631,      272,      231,
     +                 5603,      362,      203,      205,
     +                 2285,      172,      124,       24,
     +                12621,      858,     4469,      623,
     +                 2648,      398,      798,      305,
     +                 6546,      529,      321,      487,
     +                 7664,      577,     1121,      552,
     +                 1601,      121,      128,      240,
     +                 1286,       82,       30,        5,
     +                  974,       73,      169,       58,
     +                 2626,      346,     1547,       82,
     +                 3941,      250,      128,      109,
     +                59611,     3691,     2857,     6842,
     +                 3925,      295,      173,      106,
     +                  951,       72,      140,       48,
     +                 5561,      419,      727,     1025,
     +                 4602,      346,      272,       70,
     +                42607,     3207,     1869,     9019,
     +                 2474,      186,      143,       54,
     +                10955,      825,     1036,      256,
     +                 1200,       77,       39,       34,
     +                  956,       72,      165,       43,
     +                  873,       66,       42,       10,
     +                  298,       22,       29,        8,
     +                    540*0/	

C  'BTHRUV' array: base (2010) through trip ends by external station
C   and vehicle type.  Source: CDOT.  Updated 3 Jul 13 (see 
c   cal\TD\xxTE.dat and buildXX.s).
c   type:       Auto     COM     MTK     HTK
      data bthruv /0,      0,      0,      0,   
     +            35,     11,      0,      0,   
     +             0,      0,      0,      0,   
     +             0,      0,      0,      0,   
     +            30,      9,      0,      0,   
     +            24,      9,      0,      0,   
     +             0,      0,      0,      0,   
     +             0,      0,      0,      0,   
     +             0,      0,      0,      0,   
     +           566,     32,    232,     67,   
     +             0,      0,      0,      0,   
     +          1977,    209,    332,    815,   
     +           176,     32,     38,     42,   
     +             0,      0,      0,      0,   
     +            20,      9,      0,      0,   
     +             0,      0,      0,      0,   
     +           277,     30,     44,     46,   
     +             0,      0,      0,      0,   
     +           394,     58,    134,    119,   
     +             0,      0,      0,      0,   
     +           334,     25,     69,     10,   
     +          5580,    458,    414,   3307,   
     +           102,     10,      0,     12,   
     +            28,     10,      0,      0,   
     +            24,      8,      0,      0,   
     +            20,      9,      0,      0,   
     +            30,      8,      0,      8,   
     +            18,      9,      8,      0,   
     +           234,     25,     13,     12,   
     +           758,     84,     52,     26,   
     +           413,     52,      0,     93,   
     +          2382,    228,    146,    500,   
     +            50,      9,      7,      6,   
     +           476,     46,    145,     62,      
     +             0,      0,      0,      0,   
     +         14186,   1022,   1048,   4155,   
     +            28,     10,      8,      0,   
     +             0,      0,      0,      0,   
     +             0,      0,      0,      0,   
     +          1722,    151,    133,    111,
     +           416,     21,      0,     38,
     +           245,     22,     18,     21,
     +           199,     20,     14,     11,
     +            30,      9,      0,      0,   
     +          1063,     72,    284,    199,
     +           183,     27,    144,    147,
     +           154,     10,     40,    106,
     +           344,     25,      0,     41,   
     +            30,     11,      9,      0,   
     +             0,      0,      0,      0,
     +            10,      9,      0,      0,
     +           135,     18,     40,     62,   
     +            59,     11,      8,      8,
     +         13552,    983,   1277,   3434,   
     +            13,     12,      3,      2,
     +           105,     21,     23,     15,
     +           330,     40,     20,     22,   
     +            54,     12,     10,     10,   
     +          9078,    760,   1173,   4401,   
     +            36,      9,      8,      7,
     +          1070,    110,     42,     21,
     +            16,      0,      0,      0,   
     +            18,      9,      0,      0,   
     +             0,      0,      0,      0,   
     +             0,      0,      0,      0,
     +   540*0/

c  'EXTADJ' array: adjustments to external share models, in order
c   to make the base year (2010) estimates match the cordon counts.
c   Array is (vehicle type 1-5, direction 1-2), where direction 1
c   is I/E and direction 2 is E/I.

c                 wk auto nw auto     com     mtk     htk
      data extadj/ 0.8585, 1.4755, 0.3600, 0.9050, 3.2500,      ! I/E
     +             0.6380, 0.2790, 0.2134, 0.5390, 1.4500/      ! E/I

c  'LCFAC' array: adjustments to life cycle model, in order to 
c   reflect substantial differences in the Charlotte Uptown area.
c   Array is (lifecycle, income).  Adjustments are derived from 
c   2012 survey; see LifeCycle.xlsx.

c        lifecycle   1     2     3
      data lcfac/ 0.89, 1.82, 0.81,	! inc 1
     +            1.02, 0.00, 1.36,	! inc 2
     +            0.73, 0.00, 1.58,	! inc 3
     +            0.74, 0.30, 1.53/	! inc 4

C--------------------------------------------------------------------
C  Start the program.
C  Version number and release date.
      verinfo='1.2.1  21 Jan 14'

C  Get system date and time for the listing header.

      call getdat(yr,mon,day)
      call gettim(hr,min,sec,hun)

C Check command line for setup file name.
      call getarg(1,control,stat1)
      if(stat1.le.0) then
        write(*,'(/'' Version '',a17)') verinfo
        write(*,'('' Usage:   tgmet [control-file]'')')
        stop "Enter the driver file name on the command line."
      end if

      write(*,50) verinfo
   50 format(' TGMET Program Version ',a16/)

C  Open the setup (a.k.a. "driver") file.  This contains some 
C    parameters in a NAMELIST.  The setup file MUST be 
C    named on the program's command line, like so:  
C    TGMET SETUP.SET

C  The first line of the driver file is an 80-character title, to
C    be placed on all pages of the printed output.

C  Driver file parameter definitions:

C  FILES
c   input
C    sefile      = zonal land use data file
c    distcorfile = zonal distance to the cordon file
c    distcbdfile = zonal distance to the CBD file (not used, but
c	variable retained in code)
c    xvolfile    = external station volume file
c    pumafile    = TAZ/PUMA equivalency file
c   output
c    prodfile    = productions file
c    attrfile    = attractions file
c    xxfile      = through trip growth factor file
c    hhfile      = file of individual HH records
C    list        = listing file
C  PARAMETERS
C    avg5per  = average persons/HH for HHs with 5+ persons [5.54]
C    empfactor= regional ratio of labor force (resident workers)
c       to employees [0.8740]
C    repo(1)= switch to print report of input "seed" arrays [T]
C    repo(2)= switch to print report of HH's by breakdowns [T]
C    repo(3)= switch to print report of trip end normalization [T]
C    repo(4)= switch to print report of trip ends [T]
C    repo(5)= switch to print report of trip ratios [T]
C    repo(6)= switch to print zonal data [T]
C    repo(7)= switch to print future cordon volume report [T]
C    repo(8)= switch to print Through trip factors [T]
C    tfactor(1) = final factor to be applied to HBW trip ends [1.0]
C    tfactor(2) = final factor to be applied to SCH trip ends [1.0]
C    tfactor(3) = final factor to be applied to HBU trip ends [1.0]
C    tfactor(4) = final factor to be applied to HBS trip ends [1.0]
C    tfactor(5) = final factor to be applied to HBO trip ends [1.0]
C    tfactor(6) = final factor to be applied to JTW trip ends [1.0]
C    tfactor(7) = final factor to be applied to ATW trip ends [1.0]
C    tfactor(8) = final factor to be applied to NWK trip ends [1.0]
C    tfactor(9) = final factor to be applied to COM trip ends [1.0]
C    tfactor(10)= final factor to be applied to MTK trip ends [1.0]
C    tfactor(11)= final factor to be applied to HTK trip ends [1.0]
c    iewrkavo   = I/E work average vehicle occupancy [1.182]
c    ienwkavo   = I/E non-work average vehicle occupancy [1.666]
c    eiwrkavo   = E/I work average vehicle occupancy [1.172]
c    einwkavo   = E/I non-work average vehicle occupancy [1.556]
c    begtr      = beginning zone number to trace [none]
c    endtr      = ending zone number to trace [none]
C    zTAZ-zAREA = variable position in the S/E data file of the
C		  model-defined variables
C  COEFFS
C    prate   = 8x5x3x4 array of production trip rates/HH
C    arate   = 11x16 array of attraction equation coefficients
C    acoefas = 5x5 array of acc. attraction split coefficients
C    atfactp = 8x5 array of Area Type production rate adjustment factors
C    atfacta = 10x5 array of Area Type attraction rate adj factors
C    gqfact  = 8x2 array of Group Quarters trip rates per person
C    pfact   = 8x4 array of production rate factors by inc & purpose
C    extadj  = 5x2 array of external model adj factors
C    siseed  = 4x5x15 array of seed matrix of HHs by income, size, PUMA
C    basvol  = 4x200 array of base (2010) cordon volume by station
C    bthruv  = 4x200 array of base (2010) cordon EE volume by station
C  SPECIAL
C    specgenzone = 30x11 array of special gen zone numbers by purpose
C    specgenprod = 30x11 array of special gen productions by purpose
C    specgenattr = 30x11 array of special gen attractions by purpose
C  EQUIV
C    cbd     = list of up to 100 zone numbers in the Charlotte CBD
C    uptown  = list of up to 100 zone numbers in the Uptown area

      istop = 0
      begtr = 0
      endtr = 0
      open(5,err=105,file=control,status='old',form='formatted')
      read(5,100) (title(i),i=1,10)
  100 format(10a8)
      read(5,files)
      rewind 5
      read(5,parameters)
      rewind 5
      read(5,coeffs)
      rewind 5
      read(5,special)
      rewind 5
      read(5,equiv)
      go to 114
  105 write(*,110)
  110 format(' TGMET 110 (F): Cannot find the specified setup/',
     +  'driver file.  I quit.'/)
      stop "Enter the setup/driver file name on the command line."

C  Open output listing file (will overwrite existing file).

  114 open(6,file=list,status='unknown')
      write(6,120) (title(i),i=1,10),day,month(mon),yr,hr,min,sec,
     + page
  120 format(10a8//i2,1x,a4,i4,2x,i2,1h:,i2.2,1h:,i2.2,16x,'TGMET',
     +  29x,'Page ',i3/)

C  Rewind driver file and echo to the output listing.

      rewind 5
      do while (.NOT. eof(5))
        read (5,100,end=121) (scard(i),i=1,10)
        write (6,100) (scard(i),i=1,10)
      end do
  121 continue

C  If the specified input files do not exist, quit.

      write(*,'('' Checking input files.'')')

      do 138 t = 1,5
        fil(t) = 0
  138 continue
      call findit (sefile,names(1),fil(1))
      call findit (xvolfile,names(2),fil(2))
      call findit (distcorfile,names(3),fil(3))
c      call findit (distcbdfile,names(4),fil(4))
      call findit (pumafile,names(5),fil(5))
      totfil = fil(1) + fil(2) + fil(3) + fil(4) + fil(5)

      if (totfil .gt. 0) then
        write(6,140)
  140   format('TGMET 140 (F): Cannot find required files.  I quit.')
        stop "A fatal error has occurred.  Please check listing file."
      end if

C  Open the files.  Output files will overwrite any existing
C   files of the same name, without warning.  Unit assignments:
C               INPUT                           OUTPUT
C    1 = zonal S/E data file            6 = listing
C        (CSV format)                   7 = productions
C    2 = external station volume file   8 = attractions
C    3 = distance to cordon file        9 = scratch for size/inc data
C    4 = dist. to CBD file (NOT USED)   10= scratch for prods
C    5 = setup file                     11= scratch for initial attrs
C   15 = area type file                 12= scratch for adjusted attrs
C   21 = PUMA equiv file                13= scratch for attr by pur&inc
C                                       14= scratch for normalized attr
c                                       16= X/X growth factor file
c                                       17= production DCC
c                                       18= attraction DCC
c                                       19= X/X factor DCC
c                                 reuse 21= individual HH file
c                                       22= individual HH DCC

C If REPO(1) = T, print size/income regional seed matrix.

      if (repo(1)) then
        call header
	  write(6,144)
  144   format(/' ',35x,'Report 1'/' ',29x,'Report of Input Arrays'//
     +    ' ',18x,'Proportion of Households by Income and Size'//)
        do p = 1,15
          write(6,145) p,(stitl(s),s=1,5),((siseed(i,s,p),s=1,5),i=1,4)
  145     format(' ','PUMA ',i2,35x,'Persons'/' ',t27,5(4x,a4)/
     +      '   lowest 10%',t27,
     +      5f8.4/'   11-25 %ile    ',t27,5f8.4/'   26-50 %ile     ',
     +      t27,5f8.4/'   upper 50%  ',t27,5f8.4/)
        end do
      end if

      write(*,'('' Opening input files.'')')
      open(1,file=sefile,status='old',form='formatted')
      open(2,file=xvolfile,status='old',form='formatted')
      open(3,file=distcorfile,status='old',form='formatted')
      open(15,file=atfile,status='old',form='formatted')

C If user used undocumented SAVESCR switch, save scratch files.
      if (savescr) then
        open (9,file='temp9a.scr',status='unknown',form='formatted')
        open(10,file='temp10.scr',status='unknown',form='formatted')
        open(11,file='temp11.scr',status='unknown',form='formatted')
        open(12,file='temp12.scr',status='unknown',form='formatted')
        open(13,file='temp13.scr',status='unknown',form='formatted')
        open(14,file='temp14.scr',status='unknown',form='formatted')
      else
        open (9,status='scratch',form='formatted')
        open(10,status='scratch',form='formatted')
        open(11,status='scratch',form='formatted')
        open(12,status='scratch',form='formatted')
        open(13,status='scratch',form='formatted')
        open(14,status='scratch',form='formatted')
      end if

C If we're debugging, print out the production trip rates.

      if (begtr.gt.0 .or. endtr.gt.0) then
        write(6,9038)
 9038   format(' TGMET Trace 9038: Production Trip Rates'/
     1   ' Purp  W/S  Life  Inc     Rate'/)
        do 9037 p = 1,8
        do 9037 s = 1,5
        do 9037 l = 1,3
        do 9037 i = 1,4
	    s2 = s
	    if (p .eq. 1) s2 = s - 1
          write(6,9008) purcode(p),s2,l,i,prate(p,s,l,i)
 9008     format(' ',a4,3x,i1,4x,i1,5x,i1,3x,f7.3)
 9037   continue
      end if

      if (begtr.gt.0 .or. endtr.gt.0) then
        write(6,9062)
 9062   format(/' TGMET Trace 9062: External Model Adj Factors'/)
        do 9063 i = 1,5
        do 9063 j = 1,2
          write(6,9064) i,j,extadj(i,j)
 9064     format(' ','purpose: ',i2'  direction: ',i2,f10.4)
 9063   continue
      end if
      
C--------------------------------------------------------------------
C Read zonal SE file and store data in the Z array.
c Z array  Variable             Z array  Variable
c (Input)
c   1      TAZ                  12       HISVC 
c   2      POP_TOT              13       OFFGOV
C   3      POP_HHS              14       EDUC
C   4      POP_GRP              15       EMP_TOT
C   5      HH                   16       STU_K8
C   6      MED_INC              17       STU_HS
C   7      LOIND                18       STU_CU
C   8      HIIND                19       DORM
C   9      RTL                  20       AREA
C  10      HWY                  
C  11      LOSVC                
c (Calculated)
c  23      income ratio
c  24      special generator flag
c  25      CBD flag
c  26      distance to cordon
c  27      distance to CBD
c  28      area type
c  29      density function
c  30      % RTL + HWY employment
c  31      Uptown flag

      write(*,'('' Reading zonal data.''/)')
      
c Find how many fields we have to read from the S/E file in order
c  to get all of the model variables.  Can't read more than 50.
c  Then, read the first (header) record but don't do anything with
c  it.

      nfld = max(zTAZ,zPOP_TOT,zPOP_HHS,zPOP_GRP,zHH,zMED_INC,zLOIND,
     + zHIIND,zRTL,zHWY,zLOSVC,zHISVC,zOFFGOV,zEDUC,zEMP_TOT,zSTU_K8,
     + zSTU_HS,zSTU_CU,zDORM,zAREA)
     
      if (nfld .gt. 50) then
        write(6,9049) nfld
 9049   format(' TGMET 9049 (F): User specified reading past ',
     +    'field 50 on input S/E file.  I quit.')
      stop "A fatal error has occurred.  Please check listing file."
      endif
      read(1,*) (zname(i),i=1,nfld)
      
c INTZONES is the number of internal zones.  This will be equal to 
c  the number of S/E data records.

      intzones = 0
      
  150 read(1,*,err=9050,end=158) (zdat(i),i=1,nfld)
      intzones = intzones + 1
      go to 155
      
 9050 write(6,9051)
 9051 format(' TGMET 9051 (F): Problem reading from S/E file.')
      stop "A fatal error has occurred.  Please check listing file."

c On input S/E file, fields can be in any order.  Here, put the
c  S/E variables in the Z array in the proper columns.  Change on 
c  1 Apr 2013: Area is now input in whole acres, reduced 25% from
c  the previous values to account for land area only (per JM).
  155 z(1,intzones) = zdat(zTAZ)
      z(2,intzones) = zdat(zPOP_TOT)
      z(3,intzones) = zdat(zPOP_HHS)
      z(4,intzones) = zdat(zPOP_GRP)
      z(5,intzones) = zdat(zHH)
      z(6,intzones) = zdat(zMED_INC)
      z(7,intzones) = zdat(zLOIND)
      z(8,intzones) = zdat(zHIIND)
      z(9,intzones) = zdat(zRTL)
      z(10,intzones)= zdat(zHWY)
      z(11,intzones)= zdat(zLOSVC)
      z(12,intzones)= zdat(zHISVC)
      z(13,intzones)= zdat(zOFFGOV)
      z(14,intzones)= zdat(zEDUC)
      z(15,intzones)= zdat(zEMP_TOT)
      z(16,intzones)= zdat(zSTU_K8)
      z(17,intzones)= zdat(zSTU_HS)
      z(18,intzones)= zdat(zSTU_CU)
      z(19,intzones)= zdat(zDORM)

c Convert area from acres back to sq mi.
      z(20,intzones)= zdat(zAREA) / 640

      go to 150
  
c Go through the zonal data and accumulate some totals.

  158 istop = 0
      do n = 1,5
        regtot(n) = 0.0
      end do

      do iz = 1,intzones
	  itaz = z(1,iz)
        
c Calculate "density function".  This is a combination of HH and
c  employment density.

        if (z(20,iz) .lt. 0.0001) then
          write(6,160) itaz
  160     format(' TGMET 160 (F): Area is zero for zone ',i5,
     +      '  I quit.')
          stop "A fatal error has occurred.  Please check listing file."
        else
          z(29,iz) = 0.0
          if(z(5,iz)+z(15,iz) .gt. 0.0001)
     *      z(29,iz) = 100 * log((1000*z(15,iz) + 1900*z(5,iz))/z(20,iz))
        end if

c        if (begtr .gt. 0) then
c          write(6,9054) itaz,z(29,iz)
c 9054     format(' TGMET Trace 9054: density function calc, taz: ',i5,
c     +      ' = ',f15.3)
c        end if

c Calculate % RTL+HWY employment.  This is used in the model to
c  split attractions by income.  Store in z(30,iz).

        z(30,iz) = 0.0
        if (z(15,iz) .gt. 0.01) z(30,iz) = (z(9,iz)+z(10,iz))/z(15,iz)

c Fill TAZZONE array.  This gives me a pointer from the TAZ back to
c  the sequential zone number.  Z(1,iz) gives me the pointer from
c  the sequential number to the TAZ.

        if (z(1,iz) .le. maxzone) then
          tazzone(z(1,iz)) = iz
        else
          write(*,165) itaz
  165     format(' TGMET 165 (F): input zone number exceeds ',
     1      'program limit of 30000: ',i6,'  I quit.')
          stop "A fatal error has occurred. Please check listing file."
        endif

C Accumulate regional totals of employees, HHs, persons in HHs,
C  total persons, HH income.

        regtot(1) = regtot(1) + z(15,iz)			! tot emp
        regtot(2) = regtot(2) + z(5,iz)			! hh
        regtot(3) = regtot(3) + z(3,iz)			! hh pop
        regtot(4) = regtot(4) + z(2,iz)			! tot pop
        regtot(5) = regtot(5) + z(5,iz)*z(6,iz)	! hh*inc

        if (z(1,iz).ge.begtr .and. z(1,iz).le.endtr) then
	    itaz = z(1,iz)
          write(6,9011) itaz,(z(j,iz),j=1,20),z(29,iz),z(30,iz),
     +      intzones
 9011     format(' TGMET Trace 9011: zone= ',i7,'  zonal data array'/
     +      3x,10f7.0/3x,9f7.0,f7.4/3x,2f10.3/' INTZONES= ',i5/)
        end if

      end do

      close (1)

c Calculate the regional median HH income as the HH-weighted average.
c  (2013: income measure changed from Mean to Median)

      regavginc = regtot(5)/regtot(2)

C Divide each zone's median HH income by the calculated median HH income.
C  If income value is zero for any zone with HHs, print
C   warning and use 1.0 for the income ratio.

      do iz = 1,intzones
        itaz = z(1,iz)
        if (z(6,iz) .lt. 0.01 .and. z(5,iz) .gt. 0.01) then
          write(6,170) itaz
  170     format(' TGMET 170 (W): Zero HH income for zone ',
     1      i5/5x,'Substituting the regional median.')
          z(23,iz) = 1.0
        else
          z(23,iz) = z(6,iz)/regavginc
        end if

        if (itaz.ge.begtr .and. itaz.le.endtr) then
          write(6,9012) itaz,z(6,iz),z(23,iz),regavginc
 9012     format(' READZONAL Trace 9012: zone= ',i5,'  income: ',
     +      f8.0, '  inc ratio: ',
     +      f6.3/'  regional median inc: ',f7.0)
        end if
      end do

C--------------------------------------------------------------------
C Read the sequential PUMA number from a separate ASCII file.  Store
C  it for each zone.  First, read the header record.

      open(21,file=pumafile,status='old',form='formatted')
      read(21,175) control
  175 format(a80)
  
  180 read(21,177,end=182) itaz,pumano
  177 format(i9,9x,i9)
      iz = tazzone(itaz)
      if (iz .gt. 0) tazpuma(iz) = pumano
      go to 180
  182 continue  
      close (21)

	write(*,'('' Finished with PUMA data.''/)')

C--------------------------------------------------------------------
C Read the area type from a separate ASCII file.

  185 read(15,*,end=192) itaz,atype

      iz = tazzone(itaz)
      if (iz .gt. 0) z(28,iz) = atype
      go to 185
  192 continue
      close (15)
      write(*,'('' Finished with AT data.''/)')
      if (istop .EQ. 1)
     +  stop "A fatal error has occurred. Please check listing file."
     
C--------------------------------------------------------------------
C Store the special generator flag in the Z array, element 24.

      do 195 zz = 1,30
      do 195 p = 1,11
        m = specgenzone(zz,p)
        if (m .eq. 0) cycle
        n = tazzone(m)
        if (n .gt. 0) z(24,n) = 1.0
  195 continue
	write(*,'('' Finished with Spec Gen data.''/)')
C--------------------------------------------------------------------
C Store the CBD flag in the Z array.  Z(25,iz) = 1.0 if the zone
C  is in the CBD.  Use EQUIV NAMELIST like so:
C  &EQUIV cbd = 1,5,56,140,-144 /

      rewind 5
  200 do n = 1,100
        cbd(n) = 0
      end do
      read(5,equiv,end=210)
      do n = 1,100
        if (cbd(n) .eq. 0) go to 200
        k = tazzone(abs(cbd(n)))
        if (cbd(n) .lt. 0) then
          t = 1 * k
        else
          z(25,k) = 1.0
          zz = k
          cycle
        end if
        do i = zz,t
          z(25,i) = 1.0
        end do
      end do
      go to 200
  210 continue
  
C Same for the Uptown flag.  Store in z(31,iz).

      rewind 5
  215 do n = 1,100
        uptown(n) = 0
      end do
      read(5,equiv,end=220)
      do n = 1,100
        if (uptown(n) .eq. 0) go to 215
        k = tazzone(abs(uptown(n)))
        if (uptown(n) .lt. 0) then
          t = 1 * k
        else
          z(31,k) = 1.0
          zz = k
          cycle
        end if
        do i = zz,t
          z(31,i) = 1.0
        end do
      end do
      go to 215
  220 continue

C--------------------------------------------------------------------
C Read the external station volume file.  Read the
C  input data into STAVOL, by vehicle type: 1=auto,
c  2=COM, 3=MTK, 4=HTK.  This is the TOTAL cordon volume
c  (External + E/E).

      n = 1
  230 read(2,*,end=250) itaz,(stavol(p,n),p=1,4)

c Store TAZ number in TAZZONE and sequential zone number in Z(1,iz).

      tazzone(itaz)  = intzones + n
      z(1,intzones+n) = itaz

      if (n .gt. 200) then
        write(6,240)
  240   format(' TGMET 240 (F): More than 200 external stations.',
     +    '  I quit.'/)
        stop "A fatal error has occurred.  Please check listing file."
      end if

      if (begtr .gt. 0) then
        write(6,9053) n,itaz,tazzone(itaz),(stavol(p,n),p=1,4)
 9053   format(' TGMET Trace 9053 of external volume read'/
     +    5x,' sta no.:',i4,'  taz:',i6,'  seq no.:',i6,
     +    '  vols1-4:',4f7.0)
      end if
      n = n + 1

      go to 230
  250 close (2)

c Now calculate ZONES as the number of total zones: internal
c  + external.  Check for max limit of 5000 internal zones.

      nsta  = n - 1
      zones = intzones + nsta
      if (intzones .LE. 0 .OR. intzones .GT. 5000) then
        write(6,255) intzones
  255   format(' TGMET 255 (F): More than 5000 internal zones: ',
     +   i6,'  I quit.'/)
        stop "A fatal error has occurred.  Please check listing file."
      end if

C--------------------------------------------------------------------
c Read the file with the distance to the cordon (store in z(26,iz))

  260 read(3,*,end=280) itaz,yi,yrl
      iz = tazzone(itaz)
      if (iz .lt. 1 .or. iz .gt. 5000) go to 260
      if (yrl .lt. 0.000 .or. yrl .gt. 100.0) then
        write(6,275) itaz,yrl
  275   format(' TGMET 275 (F): Bad distance to cordon for zone ',
     +    i5,'  value: ',f8.2,'  I quit.')
        stop "A fatal error has occurred.  Please check listing file."
      else
        z(26,iz) = yrl
      end if

      if (itaz .ge. begtr .and. itaz .le. endtr) then
        write(6,9059) itaz,z(26,iz),intzones,nsta,zones
 9059   format(' TGMET Trace 9059: Dist to cordon for taz= ',i5,
     +    '  = ',f6.2/' ',5x,'Intzones= ',i5,'  No. Sta.= ',i5,
     +    '  Tot Zones= ',i5/)
      endif

      go to 260
  280 continue

C--------------------------------------------------------------------
c Read the file with the distance to the CBD (store in z(27,iz))
c  Note: as of 25 Aug 05, this file is no longer used in the model.
c  But, keep the code in for possible future use.

c      ymin = 999.9
c  290 read(4,*,end=297) itaz,yi,yrl
c      iz = tazzone(itaz)
c      if (iz .lt. 1 .or. iz .gt. 5000) go to 290
c      if (yrl .lt. 0.000 .or. yrl .gt. 100.0) then
c        write(6,295) itaz,yrl
c  295   format(' TGMET 295 (F): Bad distance to CBD for zone ',
c     +    i5,'  value: ',f8.2,'  I quit.')
c        stop "A fatal error has occurred.  Please check listing file."
c      else
c        z(27,iz) = yrl
c      end if

c This input value can logically be zero, but that is unacceptable
c  to the model.  Reset zero values as half the minimum value
c  (other than zero), encountered up to that point in the input stream.

c      if (yrl .gt. 0.0001) then
c        if (yrl .lt. ymin) ymin = yrl
c      else
c        z(27,iz) = ymin/2.0
c      endif

c      if (itaz .ge. begtr .and. itaz .le. endtr) then
c        write(6,9049) itaz,ymin,z(27,iz)
c 9049   format(' TGMET Trace 9049: Dist to CBD for taz= ',i5/
c     +    '  Minimum distance = ',f6.2,'  Dist for this zone = ',f6.2/)
c      endif

c      go to 290
c  297 continue

c--------------------------------------------------------------------
C  Start first loop.

      do 700 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,302) itaz
  302   format('+','TGMET  302 (N): Loop  1 - processing zone ',i5)

C  Initialize for this zone, but if no HHs, jump to the end.

        hh       = z(5,iz)
        hhpop    = z(3,iz)
        do s = 1,5
          spct(s) = 0.0
          do i = 1,4
            ctot(i)     = 0.0
            ipct(i)     = 0.0
            sizinc(s,i) = 0.0
            do l = 1,3
              sizinclif(s,i,l) = 0.0
            end do
          end do
        end do
        if (hh .eq. 0) go to 640

C--------------------------------------------------------------------
C  Determine HH's by size and income.  First, calculate average
C   HH size for this zone.

  312   perhh = hhpop/hh
        if (perhh .gt. 3.9) perhh = 3.9
        if (perhh .lt. 1.0) perhh = 1.0

C  Now, calculate the desired row (HH size) shares.

  315   lind  = INT(10.0*perhh - 9.0)
	  hind  = lind + 1
        low   = 0.9 + 0.10*float(lind)
        high  = 0.9 + 0.10*float(hind)
        range = high - low
        ratio = 0.0
        if (range .gt. 0.001) ratio = (perhh - low)/range
        if (lind .lt. 1) lind  = 1
        if (hind .gt. 30) hind = 30
        do s = 1,5
          spct(s) = 0.01 * (sizedist(s,lind) +
     +              ratio* (sizedist(s,hind) - sizedist(s,lind)))
        end do

C  Ensure that total percentages sum to 1.0.

        csum = spct(1)+spct(2)+spct(3)+spct(4)+spct(5)
        diff = abs(csum - 1.000)
        if (diff .gt. 0.001) then
          do s = 1,5
            spct(s) = spct(s)/csum
          end do
        end if

C  Calc. desired row totals.  Do not round -- leave as Real.

        do s = 1,5
          size(s) = hh * spct(s)
        end do

      if (itaz.ge.begtr .and. itaz.le.endtr) then
        write(6,9002) itaz,perhh,(spct(s),s=1,5),(size(s),s=1,5)
 9002   format(' TGMET Trace 9002: taz=',i5,' per/hh= ',f6.3,
     +    ' size % = ',5f5.2/5x,'HHs by size= ',5f8.3)
      end if

C--------------------------------------------------------------------
C  Now, calculate HHs by income group.

  342   incrat = z(23,iz)
        if (incrat .gt. 3.7) incrat = 3.7
        if (incrat .lt. 0.1) incrat = 0.1

C  Now, calculate the desired column (income group) shares.

  345   lind  = INT(10.0*incrat)
	  hind  = lind + 1
        low   = 0.10*float(lind)
        high  = 0.10*float(hind)
        range = high - low
        ratio = 0.0
        if (range .gt. 0.001) ratio = (incrat - low)/range
        if (lind .lt. 1) lind  = 1
        if (hind .gt. 37) hind = 37
        do i = 1,4
          ipct(i) = 0.01 * (incdist(i,lind) +
     +              ratio* (incdist(i,hind) - incdist(i,lind)))
        end do

C  Ensure that total percentages sum to 1.0.

        csum = ipct(1)+ipct(2)+ipct(3)+ipct(4)
        diff = abs(csum - 1.000)
        if (diff .gt. 0.001) then
          do i = 1,4
            ipct(i) = ipct(i)/csum
          end do
        end if

C Calc. desired column totals.  Again, leave as Real.

        do i = 1,4
          income(i) = hh * ipct(i)
        end do

      if (itaz.ge.begtr .and. itaz.le.endtr) then
        write(6,9003) itaz,incrat,(ipct(i),i=1,4),(income(i),i=1,4)
 9003   format(' TGMET Trace 9003: taz=',i5,' inc ratio= ',f5.3,
     +    ' income %=',4f6.3/5x,'initial HHs by income = ',4f8.3)
      end if

C--------------------------------------------------------------------
C Calc. initial joint distribution matrix [JOINT(size,income)]
C   and get initial row totals.  Loops are indexed on size (S) and
C   income (I).  Initial joint distribution is now stratified by
C   PUMA, which we have to look up.

        p = tazpuma(iz)

        do s = 1,5
          rtot(s) = 0.0
        end do
        do 370 s = 1,5
        do 370 i = 1,4
          joint(s,i) = hh * siseed(i,s,p)
          rtot(s)    = rtot(s) + joint(s,i)
  370   continue

C Factor matrix to get desired row totals.

        do 380 s = 1,5
        do 380 i = 1,4
          if (rtot(s).GT.0.0) joint(s,i) = joint(s,i) * size(s)/rtot(s)
  380   continue
        newtot = hh

C Start big row loop.

        do 500 s = 1,5
          sneg = 0.0

C Calc. the column difference.

          do i = 1,4
            cdiff(i) = income(i)
            do s2 = 1,5
              cdiff(i) = cdiff(i) - joint(s2,i)
            end do

C Apportion each column's difference along this row.

            if (newtot .GT. 0.0) share(i) = cdiff(i) * size(s)/newtot
            joint(s,i) = joint(s,i) + share(i)

C Check to see if resulting value is negative.

            if (joint(s,i) .LT. 0.0) then
              sneg = sneg + joint(s,i)
              joint(s,i) = 0
            end if
          end do

C End column loop no. 1.  Calc. adjustment for negative values.

          negfac = 1.0000
          if (sneg .LT. 0.0) negfac = 1.0 + sneg/(size(s)-sneg)

C Apply adjustment for negative values (col. loop #2).

          do i = 1,4
            joint(s,i)  = joint(s,i) * negfac
            sizinc(s,i) = joint(s,i)
          end do

C Calc. "new matrix total" (current matrix total less this row).

          newtot = newtot - size(s)

  500   continue

C For accuracy, do one last factor to get the column
C  totals (by income) to come out more closely to the desired totals.

        do 610 s = 1,5
        do 610 i = 1,4
          ctot(i) = ctot(i) + sizinc(s,i)
  610   continue

        do 630 i = 1,4
          cfac  = 0.0
          if (ctot(i) .gt. 0.0) cfac = income(i)/ctot(i)
          do s = 1,5
            sizinc(s,i) = cfac * sizinc(s,i)
          end do

      if (itaz.ge.begtr .and. itaz.le.endtr) then
        write(6,9004) itaz,i,income(i),ctot(i),cfac,
     +    (sizinc(s2,i),s2=1,5)
 9004   format(' TGMET Trace 9004: taz= ',i5,'  i= ',i1,' desired col',
     +    ' tot= ',f8.3/20x,'current col tot= ',f8.3,'  factor= ',f8.4/
     +    20x,'sizinc (row 1-5)= ',5f8.3/)
      end if

  630   continue

C Write the 20 values of HHs by size and income to a scratch file
C  for later use.  Write them in row order: S1/I1, S1/I2, S1/I3,
C  S1/I4, S2/I1, etc.  Maintain 6 digits to the right of the decimal.
C  Write this file for ALL zones, including zones with no HHs,
C  to preserve the zone order.

  640   write(9,650) itaz,((sizinc(s,i),i=1,4),s=1,5)
  650   format(i5,20f11.6)

C Sum HHs by income group.

        do 660 i = 1,4
        do 660 s = 1,5
          tinc(i) = tinc(i) + sizinc(s,i)
  660   continue

C End of first loop.

  700 continue

C Calculate regional percent of HHs by income group.  Need this
c  later.

      isum = tinc(1) + tinc(2) + tinc(3) + tinc(4)
      do i = 1,4
        ripct(i) = tinc(i)/isum
      end do

      if (begtr.gt.0 .or. endtr.gt.0) then
        write(6,9010) isum,(tinc(i),i=1,4),(ripct(i),i=1,4)
 9010   format(' TGMET Trace 9010: income normalization calculation '/
     +    5x,' isum= ',f11.1,'  tinc 1-4= ',4f11.1
     +    /5x,' ripct= ',4f8.4/)
      end if

C--------------------------------------------------------------------
C Rewind scratch file 9 and start second loop.

      rewind 9
      write(*,'(/)')
      do 800 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,710) itaz
  710   format('+','TGMET  710 (N): Loop  2 - processing zone ',i5)

C Since income groups are supposed to be 10%/15%/25%/50%, normalize
C  them accordingly and write them back out to another scratch file.

        read(9,650) k,((sizinc(s,i),i=1,4),s=1,5)
        do 715 i = 1,4
        do 715 s = 1,5
          sizinc(s,i) = sizinc(s,i) * igroup(i) / ripct(i)
  715   continue
        write(10,650) iz,((sizinc(s,i),i=1,4),s=1,5)

      if (itaz.ge.begtr .and. itaz.le.endtr) then
        write(6,9047) itaz,((sizinc(s,i),i=1,4),s=1,5)
 9047   format(' TGMET Trace 9047: taz=',i5,' 1st intermed. SIZINC ',
     +    '(after income normalization)'/5x,'size 1, inc 1-4: ',4f9.3/
     +    5x,'size 2, inc 1-4: ',4f9.3/5x,'size 3, inc 1-4: ',4f9.3/
     +    5x,'size 4, inc 1-4: ',4f9.3/5x,'size 5, inc 1-4: ',4f9.3/)
      end if

C End of second loop.

  800 continue

C Re-use unit 9 as a new scratch file.

      close (9)
      if (savescr) then
        open(9,file='temp9b.scr',status='unknown',form='formatted')
      else
        open(9,status='scratch',form='formatted')
      end if

C--------------------------------------------------------------------
C Rewind scratch file 10 and start third loop.

      rewind 10
      write(*,'(/)')
      do 850 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,810) itaz
  810   format('+','TGMET  810 (N): Loop  3 - processing zone ',i5)

C The previous loop (income group normalization) will have goofed up
C  the no. of HHs by zone.  Re-normalize here to get the right number
C  of HHs by zone.  [Z(5,IZ) = HH].

        read(10,650) k,((sizinc(s,i),i=1,4),s=1,5)
        newtot = 0.0
        do 820 s = 1,5
        do 820 i = 1,4
          newtot = newtot + sizinc(s,i)
  820   continue

        factor = 1.0
        if (newtot .gt. 0.0001) factor = z(5,iz)/newtot

        do 830 s = 1,5
        do 830 i = 1,4
          sizinc(s,i) = sizinc(s,i) * factor
  830   continue

        write(9,650) iz,((sizinc(s,i),i=1,4),s=1,5)

        if (itaz.ge.begtr .and. itaz.le.endtr) then
        write(6,9015) itaz,newtot,factor,((sizinc(s,i),i=1,4),s=1,5)
 9015   format(' TGMET Trace 9015: taz=',i5,' 2nd intermed. SIZINC (',
     +  'after zone normaliz.)'/5x,'new tot= ',f10.3,' adj fact= ',f9.6/
     +    5x,'size 1, inc 1-4: ',4f9.3/5x,'size 2, inc 1-4: ',4f9.3/
     +    5x,'size 3, inc 1-4: ',4f9.3/5x,'size 4, inc 1-4: ',4f9.3/
     +    5x,'size 5, inc 1-4: ',4f9.3/)
        end if

C End of third loop.

  850 continue
      close (10)
C--------------------------------------------------------------------
C Rewind scratch file 9 and start fourth loop.

      rewind 9
      write(*,'(/)')
      do 1000 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,890) itaz
  890   format('+','TGMET  890 (N): Loop  4 - processing zone ',i5)

        read(9,650) k,((sizinc(s,i),i=1,4),s=1,5)

C For each size and income category, use the 'LIFEDIST' array to
C  compute the initial distribution of HHs by size, income, and life
C  cycle.

C Start loops on size (S) and income level (I).

        do l = 1,3
          life(l) = 0.0
        end do

C If zone is in Uptown, incorporate special factor.  Then normalize
C  to be sure the LC fractions sum to 1.

        do 900 s = 1,5
        do 900 i = 1,4
          if (z(31,iz) .gt. 0.5) then
            do l = 1,3
              ld(l,i,s) = lifedist(l,i,s) * lcfac(l,i)
            end do
            sum = ld(1,i,s) + ld(2,i,s) + ld(3,i,s)
            do l = 1,3
              ld(l,i,s) = ld(l,i,s)/sum
            end do  
          else
            do l = 1,3
              ld(l,i,s) = lifedist(l,i,s)
            end do
          end if          
          
        do 900 l = 1,3        
          sizinclif(s,i,l) = sizinc(s,i) * ld(l,i,s)
          life(l) = life(l) + sizinclif(s,i,l)
  900   continue

C Write out HHs by size/income/life cycle to scratch file.

        write(11,940) iz,(((sizinclif(s,i,l),l=1,3),i=1,4),s=1,5)
  940   format(i5,60f11.6)

C Accumulate (Real) HHs by size, income, and life cycle into a
C  total table for the region, in case user later asks that it be
C  printed.

        do 970 s = 1,5
        do 970 i = 1,4
        do 970 l = 1,3
          tjointSIL(s,i,l) = tjointSIL(s,i,l) + sizinclif(s,i,l)
          tsize(s)         = tsize(s)         + sizinclif(s,i,l)
  970   continue

      if (itaz.ge.begtr .and. itaz.le.endtr) then
        write(6,9029) itaz
 9029   format(' TGMET Trace 9029: taz=',i5,' size/income/life '
     +    'cycle calc.')
        do 945 s = 1,5
        do 945 i = 1,4
          write(6,9030) s,i,(sizinclif(s,i,l),l=1,3)
 9030     format(' Sz=',i2,' In=',i2,' LC=1-3,  HHs = ',3f12.6)
  945   continue
      end if

 1000 continue

C--------------------------------------------------------------------
C Rewind scratch file 11 and start fifth loop.

      rewind 11
      write(*,'(/)')
      do 1100 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,1010) itaz
 1010   format('+','TGMET 1010 (N): Loop  5 - processing zone ',i5)

        read(11,940) n,(((sizinclif(s,i,l),l=1,3),i=1,4),s=1,5)

C For each size/income/life cycle category, use the 'WKRDIST' array to
C  compute the initial distribution of HHs by size, income, life
C  cycle and workers.

C Start loops on size (S), income level (I), and life cycle (L).

        do 1020 s = 1,5
        do 1020 i = 1,4
        do 1020 l = 1,3
          do w = 1,4
            sizinclifwkr(s,i,l,w) = sizinclif(s,i,l) * wkrdist(w,l,i,s)
          end do
          regtotwkr  = regtotwkr + sizinclifwkr(s,i,l,2) +
     1     2.0 * sizinclifwkr(s,i,l,3) + avg3wkr*sizinclifwkr(s,i,l,4)
 1020   continue

        if (itaz.ge.begtr .and. itaz.le.endtr) then
          write(6,9035) itaz
 9035     format(/' TGMET Trace 9035: taz=',i5,' size/income/life '
     +      'cycle/worker calc.')
          do 1102 s = 1,5
          do 1102 i = 1,4
          do 1102 l = 1,3
            write(6,9036) s,i,l,(sizinclifwkr(s,i,l,w),w=1,4)
 9036       format(' Sz=',i2,' In=',i2,' LC=',i2,' Wk0-3, HHs = ',
     +        4f12.6)
 1102     continue
        end if

C End of fifth loop.

 1100 continue

C Adjust the regional total number of workers to match the regional
C  total employment, factored to account for I/E workers, E/I workers,
C  unemployment, and multiple job holders.  Factor is 'EMPFACTOR' and
C  its default value is based on 2010 data.  Calculate a new adjustment
C  factor called 'EMPADJUST'.  2010 values: REGTOT(1) = regional total
C  Metrolina employment = 1,220,673, REGTOTWKR = 1,067,600 (program est.).

      if (begtr .gt. 0) then
        write(6,9034) regtot(1),regtot(2),regtotwkr
 9034   format(/' TGMET Trace 9034: reg tot emp= ',f11.2,
     1   '  reg tot hh= ',f11.2/'   regtotwkr= ',f11.2/)
      end if

      oldwkrhh  = regtotwkr / regtot(2)
      newtotwkr = regtot(1) * empfactor
      empadjust = newtotwkr / regtotwkr
      newwkrhh  = newtotwkr / regtot(2)

C Write this calculation to the listing file.

      write(6,1105) regtot(1), empfactor, newtotwkr, regtotwkr,
     +  empadjust
 1105 format(//28x,'Report of Worker Submodel'//5x,'Regional total ',
     + 'employment: ',f11.2/5x,'Worker/employee ratio:',10x,f8.4/
     + 5x,'New est. regional workers: ',f11.2/5x,
     + 'Initial total workers:'5x,f11.2/5x,'Workers/HH adjustment',
     + ' factor:   ',f8.4//)

C Use old and new workers/HH to enter the 'WKRMODL' curve and
C  obtain the old and new regional proportion of HHs by number of
C  workers [OLDWRK(4) and NEWWRK(4)].

      call workers(oldwkrhh,oldwrk)
      call workers(newwkrhh,newwrk)

C Calculate ratio of NEWWRK to OLDWRK, by no. of workers.

      do w = 1,4
        wratio(w) = 1.0
        if (oldwrk(w) .gt. 0.001) wratio(w) = newwrk(w)/oldwrk(w)
      end do

C Re-use unit 10 for a new scratch file.

      if (savescr) then
        open(10,file='temp4.scr',status='unknown',form='formatted')
      else
        open(10,status='scratch',form='formatted')
      end if

C--------------------------------------------------------------------
C Rewind scratch file 11 and start sixth loop.

      rewind 11
      write(*,'(/)')

c Open individual HH output file.  

      open(21,file=hhfile,status='unknown',form='formatted')

      do 1300 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,1210) itaz
 1210   format('+','TGMET 1210 (N): Loop  6 - processing zone ',i5)

        read(11,940) n,(((sizinclif(s,i,l),l=1,3),i=1,4),s=1,5)

C Just as above...
C For each size/income/life cycle category, use the 'WKRDIST' array to
C  compute the initial distribution of HHs by size, income, life
C  cycle and workers.
C  Except this time, modify the worker distribution using WRATIO, as
C  calculated above.

C Start loops on size (S), income level (I), and life cycle (L).

        tothh = 0.0
        do 1240 s = 1,5
        do 1240 i = 1,4
        do 1240 l = 1,3
          wsum = 0.0
          do w = 1,4
            sizinclifwkr(s,i,l,w) = sizinclif(s,i,l) * wkrdist(w,l,i,s)
     1                            * wratio(w)
            wsum = wsum + sizinclifwkr(s,i,l,w)
          end do

C The resulting subtotal of HHs by size/income/life cycle
C  probably won't be correct and will need to be normalized to the
C  proper total for each size/income/life cycle group.

          wfact = 1.0
          if (wsum .gt. 0.001) wfact = sizinclif(s,i,l)/wsum
          do w = 1,4
            sizinclifwkr(s,i,l,w) = wfact * sizinclifwkr(s,i,l,w)
            tothh = tothh + sizinclifwkr(s,i,l,w)
          end do

 1240   continue

C Check the resulting total HHs.  If they don't match the input total,
C  warn the user.

        if (abs(tothh - z(5,iz)) .gt. 1.0) write(6,1250) itaz,tothh,
     1   z(5,iz)
 1250   format(' TGMET 1250 (W): On zone ',i5,', estimated total ',
     1   'HHs'/'  by size, income, life cycle: ',f6.0,' do not match '/
     2   '  the input total: ',f6.0'.  Check workers/HH calculation.')

C Now collapse the size dimension, leaving HHs by workers/income/
C  life cycle.

        do 1260 w = 1,4
        do 1260 i = 1,4
        do 1260 l = 1,3
          wkrinclif(w,i,l) = 0.0
 1260   continue

        do 1270 w = 1,4
        do 1270 i = 1,4
        do 1270 l = 1,3
        do 1270 s = 1,5
          wkrinclif(w,i,l) = wkrinclif(w,i,l) + sizinclifwkr(s,i,l,w)
 1270   continue

C Write out HHs by workers/income/life cycle to scratch file.

        write(10,1275) iz,(((wkrinclif(w,i,l),l=1,3),i=1,4),w=1,4)
 1275   format(i5,48f11.6)

      if (itaz.ge.begtr .and. itaz.le.endtr) then
        write(6,9031) itaz
 9031   format(' TGMET Trace 9031: taz=',i5,' wkr/income/life '
     +    'cycle calc.')
        do 9045 w = 1,4
        do 9045 i = 1,4
          write(6,9032) w-1,i,(wkrinclif(w,i,l),l=1,3)
 9032     format(' Wk=',i2,' In=',i2,' LC1-3,  HHs = ',3f12.6)
 9045   continue
      end if

c Write out the individual HH records for this zone to a permanent 
c  file, showing the size, income, lifecycle, and workers.  First,
c  bucket round the SIZINCLIFWKR array.
        ihh  = z(5,iz)
        thh  = 0
        buck = 0.5  
        do 1280 s = 1,5
        do 1280 i = 1,4
        do 1280 l = 1,3
        do 1280 w = 1,4
          qq = sizinclifwkr(s,i,l,w)
          call bucket1(qq,jj,buck)
          szinlfwk(s,i,l,w) = jj
          thh = thh + jj
 1280   continue
  
c Check total HHs to make sure we didn't lose/gain any.  If we did,
c  repeatedly add/subtract 1 from a random non-zero cell until the
c  difference is zero.

        hdiff = ihh - thh
        do while (hdiff .ne. 0)
          call random(qq)
          wr = min0(max1(4*qq,4.0),1)
          call random(qq)
          ir = min0(max1(4*qq,4.0),1)
          call random(qq)
          lr = min0(max1(3*qq,3.0),1)
          call random(qq)
          sr = min0(max1(5*qq,5.0),1)
          
          if (szinlfwk(sr,ir,lr,wr) .gt. 0) then
            incr = hdiff/iabs(hdiff)
            szinlfwk(sr,ir,lr,wr) = szinlfwk(sr,ir,lr,wr) + incr
            hdiff = hdiff - incr
          end if
        end do

      if (itaz.ge.begtr .and. itaz.le.endtr) then
          write(6,9043) itaz
 9043     format(/' TGMET Trace 9043: taz=',i5,' disagg size/income/life '
     +      'cycle/worker calc.')
          do 1282 s = 1,5
          do 1282 i = 1,4
          do 1282 l = 1,3
            write(6,9044) s,i,l,(szinlfwk(s,i,l,w),w=1,4)
 9044       format(' Sz=',i2,' In=',i2,' LC=',i2,' Wk0-3, HHs = ',
     +        4i4)
 1282     continue
        end if

c Write out the HH records.
c @@@ LATER: CHECK THE DISAGGREGATE CALCULATED HHs BY S/I/W/L
c   VS THE AGGREGATE SUMMARIES
        do 1290 w = 1,4
        do 1290 i = 1,4
        do 1290 l = 1,3
        do 1290 s = 1,5
	    jj = szinlfwk(s,i,l,w)
          if (jj .gt. 0) then
		  do qq = 1,jj
	        hhno =  hhno + 1
		    write(21,1285) hhno,itaz,s,i,l,w-1
 1285         format(i8,i6,4i2) 
            end do
          end if
 1290   continue

 1300 continue
      close (21)
	write(*,'('' Finished loop 6 OK.'')')

C--------------------------------------------------------------------
C Rewind scratch file 10 and start seventh loop.

      rewind 10
      rewind 11
      write(*,'(/)')
      do 1800 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,1410) itaz
 1410   format('+','TGMET 1410 (N): Loop  7 - processing zone ',i5)

        read(10,1275) n,(((wkrinclif(w,i,l),l=1,3),i=1,4),w=1,4)
        read(11,940)  n,(((sizinclif(s,i,l),l=1,3),i=1,4),s=1,5)

C Calculate total workers.

        ztotwkr = 0.0
        do 1420 i = 1,4
        do 1420 l = 1,3
          ztotwkr = ztotwkr + wkrinclif(2,i,l) + 2.0*wkrinclif(3,i,l)
     1            + avg3wkr * wkrinclif(4,i,l)
 1420   continue

C Calculate and output final total integer HHs by income.
C  Bucket round across income categories within each zone.  Also
C  write out total number of workers in the zone on that same file.

        bu = 4
        do 1450 i = 1,4
          rinc(i) = 0.0
          do 1445 w = 1,4
          do 1445 l = 1,3
            rinc(i) = rinc(i) + wkrinclif(w,i,l)
 1445     continue
          call bucket(rinc,intinc,bu)
 1450   continue

c        write(15,1460) iz,(intinc(i),i=1,4),ztotwkr
c 1460   format(i4,4i6,f7.0)

C Accumulate (Real) HHs by workers, income, and life cycle into a
C  total table for the region, in case user later asks that it be
C  printed.

        do 1470 w = 1,4
        do 1470 i = 1,4
        do 1470 l = 1,3
          tjointWIL(w,i,l) = tjointWIL(w,i,l) + wkrinclif(w,i,l)
          tinc(i)          = tinc(i)          + wkrinclif(w,i,l)
          twkr(w)          = twkr(w)          + wkrinclif(w,i,l)
          tlife(l)         = tlife(l)         + wkrinclif(w,i,l)
 1470   continue

C--------------------------------------------------------------------
C  Apply production trip rates and accumulate initial trip
C   productions by purpose and income.  Use worker/income/life cycle
C   breakdowns for HBW, JTW, and ATW trips and size/income/life
C   cycle breakdowns for SCH, HBU, HBS, HBO, and NWK trips.  For now,
C   store the total productions in PROD(p,i).  "Total" means I/I
c   plus I/E.

        do 1500 p = 1,11
        do 1500 i = 1,4
          prod(p,i) = 0.0
 1500   continue

        do 1520 p = 1,8
        do 1520 i = 1,4
          if (p .eq. 1 .or. p .eq. 6 .or. p .eq. 7) then
            do 1505 l = 1,3
            do 1505 w = 1,4
              prod(p,i) = prod(p,i)
     +                + wkrinclif(w,i,l) * prate(p,w,l,i) * pfact(p,i)
 1505       continue
          else
            do 1510 l = 1,3
            do 1510 s = 1,5
              prod(p,i) = prod(p,i)
     +                + sizinclif(s,i,l) * prate(p,s,l,i) * pfact(p,i)
 1510       continue
          end if
 1520   continue

c Before adding in GQ and special generator productions, accumulate
c  the HBW, HBS, and HBO productions by income and county for later
c  use in the attraction split model.

        c = (itaz-mod(itaz,1000))/1000 + 1
        if (itaz .gt. 10000 .and. itaz .lt. 11999) c = 11
        if (c .gt. 16) then
          write(6,1525) itaz
 1525     format(' TGMET 1525 (F): TAZ number ',i5,' implies more ',
     +      ' than 15 counties.'/'   Cannot handle that.  I quit.')
          stop "A fatal error has occurred.  Please check listing file."
        end if

        if (itaz .ge. begtr .and. itaz .le. endtr) then
          write(6,9060) itaz,c,z(25,iz)
 9060     format(/' TGMET Trace 9052: taz = ',i5,'  county = ',i3,
     +      '  CBD flag = ',f3.0)
          do p = 1,8
            write(6,9052) p,(pfact(p,i),i=1,4)
 9052       format(' PFACT for purp ',i2,' inc 1-4: ',4f10.4)
          enddo
        end if

        do i = 1,4
          copct(c,1,i) = copct(c,1,i) + prod(1,i)
          copct(c,4,i) = copct(c,4,i) + prod(4,i)
          copct(c,5,i) = copct(c,5,i) + prod(5,i)
        end do

C Add in productions from people in group quarters.  Trip rate/
C  person is calculated as GQFACT(purpose,zone type) * the following
C  production rates:
C       Purpose         Size         Workers Life Cycle Income
C     1 HBW                             1               1
C     2 SCH             1                       1       1
C     3 HBU             4                       2       1
C               (to account for students in dorms)
C     4 HBS             1                       1       1
C     5 HBO             1                       1       1
C     6 JTW             1               1               1
C     7 ATW             1               1               1
C     8 NWK             1                       1       1

C Z(19,iz) is 1.0 if this zone is a college dormitory zone, else 0.0.
C  All GQ trips are considered to be Income 1.

C 22 Aug 05: do this calc only if DO_GQ is True.  This allows user
C  to skip the GQ trip calc for purposes of validating results
C  to a home-interview survey.

        if (do_gq) then
          n = 2 - ifix(z(19,iz))
          prod(1,1) = prod(1,1)
     1              + gqfact(1,n) * prate(1,2,1,1) * z(4,iz)
          prod(2,1) = prod(2,1)
     1              + gqfact(2,n) * prate(2,1,1,1) * z(4,iz)
          prod(3,1) = prod(3,1)
     1              + gqfact(3,n) * prate(3,4,2,1) * z(4,iz)
          prod(4,1) = prod(4,1)
     1              + gqfact(4,n) * prate(4,1,1,1) * z(4,iz)
          prod(5,1) = prod(5,1)
     1              + gqfact(5,n) * prate(5,1,1,1) * z(4,iz)
          prod(6,1) = prod(6,1)
     1              + gqfact(6,n) * prate(6,2,1,1) * z(4,iz)
          prod(7,1) = prod(7,1)
     1              + gqfact(7,n) * prate(7,2,1,1) * z(4,iz)
          prod(8,1) = prod(8,1)
     1              + gqfact(8,n) * prate(8,1,1,1) * z(4,iz)
        end if

        if (itaz.ge.begtr .and. itaz.le.endtr) then
          write(6,9007) itaz,z(19,iz),((gqfact(p,n),p=1,8),n=1,2)
 9007     format(' TGMET Trace 9007: Initial Productions for taz=',i5/
     1      ' ','Dorm zone flag: ',f2.0/' ','GQ Factors: ',8f7.4/
	2      ' ','            ',8f7.4)
          do p = 1,8
            write(6,9022) purcode(p),(prod(p,i),i=1,4)
 9022       format(' ',5x,'purpose ',a4,'  by inc 1-4: ',4f10.4)
          end do
        end if

C Modify initially estimated zonal productions for Area Type and
C  income.  Note that in the original model calibration, no such
C  factors were developed.  But, we leave this section in, for
C  possible future use.  Also apply global adjustment factor.

        atype = ifix(z(28,iz))
        do 1530 p = 1,8
        do 1530 i = 1,4
          prod(p,i) = prod(p,i) * atfactp(p,atype) * tfactor(p)
 1530   continue

        if (itaz.ge.begtr .and. itaz.le.endtr) then
          write(6,9048) itaz
 9048     format(/' TGMET Trace 9048: Final Productions for taz=',i5/
     +      '     (After area type/income adjustment)')
          do p = 1,8
            write(6,9024) purcode(p),(prod(p,i),i=1,4)
 9024       format(' ',5x,'purpose ',a4,'by inc 1-4: ',4f10.4)
          end do
        end if

C Commercial and Truck productions (= attractions).  Store them all
C  as "income 1".  Apply Attraction area type adjustment.

        do p = 9,11
          prod(p,1) = (arate(p,1) * z(5,iz)  + arate(p,3) * z(7,iz)
     1               + arate(p,4) * z(8,iz)
     1               + arate(p,5) * z(9,iz)  + arate(p,6) * z(10,iz)
     2               + arate(p,7) * z(11,iz) + arate(p,8) * z(12,iz)
     3               + arate(p,9) * z(13,iz) + arate(p,10) * z(14,iz))
     4               * atfacta(p,atype) * tfactor(p)
        end do

C Special generator productions.  Only need to check this if the flag
C  (Z(24,iz)) is > 0.  If SPECGENPROD is negative, replace the
C  previously calculated value with the absolute value of it.  If it
C  is positive, add it to
C  the previously calculated value.  Since user inputs only a single
C  value for productions, use the previously estimated split by income
C  to split the new value by income.

        if (z(24,iz) .gt. 0.5) then

          do 1570 p = 1,11
            do 1565 zz = 1,30
              m = specgenzone(zz,p)
              if (m .eq. 0) cycle
              n = tazzone(m)
              if (n .eq. iz) then
                csum = prod(p,1)+prod(p,2)+prod(p,3)+prod(p,4)
                do i = 1,4
                  ipct(i) = igroup(i)
                  if (csum .gt. 0.001) ipct(i) = prod(p,i)/csum
                end do

                if (specgenprod(zz,p) .lt. 0) then
                  do i = 1,4
                    prod(p,i) = ipct(i) * abs(specgenprod(zz,p))
                  end do
                else
                  do i = 1,4
                    prod(p,i) = prod(p,i)+ipct(i)*specgenprod(zz,p)
                  end do
                end if

                write(6,1575) m,purcode(p),specgenprod(zz,p)
 1575           format(' TGMET 1575 (N): Special generator ',
     +            'productions used for TAZ ',i5/' purpose: ',a4,
     +            '  value: ',i9/)

                go to 1570

              end if
 1565       continue


 1570     continue

        end if

C Apply I/E model to split productions into I/I and I/E.  I/E model
C  estimates the % of total productions that are externally attracted,
C  as an exponential function of the zone's distance to the cordon.
C  Model was calibrated from 2012 survey data; see iemodel.xlsx.
C  If that distance is 0.0, can't do the exponentiation, so just
C  set the external share to 100%.  Calculate 2 percents: Work and
c  Non-work.  Start with the Work share for COM/MTK/HTK, then
c  change it to match the cordon count data.  External trips are
c  all "income 1".  Last term in "EXTPCT" equations is a final
c  adjustment to get the proper regional total I/E trips.

        if (z(26,iz) .lt. 0.0001) then
          extpctw = 1.0000
          extpctn = 1.0000
        else
          extw = 1.31 * z(26,iz)**(-1.47)
          extn = 0.29 * z(26,iz)**(-1.33)
          extpctw = extw * extadj(1,1)
          extpctn = extn * extadj(2,1)
          if (extpctw .gt. 0.95) extpctw = 0.95
          if (extpctn .gt. 0.98) extpctn = 0.98
        end if

c Compute the I/E purpose productions.
c  Use "Work" I/E fraction for HBW, JTW, COM, and truck; use
c  the "Non-Work" I/E fraction for the other purposes.

        extpctc = extw * extadj(3,1)
        extpctm = extw * extadj(4,1)
        extpcth = extw * extadj(5,1)
	  extpctc = amin1(extpctc,0.95)
	  extpctm = amin1(extpctm,0.95)
        extpcth = amin1(extpcth,0.95)

        prod(12,1) = extpctw * (prod(1,1)+prod(1,2)+prod(1,3)+prod(1,4)
     +     +prod(6,1)+prod(6,2)+prod(6,3)+prod(6,4))
        prod(13,1) = extpctn * (prod(2,1)+prod(2,2)+prod(2,3)+prod(2,4)
     +     +prod(3,1)+prod(3,2)+prod(3,3)+prod(3,4)+prod(4,1)+prod(4,2)
     +     +prod(4,3)+prod(4,4)+prod(5,1)+prod(5,2)+prod(5,3)+prod(5,4)
     +     +prod(7,1)+prod(7,2)+prod(7,3)+prod(7,4)+prod(8,1)+prod(8,2)
     +     +prod(8,3)+prod(8,4))
        prod(14,1) = extpctc * prod(9,1)
        prod(15,1) = extpctm * prod(10,1)
        prod(16,1) = extpcth * prod(11,1)

c Before removing the I/E's, sum the productions by purpose and income
c  for later use.

        do 1580 p = 1,11
        do 1580 i = 1,4
          tprod(p,i) = tprod(p,i) + prod(p,i)
 1580   continue

c Now remove the I/E share from the total, to calculate the I/I trips.

        do i = 1,4
          prod(1,i) = (1.0 - extpctw) * prod(1,i)
          prod(2,i) = (1.0 - extpctn) * prod(2,i)
          prod(3,i) = (1.0 - extpctn) * prod(3,i)
          prod(4,i) = (1.0 - extpctn) * prod(4,i)
          prod(5,i) = (1.0 - extpctn) * prod(5,i)
          prod(6,i) = (1.0 - extpctw) * prod(6,i)
          prod(7,i) = (1.0 - extpctn) * prod(7,i)
          prod(8,i) = (1.0 - extpctn) * prod(8,i)
        end do
        prod(9,1)  = (1.0 - extpctc) * prod(9,1)
        prod(10,1) = (1.0 - extpctm) * prod(10,1)
        prod(11,1) = (1.0 - extpcth) * prod(11,1)

        if (itaz.ge.begtr .and. itaz.le.endtr) then
          write(6,9013) itaz,z(26,iz),extpctw,extpctn,extpcth,
     +     ((extadj(i,j),i=1,5),j=1,2)
 9013     format(/' TGMET Trace 9013: pct I/E calc. for zone ',i5,
     +      '  Cordon dist= ',f6.2/
     +      5x,'  ext pct for work, nonwk, HTK= ',3f10.6/'   ',
     +      'ext adj: ',10f7.4/
     +      '   I/I productions by purpose:')
          do p = 1,11
            write(6,9019) purcode(p),(prod(p,i),i=1,4)
 9019       format(' ',5x,'purpose ',a4,'  by inc 1-4: ',4f10.4)
          end do
      end if

C Sum regional trip productions by purpose and income.  Sum them
C  by I/I (for later use in normalization) and by I/E
C  (for later use in cordon allocation).

        do 1592 p = 1,11
        do 1592 i = 1,4
          totiiprod(p,i) = totiiprod(p,i) + prod(p,i)
 1592   continue
        do p = 12,16
          totextprod(p)  = totextprod(p)  + prod(p,1)
        end do

C Write productions by purpose and income to a temporary
C  scratch file.

        write(12,1595) iz,((prod(p,i),i=1,4),p=1,11),
     +    (prod(p,1),p=12,16)
 1595   format(i5,49f12.6)

C--------------------------------------------------------------------
C Now, on to attractions.
C  Calculate initial I/I attractions by purpose.  Apply
C  regression equations.  Get initial regional totals by purpose.
C  For the NHB and Truck purposes (6-11), the originally calibrated
C  attraction model coefficients have been already divided by 2,
C  in order to convert total trip ends to true attractions.
C Also, adjust attractions by Area Type and factor in the
C  global adjustment factor.

        do 1600 p = 1,11
        
          sattr(p,1)  = arate(p,1) * z(5,iz)  + arate(p,2) * z(3,iz)
     1                + arate(p,3) * z(7,iz)  + arate(p,4) * z(8,iz)
     2                + arate(p,5) * z(9,iz)  + arate(p,6) * z(10,iz)
     3                + arate(p,7) * z(11,iz) + arate(p,8) * z(12,iz)
     4                + arate(p,9) * z(13,iz) + arate(p,10) * z(14,iz)
     5                + arate(p,11) *z(16,iz) + arate(p,12) * z(17,iz)
     6                + arate(p,13) *z(18,iz) + arate(p,14) * z(29,iz)
     7                + arate(p,15) *z(6,iz)  + arate(p,16) * z(25,iz)

          sattr(p,1)  = sattr(p,1) * atfacta(p,atype) * tfactor(p)

C For HBS, if there are no Retail employees, set attractions to zero.   
     
          if (p .eq. 4) then
            if ((z(9,iz)+z(10,iz)) .lt. 1) sattr(4,1) = 0
          endif

C HBO, JTW, and NWK attraction equations contain a density term.  But if 
C   there are no HHs or jobs, set attractions to zero.

          if (p.eq.5 .or. p.eq.6 .or. p.eq.8) then
	      if ((z(5,iz)+z(15,iz)) .lt. 1) sattr(p,1) = 0
	    endif

 1600   continue

C Special generator attractions.  Only need to check this if the flag
C  (Z(24,iz)) is > 0.  If SPECGENATTR is negative, replace the
C  previously calculated value with the absolute value of it.  If
C  it is positive, add it to
C  the previously calculated value.  The calculations are simpler than
C  for productions, because we haven't calculated the income split yet.

        if (z(24,iz) .gt. 0.5) then

          do 1670 p = 1,11
            do 1665 zz = 1,30
              m = specgenzone(zz,p)
              if (m .eq. 0) cycle
              n = tazzone(m)
              if (n .eq. iz) then
                if (specgenattr(zz,p) .lt. 0) then
                  sattr(p,1) = abs(specgenattr(zz,p))
                else
                  sattr(p,1) = sattr(p,1) + specgenattr(zz,p)
                end if

                write(6,1675) m,purcode(p),specgenattr(zz,p)
 1675           format(' TGMET 1675 (N): Special generator ',
     +            'attractions used for TAZ ',i5/' purpose: ',a4,
     +            '  value: ',i9/)

                go to 1670
              end if
 1665       continue
 1670     continue

        end if

c Sum total attractions by purpose.  Do this twice to help the
c  normalization calculation, below.

        do p = 1,11
          tattr1(p)   = tattr1(p)   + sattr(p,1)
          tattr2(p)   = tattr2(p)   + sattr(p,1)
        end do

        if (itaz.ge.begtr .and. itaz.le.endtr) then
          totemp = 0
          
          write(6,9016) itaz,z(3,iz),z(4,iz),z(5,iz),z(7,iz),z(8,iz),
     +      z(9,iz),z(10,iz),z(11,iz),z(12,iz),z(13,iz),z(14,iz),
     +      z(15,iz),z(16,iz),z(17,iz),z(18,iz),atype,(sattr(p,1),p=1,11),
     +      (atfacta(p,atype),p=1,11),z(29,iz),z(30,iz)
 9016     format(/' TGMET Trace 9016: attraction calc. for zone ',i5/
     +      5x,'POP_HHS= ',f6.0,'  POP_GRP= ',f6.0,' HH= ',f6.0,
     +      '  LOIND= ',f6.0/3x,'  HIIND= ',f6.0,' RTL= ',f6.0,
     +      '   HWY= ',f6.0,'   LOSVC= ',f6.0,'  HISVC= ',f6.0/3x,
     +      '  OFFGOV= ',f6.0,'   EDUC= ',f6.0,'  EMP_TOT= ',f6.0,
     +      '  STU_K8= ',f6.0,'  STU_HS= ',f6.0,'  STU_CU= ',f6.0/
     +      ' ',5x,'Area Type= ',i2,'  Attr by purp= '/' ',2x,11f8.1/
     +      ' ',5x,'Attr AT factors by purp: '/' ',11f7.4/
     +      ' ',5x,'Density fcn, %RTL+HWY: ',f12.4,f7.4/)
        end if

C Some of the attraction models contain negative coefficients
C  and this may result in negative attractions being calculated for
C  some zones.  For such zones, set attractions to zero and
C  normalize the rest of the zones' attractions to match the correct
C  regional total (TATTR1(p)).  Do this by purpose.

        do p = 1,11
          if (sattr(p,1) .lt. 0.0) then
            tattr2(p) = tattr2(p) - sattr(p,1)
            sattr(p,1)  = 0.0
          end if
        end do

c        if (itaz.ge.begtr .and. itaz.le.endtr) then
c          write(6,9018) itaz,(tattr1(p),p=1,11),(tattr2(p),p=1,11)
c 9018     format(' TGMET Trace 9018: taz=',i5,'  TATTR1(p)='/5x,
c     +      11f8.0/5x,'TATTR2(p)='/5x,11f8.0/)
c        end if

C Write attractions by purpose to a temporary scratch file.

        write(13,1720) iz,(sattr(p,1),p=1,11)
 1720   format(i5,11f14.6)

C End of seventh loop.

 1800 continue
      close (9)
      close (10)
      close (11)
      if (repo(6)) then
        rewind 8
      else
        close (8)
      end if

C--------------------------------------------------------------------
C Calculate percent of HBW/HBS/HBO person trip productions by purpose
C  and income, by county.

      do 1850 c = 1,16
        y1 = copct(c,1,1) + copct(c,1,2) + copct(c,1,3) + copct(c,1,4)
        y4 = copct(c,4,1) + copct(c,4,2) + copct(c,4,3) + copct(c,4,4)
        y5 = copct(c,5,1) + copct(c,5,2) + copct(c,5,3) + copct(c,5,4)
        do i = 1,4
          if (y1 .gt. 0.0001) then
            copct(c,1,i) = copct(c,1,i)/y1
          else
            copct(c,1,i) = 0.25
          endif
          if (y4 .gt. 0.0001) then
            copct(c,4,i) = copct(c,4,i)/y4
          else
            copct(c,4,i) = 0.25
          endif
          if (y5 .gt. 0.0001) then
            copct(c,5,i) = copct(c,5,i)/y5
          else
            copct(c,5,i) = 0.25
          endif
        end do
 1850 continue

      if (begtr.gt.0 .or. endtr.gt.0) then
        write(6,9017) ((copct(c,1,i),i=1,4),c=1,16),
     +    ((copct(c,4,i),i=1,4),c=1,16),
     +    ((copct(c,5,i),i=1,4),c=1,16),
     +    (tattr1(p),p=1,11),(tattr2(p),p=1,11)
 9017   format(' TGMET Trace 9017: co. production split calc.'/
     +    5x,'HBW % by co and inc: '/
     +    16(5x,4f7.4/),5x,'HBS % by co and inc: '/16(5x,4f7.4/),
     +    5x,'HBO % by co and inc: '/16(5x,4f7.4/),
     +    5x,'TATTR1(purp): '/3x,11f9.0/5x,'TATTR2(purp): '/3x,11f9.0/)

        write(6,9039) ((totiiprod(p,i),p=1,8),i=1,4),
     1    (totextprod(p),p=12,13)
 9039   format(' TGMET Trace 9039: total productions by purp:'/
     1    ' I/I,I1:',8f8.0/' I/I,I2:',8f8.0/' I/I,I3:',8f8.0/
     2    ' I/I,I4:',8f8.0/' I/E:   ',2f8.0/)
      end if

C--------------------------------------------------------------------
C Rewind attractions file, and start eighth loop.

      rewind 13
      write(*,'(/)')
      do 3000 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,2000) itaz
 2000   format('+','TGMET 2000 (N): Loop  8 - processing zone ',i5)

C Read attractions from scratch file.

        read(13,1720) k,(sattr(p,1),p=1,11)
        if (k .ne. iz) then
          write(6,2050) 13,z(1,k),z(1,iz)
 2050     format(' TGMET 2050 (F): Problem with scratch file ',i2/
     +      '  Reading data for TAZ ',i5,'  Expecting data for TAZ ',
     +      i5,'  I quit.'/)
          stop "A fatal error has occurred.  Please check listing file."
        end if

C Normalize attractions to the proper totals, by purpose, to account
C  for possible initial negative attractions.

        do p = 1,11
          sattr(p,1) = sattr(p,1) * tattr1(p)/tattr2(p)
        end do

C Split HBW, HBS, and HBO attractions by income.  Split is based on
C  county-level production split by purpose, modified by the variables
C  mentioned above.  Assume we can determine the county based on the
C  zone number.
c  Variables are: 1=bias 1, 2=bias 2, 3=bias 3, 4=CBD dummy (0/1),
c   5=% loind, 6=% hiind, 7=%rtl, 8=% hwy, 9=% losvc, 10=% educ.  

        c = (itaz-mod(itaz,1000))/1000 + 1
        if (itaz .gt. 10000 .and. itaz .lt. 11999) c = 11
        ploind = 0
	  phiind = 0
	  prtl   = 0
	  phwy   = 0
        plosvc = 0
	  peduc  = 0
	  if (z(15,iz) .gt. 0) then
	    ploind = z(7,iz)/z(15,iz)
	    phiind = z(8,iz)/z(15,iz)
	    prtl   = z(9,iz)/z(15,iz)
	    phwy   = z(10,iz)/z(15,iz)
	    plosvc = z(11,iz)/z(15,iz)
	    peduc  = z(14,iz)/z(15,iz)
        endif
	  do 2120 p = 1,5
          if (p .eq. 2 .or. p .eq. 3) then
            attr(p,1) = sattr(p,1)
            cycle
          end if
          do i = 1,3
	      u(i) = acoefas(p,i)        + acoefas(p,4)*z(25,iz)
     +           + acoefas(p,5)*ploind + acoefas(p,6)*phiind
     +           + acoefas(p,7)*prtl   + acoefas(p,8)*phwy
     +           + acoefas(p,9)*plosvc + acoefas(p,10)*peduc

            eu(i) = copct(c,p,i) * exp(u(i))

            if (itaz.ge.begtr .and. itaz.le.endtr) then
              write(6,9057) itaz,purcode(p),i,acoefas(p,i),
     +          copct(c,p,i),u(i),eu(i)
 9057         format(' TGMET Trace 9057: taz=',i5,' purp: ',a4,' inc: ',
     1          i1/'  ACOEFAS(p,i): ',f9.4,'  COPCT: ',f9.4,' U: ',f9.4,
     2          ' EU: ',f9.4/)
            end if

          end do

c Income 4 is the "floater" -- the one choice in the choice set
c  that does not use coefficients.

          eu(4) = copct(c,p,4)
          sumeu = eu(1) + eu(2) + eu(3) + eu(4)

C Calculate attractions by income.

          if (itaz.ge.begtr .and. itaz.le.endtr) then
            write(6,9027) itaz,purcode(p),(acoefas(p,v),v=1,10),sumeu
 9027       format(' TGMET Trace 9027: taz=',i5,
     +        ' Attractions by income calc.: ',a4/'  ACOEFAS ',
     +        'coefs(1-10)= '/10f10.3/' SUMEU = ',f10.5/)
          end if

          do i = 1,4
            npct(i) = eu(i)/sumeu
            attr(p,i) = npct(i) * sattr(p,1)
          end do

          if (itaz.ge.begtr .and. itaz.le.endtr) then
            write(6,9014) itaz,purcode(p),(copct(c,p,i),i=1,4),
     +         (eu(i),i=1,4),(npct(i),i=1,4),(attr(p,i),i=1,4)
 9014       format(' TGMET Trace 9014: taz=',i5,'  attractions by inc,',
     +         ' purp: ',a4/
     +         ' county pct. by inc, 1-4:   ',4f9.5/
     +         ' e(U) by inc, 1-4:          ',4f9.5/
     +         ' revised  pct. by inc, 1-4: ',4f9.5/
     +         ' new attractns by inc, 1-4: ',4f9.3/)
          end if

 2120   continue

C
C Do not split NH attractions by income.  Put them all in the
C  "income 1" category and fill the other categories with zeroes.

        do p = 6,11
          attr(p,1) = sattr(p,1)
          attr(p,2) = 0.0
          attr(p,3) = 0.0
          attr(p,4) = 0.0
        end do

C Sum HB attractions by income.

        do p = 1,5
          do i = 1,4
            tattr3(p,i) = tattr3(p,i) + attr(p,i)
          end do
        end do
        do p = 6,11
          tattr3(p,1) = tattr3(p,1) + attr(p,1)
        end do

c 10 Jun 05 change: new E/I function
C Apply E/I model to calculate E/I attractions.  E/I model
C  estimates the % of total attractions that are externally produced,
C  as a parabolic function of the zone's distance to the cordon.  This
c  is slightly different than the I/E model.  The I/E model splits
c  total productions into I/E and I/I:
c    I/E prod = total prod * I/E%
c    I/I prod = total prod * (1 - I/E%)
c  In the case of E/I trips, we don't have the total to start with,
c  only the I/I value.  Thus, the equations become:
c     total attr = I/I attr / (1 - E/I%)
c     E/I attr   = total attr * E/I%
c or: E/I attr   = I/I attr * E/I% / (1 - E/I%)

c Set an arbitrary upper limit of 75% on the E/I share.  Use same
c  equation for Work and Non-Work.

        extw = 0.55 - 0.057*z(26,iz) + 0.0015*z(26,iz)*z(26,iz)
        extn = extw
        extpctw = extw * extadj(1,2)
        extpctn = extn * extadj(2,2)

        extpctw = amin1(extpctw,0.75)
        extpctn = amin1(extpctn,0.75)

        csum       = attr(1,1) + attr(1,2) + attr(1,3) + attr(1,4)
     1             + attr(6,1)
        attr(17,1) = csum * extpctw / (1.0 - extpctw)
        csum       = attr(2,1) + attr(3,1) + attr(4,1) + attr(4,2)
     1             + attr(4,3) + attr(4,4) + attr(5,1) + attr(5,2)
     2             + attr(5,3) + attr(5,4) + attr(7,1) + attr(8,1)
        attr(18,1) = csum * extpctn / (1.0 - extpctn)

c Use the Work E/I fractions for COM/truck, modified to match the
c  base year cordon data.  Use different upper limit here: 95% E/I.
c  Again, somewhat arbitrary.

        extpctc = extw * extadj(3,2)
        extpctm = extw * extadj(4,2)
        extpcth = extw * extadj(5,2)
        extpctc = amin1(extpctc,0.95)
        extpctm = amin1(extpctm,0.95)
        extpcth = amin1(extpcth,0.95)

        attr(19,1) = attr(9,1)  * extpctc / (1.0 - extpctc)
        attr(20,1) = attr(10,1) * extpctm / (1.0 - extpctm)
        attr(21,1) = attr(11,1) * extpcth / (1.0 - extpcth)

        if (itaz.ge.begtr .and. itaz.le.endtr) then
          write(6,9026) itaz,z(26,iz),extpctw,extpctn,extpcth
 9026     format(/' TGMET Trace 9026: pct E/I calc. for zone ',i5,
     +     '  cordon dist= ',f6.2/'  ext pct (wk,nw,ht)= ',3f9.6/'   ',
     +     'I/I attractions by purpose:')
          do p = 1,11
            write(6,9033) purcode(p),(attr(p,i),i=1,4)
 9033       format(' ',5x,'purpose ',a4,'  by inc 1-4: ',4f11.4)
          end do
          do p = 17,21
            write(6,9058) purcode(p),attr(p,1)
 9058       format(' ',5x,'purpose ',a4,f11.4)
          end do
        end if

C Sum regional I/I attractions for later use in normalization.  Sum
C  regional E/I person attractions for later use in cordon allocation.

        do 2310 p = 1,11
        do 2310 i = 1,4
          totiiattr(p,i) = totiiattr(p,i) + attr(p,i)
 2310   continue

        do p = 17,21
          totextattr(p)  = totextattr(p)  + attr(p,1)
        end do

C Write attractions by income and purpose out to a new
C  scratch file.

        write(14,2400) iz,((attr(p,i),i=1,4),p=1,11),
     +    (attr(p,1),p=17,21)
 2400   format(i5,49f12.6)

C End of eighth ZONES loop.

 3000 continue
      close (13)
      close (15)

      if (begtr.gt.0 .or. endtr.gt.0) then
        write(6,9040) ((totiiattr(p,i),p=1,11),i=1,4),
     1    (totextattr(p),p=17,21)
 9040   format(' TGMET Trace 9040: total attractions by purp:'/
     1    ' I/I,I1:',11f9.0/' I/I,I2:',11f9.0/' I/I,I3:',11f9.0/
     2    ' I/I,I4:',11f9.0//' E/I:   ',5f9.0/)
      end if

C Rewind attractions scratch file 14 and position it at the start of
C  the external station records.

c      rewind 14
c      do iz = 1,intzones
c        read(14,2400) iz,((attr(p,i),i=1,4),p=1,11),
c     +    (attr(p,1),p=17,21)
c      end do

C--------------------------------------------------------------------
c Apply NHB Non-Resident Model ("secondary NHB trips") here.  This
c  says that the non-resident (E/I) travellers make internal NHB
c  trips at the same rate as resident (I/I + I/E) travellers.
c 22 Aug 05: do this only if DO_NONRES is True.
c First, get the regional resident (I/I + I/E) NHB/HB ratio.

      nhbadj = 1.0
      if (do_nonres) then
      do i = 1,4
        do p = 1,5
          hbtot = hbtot + tprod(p,i)
        end do

        do p = 6,8
          nhbtot = nhbtot + tprod(p,i)
        end do

      end do
      ratio = nhbtot/hbtot

c Now calculate the non-resident NHB trips as this ratio, times the
c  sum of the work and non-work E/I person trips.

      eipsn = totextattr(17) + totextattr(18)
      nrtot = ratio * eipsn

c Finally, the NHB adjustment factor is the ratio of the non-resident
c  NHB trips to the resident NHB trips, plus 1.  Apply this adjustment
c  to all 3 NHB purpose trip end totals.

      nhbadj = nrtot/nhbtot + 1.0

      if (begtr .gt. 0 .or. endtr .gt. 0) then
        write(6,9046) hbtot,nhbtot,ratio,eipsn,nrtot,nhbadj,
     +   ((tprod(p,i),p=1,8),i=1,4)
 9046   format(' TGMET Trace 9046: Non-resident NHB calculation'/
     +    ' HB total:      ',f12.0/' NHB total:     ',f12.0/
     +    ' NHB/HB ratio:  ',f12.3/' E/I person:    ',f12.0/
     +    ' Non-Res NHB:   ',f12.0/' NR NHB adj fac:',f12.3//
     +    ' Total resident productions (I/I + I/E) by purp:'/
     1    ' I1:',8f8.0/' I2:',8f8.0/' I3:',8f8.0/
     2    ' I4:',8f8.0/)
      end if
      end if

C--------------------------------------------------------------------
C Open trip end output files.  There are 2 such files: unit 7 is
c  Productions, unit 8 is Attractions.  Open these files for output.
c  Also, open the associated dictionary files for TransCAD.

      open(7,file=prodfile,status='unknown',form='formatted')
      open(8,file=attrfile,status='unknown',form='formatted')

c Construct names of Production, Attraction, and HH DCC files, then
c  open the files for output.

      strlth   = len_trim(prodfile) - 4
      proddict = prodfile(1:strlth) // '.DCC'
      strlth   = len_trim(attrfile) - 4
      attrdict = attrfile(1:strlth) // '.DCC'
	strlth   = len_trim(hhfile) - 4
	hhdict   = hhfile(1:strlth) // '.DCC'

      open(17,file=proddict,status='unknown',form='formatted')
      open(18,file=attrdict,status='unknown',form='formatted')

C--------------------------------------------------------------------
C Now, we must allocate the I/E attractions and the E/I productions
C  among the external stations.  This is done in proportion to the
C  estimated future total daily External (I/E + E/I) 2-way volume at
C  each station.  These volumes are handled separately, by type.
C We start by calculating an estimated External volume at each
c  external station.  This is the total input volume, multiplied by
c  the base year E/E trip share, by station and type.  These volumes
c  are used to allocate the I/E attractions to the stations and the
c  E/I productions to the stations.  Then, we calculate the actual
c  future E/E volume by station as the input total, less the I/E attrs,
c  less the E/I prods.  Then, calculate the E/E growth factors as
c  the ratio of future to base 2000 E/E volume, by station.
c All calculations are stratified by 1 of 2 vehicle type groupings:
c  TYPE4: 1=auto (PC), 2=COM, 3=MTK, 4=HTK.
c  TYPE5: 1=work auto, 2=nonwk auto, 3=COM, 4=MTK, 5=HTK.

C Here is where the resulting numbers are stored:
c  BASVOL(type4,station)        base 2000 total cordon volume (veh)
c  STAVOL(type4,station)        input forecast yr tot cordon vol (veh)
c  BTHRUV(type4,station)        base 2000 E/E trip volume (veh)
c  BTHRUP(type4,station)        base 2000 E/E trip share (fraction)
c  EXTVOL(type5,station)        initial fcast yr external volume (veh)
c  TOTEXT(type5)                total initial fcast yr ext vol (veh)
c  EXTPROD(type5,station)       final fcast yr external prods (psn)
c  EXTATTR(type5,station)       final fcast yr external attrs (psn)
c  STATRIPENDS(type5,station)   final fcast yr ext trip ends (veh)
c  FTHRUV(type4,station)        forecast year E/E trip volume (veh)
c  XXFACT(type4,station)        forecast year E/E trip factor

C First, calculate initial estimate of E/E trips by station, using the
C  Base year data. Then, calculate each station's share of the initial
c  future I/E + E/I cordon volume by vehicle type, and sum it by type.

      do 3200 m = 1,nsta
        do 3100 p = 1,4
          bthrup(p,m) = 0.0
          if (basvol(p,m) .gt. 0.01) bthrup(p,m) =
     +        bthruv(p,m)/basvol(p,m)
          extvol(p,m) = basvol(p,m) * (1.0 - bthrup(p,m))
          totext(p)   = totext(p) + extvol(p,m)
 3100   continue

        if (begtr .gt. 0) then
          n = z(1,intzones + m)
          write(6,9055) n,(bthrup(p,m),p=1,4),(extvol(p,m),p=1,4),
     +      (totext(p),p=1,4)
 9055     format(' TGMET Trace 9055: sta= ',i5/
     +      '  BTHRUP(p)=',4f7.4/'  EXTVOL(p)=',4f9.2/
     +      '  TOTEXT(p)=',4f9.2/)
        end if

 3200 continue

c The input cordon volumes for Auto do not distinguish between Work
c  and Non-Work.  Use the total Auto volume to allocate the Work and
c  Non-Work values.  Must shift from TYPE4 to TYPE5 indexing also
c  (TYPE4: auto, com, mtk, htk; TYPE5: wk auto, nw auto, com, mtk, htk)

      do p5 = 5,2,-1
        p4 = max(p5-1,1)
        do m = 1,nsta
          extvol(p5,m) = extvol(p4,m)
        end do
        totext(p5) = totext(p4)
      end do

c Zero out the I/I cells of the PROD and ATTR arrays.

      do p = 1,11
        do i = 1,4
          prod(p,i) = 0.0
          attr(p,i) = 0.0
        end do
      end do

      if (begtr .gt. 0) then
        write(6,9056) (totext(p),p=1,5),(totextprod(p),p=12,16),
     +    (totextattr(p),p=17,21)
 9056   format(' TGMET Trace 9056'/'  TOTEXT(type):     ',5f11.2/
     +    '  TOTEXTPROD(type): ',5f11.2/
     +    '  TOTEXTATTR(type): ',5f11.2/)
      end if

C  Allocate I/E attractions and E/I productions to stations, by
C    vehicle type.
c    Divide person
C    trips in cars by average external vehicle occupancy to get
C    vehicle trips.  Sum trip ends across purposes.

      do 3250 m = 1,nsta
        do p = 1,5
          extattr(p,m) = totextprod(p+11) * extvol(p,m)/totext(p)
          extprod(p,m) = totextattr(p+16) * extvol(p,m)/totext(p)
        end do

        statripends(1,m) = extattr(1,m)/iewrkavo + extprod(1,m)/eiwrkavo
        statripends(2,m) = extattr(2,m)/ienwkavo + extprod(2,m)/einwkavo
        do p = 3,5
          statripends(p,m) = extattr(p,m) + extprod(p,m)
        end do

C Store the cordon station external person trip ends in the PROD and
C  ATTR arrays.  Put them all in Income 1.

        do p = 1,5
          prod(p+11,1) = extprod(p,m)
          attr(p+16,1) = extattr(p,m)
        end do

        n = intzones + m

        write(12,1595) n,((prod(p,i),i=1,4),p=1,11),
     +    (prod(p,1),p=12,16)

        write(14,2400) n,((attr(p,i),i=1,4),p=1,11),
     +    (attr(p,1),p=17,21)
 3250 continue

C--------------------------------------------------------------------
C Here we calculate the E/E vehicle trip growth factors, as follows:
C   1) Future Through Trip Ends = Future Total Cordon Veh. Trip Ends
C                               - Future External Veh. Trip Ends
C   2) Growth Factor = Future Through Veh. Trip Ends
C                               / Base Through Veh. Trip Ends
C   This is done separately by vehicle type (TYPE4), for each external
C   station, but not separately by direction.

      do 3300 m = 1,nsta
        n = z(1,intzones + m)
        fthruv(1,m) = stavol(1,m) - statripends(1,m) - statripends(2,m)

        do p = 2,4
          fthruv(p,m) = stavol(p,m) - statripends(p+1,m)
        end do

        do p = 1,4
          xxfact(p,m) = 1.0
          if (bthruv(p,m) .gt. 0.01) xxfact(p,m)=fthruv(p,m)/bthruv(p,m)

          if (fthruv(p,m) .lt. 0.0) then
            if (fthruv(p,m).lt.-2.0) write(6,3260) p,n,fthruv(p,m)
 3260       format(' TGMET 3260 (W): Type ',i1,' through trips at ',
     +        'station ',i5,' are negative: ',f10.2/
     +        5x,'Re-set to zero.'/)
            fthruv(p,m) = 0.0
            xxfact(p,m) = 1.0
          end if
        end do
        if (begtr .gt. 0) then
          write(6,9041) n,(fthruv(p,m),p=1,4),
     1      (extprod(p,m),p=1,5),(extattr(p,m),p=1,5),
     2      (statripends(p,m),p=1,5),(xxfact(p,m),p=1,4)
 9041     format(' TGMET Trace 9041: sta=',i5,'  FTHRUV:',
     1      4f9.1/' EXTPROD (type):   ',5f10.2/
     2      ' EXTATTR (type):   ',5f10.2/
     4      ' STATRIPENDS(type): ',5f10.2/' XXFACT(type): ',4f10.2/)
        end if

 3300 continue

C Re-use unit 13 as a new scratch file.

      close (13)
      if (savescr) then
        open(13,file='temp13a.scr',status='unknown',form='formatted')
      else
        open(13,status='scratch',form='formatted')
      end if

C--------------------------------------------------------------------
C Rewind production and attraction files and start ninth loop
C  to normalize I/I trip ends.  Normalize I/I HB trips to the
C  production total, by income.  For the NHB purposes, force the
C  attraction total to equal the production total.  Then set the
C  productions by zone equal to the adjusted attractions by zone.
C  Normalization should not be needed for COM and truck trips, but
C  do it anyway just to be safe.
c  Also, apply the non-resident NHB adjustment factor.
C The '3800' loop covers internal zones only.

      rewind 12
      rewind 14
      write(*,'(/)')
      do 3800 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,3400) itaz
 3400   format('+','TGMET 3400 (N): Loop  9 - processing zone ',i5)

C Read productions from scratch file.

        read(12,1595) n,((prod(p,i),i=1,4),p=1,11),
     +    (prod(p,1),p=12,16)

C Read attractions from scratch file.  Normalize all I/I
C  attractions to the production total by income.

        read(14,2400) k,((attr(p,i),i=1,4),p=1,11),
     +    (attr(p,1),p=17,21)

        do p = 1,5
          if (p .eq. 2 .or. p .eq. 3) then
            tempp = totiiprod(p,1) + totiiprod(p,2) + totiiprod(p,3) +
     +              totiiprod(p,4)
            tempa = totiiattr(p,1) + totiiattr(p,2) + totiiattr(p,3) +
     +              totiiattr(p,4)
            if (tempa .lt. 0.001) cycle
            attr(p,1) = attr(p,1) * tempp/tempa

          else

            do i = 1,4
              attr(p,i) = attr(p,i) * totiiprod(p,i)/totiiattr(p,i)
            end do
          end if
        end do

C For NHB, COM, and truck, don't normalize by income.

        do p = 6,11
          tempp = totiiprod(p,1) + totiiprod(p,2) + totiiprod(p,3)
     1          + totiiprod(p,4)
          tempa = totiiattr(p,1) + totiiattr(p,2) + totiiattr(p,3)
     1          + totiiattr(p,4)

          if (tempa .lt. 0.001) cycle
          attr(p,1) = attr(p,1) * tempp/tempa

c Apply non-resident NHB adjustment.

          if (p .le. 8) attr(p,1) = nhbadj * attr(p,1)

        end do

C Set NHB I/I productions = NHB I/I normalized attractions by zone.
C  All NHB attractions are already stored in Income 1.  Zero out
C  the previously calculated NHB Productions for Incomes 2-4.

        do p = 6,8
          prod(p,1) = attr(p,1)
          prod(p,2) = 0.0
          prod(p,3) = 0.0
          prod(p,4) = 0.0
        end do

c Sum the productions by income into "income 1" for SCH and HBU.
c  We're not splitting those purposes by income.

        prod(2,1) = prod(2,1) + prod(2,2) + prod(2,3) + prod(2,4)
        prod(2,2) = 0.0
        prod(2,3) = 0.0
        prod(2,4) = 0.0

        prod(3,1) = prod(3,1) + prod(3,2) + prod(3,3) + prod(3,4)
        prod(3,2) = 0.0
        prod(3,3) = 0.0
        prod(3,4) = 0.0

C--------------------------------------------------------------------
C Create output Production/Attraction files.  First,
C  write Productions.  For the 6 NHB/COM/truck purposes,
C  Productions are defined as equal to Attractions.
C Write the income-based HB purposes by income.

        write(7,3520) itaz,iz,(prod(1,i),i=1,4),prod(2,1),
     +    prod(3,1),((prod(p,i),i=1,4),p=4,5),
     +    (prod(p,1),p=6,21)
 3520   format(2(i10,','),29(f10.3,','),f10.3)

C Write unrounded, Real I/I productions and attractions to scratch
C  file 13.

        write(13,3750) iz,((prod(p,i),i=1,4),p=1,11),
     +                    ((attr(p,i),i=1,4),p=1,11)
 3750   format(i5,88f12.6)

C End of ninth loop.

 3800 continue

c Apply non-resident NHB adjustment to the NHB trip totals also,
c  for the reports.

      do i = 1,4
        do p = 6,8
          tprod(p,i) = tprod(p,i) * nhbadj
        end do
      end do

C Start a new loop ('4000') on external stations to write out zero
C  trip end records as the Productions for external stations.

      do 4000 iz = intzones+1,zones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.zones) write(*,3400) itaz

C Read records from scratch files.

        read(12,1595) n,((prod(p,i),i=1,4),p=1,11),
     +    (prod(p,1),p=12,16)
        read(14,2400) k,((attr(p,i),i=1,4),p=1,11),
     +    (attr(p,1),p=17,21)

c Stick in DUMMY array as a zero placeholder for external station
c  I/E productions.

        write(7,3520) itaz,iz,(prod(1,i),i=1,4),prod(2,1),
     +    prod(3,1),((prod(p,i),i=1,4),p=4,5),
     +    (prod(p,1),p=6,11),(dummy(p),p=1,5),(prod(p,1),p=12,16)

C Write unrounded, Real productions and attractions to scratch
C  file 13.

        write(13,3850) iz,(prod(p,1),p=12,16),
     +                    (attr(p,1),p=17,21)
 3850   format(i5,10f12.6)
 4000 continue

C--------------------------------------------------------------------
C Rewind final attractions file and start tenth loop.  This is
C  actually 2 loops: one for internal zones and one for external
C  stations.

      rewind 12
      rewind 13
      rewind 14
      write(*,'(/)')
      do 5600 iz = 1,intzones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.intzones) write(*,5150) itaz
 5150   format('+','TGMET 5150 (N): Loop 10 - processing zone ',i5)

C Read final attractions from scratch file (skip over the productions).

        read(13,4160) k,((attr(p,i),i=1,4),p=1,11)
 4160   format(i5,528x,44f12.6)

c Read external attractions from scratch file.

        read(14,4180) m,(attr(p,1),p=17,21)
 4180   format(i5,528x,5f12.6)

c Read production file to skip past the internal zones.

        read(12,1595) n,((prod(p,i),i=1,4),p=1,11),
     +    (prod(p,1),p=12,16)

C Write attraction data.  First, I/I HB purposes, by income.

        write(8,3520) itaz,iz,(attr(1,i),i=1,4),attr(2,1),
     +    attr(3,1),((attr(p,i),i=1,4),p=4,5),
     +    (attr(p,1),p=6,21)

C End of internal zone loop.

 5600 continue

C Don't rewind scratch files 12-14.  These files should already be
C  positioned at the start of the external stations.

C Start external station loop.

      do 6000 iz = intzones+1,zones
        itaz = z(1,iz)
        if (mod(itaz,10).eq.0 .or. iz.eq.zones) write(*,5150) itaz

C Again read final attractions from scratch file, starting with first
C  external station.

        read(13,3850) k,(prod(p,1),p=12,16),(attr(p,1),p=12,16)

C Write zero external station attraction records to the trip files,
C  just to keep everything straight.

        do 5750 p = 1,11
        do 5750 i = 1,4
          attr(p,i) = 0.0
 5750   continue

        do p = 17,21
          attr(p,1) = 0.0
        end do

        write(8,3520) itaz,iz,(attr(1,i),i=1,4),attr(2,1),
     +    attr(3,1),((attr(p,i),i=1,4),p=4,5),
     +    (attr(p,1),p=6,11),(attr(p,1),p=12,16),
     +    (attr(p,1),p=17,21)

C End of external station loop.

 6000 continue

C--------------------------------------------------------------------
C Write file of E/E trip growth factors, with DCC file.

      write(*,'('' Writing E/E factor file.'')')
      open (16,file=xxfile,status='unknown',form='formatted')
 
      strlth = len_trim(xxfile) - 4
      xxdict = xxfile(1:strlth) // '.DCC'
      open (19,file=xxdict,status='unknown',form='formatted')

      do 6100 m = 1,nsta
        iz = intzones + m
        itaz = z(1,iz)

C  The growth factors are to be used in a subsequent TransCAD Fratar
C   run.

        write(16,6020) itaz,(xxfact(p,m),p=1,4)
 6020   format(i10,',',3(f10.2,','),f10.2)
 6100 continue
      close (16)

c-------------------------------------------------------------------
c Write TransCAD dictionary (DCC) files.

      write(17,7000)
 7000 format(/'0 header')
      write(17,7020)
 7020 format('"TAZ",I,1,10,0,10,0,,,"",,Blank,'/
     +       '"SEQ",I,11,10,0,10,0,,,"",,Blank,'/
     +       '"HBW1",R,21,10,0,10,3,,,"",,Blank,'/
     +       '"HBW2",R,31,10,0,10,3,,,"",,Blank,'/
     +       '"HBW3",R,41,10,0,10,3,,,"",,Blank,'/
     +       '"HBW4",R,51,10,0,10,3,,,"",,Blank,'/
     +       '"SCH",R,61,10,0,10,3,,,"",,Blank,'/
     +       '"HBU",R,71,10,0,10,3,,,"",,Blank,'/
     +       '"HBS1",R,81,10,0,10,3,,,"",,Blank,'/
     +       '"HBS2",R,91,10,0,10,3,,,"",,Blank,'/
     +       '"HBS3",R,101,10,0,10,3,,,"",,Blank,'/
     +       '"HBS4",R,111,10,0,10,3,,,"",,Blank,'/
     +       '"HBO1",R,121,10,0,10,3,,,"",,Blank,'/
     +       '"HBO2",R,131,10,0,10,3,,,"",,Blank,'/
     +       '"HBO3",R,141,10,0,10,3,,,"",,Blank,'/
     +       '"HBO4",R,151,10,0,10,3,,,"",,Blank,')
      write(17,7025)
 7025 format('"JTW",R,161,10,0,10,3,,,"",,Blank,'/
     +       '"ATW",R,171,10,0,10,3,,,"",,Blank,'/
     +       '"NWK",R,181,10,0,10,3,,,"",,Blank,'/
     +       '"COM",R,191,10,0,10,3,,,"",,Blank,'/
     +       '"MTRK",R,201,10,0,10,3,,,"",,Blank,'/
     +       '"HTRK",R,211,10,0,10,3,,,"",,Blank,'/
     +       '"IEWK",R,221,10,0,10,3,,,"",,Blank,'/
     +       '"IENW",R,231,10,0,10,3,,,"",,Blank,'/
     +       '"IECM",R,241,10,0,10,3,,,"",,Blank,'/
     +       '"IEMT",R,251,10,0,10,3,,,"",,Blank,'/
     +       '"IEHT",R,261,10,0,10,3,,,"",,Blank,'/
     +       '"EIWK",R,271,10,0,10,3,,,"",,Blank,'/
     +       '"EINW",R,281,10,0,10,3,,,"",,Blank,'/
     +       '"EICM",R,291,10,0,10,3,,,"",,Blank,'/
     +       '"EIMT",R,301,10,0,10,3,,,"",,Blank,'/
     +       '"EIHT",R,311,10,0,10,3,,,"",,Blank,')

      write(18,7000)
      write(18,7020)
      write(18,7025)

      write(19,7000)
      write(19,7070)
 7070 format('"STATION",I,1,10,0,10,0,,,"",,Blank,'/
     +       '"PC FACTOR",R,11,10,0,10,3,,,"",,Blank,'/
     +       '"COM FACTOR",R,21,10,0,10,3,,,"",,Blank,'/
     +       '"MTK FACTOR",R,31,10,0,10,3,,,"",,Blank,'/
     +       '"HTK FACTOR",R,41,10,0,10,3,,,"",,Blank,'/)

      open(22,file=hhdict,status='unknown',form='formatted')
	write(22,7000)
      write(22,7080)
 7080 format('"HHNO",I,1,8,0,8,0,,,"",,Blank,'/
     +       '"ITAZ",I,9,14,0,6,0,,,"",,Blank,'/
     +       '"SIZE",I,15,16,0,2,0,,,"",,Blank,'/
     +       '"INC",I,17,18,0,2,0,,,"",,Blank,'/
     +       '"LIFE",I,19,20,0,2,0,,,"",,Blank,'/
     +       '"WORKERS",I,21,22,0,2,0,,,"",,Blank,'/)
	close(22)

C--------------------------------------------------------------------
C Finished with the calculations.  Call subroutine to write reports
C  2-8.

      write(*,'('' Writing reports.'')')
      call report

C--------------------------------------------------------------------
C  All done.

      write(*,7100)
 7100 format(' TGMET is finished.  Thanks for watching.')
      stop
      end

C====================================================================
C Subroutines for TGMET.FOR:

C REPORT        write reports 2-8
C FINDIT        determines if a file exists
C HEADER        puts header at top of each page of the listing file
C BUCKET        bucket round N-element array (N<=10)
C BUCKET1       bucket round a scalar
C WORKERS       apply worker submodel

C-------------------------------------------------------------------
C Subroutine 'REPORT' to write reports 2-8.

      subroutine REPORT

      implicit none

      INTEGER*4 ZONES,NSTA
      REAL*8    PROD,ATTR
	INTEGER*4 DUM_01

      common /rept/ tjointWIL(4,4,3),tjointSIL(5,4,3),tlife(3),
     + twkr(4),tinc(4),tsize(5),repo(8),zones,
     + xxfact(4,200),xxfile,totiiattr(11,4),tprod(21,4),
     + totextprod(21),totextattr(21),statripends(5,200),
     + regtot(5),purcode(21),totiiprod(11,4),DUM_01,prod(21,4),
     + attr(21,4),ttrip(21,4),nsta,fthruv(4,200)

      common /zd/ z(31,5000),intzones,begtr

C Following statements to link to the HEADER subroutine.

      common /dattim/ yr,mon,day,hr,min,sec,hun,
     +                month(12),title(10),page
      character*8 title
      character*4 month

      character*80 xxfile,headrec
      integer*4 yr,mon,day,hr,min,sec,hun,page,
     + zi(30),tsvol(10),sumv(10),itotwkr,itaz,ista

      integer*2 n,i,s,w,m,p,t,l,line,iz,intzones,begtr

      real*4 tsw(5),tjointSIL,tjointWIL,xx,y,tj2(3,5),tsize,twkr,
     +  factor,ttrip,item(4),regtot,totiiprod,totiiattr,
     +  zz,ztotwkr,z,tp(21),ta(21),statripends,fthruv,
     +  tlife,tinc,xxfact,tprod,gtotp(21),gtota(21),
     +  totextprod,totextattr


      character*4 ititl(4),purcode
      character*10 ltitl(3)

      logical repo

      data ititl/'  1 ','  2 ','  3 ','  4 '/,
     + ltitl/'Retired','Kids <=18','NoRet/Kids'/,sumv/10*0/,
     + gtotp,gtota/42*0.0/

C  If requested, write reports of regional HH's by income, size,
C  workers, and life cycle.

      if (repo(2)) then
        call header
        write(6,5600)
 5600   format(/' ',35x,'Report 2a'/' ',
     +    12x,'Report of Estimated HHs by Life Cycle, Income, and ',
     +    'Workers'/)
        do 5650 i = 1,4
          zz = 0.0
          do 5605 w = 1,4
            tsw(w) = 0.0
 5605     continue
          write(6,5610) ititl(i)
 5610     format(3x,'Income: ',a4/'Life',19x,'Workers'/'Cycle ',
     +        '      0        1        2        3+   Total'/)
          do 5640 l = 1,3
            xx = tjointWIL(1,i,l) + tjointWIL(2,i,l) + tjointWIL(3,i,l)
     1         + tjointWIL(4,i,l)
            zz = zz + xx
            write(6,5630) ltitl(l),(tjointWIL(w,i,l),w=1,4),xx
 5630       format(' ',a4,5f9.0)
            do 5635 w = 1,4
              tsw(w) = tsw(w) + tjointWIL(w,i,l)
 5635       continue
 5640     continue
          write(6,5645) (tsw(w),w=1,4),zz
 5645     format(/'Total',5f9.0//)
 5650   continue

        write(6,5660)
 5660   format('Income: All'/'Life',19x,'Workers'/'Cycle ',
     +   '      0        1        2        3+   Total'/)
        do 5700 l = 1,3
          do 5670 w = 1,4
          do 5670 i = 1,4
            tj2(l,w) = tj2(l,w) + tjointWIL(w,i,l)
 5670     continue
          write(6,5680) ltitl(l),(tj2(l,w),w=1,4),tlife(l)
 5680     format(' ',a4,5f9.0)
 5700   continue
        write(6,5710) (twkr(w),w=1,4),regtot(2)
 5710   format(/'Total',5f9.0)

C Write companion report of HHs by life cycle, income, and size.

        call header
        write(6,5720)
 5720   format(/' ',35x,'Report 2b'/' ',
     +    13x,'Report of Estimated HHs by Life Cycle, Income, and ',
     +    'Size'/)
        do 5750 i = 1,4
          zz = 0.0
          do 5725 s = 1,5
            tsw(s) = 0.0
 5725     continue
          write(6,5730) ititl(i)
 5730     format(3x,'Income: ',a4/'Life',25x,'Size'/'Cycle ',
     +        '      1        2        3        4        5+   Total'/)
          do 5740 l = 1,3
            xx = tjointSIL(1,i,l) + tjointSIL(2,i,l) + tjointSIL(3,i,l)
     1         + tjointSIL(4,i,l) + tjointSIL(5,i,l)
            zz = zz + xx
            write(6,5735) ltitl(l),(tjointSIL(s,i,l),s=1,5),xx
 5735       format(' ',a4,6f9.0)
            do 5737 s = 1,5
              tsw(s) = tsw(s) + tjointSIL(s,i,l)
 5737       continue
 5740     continue
          write(6,5745) (tsw(s),s=1,5),zz
 5745     format(/'Total',6f9.0//)
 5750   continue

        write(6,5760)
 5760     format('Income: All'/'Life',25x,'Size'/'Cycle ',
     +        '      1        2        3        4        5+   Total'/)
        do 5780 l = 1,3
          do 5770 s = 1,5
          do 5770 i = 1,4
            tj2(l,s) = tj2(l,s) + tjointSIL(s,i,l)
 5770     continue
          write(6,5775) ltitl(l),(tj2(l,s),s=1,5),tlife(l)
 5775     format(' ',a4,6f9.0)
 5780   continue
        write(6,5790) (tsize(s),s=1,5),regtot(2)
 5790   format(/'Total',6f9.0)
      end if

C If requested, write report of normalization calculation.

      if (repo(3)) then
        call header
        write(6,5800)
 5800   format(/' ',35x,'Report 3'/' ',
     +    15x,'Report of I/I Trip End Normalization Calculation'//
     +    'Purpose  Income        Productions        Init. Attractions',
     +    '      Factor  Control'/)

        do 5860 p = 1,5
          do 5850 i = 1,4
            factor = 1.0
            if (totiiattr(p,i) .gt. 0.001)
     +        factor = totiiprod(p,i)/totiiattr(p,i)
            if ((p .eq. 2 .or. p .eq. 3) .and. i .eq. 1)
     +        factor = (totiiprod(p,1)+totiiprod(p,2)+totiiprod(p,3)+
     +                  totiiprod(p,4))/totiiattr(p,1)
            write(6,5810) purcode(p),ititl(i),totiiprod(p,i),
     +        totiiattr(p,i),factor,'Prod'
 5810       format(' ',a4,4x,a4,10x,f10.0,13x,f10.0,8x,f6.4,3x,a4)
 5850     continue
          write(6,5855)
 5855     format(/)
 5860   continue

C For NHB trips, attractions are already stored in the "income 1"
C  array position (col. 1).  Must now sum productions and store
C  them in the same position.

        do 5870 p = 6,8
          totiiprod(p,1) = totiiprod(p,1) + totiiprod(p,2)
     1                   + totiiprod(p,3) + totiiprod(p,4)
          factor = totiiprod(p,1)/totiiattr(p,1)
          write(6,5810) purcode(p),' All',totiiprod(p,1),
     1     totiiattr(p,1),factor,'Prod'
          write(6,5855)
 5870   continue

C Commercial and Trucks are already all "income 1".

        do 5880 p = 9,11
          factor = totiiprod(p,1)/totiiattr(p,1)
          write(6,5810) purcode(p),' All',totiiprod(p,1),
     1     totiiattr(p,1),factor,'Prod'
          write(6,5855)
 5880   continue

      end if

C If requested, write report of zonal trip ends by purpose.

      if (repo(4)) then

C Read Real productions and attractions from scratch file 13 and sum
C  across income.  Do entire report
C  twice, first for I/I and then for External.

        rewind 13
        line = 51
        do 5999 iz = 1,intzones
          itaz = z(1,iz)
          read(13,5900) ((prod(p,i),i=1,4),p=1,11),
     +      ((attr(p,i),i=1,4),p=1,11)
 5900     format(5x,88f12.6)

          do p = 1,11
            tp(p) = 0.0
            ta(p) = 0.0
          end do
          do i = 1,4
            do p = 1,11
              tp(p) = tp(p) + prod(p,i)
              ta(p) = ta(p) + attr(p,i)
            end do
          end do

          do p = 1,11
            gtotp(p) = gtotp(p) + tp(p)
            gtota(p) = gtota(p) + ta(p)
          end do

          if (line .gt. 50) then
            call header
            write(6,5941)
 5941       format(' ',35x,'Report 4'/' ',20x,'Report of I/I',
     1        ' Trip Ends by Purpose'//)

            write(6,5945) (purcode(p),p=1,11),(purcode(p),p=1,11)
 5945       format(' ',t7,'Productions',t76,'Attractions'/'Zone  ',
     +        11a6,3x,11a6/)
            line = 1
          end if
          write(6,5950) itaz,(tp(p),p=1,11),(ta(p),p=1,11)
 5950     format(' ',i5,11f6.0,3x,11f6.0)
          line = line + 1
 5999   continue

C Write grand totals, staggered on 2 lines.

        write(6,5997) (gtotp(p),p=2,10,2),(gtota(p),p=2,10,2),
     1                (gtotp(p),p=1,11,2),(gtota(p),p=1,11,2)
 5997   format(/'Total ',5f12.0,9x,5f12.0/6f12.0,f9.0,5f12.0)

c External Stations.

        line = 51
        do 6099 iz = intzones+1,zones
          itaz = z(1,iz)
          read(13,6000) (totextprod(p),p=12,16),
     +                  (totextattr(p),p=17,21)
 6000     format(5x,10f12.6)

c Switch the definitions here, since I/E trips are defined as
c  attractions and E/I trips are defined as productions, at the
c  external stations.

          do p = 17,21
            tp(p) = totextattr(p)
            gtotp(p) = gtotp(p) + tp(p)
          end do
          do p = 12,16
            ta(p) = totextprod(p)
            gtota(p) = gtota(p) + ta(p)
          end do

          if (line .gt. 50) then
            call header
            write(6,6041)
 6041       format(' ',35x,'Report 4'/' ',17x,'Report of External',
     1        ' Person Trip Ends by Purpose'/)

c     ' ',11x,'(Trip Ends Shown',
c     2        ' As Originally Calculated for Internal Zones)'/)

            write(6,6045) (purcode(p),p=12,21)
 6045       format(' ',t9,'Attractions',t52,'Productions'/'Sta. ',
     +        5a8,3x,5a8/)
            line = 1
          end if
          write(6,6050) itaz,(tp(p),p=17,21),(ta(p),p=12,16)
 6050     format(i5,5f8.0,3x,5f8.0)
          line = line + 1
 6099   continue

C Write grand totals.

        write(6,6097) (gtotp(p),p=17,21),(gtota(p),p=12,16)
 6097   format(/'Total',5f8.0,3x,5f8.0)

      end if

C If requested, write report of trip ratios.

      if (repo(5)) then
        call header
        write(6,6100) (ititl(i),i=1,4)
 6100   format(' ',35x,'Report 5'/' ',
     +    30x,'Report of Trip Ratios'//
     +    37x,'Income'/'Purpose  Item',4(7x,a4),5x,'Total'/)

        do 6200 p = 1,8
          xx = tprod(p,1) + tprod(p,2) + tprod(p,3) + tprod(p,4)
          write(6,6120) purcode(p),'Tot Trips ',(tprod(p,i),i=1,4),xx
 6120     format(' ',a4,a10,5f11.0)

          do i = 1,4
            item(i) = tprod(p,i)/regtot(1)
          end do
          y = xx/regtot(1)
          write(6,6140) 'Trips/Empl',(item(i),i=1,4),y
 6140     format(' ',4x,a10,4x,4(f5.3,6x),f6.3)

          do i = 1,4
            item(i) = tprod(p,i)/regtot(2)
          end do
          y = xx/regtot(2)
          write(6,6140) 'Trips/HH  ',(item(i),i=1,4),y

          do i = 1,4
            item(i) = tprod(p,i)/regtot(4)
          end do
          y = xx/regtot(4)
          write(6,6140) 'Trips/Psn ',(item(i),i=1,4),y

          write(6,5855)
 6200   continue

C Now total across purposes.

        xx = 0.0
        do i = 1,4
          item(i) = 0.0
          do p = 1,8
            item(i) = item(i) + tprod(p,i)
            xx      = xx      + tprod(p,i)
          end do
        end do
        write(6,6120) 'All ','Tot Trips ',(item(i),i=1,4),xx
        write(6,6140) 'Trips/Empl',item(1)/regtot(1),item(2)/regtot(1),
     +    item(3)/regtot(1),item(4)/regtot(1),xx/regtot(1)
        write(6,6140) 'Trips/HH  ',item(1)/regtot(2),item(2)/regtot(2),
     +    item(3)/regtot(2),item(4)/regtot(2),xx/regtot(2)
        write(6,6140) 'Trips/Psn ',item(1)/regtot(4),item(2)/regtot(4),
     +    item(3)/regtot(4),item(4)/regtot(4),xx/regtot(4)
      end if

C If requested, write zonal data report.

      if (repo(6)) then
        line = 51
        do 6300 iz = 1,intzones
           ztotwkr = 0
           itotwkr = 0
c          read(15,6210) ztotwkr
c 6210     format(28x,f7.0)

          if (line .gt. 50) then
            call header
            write(6,6220)
 6220       format(' ',32x,'Report 6'/' ',28x,'Zonal Data Report'//
     +        '             Tot       HH   GQ   LoIn HiIn Rtl  Hwy',
     +        '  LSv  HSv  Off  Edu  K-8  HS   Uni Drm    Med Inc'
     +        ' Gen CBD  Dst       Den'/
     +        ' Zone  Area  Pop   HH  Pop  Pop  Emp  Emp  Emp  Emp',
     +        '  Emp  Emp  ',
     +        'Emp  Emp  Enr  Enr  Enr Flg    Inc Rat Flg Flg  Cor',
     +        '       Fcn  AT'/)
            line = 1
          end if
          do t = 1,30
            zi(t) = ifix(z(t,iz))
          end do
          itaz = z(1,iz)
          write(6,6240) itaz,z(20,iz),zi(2),zi(5),zi(3),zi(4),
	1	  (zi(t),t=7,14),(zi(t),t=16,19),zi(6),z(23,iz),zi(24),
     2      zi(25),z(26,iz),z(29,iz),zi(28)
 6240     format(i5,f6.2,15i5,i4,i7,f5.2,i3,i4,f5.1,5x,f6.0,i3)
          line = line + 1
 6300   continue
        close (8)
      end if

C If requested, write out report of estimated cordon vehicle volumes.

      if (repo(7)) then
        line = 51
        do 6600 m = 1,nsta
          if (line .gt. 50) then
            call header
            write(6,6410)
 6410       format(' ',35x,'Report 7'/' ',25x,'Vehicle Cordon Crossing',
     +       ' Report'/
     +       '        Through                               External'/
     +       'Station Auto   COM   MedTrk HvyTrk Total      Auto  ',
     +       ' COM   MedTrk HvyTrk Total'/)
            line = 1
          end if
          ista = z(1,intzones + m)

          tsvol(5) = 0
          do t = 1,4
            tsvol(t) = int4(fthruv(t,m) + 0.5)
            tsvol(5) = tsvol(5) + tsvol(t)
          end do

          tsvol(6) = int4(statripends(1,m) + statripends(2,m) + 0.5)
          tsvol(10)= tsvol(6)
          do t = 3,5
            tsvol(t+4) = int4(statripends(t,m) + 0.5)
            tsvol(10)  = tsvol(10) + tsvol(t+4)
          end do

          do t = 1,10
            sumv(t) = sumv(t) + tsvol(t)
          end do
          write(6,6440) ista,(tsvol(t),t=1,10)
 6440     format(i5,5i7,3x,5i7)
          line = line + 1
 6600   continue
        write(6,6610) (sumv(t),t=1,10)
 6610   format(/'Total',5i7,3x,5i7)
      end if

C If requested, write out report of E/E trip growth factors.

      if (repo(8)) then
        open (16,file=xxfile,status='old',form='formatted')
c	  read(16,6505) headrec
c 6505   format(a80)
        line = 51
        do 6800 m = 1,nsta
          if (line .gt. 50) then
            call header
            write(6,6510)
 6510       format(' ',35x,'Report 8'/' ',26x,'Through Trip Growth',
     +       ' Factors'//
     +       '   Station      Auto      COM  Med Truck Hvy Truck'/)
            line = 1
          end if
          ista = z(1,intzones + m)
          read(16,6530) n,(xxfact(p,m),p=1,4)
 6530     format(i10,1x,f10.3,1x,f10.3,1x,f10.3,1x,f10.3)
          write(6,6540) ista,(xxfact(p,m),p=1,4)
 6540     format(i10,4f10.3)
          line = line + 1
 6800   continue
        close (16)
      end if

      return
      end

C-------------------------------------------------------------------
C Subroutine 'FINDIT' to determine if input files really exist.
C  Returns FERR = 1 if file FNO does not exist.  Returns FERR = 0
C  otherwise.

      subroutine findit (fno,fname,ferr)

      integer*2 ferr
      character*80 fno,fname
      logical infile

      ferr = 0
      inquire (file=fno,exist=infile)
      if (.NOT. infile) then
        write(6,100) fname,fno 
  100   format (' FINDIT 100 (F): Cannot find '/5x,a80,': ',/5x,a80)
        ferr = 1
      end if
      return
      end 

C-------------------------------------------------------------------
C Subroutine 'HEADER' to place a form feed character and write a new
C  header to the listing file.

      subroutine header 

      implicit integer (a-z)

      common /dattim/ yr,mon,day,hr,min,sec,hun,
     +                month(12),title(10),page

      character*8 title
      character*4 month
      integer*4 yr,mon,day,hr,min,sec,hun,page
	integer*2 i
 
C Write header with page eject (ASCII 12) as control character.

      page = page+1
      write (6,100) char(12),(title(i),i=1,10),day,month(mon),yr,
     +  hr,min,sec,page
  100 format(a1,9a8,a7//i2,1x,a4,i4,2x,i2,1h:,i2.2,1h:,i2.2,16x,
     +  'TGMET',28x,'Page ',i3/)

      return
      end

C-------------------------------------------------------------------
C Subroutine 'BUCKET' to bucket round a vector (max 10 elements).
C  Input = R*4 array, Output = I*4 array

      subroutine bucket(intable,outtable,lth)

      implicit integer*2 (a-z)
      integer*2 i,lth
      integer*4 outtable
      real*4    garb,intable
      dimension garb(10),intable(lth),outtable(lth)

      do 100 i = 1,lth
        garb(i) = 0.5
  100 continue

      do 200 i = 1,lth
        outtable(i) = INT4(intable(i) + garb(i))
        garb(i)     = intable(i) - outtable(i) + garb(i)
  200 continue

      return
      end

C-------------------------------------------------------------------
C Subroutine 'BUCKET1' to bucket round a single scalar value
C  Input = R*4 scalar, Output = I*4 scalar

      subroutine bucket1(inval,outval,garb)

      implicit  none
      integer*4 outval
      real*4    garb,inval

      outval = INT4(inval + garb)
      garb   = inval - outval + garb

      return
      end

C-------------------------------------------------------------------
C Subroutine 'WORKERS' to apply worker submodel to translate an
C  average no. of workers/HH to the percent of HHs with 0, 1, 2, and
C  3+ workers.

      subroutine workers(wkrhh,wpct)

      implicit none

      integer*2 lind,hind,w

      real*4 low,high,range,ratio,wpct(4),csum,diff,
     +  wkrhh,wkrmodl(4,16)

C  'WKRMODL' array: regional base workers/HH model.
C   (Derived from 2000 CTPP, part 1, table 62, WorkerModel.xls).
C   Dimensions: WKRMODL(workers, avg workers/HH index)
C                                       DATA OK
C           workers:    0      1      1      3+
      data wkrmodl / 65.59, 26.22,  8.19,  0.00,        ! 0.4
     +               60.69, 29.45,  9.86,  0.00,        ! 0.5
     +               55.79, 32.68, 11.53,  0.00,
     +               48.84, 37.33, 11.22,  2.61,
     +               41.28, 39.42, 16.23,  3.07,
     +               38.08, 37.89, 19.61,  4.42,
     +               33.55, 38.13, 23.45,  4.87,        ! 1.0
     +               27.78, 39.88, 27.50,  4.84,
     +               23.89, 39.26, 30.82,  6.03,
     +               20.02, 38.66, 34.50,  6.82,
     +               16.75, 37.45, 37.80,  8.00,
     +               12.47, 36.48, 42.67,  8.38,        ! 1.5
     +                8.19, 36.61, 46.88,  8.32,
     +                6.80, 33.39, 45.89, 13.92,
     +                5.55, 33.01, 45.77, 18.31,
     +                2.00, 18.00, 59.00, 21.00/        ! 2.0

C Check for min/max input workers/HH.

          if (wkrhh .gt. 2.0) wkrhh = 2.0
          if (wkrhh .lt. 0.4) wkrhh = 0.4

C Interpolate within the look-up table to get the initial proportion
C  of HHs by number of workers.

          lind  = INT(10.0*wkrhh - 3.0)
          hind  = lind + 1
          ratio = 10.0*wkrhh - INT(10.0*wkrhh)
          if (lind .lt. 1)  lind = 1
          if (lind .gt. 17) lind = 17
          if (hind .lt. 1)  hind = 1
          if (hind .gt. 17) hind = 17
          do w = 1,4
            wpct(w) = 0.01 * (wkrmodl(w,lind) +
     +                ratio* (wkrmodl(w,hind) - wkrmodl(w,lind)))
          end do

C Ensure that total percentages sum to 1.0.

          csum = wpct(1) + wpct(2) + wpct(3) + wpct(4)
          diff = abs(csum - 1.000)
          if (diff .gt. 0.001) then
            do w = 1,4
              wpct(w) = wpct(w)/csum
            end do
          end if

      return
      end



