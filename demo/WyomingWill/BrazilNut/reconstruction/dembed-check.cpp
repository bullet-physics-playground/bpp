/*
 * dembed-check.cpp: runs bpp's DemCore (src/demcore.cpp, the DemBed hook's
 * physics) outside bpp, taking bead-bed.c's arguments and printing its
 * result lines in its formats, so the two can be compared line for line.
 *
 *   g++ -O2 -I../../../../src -o dembed-check dembed-check.cpp ../../../../src/demcore.cpp
 *   ./dembed-check BOX=middle MODEL=1 YM=6.3e9 NS=60 E=0.1 SEED=7 TEND=4
 *   ./dembed-check TEST=drop|pair|incline|gdrop|ghollow ...
 * (cpu_per_s is left out: it is the one field that differs)
 */
#include "demcore.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

int main(int argc, char **argv)
{
  DemCore c;
  std::string test, boxn = "middle";
  for (int a = 1; a < argc; a++) {
    const char *eq = strchr(argv[a], '=');
    if (!eq) { fprintf(stderr, "bad arg %s\n", argv[a]); return 1; }
    std::string k(argv[a], eq - argv[a]), val(eq + 1);
    if (k == "TEST") test = val;
    else if (k == "BOX") { boxn = val; c.set("BOX", val == "right" ? 2 : (val == "gentle" || val == "left") ? 0 : 1); }
    else if (k == "LOG") {}
    else if (!c.set(k, atof(val.c_str()))) { fprintf(stderr, "unknown key %s\n", k.c_str()); return 1; }
  }
  if (!test.empty()) { fputs(c.test(test).c_str(), stdout); return 0; }
  c.init();
  int settled = 0, phase = 0, gphase = 0, conv = 0;
  double lastReached = -1;
  while (c.simTime() < c.TEND) {
    c.stepTo(c.simTime() + 1.0 / 60);
    if (!settled && c.get("settled")) {
      settled = 1;
      printf("RESULT_SETTLE ovmax=%.3e ovmean=%.3e static_est=%.3e ke_per_bead_over_mgd=%.3e\n", c.get("settleOvMax"), c.get("settleOvMean"),
             c.MODEL == 0 ? 12 * (0.0025 * 4.0 / 3.0 * 3.14159265358979323846 * 0.5 * 0.5 * 0.5) * 981.0 / c.get("KN") / (0.5 / 2) : 0, c.get("settleKe"));
    }
    if (lastReached < 0 && c.get("reached") >= 0) {
      lastReached = c.get("reached");
      printf("  the %s bead reaches the top at %.2f s\n", c.BIG ? "big" : "coloured", lastReached);
    }
    if (!phase && c.get("phase")) {
      phase = 1;
      printf("RESULT_PHASE least=%.4f off=%d landed=%d vdown19=%.2f\n", c.get("least"), (int)c.get("off"), (int)c.get("landed"), c.get("vdown"));
    }
    if (!gphase && c.get("gphase")) {
      gphase = 1;
      printf("RESULT_GPHASE least=%.4f\n", c.get("gleast"));
    }
    if (!conv && c.get("conv")) {
      conv = 1;
      printf("  from %.0f s to %.0f s: beads in the middle rising %.2f mm/s, beside the walls %.2f mm/s\n", c.CONVSTART, c.CONVEND, c.get("mid"), c.get("wall"));
    }
  }
  printf("RESULT box=%s gamma=%.2f model=%d tc=%.3g ns=%d seed=%d mub=%.3g muw=%.3g e=%.3g plates=%d reached=%.3f upper=%.3f mid=%.3f wall=%.3f trips=%d upx=%.2f downx=%.2f"
         " ovmean=%.2e ovmax=%.2e up20=%.3f top20=%.3f h20=%.3f hc20=%.3f\n",
         boxn.c_str(), c.GAMMA, c.MODEL, c.TC, c.NS, c.SEED, c.MUB, c.MUW, c.EB, c.PLATES, c.get("reached"), c.get("upper"), c.get("mid"), c.get("wall"),
         (int)c.get("trips"), c.get("upx"), c.get("downx"), c.get("ovmean"), c.get("ovmax"), c.get("up20"), c.get("top20"), c.get("h20"), c.get("hc20"));
  printf("RESULT_EXTRA rise1=%.3f rise2=%.3f lateMean=%.4f lateMin=%.4f\n", c.get("rise1"), c.get("rise2"), c.get("lateMean"), c.get("lateMin"));
  return 0;
}
