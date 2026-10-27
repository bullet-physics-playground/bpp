/*
 * ch11/maxim1.c -- Maxim's coverage simulator without the window: one robot
 * in one of his environments, run as long as you like, its coverage printed
 * as it goes. The same steps as ch11/maxim.lua, which is his C operation for
 * operation (ch11/maxim/src/coverage_simulation.c), with FINDINGS F81's fix
 * and a seed (ch11/maxim_fixed.diff): checkpoints for checkpoint, it gives
 * the same counts as his fixed, seeded C (checks/ch11.lua tests the Lua copy
 * against that C; run this one against ch11/c_reference_fixed.txt with
 * ./maxim1 maxim/84cell.environment/environment_20.ini 7 3 200000 200000).
 *
 *   cc -O2 -o maxim1 maxim1.c -lm
 *   ./maxim1 ENVFILE K SEED MAXSTEPS [FIRST [MINSTEPS]]
 *   e.g. ./maxim1 maxim/84cell.environment/environment_20.ini 13 1 1e10
 *
 * THE MODEL (his move_agent and record_cell_visits, one robot):
 *   - the environment file: the wall's vertices (a closed polygon), the
 *     cells' lower-left corners, the cell size; positions are single
 *     precision (his GLfloat), the rest double;
 *   - the start: the centre of the cell at the middle of a random wall
 *     ("side"), heading pi/2, then two draws unused (his impulse_agent);
 *   - each step: the sensor looks 1 ahead (his response range); while that
 *     line crosses any wall, or the robot has gone K steps since its last
 *     turn, it takes a new heading uniform in [0, 2 pi) and looks again;
 *     then it moves 1 to the point the sensor tested (the fix: his C moves
 *     by a separately rounded step and can land on a wall, F81); it is
 *     counted in the cell of highest index whose lower-left corner is at
 *     or below and left of it;
 *   - random numbers: Bourke's RandomUniform (Marsaglia and Zaman), seeded
 *     RandomInitialise(1, SEED), SEED 0..30081.
 *
 * DEFINITIONS (printed):
 *   K     turn after K steps without a wall; f = K / cell size, the mean free
 *         path in cell widths (the theory's bound: 0.65)
 *   KL    sum over the C cells of p_i ln(p_i C) (Sec. 11.2.3; the book's
 *         target in simulation: 0.001)
 *   dev   sqrt(sum (p_i - 1/C)^2), Eq. 4.1 (Ch. 4's measure)
 *
 * STOPPING: checkpoints at FIRST steps (default 10^7), then doubling; the
 * run stops when KL has not improved at two checkpoints in a row and at
 * least MINSTEPS (default 1.6 x 10^8) have run, or at MAXSTEPS. One line a
 * checkpoint: steps KL dev; then the cell shares.
 */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Bourke's randomlib.c, RandomInitialise / RandomUniform */
static double u[97], c, cd, cm;
static int i97, j97;
static void rinit(int ij, int kl)
{
	if (ij < 0 || ij > 31328 || kl < 0 || kl > 30081) { ij = 1802; kl = 9373; }
	int i = (ij / 177) % 177 + 2, j = (ij % 177) + 2, k = (kl / 169) % 178 + 1, l = kl % 169;
	for (int ii = 0; ii < 97; ii++) {
		double s = 0.0, t = 0.5;
		for (int jj = 0; jj < 24; jj++) {
			int m = (((i * j) % 179) * k) % 179;
			i = j; j = k; k = m;
			l = (53 * l + 1) % 169;
			if (((l * m) % 64) >= 32) s += t;
			t *= 0.5;
		}
		u[ii] = s;
	}
	c = 362436.0 / 16777216.0; cd = 7654321.0 / 16777216.0; cm = 16777213.0 / 16777216.0;
	i97 = 97; j97 = 33;
}
static double rnd(void)
{
	double uni = u[i97 - 1] - u[j97 - 1];
	if (uni <= 0.0) uni++;
	u[i97 - 1] = uni;
	if (--i97 == 0) i97 = 97;
	if (--j97 == 0) j97 = 97;
	c -= cd;
	if (c < 0.0) c += cm;
	uni -= c;
	if (uni < 0.0) uni++;
	return uni;
}

static int nv, nc;
static float *wx, *wy, *cx, *cy, size;
static void read_env(const char *path)
{
	FILE *f = fopen(path, "r");
	if (!f) { perror(path); exit(1); }
	char key[64];
	double a, b;
	if (fscanf(f, "%63s %d", key, &nv) != 2 || strcmp(key, "vertix_number")) { fprintf(stderr, "bad file\n"); exit(1); }
	wx = malloc(nv * sizeof *wx); wy = malloc(nv * sizeof *wy);
	for (int i = 0; i < nv; i++) { if (fscanf(f, "%lf %lf", &a, &b) != 2) exit(1); wx[i] = (float)a; wy[i] = (float)b; }
	if (fscanf(f, "%63s %d", key, &nc) != 2 || strcmp(key, "cell_number")) { fprintf(stderr, "bad file\n"); exit(1); }
	cx = malloc(nc * sizeof *cx); cy = malloc(nc * sizeof *cy);
	for (int i = 0; i < nc; i++) { if (fscanf(f, "%lf %lf", &a, &b) != 2) exit(1); cx[i] = (float)a; cy[i] = (float)b; }
	if (fscanf(f, "%63s %lf", key, &a) != 2 || strcmp(key, "cell_size")) { fprintf(stderr, "bad file\n"); exit(1); }
	size = (float)a;
	fclose(f);
}

/* his intersect(): segments (x1,y1)-(x2,y2) and (a1,b1)-(a2,b2), in double */
static int intersect(double x1, double y1, double x2, double y2, double a1, double b1, double a2, double b2)
{
	double dx = x2 - x1, dy = y2 - y1, da = a2 - a1, db = b2 - b1;
	double den = da * dy - db * dx;
	if (den == 0) return 0;
	double s = (dx * (b1 - y1) + dy * (x1 - a1)) / den;
	double t = (da * (y1 - b1) + db * (a1 - x1)) / (db * dx - da * dy);
	return s >= 0.0 && s <= 1.0 && t >= 0.0 && t <= 1.0;
}

static const double PI = 3.141592653589793238462643;
static float x, y;
static double heading;

static int blocked(void)
{
	float sx = (float)(cos(0 + heading) * 1.0 + x), sy = (float)(sin(0 + heading) * 1.0 + y);
	for (int v = 0; v < nv; v++) {
		int w = v == nv - 1 ? 0 : v + 1;
		if (intersect(x, y, sx, sy, wx[v], wy[v], wx[w], wy[w])) return 1;
	}
	return 0;
}

static int find_cell(float px, float py)
{
	for (int i = 0; i < nc; i++)
		if (px >= cx[i] && px <= cx[i] + size && py >= cy[i] && py <= cy[i] + size) return i;
	return -1;
}

int main(int argc, char **argv)
{
	if (argc < 5) { fprintf(stderr, "usage: %s ENVFILE K SEED MAXSTEPS [FIRST [MINSTEPS]]\n", argv[0]); return 1; }
	read_env(argv[1]);
	int K = atoi(argv[2]);
	int seed = atoi(argv[3]);
	double maxsteps = atof(argv[4]);
	uint64_t first = argc > 5 ? (uint64_t)atof(argv[5]) : 10000000;
	double minsteps = argc > 6 ? atof(argv[6]) : 1.6e8;
	rinit(1, seed);
	/* the side start */
	int r = (int)((nv - 1) * rnd());
	int A = r, B = (r + 1) % nv, cell;
	if (wx[A] == wx[B]) {
		float ty = wy[A] > wy[B] ? (wy[A] - wy[B]) / 2 + wy[B] : (wy[B] - wy[A]) / 2 + wy[A];
		cell = find_cell(wx[A], (float)(int)ty);
	} else {
		float tx = wx[A] > wx[B] ? (wx[A] - wx[B]) / 2 + wx[B] : (wx[B] - wx[A]) / 2 + wx[A];
		cell = find_cell((float)(int)tx, wy[A]);
	}
	if (cell < 0) { fprintf(stderr, "no side starting position\n"); return 1; }
	unsigned half = (unsigned)size / 2;
	x = (float)(cx[cell] + half); y = (float)(cy[cell] + half);
	heading = PI / 2;
	rnd(); rnd();

	uint64_t *count = calloc(nc, sizeof *count), steps = 0;
	int counter = 0;
	printf("# %s, K %d (f = %.4f), seed %d, %d cells\n# steps KL dev\n", argv[1], K, K / size, seed, nc);
	double best = INFINITY;
	int worse = 0;
	for (uint64_t next = first; ; next *= 2) {
		while (steps < next) {
			int flag = blocked();
			counter++;
			while (flag || counter == K) {
				heading = rnd() * PI * 2;
				counter = 0;
				flag = blocked();
			}
			x = (float)(cos(heading) * 1.0 + x);
			y = (float)(sin(heading) * 1.0 + y);
			steps++;
			for (int i = nc - 1; i >= 0; i--)
				if (x >= cx[i] && y >= cy[i]) { count[i]++; break; }
		}
		double kl = 0, dev = 0;
		for (int i = 0; i < nc; i++) {
			double p = (double)count[i] / steps;
			if (p > 0) kl += p * log(p * nc);
			dev += (p - 1.0 / nc) * (p - 1.0 / nc);
		}
		printf("%llu %.7f %.6f\n", (unsigned long long)steps, kl, sqrt(dev));
		fflush(stdout);
		if (kl < best) { best = kl; worse = 0; } else if (++worse >= 2 && steps >= minsteps) break;
		if (next * 2 > maxsteps) break;
	}
	printf("# counts:");
	for (int i = 0; i < nc; i++) printf(" %llu", (unsigned long long)count[i]);
	printf("\n");
	return 0;
}
