import os, sys, numpy as np
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged
from sphere_metrics import *
from scipy.spatial import ConvexHull
a=np.load(REPO+'/genomes-edged/mono-e2.npy')
X=edged.body(a,3,4,6)['X']; B=Body(X,6)
Bd=edged.body(a,3,4,6); vol0,Gh,I0,_=hull_mass(Bd['X']); w,R=np.linalg.eigh(I0); R[:,2]*=np.linalg.det(R)
g7=edged.grid(4,7); A=a.reshape(3,g7.nb); sc=g7.scale
F_=lambda U: (edged.Ybasis(4,U)*sc)@A.T
r7=np.exp(F_(g7.N).min(1)); Vq=(r7**3*g7.w).sum()/3; Gq=((r7**4*g7.w)[:,None]*g7.N).sum(0)/(4*Vq)
from scipy.optimize import minimize
def pt(u): u=u/np.linalg.norm(u); return ((np.exp(F_(u[None]).min())*u-Gq)*Bd['s']-Gh)@R
u0=g7.N[np.argmin(np.linalg.norm(((r7[:,None]*g7.N-Gq)*Bd['s']-Gh),axis=1))]
o=minimize(lambda u: np.linalg.norm(pt(u)),u0,method='Nelder-Mead',options=dict(xatol=1e-10,fatol=1e-12,maxiter=4000))
p=pt(o.x); B.rest=p/np.linalg.norm(p); print('exact rest height',np.linalg.norm(p))
Y=B.P@B.to_upright()                     # mm at 90, COM origin, rest straight down (-Y)
vol,G,I,H=hull_mass(Y); Y=Y-G            # re-centre exactly (tiny)
H=ConvexHull(Y); F=H.simplices.copy(); c=Y[F].mean(1)
nrm=np.cross(Y[F[:,1]]-Y[F[:,0]],Y[F[:,2]]-Y[F[:,0]]); fl=(nrm*c).sum(1)<0; F[fl]=F[fl][:,[0,2,1]]
used=np.unique(F); remap=-np.ones(len(Y),int); remap[used]=np.arange(len(used)); V=Y[used]/10; F=remap[F]
lowest=V[np.argmin(V[:,1])]; print('lowest point (cm)',lowest, 'COM offset check', hull_mass(V*10)[1])
with open('out/mono-e2.obj','w') as f:
    f.write('# mono-e2: edged (1,1) body, genome genomes-edged/mono-e2.npy, edged.body(a, K=3, L=4, level=6)\n')
    f.write('# convex hull of 41,817 surface + crease samples; 9 cm diameter (largest width), in cm; centre of mass at the origin;\n')
    f.write('# upright = +Y (resting point straight down); X = least-inertia axis projected horizontal\n')
    f.write(f'# volume {vol/1000:.3f} cm^3; rest height {-V[:,1].min():.4f} cm; {len(V)} vertices, {len(F)} faces\n')
    for v in V: f.write(f'v {v[0]:.6f} {v[1]:.6f} {v[2]:.6f}\n')
    for t in F+1: f.write(f'f {t[0]} {t[1]} {t[2]}\n')
np.save('out/mono-e2.npy',a)
print(len(V),len(F), np.ptp(V,0))
