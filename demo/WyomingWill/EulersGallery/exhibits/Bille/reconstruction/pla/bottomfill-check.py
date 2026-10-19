import numpy as np, sys
from scipy.spatial import ConvexHull, Delaunay
import os; M=os.path.join(os.path.dirname(os.path.abspath(__file__)),'../../bille-meshes/')
rng=np.random.default_rng(1)
def load(n):
    V=np.array([list(map(float,l.split()[1:4])) for l in open(M+n) if l.startswith('v ')])
    V=np.unique(V.round(6),axis=0); return V
def planes(V):
    h=ConvexHull(V); P={}
    for s,eq in zip(h.simplices,h.equations):
        k=tuple(np.round(eq,5)); P.setdefault(k,[]).append(V[s])
    return h,P
def stable(P,c):
    out=[]
    for k,tris in P.items():
        n=np.array(k[:3]); d=k[3]; f=c-(n@c+d)*n
        for a,b,cc in tris:
            # barycentric
            v0,v1,v2=b-a,cc-a,f-a; d00,d01,d11=v0@v0,v0@v1,v1@v1; d20,d21=v2@v0,v2@v1
            den=d00*d11-d01*d01; v=(d11*d20-d01*d21)/den; w=(d00*d21-d01*d20)/den
            if v>=-1e-9 and w>=-1e-9 and v+w<=1+1e-9: out.append((k,-(n@c+d))); break
    return out
def com(V,h,base_n,base_d,fillh,t,N=400000):
    # base plane: n.x+d=0 outward normal base_n; height above base = -(n.x+d)
    lo,hi=V.min(0),V.max(0); X=rng.uniform(lo,hi,(N,3)); dl=Delaunay(V); X=X[dl.find_simplex(X)>=0]
    ht=-(X@base_n+base_d); vol=np.prod(hi-lo)*len(X)/N
    inside=ht<fillh
    # shell: points within t of surface (distance to hull planes)
    dist=np.min(-(X@h.equations[:,:3].T+h.equations[:,3]),axis=1)
    m=inside|(dist<t)
    return X[m].mean(0), vol*m.mean()
for name in ['p37.obj','p26.obj','p21.obj']:
    V=load(name); h,P=planes(V)
    c0=V.mean(0)
    # base = plane with most negative z normal (body frame z up)
    kb=min(P,key=lambda k:k[2]); bn=np.array(kb[:3]); bd=kb[3]
    H=max(-(V@bn+bd))
    print(name,'height %.2f cm'%H, 'faces',len(P))
    for t in [0.08,0.12]:
      for f in [0,0.1,0.2,0.3,0.4]:
        c,vol=com(V,h,bn,bd,f*H,t)
        s=stable(P,c)
        print('  wall %.1f mm, solid bottom %2d%%: stable faces %d %s, mass %.0f g'%(t*10,f*100,len(s),'BASE ONLY' if len(s)==1 and s[0][0]==kb else '',vol*1.24))
    # uniform solid
    c,vol=com(V,h,bn,bd,10*H,0); s=stable(P,c); print('  uniform solid: stable faces',len(s),'mass %.0f g'%(vol*1.24))
