#!/bin/sh
#set -x

CYC=12
ELEMENT=wind
MODEL=nam
SEASON=wm
TAUS=$(seq --format="%03gp" 6 3 84 && seq --format="%03gs" 6 3 15)
YYMMDD=$(date +"%y%m%d")

. ../dev.env

if [[ $SEASON == "cl" ]]; then
  SDATE=10010331
elif [[ $SEASON == "wm" ]]; then
  SDATE=04010930
fi

FINALDIR=/mdlstat/save/usr/$USER/u600/${MODEL}${CYC}z/$SDATE
mkdir -p $FINALDIR

cd $DEVOUTDIR/u600/final

for TAU in $TAUS
do

   cp -v u600.${MODEL}${CYC}.${ELEMENT}.$SEASON.f${TAU} $FINALDIR/${ELEMENT}${TAU}.EQ.$YYMMDD

done
