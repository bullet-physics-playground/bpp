import numpy as np
from scipy.spatial import ConvexHull
def equilibria(V, c):
    h=ConvexHull(V)
    # merge coplanar simplices into faces by normal
    eqs=h.equations
    faces={}
    for s,e in zip(h.simplices,eqs):
        key=tuple(np.round(e,7)); faces.setdefault(key,set()).update(s)
    stable=[]
    for key,vs in faces.items():
        n=np.array(key[:3]); d=key[3]
        p=c-(n@c+d)*n   # projection
        vs=list(vs); P=V[vs]
        # check p inside polygon: for each hull edge of face polygon in plane
        # build 2D basis
        u=np.cross(n,[1,0,0]); 
        if np.linalg.norm(u)<1e-6: u=np.cross(n,[0,1,0])
        u/=np.linalg.norm(u); w=np.cross(n,u)
        q=np.c_[P@u,P@w]; pp=np.array([p@u,p@w])
        from scipy.spatial import Delaunay
        if len(q)==3 or True:
            hh=ConvexHull(q); 
            inside=np.all(hh.equations[:,:2]@pp+hh.equations[:,2]< -1e-12)
        if inside: stable.append((vs, (n@c+d)))
    # unstable vertices: (v-c) lies in normal cone at v: i.e., for all hull neighbours u of v, (u-v).(v-c) < 0
    nb={i:set() for i in range(len(V))}
    for s in h.simplices:
        for a in s:
            nb[a].update(s)
    unstable=[]
    for i in h.vertices:
        d=V[i]-c
        # normal cone check: v-c direction maximised uniquely at v over all vertices
        if np.all((V@d)[np.arange(len(V))!=i] < V[i]@d - 1e-12): unstable.append(i)
    return stable, unstable, faces
if __name__=="__main__":
    from spiral import build
    V,P=build([66.173,44.519,29.875,19.716])
    c=V.mean(0)
    st,un,f=equilibria(V,c)
    print("faces",len(f),"stable",[(sorted(s),round(-h,4)) for s,h in st],"unstable",un, "zc",c)
