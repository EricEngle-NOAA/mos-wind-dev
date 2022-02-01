#!/usr/bin/env python3

import os
import sys

if len(sys.argv) != 4:
    print("Usage:",os.path.basename(sys.argv[0]),"<ALL DEV SITES FILE> <METAR FILE> <MARINE FILE>")
    exit(1)

listfile = sys.argv[1]
metarfile = sys.argv[2]
marinefile = sys.argv[3]

with open(listfile) as f:
    stations = f.readlines()

fmetar = open(metarfile,mode='wt')
fmarine = open(marinefile,mode='wt')

for s in stations:
    s1 = s.rstrip('\n')
    if s1 == '99999999': continue
    if len(s1) == 4 and s1[0].isalpha():
        fmetar.write(s1+'\n')
    else:
        fmarine.write(s1+'\n')

fmetar.write('99999999\n99999999')
fmarine.write('99999999\n99999999')
fmetar.close()
fmarine.close()
