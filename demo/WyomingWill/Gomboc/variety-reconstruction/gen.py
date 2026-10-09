"""Generate Sloan beta-Gomboc data for bpp: display OBJ + hull/mass-props Lua file.
Shape (Sloan 2023, via MathWorld):
  form 1: r^4 = 1 + 4 b sin(phi) cos(theta - 5 phi)
  form 2: r^4 = 1 + 4 b sin(phi) cos(theta - (3pi/2)(cos phi - cos^3 phi / 3))
phi = polar angle from +z, theta = azimuth. Uniform density. Scaled so the longest
extent is SIZE cm. Body frame = principal axes, origin at centre of mass."""
import numpy as np, sys
from scipy.spatial import ConvexHull
import shapes

def fib(n):
    i=np.arange(n)+0.5; z=1-2*i/n; th=np.pi*(1+5**.5)*i; r=np.sqrt(1-z*z)
    U=np.c_[r*np.cos(th),r*np.sin(th),z]; F=ConvexHull(U).simplices
    # orient outward
    c=U[F].mean(1); n=np.cross(U[F[:,1]]-U[F[:,0]],U[F[:,2]]-U[F[:,0]])
    flip=np.einsum('ij,ij->i',n,c)<0; F[flip]=F[flip][:,::-1]
    return U,F

def surface(U,form,beta): return U*shapes.radius(U,form,beta)[:,None]

def make(form,beta,size=9.0,nhull=25000,ndisp=8000,name=None):
    # mass properties from a fine mesh (icosphere level 7)
    Uf,Ff=shapes.icosphere(7); Vf=surface(Uf,form,beta)
    vol,com,I=shapes.mass_props(Vf,Ff)
    w,R=np.linalg.eigh(I)          # principal axes (columns), ascending
    if np.linalg.det(R)<0: R[:,2]*=-1
    s=size/np.ptp((Vf-com)@R,axis=0).max()
    tr=lambda X:((X-com)@R)*s
    # stable (rest) and unstable directions in Sloan coords -> body
    if form==1: rest_u=np.array([0,-1.0,0]); top_u=np.array([0,1.0,0])
    else:       rest_u=np.array([-1.0,0,0]); top_u=np.array([1.0,0,0])   # (MathWorld lists phi=0, but r is largest at +x)
    Uh,Fh=fib(nhull); Vh=tr(surface(Uh,form,beta)); H=ConvexHull(Vh); P=Vh[H.vertices]
    # rest: support plane in the rest direction (outward normal of the resting point)
    down=(R.T@rest_u); down/=np.linalg.norm(down)
    restH=(P@down).max()
    top=tr(surface(top_u[None],form,beta))[0]; topH=np.linalg.norm(P,axis=1).max()
    Ud,Fd=fib(ndisp); Vd=tr(surface(Ud,form,beta))
    K2=w*s**2/vol      # squared radii of gyration about principal axes (cm^2): I/(rho V) * s^2 ... (I scales s^5, V s^3)
    name=name or f"beta{form}-{int(round(beta*100)):02d}"
    with open(f"out/{name}.obj","w") as f:
        f.write(f"# Sloan beta-Gomboc, form {form}, beta {beta}; cm; COM at origin; principal axes\n")
        for v in Vd: f.write("v %.5f %.5f %.5f\n"%tuple(v))
        for t in Fd: f.write("f %d %d %d\n"%tuple(t+1))
    with open(f"out/{name}.lua","w") as f:
        f.write(f"-- Sloan's analytic Gomboc (M. L. Sloan 2023, 'An Analytical Gomboc', arXiv:2306.14914),\n")
        f.write(f"-- form {form}, beta = {beta}:  " + ("r^4 = 1 + 4 b sin(phi) cos(theta - 5 phi)" if form==1 else
                "r^4 = 1 + 4 b sin(phi) cos(theta - (3pi/2)(cos phi - cos^3 phi / 3))") + "\n")
        f.write(f"-- Uniform density, longest extent {size} cm, in cm, centre of mass at the origin,\n")
        f.write("-- principal axes. Not strictly convex at this beta: the dimples never touch the\n")
        f.write("-- table, so it rolls on its convex hull (these points); checked: that hull has one\n")
        f.write("-- resting point and one balancing point (see gomboc-variety.lua).\n")
        f.write("return {\n")
        f.write(f"  form = {form}, beta = {beta}, size = {size}, volume = {vol*s**3:.4f},\n")
        f.write("  inertia = { %.6f, %.6f, %.6f },   -- squared radii of gyration, cm^2\n"%tuple(K2))
        f.write("  down = { %.6f, %.6f, %.6f },      -- outward normal at the resting point\n"%tuple(down))
        f.write("  top = { %.6f, %.6f, %.6f },       -- the balancing (unstable) point\n"%tuple(top))
        f.write(f"  restHeight = {restH:.5f}, topHeight = {topH:.5f},\n")
        f.write("  points = {\n")
        for p in P: f.write("    %.5f,%.5f,%.5f,\n"%tuple(p))
        f.write("  },\n}\n")
    print(name, "hull pts",len(P),"vol",round(vol*s**3,2),"K2",np.round(K2,3),"restH",round(restH,3),"topH",round(topH,3),"|top|",round(np.linalg.norm(top),3),"down",np.round(down,3))
    return P,down,top,vol*s**3,K2
if __name__=="__main__":
    import os; os.makedirs("out",exist_ok=True)
    for form,beta in [(1,0.12),(1,0.15),(2,0.12),(2,0.17)]:
        make(form,beta)
