import numpy as np
from scipy.spatial import ConvexHull

def icosphere(level):
    t=(1+5**.5)/2
    V=[(-1,t,0),(1,t,0),(-1,-t,0),(1,-t,0),(0,-1,t),(0,1,t),(0,-1,-t),(0,1,-t),(t,0,-1),(t,0,1),(-t,0,-1),(-t,0,1)]
    F=[(0,11,5),(0,5,1),(0,1,7),(0,7,10),(0,10,11),(1,5,9),(5,11,4),(11,10,2),(10,7,6),(7,1,8),(3,9,4),(3,4,2),(3,2,6),(3,6,8),(3,8,9),(4,9,5),(2,4,11),(6,2,10),(8,6,7),(9,8,1)]
    V=[np.array(v,float)/np.linalg.norm(v) for v in V]
    for _ in range(level):
        cache={}; NF=[]
        def mid(a,b):
            k=(min(a,b),max(a,b))
            if k not in cache:
                m=V[a]+V[b]; V.append(m/np.linalg.norm(m)); cache[k]=len(V)-1
            return cache[k]
        for a,b,c in F:
            ab,bc,ca=mid(a,b),mid(b,c),mid(c,a)
            NF+= [(a,ab,ca),(b,bc,ab),(c,ca,bc),(ab,bc,ca)]
        F=NF
    return np.array(V),np.array(F)

def radius(U, form, beta):
    x,y,z=U.T
    phi=np.arccos(np.clip(z,-1,1)); th=np.arctan2(y,x)
    if form==1: f=np.sin(phi)*np.cos(th-5*phi)
    else:       f=np.sin(phi)*np.cos(th-1.5*np.pi*(np.cos(phi)-np.cos(phi)**3/3))
    return (1+4*beta*f)**0.25

def mass_props(V,F):
    a,b,c=V[F[:,0]],V[F[:,1]],V[F[:,2]]
    vol6=np.einsum('ij,ij->i',a,np.cross(b,c)); vol=vol6.sum()/6
    com=((a+b+c)*vol6[:,None]).sum(0)/24/vol
    # second moments  ∫ x x^T over tetra (0,a,b,c) = vol6/120 * (sum p p^T + (sum p)(sum p)^T)
    S=a+b+c
    M=np.einsum('i,ij,ik->jk',vol6/120,S,S)+np.einsum('i,ij,ik->jk',vol6/120,a,a)+np.einsum('i,ij,ik->jk',vol6/120,b,b)+np.einsum('i,ij,ik->jk',vol6/120,c,c)
    M=M - vol*np.outer(com,com)
    I=np.trace(M)*np.eye(3)-M      # per unit density
    return vol,com,I

def persistence_count(U,F,h,eps):
    """number of local minima of h on the sphere graph with persistence > eps (plus the global one)"""
    n=len(U); nb=[set() for _ in range(n)]
    for a,b,c in F: nb[a]|={b,c}; nb[b]|={a,c}; nb[c]|={a,b}
    order=np.argsort(h); parent=-np.ones(n,int); birth={}
    def find(i):
        while parent[i]!=i: parent[i]=parent[parent[i]]; i=parent[i]
        return i
    pers=[]
    for i in order:
        parent[i]=i; roots={find(j) for j in nb[i] if parent[j]>=0}
        if not roots: birth[i]=h[i]; continue
        roots=sorted(roots,key=lambda r:birth[r])
        keep=roots[0]; parent[i]=keep
        for r in roots[1:]:
            pers.append((h[i]-birth[r], r)); parent[r]=keep
    return 1+sum(p>eps for p,_ in pers), sorted([p for p,_ in pers],reverse=True)[:5]

def analyse(form,beta,level=6,dirlevel=6,size=9.0,eps_rel=2e-6):
    U,F=icosphere(level); r=radius(U,form,beta); V=U*r[:,None]
    vol,com,I=mass_props(V,F)
    V=V-com
    H=ConvexHull(V); HP=V[H.vertices]
    D,DF=icosphere(dirlevel)
    h=np.concatenate([(D[i:i+2000]@HP.T).max(1) for i in range(0,len(D),2000)])
    scale=size/np.ptp(V,axis=0).max()
    eps=eps_rel*size/scale
    ns,ps=persistence_count(D,DF,h,eps)
    nu,pu=persistence_count(D,DF,-h,eps)
    # non-convexity: fraction of mesh vertices not on hull (distance)
    return dict(form=form,beta=beta,stable=ns,unstable=nu,ps=np.array(ps)*scale*1e4,pu=np.array(pu)*scale*1e4,
                rmin=r.min(),rmax=r.max(),nonhull=1-len(H.vertices)/len(V),com=com,scale=scale)
if __name__=="__main__":
    import sys
    for form in (1,2):
        for beta in (0.03,0.06,0.09,0.12,0.15,0.17):
            a=analyse(form,beta,level=5,dirlevel=5)
            print(f"form {form} beta {beta:.2f}: stable {a['stable']} unstable {a['unstable']}  r {a['rmin']:.3f}-{a['rmax']:.3f}  off-hull {a['nonhull']*100:.1f}%  next-deepest(µm) S {np.round(a['ps'][:2],2)} U {np.round(a['pu'][:2],2)}",flush=True)
