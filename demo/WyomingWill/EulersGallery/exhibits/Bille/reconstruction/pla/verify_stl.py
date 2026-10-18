# Independent check of ppla37 straight from the print file (not using core.py):
# mass and centre of mass from the STL (signed tetrahedra; the void is the inner,
# inward-facing shell), then which outer-hull faces have the COM foot inside.
# usage: python3 verify_stl.py ../../print/ppla37.stl
import numpy as np, sys, re
from scipy.spatial import ConvexHull
tri=[]; cur=[]
for line in open(sys.argv[1]):
    m=re.match(r'\s*vertex\s+(\S+)\s+(\S+)\s+(\S+)',line)
    if m:
        cur.append([float(x) for x in m.groups()])
        if len(cur)==3: tri.append(cur); cur=[]
T=np.array(tri)  # mm
v=np.einsum('ij,ij->i',T[:,0],np.cross(T[:,1],T[:,2]))/6
V=v.sum(); c=(v[:,None]*(T.sum(1)/4)).sum(0)/V
print("STL volume cm3 %.4f mass g %.3f COM mm %s"%(V/1e3, V/1e3*1.24, c))
P=T.reshape(-1,3); P=np.unique(P.round(6),axis=0)
h=ConvexHull(P)
# merge coplanar facets
eqs={}
for e in h.equations:
    k=tuple(np.round(e,6)); eqs[k]=e
print("hull facets(merged)",len(eqs))
stable=[]; margins=[]
for e in eqs.values():
    n=e[:3]; d=e[3]
    foot=c-(n@c+d)*n
    # distance of foot to polygon boundary: polygon = hull points on this plane
    on=P[np.abs(P@n+d)<1e-6]
    # 2D projection
    u=np.cross(n,[1,0,0] if abs(n[0])<.9 else [0,1,0]); u/=np.linalg.norm(u); w=np.cross(n,u)
    q=np.c_[on@u,on@w]; f=np.array([foot@u,foot@w])
    hh=ConvexHull(q); dist=min(-(eq[:2]@f+eq[2]) for eq in hh.equations)  # >0 inside
    margins.append((dist,n[2]))
margins.sort(reverse=True)
print("faces with foot inside:",sum(1 for m in margins if m[0]>0))
for m in margins[:3]: print("  signed distance foot-in mm %.3f  n_z %.4f"%m)
