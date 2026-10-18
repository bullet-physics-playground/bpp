"""Frame ("skeleton") drawing meshes for the spiral polyhedra: a ball at every
corner and a rod along every edge, same body frame as pNN.lua/pNN.obj."""
import numpy as np, re, sys
from scipy.spatial import ConvexHull
from collections import defaultdict
sys.path.insert(0, "../../Gomboc/variety-reconstruction"); import shapes   # icosphere helper
SRC=sys.argv[1] if len(sys.argv)>1 else "out/"
Us,Fs=shapes.icosphere(2)
for nv in (21,26,37):
    s=open(f"{SRC}p{nv}.lua").read()
    V=np.array(list(map(float,re.findall(r"-?\d+\.\d+",s[s.index("vertices = {"):s.index("faces = {")])))).reshape(-1,3)
    H=ConvexHull(V); keys=[]; F=defaultdict(list)
    for simp,e in zip(H.simplices,H.equations):
        key=None
        for kk in keys:
            if np.dot(kk[:3],e[:3])>1-1e-7 and abs(kk[3]-e[3])<1e-5: key=kk; break
        if key is None: key=tuple(e); keys.append(key)
        F[key].append(simp)
    E=set()
    for tris in F.values():
        cnt=defaultdict(int)
        for t in tris:
            for a,b in ((t[0],t[1]),(t[1],t[2]),(t[2],t[0])): cnt[tuple(sorted((a,b)))]+=1
        E|={e for e,c in cnt.items() if c==1}
    BR,DR=0.30,0.10            # drawn ball and rod radii (cm, at 9 cm tall)
    vs=[];fs=[]
    def add(Vn,Fn):
        o=sum(len(x) for x in vs); vs.append(Vn); fs.append(np.asarray(Fn)+o)
    for v in V: add(v+Us*BR,Fs)
    for a,b in E:
        A,B=V[a],V[b]; d=B-A; L=np.linalg.norm(d); d/=L
        u=np.cross(d,[1,0,0]); u=u if np.linalg.norm(u)>0.1 else np.cross(d,[0,1,0]); u/=np.linalg.norm(u); w=np.cross(d,u)
        n=10; ang=2*np.pi*np.arange(n)/n; ring=np.outer(np.cos(ang),u)+np.outer(np.sin(ang),w)
        add(np.vstack([A+DR*ring,B+DR*ring]),[(i,(i+1)%n,n+(i+1)%n) for i in range(n)]+[(i,n+(i+1)%n,n+i) for i in range(n)])
    Vd=np.vstack(vs); Fd=np.vstack(fs)
    with open(f"out/p{nv}-frame.obj","w") as f:
        f.write(f"# {nv}-corner spiral polyhedron drawn as a frame: balls at the corners, rods on the {len(E)} edges (cm, COM at origin)\n")
        for v in Vd: f.write("v %.5f %.5f %.5f\n"%tuple(v))
        for t in Fd: f.write("f %d %d %d\n"%tuple(t+1))
    print(nv, "edges", len(E), "faces", len(F))
