/*
 * The chain fountain outside bpp and Bullet: a ball chain as beads on rods
 * of fixed length, every bead simulated, coiled in a jar as the exhibit's
 * coil is, its lead hanging over the rim to the floor. A check on what an
 * ideal chain of this kind does when it is picked up off a pile.
 *
 * The chain: N beads, each of mass m, diameter D. Each bead is joined to
 * the next by a rod of length L that can't stretch or shrink. The chain can
 * bend at most BEND degrees at a bead: that is kept as the least distance,
 * 2 L cos(BEND/2), between a bead and the next but one, as the real chain's
 * rods butt against the balls. Beads don't pass through each other (unless
 * they are neighbours), the jar's wall (inside, top and outside) or the
 * floor of the jar, with friction MU (Coulomb). Gravity. Nothing else: no
 * air, no restitution (contacts are perfectly inelastic), no rotation of a
 * bead about its centre (point masses), no twist.
 *
 * How it moves: position-based dynamics with small steps (Macklin et al.,
 * "Small steps in physics simulation", SCA 2019): each step every bead
 * moves on with its velocity and gravity, then the rods, the bending
 * limits and the contacts are put right by moving the beads (equal masses:
 * each by half, Gauss-Seidel, ITERS sweeps a step), and the velocity is
 * what the bead moved, over the step. With small enough steps this is the
 * rigid, inelastic limit; the results are checked against the step and the
 * number of sweeps.
 *
 * A bead that falls below 2.5 cm above the floor is frozen where it is and
 * its rod to the next is cut, as the exhibit does (so nothing at the floor
 * pulls: b = 0). Before it goes, the pile settles for SETTLE seconds with
 * the lead's floor end held.
 *
 * Measured over the steady part (from T0 until the pick-up is 30 beads
 * from the coil's end), as in the exhibit (chain-fountain.lua, CF_PUSH=2):
 *   v      chain length landing a second (beads landing x L);
 *   vrms   the beads' own speed as they land;
 *   h1     the pick-up above where they land; h2 the top of the moving
 *          chain above the pick-up;
 *   push   the vertical contact force of the unmoved pile (jar floor and
 *          beads not yet moved) on moving beads, less m g for each moving
 *          bead it touches, over lambda v^2 (lambda = m/L);
 *   rim    the same for the jar's wall and rim;
 *   carried  -(T - lambda v_i^2 - lambda g y)/(lambda v^2) on the falling
 *          chain 20-100 cm below the pick-up, T the rods' tension (from
 *          their corrections), y above the pick-up: Biggins and Warner's
 *          steady chain keeps this equal to their a from pile to floor.
 *
 *   cc -O2 -o bead-chain bead-chain.c -lm
 *   ./bead-chain [key=value ...]
 *     L=0.65 D=0.45 BEND=30 MU=0.3 LAYERS=3 H=150 RJ=7 JH=8 DT=2e-5
 *     ITERS=4 SETTLE=0.2 T0=1.0 TMAX=4 WALL=1 LOG=file.csv
 *   (WALL=0: no jar wall, the coil on a bare disc of radius RJ, a table;
 *   DEPTH: the top layer this far under the rim, 3; below 0 it stands
 *   above the rim; RIMMU: friction on the jar's wall and rim, if not MU;
 *   HEAP=n SEED=s: a jumbled heap of n beads instead of the coil, see below)
 *   (defaults: Biggins and Warner's chain, 4.5 mm balls 6.5 mm apart
 *   (2 mm rods), bending 30 degrees a ball (six balls turn it round);
 *   the exhibit's jar and drop)
 *
 * Units: cm, s; m = 1 (it cancels).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

static double L = 0.65, D = 0.45, BEND = 30, MU = 0.3, RIMMU = -1, H = 150, RJ = 7, JH = 8;
static double DT = 2e-5, SETTLE = 0.2, T0 = 1.0, TMAX = 4, DEPTH = 3, DUMPT = -1;
static int LAYERS = 3, ITERS = 4, WALL = 1, HEAP = 0, SEED = 1;
static const char *LOGF = NULL;
#define G 981.0
#define YF 2.5                         /* beads below this are on the floor */

typedef struct { double x[3], p[3], v[3]; int frozen, pinned; } Bead;
static Bead *b;
static int N, nLead, *cut;              /* cut[i]: rod i (i, i+1) is gone */

static void getarg(const char *s) {
  char k[32]; double v;
  if (sscanf(s, "%31[^=]=%lf", k, &v) == 2) {
    if (!strcmp(k, "L")) L = v; else if (!strcmp(k, "D")) D = v;
    else if (!strcmp(k, "BEND")) BEND = v; else if (!strcmp(k, "MU")) MU = v;
    else if (!strcmp(k, "LAYERS")) LAYERS = (int)v; else if (!strcmp(k, "H")) H = v;
    else if (!strcmp(k, "RJ")) RJ = v; else if (!strcmp(k, "JH")) JH = v;
    else if (!strcmp(k, "DT")) DT = v; else if (!strcmp(k, "ITERS")) ITERS = (int)v;
    else if (!strcmp(k, "SETTLE")) SETTLE = v; else if (!strcmp(k, "T0")) T0 = v;
    else if (!strcmp(k, "TMAX")) TMAX = v; else if (!strcmp(k, "WALL")) WALL = (int)v;
    else if (!strcmp(k, "DUMPT")) DUMPT = v;
    else if (!strcmp(k, "DEPTH")) DEPTH = v; else if (!strcmp(k, "RIMMU")) RIMMU = v;
    else if (!strcmp(k, "HEAP")) HEAP = (int)v; else if (!strcmp(k, "SEED")) SEED = (int)v;
    else { fprintf(stderr, "unknown %s\n", k); exit(1); }
  } else if (!strncmp(s, "LOG=", 4)) LOGF = s + 4;
  else { fprintf(stderr, "bad argument %s\n", s); exit(1); }
}

/* ---- the path the chain is laid along, then one bead every L ---- */
static double (*path)[3]; static int np, cap;
static void addp(double x, double y, double z) {
  if (np == cap) { cap = cap ? 2 * cap : 4096; path = realloc(path, cap * sizeof *path); }
  path[np][0] = x; path[np][1] = y; path[np][2] = z; np++;
}

int main(int argc, char **argv) {
  for (int i = 1; i < argc; i++) getarg(argv[i]);
  double th = BEND * M_PI / 180, dmin = 2 * L * cos(th / 2);
  double LT = D + 0.05;                               /* a layer's thickness */
  double rim = H + JH, ytop = rim - DEPTH;            /* the top layer, DEPTH cm under the rim */
  double floorJ = ytop - (LAYERS - 1) * LT - D / 2;   /* what the coil rests on */
  /* the lead, floor end first: up from the floor at x = 12, over the rim
     in two quarter circles of radius 2 (all at z = -2), down inside the
     wall, and round a quarter circle into the coil's start, heading along
     it (no joint laid past its limit) */
  double Ro = RJ - D / 2 - 0.1, R = 2, y1 = fmax(rim + 1, ytop + R), xo = 12, z0 = -R;
  double xi = sqrt(Ro * Ro - z0 * z0);
  for (double y = YF + 1; y < y1; y += 0.01) addp(xo, y, z0);
  for (double a = 0; a < M_PI / 2; a += 0.01 / R) addp(xo - R + R * cos(a), y1 + R * sin(a), z0);
  for (double x = xo - R; x > xi + R; x -= 0.01) addp(x, y1 + R, z0);
  for (double a = M_PI / 2; a < M_PI; a += 0.01 / R) addp(xi + R + R * cos(a), y1 + R * sin(a), z0);
  for (double y = y1; y > ytop + R; y -= 0.01) addp(xi, y, z0);
  for (double a = 0; a < M_PI / 2; a += 0.01 / R) {
    double z = z0 * cos(a);
    addp(sqrt(Ro * Ro - z * z), ytop + R - R * sin(a), z);
  }
  int leadPts = np;
  /* the coil: spirals, outside in then inside out, all turning the same
     way, no tighter than the chain can turn while dropping to the next
     layer (as the exhibit's coil()) */
  double tip = asin(LT / 3 / L), turn = sqrt(fmax(th * th - tip * tip, 1e-6));
  double Ri = fmax(L / (2 * sin(turn / 2)) + 0.1, 1.0), pitch = (D + 0.1) / (2 * M_PI);
  double phi = 0, r = Ro, y = ytop;
  for (int lay = 0; lay < LAYERS; lay++) {
    int dir = lay % 2 ? 1 : -1;
    if (lay > 0) {               /* down to the next layer over 3 bead spacings */
      double len = 3 * L, s = 0;
      while (s < len) { phi += 0.01 / r; y -= LT * 0.01 / len; s += 0.01; addp(r * cos(phi), y, r * sin(phi)); }
    }
    for (;;) {
      double r2 = r + dir * pitch * 0.01 / r;
      if ((dir < 0 && r2 < Ri) || (dir > 0 && r2 > Ro)) break;
      phi += 0.01 / r; r = r2;
      addp(r * cos(phi), y, r * sin(phi));
    }
  }
  /* beads exactly L apart along the path (on the segment where the
     distance from the last bead reaches L, by bisection) */
  b = calloc(np, sizeof *b); cut = calloc(np, sizeof *cut);
  memcpy(b[0].x, path[0], sizeof b[0].x); N = 1; nLead = -1;
  for (int k = 1; k < np; k++) {
    double *A = path[k - 1], *B = path[k], *P = b[N - 1].x;
    double dB = 0; for (int c = 0; c < 3; c++) dB += (B[c] - P[c]) * (B[c] - P[c]);
    if (dB < L * L) continue;
    double lo = 0, hi = 1, q[3];
    for (int it = 0; it < 60; it++) {
      double m = (lo + hi) / 2, d2 = 0;
      for (int c = 0; c < 3; c++) { q[c] = A[c] + m * (B[c] - A[c]); d2 += (q[c] - P[c]) * (q[c] - P[c]); }
      if (d2 < L * L) lo = m; else hi = m;
    }
    memcpy(b[N].x, q, sizeof q);
    if (nLead < 0 && k >= leadPts) nLead = N;
    N++; k--;                                   /* (the same segment may hold another) */
  }
  for (int i = 0; i < N; i++) memcpy(b[i].p, b[i].x, sizeof b[i].x);
  /* HEAP=n: instead of the coil, n beads more laid as a random walk in
     the jar, every step turning a random angle up to BEND, keeping off the
     wall and a bead's width from every bead before it, working down a
     slab 3 cm thick from the top to the jar's floor: a jumbled heap, as the
     experiments' chains "fed into the beaker in a random configuration" */
  if (HEAP > 0) {
    N = nLead + 1;
    srand(SEED);
    double dir[3] = { 0, 0, 1 };
    double yBot = floorJ + D / 2, yTopH = ytop;
    int backs = 0;
    for (int k = 0; k < HEAP; k++) {
      double yc = yTopH - (yTopH - yBot - 1.5) * k / (double)HEAP;
      int ok = 0;
      double *P0 = b[N - 1].x, r0 = sqrt(P0[0] * P0[0] + P0[2] * P0[2]);
      for (int tr = 0; tr < 400 && !ok; tr++) {
        /* a random direction within BEND of the last, leaning away from
           the wall and toward the slab's middle */
        double u[3]; for (;;) { for (int c = 0; c < 3; c++) u[c] = 2.0 * rand() / RAND_MAX - 1; double n = sqrt(u[0]*u[0]+u[1]*u[1]+u[2]*u[2]); if (n > 0.1 && n <= 1) { for (int c = 0; c < 3; c++) u[c] /= n; break; } }
        if (r0 > Ro - 2 && r0 > 1e-9) { u[0] -= 1.5 * P0[0] / r0; u[2] -= 1.5 * P0[2] / r0; }
        u[1] += 0.5 * (yc - P0[1]);
        { double n = sqrt(u[0]*u[0]+u[1]*u[1]+u[2]*u[2]); for (int c = 0; c < 3; c++) u[c] /= n; }
        double ang = (tr < 300 ? 1.0 : 0.5) * th * rand() / RAND_MAX;
        double dt0 = u[0]*dir[0]+u[1]*dir[1]+u[2]*dir[2], w[3], wn = 0;
        for (int c = 0; c < 3; c++) { w[c] = u[c] - dt0 * dir[c]; wn += w[c] * w[c]; }
        wn = sqrt(wn); if (wn < 1e-9) continue;
        double nd[3], q[3];
        for (int c = 0; c < 3; c++) { nd[c] = cos(ang) * dir[c] + sin(ang) * w[c] / wn; q[c] = b[N - 1].x[c] + L * nd[c]; }
        double rr = sqrt(q[0] * q[0] + q[2] * q[2]);
        if (rr > Ro || q[1] < fmax(yBot, yc - 1.5) || q[1] > fmin(yTopH, yc + 1.5)) continue;
        ok = 1;
        for (int j = 0; j < N - 2 && ok; j++) {
          double d2 = 0; for (int c = 0; c < 3; c++) d2 += (b[j].x[c] - q[c]) * (b[j].x[c] - q[c]);
          if (d2 < D * D * 1.02) ok = 0;
        }
        if (ok) { memcpy(b[N].x, q, sizeof q); memcpy(dir, nd, sizeof nd); N++; }
      }
      if (!ok) {                       /* back up a few beads and try again */
        int back = k < 6 ? k : 6;
        if (++backs > 20000 || back == 0) { printf("heap: stuck after %d beads\n", k); break; }
        N -= back; k -= back + 1;
        for (int c = 0; c < 3; c++) dir[c] = b[N - 1].x[c] - b[N - 2].x[c];
        { double n = sqrt(dir[0]*dir[0]+dir[1]*dir[1]+dir[2]*dir[2]); for (int c = 0; c < 3; c++) dir[c] /= n; }
      }
    }
    for (int i = 0; i < N; i++) memcpy(b[i].p, b[i].x, sizeof b[i].x);
  }
  /* laid past the limit anywhere? */
  int over = 0;
  for (int i = 1; i < N - 1; i++) {
    double d2 = 0; for (int c = 0; c < 3; c++) d2 += (b[i + 1].x[c] - b[i - 1].x[c]) * (b[i + 1].x[c] - b[i - 1].x[c]);
    if (sqrt(d2) < dmin - 1e-6) over++;
  }
  printf("bead chain: %d beads (%.1f m), %d in the lead; L=%.3f D=%.3f bend %.0f deg (least next-but-one %.3f cm); mu %.2f\n",
         N, N * L / 100, nLead, L, D, BEND, dmin, MU);
  printf("jar r %.1f, rim %.1f cm up, coil %d layers from %.2f down, inner radius %.2f; %d joints laid past the limit\n",
         RJ, rim, LAYERS, ytop, Ri, over);
  printf("step %.1e s, %d sweeps; settle %.2f s\n", DT, ITERS, SETTLE);

  /* ---- spatial hash for bead contacts ---- */
  const int HS = 1 << 16;
  int *head = malloc(HS * sizeof(int)), *next = malloc(N * sizeof(int));
  int maxPairs = 64 * N, nPairs; int (*pairs)[2] = malloc(maxPairs * sizeof *pairs);
  double cell = D + 0.2;
  FILE *log = LOGF ? fopen(LOGF, "w") : NULL;
  if (log) fprintf(log, "t,h2,h1,pick,landed,moving\n");

  double lam = 1.0 / L, t = -SETTLE;
  b[0].pinned = SETTLE > 0;
  int tail = 0, landed = 0, pick = 0, win = 0;
  double wt0 = 0, wt1 = 0; int wl0 = 0, wl1 = 0;
  double sh2 = 0, sh1 = 0, srim = 0; int sn = 0;
  double sPush = 0, sRim = 0, sCar = 0, sV2 = 0; long sSteps = 0, sCarN = 0; int sLand = 0;
  double best = -1e9, nextSample = 0;
  double *Tc = calloc(N, sizeof *Tc);                 /* rod tension this step */
  double *Fy = calloc(N, sizeof *Fy), *Fr = calloc(N, sizeof *Fr);
  int *touch = calloc(N, sizeof *touch);
  long step = 0;
  int coilEnd = N - 1;

  while (t < TMAX) {
    int settling = t < 0;
    /* predict */
    for (int i = tail; i < N; i++) {
      Bead *q = &b[i];
      memcpy(q->p, q->x, sizeof q->x);
      if (q->pinned) continue;
      if (settling) for (int c = 0; c < 3; c++) q->v[c] *= 1 - 50 * DT;   /* (settling only) */
      q->v[1] -= G * DT;
      for (int c = 0; c < 3; c++) q->x[c] += q->v[c] * DT;
    }
    /* candidate bead pairs, from the predicted positions */
    for (int k = 0; k < HS; k++) head[k] = -1;
    for (int i = tail; i < N; i++) {
      int ix = (int)floor(b[i].x[0] / cell), iy = (int)floor(b[i].x[1] / cell), iz = (int)floor(b[i].x[2] / cell);
      unsigned h = ((unsigned)(ix * 73856093) ^ (unsigned)(iy * 19349663) ^ (unsigned)(iz * 83492791)) & (HS - 1);
      next[i] = head[h]; head[h] = i;
    }
    nPairs = 0;
    for (int i = tail; i < N; i++) {
      int ix = (int)floor(b[i].x[0] / cell), iy = (int)floor(b[i].x[1] / cell), iz = (int)floor(b[i].x[2] / cell);
      for (int dx = -1; dx <= 1; dx++) for (int dy = -1; dy <= 1; dy++) for (int dz = -1; dz <= 1; dz++) {
        unsigned h = ((unsigned)((ix + dx) * 73856093) ^ (unsigned)((iy + dy) * 19349663) ^ (unsigned)((iz + dz) * 83492791)) & (HS - 1);
        for (int j = head[h]; j >= 0; j = next[j]) {
          if (j <= i + 2) continue;
          double d2 = 0; for (int c = 0; c < 3; c++) d2 += (b[i].x[c] - b[j].x[c]) * (b[i].x[c] - b[j].x[c]);
          if (d2 < (D + 0.1) * (D + 0.1) && nPairs < maxPairs) { pairs[nPairs][0] = i; pairs[nPairs][1] = j; nPairs++; }
        }
      }
    }
    for (int i = tail; i < N; i++) { Tc[i] = 0; Fy[i] = 0; Fr[i] = 0; touch[i] = 0; }
    /* project */
    for (int it = 0; it < ITERS; it++) {
      int fwd = it % 2 == 0;
      for (int kk = tail; kk < N - 1; kk++) {             /* rods */
        int i = fwd ? kk : N - 2 - (kk - tail);
        if (cut[i]) continue;
        Bead *a = &b[i], *c2 = &b[i + 1];
        double d[3], n = 0; for (int c = 0; c < 3; c++) { d[c] = c2->x[c] - a->x[c]; n += d[c] * d[c]; }
        n = sqrt(n);
        double wa = a->pinned ? 0 : 1, wb = c2->pinned ? 0 : 1, C = n - L;
        if (wa + wb == 0) continue;
        for (int c = 0; c < 3; c++) { double k = C * d[c] / n / (wa + wb); a->x[c] += wa * k; c2->x[c] -= wb * k; }
        Tc[i] += C / (wa + wb) / (DT * DT);            /* (m = 1) */
      }
      for (int i = tail + 1; i < N - 1; i++) {            /* bending limits */
        if (cut[i - 1] || cut[i]) continue;
        Bead *a = &b[i - 1], *c2 = &b[i + 1];
        double d[3], n = 0; for (int c = 0; c < 3; c++) { d[c] = c2->x[c] - a->x[c]; n += d[c] * d[c]; }
        n = sqrt(n);
        if (n >= dmin) continue;
        double wa = a->pinned ? 0 : 1, wb = c2->pinned ? 0 : 1, C = n - dmin;
        if (wa + wb == 0) continue;
        for (int c = 0; c < 3; c++) { double k = C * d[c] / n / (wa + wb); a->x[c] += wa * k; c2->x[c] -= wb * k; }
      }
      for (int k = 0; k < nPairs; k++) {                  /* bead on bead */
        Bead *a = &b[pairs[k][0]], *c2 = &b[pairs[k][1]];
        double d[3], n = 0; for (int c = 0; c < 3; c++) { d[c] = c2->x[c] - a->x[c]; n += d[c] * d[c]; }
        n = sqrt(n);
        if (n >= D || n < 1e-12) continue;
        double wa = a->pinned ? 0 : 1, wb = c2->pinned ? 0 : 1;
        if (wa + wb == 0) continue;
        double pen = D - n, nn[3]; for (int c = 0; c < 3; c++) nn[c] = d[c] / n;
        for (int c = 0; c < 3; c++) { double k = pen * nn[c] / (wa + wb); a->x[c] -= wa * k; c2->x[c] += wb * k; }
        /* friction: undo relative sliding, up to MU times the push */
        double rel[3], rn = 0; for (int c = 0; c < 3; c++) { rel[c] = (c2->x[c] - c2->p[c]) - (a->x[c] - a->p[c]); rn += rel[c] * nn[c]; }
        double tg[3], tl = 0; for (int c = 0; c < 3; c++) { tg[c] = rel[c] - rn * nn[c]; tl += tg[c] * tg[c]; }
        tl = sqrt(tl);
        if (tl > 1e-12) {
          double f = fmin(1, MU * pen / tl);
          for (int c = 0; c < 3; c++) { double k = f * tg[c] / (wa + wb); a->x[c] += wa * k; c2->x[c] -= wb * k; }
        }
        /* the unmoved pile on a moving bead: its vertical push */
        int ia = pairs[k][0], ib = pairs[k][1];
        if (!settling && ia < pick && ib >= pick) { Fy[ia] -= wa * pen * nn[1] / (wa + wb) / (DT * DT); touch[ia] = 1; }
        if (!settling && ib < pick && ia >= pick) { Fy[ib] += wb * pen * nn[1] / (wa + wb) / (DT * DT); touch[ib] = 1; }
      }
      for (int i = tail; i < N; i++) {                    /* the jar */
        Bead *q = &b[i];
        if (q->pinned) continue;
        double rr = sqrt(q->x[0] * q->x[0] + q->x[2] * q->x[2]);
        double cy = q->x[1];
        /* its floor (inside) */
        if (rr < RJ && cy < floorJ + D / 2 && q->p[1] >= floorJ + D / 2 - 0.5) {
          double pen = floorJ + D / 2 - cy;
          q->x[1] += pen;
          double tx = q->x[0] - q->p[0], tz = q->x[2] - q->p[2], tl = sqrt(tx * tx + tz * tz);
          if (tl > 1e-12) { double f = fmin(1, MU * pen / tl); q->x[0] -= f * tx; q->x[2] -= f * tz; }
          if (!settling && i < pick) { Fy[i] += pen / (DT * DT); touch[i] = 1; }
        }
        /* its wall: r in [RJ, RJ+1], y in [floorJ - 10, rim] */
        double cr = fmin(fmax(rr, RJ), RJ + 1), cyy = fmin(fmax(cy, floorJ - 10), rim);
        double er = rr - cr, ey = cy - cyy, dd = sqrt(er * er + ey * ey);
        if (WALL && dd < D / 2) {
          double nr, ny;
          if (dd > 1e-9) { nr = er / dd; ny = ey / dd; }
          else { nr = rr < RJ + 0.5 ? -1 : 1; ny = 0; }      /* (inside the wall: out the nearer side) */
          double pen = D / 2 - dd, ux = rr > 1e-9 ? q->x[0] / rr : 1, uz = rr > 1e-9 ? q->x[2] / rr : 0;
          double n3[3] = { nr * ux, ny, nr * uz };
          for (int c = 0; c < 3; c++) q->x[c] += pen * n3[c];
          double rel[3], rn = 0; for (int c = 0; c < 3; c++) { rel[c] = q->x[c] - q->p[c]; rn += rel[c] * n3[c]; }
          double tg[3], tl = 0; for (int c = 0; c < 3; c++) { tg[c] = rel[c] - rn * n3[c]; tl += tg[c] * tg[c]; }
          tl = sqrt(tl);
          double mur = RIMMU >= 0 ? RIMMU : MU;
          if (tl > 1e-12) { double f = fmin(1, mur * pen / tl); for (int c = 0; c < 3; c++) q->x[c] -= f * tg[c]; }
          if (!settling && i < pick) Fr[i] += pen * n3[1] / (DT * DT);
        }
      }
    }
    /* velocities */
    for (int i = tail; i < N; i++) for (int c = 0; c < 3; c++) b[i].v[c] = (b[i].x[c] - b[i].p[c]) / DT;
    t += DT; step++;
    if (settling && t >= 0) {                              /* let go */
      b[0].pinned = 0;
      for (int i = 0; i < N; i++) memset(b[i].v, 0, sizeof b[i].v);
    }
    if (t < 0) continue;
    /* the pick-up: the first bead of the coil, from the floor end, still at rest */
    pick = tail > nLead ? tail : nLead;
    while (pick < N - 1) {
      double s2 = 0; for (int c = 0; c < 3; c++) s2 += b[pick].v[c] * b[pick].v[c];
      if (s2 < 10 * 10) break;
      pick++;
    }
    double pickY = b[pick].x[1];
    int steady = t >= T0 && pick < coilEnd - 30;
    /* landing: freeze, cut the rod */
    while (tail < N - 1 && b[tail].x[1] < YF) {
      double s2 = 0; for (int c = 0; c < 3; c++) s2 += b[tail].v[c] * b[tail].v[c];
      if (steady) { sV2 += s2; sLand++; }
      b[tail].frozen = 1; cut[tail] = 1; tail++; landed++;
    }
    if (steady) {
      if (!win) { win = 1; wt0 = t; wl0 = landed; }
      wt1 = t; wl1 = landed;
      double vm = 0; /* (filled at the end: use the running rate) */
      (void)vm;
      double push = 0, rimf = 0;
      for (int i = tail; i < pick; i++) { push += Fy[i] - (touch[i] ? G : 0); rimf += Fr[i]; }
      sPush += push; sRim += rimf; sSteps++;
      for (int i = tail; i < pick - 1; i++) {
        double yy = b[i].x[1] - pickY;
        if (yy < -20 && yy > -100 && !cut[i]) {
          double v2 = 0; for (int c = 0; c < 3; c++) v2 += b[i].v[c] * b[i].v[c];
          sCar += Tc[i] - lam * v2 - lam * G * yy; sCarN++;
        }
      }
    }
    if (DUMPT >= 0 && t >= DUMPT && t < DUMPT + DT) {
      FILE *f = fopen("dump.csv", "w");
      for (int i = 0; i < N; i++) fprintf(f, "%d,%.4f,%.4f,%.4f,%.2f,%.2f,%.2f,%d,%.3f,%.3f\n", i, b[i].x[0], b[i].x[1], b[i].x[2], b[i].v[0], b[i].v[1], b[i].v[2], b[i].frozen, Tc[i], Fr[i]);
      fclose(f);
    }
    if (t >= nextSample) {
      nextSample += 1.0 / 240;
      double top = -1e9; for (int i = tail; i < pick; i++) if (b[i].x[1] > top) top = b[i].x[1];
      if (pick < coilEnd - 30) best = fmax(best, top - rim);
      if (steady) { sh2 += top - pickY; sh1 += pickY - YF; srim += rim - pickY; sn++; }
      if (log) fprintf(log, "%.4f,%.3f,%.3f,%d,%d,%d\n", t, top - pickY, pickY - YF, pick, landed, pick - tail);
      if (fmod(t + 1e-9, 0.25) < 1.0 / 240)
        printf("t=%5.2fs  top of the chain %5.1f cm above the rim; %d beads moving; %.1f m landed\n", t, top - rim, pick - tail, landed * L / 100);
    }
    if (pick >= N - 2 || (win && !steady && t > T0 + 0.1)) break;
  }
  if (!sn || wt1 <= wt0) { printf("no steady part\n"); return 0; }
  double vm = (wl1 - wl0) * L / (wt1 - wt0), h2 = sh2 / sn, h1 = sh1 / sn, mv2 = lam * vm * vm;
  printf("steady part t=%.2f-%.2fs: h1 = %.1f cm (rim %.1f cm above the pick-up), h2 = %.1f cm, h2/h1 = %.3f; highest %.1f cm above the rim\n",
         wt0, wt1, h1, srim / sn, h2, h2 / h1, best);
  printf("v = %.0f cm/s (sqrt(g h1) = %.0f; v/sqrt(2 g h1) = %.3f); beads land at %.0f cm/s rms, with %.0f%% of the energy of the drop\n",
         vm, sqrt(G * h1), vm / sqrt(2 * G * h1), sqrt(sV2 / sLand), 100 * sV2 / sLand / (2 * G * h1));
  printf("a: from the height %.3f, from the speed %.3f; the pile's push %.3f, the rim's %.3f; carried by the falling chain %.3f\n",
         G * h2 / (vm * vm), 1 - G * h1 / (vm * vm), sPush / sSteps / mv2, sRim / sSteps / mv2, -sCar / sCarN / mv2);
  return 0;
}
