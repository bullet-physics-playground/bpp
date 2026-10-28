/*
 * ch04/couette1.c -- ch04/couette.lua (kt.nlogo, Ch. 4.4) in C, for the
 * long runs of Figs. 4.23 and 4.24: the same model, the same random
 * numbers (lib/rng.lua's multiply-with-carry, seeded the same way) drawn
 * in the same order, so it gives the Lua's numbers to the last bit
 * (checks/ch04_couette.lua compares them through couette1_reference.txt).
 *
 *   cc -O2 -ffp-contract=off -o couette1 couette1.c -lm
 *   ./couette1 V T SEED TICKS [RESAMPLE [N [INWARD]]]
 *   e.g. ./couette1 1.0 0.01 1 10000 5000       (Fig. 4.23: V = 1)
 *        ./couette1 0 0.0025 1 100000 50000     (Fig. 4.24: sqrt T = 0.05)
 *
 * The model, its world and its step are described at the top of
 * couette.lua. RESAMPLE (default TICKS/2) is the tick after which the
 * Resample button is pressed; N defaults to 1000; INWARD 1 (the default)
 * is couette.lua's o.inward (walls thermalise only particles moving into
 * them, Kerr's rule), 0 the .nlogo's wall.
 *
 * DEFINITIONS (printed, one line each):
 *   slope corr  least-squares slope of the 13 bars (mean vy per column,
 *               averaged over the samples since Resample) against
 *               0..12, and their correlation (compute-stats); theory
 *               V/6 and 1
 *   speed       mean particle speed |v| over the samples (units/tick);
 *               theory at V = 0: 1.2533 sqrt(T) (Eq. 4.5)
 *   ratio       speed / sqrt(T)
 *   wall in share   (ours) the mean speed of particles within a wall's
 *               in-radius 1, of the others, and the share of
 *               particle-samples in a wall zone
 *   exit        (ours) over all ticks, the mean |vx|/sqrt(T) and vx^2/T
 *               of particles leaving a wall zone (Rayleigh: 1.2533, 2)
 *   px py       mean vx and mean vy at the end (the momentum monitors)
 *   bars        the 13 bars, left (yellow wall, down) to right (red, up)
 */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

/* lib/rng.lua's Stream */
static double rz, rw, spare;
static int hasSpare;
static void seed(double s)
{
	s = fmod(floor(fabs(s)), 4294967296.0);
	if (s == 0) s = 1;
	rz = s;
	rw = fmod(s * 69069 + 1, 4294967296.0);
	if (rz == 0) rz = 362436069;
	if (rw == 0) rw = 521288629;
	hasSpare = 0;
}
static double rnd(void)
{
	uint32_t z = (uint32_t)rz, w = (uint32_t)rw;
	z = 36969u * (z & 65535u) + (z >> 16);
	w = 18000u * (w & 65535u) + (w >> 16);
	rz = z; rw = w;
	return (double)((z << 16) + w) / 4294967296.0;
}
static int rndInt(int m, int n) { return m + (int)floor(rnd() * (n - m + 1)); }
static double gauss(void)
{
	if (hasSpare) { hasSpare = 0; return spare; }
	double u1 = rnd(), u2 = rnd();
	double r = sqrt(-2 * log(1 - u1));
	spare = r * sin(2 * M_PI * u2); hasSpare = 1;
	return r * cos(2 * M_PI * u2);
}

#define MAX 42
#define W 85.0
#define NC 42
#define NMAX 100000
static const double CW = W / NC;
static double X[NMAX], Y[NMAX], VX[NMAX], VY[NMAX], SP[NMAX];
static int order[NMAX], cellOf[NMAX], near[NMAX];
static int cellStart[NC * NC + 1], cellList[NMAX], cellFill[NC * NC];
static double S[360], Cs[360], B[14], hist[13], sumVel, wallSum, inSum;
static long sample, wallCount, inCount;
static int n, inward;
static double exitSum, exitSum2;
static long exitCount;

static double luamod(double a, double b) { return a - floor(a / b) * b; }
static double wrap(double x) { return luamod(x + MAX + 0.5, W) - (MAX + 0.5); }
static double dxRed(double x)
{
	if (x >= 40 && x <= 42) return 0;
	if (x < 40) return fmin(40 - x, x + W - 42);
	return x - 42;
}
static double dxYellow(double x)
{
	if (x >= -42 && x <= -40) return 0;
	if (x > -40) return fmin(x + 40, -42 + W - x);
	return -42 - x;
}
static int nearWall(double dx, double y)
{
	double dy = y - floor(y + 0.5);
	return dx * dx + dy * dy <= 1;
}

static void monitor(void)
{
	double sum[13] = {0}, sv = 0;
	int cnt[13] = {0};
	if (sample == 0) {
		sumVel = 0;
		for (int k = 0; k < 13; k++) hist[k] = 0;
		wallSum = inSum = 0; wallCount = inCount = 0;
	}
	for (int i = 0; i < n; i++) {
		double x = X[i];
		if (x > B[0] && x < B[13]) {
			int k = (int)floor((x - B[0]) * 13 / (2 * MAX));
			if (k > 12) k = 12;
			if (x > B[k] && x < B[k + 1]) { sum[k] += VY[i]; cnt[k]++; }
		}
		sv += SP[i];
	}
	for (int k = 0; k < 13; k++) if (cnt[k] > 0) hist[k] += sum[k] / cnt[k];
	sumVel += sv;
	for (int i = 0; i < n; i++) {
		if (nearWall(dxRed(X[i]), Y[i]) || nearWall(dxYellow(X[i]), Y[i])) { wallSum += SP[i]; wallCount++; }
		else { inSum += SP[i]; inCount++; }
	}
	sample++;
}

static int cellIndex(double x, double y)
{
	int a = (int)floor((x + MAX + 0.5) / CW), b = (int)floor((y + MAX + 0.5) / CW);
	a = ((a % NC) + NC) % NC; b = ((b % NC) + NC) % NC;
	return a + NC * b;
}

static void step(double V, double T)
{
	double s2T = sqrt(2 * T), sT = sqrt(T);
	/* the grid, each cell's particles in ascending order (as the Lua's lists) */
	for (int k = 0; k < NC * NC; k++) cellFill[k] = 0;
	for (int i = 0; i < n; i++) { cellOf[i] = cellIndex(X[i], Y[i]); cellFill[cellOf[i]]++; }
	cellStart[0] = 0;
	for (int k = 0; k < NC * NC; k++) { cellStart[k + 1] = cellStart[k] + cellFill[k]; cellFill[k] = 0; }
	for (int i = 0; i < n; i++) { int k = cellOf[i]; cellList[cellStart[k] + cellFill[k]++] = i; }
	for (int i = n; i >= 2; i--) { int j = rndInt(1, i); int t = order[i - 1]; order[i - 1] = order[j - 1]; order[j - 1] = t; }
	for (int q = 0; q < n; q++) {
		int i = order[q];
		double x = X[i], y = Y[i];
		int k = cellOf[i], cx = k % NC, cy = k / NC, cntN = 0;
		for (int a = -1; a <= 1; a++)
			for (int b = -1; b <= 1; b++) {
				int c = (cx + a + NC) % NC + NC * ((cy + b + NC) % NC);
				for (int p = cellStart[c]; p < cellStart[c + 1]; p++) {
					int j = cellList[p];
					if (j == i) continue;
					double dx = X[j] - x, dy = Y[j] - y;
					if (dx > MAX + 0.5) dx -= W; else if (dx < -(MAX + 0.5)) dx += W;
					if (dy > MAX + 0.5) dy -= W; else if (dy < -(MAX + 0.5)) dy += W;
					if (dx * dx + dy * dy <= 4) near[cntN++] = j;
				}
			}
		if (cntN > 0) {
			int f = near[rndInt(1, cntN) - 1];
			double dvx = VX[i] - VX[f], dvy = VY[i] - VY[f];
			double rel = sqrt(dvx * dvx + dvy * dvy);
			double cmx = 0.5 * (VX[i] + VX[f]), cmy = 0.5 * (VY[i] + VY[f]);
			int th = rndInt(0, 359);
			double rx = rel * S[th], ry = rel * Cs[th];
			VX[i] = cmx + 0.5 * rx; VY[i] = cmy + 0.5 * ry;
			VX[f] = cmx - 0.5 * rx; VY[f] = cmy - 0.5 * ry;
		}
		if (nearWall(dxRed(x), y) && !(inward && VX[i] < 0)) {
			VX[i] = -s2T * sqrt(-log(1 - rnd()));
			VY[i] = gauss() * sT + V;
		}
		if (nearWall(dxYellow(x), y) && !(inward && VX[i] > 0)) {
			VX[i] = s2T * sqrt(-log(1 - rnd()));
			VY[i] = gauss() * sT - V;
		}
	}
	for (int i = 0; i < n; i++) {
		double vx = VX[i], vy = VY[i];
		int was = nearWall(dxRed(X[i]), Y[i]) || nearWall(dxYellow(X[i]), Y[i]);
		SP[i] = sqrt(vx * vx + vy * vy);
		X[i] = wrap(X[i] + vx); Y[i] = wrap(Y[i] + vy);
		if (was && !(nearWall(dxRed(X[i]), Y[i]) || nearWall(dxYellow(X[i]), Y[i]))) {
			exitSum += fabs(vx); exitSum2 += vx * vx; exitCount++;
		}
	}
	monitor();
}

int main(int argc, char **argv)
{
	if (argc < 5) { fprintf(stderr, "usage: couette1 V T SEED TICKS [RESAMPLE [N]]\n"); return 1; }
	double V = atof(argv[1]), T = atof(argv[2]);
	long ticks = atol(argv[4]);
	long resample = argc > 5 ? atol(argv[5]) : ticks / 2;
	n = argc > 6 ? atoi(argv[6]) : 1000;
	inward = argc > 7 ? atoi(argv[7]) : 1;
	if (n < 1 || n > NMAX) { fprintf(stderr, "couette1: N must be 1..%d\n", NMAX); return 1; }
	const double RAD = 3.14159265358979323846 / 180.0;
	for (int h = 0; h < 360; h++) { S[h] = sin(h * RAD); Cs[h] = cos(h * RAD); }
	for (int i = 0; i <= 13; i++) B[i] = -MAX + i * 2.0 * MAX / 13;
	seed(atof(argv[3]));
	for (int i = 0; i < n; i++) {
		int h = rndInt(0, 359);
		double v = sqrt(T) * 1.2533;
		SP[i] = v; VX[i] = v * cos(h * RAD); VY[i] = v * sin(h * RAD);
		X[i] = 7 * (rnd() * W - (MAX + 0.5)) / 8;
		Y[i] = 7 * (rnd() * W - (MAX + 0.5)) / 8;
		order[i] = i;
	}
	monitor();
	for (long t = 1; t <= ticks; t++) {
		step(V, T);
		if (t == resample) sample = 0;
	}
	double p[13], ybar = 0, sxy = 0, sx = 0, sy = 0, px = 0, py = 0;
	for (int k = 0; k < 13; k++) { p[k] = hist[k] / sample; ybar += p[k]; }
	ybar /= 13;
	for (int k = 0; k < 13; k++) {
		sxy += (k - 6) * (p[k] - ybar); sx += (k - 6) * (k - 6); sy += (p[k] - ybar) * (p[k] - ybar);
	}
	for (int i = 0; i < n; i++) { px += VX[i]; py += VY[i]; }
	double speed = sumVel / ((double)sample * n);
	printf("V %g T %g seed %s ticks %ld resample %ld n %d inward %d\n", V, T, argv[3], ticks, resample, n, inward);
	printf("slope %.17g corr %.17g\n", sxy / sx, sxy / (sqrt(sx) * sqrt(sy)));
	printf("speed %.17g ratio %.17g\n", speed, T > 0 ? speed / sqrt(T) : 0);
	printf("wall %.17g in %.17g share %.17g\n", wallSum / wallCount, inSum / inCount,
	       (double)wallCount / (wallCount + inCount));
	printf("exit %.17g %.17g n %ld\n", exitSum / exitCount / sqrt(T), exitSum2 / exitCount / T, exitCount);
	printf("px %.17g py %.17g\n", px / n, py / n);
	printf("bars");
	for (int k = 0; k < 13; k++) printf(" %.17g", p[k]);
	printf("\n");
	return 0;
}
