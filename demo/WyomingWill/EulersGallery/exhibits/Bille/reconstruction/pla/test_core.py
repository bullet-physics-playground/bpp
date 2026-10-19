import numpy as np, sys
from core import *
# box 2x3x4 at offset
P=np.array([[x,y,z] for x in (1,3) for y in (0,3) for z in (2,6)],float)
v,m1,S=convex_props(P); c=m1/v
Sc=S-v*np.outer(c,c)
print(v, c, np.diag(Sc), "expect 24, (2,1.5,4), V*(4,9,16)/12=",24*np.array([4,9,16])/12)
# void inside box: box minus inner box via halfspaces
fs,_=faces_of(P); print(len(fs),"faces")
mp=mass_props(P,fs,0.5,2.5)
# expected: void = [1.5,2.5]x[0.5,2.5]x[2.5,5.5] vol=1*2*3=6
print(mp['void_vol'], mp['vol'], mp['com'])
# compare with p26 in eq.py
sys.path.insert(0,'../../../Gomboc/variety-reconstruction')
import eq
txt=open('../../bille-meshes/p26.lua').read()
import re
blk=txt.split('vertices = {')[1].split('}')[0]
V=np.array([float(x) for x in re.findall(r'-?\d+\.\d+',blk)]).reshape(-1,3)
c=np.zeros(3)
st,un,_=eq.equilibria(V,c); print("eq.py",len(st),len(un))
fs,_=faces_of(V); st2,un2=equilibria(V,fs,c); print("core",len(st2),len(un2), len(fs))
for cc in [np.array([0.3,0.1,0.5]), np.array([0,0,1.0]),np.array([0.2,-.3,2.0])]:
    st,un,_=eq.equilibria(V,cc); st2,un2=equilibria(V,fs,cc); print(len(st),len(un),len(st2),len(un2))
sm=summary_margin(V,fs,c,[i for i,f in enumerate(fs) if f[0][2]<-0.999][0],0); print(sm['face']*10,sm['vert']*10)
