#!/bin/sh
set -x

# ======================================================================== 
# Set variables
# ======================================================================== 
CYCS="00 06 12 18"
ELEMENT="gust prob"
MODEL="gfs"
SEASON="cl wm"

# ======================================================================== 
# Define the beginning and end dates in MMDD format
# ======================================================================== 
if [[ $SEASON == "cl" ]]; then
   sb="1001"
   se="0331"
elif [[ $SEASON == "wm" ]]; then
   sb="0401"
   se="0930"
fi

# ======================================================================== 
# Build a list of projections
# ======================================================================== 
TAUS=$(seq --format="%03g" 6 3 240)

for CYC in $CYCS
do

   if [ $CYC -eq 00 -o $CYC -eq 12 ]; then
   TAUS=$(../ush/make-taus.sh 6,3,192,p 198,6,264,p 6,3,15,s)
   elif [ $CYC -eq 06 -o $CYC -eq 18 ]; then
   TAUS=$(../ush/make-taus.sh 6,3,84,p 6,3,15,s)
   fi


   # Define variables
   cycle="t${CYC}z"
   short=mdl_${MODEL}mn${ELEMENT}.$sb$se.$cycle
   ext=mdl_${MODEL}xmn${ELEMENT}.$sb$se.$cycle

   # Loop through projections
   for TAU in $TAUS
   do
      # Strip off the 1st line of each equation file and
      # and insert a specfic string for operations
      header=" ${CYC}00 UTC ${sb} ${se}"
      #eqnfile=/mdlstat/noscrub/usr/Eric.Engle/ecmmos_meso_wind_2015/u600/final/u600.${MODEL}${CYC}.${ELEMENT}.${SEASON}.f${TAU}
      eqnfile=/mdlstat/noscrub/usr/Eric.Engle/u600/gfs${cyc}z/$sb$se/
      if [ $TAU -le 84 ]; then
        sed "1s/.*/$header/" $eqnfile >> $short
      else
        sed "1s/.*/$header/" $eqnfile >> $ext
      fi
      
      ## Just secondary equations
      #if [ $TAU -le 15 ]; then
      #   #eqnfile=/mdlstat/noscrub/usr/efe/u600/mrgd/${CYC}z/gfs${CYC}.f${TAU}s
      #   eqnfile=/mdlstat/noscrub/usr/Wei.Yan/oscig/u600/nmm$CYC/cl/nmm${TAU}s.eqn.110813
      #   sed "1s/.*/$header/" $eqnfile >> $short
      #fi

      # Break at 84 for 06Z and 18Z
      if [ $CYC -eq 6 -o $CYC -eq 18 ]; then
         if [ $TAU -eq 84 ]; then
            break
         fi
      fi

   done

done
