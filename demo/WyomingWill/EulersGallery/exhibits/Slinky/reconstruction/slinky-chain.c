/*
 * The falling Slinky as a plain chain, outside bpp: N equal masses (M/N),
 * N-1 springs of k(N-1) that pull only when stretched beyond the closed-up
 * spacing (5.6 cm / N), no pre-tension, coils that stick when they meet
 * (perfectly inelastic: the touching run moves on with their mean speed).
 * Hung at rest from the top, let go at t = 0; prints when the bottom first
 * moves faster than 1 cm/s (and when its gap closes), against sqrt(M/3k).
 *
 *   cc -O2 -o slinky-chain slinky-chain.c -lm
 *   ./slinky-chain 86 1e-6        (coils, step in s)
 *
 * Units: cm, kg, s. 215 g, 1.76 N/m, as the exhibit.
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
int main(int argc, char **argv) {
  int N = argc > 1 ? atoi(argv[1]) : 86;
  double dt = argc > 2 ? atof(argv[2]) : 1e-6;
  double P = 5.6 / N, M = 0.215, K = 1.76, G = 981, m = M / N, ks = K * (N - 1);
  double *y = calloc(N, sizeof *y), *v = calloc(N, sizeof *v), *f = calloc(N, sizeof *f);
  for (int i = 1; i < N; i++) y[i] = y[i - 1] - (P + (N - i) * m * G / ks);
  double t = 0, tMoved = -1, tClosed = -1;
  while (t < 0.4 && (tMoved < 0 || tClosed < 0)) {
    for (int i = 0; i < N; i++) f[i] = -m * G;
    for (int i = 0; i < N - 1; i++) {
      double s = y[i] - y[i + 1] - P;
      if (s > 0) { f[i] -= ks * s; f[i + 1] += ks * s; }
    }
    for (int i = 0; i < N; i++) v[i] += f[i] / m * dt;
    for (int it = 0; it < 10000; it++) {          /* touching and closing: stick */
      int changed = 0;
      for (int i = 0; i < N - 1; i++) {
        if (y[i] - y[i + 1] - P < 1e-12 && v[i] < v[i + 1] - 1e-13) {
          int a = i, b = i + 1;
          while (a > 0 && y[a - 1] - y[a] - P < 1e-12 && v[a - 1] <= v[a] + 1e-13) a--;
          while (b < N - 1 && y[b] - y[b + 1] - P < 1e-12 && v[b] <= v[b + 1] + 1e-13) b++;
          double s = 0;
          for (int j = a; j <= b; j++) s += v[j];
          s /= b - a + 1;
          for (int j = a; j <= b; j++) v[j] = s;
          changed = 1;
        }
      }
      if (!changed) break;
    }
    for (int i = 0; i < N; i++) y[i] += v[i] * dt;
    for (int i = 0; i < N - 1; i++) if (y[i] - y[i + 1] < P) y[i + 1] = y[i] - P;
    t += dt;
    if (tMoved < 0 && fabs(v[N - 1]) > 1.0) tMoved = t;
    if (tClosed < 0 && y[N - 2] - y[N - 1] - P < 1e-12) tClosed = t;
  }
  printf("%d coils, step %g s: the bottom moves at %.5f s (its gap closes at %.5f s); sqrt(M/3k) = %.5f s\n",
         N, dt, tMoved, tClosed, sqrt(M / (3 * K)));
  return 0;
}
