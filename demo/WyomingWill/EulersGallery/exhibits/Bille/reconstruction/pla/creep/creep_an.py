import numpy as np, glob, os, sys
D=sys.argv[1]
def rot(q0,q):
    d=np.abs(np.sum(q*q0,axis=1)).clip(0,1); return np.degrees(2*np.arccos(d))
print("%-28s %8s %9s %9s %9s %9s" % ("run","tilt@2s","tiltrate","rot/s","drift mm/s","w_med"))
for f in sorted(glob.glob(D+'/home-*.csv')):
    a=np.genfromtxt(f,delimiter=',',dtype=None,encoding=None)
    t=np.array([r[0] for r in a]); tilt=np.array([r[4] for r in a]); q=np.array([[r[5],r[6],r[7],r[8]] for r in a])
    p=np.array([[r[9],r[10],r[11]] for r in a]); w=np.array([r[12] for r in a])
    m=t>=2; t0=t[m][0]; T=t[m][-1]-t0
    r=rot(q[m][0],q[m]); dp=np.linalg.norm((p[m]-p[m][0])[:,[0,2]],axis=1)*10
    print("%-28s %8.4f %9.5f %9.5f %9.4f %9.4f   (tilt max %.4f, rot max %.4f deg over %.0f s)" % (os.path.basename(f)[5:-4], tilt[m][0],
          (tilt[m][-1]-tilt[m][0])/T, r[-1]/T, dp[-1]/T, np.median(w[m]), tilt[m].max(), r.max(), T))
print()
for f in sorted(glob.glob(D+'/false-*.csv')):
    a=np.genfromtxt(f,delimiter=',',dtype=None,encoding=None)
    t=np.array([r[0] for r in a]); tilt=np.array([r[4] for r in a])
    def tt(x):
        i=np.argmax(tilt>x); return t[i] if tilt[i]>x else np.nan
    print("%-24s tilt reaches 0.5/2/10 deg at %.4f %.4f %.4f s" % (os.path.basename(f)[6:-4], tt(.5), tt(2), tt(10)))
