#!/bin/sh
set -x

SG='sgroup2'

TAUS=$(seq 6 3 240)
for tau in $TAUS
do

   tau1=$(printf "%.3d" $tau)

   #  Insert forecast projection for forecast IDs
   #sed -e "s/XXX/${tau1}/g" \
   #    -e "s/YYY/${ISG}/g" ids_fcst_${SG}.TMPL >>tempA
   sed -e "s/XXX/${tau1}/g" ids_fcst_${SG}.TMPL >>tempA
   #  Insert forecast projection for observation IDs
   #sed -e "s/XXX/${tau1}/g" \
   #    -e "s/YYY/${ISG}/g" ids_wsob_${SG}.TMPL >>tempB
   sed -e "s/XXX/${tau1}/g" ids_wsob_${SG}.TMPL >>tempB
#
done 
#
echo "   999999" >> tempA
#
echo "   999999" >> tempB
echo "   999999" >> tempB
echo "999999   " >> tempB
#
cat header_${SG} tempA tempB > ${SG}_wspd.ids
#cat header_${SG} tempA tempB > ${SG}_wdir.ids
rm -f temp*
