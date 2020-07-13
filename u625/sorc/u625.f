      SUBROUTINE U625(KFILDI,KFILDO,KFILEQ,EQNNAM,MODNUM,JFOPEN, 
     1                CDUPS,CMISS,IFOUND,CCALLD,LOCSTA, 
     2                IPACK,IWORK,SDATA,XDATA,
     3                ITIMEZ,NAME,NGPMSL,
     4                NGPRUN,ALSTAS,ALREGS,
     5                DSTAS,STNMEF,ITAU,TRESHL,
     6                NGP,LGP,IRNGP,DNGP,
     7                CCALLML,CCALLEF,
     8                CONST,AVG,CORR,IDTAND,
     9                ID,IDPARS,JD,MTRMS,COEF,IDEQN,
     A                L3264B,L3264W,ND1,ND2,ND3,ND4,ND11,ND13)
C
C        NOVEMBER 1999   DREWRY   TDL   MOS-2000
C        JUNE     2000   GLAHN    REMOVED TEST FOR ND11 BEING EXCEEDED;
C                                 ADDED STATEMENT NUMBERS; REMOVED CALL
C                                 TO PLIST FROM NSETS LOOP
C        JULY     2000   GLAHN    MODIFIED EXTENSIVELY
C        AUG      2000   MCE      MODIFIED "NN" TO "$"
C                                 THE $ OR NN ON AN HP SUPPRESSES A 
C                                 NEWLINE AT THE END OF OUTPUT.  ONLY
C                                 A $ CHARACTER CAN BE USED ON IBM.
C        MAY      2006  RUDACK    MODIFIED CODE TO OUTPUT EQUATION FILES
C                                 THAT CONTAIN NO DUPLICATE STATIONS.
C        AUGUST   2014  ENGLE     UPDATED "DATA SET USE" DOC SECTION WITH
C                                 KFILM; ADDED CHECKS TO SKIP CALLS TO
C                                 ALIST AND MATCHP IF KFILCP = 0.
C
C        PURPOSE
C           PROGRAM U625 IS USED TO INVENTORY EQUATION FILES.
C
C        DATA SET USE
C            KFILD(J)    - UNIT NUMBER OF MASTER STATION LIST (J=1) AND
C                          STATION DICTIONARY (J=2). (INPUT)
C            KFILDI      - UNIT NUMBER OF CONTROL FILE. (INPUT)
C            KFILDO      - UNIT NUMBER OF DIAGNOSTIC OUTPUT FILE.
C                          (OUTPUT)
C            KFILEO(J)   - UNIT NUMBER(S) OF MODIFIED EQUATION FILE(S),
C                          (J=1, ND11). (OUTPUT)
C            KFILEQ(J)   - UNIT NUMBER OF EQUATION FILE(S). (INPUT)
C            KFILCP      - UNIT NUMBER OF PREDICTOR CONSTANT FILE.
C                          (INPUT)
C            KFILM       - UNIT NUMBER FOR READING THE VARIABLE LIST
C                          TO MATCH WITH THE UNIQUE PREDICTOR LIST.
C                          (INPUT)
C            IP(4)       - UNIT NUMBER OF STATION OUTPUT FILE. (OUTPUT)
C            IP(5)       - UNIT NUMBER OF STATIONS AND NAMES. (OUTPUT)
C            IP(6)       - UNIT NUMBER OF REGION OUTPUT FILE. (OUTPUT)
C            IP(7)       - UNIT NUMBER OF DUPLICATE OUTPUT FILE.
C                          (OUTPUT)
C            IP(8)       - UNIT NUMBER OF MISSING STATION OUTPUT FILE.
C                          (OUTPUT)
C            IP(9)       - UNIT NUMBER OF MISSING EQUATION OUTPUT FILE.
C                          (OUTPUT)
C            IP(10)      - THE LIST OF U201 VARIABLES READ IN AND
C                          THE LIST OF UNIQUE PREDICTORS NOT IN
C                          THE U201 LIST. 
C            IP(11)      - UNIT NUMBER OF INFORMATION REGARDING INPUT EQUATION FILE.
C            IP(12)      - UNIT NUMBER OF INFORMATION REGARDING OUTPUT EQUATION FILE.
C            IP(15)      - UNIT NUMBER OF UNIQUE PREDICTOR OUTPUT FILE.
C                          (OUTPUT)
C            
C        VARIABLES
C              A(ND2) = SAME AS CONST BUT DIMENSIONED SO IT CAN BE PASSED TO
C                       WROPEQ.
C         ALREGS(ND1) = ARRAY OF STATIONS ALPHABETIZED BY REGION. 
C         ALSTAS(ND1) = ARRAY OF ALPHABETIZED STATIONS.
C       AVG(ND13,ND3) = INFORMATION READ IN BY RDEQN.
C           AVG2(ND2) = SAME AS AVG BUT DIMENSIONED SO IT CAN BE PASSED TO
C                       WROPEQ.
C         CCALLD(ND1) = LIST OF STATIONS READ. RETURNED FROM RDC().
C      CCALLEF(ND1,6) = CALL LETTERS OF THE STATIONS IN THE EQUATION
C                       FILE.
C      CCALLML(ND1,6) = CALL LETTERS OF THE STATIONS IN THE MASTER 
C                       STATION LIST. 
C            CDICT(J) = HOLDS A LINE OF THE STATION DICTIONARY.
C          CDUPS(ND1) = HOLDS DUPLICATE STATIONS THAT ARE READ IN FROM 
C                       THE EQUATION FILE.
C          CMISS(ND1) = HOLDS STATIONS IN THE MASTER STATION LIST THAT
C                       WERE NOT IN THE EQUATION FILE.
C  COEF(ND13,ND2,ND3) = INFORMATION READ IN BY RDEQN.
C              COLDFL = READS IN THE CHARACTER FROM THE STATION 
C                       DICTIONARY WHICH MARKS IT AS OLD.
C     CONST(ND13,ND3) = INFORMATION READ IN BY RDEQN.
C      CORR(ND13,ND3) = INFORMATION READ IN BY RDEQN.
C          CORR2(ND2) = SAME AS CORR BUT DIMENSIONED SO IT CAN BE PASSED TO
C                       WROPEQ.
C               CTMP1 = TEMPORARY VARIABLE USED IN SORTING THE STATIONS. 
C               CTMP2 = TEMPORARY VARIABLE USED IN SORTING THE STATIONS. 
C           DIRNAM(2) = HOLDS THE NAMES OF THE MASTER STATION LIST AND 
C                       STATION DICTIONARY.
C          DSTAS(ND1) = STATION LIST WITH NONE OF THE DUPLICATES
C                       REMOVED. 
C          DNGP(ND13) = FOR EACH EQUATION (L=1,KGP) IN THIS SET, THE
C                       NUMBER OF STATIONS IN EACH GROUP, BEFORE 
C                       DUPLICATES ARE REMOVED.
C                DONE = BOOLEAN VARIABLE USED TO DETERMINE IF THERE 
C                       WERE ANY STATIONS IN THE FILE FOR WHICH THERE
C                       WERE NO EQUATIONS 
C        EQNNAM(ND11) = PATH(S) OF EACH EQUATION FILE. 
C       EQNNAMO(ND11) = PATH(S) OF THE MODIFIED EQUATION FILE(S).
C               FOUND = FLAGS IF A STATION DID NOT HAVE AN EQUATION FOR
C                       ANY PREDICTORS. 
C                   I = LOOP CONTROL VARIABLE.
C                IALL = 0 WHEN THE MASTER LIST OF STATIONS IS INPUT IN
C                         CCALL( ,1) AND IS TO BE USED.
C                     = 1 WHEN THE MASTER LIST OF STATIONS IS GENERATED 
C                         IN RDEQN AND IS COMPOSED OF ALL STATIONS IN 
C                         THE EQUATIONS.  THIS LIST WILL BE IN THE ORDER 
C                         THE STATIONS ARE ENCOUNTERED IN THE EQUATIONS.
C                ICNT = COUNT OF THE STATIONS DONE REGION BY REGION.
C           ID(J,ND4) = THE LIST OF UNIQUE PREDICTORS (J=1,4).
C        IDEQN(J,L,M) = THE 4-WORD ID (J=1,4) FOR EACH EQUATION
C                       (L=1,KGP), AND EACH PREDICTAND (M=1,MTANDS).
C                       (J=5,6,7 ARE NEEDED IN RDEQN.)
C               IDICT = MAXIMUM NUMBER OF LINES IN THE STATION DICTIONARY.
C                       THIS HAS NO EFFECT ON ANYTHING, REALLY, AS LONG
C                       AS IT IS LARGE ENOUGH.  THE LOOP IN WHICH IT IS
C                       USED TERMINATES WHEN THE END OF FILE IS REACHED.
C      IDPARS(15,ND4) = VARIABLE USED BY PLIST.
C       IDTAND(J,ND3) = THE PREDICTAND IDS (J=1,4) FOR THE EQUATION SET.
C             IDUPCNT = COUNT OF DUPLICATED STATIONS IN THE EQUATION
C                       FILE.
C                IEOF = END OF FILE RETURN VALUE. 
C                 IER = STATUS RETURN.
C             IFILCNT = COUNTER TO DETERMINE IF ALL OF THE STATIONS
C                       FROM THE EQUATION FILE HAVE BEEN FOUND IN THE
C                       STATION DIRECTORY. 
C         IFOUND(ND1) = VARIABLE USED IN RDEQN.
C              IMSCNT = NUMBER OF STATIONS IN THE MASTER STATION LIST
C                       MISSING FROM THE EQUATION FILE.
C               INITF = VARIABLE OUTPUT FROM RDEQN.  NOT USED IN U625.
C              INOAVG = CONSTANT VALUE * 1000 THAT SIGNIFIES THERE IS
C                       NO AVG VALUE, AND CONSEQUENTLY NO EQUATION,
C                       FOR A PARTICULAR STATION AND PREDICTAND.
C                 IOS = IOSTAT RETURN. 
C               IP(J) = EACH VALUE (J=1,25) INDICATES WHETHER (>1)
C                       OR NOT (=0) CERTAIN INFORMATION WILL BE WRITTEN.
C                       WHEN IP( ) > 0, THE VALUE INDICATES THE UNIT
C                       NUMBER FOR OUTPUT.  THESE VALUES SHOULD NOT BE
C                       THE SAME AS ANY KFILX VALUES EXCEPT POSSIBLY
C                       KFILDO, WHICH IS THE DEFAULT OUTPUT FILE.  THIS
C                       IS ASCII OUTPUT, GENERALLY FOR DIAGNOSTIC 
C                       PURPOSES.  THE FILE NAMES WILL BE 4 CHARACTERS
C                       'U600', THEN 4 CHARACTERS FROM IPINIT, THEN 
C                       2 CHARACTERS FROM IP(J) (E.G., 'U600HRG130').
C                       THE ARRAY IS INITIALIZED TO ZERO IN CASE LESS
C                       THAN THE EXPECTED NUMBER OF VALUES ARE READ IN.
C                       EACH OUTPUT ASCII FILE WILL BE TIME STAMPED.
C                       NOTE THAT THE TIME ON EACH FILE SHOULD BE VERY
C                       NEARLY THE SAME, BUT COULD VARY BY A FRACTION
C                       OF A SECOND.  IT IS INTENDED THAT ALL ERRORS
C                       BE INDICATED ON THE DEFAULT, SOMETIMES IN
C                       ADDITION TO BEING INDICATED ON A FILE WITH
C                       A SPECIFIC IP( ) NUMBER, SO THAT THE USER
C                       WILL NOT MISS AN ERROR.
C                       (1) = ALL ERRORS AND OTHER INFORMATION NOT
C                           SPECIFICALLY IDENTIFIED WITH OTHER IP( )
C                           NUMBERS.  WHEN IP(1) IS READ AS NONZERO,
C                           KFILDO, THE DEFAULT OUTPUT FILE UNIT NUMBER,
C                           WILL BE SET TO IP(1).  WHEN IP(1) IS READ
C                           AS ZERO, KFILDO WILL BE USED UNCHANGED.
C                       (4) = THE EQUATION FILE STATION LIST, CALL 
C                           LETTERS ONLY.
C                       (5) = THE EQUATION FILE CALL LETTERS ALONG
C                           WITH THEIR CORRESPONDING NAMES.
C                       (6) = THE EQUATION FILE CALL LETTERS OUTPUT
C                           BY REGION. 
C                       (7) = STATIONS WHICH WERE DUPLICATED IN THE
C                           EQUATION FILE. THE REGIONS IN WHICH THESE
C                           DUPLICATED STATIONS APPEAR IS ALSO OUTPUT.
C                       (8) = ALL STATIONS WHICH APPEAR IN THE EQUATION
C                           FILE BUT WHICH ARE MISSING FROM THE MASTER 
C                           STATION LIST, AS WELL AS ALL STATIONS WHICH
C                           APPEAR IN THE MASTER STATION LIST BUT WHICH
C                           ARE MISSING FROM THE EQUATION FILE.
C                       (9) = ALL STATIONS AND PREDICTANDS FOR WHICH
C                           THERE ARE NO EQUATIONS. 
C                       (10) = THE LIST OF U201 VARIABLES READ IN AND
C                           THE LIST OF UNIQUE PREDICTORS NOT IN
C                           THE U201 LIST. 
C                       (11) = THE TOTAL NUMBER OF EQUATIONS, STATIONS
C                            (INCLUDING DUPLICATES), AND FILENAME OF INPUT
C                            EQUATION FILES.
C                       (12) = THE TOTAL NUMBER OF EQUATIONS, STATIONS
C                            (SANS DUPLICATES), AND FILENAME OF OUTPUT
C                            (MODIFIED) EQUATION FILES.
C                       (15) = LIST OF ALL UNIQUE PREDICTORS.
C          IPACK(ND1) = VARIABLE USED IN RDSTGN AND RDSTGA.
C              IPINIT = FOUR CHARACTERS READ FROM THE CONTROL FILE THAT 
C                       GO INTO THE FILE NAME OF EACH IP USED. 
C         IRNGP(ND13) = FOR EACH EQUATION (L=1,KGP) IN THIS SET, THE
C                       NUMBER STATIONS IN EACH GROUP.
C               ISTOP = VARIABLE USED BY PLIST.
C                ISUM = USED TO DETERMINE IN WHICH REGION(S) EACH 
C                       DUPLICATE IS FOUND. 
C           ITAU(ND4) = VARIABLE USED IN PLIST.
C         ITIMEZ(ND1) = VARIABLE USED BY RDSTGN AND RDSTGA.
C             ITMPVAR = TEMPORARY VARIABLE USED TO FILL IN STATION
C                       CALL LETTER FIELDS FROM THE STATION DICTIONARY
C          IWORK(ND1) = VARIABLE USED IN RDSTGN AND RDSTGA
C                   J = LOOP CONTROL VARIABLE.
C           JD(4,ND4) = VARIABLE USED IN PLIST.
C        JFOPEN(ND11) = VARIABLE USED IN RDSNAM.
C                   K = LOOP CONTROL VARIABLE. 
C            KFILD(J) = UNIT NUMBER OF MASTER STATION LIST (J=1) AND
C                       STATION DICTIONARY (J=2). (INPUT)
C              KFILDI = UNIT NUMBER OF CONTROL FILE. 
C              KFILDO = UNIT NUMBER OF DIAGNOSTIC OUTPUT FILE. 
C         KFILEO(ND11)= UNIT NUMBER(S) OF MODIFIED EQUATION FILE(S),
C                       (J=1, ND11).
C        KFILEQ(ND11) = UNIT NUMBER OF THE EQUATION FILE(S). (INPUT)
C        KGPMSL(ND11) = NUMBER OF EQUATIONS IN THE MASTER STATION LIST.
C                   L = LOOP CONTROL VARIABLE. 
C              L3264B = INTEGER WORD LENGTH OF MACHINE BEING USED.
C              L3264W = NUMBER OF WORDS IN 64 BITS ON THE MACHINE
C                       BEING USED.
C              LGP(L) = FOR EACH EQUATION (L=1,KGP) IN THIS SET, THE 
C                       LOCATION IN LOCSTA ( ,I) OF WHERE THE FIRST 
C                       STATION IN THE SET IS.
C         LOCSTA(ND1) = VARIABLE USED IN RDEQN.
C                 LOW = VARIABLE USED TO SORT STATIONS.
C           LP(5,ND2) = SAME AS IDEQN BUT DIMENSIONED SO IT CAN BE PASSED TO
C                       WROPEQ.
C              MISSNG = DETERMINES IF A MASTER STATION LIST VALUE IS 
C                       MISSING FROM THE EQUATION FILE.
C        MODNUM(ND11) = VARIABLE USED BY RDSNAM IN INT625.
C              MTANDS = NUMBER OF PREDICTANDS IN AN EQUATION SET. 
C            MTRMS(L) = THE NUMBER OF TERMS IN EACH EQUATION 
C                       (L=1,KGP).  
C               NALPH = DETERMINES IF THE OUTPUT FILES WILL
C                       CONTAIN ALPHABETIZED STATION LISTS.
C           NAME(ND1) = VARIABLE USED IN RDSTGN AND RDSTGA.
C                 ND1 = MAXIMUM NUMBER OF STATIONS THAT CAN BE INPUT.
C                 ND2 = MAXIMUM NUMBER OF TERMS IN ANY EQUATION.
C                 ND3 = MAXIMUM NUMBER OF PREDICTANDS IN ANY EQUATION.
C                 ND4 = MAXIMUM NUMBER OF DIFFERENT PREDICTORS IN RUN.
C                ND11 = MAXIMUM NUMBER OF EQUATION FILES.
C                ND13 = MAXIMUM NUMBER OF DIFFERENT EQUATIONS PER SET.
C                 KGP = NUMBER OF EQUATIONS IN THE EQUATION SET 
C                       BEING PROCESSED. 
C               NDATE = FOR U700, THIS MUST BE 9999.
C                 NEW = 0 WHEN THE CALL LETTERS FROM THE EQUATION FILE 
C                         ARE TO BE OUTPUT.
C                     = 1 WHEN THE CIAO CALL LETTERS ARE TO BE OUTPUT. 
C              NGP(L) = FOR EACH EQUATION (L=1,KGP) IN THIS SET, THE 
C                       NUMBER OF STATIONS IN EACH GROUP.
C         NGPMSL(ND1) = FOR EACH EQUATION (L=1,KGPMSL) IN THIS SET,
C                       THE NUMBER OF STATIONS IN EACH GROUP. 
C         NGPRUN(ND1) = VARIABLE USED IN RDSTGA.
C               NOPP1 = VARIABLE USED BY WROPEQ.
C               NPRED = THE NUMBER OF VALUES IN ID( , ).  
C                NSET = CURRENT EQUATION SET BEING PROCESSED. 
C               NSETS = TOTAL NUMBER OF EQUATION SETS.
C               NSSEI = NUMBER OF SINGLE-STATION EQUATIONS OF INPUT
C                       EQUATION FILES.
C               NSSEO = NUMBER OF SINGLE-STATION EQUATIONS OF OUTPUT
C                       EQUATION FILES.
C               NSTAD = NUMBER OF STATIONS IN THE EQUATION FILE, 
C                       INCLUDING ALL DUPLICATES.
C              NSTAND = NUMBER OF STATIONS WRITTEN TO THE MODIFIED EQUATION
C                       OUTPUT FILE (I.E. SANS DUPLICATES).
C              NSTAEF = NUMBER OF STATIONS IN THE EQUATION FILE.
C              NSTAML = NUMBER OF STATIONS IN THE MASTER STATION LIST.
C              NUMOUT = TOTAL NUMBER OF MODIFIED EQUATION FILES TO BE
C                       WRITTEN OUT TO UNIT KFILEO(J) (J=1,NUMOUT).
C               NVRBL = VARIABLE TO BE USED BY WROPEQ.
C              P(ND2) = SAME AS COEF BUT DIMENSIONED SO IT CAN BE PASSED TO
C                       WROPEQ.
C               RUNID = RUN ID INPUT IN THE CONTROL FILE BY THE USER.
C          SDATA(ND1) = VARIABLE USED BY RDSTGN AND RDSTGA.
C              STANAM = STATION NAME READ IN FROM THE STATION 
C                       DICTIONARY.
C         STNMEF(ND1) = HOLDS THE STATION NAMES OF THE STATIONS IN THE 
C                       EQUATION FILE.
C           TRESHL(N) = THE LOWER BINARY THRESHOLD CORRESPONDING TO 
C                       IDPARS( ,N) (N=1,ND4).  FOR U700, THE UPPER 
C                       THRESHOLD IS ALWAYS LARGE.  THAT IS, THE
C                       PREDICTORS CARRY WITH THEM ONLY ONE THRESHOLD,
C                       THE LOWER ONE.  (OUTPUT)
C          XDATA(ND1) = VARIABLE USED BY RDSTGN AND RDSTGA.
C
C        NONSYSTEM SUBROUTINES CALLED
C            RDSTGN, RDSTGA, RDEQN, PLIST, WRHEAD, WROPEQ
C
      CHARACTER*1  COLDFL
      CHARACTER*4  IPINIT
      CHARACTER*8  CCALLEF, CCALLML, CDUPS,
     1             CMISS, CDICT, CCALLD, ALSTAS, ALREGS,
     2             CTMP1, DSTAS
      CHARACTER*20 NAME, STANAM, STNMEF, CTMP2
      CHARACTER*60 EQNNAM, EQNNAMO, DIRNAM 
      CHARACTER*72 RUNID
C      
      LOGICAL MISSNG, FOUND, DONE
C
      REAL          :: AVG, CORR, CORR2, CONST, COEF
      REAL*8        :: AVG2, A, P
C
      INTEGER, PARAMETER :: NTERM=99999999
C
      DIMENSION CDUPS(ND1), CMISS(ND1), AVG2(ND2), CORR2(ND2),
     1          A(ND2),IFOUND(ND1), CCALLD(ND1), LOCSTA(ND1), 
     2          IPACK(ND1), IWORK(ND1), SDATA(ND1), XDATA(ND1),
     3          ITIMEZ(ND1), NAME(ND1), NGPMSL(ND1),
     4          NGPRUN(ND1), ALSTAS(ND1), ALREGS(ND1),
     5          DSTAS(ND1), STNMEF(ND1)
      DIMENSION CCALLML(ND1,6), CCALLEF(ND1,6)
      DIMENSION IDTAND(4,ND3)
      DIMENSION ITAU(ND4), TRESHL(ND4)
      DIMENSION ID(4,ND4), IDPARS(15,ND4), JD(4,ND4), LP(5,ND2)
      DIMENSION KFILEQ(ND11), EQNNAM(ND11), KFILEO(ND11), 
     1          EQNNAMO(ND11), MODNUM(ND11), JFOPEN(ND11)
      DIMENSION NGP(ND13),LGP(ND13),IRNGP(ND13),DNGP(ND13)
      DIMENSION CONST(ND13,ND3), AVG(ND13,ND3), CORR(ND13,ND3)
      DIMENSION MTRMS(ND13)
      DIMENSION COEF(ND13,ND2,ND3),P(ND2,ND3)
      DIMENSION IDEQN(7,ND13,ND2)  
      DIMENSION KFILD(2), DIRNAM(2), CDICT(6), IP(25)
C    
      DATA IDICT/10000/,
     1     INOAVG/9999000./,
     2     IEOF/-1/
C
      NPRED=0
      NCYCLE=99
C
C            INITIALIZE ARRAYS USED IN RDSNAM( ).
C
      DO I=1,ND11
         KFILEQ(I) = 0
         EQNNAM(I) = ' '
         EQNNAMO(I) = ' '
         MODNUM(I) = 0
         JFOPEN(I) = 0
      ENDDO
C         
      DO I=1,2
         KFILD(I) = 0
         DIRNAM(I) = ' '
      ENDDO
C
C         READ CONTROL INFORMATION FROM THE CONTROL FILE.
C
      CALL INT625(KFILDI,KFILDO,KFILEQ,KFILEO,KFILD,KFILCP,
     1            KFILM,IP,ND11,L3264B,IPINIT,
     2            NALPH,NEW,NDATE,EQNNAM,EQNNAMO,DIRNAM,
     3            MODNUM,JFOPEN,NSETS,NUMOUT,
     4            RUNID,IER) 
C
C        EXECUTED IF A MASTER STATION LIST IS TO BE USED.  READ STATION
C        LIST AND OTHER STATION INFORMATION. THE STATION LIST IS NOT
C        MANDATORY TO RUN THE PROGRAM. IF IT IS PROVIDED, THE STATION
C        LIST CAN BE USED AS READ, OR BE ORDERED ACCORDING TO THE
C        STATION DIRECTORY, WHICH IS ALPHABETICAL BY ICAO CALL LETTERS.
C        THIS ORDERING IS DETERMINED BY THE VALUE OF NALPH READ IN FROM
C        THE CONTROL FILE.
C
      IF (KFILD(1) .NE. 0) THEN
C
         DO J = 1,6
         DO I = 1,ND1
            CCALLML(I,J) = ' '
         ENDDO
         ENDDO
C
         IF(NALPH.EQ.0)THEN
C
C              RETURNS THE MASTER STATION LIST IN THE ORDER AS IT 
C              WAS PROVIDED.
C
            CALL RDSTGN(KFILDO,0,0,KFILD,NEW,CCALLML,
     1                  NAME,IPACK,IWORK,SDATA,XDATA,ITIMEZ,
     2                  NGPMSL,ND1,KGPMSL,NSTAML,IER)
         ELSE
C
C              RETURNS THE MASTER STATION LIST ORDERED ALPHABETICALLY.
C
            CALL RDSTGA(KFILDO,0,0,KFILD,NEW,CCALLML,CCALLD,
     1                  NAME,IPACK,IWORK,SDATA,XDATA,ITIMEZ,
     2                  NGPMSL,NGPRUN,ND1,KGPMSL,NSTAML,IER)
         ENDIF
C
      ENDIF
C      
C         EXECUTED ONCE FOR EACH EQUATION FILE INPUT IN THE CONTROL
C         FILE.
C
      EQUNFILE: DO NSET = 1, NSETS
C
C            INITIALIZE CALL LETTER ARRAYS AND THE REGION DESIGNATION.
C
         NSSEI=0
         NSSEO=0
         NSTAND=0
         DO I=1,ND1
            CCALLD(I) = ' '
            CDUPS(I) = ' '
            CMISS(I) = ' '
            ALSTAS(I) = ' '
            ALREGS(I) = ' '
            STNMEF(I) = ' '
C
            DO J = 1,6
               CCALLEF(I,J) = ' '
            ENDDO
C
         ENDDO                
C
C           READ THE INFORMATION FROM THE EQUATION FILE.
C
         IALL = 1
         REWIND(KFILD(2))
C
         CALL RDEQN(KFILDO, KFILEQ(NSET), EQNNAM(NSET), NDATE,
     1              0, 0, 0, 0, 
     2              0, 0, 0,
     3              CCALLEF, IFOUND, NSTAEF, IALL, INITF, CCALLD,
     4              KGP, NGP, LGP,
     5              MTRMS, MTANDS,
     6              IDEQN, IDTAND,
     7              LOCSTA, CONST,
     8              AVG, CORR,
     9              COEF,
     A              ND1, ND2, ND3, ND1, ND13, IER)
C
C            DETERMINE THE NUMBER OF SINGLE-STATION EQUATIONS
C            FROM INPUT EQUATION FILES.
C
         DO L=1,KGP
            IF(NGP(L).EQ.1)NSSEI=NSSEI+1
         ENDDO
C
C            COMPARE THE EQUATION FILE STATION LIST WITH THE STATION
C            DICTIONARY.
C
	 IFILCNT = 0
C
         DO 150 I = 1,IDICT
C 
C               CHECK THE VALUES READ FROM EACH LINE OF THE STATION
C               DICTIONARY AGAINST THOSE IN THE STATION LIST UNTIL
C               A MATCH IS FOUND OR THE STATION LIST IS FINISHED.
C
            STANAM = ' '
C
            DO J = 1, 6
               CDICT(J) = ' '
            ENDDO
C
            READ(KFILD(2), '(A8,1X,A8,1X,A20,42X,A1,1X,A8,1X,A8,1X,A8,
     1         1X,A8)', IOSTAT=IOS) CDICT(1), CDICT(2), STANAM,
     2         COLDFL, CDICT(3), CDICT(4), CDICT(5), CDICT(6)
            IF (IOS .EQ. IEOF) EXIT
C
            J = 1
C
	    DO 
               IF (J .GT. NSTAEF) EXIT
C
               IF (((CCALLEF(J,1) .EQ. CDICT(1)) .OR. 
     1              (CCALLEF(J,1) .EQ. CDICT(2)) .OR.
     2              (CCALLEF(J,1) .EQ. CDICT(3)) .OR. 
     3              (CCALLEF(J,1) .EQ. CDICT(4)) .OR. 
     4              (CCALLEF(J,1) .EQ. CDICT(5)) .OR. 
     5              (CCALLEF(J,1) .EQ. CDICT(6))) .AND. 
     6              (COLDFL .NE. 'O')) THEN
C
C                    FILLS IN THE FIELDS OF CCALLEF ACCORDING TO THE
C                    ORDER IN THE STATION DICTIONARY.
C
                  IF (NEW .EQ. 1) THEN
                     CCALLEF(J,1) = CDICT(1)
                     CCALLEF(J,2) = CDICT(2)
                     CCALLEF(J,3) = CDICT(3)
                     CCALLEF(J,4) = CDICT(4)
                     CCALLEF(J,5) = CDICT(5)
                     CCALLEF(J,6) = CDICT(6)
C
                  ELSE
C                       FILLS THE REMAINING FIELDS IN CCALLEF, LEAVING
C                       THE FIRST FIELD ALONE, PRESERVING THE CALL
C                       LETTERS WHICH WERE READ FROM THE EQUATION FILE
C                       AND WHICH WILL BE OUTPUT.
C
                     ITMPVAR = 2
C
                     DO K = 1,6
C                          IF THE STATION ID IS THE SAME AS THE ID IN
C                          THE FIRST COLUMN OF CCALLEF, IT IS SKIPPED
C                          OVER, BECAUSE THAT ID WILL BE LEFT IN THE 
C                          FIRST COLUMN.
                        IF (CCALLEF(J,1) .EQ. CDICT(K)) THEN
                           CYCLE
                        ELSE
                           CCALLEF(J,ITMPVAR) = CDICT(K) 
                           ITMPVAR = ITMPVAR + 1
                        ENDIF
                     ENDDO
C
                  ENDIF
C
                  STNMEF(J) = STANAM
                  IFILCNT = IFILCNT + 1
                  EXIT
               ENDIF
C
               J = J + 1
            ENDDO
C
C              CHECKS IF ALL OF THE STATIONS HAVE BEEN FOUND IN THE
C              DICTIONARY.
            IF (IFILCNT .EQ. NSTAEF) EXIT
 150     CONTINUE
C
C            MAKE A COPY OF THE STATION LIST AND NGP() BEFORE THE
C            DUPLICATES ARE REMOVED SO THAT THEY CAN BE USED TO OUTPUT
C            IN THE REGIONAL OUTPUT FILE.
C         
	 DO I = 1, NSTAEF
            ALREGS(I) = CCALLEF(I,1)
            DSTAS(I) = CCALLEF(I,1)
         ENDDO
C         
	 DO I = 1, ND13
            IRNGP(I) = NGP(I)
            DNGP(I) = NGP(I)
         ENDDO
C
         NSTAD = NSTAEF
C            
C            CHECK EACH STATION TO SEE IF IT HAS ANY 
C            DUPLICATES IN THE LIST.
C
         I = 1
         IDUPCNT = 0
C
         DO 160 WHILE (CCALLEF(I,1) .NE. ' ')
            J = I + 1
C
            DO WHILE((CCALLEF(J,1) .NE. ' ') .AND. (J .LE. NSTAEF))            
C                 IF THE STATION IS A DUPLICATE ADD IT TO THE DUPLICATE
C                 LIST.
C               
	       IF ((CCALLEF(J,1) .EQ. CCALLEF(I,1)) .OR.
     1             (CCALLEF(J,2) .EQ. CCALLEF(I,1)) .OR.
     2             (CCALLEF(J,3) .EQ. CCALLEF(I,1)) .OR.
     3             (CCALLEF(J,4) .EQ. CCALLEF(I,1)) .OR.
     4             (CCALLEF(J,5) .EQ. CCALLEF(I,1)) .OR.
     5             (CCALLEF(J,6) .EQ. CCALLEF(I,1))) THEN
C
                  IDUPCNT = IDUPCNT + 1
                  CDUPS(IDUPCNT) = CCALLEF(I,1)
C
C                    REMOVE THE DUPLICATE FROM THE STATION ARRAY BY 
C                    MOVING EACH ELEMENT IN THE ARRAY UP ONE INDEX.               
C                  
		  DO K = J, NSTAEF
                     CCALLEF(K,1) = CCALLEF(K+1,1)
                     CCALLEF(K,2) = CCALLEF(K+1,2)
                     CCALLEF(K,3) = CCALLEF(K+1,3)
                     CCALLEF(K,4) = CCALLEF(K+1,4)
                     CCALLEF(K,5) = CCALLEF(K+1,5)
                     CCALLEF(K,6) = CCALLEF(K+1,6)
                     STNMEF(K) = STNMEF(K+1)
                  ENDDO
C
C                    DECREMENTS THE APPROPRIATE NGP INDEX.
                  L = 1
                  ICNT = NGP(1)
                  DO
                     IF (J .LE. ICNT) THEN
                        NGP(L) = NGP(L) - 1
                        EXIT
                     ELSE
                        L = L + 1
                        ICNT = ICNT + NGP(L)  
                     ENDIF
                  ENDDO
C
                  NSTAEF = NSTAEF - 1
C               
	       ENDIF
C
               J = J + 1
            END DO
C
            I = I + 1
 160        CONTINUE 
C
C            CREATE ALPHABETIZED LISTS OF THE EQUATION FILE STATIONS
C            AND THE REGIONALIZED EQUATION FILE STATIONS.
C
C            CREATE COPIES OF THE FIRST COLUMN OF THE STATION ARRAY
C            TO BE ALPHABETIZED.
C         
	 IF(NALPH .EQ. 1) THEN
C            
	    DO I = 1, NSTAEF
               ALSTAS(I) = CCALLEF(I,1)
            ENDDO
C
C               SORT THE STATION LIST CALL LETTERS 
C               ALPHABETICALLY USING A SELECTION SORT.
C            
	    DO I = 1, NSTAEF
               LOW = I
C               
	       DO J = I+1, NSTAEF
                  IF (ALSTAS(J) .LT. ALSTAS(LOW)) LOW = J
               ENDDO
C
C                 IF THE CURRENT STATION WAS NOT FOUND TO BE NEXT
C                 ALPHABETICALLY, IT IS EXCHANGED IN THE ARRAY
C                 WITH THE STATION WHICH WAS FOUND TO BE NEXT.
C               
	       IF (LOW .NE. I) THEN
                  CTMP1 = ALSTAS(I)
                  CTMP2 = STNMEF(I)
                  ALSTAS(I) = ALSTAS(LOW)
                  STNMEF(I) = STNMEF(LOW)
                  ALSTAS(LOW) = CTMP1
                  STNMEF(LOW) = CTMP2
               ENDIF
C
            ENDDO
C
         ENDIF
C
C            ALPHABETIZE THE REGIONAL STATION ARRAY.
C         
	 IF (NALPH .EQ. 1) THEN
            L = 0
C
C              LOOPS THROUGH EACH GROUP (REGION) ONE AT A TIME.
C            
	    DO 195 I = 1, KGP
C
C                 LOOPS THROUGH EACH STATION IN THE CURRENT REGION,
C                 PLACING THEM IN ALPHABETICAL ORDER.  THE FINAL
C                 POSITION WILL CONTAIN THE CORRECT STATION ONCE
C                 ALL OF THE PRECEDING STATIONS HAVE BEEN ORDERED.
C               
	       DO 190 J = 1, NGP(I)-1
C                  
		  L = L + 1
                  LOW = L
C                    
C                    LOOPS THROUGH EVERY STATION IN THE CURRENT
C                    GROUP WHICH COMES AFTER THE POSITION IN THAT
C                    GROUP WHICH IS CURRENTLY BEING ORDERED.  THE
C                    POSITION OF THE STATION WITH THE LOWEST VALUE 
C                    ALPHABETICALLY IS MARKED WITH THE VARIABLE LOW.
C                  
		  DO K = L+1, L+NGP(I)-J
                     IF (ALREGS(K) .LT. ALREGS(LOW)) LOW = K
                  ENDDO
C
C                    IF THE LOWEST STATION ALPHABETICALLY IS NOT IN THE
C                    POSITION WHICH IS CURRENTLY BEING ORDERED, THEN 
C                    THE CONTENTS OF THE POSITION CURRENTLY BEING 
C                    ORDERED AND THOSE OF THE POSITION WHICH HOLDS
C                    THE LOWEST STATION ALPHABETICALLY ARE SWITCHED. 
C                  
		  IF (LOW .NE. L) THEN
                     CTMP1 = ALREGS(L)
                     ALREGS(L) = ALREGS(LOW)
                     ALREGS(LOW) = CTMP1
                  ENDIF
C               
 190           CONTINUE
C               
	       L = L + 1
C             
 195        CONTINUE
C         
	 ENDIF
C
C            ALPHABETIZE THE STATIONS THAT WILL BE OUTPUT TO THE
C            MODIFIED EQUATIONS FILE(S).  THEN, OUTPUT THE MODIFIED
C            EQUATION FILE.
C
         IF (NUMOUT. NE. 0) THEN
C
C              NOW THAT THE DUPLICATE STATIONS HAVE BEEN REMOVED, RECONFIGURE THE
C              LOCATION IN LOCSTA ( ,I) OF WHERE THE FIRST STATION IN THE SET IS
C              FOR EACH EQUATION (L=1,KGP) IN THIS SET
C
            ITOT=NGP(1)
C
            DO 1950 K=2,KGP
               ITOT = ITOT + NGP(K)
               LGP(K)= ITOT - NGP(K) +1
 1950       CONTINUE
C
            IF (NALPH .EQ. 1) THEN
C
               L = 0
C
C                 LOOPS THROUGH EACH GROUP (REGION) ONE AT A TIME.
C
               DO 197 I = 1, KGP
C
C                    LOOPS THROUGH EACH STATION IN THE CURRENT REGION,
C                    PLACING THEM IN ALPHABETICAL ORDER.  THE FINAL
C                    POSITION WILL CONTAIN THE CORRECT STATION ONCE
C                    ALL OF THE PRECEDING STATIONS HAVE BEEN ORDERED.
C
                  DO 196 J = 1, NGP(I)-1
C
                     L = L + 1
C
                     LOW = L
C
C                       LOOPS THROUGH EVERY STATION IN THE CURRENT
C                       GROUP WHICH COMES AFTER THE POSITION IN THAT
C                       GROUP WHICH IS CURRENTLY BEING ORDERED.  THE
C                       POSITION OF THE STATION WITH THE LOWEST VALUE
C                       ALPHABETICALLY IS MARKED WITH THE VARIABLE LOW.
C
                     DO K = L+1, L+NGP(I)-J
                        IF (CCALLEF(K,1) .LT. CCALLEF(LOW,1)) LOW = K
                     ENDDO
C
C                       IF THE LOWEST STATION ALPHABETICALLY IS NOT IN THE
C                       POSITION WHICH IS CURRENTLY BEING ORDERED, THEN
C                       THE CONTENTS OF THE POSITION CURRENTLY BEING
C                       ORDERED AND THOSE OF THE POSITION WHICH HOLDS
C                       THE LOWEST STATION ALPHABETICALLY ARE SWITCHED.
C
                     IF (LOW .NE. L) THEN
                        CTMP1 = CCALLEF(L,1)
                        CCALLEF(L,1) = CCALLEF(LOW,1)
                        CCALLEF(LOW,1) = CTMP1
                     ENDIF
C
 196              CONTINUE
C
C                    DO NOT INCREMENT THE STATION COUNTER "L"
C                    IF THE NUMBER OF STATIONS IN THE CURRENT 
C                    GROUP BEING PROCESSED IS EQUAL TO ZERO.
C
                  IF(NGP(I).GT.0) L = L + 1
C
 197           CONTINUE
C
            ENDIF
C
C            DETERMINE THE NUMBER OF SINGLE-STATION EQUATIONS
C            FROM OUTPUT EQUATION FILES.
C
         DO L=1,KGP
            IF(NGP(L).EQ.1)NSSEO=NSSEO+1
         ENDDO

C
C              OUTPUT ALL OF THE RECORDS OF THE CHANGED EQUATION FILE.
C
            CALL WRHEAD(KFILDO,KFILEO(NSET),EQNNAM(NSET),IDTAND,
     1                  MTANDS,NCYCLE,IER)
C
            DO 1975 J = 1, KGP
C
               NOPP1 = 1
               NVRBL = MTANDS
C
               DO 1974 K = 1, ND2
                  LP(1,K) = 0
                  LP(2,K) = IDEQN(1,J,K)
                  LP(3,K) = IDEQN(2,J,K)
                  LP(4,K) = IDEQN(3,J,K)
                  LP(5,K) = IDEQN(4,J,K)
                  A(K) = CONST(J,K)
                  AVG2(K) = AVG(J,K)
                  CORR2(K) = CORR(J,K)
C
                  DO 1973 L = 1, ND3
                     P(K,L) = COEF(J,K,L)
 1973             CONTINUE 
C 
 1974          CONTINUE
C
               IF(NGP(J).GT.0) THEN
                  CALL WROPEQ(KFILDO,KFILEO(NSET),
     1                        CCALLEF(LGP(J):LGP(J)+NGP(J)-1,1),NGP(J),
     2                        MTRMS(J),LP,AVG2,CORR2,A,P,NOPP1,MTANDS,
     3                        NVRBL,ND2,IER)
                  NSTAND=NSTAND+NGP(J)
               ENDIF
C
 1975       CONTINUE 
C
            WRITE(KFILEO(NSET), '(1X,I8)') NTERM
C
         ENDIF
C
C            OUTPUT THE STATIONS FROM THE EQUATION FILE.
C         
	 IF (NSET .EQ. 1) THEN
            WRITE(IP(4),198)
 198        FORMAT(/' THE FOLLOWING OUTPUT DEFINES THE STATION LIST(S)')
         ENDIF
C         
	 WRITE(IP(4),199)EQNNAM(NSET)
 199     FORMAT(/' PREDICTANDS FOR EQUATION SET ON FILE ',A60)
         WRITE(IP(4),200)((IDTAND(I,K),I=1,4),K=1,MTANDS)
 200     FORMAT((3(1X,I9.9),1X,I10.3))
	 WRITE(IP(4),201)
 201     FORMAT(/' STATIONS IN THE EQUATION FILE:'/)
C         
	 IF (NALPH .EQ. 1) THEN
	    WRITE(IP(4),220)(ALSTAS(I),I=1,NSTAEF)
 220        FORMAT(14(1X,A8))
         ELSE
	    WRITE(IP(4),220)(CCALLEF(I,1),I=1,NSTAEF)
	 ENDIF
C
C            OUTPUT THE STATIONS AND THEIR RESPECTIVE NAMES.
C         
	 IF (NSET .EQ. 1) THEN
            WRITE(IP(5),230)
 230        FORMAT(/' THE FOLLOWING OUTPUT LISTS THE',
     1              ' STATIONS IN THE EQUATION FILE ALONG',
     2              ' WITH THEIR CORRESPONDING NAMES')
         ENDIF
C         
	 WRITE(IP(5),231)EQNNAM(NSET)
 231     FORMAT(/' PREDICTANDS FOR EQUATION SET ON FILE ',A60) 
         WRITE(IP(5),232) ((IDTAND(I,K),I=1,4),K=1,MTANDS)
 232     FORMAT(/(3(1X,I9.9),1X,I10.3))
C         
	 WRITE(IP(5),233)
 233     FORMAT(/' STATION CALL LETTERS IN THE EQUATION FILE',
     1           ' AND THEIR NAMES') 
C         
	 IF (NALPH .EQ. 1) THEN
            WRITE(IP(5),234)
 234        FORMAT(/' ALPHABETICAL ORDER BY CALL LETTERS')
            WRITE(IP(5),235) (ALSTAS(K), STNMEF(K),K=1,NSTAEF)
 235        FORMAT(' ',A8,5X,A20)
         ELSE
            WRITE(IP(5),235) (CCALLEF(K,1), STNMEF(K),K=1,NSTAEF)
         ENDIF
C 
C            OUTPUT THE STATIONS FROM THE EQUATION FILE BY REGION.
C         
	 IF (NSET .EQ. 1) THEN
            WRITE(IP(6),240)
 240        FORMAT(/' THE FOLLOWING OUTPUT DEFINES THE',
     1              ' STATION LIST(S) DIVIDED BY REGION')
         ENDIF
C         
	 WRITE(IP(6),241) EQNNAM(NSET)
 241     FORMAT(/' PREDICTANDS FOR EQUATION SET ON FILE ',A60)
         WRITE(IP(6),242)((IDTAND(I,K), I=1,4),K=1,MTANDS)
 242     FORMAT(/(3(1X,I9.9),1X,I10.3))
C         
	 WRITE(IP(6),243)
 243     FORMAT(/' STATIONS OUTPUT BY REGION:'/) 
C         
	 K = 1
C
         DO 250  I = 1,KGP
            WRITE(IP(6),245)I
 245        FORMAT(' REGION NO.',I5)
            WRITE(IP(6),247)(ALREGS(M),M=K,K+IRNGP(I)-1)
 247        FORMAT(4X,14(' ',A8))
            K=K+IRNGP(I)
 250     CONTINUE
C
C            OUTPUT THE DUPLICATE STATION FILE.
C         
	 IF (NSET .EQ. 1) THEN
            WRITE(IP(7),255)
 255        FORMAT(/' THE FOLLOWING OUTPUT DEFINES THE',
     1              ' DUPLICATE STATION LIST(S)')
         ENDIF
C
         WRITE(IP(7),256) EQNNAM(NSET)
 256     FORMAT(/' PREDICTANDS FOR EQUATION SET ON FILE ',A60)
         WRITE(IP(7),257)((IDTAND(I,K), I=1,4),K=1,MTANDS)
 257     FORMAT((3(1X,I9.9),1X,I10.3))
	 WRITE(IP(7),258)
 258     FORMAT(/' STATIONS DUPLICATED IN THE EQUATION FILE:'/)
C
	 IF (CDUPS(1) .EQ. ' ') THEN
            WRITE(IP(7),259)
 259        FORMAT('     THERE WERE NO DUPLICATES')
	 ELSE
C              OUTPUTS EACH DUPLICATE AND THE REGION(S)
C              IN WHICH IT WAS FOUND.
C            
	    DO 270 I = 1,IDUPCNT 
               WRITE(IP(7),265)CDUPS(I)
 265           FORMAT(1X,A8,1X,'FOUND IN REGION(S): ',$) 
C               
	       DO 269 J = 1,NSTAD
                  IF (DSTAS(J) .EQ. CDUPS(I)) THEN
                     ISUM = 0
                     K = 0
C
                     DO 267 WHILE (J .GT. ISUM)
                        K = K + 1
                        ISUM = ISUM + DNGP(K)
 267                 CONTINUE                       
C
                     WRITE(IP(7),268)K
 268                 FORMAT(I5,$)
                  ENDIF   
C
 269           CONTINUE
C               
	       WRITE(IP(7),2690)
 2690          FORMAT(' ')
 270        CONTINUE
C         
	 END IF   
C
C            OUTPUT THE MISSING STATION FILE.
C
C            FIRST FIND AND OUTPUT THE STATIONS THAT WERE FOUND IN
C            THE MASTER STATION LIST BUT NOT IN THE EQUATION FILE.
C         
	 IF (NSET .EQ. 1) THEN
            WRITE(IP(8),275)
 275        FORMAT(/' THE FOLLOWING OUTPUT DEFINES THE',
     1              ' MISSING STATION LIST(S)')
         ENDIF
C
         WRITE(IP(8),276) EQNNAM(NSET)
 276     FORMAT(/' PREDICTANDS FOR EQUATION SET ON FILE ',A60)
C         
	 DO K = 1,MTANDS
            WRITE(IP(8),277) (IDTAND(I,K), I=1,4)
 277        FORMAT(3(1X,I9.9),1X,I10.3)
         ENDDO
C         
	 WRITE(IP(8),278)
 278     FORMAT(/' MISSING STATION LISTS: ')
C         
	 IF (KFILD(1) .EQ. 0) THEN
            WRITE(IP(8),279)
 279        FORMAT('    NO MASTER STATION LIST WAS INPUT')
C
C           IF A MASTER STATION LIST WAS INPUT THEN THIS CODE
C           DETERMINES AND OUTPUTS THE STATIONS IN THE EQUATION FILE
C           WHICH ARE MISSING FROM THE MASTER STATION LIST, AS WELL AS
C           THOSE STATIONS IN THE MASTER STATION LIST WHICH WERE NOT
C           FOUND IN THE EQUATION FILE(S).
C
	 ELSE
            WRITE(IP(8),280)
 280        FORMAT(/' THE STATIONS IN THE MASTER STATION LIST',
     1              ' NOT FOUND IN THE EQUATION FILE ARE: '/)
             IMSCNT = 0
C            
	    DO  294 I = 1,NSTAML
               MISSNG = .TRUE.
C               
	       DO J = 1,NSTAEF
		  IF ((CCALLML(I,1) .EQ. CCALLEF(J,1)) .OR.
     1                (CCALLML(I,1) .EQ. CCALLEF(J,2)) .OR.
     2                (CCALLML(I,1) .EQ. CCALLEF(J,3)) .OR.
     3                (CCALLML(I,1) .EQ. CCALLEF(J,4)) .OR.
     4                (CCALLML(I,1) .EQ. CCALLEF(J,5)) .OR.   
     5                (CCALLML(I,1) .EQ. CCALLEF(J,6))) THEN
                     MISSNG = .FALSE.
                     EXIT
                  END IF
	       ENDDO
C               
	       IF (MISSNG .EQ. .TRUE.) THEN
                  IMSCNT = IMSCNT + 1
                  WRITE(IP(8),290)CCALLML(I,1)
 290              FORMAT(1X,A8,$)
C                    THE $(NN) IN THE FORMAT OVERRIDES THE DEFAULT
C                    LINE FEED.
                  IF (MOD(IMSCNT,14) .EQ. 0) WRITE(IP(8),291)
C                    THIS LINE FEEDS WHEN 14 VALUES HAVE BEEN
C                    WRITTEN.
 291              FORMAT(/)
               END IF
C
 294        CONTINUE
C            
	    IF (IMSCNT .EQ. 0)THEN
	       WRITE(IP(8),295)
 295           FORMAT('    THERE WERE NO MISSING STATIONS')
            ELSE
               IF(MOD(IMSCNT,14).NE.0)WRITE(IP(8),2690)
C                 THERE NEEDS TO BE A LINE FEED UNLESS THERE
C                 HAS JUST BEEN ONE.
            ENDIF
C            
            IMSCNT = 0
            WRITE(IP(8),297)
 297        FORMAT(/' THE STATIONS IN THE EQUATION FILE',
     1              ' NOT FOUND IN THE MASTER STATION LIST ARE: '/)
C            
	    DO 2985 I = 1,NSTAEF
               MISSNG = .TRUE.
C               
	       DO J = 1,NSTAML
                  IF ((CCALLEF(I,1) .EQ. CCALLML(J,1)) .OR.
     1                (CCALLEF(I,1) .EQ. CCALLML(J,2)) .OR.
     2                (CCALLEF(I,1) .EQ. CCALLML(J,3)) .OR.
     3                (CCALLEF(I,1) .EQ. CCALLML(J,4)) .OR. 
     4                (CCALLEF(I,1) .EQ. CCALLML(J,5)) .OR.
     5                (CCALLEF(I,1) .EQ. CCALLML(J,6))) THEN
                     MISSNG = .FALSE.
                     EXIT
                  END IF
C
               ENDDO
C               
	       IF (MISSNG .EQ. .TRUE.) THEN
                  IMSCNT = IMSCNT + 1
                  WRITE(IP(8),298)CCALLEF(I,1)
 298              FORMAT(1X,A8,$)
                  IF (MOD(IMSCNT,14) .EQ. 0) WRITE(IP(8),291)
               END IF
C            
 2985       CONTINUE
C            
	    IF (IMSCNT .EQ. 0) 
     1         WRITE(IP(8),299)
 299           FORMAT('    THERE WERE NO MISSING STATIONS')
         ENDIF
C
C            OUTPUT EACH GROUP OF STATIONS AND PREDICTAND
C            FOR WHICH THERE IS NO EQUATION.
C         
	 IF (NSET .EQ. 1) THEN
            WRITE(IP(9),305)
 305        FORMAT(/' THE FOLLOWING OUTPUT DEFINES THE',
     1              ' STATIONS AND PREDICTANDS FOR WHICH',
     2              ' THERE ARE NO EQUATIONS')
         ENDIF
C         
	 WRITE(IP(9),306) EQNNAM(NSET)
 306     FORMAT(/' PREDICTANDS FOR EQUATION SET ON FILE ',A60)
C         
            WRITE(IP(9),307)((IDTAND(I,K),I=1,4),K=1,MTANDS)
 307        FORMAT(3(1X,I9.9),1X,I10.3)
C         
	 WRITE(IP(9),309)
 309     FORMAT(/' STATIONS IN EQUATION FILE WITH NO',
     1           ' EQUATIONS FOR SPECIFIC PREDICTANDS:'/)
C         
	 DONE = .FALSE.
C
C           EXECUTED FOR EACH REGION IN THE FILE.
C         
	 DO 324 I = 1,KGP
            FOUND = .FALSE.
C            
	    DO 323 J = 1,MTANDS
C               
	       IF (NINT(AVG(I,J)*1000.) .EQ. INOAVG) THEN
C                       THE 1000 MULTIPLIER AND NINT FUNCTION	  
C                       MAKE IT HIGHLY UNLIKELY A NON-LEGITIMATE
C                       MATCH WILL OCCUR.     
                  DONE = .TRUE. 
C
C                    OUTPUT THE STATIONS FOR THIS EQUATION.
C                  
		  IF (FOUND .EQ. .FALSE.) THEN
C
		     DO K = 1,NGP(I)
                        WRITE(IP(9),320)CCALLEF(I,1)
 320                    FORMAT(1X,A8,$)
C                          THE $(NN) IN THE FORMAT OVERRIDES THE DEFAULT
C                          LINE FEED.
                        IF (MOD(K,14) .EQ. 0) WRITE(IP(9),321)
C                          THIS LINE FEEDS WHEN 14 VALUES HAVE BEEN
C                          WRITTEN.
 321                    FORMAT(/)
                     ENDDO
C                     
		     IF(MOD(K,14).NE.0)WRITE(IP(9),321)
C                        LINE FEED UNLESS ONE HAS JUST BEEN MADE.		     
                     FOUND = .TRUE.
                  ENDIF 
C                  
		  WRITE(IP(9),322) (IDTAND(K,J), K=1,4)
 322              FORMAT((3(1X,I9.9),1X,I10.3))
               ENDIF
C            
 323        CONTINUE
C            
 324     CONTINUE
C         
	 IF (DONE .EQ. .FALSE.) 
     1      WRITE(IP(9),325)
 325        FORMAT('    NONE WERE FOUND')
C
         IF(KFILCP.NE.0)THEN
C
C              SUBROUTINE ALIST BUILDS THE LIST OF UNIQUE PREDICTORS
C              IN ID( , ) FROM THE INPUT IDEQN( , , ).  NPRED IS THE
C              NUMBER OF ENTRIES IN ID( , ) AND IS UPDATED BY ALIST.
C              PRINT IS PROVIDED WHEN NSET = NSETS.
C
            CALL ALIST(KFILDO,KFILCP,IP(15),IDEQN,ID,IDPARS,TRESHL,JD,
     1                 KGP,MTRMS,ITAU,
     2                 ND2,ND4,ND13,NPRED,NSET,NSETS,IER)
         ENDIF
C
C        WRITE INFORMATION ON IP(11) REGARDING INPUT EQUATION FILES.
C        WRITING TOTAL NUMBER OF EQUATIONS, TOTAL NUMBER OF STATIONS
C        (INCLUDING DUPLICATES), AND INPUT EQUATION FILENAME.
C
         IF(IP(11).NE.0)THEN
            IF(NSET.EQ.1)WRITE(IP(11),3000)
 3000       FORMAT(/' INPUT EQUATION FILE INFORMATION.'/) 
            WRITE(IP(11),3001)NSTAD,KGP,NSSEI,EQNNAM(NSET)
 3001       FORMAT(I5,1X,I5,1X,I5,1X,A60)
         ENDIF
C
C        WRITE INFORMATION ON IP(12) REGARDING OUTPUT (MODIFIED)
C        EQUATION FILES. WRITING TOTAL NUMBER OF EQUATIONS, 
C        TOTAL NUMBER OF STATIONS (NO DUPLICATES), AND
C        OUTPUT EQUATION FILENAME.
C
         IF(IP(12).NE.0)THEN
            IF(NSET.EQ.1)WRITE(IP(12),3005)
 3005       FORMAT(/' OUTPUT EQUATION FILE INFORMATION.'/) 
            WRITE(IP(12),3001)NSTAND,KGP,NSSEO,EQNNAMO(NSET)
         ENDIF 
C
      END DO EQUNFILE     
C 
C        FIND THE LIST OF UNIQUE PREDICTORS IN ALL NSETS
C        FILES.
C
      IF(KFILCP.NE.0)THEN
         REWIND(KFILCP)
         WRITE(IP(15),326)
 326     FORMAT(/' THE FOLLOWING OUTPUT DEFINES THE LIST',
     1        ' OF UNIQUE PREDICTORS')   
C
C           AT THIS POINT, ID(J,N) (J=1,4) (N=1,NPRED) HOLDS THE 
C           UNIQUE PREDICTOR LIST.  CALL MATCHP TO READ A LIST OF
C           U201 VARIABLES, WRITE THE LIST, AND OUTPUT TO IP10
C           THE UNIQUE VARIABLES THAT ARE NOT IN THE U201 LIST.
C
         CALL MATCHP(KFILDO,IP(10),KFILM,
     1               ID,IDPARS,TRESHL,JD,ND4,NPRED,IER)
      ENDIF
C
      RETURN
C
      END
      
