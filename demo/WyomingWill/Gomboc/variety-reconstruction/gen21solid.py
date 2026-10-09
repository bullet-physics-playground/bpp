"""21-vertex mono-monostatic polyhedron, drawn as a closed solid.
Physics = the paper's idealisation: equal masses at the 21 corners, weightless skin."""
import numpy as np
from scipy.spatial import ConvexHull
from collections import defaultdict
from opt21 import verts, margins
from eq import equilibria
p=np.load("nk_4_5.npy"); V0=verts(p)   # fitted by optnk.py (the earlier best21.npy: 0.6 mm)
SIZE=9.0; s=SIZE/np.ptp(V0,axis=0).max(); V=V0*s
M_CORNER=0.0052; M=21*M_CORNER
com=V.mean(0); Vc=V-com
st,un,_=equilibria(Vc,np.zeros(3)); assert len(st)==1 and len(un)==1
S=M_CORNER*Vc.T@Vc; I=np.trace(S)*np.eye(3)-S; K2=np.diag(I)/M
H=ConvexHull(Vc); faces=defaultdict(set)
for simp,e in zip(H.simplices,H.equations): faces[tuple(np.round(e,7))].update(simp)
vs=[]; fs=[]
for key,idx in faces.items():
    n=np.array(key[:3]); P=Vc[list(idx)]; c=P.mean(0)
    u=np.cross(n,[1,0,0]); u=u if np.linalg.norm(u)>1e-6 else np.cross(n,[0,1,0]); u/=np.linalg.norm(u); w=np.cross(n,u)
    ang=np.arctan2((P-c)@w,(P-c)@u); P=P[np.argsort(ang)]
    o=len(vs); vs+=list(P)
    for k in range(1,len(P)-1):
        a,b,cc=o,o+k,o+k+1
        if np.cross(P[k]-P[0],P[k+1]-P[0])@n<0: b,cc=cc,b
        fs.append((a,b,cc))
import opt21s; mm=opt21s.margins_c(V,V.mean(0)); m={'face':min(mm.values())/s,'vert':min(mm.values())/s}
with open("out/p21.obj","w") as f:
    f.write("# 21-vertex mono-monostatic polyhedron, closed faces (flat), cm, COM at origin\n")
    for v in vs: f.write("v %.5f %.5f %.5f\n"%tuple(v))
    for t in fs: f.write("f %d %d %d\n"%(t[0]+1,t[1]+1,t[2]+1))
restH=-(Vc[:,2].min()); top=Vc[0]
with open("out/p21.lua","w") as f:
    f.write("""-- A 21-vertex polyhedron with one stable and one unstable equilibrium,
-- after Domokos & Kovacs, "Conway's spiral and a discrete Gomboc with 21 point
-- masses" (Amer. Math. Monthly 130, 2023; arXiv:2103.13727): a Conway (4,5)-spiral
-- -- one apex and four horizontal regular pentagons, 21 faces -- with equal
-- masses at its 21 corners. RECONSTRUCTED: the paper gives the spiral's angles
-- but not the vertices, and its listed centre-of-mass height does not follow
-- from them, so the ring radii and heights were re-fitted (close to the paper's
-- spiral) to make the margins as large as possible: every other face tips the
-- body by at least %.2f mm, every other vertex by at least %.2f mm (at 9 cm).
-- Drawn as a closed polyhedron, but the physics is the paper's idealisation:
-- ALL the mass in the 21 corners (%.1f g each), a weightless skin. Building a
-- real one is much harder than the drawing suggests: with a 0.3 mm plastic
-- skin and 5-10 g weights centred 2 mm inside the corners, even the best
-- re-fitted shape has extra resting faces; 20 g a corner (420 g in all) just
-- scrapes by, 0.05 mm to spare (variety-reconstruction/opt21s.py, try_s.py).
-- Stable: the bottom pentagon. Unstable: the apex.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass.
return {
  size = %.2f, mass = %.6f, margin = 0.04,
  inertia = { %.6f, %.6f, %.6f },   -- squared radii of gyration, cm^2
  down = { 0, 0, -1 }, top = { %.6f, %.6f, %.6f },
  restHeight = %.5f, topHeight = %.5f,
  vertices = {
"""%(m['face']*s*10,m['vert']*s*10,M_CORNER*1e3,SIZE,M,*K2,*top,restH,np.linalg.norm(Vc,axis=1).max()))
    for v in Vc: f.write("    %.5f,%.5f,%.5f,\n"%tuple(v))
    f.write("  },\n}\n")
print("faces",len(faces),"tris",len(fs),"mass %.1f g"%(M*1e3),"K2",np.round(K2,3),"restH",round(restH,3))
