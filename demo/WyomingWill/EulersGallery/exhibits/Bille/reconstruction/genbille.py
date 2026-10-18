"""Face data for the spiral polyhedra in the Bille demo: for each face its
outward normal, the centre of mass's height above it, its band name and the
face it tips onto (quasi-static), in the body frame of p21/p26/p37.lua."""
import numpy as np, re, sys
from scipy.spatial import ConvexHull
from collections import defaultdict, Counter
SRC=sys.argv[1] if len(sys.argv) > 1 else "./"   # folder holding p21/p26/p37.lua
def loadlua(fn):
    s=open(fn).read(); hdr=s[:s.index("vertices = {")]
    vs=np.array(list(map(float,re.findall(r"-?\d+\.\d+",s[s.index("vertices = {"):])))).reshape(-1,3)
    return s,vs
for nv in (21,26,37):
    s,V=loadlua(f"{SRC}p{nv}.lua")
    n={21:4,26:5,37:6}[nv]; k=(nv-1)//n
    H=ConvexHull(V); F=defaultdict(set); EQ={}
    keys=[]
    for simp,e in zip(H.simplices,H.equations):
        key=None
        for kk in keys:
            if np.dot(kk[:3],e[:3])>1-1e-7 and abs(kk[3]-e[3])<1e-5: key=kk; break
        if key is None: key=tuple(e); keys.append(key)
        F[key].update(simp); EQ[key]=e
    # ring index of each vertex: 0 = apex, 1..n rings (by order in file)
    ring=np.zeros(len(V),int)
    for i in range(1,len(V)): ring[i]=(i-1)//k+1
    faces=[]
    for key,vs in F.items():
        vs=sorted(vs); nrm=np.array(key[:3]); h=-key[3]
        rs=set(ring[list(vs)])
        if len(vs)==k and rs=={n}: name="base"
        else: name=f"S{n-min(rs)+1 if 0 not in rs else n}"   # S1 = band next to the base ... Sn = apex triangles
        if 0 in rs: name=f"S{n}"
        else:
            lo=max(rs)   # lower ring of the band
            name="base" if (len(rs)==1 and lo==n) else f"S{n-lo+1}"
        faces.append(dict(key=key,v=vs,n=nrm,h=h,name=name))
    # successor: foot point outside -> neighbour across the most violated edge
    edge_faces=defaultdict(list)
    for fi,f in enumerate(faces):
        P=V[f["v"]]; c=P.mean(0); nr=f["n"]
        u=np.cross(nr,[1,0,0]); u=u if np.linalg.norm(u)>1e-6 else np.cross(nr,[0,1,0]); u/=np.linalg.norm(u); w=np.cross(nr,u)
        order=np.argsort(np.arctan2((P-c)@w,(P-c)@u)); f["poly"]=[f["v"][j] for j in order]
        for a,b in zip(f["poly"],f["poly"][1:]+f["poly"][:1]): edge_faces[tuple(sorted((a,b)))].append(fi)
    for fi,f in enumerate(faces):
        if f["name"]=="base": f["next"]=None; continue
        foot=-f["n"]*(-f["h"])*-1  # COM at origin: foot = -h*n?  plane n.x = h -> foot = h*n
        foot=f["h"]*f["n"]; best=None
        for a,b in zip(f["poly"],f["poly"][1:]+f["poly"][:1]):
            A,B=V[a],V[b]; ed=B-A; out=np.cross(ed,f["n"]); out/=np.linalg.norm(out)
            if (V[f["poly"]].mean(0)-A)@out>0: out=-out
            d=(foot-A)@out
            if best is None or d>best[0]: best=(d,(a,b))
        assert best[0]>0
        nb=[x for x in edge_faces[tuple(sorted(best[1]))] if x!=fi][0]
        f["next"]=faces[nb]["name"]
    print(nv, Counter((f["name"],f["next"]) for f in faces))
    # write
    body=s[:s.index("  vertices = {")]
    out=body.replace("return {","return {",1)
    lines=[out,"  vertices = {\n"]+["    %.5f,%.5f,%.5f,\n"%tuple(v) for v in V]+["  },\n",
           "  -- faces: outward normal, centre-of-mass height above it (cm), band, the band it tips onto\n","  faces = {\n"]
    for f in sorted(faces,key=lambda f:(f["name"]!="base",f["name"])):
        lines.append('    { n = { %.6f, %.6f, %.6f }, h = %.5f, name = "%s", next = %s },\n'%(*f["n"],f["h"],f["name"],'"%s"'%f["next"] if f["next"] else "nil"))
    lines.append("  },\n}\n")
    open(f"out/p{nv}.lua","w").write("".join(lines))
