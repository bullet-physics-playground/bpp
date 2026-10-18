# initial angular acceleration about the tipping edge for a body set flat on a false face
# alpha = g * e / (k_edge^2), e = horizontal distance of COM foot beyond the edge,
# k_edge^2 = I_axis/m + d^2 (d = distance COM to edge line); t(theta) ~ sqrt(2 theta/alpha)
import numpy as np, re, sys
G=981.0
def parse(fn):
    s=open(fn).read(); return s
def tip(V, n, I, s=1.0):
    V=np.array(V)*s; n=np.array(n)/np.linalg.norm(n)
    h=-min(V@n) if False else None
    d0=max(V@n); on=V[np.abs(V@n-d0)<1e-4*s]   # vertices on the face (n outward, face = max n.x)
    foot=-(0)*n  # COM at origin; foot = projection of origin onto face plane
    foot=n*d0
    # polygon edges: convex hull in plane
    u=np.cross(n,[1,0,0]); u=u if np.linalg.norm(u)>1e-6 else np.cross(n,[0,1,0]); u/=np.linalg.norm(u); w=np.cross(n,u)
    from scipy.spatial import ConvexHull
    q=np.c_[on@u,on@w]; H=ConvexHull(q); f=np.array([foot@u,foot@w])
    best=None
    for eq,simp in zip(H.equations,H.simplices):
        e=eq[:2]@f+eq[2]
        if best is None or e>best[0]: best=(e,simp)
    e,simp=best; a,b=on[simp[0]],on[simp[1]]; ax=(b-a)/np.linalg.norm(b-a)
    r=-a-np.dot(-a,ax)*ax; d2=r@r
    Iax=ax@np.diag(I)@ax
    k2=Iax+d2; alpha=G*e/k2
    return e, alpha, np.sqrt(2*np.radians(0.5)/alpha), np.sqrt(2*np.radians(2)/alpha)
import importlib
M=sys.argv[1]
def num(s): return [float(x) for x in re.findall(r'-?\d+\.\d+(?:e-?\d+)?', s)]
b=open(M+'/bille-data.lua').read()
mass=float(re.search(r'mass = ([\d.]+)',b).group(1)); I=np.array(num(re.search(r'inertia = \{([^}]*)\}',b).group(1)))/mass
vs={k:num(v) for k,v in re.findall(r'\b([A-D]) = \{ ([^}]*) \}', [l for l in b.splitlines() if l.strip().startswith("vertices")][0])}
ns={k:num(v) for k,v in re.findall(r'\b([A-D]) = \{ ([^}]*) \}', [l for l in b.splitlines() if l.strip().startswith("normals")][0])}
V=[vs[k] for k in "ABCD"]
for f in "ABC":
    e,a,t05,t2=tip(V,ns[f],I); print("bille face %s: foot beyond edge %.3f mm, alpha0 %.1f rad/s^2, 0.5 deg at %.4f s, 2 deg at %.4f s"%(f,e*10,a,t05,t2))
for name,fn,s in (("p26","p26.lua",4.5),("p37","p37.lua",4.5),("ppla","ppla37-data.lua",40/15)):
    t=open(M+'/'+fn).read()
    vv=num(re.search(r'vertices = \{(.*?)\}',t,re.S).group(1)); V=np.array(vv).reshape(-1,3)
    I=np.array(num(re.search(r'inertia = \{([^}]*)\}',t).group(1)))*s*s
    n=num(re.search(r'n = \{([^}]*)\}[^\n]*name = "S1"',t).group(1))
    e,a,t05,t2=tip(V,n,I,s); print("%s S1 at 40 cm: foot beyond edge %.2f mm, alpha0 %.1f rad/s^2, 0.5 deg at %.4f s, 2 deg at %.4f s"%(name,e*10,a,t05,t2))
