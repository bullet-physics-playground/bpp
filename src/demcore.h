#ifndef DEMCORE_H
#define DEMCORE_H

/**
 * @file demcore.h
 * @brief A shaken bed of beads by discrete elements (soft spheres), outside
 * Bullet: the physics of demo/WyomingWill/BrazilNut/reconstruction/bead-bed.c,
 * lifted into a class, number for number.
 *
 * The contact and integration code is bead-bed.c's, unchanged (Hertz-Mindlin
 * with Tsuji's damping, a Cundall-Strack tangential spring, glued-sphere
 * walls, velocity Verlet, a cell list; see bead-bed.c and FINDINGS.md /
 * GLASS-DESIGN.md beside it for the model and its validation). Its
 * parameters are bead-bed.c's keys, set with set(); its frame loop is
 * bead-bed.c's main loop cut into substeps, so a run gives bead-bed.c's
 * numbers bit for bit, however the steps are handed out.
 *
 * Added for the exhibit (all off by default): a gentle opening (GAMMA0 for
 * TG s, then the amplitude ramped to GAMMA's over TR s), a second push
 * window for it, a tracer bead, the wall height H, and the special bead's
 * rise times and late height.
 *
 * Units: cm, kg, s. No Qt, no Lua: a plain C++ class (DemBed wraps it for
 * bpp).
 */

#include <string>

#define DEM_MAXB 400
#define DEM_MAXC 24
#define DEM_NCXMAX 64
#define DEM_NCY 64
#define DEM_MAXG 4000

class DemCore {
public:
  DemCore();

  /** @brief Sets a parameter by bead-bed.c's key; false if the key is unknown. */
  bool set(const std::string &key, double val);
  /** @brief A parameter, or a result, by name (see the .cpp); NaN if unknown. */
  double get(const std::string &key) const;
  /** @brief Pours the bed and gets it ready (call once, after set()). */
  void init();
  /** @brief Runs on to simulated time t (s; the shaking starts at 0, the
   * bed is poured at -SETTLE), in whole steps of DT. */
  void stepTo(double t);
  /** @brief Runs a validation test (drop, pair, incline, gdrop, ghollow), as
   * bead-bed.c TEST= does, and returns what it prints. */
  std::string test(const std::string &name);

  int count() const { return N; }
  double posX(int i) const { return x[i][0]; }
  double posY(int i) const { return x[i][1]; }
  double radius(int i) const { return rad[i]; }
  double spin(int i) const { return w[i][2]; }
  double boxHeight() const { return boxy; }
  int gluedCount(int wall) const { return nG[wall]; }
  /** @brief A glued sphere's centre, in the box's frame (x across, y up from
   * the floor), wall 0 left, 1 right, 2 the floor. */
  double gluedX(int wall, int k) const;
  double gluedY(int wall, int k) const;
  double simTime() const { return tf + kSub * DT; }

  // ---- bead-bed.c's parameters (its keys) ----
  double GAMMA = -1, FHZ = 7, POLY = 0.1, MUB = 0.64, MUW = 0.8, MUF = -1, MUP = -1;
  double EB = 0.01, EW = -1, TC = 1e-4, YM = 6.3e10, NU = 0.22, KT = -1, ROLL = 0;
  double GAP = 1.1, SETTLE = 0.5, TEND = 60.05, CONVEND = 60, CONVSTART = 5;
  int NSM = 140, SEED = 7, MODEL = 0, NS = 40, PLATES = 0, BIG = 1;
  int BOX = 1;                              // bead-bed.c's BOX: 0 left (gentle), 1 middle, 2 right
  double W_IN = 15.0, R_B = 1.5, RHOB = 0.0025;
  int ROUGH = 0, ROUGHF = 0;
  double RG = 0.5, SG = 1.0, GEMB = 0.5, GJIT = 0, MUG = -1, EG = -1;
  double ETH = 0, ELOW = 0.1;
  double TH = 10, H0 = 1, V0 = 50;
  int TW = 2;
  int FORCE3D = 0;
  // ---- added for the exhibit ----
  double H_IN = 24.0;                       // the walls' height (glued spheres up to H + 2)
  double GAMMA0 = -1, TG = 0, TR = 0;       // gentle opening (GAMMA0 < 0: none)
  int WATCH1 = 4, WATCH2 = 32;              // the push window, in shakes
  int GW1 = -1, GW2 = -1;                   // the gentle push window, in shakes
  int TRACER = -1;                          // a small bead to follow (-1: the special one, if not big)
  double RISE1 = 10, RISE2 = 12;            // heights (cm, the special bead's centre above the floor)
  double RISEW = 0;                         // ... reached by its mean over the last RISEW s (0: by itself)
  double LATE0 = -1, LATE1 = 1e30;          // the late window (LATE0 < 0: TEND - 20)

private:
  typedef struct { int j; double s[3]; } Hist;
  void out(const char *fmt, ...);
  std::string outBuf;
  void boxAt(double te, double &y, double &v) const;
  void substep();
  void afterFrame();
  void pushReport(bool gentle);

  // ---- bead-bed.c's state ----
  char TEST[16] = "";
  int N = 0;
  double x[DEM_MAXB][3], v[DEM_MAXB][3], w[DEM_MAXB][3], f[DEM_MAXB][3], tq[DEM_MAXB][3], a_old[DEM_MAXB][3], al_old[DEM_MAXB][3];
  double rad[DEM_MAXB], mass[DEM_MAXB], inert[DEM_MAXB];
  Hist hist[2][DEM_MAXB][DEM_MAXC];
  int nh[2][DEM_MAXB], cur = 0;
  double KN = 0, DT = 0, AMP = 0, OMEGA = 0, gvec[3] = { 0, -981.0, 0 };
  double boxy = 0, boxv = 0;
  int LOCKZ = 1;
  double floorTilt = 0;
  // (lifted from bead-bed.c)
  int nContacts;
  double sumOverlap, maxOverlap;
  double *findHist(int i, int j);
  double SQKT, SQKN;
  double zetaLow;
  void contact2(int i, int j, const double *n, double d, double ai, double aj,
                       const double *vi, const double *wi, const double *vj, const double *wj,
                       double meff, double reff, double mu, double zeta);
  void contact(int i, int j, const double *n, double d, double ai, double aj,
                      const double *vi, const double *wi, const double *vj, const double *wj,
                      double meff, double reff, double mu, double zeta);
  void contact3(int i, int j, const double *n, double d, double ai, double aj,
                       const double *vi, const double *wi, const double *vj, const double *wj,
                       double meff, double reff, double mu, double zeta);
  int NCX = 15;
  int cellHead[DEM_NCXMAX * DEM_NCY], cellNext[DEM_MAXB];
  double vp[DEM_MAXB][3], wp[DEM_MAXB][3];   /* predicted velocities */
  double zetaBB, zetaBW, zetaG;
  int nG[3];
  double gc[3][DEM_MAXG], gd[3][DEM_MAXG], gc0[3];
  void makeGlued(void);
  double gluedReach(void);
  void gluedForces(int i, const double *vb);
  void pairForce(int i, int j);
  void forces(void);
  void step(void);
  double meanSmallMass(void);
  void setStiffness(void);
  double lseed;
  double lrnd(void);
  double smallR(int i);
  void pour(int which);
  void testDrop(void);
  void testIncline(void);
  void testGlued(void);

  // ---- the run (bead-bed.c's main loop, kept between calls) ----
  int which = 1, nsub = 1, kSub = 0;
  bool ready = false;
  double Mtot = 0, Wt = 0, tf = 0;
  long frame = 0, stepNo = 0, stepsDone = 0;
  double pushSum[200], vrelSum[200], pushSumG[200], vrelSumG[200];
  long pushN[200], pushNG[200];
  double reached = -1;
  long upN = 0, upHalf = 0, lateN = 0, lateUp = 0, lateTop = 0;
  double lateH = 0, lateHC = 0, lateHsum = 0, lateHmin = 1e30;
  double midSum = 0, wallSum = 0, upX = 0, downX = 0;
  long midN = 0, wallN = 0, upNN = 0, downNN = 0;
  int trips = 0, zoneTop = 0, haveSample = 0, reportedConv = 0;
  double lastT = 0, lastP[DEM_MAXB][2], lastYs = 0, convMid = 0, convWall = 0;
  double ovSum = 0, ovMax = 0, setMax = 0, setSum = 0;
  long ovN = 0, setN = 0;
  double settleKe = 0, settleOvMax = 0, settleOvMean = 0;
  int settleDone = 0;
  // the push reports: [0] the hard window, [1] the gentle one
  int phaseDone[2] = { 0, 0 }, phaseOff[2] = { -1, -1 }, phaseLanded[2] = { -1, -1 };
  double phaseLeast[2] = { 0, 0 }, phaseVdown[2] = { 0, 0 };
  double rise1T = -1, rise2T = -1;
  double riseBuf[600], riseSum = 0;         // (the special bead's height, the last RISEW s of frames)
  int riseN = 0, riseK = 0;
  int lateDone = 0;
  double trMin = 1e30, trMinT = -1, trMinX = 0;   // the tracer's lowest (centre above the floor), when, and where
  double top = 0, special = 0;              // the bed's top and the special bead's centre, above the floor, at the last frame
};

#endif
