/* linkage_core.h -- generalized planar linkage mechanism model in C,
 * mirroring linkage_synthesis.py's mechanism model exactly (same param
 * layout, same Grashof/margin logic, same 2D Procrustes closed form).
 */
#ifndef LINKAGE_CORE_H
#define LINKAGE_CORE_H

#include <math.h>
#include <string.h>

#define MAX_DYADS 6
#define BASE_NPARAMS 12
#define DYAD_NPARAMS 7
#define PENALTY 1.0e6

typedef struct { double x, y; } Vec2;

static inline Vec2 v_sub(Vec2 a, Vec2 b){ Vec2 r={a.x-b.x, a.y-b.y}; return r; }
static inline double v_hyp(Vec2 a){ return sqrt(a.x*a.x + a.y*a.y); }

static inline double dotcross(Vec2 d, Vec2 p, Vec2 p0){
    return d.x*(p.y-p0.y) - d.y*(p.x-p0.x);
}

/* returns 1 if intersection exists (writes s1,s2), 0 otherwise */
static inline int circle_circle(Vec2 p0, double r0, Vec2 p1, double r1, Vec2 *s1, Vec2 *s2){
    double dx = p1.x-p0.x, dy = p1.y-p0.y;
    double d = sqrt(dx*dx+dy*dy);
    double eps = 1e-9;
    if (d < eps) return 0;
    if (d > r0+r1+eps) return 0;
    if (d < fabs(r0-r1)-eps) return 0;
    double dmin = fabs(r0-r1), dmax = r0+r1;
    double dc = d < dmin ? dmin : (d > dmax ? dmax : d);
    double a = (r0*r0 - r1*r1 + dc*dc)/(2*dc);
    double h2 = r0*r0 - a*a;
    double h = h2 > 0 ? sqrt(h2) : 0.0;
    double xm = p0.x + a*dx/d, ym = p0.y + a*dy/d;
    s1->x = xm + h*dy/d; s1->y = ym - h*dx/d;
    s2->x = xm - h*dy/d; s2->y = ym + h*dx/d;
    return 1;
}

static inline double loop_margin(Vec2 p0, double r0, Vec2 p1, double r1){
    double d = v_hyp(v_sub(p1,p0));
    double m1 = r0+r1-d, m2 = d-fabs(r0-r1);
    return m1 < m2 ? m1 : m2;
}

static inline Vec2 pick_branch(Vec2 s1, Vec2 s2, Vec2 p0, Vec2 p1, double sign){
    Vec2 d = v_sub(p1,p0);
    double c1 = dotcross(d, s1, p0);
    int want_pos = sign >= 0;
    int is_pos = c1 >= 0;
    return (is_pos == want_pos) ? s1 : s2;
}

static inline int rigid_point(Vec2 A, Vec2 B, double u, double v, Vec2 *out){
    Vec2 d = v_sub(B,A);
    double L = v_hyp(d);
    if (L < 1e-9) return 0;
    Vec2 e1 = {d.x/L, d.y/L};
    Vec2 e2 = {-e1.y, e1.x};
    out->x = A.x + u*e1.x + v*e2.x;
    out->y = A.y + u*e1.y + v*e2.y;
    return 1;
}

static inline double snap_k(double k_raw){
    double k_int = round(k_raw);
    if (k_int == 0.0) k_int = (k_raw >= 0) ? 1.0 : -1.0;
    return k_int;
}

/* Grashof crank-rocker check. Returns 1 if the crank (r2) can complete a
 * full continuous rotation. Writes grashof_margin (>=0 required) and
 * shortest_gap (<=0 required, i.e. r2 IS the shortest link). */
static inline int grashof_check(double ground, double r2, double r3, double r4,
                                 double *grashof_margin, double *shortest_gap){
    double lens[4] = {ground, r2, r3, r4};
    double s = lens[0], l = lens[0];
    for (int i=1;i<4;i++){ if (lens[i]<s) s=lens[i]; if (lens[i]>l) l=lens[i]; }
    double pq = ground+r2+r3+r4 - s - l;
    *grashof_margin = pq - (s+l);
    *shortest_gap = r2 - s;
    return (*shortest_gap <= 1e-9) && (*grashof_margin >= 0);
}

/* Verified (brute-force-checked) closed-form 2D Procrustes: rotation +
 * uniform scale (no reflection) mapping pts onto target. */
static inline void procrustes_2d(const Vec2 *pts, const Vec2 *target, int n,
                                  double *R /*len4, row-major*/, double *scale,
                                  Vec2 *mu_p, Vec2 *mu_t){
    Vec2 mp = {0,0}, mt = {0,0};
    for (int i=0;i<n;i++){ mp.x+=pts[i].x; mp.y+=pts[i].y; mt.x+=target[i].x; mt.y+=target[i].y; }
    mp.x/=n; mp.y/=n; mt.x/=n; mt.y/=n;
    double Sxx=0,Sxy=0,Syx=0,Syy=0, normP=0;
    for (int i=0;i<n;i++){
        double px=pts[i].x-mp.x, py=pts[i].y-mp.y;
        double tx=target[i].x-mt.x, ty=target[i].y-mt.y;
        Sxx += px*tx; Sxy += px*ty; Syx += py*tx; Syy += py*ty;
        normP += px*px+py*py;
    }
    if (normP < 1e-24){
        R[0]=1;R[1]=0;R[2]=0;R[3]=1; *scale=1.0; *mu_p=mp; *mu_t=mt; return;
    }
    double A = Sxx+Syy, B = Syx-Sxy;
    double theta = atan2(B, A);
    double c = cos(theta), s = sin(theta);
    R[0]=c; R[1]=-s; R[2]=s; R[3]=c;
    *scale = hypot(A,B)/normP;
    *mu_p = mp; *mu_t = mt;
}

typedef struct {
    Vec2 O2, O4;
    double r2, r3, r4, u0, v0, theta0, k, branch0;
    int n_dyads;
    Vec2 dO[MAX_DYADS];
    double dr5[MAX_DYADS], dr6[MAX_DYADS], du[MAX_DYADS], dv[MAX_DYADS], dbranch[MAX_DYADS];
} Mech;

static inline void unpack_mech(const double *p, int n_dyads, Mech *m){
    m->O2.x=p[0]; m->O2.y=p[1];
    m->O4.x=p[2]; m->O4.y=p[3];
    m->r2=p[4]; m->r3=p[5]; m->r4=p[6];
    m->u0=p[7]; m->v0=p[8];
    m->theta0=p[9]; m->k=snap_k(p[10]); m->branch0=p[11];
    m->n_dyads = n_dyads;
    int idx = BASE_NPARAMS;
    for (int i=0;i<n_dyads;i++){
        m->dO[i].x = p[idx+0]; m->dO[i].y = p[idx+1];
        m->dr5[i] = p[idx+2]; m->dr6[i] = p[idx+3];
        m->du[i] = p[idx+4]; m->dv[i] = p[idx+5];
        m->dbranch[i] = p[idx+6];
        idx += DYAD_NPARAMS;
    }
}

static inline int n_params_for(int n_dyads){ return BASE_NPARAMS + DYAD_NPARAMS*n_dyads; }
static inline int n_links_for(int n_dyads){ return 4 + 2*n_dyads; }

/* Solve one frame. Returns 1 + traced point + min margin over all loops,
 * or 0 (infeasible) + the margin at the loop that failed. */
static inline int solve_frame_with_margin(const Mech *m, double t, Vec2 *P_out, double *margin_out){
    double theta = m->k*t + m->theta0;
    Vec2 A = { m->O2.x + m->r2*cos(theta), m->O2.y + m->r2*sin(theta) };
    double margin = loop_margin(A, m->r3, m->O4, m->r4);
    if (margin < 0){ *margin_out = margin; return 0; }
    Vec2 s1, s2;
    if (!circle_circle(A, m->r3, m->O4, m->r4, &s1, &s2)){ *margin_out = margin; return 0; }
    Vec2 B = pick_branch(s1, s2, A, m->O4, m->branch0);
    Vec2 P;
    if (!rigid_point(A, B, m->u0, m->v0, &P)){ *margin_out = margin; return 0; }

    double min_margin = margin;
    for (int i=0;i<m->n_dyads;i++){
        double mg = loop_margin(P, m->dr5[i], m->dO[i], m->dr6[i]);
        if (mg < min_margin) min_margin = mg;
        if (mg < 0){ *margin_out = min_margin; return 0; }
        Vec2 c1, c2;
        if (!circle_circle(P, m->dr5[i], m->dO[i], m->dr6[i], &c1, &c2)){ *margin_out = min_margin; return 0; }
        Vec2 C = pick_branch(c1, c2, P, m->dO[i], m->dbranch[i]);
        Vec2 P_next;
        if (!rigid_point(P, C, m->du[i], m->dv[i], &P_next)){ *margin_out = min_margin; return 0; }
        P = P_next;
    }
    *P_out = P;
    *margin_out = min_margin;
    return 1;
}

/* Objective function, matching linkage_synthesis.py's objective() exactly:
 * hard Grashof gate, per-frame assembly-margin gate, curve-fit MSE (with
 * optional Procrustes alignment for mode="shape"), soft singularity
 * penalty. use_shape_mode selects Procrustes alignment; margin_scale must
 * be in the mechanism's own raw length units (NORMALIZED_R2=1.0 for shape
 * mode, target curve scale for exact mode). */
static inline double objective_c(const double *params, int n_dyads,
                                  const Vec2 *target_pts, const double *t_values, int n_samples,
                                  int use_shape_mode, double margin_scale, double min_margin_frac,
                                  int enforce_grashof, Vec2 *scratch_pts /* len >= n_samples */){
    Mech m;
    unpack_mech(params, n_dyads, &m);

    if (enforce_grashof){
        double ground = v_hyp(v_sub(m.O2, m.O4));
        double gmargin, ggap;
        int is_cr = grashof_check(ground, m.r2, m.r3, m.r4, &gmargin, &ggap);
        if (!is_cr){
            double violation = (ggap>0?ggap:0) + (gmargin<0?-gmargin:0);
            return PENALTY + 1e3*violation/margin_scale;
        }
    }

    double min_margin = 1e300;
    for (int i=0;i<n_samples;i++){
        Vec2 P; double mg;
        int ok = solve_frame_with_margin(&m, t_values[i], &P, &mg);
        if (mg < min_margin) min_margin = mg;
        if (!ok){
            return PENALTY + 1e3*((-mg)>0?(-mg):0)/margin_scale;
        }
        scratch_pts[i] = P;
    }

    double err;
    if (use_shape_mode){
        double R[4], sc; Vec2 mu_p, mu_t;
        procrustes_2d(scratch_pts, target_pts, n_samples, R, &sc, &mu_p, &mu_t);
        err = 0.0;
        for (int i=0;i<n_samples;i++){
            double px = scratch_pts[i].x-mu_p.x, py = scratch_pts[i].y-mu_p.y;
            double ax = sc*(px*R[0]+py*R[2]) + mu_t.x;
            double ay = sc*(px*R[1]+py*R[3]) + mu_t.y;
            double ex = ax - target_pts[i].x, ey = ay - target_pts[i].y;
            err += ex*ex+ey*ey;
        }
    } else {
        err = 0.0;
        for (int i=0;i<n_samples;i++){
            double ex = scratch_pts[i].x - target_pts[i].x, ey = scratch_pts[i].y - target_pts[i].y;
            err += ex*ex+ey*ey;
        }
    }
    err /= n_samples;

    double margin_threshold = min_margin_frac*margin_scale;
    if (min_margin < margin_threshold){
        double deficit = (margin_threshold-min_margin)/margin_scale;
        err += deficit*deficit*margin_scale*margin_scale*2.0;
    }
    return err;
}

#endif
