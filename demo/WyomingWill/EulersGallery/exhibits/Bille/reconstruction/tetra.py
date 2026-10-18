"""Statics of a tetrahedron with arbitrary centre of mass O on a horizontal plane.

Faces are named by the opposite vertex (face 'D' = triangle ABC).  For each face
F we find what happens when the body is put down on F (quasi-static rolling,
i.e. steepest descent of the potential = height of O):

  * the foot P of O on F's plane lies inside F  -> F is a stable face (sink)
  * P's nearest point on F is inside an edge e  -> it tips over e onto the
    other face containing e
  * P's nearest point on F is a vertex v        -> it pivots on v (descent in
    v's region of the Gauss sphere), meets the arc of the edge v-l (l = 4th
    vertex), and slides along that arc to one of its two faces.

successors(V, O) -> int array (N, 4): for each face, -1 if stable, else the face
it rolls onto first.  Vectorised over many O.
"""
import numpy as np

NAMES = "ABCD"


def face_normals(V):
    """outward unit normals; face f is opposite vertex f"""
    N = np.zeros((4, 3))
    for f in range(4):
        i, j, k = [x for x in range(4) if x != f]
        n = np.cross(V[j] - V[i], V[k] - V[i])
        n /= np.linalg.norm(n)
        if np.dot(V[f] - V[i], n) > 0:
            n = -n
        N[f] = n
    return N


def _closest_region(a, b, c, p):
    """Ericson's closest-point-on-triangle regions, vectorised.
    returns region code: 0 inside, 1/2/3 vertex a/b/c, 4 edge ab, 5 edge ac, 6 edge bc"""
    ab, ac = b - a, c - a
    ap = p - a
    d1, d2 = ap @ ab, ap @ ac
    bp = p - b
    d3, d4 = bp @ ab, bp @ ac
    cp = p - c
    d5, d6 = cp @ ab, cp @ ac
    vc = d1 * d4 - d3 * d2
    vb = d5 * d2 - d1 * d6
    va = d3 * d6 - d5 * d4
    reg = np.zeros(len(p), dtype=int)
    done = np.zeros(len(p), dtype=bool)
    for code, m in [(1, (d1 <= 0) & (d2 <= 0)),
                    (2, (d3 >= 0) & (d4 <= d3)),
                    (4, (vc <= 0) & (d1 >= 0) & (d3 <= 0)),
                    (3, (d6 >= 0) & (d5 <= d6)),
                    (5, (vb <= 0) & (d2 >= 0) & (d6 <= 0)),
                    (6, (va <= 0) & ((d4 - d3) >= 0) & ((d5 - d6) >= 0))]:
        mm = m & ~done
        reg[mm] = code
        done |= mm
    return reg


def successors(V, O):
    V = np.asarray(V, float)
    O = np.atleast_2d(np.asarray(O, float))
    N = face_normals(V)
    out = np.full((len(O), 4), -9, dtype=int)
    for f in range(4):
        i, j, k = [x for x in range(4) if x != f]
        n = N[f]
        P = O - ((O - V[i]) @ n)[:, None] * n
        reg = _closest_region(V[i], V[j], V[k], P)
        res = np.full(len(O), -9, dtype=int)
        res[reg == 0] = -1
        # edges: tip over edge (x,y) onto face opposite the third vertex z of F
        res[reg == 4] = k      # edge ab = (i,j): third vertex k
        res[reg == 5] = j      # edge ac = (i,k)
        res[reg == 6] = i      # edge bc = (j,k)
        # vertex cases
        for code, v in [(1, i), (2, j), (3, k)]:
            m = reg == code
            if not m.any():
                continue
            l = f                                # the 4th vertex (not on F)
            x1, x2 = [x for x in (i, j, k) if x != v]
            Pm, Om = P[m], O[m]
            d = Pm - V[v]
            d /= np.linalg.norm(d, axis=1)[:, None]
            a = np.dot(V[l] - V[v], n)           # < 0
            b = d @ (V[l] - V[v])
            th = np.arctan2(-a, b)               # in (0, pi) when b > 0
            u = np.cos(th)[:, None] * n + np.sin(th)[:, None] * d
            e = V[l] - V[v]
            e /= np.linalg.norm(e)
            w = V[v] - Om
            g = w - np.sum(w * u, 1)[:, None] * u - (w @ e)[:, None] * e
            s1 = np.sum((N[x1] - u) * (-g), 1)   # face opposite x1 contains v,l,x2
            s2 = np.sum((N[x2] - u) * (-g), 1)
            res[m] = np.where(s1 > s2, x1, x2)
        out[:, f] = res
    return out


def pattern_str(s):
    """e.g. 'A->B->D<-C' style: list of arrows 'X->Y' plus sinks"""
    parts = []
    for f in range(4):
        parts.append(f"{NAMES[f]}*" if s[f] == -1 else f"{NAMES[f]}->{NAMES[s[f]]}")
    return " ".join(parts)


def volume(V):
    return abs(np.dot(V[1] - V[0], np.cross(V[2] - V[0], V[3] - V[0]))) / 6


def sample_in_tetra(V, n, rng):
    """uniform points in tetrahedron"""
    r = rng.random((n, 3))
    r.sort(axis=1)
    w = np.column_stack([r[:, 0], r[:, 1] - r[:, 0], r[:, 2] - r[:, 1], 1 - r[:, 2]])
    return w @ V


def dihedral_angles(V):
    """interior dihedral angle (deg) at each edge (i,j)"""
    N = face_normals(V)
    out = {}
    for i in range(4):
        for j in range(i + 1, 4):
            f1, f2 = [x for x in range(4) if x not in (i, j)]
            # faces containing edge (i,j) are those opposite the other two vertices
            ang = np.degrees(np.pi - np.arccos(np.clip(N[f1] @ N[f2], -1, 1)))
            out[NAMES[i] + NAMES[j]] = ang
    return out
