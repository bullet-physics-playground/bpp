import numpy as np, re, sys
from scipy.spatial import ConvexHull
from collections import defaultdict
def basins(P, thresh=1e-3):
    """Resting basins of hull(P) (COM at origin): persistence of minima of face height over the
    face-adjacency graph, saddle = COM distance to the shared edge. Returns [(depth, normal, height)]"""
    H=ConvexHull(P)
    h=-H.equations[:,3]; n=H.equations[:,:3]
    edges={}
    for f,s in enumerate(H.simplices):
        for a,b in ((s[0],s[1]),(s[1],s[2]),(s[2],s[0])):
            k=(min(a,b),max(a,b)); edges.setdefault(k,[]).append(f)
    E=[]
    for (a,b),fs in edges.items():
        if len(fs)!=2: continue
        A,B=P[a],P[b]; ab=B-A; t=-(A@ab)/(ab@ab); c=A+t*ab; d=np.linalg.norm(c); u=c/d
        n1,n2=n[fs[0]],n[fs[1]]
        ang=lambda x,y: np.arccos(np.clip(x@y,-1,1))
        if ang(n1,u)+ang(u,n2) <= ang(n1,n2)+1e-9:      # rolling over this edge passes over its top
            tc=np.clip(t,0,1); d=np.linalg.norm(A+tc*ab)
            w=max(d,h[fs[0]],h[fs[1]])
        else:
            w=max(h[fs[0]],h[fs[1]])
        E.append((w,fs[0],fs[1]))
    E.sort()
    parent=list(range(len(h))); mn=list(range(len(h)))
    def find(i):
        while parent[i]!=i: parent[i]=parent[parent[i]]; i=parent[i]
        return i
    out=[]
    for w,f1,f2 in E:
        r1,r2=find(f1),find(f2)
        if r1==r2: continue
        m1,m2=mn[r1],mn[r2]
        lo,hi=(m1,m2) if h[m1]<=h[m2] else (m2,m1)
        if w-h[hi]>thresh: out.append((w-h[hi],n[hi],h[hi]))
        parent[r2]=r1; mn[r1]=lo
    g=min(range(len(h)),key=lambda i:h[i])
    out.append((np.inf,n[g],h[g]))
    return sorted(out,key=lambda x:-x[0])
def loadpts(fn):
    s=open(fn).read(); s=s[s.index("points = {"):]
    return np.array(list(map(float,re.findall(r"-?\d+\.\d+",s)))).reshape(-1,3)
if __name__=="__main__":
    for fn in sys.argv[1:]:
        P=loadpts(fn)
        B=basins(P,thresh=1e-3)  # 10 µm
        print(fn, len(B),"basins deeper than 10 µm")
        main=B[0][1]
        for d,nv,hh in B[:6]:
            print(f"   depth {d*1e4 if np.isfinite(d) else float('inf'):9.1f} µm  rest height {hh:.3f} cm  {np.degrees(np.arccos(np.clip(nv@main,-1,1))):6.1f}° from main  normal {np.round(nv,3)}")
