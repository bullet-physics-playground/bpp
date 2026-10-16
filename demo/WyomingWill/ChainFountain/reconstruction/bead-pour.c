/*
 * The chain fountain from a poured heap, outside bpp and Bullet: a ball
 * chain as beads on rods, every bead simulated. It is fed into the jar from
 * above, as Biggins and Warner fed theirs into the beaker "in a random
 * configuration", and left to settle. Then its end is drawn up over the rim
 * and down to the floor, as by hand, and let go. The control is the same
 * chain laid as the exhibit's coil (LAYOUT=1, LAYERS layers on the jar's
 * floor), settled and pulled over in the same way.
 *
 * The chain: beads of diameter D, one every L, joined by rods that can't
 * stretch (or, with PLAY > 0, can shorten by up to PLAY: the real chain's
 * rods slide in the balls). The chain bends at most BEND degrees at a bead,
 * kept as the least distance 2 L cos(BEND/2) between a bead and the next
 * but one. Beads don't pass through each other, the jar's floor or its
 * wall (inside, rim and outside). With ROD > 0 the rods are solid too,
 * cylinders of radius ROD that touch each other and the glass: without
 * them a chain of 4.5 mm beads 6.5 mm apart can pass through itself (two
 * rods crossing at their middles leave the four beads 4.6 mm apart).
 * Contacts are perfectly inelastic, with Coulomb friction MU (MURIM on the
 * glass). Gravity. No air, no bead spin.
 *
 * How it moves: XPBD with small steps (Macklin et al., "Small steps in
 * physics simulation", SCA 2019; from memory): substeps of HS seconds, each
 * ITERS passes of the constraints (rods, bending limits, contacts, all
 * stiff), the velocity taken from what each bead moved. Friction is applied once a
 * substep, on the velocities, limited by MU times the contact's normal
 * impulse (Mueller et al., "Detailed rigid body simulation with extended
 * position based dynamics", SCA 2020). (Applying it in the position passes,
 * as bead-chain.c does, lets the chain grip the rim far harder than Coulomb
 * allows: there the tension just outside the rim was 50 times that inside,
 * where e^(MU pi) = 2.6. That jammed its longer runs.)
 *
 * Friction checks (LAYOUT=2, 3; a straight chain of NB beads drawn along,
 * the pull against Coulomb's mu (n-1) m g): on the floor 1.000; in a
 * groove of two fixed rows of beads 1.087 with 4 passes of 1e-5 s, the
 * same with 2 or 8 passes, or 1 pass of 7e-6 s or less; of the 1.087, 0.09
 * is the bumps of the rows (it is there with MU=0). One pass of 1e-5 s
 * gives 5.0, and 2 passes of 2e-5 s 4.5: the passes fight, and friction,
 * limited by an overdone normal push, holds too hard. So ITERS=4, HS=1e-5
 * at least. (Until 16 Oct 2026 the groove was shorter than the pull and the
 * chain ran off its end; that check read 3.8 whatever the setting.)
 *
 * The run:
 *   pour   the beads hang in a vertical line above a feed point POURH cm
 *          over the jar's floor that wanders at random within POURR cm of
 *          the axis (SEED); the line is lowered at FEED cm/s and each bead
 *          is let go as it passes the feed point. The lead's end goes last.
 *   settle until the fastest bead is slower than 1 cm/s (at most 2 s).
 *   pull   the end is drawn straight up to 4 cm over the rim and out to
 *          x = 12 cm at PULL cm/s, then down to 3.5 cm above the floor at
 *          1.2 g (faster than the chain could fall, so it is drawn taut and
 *          never folds on itself), and let go there (t = 0), as "dragged
 *          over the rim and released" (Biggins 2014).
 *   flow   a bead below 2.5 cm is frozen and its rod cut (b = 0), as in
 *          the exhibit. Measured from T0 s after letting go until the
 *          pick-up is 40 beads from the end, as in bead-chain.c:
 *          v (landing rate), vrms, h1, h2 (top of the moving chain above
 *          the pick-up), the unmoved pile's push, the rim's push, and the
 *          push the falling chain carries (from the rods' tension).
 *
 *   cc -O2 -o bead-pour bead-pour.c -lm
 *   ./bead-pour [key=value ...]   NB=1500 L=0.65 D=0.45 ROD=0 BEND=30
 *     MU=0.3 MURIM=-1 PLAY=0 H=150 RJ=7 JH=8 HS=1e-5 ITERS=4 SEED=1
 *     LAYOUT=0 LAYERS=4 POURH=6 POURR=2 FEED=100 PULL=150 T0=1.0 TMAX=5
 *     DUMPT=-1 LOG=file.csv
 *   (the heap test, 16 Oct 2026: NB=1500 D=0.45 ROD=0.05, SEED=1-3, and
 *   LAYOUT=1 for the coil)
 *   SAVE=file writes the settled heap, LOAD=file starts from one (it settles
 *   again, then is pulled over)
 *   (fed from 2 cm under the rim: from higher up, loops of chain landed on
 *   the rim and slid over it, and the chain then hung on both sides; a run
 *   is refused if any bead ends up outside the jar)
 *
 * Units: cm, s; each bead's mass is 1 (it cancels).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

static double L = 0.65, D = 0.45, BEND = 30, MU = 0.3, MURIM = -1, PLAY = 0, ROD = 0;
static double HJ = 150, RJ = 7, JH = 8, HS = 1e-5, POURH = 6, POURR = 2, FEED = 100, PULL = 150;
static double T0 = 1.0, TMAX = 5, DUMPT = -1;
static int NB = 1500, SEED = 1, LAYOUT = 0, LAYERS = 4, ITERS = 4;
static const char *LOGF = NULL, *SAVEF = NULL, *LOADF = NULL;
#define G 981.0
#define YF 2.5
#define DUMP_BEADS 0

typedef struct { double x[3], p[3], v[3]; int kin, frozen; } Bead;
static Bead *b;
static int N;
static int *cut;

static void arg(const char *s) {
  char k[32]; double v;
  if (!strncmp(s, "LOG=", 4)) { LOGF = s + 4; return; }
  if (!strncmp(s, "SAVE=", 5)) { SAVEF = s + 5; return; }
  if (!strncmp(s, "LOAD=", 5)) { LOADF = s + 5; return; }
  if (sscanf(s, "%31[^=]=%lf", k, &v) != 2) { fprintf(stderr, "bad %s\n", s); exit(1); }
#define P(n) if (!strcmp(k, #n)) { n = v; return; }
  P(L) P(D) P(ROD) P(BEND) P(MU) P(MURIM) P(PLAY) P(RJ) P(JH) P(HS) P(POURH) P(POURR) P(FEED) P(PULL) P(T0) P(TMAX) P(DUMPT)
  if (!strcmp(k, "H")) { HJ = v; return; }
  if (!strcmp(k, "NB")) { NB = (int)v; return; }
  if (!strcmp(k, "SEED")) { SEED = (int)v; return; }
  if (!strcmp(k, "LAYOUT")) { LAYOUT = (int)v; return; }
  if (!strcmp(k, "LAYERS")) { LAYERS = (int)v; return; }
  if (!strcmp(k, "ITERS")) { ITERS = (int)v; return; }
  fprintf(stderr, "unknown %s\n", k); exit(1);
}

static double urand(void) { return rand() / (RAND_MAX + 1.0); }

/* contacts recorded in the position pass, for friction in the velocity pass */
typedef struct { int a, bb; double n[3], dn; double mu; } Contact;   /* bb < 0: the jar */
static Contact *cs; static int ncs, maxcs;
static void addContact(int a, int bb, const double *n, double dn, double mu) {
  if (ncs == maxcs) { maxcs = maxcs ? 2 * maxcs : 65536; cs = realloc(cs, maxcs * sizeof *cs); }
  cs[ncs].a = a; cs[ncs].bb = bb; memcpy(cs[ncs].n, n, 3 * sizeof(double)); cs[ncs].dn = dn; cs[ncs].mu = mu; ncs++;
}

/* the rods (ROD > 0): rod i, from bead i to bead i+1, is a cylinder of
   radius ROD round the line between their centres. Without them a chain
   of 4.5 mm beads 6.5 mm apart can pass through itself: two rods crossing
   at their middles leave the four beads 4.6 mm apart. A rod touches
   another rod (t >= 0: the nearest points, at u along rod s and w along
   rod t) or the jar (t < 0: at u along rod s, three points on the bare
   part of the rod). The push is shared between the two beads of a rod as
   u says; friction as for the beads. */
typedef struct { int s, t; double u, w, n[3], lam, W; } RodC;
static RodC *rc; static int nrc, maxrc;
static void addRod(int s, int t, double u, double w) {
  if (nrc == maxrc) { maxrc = maxrc ? 2 * maxrc : 65536; rc = realloc(rc, maxrc * sizeof *rc); }
  RodC *c = &rc[nrc++]; c->s = s; c->t = t; c->u = u; c->w = w; c->n[0] = 0; c->n[1] = 1; c->n[2] = 0; c->lam = 0; c->W = 0;
}
static double dot3(const double *a, const double *c) { return a[0] * c[0] + a[1] * c[1] + a[2] * c[2]; }
static double clamp01(double x) { return x < 0 ? 0 : (x > 1 ? 1 : x); }
/* the nearest points of segments p1-q1 and p2-q2 (Ericson, Real-Time
   Collision Detection, 5.1.9) */
static void segNearest(const double *p1, const double *q1, const double *p2, const double *q2, double *S, double *T) {
  double d1[3], d2[3], r[3];
  for (int c = 0; c < 3; c++) { d1[c] = q1[c] - p1[c]; d2[c] = q2[c] - p2[c]; r[c] = p1[c] - p2[c]; }
  double a = dot3(d1, d1), e = dot3(d2, d2), f = dot3(d2, r), cc = dot3(d1, r), bb = dot3(d1, d2), den = a * e - bb * bb;
  double s = den > 1e-14 ? clamp01((bb * f - cc * e) / den) : 0, t = (bb * s + f) / e;
  if (t < 0) { t = 0; s = clamp01(-cc / a); } else if (t > 1) { t = 1; s = clamp01((bb - cc) / a); }
  *S = s; *T = t;
}
/* a point's distance from the jar's glass (inside, rim, outside), and the
   way out of it */
static double glassDist(const double *x, double floorJ, double rim, double *nn) {
  double rr = sqrt(x[0] * x[0] + x[2] * x[2]);
  double cr = fmin(fmax(rr, RJ), RJ + 1), cyy = fmin(fmax(x[1], floorJ - 10), rim);
  double er = rr - cr, ey = x[1] - cyy, dd = sqrt(er * er + ey * ey), nr, ny;
  if (dd > 1e-9) { nr = er / dd; ny = ey / dd; } else { nr = rr < RJ + 0.5 ? -1 : 1; ny = 0; }
  double ux = rr > 1e-9 ? x[0] / rr : 1, uz = rr > 1e-9 ? x[2] / rr : 0;
  nn[0] = nr * ux; nn[1] = ny; nn[2] = nr * uz;
  return dd;
}
/* (a rod cut at the floor, or with a bead frozen there, no longer collides) */
static int rodGone(const RodC *c) {
  if (cut[c->s] || b[c->s].frozen || b[c->s + 1].frozen) return 1;
  return c->t >= 0 && (cut[c->t] || b[c->t].frozen || b[c->t + 1].frozen);
}
static void solveRods(double floorJ, double rim) {
  for (int k = 0; k < nrc; k++) {
    RodC *c = &rc[k];
    if (rodGone(c)) continue;
    Bead *A = &b[c->s], *B = &b[c->s + 1];
    double wA = A->kin ? 0 : 1, wB = B->kin ? 0 : 1, nn[3], C, W, u;
    if (c->t >= 0) {
      Bead *E = &b[c->t], *F = &b[c->t + 1];
      double wE = E->kin ? 0 : 1, wF = F->kin ? 0 : 1, w, P[3], Q[3], d[3];
      segNearest(A->x, B->x, E->x, F->x, &u, &w);
      for (int q = 0; q < 3; q++) { P[q] = A->x[q] + u * (B->x[q] - A->x[q]); Q[q] = E->x[q] + w * (F->x[q] - E->x[q]); d[q] = Q[q] - P[q]; }
      double n = sqrt(dot3(d, d));
      if (n < 1e-12) continue;
      for (int q = 0; q < 3; q++) nn[q] = d[q] / n;
      C = n - 2 * ROD;
      W = (1 - u) * (1 - u) * wA + u * u * wB + (1 - w) * (1 - w) * wE + w * w * wF;
      if (W == 0) continue;
      double dl = -C / W;
      if (c->lam + dl < 0) dl = -c->lam;
      c->u = u; c->w = w; c->W = W; memcpy(c->n, nn, sizeof nn);
      if (dl == 0) continue;
      for (int q = 0; q < 3; q++) {
        A->x[q] -= (1 - u) * wA * dl * nn[q]; B->x[q] -= u * wB * dl * nn[q];
        E->x[q] += (1 - w) * wE * dl * nn[q]; F->x[q] += w * wF * dl * nn[q];
      }
      c->lam += dl;
    } else {
      double P[3];
      u = c->u;
      for (int q = 0; q < 3; q++) P[q] = A->x[q] + u * (B->x[q] - A->x[q]);
      C = glassDist(P, floorJ, rim, nn) - ROD;
      W = (1 - u) * (1 - u) * wA + u * u * wB;
      if (W == 0) continue;
      double dl = -C / W;
      if (c->lam + dl < 0) dl = -c->lam;
      c->W = W; memcpy(c->n, nn, sizeof nn);
      if (dl == 0) continue;
      for (int q = 0; q < 3; q++) { A->x[q] += (1 - u) * wA * dl * nn[q]; B->x[q] += u * wB * dl * nn[q]; }
      c->lam += dl;
    }
  }
}
static void rodFriction(void) {
  for (int k = 0; k < nrc; k++) {
    RodC *c = &rc[k];
    if (c->lam <= 0 || c->W <= 0 || rodGone(c)) continue;
    Bead *A = &b[c->s], *B = &b[c->s + 1], *E = c->t >= 0 ? &b[c->t] : NULL, *F = c->t >= 0 ? &b[c->t + 1] : NULL;
    double u = c->u, w = c->w, wA = A->kin ? 0 : 1, wB = B->kin ? 0 : 1, wE = E && !E->kin ? 1 : 0, wF = F && !F->kin ? 1 : 0;
    double vr[3];
    for (int q = 0; q < 3; q++) vr[q] = (E ? (1 - w) * E->v[q] + w * F->v[q] : 0) - ((1 - u) * A->v[q] + u * B->v[q]);
    double vn = dot3(vr, c->n), vt[3];
    for (int q = 0; q < 3; q++) vt[q] = vr[q] - vn * c->n[q];
    double vtl = sqrt(dot3(vt, vt));
    if (vtl < 1e-12) continue;
    double dv = fmin((E ? MU : MURIM) * c->lam * c->W / HS, vtl), J = dv / c->W;
    for (int q = 0; q < 3; q++) {
      double tq = J * vt[q] / vtl;
      A->v[q] += (1 - u) * wA * tq; B->v[q] += u * wB * tq;
      if (E) { E->v[q] -= (1 - w) * wE * tq; F->v[q] -= w * wF * tq; }
    }
  }
}

int main(int argc, char **argv) {
  setvbuf(stdout, NULL, _IOLBF, 0);
  for (int i = 1; i < argc; i++) arg(argv[i]);
  if (MURIM < 0) MURIM = MU;
  srand(SEED);
  double th = BEND * M_PI / 180, dmin = 2 * L * cos(th / 2), rim = HJ + JH, Ro = RJ - D / 2 - 0.05;
  double floorJ = HJ;                                 /* the jar's floor */
  int cap = 40 * NB + 200 + (LAYOUT == 3 ? (int)(2 * (NB * L + PULL + 4) / 0.05) + 200 : 0);
  b = calloc(cap, sizeof *b); cut = calloc(cap, sizeof *cut);
  N = NB;
  int nLead = 0;
  if (LAYOUT == 0) {
    /* the chain, end first, on a vertical line above the feed point: bead
       N-1 lowest (it goes in first), bead 0 (the end) highest */
    for (int i = 0; i < N; i++) { b[i].x[0] = 0; b[i].x[1] = floorJ + POURH + (N - 1 - i) * L; b[i].x[2] = 0; b[i].kin = 1; }
  } else {
    /* the exhibit's coil, LAYERS layers on the jar's floor, the end at the
       top layer's outer edge (it is pulled over the rim as the heap's is) */
    double LT = D + 0.05, ytop = HJ + D / 2 + (LAYERS - 1) * LT;
    double tip = asin(LT / 3 / L), turn = sqrt(fmax(th * th - tip * tip, 1e-6));
    double Ri = fmax(L / (2 * sin(turn / 2)) + 0.1, 1.0), pitch = (D + 0.1) / (2 * M_PI);
    int cap = 1 << 22, np = 0; double (*path)[3] = malloc(cap * sizeof *path);
#define ADD(X, Y, Z) do { path[np][0] = (X); path[np][1] = (Y); path[np][2] = (Z); np++; } while (0)
    ADD(Ro, ytop, 0);
    int leadPts = 0;
    double phi = 0, r = Ro, y = ytop;
    for (int lay = 0; lay < LAYERS; lay++) {
      int dir = lay % 2 ? 1 : -1;
      if (lay > 0) { double len = 3 * L, s = 0; while (s < len) { phi += 0.01 / r; y -= LT * 0.01 / len; s += 0.01; ADD(r * cos(phi), y, r * sin(phi)); } }
      for (;;) { double r2 = r + dir * pitch * 0.01 / r; if ((dir < 0 && r2 < Ri) || (dir > 0 && r2 > Ro)) break; phi += 0.01 / r; r = r2; ADD(r * cos(phi), y, r * sin(phi)); }
    }
    memcpy(b[0].x, path[0], sizeof b[0].x); N = 1; nLead = -1;
    for (int k = 1; k < np && N < NB; k++) {
      double *A = path[k - 1], *B = path[k], *Pp = b[N - 1].x, dB = 0;
      for (int c = 0; c < 3; c++) dB += (B[c] - Pp[c]) * (B[c] - Pp[c]);
      if (dB < L * L) continue;
      double lo = 0, hi = 1, q[3];
      for (int it = 0; it < 60; it++) { double m = (lo + hi) / 2, d2 = 0; for (int c = 0; c < 3; c++) { q[c] = A[c] + m * (B[c] - A[c]); d2 += (q[c] - Pp[c]) * (q[c] - Pp[c]); } if (d2 < L * L) lo = m; else hi = m; }
      memcpy(b[N].x, q, sizeof q); if (nLead < 0 && k >= leadPts) nLead = N; N++; k--;
    }
    free(path);
    (void)nLead;
  }
  /* friction checks (LAYOUT=2, 3): a straight chain of NB beads lying on
     the floor (2) or in the groove of two fixed rows of beads (3), its end
     drawn along at PULL cm/s for 1 s; the pull it takes, against Coulomb */
  if (LAYOUT >= 2) {
    double y0 = floorJ + D / 2, zz = 0, cphi = 1;
    int nb = NB; double PF = 0.05;                      /* (the fixed rows: a bead every PF, a smooth rail) */
    int nf = (int)((nb * L + PULL * 0.9 + 4) / PF) + 40;   /* (long enough for the whole pull)  */
    N = LAYOUT == 2 ? nb : nb + 2 * nf;
    if (LAYOUT == 3) {
      double off = 0.5 * D * 0.9;                     /* the fixed rows' half spacing */
      double up = sqrt(D * D - off * off);
      cphi = up / D;
      for (int i = 0; i < nf; i++) for (int r = 0; r < 2; r++) {
        Bead *q = &b[nb + 2 * i + r]; q->x[0] = -L * nb / 2 - 2 - PULL * 0.9 + i * PF; q->x[1] = y0; q->x[2] = r ? off : -off; q->kin = 1;
      }
      y0 += up; zz = 0;
    }
    for (int i = 0; i < nb; i++) { b[i].x[0] = -L * nb / 2 + i * L + L / 2; b[i].x[1] = y0; b[i].x[2] = zz; }
    for (int i = 0; i < N; i++) memcpy(b[i].p, b[i].x, sizeof b[i].x);
    for (int i = nb; i < N; i++) cut[i] = 1;          /* (the fixed rows aren't a chain) */
    cut[nb - 1] = 1;
    RJ = 1e4;                                          /* (no wall in the way) */
    b[0].kin = 1;
    double sumT = 0, T01 = 0; long nT = 0, sub2 = 0;
    const int HSZ2 = 1 << 17; int *hd = malloc(HSZ2 * sizeof(int)), *nx = malloc(N * sizeof(int));
    for (double tt = 0; tt < 1.0; tt += HS, sub2++) {
      memcpy(b[0].p, b[0].x, sizeof b[0].x);
      if (tt > 0.1) { b[0].x[0] -= PULL * HS; b[0].v[0] = -PULL; }
      for (int i = 1; i < N; i++) { Bead *q = &b[i]; if (q->kin) continue; memcpy(q->p, q->x, sizeof q->x); q->v[1] -= G * HS; for (int c = 0; c < 3; c++) q->x[c] += q->v[c] * HS; }
      ncs = 0;
      for (int i = 1; i < nb; i++) {                    /* candidate contacts */
        double n3[3] = { 0, 1, 0 };
        if (LAYOUT == 2) addContact(i, -1, n3, 0, MU);
        else {
          int i0 = (int)floor((b[i].x[0] + L * nb / 2 + 2 + PULL * 0.9) / PF);
          for (int di = -6; di <= 6; di++) for (int r = 0; r < 2; r++) { int j = i0 + di; if (j >= 0 && j < nf) addContact(nb + 2 * j + r, i, n3, 0, MU); }
        }
      }
      for (int it = 0; it < ITERS; it++) {
        for (int i = 0; i < nb - 1; i++) {              /* rods */
          Bead *a = &b[i], *c2 = &b[i + 1]; double wa = a->kin ? 0 : 1, wb = 1, d[3], n = 0;
          for (int c = 0; c < 3; c++) { d[c] = c2->x[c] - a->x[c]; n += d[c] * d[c]; } n = sqrt(n);
          double C = n - L; for (int c = 0; c < 3; c++) { double k = C * d[c] / n / (wa + wb); a->x[c] += wa * k; c2->x[c] -= wb * k; }
          if (i == 0) T01 = (it ? T01 : 0) + C / (wa + wb) / (HS * HS);
        }
        for (int k = 0; k < ncs; k++) {                 /* contacts, as in the run */
          Contact *ct = &cs[k];
          if (ct->bb < 0) {
            Bead *q = &b[ct->a]; double C = q->x[1] - (floorJ + D / 2), dl = -C;
            if (ct->dn + dl < 0) dl = -ct->dn;
            q->x[1] += dl; ct->dn += dl;
          } else {
            Bead *a = &b[ct->a], *c2 = &b[ct->bb]; double wa = a->kin ? 0 : 1, wb = 1, d[3], n = 0, nn[3];
            for (int c = 0; c < 3; c++) { d[c] = c2->x[c] - a->x[c]; n += d[c] * d[c]; } n = sqrt(n);
            for (int c = 0; c < 3; c++) nn[c] = d[c] / n;
            double C = n - D, dl = -C / (wa + wb);
            if (ct->dn + dl * (wa + wb) < 0) dl = -ct->dn / (wa + wb);
            for (int c = 0; c < 3; c++) { a->x[c] -= wa * dl * nn[c]; c2->x[c] += wb * dl * nn[c]; }
            ct->dn += dl * (wa + wb); memcpy(ct->n, nn, sizeof nn);
          }
        }
      }
      for (int i = 1; i < nb; i++) for (int c = 0; c < 3; c++) b[i].v[c] = (b[i].x[c] - b[i].p[c]) / HS;
      for (int k = 0; k < ncs; k++) {                   /* friction, as in the run */
        Contact *ct = &cs[k]; Bead *a = &b[ct->bb >= 0 ? ct->bb : ct->a];
        if (ct->dn <= 0) continue;
        double vr[3]; for (int c = 0; c < 3; c++) vr[c] = -a->v[c];
        double vn = vr[0] * ct->n[0] + vr[1] * ct->n[1] + vr[2] * ct->n[2], vt[3], vtl = 0;
        for (int c = 0; c < 3; c++) { vt[c] = vr[c] - vn * ct->n[c]; vtl += vt[c] * vt[c]; } vtl = sqrt(vtl);
        if (vtl < 1e-12) continue;
        double dv = fmin(ct->mu * ct->dn / HS, vtl); for (int c = 0; c < 3; c++) a->v[c] += dv * vt[c] / vtl;
      }
      if (tt > 0.5) { sumT += T01; nT++; }
    }
    (void)hd; (void)nx;
    double expect = MU * (nb - 1) * G / cphi;
    printf("friction check (%s): pull %.1f, Coulomb mu (n-1) m g%s = %.1f: ratio %.3f\n", LAYOUT == 2 ? "chain on the floor" : "chain in a groove of beads",
           sumT / nT, LAYOUT == 3 ? " / cos" : "", expect, sumT / nT / expect);
    return 0;
  }
  int loaded = 0;
  if (LOADF) {                                        /* a settled heap saved before */
    FILE *f = fopen(LOADF, "r"); int n;
    if (!f || fscanf(f, "%d", &n) != 1 || n != N) { fprintf(stderr, "can't load %s\n", LOADF); return 1; }
    for (int i = 0; i < N; i++) { if (fscanf(f, "%lf %lf %lf", &b[i].x[0], &b[i].x[1], &b[i].x[2]) != 3) return 1; b[i].kin = 0; memset(b[i].v, 0, sizeof b[i].v); }
    fclose(f); loaded = 1;
  }
  for (int i = 0; i < N; i++) memcpy(b[i].p, b[i].x, sizeof b[i].x);
  printf("bead chain: %d beads (%.2f m), L=%.3f D=%.3f bend %.0f (least next-but-one %.3f), play %.3f; mu %.2f, glass %.2f; rods %s\n",
         N, N * L / 100, L, D, BEND, dmin, PLAY, MU, MURIM, ROD > 0 ? "solid" : "not colliding");
  if (ROD > 0) printf("rods %.3f cm thick\n", 2 * ROD);
  printf("jar r %.1f, floor %.1f, rim %.1f; %s; substep %.1e s, seed %d\n", RJ, floorJ, rim,
         LAYOUT ? "laid as the exhibit's coil" : "poured", HS, SEED);

  /* spatial hash */
  const int HSZ = 1 << 17;
  int *head = malloc(HSZ * sizeof(int)), *next = malloc(N * sizeof(int));
  double cell = D + 0.1;
  int maxPairs = 64 * N, nPairs; int (*pairs)[2] = malloc(maxPairs * sizeof *pairs);
  double *Tc = calloc(N, sizeof *Tc), *Fy = calloc(N, sizeof *Fy), *Fr = calloc(N, sizeof *Fr);
  int *touch = calloc(N, sizeof *touch);
  int *shead = malloc(HSZ * sizeof(int)), *snext = malloc(N * sizeof(int)), *rodOK = calloc(N, sizeof(int));
  double (*mid)[3] = malloc(N * sizeof *mid);
  FILE *log = LOGF ? fopen(LOGF, "w") : NULL;
  if (log) fprintf(log, "phase,t,h2,h1,pick,landed,ke,vmax\n");

  /* phases: 0 pour, 1 settle, 2 pull, 3 flow */
  int phase = (LAYOUT || loaded) ? 1 : 0;
  double t = 0, tPhase = 0, feedX = 0, feedZ = 0, feedVX = 0, feedVZ = 0;
  int fed = 0;                                        /* beads let go so far (from N-1 down) */
  double pullS = 0, pullStart[3] = { 0 }, pullUp = 0, pullDown = -1;
  int tail = 0, landed = 0, pick = 0, win = 0, wl0 = 0, wl1 = 0;
  double wt0 = 0, wt1 = 0, sh2 = 0, sh1 = 0, srim = 0, sPush = 0, sRim = 0, sCar = 0, sV2 = 0, best = -1e9;
  long sSteps = 0, sCarN = 0; int sn = 0, sLand = 0;
  double nextSample = 0, settleKE = 0, settleVmax = 0, settleT = 0, pourT = 0, maxStretch = 0;
  double lam = 1.0 / L;
  long sub = 0;
  if (LAYOUT == 0 && !loaded) for (int i = 0; i < N; i++) b[i].kin = 1;

  while (1) {
    /* scripted beads: the feed line, or the end being pulled */
    if (phase == 0) {
      /* the feed point wanders: a random walk of its velocity, kept within POURR */
      if (sub % 1000 == 0) {
        feedVX += (urand() - 0.5) * 20; feedVZ += (urand() - 0.5) * 20;
        double r = sqrt(feedX * feedX + feedZ * feedZ);
        if (r > POURR) { feedVX -= 5 * feedX / r; feedVZ -= 5 * feedZ / r; }
        double sp = sqrt(feedVX * feedVX + feedVZ * feedVZ); if (sp > 20) { feedVX *= 20 / sp; feedVZ *= 20 / sp; }
      }
      feedX += feedVX * HS; feedZ += feedVZ * HS;
      double yFeed = floorJ + POURH;
      for (int i = 0; i < N - fed; i++) {             /* the line still held: beads 0 .. N-1-fed */
        Bead *q = &b[i];
        memcpy(q->p, q->x, sizeof q->x);
        q->x[0] = feedX; q->x[2] = feedZ; q->x[1] -= FEED * HS;
        q->v[0] = feedVX; q->v[1] = -FEED; q->v[2] = feedVZ;
      }
      while (fed < N && b[N - 1 - fed].x[1] < yFeed) { b[N - 1 - fed].kin = 0; fed++; }
    } else if (phase == 2) {
      Bead *q = &b[0];
      memcpy(q->p, q->x, sizeof q->x);
      pullS += PULL * HS;
      /* the path: up pullUp, out to x = 12 (in a line), down to 3.5 */
      double topY = rim + 4, outX = 12;
      double seg1 = pullUp, dx = outX - pullStart[0], dz = -pullStart[2], seg2 = sqrt(dx * dx + dz * dz), seg3 = topY - (YF + 1);
      double s = pullS, P0[3];
      if (s < seg1) { P0[0] = pullStart[0]; P0[1] = pullStart[1] + s; P0[2] = pullStart[2]; }
      else if (s < seg1 + seg2) { double f = (s - seg1) / seg2; P0[0] = pullStart[0] + f * dx; P0[1] = topY; P0[2] = pullStart[2] + f * dz; }
      else {
        /* down, faster than the chain could fall (1.2 g), so it is pulled
           taut and never folds on itself */
        if (pullDown < 0) pullDown = tPhase;
        double td = tPhase - pullDown, f = fmin(1, 0.5 * 1.2 * G * td * td / seg3);
        P0[0] = outX; P0[1] = topY - f * seg3; P0[2] = 0;
        if (f >= 1) s = seg1 + seg2 + seg3;
      }
      for (int c = 0; c < 3; c++) { q->v[c] = (P0[c] - q->x[c]) / HS; q->x[c] = P0[c]; }
      if (s >= seg1 + seg2 + seg3) {                  /* let go */
        q->kin = 0; phase = 3; t = 0; nextSample = 0;
        printf("pulled over in %.2f s; let go\n", tPhase);
      }
    }
    /* predict */
    for (int i = tail; i < N; i++) {
      Bead *q = &b[i];
      if (q->kin || q->frozen) continue;
      memcpy(q->p, q->x, sizeof q->x);
      q->v[1] -= G * HS;
      for (int c = 0; c < 3; c++) q->x[c] += q->v[c] * HS;
    }
    /* candidate pairs (free beads, and the held ones near the jar) */
    for (int k = 0; k < HSZ; k++) head[k] = -1;
    for (int i = tail; i < N; i++) {
      if (b[i].frozen) continue;
      if (b[i].kin && phase == 0 && b[i].x[1] > floorJ + POURH + 1) continue;
      int ix = (int)floor(b[i].x[0] / cell), iy = (int)floor(b[i].x[1] / cell), iz = (int)floor(b[i].x[2] / cell);
      unsigned h = ((unsigned)(ix * 73856093) ^ (unsigned)(iy * 19349663) ^ (unsigned)(iz * 83492791)) & (HSZ - 1);
      next[i] = head[h]; head[h] = i;
    }
    nPairs = 0;
    for (int i = tail; i < N; i++) {
      if (b[i].frozen) continue;
      if (b[i].kin && phase == 0 && b[i].x[1] > floorJ + POURH + 1) continue;
      int ix = (int)floor(b[i].x[0] / cell), iy = (int)floor(b[i].x[1] / cell), iz = (int)floor(b[i].x[2] / cell);
      for (int dx = -1; dx <= 1; dx++) for (int dy = -1; dy <= 1; dy++) for (int dz = -1; dz <= 1; dz++) {
        unsigned h = ((unsigned)((ix + dx) * 73856093) ^ (unsigned)((iy + dy) * 19349663) ^ (unsigned)((iz + dz) * 83492791)) & (HSZ - 1);
        for (int j = head[h]; j >= 0; j = next[j]) {
          if (j <= i + 2) continue;
          double d2 = 0; for (int c = 0; c < 3; c++) d2 += (b[i].x[c] - b[j].x[c]) * (b[i].x[c] - b[j].x[c]);
          if (d2 < (D + 0.05) * (D + 0.05) && nPairs < maxPairs) { pairs[nPairs][0] = i; pairs[nPairs][1] = j; nPairs++; }
        }
      }
    }
    int flow = phase == 3;
    for (int i = tail; i < N; i++) { Tc[i] = 0; Fy[i] = 0; Fr[i] = 0; touch[i] = 0; }
    ncs = 0;
    /* ITERS passes of the constraints. The contacts keep their push (lambda,
       the distance moved along the normal) across the passes and may give
       back what an earlier pass overdid, never pulling (lambda >= 0): so
       lambda converges to the true normal impulse x HS, and friction, which
       is limited by it, is right where a bead rests on several others.
       (With one pass of 1e-5 s a bead in a groove of two others is still
       held 5 times harder than Coulomb allows: see the friction checks
       at the top.) */
    ncs = 0;
    for (int k = 0; k < nPairs; k++) {                  /* the candidate contacts */
      double nn[3] = { 0, 1, 0 };
      addContact(pairs[k][0], pairs[k][1], nn, 0, MU);
    }
    for (int i = tail; i < N; i++) {
      Bead *q = &b[i];
      if (q->kin || q->frozen) continue;
      double rr = sqrt(q->x[0] * q->x[0] + q->x[2] * q->x[2]), n3[3] = { 0, 1, 0 };
      if (rr < RJ && q->x[1] < floorJ + D / 2 + 0.05 && q->x[1] > floorJ - 1) addContact(i, -1, n3, 0, MURIM);
      double cr = fmin(fmax(rr, RJ), RJ + 1), cyy = fmin(fmax(q->x[1], floorJ - 10), rim);
      double er = rr - cr, ey = q->x[1] - cyy;
      if (er * er + ey * ey < (D / 2 + 0.05) * (D / 2 + 0.05)) addContact(i, -2, n3, 0, MURIM);
    }
    if (ROD > 0 && sub % 4) for (int k = 0; k < nrc; k++) rc[k].lam = 0;
    else nrc = 0;
    if (ROD > 0 && sub % 4 == 0) {
      /* the rods' candidate contacts, found every fourth substep with room
         to spare (a bead moves 0.02 cm in four at 5 m/s): rods whose
         middles are near enough (a hash of the middles), and points of rods
         near the glass */
      double scell = L + 2 * ROD + 0.08;
      for (int k = 0; k < HSZ; k++) shead[k] = -1;
      for (int i = tail; i < N - 1; i++) {
        rodOK[i] = !(cut[i] || b[i].frozen || b[i + 1].frozen || (b[i].kin && b[i + 1].kin && phase == 0 && b[i].x[1] > floorJ + POURH + 1));
        if (!rodOK[i]) continue;
        for (int c = 0; c < 3; c++) mid[i][c] = 0.5 * (b[i].x[c] + b[i + 1].x[c]);
        int ix = (int)floor(mid[i][0] / scell), iy = (int)floor(mid[i][1] / scell), iz = (int)floor(mid[i][2] / scell);
        unsigned h = ((unsigned)(ix * 73856093) ^ (unsigned)(iy * 19349663) ^ (unsigned)(iz * 83492791)) & (HSZ - 1);
        snext[i] = shead[h]; shead[h] = i;
        if (b[i].kin && b[i + 1].kin) continue;
        for (int q = 0; q < 3; q++) {
          double u = 0.5 + (q - 1) * (0.5 - D / (2 * L)), P[3], nn[3];
          for (int c = 0; c < 3; c++) P[c] = b[i].x[c] + u * (b[i + 1].x[c] - b[i].x[c]);
          if (glassDist(P, floorJ, rim, nn) < ROD + 0.08) addRod(i, -1, u, 0);
        }
      }
      for (int i = tail; i < N - 1; i++) {
        if (!rodOK[i]) continue;
        int ix = (int)floor(mid[i][0] / scell), iy = (int)floor(mid[i][1] / scell), iz = (int)floor(mid[i][2] / scell);
        for (int dx = -1; dx <= 1; dx++) for (int dy = -1; dy <= 1; dy++) for (int dz = -1; dz <= 1; dz++) {
          unsigned h = ((unsigned)((ix + dx) * 73856093) ^ (unsigned)((iy + dy) * 19349663) ^ (unsigned)((iz + dz) * 83492791)) & (HSZ - 1);
          for (int j = shead[h]; j >= 0; j = snext[j]) {
            if (j <= i + 1) continue;
            double d2 = 0; for (int c = 0; c < 3; c++) d2 += (mid[i][c] - mid[j][c]) * (mid[i][c] - mid[j][c]);
            if (d2 > scell * scell) continue;
            if (b[i].kin && b[i + 1].kin && b[j].kin && b[j + 1].kin) continue;
            double u, w, dd = 0;
            segNearest(b[i].x, b[i + 1].x, b[j].x, b[j + 1].x, &u, &w);
            for (int c = 0; c < 3; c++) { double e = b[j].x[c] + w * (b[j + 1].x[c] - b[j].x[c]) - b[i].x[c] - u * (b[i + 1].x[c] - b[i].x[c]); dd += e * e; }
            if (dd < (2 * ROD + 0.08) * (2 * ROD + 0.08)) addRod(i, j, u, w);
          }
        }
      }
    }
    for (int it = 0; it < ITERS; it++) {
      int fwd = (sub + it) % 2 == 0;
      for (int kk = tail; kk < N - 1; kk++) {           /* rods */
        int i = fwd ? kk : N - 2 - (kk - tail);
        if (i < tail || cut[i] || b[i].frozen || b[i + 1].frozen) continue;
        Bead *a = &b[i], *c2 = &b[i + 1];
        double wa = a->kin ? 0 : 1, wb = c2->kin ? 0 : 1;
        if (wa + wb == 0) continue;
        double d[3], n = 0; for (int c = 0; c < 3; c++) { d[c] = c2->x[c] - a->x[c]; n += d[c] * d[c]; }
        n = sqrt(n);
        double C = n > L ? n - L : (n < L - PLAY ? n - (L - PLAY) : 0);
        if (C == 0) continue;
        for (int c = 0; c < 3; c++) { double k = C * d[c] / n / (wa + wb); a->x[c] += wa * k; c2->x[c] -= wb * k; }
        Tc[i] += C / (wa + wb) / (HS * HS);
      }
      for (int i = tail + 1; i < N - 1; i++) {          /* bending limits */
        if (cut[i - 1] || cut[i] || b[i - 1].frozen) continue;
        Bead *a = &b[i - 1], *c2 = &b[i + 1];
        double wa = a->kin ? 0 : 1, wb = c2->kin ? 0 : 1;
        if (wa + wb == 0) continue;
        double d[3], n = 0; for (int c = 0; c < 3; c++) { d[c] = c2->x[c] - a->x[c]; n += d[c] * d[c]; }
        n = sqrt(n);
        if (n >= dmin) continue;
        double C = n - dmin;
        for (int c = 0; c < 3; c++) { double k = C * d[c] / n / (wa + wb); a->x[c] += wa * k; c2->x[c] -= wb * k; }
      }
      for (int k = 0; k < ncs; k++) {                   /* contacts */
        Contact *ct = &cs[k];
        Bead *a = &b[ct->a];
        double C, nn[3];
        if (ct->bb >= 0) {
          Bead *c2 = &b[ct->bb];
          double wa = a->kin ? 0 : 1, wb = c2->kin ? 0 : 1;
          if (wa + wb == 0) continue;
          double d[3], n = 0; for (int c = 0; c < 3; c++) { d[c] = c2->x[c] - a->x[c]; n += d[c] * d[c]; }
          n = sqrt(n); if (n < 1e-12) continue;
          for (int c = 0; c < 3; c++) nn[c] = d[c] / n;
          C = n - D;
          double dl = -C / (wa + wb);
          if (ct->dn + dl * (wa + wb) < 0) dl = -ct->dn / (wa + wb);
          if (dl == 0) continue;
          for (int c = 0; c < 3; c++) { a->x[c] -= wa * dl * nn[c]; c2->x[c] += wb * dl * nn[c]; }
          ct->dn += dl * (wa + wb);
          memcpy(ct->n, nn, sizeof nn);
        } else {
          if (a->kin) continue;
          if (ct->bb == -1) { nn[0] = 0; nn[1] = 1; nn[2] = 0; C = a->x[1] - (floorJ + D / 2); }
          else {
            double rr = sqrt(a->x[0] * a->x[0] + a->x[2] * a->x[2]);
            double cr = fmin(fmax(rr, RJ), RJ + 1), cyy = fmin(fmax(a->x[1], floorJ - 10), rim);
            double er = rr - cr, ey = a->x[1] - cyy, dd = sqrt(er * er + ey * ey), nr, ny;
            if (dd > 1e-9) { nr = er / dd; ny = ey / dd; } else { nr = rr < RJ + 0.5 ? -1 : 1; ny = 0; }
            double ux = rr > 1e-9 ? a->x[0] / rr : 1, uz = rr > 1e-9 ? a->x[2] / rr : 0;
            nn[0] = nr * ux; nn[1] = ny; nn[2] = nr * uz;
            C = dd - D / 2;
          }
          double dl = -C;
          if (ct->dn + dl < 0) dl = -ct->dn;
          if (dl == 0) continue;
          for (int c = 0; c < 3; c++) a->x[c] += dl * nn[c];
          ct->dn += dl;
          memcpy(ct->n, nn, sizeof nn);
        }
      }
      if (nrc) solveRods(floorJ, rim);
    }
    /* what the pile and the rim push on moving beads (from the contacts'
       final lambda: force = lambda / HS^2, unit masses) */
    if (flow) for (int k = 0; k < ncs; k++) {
      Contact *ct = &cs[k];
      if (ct->dn <= 0) continue;
      int ia = ct->a, ib = ct->bb;
      if (ib >= 0) {
        double wa = b[ia].kin ? 0 : 1, wb = b[ib].kin ? 0 : 1;
        if (ia < pick && ib >= pick) { Fy[ia] -= wa / (wa + wb) * ct->dn * ct->n[1] / (HS * HS); touch[ia] = 1; }
        if (ib < pick && ia >= pick) { Fy[ib] += wb / (wa + wb) * ct->dn * ct->n[1] / (HS * HS); touch[ib] = 1; }
      } else if (ib == -1) { if (ia < pick) { Fy[ia] += ct->dn / (HS * HS); touch[ia] = 1; } }
      else if (ia < pick) Fr[ia] += ct->dn * ct->n[1] / (HS * HS);
    }
    if (flow) for (int k = 0; k < nrc; k++) {         /* (and through the rods) */
      RodC *c = &rc[k];
      if (c->lam <= 0) continue;
      int s = c->s; double u = c->u, f = c->lam * c->n[1] / (HS * HS);
      if (c->t >= 0) {
        if (s + 1 < pick && c->t >= pick) { Fy[s] -= (1 - u) * f; Fy[s + 1] -= u * f; touch[u < 0.5 ? s : s + 1] = 1; }
      } else if (s + 1 < pick) { Fr[s] += (1 - u) * f; Fr[s + 1] += u * f; }
    }
    /* velocities */
    for (int i = tail; i < N; i++) {
      Bead *q = &b[i];
      if (q->kin || q->frozen) continue;
      for (int c = 0; c < 3; c++) q->v[c] = (q->x[c] - q->p[c]) / HS;
    }
    /* friction, once, on the velocities: Coulomb, up to mu times the
       normal impulse (pen / HS, unit masses) */
    for (int k = 0; k < ncs; k++) {
      Contact *ct = &cs[k];
      Bead *a = &b[ct->a], *c2 = ct->bb >= 0 ? &b[ct->bb] : NULL;
      double wa = a->kin ? 0 : 1, wb = (c2 && !c2->kin) ? 1 : 0;
      if (wa + wb == 0) continue;
      double vr[3]; for (int c = 0; c < 3; c++) vr[c] = (c2 ? c2->v[c] : 0) - a->v[c];
      double vn = vr[0] * ct->n[0] + vr[1] * ct->n[1] + vr[2] * ct->n[2], vt[3], vtl = 0;
      for (int c = 0; c < 3; c++) { vt[c] = vr[c] - vn * ct->n[c]; vtl += vt[c] * vt[c]; }
      vtl = sqrt(vtl);
      if (vtl < 1e-12) continue;
      double dv = fmin(ct->mu * ct->dn / HS, vtl);
      for (int c = 0; c < 3; c++) {
        double u = dv * vt[c] / vtl / (wa + wb);
        a->v[c] += wa * u;
        if (c2) c2->v[c] -= wb * u;
      }
    }
    if (nrc) rodFriction();
    sub++; t += HS; tPhase += HS;

    /* phase changes */
    if (phase == 0 && fed >= N) { phase = 1; pourT = tPhase; tPhase = 0; printf("poured in %.2f s\n", pourT); }
    if (phase == 1 && sub % 100 == 0) {
      /* (a check on the contact forces: in a resting heap the jar's floor
         carries the chain's weight, N g; the beads' contacts with each other
         carry the weight of what lies above them) */
      double ff = 0, fb = 0;
      for (int k = 0; k < ncs; k++) { if (cs[k].bb == -1) ff += cs[k].dn / (HS * HS); else if (cs[k].bb >= 0) fb += cs[k].dn / (HS * HS); }
      if (sub % 20000 == 0) printf("  (settling: the jar floor carries %.3f N g; bead-bead contacts %.2f N g in all; %d contacts)\n", ff / (N * G), fb / (N * G), ncs);
      double ke = 0, vmax = 0;
      for (int i = 0; i < N; i++) { if (b[i].kin) continue; double s2 = 0; for (int c = 0; c < 3; c++) s2 += b[i].v[c] * b[i].v[c]; ke += 0.5 * s2; vmax = fmax(vmax, sqrt(s2)); }
      if ((vmax < 1.0 && tPhase > 0.2) || tPhase > 2.0) {
        settleKE = ke; settleVmax = vmax; settleT = tPhase;
        double top = -1e9; int itop = 0;
        for (int i = 0; i < N; i++) if (b[i].x[1] > top) { top = b[i].x[1]; itop = i; }
        int spilled = 0;
        for (int i = 0; i < N; i++) if (sqrt(b[i].x[0] * b[i].x[0] + b[i].x[2] * b[i].x[2]) > RJ || b[i].x[1] < floorJ) spilled++;
        printf("settled in %.2f s: fastest bead %.2f cm/s, kinetic energy %.3g (m = 1, cm^2/s^2); heap top %.2f cm above the floor of the jar (bead %d); %d beads outside the jar\n",
               settleT, vmax, ke, top - floorJ, itop, spilled);
        if (spilled) { printf("spilled over the rim while pouring: no run\n"); return 1; }
        if (SAVEF) {
          FILE *f = fopen(SAVEF, "w"); fprintf(f, "%d\n", N);
          for (int i = 0; i < N; i++) fprintf(f, "%.9f %.9f %.9f\n", b[i].x[0], b[i].x[1], b[i].x[2]);
          fclose(f); printf("saved the settled heap to %s\n", SAVEF);
        }
        phase = 2; tPhase = 0; pullS = 0; b[0].kin = 1;
        memcpy(pullStart, b[0].x, sizeof pullStart);
        pullUp = rim + 4 - b[0].x[1];
      }
    }
    if (phase != 3) continue;
    if (t >= TMAX) break;
    /* the pick-up, landing, and the steady part */
    pick = tail;
    while (pick < N - 1) {
      double s2 = 0; for (int c = 0; c < 3; c++) s2 += b[pick].v[c] * b[pick].v[c];
      if (s2 < 10 * 10 && b[pick].x[1] > floorJ - 1) break;
      pick++;
    }
    double pickY = b[pick].x[1];
    int steady = t >= T0 && pick < N - 40;
    while (tail < N - 1 && b[tail].x[1] < YF && !b[tail].kin) {
      double s2 = 0; for (int c = 0; c < 3; c++) s2 += b[tail].v[c] * b[tail].v[c];
      if (steady) { sV2 += s2; sLand++; }
      b[tail].frozen = 1; cut[tail] = 1; tail++; landed++;
    }
    if (steady) {
      if (!win) { win = 1; wt0 = t; wl0 = landed; }
      wt1 = t; wl1 = landed;
      double push = 0, rf = 0;
      for (int i = tail; i < pick; i++) { push += Fy[i] - (touch[i] ? G : 0); rf += Fr[i]; }
      sPush += push; sRim += rf; sSteps++;
      for (int i = tail; i < pick - 1; i++) {
        double yy = b[i].x[1] - pickY;
        if (yy < -20 && yy > -100 && !cut[i]) {
          double v2 = 0; for (int c = 0; c < 3; c++) v2 += b[i].v[c] * b[i].v[c];
          sCar += Tc[i] - lam * v2 - lam * G * yy; sCarN++;
        }
        double dd = 0; for (int c = 0; c < 3; c++) dd += (b[i + 1].x[c] - b[i].x[c]) * (b[i + 1].x[c] - b[i].x[c]);
        maxStretch = fmax(maxStretch, sqrt(dd) - L);
      }
    }
    if (DUMPT >= 0 && t >= DUMPT && t < DUMPT + HS * 1.5) {
      FILE *f = fopen("pour-dump.csv", "w");
      for (int i = 0; i < N; i++) fprintf(f, "%d,%.4f,%.4f,%.4f,%.2f,%.2f,%.2f,%d,%.1f\n", i, b[i].x[0], b[i].x[1], b[i].x[2], b[i].v[0], b[i].v[1], b[i].v[2], b[i].frozen, Tc[i]);
      fclose(f);
    }
    if (t >= nextSample) {
      nextSample += 1.0 / 240;
      double top = -1e9; for (int i = tail; i < pick; i++) if (b[i].x[1] > top) top = b[i].x[1];
      if (pick < N - 40) best = fmax(best, top - rim);
      if (steady) { sh2 += top - pickY; sh1 += pickY - YF; srim += rim - pickY; sn++; }
      if (log) fprintf(log, "3,%.4f,%.3f,%.3f,%d,%d,0,0\n", t, top - pickY, pickY - YF, pick, landed);
      if (fmod(t + 1e-9, 0.25) < 1.0 / 240)
        printf("t=%5.2fs  top of the chain %5.1f cm above the rim, pick-up %.1f cm under it; %d beads moving; %.2f m landed\n",
               t, top - rim, rim - pickY, pick - tail, landed * L / 100);
    }
    if (pick >= N - 2 || (win && !steady)) break;
  }
  if (!sn || wt1 <= wt0) { printf("no steady part\n"); return 0; }
  double vm = (wl1 - wl0) * L / (wt1 - wt0), h2 = sh2 / sn, h1 = sh1 / sn, mv2 = lam * vm * vm;
  printf("steady part t=%.2f-%.2fs: h1 = %.1f cm (rim %.1f cm above the pick-up), h2 = %.1f cm, h2/h1 = %.3f; highest %.1f cm above the rim\n",
         wt0, wt1, h1, srim / sn, h2, h2 / h1, best);
  printf("v = %.0f cm/s (v/sqrt(2 g h1) = %.3f); beads land at %.0f cm/s rms (%.0f%% of the drop's energy); longest rod %.4f cm over L\n",
         vm, vm / sqrt(2 * G * h1), sqrt(sV2 / sLand), 100 * sV2 / sLand / (2 * G * h1), maxStretch);
  printf("a: from the height %.3f, from the speed %.3f; the pile's push %.3f, the rim's %.3f; carried by the falling chain %.3f\n",
         G * h2 / (vm * vm), 1 - G * h1 / (vm * vm), sPush / sSteps / mv2, sRim / sSteps / mv2, -sCar / sCarN / mv2);
  printf("RESULT layout=%d seed=%d hs=%.1e iters=%d d=%.2f rod=%.3f play=%.3f mu=%.2f v=%.1f vrms=%.1f h1=%.2f h2=%.2f ratio=%.4f push=%.3f rim=%.3f carried=%.3f E=%.1f settleT=%.2f settleVmax=%.3f settleKE=%.3g\n",
         LAYOUT, SEED, HS, ITERS, D, ROD, PLAY, MU, vm, sqrt(sV2 / sLand), h1, h2, h2 / h1, sPush / sSteps / mv2, sRim / sSteps / mv2, -sCar / sCarN / mv2,
         100 * sV2 / sLand / (2 * G * h1), settleT, settleVmax, settleKE);
  return 0;
}
