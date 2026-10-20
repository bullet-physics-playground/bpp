#!/usr/bin/env python3
"""Gravity's lever on the exact CAD body, for every way it can touch the table.

If the body touches the table at surface point p (from the centre of mass,
body cm) with outward normal n straight down, gravity's lever -- the
horizontal distance from the contact to the centre of mass -- is
|p - (p.n) n|. At a crease or corner the body can touch with any n in the
cone of the faces' normals there. Sampling every face (at 1.5 mm, CAD), every
edge and every corner of the STEP solid gives a table of (n, lever) pairs:
the smooth body's lever map, against which a hull's lever map is checked
(statics.py). Saved as cadlever.npz (n: unit normals in body axes, L: lever, cm).

  python3 cadlever.py GOMBOC900.STEP [OUT.npz]
"""
import sys
import numpy as np
import gmsh

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from gen_hull import mass_properties, to_body


def lever(p, n):
    return np.linalg.norm(p - np.sum(p * n, 1)[:, None] * n, axis=1)


def build(step, mesh_mm=1.5):
    _, com, _ = mass_properties(step, 1e-9)
    gmsh.initialize()
    gmsh.option.setNumber("General.Terminal", 0)
    gmsh.option.setNumber("Mesh.MeshSizeMax", mesh_mm)
    gmsh.open(step)
    gmsh.model.mesh.generate(2)

    def normals(f, X):
        uv = np.array(gmsh.model.getParametrization(2, f, X.ravel()))
        n = np.array(gmsh.model.getNormal(f, uv)).reshape(-1, 3)
        n *= np.sign(np.sum(n * (X - com), 1))[:, None]
        return to_body(n + com, com) / 0.01  # directions: same axis turn, no scale

    N, L = [], []
    for d, f in gmsh.model.getEntities(2):
        _, xyz, _ = gmsh.model.mesh.getNodes(2, f, True)
        X = xyz.reshape(-1, 3)
        n = normals(f, X)
        p = to_body(X, com)
        N.append(n)
        L.append(lever(p, n))
    # creases: along every edge, the normals between the two faces' normals
    lam = np.linspace(0, 1, 41)[:, None]
    for d, c in gmsh.model.getEntities(1):
        faces = gmsh.model.getAdjacencies(1, c)[0]
        if len(faces) < 2:
            continue
        t0, t1 = [float(b[0]) for b in gmsh.model.getParametrizationBounds(1, c)]
        Y = np.array(gmsh.model.getValue(1, c, np.linspace(t0, t1, 400))).reshape(-1, 3)
        n1, n2 = normals(faces[0], Y), normals(faces[1], Y)
        p = to_body(Y, com)
        for i in range(len(Y)):
            if n1[i] @ n2[i] > 1 - 1e-10:
                continue
            u = lam * n1[i] + (1 - lam) * n2[i]
            u /= np.linalg.norm(u, axis=1)[:, None]
            N.append(u)
            L.append(lever(np.repeat(p[i:i + 1], len(u), 0), u))
    # corners: the cone of all the faces' normals there
    rng = np.random.RandomState(0)
    for d, v in gmsh.model.getEntities(0):
        X = np.array(gmsh.model.getValue(0, v, [])).reshape(1, 3)
        faces = set()
        for c in gmsh.model.getAdjacencies(0, v)[0]:
            faces |= set(gmsh.model.getAdjacencies(1, c)[0])
        ns = np.vstack([normals(f, X) for f in sorted(faces)])
        w = rng.dirichlet(np.ones(len(ns)) * 0.5, 4000)
        u = w @ ns
        u /= np.linalg.norm(u, axis=1)[:, None]
        p = to_body(X, com)
        N.append(u)
        L.append(lever(np.repeat(p, len(u), 0), u))
    gmsh.finalize()
    return np.vstack(N), np.concatenate(L)


if __name__ == "__main__":
    N, L = build(sys.argv[1])
    out = sys.argv[2] if len(sys.argv) > 2 else "cadlever.npz"
    np.savez_compressed(out, n=N, L=L)
    print("%d (normal, lever) samples -> %s" % (len(L), out))
