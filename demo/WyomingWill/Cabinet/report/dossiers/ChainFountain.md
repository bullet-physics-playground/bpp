## The Chain Fountain

**What it shows** — A long bead chain is pulled over the rim of a jar 1.5 m above the floor. It then siphons out on its own, and rises in an arch above the rim instead of sliding over it. This is the "Mould effect", filmed by Steve Mould in 2013 and explained by Biggins and Warner in 2014. A link picked up by one end rotates and pushes its other end into the pile, and the pile's upward reaction throws the chain up. A rope, with no links, would just slide over.

**Model**
- Chain: Bullet rigid capsule links, 1.5 cm joint-to-joint, radius 0.3 cm, mass 0.5 g, with no damping and no restitution. Neighbours are joined by btConeTwistConstraint with a swing limit equal to the bending angle (default 30 deg; CF_BEND) and free twist. Friction is 0.3 for chain on glass and chain on chain.
- Pile and jar: a rigid disc stands in for the coil in the jar, lowered one layer (0.65 cm) at a time, inside a jar of 24 glass slabs (7 cm inside radius, 8 cm wall).
- Initial coil: 10 layers, 15.8 m, 1055 links, laid as flat spirals no tighter than 3 cm. It is drawn but not simulated until it is picked up.
- Simulation window: links are woken so that 10 links ahead of the pick-up still lie where they were laid, at most 1200 links per simulated second. The last link woken is held at its far end by a cone-twist joint to a fixed body in the next link's place (the coil not yet moving). Links that reach y < 2.5 cm are frozen: their joint is removed and they become drawn-only, non-colliding meshes. About 130-200 links are active at a time.
- Stepping: the step is exactly 1/1800 s at every display speed. Each frame takes as many whole steps as its share of simulated time (7 and 8 alternately at the default 0.25x). Wake, freeze and measurement run after every physics step; the fountain is sampled every 1/240 simulated s and printed every 0.25 simulated s. 20 solver iterations.
- What Bullet does: all dynamics and contacts. What the script does: wake, anchor, freeze and the pile disc. The script integrates nothing itself.

**Theory checks** — Since 15 Oct 2026 the console prints a check against Biggins and Warner (2014) at the end of each run. Their notation: h1 = drop from the pick-up to the floor, h2 = top of the chain above the pick-up, pile push a m v^2, floor pull b m v^2. Steady flow gives v^2 = g h1/(1 - a - b) and h2 = a v^2/g. Here b = 0 by construction (landed links are frozen, lose their joint and do not collide), so v = sqrt(g (h1 + h2)) with no free parameter. Table numbers are from fresh runs (10 layers unless noted). Height statistics come from the CF_LOG CSV (0.5 s until the last coil link is woken). "Highest" is the console value, which now excludes the free end flying out at the end.

| Quantity | Theory / source | Simulation (this run) | Agreement |
|---|---|---|---|
| Same run at any display speed | physics must not depend on frame rate | 0.25x (with pause), 0.5x and 1x: console and CSV identical line for line (30, 20, 60 deg) | **yes, exact** (was ~2x different) |
| Speed bound, 30 deg | ideal chain (a = b = 0): sqrt(g h1), h1 = 150.4 cm: 384 cm/s | 406 cm/s off the pile (t = 1.00-3.62 s) | +5.7%, faster as theory requires when a > 0 |
| Speed, 30 deg | B&W with b = 0: sqrt(g (h1 + h2)), h2 = 13.7 cm: 401 cm/s | 406 cm/s | **+1.2%** |
| Speed, 20 / 60 / 90 deg | same: 405 / 395 / 396 cm/s | 463 / 422 / 426 cm/s | +14% / +7% / +8%: **no for 20 deg** |
| a from height vs from speed | equal in steady flow: g h2/v^2 = 1 - g h1/v^2 | 30: 0.08 vs 0.11; 20: 0.08 vs 0.31; 60: 0.05 vs 0.17; 90: 0.05 vs 0.19 (14 layers: 0.09/0.28, 0.09/0.17, 0.05/0.20, 0.05/0.20) | only roughly at 30 deg |
| a, size of the push | B&W rod model a = (1 - I/(m b^2/4))/2: 0.31 for these links; B&W bead chain 1/6; B&W measured h2/h1 = 0.14 | a 0.05-0.09 from height; h2/h1 = 0.113 / 0.091 / 0.057 / 0.065 (20/30/60/90) | fountain lower than B&W's |
| Fountain above rim, 20 deg | (README, now this run) | median 11.1 cm (IQR 9.0-13.7), highest 21.2; 14 layers 11.1 (8.2-13.8), 24.5 | README replaced |
| 30 deg (default) | | median 8.8 (6.5-11.0), highest 16.1; 14 layers 9.2 (6.6-11.5), 16.3 | README replaced |
| 60 deg | | median 3.4 (2.4-5.0), highest 7.5; 14 layers 3.9 (2.6-5.1), 7.7 | README replaced; **no stall** |
| 90 deg | | median 4.4 (3.6-5.1), highest 9.7; 14 layers 3.7 (2.6-4.8), 9.7 | README replaced |
| Stiffer chain, higher fountain | B&W; in-app help | 20 > 30 > 60 ~ 90 | yes up to 60 deg; "twice as high at 20" was not true and the help now says "a little higher than at 30" |
| Time to empty | README: about 4 s | 4.25 s (30), 3.75 (20), 4.00 (60, 90) | yes |

**Run used**

```
cd demo/WyomingWill/ChainFountain
CF_SPEED=1 CF_BEND=<20|30|60|90> CF_LOG=r<b>.csv HOLD_S=0 ../../../release/bpp -f chain-fountain.lua -n 300
CF_LAYERS=14 CF_SPEED=1 CF_BEND=<b> CF_LOG=l<b>.csv HOLD_S=0 ../../../release/bpp -f chain-fountain.lua -n 400
timeout 3000 ../../../release/bpp -f chain-fountain.lua -n 1200        # default 0.25x with pause; identical to the 1x run
CF_HEIGHT=<60|200> CF_SPEED=1 CF_BEND=60 HOLD_S=0 ... -n 600            # 60 deg at other heights: empties (6.75 s, 3.75 s)
bash ../Cabinet/report/cmp2.sh chain ChainFountain chain-fountain.lua 1200 cf          # chain: IDENTICAL (21 run lines)
```

```
t= 4.25s  all of it out of the jar; the fountain stood up to 16.1 cm above the rim
  theory (Biggins and Warner 2014), steady part t=1.00-3.62s; h1 = 150.4 cm, the pick-up above where a link lands (the rim is 5.1 cm above the pick-up)
  chain 406 cm/s off the pile: an ideal chain (a = b = 0) would go sqrt(g h1) = 384 cm/s and not rise above the pick-up
  top of the chain 13.7 cm above the pick-up on average (h2): h2/h1 = 0.091 (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = 401 cm/s
  a = g h2/v^2 = 0.08 from the height, 1 - g h1/v^2 = 0.11 from the speed (rod model for one of these links: 0.31)
[20 deg] chain 463 cm/s off the pile ... v = sqrt(g (h1 + h2)) = 405 cm/s
[20 deg]   a = g h2/v^2 = 0.08 from the height, 1 - g h1/v^2 = 0.31 from the speed (rod model for one of these links: 0.31)
[60 deg] t= 4.00s  all of it out of the jar; the fountain stood up to 7.5 cm above the rim
```
Pause: HOLD_S=0 for 500 frames is an exact prefix of the default hold for 530 frames.

**Known departures and honest caveats**
- Fixed on 15 Oct 2026: frame-rate dependence. Wake and freeze used to run once per drawn frame, with at most 6 wakes per frame, and the step was 1/1920 s at 0.25x. Now everything runs per physics step at a fixed 1/1800 s, so all speeds give the same run.
- Fixed on 15 Oct 2026: the 60-degree stall. The diagnosis came from a dump of the old code at t = 6 s. The woken links ahead of the pick-up had a free far end. The moving chain dragged them off their places, so the wake rule kept waking until the whole remaining coil (head = 1055) was active. That left a loose heap of 140 links in the jar, held by friction and the rim, with the hanging leg's foot resting on the frozen floor links, and it stopped. The fix holds the last woken link by its far end, as the unmoved coil would. Landed links also no longer collide.
- The README table was measured afresh and replaced; the old 20/30-degree figures (10-25, 10-20 cm) were not reproduced at any speed.
- **The steady theory holds only roughly.** a should come out the same from the speed and from the height. It does roughly at 30 deg (0.11 vs 0.08), but not at 20 deg (0.31 vs 0.08) or at 60 and 90 (0.17-0.20 vs 0.05). The chain runs up to 14% faster than sqrt(g (h1 + h2)). The cause is not established. The pick-up runs round a flat spiral and the arch swings and loops. At 20 deg about 60 more links are moving than the pile-to-floor path needs. The flow is therefore not the steady flow the theory assumes. The fountain (a about 0.05-0.09) is lower than Biggins and Warner's chain (h2/h1 = 0.14, rod model 1/6).
- The coil is a rigid disc, not a heap. The anchor is infinitely strong, so the unmoved coil never yields. The "floor" is a freeze at 2.5 cm, with no floor dynamics (b = 0 by construction).
- Each run is deterministic, so "several runs" means the 10- and 14-layer runs. 60 vs 90 deg is within noise.

**References**
- S. Mould, video, 2013 ("Mould effect") (README).
- J. S. Biggins, M. Warner, "Understanding the chain fountain", Proc. R. Soc. A 470 (2014) 20130689, arXiv:1310.4056 (code and README; equations v^2 = g h1/(1 - a - b), h2/h1 = a/(1 - a - b), rod model a = (1 - I/(m b^2/4))/2, measured h2 = 0.14 h1, read from the arXiv PDF).
