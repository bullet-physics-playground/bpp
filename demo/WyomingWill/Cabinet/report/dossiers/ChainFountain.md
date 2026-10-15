## The Chain Fountain

**What it shows** — A long bead chain is pulled over the rim of a jar 1.5 m above the floor. It then siphons out on its own, and rises in an arch above the rim instead of sliding over it. This is the "Mould effect", filmed by Steve Mould in 2013 and explained by Biggins and Warner in 2014. A link picked up by one end rotates and pushes its other end into the pile, and the pile's upward reaction throws the chain up. A rope, with no links, would just slide over.

**Model**
- Chain: Bullet rigid capsule links, 1.5 cm joint-to-joint, radius 0.3 cm, mass 0.5 g, no damping, no restitution. Neighbours are joined by btConeTwistConstraint with a swing limit equal to the bending angle (default 30 deg; CF_BEND; slider 20-90 deg, was 10-90) and free twist. Friction 0.3, chain on glass and chain on chain.
- Pile and jar: a rigid disc stands in for the coil, lowered one layer (0.65 cm) when the first link of a new layer is woken. The jar is 24 glass slabs (7 cm inside radius, 8 cm wall).
- Initial coil (changed 15 Oct 2026): flat spirals, outside in then inside out, all turning the same way. Every link is 1.5 cm and no joint is laid bent past its limit. The inner radius is max(3 cm, the tightest the chain can turn while tipping down) = 3.1 cm at 30 deg, 4.8 cm at 20. At a layer's end the chain tips down 0.65 cm over 3 links, going on round. 10 layers: 15.8 m (1053 links) at 30 deg, 9.6 m at 20, 16.1 m at 60/90. Waiting links are drawn, not simulated.
- Simulation window: links are woken so that 10 links ahead of the pick-up still lie where they were laid, at most 1200 per simulated second. The last link woken is held at its far end by a cone-twist joint to a fixed body in the next link's place. Links below y = 2.5 cm are frozen: their joint is removed and they become drawn-only, non-colliding meshes. About 130-200 links are active.
- Stepping: exactly 1/1800 s at every display speed. Each frame takes as many whole steps as its share of simulated time. Wake, freeze and measurement run after every step. 20 solver iterations.
- Bullet does all dynamics and contacts. The script does wake, anchor, freeze, the pile disc, and (read-only) measurement.

**Theory checks** — Biggins and Warner (2014): pile push a m v^2 up on the link being lifted, floor pull b m v^2. Steady flow gives v^2 = g h1/(1 - a - b) and h2 = a v^2/g (narrow arch). Here b = 0 by construction (frozen links, no joint, no collisions). Fresh runs, 10 layers, CF_SPEED=1, steady window t = 1.00 s to the last coil link woken. v = rate links land x 1.5 cm. "Push" = disc contact force minus the weight of links touching it, divided by m v^2 (CF_PUSH=1, new).

| Quantity | Theory / source | Simulation (this run) | Agreement |
|---|---|---|---|
| Same run at any display speed | must not depend on frame rate | 0.25x with pause = 1x (30 deg); 0.5x = 1x (60 deg, CF_PUSH) | **yes, exact** |
| Speed bound | ideal chain sqrt(g h1) = 384 cm/s | 397 / 450 / 425 / 432 cm/s (30/20/60/90) | faster, as a > 0 requires |
| Pile push a (direct) | B&W rod model a = (1 - I/(m b^2/4))/2: 1/6 for their chain, 0.31 for these links | 0.31 / 0.27 / 0.19 / 0.17; 0.05-0.10 lower (0.22/0.17/0.13/0.12) if every link within 7 mm of the pile is counted as lying on it | push present, same order as theirs |
| a from speed, 1 - g h1/v^2 | = push if nothing else acts | 0.06 / 0.27 / 0.18 / 0.21 | 60, 90: within the push's uncertainty. 30: **no**, the rim holds the chain up with 0.31 m v^2 (20: 0.14) |
| a from height, g h2/v^2 | = push (narrow steady arch) | 0.07 / 0.05 / 0.07 / 0.07; h2 = 10.5 / 10.7 / 12.8 / 13.2 cm | **no**: fountain about 1/3 of a v^2/g with the measured push (35 cm at 60 deg) |
| 30 deg: height vs speed | equal | 0.07 vs 0.06 | agree only by chance (push 0.31) |
| Energy at landing | lossless chain: 1/(2(1 - a)) of the drop = 60-72% | 42 / 44 / 50 / 49%; rms landing speed 352 / 361 / 383 / 380 cm/s, 11-20% below v | **no**: 11-30% of the power lost on the way |
| h2/h1 | B&W measured 0.14 | 0.070 / 0.071 / 0.085 / 0.088 | fountain lower |
| Chaos spread (jar 146, 148, 152, 154 cm) | | v 414-448 cm/s, push 0.15-0.41, height-a 0.05-0.07 | |
| Step 1/3600 s | converged? | 20 deg: v 477, push 0.39, h2 19.8; 30: 437, 0.32, 14.3 | **not converged** at 20 deg |
| Fountain above rim (CF_LOG, t >= 0.5 s), median (IQR), highest; 14 layers in brackets | README | 20: 4.7 (3.5-5.8), 11.9 [4.5 (3.0-5.8)]; 30: 5.4 (3.4-8.0), 12.4 [4.1 (1.9-6.7)]; 60: 7.7 (6.0-8.3), 10.1 [6.3]; 90: 7.8 (6.6-8.6), 12.4 [7.3] | README replaced |
| Stiffer chain, higher fountain | B&W; old README | no trend beyond chaos (medians at 4 jar heights: 6-8 / 5-7 / 4-8 / 5-8 cm) | old trend came from the bad coil |
| Time to empty | README "about 4 s" | 4.25 s (30), 4.00 (60, 90), 2.50 (20, shorter chain) | yes |

**Run used**

```
cd demo/WyomingWill/ChainFountain
CF_PUSH=1 CF_SPEED=1 CF_BEND=<20|30|60|90> CF_LOG=d<b>.csv HOLD_S=0 ../../../release/bpp -f chain-fountain.lua -n 300
CF_PUSH=1 CF_SPEED=1 CF_LAYERS=14 CF_BEND=<b> ... -n 400 ; CF_HEIGHT=<146|148|152|154> ... ; CF_STEPS=3600 ... -n 400
timeout 3000 ../../../release/bpp -f chain-fountain.lua -n 1200        # 0.25x with pause: identical to 1x
bash ../Cabinet/report/cmp2.sh chain ChainFountain chain-fountain.lua 1200 cf   # IDENTICAL (22 lines); CF_PUSH=1: IDENTICAL (23); CF_BEND=60: IDENTICAL (21)
```

```
t= 4.25s  all of it out of the jar; the fountain stood up to 12.4 cm above the rim
  theory (Biggins and Warner 2014), steady part t=1.00-3.68s; h1 = 150.2 cm, the pick-up above where a link lands (the rim is 5.3 cm above the pick-up)
  chain 397 cm/s (the rate links land): an ideal chain (a = b = 0) would go sqrt(g h1) = 384 cm/s and not rise above the pick-up
  top of the chain 10.5 cm above the pick-up on average (h2): h2/h1 = 0.070 (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = 397 cm/s
  a = g h2/v^2 = 0.07 from the height, 1 - g h1/v^2 = 0.06 from the speed (rod model for one of these links: 0.31)
  the links reach the floor at 352 cm/s (rms), with 42% of the energy of their drop (an ideal chain: 50%; one the pile pushes, more)
  the pile's push, measured (its contact forces less the weight lying on it): a = 0.31; the rim holds the chain up with 0.31 m v^2
[60 deg] a = g h2/v^2 = 0.07 from the height, 1 - g h1/v^2 = 0.18 from the speed ... a = 0.19; the rim ... 0.02 m v^2
```
Pause: CF_SPEED=1, HOLD_S=0 for 300 frames is an exact prefix of the default hold for 330 frames (24 lines).

**Known departures and honest caveats**
- Fixed 15 Oct 2026: frame-rate dependence (all work per physics step, fixed 1/1800 s) and the 60-degree stall (last woken link anchored; landed links don't collide).
- Fixed 15 Oct 2026: the coil was laid wrong. The spiral went in to 3 cm at every bending, so at 20 deg 304 of 1054 joints were laid bent past their stop (worst about 29 deg against 20). At every bending each layer began with a 0.65 cm upright link (90 deg bends) and the next layer wound the other way. When woken, the solver kicked these joints straight. The old "stiffer chain, higher fountain" (20 deg median 11.1 cm) came from those kicks: with the fixed coil it is 4.7. Only the lead's 3 corners, woken at t = 0, are still laid past the limit.
- Measurement changes (15 Oct): v is now the rate links land, not the rate they are woken. At 20 deg and 4800 steps/s the waking ran ahead (wake rate 592 cm/s, above the sqrt(2 g h1) = 542 energy bound). New lines: landing speed and energy, and with CF_PUSH=1 the directly measured push. CF_PUSH is off by default because eachContact makes the run 2.6x slower in the Cabinet (34.7 s against 13.2 s for 1200 frames).
- **Still open: the flow is not the steady, lossless flow of the theory.** The pile's push is present (a 0.17-0.31), and the speed rule matches it where the chain keeps clear of the rim. But the fountain is about a third of the narrow-arch prediction. The links land 11-20% slower than the chain's length-rate, with 42-50% of the drop's energy against at least 60% for a lossless chain. Contributing causes, seen but not isolated: the pick-up circles the spiral at the chain speed (10-20 times a second), the arch swings, the falling leg is wavy, and the chain rubs the rim (30 deg). Where the lost energy goes (joint stops, link-link contacts, rim) is not established. A pile whose pick-up stays put was not tried.
- Not step-converged at 20 deg (1/3600 s: v +6%, h2 +85%). The run is chaotic, with spreads as in the table.
- The waking scheme is not neutral. With 5 links woken ahead instead of 10 (scratch copy with CF_K), v = 476 / 452 cm/s at 30 / 60 deg (+20% / +6%) and a from speed 0.35 / 0.28, against a push of 0.21 / 0.16. The anchor's force is not measured. With 20 the woken links are dragged into a heap (276-446 links moving; at 60 deg the rim carries 1.3 m v^2). So v is known to about 20%.
- The coil is a rigid disc, not a heap. When the disc drops a layer, the last ~10 woken links of the old layer fall 0.65 cm. The anchor is infinitely strong. The floor is a freeze at 2.5 cm (b = 0 by construction).

**References**
- S. Mould, video, 2013 (README).
- J. S. Biggins, M. Warner, "Understanding the chain fountain", Proc. R. Soc. A 470 (2014) 20130689, arXiv:1310.4056: v^2 = g h1/(1 - a - b), h2/h1 = a/(1 - a - b), rod model a = (1 - I/(m b^2/4))/2 = 1/6 for three beads per link, measured h2 = 0.14 h1, energy requires a + b <= 1/2.
