/*
 * The Brazil-nut exhibit's bed, outside bpp and Bullet: a discrete-element
 * (DEM) reference with soft-sphere contacts, for the same beads, box and
 * shaking as brazil-nut.lua, measured the same way.
 *
 * THE BED (from brazil-nut.lua): a box 15 cm wide inside, its floor and two
 * side walls moved together as y = A sin(w t) from t = 0 (at rest before),
 * f = 7 Hz, A = Gamma g / w^2. 140 small glass beads, radius 0.5 cm times
 * (1 - POLY/2 + POLY ((i*37) % 100) / 99), i = 1..140 (POLY 0.1), and a
 * special bead: the big one (radius 1.5) at the bottom in the middle, or a
 * coloured small one (radius 0.5). Density 0.0025 kg/cm^3. g = 981 cm/s^2.
 * Poured in loose rows exactly as the lua pours them (its own random-number
 * generator, BN_SEED 7, drawn through the three boxes in turn), left to
 * settle for 0.5 s, then shaken.
 *
 * THE BEADS: spheres. By default (PLATES=0) they move in the box's plane and
 * spin about the axis normal to it, as the exhibit's beads do (Bullet's
 * linear factor (1,1,0), angular factor (0,0,1)); there are no front and
 * back plates, as in the exhibit (its glass is only drawn). With PLATES=1
 * they move in 3-D, spin about any axis, and are held between a front and a
 * back plate GAP apart, which they touch with friction MUP (only for the
 * box with no big bead: a 3 cm bead can't share a one-bead-thick slot).
 *
 * CONTACTS (bead-bead, bead-floor, bead-wall, bead-plate), soft spheres:
 *   normal   MODEL=0: linear spring-dashpot, F = k d + c d', clamped at 0
 *            (no pull); k the same for every pair, set by the undamped
 *            half-period TC of two average small beads (k = m/2 (pi/TC)^2);
 *            c = 2 z sqrt(m_eff k), z chosen so that a two-body collision
 *            with this clamped law gives back exactly the restitution E
 *            (found once at start by integrating the collision and
 *            bisecting; Schwager and Poeschel, Granular Matter 9, 465
 *            (2007), show the clamp changes e(z) -- from memory).
 *            MODEL=1: Hertz, F = K d^1.5 + a sqrt(m_eff K) d^0.25 d' (Tsuji,
 *            Tanaka and Ishida, Powder Technol. 71, 239 (1992) -- from
 *            memory), clamped at 0; K = 4/3 E* sqrt(R_eff) from Young's
 *            modulus YM (Pa) and Poisson's ratio NU, E* = E/(2(1-nu^2)) for
 *            glass on glass (beads and box alike); a found as z above.
 *   tangent  Cundall-Strack: a spring kt = KT k (MODEL=1: KT times the
 *            normal tangent stiffness 1.5 K sqrt d; KT defaults to 2/7 for
 *            the linear law, Mindlin's 2 (1 - nu) / (2 - nu) = 0.876 for
 *            Hertz -- and the convection depends on it, see FINDINGS) and dashpot with the
 *            same damping ratio as the normal, the spring stretched by the
 *            contact's sliding velocity, kept in the tangent plane, and
 *            capped by Coulomb: |Ft| <= MU Fn (the spring then set to the
 *            stretch that gives the cap: Luding, Granular Matter 10, 235
 *            (2008) -- from memory).
 *   rolling  optional (ROLL > 0): a torque against the relative spin,
 *            ROLL R_eff Fn (constant directional model, regularised below
 *            0.5 rad/s). Off by default, as in the exhibit.
 *
 * INTEGRATION: velocity Verlet (kick-drift-kick); the velocity-dependent
 * forces use the predicted velocity v + a_old dt/2. A cell list (cells 1.1
 * cm, wider than any small bead) finds small-small pairs; the big bead is
 * tested against every bead. Step DT = TC / NS (MODEL=1: TC is the Hertz
 * contact time of two small beads closing at A w, the shaker's top speed).
 *
 * STABLE STEPS (an overdamped dashpot integrated explicitly blows up on a
 * bead with several contacts; the settled bed's overlaps and kinetic
 * energy, printed as RESULT_SETTLE at t = 0, are the check): linear NS >= 40
 * for e >= 0.1 (NS 20 blows up), NS >= 200 for e = 0.01; Hertz NS >= 60 for
 * e = 0.1 (30 blows up), NS >= 40 for e = 0.95 (80 for the shaken glass
 * bed's convection); Hertz e = 0.01 blew up under shaking even at NS 200.
 *
 * MEASURED (as brazil-nut.lua measures; frame clock 1/60 s):
 *   push     the floor's push on the bed, (P_after - P_before)/dt + W from
 *            the bed's momentum, every step of shakes 5 to 32, binned by
 *            phase in 2-degree bins; lift-off = first bin in 0..90 where
 *            the mean is below 0.1 W; landed = first bin where the bed's
 *            middle has stopped coming down relative to the floor; below
 *            Gamma 1, the least push in 0..90 degrees.
 *   rise     the special bead "reaches the top" when its top is within 0.3
 *            cm of the bed's top (mean height of the highest tenth of small
 *            beads, plus 0.5 cm); checked every frame from t = 0.
 *   conv     every 0.5 s from t = 5 s: each small bead's rise rate in the
 *            box, binned by where it was: the middle (|x| < 3 cm) or by
 *            the walls (|x| > 5 cm); mean over beads and samples, to the
 *            first frame past 60 s (CONVEND), in mm/s.
 *   trips    the coloured bead: from the bottom third up to the top two
 *            thirds and back, counted, sampled every 0.5 s.
 *   upper    the big bead: fraction of frames in the bed's upper half
 *            after first reaching the top.
 *
 *   gcc -O2 -o bead-bed bead-bed.c -lm
 *   ./bead-bed [key=value ...]
 *     BOX=middle|gentle|right GAMMA=(3 or 0.8) F=7 SEED=7 POLY=0.1 N=140
 *     MUB=0.64 MUW=0.8 MUF=(MUW) MUP=(MUW) E=0.01 EW=(E) MODEL=0 TC=1e-4
 *     YM=6.3e10 NU=0.22 NS=40 KT=(2/7; Hertz 2(1-NU)/(2-NU)) ROLL=0 PLATES=0 GAP=1.1
 *     SETTLE=0.5 TEND=60.05 CONVEND=60 LOG=file.csv
 *     TEST=drop|pair|incline (validation, see below)
 *   GLASS-DESIGN.md adds (all off by default; defaults give the same runs):
 *     W=15 RB=1.5 RHOB=(0.0025) N F GAMMA as design variables;
 *     ROUGH=1 (side walls lined with glued spheres) ROUGHF=1 (the floor too)
 *     RG=0.5 SG=1.0 GEMB=0.5 GJIT=0 MUG=(MUW) EG=(EW); ETH= ELOW=0.1 (a
 *     Bullet-like restitution threshold, unvalidated); TEST=gdrop|ghollow
 *     TW=0|1|2 (the glued spheres' validation); LID= (a lid that many cm above
 *     the floor; TEST=lid checks it); RESULT gains up20, top20,
 *     h20, hc20 (the special bead over the last 20 s).
 *
 * Units: cm, kg, s (forces kg cm / s^2).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#define G 981.0
#define MAXB 400
#define MAXC 24
#define RHO 0.0025
#define R_S 0.5
#define H_IN 24.0
/* partner ids for the walls */
#define FLOOR (-1)
#define LWALL (-2)
#define RWALL (-3)
#define FRONT (-4)
#define BACK (-5)
#define LIDW (-6)

typedef struct { int j; double s[3]; } Hist;

/* ---------- parameters ---------- */
static char BOXN[16] = "middle";
static double GAMMA = -1, FHZ = 7, POLY = 0.1, MUB = 0.64, MUW = 0.8, MUF = -1, MUP = -1;
static double EB = 0.01, EW = -1, TC = 1e-4, YM = 6.3e10, NU = 0.22, KT = -1, ROLL = 0;
static double GAP = 1.1, SETTLE = 0.5, TEND = 60.05, CONVEND = 60, CONVSTART = 5;
static int NSM = 140, SEED = 7, MODEL = 0, NS = 40, PLATES = 0, BIG = 1;
/* the box's width and the big bead (defaults: the exhibit's) */
static double W_IN = 15.0, R_B = 1.5, RHOB = RHO;   /* (RHOB: the big bead's density, kg/cm^3) */
/* rough walls (GLASS-DESIGN.md): ROUGH=1 lines the side walls (ROUGHF=1 the
 * floor too) with fixed glued spheres of radius RG, centres SG apart along
 * the wall, embedded GEMB of their diameter in it (0.5: half-embedded, the
 * centres on the wall's face), each jittered by up to GJIT/2 of SG along
 * the wall and GJIT/2 of RG into it (a hashed, fixed pattern); friction MUG
 * and restitution EG against a bead. The flat face behind them keeps MUW. */
static int ROUGH = 0, ROUGHF = 0;
static double RG = 0.5, SG = 1.0, GEMB = 0.5, GJIT = 0, MUG = -1, EG = -1;
/* restitution threshold (an emulation of Bullet's): a contact whose closing
 * speed at first touch is below ETH cm/s gets restitution ELOW instead */
static double ETH = 0, ELOW = 0.1;
/* a lid (EXHIBIT): a flat glass ceiling LID cm above the floor, moving with
 * the box, met like the walls (MUW, EW); 0: none, the box open */
static double LID = 0;
static char LOGF[256] = "", TEST[16] = "";
static double TH = 10, H0 = 1, V0 = 50;    /* tests */
static int TW = 2;

/* ---------- state ---------- */
static int N;                      /* beads: 0..N-2 small, N-1 the special one */
static double x[MAXB][3], v[MAXB][3], w[MAXB][3], f[MAXB][3], tq[MAXB][3], a_old[MAXB][3], al_old[MAXB][3];
static double rad[MAXB], mass[MAXB], inert[MAXB];
static Hist hist[2][MAXB][MAXC];
static int nh[2][MAXB], cur = 0;
static double KN, DT, AMP, OMEGA, gvec[3] = { 0, -G, 0 };
static double boxy = 0, boxv = 0;   /* the box's floor height and speed */
static int LOCKZ = 1, FORCE3D = 0;   /* (FORCE3D=1: the 3-D contact even in the plane, a check) */
static double floorTilt = 0;        /* (tests) */

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
static int nContacts;
static double sumOverlap, maxOverlap;

static double *findHist(int i, int j)
{
  int o = 1 - cur;
  for (int k = 0; k < nh[o][i]; k++) if (hist[o][i][k].j == j) return hist[o][i][k].s;
  return NULL;
}

/* n: unit normal from the partner toward i; d: overlap; ai, aj: lever arms
 * from the centres to the contact point; vj, wj: partner velocity and spin
 * (walls: their velocity, no spin); mu: friction; e: which restitution */
static double SQKT, SQKN;
/* the same contact in the plane (PLATES=0, ROLL=0): n = (nx, ny), spins
 * about z only, the tangent t = (-ny, nx); the spring kept as a vector as
 * in 3-D (turned onto the new tangent, its length kept) -- the same
 * arithmetic with the zero components left out */
static double zetaLow;
static void contact2(int i, int j, const double *n, double d, double ai, double aj,
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

static void contact3(int i, int j, const double *n, double d, double ai, double aj,
                     const double *vi, const double *wi, const double *vj, const double *wj,
                     double meff, double reff, double mu, double zeta);
static void contact(int i, int j, const double *n, double d, double ai, double aj,
                    const double *vi, const double *wi, const double *vj, const double *wj,
                    double meff, double reff, double mu, double zeta)
{
  if (LOCKZ && ROLL == 0 && !FORCE3D) contact2(i, j, n, d, ai, aj, vi, wi, vj, wj, meff, reff, mu, zeta);
  else contact3(i, j, n, d, ai, aj, vi, wi, vj, wj, meff, reff, mu, zeta);
}

static void contact3(int i, int j, const double *n, double d, double ai, double aj,
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
#define CS 1.1
#define NCXMAX 64
#define NCY 64
static int NCX = 15;
static int cellHead[NCXMAX * NCY], cellNext[MAXB];
static double vp[MAXB][3], wp[MAXB][3];   /* predicted velocities */
static double zetaBB, zetaBW, zetaG;

/* the glued spheres, in the box's frame: side walls (0 left, 1 right) and
 * the floor (2); gc along the wall (y for the sides, x for the floor), gd
 * the centre's distance inside the wall's face (negative: behind it) */
#define MAXG 4000
static int nG[3];
static double gc[3][MAXG], gd[3][MAXG], gc0[3];
static double hash01(unsigned a)
{
  a ^= a >> 16; a *= 0x7feb352dU; a ^= a >> 15; a *= 0x846ca68bU; a ^= a >> 16;
  return (a & 0xffffff) / 16777215.0;
}
static void makeGlued(void)
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
static double gluedReach(void) { return ROUGH ? RG * (2 - 2 * GEMB) + GJIT * RG / 2 : 0; }

static void gluedForces(int i, const double *vb)
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

static void pairForce(int i, int j)
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

static void forces(void)
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
    if (LID > 0) {
      d = r - (boxy + LID - x[i][1]);
      if (d > 0) { double n[3] = { 0, -1, 0 }; contact(i, LIDW, n, d, r - d, 0, vp[i], wp[i], vb, zero, m, r, MUW, zetaBW); }
    }
    if (PLATES) {
      d = r - (x[i][2] + GAP / 2);
      if (d > 0) { double n[3] = { 0, 0, 1 }; contact(i, BACK, n, d, r - d, 0, vp[i], wp[i], vb, zero, m, r, MUP, zetaBW); }
      d = r - (GAP / 2 - x[i][2]);
      if (d > 0) { double n[3] = { 0, 0, -1 }; contact(i, FRONT, n, d, r - d, 0, vp[i], wp[i], vb, zero, m, r, MUP, zetaBW); }
    }
  }
}

static void step(void)
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

static double meanSmallMass(void) { return RHO * 4.0 / 3.0 * M_PI * R_S * R_S * R_S; }

/* set k (MODEL 0) and DT from TC */
static void setStiffness(void)
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
static double lseed;
static double lrnd(void)
{
  double a = lseed * 1103515245.0 + 12345.0;
  lseed = a - floor(a / 2147483648.0) * 2147483648.0;
  return lseed / 2147483648.0;
}
static double smallR(int i) { return R_S * (1 - POLY / 2 + POLY * ((i * 37) % 100) / 99.0); }

/* pour the three boxes as the lua does; keep box `which` (0 left, 1 middle, 2 right) */
static void pour(int which)
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

/* ---------- arguments ---------- */
static void arg(const char *s)
{
  char k[64];
  const char *eq = strchr(s, '=');
  if (!eq) { fprintf(stderr, "bad arg %s\n", s); exit(1); }
  snprintf(k, sizeof k, "%.*s", (int)(eq - s), s);
  const char *val = eq + 1;
  double d = atof(val);
#define D(name, var) else if (!strcmp(k, name)) var = d;
#define I(name, var) else if (!strcmp(k, name)) var = (int)d;
  if (!strcmp(k, "BOX")) snprintf(BOXN, sizeof BOXN, "%s", val);
  else if (!strcmp(k, "LOG")) snprintf(LOGF, sizeof LOGF, "%s", val);
  else if (!strcmp(k, "TEST")) snprintf(TEST, sizeof TEST, "%s", val);
  D("GAMMA", GAMMA) D("F", FHZ) D("POLY", POLY) D("MUB", MUB) D("MUW", MUW) D("MUF", MUF) D("MUP", MUP)
  D("E", EB) D("EW", EW) D("TC", TC) D("YM", YM) D("NU", NU) D("KT", KT) D("ROLL", ROLL) D("GAP", GAP)
  D("SETTLE", SETTLE) D("TEND", TEND) D("CONVEND", CONVEND) D("CONVSTART", CONVSTART) D("TH", TH) D("H0", H0) D("V0", V0) D("LID", LID)
  D("W", W_IN) D("RB", R_B) D("RHOB", RHOB) D("RG", RG) D("SG", SG) D("GEMB", GEMB) D("GJIT", GJIT) D("MUG", MUG) D("EG", EG)
  D("ETH", ETH) D("ELOW", ELOW) I("ROUGH", ROUGH) I("ROUGHF", ROUGHF)
  I("TW", TW) I("N", NSM) I("FORCE3D", FORCE3D) I("SEED", SEED) I("MODEL", MODEL) I("NS", NS) I("PLATES", PLATES)
  else { fprintf(stderr, "unknown key %s\n", k); exit(1); }
}

/* ---------- validation tests ---------- */
static void testDrop(void)
{
  /* a bead dropped on the floor (or, TEST=pair, two beads closing head on,
   * no gravity): the restitution it gives back, by impact speed */
  int pair = !strcmp(TEST, "pair");
  double speeds[] = { 1, 5, 20, 67, 200 };
  printf("# TEST=%s MODEL=%d E=%g (nominal) TC=%g NS=%d: measured e by closing speed\n", TEST, MODEL, pair ? EB : EW, TC, NS);
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
    printf("  closing %6.1f cm/s: e = %.4f, contact %.3g s (%.1f steps)\n", vin, vout / vin, tcol, tcol / DT);
    gvec[1] = -G;
  }
}

static void testLid(void)
{
  /* a bead rising into the lid (LID cm up), no gravity: the restitution it
   * gives back, and the contact time, by closing speed (as TEST=drop) */
  double speeds[] = { 1, 5, 20, 67, 200 };
  if (LID <= 0) LID = 30;
  printf("# TEST=lid MODEL=%d LID %.1f EW=%g (nominal) NS=%d: measured e by closing speed\n", MODEL, LID, EW, NS);
  for (int s = 0; s < 5; s++) {
    double vin = speeds[s];
    BIG = 0; LOCKZ = 1; AMP = 0; boxy = 0; boxv = 0; N = 1;
    rad[0] = R_S; mass[0] = meanSmallMass(); inert[0] = 0.4 * mass[0] * R_S * R_S;
    for (int k = 0; k < 3; k++) x[0][k] = v[0][k] = w[0][k] = a_old[0][k] = al_old[0][k] = 0;
    memset(nh, 0, sizeof nh);
    gvec[1] = 0;
    x[0][1] = LID - R_S - 1e-6; v[0][1] = vin;
    double tcol = 0, vout = 0;
    int touching = 0, done = 0;
    for (long it = 0; it < 100000000 && !done; it++) {
      step();
      int now = x[0][1] > LID - R_S;
      if (now) { touching = 1; tcol += DT; }
      if (touching && !now) { done = 1; vout = -v[0][1]; }
    }
    printf("  closing %6.1f cm/s: e = %.4f, contact %.3g s (%.1f steps)\n", vin, vout / vin, tcol, tcol / DT);
    gvec[1] = -G;
  }
}

static void testIncline(void)
{
  /* a bead on a floor tilted TH degrees (MUF its friction): free to roll,
   * and with its spin locked (it must slide, or stick). Rolling without
   * slipping holds for tan TH <= 3.5 mu (a = 5/7 g sin TH); a locked bead
   * sticks for tan TH <= mu (a = 0), else a = g (sin - mu cos). */
  printf("# TEST=incline MODEL=%d MU=%g TC=%g NS=%d: tan(th)/mu, acceleration/g, slip speed at the contact after 0.3 s\n", MODEL, MUF, TC, NS);
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
      printf("  %s tan/mu %.2f: a/g = %.5f (theory %.5f), contact slip %.4f cm/s\n", lock ? "spin locked" : "free      ",
             ths[s], -acc / G, expect / G, -slip);
    }
  }
  floorTilt = 0;
}

static void testGlued(void)
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
  if (!ROUGH || !ROUGHF || nG[2] < 3) { fprintf(stderr, "TEST=gdrop|ghollow needs ROUGH=1 ROUGHF=1\n"); exit(1); }
  int tw = TW, k = 0;
  double mid = tw == 2 ? 0 : 8;
  for (int q = 0; q < nG[tw]; q++) if (fabs(gc[tw][q] - mid) < fabs(gc[tw][k] - mid)) k = q;
  if (k + 1 >= nG[tw]) k--;
  /* a point (normal n, along a) of surface tw in the box's x, y; a direction too */
#define SX(nn, aa) (tw == 2 ? (aa) : tw == 0 ? -W_IN / 2 + (nn) : W_IN / 2 - (nn))
#define SY(nn, aa) (tw == 2 ? (nn) : (aa))
#define DX(nn, aa) (tw == 2 ? (aa) : tw == 0 ? (nn) : -(nn))
#define DY(nn, aa) (tw == 2 ? (nn) : (aa))
  double r = R_S, m = meanSmallMass(), Rr = r + RG;
  BIG = 0; LOCKZ = 1; AMP = 0; N = 1; boxy = 0; boxv = 0;
  if (!strcmp(TEST, "gdrop")) {
    double Es = YM * 1e-2 / (2 * (1 - NU * NU)), reff = r * RG / Rr;
    double speeds[] = { 1, 5, 20, 67, 200 };
    printf("# TEST=gdrop MODEL=%d RG %.3f EG %.3g NS %d DT %.3g: e and contact time by closing speed\n", MODEL, RG, EG, NS, DT);
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
      printf("  closing %6.1f cm/s: e = %.4f, contact %.3g s (elastic Hertz %.3g s), sideways drift %.1e cm/s\n", vin, vout / vin, tcol, th, v[0][0]);
    }
    gvec[1] = -G;
    return;
  }
  double ah = 0.5 * (gc[tw][k] + gc[tw][k + 1]), half = 0.5 * (gc[tw][k + 1] - gc[tw][k]);
  if (half >= Rr) { fprintf(stderr, "the hollow is wider than the bead: it would sit on the floor\n"); exit(1); }
  double alpha = asin(half / Rr), nseat = gd[tw][k] + sqrt(Rr * Rr - half * half);
  printf("# TEST=ghollow TW=%d MODEL=%d RG %.3f SG %.3f MUG %.3g: alpha = %.3f deg; spin locked: alpha + atan(MUG) = %.3f deg\n", tw, MODEL, RG, SG, MUG,
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
      printf("  %s TH/thc %.2f (%.2f deg): seat %.5f cm (geometry %.5f), moved %.4f cm: %s (theory: %s)\n", lock ? "spin locked" : "free       ",
             ths[q], th * 180 / M_PI, seat, nseat, moved, moved > 0.05 ? "out" : "held", ths[q] < 1 ? "held" : "out");
    }
  gvec[0] = 0; gvec[1] = -G;
}

/* ---------- the run ---------- */
int main(int argc, char **argv)
{
  for (int a = 1; a < argc; a++) arg(argv[a]);
  if (MUF < 0) MUF = MUW;
  if (MUP < 0) MUP = MUW;
  if (EW < 0) EW = EB;
  if (MUG < 0) MUG = MUW;
  if (EG < 0) EG = EW;
  NCX = (int)ceil(W_IN / CS);
  if (NCX > NCXMAX || NSM + 1 > MAXB) { fprintf(stderr, "box too wide or too many beads\n"); return 1; }
  makeGlued();
  /* the tangential to normal stiffness: 2/7 for the linear law (the usual
   * choice, equal normal and tangential periods); Mindlin's no-slip value
   * 2 (1 - nu) / (2 - nu) for Hertz (0.876 for glass) */
  if (KT < 0) KT = MODEL == 0 ? 2.0 / 7.0 : 2 * (1 - NU) / (2 - NU);
  OMEGA = 2 * M_PI * FHZ;
  int which = 1;
  if (!strcmp(BOXN, "gentle") || !strcmp(BOXN, "left")) { which = 0; if (GAMMA < 0) GAMMA = 0.8; }
  else if (!strcmp(BOXN, "right")) { which = 2; BIG = 0; }
  if (GAMMA < 0) GAMMA = 3.0;
  AMP = GAMMA * G / (OMEGA * OMEGA);
  if (TEST[0]) {
    AMP = 0;
    setStiffness();
    if (MODEL == 0) { zetaBB = damping_for(0, EB); zetaBW = damping_for(0, EW); }
    printf("# damping: zeta(bead) %.5f zeta(wall) %.5f, k %.4g, DT %.3g\n", zetaBB, zetaBW, KN, DT);
    if (!strcmp(TEST, "incline")) testIncline();
    else if (!strcmp(TEST, "gdrop") || !strcmp(TEST, "ghollow")) testGlued();
    else if (!strcmp(TEST, "lid")) testLid();
    else testDrop();
    return 0;
  }
  LOCKZ = !PLATES;
  if (PLATES && which != 2) { fprintf(stderr, "PLATES=1 only for BOX=right (no big bead)\n"); return 1; }
  setStiffness();
  pour(which);
  int nsub = (int)ceil((1.0 / 60) / DT);
  DT = (1.0 / 60) / nsub;
  double Mtot = 0;
  for (int i = 0; i < N; i++) Mtot += mass[i];
  double W = Mtot * G;
  printf("# bead-bed: BOX=%s Gamma %.2f f %.1f Hz A %.2f mm; MODEL %d TC %.3g s (shaking period %.4f s, ratio %.1e) DT %.3g (%d steps/frame) NS %d\n",
         BOXN, GAMMA, FHZ, AMP * 10, MODEL, TC, 1 / FHZ, TC * FHZ, DT, nsub, NS);
  printf("# damping number per contact, two small beads (2 z w0 DT, linear; explicit damping needs it well under 2 / (contacts per bead)): %.3f\n",
         MODEL == 0 ? 2 * zetaBB * (M_PI / TC) * DT : -1);
  printf("# MUB %.3g MUW %.3g MUF %.3g MUP %.3g E %.3g EW %.3g (zeta %.4f, %.4f) KT %.3f ROLL %.3g PLATES %d GAP %.3f SEED %d POLY %.2f N %d\n",
         MUB, MUW, MUF, MUP, EB, EW, zetaBB, zetaBW, KT, ROLL, PLATES, GAP, SEED, POLY, NSM);
  printf("# W %.2f RB %.2f RHOB %.4g ROUGH %d ROUGHF %d RG %.3f SG %.3f GEMB %.2f GJIT %.2f MUG %.3g EG %.3g (glued: %d, %d, %d; reach %.3f) ETH %.3g ELOW %.3g\n",
         W_IN, R_B, RHOB, ROUGH, ROUGHF, RG, SG, GEMB, GJIT, MUG, EG, nG[0], nG[1], nG[2], gluedReach(), ETH, ELOW);
  FILE *lf = LOGF[0] ? fopen(LOGF, "w") : NULL;
  if (lf) fprintf(lf, "t,special_height,surface,special_x\n");

  /* the measurements */
  double pushSum[200] = { 0 }, vrelSum[200] = { 0 };
  long pushN[200] = { 0 };
  double reached = -1;
  long upN = 0, upHalf = 0, lateN = 0, lateUp = 0, lateTop = 0;
  double lateH = 0, lateHC = 0;
  double midSum = 0, wallSum = 0, upX = 0, downX = 0;
  long midN = 0, wallN = 0, upNN = 0, downNN = 0;
  int trips = 0, zoneTop = 0, haveSample = 0, reportedConv = 0;
  double lastT = 0, lastP[MAXB][2], lastYs = 0, convMid = 0, convWall = 0;
  double tf = -SETTLE;      /* the frame clock */
  long frame = 0, stepNo = 0;
  clock_t c0 = clock();
  forces();
  for (int i = 0; i < N; i++) for (int k = 0; k < 3; k++) { a_old[i][k] = f[i][k] / mass[i]; al_old[i][k] = tq[i][k] / inert[i]; }
  double ovSum = 0; long ovN = 0; double ovMax = 0, setMax = 0, setSum = 0; long setN = 0;
  while (tf < TEND) {
    for (int k = 0; k < nsub; k++) {
      double tt = tf + k * DT;
      int cyc = (int)floor(tt * FHZ);
      int watch = tt > 0 && cyc >= 4 && cyc < 32;
      double P0 = 0;
      if (watch) for (int i = 0; i < N; i++) P0 += mass[i] * v[i][1];
      /* the box at the end of this step */
      double te = tt + DT;
      boxy = te > 0 ? AMP * sin(OMEGA * te) : 0;
      boxv = te > 0 ? AMP * OMEGA * cos(OMEGA * te) : 0;
      nContacts = 0; sumOverlap = 0; maxOverlap = 0;
      step();
      stepNo++;
      if (tt > 0) { ovSum += nContacts ? sumOverlap / nContacts : 0; ovN++; if (maxOverlap > ovMax) ovMax = maxOverlap; }
      else if (tt > -0.1) { if (maxOverlap > setMax) setMax = maxOverlap; setSum += nContacts ? sumOverlap / nContacts : 0; setN++; }
      if (tt < 0 && tt + DT >= 0) {
        /* the settled bed, just before the shaking starts: its overlaps over
         * the last 0.1 s (relative to R_eff), against the static estimate (a
         * column of the bed's depth on one contact: about 12 m g / k), and its
         * kinetic energy per bead against m g d */
        double ke = 0;
        for (int i = 0; i < N; i++) ke += 0.5 * mass[i] * dot(v[i], v[i]) + 0.5 * inert[i] * dot(w[i], w[i]);
        printf("RESULT_SETTLE ovmax=%.3e ovmean=%.3e static_est=%.3e ke_per_bead_over_mgd=%.3e\n", setMax, setN ? setSum / setN : 0,
               MODEL == 0 ? 12 * meanSmallMass() * G / KN / (R_S / 2) : 0, ke / N / (meanSmallMass() * G * 2 * R_S));
        fflush(stdout);
      }
      if (watch) {
        double P = 0;
        for (int i = 0; i < N; i++) P += mass[i] * v[i][1];
        double push = (P - P0) / DT + W;
        int bin = (int)floor((tt * FHZ - cyc) * 180);
        if (bin >= 0 && bin < 180) {
          pushSum[bin] += push;
          vrelSum[bin] += P / Mtot - boxv;
          pushN[bin]++;
        }
      }
    }
    tf += 1.0 / 60;
    frame++;
    /* after the frame */
    double by = tf > 0 ? AMP * sin(OMEGA * tf) : 0;
    double ys[MAXB];
    for (int i = 0; i < NSM; i++) ys[i] = x[i][1];
    /* sort (insertion: small) */
    for (int i = 1; i < NSM; i++) { double t = ys[i]; int j = i - 1; while (j >= 0 && ys[j] > t) { ys[j + 1] = ys[j]; j--; } ys[j + 1] = t; }
    double sum = 0; int n = 0;
    for (int i = (int)floor(NSM * 0.9) - 1; i < NSM; i++) { sum += ys[i]; n++; }   /* (lua: indices floor(0.9 N)..N, 1-based) */
    double top = sum / n + R_S;
    double ysp = x[N - 1][1], rs = rad[N - 1];
    if (tf > 0 && reached < 0 && ysp + rs > top - 0.3) {
      reached = tf;
      printf("  the %s bead reaches the top at %.2f s (%d shakes), having risen %.2f cm\n", BIG ? "big" : "coloured", tf,
             (int)floor(tf * FHZ), ysp - by - rs);
    }
    if (reached >= 0 && BIG) { upN++; if (ysp - by > (top - by) / 2) upHalf++; }
    /* the last 20 s: the special bead's time in the upper half, at the top,
     * and its mean height (bottom 0, the bed's top 1) */
    if (tf > TEND - 20) {
      lateN++;
      if (ysp - by > (top - by) / 2) lateUp++;
      if (ysp + rs > top - 0.3) lateTop++;
      /* (and against the bed's depth taken as twice its centre of mass's
       * height, which a few beads thrown high don't move) */
      double ycm = 0;
      for (int q = 0; q < NSM; q++) ycm += x[q][1] - by;
      lateHC += (ysp - by) / (2 * ycm / NSM);
      lateH += (ysp - rs - by - (ROUGHF ? gluedReach() : 0)) / (top - by - 2 * rs - (ROUGHF ? gluedReach() : 0));
    }
    if (tf > CONVSTART && (!haveSample || tf - lastT >= 0.5)) {
      if (haveSample && !reportedConv) {
        for (int i = 0; i < NSM; i++) {
          double dx = fabs(lastP[i][0]), dy = ((x[i][1] - by) - lastP[i][1]) / (tf - lastT);
          if (dx < 3) { midSum += dy; midN++; }
          else if (dx > W_IN / 2 - 2.5) { wallSum += dy; wallN++; }
        }
        if (!BIG) {
          double h = ysp - by - rs, depth = top - by, sdx = fabs(x[N - 1][0]), dyS = ysp - lastYs;
          if (dyS > 0) { upX += sdx; upNN++; } else { downX += sdx; downNN++; }
          if (h > depth * 2 / 3 && !zoneTop) zoneTop = 1;
          if (h < depth / 3 && zoneTop) { zoneTop = 0; trips++; }
        }
      }
      for (int i = 0; i < NSM; i++) { lastP[i][0] = x[i][0]; lastP[i][1] = x[i][1] - by; }
      lastYs = ysp;
      lastT = tf;
      haveSample = 1;
    }
    if (lf && frame % 6 == 0) fprintf(lf, "%.3f,%.4f,%.4f,%.4f\n", tf, ysp - by, top - by, x[N - 1][0]);
    if (tf > 32.0 / FHZ + 0.02 && tf - 1.0 / 60 <= 32.0 / FHZ + 0.02) {
      /* the push report */
      int off = -1, landed = -1;
      double least = 1e9;
      for (int b = 0; b < 45; b++) {
        if (!pushN[b]) continue;
        double p = pushSum[b] / pushN[b] / W;
        if (p < least) least = p;
        if (off < 0 && p < 0.1) off = 2 * b;
        if (landed < 0 && vrelSum[b] / pushN[b] >= 0) landed = 2 * b;
      }
      int b19 = (int)floor((GAMMA > 1 ? asin(1 / GAMMA) : M_PI / 2) * 180 / M_PI / 2);
      double vdown = pushN[b19] ? -vrelSum[b19] / pushN[b19] : 0;
      printf("  Gamma %.2f: least push in 0-90 deg %.3f W (rigid bed %.2f); lifts off %d deg; landed %d deg; CoM approach at %d-%d deg %.1f cm/s\n",
             GAMMA, least, 1 - GAMMA, off, landed, 2 * b19, 2 * b19 + 2, vdown);
      printf("RESULT_PHASE least=%.4f off=%d landed=%d vdown19=%.2f\n", least, off, landed, vdown);
      if (lf) {
        char pf[300];
        snprintf(pf, sizeof pf, "%s.phase", LOGF);
        FILE *pp = fopen(pf, "w");
        if (pp) {
          fprintf(pp, "deg,push_over_W,vrel\n");
          for (int b = 0; b < 180; b++) if (pushN[b]) fprintf(pp, "%d,%.4f,%.3f\n", 2 * b, pushSum[b] / pushN[b] / W, vrelSum[b] / pushN[b]);
          fclose(pp);
        }
      }
      fflush(stdout);
    }
    if (!reportedConv && tf > CONVEND) {
      reportedConv = 1;
      convMid = midN ? midSum / midN * 10 : 0;
      convWall = wallN ? wallSum / wallN * 10 : 0;
      printf("  from %.0f s to %.0f s: beads in the middle rising %.2f mm/s, beside the walls %.2f mm/s\n", CONVSTART, CONVEND, convMid, convWall);
      fflush(stdout);
    }
  }
  double cpu = (double)(clock() - c0) / CLOCKS_PER_SEC;
  double simT = tf + SETTLE;
  printf("RESULT box=%s gamma=%.2f model=%d tc=%.3g ns=%d seed=%d mub=%.3g muw=%.3g e=%.3g plates=%d reached=%.3f upper=%.3f mid=%.3f wall=%.3f trips=%d upx=%.2f downx=%.2f"
         " ovmean=%.2e ovmax=%.2e cpu_per_s=%.3f up20=%.3f top20=%.3f h20=%.3f hc20=%.3f\n",
         BOXN, GAMMA, MODEL, TC, NS, SEED, MUB, MUW, EB, PLATES, reached, upN ? (double)upHalf / upN : -1, convMid, convWall, trips,
         upNN ? upX / upNN : -1, downNN ? downX / downNN : -1, ovN ? ovSum / ovN : 0, ovMax, cpu / simT,
         lateN ? (double)lateUp / lateN : -1, lateN ? (double)lateTop / lateN : -1, lateN ? lateH / lateN : -1, lateN ? lateHC / lateN : -1);
  if (lf) fclose(lf);
  return 0;
}
