      SUBROUTINE GUSTRAT(KFILDO,KFIL10,IDPARS,JD,NDATE,
     1                   IPACK,IWORK,DATA,ND5,
     2                   FD1,FD2,FD3,FD4,ND2X3,
     3                   IS0,IS1,IS2,IS4,ND7,
     4                   LSTORE,ND9,LITEMS,CORE,ND10,
     5                   NGRIDC,ND11,NSLAB,NBLOCK,NFETCH,
     6                   ISTAV,L3264B,MISTOT,IER)
C
C        MARCH  2006   RUDACK     MDL   MOS-2000  
C        SEP    2007   COSGROVE   MODIFIED COMPUTATIONAL LOOP TO
C                                 LOOP THROUGH ND2X3, NOT ND5
C        DEC    2014   ENGLE      ADDED NSLAB TO CALL SEQUENCE
C              
C        PURPOSE
C            TO COMPUTE THE RATIO OF THE MODEL 925 MB WIND SPEED
C            TO THE MODEL 10M WIND SPEED.  LARGER RATIO VALUES
C            INDICATE THAT SURFACE WIND GUSTS ARE MORE LIKELY TO
C            OCCURR.
C
C            THE FOLLOWING IDPARS(1) AND IDPARS(2) ARE ACCOMMODATED:
C
C               004 500 - RATIO OF THE 925 MB WIND SPEED TO THE
C                         10M WIND SPEED. 
C
C        DATA SET USE
C            KFILDO = DEFAULT UNIT NUMBER FOR OUTPUT(PRINT) FILE.
C                     (OUTPUT)
C            KFIL10 = UNIT NUMBER OF TDL MOS-2000 FILE SYSTEM
C                     ACCESS.(INPUT-OUTPUT)
C
C        VARIABLES
C              KFILDO = DEFAULT UNIT NUMBER FOR OUTPUT (PRINT) FILE.
C                       (INPUT)
C              KFIL10 = UNIT NUMBER OF TDL MOS-2000 FILE SYSTEM ACCESS.
C                       (INPUT)
C           IDPARS(J) = THE PARSED, INDIVIDUAL COMPONENTS OF THE
C                       PREDICTOR ID CORRESPONDING TO ID() (J=1,15).
C                       (INPUT)
C                       J=1--CCC      (CLASS OF VARIABLE),
C                       J=2--FFF      (SUBCLASS OF VARIABLE),
C                       J=3--B        (BINARY INDICATOR),
C                       J=4--DD       (DATA SOURCE, MODEL NUMBER),
C                       J=5--V        (VERTICAL APPLICATION),
C                       J=6--LBLBLBLB (BOTTOM OF LAYER, 0 IF ONLY
C                                      1 LAYER)
C                       J=7--LTLTLTLT (TOP OF LAYER)
C                       J=8--T        (TRANSFORMATION)
C                       J=9--RR       (RUN TIME OFFSET, ALWAYS +
C                                      AND BACK IN TIME)
C                       J=10-OT       (TIME APPLICATION)
C                       J=11-OH       (TIME PERIOD IN HOURS)
C                       J=12-TAU      (PROJECTION IN HOURS)
C                       J=13-I        (INTERPOLATION TYPE)
C                       J=14-S        (SMOOTHING INDICATOR)
C                       J=15-G        (GRID INDICATOR)
C               JD(J) = THE BASIC INTEGER PREDICTOR ID (J=1,4).
C                       THIS IS THE SAME AS ID(J), EXCEPT THAT
C                       THE PORTIONS PERTAINING TO PROCESSING
C                       ARE OMITTED:
C                       B = IDPARS(3),
C                       T = IDPARS(8),
C                       I = IDPARS(13),
C                       S = IDPARS(14),
C                       G = IDPARS(15), AND
C                       THRESH.
C                       ID() IS USED TO HELP IDENTIFY THE BASIC MODEL
C                       FIELDS AS READ FROM THE ARCHIVE. (INPUT)
C               NDATE = THE DATE/TIME FOR WHICH PREDICTOR IS NEEDED.
C                       (INPUT)
C            IPACK(J) = WORK ARRAY (J=1,ND5). (INTERNAL)
C            IWORK(J) = WORK ARRAY (J=1,ND5). (INTERNAL)
C             DATA(J) = DATA ARRAY TO HOLD RETURNED DATA AT
C                       GRIDPOINTS. IN THIS CASE, THE RATIO
C                       OF THE 925MB WIND SPEED AND THE 10M
C                       WIND SPEED (J=1,ND5). (OUTPUT)
C                 ND5 = DIMENSION OF IPACK( ), AND IWORK( ) AND
C                       DATA( ) TO ND5.  (INPUT)
C              FD1(J) = WORK ARRAY TO HOLD THE 925MB WIND SPEED.
C                       (J=1,ND2X3). (INTERNAL)
C              FD2(J) = WORK ARRAY TO HOLD THE 10M WIND SPEED.
C                       (J=1,ND2X3). (INTERNAL)
C              FD3(J) = WORK ARRAY. (J=1,ND2X3).  (INTERNAL)
C              FD4(J) = WORK ARRAY. (J=1,ND2X3).  (INTERNAL)
C               ND2X3 = DIMENSION OF SEVERAL VARIABLES.  THE SIZE OF
C                       THE GRID IS NOT KNOWN BEFORE FD1 AND FD2
C                       ARE FETCHED.  (INPUT)
C              IS0(J) = MOS-2000 GRIB SECTION 0 ID'S (J=1,3).
C                       (INTERNAL)
C              IS1(J) = MOS-2000 GRIB SECTION 1 ID'S (J=1,22+).
C                       (INTERNAL)
C              IS2(J) = MOS-2000 GRIB SECTION 2 ID'S (J=1,12).
C                       IS2(3) AND IS2(4) ARE USED BY THE CALLING
C                       PROGRAM AS THE GRID DIMENSIONS.
C                       (INTERNAL-OUTPUT)
C              IS4(J) = MOS-2000 GRIB SECTION 4 ID'S (J=1,4).
C                       (INTERNAL)
C                 ND7 = DIMENSION OF IS0(),IS1(),IS2(), AND IS4().
C                       NOT ALL LOCATIONS ARE USED. (INPUT)
C         LSTORE(L,J) = THE ARRAY HOLDING INFORMATION ABOUT THE
C                       DATA STORED (L=1,12) (J=1,LITEMS).
C                       (INPUT-OUTPUT)
C                       L=1,4--THE 4 ID'S FOR THE DATA.
C                       L=5  --LOCATION OF STORED DATA.  WHEN IN CORE,
C                              THIS IS THE LOCATION IN CORE() WHERE
C                              THE DATA START.  WHEN ON DISK,
C                              THIS IS MINUS THE RECORD NUMBER WHERE
C                              THE DATA START.
C                       L=6  --THE NUMBER OF 4-BYTE WORDS STORED.
C                       L=7  --2 FOR DATA PACKED IN TDL GRIB, 1 FOR NOT.
C                       L=8  --THE DATE/TIME OF THE DATA IN FORMAT
C                              YYYYMMDDHH.
C                       L=9  --NUMBER OF TIMES DATA HAVE BEEN RETRIEVED.
C                       L=10 --NUMBER OF THE SLAB IN DIR(, ,L) AND
C                              IN NGRIDC(,L) DEFINING THE
C                              CHARACTERISTICS OF THIS GRID.
C                       L=11 --THE NUMBER OF THE PREDICTOR IN THE SORTED
C                              LIST IN ID(,N) (N=1,NPRED) FOR WHICH
C                              THIS VARIABLE IS NEEDED, WHEN IT IS
C                              NEEDED ONLY ONCE FROM LSTORE(,).
C                              WHEN IT IS NEEDED MORE THAN ONCE, THE
C                              VALUE IS SET = 7777.
C                       L=12 --USED INITIALLY IN ESTABLISHING
C                              MSTORE(,). LATER USED AS A WAY OF
C                              DETERMINING WHETHER TO KEEP THIS
C                              VARIABLE.
C                 ND9 = THE SECOND DIMENSION OF LSTORE(,). (INPUT)
C              LITEMS = THE NUMBER OF ITEMS (COLUMNS) IN LSTORE(,)
C                       THAT HAVE BEEN USED IN THIS RUN. (INPUT)
C             CORE(J) = THE ARRAY TO STORE OR RETRIEVE THE DATA
C                       IDENTIFIED IN LSTORE(,) (J=1,ND10).
C                       WHEN CORE() IS FULL DATA ARE STORED ON DISK.
C                       (INPUT)
C                ND10 = DIMENSION OF CORE(). (INPUT)
C         NGRIDC(L,M) = HOLDS THE GRID CHARACTERISTICS (L=1,6) FOR
C                       EACH GRID COMBINATION (M=1,NGRID).
C                       L=1--MAP PROJECTION NUMBER (3=LAMBERT, 5=
C                            POLAR STEREOGRAPHIC).
C                       L=2--GRID LENGTH IN METERS.
C                       L=3--LATITUDE AT WHICH THE GRID LENGTH IS
C                            CORRECT *1000.
C                       L=4--GRID ORIENTATION IN DEGREES * 1000.
C                       L=5--LATITUDE OF LL CORNER IN DEGREES *1000.
C                       L=6--LONGITUDE OF LL CORNER IN DEGREES*1000.
C                ND11 = MAXIMUM NUMBER OF GRID COMBINATIONS THAT CAN
C                       BE DEALT WITH ON THIS RUN.  LAST DIMENSION
C                       OF NGRIDC(,). (INPUT)
C               NSLAB = THE NUMBER OF THE SLAB IN DIR( , , ) AND
C                       IN NGRIDC( , ) DEFINING THE CHARACTERISTICS
C                       OF THIS GRID.  (OUTPUT)
C              NBLOCK = THE BLOCK SIZE IN WORDS OF THE MOS-2000 RANDOM
C                       DISK FILE. (INPUT)
C              NFETCH = INCREMENTED EACH TIME GFETCH IS ENTERED.
C                       IT IS A RUNNING COUNT FROM THE BEGINNING OF
C                       THE PROGRAM.  THIS COUNT IS MAINTAINED IN
C                       CASE THE USER NEEDS IT(DIAGNOSTICS, ETC.).
C                       (OUTPUT)
C               ISTAV = 0 SINCE THE DATA RETURNED ARE GRID DATA.
C                       (OUTPUT)
C              L3264B = INTEGER WORD LENGTH IN BITS OF MACHINE BEING
C                       USED (EITHER 32 OR 64). (INPUT)
C              MISTOT = TOTAL NUMBER OF TIMES A MISSING INDICATOR
C                       HAS BEEN ENCOUNTERED IN UNPACKING GRIDS.
C                       (INPUT-OUTPUT)
C                 IER = STATUS RETURN
C                         0 = GOOD RETURN
C                       100 = THE TWO GRIDS NEEDED ARE NOT THE SAME SIZE
C                       103 = IDPARS(1) AND IDPARS(2) DO NOT INDICATE
C                             THE RATIO OF 925MB WIND SPEED TO THE 10M
C                             WIND SPEED.
C                       SEE GFETCH FOR OTHER VALUES.  (OUTPUT)
C                       WHEN IER NE 0, DATA ARE RETURNED AS MISSING.
C                       (INTERNAL-OUTPUT)
C
C       INTERNAL VARIABLES:
C
C               JD(J) = HOLDS THE 4 ID WORDS OF THE DATA RETRIEVED
C                       INTO FD1() (J=1,4). (INTERNAL)
C               MD(J) = HOLDS THE 4 ID WORDS OF THE DATA RETRIEVED
C                       INTO FD2() (J=1,4). (INTERNAL)
C              MISTOT = TOTAL NUMBER OF TIMES A MISSING INDICATOR
C                       HAS BEEN ENCOUNTERED IN UNPACKING GRIDS.
C                       (INPUT-OUTPUT)
C              NWORDS = NUMBER OF WORDS RETURNED IN DATA().  THIS 
C                       IS RETURNED FROM GFETCH.  (INTERNAL)
C           ITABLE(J) = CONTAINS THE CCCFFF PORTION OF THE 925MB (J=1) 
C                       AND 10M WIND SPEED (J=2), RESPECTIVELY.
C
C     NON SYSTEM SUBROUTINES USED
C        PRSID1, WSPEED
C
      DIMENSION IPACK(ND5),IWORK(ND5),DATA(ND5)
      DIMENSION FD1(ND2X3),FD2(ND2X3),FD3(ND2X3),FD4(ND2X3)
      DIMENSION IS0(ND7),IS1(ND7),IS2(ND7),IS4(ND7)
      DIMENSION LSTORE(12,ND9)
      DIMENSION CORE(ND10)
      DIMENSION NGRIDC(6,ND11)
      DIMENSION JD(4),LD(4),MD(4),IDPARS(15),LDPARS(15),MDPARS(15)
      DIMENSION ITABLE(2)
C
      IER=0
      ISTAV=0
C
      DATA ITABLE/004210,004211/
C
C        MAKE SURE THIS SUBROUTINE DEALS WITH THE PREDICTOR.
C
      IF(IDPARS(1).NE.004.AND.(IDPARS(2).NE.500))THEN
         WRITE(KFILDO,101)(JD(J),J=1,4)
 101     FORMAT(/' ****IDPARS(1) AND IDPARS(2) DO NOT INDICATE ',
     1           'RATIO OF 925MB WIND SPEED TO SURFACE WIND',
     2           'SPEED.',
     3          /'     PREDICTOR ',I9.9,I10.9,I10.9,I4.3,' NOT',
     4           ' ACCOMMODATED IN GUSTRAT.  IER =',I4)
         IER=103
         GOTO 800
      END IF
C
C        CREATE ID FOR THE 925 MB WIND SPEED.
C
      LD(1)=ITABLE(1)*1000+IDPARS(4)
      LD(2)=000000925
      LD(3)=IDPARS(9)*1000000+IDPARS(12)
      LD(4)=0
C
C        FETCH THE 925MB WIND SPEED.
C
      CALL PRSID1(KFILDO,LD,LDPARS)
      CALL WSPEED(KFILDO,KFIL10,LDPARS,LD,NDATE,
     1            NGRIDC,ND11,NSLABL,IPACK,IWORK,FD1,ND5,
     2            LSTORE,ND9,LITEMS,CORE,ND10,NBLOCK,NFETCH,
     3            IS0,IS1,IS2,IS4,ND7,
     4            FD3,FD4,ND2X3,
     5            ISTAV,L3264B,MISTOT,IER)
C
      LX=IS2(3)
      LY=IS2(4)
      NSLAB=NSLABL
C
C        CREATE THE MODEL 10M WIND SPEED ID.
C
      MD(1)=ITABLE(2)*1000+IDPARS(4)
      MD(2)=000000010
      MD(3)=IDPARS(9)*1000000+IDPARS(12)
      MD(4)=0
C
C        FETCH THE 10M MODEL WIND SPEED.
C
      CALL PRSID1(KFILDO,MD,MDPARS)
      CALL WSPEED(KFILDO,KFIL10,MDPARS,MD,NDATE,
     1            NGRIDC,ND11,NSLABM,IPACK,IWORK,FD2,ND5,
     2            LSTORE,ND9,LITEMS,CORE,ND10,NBLOCK,NFETCH,
     3            IS0,IS1,IS2,IS4,ND7,
     4            FD3,FD4,ND2X3,
     5            ISTAV,L3264B,MISTOT,IER)
C
      IF(IER.NE.0)GOTO 800
C
      MX=IS2(3)
      MY=IS2(4)
      NSLAB=NSLABM
C
C        CHECK THE GRID CHARACTERISTICS.
C
      IF((NSLABL.NE.NSLABM).OR.(LX.NE.MX).OR.(LY.NE.MY))THEN
C           THE GRID CHARACTERISTICS ARE NOT THE SAME.
         IER=100
         WRITE(KFILDO,300)(LD(J),J=1,4),(NGRIDC(J,NSLABL),J=1,6),
     1                     LX,LY,
     2                    (MD(J),J=1,4),(NGRIDC(J,NSLABM),J=1,6),
     3                     MX,MY,IER
 300     FORMAT(/' ****DIFFERENT GRID CHARACTERISTICS.  PREDICTOR ',
     1           'NOT COMPUTED IN GUSTRAT.  VALUES FROM NGRIDC( , )',
     2           ' AND X*Y ARE:',
     3           2(/,4X,3I10.9,I4.3,4X,6I10,4X,I3,'*',I3),
     4           '  IER =',I4)
         GOTO 900
      ENDIF
C
C        BEGIN COMPUTATION OF THE GUST RATIO.
C
      DO 400 J=1,ND2X3
C
C           ENSURE THE DENOMINATOR DOES NOT EQUAL ZERO.
C
         IF(FD2(J).LT.1.) FD2(J)=1.
C
         DATA(J)=FD1(J)/FD2(J)     
C
400   CONTINUE
C
      GOTO 900
C
C        SET OUTPUT FIELD TO MISSING WHEN AN ERROR HAS OCCURRED.
C 
 800  DO 801 J=1,ND2X3
        DATA(J)=9999.
 801  CONTINUE
C
 900  RETURN
      END
