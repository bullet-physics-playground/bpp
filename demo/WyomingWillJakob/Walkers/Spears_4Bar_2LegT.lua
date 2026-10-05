-- Sept 22, 2026, by William M. Spears
-- (Hoecken-Spears slider -> Spears 4Bar-1 linkage swap ported by Claude)

-- This is a simulation of a walker driven by "Spears 4Bar-1" --
-- linkage.lua's compute_spears4bar1 (crank=36, ground=223.659 @54.459deg,
-- rocker=121.37, coupler=138.789, leg=181.45 @-102.27deg from the
-- coupler, attached 25% of the way from the coupler's B end toward A)
-- -- CONVERTED from an earlier version of this file that used the
-- Hoecken SLIDER mechanism (a crank driving a bar through a fixed
-- slider pivot, no rocker at all) instead. THIS IS A GENUINELY
-- DIFFERENT TOPOLOGY, not just different proportions of the same shape:
-- Spears 4Bar-1 is a true CLOSED four-bar loop (crank O2->A, coupler
-- A->B, rocker B->O4, ground O4->O2, exactly like the classical
-- Chebyshev/Hoecken 4-bar walkers earlier in this file series), with a
-- LEG-ARM rigidly welded (not hinged) to the coupler at a fixed point
-- and a fixed angle -- there's no free-hinged pendant anywhere in this
-- version, and consequently no crossbar either (see the LEG WELD and
-- NO CROSSBARS notes further down). Ported from Chebyshev's Plantigrade
-- Machine (shown at the 1878 Paris World Exhibition) that this file was
-- originally built around. Claude wrote most of the original Chebyshev
-- code under Bill Spears's guidance -- this was not a simple process.
-- Top-down approaches failed miserably; the machine had to be built
-- component by component, and even after it started to move it took
-- hours to tweak the parameters. I want to thank Jakob Flierl for
-- providing the very nice mesh floor, which makes this much more
-- interesting.
--
-- MODEL S4B1 (branched from Model H): four copies of the same Spears
-- 4Bar-1 linkage -- the original two on the front face, plus a mirrored
-- pair on the back face. Each leg's phase is now an independently
-- optimized value (0, 225, 180, 225 -- see the PHASE OPTIMIZED PER LEG
-- note above the linkage1-4 calls for the full derivation), not the
-- simple "front pair together, back pair 180 degrees opposite" pattern
-- every earlier version of this file used.
--
-- SPEARS 4BAR-1 CONVERSION, precisely: linkage.lua's own Spears 4Bar-1
-- entry uses genuinely different absolute lengths (and a genuinely
-- different TOPOLOGY, not just different proportions) than the previous
-- slider mechanism did --
--   crank=36  ground=223.659 @54.459deg  rocker=121.37  coupler=138.789
--   leg=181.45 @-102.27deg from the coupler's own current direction,
--   attached 25% of the way from B toward A along the coupler (not at
--   either end, and not the midpoint either).
-- RENORMALIZED here to the SAME running stride baseline this whole file
-- series has used throughout (8.323638, the original 1867 Hoecken
-- slider's own stride at crank=1): k=0.08087749, solved numerically so
-- Spears 4Bar-1's own swept foot X-span exactly matches that target
-- (verified to 6 decimal places: 8.323638 both ways, computed via
-- linkage.lua's own compute_spears4bar1 formula, sweeping a full
-- 2000-sample crank rotation). ALL FIVE lengths (crank, ground, rocker,
-- coupler, leg) are scaled by that same k -- ground_angle=54.459 and
-- leg_angle=-102.27 are NOT rescaled (they're angles, not lengths --
-- genuinely part of "which mechanism this is"), and attach_frac=0.25
-- isn't rescaled either (it's already a pure, scale-invariant fraction).
--
-- Ground link  g = 18.088979  -- O2 (crank pivot) -> O4 (rocker pivot), at g_ang=54.459deg
-- Crank        a = 2.911590   -- O2 -> A
-- Coupler      f = 11.224906  -- A -> B (called coupler_len in this file, not f_len -- see the constants section)
-- Rocker       h = 9.816101   -- O4 -> B (rocker_len)
-- Leg-arm      p = 14.675221  -- attach -> C, rigidly WELDED (not hinged) to the coupler at ATTACH_FRAC=0.25 of the way from B to A, at a fixed LEG_ANGLE_DEG=-102.27 offset from the coupler's own current direction ("p_len" keeps its old variable name purely so buildFoot's existing p_len/2 reference still resolves -- see the constants section)
--
-- Both g_len and a_len (ground, crank) are exactly as renormalized
-- above -- unlike the previous slider version, this mechanism genuinely
-- needs BOTH fixed pivots (O2 for the crank, O4 for the rocker), closed
-- by a real hinge at B, not a slider joint threaded through a floating
-- point.
--
-- LEG WELD, precisely: compute_spears4bar1's own formula rotates the
-- leg-arm by exactly LEG_ANGLE_DEG relative to the COUPLER's CURRENT
-- direction (not a fixed world direction) -- so the coupler-to-leg
-- angular relationship is a genuine invariant of the ENTIRE gait cycle,
-- true for every crank angle, not just a snapshot at construction time.
-- That means welding the leg-arm to the coupler (translation AND
-- rotation both locked, matched orientation at build time) reproduces
-- the analytic formula EXACTLY for all subsequent motion, not just
-- approximately -- see buildLinkage's own LEG WELD comment for the full
-- derivation of the weld frames that make this work.
--
-- NO CROSSBARS: linkage.lua's own MECHANISMS table marks Spears 4Bar-1
-- as twin=false (unlike Chebyshev-Spears and Hoeckens-Spears, both
-- twin=true) -- it was never a paired/crank-shared design needing a
-- crossbar in the first place, and since the leg-arm here is already
-- rigidly welded to its own coupler (no free rotational DOF at the foot
-- end at all), there's nothing left for a crossbar to stabilize even if
-- one were added. Removed entirely from this version, per request.
--
-- STARTING-HEIGHT / FLOOR: Spears 4Bar-1's own geometry reaches much
-- further down on its own than the slider mechanism's B point did (no
-- separate long pendant needed to reach the ground -- the leg-arm IS
-- the ground-reaching member here). Checked numerically (this file's
-- own buildLinkage formula, g_ang=54.459, full crank sweep): the foot
-- (C) ranges roughly Y in [-16.45, -13.35] in this file's own world
-- coordinates (g_center.y=1.25 baseline) -- floor_top_y was moved from
-- the previous version's -5.7 down to -16.7 to sit just below that new
-- low point (a margin of roughly 0.25, after accounting for the foot
-- pad's own 0.15 half-thickness below C) -- see the floor-section note
-- further down for the exact derivation. This is NOT re-derived from
-- p_len/leg length automatically (same "fixed literal, not a live
-- formula" convention the previous version used) -- if leg proportions
-- change again, floor_top_y needs to be re-checked/re-moved by hand.
--
-- Each link lives on its own Z-plane (0.4 units apart) out from the
-- cube face so the rotating parts never collide with each other or with
-- the cube -- all four (crank, coupler, rocker, leg-arm) get their own
-- plane in this version, no sharing assumed (see the z-plane comment
-- above buildScene() for why). All hinge axes are world Z, so every
-- link only ever rotates about Z -- which means each link's local
-- pivot points are simply (+-L/2, 0, z_offset) in its own frame, no
-- trig needed at hinge time.
--
-- MIRRORING: since every link only ever rotates about world Z, mounting
-- onto the back face just means flipping the sign of the whole
-- staggered Z-plane stack -- none of the in-plane (X,Y) geometry needs
-- to change. That's buildLinkage's `mirror` argument.
--
-- PHASE: with a constant-velocity motor, a "phase offset" is just a
-- different starting crank angle -- a constant angular lag/lead that a
-- constant angular velocity preserves forever. That's buildLinkage's
-- `phase` argument, added to the crank's initial angle.
--
-- LEG WELD (replaces the old CROSSBAR note): the leg-arm is rigidly
-- welded, not hinged, to the coupler at a fixed angle and a fixed point
-- partway along its length (ATTACH_FRAC) -- see buildLinkage's own LEG
-- WELD comment for the full derivation. Since there's no free-swinging
-- pendant DOF at all in this mechanism (unlike every Hoecken-family
-- version in this file series), there's also nothing for a crossbar to
-- stabilize -- Spears 4Bar-1 is twin=false in linkage.lua's own
-- MECHANISMS table, meaning it was never a paired/crank-shared design
-- to begin with. No crossbars are built in this version.
--
-- IMPORTANT: btSliderConstraint does NOT lock translation by default --
-- its stock constructor leaves the linear range free (lower=1 > upper=
-- -1, Bullet's "free" convention) and only locks rotation. A "weld"
-- needs setLowerLinLimit(0)/setUpperLinLimit(0) explicitly, or the
-- welded body can just slide off along the constraint's own axis.
--
-- Building one linkage (crank, coupler, rocker, and its welded leg-arm)
-- is wrapped in buildLinkage(...), so the back pair is just two more
-- calls with mirror=true.
--
-- FEET: buildFoot welds a wide, flat pad to the bottom of each pendant,
-- extending both inward (toward z=0, under the body) and outward (past
-- the pendant's own Z-plane, away from the body) -- widening the
-- support base in Z so a single pair (front-only or back-only) still
-- has real Z-extent to resist tipping, not just a zero-width line.
-- Inner edges stop short of z=0 by a small gap so opposing feet (front
-- vs back) don't touch at the centerline.
--
-- BODY MASS + FLOOR: the cube now has a small nonzero mass, so it's no
-- longer fixed in place -- gravity affects it, and it's held up (once
-- things settle) by whatever the legs/feet transmit to the floor.
-- None of the existing hinge/weld pivot math needed to change for this
-- -- every pivot was already stored as a LOCAL offset relative to the
-- cube's own body frame at construction time, which Bullet tracks
-- correctly regardless of how the body later moves or rotates. The
-- floor sits at the lowest point any foot reaches over a full crank
-- rotation (checked numerically), so every foot touches down at some
-- point in its own cycle, not just whichever pair happens to start low.
--
-- MASS RATIOS / WOBBLE: cube mass is now 20.0 (see the CUBE MASS
-- OPTIMIZED note above setParam("cubeMass", ...) for the real-physics-
-- trial derivation) -- previously 100.0. Leg bodies are crank 2.0,
-- coupler 4.0, rocker 3.0, leg-arm 3.0, carried over unmodified from
-- the previous (slider) version of this file, which itself raised
-- these from even smaller originals specifically to bring an iterative-
-- solver-unfriendly mass ratio down to something more tractable (see
-- that version's own history for the reasoning). With the cube now
-- lighter, the ratio against leg masses is correspondingly smaller too
-- (5:1 to 10:1, not the 25:1-50:1 it would have been at the old
-- mass=100) -- likely a further help for solver stability, though not
-- independently re-verified as such; the optimization above was scored
-- purely on net displacement, not on any wobble/jitter metric.
-- maxMotorImpulse at O2 is also carried over unmodified (150.0) -- NOT
-- independently re-verified for this new topology's own load pattern
-- (a driven crank in a closed 4-bar loop with a genuinely hinged rocker
-- is mechanically different from a crank dragging a bar through a
-- floating slider point was). Not verified against a live physics run
-- beyond the mass sweep itself -- these are the standard levers for
-- this class of problem, carried over as a reasonable starting point,
-- not a confirmed diagnosis for this specific mechanism.
--
-- ASPECT RATIO: a separate lever from mass, applied on top of the above.
-- Every rod here only ever rotates about world Z (the hinge axis) --
-- I_zz for that DRIVEN rotation is m/12*(length^2+width^2), dominated by
-- length^2 for anything longer than a few units, so cross-section barely
-- affects the torque the motor feels. But nothing about a rod's LENGTH
-- helps resist it twisting OFF that Z-plane about its own long axis --
-- I_xx = m/12*(width^2+depth^2) for THAT rotation, which is exactly the
-- "wobble"/"whipping" failure mode described throughout this file, and
-- widening pays for itself far more there than it costs in extra motor
-- load. The width bumps below (crank 0.18->0.3, coupler/rocker/leg-arm
-- 0.18->1.0-1.2) are carried over from the previous (slider) version of
-- this file, where they were checked numerically against THAT
-- mechanism's own lengths (crank=1.0, bar=10.0, pendant=14.0) -- NOT
-- re-derived for Spears 4Bar-1's own renormalized lengths (crank=2.91,
-- coupler=11.22, rocker=9.82, leg=14.68) or for the rocker itself (a
-- body type that didn't exist in the slider version at all, given the
-- same 1.0 width as the leg-arm/coupler here purely by similarity of
-- magnitude, not by calculation). Depth (rod_d) is left untouched
-- throughout -- that's the dimension that eats into plane_gap clearance
-- between stacked Z-planes, so only width (which stays within the
-- rod's own Z-plane) was grown. The previous version's own "clears the
-- O4 block by 0.6 units" clearance check no longer applies at all --
-- there's no block anymore, only a genuinely hinged rocker -- so this
-- hasn't been re-checked for the new topology's own geometry, flagged
-- rather than assumed.
--

local common = require "common"

common.setTiming(1/10, 200, 1/960)

--v:setErp(0.8)
--v:setErp2(0.0) -- Seems useful.
v:setTau(0.0)
-- ---------------------------------------------------------------------
-- shared geometry / constants
-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
-- GUI sliders. All seven apply live, no Restart needed -- Restart
-- Simulation wipes v's own param table and reruns this script from its
-- literal hardcoded defaults (checked the actual BPP source,
-- Viewer::restartSim -> parse(_scriptContent) -> Viewer::clear() ->
-- _params.clear()), so it can't preserve a dragged value either way.
-- maxSubSteps and "Speed" are applied in place via
-- v:onParamChanged (plus a redundant per-tick re-apply in the v:preSim
-- hook near the bottom, shared with the trail-marker code -- this
-- engine only allows one v:preSim and one v:onParamChanged
-- registration each, so everything for both funnels through those two
-- single callbacks). "Speed" drives all four legs' hip hinges
-- identically -- COLLAPSED from two independent sliders ("Left Speed"
-- for linkage1/linkage2, "Right Speed" for linkage3/linkage4) into one,
-- per direct request. cube_d, cubeMass,
-- terrainAmp and linkageSpacing instead tear down and rebuild the
-- whole scene (cube, terrain, all 4 legs) via teardownScene()/
-- buildScene(), also from v:onParamChanged -- see that registration,
-- right after buildScene()'s definition further down, for the full
-- picture. Since a rebuild snaps the walker back to its starting
-- position, that same handler also clears the red centroid-trail
-- markers (clearTrail(), defined next to the trail-marker code near
-- the bottom) so an old trail from before the rebuild doesn't linger
-- and misrepresent where the walker has actually been since.
-- ---------------------------------------------------------------------
local PARAM_INFO = {
  maxSubSteps = { min = 1,   max = 200, step = 1,
                  comment = "Bullet max substeps per tick (live)" },
  Speed = { min = 0,   max = 8,   step = 0.1,
                  comment = "hip hinge motor target angular speed, all four legs (live)" },
  cube_d      = { min = 1,   max = 20,  step = 0.1,
                  comment = "cube's own depth / Z (rebuilds the scene)" },
  cubeMass    = { min = 1,   max = 300, step = 1,
                  comment = "cube body mass (rebuilds the scene)" },
  terrainAmp  = { min = 0,   max = 3,   step = 0.02,
                  comment = "terrain bump height (rebuilds the scene) -- validated stable (no instability, no falls) across the full 0-2.0 range, see the AMPLITUDE-CONSISTENCY / EXTENDED-RANGE notes above setParam(\"cube_d\", ...)" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

-- CUBE MASS OPTIMIZED, found by running real 600-frame physics trials
-- (bpp -n <N>, real Bullet, not just kinematics) sweeping mass in two
-- passes: coarse (10-300, step ~10-30) then fine (5-120, step 5) around
-- the promising region, measuring net XZ displacement of the cube after
-- 600 frames from a fresh scene rebuild each time (same mechanism the
-- cubeMass GUI slider itself uses -- v:addParam triggers
-- teardownScene()+buildScene()+clearTrail(), so each mass starts from
-- an identical, momentum-free construction pose).
--
-- The result landscape is genuinely CHAOTIC, not smoothly unimodal --
-- several mass values (e.g. 40, 60, 100) gave meaningfully different
-- net-displacement numbers across otherwise-identical repeated trials
-- (same mass, different trial history/ordering), a known feature of
-- contact-rich rigid-body walking gaits: tiny floating-point differences
-- in exactly which physics substep a contact event lands on can amplify
-- over hundreds of frames of nonlinear dynamics. mass=20 stood out as a
-- genuinely ROBUST performer specifically because it did NOT show that
-- sensitivity: it reproduced to 3 decimal places (273.497, 273.497,
-- 273.493) across three independently-constructed trials (two different
-- sweep-position contexts plus one fully isolated fresh-load run) --
-- strong evidence this is a real, stable optimum rather than a lucky
-- single-trial outlier. The previous default, mass=100, by contrast
-- ranged 214.8-235.8 (a ~20-unit spread) across the same three
-- conditions -- squarely in the chaotic-sensitivity zone, not a
-- reliable number to have picked a "best" value from in the first
-- place. Full sweep highlights (net XZ displacement, 600 frames): 5->
-- 40.8, 10->22.8/49.6 (both trials agree: genuinely bad, too light to
-- carry momentum), 20->273.5 (this optimum), 30->226.4 (reproduced
-- exactly too), 40->262.8-278.1 (noisy), 80->244.95-254.45,
-- 105->273.28 (a second near-tie with the mass=20 optimum, not
-- independently re-verified for reproducibility the way mass=20 was --
-- worth a follow-up check if 105 also turns out to be a robust peak,
-- not just this run's noise). Above ~150, results trend down (200->
-- 191.0, 250->133.7, 300->162.7-163.0) -- a heavier cube consistently
-- travels less far in this mechanism, not just noisier.
--
-- RE-OPTIMIZED after the foot-size change below (see buildFoot's own
-- FOOT SIZE OPTIMIZED note) -- shrinking the feet changes ground-
-- contact dynamics enough that mass=20 is no longer the best choice.
-- Re-swept mass (10-100) at the new foot scale=0.40, across terrainAmp
-- 0/0.25/0.5/0.75/1.0 (400 frames/trial each), then refined (22-38) at
-- the same 5 amplitudes. mass=32 won on BOTH the metrics that matter
-- for "good across the whole 0-1 range": highest average net
-- displacement (133.89 across the 5-amplitude refinement sweep) AND no
-- catastrophic dip anywhere in its profile (216.94/166.93/103.02/
-- 75.75/106.80 as amp goes 0->1 -- a smooth decline that even ticks
-- back up at the top end, unlike e.g. mass=30's severe dip to 55.97 at
-- amp=0.5 despite doing fine on either side of it). A final isolated
-- head-to-head (500-frame trials, fresh construction, not mid-sweep)
-- confirmed the combined change is a real, substantial win over the
-- OLD (scale=1.0, mass=20) setup -- average net displacement +38%
-- (133.61 vs 96.76 across the 5 amplitudes) and worst-case +305%
-- (47.27 vs 11.68 at amp=1.0 specifically -- the old full-size-foot
-- setup was NEARLY STALLED on the bumpiest terrain the slider now
-- allows, where the new setup still makes real progress).
--
-- LINKAGE SPACING / CROSSBAR / MASS -- INVESTIGATED AND MOSTLY REVERTED,
-- per a direct request that a modified version "worked worse" than this
-- baseline. That modified version had changed three things at once
-- (linkageSpacing 10->12.5, cubeMass 32->10, added a crossbar welding
-- linkage2 to linkage4) -- compared head-to-head against THIS file with
-- real physics trials, isolating each change independently to find out
-- which one(s) actually caused the regression, rather than guessing:
--
--   spacing=12.5 alone (mass=32, no crossbar): net_dist 288.86 at
--   amp=0 (vs this baseline's 280.36 -- a genuine, if modest, +3%
--   improvement) -- KEPT below.
--
--   cubeMass=10 alone (spacing=10, no crossbar): 263.75 at amp=0 (-6%)
--   -- that mass value had been optimized specifically at amp=1.0, but
--   at the OLD spacing=10 -- once spacing changed to 12.5, a full joint
--   sweep (10 masses x 2 amplitudes, 400-frame trials each) showed
--   mass=32 (THIS file's own original value) beats every other mass
--   tested on BOTH average (255.06) and worst-case (221.25) -- mass=10
--   at the new spacing only reaches 189.18 average / 137.95 worst-case.
--   Optimized parameters don't compose independently -- re-optimizing
--   one at a stale baseline for the other doesn't transfer. REVERTED to
--   32 below, not because 10 was a bad number, but because it was
--   solving a problem (which mass suits amp=1.0) that had already
--   changed underneath it once spacing moved.
--
--   crossbar (linkage2<->linkage4 weld) alone: 143.08 at amp=0, barely
--   HALF this baseline's 280.36. Root cause: unlike a different walker
--   in this file series where a similar crossbar helped, THAT walker
--   had already axle-linked the pair (one shared motor, the other leg
--   fully slaved, no independent motor of its own) before the crossbar
--   was added -- the crossbar there reinforced an already-coordinated
--   pair. HERE, linkage2 and linkage4 are each still driven by their
--   OWN independent motor -- at the time this was tested, "Left Speed"/
--   "Right Speed" respectively (still front/back in that un-axle-linked
--   version), with nothing actually synchronizing them in real time
--   beyond hoping their target speeds match. (Left Speed/Right Speed
--   have since been collapsed into a single "Speed" -- see the GUI
--   sliders note above -- which removes the "hoping they match" part,
--   since all four legs now share the exact same target value by
--   construction, but each still has its OWN motor/hinge, not a rigid
--   axle -- this crossbar re-test wasn't re-run after that change, so
--   whether the verdict still holds isn't confirmed either way.)
--   Rigidly welding
--   them together fights BOTH motors continuously instead of
--   stabilizing anything -- a genuine over-constraint, not a helpful
--   stiffener. REMOVED entirely below -- not present in this file.
--   (Its effect at amp=1.0 specifically looked less clearly bad in
--   isolated testing, but not verified cleanly enough to justify
--   keeping something that costs 49% on the default flat-terrain
--   setting for an unconfirmed bumpy-terrain upside.)
--
-- AMPLITUDE-CONSISTENCY PASS, per direct request: swept terrainAmp 0.0
-- to 1.0 in 0.2 increments (6 points), varying cubeMass, cube_d and
-- foot shape jointly to look for "consistent good results" across the
-- whole range, not just a single good average. Baseline (this file's
-- own settings before this pass) was ALREADY reasonably consistent --
-- a smooth, monotonic decline from 290.37 at amp=0 down to 206.84 at
-- amp=1.0, no catastrophic dips anywhere, minY_drop staying under 1.8
-- throughout. Foot area (2.0-12.0, ratio held at 0.5) showed no clear
-- win over the current 5.48 -- 7.0 was close (avg 237.25 vs 5.48's
-- 238.68 across a 3-amplitude sample) but not decisively better, so
-- left unchanged. cube_d (2.5-8.0, coarse then refined 5.0-6.0) found
-- what LOOKED LIKE a genuine improvement at 5.5 within that 0-1.0
-- range -- SUPERSEDED below once the range was pushed further; keeping
-- this paragraph for the record of what was actually tried, not
-- because cube_d=5.5 is the final answer.
--
-- EXTENDED-RANGE CORRECTION: a separately-found configuration
-- (linkageSpacing=15, cube_d=10, cubeMass=32 -- unchanged from this
-- file's own already-good mass) was compared head-to-head against the
-- cube_d=5.5/linkageSpacing=12.5 result above, first across 0.0-1.2,
-- then pushed further to 0.0-2.0 (11 points total, 400-frame trials,
-- each point run as a fully isolated fresh-construction trial to avoid
-- sweep-history contamination -- an earlier sweep-based comparison at
-- the same points had shown some real noise, e.g. one config's amp=1.2
-- differing by ~16% between sweep-context and isolated measurement).
-- Up to amp=1.2 the two were close and traded wins depending on the
-- exact amplitude (cube_d=5.5 stronger at 0.8-1.0, cube_d=10 stronger
-- at 0.4-0.6, roughly tied at the extremes). Past amp=1.2 the picture
-- flipped hard: cube_d=5.5 degraded badly at 1.6 (90.22) and 2.0
-- (40.61) while cube_d=10/linkageSpacing=15 stayed remarkably
-- consistent the whole way out to 2.0 (140-193 throughout 1.4-2.0, no
-- comparable collapse). Full 11-point (0.0-2.0) comparison: cube_d=10
-- config average 197.67 vs cube_d=5.5's 180.56 (+9.5%), and worst-case
-- 124.84 vs 40.61 -- roughly 3x better. No instability in either
-- config anywhere in this range (minY_drop stayed under ~3.1
-- throughout for both, no falls, no freezes) -- this is a genuine
-- performance difference, not one config breaking outright. KEPT:
-- linkageSpacing=15, cube_d=10 (below), cubeMass=32 (unchanged --
-- already the best value found for this combination, re-confirmed
-- separately). The lesson here generalizes: an optimization scoped to
-- a narrower amplitude range (0-1.0, then 0-1.2) doesn't necessarily
-- hold once the range is pushed further -- cube_d=5.5's apparent edge
-- within that narrower window came at the cost of robustness further
-- out, which wasn't visible until the range was actually tested there.
--
-- TWO-LEGGED CONVERSION, per direct request: linkage2/linkage4 (the
-- "right" column, x=linkage_spacing, both phase=225) REMOVED entirely
-- -- only linkage1 (front, x=0, phase=0) and linkage3 (back, x=0,
-- phase=180) remain, both on the same single mount column. This makes
-- linkageSpacing meaningless (there's no second column to space
-- anymore) -- REMOVED as a GUI slider/param entirely, not just left at
-- some fixed value. cube_w and cube_center_x, which both used to
-- depend on linkageSpacing (spanning + centering between the two
-- columns), are recalculated below to center on the single remaining
-- column at x=0 instead -- see the buildScene() note above cube_w's
-- own definition for the exact derivation. Foot size increased
-- separately -- see buildFoot's own note.
--
-- HONEST FINDING, not fully resolved: this configuration has a real
-- stability problem the 4-legged version never showed. Direct
-- diagnosis (tracking cube.trans:getRotation() over a 400-frame run):
-- the cube's Z-axis rotation component grows CONTINUOUSLY and
-- substantially (0.029 at frame 50 to 0.515 by frame 400, roughly 62
-- degrees of accumulated rotation) rather than oscillating around a
-- stable value -- a genuine progressive tip/turn, not benign drift.
-- With only front and back legs (no left-right pair), asymmetric
-- loading between the two alternating (180-degree-offset) legs creates
-- a net torque that nothing in this layout counteracts, unlike the
-- 4-legged version where a lateral leg pair provided that resistance.
-- Net X displacement is consequently erratic -- makes real progress
-- for a couple hundred frames, then partially reverses as the whole
-- body's orientation rotates out from under it.
--
-- Tried cube.damp_ang beyond its current 1.0 -- NO effect: 1.0, 3.0,
-- 5.0, and 8.0 all gave bit-identical results, while 0.0 gave a
-- genuinely different (worse) one -- Bullet's own damping parameter is
-- clamped to [0,1] internally (it represents a fractional per-step
-- velocity retention, not an unbounded multiplier), so this file is
-- already at the engine's own damping ceiling; there's no more headroom
-- there. Foot size (below) helps meaningfully but doesn't fix the
-- underlying torque imbalance -- it's currently the best lever found,
-- not a full solution. This likely needs a genuinely different
-- structural intervention to fully resolve -- e.g. revisiting the
-- front/back phase relationship, or accepting that a front-back-only
-- two-leg layout may be inherently less stable than a left-right pair
-- would have been, given it has no lateral base of support at all.
--
-- SPEED RE-TUNED FOR TERRAIN-AMPLITUDE ROBUSTNESS, per direct request
-- and diagnosis ("I suspect a correlation between the speed of the
-- walker and the phase of the terrain"). Confirmed exactly right: an
-- 800-frame sweep across terrainAmp 0.0-2.0 at the old Speed=2.6 showed
-- several amplitudes partially or almost entirely reversing their own
-- progress after an initial good start -- worst at amp=1.2, which
-- peaked at 67.19 units of progress then gave essentially all of it
-- back (final net 1.06). This isn't random -- terrainHeight() is a
-- fixed, deterministic function of (x,z), so a given walking speed
-- always meets the SAME bump pattern at the SAME point in its own gait
-- cycle -- some (speed, amplitude) combinations land badly, some don't,
-- consistently. Tested speed directly against this same amp=1.2 case:
-- 1.5/2.0/2.6 all gave back 30-85 units; 3.2/4.0 gave back ZERO. Swept
-- Speed=3.8 across the full 0.0-2.0 range (floor-safe 250-frame
-- windows to get a clean read, then re-verified the two remaining soft
-- spots -- amp=0.0 and amp=1.8 -- out to 1600 frames on a temporarily
-- enlarged floor): 9 of 11 amplitudes show ZERO give-back in the short
-- window; the two that don't (amp=0.0, amp=1.8) show only small,
-- SELF-RECOVERING stumbles (single-digit give-back around frame 800)
-- before continuing to make real progress -- not permanent reversals.
-- amp=1.2 specifically, the original worst case, now reaches 449.71 by
-- frame 1600 instead of collapsing to 1.06. minY_drop stayed healthy
-- (under ~16) throughout every long trial -- no falls, no instability,
-- just genuinely more consistent forward progress.
--
-- maxSubSteps LOWERED (100 -> 35), per direct observation ("Trying
-- lowering maxsubsteps. It seems to help for me"). Confirmed and
-- quantified with the same long-horizon (1600-frame) tracking used for
-- the pre-rotation fix above: at maxSubSteps=100, the cube's own
-- rotation drifted a further -104 degrees beyond its -50-degree
-- starting pre-rotation, with minY_drop around 15 (matching the
-- earlier-diagnosed tilt-and-sink pattern, just starting later). Swept
-- maxSubSteps 5-100 -- lower values consistently show LESS drift and
-- a MUCH healthier height, but also less raw distance (5 and 10 barely
-- moved at all, over-damped by the coarse substepping). There's a real
-- threshold in between: 25-40 stayed in a smoothly-varying, moderate-
-- drift regime (-17 to -61 degrees, minY_drop 0.7-4.8), then jumped
-- sharply between 40 and 45 (-61 to -99 degrees, minY_drop 4.8 to 14.7)
-- back into the same bad regime 100 was already in. 35 sits clearly on
-- the safe side of that jump while still keeping strong distance
-- (-507.51 over 1600 frames, comparable to 100's own -557.83) --
-- re-verified in an isolated fresh-load run, reproduced exactly. The
-- progress pattern is also qualitatively healthier at 35: roughly
-- linear, sustained progress the WHOLE 1600 frames (102/289/422/507 at
-- the four 400-frame checkpoints) rather than a fast start followed by
-- a near-stall.
setParam("maxSubSteps", 35)
setParam("Speed", 3.8)
setParam("cube_d", 20)
setParam("cubeMass", 65.0)
setParam("terrainAmp", 0.0)

v.maxSubSteps = v:getParam("maxSubSteps")

local g_len, a_len, coupler_len, rocker_len, p_len = 18.088979, 2.911590, 11.224906, 9.816101, 14.675221   -- Spears 4Bar-1 ratio (crank:ground:rocker:coupler:leg = 36:223.659:121.37:138.789:181.45) scaled by k=0.08087749 for equal stride to the running baseline (8.323638, the original a=1,g=2,L=10 Hoecken slider's own stride) -- see the SPEARS 4BAR-1 CONVERSION header note for the full derivation. "p_len" keeps its name (not renamed to leg_len) purely so buildFoot's existing p_len/2 reference below still resolves correctly -- it's the LEG's length now, not a hanging pendant's.
local rod_w, rod_d = 0.18, 0.18          -- rod cross-section
local plane_gap = 0.8--0.4                     -- spacing between staggered planes

-- No plane-sharing in this version: crank, coupler, rocker, and the
-- leg-arm each get their own dedicated Z-plane (see the z-plane comment
-- above buildScene() for why -- the crank/rocker-share-a-plane
-- optimization used elsewhere in this file series was never verified
-- for THIS mechanism's own proportions, so it isn't assumed here).
function midpoint(p1, p2)
  return { x = (p1.x + p2.x)/2, y = (p1.y + p2.y)/2 }
end

-- one of the two points where a circle (center c1, radius r1) meets
-- a circle (center c2, radius r2) -- this is the law of cosines,
-- just algebraically pre-solved so it costs one sqrt instead of an
-- acos followed by a cos and a sin:
--   cos(theta) = (r1^2 + d^2 - r2^2) / (2*r1*d)   <- law of cosines
--   a  = r1*cos(theta)                            <- adjacent leg
--   hh = r1*sin(theta) = sqrt(r1^2 - a^2)          <- opposite leg (Pythagoras)
function circleIntersect(c1, r1, c2, r2, flip)
  local dx, dy = c2.x - c1.x, c2.y - c1.y
  local d = math.sqrt(dx*dx + dy*dy)
  local a = (r1*r1 - r2*r2 + d*d) / (2*d)
  local hh = math.sqrt(r1*r1 - a*a)
  local xm, ym = c1.x + a*dx/d, c1.y + a*dy/d
  local px, py = -dy/d, dx/d
  if flip then px, py = -px, -py end
  return { x = xm + hh*px, y = ym + hh*py }
end

-- build a Z-axis rotation quaternion directly from a direction vector
-- (half-angle formulas -- avoids atan2, which isn't in every Lua build)
function zrotVec(dx, dy)
  local len = math.sqrt(dx*dx + dy*dy)
  local cosT, sinT = dx/len, dy/len
  local cosHalf = math.sqrt((1 + cosT)/2)
  local sinHalf = math.sqrt((1 - cosT)/2)
  if sinT < 0 then sinHalf = -sinHalf end
  return btQuaternion(0, 0, sinHalf, cosHalf)
end

local IDENTITY_QUAT = btQuaternion(0, 0, 0, 1)

-- makes one rod-shaped link body from p1 to p2, sitting flat on its
-- own Z-plane, and adds it to the view.
function makeLink(p1, p2, z, mass, color, width, depth)
  width = width or rod_w
  depth = depth or rod_d
  local len = math.sqrt((p2.x-p1.x)^2 + (p2.y-p1.y)^2)
  local mid = midpoint(p1, p2)
  local q = zrotVec(p2.x - p1.x, p2.y - p1.y)
  local obj = Cube(len, width, depth, mass)
  obj.col = color
  obj.trans = btTransform(q, btVector3(mid.x, mid.y, z))
  obj.friction = 0.5
  track(obj)   -- track() is defined below, but only called once this function itself is called from inside buildScene() -- global lookup happens at call time, so definition order doesn't matter here
  return obj
end
-- ---------------------------------------------------------------------
-- ground: one wide cube shared by both linkages. Wide enough to carry
-- both g-mountings (10 units apart) plus a margin on each outer side.
-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
-- REBUILD SUPPORT for cube_d/cubeMass/terrainAmp/linkageSpacing: every
-- object and constraint buildScene() creates is tracked here so a
-- later call can tear the whole thing down cleanly (v:remove /
-- v:removeConstraint) before rebuilding it with a new slider value --
-- see the GUI sliders comment above for why Restart Simulation can't
-- do this for us.
-- ---------------------------------------------------------------------
local builtObjects, builtConstraints = {}, {}

function track(obj)
  v:add(obj)
  -- DISABLE_DEACTIVATION (Bullet's activation-state constant 4, not
  -- exposed as a named Lua constant by this engine's bindings, so used
  -- as a raw literal): without this, Bullet puts any body that's stayed
  -- below its velocity threshold for a while to ISLAND_SLEEPING, and a
  -- sleeping body ignores its own motor's torque entirely until
  -- something else collides with it and wakes it back up -- confirmed
  -- as a real failure mode in a later version of this walker (the whole
  -- mechanism would go instantly and PERMANENTLY motionless partway
  -- through a long run, hinge angle frozen bit-for-bit, not a
  -- mechanical jam). Added proactively here since this file predates
  -- that fix. mass=0 bodies (floor, trail markers) don't go through
  -- track() and don't need this -- static/kinematic bodies aren't
  -- affected by deactivation the same way.
  obj.body:setActivationState(4)
  builtObjects[#builtObjects + 1] = obj
  return obj
end

function trackConstraint(con)
  v:addConstraint(con)
  builtConstraints[#builtConstraints + 1] = con
  return con
end

function teardownScene()
  for i = 1, #builtConstraints do
    v:removeConstraint(builtConstraints[i])
  end
  builtConstraints = {}
  for i = 1, #builtObjects do
    v:remove(builtObjects[i])
  end
  builtObjects = {}
end

local floor_top_y = -16.7   -- Spears 4Bar-1's own leg reaches roughly Y in [-16.45,-13.35] on its own (no separate long pendant needed) -- see the STARTING-HEIGHT / FLOOR header note and the floor-section note above buildScene() for the full derivation

function buildScene()
local cube_d = v:getParam("cube_d")       -- cube's own depth (Z) -- GUI slider -- z_ground below derives from this, so changing cube_d keeps every linkage plane aligned with the cube's actual face automatically
local cube_margin = 2.5
-- TWO-LEGGED: only one leg column remains (x=0, linkage1/linkage3 --
-- see the TWO-LEGGED CONVERSION header note), so cube_w no longer
-- spans between two mounts -- it's now just enough width to carry the
-- single mount plus margin on each side.
cube_w = 2 * cube_margin   -- global (no "local"): the one-time camera setup further down reads this after buildScene()'s first call
-- CENTER OF MASS FIX, per direct diagnosis: cube_center_x=0 (centered
-- geometrically ON the leg mount) looked reasonable but was WRONG --
-- direct measurement (summing mass*position across cube + both legs'
-- bodies + feet) showed the COMBINED center of mass sits substantially
-- offset from the cube's own geometric center, and the offset GROWS
-- over the gait cycle (0.49 units at frame 20, growing to 1.34+ by
-- frame 180) -- exactly the "tips forward and down" symptom described.
-- Root cause: O2 (the crank pivot, where the whole leg assembly
-- anchors) sits at g_center - (g_len/2)*(cos g_ang, sin g_ang) --
-- roughly 5.26 units offset from cube_center_x on its own, before any
-- dynamic leg motion is even considered -- and the leg assembly's own
-- mass (crank+coupler+rocker+leg-arm+foot, ~13.5 per leg, 27 total
-- across both) is substantial relative to the cube (65), so that
-- anchor offset really does drag the combined CoM off-center.
-- Swept cube_center_x directly against real physics trials (400-frame,
-- forced-rebuild, tracking net displacement AND cube.trans's own Z
-- rotation as the tipping signature) -- this is NOT a small correction:
-- 0 through 5 (in the direction that seemed like it should compensate)
-- made qz WORSE, not better (up to 0.736) -- the sign was backwards
-- from the naive expectation. Reversing direction, 6 was dramatic:
-- qz collapsed to -0.285 (vs 0.602 at cube_center_x=0), cube.pos.y
-- stayed positive instead of sinking (0.81 vs -3.89), and net
-- displacement over 400 frames went from 40.78 to 265.98 -- by far the
-- single largest improvement found anywhere in this whole two-legged
-- investigation, well past what foot size or phase tuning achieved on
-- their own.
--
-- CORRECTION, from a longer test: the 1500-frame check that originally
-- validated this as "still making real progress the whole way through"
-- wasn't long enough. A proper 1600-frame monitor (direct request:
-- "I see the green body cube tilt backwards slowly as the walker goes
-- forward... monitor that") shows the tilt isn't eliminated, only
-- delayed and reduced -- cube.trans's own Z-rotation grows steadily
-- from -4.6 degrees at frame 100 to -101 degrees by frame 700-800, THEN
-- STABILIZES there (not unbounded -- same "settles into an equilibrium"
-- character the earlier diagnosis found, just at a far larger angle
-- than that first pass caught). Once settled, forward progress
-- essentially stalls (roughly 17 more units gained over the next 900
-- frames) and cube.pos.y sinks to about -14.
--
-- Re-swept BOTH cube_center_x (5.5 through 10) and foot area (35
-- through 150) over this same full 1600-frame horizon looking for a
-- value that avoids the eventual tilt entirely -- none did. Every
-- cube_center_x tested still tips 87-134 degrees by frame 1600; every
-- foot area tested (holding cube_center_x=6) still tips 129-134
-- degrees. cube_center_x=6 remains clearly the BEST of everything
-- tried -- by a wide margin, it maximizes how much real progress
-- happens before the eventual settle (roughly 500-517 units, vs 14-360
-- for every other value tested) -- but it delays and reduces the
-- problem rather than eliminating it. This now reads as a genuine
-- structural characteristic of a front-back-only two-leg layout, not a
-- tunable-parameter bug -- consistent with the earlier TWO-LEGGED
-- CONVERSION note's own speculation that this configuration may be
-- inherently less stable than a left-right leg pair would have been,
-- now with much stronger long-horizon evidence behind it. A genuinely
-- complete fix likely needs the kind of structural intervention that
-- note already flagged (revisiting the phase relationship at a deeper
-- level, or a different leg arrangement entirely) rather than further
-- parameter search within this layout.
local cube_center_x = 6   -- see CENTER OF MASS FIX + its CORRECTION above -- best found, not a full fix
-- Read early (also used by the floor section further down) so the
-- walker's starting height can already account for it -- see
-- terrain_lift below.
local terrain_amp = v:getParam("terrainAmp")  -- bump height -- GUI slider
-- STARTING-HEIGHT CLEARANCE: terrainHeight()'s three sine terms sum to
-- a max combined amplitude of 0.5+0.3+0.2=1.0, so the terrain can bulge
-- up to terrain_amp above the flat floor_top_y baseline anywhere on the
-- mesh. At terrain_amp=0 the walker was built flush with that baseline
-- (fine, since there's no bulge to clip); raising terrain_amp alone
-- left the walker's construction-time height fixed while the terrain
-- under it could now rise above that height, embedding the feet at the
-- very first frame, before gravity/contact ever got a chance to settle
-- it naturally. Lifting the whole walker by terrain_lift clears the
-- tallest possible bump anywhere on the terrain, not just wherever it
-- happens to start -- gravity still settles it onto the actual surface
-- normally from there.
local terrain_lift = terrain_amp * 1.0

-- Five distinct planes now: ground/crank/coupler/rocker/leg (no
-- crossbar plane -- Spears 4Bar-1 is twin=false, no crossbar needed at
-- all, see the SPEARS 4BAR-1 CONVERSION note). Unlike the crank/rocker
-- plane-sharing optimization used elsewhere in this file series, each
-- link here gets its OWN plane -- this is a genuinely different
-- mechanism with different proportions, and that clearance property
-- was never re-verified for it, so this is the safe default rather
-- than an assumed carry-over.
local z_ground, z_crank, z_coupler, z_rocker, z_pendant =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + 3*plane_gap, cube_d/2 + 4*plane_gap

--cube = Cube(cube_w, 1.5, cube_d, 100.0)   -- small mass -> now dynamic, affected by gravity
cube = Cube(cube_w, 1.5, cube_d, v:getParam("cubeMass"))   -- GUI slider -- small mass -> now dynamic, affected by gravity
cube.col = "#29c235"
-- PRE-ROTATION, per direct request, following up on the CENTER OF MASS
-- FIX's own CORRECTION note above: since the cube's own rotation
-- settles into an equilibrium (roughly -101 degrees from a 0-degree
-- start, over about 700 frames) rather than growing unboundedly,
-- starting the whole mechanism ALREADY at (or near) that equilibrium
-- should skip the costly drift-and-stall transient. Implemented via
-- cube.trans:invXform(worldPoint) for the hinge pivot vectors below
-- (pivotCube_O2/pivotCube_O4) -- CANNOT just rotate cube.trans's
-- rotation alone: those pivots used to be computed as plain WORLD-frame
-- displacements (worldPoint - cube.pos), which only equals the LOCAL-
-- frame offset btHingeConstraint actually expects when the cube's own
-- rotation is identity. invXform correctly converts a world point into
-- the cube's own (now rotated) local frame, verified directly against
-- a known displacement before trusting it for the real fix.
--
-- -101 degrees itself turned out to be the WRONG angle to pre-rotate
-- to: tested directly, it gave only 197.49 net displacement over 1600
-- frames -- confirming that orientation is where the walker gets stuck
-- (the drift's destination is a bad configuration, not a "found its
-- stride" one). Swept pre-rotation broadly (-150 to +150) and refined
-- around the best region -- -50 degrees won clearly (net displacement
-- -631.74 in the sweep, -557.83 re-verified in an isolated fresh-load
-- check, both comfortably beating the un-rotated baseline's ~-490 to
-- -517). Still a partial improvement, not a full fix: the isolated
-- check showed steady progress the WHOLE 1600 frames (unlike the
-- baseline's near-total stall past frame 800), but the RATE does slow
-- in the second half (roughly 120 units/400 frames early, dropping to
-- 20-30 units/400 frames later) -- better, not eliminated.
local preRotRad = math.rad(-50)
local preRotQuat = btQuaternion(0, 0, math.sin(preRotRad/2), math.cos(preRotRad/2))
cube.trans = btTransform(preRotQuat, btVector3(cube_center_x, terrain_lift, 0))   -- see terrain_lift above -- 0 when terrainAmp is 0, same starting position as before
cube.friction = 0.5
-- STRAIGHT-LINE FIX: cube.damp_ang=1.0 was found by running actual 600-frame
-- physics trials (bpp -n 600, real Bullet, not just kinematics) and sweeping
-- parameters against a heading-drift metric. Without any rotational damping,
-- the cube had nothing resisting small torque asymmetries between the two
-- leg pairs (front phase=0, back phase=180 -- never perfectly synchronized in
-- practice), which accumulated into a persistent yaw and a curving path:
-- baseline heading drifted 53 degrees over 15 simulated seconds, ending up
-- 58.5 units from start. damp_ang=1.0 cuts that to -3 degrees (measured
-- heading is pinned at +-179-180 degrees from frame 61 onward -- a genuinely
-- straight line, not just matching start/end points) and INCREASES distance
-- traveled to 73.2 units (+25%) -- no distance/straightness tradeoff needed
-- here, damping the yaw actually let more of the leg thrust go into forward
-- motion instead of an arcing path.
-- What did NOT work, tried and discarded: (1) adjusting the front/back phase
-- offset away from 180 -- tested 0/90/110/120/130/140/150/160/170/175/185/
-- 190/200/210/270, none gave a clean fix, several collapsed distance
-- entirely (the back pair needs to stay close to 180 out of phase with the
-- front pair for the gait itself to work); (2) locking ONLY yaw via
-- cube.body:setAngularFactor(btVector3(1,0,1)) (free pitch/roll, no yaw) --
-- a more surgical-sounding fix that empirically made it WORSE (-88 degrees
-- of drift), for reasons not fully understood -- worth flagging that the
-- more "obviously correct" mechanism-based fix didn't win here, plain high
-- angular damping did. Also tried: damp_lin=1.0 alone, which nearly stops
-- the walker outright (0.01 units traveled) -- linear damping fights
-- translation directly, not a fix for this.
-- damp_ang below 1.0 gave partial, inconsistent improvement (e.g. 0.99 ->
-- 16.7 degrees, 0.9 -> 34.4 degrees) -- there's a real threshold effect
-- around full damping, not a smooth tradeoff curve, so 1.0 is used rather
-- than a "gentler" partial value.
cube.damp_ang = 1.0
track(cube)

-- ---------------------------------------------------------------------
-- floor: an uneven terrain mesh (Terrain, backed by
-- btBvhTriangleMeshShape -- Bullet's BVH-accelerated static concave
-- shape) instead of a flat Cube. floor_top_y is a fixed literal (not
-- re-derived from p_len -- see the note below), sitting just under the
-- foot's own lowest natural reach; terrainHeight(x,z) adds a small
-- undulation ON TOP of that baseline, so a foot still finds
-- ~floor_top_y on average but has real bumps to step over/into instead
-- of a perfectly flat surface.
-- (Terrain was tried here before via btGImpactMeshShape -- tiles,
-- scattered patches -- but reverted: GImpact is built for shapes that
-- might move, and is markedly slower/less stable than it needs to be
-- for a shape that never does. btBvhTriangleMeshShape builds its BVH
-- tree once, at construction, and is ONLY ever valid for a static body
-- -- exactly what the floor already was, so nothing about "static,
-- never moves" had to change, just the shape type backing it.)
-- ---------------------------------------------------------------------
-- Spears 4Bar-1's own foot (C, the leg-arm's tip) ranges roughly Y in
-- [-16.45, -13.35] over a full crank rotation at this scale (g_ang=
-- 54.459, this file's own world-Y baseline g_center.y=1.25) -- checked
-- numerically (Lua sweep, no NaNs/degenerate geometry across a full
-- rotation, using both linkage.lua's abstract compute_spears4bar1 AND
-- this file's own buildLinkage formula independently, cross-checked
-- against each other), not from a live physics run. See the SPEARS
-- 4BAR-1 CONVERSION note up top for the full renormalization
-- derivation of these lengths.
--
-- floor_top_y is a fixed literal, -16.7, sitting a small margin
-- (~0.25, after the foot pad's own 0.15 half-thickness below C) under
-- the foot's own lowest computed point (-16.4521 for foot1 specifically,
-- at x_offset=0) -- NOT automatically re-derived from p_len/leg length,
-- same "fixed literal, hand-checked" convention every version of this
-- file has used. If leg proportions change again (a different
-- renormalization target, a different mechanism entirely), this needs
-- re-checking by hand, the same way it was derived here.
-- FLOOR ENLARGED, per the same "make it work for the whole walk"
-- request that motivated the speed re-tune above: at the new Speed=
-- 3.8, this walker covers roughly 300 units in just 250 frames --
-- the old 600-unit floor (a ~300-unit safe radius from cube_center_x)
-- would have the walker running off the edge within a few hundred
-- frames of normal operation, which looks identical to a genuine
-- fall in any longer test or real use. 2400x2400 (4x each dimension)
-- gives a ~1200-unit safe radius, several thousand frames of headroom
-- at this speed. terrain_nx/terrain_nz scaled 2x each (not the full
-- 4x) to keep the mesh's total cell count from growing 16x --
-- resulting cell size is coarser (10 units vs the original ~5) but
-- still fine-grained enough for the terrain's own bump wavelength.
-- floor_w/floor_d/terrain_nx/terrain_nz/floor_x0/floor_z0 (below) are
-- globals, not locals -- same "REBUILD SUPPORT" convention already used
-- for cube/floor themselves, needed so the trail code past the end of
-- buildScene() can convert a world (x,z) back to a terrain triangle
-- index using these exact same values, instead of only the code inside
-- this function being able to see them.
floor_w, floor_d = 600, 600
--local floor_w, floor_d = 2400, 2400
terrain_nx, terrain_nz = 240, 120   -- grid resolution: ~10-unit cells in both X and Z

-- Smooth, deterministic pseudo-noise: three sine waves at different
-- frequencies/phases/axes summed together. Each term alone is perfectly
-- smooth (a sine has no discontinuities), so neighboring grid points are
-- always close in height -- no cliff edge a foot could catch a corner on
-- -- while the SUM of three incommensurate frequencies isn't simply
-- periodic the way a single sine would be, so the walker's path crosses
-- real bump-to-bump variation rather than a uniform ripple.
function terrainHeight(x, z)
  return terrain_amp * (
    0.5 * math.sin(x * 0.30 + z * 0.21) +
    0.3 * math.sin(x * 0.11 - z * 0.44 + 1.7) +
    0.2 * math.sin(x * 0.53 + z * 0.07 + 4.1))
end

floor = Terrain()
floor_x0, floor_z0 = cube_center_x - floor_w/2, -floor_d/2
for i = 0, terrain_nx - 1 do
  for j = 0, terrain_nz - 1 do
    local xa, xb = floor_x0 + i*(floor_w/terrain_nx), floor_x0 + (i+1)*(floor_w/terrain_nx)
    local za, zb = floor_z0 + j*(floor_d/terrain_nz), floor_z0 + (j+1)*(floor_d/terrain_nz)
    local yaa, yab = floor_top_y + terrainHeight(xa, za), floor_top_y + terrainHeight(xa, zb)
    local yba, ybb = floor_top_y + terrainHeight(xb, za), floor_top_y + terrainHeight(xb, zb)
    floor:addTriangle(btVector3(xa, yaa, za), btVector3(xa, yab, zb), btVector3(xb, yba, za))
    floor:addTriangle(btVector3(xb, yba, za), btVector3(xa, yab, zb), btVector3(xb, ybb, zb))
  end
end
floor:build()
floor.col = "#694811"
floor.friction = 0.8
track(floor)

-- ---------------------------------------------------------------------
-- linkage builder -- one full copy of Spears 4Bar-1 (crank/coupler/
-- rocker + a rigidly-welded leg-arm) mounted at x_offset along the
-- cube's face (g_center = (x_offset, 1.25)), with its own motor. g_ang
-- tilts the ground link around its own midpoint -- passed as 54.459
-- below (Spears 4Bar-1's own ground_angle), not the 90 the previous
-- slider-mechanism version of this file used.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- SPEARS 4BAR-1 CONSTANTS: linkage.lua's compute_spears4bar1 fixes
-- these as literal numbers inside its own compute() function (unlike
-- the crank/ground/coupler/rocker lengths, which are passed through
-- this file's own g_len/a_len/coupler_len/rocker_len instead) --
-- ground_angle=54.459deg and leg_angle=-102.27deg are genuinely part of
-- "which mechanism this is", not free parameters to renormalize, so
-- they're kept as exact literals here too, matching the source.
-- attach_frac=0.25 is like both -- also fixed by the source mechanism,
-- but expressed as a pure fraction (scale-invariant), so it doesn't
-- need to be renormalized at all.
-- ---------------------------------------------------------------------
local ATTACH_FRAC = 0.25
local LEG_ANGLE_DEG = -102.27
local LEG_ANGLE_RAD = math.rad(LEG_ANGLE_DEG)

function buildLinkage(x_offset, g_ang, mirror, phase, speed)
  g_ang = g_ang or 0
  phase = phase or 0
  local zSign = mirror and -1 or 1
  local z_ground_l  = zSign * z_ground
  local z_crank_l   = zSign * z_crank
  local z_coupler_l = zSign * z_coupler
  local z_rocker_l  = zSign * z_rocker
  local z_pendant_l = zSign * z_pendant   -- "pendant" naming kept for buildFoot's benefit -- this is really the rigid leg-arm, welded (not hinged) to the coupler, see the LEG WELD note below

  local g_center = { x = x_offset, y = 1.25 + terrain_lift }   -- terrain_lift (from buildScene above) keeps every downstream point in sync with the raised cube
  local O2 = { x = g_center.x - (g_len/2)*math.cos(math.rad(g_ang)),
               y = g_center.y - (g_len/2)*math.sin(math.rad(g_ang)) }
  local O4 = { x = g_center.x + (g_len/2)*math.cos(math.rad(g_ang)),
               y = g_center.y + (g_len/2)*math.sin(math.rad(g_ang)) }

  local a_ang0 = g_ang + 90 + phase
  local A = { x = O2.x + a_len*math.cos(math.rad(a_ang0)),
              y = O2.y + a_len*math.sin(math.rad(a_ang0)) }
  -- B: coupler <-> rocker meeting point, via circle-circle intersection
  -- -- exactly linkage.lua's own compute_spears4bar1 (branch=-1, "the
  -- other Grashof-boundary path" -- the same branch sign the source
  -- uses, kept exactly, not re-derived).
  local B = circleIntersect(A, coupler_len, O4, rocker_len, -1)

  -- attach: the point ALONG the coupler, ATTACH_FRAC of the way from B
  -- toward A -- NOT at either end, and NOT the coupler's own midpoint
  -- either (that would be ATTACH_FRAC=0.5). The leg-arm welds on here.
  local attach = { x = B.x + ATTACH_FRAC*(A.x - B.x), y = B.y + ATTACH_FRAC*(A.y - B.y) }
  -- C: the leg-arm's tip, extended from attach at a FIXED angle
  -- (LEG_ANGLE_DEG) relative to the coupler's own current direction --
  -- exactly compute_spears4bar1's own P = attach + leg_len*rotate(unit(B-A), leg_angle).
  -- Note this offset is measured from the coupler's A->B direction, not
  -- O2->O4 or any other reference -- matching the source exactly.
  local ux, uy = (B.x - A.x)/coupler_len, (B.y - A.y)/coupler_len
  local ca, sa = math.cos(LEG_ANGLE_RAD), math.sin(LEG_ANGLE_RAD)
  local lx, ly = ux*ca - uy*sa, ux*sa + uy*ca
  local C = { x = attach.x + p_len*lx, y = attach.y + p_len*ly }   -- "C"/p_len kept for buildFoot's benefit -- this is the Leg tip, at leg_len from attach

  local crank   = makeLink(O2, A, z_crank_l, 2.0, "coral", 0.3, rod_d)
  local coupler = makeLink(A, B, z_coupler_l, 4.0, "teal", 1.2, rod_d)
  coupler.damp_ang = 0.15
  coupler.damp_lin = 0.1
  local rocker  = makeLink(O4, B, z_rocker_l, 3.0, "purple", 1.0, rod_d)   -- NEW body type -- this mechanism has a genuine hinged rocker (unlike the slider version's free-spinning block), closing a true 4-bar loop O2-A-B-O4
  rocker.damp_ang = 0.15
  rocker.damp_lin = 0.1
  local pendant = makeLink(attach, C, z_pendant_l, 3.0, "goldenrod", 1.0, rod_d)   -- the rigid leg-arm -- "pendant" name kept for buildFoot's benefit, but it's WELDED below, not hinged: this mechanism has zero free-swinging DOF at the foot end, unlike every Hoecken-family version in this series
  pendant.damp_ang = 0.15   -- welded rigidly to the coupler below, so this mostly just aids solver stability rather than damping a genuine free oscillation the way it did for the old hinged pendant
  pendant.damp_lin = 0.1

  local axis = btVector3(0,0,1)

  -- O2: cube (ground) <-> crank -- the motored joint
  -- pivotCube_O2 MUST go through cube.trans:invXform, not a plain world-
  -- frame subtraction, now that cube.trans carries a real rotation (the
  -- PRE-ROTATION above) -- btHingeConstraint's simplified constructor
  -- expects pivotInA in body A's own LOCAL frame; invXform correctly
  -- converts the world point O2 into that frame regardless of cube's
  -- current orientation. See the PRE-ROTATION note above cube.trans's
  -- own definition for the full derivation.
  local pivotCube_O2  = cube.trans:invXform(btVector3(O2.x, O2.y, z_ground_l))
  local pivotCrank_O2 = btVector3(-a_len/2, 0, z_ground_l - z_crank_l)
  local hingeO2 = btHingeConstraint(cube.body, crank.body, pivotCube_O2, pivotCrank_O2, axis, axis)
  -- maxMotorImpulse kept at 150.0, carried over unmodified from the
  -- Hoecken-slider version of this file -- NOT independently re-tuned
  -- for Spears 4Bar-1's own mass distribution (a true 4-bar loop with a
  -- driven rocker is a different load pattern than a crank dragging a
  -- bar through a fixed slider point was). Flagged, not verified
  -- against a live physics run -- raise this if the motor looks
  -- underpowered.
  hingeO2:enableAngularMotor(true, speed, 150.0)
  trackConstraint(hingeO2)

  -- A: crank <-> coupler (free hinge)
  local pivotCrank_A   = btVector3(a_len/2, 0, 0)
  local pivotCoupler_A = btVector3(-coupler_len/2, 0, z_crank_l - z_coupler_l)
  local hingeA = btHingeConstraint(crank.body, coupler.body, pivotCrank_A, pivotCoupler_A, axis, axis)
  trackConstraint(hingeA)

  -- O4: cube <-> rocker (free hinge, no motor -- this is the SECOND
  -- fixed pivot of the closed 4-bar loop, matching linkage.lua's own O2)
  -- Same invXform fix as pivotCube_O2 above -- see that comment.
  local pivotCube_O4  = cube.trans:invXform(btVector3(O4.x, O4.y, z_ground_l))
  local pivotRocker_O4 = btVector3(-rocker_len/2, 0, z_ground_l - z_rocker_l)
  local hingeO4 = btHingeConstraint(cube.body, rocker.body, pivotCube_O4, pivotRocker_O4, axis, axis)
  trackConstraint(hingeO4)

  -- B: coupler <-> rocker (free hinge -- this is what CLOSES the 4-bar
  -- loop; unlike the slider version, there's no slider joint at all here)
  local pivotCoupler_B = btVector3(coupler_len/2, 0, 0)
  local pivotRocker_B  = btVector3(rocker_len/2, 0, z_coupler_l - z_rocker_l)
  local hingeB = btHingeConstraint(coupler.body, rocker.body, pivotCoupler_B, pivotRocker_B, axis, axis)
  -- HARD LIMIT AT B, precisely to prevent the change-point/wrong-branch
  -- flip: this mechanism's Grashof condition is met by only a 0.19%
  -- margin (crank=2.911590, ground=18.088979, rocker=9.816101,
  -- coupler=11.224906 -- s+l=21.000569 vs p+q=21.041007), meaning the
  -- coupler-rocker joint's reachable region is nearly degenerate at one
  -- extreme of its cycle. Confirmed directly, not just analytically:
  -- an unlimited hingeB, tracked continuously (unwrapped) over an
  -- 800-frame run, sat happily within roughly 92-177 degrees for 500
  -- frames, then between frames 500-600 shot straight through 180
  -- degrees (the true dead center) and kept going to 249 degrees --
  -- the exact wrong-branch flip this note is meant to prevent, caught
  -- live, not hypothesized. Bullet's own getHingeAngle() convention for
  -- THIS specific hinge was verified empirically (matched exactly
  -- against coupler.trans/rocker.trans's own Z-rotation difference, to
  -- rule out a sign/offset mismatch before trusting these numbers) --
  -- normal operation across all four legs stays within roughly
  -- 92-178 degrees, well clear of 180 on the high side and nowhere
  -- near -180 on the low side (that end sits at h2=52.6, nowhere close
  -- to the h2=0.42 near-degeneracy on the high end -- see the SPEARS
  -- 4BAR-1 GRASHOF MARGIN header note for the full derivation).
  -- setLimit(85deg, 178deg) below gives ~2 degrees of genuine hard-stop
  -- margin before the true 180-degree danger point, while sitting
  -- comfortably outside the highest legitimate reading observed
  -- (176.9 degrees, just before the flip) so normal motion is never
  -- clipped -- the lower bound (85 degrees) is generous since that end
  -- was never at risk.
  hingeB:setLimit(math.rad(85), math.rad(178), 0.9, 0.3, 1.0)
  trackConstraint(hingeB)

  -- LEG WELD: coupler <-> leg-arm, RIGIDLY WELDED (translation AND
  -- rotation both locked) at the fixed angle LEG_ANGLE_DEG -- not a
  -- free hinge. This is kinematically EXACT, not an approximation: for
  -- ANY crank angle theta, compute_spears4bar1's own formula rotates
  -- the leg by exactly LEG_ANGLE_DEG relative to the COUPLER's current
  -- (not fixed) direction, so the coupler-to-leg angular relationship
  -- is a true invariant of the whole gait cycle, not just a snapshot at
  -- this one construction-time pose -- welding it here with matched
  -- orientation preserves that exact relationship for every future
  -- frame too. (Same principle buildCrossbar/buildFoot already use
  -- elsewhere in this file to weld two independently-built, already-
  -- correctly-posed bodies together with zero relative-rotation error.)
  --
  -- frameInCoupler's local rotation is built directly as a pure Z
  -- rotation by LEG_ANGLE_DEG (not composed from either body's own
  -- world rotation) -- correct because both coupler.body and
  -- pendant.body were built via makeLink with THEIR OWN world
  -- rotations already differing by exactly that angle (coupler's angle
  -- is atan2(B-A), the leg-arm's is atan2(C-attach) = atan2(B-A) +
  -- LEG_ANGLE_DEG, by construction above) -- so composing coupler's
  -- world rotation with this LOCAL LEG_ANGLE_DEG offset lands exactly
  -- on the leg-arm's own world rotation, giving both sides of the weld
  -- the same target orientation.
  local legRelQuat = btQuaternion(0, 0, math.sin(LEG_ANGLE_RAD/2), math.cos(LEG_ANGLE_RAD/2))
  local attachLocalX = coupler_len * (0.5 - ATTACH_FRAC)   -- attach's position along the coupler's own local +-coupler_len/2 axis (A end at -coupler_len/2, B end at +coupler_len/2)
  local frameInCoupler = btTransform(legRelQuat, btVector3(attachLocalX, 0, z_pendant_l - z_coupler_l))
  local frameInPendant = btTransform(IDENTITY_QUAT, btVector3(-p_len/2, 0, 0))   -- attach is the leg-arm's own "-X end" (matches makeLink(attach, C, ...): p1=attach at local -p_len/2)
  local weldLeg = btSliderConstraint(coupler.body, pendant.body, frameInCoupler, frameInPendant, true)
  weldLeg:setLowerLinLimit(0)   -- see the IMPORTANT note up top: slider defaults to FREE translation unless locked
  weldLeg:setUpperLinLimit(0)
  trackConstraint(weldLeg)

  return {
    crank = crank, coupler = coupler, rocker = rocker, pendant = pendant,
    hingeO2 = hingeO2, hingeA = hingeA, hingeO4 = hingeO4, hingeB = hingeB, weldLeg = weldLeg,
    z_pendant = z_pendant_l, C = C,
  }
end
-- g_ang=54.459: the ground link (O2->O4) is tilted at Spears 4Bar-1's
-- own ground_angle, not 90/vertical the way the earlier slider-
-- mechanism version of this file used, nor 0/"along the top edge" the
-- way the classical 4-bar versions used.
--
-- PHASE OPTIMIZED PER LEG, found by running real physics trials (bpp
-- -n <N>, real Bullet) with each of the four legs' phase treated as an
-- INDEPENDENT parameter (previously only two values existed: front
-- pair shared phase=0, back pair shared phase=180). Two-round
-- coordinate-descent search: sweep each leg's phase (0-315 in 45-degree
-- steps) holding the other three fixed, averaged across terrainAmp
-- {0,1.0} (400 frames/trial), update that leg to its best value, move
-- to the next leg; repeat once more from the round-1 result. Round 2
-- reproduced round 1's answer exactly (0,225,180,225) -- converged, not
-- still drifting. A final head-to-head across the FULL 5-amplitude
-- range (500 frames/trial) confirmed this beats the old (0,0,180,180)
-- baseline substantially: average net displacement +80% (257.81 vs
-- 143.13) and worst-case (the amp=0.75 trial specifically) +150%
-- (168.64 vs 67.30). Re-verified in isolation afterward (not mid-
-- sweep) to rule out sweep-ordering artifacts -- reproduced to the same
-- strong ballpark (306.64 vs the sweep's 322.64 at amp=0), with a
-- healthy, steady cube.pos.y trajectory throughout, no instability.
--
-- Only linkage1's phase (0) matches its original value -- every other
-- leg moved. There's no simple "front pair together, back pair
-- together, offset by 180" structure left in the optimum; the four
-- phases found (0, 225, 180, 225) don't reduce to any smaller pattern
-- that was checked for -- worth knowing if a future change wants to
-- exploit symmetry for a smaller search space, since this optimum
-- doesn't have any.
linkage1 = buildLinkage(0, 54.459, false, 0, v:getParam("Speed"))     -- front face, x=0
linkage3 = buildLinkage(0, 54.459, true, 180, v:getParam("Speed"))    -- back face,  x=0

-- NO CROSSBARS in this version: linkage.lua's own MECHANISMS table
-- marks Spears 4Bar-1 as twin=false, unlike Chebyshev-Spears and
-- Hoeckens-Spears (both twin=true) -- it's a self-contained, standalone
-- single-leg mechanism, with no crank-shared paired-leg design to weld
-- together. The previous (Hoecken-Spears slider) version of this file
-- built two crossbars (front pair, back pair) specifically because that
-- mechanism's own free-hinged pendant needed something to pin its
-- rotation down to; this mechanism's leg-arm is already rigidly welded
-- to its own coupler (see the LEG WELD note inside buildLinkage above),
-- so there's no free rotational DOF left to stabilize with a crossbar
-- in the first place.

-- ---------------------------------------------------------------------
-- foot builder: a wide, flat pad welded (not hinged) to the bottom of
-- a pendant, extending from the pendant's own Z-plane inward to z=0 --
-- the cube's own centerline -- so each foot reaches under the body
-- rather than just sitting out at the side where its pendant hangs.
-- Built unrotated (like the front/back crossbars), with the Z-extent
-- baked directly into the Cube's own depth dimension, so no rotation
-- bookkeeping is needed for the body itself -- only the weld frame's
-- rotation needs to match the pendant's actual orientation, using the
-- same identity-body-plus-matched-frame trick as the crossbars.
-- ---------------------------------------------------------------------
function buildFoot(lk, color)
  local C = lk.C
  local zp = lk.z_pendant
  local dir = zp >= 0 and 1 or -1
  -- FOOT SIZE OPTIMIZED, found by running real 400-500 frame physics
  -- trials (bpp -n <N>, real Bullet) sweeping foot scale (a uniform
  -- multiplier on outward_extra/inner_gap/foot_x, foot_y held fixed)
  -- across terrainAmp 0-1 (the newly-narrowed slider range). The old
  -- full-size feet (outward_extra=5.0, inner_gap=1.5, foot_x=2.0)
  -- performed well on perfectly flat ground but collapsed badly as
  -- terrain got bumpier -- net XZ displacement over 500 frames dropped
  -- from 238 at amp=0 to just 12 at amp=1.0, a near-total stall, almost
  -- certainly from the big flat pad repeatedly snagging/catching on
  -- bumps rather than sliding cleanly over them. Smaller feet trade a
  -- little flat-ground reach for dramatically better bump tolerance --
  -- but TOO small is a real failure mode, not just a smaller version of
  -- the same behavior: scale=0.20 caused the walker to fall through the
  -- world entirely (minY_drop of ~2000-2600 units, vs. ~0.2-2.0 for
  -- every working scale) -- most likely the weld/foot geometry
  -- destabilizing outright, not a gentle performance dip. scale=0.40
  -- was the strongest robust performer of everything tried (0.20 to
  -- 1.0): smoothly declining, no catastrophic dips anywhere across
  -- amp=0/0.25/0.5/0.75/1.0, unlike scale=0.30 which had a severe dip
  -- at amp=0.5 (14.85) despite doing fine on either side of it.
  --
  -- ASPECT RATIO OPTIMIZED SEPARATELY, after the size sweep above: the
  -- scale=0.40 foot's SHAPE (foot_x=0.8 vs foot_z_len=6.85, a ratio of
  -- only ~0.117 -- heavily elongated sideways, perpendicular to the
  -- walking direction) was never itself examined -- the size sweep
  -- moved area and shape together, so it couldn't tell which one was
  -- doing the work. Re-tested with footprint AREA held fixed at that
  -- same 5.48 and the X:Z ratio swept from 0.10 (near the original
  -- shape) through square (1.0) to 4.0 (elongated the OTHER way, along
  -- the stride direction), first coarse then refined (0.3-0.85) across
  -- the full 5-point amplitude range (400 frames/trial). The original
  -- ratio (0.117) turned out to be one of the WEAKER shapes tested, not
  -- the best -- ratio=0.5 (closer to square, foot_x=1.6553 vs
  -- foot_z_len=3.3106) won clearly on both metrics that matter for
  -- "good across the whole range": highest average net displacement
  -- (233.00 vs the original shape's 199.18, roughly +17%) AND by far
  -- the best worst-case (158.44 at amp=1.0, vs. every other ratio
  -- tested collapsing to ~100-160 there -- ratio=0.5 held up
  -- noticeably better than its immediate neighbors 0.4/0.6, both of
  -- which fell to ~102). Re-verified in isolation afterward at the
  -- worst-case amplitude specifically: 182.93, healthy minY_drop=1.79,
  -- consistent with the sweep's own finding, not a fluke.
  --
  -- FOOT SIZE INCREASED for the two-legged conversion, per direct
  -- request. With only 2 feet instead of 4, and both legs mounted at
  -- the SAME x=0 (front/back only, no left-right pair at all), the
  -- walker turned out to have a real, unresolved stability problem --
  -- see the TWO-LEGGED CONVERSION header note for the full story. Real
  -- physics trials (400-frame, forced-rebuild-then-measure, matching
  -- established methodology) swept foot area (18-120) and ratio
  -- (0.15-0.7) -- area=35/ratio=0.5 won clearly (net_dist=55.49 over
  -- 400 frames, vs the original 18.31/0.1497 shape's 9.88) -- bigger
  -- AND less elongated than before helps meaningfully, though it does
  -- NOT fully fix the underlying tipping problem (see that same header
  -- note). Solving for outward_extra/inner_gap to hit this new shape
  -- while preserving foot_center_z=7.9 (the same reference position
  -- every earlier foot revision in this file has used) gives a
  -- NEGATIVE outward_extra (-1.1167) -- meaning the foot's outer edge
  -- now sits slightly INWARD of the leg's own mounting Z-plane, not
  -- past it, and the leg's own attachment point (Z=13.2) actually falls
  -- OUTSIDE the foot's own [3.72, 12.08] Z-extent entirely. Flagged as
  -- an honest oddity, not hidden: geometrically valid (the weld is just
  -- an offset, Bullet doesn't care whether it's inside or outside the
  -- foot's own footprint) and this exact configuration is what was
  -- empirically tested and found best, but it's an unusual foot/leg
  -- relationship that a from-scratch redesign probably wouldn't
  -- reproduce on purpose.
  local outward_extra = -1.1167
  local inner_gap = 3.7167

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 4.1833, 0.3      -- foot_y (thickness) still deliberately unchanged -- only the X:Z footprint shape/size was re-optimized here

  local foot = Cube(foot_x, foot_y, foot_z_len, 1.5)   -- was 0.1 -- far too light against the now much-heavier cube (100) and pendant (3.0) it's rigidly welded to; a big local mass mismatch right at a weld (a 0-limit slider, very stiff) is its own source of jitter
  foot.col = color
  local pendant_quat = lk.pendant.trans:getRotation()
  -- HINGED FOOT, per direct request ("can the feet be hinged along the
  -- z axis so that they hit the ground more flushly?"). Previously
  -- welded (0-limit slider, translation AND rotation both locked) --
  -- the foot's own orientation was entirely dictated by the leg's
  -- kinematics, with no way to passively level itself against the
  -- actual ground angle at contact. The constraint below is a real
  -- btHingeConstraint (axis=world Z, matching every other rotating
  -- joint in this file) instead of a weld -- the foot is now free to
  -- rotate about that axis relative to the leg, like an ankle.
  --
  -- FIRST ATTEMPT EXPLODED, root-caused before landing on this version:
  -- starting foot.trans at pendant_quat (matching the leg's OWN current
  -- angle, seemingly the "natural" choice) launched the whole walker
  -- into the air within ~50 frames -- verified the hinge's pivot points
  -- and axis were geometrically correct (matched to the sub-millimeter
  -- via cube.trans-style invXform math, not just hand-derived formulas)
  -- and that the hinge's own angle read exactly 0 at construction, so
  -- it wasn't a pivot mismatch or a limit fighting a nonzero starting
  -- angle -- even a TIGHT +-3 degree limit with max damping made it
  -- WORSE, ruling out an energetic/dynamic explanation too. Root cause:
  -- pendant_quat can point the foot's flat side at a steep angle to the
  -- actual (locally flat) ground at construction -- gravity pulling a
  -- BOX down onto its own CORNER/EDGE instead of its face is a classic
  -- rigid-body instability, and that's exactly what a leg-aligned
  -- starting foot risks. Fix: foot.trans starts at IDENTITY (flat,
  -- matching the OLD weld's effective world orientation, not the leg's
  -- current angle) -- confirmed this alone eliminates the explosion.
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(C.x, C.y, foot_center_z))
  foot.friction = 0.8
  foot.damp_ang = 1.0   -- Bullet clamps this to [0,1] internally (same finding as the crank-damping investigation elsewhere in this file) -- 1.0 is the engine's own ceiling, not an arbitrarily large number
  foot.damp_lin = 0.1
  track(foot)

  -- pivot points only (no frame/rotation needed for a hinge, unlike the
  -- weld this replaces) -- same POSITIONS the old weld's frames used,
  -- verified to coincide in world space to 4 decimal places before
  -- trusting them.
  local pivotFoot    = btVector3(0, 0, zp - foot_center_z)
  local pivotPendant = btVector3(p_len/2, 0, 0)   -- C is the pendant's own "+X end"
  local axis = btVector3(0, 0, 1)
  local ankleHinge = btHingeConstraint(foot.body, lk.pendant.body, pivotFoot, pivotPendant, axis, axis)
  -- LIMITED, not fully free: the leg's own pendant sweeps through a
  -- wide natural angle range over a gait cycle (the two feet's own
  -- starting hinge angles, measured directly, were 84 and 66 degrees
  -- apart just from their different phases) -- so a tight limit
  -- (originally tried +-40 degrees around a wrongly-assumed "0"
  -- reference) doesn't fit this joint's real range of motion. +-90
  -- degrees, combined with max damping, is the tuned result: 1600-frame
  -- long-horizon test reached -694.82 net displacement with minY_drop
  -- staying under 1.35 THE WHOLE WAY -- clearly better than the rigid-
  -- weld version's own best (-507.51, minY_drop 1.84) on both counts.
  -- (5-argument setLimit signature, same as the hingeB change-point fix
  -- elsewhere in this file -- this binding has no default-parameter
  -- support.) SAVED AS "Model2Leg" -- further tuning paused here per
  -- direct request, to resume later.
  ankleHinge:setLimit(math.rad(-90), math.rad(90), 0.9, 0.3, 1.0)
  trackConstraint(ankleHinge)

  return foot
end
foot1 = buildFoot(linkage1, "yellow")
foot3 = buildFoot(linkage3, "blue")
end

buildScene()

-- ---------------------------------------------------------------------
-- GUI SLIDER LIVE SYNC: v:onParamChanged fires whenever a slider is
-- dragged (or setParam() is called from Lua), exactly like the GUI's
-- own drag handler updates a param. Only one v:onParamChanged may be
-- registered for the whole file (same single-callback rule as
-- v:preSim), so every param's handling lives in this one function.
--
-- maxSubSteps and "Speed" apply immediately in
-- place. cube_d, cubeMass, terrainAmp and linkageSpacing instead tear
-- down and rebuild the whole scene (cube, terrain, all 4 legs) via
-- teardownScene()/buildScene(), then clear the centroid trail since
-- the walker just snapped back to its starting position.
-- ---------------------------------------------------------------------
v:onParamChanged(function(N, name, value)
  if name == "maxSubSteps" then
    v.maxSubSteps = math.floor(value)
  elseif name == "Speed" then
    linkage1.hingeO2:enableAngularMotor(true, value, 150.0)
    linkage3.hingeO2:enableAngularMotor(true, value, 150.0)
    print(string.format("Speed = %.2f", value))
  elseif name == "cube_d" or name == "cubeMass" or name == "terrainAmp" then
    teardownScene()
    buildScene()
    clearTrail()   -- the walker just snapped back to its starting position -- an old trail from before the rebuild would misleadingly show a path it never walked from here
    print(string.format("%s = %s (scene rebuilt)", name, tostring(value)))
  end
end)

-- GUI SLIDER LIVE SYNC, redundant safety net for maxSubSteps/"Speed":
-- also re-applied every tick in the SINGLE
-- v:preSim hook further down (with the trail-marker code) -- this file
-- only supports one v:preSim registration, so a second one here would
-- silently replace it instead of running alongside it.

-- ---------------------------------------------------------------------
-- CENTROID TRAIL: colors the terrain triangle under the mechanism's
-- current (x,z) position every TRAIL_INTERVAL frames, to visualize its
-- trajectory over time (turning, drifting, straight-line travel, etc.).
--
-- Uses the CUBE's position as a practical stand-in for the true mass-
-- weighted centroid, rather than summing every body in the mechanism
-- every frame -- the cube alone is close to half the total mass, so
-- its path should closely track the true centroid's shape without
-- that bookkeeping.
--
-- REWORKED, per direct request, to color existing terrain triangles
-- instead of spawning a Cube marker per trail point: a long run drops a
-- lot of markers (every 0.5s), and each one was a genuine extra static
-- rigid body PLUS an extra draw call for the rest of the run -- the
-- count only ever grows, so a long walk visibly slowed down over time.
-- Terrain:setTriangleColor() (added to the engine for this) recolors a
-- triangle that's already part of the one floor body and already being
-- drawn every frame -- no new bodies, no growing draw-call count, no
-- matter how long the walk runs or how fine TRAIL_INTERVAL is set. This
-- also means there's nothing to v:remove() any more -- see clearTrail()
-- below.
--
-- floor_x0/floor_z0/floor_w/floor_d/terrain_nx/terrain_nz are the exact
-- same values the floor-building loop above used to place its
-- triangles -- converting a world (x,z) back to that loop's own (i,j)
-- cell indices, then to the triangle index Bullet assigns in
-- addTriangle() call order (2 triangles per cell, added in row-major
-- i,j order: cell (i,j)'s first triangle is index 2*(i*terrain_nz+j),
-- its second is that +1), recolors the exact cell the mechanism is over.
-- A position outside the floor's own extent is skipped rather than
-- clamped -- clamping would misleadingly paint the floor's edge cell for
-- a walker that's actually run off the mesh entirely, instead of just
-- not drawing anything.
-- ---------------------------------------------------------------------

local TRAIL_INTERVAL = 30   -- frames between markers (0.5s at 60fps) -- lower = finer trail, more markers over a long run
local trail_frame_count = 0

function clearTrail()
  floor:clearTriangleColors()   -- one call resets the whole floor to its base .col -- no per-marker list to walk any more
  trail_frame_count = 0
end

local function colorTrailAt(x, z)
  local i = math.floor((x - floor_x0) / (floor_w / terrain_nx))
  local j = math.floor((z - floor_z0) / (floor_d / terrain_nz))
  if i < 0 or i >= terrain_nx or j < 0 or j >= terrain_nz then
    return   -- off the floor's own extent -- nothing to color
  end
  local triIndex = 2 * (i * terrain_nz + j)
  floor:setTriangleColor(triIndex, 255, 0, 0)       -- "red", matching the old marker color
  floor:setTriangleColor(triIndex + 1, 255, 0, 0)   -- both triangles of the cell, not just one half of it
end

v:preSim(function(N)
  -- GUI SLIDER LIVE SYNC: maxSubSteps and "Speed" can be dragged while
  -- the sim is running. maxSubSteps is just re-assigned onto v each
  -- tick; Speed is re-applied to all four hip hinges via
  -- enableAngularMotor (maxMotorImpulse stays fixed at 150.0, matching
  -- each hinge's original construction-time call -- this file's much
  -- heavier bar+pendant+foot chain needs far more torque headroom than
  -- the flat 8.0 used elsewhere in this series).
  v.maxSubSteps = math.floor(v:getParam("maxSubSteps"))
  local speed = v:getParam("Speed")
  linkage1.hingeO2:enableAngularMotor(true, speed, 150.0)
  linkage3.hingeO2:enableAngularMotor(true, speed, 150.0)

  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    colorTrailAt(cube.pos.x, cube.pos.z)
  end
end)

-- ---------------------------------------------------------------------
-- camera
-- ---------------------------------------------------------------------
  local CAM_SCALE = cube_w / 15

  common.setCamera(btVector3(cube.pos.x - 120*CAM_SCALE, cube.pos.y, cube.pos.z + 120*CAM_SCALE),               btVector3(cube.pos.x, cube.pos.y, cube.pos.z), 0.15)

common.gravity(-9.8)
