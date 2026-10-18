import csv, sys, numpy as np
for f in sys.argv[1:]:
    R=list(csv.DictReader(open(f)))
    t=np.array([float(r['t']) for r in R]); tilt=np.array([float(r['tilt_deg']) for r in R])
    q=np.array([[float(r[k]) for k in ('qx','qy','qz','qw')] for r in R]); p=np.array([[float(r['x']),float(r['z'])] for r in R])
    w=np.array([float(r['angvel_deg_s']) for r in R])
    # rest: first time after which angvel stays < 0.5 deg/s for 5 s
    i0=None
    for i in range(len(t)):
        j=np.searchsorted(t,t[i]+5)
        if j<len(t) and (w[i:j]<0.5).all(): i0=i; break
    if i0 is None: print(f, "never at rest"); continue
    T=t[-1]-t[i0]
    d=np.degrees(2*np.arccos(np.abs(q[i0:]@q[i0]).clip(0,1)))
    dp=np.linalg.norm(p[i0:]-p[i0],axis=1)*10
    print(f"{f.split('/')[-1]}: settled by t={t[i0]:.1f}s at tilt {tilt[i0]:.2f} deg; over the next {T:.0f} s: tilt {tilt[i0]:.3f} -> {tilt[-1]:.3f} deg "
          f"(max |change| {np.abs(tilt[i0:]-tilt[i0]).max():.3f}), total rotation {d[-1]:.3f} deg (max {d.max():.3f}) = {d[-1]/T*60:.3f} deg/min, "
          f"slide {dp[-1]:.3f} mm, angvel median {np.median(w[i0:]):.4f} deg/s")
