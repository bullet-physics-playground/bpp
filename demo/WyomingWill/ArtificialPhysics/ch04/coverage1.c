/*
 * ch04/coverage1.c -- one agent of the Android app's uniform coverage
 * (UniformCoverageSimulation.kt, as ported to BPP in Uniform_Coverage.lua),
 * run until its coverage stops improving.
 *
 *   cc -O2 -o coverage1 coverage1.c -lm
 *   ./coverage1 MFP SEED [MAXSTEPS [FIRST]]
 *   e.g. ./coverage1 17 1          (MFP may be fractional: 17.333)
 *        ./coverage1 17 1 1.6e9 1.25e7   (checkpoints 1.25e7, 2.5e7, ...,
 *                                         2e8 -- Fig. 4.19's budget -- ...)
 *
 * THE MODEL (the scene's rules, one agent, so no agent-agent turns):
 *   - arena -40..40 in x and y; 9 cells split at -13 1/3 and +13 1/3
 *     (cell width 26 2/3), a point on a split counted in the middle cell;
 *   - the agent starts uniform in +-37.5 (15/16 of the arena) with a
 *     uniform heading in [0, 360) degrees, and that start is counted;
 *   - every tick: steps += 1; it must turn if steps >= MFP or the point
 *     0.0001 ahead is at or beyond the arena edge (|x| or |y| >= 40); a
 *     turn is a new uniform heading with steps = 0, tried up to 9 times;
 *     if a clear heading is found it moves 1 along it (clamped to +-40)
 *     and is counted in its cell, otherwise it stays and is not counted;
 *   - MFP 120 or more is the same as no mean free path (the longest
 *     straight path, 80 sqrt 2, is 113).
 *
 * DEFINITIONS (printed):
 *   deviation  sqrt( sum over the 9 cells of (p_k - 1/9)^2 ), p_k the
 *              cell's visits over the ticks so far (Eq. 4.1; as the scene,
 *              the divisor is ticks, so an uncounted tick lowers the sum)
 *   f          MFP / 26.667, the mean free path in cell widths
 *
 * STOPPING RULE (William, 2026-10-26: "keep running if there is any
 * improvement"): checkpoints at FIRST steps (default 10^7) and then
 * doubling; the run stops when the deviation has not improved at two
 * checkpoints in a row, but never before 2 x 10^8 steps (Fig. 4.19's
 * budget for one particle, PDF 145), or at MAXSTEPS (default 10^10). One
 * line a checkpoint, then the cell shares.
 *
 * RANDOM NUMBERS: splitmix64 seeded with SEED, not BPP's lib/rng.lua, so
 * runs agree with the scene statistically, not number for number.
 */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static uint64_t state;
static double rnd(void) /* uniform in [0, 1) */
{
	uint64_t z = (state += 0x9E3779B97F4A7C15ULL);
	z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
	z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
	z ^= z >> 31;
	return (z >> 11) * (1.0 / 9007199254740992.0);
}

#define BOUNDARY 40.0
#define LOOKAHEAD 0.0001
static const double B1 = (2 * BOUNDARY / 3) - BOUNDARY, B2 = (4 * BOUNDARY / 3) - BOUNDARY;
static const double DEG = 3.14159265358979323846 / 180.0;

static double x, y, heading, mfp;
static long steps;
static uint64_t counts[9], ticks;

static void count(void)
{
	int cx = x < B1 ? 0 : (x <= B2 ? 1 : 2);
	int cy = y < B1 ? 0 : (y <= B2 ? 1 : 2);
	counts[cx + 3 * cy]++;
}

static int must_turn(void)
{
	if (steps >= mfp) return 1;
	double lx = x + cos(heading * DEG) * LOOKAHEAD, ly = y + sin(heading * DEG) * LOOKAHEAD;
	return fabs(lx) >= BOUNDARY || fabs(ly) >= BOUNDARY;
}

static void tick(void)
{
	int tries = 0, blocked;
	ticks++;
	steps++;
	blocked = must_turn();
	while (blocked && tries < 9) {
		heading = rnd() * 360.0;
		steps = 0;
		tries++;
		blocked = must_turn();
	}
	if (!blocked) {
		x += cos(heading * DEG);
		y += sin(heading * DEG);
		if (x < -BOUNDARY) x = -BOUNDARY;
		if (x > BOUNDARY) x = BOUNDARY;
		if (y < -BOUNDARY) y = -BOUNDARY;
		if (y > BOUNDARY) y = BOUNDARY;
		count();
	}
}

static double deviation(void)
{
	double s = 0;
	for (int i = 0; i < 9; i++) {
		double d = (double)counts[i] / ticks - 1.0 / 9;
		s += d * d;
	}
	return sqrt(s);
}

int main(int argc, char **argv)
{
	if (argc < 3) {
		fprintf(stderr, "usage: %s MFP SEED [MAXSTEPS [FIRST]]\n", argv[0]);
		return 1;
	}
	mfp = atof(argv[1]);
	state = strtoull(argv[2], NULL, 10);
	double maxsteps = argc > 3 ? atof(argv[3]) : 1e10;
	uint64_t first = argc > 4 ? (uint64_t)atof(argv[4]) : 10000000;
	x = (rnd() * 2 - 1) * (15.0 * BOUNDARY / 16.0);
	y = (rnd() * 2 - 1) * (15.0 * BOUNDARY / 16.0);
	heading = rnd() * 360.0;
	count();
	printf("# MFP %g (f = %.4f), seed %s\n# steps deviation\n", mfp, mfp / (2 * BOUNDARY / 3), argv[2]);
	double best = INFINITY;
	int worse = 0;
	for (uint64_t next = first; ; next *= 2) {
		while (ticks < next) tick();
		double d = deviation();
		printf("%llu %.6f\n", (unsigned long long)ticks, d);
		fflush(stdout);
		if (d < best) { best = d; worse = 0; } else if (++worse >= 2 && ticks >= 200000000) break;
		if (next * 2 > maxsteps) break;
	}
	printf("# shares:");
	for (int i = 0; i < 9; i++) printf(" %.5f", (double)counts[i] / ticks);
	printf("\n");
	return 0;
}
