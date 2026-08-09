--
-- The World's Simplest Clock -- a weight-driven, single-wheel pendulum clock
--
-- Rebuilt from G. Mahony's 2004 drawing set (worlds-simplest-clock-assy and
-- worlds-simplest-parts-1, 6-May-04, plus the full-scale layout DXF "WS-A1"
-- rev 2, 30-Nov-04). Every profile below was traced out of the DXF's own
-- arcs and lines; every diameter, thickness and hole spacing comes from the
-- parts sheets. Nothing here is eyeballed.
--
-- WHAT THE MACHINE IS: a clock with no gear train at all. A weight on a
-- string hangs off a drum on the escape-wheel arbor, so the wheel is driven
-- directly; a pendulum hung on the same frame carries the anchor, and the
-- anchor lets the wheel past one tooth per beat. Wheel, anchor, pendulum,
-- weight -- that is the whole mechanism, which is where the name comes
-- from. The escape wheel is 24 teeth cut into a scrap COMPACT DISC (the
-- CD's own 15 mm centre hole, .5906", locates it on the arbor), the anchor
-- is a nylon fork, and the pendulum rod is a strip of photographic film.
--
-- THE ESCAPEMENT, AS DRAWN -- the numbers that make it work, recovered from
-- the DXF assembly view rather than from any printed dimension:
--   * wheel: 24 teeth, tip radius 1.000", gullet radius .880", 15 deg pitch
--   * the anchor's two pallet tips sit 1.5333" and 1.4540" from its pivot,
--     and they are NOT symmetric -- the parts sheet draws them as separate
--     DETAIL J and DETAIL H, an entry and an exit pallet of different shape
--   * the pivot-to-wheel distance that makes those two unequal arms reach
--     the same working radius is 1.7966"; at that distance both tips land
--     .9783" from the wheel axis, between gullet (.880) and tip (1.000)
--   * the tips then straddle 112.56 deg of wheel, which is exactly 7.5
--     tooth pitches -- the classic half-pitch anchor span, so one tooth
--     escapes per beat and the wheel turns 15 deg per full swing
--
-- WHY THE ANCHOR PIVOT IS NOT WHERE THE PIVOT SHAFT IS: the anchor does not
-- run on its shaft, it HANGS on it. Its .375" bore carries a steel disc
-- (item 18) bored .250", and that .250" bore simply rests on top of a .125"
-- shaft (item 11), so the anchor rocks on a rolling contact .0625" above
-- the shaft centre. The DXF confirms it twice over: the plates put the
-- shaft 1.7290" below the wheel while the assembly puts the anchor's bore
-- centre 1.7966" below it (a .0676" drop, i.e. the shaft radius), and the
-- anchor's own pallet-face arcs are struck about a centre .125" ABOVE its
-- bore -- that is, about the rolling contact, exactly where a draughtsman
-- would put them.
--
-- THE HINGE HERE SITS AT THE SHAFT, NOT THE ROLLING CONTACT: the pallet
-- faces are arcs struck about the rolling contact, so hinging the anchor
-- there makes their normals pass straight through the pivot -- a tooth push
-- can then only brake the pendulum, never drive it, and the escapement
-- stalls. The real anchor rotates about the shaft centre (the bore simply
-- rocks on the shaft), so this demo puts the hinge 1.7290" below the wheel
-- at the shaft centre and leaves the .0625" rolling offset unmodelled.
--
-- HOW THE PARTS BECOME BODIES: every item in the drawing's bill of material
-- is its own OpenSCAD instance. The static frame and the parts pressed onto
-- the wheel arbor (shaft, cord drum, weight) are mass-0 riders carried
-- rigidly by the body they are screwed to (the idiom linkage.lua uses for
-- its kinematic links). The pendulum is different: lever, pivot disc, film
-- strip, clamp and bob are five independent rigid bodies, each carrying its
-- own mass and inertia tensor accumulated by massProps() from the same
-- traced polygons OpenSCAD is about to extrude and pushed on with
-- setMassProps(), welded together with btFixedConstraint -- so the escape
-- wheel's impulse travels through the lever and the welds into the film and
-- the bob, and the swing is the real five-body dynamics, not one rigid
-- body.
--
-- WHY THE CORD IS NOT A ROPE OF LINKS: an inextensible cord over a fixed
-- radius drum is EXACTLY a constant torque on the arbor, plus a weight
-- whose descent is the arbor angle times that radius. That is what runs
-- here: the torque is applied every step, the weight is positioned from the
-- wheel angle, and the weight's reflected inertia (m*r^2) is added to the
-- arbor's own. A chain of rigid links would only add stretch and jitter to
-- something the closed form already gets right.
--
-- SCALE AND BEAT: the drawing is in inches and Bullet is happier well away
-- from its .04 default collision margin, so 1 drawing inch = 10 simulation
-- units (a .015" tooth-tip fillet becomes .15 units, comfortably
-- resolvable). Gravity is 981, i.e. the model runs as though those units
-- were centimetres, which puts the beat near .75 s -- slow enough to watch
-- the teeth escape one at a time. At 24 teeth and two beats per tooth that
-- is 48 beats, about 36 s, per turn of the compact disc.
--
-- KEYBOARD SHORTCUTS:
-- * F1 - restart the pendulum from rest at its drawn offset
-- * F2 - print beats, wheel turns and the current amplitude
--
-- STATUS -- WORK IN PROGRESS. The pendulum is right: it beats a steady
-- .72-.74 s against .746 s predicted from its own accumulated inertia, at a
-- stable ~2 deg amplitude, hung on the real five-body welded assembly. What
-- does not work yet is the escapement -- the wheel only rocks +-0.17 deg,
-- and identically so across a 10x range of drive torque, which is the
-- signature of a wheel that is held rather than one that is under-driven.
--
-- The reason, found by walking the contact manifolds (v:eachContact) and
-- then confirmed geometrically: the anchor NEVER clears the teeth. Tracking
-- the two pallet tip points alone suggests it does -- they rise past the
-- 1.000" tip circle at under a degree of swing -- but the tips are not the
-- lowest part of the hook. Sweeping the whole traced outline gives its
-- closest approach to the wheel axis as
--     swing  -3    -2    -1     0    +1    +2    +3  deg
--     min r .891  .917  .942  .968  .944  .920  .895
-- i.e. inside the .880-1.000 tooth band at every angle of the swing, on both
-- sides at once. There is always anchor material in the tooth path, so no
-- tooth can ever pass, and the manifold dump duly shows the wheel bottoming
-- on the gullet floor (contacts at r = 8.800 units, exactly the root circle).
--
-- The hooks have since been trimmed for exactly that (see THE HOOK TRIM
-- below) and it worked as far as it goes: release now happens at +-0.75 deg
-- instead of +-1.5, the wheel moves +-1 to 2 deg per beat where it managed
-- +-0.17 before, and the manifold dump no longer shows it bottoming on the
-- gullet floor -- the deepest contact moved from r = 8.800 to 8.99.
--
-- What still stops it is DROP, the small free rotation a wheel needs between
-- one pallet letting go and the other catching. There is none here: the two
-- hooks span 7.5 tooth pitches exactly, so the far tooth is already touching
-- the moment the near one is released and the wheel is handed straight from
-- one pallet to the other. That the holding is continuous rather than
-- intermittent is measurable -- the impulses that do it are about .0006,
-- which is what it takes to balance the drive torque at this radius, and
-- they are present on nearly every step.
--
-- Cutting each hook back to a short locking face (see OPENING THE DROP)
-- roughly doubles what the wheel gets per beat again -- +-4.3 deg where the
-- radial trim alone gave +-2.0 -- but it still recoils rather than escaping,
-- and once the swing decays under about 2 deg the wheel locks solid again at
-- +-0.17 deg. The behaviour scales cleanly with amplitude, which says the
-- escapement is close but the pallets still give back on the return swing
-- most of what they gained. Two knobs are left untried: FACE_W (how much of
-- each hook survives as a face; 2.0 deg here) and TRIM_RELEASE (note SMALLER
-- values cut MORE, the cutting circle sitting nearer the anchor's centreline
-- -- .2 holds amplitude better than the .75 used here).
--
-- LIMITATIONS, stated plainly:
-- * the rolling anchor pivot is a plain hinge at the shaft centre, the
--   .0625" rolling offset left unmodelled (see above)
-- * the anchor is modelled coplanar with the disc rather than at its drawn
--   .187 thickness (see the z stack below for why, and for the measurements)
-- * the film strip is rigid here; in the real clock it is a flexure and
--   carries part of the pendulum's compliance
-- * the drive weight is reduced in simulation so the freewheeling catches
--   stay stable; the drawing never states what the original weighed
--

local common = require "common"

-- ---------------------------------------------------------------------
-- units
-- ---------------------------------------------------------------------

local S = 10.0                      -- simulation units per drawing inch
local function u(inches) return inches * S end

local GRAVITY = -981.0

common.setTiming(1 / 50, 16, 1 / 400)
common.gravity(GRAVITY)

-- The pendulum is a five-body welded chain (lever -> disc -> clamp -> film
-- -> bob).  A tooth impulse has to travel from the light lever through three
-- weld constraints to the bob, so Bullet's default 10 solver iterations per
-- substep are not enough to keep the chain rigid: the lever deflects and the
-- wheel freewheels.  Raise the iteration count so the welds behave like a
-- single rigid pendulum.
v:setSolverIterations(100)

-- Iterations alone only converge the solve; they do not make a joint stiff.
-- Bullet's default joint error-reduction (m_erp = .2) leaves a weld visibly
-- compliant under an impulse, and the pendulum's welds carry the whole bob.
--
-- Only m_erp may be raised. btContactSolverInfo.h is explicit that m_erp is
-- "error reduction for non-contact constraints" and m_erp2 is "error
-- reduction for CONTACT constraints" -- raising the two together (the
-- obvious-looking way to stiffen everything) instead makes the escapement's
-- penetration recovery 4.5x more aggressive, which pumps energy into the very
-- contact this demo depends on. Measured: erp2 .9 buzzes the anchor at .16 s
-- against a locked wheel; erp2 at its .2 default gives beats up to .62 s,
-- against a natural .745 s. Leave contacts alone and stiffen the welds
-- individually instead, via setParam below.
v:setErp(0.9)
v:setErp2(0.2)
v:setCfm(0.0)

-- btTypedConstraint::setParam selectors (Bullet's own enum values).
local BT_CONSTRAINT_ERP, BT_CONSTRAINT_STOP_ERP = 1, 2
local BT_CONSTRAINT_CFM, BT_CONSTRAINT_STOP_CFM = 3, 4

-- btFixedConstraint is a 6-DOF spring2 joint with every axis locked at its
-- limit, so it is the STOP_ERP/STOP_CFM pair -- not the plain ERP/CFM pair --
-- that governs how hard each locked axis is held. Set both on all six axes.
local function stiffenWeld(con)
  for axis = 0, 5 do
    con:setParam(BT_CONSTRAINT_STOP_ERP, 0.95, axis)
    con:setParam(BT_CONSTRAINT_STOP_CFM, 0.0, axis)
  end
  return con
end

-- The two hinges are ordinary constraints, so they take the plain pair.
local function stiffenHinge(con)
  for axis = 0, 5 do
    con:setParam(BT_CONSTRAINT_ERP, 0.95, axis)
    con:setParam(BT_CONSTRAINT_CFM, 0.0, axis)
  end
  return con
end

-- ---------------------------------------------------------------------
-- profiles traced out of worlds-simplest-clock-dxfs-rev2.DXF
--
-- Each profile is a start point followed by segments, in drawing inches,
-- in the part's own datum frame:
--     { x, y }                    -- straight to (x, y)
--     { cx, cy, r, a1, sweep }    -- arc about (cx, cy) of radius r, from
--                                    a1 degrees turning through sweep
-- ---------------------------------------------------------------------

-- One of the escape wheel's 24 identical teeth, datum = wheel axis.
-- Repeating it every 15 deg reproduces the DXF's 144-segment outline
-- exactly: a spike from the .880 gullet out to a .015 fillet at radius
-- 1.000, with a near-radial leading face and a raked back.
local TOOTH = {
  { 0.7398, -0.4765 },
  { 0.7902, -0.5090, 0.0600, 147.2129, 93.7871 },
  { 0.7939, -0.5797 },
  { 0.7867, -0.5928, 0.0150, 61.0000, -168.0000 },
  { 0.7052, -0.5835 },
  { 0.6876, -0.6409, 0.0600, 73.0000, 64.0121 },
  { 0.0000, 0.0000, 0.8800, 317.0121, -4.7992 },
}

-- One of the 4 kidney windows the disc keeps between its spokes, repeated
-- every 90 deg. Datum = wheel axis.
local CD_WINDOW = {
  { 0.7443, 0.0322 },
  { 0.5758, -0.0924, 0.2095, 36.4784, 63.3812 },
  { 0.5057, 0.3111, 0.2000, 279.8596, -68.2633 },
  { 0.0000, 0.0000, 0.3937, 31.5963, 38.5043 },
  { 0.2032, 0.5612, 0.2031, 250.1006, -180.0000 },
  { 0.0000, 0.0000, 0.8000, 70.1006, -66.3775 },
  { 0.7684, 0.0500, 0.0300, 3.7231, -147.2447 },
}

-- The compact disc lever (item 17) -- the anchor. Datum = its .375 bore.
-- The two hooks at the top are the pallets (tips at (-.8345, 1.2863) and
-- (.7905, 1.2203)); the long r=4.5 flanks form the tail the film clamp
-- screws to.
local LEVER = {
  { -0.2000, -1.6275 },
  { 0.0000, -1.6250, 0.2000, 180.7237, 178.5526 },
  { 4.6996, -1.6844, 4.5000, 179.2763, -17.0260 },
  { 4.6996, -1.6844, 4.5000, 162.2504, -17.9206 },
  { 0.9220, 1.0271, 0.1500, 324.3297, 80.0457 },
  { 0.0000, 0.1250, 1.4400, 44.3754, 6.7929 },
  { 0.8590, 1.1922, 0.0700, 51.1683, 70.6728 },
  { 0.7852, 1.2287 },
  { 0.7905, 1.2203, 0.0100, 121.8411, 112.3397 },
  { 0.0000, 0.1250, 1.3407, 54.1808, -5.4564 },
  { 0.8184, 1.0575, 0.1000, 48.7244, -82.1588 },
  { 0.6259, 0.5843 },
  { 0.0000, 0.9975, 0.7500, 326.5656, -113.1313 },
  { -0.9016, 1.0018 },
  { -0.8181, 1.0569, 0.1000, 213.4344, -82.1546 },
  { 0.0000, 0.1250, 1.3401, 131.2798, -2.3690 },
  { -0.8857, 1.2222, 0.0700, 308.9108, 59.4303 },
  { -0.8246, 1.2877 },
  { -0.8345, 1.2863, 0.0100, 8.3411, 117.3579 },
  { 0.0000, 0.1250, 1.4400, 125.6990, 9.9256 },
  { -0.9221, 1.0271, 0.1500, 135.6246, 80.0457 },
  { -4.6997, -1.6844, 4.5000, 35.6703, -17.9206 },
  { -4.6997, -1.6844, 4.5000, 17.7496, -17.0260 },
}

-- Baseplate (item 1), 2.397 x 2.975. Datum = its .375 anchor-pivot
-- counterbore. Drawn from the back, so it is mirrored in x on assembly.
local BASEPLATE = {
  { -0.4542, -0.5230 },
  { -0.1000, -0.4000, 0.3750, 199.1530, 141.6940 },
  { 1.0847, 1.8680 },
  { 0.8486, 1.9500, 0.2500, 340.8470, 109.1530 },
  { -1.0485, 2.2000 },
  { -1.0485, 1.9500, 0.2500, 90.0000, 109.1530 },
  { -0.4542, -0.5230 },
}

-- Front plate (item 6), 2.011 tall. Datum = its .250 arbor-bushing bore,
-- i.e. the wheel axis. Also drawn from the back.
local FRONTPLATE = {
  { -0.0346, -1.0393 },
  { -0.0669, -0.9888, 0.0600, 302.5771, 66.2280 },
  { -0.1556, -0.0241 },
  { 0.0000, 0.0000, 0.1575, 188.8051, -180.0000 },
  { 0.3470, -1.2117 },
  { 0.1000, -1.2500, 0.2500, 8.8051, -35.3976 },
  { 0.1118, -1.7850 },
  { 0.0000, -1.7290, 0.1250, 333.4075, -180.0000 },
  { -0.0362, -1.5220 },
  { -0.0898, -1.4951, 0.0600, 333.4075, 78.8401 },
  { 0.1000, -1.2500, 0.2500, 232.2475, -109.6704 },
}

-- One of the cord drum's 10 teeth (item 16, the parts sheet's "8 T-pinion"
-- -- the DXF's rev 2 draws 10 of them). Datum = its .250 bore.
local DRUM_TOOTH = {
  { -0.0972, 0.3306 },
  { -0.1115, 0.3791, 0.0506, 286.3892, 82.6483 },
  { -0.0749, 0.4709 },
  { 0.0000, 0.4828, 0.0758, 189.0374, -198.0748 },
  { 0.0615, 0.3870 },
  { 0.1115, 0.3791, 0.0506, 170.9626, 82.6483 },
  { 0.0000, 0.0000, 0.3445, 73.6108, -3.2217 },
}

-- ---------------------------------------------------------------------
-- assembly datum: the escape wheel axis is the world origin, +x right,
-- +y up, +z out of the drawing toward the viewer. Figures stay in drawing
-- inches until u() converts them.
-- ---------------------------------------------------------------------

local ANCHOR_PIVOT_Y = -1.6716      -- rolling contact the anchor rocks on
local PIVOT_SHAFT_Y  = -1.7290      -- the .125 shaft it rests on
local LEVER_DROP     = -0.1250      -- anchor bore, .125 below that contact
local STANDOFF_X     = -0.1000      -- the #6 screw / standoff spacing the plates
local STANDOFF_Y     = -1.2500

local DRUM_R         =  0.5000      -- radius the DXF shows the cord leaving at
local WEIGHT_X       =  0.0750      -- the cord hangs on the +x side
local WEIGHT_TOP_Y   = -3.0300
local WEIGHT_D       =  0.2500
local WEIGHT_L       =  0.9400

local PEND_LEN       = -5.4375      -- anchor pivot to bob centre (5 + 5/16)
local BOB_D          =  3.0000
local BOB_HUB_D      =  1.0000
local FILM_W         =  0.5000
local FILM_TOP       = -0.4480      -- both below the pivot, along the pendulum
local FILM_BOT       = -6.9350
local CLAMP_W        =  0.4000
local CLAMP_L        =  1.3000
local CLAMP_Y        = LEVER_DROP - (0.5625 + 1.6250) / 2   -- on the lever's two screw holes

-- z stack, read straight off the assembly's side view (baseplate front
-- face = 0, +z toward the viewer). The anchor's fork spans the disc's own
-- plane -- which is how the pallets reach the teeth at all.
local Z_BASE_BACK,  Z_BASE_FRONT  = -0.125, 0.000
local Z_HUB_BACK,   Z_HUB_FRONT   =  0.000, 0.118   -- escape wheel shaft flange
local Z_DISC_BACK,  Z_DISC_FRONT  =  0.118, 0.165   -- the compact disc itself
local Z_DRUM_BACK,  Z_DRUM_FRONT  =  0.165, 0.352
-- The anchor is drawn .187 thick (z .110 .. .297) with its tail stepping to
-- .088, and that is what the parts sheet shows. It is modelled COPLANAR with
-- the .047 disc instead, and that is the single change that makes the
-- escapement behave at all.
--
-- At the drawn thickness the fork is thicker than the disc and encloses it
-- completely in z, which is the case GImpact handles worst: a thin plate
-- buried inside a thicker slab has no unambiguous nearest face, so the
-- contact returns out-of-plane normals and does work on the pendulum instead
-- of merely constraining it. The test that settles it is running with the
-- drive torque switched OFF, where the only honest outcome is a slow decay:
-- enclosed, a 3 deg swing was pumped up to 21 deg, and stiffening the welds
-- made it worse (87 deg) because a stiffer chain transmits a bad impulse more
-- faithfully. Coplanar, the same test decays -- 3.0 -> 2.4 -> 2.2 -> 1.2 deg
-- -- as a real escapement must. Relieving only the region over the disc was
-- tried and is worse still (78 deg): the union leaves coincident faces along
-- the relief seam, which is the same ambiguity again.
local Z_FORK_BACK,  Z_FORK_FRONT  =  0.118, 0.165   -- = the disc's own band
local Z_TAIL_FRONT                =  0.165          -- (drawn: .110/.297/.198)
local Z_FILM_BACK,  Z_FILM_FRONT  =  0.198, 0.228
local Z_CLAMP_FRONT               =  0.328
local Z_BOB_BACK,   Z_BOB_FRONT   =  0.158, 0.268
local Z_STANDOFF_FRONT            =  0.540
local Z_FRONT_BACK, Z_FRONT_FRONT =  0.540, 0.690

-- ---------------------------------------------------------------------
-- profile -> polygon -> OpenSCAD
-- ---------------------------------------------------------------------

-- Longest facet allowed when flattening an arc. The coarse figure is fine
-- for the frame, whose parts only have to look right.
local CHORD_TOL = u(0.04)

-- The escapement gets its own, far finer tolerance, and this is the number
-- the whole mechanism turns on. The pallet tips sit at radius .9783 in a
-- tooth band running .880 to 1.000, so a pallet only ever engages a tooth
-- over .0217" -- .217 simulation units. At the coarse tolerance a single
-- facet is .40 units, nearly TWICE that: the one feature doing all the work
-- was smaller than the triangles representing it, so whether a tooth caught
-- or slipped depended on where a facet boundary happened to fall rather than
-- on the geometry. At .004" the engagement spans about 5 facets.
--
-- Note this is emphatically NOT a case for moving the pallets deeper into
-- the band. They sit high in it by design: from .9783 it is only .022" up to
-- release but .098" down to jamming against the gullet. Re-centring them
-- (pivot 1.594 instead of 1.6716) inverts that -- .07" to release against
-- .05" to jam -- so the wheel would seize before it ever unlocked. The
-- drawing is right; only its discretisation was wrong.
local FINE_TOL = u(0.004)

-- Expands a traced profile into a closed polygon in simulation units,
-- optionally rotated about the datum by `deg`, shifted in y by `dy`, and
-- flattened at `tol` (default CHORD_TOL).
local function trace(prof, deg, dy, tol)
  local c, s = 1.0, 0.0
  if deg and deg ~= 0 then
    local a = math.rad(deg)
    c, s = math.cos(a), math.sin(a)
  end
  dy = dy or 0
  tol = tol or CHORD_TOL
  local pts = {}
  local function push(x, y)
    pts[#pts + 1] = { c * x - s * y, s * x + c * y + dy }
  end
  push(u(prof[1][1]), u(prof[1][2]))
  for i = 2, #prof do
    local seg = prof[i]
    if #seg == 2 then
      push(u(seg[1]), u(seg[2]))
    else
      local cx, cy, r = u(seg[1]), u(seg[2]), u(seg[3])
      local a1, sweep = seg[4], seg[5]
      local n = math.max(2, math.ceil(r * math.abs(math.rad(sweep)) / tol))
      for k = 1, n do
        local a = math.rad(a1 + sweep * k / n)
        push(cx + r * math.cos(a), cy + r * math.sin(a))
      end
    end
  end
  return pts
end

-- The teeth are traced tooth-to-tooth: each one ends exactly where the next
-- begins, so n rotated copies concatenate into ONE closed outline. Both
-- wheels are drawn with decreasing angle, hence the negative step.
local function chain(prof, n, deg, tol)
  local pts = {}
  for i = 0, n - 1 do
    for _, p in ipairs(trace(prof, i * deg, 0, tol)) do
      pts[#pts + 1] = p
    end
  end
  return pts
end

-- The disc's four windows are separate closed loops, so they stay separate
-- polygons -- concatenating them would make one self-intersecting path.
local function copies(prof, n, deg, tol)
  local list = {}
  for i = 0, n - 1 do
    list[#list + 1] = trace(prof, i * deg, 0, tol)
  end
  return list
end

-- repeated(prof, n, deg): n copies of a profile, each turned `deg` further.
-- Open profiles -- the teeth -- are traced tooth-to-tooth, so the copies
-- concatenate into ONE closed outline. Closed profiles -- the disc's windows
-- -- come back as a list of separate loops, because concatenating those would
-- make one self-intersecting path.
local function repeated(prof, n, deg, tol)
  local one = trace(prof, 0, 0, tol)
  local dx = one[1][1] - one[#one][1]
  local dy = one[1][2] - one[#one][2]
  if dx * dx + dy * dy < 1e-6 then
    return copies(prof, n, deg, tol)
  end
  return chain(prof, n, deg, tol)
end

local function scadPoly(pts)
  local out = {}
  for i = 1, #pts do
    out[i] = string.format("[%.4f,%.4f]", pts[i][1], pts[i][2])
  end
  return "polygon(points=[" .. table.concat(out, ",") .. "]);"
end

local function scadPlate(pts, z0, z1)
  return string.format("translate([0,0,%.4f])linear_extrude(height=%.4f,convexity=12)%s",
                       u(z0), u(z1 - z0), scadPoly(pts))
end

local function scadPlates(list, z0, z1)
  local out = {}
  for i, pts in ipairs(list) do out[i] = scadPlate(pts, z0, z1) end
  return table.concat(out, "\n")
end

-- A round feature. `over` extends it past both z faces, for clean cutters.
local function scadDisc(x, y, z0, z1, d, over)
  over = over or 0
  return string.format("translate([%.4f,%.4f,%.4f])cylinder(h=%.4f,d=%.4f,$fn=64);",
                       u(x), u(y), u(z0) - over, u(z1 - z0) + 2 * over, u(d))
end

local function scadBox(x, y, z0, z1, w, h)
  return string.format("translate([%.4f,%.4f,%.4f])cube([%.4f,%.4f,%.4f]);",
                       u(x - w / 2), u(y - h / 2), u(z0), u(w), u(h), u(z1 - z0))
end

-- ---------------------------------------------------------------------
-- rigid-body mass properties
--
-- Bullet puts a body's centre of mass at its own origin and derives the
-- inertia from its collision shape, which is exactly wrong for a carrier
-- body standing in for a whole sub-assembly. So each moving assembly's
-- mass, centre and inertia are accumulated here from the same polygons
-- OpenSCAD extrudes, then pushed on with setMassProps(). Elements may
-- carry a negative density -- that is how bores and windows come out.
-- ---------------------------------------------------------------------

local RHO = 2.0e-4                  -- mass units per (unit^3 x g/cm^3)
local MAT = { wood = 0.70, nylon = 1.14, lexan = 1.20, delrin = 1.41,
              film = 1.40, steel = 7.85, brass = 8.40 }

-- Area, centroid and second moments about that centroid, for a closed
-- polygon -- the standard shoelace accumulation.
local function polyProps(pts)
  local a, cx, cy, sxx, syy = 0, 0, 0, 0, 0
  local n = #pts
  for i = 1, n do
    local x1, y1 = pts[i][1], pts[i][2]
    local j = (i % n) + 1
    local x2, y2 = pts[j][1], pts[j][2]
    local cr = x1 * y2 - x2 * y1
    a   = a + cr
    cx  = cx + (x1 + x2) * cr
    cy  = cy + (y1 + y2) * cr
    sxx = sxx + (y1 * y1 + y1 * y2 + y2 * y2) * cr
    syy = syy + (x1 * x1 + x1 * x2 + x2 * x2) * cr
  end
  a = a / 2
  if a == 0 then return 0, 0, 0, 0, 0 end
  cx, cy = cx / (6 * a), cy / (6 * a)
  sxx, syy = sxx / 12 - a * cy * cy, syy / 12 - a * cx * cx
  local sgn = (a < 0) and -1 or 1
  return sgn * a, cx, cy, sgn * sxx, sgn * syy
end

local Mass = {}
Mass.__index = Mass

local function massProps() return setmetatable({ e = {} }, Mass) end

function Mass:element(m, x, y, z, ixx, iyy, izz)
  self.e[#self.e + 1] = { m = m, x = x, y = y, z = z, ixx = ixx, iyy = iyy, izz = izz }
end

-- An extruded polygon of one material; a negative rho subtracts it again.
function Mass:plate(pts, z0, z1, rho)
  local t = u(z1 - z0)
  local a, cx, cy, sxx, syy = polyProps(pts)
  local m = rho * a * t
  self:element(m, cx, cy, u((z0 + z1) / 2),
               rho * t * sxx + m * t * t / 12,
               rho * t * syy + m * t * t / 12,
               rho * t * (sxx + syy))
end

function Mass:disc(x, y, z0, z1, d, rho)
  local t, r = u(z1 - z0), u(d) / 2
  local m = rho * math.pi * r * r * t
  local diam = 0.25 * m * r * r + m * t * t / 12
  self:element(m, u(x), u(y), u((z0 + z1) / 2), diam, diam, 0.5 * m * r * r)
end

-- Total mass, centre of mass and the (diagonal) inertia about it. The
-- clock is planar and near-symmetric about its own plane, so the products
-- of inertia Bullet cannot represent are negligible here.
function Mass:total()
  local M, cx, cy, cz = 0, 0, 0, 0
  for _, e in ipairs(self.e) do
    M = M + e.m
    cx, cy, cz = cx + e.m * e.x, cy + e.m * e.y, cz + e.m * e.z
  end
  cx, cy, cz = cx / M, cy / M, cz / M
  local ixx, iyy, izz = 0, 0, 0
  for _, e in ipairs(self.e) do
    local dx, dy, dz = e.x - cx, e.y - cy, e.z - cz
    ixx = ixx + e.ixx + e.m * (dy * dy + dz * dz)
    iyy = iyy + e.iyy + e.m * (dx * dx + dz * dz)
    izz = izz + e.izz + e.m * (dx * dx + dy * dy)
  end
  return M, cx, cy, cz, ixx, iyy, izz
end

-- Rectangles come up often enough (film strip, clamp) to be worth a shim.
local function rect(x, y, w, h)
  local hw, hh = u(w) / 2, u(h) / 2
  local cx, cy = u(x), u(y)
  return { { cx - hw, cy - hh }, { cx + hw, cy - hh },
           { cx + hw, cy + hh }, { cx - hw, cy + hh } }
end

-- ---------------------------------------------------------------------
-- the parts, one OpenSCAD instance each
-- ---------------------------------------------------------------------

local function scad(src, mass, col, transparency)
  local o = OpenSCAD(src, mass, false)
  o.col = col
  if transparency then o.transparency = transparency end
  v:add(o)
  return o
end

local CF_STATIC, CF_NO_RESPONSE = 1, 4

-- Cosmetic riders must not collide: several share a surface with the body
-- they are screwed to (the pivot disc is a press fit INSIDE the anchor's
-- own bore) and a mass-0 body is static, so any contact would be
-- infinitely stiff and would simply jam the mechanism.
local function rider(o)
  o.body:setCollisionFlags(CF_STATIC + CF_NO_RESPONSE)
  return o
end

-- item 1 -- baseplate, 2.397 x 2.975 x .125 wood, with the .375 boss that
-- carries the anchor's pivot shaft. Emitted straight into assembly
-- coordinates: mirrored in x (it is drawn from the back) and hung off the
-- standoff hole. The check that the mirror is right is that the plate's
-- own .125 hole then lands on the wheel centreline at y = -1.729, which is
-- exactly where the assembly puts the pivot shaft.
local function makeBaseplate()
  local src = string.format([[
translate([%.4f,%.4f,0])mirror([1,0,0])difference(){
union(){
%s
%s
}
%s
%s
%s
%s
%s
}
]], u(STANDOFF_X), u(STANDOFF_Y),
    scadPlate(trace(BASEPLATE), Z_BASE_BACK, Z_BASE_FRONT),
    scadDisc(0, 0, Z_BASE_FRONT, Z_BASE_FRONT + 0.110, 0.3750),
    scadDisc(0, 0, Z_BASE_BACK, Z_BASE_FRONT + 0.110, 0.1440, 1),
    scadDisc(0.1350, 0, Z_BASE_BACK, Z_BASE_FRONT, 0.0625, 1),
    scadDisc(-1.0485, 1.9500, Z_BASE_BACK, Z_BASE_FRONT, 0.1440, 1),
    scadDisc(0.8486, 1.9500, Z_BASE_BACK, Z_BASE_FRONT, 0.1440, 1),
    scadDisc(-0.1000, -0.4790, Z_BASE_BACK, Z_BASE_FRONT, 0.1250, 1))
  return scad(src, 0, "#c2703c")
end

-- item 6 -- front plate. Despite the name it is a lever-shaped strap: it
-- carries the arbor's front bushing at the top and the pivot shaft 1.729
-- below it, and nothing else.
local function makeFrontPlate()
  local src = string.format([[
mirror([1,0,0])difference(){
%s
%s
%s
%s
%s
}
]], scadPlate(trace(FRONTPLATE), Z_FRONT_BACK, Z_FRONT_FRONT),
    scadDisc(0, 0, Z_FRONT_BACK, Z_FRONT_FRONT, 0.2500, 1),
    scadDisc(0.1000, -1.2500, Z_FRONT_BACK, Z_FRONT_FRONT, 0.1440, 1),
    scadDisc(0.2350, -1.2500, Z_FRONT_BACK, Z_FRONT_FRONT, 0.0625, 1),
    scadDisc(0, -1.7290, Z_FRONT_BACK, Z_FRONT_FRONT, 0.1250, 1))
  return scad(src, 0, "#e0a0a0")
end

-- item 7 -- standoff, .450 dia x .600 long, bored .150, with the .375
-- scallop that clears the anchor. It is what sets the .940 overall width.
-- Items 5/10 (the #6 screws) and item 9 (the washer) ride with it.
local function makeStandoff()
  local src = string.format([[
difference(){
union(){
%s
%s
%s
}
%s
}
]], scadDisc(STANDOFF_X, STANDOFF_Y, Z_BASE_FRONT, Z_STANDOFF_FRONT, 0.4500),
    scadDisc(STANDOFF_X, STANDOFF_Y, Z_BASE_BACK - 0.06, Z_FRONT_FRONT + 0.06, 0.1380),
    scadDisc(STANDOFF_X, STANDOFF_Y, Z_FRONT_FRONT, Z_FRONT_FRONT + 0.06, 0.2620),
    -- The scallop has to be centred on wherever the anchor actually passes,
    -- and cut deeper than the standoff is wide, or the anchor fouls it. The
    -- contact-manifold dump caught exactly that: with the scallop on the
    -- standoff's own mid-height the anchor was striking its lower edge at
    -- (-1.38, -14.74) with an applied impulse of 23.3, a static-body contact
    -- stiff enough to cage the pendulum and ring it at .15 s instead of
    -- letting it beat. Following the anchor's z band keeps it clear.
    string.format("translate([%.4f,%.4f,%.4f])rotate([0,90,0])cylinder(h=%.4f,d=%.4f,$fn=48,center=true);",
      u(STANDOFF_X), u(STANDOFF_Y), u((Z_FORK_BACK + Z_FORK_FRONT) / 2),
      u(0.6000), u(0.5000)))
  return scad(src, 0, "#b98a5a")
end

-- item 11 -- the anchor's pivot shaft, and items 2/8 -- the two plastic
-- bushings and the .0625 dowel that is the escape wheel's arbor.
local function makeShaftsAndBushings()
  local src = table.concat({
    scadDisc(0, PIVOT_SHAFT_Y, Z_BASE_FRONT, Z_FRONT_BACK, 0.1250),
    scadDisc(0, 0, Z_BASE_FRONT, Z_BASE_FRONT + 0.125, 0.2500),
    scadDisc(0, 0, Z_FRONT_BACK - 0.125, Z_FRONT_BACK, 0.2500),
    scadDisc(0, 0, Z_BASE_BACK, Z_FRONT_FRONT, 0.0625),
  }, "\n")
  return scad(src, 0, "#9aa0a6")
end

-- item 12 -- the driving weight, .250 x .940, drawn about its own centre
-- so it can simply be repositioned as the cord pays out.
local function makeWeight()
  local src = string.format("rotate([90,0,0])cylinder(h=%.4f,d=%.4f,$fn=48,center=true);",
                            u(WEIGHT_L), u(WEIGHT_D))
  return scad(src, 0, "#8fd4d4")
end

-- The cord itself. It is .015" of string in the drawing -- drawn here as
-- one static thread from the drum down past the weight's whole travel,
-- with the weight sliding down it, rather than as a rope of rigid links.
local function makeCord(drop)
  local top, bot = -DRUM_R, WEIGHT_TOP_Y - WEIGHT_L - drop
  local src = string.format(
    "translate([%.4f,%.4f,%.4f])rotate([90,0,0])cylinder(h=%.4f,d=%.4f,$fn=12,center=true);",
    u(WEIGHT_X), u((top + bot) / 2), u((Z_DRUM_BACK + Z_DRUM_FRONT) / 2),
    u(top - bot), u(0.0150))
  return scad(src, 0, "#efe6c8")
end

-- item 13 -- the escape wheel: 24 teeth cut into a compact disc, .047
-- thick, still carrying the CD's .5906 centre hole and the four windows
-- between its spokes. Clear polycarbonate, hence the transparency.
local function escapeWheelSrc(dz)
  return string.format([[
translate([0,0,%.4f])difference(){
%s
%s
%s
}
]], dz,
    scadPlate(repeated(TOOTH, 24, -15.0, FINE_TOL), Z_DISC_BACK, Z_DISC_FRONT),
    scadDisc(0, 0, Z_DISC_BACK, Z_DISC_FRONT, 0.5906, 1),
    scadPlates(repeated(CD_WINDOW, 4, 90.0), Z_DISC_BACK - 0.02, Z_DISC_FRONT + 0.02))
end

-- item 14 -- escape wheel shaft: a .787 flange, a .591 spigot the CD's own
-- hole drops onto, and a .250 body for the cord drum.
local function makeWheelShaft()
  local src = string.format([[
difference(){
union(){
%s
%s
%s
}
%s
}
]], scadDisc(0, 0, Z_HUB_BACK, Z_HUB_FRONT, 0.7870),
    scadDisc(0, 0, Z_DISC_BACK, Z_DISC_FRONT, 0.5906),
    scadDisc(0, 0, Z_DISC_FRONT, Z_DRUM_FRONT, 0.2500),
    scadDisc(0, 0, Z_HUB_BACK, Z_DRUM_FRONT, 0.0630, 1))
  return scad(src, 0, "#c9a06a")
end

-- item 16 -- the toothed drum the cord winds on, .187 thick, 10 teeth.
local function makeCordDrum()
  local src = string.format([[
difference(){
%s
%s
}
]], scadPlate(repeated(DRUM_TOOTH, 10, -36.0), Z_DRUM_BACK, Z_DRUM_FRONT),
    scadDisc(0, 0, Z_DRUM_BACK, Z_DRUM_FRONT, 0.2500, 1))
  return scad(src, 0, "#7fb2e0")
end

-- item 17 -- the compact disc lever: the anchor. Emitted about the ROLLING
-- CONTACT it rocks on, .125 above its own bore, so the whole pendulum
-- assembly shares one datum. The fork keeps the full .187 thickness and
-- the tail steps down to .088, per the parts sheet's side view.
-- THE HOOK TRIM -- the one edit here that departs from the traced profile.
--
-- As drawn, neither hook ever gets far enough out of the tooth band. Swept
-- hook by hook, the closest either comes to the wheel axis is
--     swing   -3    -2  -1.5    -1     0    +1  +1.5    +2    +3  deg
--     left   .891  .917 .930  .942  .968  .994 1.007 1.020 1.045
--     right 1.042 1.017 1.005  .993  .968  .944 .932  .920  .895
-- so a pallet only clears the 1.000 tip circle past +-1.5 deg, while the
-- pendulum settles at about 2 deg: half a degree of margin, with a +-1.5 deg
-- dead band in the middle where both hooks are in the teeth at once.
--
-- Each hook is therefore cut back with the tooth-tip circle itself, taken
-- where that circle sits relative to the anchor at the swing the pallet is
-- meant to release at. Cutting the LEFT hook with the circle as seen at
-- +TRIM_RELEASE guarantees it is clear there, by construction, and leaves it
-- untouched at negative swing where it still has to lock. The right hook
-- gets the mirror. Verified after trimming:
--     swing  -2    -1  -0.75     0  +0.75    +1    +2  deg
--     left  .934  .960  .966  .986  1.005 1.011 1.036
--     right 1.035 1.011 1.005  .986  .967  .961  .936
-- release at +-0.75 instead of +-1.5, the dead band halved, and the engaged
-- hook still locks .056 deep at 2 deg -- well clear of bottoming on the .880
-- gullet floor, which is what the manifold dump had caught it doing.
local TRIM_RELEASE = 0.75              -- swing (deg) at which a pallet must be clear
local TRIM_CLEAR   = 0.005             -- radial clearance past the tooth tips
local TRIM_R       = 1.0000 + TRIM_CLEAR

-- Catching edges of the two hooks, measured about the wheel axis at neutral,
-- and how much of each to keep as a locking face. Everything above the face,
-- inside the tooth band, is cut away so a released tooth has clear air until
-- the next face comes round.
local LEFT_FACE  = 210.86
local RIGHT_FACE = 323.32
local FACE_W     = 2.0

-- Where the wheel axis sits in the anchor's own frame at a given swing --
-- the anchor turns about the shaft, so from the anchor the axis swings the
-- other way about it.
local function wheelAxisInAnchor(deg)
  local t = math.rad(deg)
  local arm = -PIVOT_SHAFT_Y                        -- shaft to wheel axis
  local shaftInDatum = PIVOT_SHAFT_Y - ANCHOR_PIVOT_Y
  return arm * math.sin(t), shaftInDatum + arm * math.cos(t)
end

local function anchorSrc(dx, dy, dz)
  local waist = LEVER_DROP - 0.3125      -- where the drawing steps the thickness
  local lx, ly = wheelAxisInAnchor(TRIM_RELEASE)
  local rx, ry = wheelAxisInAnchor(-TRIM_RELEASE)
  local wnx, wny = wheelAxisInAnchor(0)
  local zb, zf = Z_FORK_BACK - 0.05, Z_FORK_FRONT + 0.05

  -- each cut is confined to its own side, or trimming one hook would trim
  -- the other -- and the other one has to stay down in the teeth to lock
  local trimLeft = string.format("intersection(){%s %s}",
    scadDisc(lx, ly, zb, zf, 2 * TRIM_R, 0), scadBox(-20, 0, zb, zf, 40, 80))
  local trimRight = string.format("intersection(){%s %s}",
    scadDisc(rx, ry, zb, zf, 2 * TRIM_R, 0), scadBox(20, 0, zb, zf, 40, 80))

  -- OPENING THE DROP. The radial cut above leaves each hook as a 5.4 deg arc
  -- struck about the wheel axis -- concentric with the tooth tips, i.e. a
  -- deadbeat face. Concentric faces give no drop at all: the far arc is
  -- already at the same depth on the other side of the wheel the instant the
  -- near one lifts, so the wheel is handed straight from pallet to pallet.
  -- Measured about the wheel axis at neutral, the hooks occupy
  --     left  210.86 .. 216.23 deg   (deepest .9682 at 211.48)
  --     right 323.32 .. 328.33 deg   (deepest .9683 at 323.90)
  -- a span of 112.46 deg between the catching edges = 7.497 tooth pitches,
  -- which SHOULD give a tooth 7.46 deg of free run. It does not, because
  -- each arc is long enough to meet the next tooth along well before that.
  -- So each hook is cut back to a short locking face at its catching edge --
  -- the low-angle one, since the wheel runs anticlockwise and every tooth
  -- therefore arrives from below -- and everything above that face, inside
  -- the tooth band, is taken away.
  local function sector(a0, a1, r0, r1)
    local pts, n = {}, 48
    for k = 0, n do
      local a = math.rad(a0 + (a1 - a0) * k / n)
      pts[#pts + 1] = { u(wnx + r1 * math.cos(a)), u(wny + r1 * math.sin(a)) }
    end
    for k = n, 0, -1 do
      local a = math.rad(a0 + (a1 - a0) * k / n)
      pts[#pts + 1] = { u(wnx + r0 * math.cos(a)), u(wny + r0 * math.sin(a)) }
    end
    return scadPlate(pts, zb, zf)
  end

  local backLeft  = sector(LEFT_FACE + FACE_W, LEFT_FACE + 12.0, 0.84, 1.06)
  local backRight = sector(RIGHT_FACE + FACE_W, RIGHT_FACE + 12.0, 0.84, 1.06)

  return string.format([[
translate([%.4f,%.4f,%.4f])difference(){
intersection(){
%s
union(){
%s
%s
}
}
%s
%s
%s
%s
%s
%s
%s
}
]], dx, dy, dz,
    scadPlate(trace(LEVER, 0, u(LEVER_DROP), FINE_TOL), Z_FORK_BACK, Z_FORK_FRONT),
    scadBox(0, waist + 1.5, Z_FORK_BACK, Z_FORK_FRONT, 2.8, 3.0),
    scadBox(0, waist - 1.1, Z_FORK_BACK, Z_TAIL_FRONT, 2.8, 2.2),
    scadDisc(0, LEVER_DROP, Z_FORK_BACK, Z_FORK_FRONT, 0.3750, 1),
    scadDisc(0, LEVER_DROP - 0.5625, Z_FORK_BACK, Z_FORK_FRONT, 0.1285, 1),
    scadDisc(0, LEVER_DROP - 1.6250, Z_FORK_BACK, Z_FORK_FRONT, 0.1285, 1),
    trimLeft, trimRight, backLeft, backRight)
end

-- item 18 -- the steel pivot disc pressed into the anchor's .375 bore,
-- whose .250 bore is what actually rests on the pivot shaft.
local function makePivotDisc()
  return string.format([[
difference(){
%s
%s
}
]], scadDisc(0, LEVER_DROP, Z_FORK_BACK, Z_FORK_FRONT, 0.3750),
    scadDisc(0, LEVER_DROP, Z_FORK_BACK, Z_FORK_FRONT, 0.2500, 1))
end

-- item 19 -- the pendulum rod: a .500 wide strip of photographic film.
local function makeFilmStrip()
  return scadBox(0, (FILM_TOP + FILM_BOT) / 2, Z_FILM_BACK, Z_FILM_FRONT,
                 FILM_W, FILM_TOP - FILM_BOT)
end

-- item 20 -- the bob: a 3" disc with a 1" hub, hung on the film strip.
local function makePendulumBob()
  return table.concat({
    scadDisc(0, PEND_LEN, Z_BOB_BACK, Z_BOB_FRONT, BOB_D),
    scadDisc(0, PEND_LEN, Z_BOB_BACK - 0.085, Z_BOB_FRONT + 0.085, BOB_HUB_D),
  }, "\n")
end

-- item 21 -- Delrin film clamp, screwed to the lever's tail by the two
-- #4-40 flat heads (item 22), trapping the film strip against it.
local function makeFilmClamp()
  return table.concat({
    scadBox(0, CLAMP_Y, Z_FILM_FRONT, Z_CLAMP_FRONT, CLAMP_W, CLAMP_L),
    scadDisc(0, CLAMP_Y - CLAMP_L / 2, Z_FILM_FRONT, Z_CLAMP_FRONT, CLAMP_W),
  }, "\n")
end

-- ---------------------------------------------------------------------
-- the frame
-- ---------------------------------------------------------------------

local baseplate = makeBaseplate()
makeFrontPlate()
makeStandoff()
makeShaftsAndBushings()

-- ---------------------------------------------------------------------
-- the escape wheel assembly: disc + shaft + cord drum on one arbor
-- ---------------------------------------------------------------------

local WEIGHT_M = MAT.brass * RHO * math.pi * (u(WEIGHT_D) / 2) ^ 2 * u(WEIGHT_L)
-- The drawn weight is ~200x too strong for the sim: between beats the wheel
-- is unengaged and freewheels, so a real-weight torque slams the pallet hard
-- enough to slip teeth.  Scale it down so the catch is gentle and the wheel
-- holds and recoils one tooth per beat instead of escaping several.
local TORQUE_SCALE = 0.0053
local DRIVE_TORQUE = TORQUE_SCALE * WEIGHT_M * (-GRAVITY) * u(DRUM_R)

local wheelM, wheelCX, wheelCY, wheelCZ, wheelIxx, wheelIyy, wheelIzz
do
  local mp = massProps()
  mp:plate(repeated(TOOTH, 24, -15.0, FINE_TOL), Z_DISC_BACK, Z_DISC_FRONT, MAT.lexan * RHO)
  for _, win in ipairs(repeated(CD_WINDOW, 4, 90.0)) do
    mp:plate(win, Z_DISC_BACK, Z_DISC_FRONT, -MAT.lexan * RHO)
  end
  mp:disc(0, 0, Z_DISC_BACK, Z_DISC_FRONT, 0.5906, -MAT.lexan * RHO)
  mp:disc(0, 0, Z_HUB_BACK, Z_HUB_FRONT, 0.7870, MAT.wood * RHO)
  mp:disc(0, 0, Z_DISC_FRONT, Z_DRUM_FRONT, 0.2500, MAT.wood * RHO)
  mp:plate(repeated(DRUM_TOOTH, 10, -36.0), Z_DRUM_BACK, Z_DRUM_FRONT, MAT.nylon * RHO)
  wheelM, wheelCX, wheelCY, wheelCZ, wheelIxx, wheelIyy, wheelIzz = mp:total()
  -- the descending weight is geared to this arbor by the cord, so it shows
  -- up here as m*r^2 of extra rotational inertia
  wheelIzz = wheelIzz + WEIGHT_M * u(DRUM_R) ^ 2
end

local wheel = scad(escapeWheelSrc(-wheelCZ), 1, "#a9c4d8", 0.35)
wheel.body:setMassProps(wheelM, btVector3(wheelIxx, wheelIyy, wheelIzz))
wheel.body:updateInertiaTensor()
wheel.body:forceActivationState(4)          -- DISABLE_DEACTIVATION: a clock never sleeps
wheel.pos = btVector3(0, 0, wheelCZ)
wheel.friction = 0.30
wheel.restitution = 0.0

local wheelShaft = rider(makeWheelShaft())
local cordDrum   = rider(makeCordDrum())
local weight     = rider(makeWeight())
makeCord(3.5)

v:addConstraint(stiffenHinge(btHingeConstraint(
  baseplate.body, wheel.body,
  btVector3(0, 0, 0), btVector3(0, 0, -wheelCZ),
  btVector3(0, 0, 1), btVector3(0, 0, 1))))

-- ---------------------------------------------------------------------
-- the anchor + pendulum assembly
-- ---------------------------------------------------------------------

-- Each member of the pendulum assembly becomes its own rigid body, welded
-- to its neighbours. massProps' datum is the assembly, so each part's own
-- total comes straight out; the combined totals (for the printed pendulum
-- statistics and the beat period) are the five parts summed by the parallel
-- axis theorem.
local function partProps(fn)
  local mp = massProps()
  fn(mp)
  local m, cx, cy, cz, ixx, iyy, izz = mp:total()
  return { m = m, cx = cx, cy = cy, cz = cz, ixx = ixx, iyy = iyy, izz = izz }
end

local leverP = partProps(function(mp)
  mp:plate(trace(LEVER, 0, u(LEVER_DROP), FINE_TOL), Z_FORK_BACK, Z_FORK_FRONT, MAT.nylon * RHO)
  mp:disc(0, LEVER_DROP, Z_FORK_BACK, Z_FORK_FRONT, 0.3750, -MAT.nylon * RHO)
end)
local discP = partProps(function(mp)
  mp:disc(0, LEVER_DROP, Z_FORK_BACK, Z_FORK_FRONT, 0.3750, MAT.steel * RHO)
  mp:disc(0, LEVER_DROP, Z_FORK_BACK, Z_FORK_FRONT, 0.2500, -MAT.steel * RHO)
end)
local filmP = partProps(function(mp)
  mp:plate(rect(0, (FILM_TOP + FILM_BOT) / 2, FILM_W, FILM_TOP - FILM_BOT),
           Z_FILM_BACK, Z_FILM_FRONT, MAT.film * RHO)
end)
local clampP = partProps(function(mp)
  mp:plate(rect(0, CLAMP_Y, CLAMP_W, CLAMP_L), Z_FILM_FRONT, Z_CLAMP_FRONT, MAT.delrin * RHO)
end)
local bobP = partProps(function(mp)
  mp:disc(0, PEND_LEN, Z_BOB_BACK, Z_BOB_FRONT, BOB_D, MAT.brass * RHO)
  mp:disc(0, PEND_LEN, Z_BOB_BACK - 0.085, Z_BOB_FRONT + 0.085, BOB_HUB_D, MAT.brass * RHO)
end)

local function combine(a, b)
  local m = a.m + b.m
  local cx, cy, cz = (a.m * a.cx + b.m * b.cx) / m,
                     (a.m * a.cy + b.m * b.cy) / m,
                     (a.m * a.cz + b.m * b.cz) / m
  local dax, day, daz = a.cx - cx, a.cy - cy, a.cz - cz
  local dbx, dby, dbz = b.cx - cx, b.cy - cy, b.cz - cz
  return {
    m = m, cx = cx, cy = cy, cz = cz,
    ixx = a.ixx + b.ixx + a.m * (day * day + daz * daz) + b.m * (dby * dby + dbz * dbz),
    iyy = a.iyy + b.iyy + a.m * (dax * dax + daz * daz) + b.m * (dbx * dbx + dbz * dbz),
    izz = a.izz + b.izz + a.m * (dax * dax + day * day) + b.m * (dbx * dbx + dby * dby),
  }
end

local pendP = combine(combine(combine(combine(leverP, discP), filmP), clampP), bobP)
local pendM, pendCX, pendCY, pendCZ, pendIxx, pendIyy, pendIzz =
  pendP.m, pendP.cx, pendP.cy, pendP.cz, pendP.ixx, pendP.iyy, pendP.izz

local PIVOT_Y = u(ANCHOR_PIVOT_Y)
local SHAFT_Y = u(PIVOT_SHAFT_Y)    -- the pivot shaft the anchor's bore rides on

-- A pendulum body: the part's mesh re-emitted with its centre of mass at
-- the body origin, carrying its own mass and inertia (the same setMassProps
-- idiom as the wheel). The disc is a press fit inside the lever's bore and
-- the clamp traps the film against the lever, so these parts must not
-- collide; the fixed welds below hold them, not the contact solver.
local function pendulumBody(part, src, col)
  local o = scad(string.format("translate([%.4f,%.4f,%.4f]){\n%s\n}",
                               -part.cx, -part.cy, -part.cz, src), 1, col)
  o.body:setMassProps(part.m, btVector3(part.ixx, part.iyy, part.izz))
  o.body:updateInertiaTensor()
  o.body:forceActivationState(4)
  o.body:setCollisionFlags(CF_NO_RESPONSE)
  return o
end

-- The lever keeps its collisions: it is the only pendulum part the escape
-- wheel touches.
local anchor = scad(anchorSrc(-leverP.cx, -leverP.cy, -leverP.cz), 1, "#e8c9a0")
anchor.body:setMassProps(leverP.m, btVector3(leverP.ixx, leverP.iyy, leverP.izz))
anchor.body:updateInertiaTensor()
anchor.body:forceActivationState(4)
anchor.friction = 0.30
anchor.restitution = 0.0
anchor.damp_ang = 0.004                     -- air drag + pivot loss: a high-Q pendulum

local pivotDisc = pendulumBody(discP, makePivotDisc(), "#8d9298")
local filmStrip = pendulumBody(filmP, makeFilmStrip(), "#4a4a52")
local filmClamp = pendulumBody(clampP, makeFilmClamp(), "#f0f0ea")
local bob       = pendulumBody(bobP, makePendulumBob(), "#e8b478")

v:addConstraint(stiffenHinge(btHingeConstraint(
  baseplate.body, anchor.body,
  btVector3(0, SHAFT_Y, 0), btVector3(0, u(LEVER_DROP) - leverP.cy, -leverP.cz),
  btVector3(0, 0, 1), btVector3(0, 0, 1))))

-- Weld the assembly together, each joint at the part it hangs on: the
-- lever-disc bore, the clamp, and the bob. Each frame is the shared weld
-- point from that body's own COM (the identity offset when the weld IS the
-- part's COM); the identity rotations lock the parts in their initial
-- (assembly) alignment forever.
--
-- Every weld is stiffened before it is added: v:addConstraint adopts the
-- constraint into C++ ownership, so the parameters go on while it is still
-- ours. The chain is deliberately STAR-shaped where it can be -- disc, clamp
-- and film all hang off the lever rather than in series -- because each
-- additional weld in a series is another compliant link between a tooth
-- impulse and the bob it has to move.
local function weld(a, b, frameA, frameB)
  local con = stiffenWeld(btFixedConstraint(a.body, b.body, frameA, frameB))
  v:addConstraint(con)
  return con
end

local function atLever(p)
  return common.transform(0, 0, 0, p.cx - leverP.cx, p.cy - leverP.cy, p.cz - leverP.cz)
end

local ORIGIN = common.transform(0, 0, 0, 0, 0, 0)

weld(anchor, pivotDisc, atLever(discP), ORIGIN)
weld(anchor, filmClamp, atLever(clampP), ORIGIN)
weld(anchor, filmStrip, atLever(filmP), ORIGIN)
weld(anchor, bob, atLever(bobP), ORIGIN)

-- Places the whole pendulum at `ang` radians from vertical, at rest. Every
-- body's origin is its own COM, so each rides the pivot on its own swing
-- radius.
local function setPendulum(ang)
  local c, s = math.cos(ang), math.sin(ang)
  local q = btQuaternion(0, 0, math.sin(ang / 2), math.cos(ang / 2))
  local off = PIVOT_Y - SHAFT_Y       -- the rolling-contact datum sits above the shaft
  local function place(o, cx, cy, cz)
    o.trans = btTransform(q, btVector3(c * cx - s * (cy + off),
                                       SHAFT_Y + s * cx + c * (cy + off), cz))
    o.vel = btVector3(0, 0, 0)
    o.body:setAngularVelocity(btVector3(0, 0, 0))
  end
  place(anchor, leverP.cx, leverP.cy, leverP.cz)
  place(pivotDisc, discP.cx, discP.cy, discP.cz)
  place(filmStrip, filmP.cx, filmP.cy, filmP.cz)
  place(filmClamp, clampP.cx, clampP.cy, clampP.cz)
  place(bob, bobP.cx, bobP.cy, bobP.cz)
end

local START_ANGLE = math.rad(-3.0)
setPendulum(START_ANGLE)

-- The swing is about the HINGE, not about the assembly's own centre of mass,
-- so the beat has to be quoted from the inertia transferred to the hinge --
-- Izz + m*d^2 -- with d measured from the hinge (the pivot shaft) down to the
-- centre of mass. Quoting the centroidal Izz on its own understates the beat
-- by more than 3x here, since m*d^2 is the bulk of it.
local PEND_ARM = math.abs(pendCY - (SHAFT_Y - PIVOT_Y))
local PEND_I_PIVOT = pendIzz + pendM * PEND_ARM * PEND_ARM
local PEND_BEAT = math.pi * math.sqrt(PEND_I_PIVOT / (pendM * (-GRAVITY) * PEND_ARM))

print(string.format("escape wheel: m=%.4f  Izz=%.2f   drive torque=%.1f (weight m=%.4f)",
                    wheelM, wheelIzz, DRIVE_TORQUE, WEIGHT_M))
print(string.format("pendulum:     m=%.4f  arm=%.2f  I(hinge)=%.1f   beat=%.3f s (%.1f frames)",
                    pendM, PEND_ARM, PEND_I_PIVOT, PEND_BEAT, PEND_BEAT / v.timeStep))

-- ---------------------------------------------------------------------
-- riders: carried rigidly by the body they are screwed to
--
-- Every rider is emitted in its carrier's own datum frame, and every
-- carrier's body origin sits at that frame's centre of mass, so one offset
-- (-com) places all of them. The carrier's z-rotation is read straight off
-- its quaternion as cos/sin -- for a rotation about z alone, q = (0, 0,
-- sin(a/2), cos(a/2)), so cos a = w^2 - z^2 and sin a = 2wz, with no
-- inverse trig anywhere (same portability caution as linkage.lua).
-- ---------------------------------------------------------------------

local function carrierFrame(carrier, comX, comY, comZ)
  local q = carrier.trans:getRotation()
  local qz, qw = q:getZ(), q:getW()
  local c, s = qw * qw - qz * qz, 2 * qw * qz
  local p = carrier.pos
  local ox, oy = -comX, -comY
  return q, c, s,
         btVector3(p.x + c * ox - s * oy, p.y + s * ox + c * oy, p.z - comZ)
end

local function ride(part, q, origin)
  part.trans = btTransform(q, origin)
end

-- ---------------------------------------------------------------------
-- run: drive the arbor, carry the riders, count the beats
-- ---------------------------------------------------------------------

-- Which way the weight turns the wheel. The teeth are asymmetric -- one face
-- is very nearly radial (its ends lie at -36.40 and -36.13 deg, i.e. along a
-- radius) and the other rakes back from -37.8 to -39.6 deg -- and it is the
-- radial face that has to lead, since that is the one a pallet can hold
-- against. That face sits on the anticlockwise side of each tooth, so the
-- wheel is driven anticlockwise, +1 about z. Confirmed by measurement: +1
-- advances the wheel 8.20 deg in a beat where -1 manages 1.60.
local DRIVE_SIGN = 1
local wheelTurn, prevC, prevS = 0, 1, 0
local beats, lastSide, maxAng = 0, 0, 0
local beatFrame, beatTurn = 0, 0

-- A beat is a zero crossing of the swing, but only after the pendulum has
-- actually been somewhere: a bare sign test also counts the jitter while a
-- tooth is landing on a pallet, which reported 8 beats in 25 frames -- an
-- impossibility at a .75 s beat -- and made the escapement look far worse
-- than it is. Arming the crossing outside a 1 degree dead band removes that
-- entirely, so the beat count is the mechanism's and not the solver's.
local BEAT_ARM = math.sin(math.rad(1.0))

-- What the escapement should deliver: 24 teeth, two beats per tooth, so
-- 7.5 degrees of wheel per beat. Anything more is a slipped tooth.
local DEG_PER_BEAT = 360.0 / (24 * 2)

v:preSim(function(N)
  wheel.body:applyTorque(btVector3(0, 0, DRIVE_SIGN * DRIVE_TORQUE))
end)

v:postSim(function(N)
  -- escape wheel and everything pressed onto its arbor
  local q, c, s, o = carrierFrame(wheel, wheelCX, wheelCY, wheelCZ)
  ride(wheelShaft, q, o)
  ride(cordDrum, q, o)

  -- accumulated arbor angle, from the frame-to-frame rotation only, so it
  -- keeps counting past a full turn (asin is safe: the step is tiny)
  local dSin = s * prevC - c * prevS
  local dCos = c * prevC + s * prevS
  if dCos > 0 then
    wheelTurn = wheelTurn + math.asin(math.max(-1, math.min(1, dSin)))
  end
  prevC, prevS = c, s

  -- the cord pays out: the weight drops by r * (turn), no rope needed
  weight.pos = btVector3(u(WEIGHT_X),
                         u(WEIGHT_TOP_Y - WEIGHT_L / 2) - DRIVE_SIGN * wheelTurn * u(DRUM_R),
                         u((Z_DRUM_BACK + Z_DRUM_FRONT) / 2))

  -- the pendulum assembly now swings on its own welded bodies; only its
  -- swing angle is wanted here, for the beat count
  local _, _, as = carrierFrame(anchor, leverP.cx, leverP.cy, leverP.cz)

  -- one beat per armed zero crossing of the pendulum
  if math.abs(as) > maxAng then maxAng = math.abs(as) end
  if math.abs(as) > BEAT_ARM then
    local side = (as > 0) and 1 or -1
    if lastSide ~= 0 and side ~= lastSide then
      beats = beats + 1
      local turn = math.deg(math.abs(wheelTurn))
      print(string.format(
        "beat %4d  frame %5d (%5.3f s)   wheel +%5.2f deg%s   amplitude %5.2f deg",
        beats, N, (N - beatFrame) * v.timeStep, turn - beatTurn,
        (turn - beatTurn > 1.5 * DEG_PER_BEAT) and "  <- SLIPPED" or "",
        math.deg(math.asin(math.min(1, maxAng)))))
      beatFrame, beatTurn, maxAng = N, turn, 0
    end
    lastSide = side
  end
end)

v:addShortcut("F1", function(N)
  setPendulum(START_ANGLE)
  beats, lastSide, maxAng = 0, 0, 0
  print("pendulum restarted from rest")
end)

v:addShortcut("F2", function(N)
  print(string.format(
    "frame %d: %d beats, wheel %.2f deg (%.3f turns), weight down %.2f units",
    N, beats, math.deg(wheelTurn), math.abs(wheelTurn) / (2 * math.pi),
    math.abs(wheelTurn) * u(DRUM_R)))
end)

-- ---------------------------------------------------------------------
-- view
-- ---------------------------------------------------------------------

common.setCamera(btVector3(0, -34, 128), btVector3(0, -5, 0), nil,
                 { up = btVector3(0, 1, 0) })

v.pre_sdl = [[
#include "colors.inc"
#include "textures.inc"
]]

v.sdl = [[
light_source { <60, 40, 180> color rgb <1, 0.96, 0.88> area_light
  <20,0,0>, <0,20,0>, 3, 3 adaptive 1 jitter }
light_source { <-90, -20, 120> color rgb <0.55, 0.62, 0.75> }
light_source { <0, 60, -140> color rgb <0.35, 0.35, 0.4> shadowless }
]]

print("The World's Simplest Clock -- F1: restart the pendulum, F2: report the beat count")

-- EOF
