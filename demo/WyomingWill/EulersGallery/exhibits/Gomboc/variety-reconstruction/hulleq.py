import numpy as np
from scipy.spatial import ConvexHull
from collections import defaultdict
import shapes

def stable_faces(P, H=None):
    """stable resting faces of hull(P), COM at origin: (normal, height, barrier)"""
    H=H or ConvexHull(P)
    keys=defaultdict(list)
    for i,e in enumerate(H.equations): keys[tuple(np.round(e,10))].append(i)
    out=[]
    for k,tris in keys.items():
        n=np.array(k[:3]); h=-k[3]; foot=n*h
        inside=False
        for t in tris:
            a,b,c=P[H.simplices[t]]
            v0,v1,v2=b-a,c-a,foot-a
            d00,d01,d11,d20,d21=v0@v0,v0@v1,v1@v1,v2@v0,v2@v1
            den=d00*d11-d01*d01
            if den<=0: continue
            v=(d11*d20-d01*d21)/den; w=(d00*d21-d01*d20)/den
            if v>=-1e-12 and w>=-1e-12 and v+w<=1+1e-12: inside=True;break
        if not inside: continue
        ec=defaultdict(int)
        for t in tris:
            s=H.simplices[t]
            for e in ((s[0],s[1]),(s[1],s[2]),(s[2],s[0])): ec[tuple(sorted(e))]+=1
        bar=1e9
        for (i,j),cnt in ec.items():
            if cnt!=1: continue
            a,b=P[i],P[j]; ab=b-a; t=np.clip(-(a@ab)/(ab@ab),0,1); bar=min(bar,np.linalg.norm(a+t*ab)-h)
        out.append((n,h,bar))
    return out

def unstable_vertices(P,H):
    """hull vertices that are local maxima of distance from the COM (over hull neighbours), with persistence"""
    nb=defaultdict(set)
    for s in H.simplices:
        for a in s: nb[a].update(s)
    d=np.linalg.norm(P,axis=1)
    idx=H.vertices
    order=idx[np.argsort(-d[idx])]
    parent={}; birth={}
    def find(i):
        while parent[i]!=i: parent[i]=parent[parent[i]]; i=parent[i]
        return i
    pers=[]
    for i in order:
        parent[i]=i; roots={find(j) for j in nb[i] if j in parent and j!=i}
        if not roots: birth[i]=d[i]; continue
        roots=sorted(roots,key=lambda r:-birth[r]); keep=roots[0]; parent[i]=keep
        for r in roots[1:]: pers.append(birth[r]-d[i]); parent[r]=keep
    return sorted(pers,reverse=True)

def build(form,beta,level=7,size=9.0):
    U,F=shapes.icosphere(level); r=shapes.radius(U,form,beta); V=U*r[:,None]
    vol,com,I=shapes.mass_props(V,F)
    s=size/np.ptp(V-com,axis=0).max()
    V=(V-com)*s; vol*=s**3; I=I*s**5
    return U,F,V,vol,I

def check(form,beta,level=7,size=9.0,down=None):
    U,F,V,vol,I=build(form,beta,level,size)
    H=ConvexHull(V)
    S=stable_faces(V,H)
    S.sort(key=lambda x:-x[2])
    main=S[0][0]
    rows=[(np.degrees(np.arccos(np.clip(n@main,-1,1))),b*1e4) for n,h,b in S]
    deep=[r for r in rows[1:] if r[1]>1.0]
    up=unstable_vertices(V,H)
    return dict(nS=len(S), main=main, mainbar=rows[0][1], extra_deep=deep, maxang=max(a for a,b in rows),
                unstable_pers_um=np.array(up[:4])*1e4, offhull=1-len(H.vertices)/len(V), vol=vol, I=I, V=V, F=F, H=H)

if __name__=="__main__":
    import sys
    for form in (1,2):
        for beta in ((0.03,0.06,0.09,0.12,0.15) if form==1 else (0.03,0.06,0.09,0.12,0.15,0.17)):
            c=check(form,beta,level=int(sys.argv[1]) if len(sys.argv)>1 else 7)
            print(f"form {form} β {beta:.2f}: stable faces {c['nS']} (all within {c['maxang']:.1f}° of main; main barrier {c['mainbar']:.0f} µm); "
                  f"extra faces with barrier>1µm: {len(c['extra_deep'])} {[(round(a),round(b,1)) for a,b in c['extra_deep'][:4]]}; "
                  f"2nd unstable prominence(µm) {np.round(c['unstable_pers_um'][:3],2)}; off-hull {c['offhull']*100:.0f}%",flush=True)
