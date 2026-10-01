import numpy as np, re
F='/home/koppi/bpp/export/11-geneva-drive/mesh_9a27766775c96472b978d74087fb88d343fc2010.inc'
txt=open(F).read()
rat=re.compile(r'<(\s*-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*,\s*(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*,\s*(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)\s*>')
v=[]
num=0
for a,b,c in rat.findall(txt):
    a=float(a);b=float(b);c=float(c)
    if abs(c)>0.31: continue
    v.append((a,b))
print("cross z-plane vertices:",len(v))
assert len(v)%3==0
tris=[v[i:i+3] for i in range(0,len(v),3)]
print("tris",len(tris))
N=2400; ext=4.2
g=np.linspace(-ext,ext,N,endpoint=False); X,Y=np.meshgrid(g,g)
m=np.zeros((N,N),dtype=bool)
def raster_tri(t):
    p0,p1,p2=t
    xs=[p[0] for p in t]; ys=[p[1] for p in t]
    if max(ys)<-ext or min(ys)>ext or max(xs)<-ext or min(xs)>ext: return
    x0=int((min(xs)+ext)/(2*ext)*N); x1=int((max(xs)+ext)/(2*ext)*N)+1
    y0=int((min(ys)+ext)/(2*ext)*N); y1=int((max(ys)+ext)/(2*ext)*N)+1
    x0=max(x0,0);y0=max(y0,0);x1=min(x1,N);y1=min(y1,N)
    px=X[y0:y1,x0:x1]; py=Y[y0:y1,x0:x1]
    s1=(p1[0]-p0[0])*(py-p0[1])-(p1[1]-p0[1])*(px-p0[0])
    s2=(p2[0]-p1[0])*(py-p1[1])-(p2[1]-p1[1])*(px-p1[0])
    s3=(p0[0]-p2[0])*(py-p2[1])-(p0[1]-p2[1])*(px-p2[0])
    q=(s1>=0)&(s2>=0)&(s3>=0)
    r=(s1<=0)&(s2<=0)&(s3<=0)
    m[y0:y1,x0:x1]|=q|r
for t in tris: raster_tri(t)
np.save('/tmp/opencode/mesh_cross.npy',m)
print("mesh cells",int(m.sum()))
N2=m.shape[0];W=60;step=N2/W
for i in range(W):
    print(''.join('#' if m[int((i+.5)*step),int((j+.5)*step)] else '.' for j in range(W)))
