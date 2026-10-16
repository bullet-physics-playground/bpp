## The Chain Fountain

**What it shows** — A long bead chain is pulled over the rim of a jar 1.5 m above the floor. It then siphons out on its own, and rises in an arch above the rim instead of sliding over it. This is the "Mould effect", filmed by Steve Mould in 2013 and explained by Biggins and Warner in 2014. A link picked up by one end rotates and pushes its other end into the pile, and the pile's upward reaction throws the chain up. A rope, with no links, would just slide over.

**Model**
- Chain: Bullet rigid capsule links, 1.5 cm joint-to-joint, radius 0.3 cm, mass 0.5 g, no damping, no restitution. Neighbours are joined by btConeTwistConstraint with a swing limit equal to the bending angle (default 30 deg; CF_BEND; slider 20-90 deg, was 10-90) and free twist. Friction 0.3, chain on glass and chain on chain.
- Pile and jar: a rigid disc stands in for the coil, lowered one layer (0.65 cm) when the first link of a new layer is woken. The jar is 24 glass slabs (7 cm inside radius, 8 cm wall).
- Initial coil (changed 15 Oct 2026): flat spirals, outside in then inside out, all turning the same way. Every link is 1.5 cm and no joint is laid bent past its limit. The inner radius is max(3 cm, the tightest the chain can turn while tipping down) = 3.1 cm at 30 deg, 4.8 cm at 20. At a layer's end the chain tips down 0.65 cm over 3 links, going on round. 10 layers: 15.8 m (1053 links) at 30 deg, 9.6 m at 20, 16.1 m at 60/90. Waiting links are drawn, not simulated.
- Simulation window: links are woken so that 10 links ahead of the pick-up still lie where they were laid, at most 1200 per simulated second. The last link woken is held at its far end by a cone-twist joint to a fixed body in the next link's place. Links below y = 2.5 cm are frozen: their joint is removed and they become drawn-only, non-colliding meshes. About 130-200 links are active.
- Stepping: exactly 1/1800 s at every display speed. Each frame takes as many whole steps as its share of simulated time. Wake, freeze and measurement run after every step. 20 solver iterations.
- Bullet does all dynamics and contacts. The script does wake, anchor, freeze, the pile disc, and (read-only) measurement.

**Theory checks** — Biggins and Warner (2014): pile push a m v^2 up on the link being lifted, floor pull b m v^2. Steady flow gives v^2 = g h1/(1 - a - b) and h2 = a v^2/g (narrow arch). Here b = 0 by construction (frozen links, no joint, no collisions). Fresh runs, 10 layers, CF_SPEED=1, steady window t = 1.00 s to the last coil link woken. v = rate links land x 1.5 cm. "Push" = disc contact force minus the weight of links touching it, divided by m v^2 (CF_PUSH=1). "Carried" (new, CF_PUSH=1) = -(T - m v_i^2 - m g y)/(m v^2) on the freely falling chain 20-100 cm below the pick-up. T is the tension worked out from the links' accelerations, summed up from the free lowest link. A steady B&W chain keeps this equal to a from pile to floor.

| Quantity | Theory / source | Simulation (this run) | Agreement |
|---|---|---|---|
| Same run at any display speed | must not depend on frame rate | 0.25x with pause = 1x (30 deg); 0.5x = 1x (60 deg, CF_PUSH) | **yes, exact** |
| Speed bound | ideal chain sqrt(g h1) = 384 cm/s | 397 / 450 / 425 / 432 cm/s (30/20/60/90) | faster, as a > 0 requires |
| Pile push a (direct) | B&W rod model a = (1 - I/(m b^2/4))/2: 1/6 for their chain, 0.31 for these links | 0.31 / 0.27 / 0.19 / 0.17; 0.05-0.10 lower (0.22/0.17/0.13/0.12) if every link within 7 mm of the pile is counted as lying on it | push present, same order as theirs |
| a from speed, 1 - g h1/v^2 | = push if nothing else acts | 0.06 / 0.27 / 0.18 / 0.21 | 60, 90: within the push's uncertainty. 30: **no**, the rim holds the chain up with 0.31 m v^2 (20: 0.14) |
| a from height, g h2/v^2 | = push (narrow steady arch) | 0.07 / 0.05 / 0.07 / 0.07; h2 = 10.5 / 10.7 / 12.8 / 13.2 cm | **no**: fountain about 1/3 of a v^2/g with the measured push (35 cm at 60 deg) |
| 30 deg: height vs speed | equal | 0.07 vs 0.06 | agree only by chance (push 0.31) |
| Energy at landing | lossless chain: 1/(2(1 - a)) of the drop = 60-72% | 42 / 44 / 50 / 49%; rms landing speed 352 / 361 / 383 / 380 cm/s, 11-20% below v | **no**: 11-30% of the power lost on the way |
| a the falling chain carries | = push (steady, lossless) | -0.13 / -0.07 / 0.04 / 0.03 | **no**: a third or less of the push reaches the falling chain; below zero where the rim takes more (20, 30) |
| Stationary pick-up (CF_LAYOUT=flake, CF_JAR=0, 40 layers; 45/60/90 deg) | h2 = a v^2/g | push 0.28/0.23/0.13; h2 18.2/17.3/9.1 cm = 0.36/0.40/0.36 of push v^2/g; spiral on the same table 0.30/0.29 (60/90) | **no**: helps a little (60 deg 17.3 vs 10.6 cm), not the cause |
| Flake: theory with the carried a (0.10/0.08/0.06) | h2 = a v^2/g; v = sqrt(g h1/(1 - a)); energy 1/(2(1 - a)) | h2 ratio 1.01/1.16/0.79; rms landing speed 0.979/0.972/0.962 of the formula; energy 53/51/49% against 56/54/53% | **yes, within 21% (height), 4% (speed), 4 points (energy)** |
| One thing at a time (flake 60 and spiral 60): steps 3600, 7200; iterations 50, 100; friction 0; joint stops off (CF_STOP=179); 5, 15 woken ahead; links half size (CF_LINK=0.5) | | h2/(push v^2/g) 0.25-0.50 (flake), 0.24-0.35 (spiral); energy 43-53% | no model channel restores the fountain |
| Shortcut vs every link simulated (CF_LIVE=1; 6 layers, 5 runs each at jar 146-154 cm, CF_PUSH=2) | the shortcut should not matter | h2 every link / exhibit's way: 8.6±0.4 / 10.6±1.5 (30), 6.3±0.5 / 10.8±0.6 (60), 5.5±0.4 / 11.2±0.8 (90) cm. Unmoved-pile push 0.49/0.23/0.20 vs 0.20/0.17/0.15. Carried -0.13/-0.19/-0.16 vs -0.01/0.01/0.01. Rim 0.26/0.32/0.28 vs 0.13/0.03/0.03 m v^2. v 399/379/397 vs 420/418/423 cm/s | shortcut **not** the cause of the lost push (every-link chain carries none either), but it **raises the fountain** 1.2x (30) to 2x (60, 90) and keeps the chain off the rim |
| Reference convergence | | every link, 3600 steps/s: h2 8.5, 9.4 (30); 5.7, 6.0 (90). Settled 0.3 s first: 9.6 (30). Landed links left on the floor: 8.5 (30) | within the 5-run spread |
| Cheaper match (CF_WAKE=layer) | = every link | 4 live layers at 30: v 406±17, h2 8.7±0.6, push 0.48, carried -0.09, rim 0.20; 3 layers match at 60; at 90 neither (v 356-359 vs 397, rim 0.57-0.62 vs 0.28) | matches at 30 and 60 |
| Cost per frame, 0.25x, standalone (Cabinet run, 1200 frames) | 16.7 ms at 60 fps | exhibit 4.4 ms (12.8 s); 4 live layers 21 ms (30.3 s); every link 35 ms (46.9 s) | faithful ways not affordable: default unchanged |
| h2/h1 | B&W measured 0.14 (a = 0.12 by their formula with b = 0) | 0.070 / 0.071 / 0.085 / 0.088 (spiral), up to 0.13 (flake 45) | fountain lower |
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
CF_PUSH=1 CF_SPEED=1 CF_JAR=0 CF_LAYOUT=flake CF_LAYERS=40 CF_BEND=<45|60|90> HOLD_S=0 ... -n 400   # plus CF_STEPS, CF_ITER, CF_MU=0, CF_STOP=179, CF_AHEAD, CF_LINK=0.5 one at a time
timeout 3000 ../../../release/bpp -f chain-fountain.lua -n 1200        # 0.25x with pause: identical to 1x
bash ../Cabinet/report/cmp2.sh chain ChainFountain chain-fountain.lua 1200 cf   # IDENTICAL (22 lines); CF_PUSH=1: IDENTICAL (25); flake 60 CF_PUSH=1 (1300 frames): IDENTICAL (23)
CF_LIVE=1 CF_LAYERS=<6> CF_HEIGHT=<146..154> CF_BEND=<30|60|90> CF_PUSH=2 CF_SPEED=1 HOLD_S=0 ... -n 400   # and the same without CF_LIVE, and with CF_WAKE=layer CF_LIVELAYERS=<3|4>
CF_LIVE=1 CF_LAYERS=6 CF_PUSH=2 bash ../Cabinet/report/cmp2.sh chain ... 1100 cfl   # IDENTICAL (21); CF_WAKE=layer CF_LIVELAYERS=4 CF_PUSH=2, 1200 frames: IDENTICAL (26)
```

```
t= 4.25s  all of it out of the jar; the fountain stood up to 12.4 cm above the rim
  theory (Biggins and Warner 2014), steady part t=1.00-3.68s; h1 = 150.2 cm, the pick-up above where a link lands (the rim is 5.3 cm above the pick-up)
  chain 397 cm/s (the rate links land): an ideal chain (a = b = 0) would go sqrt(g h1) = 384 cm/s and not rise above the pick-up
  top of the chain 10.5 cm above the pick-up on average (h2): h2/h1 = 0.070 (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = 397 cm/s
  a = g h2/v^2 = 0.07 from the height, 1 - g h1/v^2 = 0.06 from the speed (rod model for one of these links: 0.31)
  the links reach the floor at 352 cm/s (rms), with 42% of the energy of their drop (an ideal chain: 50%; one the pile pushes, more)
  the pile's push, measured (its contact forces less the weight lying on it): a = 0.31; the rim holds the chain up with 0.31 m v^2
  with that push a steady narrow arch would stand h2 = a v^2/g = 50.4 cm above the pick-up (it stood 10.5)
  what the falling chain carries of it (its tension, from the links' accelerations, 20-100 cm below the pick-up): a = -0.13
[flake 60, table] the pile's push ... a = 0.23 ... h2 = a v^2/g = 42.9 cm (it stood 17.3) ... carries of it ... a = 0.08
[60 deg] a = g h2/v^2 = 0.07 from the height, 1 - g h1/v^2 = 0.18 from the speed ... a = 0.19; the rim ... 0.02 m v^2
```
Pause: CF_SPEED=1, HOLD_S=0 for 300 frames is an exact prefix of the default hold for 330 frames (24 lines; with CF_PUSH=1, 27 lines). Default output (CF_PUSH off) is byte-identical to the committed b241d9c. 0.25x with pause = 1x with CF_PUSH=1; flake 60 at 0.5x = 1x.

**Known departures and honest caveats**
- Fixed 15 Oct 2026: frame-rate dependence (all work per physics step, fixed 1/1800 s) and the 60-degree stall (last woken link anchored; landed links don't collide).
- Fixed 15 Oct 2026: the coil was laid wrong. The spiral went in to 3 cm at every bending, so at 20 deg 304 of 1054 joints were laid bent past their stop (worst about 29 deg against 20). At every bending each layer began with a 0.65 cm upright link (90 deg bends) and the next layer wound the other way. When woken, the solver kicked these joints straight. The old "stiffer chain, higher fountain" (20 deg median 11.1 cm) came from those kicks: with the fixed coil it is 4.7. Only the lead's 3 corners, woken at t = 0, are still laid past the limit.
- Measurement changes (15 Oct): v is now the rate links land, not the rate they are woken. At 20 deg and 4800 steps/s the waking ran ahead (wake rate 592 cm/s, above the sqrt(2 g h1) = 542 energy bound). New lines: landing speed and energy, and with CF_PUSH=1 the directly measured push. CF_PUSH is off by default because eachContact makes the run 2.6x slower in the Cabinet (34.7 s against 13.2 s for 1200 frames).
- **Located 15 Oct 2026, mechanism still open: the fountain is low because the pile's push doesn't reach the moving chain.** The pile pushes up with a = 0.13-0.31, but the falling chain carries only a third or less of it. A pile whose pick-up stays put (flake on a table) raises the fountain only a little (ratio 0.36-0.40 against 0.29-0.30 for the spiral on the same table). No model channel tried (step x2 and x4, iterations x2.5 and x5, friction 0, joint stops off, link size x0.5, look-ahead 5/15) brings the ratio above 0.50. With the push the chain does carry, the flake obeys all three B&W relations: height within 21%, speed within 4%, energy within 4 points. So the earlier apparent 11-30% energy loss mostly came from using the contact push as a. The gap is in the pick-up zone. The chain is dragged and lifted over several links (still only about 90% of full speed 4-6 cm above the pile, from the inferred tension), not picked up a link at a time. This does not change with step or iterations, so it is not solver convergence. Without joint stops the push itself halves. On the spiral, and with half-size links, the falling chain carries 0.00-0.04 while the fountain stands higher than that would give. So between pile and falling leg those flows are not steady either. Whether real chains also carry only part of the contact push is unknown; B&W's own h2 = 0.14 h1 means a = 0.12 against their rod model's 1/6.
- Not step-converged at 20 deg (1/3600 s: v +6%, h2 +85%). The run is chaotic, with spreads as in the table.
- The waking scheme is not neutral. With 5 links woken ahead instead of 10 (scratch copy with CF_K), v = 476 / 452 cm/s at 30 / 60 deg (+20% / +6%) and a from speed 0.35 / 0.28, against a push of 0.21 / 0.16. The anchor's force is not measured. With 20 the woken links are dragged into a heap (276-446 links moving; at 60 deg the rim carries 1.3 m v^2). So v is known to about 20%.
- **Tested 15 Oct 2026: the wake/anchor shortcut does not lose the push, but it does make the fountain too tall.** With every link simulated, the moving chain still carries none of the pile's push (carried -0.13 to -0.19), so the lost push is how rigid links come off a pile in this model. The full chain drags the top of the pile and rubs the rim (0.26-0.32 m v^2). Its fountain is 8.6 / 6.3 / 5.5 cm against the exhibit's 10.6 / 10.8 / 11.2 at 30 / 60 / 90 deg. The exhibit's fountain is therefore up to 2x taller than the full simulation of the same chain. A cheaper scheme (4 live top layers, no anchor) matches the full chain at 30 deg, but costs 21 ms/frame at quarter speed against 4.4 now (full: 35 ms; budget 16.7). The default is unchanged; the README says so. The flake pile could not be run all-live: on the bare table the live 25-layer stack is dragged off as a mass.
- Experiment options added (env only; defaults unchanged, byte-identical output): CF_LIVE, CF_SETTLE, CF_NOFREEZE, CF_WAKE=layer, CF_LIVELAYERS, CF_PUSH=2; CF_LAYOUT=flake, CF_JAR=0, CF_ITER, CF_MU, CF_AHEAD, CF_STOP, CF_LINK; CF_PUSH=1 now also prints h2 = a v^2/g and the carried a. The flake is for 45 deg and more only (wider turns don't fit), a layer holds about 0.3 m, so a 40-layer pile is 26 cm tall and h1 drifts from about 150 to 125 cm in a run.
- The coil is a rigid disc, not a heap. When the disc drops a layer, the last ~10 woken links of the old layer fall 0.65 cm. The anchor is infinitely strong. The floor is a freeze at 2.5 cm (b = 0 by construction).

**References**
- S. Mould, video, 2013 (README).
- J. S. Biggins, M. Warner, "Understanding the chain fountain", Proc. R. Soc. A 470 (2014) 20130689, arXiv:1310.4056: v^2 = g h1/(1 - a - b), h2/h1 = a/(1 - a - b), rod model a = (1 - I/(m b^2/4))/2 = 1/6 for three beads per link, measured h2 = 0.14 h1, energy requires a + b <= 1/2.
