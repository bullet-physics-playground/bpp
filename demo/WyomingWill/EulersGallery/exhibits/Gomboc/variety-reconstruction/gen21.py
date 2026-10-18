"""21-vertex mono-monostatic 0-skeleton (after Domokos & Kovacs 2023, Conway (4,5)-spiral):
equal tungsten balls at 21 vertices, thin carbon rods along the 40 edges."""
import numpy as np, itertools
from scipy.spatial import ConvexHull
from opt21 import verts, margins
from eq import equilibria
p=np.load("best21.npy"); V0=verts(p)
SIZE=9.0                       # cm, longest extent (height)
s=SIZE/np.ptp(V0,axis=0).max()
BALL_R=0.4; RHO_W=19.3e-3      # cm, kg/cm^3
ROD_R=0.05; RHO_CF=1.36e-3*1.1 # 1 mm carbon rod
mball=4/3*np.pi*BALL_R**3*RHO_W
V=V0*s
H=ConvexHull(V)
# edges = boundary edges of merged coplanar faces
from collections import defaultdict
faces=defaultdict(list)
for simp,e in zip(H.simplices,H.equations): faces[tuple(np.round(e,7))].append(simp)
E=set()
for k,tris in faces.items():
    cnt=defaultdict(int)
    for t in tris:
        for a,b in ((t[0],t[1]),(t[1],t[2]),(t[2],t[0])): cnt[tuple(sorted((a,b)))]+=1
    E|={e for e,c in cnt.items() if c==1}
E=sorted(E); print("faces",len(faces),"edges",len(E))
# mass properties: balls + rods
M=0; mom=np.zeros(3); II=np.zeros((3,3))
for v in V: M+=mball; mom+=mball*v; II+=mball*np.outer(v,v)
lam=np.pi*ROD_R**2*RHO_CF; Lsum=0
for a,b in E:
    A,B=V[a],V[b]; L=np.linalg.norm(B-A); m=lam*L; mid=(A+B)/2; d=B-A; Lsum+=L
    M+=m; mom+=m*mid; II+=m*(np.outer(mid,mid)+np.outer(d,d)/12)
com=mom/M
S=II-M*np.outer(com,com); I=np.trace(S)*np.eye(3)-S
I+=np.eye(3)*len(V)*0.4*mball*BALL_R**2
print("mass %.1f g (balls %.1f g, rods %.2f g over %.0f cm)"%(M*1e3,len(V)*mball*1e3,lam*Lsum*1e3,Lsum))
print("COM shift from vertex centroid (mm):",np.round((com-V.mean(0))*10,4))
Vc=V-com
st,un,_=equilibria(Vc,np.zeros(3)); print("with rods: stable",len(st),"unstable",len(un))
m=margins(V0); print("margins (cm at this size): face %.3f  vertex %.3f"%(m['face']*s,m['vert']*s))
w,R=np.linalg.eigh(I); print("principal",np.round(w,8)); print(np.round(R,4))
K2=np.diag(I)/M
restH=-(Vc[:,2].min()); top=Vc[0]
# display mesh: balls (icospheres) + rods (12-sided tubes)
import sys; sys.path.insert(0,"../beta"); import shapes
Us,Fs=shapes.icosphere(2)
vs=[];fs=[]
def add(Vn,Fn):
    o=sum(len(x) for x in vs); vs.append(Vn); fs.append(Fn+o)
for v in Vc: add(v+Us*BALL_R,Fs)
DR=0.12  # drawn rod radius (real 0.5 mm, drawn thicker to be seen)
for a,b in E:
    A,B=Vc[a],Vc[b]; d=B-A; L=np.linalg.norm(d); d/=L
    u=np.cross(d,[1,0,0]); 
    if np.linalg.norm(u)<0.1: u=np.cross(d,[0,1,0])
    u/=np.linalg.norm(u); w2=np.cross(d,u); n=12
    ang=2*np.pi*np.arange(n)/n; ring=np.outer(np.cos(ang),u)+np.outer(np.sin(ang),w2)
    Vn=np.vstack([A+DR*ring,B+DR*ring]); Fn=[]
    for i in range(n):
        j=(i+1)%n; Fn+=[(i,j,n+j),(i,n+j,n+i)]
    add(Vn,np.array(Fn))
Vd=np.vstack(vs); Fd=np.vstack(fs)
import os; os.makedirs("out",exist_ok=True)
with open("out/p21.obj","w") as f:
    f.write("# 21-vertex mono-monostatic polyhedron (point masses), balls + rods, cm, COM at origin\n")
    for v in Vd: f.write("v %.5f %.5f %.5f\n"%tuple(v))
    for t in Fd: f.write("f %d %d %d\n"%tuple(t+1))
with open("out/p21.lua","w") as f:
    f.write("""-- A 21-vertex polyhedron with one stable and one unstable equilibrium,
-- after Domokos & Kovacs, "Conway's spiral and a discrete Gomboc with 21 point
-- masses" (Amer. Math. Monthly 130, 2023; arXiv:2103.13727): a Conway (4,5)-spiral
-- -- one apex and four horizontal regular pentagons -- with equal masses at its
-- 21 vertices. RECONSTRUCTED: the paper gives the spiral's angles
-- but not the vertices, and its listed centre-of-mass height does not follow from
-- them, so the ring radii and heights were re-fitted (close to the paper's spiral)
-- to make the margins as large as possible: every other face tips the body by at
-- least %.2f mm, every other vertex by at least %.2f mm (at this size).
-- Built as %d tungsten balls (r %.1f mm) on 1 mm carbon rods; the rods are
-- included in the mass. Stable: the bottom pentagon. Unstable: the apex.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass.
return {
  size = %.2f, mass = %.6f, ballRadius = %.3f, rodRadius = %.3f,
  inertia = { %.6f, %.6f, %.6f },   -- squared radii of gyration, cm^2
  down = { 0, 0, -1 }, top = { %.6f, %.6f, %.6f },
  restHeight = %.5f, topHeight = %.5f,
  vertices = {
"""%(m['face']*s*10,m['vert']*s*10,len(V),BALL_R*10,SIZE,M,BALL_R,ROD_R,*K2,*top,restH,np.linalg.norm(Vc,axis=1).max()))
    for v in Vc: f.write("    %.5f,%.5f,%.5f,\n"%tuple(v))
    f.write("  },\n  edges = {\n")
    for a,b in E: f.write("    %d,%d,\n"%(a+1,b+1))
    f.write("  },\n}\n")
print("restH",restH,"top",top,"K2",K2)
