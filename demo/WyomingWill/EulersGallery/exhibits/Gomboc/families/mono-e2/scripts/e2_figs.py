import os, sys, numpy as np, matplotlib
matplotlib.use('Agg'); import matplotlib.pyplot as plt
from matplotlib.colors import LightSource, ListedColormap, LinearSegmentedColormap
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged
from sphere_metrics import *
from scipy.spatial import ConvexHull
a=np.load(REPO+'/genomes-edged/mono-e2.npy')
Bd=edged.body(a,3,4,6); X=Bd['X']; n0=Bd['n0']; piece=Bd['piece']
B=Body(X,6)
vol,G,I,H=hull_mass(X); w,R=np.linalg.eigh(I); R[:,2]*=np.linalg.det(R)
Rup=B.to_upright()                       # body(principal) -> delivery frame (rest down = -Y)
Y=((X-G)@R)@Rup                          # all samples in delivery frame, mm at 90
crease=Y[n0:]
H=ConvexHull(Y); F=H.simplices
# piece of each face (majority of its grid vertices)
pv=np.r_[piece,-np.ones(len(Y)-n0,int)]
fp=np.array([np.bincount(pv[f][pv[f]>=0],minlength=3).argmax() if (pv[f]>=0).any() else 0 for f in F])
cn=np.cross(Y[F[:,1]]-Y[F[:,0]],Y[F[:,2]]-Y[F[:,0]]); cn/=np.linalg.norm(cn,axis=1)[:,None]
c0=Y[F].mean(1); fl=(cn*c0).sum(1)<0; cn[fl]*=-1
restp=Y[np.argmin(Y[:,1])]; topdir=B.top@Rup; topp=Y[np.argmax(Y@topdir)]
base={0:np.array([0.80,0.84,0.90]),1:np.array([0.93,0.90,0.85])}
def view(ax, az, el, title):
    th,ph=np.radians(az),np.radians(el)
    v=np.array([np.cos(ph)*np.sin(th), np.sin(ph), np.cos(ph)*np.cos(th)])   # toward viewer (Y up)
    right=np.cross([0,1,0],v); right/=np.linalg.norm(right); up=np.cross(v,right)
    L=v*0.6+up*0.6+right*0.3; L/=np.linalg.norm(L)
    vis=(cn@v)>0; Fv=F[vis]; depth=(Y[Fv].mean(1)@v); o=np.argsort(depth)
    shade=np.clip(0.35+0.65*(cn[vis]@L),0.25,1)
    cols=np.array([base[k] for k in fp[vis]])*shade[:,None]
    P2=np.c_[Y@right, Y@up]
    from matplotlib.collections import PolyCollection
    ax.add_collection(PolyCollection(P2[Fv[o]],facecolors=np.clip(cols[o],0,1),edgecolors='none'))
    cv=(crease@v) > -5     # crease points roughly on the near side
    # draw crease as dots on visible side: test visibility by nearest face normal
    from scipy.spatial import cKDTree
    kt=cKDTree(c0); _,j=kt.query(crease); cvis=(cn[j]@v)>0.02
    ax.plot((crease@right)[cvis],(crease@up)[cvis],'.',ms=1.2,color='#1c1c1a')
    for p,lab,col in ((restp,'rest','#d03b3b'),(topp,'top','#256abf')):
        if (p/np.linalg.norm(p))@v>-0.05:
            ax.plot(p@right,p@up,'o',ms=6,color=col,mec='white',mew=1.2); ax.annotate(lab,(p@right,p@up),xytext=(6,6),textcoords='offset points',fontsize=9,color='#333')
    ax.plot([-50,50],[restp[1]]*2,color='#888',lw=0.8)
    ax.set_xlim(-52,52); ax.set_ylim(-40,56); ax.set_aspect('equal'); ax.axis('off'); ax.set_title(title,fontsize=10,color='#333')
import sys as _s
fig,axs=plt.subplots(1,3,figsize=(12,4.3),facecolor='#fcfcfb')
for ax,(az,el,t) in zip(axs,((0,8,'front (along +Z)'),(90,8,'side (along +X)'),(35,35,'three-quarter, from above'))): view(ax,az,el,t)
fig.suptitle('mono-e2, upright on its one resting point (90 mm diameter; table line grey; crease dotted)',fontsize=11,color='#222')
plt.tight_layout(); plt.savefig('e2_views.png',dpi=150,facecolor='#fcfcfb')
# ---- lever map: azimuthal equal-area about the rest
Bh=Body(X,7); t=Bh.tilt(); lev36=0.4*Bh.lever
Dd=Bh.D; rest=Bh.rest; e1=np.cross(rest,[1,0,0]); e1/=np.linalg.norm(e1); e2=np.cross(rest,e1)
th=np.radians(t); rr=2*np.sin(th/2); az=np.arctan2(Dd@e2,Dd@e1); x,y=rr*np.cos(az),rr*np.sin(az)
thr=0.4*Bh.h.min()*np.tan(np.radians(1.4))+0.05
weak=(t>25)&(lev36<thr)
fig,ax=plt.subplots(figsize=(7.2,6.4),facecolor='#fcfcfb')
blues=LinearSegmentedColormap.from_list('b',['#cde2fb','#86b6ef','#3987e5','#1c5cab','#0d366b'])
sc=ax.scatter(x,y,c=np.minimum(lev36,3),cmap=blues,s=2.2,lw=0,vmin=0,vmax=3)
ax.scatter(x[weak],y[weak],c='#ec835a',s=2.4,lw=0)
for deg in (25,90,150):
    r0=2*np.sin(np.radians(deg)/2); c=plt.Circle((0,0),r0,fill=False,ls=(0,(3,3)),lw=0.8,color='#666'); ax.add_patch(c)
    ax.text(r0*0.707,-r0*0.707,f'{deg}° from upright',fontsize=8,color='#222',bbox=dict(fc='white',ec='none',alpha=0.8,pad=1))
tp=Bh.top; tth=np.arccos(np.clip(tp@rest,-1,1)); taz=np.arctan2(tp@e2,tp@e1)
ax.plot(2*np.sin(tth/2)*np.cos(taz),2*np.sin(tth/2)*np.sin(taz),'o',color='#0d366b',mec='white',ms=8); ax.annotate('top (balancing point, on the crease)',(2*np.sin(tth/2)*np.cos(taz),2*np.sin(tth/2)*np.sin(taz)),xytext=(8,-14),textcoords='offset points',fontsize=8.5,color='#222')
ax.plot(0,0,'o',color='#d03b3b',mec='white',ms=8); ax.annotate('rest',(0,0),xytext=(8,6),textcoords='offset points',fontsize=8.5)
cb=plt.colorbar(sc,ax=ax,shrink=0.7,pad=0.02); cb.set_label('lever at 36 mm (mm), capped at 3',fontsize=9)
ax.set_aspect('equal'); ax.axis('off')
ax.set_title(f'mono-e2 orientation map (equal-area, centred on the rest)\norange = too weak for a 1.4° slope beyond 25° (lever < {thr:.2f} mm): {100*Bh.w[weak].sum():.1f}% of the sphere',fontsize=10)
plt.tight_layout(); plt.savefig('e2_levermap.png',dpi=150,facecolor='#fcfcfb')
# lever profile
print('weak share',Bh.w[weak].sum(), 'thr',thr)
for d0 in (5,10,15,20,25,30,45,60,90,120,150,170):
    m=np.abs(t-d0)<0.7; print(d0, round(lev36[m].min(),3), round(np.median(lev36[m]),3))
