/**
 * @file demcore.cpp
 * @brief The shaken bed of beads, by discrete elements: bead-bed.c's physics
 * as a class (see demcore.h).
 *
 * Everything between "bead-bed.c, unchanged" and "end of bead-bed.c" is
 * bead-bed.c's own code (demo/WyomingWill/BrazilNut/reconstruction/), its
 * globals made members, its printf()s going to the test output; it was
 * lifted mechanically (reconstruction/port/) and must stay that way: the
 * numbers depend on every operation's order. The frame loop after it is
 * bead-bed.c's main loop, cut into substeps.
 */

#include "demcore.h"

#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// (bead-bed.c's names)
#define G 981.0
#define MAXB DEM_MAXB
#define MAXC DEM_MAXC
#define RHO 0.0025
#define R_S 0.5
#define FLOOR (-1)
#define LWALL (-2)
#define RWALL (-3)
#define FRONT (-4)
#define BACK (-5)
#define CS 1.1
#define NCXMAX DEM_NCXMAX
#define NCY DEM_NCY
#define MAXG DEM_MAXG
#define SX(nn, aa) (tw == 2 ? (aa) : tw == 0 ? -W_IN / 2 + (nn) : W_IN / 2 - (nn))
#define SY(nn, aa) (tw == 2 ? (nn) : (aa))
#define DX(nn, aa) (tw == 2 ? (aa) : tw == 0 ? (nn) : -(nn))
#define DY(nn, aa) (tw == 2 ? (nn) : (aa))

using std::sqrt;

DemCore::DemCore() {
  // (bead-bed.c's globals start at zero)
  memset(x, 0, sizeof x); memset(v, 0, sizeof v); memset(w, 0, sizeof w);
  memset(f, 0, sizeof f); memset(tq, 0, sizeof tq);
  memset(a_old, 0, sizeof a_old); memset(al_old, 0, sizeof al_old);
  memset(rad, 0, sizeof rad); memset(mass, 0, sizeof mass); memset(inert, 0, sizeof inert);
  memset(hist, 0, sizeof hist); memset(nh, 0, sizeof nh);
  memset(cellHead, 0, sizeof cellHead); memset(cellNext, 0, sizeof cellNext);
  memset(vp, 0, sizeof vp); memset(wp, 0, sizeof wp);
  memset(nG, 0, sizeof nG); memset(gc, 0, sizeof gc); memset(gd, 0, sizeof gd); memset(gc0, 0, sizeof gc0);
  memset(pushSum, 0, sizeof pushSum); memset(vrelSum, 0, sizeof vrelSum); memset(pushN, 0, sizeof pushN);
  memset(pushSumG, 0, sizeof pushSumG); memset(vrelSumG, 0, sizeof vrelSumG); memset(pushNG, 0, sizeof pushNG);
  memset(lastP, 0, sizeof lastP);
  memset(riseBuf, 0, sizeof riseBuf);
  nContacts = 0; sumOverlap = maxOverlap = 0; SQKT = SQKN = 0; zetaLow = 0;
  zetaBB = zetaBW = zetaG = 0; lseed = 0;
}

void DemCore::out(const char *fmt, ...) {
  char buf[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(buf, sizeof buf, fmt, ap);
  va_end(ap);
  outBuf += buf;
}

// ---------------------------------------------------------------------
// bead-bed.c, unchanged
// ---------------------------------------------------------------------
static double dot(const double *a, const double *b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
static void cross(const double *a, const double *b, double *c)
{
  c[0] = a[1] * b[2] - a[2] * b[1];
  c[1] = a[2] * b[0] - a[0] * b[2];
  c[2] = a[0] * b[1] - a[1] * b[0];
}

/* ---------- the normal law, and its damping found from e ---------- */
/* nondimensional collision: m = 1, k = 1, closing at 1: returns e */
static double collide_e(int model, double damp)
{
  double d = 0, dd = 1, h = 1e-4;
  for (int it = 0; it < 10000000; it++) {
    /* RK4 */
    double k1d = dd, k1v, k2d, k2v, k3d, k3v, k4d, k4v, F;
#define ACC(D, DD) (model == 0 ? -((D) + 2 * damp * (DD)) : -(pow(fmax(D, 0), 1.5) + damp * pow(fmax(D, 0), 0.25) * (DD)))
    k1v = ACC(d, dd);
    k2d = dd + 0.5 * h * k1v; k2v = ACC(d + 0.5 * h * k1d, dd + 0.5 * h * k1v);
    k3d = dd + 0.5 * h * k2v; k3v = ACC(d + 0.5 * h * k2d, dd + 0.5 * h * k2v);
    k4d = dd + h * k3v;       k4v = ACC(d + h * k3d, dd + h * k3v);
    d += h / 6 * (k1d + 2 * k2d + 2 * k3d + k4d);
    dd += h / 6 * (k1v + 2 * k2v + 2 * k3v + k4v);
    F = -ACC(d, dd);
    if (it > 10 && (F <= 0 || d <= 0)) return -dd;
  }
  return -dd;
}
static double damping_for(int model, double e)
{
  double lo = 0, hi = 50;   /* (the clamped law goes below e = 0.14 only overdamped: e(z=1) = 0.135, e(z=4.8) = 0.01) */
  for (int k = 0; k < 60; k++) {
    double mid = 0.5 * (lo + hi);
    if (collide_e(model, mid) > e) lo = mid; else hi = mid;
  }
  return 0.5 * (lo + hi);
}

/* ---------- one contact: i against j (j >= 0) or a wall ---------- */

double *DemCore::findHist(int i, int j)
{
  int o = 1 - cur;
  for (int k = 0; k < nh[o][i]; k++) if (hist[o][i][k].j == j) return hist[o][i][k].s;
  return NULL;
}

/* n: unit normal from the partner toward i; d: overlap; ai, aj: lever arms
 * from the centres to the contact point; vj, wj: partner velocity and spin
 * (walls: their velocity, no spin); mu: friction; e: which restitution */
/* the same contact in the plane (PLATES=0, ROLL=0): n = (nx, ny), spins
 * about z only, the tangent t = (-ny, nx); the spring kept as a vector as
 * in 3-D (turned onto the new tangent, its length kept) -- the same
 * arithmetic with the zero components left out */
void DemCore::contact2(int i, int j, const double *n, double d, double ai, double aj,
                     const double *vi, const double *wi, const double *vj, const double *wj,
                     double meff, double reff, double mu, double zeta)
{
  double tx = -n[1], ty = n[0];
  double om = ai * wi[2] + aj * wj[2];
  double vrx = vi[0] - vj[0] - om * tx, vry = vi[1] - vj[1] - om * ty;
  double vn = vrx * n[0] + vry * n[1], vt = vrx * tx + vry * ty;
  double Fn, cn, kt;
  int o = 1 - cur;
  Hist *oh = NULL;
  for (int k = 0; k < nh[o][i]; k++)
    if (hist[o][i][k].j == j) { oh = &hist[o][i][k]; break; }
  /* (ETH: the closing speed at first touch, kept in the history's third slot) */
  double vimp = oh ? oh->s[2] : -vn;
  if (ETH > 0 && vimp < ETH) zeta = zetaLow;
  if (MODEL == 0) {
    cn = 2 * zeta * sqrt(meff) * SQKN;
    Fn = KN * d - cn * vn;
    kt = KT * KN;
  } else {
    double Kh = 4.0 / 3.0 * (YM * 1e-2 / (2 * (1 - NU * NU))) * sqrt(reff);
    double sd = sqrt(d);
    cn = zeta * sqrt(meff * Kh) * sqrt(sd);
    Fn = Kh * d * sd - cn * vn;
    kt = KT * 1.5 * Kh * sd;
  }
  if (Fn < 0) Fn = 0;
  double ct = cn * SQKT, s = 0;
  if (oh) {
    double *old = oh->s, st = old[0] * tx + old[1] * ty;
    double s0 = sqrt(old[0] * old[0] + old[1] * old[1]);
    s = st > 0 ? s0 : st < 0 ? -s0 : 0;
  }
  s += vt * DT;
  double ft = -kt * s - ct * vt, lim = mu * Fn;
  if (fabs(ft) > lim) {
    ft = ft > 0 ? lim : -lim;
    s = kt > 0 ? -(ft + ct * vt) / kt : 0;
  }
  if (nh[cur][i] < MAXC) {
    Hist *hh = &hist[cur][i][nh[cur][i]++];
    hh->j = j;
    hh->s[0] = s * tx; hh->s[1] = s * ty; hh->s[2] = vimp;
  }
  double Fx = Fn * n[0] + ft * tx, Fy = Fn * n[1] + ft * ty;
  f[i][0] += Fx; f[i][1] += Fy; tq[i][2] -= ai * ft;
  if (j >= 0) { f[j][0] -= Fx; f[j][1] -= Fy; tq[j][2] -= aj * ft; }
  nContacts++;
  sumOverlap += d / reff;
  if (d / reff > maxOverlap) maxOverlap = d / reff;
}

void DemCore::contact(int i, int j, const double *n, double d, double ai, double aj,
                    const double *vi, const double *wi, const double *vj, const double *wj,
                    double meff, double reff, double mu, double zeta)
{
  if (LOCKZ && ROLL == 0 && !FORCE3D) contact2(i, j, n, d, ai, aj, vi, wi, vj, wj, meff, reff, mu, zeta);
  else contact3(i, j, n, d, ai, aj, vi, wi, vj, wj, meff, reff, mu, zeta);
}

void DemCore::contact3(int i, int j, const double *n, double d, double ai, double aj,
                     const double *vi, const double *wi, const double *vj, const double *wj,
                     double meff, double reff, double mu, double zeta)
{
  double vr[3], t1[3], t2[3], vn, vt[3], Fn, kn, cn, kt, ct, Ft[3], s[3], ftr[3];
  /* relative velocity of i's contact point against j's */
  cross(wi, n, t1);
  cross(wj, n, t2);
  for (int k = 0; k < 3; k++) vr[k] = vi[k] - vj[k] - ai * t1[k] - aj * t2[k];
  vn = dot(vr, n);
  for (int k = 0; k < 3; k++) vt[k] = vr[k] - vn * n[k];
  if (MODEL == 0) {
    kn = KN;
    cn = 2 * zeta * sqrt(meff * KN);
    Fn = kn * d - cn * vn;
    kt = KT * KN;
  } else {
    double Kh = 4.0 / 3.0 * (YM * 1e-2 / (2 * (1 - NU * NU))) * sqrt(reff);
    double sd = sqrt(d);
    cn = zeta * sqrt(meff * Kh) * sqrt(sd);   /* zeta here is Tsuji's alpha */
    Fn = Kh * d * sd - cn * vn;
    kn = 1.5 * Kh * sd;
    kt = KT * kn;
  }
  if (Fn < 0) Fn = 0;
  ct = cn * sqrt(KT);
  /* the tangential spring: from the last step, turned into the tangent plane */
  double *old = findHist(i, j);
  if (old) {
    double s0 = sqrt(dot(old, old)), sn = dot(old, n);
    for (int k = 0; k < 3; k++) s[k] = old[k] - sn * n[k];
    double s1 = sqrt(dot(s, s));
    if (s1 > 0) for (int k = 0; k < 3; k++) s[k] *= s0 / s1;
  } else s[0] = s[1] = s[2] = 0;
  for (int k = 0; k < 3; k++) { s[k] += vt[k] * DT; ftr[k] = -kt * s[k] - ct * vt[k]; }
  double ft = sqrt(dot(ftr, ftr)), lim = mu * Fn;
  if (ft > lim) {
    double sc = ft > 0 ? lim / ft : 0;
    for (int k = 0; k < 3; k++) {
      Ft[k] = ftr[k] * sc;
      s[k] = kt > 0 ? -(Ft[k] + ct * vt[k]) / kt : 0;
    }
  } else for (int k = 0; k < 3; k++) Ft[k] = ftr[k];
  /* store the spring */
  if (nh[cur][i] < MAXC) {
    Hist *hh = &hist[cur][i][nh[cur][i]++];
    hh->j = j;
    memcpy(hh->s, s, sizeof s);
  }
  /* forces and torques */
  double F[3], c[3];
  for (int k = 0; k < 3; k++) F[k] = Fn * n[k] + Ft[k];
  cross(n, Ft, c);
  for (int k = 0; k < 3; k++) { f[i][k] += F[k]; tq[i][k] -= ai * c[k]; }
  if (j >= 0) for (int k = 0; k < 3; k++) { f[j][k] -= F[k]; tq[j][k] -= aj * c[k]; }
  /* rolling resistance */
  if (ROLL > 0) {
    double wr[3], m = 0;
    for (int k = 0; k < 3; k++) wr[k] = wi[k] - wj[k];
    m = sqrt(dot(wr, wr));
    if (m > 0) {
      double T = ROLL * reff * Fn * fmin(1, m / 0.5) / m;
      for (int k = 0; k < 3; k++) { tq[i][k] -= T * wr[k]; if (j >= 0) tq[j][k] += T * wr[k]; }
    }
  }
  nContacts++;
  sumOverlap += d / reff;
  if (d / reff > maxOverlap) maxOverlap = d / reff;
}

/* ---------- forces ---------- */

/* the glued spheres, in the box's frame: side walls (0 left, 1 right) and
 * the floor (2); gc along the wall (y for the sides, x for the floor), gd
 * the centre's distance inside the wall's face (negative: behind it) */
static double hash01(unsigned a)
{
  a ^= a >> 16; a *= 0x7feb352dU; a ^= a >> 15; a *= 0x846ca68bU; a ^= a >> 16;
  return (a & 0xffffff) / 16777215.0;
}
void DemCore::makeGlued(void)
{
  for (int w = 0; w < 3; w++) {
    nG[w] = 0;
    if (!ROUGH || (w == 2 && !ROUGHF)) continue;
    double len = w < 2 ? H_IN + 2 : W_IN;
    gc0[w] = w < 2 ? 0.5 * SG : -W_IN / 2 + 0.5 * SG;
    for (int k = 0; gc0[w] + k * SG < (w < 2 ? len : W_IN / 2) && k < MAXG; k++) {
      gc[w][k] = gc0[w] + k * SG + GJIT * SG * (hash01(7919u * k + 104729u * w + 1) - 0.5);
      gd[w][k] = RG * (1 - 2 * GEMB) + GJIT * RG * (hash01(7919u * k + 104729u * w + 2) - 0.5);
      nG[w] = k + 1;
    }
  }
}
/* how far the lining reaches into the box: the most a glued sphere stands
 * out of the wall's face */
double DemCore::gluedReach(void) { return ROUGH ? RG * (2 - 2 * GEMB) + GJIT * RG / 2 : 0; }

void DemCore::gluedForces(int i, const double *vb)
{
  static const double zero[3] = { 0, 0, 0 };
  double r = rad[i], reach = r + RG + GJIT * RG / 2;
  for (int w = 0; w < 3; w++) {
    if (!nG[w]) continue;
    /* the bead's distance from the wall's face (inside), and along it */
    double dn = w == 0 ? x[i][0] + W_IN / 2 : w == 1 ? W_IN / 2 - x[i][0] : x[i][1] - boxy;
    if (dn > gluedReach() + r) continue;
    double along = w < 2 ? x[i][1] - boxy : x[i][0];
    int k0 = (int)floor((along - reach - gc0[w]) / SG) - 1, k1 = (int)ceil((along + reach - gc0[w]) / SG) + 1;
    if (k0 < 0) k0 = 0;
    if (k1 >= nG[w]) k1 = nG[w] - 1;
    for (int k = k0; k <= k1; k++) {
      double ga = gc[w][k] - along, gn = gd[w][k] - dn;   /* glued centre relative to the bead: along, inward normal */
      double dist2 = ga * ga + gn * gn, R = r + RG;
      if (dist2 >= R * R) continue;
      double dist = sqrt(dist2), d = R - dist, n[3];
      /* n from the glued sphere toward the bead, in the box's x, y */
      double ua = -ga / dist, un = -gn / dist;
      if (w == 0) { n[0] = un; n[1] = ua; }
      else if (w == 1) { n[0] = -un; n[1] = ua; }
      else { n[0] = ua; n[1] = un; }
      n[2] = 0;
      contact(i, -100 - (w * 100000 + k), n, d, r - d / 2, RG - d / 2, vp[i], wp[i], vb, zero, mass[i], r * RG / R, MUG, zetaG);
    }
  }
}

void DemCore::pairForce(int i, int j)
{
  double dxv[3], dist2, R = rad[i] + rad[j];
  for (int k = 0; k < 3; k++) dxv[k] = x[i][k] - x[j][k];
  dist2 = dot(dxv, dxv);
  if (dist2 >= R * R) return;
  double dist = sqrt(dist2), n[3], d = R - dist;
  for (int k = 0; k < 3; k++) n[k] = dxv[k] / dist;
  double meff = mass[i] * mass[j] / (mass[i] + mass[j]);
  double reff = rad[i] * rad[j] / R;
  /* store the history on the lower index */
  if (i < j) contact(i, j, n, d, rad[i] - d / 2, rad[j] - d / 2, vp[i], wp[i], vp[j], wp[j], meff, reff, MUB, zetaBB);
  else {
    double m2[3] = { -n[0], -n[1], -n[2] };
    contact(j, i, m2, d, rad[j] - d / 2, rad[i] - d / 2, vp[j], wp[j], vp[i], wp[i], meff, reff, MUB, zetaBB);
  }
}

void DemCore::forces(void)
{
  static const double zero[3] = { 0, 0, 0 };
  for (int i = 0; i < N; i++) {
    nh[cur][i] = 0;
    for (int k = 0; k < 3; k++) {
      f[i][k] = mass[i] * gvec[k];
      tq[i][k] = 0;
      vp[i][k] = v[i][k] + 0.5 * DT * a_old[i][k];
      wp[i][k] = w[i][k] + 0.5 * DT * al_old[i][k];
    }
  }
  /* cell list of the small beads, in the box's frame */
  for (int c = 0; c < NCX * NCY; c++) cellHead[c] = -1;
  int cellOf[MAXB];
  for (int i = 0; i < N; i++) {
    if (BIG && i == N - 1) { cellOf[i] = -1; continue; }
    int cx = (int)floor((x[i][0] + W_IN / 2) / CS), cy = (int)floor((x[i][1] - boxy + 2) / CS);
    if (cx < 0) cx = 0;
    if (cx >= NCX) cx = NCX - 1;
    if (cy < 0) cy = 0;
    if (cy >= NCY) cy = NCY - 1;
    cellOf[i] = cx + NCX * cy;
    cellNext[i] = cellHead[cellOf[i]];
    cellHead[cellOf[i]] = i;
  }
  for (int i = 0; i < N; i++) {
    if (cellOf[i] < 0) continue;
    int cx = cellOf[i] % NCX, cy = cellOf[i] / NCX;
    for (int dy = -1; dy <= 1; dy++) {
      int yy = cy + dy;
      if (yy < 0 || yy >= NCY) continue;
      for (int dx = -1; dx <= 1; dx++) {
        int xx = cx + dx;
        if (xx < 0 || xx >= NCX) continue;
        for (int j = cellHead[xx + NCX * yy]; j >= 0; j = cellNext[j])
          if (j > i) pairForce(i, j);
      }
    }
  }
  if (BIG) for (int i = 0; i < N - 1; i++) pairForce(i, N - 1);
  /* walls: the floor, the side walls, the plates */
  double vb[3] = { 0, boxv, 0 };
  for (int i = 0; i < N; i++) {
    double r = rad[i], m = mass[i], d;
    if (floorTilt == 0) {
      d = r - (x[i][1] - boxy);
      if (d > 0) { double n[3] = { 0, 1, 0 }; contact(i, FLOOR, n, d, r - d, 0, vp[i], wp[i], vb, zero, m, r, MUF, zetaBW); }
    } else {
      /* (tests) a floor tilted by floorTilt about z, through the origin */
      double n[3] = { -sin(floorTilt), cos(floorTilt), 0 };
      d = r - dot(x[i], n);
      if (d > 0) contact(i, FLOOR, n, d, r - d, 0, vp[i], wp[i], zero, zero, m, r, MUF, zetaBW);
      continue;
    }
    d = r - (x[i][0] + W_IN / 2);
    if (d > 0) { double n[3] = { 1, 0, 0 }; contact(i, LWALL, n, d, r - d, 0, vp[i], wp[i], vb, zero, m, r, MUW, zetaBW); }
    d = r - (W_IN / 2 - x[i][0]);
    if (d > 0) { double n[3] = { -1, 0, 0 }; contact(i, RWALL, n, d, r - d, 0, vp[i], wp[i], vb, zero, m, r, MUW, zetaBW); }
    if (ROUGH) gluedForces(i, vb);
    if (PLATES) {
      d = r - (x[i][2] + GAP / 2);
      if (d > 0) { double n[3] = { 0, 0, 1 }; contact(i, BACK, n, d, r - d, 0, vp[i], wp[i], vb, zero, m, r, MUP, zetaBW); }
      d = r - (GAP / 2 - x[i][2]);
      if (d > 0) { double n[3] = { 0, 0, -1 }; contact(i, FRONT, n, d, r - d, 0, vp[i], wp[i], vb, zero, m, r, MUP, zetaBW); }
    }
  }
}

void DemCore::step(void)
{
  for (int i = 0; i < N; i++)
    for (int k = 0; k < 3; k++) {
      v[i][k] += 0.5 * DT * a_old[i][k];
      w[i][k] += 0.5 * DT * al_old[i][k];
      x[i][k] += DT * v[i][k];
    }
  cur = 1 - cur;
  forces();
  for (int i = 0; i < N; i++) {
    for (int k = 0; k < 3; k++) {
      a_old[i][k] = f[i][k] / mass[i];
      al_old[i][k] = tq[i][k] / inert[i];
      if (LOCKZ && k == 2) a_old[i][k] = 0;
      if (LOCKZ && k < 2) al_old[i][k] = 0;
      v[i][k] += 0.5 * DT * a_old[i][k];
      w[i][k] += 0.5 * DT * al_old[i][k];
    }
  }
}

double DemCore::meanSmallMass(void) { return RHO * 4.0 / 3.0 * M_PI * R_S * R_S * R_S; }

/* set k (MODEL 0) and DT from TC */
void DemCore::setStiffness(void)
{
  double m = meanSmallMass(), meff = m / 2;
  zetaBB = damping_for(MODEL, EB);
  zetaBW = damping_for(MODEL, EW);
  zetaG = damping_for(MODEL, EG);
  zetaLow = damping_for(MODEL, ELOW);
  if (MODEL == 0) {
    KN = meff * (M_PI / TC) * (M_PI / TC);
    DT = TC / NS;
  } else {
    /* Hertz: the contact time of two small beads closing at the shaker's top
     * speed (elastic), e.g. Johnson, Contact Mechanics (1985) */
    double Es = YM * 1e-2 / (2 * (1 - NU * NU)), reff = R_S / 2, vref = AMP > 0 ? AMP * OMEGA : 50;
    TC = 2.868 * pow(meff * meff / (reff * Es * Es * vref), 0.2);
    DT = TC / NS;
  }
  SQKT = sqrt(KT);
  SQKN = sqrt(KN);
}

/* ---------- the lua's own random numbers (Lua 5.1 doubles) ---------- */
double DemCore::lrnd(void)
{
  double a = lseed * 1103515245.0 + 12345.0;
  lseed = a - floor(a / 2147483648.0) * 2147483648.0;
  return lseed / 2147483648.0;
}
double DemCore::smallR(int i) { return R_S * (1 - POLY / 2 + POLY * ((i * 37) % 100) / 99.0); }

/* pour the three boxes as the lua does; keep box `which` (0 left, 1 middle, 2 right) */
void DemCore::pour(int which)
{
  double RMAX = (1 + POLY / 2) * R_S;
  int big[3] = { 1, 1, 0 };
  /* (lined walls: poured inside the lining; ROUGHF: above it) */
  double WP = W_IN - 2 * gluedReach(), Y0 = ROUGHF ? gluedReach() : 0;
  lseed = SEED;
  for (int b = 0; b < 3; b++) {
    double rs = big[b] ? R_B : R_S;
    int k = 0, row = 0;
    double px[MAXB], py[MAXB];
    while (k < NSM) {
      double y = Y0 + RMAX + 0.02 + row * 2.02 * RMAX;
      int nper = (int)floor(WP / (2.1 * RMAX));
      for (int c = 0; c < nper; c++) {
        if (k >= NSM) break;
        double xx = -WP / 2 + RMAX + 0.05 + c * 2.1 * RMAX + (row % 2) * 0.5 * RMAX + (lrnd() - 0.5) * 0.05;
        if (xx < WP / 2 - RMAX - 0.02 && (fabs(xx) > rs + RMAX + 0.05 || y > Y0 + 2 * rs + RMAX + 0.05)) {
          px[k] = xx; py[k] = y; k++;
        }
      }
      row++;
    }
    if (b == which) {
      N = NSM + 1;
      for (int i = 0; i < NSM; i++) {
        rad[i] = smallR(i + 1);
        x[i][0] = px[i]; x[i][1] = py[i]; x[i][2] = 0;
      }
      rad[N - 1] = rs;
      x[N - 1][0] = 0; x[N - 1][1] = Y0 + rs + 0.01; x[N - 1][2] = 0;
    }
  }
  for (int i = 0; i < N; i++) {
    mass[i] = (BIG && i == N - 1 ? RHOB : RHO) * 4.0 / 3.0 * M_PI * rad[i] * rad[i] * rad[i];
    inert[i] = 0.4 * mass[i] * rad[i] * rad[i];
    for (int k = 0; k < 3; k++) v[i][k] = w[i][k] = a_old[i][k] = al_old[i][k] = 0;
    if (PLATES) {
      /* (a small random offset across the gap, from a separate generator) */
      x[i][2] = (GAP / 2 - rad[i]) * (2 * ((i * 7919 + SEED * 104729) % 1000) / 999.0 - 1);
    }
  }
  nh[0][0] = 0;
  memset(nh, 0, sizeof nh);
}

/* ---------- validation tests ---------- */
void DemCore::testDrop(void)
{
  /* a bead dropped on the floor (or, TEST=pair, two beads closing head on,
   * no gravity): the restitution it gives back, by impact speed */
  int pair = !strcmp(TEST, "pair");
  double speeds[] = { 1, 5, 20, 67, 200 };
  out("# TEST=%s MODEL=%d E=%g (nominal) TC=%g NS=%d: measured e by closing speed\n", TEST, MODEL, pair ? EB : EW, TC, NS);
  for (int s = 0; s < 5; s++) {
    double vin = speeds[s];
    BIG = 0; LOCKZ = 1; AMP = 0; boxy = 0; boxv = 0;
    N = pair ? 2 : 1;
    for (int i = 0; i < N; i++) {
      rad[i] = R_S; mass[i] = meanSmallMass(); inert[i] = 0.4 * mass[i] * R_S * R_S;
      for (int k = 0; k < 3; k++) x[i][k] = v[i][k] = w[i][k] = a_old[i][k] = al_old[i][k] = 0;
    }
    memset(nh, 0, sizeof nh);
    if (pair) {
      gvec[1] = 0;
      x[0][0] = -R_S - 1e-6; x[1][0] = R_S + 1e-6 + 0.0;
      x[1][1] = 50;  /* (far from the floor) */
      x[0][1] = 50;
      v[0][0] = vin / 2; v[1][0] = -vin / 2;
    } else {
      gvec[1] = 0;   /* no gravity in the collision itself: e alone */
      x[0][1] = R_S + 1e-6; v[0][1] = -vin;
    }
    double tcol = 0, vout = 0;
    int touching = 0, done = 0;
    for (long it = 0; it < 100000000 && !done; it++) {
      step();
      int now = (pair ? fabs(x[1][0] - x[0][0]) < 2 * R_S : x[0][1] < R_S);
      if (now) { touching = 1; tcol += DT; }
      if (touching && !now) { done = 1; vout = pair ? (v[1][0] - v[0][0]) : v[0][1]; }
    }
    out("  closing %6.1f cm/s: e = %.4f, contact %.3g s (%.1f steps)\n", vin, vout / vin, tcol, tcol / DT);
    gvec[1] = -G;
  }
}

void DemCore::testIncline(void)
{
  /* a bead on a floor tilted TH degrees (MUF its friction): free to roll,
   * and with its spin locked (it must slide, or stick). Rolling without
   * slipping holds for tan TH <= 3.5 mu (a = 5/7 g sin TH); a locked bead
   * sticks for tan TH <= mu (a = 0), else a = g (sin - mu cos). */
  out("# TEST=incline MODEL=%d MU=%g TC=%g NS=%d: tan(th)/mu, acceleration/g, slip speed at the contact after 0.3 s\n", MODEL, MUF, TC, NS);
  double ths[] = { 0.5, 0.9, 0.99, 1.01, 1.1, 2.0, 3.3, 3.45, 3.55, 3.7, 5 };
  for (int lock = 0; lock <= 1; lock++) {
    for (int s = 0; s < 11; s++) {
      double th = atan(ths[s] * MUF);
      BIG = 0; LOCKZ = 1; AMP = 0; N = 1;
      rad[0] = R_S; mass[0] = meanSmallMass(); inert[0] = (lock ? 1e30 : 0.4 * mass[0] * R_S * R_S);
      memset(nh, 0, sizeof nh);
      floorTilt = th;
      double n[3] = { -sin(th), cos(th), 0 }, tdir[3] = { cos(th), sin(th), 0 };
      for (int k = 0; k < 3; k++) { x[0][k] = (R_S - mass[0] * G * cos(th) / (MODEL == 0 ? KN : 1e30)) * n[k]; v[0][k] = w[0][k] = a_old[0][k] = al_old[0][k] = 0; }
      /* let it seat for 0.05 s with gravity normal only, then tilt gravity in */
      double t = 0, v1 = 0, t1 = 0.1, t2 = 0.4;
      gvec[0] = 0; gvec[1] = -G;
      /* gravity vertical, floor tilted: down the slope is -tdir */
      double slip = 0;
      for (t = 0; t < t2; t += DT) {
        step();
        if (fabs(t - t1) < DT / 2) v1 = dot(v[0], tdir);
      }
      double v2 = dot(v[0], tdir);
      double acc = (v2 - v1) / (t2 - t1);
      /* contact point speed: v + w x (-R n) */
      double c[3], rn[3] = { -R_S * n[0], -R_S * n[1], 0 };
      cross(w[0], rn, c);
      double vc[3] = { v[0][0] + c[0], v[0][1] + c[1], 0 };
      slip = dot(vc, tdir);
      double sn = sin(th), cs = cos(th);
      double expect = lock ? (ths[s] <= 1 ? 0 : G * (sn - MUF * cs)) : (ths[s] <= 3.5 ? 5.0 / 7.0 * G * sn : G * (sn - MUF * cs));
      out("  %s tan/mu %.2f: a/g = %.5f (theory %.5f), contact slip %.4f cm/s\n", lock ? "spin locked" : "free      ",
             ths[s], -acc / G, expect / G, -slip);
    }
  }
  floorTilt = 0;
}

void DemCore::testGlued(void)
{
  /* the glued spheres (ROUGH=1 ROUGHF=1: the floor lined; GJIT=0):
   * gdrop: a bead closing head-on on one glued sphere, no gravity: the
   *   restitution it gives back, and the contact time against Hertz's
   *   2.868 (m^2 / (R E*^2 v))^(1/5) (m the bead's mass, R = r RG / (r + RG));
   * ghollow: a bead seated in the hollow between two glued spheres SG apart,
   *   then gravity tilted by TH: free to spin, it must roll out over the
   *   downhill sphere once TH passes alpha = asin(SG / 2 / (r + RG))
   *   (friction can't hold it: the two tangential forces must cancel in
   *   torque, which leaves them only a force along the hollow's axis, while
   *   MUG < cot alpha); spin locked, it holds until alpha + atan(MUG). Also its
   *   seat height against the geometry's. */
  /* (TW: the lined surface tested, 2 the floor, 0 the left wall, 1 the
   * right; gravity then points into that surface, tilted along it) */
  if (!ROUGH || !ROUGHF || nG[2] < 3) { out("TEST=gdrop|ghollow needs ROUGH=1 ROUGHF=1\n"); return; }
  int tw = TW, k = 0;
  double mid = tw == 2 ? 0 : 8;
  for (int q = 0; q < nG[tw]; q++) if (fabs(gc[tw][q] - mid) < fabs(gc[tw][k] - mid)) k = q;
  if (k + 1 >= nG[tw]) k--;
  /* a point (normal n, along a) of surface tw in the box's x, y; a direction too */
  double r = R_S, m = meanSmallMass(), Rr = r + RG;
  BIG = 0; LOCKZ = 1; AMP = 0; N = 1; boxy = 0; boxv = 0;
  if (!strcmp(TEST, "gdrop")) {
    double Es = YM * 1e-2 / (2 * (1 - NU * NU)), reff = r * RG / Rr;
    double speeds[] = { 1, 5, 20, 67, 200 };
    out("# TEST=gdrop MODEL=%d RG %.3f EG %.3g NS %d DT %.3g: e and contact time by closing speed\n", MODEL, RG, EG, NS, DT);
    for (int q = 0; q < 5; q++) {
      double vin = speeds[q];
      rad[0] = r; mass[0] = m; inert[0] = 0.4 * m * r * r;
      for (int c = 0; c < 3; c++) x[0][c] = v[0][c] = w[0][c] = a_old[0][c] = al_old[0][c] = 0;
      memset(nh, 0, sizeof nh);
      gvec[1] = 0;
      x[0][0] = gc[2][k]; x[0][1] = gd[2][k] + Rr + 1e-6; v[0][1] = -vin;
      double tcol = 0, vout = 0; int touching = 0, done = 0;
      for (long it = 0; it < 100000000 && !done; it++) {
        step();
        double dx = x[0][0] - gc[2][k], dy = x[0][1] - gd[2][k];
        int now = dx * dx + dy * dy < Rr * Rr;
        if (now) { touching = 1; tcol += DT; }
        if (touching && !now) { done = 1; vout = v[0][1]; }
      }
      double th = MODEL == 1 ? 2.868 * pow(m * m / (reff * Es * Es * vin), 0.2) : M_PI / sqrt(KN / m);
      out("  closing %6.1f cm/s: e = %.4f, contact %.3g s (elastic Hertz %.3g s), sideways drift %.1e cm/s\n", vin, vout / vin, tcol, th, v[0][0]);
    }
    gvec[1] = -G;
    return;
  }
  double ah = 0.5 * (gc[tw][k] + gc[tw][k + 1]), half = 0.5 * (gc[tw][k + 1] - gc[tw][k]);
  if (half >= Rr) { out("the hollow is wider than the bead: it would sit on the floor\n"); return; }
  double alpha = asin(half / Rr), nseat = gd[tw][k] + sqrt(Rr * Rr - half * half);
  out("# TEST=ghollow TW=%d MODEL=%d RG %.3f SG %.3f MUG %.3g: alpha = %.3f deg; spin locked: alpha + atan(MUG) = %.3f deg\n", tw, MODEL, RG, SG, MUG,
         alpha * 180 / M_PI, (alpha + atan(MUG)) * 180 / M_PI);
  double ths[] = { 0.9, 0.98, 1.02, 1.1 };
  for (int lock = 0; lock <= 1; lock++)
    for (int q = 0; q < 4; q++) {
      double thc = lock ? alpha + atan(MUG) : alpha, th = ths[q] * thc;
      rad[0] = r; mass[0] = m; inert[0] = lock ? 1e30 : 0.4 * m * r * r;
      for (int c = 0; c < 3; c++) x[0][c] = v[0][c] = w[0][c] = a_old[0][c] = al_old[0][c] = 0;
      memset(nh, 0, sizeof nh);
      x[0][0] = SX(nseat + 1e-4, ah); x[0][1] = SY(nseat + 1e-4, ah);
      gvec[0] = DX(-G, 0); gvec[1] = DY(-G, 0);
      double t, seat = 0, x0 = x[0][0], y0 = x[0][1];
      for (t = 0; t < 0.3; t += DT) step();
      seat = tw == 2 ? x[0][1] : tw == 0 ? x[0][0] + W_IN / 2 : W_IN / 2 - x[0][0];
      /* tilt gravity slowly (over 0.2 s) to TH, then hold it 0.5 s */
      for (t = 0; t < 0.7; t += DT) {
        double a = th * fmin(1, t / 0.2);
        gvec[0] = DX(-G * cos(a), G * sin(a)); gvec[1] = DY(-G * cos(a), G * sin(a));
        step();
      }
      double moved = hypot(x[0][0] - x0, x[0][1] - y0);
      out("  %s TH/thc %.2f (%.2f deg): seat %.5f cm (geometry %.5f), moved %.4f cm: %s (theory: %s)\n", lock ? "spin locked" : "free       ",
             ths[q], th * 180 / M_PI, seat, nseat, moved, moved > 0.05 ? "out" : "held", ths[q] < 1 ? "held" : "out");
    }
  gvec[0] = 0; gvec[1] = -G;
}

// ---------------------------------------------------------------------
// end of bead-bed.c
// ---------------------------------------------------------------------

double DemCore::gluedX(int wall, int k) const {
  return wall == 0 ? -W_IN / 2 + gd[0][k] : wall == 1 ? W_IN / 2 - gd[1][k] : gc[2][k];
}
double DemCore::gluedY(int wall, int k) const { return wall < 2 ? gc[wall][k] : gd[2][k]; }

bool DemCore::set(const std::string &key, double d) {
  const char *k = key.c_str();
#define D(name, var) else if (!strcmp(k, name)) var = d;
#define I(name, var) else if (!strcmp(k, name)) var = (int)d;
  if (false) {}
  D("GAMMA", GAMMA) D("F", FHZ) D("POLY", POLY) D("MUB", MUB) D("MUW", MUW) D("MUF", MUF) D("MUP", MUP)
  D("E", EB) D("EW", EW) D("TC", TC) D("YM", YM) D("NU", NU) D("KT", KT) D("ROLL", ROLL) D("GAP", GAP)
  D("SETTLE", SETTLE) D("TEND", TEND) D("CONVEND", CONVEND) D("CONVSTART", CONVSTART) D("TH", TH) D("H0", H0) D("V0", V0)
  D("W", W_IN) D("RB", R_B) D("RHOB", RHOB) D("RG", RG) D("SG", SG) D("GEMB", GEMB) D("GJIT", GJIT) D("MUG", MUG) D("EG", EG)
  D("ETH", ETH) D("ELOW", ELOW) I("ROUGH", ROUGH) I("ROUGHF", ROUGHF)
  I("TW", TW) I("N", NSM) I("FORCE3D", FORCE3D) I("SEED", SEED) I("MODEL", MODEL) I("NS", NS) I("PLATES", PLATES)
  I("BOX", BOX)
  D("H", H_IN) D("GAMMA0", GAMMA0) D("TG", TG) D("TR", TR) I("WATCH1", WATCH1) I("WATCH2", WATCH2)
  I("GW1", GW1) I("GW2", GW2) I("TRACER", TRACER) D("RISE1", RISE1) D("RISE2", RISE2) D("RISEW", RISEW) D("LATE0", LATE0) D("LATE1", LATE1)
  else return false;
#undef D
#undef I
  return true;
}

double DemCore::get(const std::string &key) const {
  const char *k = key.c_str();
#define R(name, val) if (!strcmp(k, name)) return (val);
  // parameters, as the run has them
  R("KN", KN) R("GAMMA", GAMMA) R("F", FHZ) R("AMP", AMP) R("DT", DT) R("TC", TC) R("NSUB", nsub) R("N", N) R("W", W_IN) R("H", H_IN)
  R("RG", RG) R("ROUGH", ROUGH) R("REACH", ROUGH ? RG * (2 - 2 * GEMB) + GJIT * RG / 2 : 0) R("MASS", Mtot) R("TRACER", TRACER < 0 && !BIG ? N - 1 : TRACER)
  // the settled bed, just before the shaking starts
  R("settled", settleDone) R("settleKe", settleKe) R("settleOvMax", settleOvMax) R("settleOvMean", settleOvMean)
  // the push reports (hard window; gentle: "g" in front)
  R("phase", phaseDone[0]) R("least", phaseLeast[0]) R("off", phaseOff[0]) R("landed", phaseLanded[0]) R("vdown", phaseVdown[0])
  R("gphase", phaseDone[1]) R("gleast", phaseLeast[1]) R("goff", phaseOff[1]) R("glanded", phaseLanded[1]) R("gvdown", phaseVdown[1])
  // the rolls (mm/s), once CONVEND has passed
  R("conv", reportedConv) R("mid", convMid) R("wall", convWall)
  // the special bead: at the top (as the lua had it), its rise, its late height
  R("reached", reached) R("upper", upN ? (double)upHalf / upN : -1)
  R("rise1", rise1T) R("rise2", rise2T) R("special", special) R("top", top)
  R("late", lateDone) R("up20", lateN ? (double)lateUp / lateN : -1) R("top20", lateN ? (double)lateTop / lateN : -1)
  R("h20", lateN ? lateH / lateN : -1) R("hc20", lateN ? lateHC / lateN : -1)
  R("lateMean", lateN ? lateHsum / lateN : -1) R("lateMin", lateN ? lateHmin : -1)
  // the tracer
  R("tracerMin", trMin) R("tracerMinT", trMinT) R("tracerMinX", trMinX)
  R("trips", trips) R("upx", upNN ? upX / upNN : -1) R("downx", downNN ? downX / downNN : -1)
  // overlaps
  R("ovmean", ovN ? ovSum / ovN : 0) R("ovmax", ovMax)
  R("time", tf + kSub * DT) R("frame", frame)
#undef R
  return std::numeric_limits<double>::quiet_NaN();
}

// the box: y = A sin(w t) from t = 0 (at rest before). With a gentle opening
// (GAMMA0 >= 0), A is GAMMA0's for TG s, then goes linearly to GAMMA's over
// TR s (its speed then has A's rate of change in it too)
void DemCore::boxAt(double te, double &y, double &vy) const {
  if (GAMMA0 < 0) {
    y = te > 0 ? AMP * sin(OMEGA * te) : 0;
    vy = te > 0 ? AMP * OMEGA * cos(OMEGA * te) : 0;
    return;
  }
  if (te <= 0) { y = vy = 0; return; }
  double A0 = GAMMA0 * G / (OMEGA * OMEGA), A = AMP, dA = 0;
  if (te < TG) A = A0;
  else if (te < TG + TR) { dA = (AMP - A0) / TR; A = A0 + dA * (te - TG); }
  y = A * sin(OMEGA * te);
  vy = dA * sin(OMEGA * te) + A * OMEGA * cos(OMEGA * te);
}

// (what bead-bed.c's main does before its loop, test or run)
void DemCore::init() {
  if (MUF < 0) MUF = MUW;
  if (MUP < 0) MUP = MUW;
  if (EW < 0) EW = EB;
  if (MUG < 0) MUG = MUW;
  if (EG < 0) EG = EW;
  NCX = (int)ceil(W_IN / CS);
  if (NCX > NCXMAX) NCX = NCXMAX;
  if (NSM + 1 > MAXB) NSM = MAXB - 1;
  makeGlued();
  if (KT < 0) KT = MODEL == 0 ? 2.0 / 7.0 : 2 * (1 - NU) / (2 - NU);
  OMEGA = 2 * M_PI * FHZ;
  which = BOX;
  if (which == 0) { if (GAMMA < 0) GAMMA = 0.8; }
  else if (which == 2) BIG = 0;
  if (GAMMA < 0) GAMMA = 3.0;
  AMP = GAMMA * G / (OMEGA * OMEGA);
  if (TEST[0]) return;
  LOCKZ = !PLATES;
  if (PLATES && which != 2) PLATES = 0, LOCKZ = 1;
  setStiffness();
  pour(which);
  nsub = (int)ceil((1.0 / 60) / DT);
  DT = (1.0 / 60) / nsub;
  Mtot = 0;
  for (int i = 0; i < N; i++) Mtot += mass[i];
  Wt = Mtot * G;
  if (LATE0 < 0) LATE0 = TEND - 20;
  tf = -SETTLE;
  forces();
  for (int i = 0; i < N; i++) for (int k = 0; k < 3; k++) { a_old[i][k] = f[i][k] / mass[i]; al_old[i][k] = tq[i][k] / inert[i]; }
  ready = true;
}

std::string DemCore::test(const std::string &name) {
  snprintf(TEST, sizeof TEST, "%s", name.c_str());
  init();
  outBuf.clear();
  AMP = 0;
  setStiffness();
  if (MODEL == 0) { zetaBB = damping_for(0, EB); zetaBW = damping_for(0, EW); }
  out("# damping: zeta(bead) %.5f zeta(wall) %.5f, k %.4g, DT %.3g\n", zetaBB, zetaBW, KN, DT);
  if (!strcmp(TEST, "incline")) testIncline();
  else if (!strcmp(TEST, "gdrop") || !strcmp(TEST, "ghollow")) testGlued();
  else testDrop();
  return outBuf;
}

// on to time t, in whole steps: the step count is what decides, so the run
// is the same however the time is handed out
void DemCore::stepTo(double t) {
  if (!ready) return;
  long target = (long)floor((t + SETTLE) * 60 * nsub + 0.5);
  while (stepsDone < target) {
    substep();
    stepsDone++;
    if (++kSub == nsub) {
      kSub = 0;
      tf += 1.0 / 60;
      frame++;
      afterFrame();
    }
  }
}

// one step of bead-bed.c's main loop (its inner loop's body, k = kSub)
void DemCore::substep() {
  int k = kSub;
  double tt = tf + k * DT;
  int cyc = (int)floor(tt * FHZ);
  int watch = tt > 0 && cyc >= WATCH1 && cyc < WATCH2;
  int watchG = tt > 0 && GAMMA0 >= 0 && cyc >= GW1 && cyc < GW2;
  double P0 = 0;
  if (watch || watchG) for (int i = 0; i < N; i++) P0 += mass[i] * v[i][1];
  // the box at the end of this step
  double te = tt + DT;
  boxAt(te, boxy, boxv);
  nContacts = 0; sumOverlap = 0; maxOverlap = 0;
  step();
  stepNo++;
  if (tt > 0) { ovSum += nContacts ? sumOverlap / nContacts : 0; ovN++; if (maxOverlap > ovMax) ovMax = maxOverlap; }
  else if (tt > -0.1) { if (maxOverlap > setMax) setMax = maxOverlap; setSum += nContacts ? sumOverlap / nContacts : 0; setN++; }
  if (tt < 0 && tt + DT >= 0) {
    // the settled bed, just before the shaking starts (RESULT_SETTLE)
    double ke = 0;
    for (int i = 0; i < N; i++) ke += 0.5 * mass[i] * dot(v[i], v[i]) + 0.5 * inert[i] * dot(w[i], w[i]);
    settleOvMax = setMax;
    settleOvMean = setN ? setSum / setN : 0;
    settleKe = ke / N / (meanSmallMass() * G * 2 * R_S);
    settleDone = 1;
  }
  if (watch || watchG) {
    double P = 0;
    for (int i = 0; i < N; i++) P += mass[i] * v[i][1];
    double push = (P - P0) / DT + Wt;
    int bin = (int)floor((tt * FHZ - cyc) * 180);
    if (bin >= 0 && bin < 180) {
      if (watch) { pushSum[bin] += push; vrelSum[bin] += P / Mtot - boxv; pushN[bin]++; }
      if (watchG) { pushSumG[bin] += push; vrelSumG[bin] += P / Mtot - boxv; pushNG[bin]++; }
    }
  }
}

// the push report (bead-bed.c's): over the window's shakes, the least push in
// 0-90 degrees, where it first drops below a tenth of the weight (lift-off),
// where the bed's middle stops coming down (landed), and how fast it's still
// coming down at arcsin(1 / Gamma)
void DemCore::pushReport(bool gentle) {
  int g = gentle ? 1 : 0;
  const double *ps = gentle ? pushSumG : pushSum, *vs = gentle ? vrelSumG : vrelSum;
  const long *pn = gentle ? pushNG : pushN;
  double gam = gentle ? GAMMA0 : GAMMA;
  int off = -1, landed = -1;
  double least = 1e9;
  for (int b = 0; b < 45; b++) {
    if (!pn[b]) continue;
    double p = ps[b] / pn[b] / Wt;
    if (p < least) least = p;
    if (off < 0 && p < 0.1) off = 2 * b;
    if (landed < 0 && vs[b] / pn[b] >= 0) landed = 2 * b;
  }
  int b19 = (int)floor((gam > 1 ? asin(1 / gam) : M_PI / 2) * 180 / M_PI / 2);
  double vdown = pn[b19] ? -vs[b19] / pn[b19] : 0;
  phaseLeast[g] = least; phaseOff[g] = off; phaseLanded[g] = landed; phaseVdown[g] = vdown;
  phaseDone[g] = 1;
}

// after each 1/60 s frame (bead-bed.c's main loop, after its inner loop)
void DemCore::afterFrame() {
  double by, byv;
  boxAt(tf, by, byv);
  double ys[MAXB];
  for (int i = 0; i < NSM; i++) ys[i] = x[i][1];
  for (int i = 1; i < NSM; i++) { double t = ys[i]; int j = i - 1; while (j >= 0 && ys[j] > t) { ys[j + 1] = ys[j]; j--; } ys[j + 1] = t; }
  double sum = 0; int n = 0;
  for (int i = (int)floor(NSM * 0.9) - 1; i < NSM; i++) { sum += ys[i]; n++; }
  double topY = sum / n + R_S;
  double ysp = x[N - 1][1], rs = rad[N - 1];
  top = topY - by;
  special = ysp - by;
  if (tf > 0 && reached < 0 && ysp + rs > topY - 0.3) reached = tf;
  if (reached >= 0 && BIG) { upN++; if (ysp - by > (topY - by) / 2) upHalf++; }
  // its rise: when its height (or its mean over the last RISEW s, from the
  // shaking's start) first reaches RISE1 and RISE2
  double hr = ysp - by;
  int nw = (int)floor(RISEW * 60 + 0.5);
  if (nw > 600) nw = 600;
  if (nw > 1 && tf > 0) {
    if (riseN == nw) riseSum -= riseBuf[riseK]; else riseN++;
    riseBuf[riseK] = hr;
    riseSum += hr;
    riseK = (riseK + 1) % nw;
    hr = riseN == nw ? riseSum / nw : -1e30;
  }
  if (tf > 0 && rise1T < 0 && hr >= RISE1) rise1T = tf;
  if (tf > 0 && rise2T < 0 && hr >= RISE2) rise2T = tf;
  // the late window: the special bead's time in the upper half, at the top,
  // its mean height (bottom 0, the bed's top 1), against twice the bed's
  // centre of mass, and its centre's mean and least height
  if (tf > LATE0 && tf <= LATE1) {
    lateN++;
    if (ysp - by > (topY - by) / 2) lateUp++;
    if (ysp + rs > topY - 0.3) lateTop++;
    double ycm = 0;
    for (int q = 0; q < NSM; q++) ycm += x[q][1] - by;
    lateHC += (ysp - by) / (2 * ycm / NSM);
    lateH += (ysp - rs - by - (ROUGHF ? gluedReach() : 0)) / (topY - by - 2 * rs - (ROUGHF ? gluedReach() : 0));
    lateHsum += ysp - by;
    if (ysp - by < lateHmin) lateHmin = ysp - by;
  }
  if (tf > LATE1) lateDone = 1;
  int tr = TRACER >= 0 ? TRACER : (!BIG ? N - 1 : -1);
  // the tracer's lowest point, from the shaking's start to CONVEND
  if (tr >= 0 && tf > 0 && tf <= CONVEND && x[tr][1] - by < trMin) { trMin = x[tr][1] - by; trMinT = tf; trMinX = x[tr][0]; }
  if (tf > CONVSTART && (!haveSample || tf - lastT >= 0.5)) {
    if (haveSample && !reportedConv) {
      for (int i = 0; i < NSM; i++) {
        double dx = fabs(lastP[i][0]), dy = ((x[i][1] - by) - lastP[i][1]) / (tf - lastT);
        if (dx < 3) { midSum += dy; midN++; }
        else if (dx > W_IN / 2 - 2.5) { wallSum += dy; wallN++; }
      }
      if (tr >= 0) {
        double yt = x[tr][1], rt = rad[tr];
        double h = yt - by - rt, depth = topY - by, sdx = fabs(x[tr][0]), dyS = yt - lastYs;
        if (dyS > 0) { upX += sdx; upNN++; } else { downX += sdx; downNN++; }
        if (h > depth * 2 / 3 && !zoneTop) zoneTop = 1;
        if (h < depth / 3 && zoneTop) { zoneTop = 0; trips++; }
      }
    }
    for (int i = 0; i < NSM; i++) { lastP[i][0] = x[i][0]; lastP[i][1] = x[i][1] - by; }
    lastYs = tr >= 0 ? x[tr][1] : ysp;
    lastT = tf;
    haveSample = 1;
  }
  if (!phaseDone[0] && tf > WATCH2 / FHZ + 0.02 && tf - 1.0 / 60 <= WATCH2 / FHZ + 0.02) pushReport(false);
  if (GAMMA0 >= 0 && !phaseDone[1] && tf > GW2 / FHZ + 0.02 && tf - 1.0 / 60 <= GW2 / FHZ + 0.02) pushReport(true);
  if (!reportedConv && tf > CONVEND) {
    reportedConv = 1;
    convMid = midN ? midSum / midN * 10 : 0;
    convWall = wallN ? wallSum / wallN * 10 : 0;
  }
}
