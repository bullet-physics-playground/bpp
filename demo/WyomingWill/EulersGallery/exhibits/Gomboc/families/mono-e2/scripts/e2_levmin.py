import os, sys, numpy as np
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged
from sphere_metrics import *
a=np.load(REPO+'/genomes-edged/mono-e2.npy')
for lev in (6,7):
  B=Body(edged.body(a,3,4,lev)['X'],7); t=B.tilt(); L=0.4*B.lever
  pm=persist(L,B.E)
  print('level',lev)
  for d,v in pm[:8]: print(f'  lever min {L[v]*1000:.1f} um at 36, tilt {t[v]:.1f}, h {B.h[v]:.3f}, basin depth {min(d,9)*1000:.0f} um')
