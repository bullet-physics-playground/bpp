import numpy as np, shapes
from scipy.spatial import ConvexHull
from hulleq import build
def vertex_normals(V,F):
    N=np.zeros_like(V); fn=np.cross(V[F[:,1]]-V[F[:,0]],V[F[:,2]]-V[F[:,0]])
    for k in range(3): np.add.at(N,F[:,k],fn)
    return N/np.linalg.norm(N,axis=1)[:,None]
def stall(form,beta,level=7,size=9.0,deltas=(50,150)):
    U,F,V,vol,I=build(form,beta,level,size)
    N=vertex_normals(V,F)
    onhull=np.zeros(len(V),bool); onhull[ConvexHull(V).vertices]=True
    lever=np.linalg.norm(V-(np.einsum('ij,ij->i',V,N))[:,None]*N,axis=1)*1e4  # µm
    # stable direction: resting normal at global min of h ~ min r
    hgt=np.einsum('ij,ij->i',V,N)
    i0=np.argmin(np.where(onhull,hgt,1e9)); n0=N[i0]
    out=[]
    for d in deltas:
        m=onhull&(lever<d)
        ang=np.degrees(np.arccos(np.clip(N[m]@n0,-1,1)))
        out.append((d, ang.max() if len(ang) else 0, m.sum()/onhull.sum()))
    # height difference unstable-stable
    return out, hgt.max()-hgt[i0], hgt[i0]
for form,betas in ((1,(0.05,0.08,0.10,0.12,0.15)),(2,(0.05,0.08,0.10,0.12,0.15,0.17))):
    for b in betas:
        o,dh,h0=stall(form,b)
        print(f"form {form} β {b:.2f}: rest height {h0:.2f} cm, top-rest {dh*10:.1f} mm; "+"; ".join(f"lever<{d}µm: up to {a:.0f}° from rest ({f*100:.1f}% of surface)" for d,a,f in o),flush=True)
