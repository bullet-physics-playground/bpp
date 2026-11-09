"""Drop test in PyBullet (pip install pybullet; 3.2.7 used): each shape at 36 mm long, dropped from 30 mm
(centre of mass) in random orientations onto a flat table; after 6 s it counts as upright when its rest
normal points within 10 deg of straight down. Friction 0.4, rolling and spinning friction 0.1 mm,
restitution 0.3, step 1/2000 s. Resin 1.24 g/cm^3 (the mass does not change where it ends up).
  python3 drop.py N genomes/mono-s2.npy ...           (about 4 s a drop)"""
import sys, os, tempfile
import numpy as np, pybullet as p
import build


def run(c, n, seed=0, size=0.036):
    X, F = build.body(c); down = build.stable(X, F)[0][1]
    X = X * size / 90.0                                          # metres
    vol, com, I = build.mass(X, F)
    tf = tempfile.mktemp(suffix='.obj')
    with open(tf, 'w') as f:
        f.write(''.join('v %.9f %.9f %.9f\n' % tuple(q) for q in X) + ''.join('f %d %d %d\n' % tuple(t + 1) for t in F))
    p.connect(p.DIRECT); p.setGravity(0, 0, -9.81); p.setTimeStep(1 / 2000)
    p.createMultiBody(0, p.createCollisionShape(p.GEOM_PLANE))
    p.changeDynamics(0, -1, lateralFriction=0.4, restitution=0.3)
    cs = p.createCollisionShape(p.GEOM_MESH, fileName=tf)
    rng = np.random.default_rng(seed); tilt = []
    for k in range(n):
        q = rng.normal(size=4); q /= np.linalg.norm(q)
        b = p.createMultiBody(vol * 1240, cs, basePosition=[0, 0, 0.03], baseOrientation=q.tolist(),
                              baseInertialFramePosition=[0, 0, 0])
        p.changeDynamics(b, -1, lateralFriction=0.4, rollingFriction=1e-4, spinningFriction=1e-4, restitution=0.3,
                         localInertiaDiagonal=list(np.diag(I) * 1240))
        for s in range(2000 * 6): p.stepSimulation()
        R = np.array(p.getMatrixFromQuaternion(p.getBasePositionAndOrientation(b)[1])).reshape(3, 3)
        tilt.append(np.degrees(np.arccos(np.clip(-(R @ down)[2], -1, 1)))); p.removeBody(b)
    p.disconnect(); os.remove(tf)
    return np.array(tilt)


if __name__ == '__main__':
    n = int(sys.argv[1])
    for path in sys.argv[2:]:
        t = run(np.load(path), n)
        print(f"{os.path.basename(path)[:-4]}: upright {100 * (t < 10).mean():.0f}% of {n}, median tilt {np.median(t):.1f} deg,"
              f" others at {np.round(np.sort(t[t >= 10])).astype(int).tolist()}", flush=True)
