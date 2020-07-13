#!/bin/sh
# ======================================================================== 
# Script: make-u600-id-list.sh
#
# Usage: make-u600-id-list.sh TAND BASEDD TAU OTHERTAU OUTPUT
#
# Arguments:
#
# TAND = wind - 10-m u, v, and speed
#        prob - gust event (NO=0, YES=1)
#        gust - gust speed (Missing=9999)
#
# BASEDD = model base DD (e.x. gfs = 08).
#
# TAU = 3-digit forecast projectio (with padded zeros) with "p" or "s"
#       appended. Ex. 006p or 006s
#
# MULTITAU = 0/1 to use other TAUS found in tau2isg (3rd column).
#
# OUTPUT = output filename. This is optional. TEMPFILE is retained.
# ======================================================================== 
set -x

if [ $# -lt 4 ]; then
   exit 1
fi

TAND=$1
BASEDD=$2
TAU=$3
MULTITAU=$4
OUTPUT=$5

TEMPFILE=temp.$$

# ======================================================================== 
# Template files to work from.
# ======================================================================== 
PREDTEMP=ids/u600_pred_TEMPLATE
TANDTEMP=ids/u600_${TAND}_tand_TEMPLATE
HARMTEMP=ids/u600_harmonic_TEMPLATE

# ======================================================================== 
# Set PS
# ======================================================================== 
PS=${TAU: -1}
if [ "$PS" != "p" -a "$PS" != "s" ]; then exit 1; fi

# ======================================================================== 
# Build U600 id list.
# ======================================================================== 

# Model Predictors
if [ $MULTITAU -eq 1 ]; then
   MORETAUS=$(grep '^'"${TAU:0:3}" ../fix/tau2isg | cut -d":" -f 3)
fi
for TAU1 in $TAU $MORETAUS
do

   if [ -f ../fix/tau2isg ]; then
      ISG=$(grep '^'"${TAU1:0:3}" ../fix/tau2isg | cut -d":" -f 2)
   else
      exit 1
   fi

   sed -e "s/DD/${BASEDD}/g" \
       -e "s/XXX/${TAU1:0:3}/g" \
       -e "s/ISG/${ISG}/g" $PREDTEMP >> $TEMPFILE
done

# Insert Harmonic Predictors
if [ ${TAU:0:3} -ge 192 ]; then
   cat u600_harmonic_TEMPLATE >> $TEMPFILE
fi

# Insert predictands as predictors
YYYval="  1"
if [ "$PS" == "p" -a ${TAU:0:3} -le 15 ]; then

   if [ $BASEDD -eq 7 ]; then
      OBSTAU=$(printf "%.3d" 1)
   else
      OBSTAU=$(printf "%.3d" 3)
   fi

   if [ "$TAND" == "gust" ];then
      OBSPREDTEMP=ids/u600_gust_obspred_TEMPLATE
   else
      OBSPREDTEMP=$TANDTEMP
   fi
   sed -e "s/XXX/${OBSTAU}/g" \
       -e "s/Z/1/g" \
       -e "s/YYY/${YYYval}/g" $OBSPREDTEMP >> $TEMPFILE
fi

# Insert Predictand IDs
unset YYYval
if [ "$TAND" == "prob" ]; then
   YYYval=" 50"
else
   YYYval="  1"
fi

sed -e "s/XXX/${TAU:0:3}/g" \
    -e "s/Z/2/g" \
    -e "s/YYY/${YYYval}/g" $TANDTEMP >> $TEMPFILE

# Insert terminator
echo "   999999" >> $TEMPFILE

# If OUTPUT is set, then copy TEMPFILE to OUTPUT
# and remove TEMPFILE.
if [ ! -z $OUTPUT ]; then
   cp $TEMPFILE $OUTPUT
   rm -f $TEMPFILE
fi
