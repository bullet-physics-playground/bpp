# Digest: Rebguns (2008), "Using Scouts to Predict Swarm Success Rate"

Page numbers below are PDF pages. Printed page N in the body is PDF page N+13.

## 1. Bibliographic
- **Title:** *Using Scouts to Predict Swarm Success Rate*
- **Author:** Antons Rebguns
- **Degree:** M.S. in Computer Science, University of Wyoming (Laramie), December 2008. The defense date is given as November 18, 2008 (PDF p.1, p.6).
- **Advisors:** Jerry C. Hamann (Chair) and Diana F. Spears (Co-Chair). Richard C. Anderson-Sprecher is the graduate faculty representative (PDF p.1).
- **The thesis is an unfinished draft.** Chapter 2 (Contributions), Sections 3.1.x and 4.2.3 (Implementation), and Chapter 6 (Conclusion) are empty headings. The Dedication and Acknowledgements read "To be completed" (PDF p.17–18, 29, 63).

## 2. What it is about
A swarm of n agents must cross a static obstacle field to a goal within a time limit. Before committing the whole swarm, k expendable scouts (k ≪ n, 3–15) are sent first. The fraction p̂ that arrive is used to predict P(Y ≥ y), the probability that at least y of the n agents will succeed. Two predictors are compared against simulated ground truth by MSE: the standard Bernoulli-trials (binomial) formula and a new Bayesian formula with a Beta prior over single-agent success probability p. The headline results are:
- The Bayesian formula, even with a uniform prior, usually beats Bernoulli and has lower variance.
- Both formulas usually predict *better* when agents interact through LJ forces, even though that breaks their independence assumption.

## 3. Task setup (PDF p.30–31, 33–34)
- **World:** a 2D pixel simulator with point agents ("dots"), circular obstacles and a square goal (Fig. 5.1). The thesis says the agents modelled are "ground-based mobile robots" (PDF p.4).
- **Sensing:** agents sense the goal at any distance, and obstacles in any direction within 1.5R, where R = 50 px.
- **Start:** agents are placed uniformly at random in a 100×100 px square, about 1,000 px from the goal. Start positions are re-randomized every run.
- **Time limit:** each run ends after t = 1,500 time steps.
- **Success:** an agent succeeds if it reaches the goal within the time limit (PDF p.20). The text does not say how an agent fails beyond not arriving. The screenshot shows "Collisions" and "Collision Ratio" counters.
- **Obstacles:** three environments were hand-crafted by choosing goal location, obstacle number, sizes, shapes and locations, and start-square location. They were targeted at p = 0.1, 0.5 and 0.9; measured values reported include 0.12, 0.51, 0.55 and 0.89 (PDF p.33).
- **Swarm and scouts:** n ∈ {100, 300, 500}; k ∈ {3, 5, 10, 15}; y swept from 1 to n. Scouts are assumed not to be part of the n swarm agents (PDF p.20).
- **Force law:** a Lennard-Jones variant, F = 24ε[2dR¹²/r¹³ − cR⁶/r⁷]. Here ε sets strength, R is the desired distance, and c and d weight attraction and repulsion. The parameters are "optimal" values evolved by Hettiarachchi (2007), and the text does not list them (PDF p.30–31).
- **Parameters visible in the Fig. 5.1 screenshot (PDF p.31):** I read these from the image; they appear only there.
  - Epsilon: A-A 6.75, A-O 8.99, A-G 10.72
  - c: A-A 1.43, A-O 4.45, A-G 5.25 (d takes the same values)
  - Force cutoffs: A-A 1.08, A-O 4.32, A-G 1.87
  - Max velocity 1.20
  - The screenshot run itself had 40 agents and 90 obstacles.
- **Two modes:** fully independent agents (agent–goal and agent–obstacle forces only), or added inter-agent LJ forces that hold a lattice formation.

## 4. Statistical framework (PDF p.20–29)
- **Bernoulli (PDF p.20):** P_Bern = P(Y ≥ y | p̂) = Σ_{j=y}^{n} C(n,j) p̂^j (1−p̂)^{n−j}, with p̂ = successes/k. It assumes independent trials. The thesis notes it needs roughly k > 20, and with k = 3 all-or-none scout outcomes are likely.
- **Bayesian (PDF p.21–26):** P_Bayes = ∫₀¹ ∫₀^p M · z^{y−1}(1−z)^{n−y} p^{r−1}(1−p)^{s−1} dz dp.
  - M = [B(r,s) · B(y, n−y+1)]⁻¹, with r = kp̂ + α and s = k(1−p̂) + β.
  - The prior is p ~ Beta(α, β), and the scout count kp̂ given p is Binomial(k, p), independent of the swarm.
  - The derivation replaces the binomial tail with the regularized incomplete Beta function, I_p(y, n−y+1).
  - The thesis stresses this is *not* the same as plugging the posterior mean into P_Bern.
  - It was computed with Simpson's rule for double integrals and Gaussian quadrature (PDF p.22).
  - *My note, not from the thesis:* this equals the Beta-Binomial(n, r, s) upper tail, which is the posterior predictive. That gives a closed-form way to check the integral.
- **Priors (PDF p.26–29):**
  - Mean μ = α/(α+β). The weakest unimodal prior sets one parameter to 1.
  - Strength is 1/σ². A prior is strengthened by shrinking its variance by a factor C:
    - for μ < 0.5: α* = C(1+μ) − μ and β* = ((1−μ)/μ)α*;
    - for μ ≥ 0.5: β* = C(2−μ) − (1−μ) and α* = (μ/(1−μ))β*.
  - Seven priors were tested:
    1. Uniform (1, 1)
    2. (2.1, 18.9), weak, almost correct for p = 0.1
    3. (10.9, 98.1), strong, p = 0.1
    4. (2.5, 2.5), weak, p = 0.5
    5. (14.5, 14.5), strong, p = 0.5
    6. (18.9, 2.1), weak, p = 0.9
    7. (98.1, 10.9), strong, p = 0.9
- **Using the scouts:** a "sender" deploys k scouts and a "receiver" counts how many arrive. Only those two need to communicate (PDF p.15–16).
- **Alternatives:** none are implemented. Related work mentions harvester-ant "patrollers", Lerman/Martinoli Markov macroscopic models and Lyapunov stability, contrasting them as model-only (PDF p.18–19).

## 5. Experiments and results
- **Ground truth P_Truth** is the fraction of 1,000 runs in which at least y of the n agents reach the goal (PDF p.32).
- **p̂ is treated as a random variable** over 1,000 runs, so MSE = E[(P_B − P_Truth)²] = Bias² + Variance (PDF p.35–36). This is a factorial design, and most curves are averaged over y.
- **Phase transition:** P_Truth drops sharply from 1 to 0 at y ≈ np. Both predictors smooth this drop, so the error curves are bimodal around np (PDF p.37–39).

**Independent agents (PDF p.40–51):**
- **H1, more scouts help:** confirmed, much less so for Bayes (Fig. 5.6, 5.7).
- **H2, priors:** a correct prior beats an incorrect one. If the prior is incorrect, weaker is better and uniform is best. If it is correct, stronger is better. A strong almost-correct prior "lowers the maximum MSE from 1.0 to around 0.12" (PDF p.43).
- **H3, scaling with k/n fixed at 0.03** (3/100, 10/300, 15/500): error rises slightly, so H3 is largely but not entirely confirmed (PDF p.49).
- **H4, robustness to difficulty:** MSE differs little for p from 0.12 to 0.89 and is largest near p = 0.5. Bayes beats Bernoulli across p (PDF p.49–50).
- Bayes variance is "much lower" than Bernoulli variance (PDF p.51).

**Dependent agents with LJ inter-agent forces (PDF p.51–60):**
- **H1 is mixed.** Scouts move as a "quasi-unit", so very few are needed. Extra scouts help mainly in hard environments, where the formation fractures (PDF p.52).
- **H2** is confirmed (Fig. 5.19).
- **H3** mostly holds. At p = 0.5 the MSE rises by less than 0.0025. At p = 0.1, Bayes MSE falls as n grows (PDF p.55–56).
- **H4:** MSE_Bayes with a uniform prior stays at or below about 0.05, while MSE_Bern rises toward 0.09 as p → 0.9 (Fig. 5.23). Bernoulli beats Bayes only at p = 0.1 (PDF p.57–58).
- **Worst-case MSE, averaged over y:** 0.14 for Bernoulli versus 0.08 for Bayes (PDF p.60).
- **Advice to practitioners:** use Bayes with a uniform prior when knowledge is lean, or a strong near-correct prior if one can be estimated. A k/n of 0.03 is "reasonable", and more scouts are still advised for lower variance (PDF p.60).
- **Independent vs dependent:** prediction is better with dependent agents (Fig. 5.25 vs 5.26, PDF p.61–62). Note that the two figures compare p = 0.55 with p = 0.51 rather than an identical p.

## 6. 3D, aerial vehicles, hardware, real robots
There is nothing on 3D or aerial vehicles, and no hardware experiments. The only related statements are these:
- Small k is "very practical when using real hardware robots" (PDF p.3).
- The simulator "closely mimics the behavior and properties of mobile robot platforms", and the agents are ground robots (PDF p.3–4).
- Motivating hazards are rough terrain, elevation drops, water, and circuit or mechanical failures (PDF p.2, 15).
- The approach is said to be independent of the controller (PDF p.30).

## 7. Implications for scouts on the drone obstacle-field crossing
- **Measure ground truth first.**
  - Run N ≥ 1,000 swarm trials, or as many as Bullet allows, per obstacle field. Re-randomize the start positions inside a fixed start box each trial, as the thesis does.
  - From these, record each drone's arrival within T. Compute P_Truth(y) for y = 1..n, and the per-drone p as arrivals divided by (n × runs).
  - Define success strictly as reaching a goal region before the time limit. Log losses (crash, stall, timeout) separately.
- **Scouts:**
  - Use k ∈ {3, 5, 10, 15} as in the thesis, with k/n ≈ 0.03 as the baseline (for example 3 scouts for 100 drones).
  - Run them in two modes: independent (no inter-drone LJ) and in-formation (the same LJ as the swarm), so scout dynamics match swarm dynamics.
  - Expect formation scouts to be predictive with only about 3 drones, and more scouts to matter mainly in hard fields.
- **Predictors:**
  - Compute P_Bern and P_Bayes with a uniform prior. Optionally use a strong prior centred on the p measured from earlier fields.
  - Compute P_Bayes as a Beta-Binomial tail rather than a double integral, then check it against quadrature once.
- **Evaluation:**
  - Repeat the scout draw over many trials so p̂ is random. Report MSE = Bias² + Variance against P_Truth, averaged over y and also plotted versus y.
  - Expect bimodal error near y = np.
  - Sweep obstacle density to span p ≈ 0.1, 0.5 and 0.9, and check scaling with n at constant k/n.
- **3D difference to test:** with drones, collision-induced losses may couple agents (one crash cascading into others). That is a dependence the 2D ground-robot setup never modelled, so compare prediction accuracy with and without LJ before trusting the thesis's "dependence helps" result.
