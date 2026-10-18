"""Write pNN.obj / pNN.lua for a Conway (n,k)-spiral polyhedron built as a real
object: 0.5 mm polycarbonate shell + a 5.2 g tungsten weight centred 3 mm inside
each corner. Checks equilibria with the true centre of mass, and robustness."""
import numpy as np, sys
from scipy.spatial import ConvexHull
from collections import defaultdict
import opt21s as o
from optnk import make_verts
from eq import equilibria
T_MM, RHO_PC, M_W, INSET, R_W = 0.5, 1.2e-3, 0.0052, 0.3, 0.4
o.T_MM, o.M_CORNER, o.INSET = T_MM, M_W, INSET
def props(V):
    H=ConvexHull(V); cen=V.mean(0)
    M=0; mom=np.zeros(3); S=np.zeros((3,3)); Iown=np.zeros((3,3))
    for v in V:
        d=cen-v; d/=np.linalg.norm(d); p=v+INSET*d
        M+=M_W; mom+=M_W*p; S+=M_W*np.outer(p,p); Iown+=0.4*M_W*R_W**2*np.eye(3)
    sig=T_MM/10*RHO_PC
    for s in H.simplices:
        a,b,c=V[s]; A=0.5*np.linalg.norm(np.cross(b-a,c-a)); m=sig*A; tot=a+b+c
        M+=m; mom+=m*tot/3; S+=m/12*(np.outer(a,a)+np.outer(b,b)+np.outer(c,c)+np.outer(tot,tot))
    com=mom/M; S=S-M*np.outer(com,com); I=np.trace(S)*np.eye(3)-S+Iown
    return M,com,I,H
def build(n,k):
    p=np.load(f"shell_{n}_{k}.npy"); V=make_verts(n,k)(p); V=V*9.0/np.ptp(V,axis=0).max()
    M,com,I,H=props(V)
    _,_,c2,_,_=o.mass_model(V); assert np.allclose(com,c2,atol=1e-9), (com,c2)
    st,un,_=equilibria(V,com); m=o.margins_c(V,com)
    margin=min(m['face'],m['vert'],m['bottom'],m['top'])
    # robustness: random vertex errors and weight-mass scatter
    rng=np.random.default_rng(0); rob={}
    for err in (0.02,0.05,0.1):
        ok=0
        for t in range(300):
            W=V+err*rng.standard_normal(V.shape)
            o.M_CORNER=M_W  # (props uses uniform weights; scatter them below)
            Mx,cx,_,_=props(W)
            ms=M_W*(1+0.03*rng.standard_normal(len(W)))
            cx=cx+((ms-M_W)[:,None]*(W+INSET*((W.mean(0)-W)/np.linalg.norm(W.mean(0)-W,axis=1)[:,None]))).sum(0)/Mx
            s2,u2,_=equilibria(W,cx); ok+=(len(s2)==1 and len(u2)==1)
        rob[err]=ok/300
    Vc=V-com
    K2=np.diag(I)/M
    off=np.abs(I-np.diag(np.diag(I))).max()
    faces=defaultdict(set)
    for simp,e in zip(H.simplices,H.equations): faces[tuple(np.round(e,7))].update(simp)
    vs=[]; fs=[]
    for key,idx in faces.items():
        nrm=np.array(key[:3]); P=Vc[list(idx)]; cc=P.mean(0)
        u=np.cross(nrm,[1,0,0]); u=u if np.linalg.norm(u)>1e-6 else np.cross(nrm,[0,1,0]); u/=np.linalg.norm(u); w=np.cross(nrm,u)
        P=P[np.argsort(np.arctan2((P-cc)@w,(P-cc)@u))]; base=len(vs); vs+=list(P)
        for j in range(1,len(P)-1):
            a,b,c3=base,base+j,base+j+1
            if np.cross(P[j]-P[0],P[j+1]-P[0])@nrm<0: b,c3=c3,b
            fs.append((a,b,c3))
    nv=len(V); name=f"p{nv}"
    with open(f"out/{name}.obj","w") as f:
        f.write(f"# {nv}-vertex mono-monostatic polyhedron (Conway ({n},{k})-spiral), shell + corner weights, cm, COM at origin\n")
        for v in vs: f.write("v %.5f %.5f %.5f\n"%tuple(v))
        for t in fs: f.write("f %d %d %d\n"%(t[0]+1,t[1]+1,t[2]+1))
    restH=-(Vc[:,2].min())
    with open(f"out/{name}.lua","w") as f:
        f.write(f"""-- A {nv}-vertex polyhedron with one stable face and one unstable vertex: a
-- Conway ({n},{k})-spiral (Domokos & Kovacs 2023): an apex above {n} horizontal
-- regular {k}-gons, {len(faces)} faces. Unlike the 21-vertex one, this is a REAL
-- object, not an idealisation: a {T_MM} mm polycarbonate shell (1.2 g/cm^3) with
-- a {M_W*1e3:.1f} g tungsten weight in every corner, centred {INSET*10:.0f} mm inside it.
-- Ring radii and heights fitted for that build (variety-reconstruction/
-- optshell.py): every other face tips it by at least {margin*10:.2f} mm, every other
-- corner by at least as much (9 cm tall). Still exactly one stable face and one
-- unstable vertex with random corner errors of 0.2 / 0.5 / 1.0 mm and 3% scatter
-- in the weights in {rob[0.02]*100:.0f}% / {rob[0.05]*100:.0f}% / {rob[0.1]*100:.0f}% of 300 trials each.
-- Stable: the bottom {k}-gon. Unstable: the apex.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass.
return {{
  size = 9.00, mass = {M:.6f}, margin = 0.04, n = {n}, k = {k},
  inertia = {{ {K2[0]:.6f}, {K2[1]:.6f}, {K2[2]:.6f} }},   -- squared radii of gyration, cm^2
  down = {{ 0, 0, -1 }}, top = {{ {Vc[0][0]:.6f}, {Vc[0][1]:.6f}, {Vc[0][2]:.6f} }},
  restHeight = {restH:.5f}, topHeight = {np.linalg.norm(Vc,axis=1).max():.5f},
  vertices = {{
""")
        for v in Vc: f.write("    %.5f,%.5f,%.5f,\n"%tuple(v))
        f.write("  },\n}\n")
    print(f"{name}: ({n},{k}) faces {len(faces)} mass {M*1e3:.1f} g, stable {len(st)} unstable {len(un)}, margin {margin*10:.2f} mm, robust {rob}, off-diag I {off:.2e}, K2 {np.round(K2,3)}")
if __name__=="__main__":
    for nk in ((5,5),(6,6)): build(*nk)
