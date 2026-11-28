/* linkage_native.c -- native (C, OpenMP-parallel) minimum-link linkage
 * synthesis search, matching linkage_synthesis.py's algorithm:
 *   - same mechanism model / parameter layout (linkage_core.h)
 *   - same Grashof hard-gate + assembly-margin soft-penalty objective
 *   - same shape-mode symmetry reduction (O2=(0,0), O4 on +x axis, r2=1)
 *   - a from-scratch differential_evolution (best1bin, dithered F,
 *     binomial crossover, bounds clipping, deferred/synchronous
 *     generations) with the population evaluated in parallel via OpenMP
 *   - a Nelder-Mead local polish on the best individual after DE
 *     (playing the role of scipy's polish=True L-BFGS-B step, but
 *     gradient-free since this objective has PENALTY discontinuities)
 *   - the same escalate-D-until-tolerance-and-constructible search loop,
 *     including the fine-grained post-optimization verification pass
 *
 * Usage:
 *   linkage_native targets.txt [options]
 * targets.txt format: first line "N", then N lines of "t x y"
 *
 * Output: human-readable progress on stderr; a single machine-readable
 * line on stdout: "RESULT D=<d> rel_error=<r> constructible=<0|1>
 * is_grashof=<0|1> min_margin_frac=<m> params=<v0,v1,...,vk>"
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <stdint.h>
#ifdef _OPENMP
#include <omp.h>
#endif
#include "linkage_core.h"

/* ---------------------------------------------------------------------
 * RNG: xorshift128+, one independent stream per thread (seeded from a
 * master seed + thread id) so parallel population evaluation/mutation
 * draws are reproducible and race-free.
 * ------------------------------------------------------------------ */
typedef struct { uint64_t s[2]; } Rng;

static uint64_t splitmix64(uint64_t *state){
    uint64_t z = (*state += 0x9E3779B97F4A7C15ULL);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}
static void rng_seed(Rng *r, uint64_t seed){
    uint64_t sm = seed;
    r->s[0] = splitmix64(&sm);
    r->s[1] = splitmix64(&sm);
}
static uint64_t rng_next(Rng *r){
    uint64_t x = r->s[0], y = r->s[1];
    r->s[0] = y;
    x ^= x << 23;
    x ^= x >> 17;
    x ^= y ^ (y >> 26);
    r->s[1] = x;
    return x + y;
}
static double rng_uniform(Rng *r){ /* [0,1) */
    return (double)(rng_next(r) >> 11) * (1.0/9007199254740992.0);
}
static double rng_range(Rng *r, double lo, double hi){ return lo + (hi-lo)*rng_uniform(r); }
static int rng_int(Rng *r, int n){ return (int)(rng_uniform(r)*n); }

/* ---------------------------------------------------------------------
 * Bounds construction, mirroring build_bounds() in linkage_synthesis.py
 * ------------------------------------------------------------------ */
#define NORMALIZED_R2 1.0

typedef struct { double lo, hi; } Bound;

static int build_bounds(Bound *b, const Vec2 *target_pts, int n_samples, int n_dyads, int shape_mode){
    int dim = n_params_for(n_dyads);
    if (shape_mode){
        double R = NORMALIZED_R2;
        /* (added for the hall's alphabet: LK_BOUND, how many cranks long an
         * arm or offset may be, 8 by default; smaller keeps a linkage compact) */
        double K8 = getenv("LK_BOUND") ? atof(getenv("LK_BOUND")) : 8.0;
        int idx=0;
        b[idx].lo=0; b[idx].hi=0; idx++;            /* x2 */
        b[idx].lo=0; b[idx].hi=0; idx++;            /* y2 */
        b[idx].lo=0.03*R; b[idx].hi=K8*R; idx++;   /* x4 (>0) */
        b[idx].lo=0; b[idx].hi=0; idx++;            /* y4 */
        b[idx].lo=R; b[idx].hi=R; idx++;            /* r2 fixed */
        b[idx].lo=0.03*R; b[idx].hi=K8*R; idx++;   /* r3 */
        b[idx].lo=0.03*R; b[idx].hi=K8*R; idx++;   /* r4 */
        b[idx].lo=-K8*R; b[idx].hi=K8*R; idx++;   /* u0 */
        b[idx].lo=-K8*R; b[idx].hi=K8*R; idx++;   /* v0 */
        b[idx].lo=0.0; b[idx].hi=2*M_PI; idx++;     /* theta0 */
        b[idx].lo=-4.0; b[idx].hi=4.0; idx++;       /* k */
        b[idx].lo=-1.0; b[idx].hi=1.0; idx++;       /* branch0 */
        for (int i=0;i<n_dyads;i++){
            b[idx].lo=-K8*R; b[idx].hi=K8*R; idx++; /* Ox */
            b[idx].lo=-K8*R; b[idx].hi=K8*R; idx++; /* Oy */
            b[idx].lo=0.03*R; b[idx].hi=K8*R; idx++; /* r5 */
            b[idx].lo=0.03*R; b[idx].hi=K8*R; idx++; /* r6 */
            b[idx].lo=-K8*R; b[idx].hi=K8*R; idx++; /* u */
            b[idx].lo=-K8*R; b[idx].hi=K8*R; idx++; /* v */
            b[idx].lo=-1.0; b[idx].hi=1.0; idx++;     /* branch */
        }
        return dim;
    } else {
        double cx=0,cy=0, xmin=1e300,xmax=-1e300,ymin=1e300,ymax=-1e300;
        for (int i=0;i<n_samples;i++){
            cx += target_pts[i].x; cy += target_pts[i].y;
            if (target_pts[i].x<xmin) xmin=target_pts[i].x;
            if (target_pts[i].x>xmax) xmax=target_pts[i].x;
            if (target_pts[i].y<ymin) ymin=target_pts[i].y;
            if (target_pts[i].y>ymax) ymax=target_pts[i].y;
        }
        cx/=n_samples; cy/=n_samples;
        double span = hypot(xmax-xmin, ymax-ymin);
        double S = span > 1e-6 ? span : 1e-6;
        int idx=0;
        b[idx].lo=cx-2*S; b[idx].hi=cx+2*S; idx++;
        b[idx].lo=cy-2*S; b[idx].hi=cy+2*S; idx++;
        b[idx].lo=cx-2*S; b[idx].hi=cx+2*S; idx++;
        b[idx].lo=cy-2*S; b[idx].hi=cy+2*S; idx++;
        b[idx].lo=0.03*S; b[idx].hi=1.5*S; idx++;
        b[idx].lo=0.03*S; b[idx].hi=2.5*S; idx++;
        b[idx].lo=0.03*S; b[idx].hi=2.5*S; idx++;
        b[idx].lo=-2.5*S; b[idx].hi=2.5*S; idx++;
        b[idx].lo=-2.5*S; b[idx].hi=2.5*S; idx++;
        b[idx].lo=0.0; b[idx].hi=2*M_PI; idx++;
        b[idx].lo=-4.0; b[idx].hi=4.0; idx++;
        b[idx].lo=-1.0; b[idx].hi=1.0; idx++;
        for (int i=0;i<n_dyads;i++){
            b[idx].lo=cx-2*S; b[idx].hi=cx+2*S; idx++;
            b[idx].lo=cy-2*S; b[idx].hi=cy+2*S; idx++;
            b[idx].lo=0.03*S; b[idx].hi=2.5*S; idx++;
            b[idx].lo=0.03*S; b[idx].hi=2.5*S; idx++;
            b[idx].lo=-2.5*S; b[idx].hi=2.5*S; idx++;
            b[idx].lo=-2.5*S; b[idx].hi=2.5*S; idx++;
            b[idx].lo=-1.0; b[idx].hi=1.0; idx++;
        }
        return dim;
    }
}

/* ---------------------------------------------------------------------
 * Differential evolution: best1bin, dithered F in [Fmin,Fmax], CR fixed,
 * bounds-clipping, deferred (synchronous) generations, population
 * evaluated in parallel via OpenMP.
 * ------------------------------------------------------------------ */
typedef struct {
    int n_dyads; const Vec2 *target_pts; const double *t_values; int n_samples;
    int shape_mode; double margin_scale; double min_margin_frac; int enforce_grashof;
} ObjCtx;

static double eval_obj(const double *params, ObjCtx *ctx, Vec2 *scratch){
    return objective_c(params, ctx->n_dyads, ctx->target_pts, ctx->t_values, ctx->n_samples,
                        ctx->shape_mode, ctx->margin_scale, ctx->min_margin_frac,
                        ctx->enforce_grashof, scratch);
}

typedef struct {
    double *best_params;   /* len dim, output */
    double best_val;
} DEResult;

static void differential_evolution(
    const Bound *bounds, int dim, ObjCtx *ctx,
    int popsize_mult, int maxiter, double Fmin, double Fmax, double CR,
    uint64_t seed, int n_threads, DEResult *result, const double *warm
){
    int NP = popsize_mult * dim;
    if (NP < 5) NP = 5;

    double *pop = malloc(sizeof(double)*NP*dim);
    double *vals = malloc(sizeof(double)*NP);
    double *trial_pop = malloc(sizeof(double)*NP*dim);
    double *trial_vals = malloc(sizeof(double)*NP);

    int nt = n_threads>0?n_threads:1;
    Rng *thread_rngs = malloc(sizeof(Rng)*nt);
    for (int i=0;i<nt;i++) rng_seed(&thread_rngs[i], seed*2654435761u + i*7919 + 1);

    /* Latin Hypercube Sampling for initial population -- matches scipy's
     * default init='latinhypercube'. Naive per-dimension uniform random
     * sampling gives much worse space coverage as dimensionality grows,
     * which was a real, measured source of a search-quality gap vs scipy
     * (confirmed by comparing per-D error at matched popsize/maxiter). */
    for (int j=0;j<dim;j++){
        double lo=bounds[j].lo, hi=bounds[j].hi;
        double *strata = malloc(sizeof(double)*NP);
        for (int i=0;i<NP;i++){
            strata[i] = lo + (hi-lo)*(i + rng_uniform(&thread_rngs[0]))/NP;
        }
        /* Fisher-Yates shuffle this dimension's strata across individuals */
        for (int i=NP-1;i>0;i--){
            int k = rng_int(&thread_rngs[0], i+1);
            double tmp = strata[i]; strata[i]=strata[k]; strata[k]=tmp;
        }
        for (int i=0;i<NP;i++) pop[i*dim+j] = strata[i];
        free(strata);
    }

    /* (added for the hall's alphabet: a warm start. The previous D's best,
     * with its new dyad set to draw nothing new, is put in the population
     * with a fifth of the rest as small mutations of it, so a bigger
     * linkage never does worse than a smaller one) */
    if (warm){
        memcpy(&pop[0], warm, sizeof(double)*dim);
        for (int i=1;i<NP/5;i++) for (int j=0;j<dim;j++){
            double w = warm[j] + 0.05*(bounds[j].hi-bounds[j].lo)*(rng_uniform(&thread_rngs[0])-0.5);
            if (j >= dim - DYAD_NPARAMS) w = pop[i*dim+j];   /* the new dyad: anywhere */
            if (w < bounds[j].lo) w = bounds[j].lo; if (w > bounds[j].hi) w = bounds[j].hi;
            pop[i*dim+j] = w;
        }
    }

    Vec2 **scratch = malloc(sizeof(Vec2*)*nt);
    for (int i=0;i<nt;i++) scratch[i] = malloc(sizeof(Vec2)*ctx->n_samples);

    #pragma omp parallel for num_threads(nt) schedule(static)
    for (int i=0;i<NP;i++){
        int tid = 0;
        #ifdef _OPENMP
        tid = omp_get_thread_num();
        #endif
        vals[i] = eval_obj(&pop[i*dim], ctx, scratch[tid]);
    }

    int best_idx = 0;
    for (int i=1;i<NP;i++) if (vals[i] < vals[best_idx]) best_idx = i;

    for (int gen=0; gen<maxiter; gen++){
        double F = rng_range(&thread_rngs[0], Fmin, Fmax);

        #pragma omp parallel for num_threads(nt) schedule(static)
        for (int i=0;i<NP;i++){
            int tid = 0;
            #ifdef _OPENMP
            tid = omp_get_thread_num();
            #endif
            Rng *r = &thread_rngs[tid];

            int b_idx, c_idx;
            do { b_idx = rng_int(r, NP); } while (b_idx==i || b_idx==best_idx);
            do { c_idx = rng_int(r, NP); } while (c_idx==i || c_idx==best_idx || c_idx==b_idx);

            double trial[64];
            int forced = rng_int(r, dim);
            for (int j=0;j<dim;j++){
                double val;
                if (j==forced || rng_uniform(r) < CR){
                    val = pop[best_idx*dim+j] + F*(pop[b_idx*dim+j]-pop[c_idx*dim+j]);
                    if (val < bounds[j].lo) val = bounds[j].lo;
                    if (val > bounds[j].hi) val = bounds[j].hi;
                } else {
                    val = pop[i*dim+j];
                }
                trial[j] = val;
            }
            memcpy(&trial_pop[i*dim], trial, sizeof(double)*dim);
            trial_vals[i] = eval_obj(trial, ctx, scratch[tid]);
        }

        for (int i=0;i<NP;i++){
            if (trial_vals[i] <= vals[i]){
                memcpy(&pop[i*dim], &trial_pop[i*dim], sizeof(double)*dim);
                vals[i] = trial_vals[i];
                if (vals[i] < vals[best_idx]) best_idx = i;
            }
        }
    }

    result->best_val = vals[best_idx];
    memcpy(result->best_params, &pop[best_idx*dim], sizeof(double)*dim);

    for (int i=0;i<nt;i++) free(scratch[i]);
    free(scratch); free(thread_rngs);
    free(pop); free(vals); free(trial_pop); free(trial_vals);
}

/* ---------------------------------------------------------------------
 * Nelder-Mead local polish (gradient-free, since PENALTY branches make
 * the objective non-smooth) -- plays the role of scipy's polish=True step
 * ------------------------------------------------------------------ */
static void nelder_mead_polish(double *x, int dim, ObjCtx *ctx, Vec2 *scratch,
                                const Bound *bounds, int max_evals){
    int n1 = dim+1;
    double *simplex = malloc(sizeof(double)*n1*dim);
    double *fvals = malloc(sizeof(double)*n1);
    for (int i=0;i<n1;i++){
        memcpy(&simplex[i*dim], x, sizeof(double)*dim);
        if (i>0){
            int j = i-1;
            double range = bounds[j].hi-bounds[j].lo;
            double step = range*0.02;
            simplex[i*dim+j] += (step>1e-9?step:1e-6);
            if (simplex[i*dim+j] > bounds[j].hi) simplex[i*dim+j] = bounds[j].hi;
        }
        fvals[i] = eval_obj(&simplex[i*dim], ctx, scratch);
    }
    int evals = n1;
    double *centroid = malloc(sizeof(double)*dim);
    double *xr = malloc(sizeof(double)*dim), *xe = malloc(sizeof(double)*dim), *xc = malloc(sizeof(double)*dim);
    while (evals < max_evals){
        for (int i=0;i<n1;i++) for (int j=i+1;j<n1;j++) if (fvals[j]<fvals[i]){
            double tmp=fvals[i]; fvals[i]=fvals[j]; fvals[j]=tmp;
            for (int k=0;k<dim;k++){ double t2=simplex[i*dim+k]; simplex[i*dim+k]=simplex[j*dim+k]; simplex[j*dim+k]=t2; }
        }
        double best = fvals[0], worst = fvals[n1-1];
        if (fabs(worst-best) < 1e-14*(fabs(best)+1e-300)) break;
        for (int j=0;j<dim;j++){
            double s=0; for (int i=0;i<n1-1;i++) s += simplex[i*dim+j];
            centroid[j] = s/(n1-1);
        }
        for (int j=0;j<dim;j++){
            double val = centroid[j] + 1.0*(centroid[j]-simplex[(n1-1)*dim+j]);
            if (val<bounds[j].lo) val=bounds[j].lo; if (val>bounds[j].hi) val=bounds[j].hi;
            xr[j]=val;
        }
        double fr = eval_obj(xr, ctx, scratch); evals++;
        if (fr < fvals[0]){
            for (int j=0;j<dim;j++){
                double val = centroid[j] + 2.0*(centroid[j]-simplex[(n1-1)*dim+j]);
                if (val<bounds[j].lo) val=bounds[j].lo; if (val>bounds[j].hi) val=bounds[j].hi;
                xe[j]=val;
            }
            double fe = eval_obj(xe, ctx, scratch); evals++;
            if (fe < fr){ memcpy(&simplex[(n1-1)*dim], xe, sizeof(double)*dim); fvals[n1-1]=fe; }
            else { memcpy(&simplex[(n1-1)*dim], xr, sizeof(double)*dim); fvals[n1-1]=fr; }
        } else if (fr < fvals[n1-2]){
            memcpy(&simplex[(n1-1)*dim], xr, sizeof(double)*dim); fvals[n1-1]=fr;
        } else {
            for (int j=0;j<dim;j++) xc[j] = centroid[j] + 0.5*(simplex[(n1-1)*dim+j]-centroid[j]);
            double fc = eval_obj(xc, ctx, scratch); evals++;
            if (fc < fvals[n1-1]){ memcpy(&simplex[(n1-1)*dim], xc, sizeof(double)*dim); fvals[n1-1]=fc; }
            else {
                for (int i=1;i<n1;i++){
                    for (int j=0;j<dim;j++){
                        simplex[i*dim+j] = simplex[0*dim+j] + 0.5*(simplex[i*dim+j]-simplex[0*dim+j]);
                        if (simplex[i*dim+j]<bounds[j].lo) simplex[i*dim+j]=bounds[j].lo;
                        if (simplex[i*dim+j]>bounds[j].hi) simplex[i*dim+j]=bounds[j].hi;
                    }
                    fvals[i] = eval_obj(&simplex[i*dim], ctx, scratch); evals++;
                }
            }
        }
    }
    int best_i=0; for (int i=1;i<n1;i++) if (fvals[i]<fvals[best_i]) best_i=i;
    if (fvals[best_i] < eval_obj(x, ctx, scratch)){
        memcpy(x, &simplex[best_i*dim], sizeof(double)*dim);
    }
    free(simplex); free(fvals); free(centroid); free(xr); free(xe); free(xc);
}

/* ---------------------------------------------------------------------
 * Fine-grained post-optimization constructibility verification, matching
 * mechanism_diagnostics() in linkage_synthesis.py
 * ------------------------------------------------------------------ */
static void mechanism_diagnostics(const double *params, int n_dyads, double t0, double t1, int n_verify,
                                   double margin_scale, int *is_grashof, int *fully_assembles,
                                   double *min_margin_frac){
    Mech m; unpack_mech(params, n_dyads, &m);
    double ground = v_hyp(v_sub(m.O2, m.O4));
    double gmargin, ggap;
    *is_grashof = grashof_check(ground, m.r2, m.r3, m.r4, &gmargin, &ggap);

    double min_margin = 1e300;
    *fully_assembles = 1;
    for (int i=0;i<n_verify;i++){
        double t = t0 + (t1-t0)*i/(double)n_verify;
        Vec2 P; double mg;
        int ok = solve_frame_with_margin(&m, t, &P, &mg);
        if (mg < min_margin) min_margin = mg;
        if (!ok){ *fully_assembles = 0; break; }
    }
    *min_margin_frac = min_margin/margin_scale;
}

/* --------------------------------------------------------------------- */

static int read_targets(const char *path, Vec2 **target_pts, double **t_values, int *n){
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    if (fscanf(f, "%d", n) != 1){ fclose(f); return 0; }
    *target_pts = malloc(sizeof(Vec2)*(*n));
    *t_values = malloc(sizeof(double)*(*n));
    for (int i=0;i<*n;i++){
        double t,x,y;
        if (fscanf(f, "%lf %lf %lf", &t,&x,&y) != 3){ fclose(f); return 0; }
        (*t_values)[i]=t; (*target_pts)[i].x=x; (*target_pts)[i].y=y;
    }
    fclose(f);
    return 1;
}

static double get_opt_double(int argc, char **argv, const char *name, double def){
    for (int i=1;i<argc-1;i++) if (strcmp(argv[i],name)==0) return atof(argv[i+1]);
    return def;
}
static int get_opt_int(int argc, char **argv, const char *name, int def){
    for (int i=1;i<argc-1;i++) if (strcmp(argv[i],name)==0) return atoi(argv[i+1]);
    return def;
}
static const char* get_opt_str(int argc, char **argv, const char *name, const char *def){
    for (int i=1;i<argc-1;i++) if (strcmp(argv[i],name)==0) return argv[i+1];
    return def;
}

int main(int argc, char **argv){
    if (argc < 2){
        fprintf(stderr, "usage: %s targets.txt [--max_extra_dyads N] [--tol T] [--mode shape|exact]\n"
                         "          [--popsize N] [--maxiter N] [--seed N] [--threads N]\n"
                         "          [--min_margin_frac F] [--verify_n N] [--enforce_grashof 0|1]\n", argv[0]);
        return 1;
    }
    Vec2 *target_pts; double *t_values; int n_samples;
    if (!read_targets(argv[1], &target_pts, &t_values, &n_samples)){
        fprintf(stderr, "failed to read targets file %s\n", argv[1]);
        return 1;
    }
    int max_extra_dyads = get_opt_int(argc, argv, "--max_extra_dyads", 2);
    double tol = get_opt_double(argc, argv, "--tol", 0.02);
    const char *mode = get_opt_str(argc, argv, "--mode", "shape");
    int shape_mode = strcmp(mode, "shape")==0;
    int popsize = get_opt_int(argc, argv, "--popsize", 20);
    int maxiter = get_opt_int(argc, argv, "--maxiter", 150);
    unsigned long seed = (unsigned long)get_opt_int(argc, argv, "--seed", 0);
    int threads = get_opt_int(argc, argv, "--threads", 1);
    double min_margin_frac = get_opt_double(argc, argv, "--min_margin_frac", 0.05);
    int verify_n = get_opt_int(argc, argv, "--verify_n", 360);
    int enforce_grashof = get_opt_int(argc, argv, "--enforce_grashof", 1);
    double t0 = t_values[0], t1 = t_values[n_samples-1] + (t_values[n_samples-1]-t_values[n_samples-2]);

    if (max_extra_dyads > MAX_DYADS) max_extra_dyads = MAX_DYADS;

    double xmin=1e300,xmax=-1e300,ymin=1e300,ymax=-1e300;
    for (int i=0;i<n_samples;i++){
        if (target_pts[i].x<xmin) xmin=target_pts[i].x; if (target_pts[i].x>xmax) xmax=target_pts[i].x;
        if (target_pts[i].y<ymin) ymin=target_pts[i].y; if (target_pts[i].y>ymax) ymax=target_pts[i].y;
    }
    double scale = hypot(xmax-xmin, ymax-ymin); if (scale<1e-6) scale=1e-6;
    double margin_scale = shape_mode ? NORMALIZED_R2 : scale;

    double best_params[512]; int best_D = -1; double best_rel_err = 1e300; int best_constructible = 0;
    double final_params[512]; double final_rel_err=1e300; int final_D=-1;
    int final_is_grashof=0, final_fully_assembles=0; double final_margin_frac=0;
    int found = 0;

    double prev_params[512]; int prev_ok = 0;
    for (int D=0; D<=max_extra_dyads; D++){
        int dim = n_params_for(D);
        Bound bounds[512];
        build_bounds(bounds, target_pts, n_samples, D, shape_mode);

        ObjCtx ctx = { D, target_pts, t_values, n_samples, shape_mode, margin_scale, min_margin_frac, enforce_grashof };
        DEResult res; double params[512]; res.best_params = params;
        double warm[512]; int have_warm = 0;
        if (D > 0 && prev_ok){
            int pd = n_params_for(D-1);
            memcpy(warm, prev_params, sizeof(double)*pd);
            /* (a dyad that draws nothing new: its output point is its input,
             * u = v = 0; it hangs from a pivot well away from the curve, on
             * equal arms, so it assembles everywhere) */
            double cx = 0, cy = 0; Mech pm; unpack_mech(prev_params, D-1, &pm);
            Vec2 P; double mg; double far = 0;
            for (int i=0;i<n_samples;i++){ if (solve_frame_with_margin(&pm, t_values[i], &P, &mg)){ cx += P.x; cy += P.y; } }
            cx /= n_samples; cy /= n_samples;
            for (int i=0;i<n_samples;i++){ if (solve_frame_with_margin(&pm, t_values[i], &P, &mg)){ double d = hypot(P.x-cx, P.y-cy); if (d > far) far = d; } }
            double g = 0.3;
            double dirs[8][2] = {{1,0},{-1,0},{0,1},{0,-1},{.7,.7},{-.7,.7},{.7,-.7},{-.7,-.7}};
            for (int k=0;k<8 && !have_warm;k++){
                double ox = cx + dirs[k][0]*(far + g), oy = cy + dirs[k][1]*(far + g);
                /* (kept inside the bounds) */
                if (ox < bounds[pd+0].lo + 0.01) ox = bounds[pd+0].lo + 0.01; if (ox > bounds[pd+0].hi - 0.01) ox = bounds[pd+0].hi - 0.01;
                if (oy < bounds[pd+1].lo + 0.01) oy = bounds[pd+1].lo + 0.01; if (oy > bounds[pd+1].hi - 0.01) oy = bounds[pd+1].hi - 0.01;
                double dmin = 1e300, dmax = 0;
                for (int i=0;i<n_samples;i++){ if (solve_frame_with_margin(&pm, t_values[i], &P, &mg)){ double d = hypot(P.x-ox, P.y-oy); if (d < dmin) dmin = d; if (d > dmax) dmax = d; } }
                double R = dmax/2 + 0.3;
                if (dmin < 0.12) continue;
                warm[pd+0] = ox; warm[pd+1] = oy;
                warm[pd+2] = R; warm[pd+3] = R; warm[pd+4] = 0; warm[pd+5] = 0; warm[pd+6] = 1;
                have_warm = 1;
                for (int j=pd;j<dim;j++) if (warm[j] < bounds[j].lo || warm[j] > bounds[j].hi) have_warm = 0;
            }
            { Vec2 *sc = malloc(sizeof(Vec2)*n_samples); ObjCtx c2 = { D, target_pts, t_values, n_samples, shape_mode, margin_scale, min_margin_frac, enforce_grashof };
              ObjCtx c1 = c2; c1.n_dyads = D-1;
              fprintf(stderr, "  (warm start for D=%d: %s; the curve's reach %.2f; objective %g, was %g)\n", D, have_warm ? "yes" : "no, out of bounds", far, eval_obj(warm, &c2, sc), eval_obj(prev_params, &c1, sc)); free(sc); }
        }
        differential_evolution(bounds, dim, &ctx, popsize, maxiter, 0.4, 1.5, 0.8, seed, threads, &res, have_warm ? warm : NULL);

        Vec2 *polish_scratch = malloc(sizeof(Vec2)*n_samples);
        nelder_mead_polish(params, dim, &ctx, polish_scratch, bounds, 400*dim);
        res.best_val = eval_obj(params, &ctx, polish_scratch);
        free(polish_scratch);

        double rms_err = sqrt(res.best_val > PENALTY ? PENALTY : (res.best_val<0?0:res.best_val));
        memcpy(prev_params, params, sizeof(double)*dim); prev_ok = res.best_val < PENALTY;
        double rel_err = rms_err/scale;

        int is_grashof, fully_assembles; double margin_frac;
        mechanism_diagnostics(params, D, t0, t1, verify_n, margin_scale, &is_grashof, &fully_assembles, &margin_frac);
        int constructible = fully_assembles && (is_grashof || !enforce_grashof);
        int meets = (rel_err < tol) && constructible;

        fprintf(stderr, "[D=%d, links=%d] best rms error = %.5g (relative = %.4f%%) -> %s; %s "
                        "[Grashof crank-rocker: %s, min margin = %.2f%%]\n",
                D, n_links_for(D), rms_err, rel_err*100.0,
                meets ? "MEETS TOLERANCE" : "above tolerance",
                constructible ? "constructible" : "NOT constructible (fails verification)",
                is_grashof ? "True":"False", margin_frac*100.0);

        /* (added for the hall's alphabet: every D's best, with its params) */
        printf("DRESULT D=%d rel_error=%.10f constructible=%d min_margin_frac=%.6f params=", D, rel_err, constructible, margin_frac);
        for (int i=0;i<dim;i++) printf("%s%.10f", i>0?",":"", params[i]);
        printf("\n"); fflush(stdout);

        if (best_D == -1 || (constructible && !best_constructible) ||
            (constructible == best_constructible && rel_err < best_rel_err)){
            best_D = D; best_rel_err = rel_err; best_constructible = constructible;
            memcpy(best_params, params, sizeof(double)*dim);
        }
        if (meets){
            final_D = D; final_rel_err = rel_err; memcpy(final_params, params, sizeof(double)*dim);
            final_is_grashof = is_grashof; final_fully_assembles = fully_assembles; final_margin_frac = margin_frac;
            found = 1;
            break;
        }
    }

    int out_D = found ? final_D : best_D;
    int out_dim = n_params_for(out_D);
    double *out_params = found ? final_params : best_params;

    if (!found){
        fprintf(stderr, "WARNING: no mechanism up to %d extra dyads met tolerance %.3f%% with a "
                        "verified-constructible design; returning best found (D=%d, rel_error=%.3f%%, constructible=%d)\n",
                max_extra_dyads, tol*100.0, out_D, best_rel_err*100.0, best_constructible);
        mechanism_diagnostics(out_params, out_D, t0, t1, verify_n, margin_scale,
                              &final_is_grashof, &final_fully_assembles, &final_margin_frac);
        final_rel_err = best_rel_err;
    }

    printf("RESULT D=%d rel_error=%.10f constructible=%d is_grashof=%d min_margin_frac=%.10f params=",
           out_D, final_rel_err, found?1:best_constructible, final_is_grashof, final_margin_frac);
    for (int i=0;i<out_dim;i++) printf("%s%.10f", i>0?",":"", out_params[i]);
    printf("\n");

    free(target_pts); free(t_values);
    return 0;
}
