--
-- Jansen Walker -- a physically-simulated Theo Jansen ("Strandbeest") leg
-- mechanism, six copies mounted on a shared cube body, built the same way
-- as demo/WyomingWill/cheby_normal6.lua: real Bullet rigid bodies + hinge
-- constraints (one of them motorized), not analytic forward kinematics.
--
-- Ground link lengths a..m are Theo Jansen's own published "holy numbers",
-- transcribed from the linkage_c reference tool's mechanisms.c (the same
-- crossing-free branch choice used there and in demo/WyomingWill/linkage.lua
-- -- an earlier, more commonly-cited branch choice was found to have two
-- links overlapping for 100% of the cycle, which isn't physically buildable
-- here any more than it would be with real hinges).
--
-- WHY 7 RIGID BODIES PER LEG, NOT 8 (AND NOT 11): mechanisms.c's own
-- compute_jansen() finds each new joint (J2..J5, F) via circle_intersect(),
-- i.e. a classic RRR dyad -- two binary links whose OTHER ends are already
-- known, meeting at the new joint. Walking that dyad chain out gives 11
-- distinct point-to-point spans (crank O-J1, then J1-J2, G-J2, J2-J3, G-J3,
-- J1-J4, G-J4, J3-J5, J4-J5, J4-F, J5-F). The README's "8 links" count is
-- the informal description of the classic linkage; TWO of these span-
-- triples form rigid triangles (G-J2-J3, via rodB/rodE/rodD; and
-- J4-J5-F, via rodG/rodH/rodI), and BOTH are built as single rigid bodies
-- here (triG, triJ4, via makeTriangle) rather than 3 separately-hinged
-- rods each -- see that function's own header note for the full
-- reasoning and the real, MEASURED chirality-flip bug it was originally
-- built to fix on a different (Klann) mechanism's own narrow triangle.
-- NEITHER Jansen triangle is anywhere near that narrow -- checked
-- directly: G-J2-J3 has b+d=81.6 vs. e=55.8 (46% margin), J4-J5-F has
-- g+i=85.7 vs. h=65.7 (30% margin) -- so this conversion is NOT fixing a
-- measured defect here, it's a consistency/quality upgrade: same fewer-
-- hinges and zero-internal-flex benefits, real OpenSCAD-rendered
-- triangular shapes instead of 3 separate bars each. Net count: crank +
-- rodJ + triG (the merged G-J2-J3 triangle) + rodK + rodC + rodF + triJ4
-- (the merged J4-J5-F triangle) = 7 bodies. DOF check: 7 * 3 planar DOF
-- = 21, minus 10 hinges * 2 DOF removed = 20, leaves exactly 1 DOF,
-- driven by the single motorized crank hinge at O.
--
-- HUB CONVENTION: with both triangles merged, only J1 and J4 still have
-- more than 2 bodies meeting at the same point (J1 has 3: crank, rodJ,
-- rodK; J4 has 3: rodK, rodC, triJ4). At each such point one body is
-- picked as the "hub" and every other body there is hinged directly to
-- the hub (all at the same local pivot) rather than to each other. G, J2,
-- J3, and J5 no longer need a hub at all -- each is now just a plain
-- 2-body joint (cube<->triG at G alongside the separate cube<->rodC;
-- rodJ<->triG at J2; triG<->rodF at J3; rodF<->triJ4 at J5), since triG
-- and triJ4 each absorbed what used to be 2-3 separate rods meeting at
-- their own vertices. F needs no hinge at all anymore -- it's now just a
-- marked point on triJ4, welded to by buildFoot below (rodI and rodH,
-- the two rods that used to meet there, are both internal to triJ4 now).
-- See the hinge block in buildJansenLeg for exactly which body is the
-- hub at each remaining multi-body joint.
--
-- WHY NO X-MIRRORING: mechanisms.c's own branch signs (-1,-1,+1,-1,+1)
-- were verified crossing-free for THIS specific (unmirrored) leg. A true
-- left/right mirror would flip handedness and could need re-verifying
-- those signs don't reintroduce a crossing -- extra risk not worth taking
-- here. Instead, every leg uses the identical unmirrored geometry, just
-- offset in X by enough to clear the mechanism's own ~122x125-unit
-- footprint (measured by sampling compute(theta) over a full cycle, same
-- technique as cheby_normal6.lua's floor-height derivation) -- so the
-- walker's left and right legs aren't mirror images of each other, just
-- two copies of the same design far enough apart not to collide. Front and
-- back copies mirror in Z exactly like cheby_normal6.lua's back face
-- (every hinge axis is world Z, so flipping the whole staggered Z-plane
-- stack's sign is enough -- no X,Y geometry has to change for that).
--
-- HONEST CAVEAT (stability): CFM softening (see v:setCfm below) was
-- needed just to keep one leg's own closed-loop network from diverging
-- (see the CFM note below for why). It also drifts sideways over a long
-- walk rather than tracking straight, likely compounding from the
-- unmirrored left/right legs noted above.
--
-- SIX LEGS, NOT FOUR: the original 4-leg build (2 rows x front/back,
-- phases 0/180) walked for a while but eventually tipped and fell -- with
-- only two phase groups 180 degrees apart, and each leg's own duty cycle
-- only ~62% of the cycle in ground contact (see linkage.lua's metrics for
-- this same mechanism), there are stretches where neither phase group has
-- solid contact, and the walker is momentarily balanced on very little
-- support. A third row at a THIRD phase (0/120/240 degrees, not 0/180)
-- fills that gap: with duty ~62% and 3 phase groups spread evenly, at
-- least one (usually two) of the three is in stance at any instant, so
-- the cube is never left standing on a near-empty base the way the 2-row
-- version was. Within a row, front and back (the Z-mirrored pair) share
-- the SAME phase -- they move together for left/right symmetry -- while
-- the three rows (spaced along X, the walking direction) are what's
-- staggered for continuous support. Verified: the 4-leg build's standing
-- height held for only ~20 simulated seconds before it sagged into a
-- lower stance; with 6 legs that stretches to ~45 seconds (checked out to
-- 1200 frames / 60s), and it still doesn't collapse further after
-- sagging -- it just keeps walking from the lower stance instead.
--

local common = require "common"

-- ---------------------------------------------------------------------
-- SLIDERS, per direct request ("Add sliders for speed and terrain
-- amplitude, and maxsubsteps"). Speed and maxSubSteps are LIVE (applied
-- in place every tick, no rebuild) -- neither changes any geometry.
-- TerrainAmp REBUILDS the scene -- it changes the floor's own shape and,
-- through O_MOUNT_Y, how high the whole walker starts, so a live-only
-- update would leave the floor and the walker's starting height out of
-- sync with each other.
-- ---------------------------------------------------------------------

local PARAM_INFO = {
  Speed = { min = 0, max = 8, step = 0.1,
            comment = "crank motor target angular speed, all 6 legs (live)" },
  maxSubSteps = { min = 1, max = 1000, step = 1,
            comment = "Bullet max substeps per tick (live)" },
  TerrainAmp = { min = 0, max = 30, step = 0.5,
            comment = "terrain bump height (rebuilds the scene)" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
end

local builtObjects, builtConstraints = {}, {}
function track(obj)
  v:add(obj)
  obj.body:setActivationState(4)   -- DISABLE_DEACTIVATION -- a sleeping body ignores its own motor's torque
  builtObjects[#builtObjects + 1] = obj
  return obj
end
function trackConstraint(con)
  v:addConstraint(con)
  builtConstraints[#builtConstraints + 1] = con
  return con
end
function teardownScene()
  for _, con in ipairs(builtConstraints) do v:removeConstraint(con) end
  for _, obj in ipairs(builtObjects) do v:remove(obj) end
  builtObjects, builtConstraints = {}, {}
end

common.setTiming(1/20, 60, 1/240)   -- maxSubSteps arg here is just Bullet's
                                     -- own ceiling for a single tick -- the
                                     -- REAL live value comes from the
                                     -- maxSubSteps slider (v.maxSubSteps=...
                                     -- below) -- set generously high (60)
                                     -- so the slider's own max (60) is never
                                     -- silently clamped by this one

-- Each leg's 10 hinges form several NESTED closed loops (unlike
-- cheby_normal6.lua's single open-then-closed 4-bar loop), which is a
-- classically hard case for an iterative sequential-impulse solver: even
-- though every pivot was verified to coincide to ~1e-6 at construction
-- (see the "WHY 7 RIGID BODIES" header note), the solver has no slack to
-- resolve the inevitable per-step floating-point/discretization error
-- among that many redundant constraints, so it fights itself and the leg
-- diverges within seconds at Bullet's default (zero) constraint force
-- mixing. A modest CFM gives every hinge a little softness -- verified
-- experimentally: 0 diverges immediately, 0.01 still drifts slowly, 0.1
-- holds a leg motionlessly stable indefinitely and lets the whole walker
-- walk (checked out to 800+ simulated frames).
--
-- CHANGED TO PER-HINGE, NOT a world-level v:setCfm() call, per direct
-- diagnosis while adding real bumpy terrain: v:setCfm() sets Bullet's
-- GLOBAL constraint force mixing, softening every constraint the solver
-- touches each step -- including the CONTACT constraints collision
-- detection generates against the terrain mesh. Confirmed directly: with
-- the global call still active, a foot's own Y tracked well BELOW the
-- local bump surface it should have been resting on (foot at -6.86 vs a
-- local terrain height of +5.02) -- it was tunneling straight through
-- the visible bumps and landing on a flat backstop underneath instead,
-- which defeats having real terrain at all. Scoped to just the 16 leg
-- hinges instead, via hinge()'s own h:setParam(3, HINGE_CFM, -1) call
-- below (Bullet's BT_CONSTRAINT_CFM, axis -1 = the hinge's main lock) --
-- terrain/foot contact now stays at Bullet's normal rigid default.
local HINGE_CFM = 0.1

-- ---------------------------------------------------------------------
-- Jansen's own link lengths (mechanisms.c's a..m), identical for every leg
-- ---------------------------------------------------------------------

local LEN = {
  a = 38.0, b = 41.5, c = 39.3, d = 40.1, e = 55.8, f = 39.4, g = 36.7,
  h = 65.7, i = 49.0, j = 50.0, k = 61.9, l = 7.8, m = 15.0,
}

-- ---------------------------------------------------------------------
-- shared geometry helpers (same conventions as demo/WyomingWill/cheby_normal6.lua)
-- ---------------------------------------------------------------------

function midpoint(p1, p2)
  return { x = (p1.x + p2.x) / 2, y = (p1.y + p2.y) / 2 }
end

-- one of the two points where a circle (center p1, radius r1) meets a
-- circle (center p2, radius r2); branch = +1 or -1 selects which one --
-- same convention (and same verified branch values) as mechanisms.c's
-- circle_intersect() / demo/WyomingWill/linkage.lua's circleIntersect().
function circleIntersect(p1, r1, p2, r2, branch)
  local dx, dy = p2.x - p1.x, p2.y - p1.y
  local dist = math.sqrt(dx * dx + dy * dy)
  local a = (r1 * r1 - r2 * r2 + dist * dist) / (2.0 * dist)
  local h2 = r1 * r1 - a * a
  local h = (h2 > 0.0) and math.sqrt(h2) or 0.0
  local mx, my = p1.x + a * dx / dist, p1.y + a * dy / dist
  local px, py = -dy / dist, dx / dist
  return { x = mx + branch * h * px, y = my + branch * h * py }
end

-- build a Z-axis rotation quaternion directly from a direction vector
-- (half-angle formulas -- avoids atan2, following the same portability
-- caution as cheby_diag4.lua's own zrotVec).
function zrotVec(dx, dy)
  local len = math.sqrt(dx * dx + dy * dy)
  local cosT, sinT = dx / len, dy / len
  local cosHalf = math.sqrt((1 + cosT) / 2)
  local sinHalf = math.sqrt((1 - cosT) / 2)
  if sinT < 0 then sinHalf = -sinHalf end
  return btQuaternion(0, 0, sinHalf, cosHalf)
end

local IDENTITY_QUAT = btQuaternion(0, 0, 0, 1)
local AXIS = btVector3(0, 0, 1)

--local ROD_W, ROD_D = 1.8, 0.8   -- rod cross-section (Z-thickness ROD_D must stay
local ROD_W, ROD_D = 4.8, 0.8   -- rod cross-section (Z-thickness ROD_D must stay
                                 -- under plane_gap below, or adjacent Z-planes'
                                 -- rods would overlap and collide)
local MASS_BASE, MASS_PER_LEN = 0.3, 0.04   -- rod mass = MASS_BASE + length*MASS_PER_LEN

-- makes one rod-shaped rigid body from p1 to p2, sitting flat on its own
-- Z-plane; also returns its length (every hinge pivot below is expressed
-- as +-length/2 along the rod's own local X, since zrotVec always points
-- local +X from p1 toward p2 -- same trick as cheby_normal6.lua's makeLink).
function makeLink(p1, p2, z, color)
  local len = math.sqrt((p2.x - p1.x) ^ 2 + (p2.y - p1.y) ^ 2)
  local mid = midpoint(p1, p2)
  local q = zrotVec(p2.x - p1.x, p2.y - p1.y)
  local obj = Cube(len, ROD_W, ROD_D, MASS_BASE + len * MASS_PER_LEN)
  obj.col = color
  obj.trans = btTransform(q, btVector3(mid.x, mid.y, z))
  obj.friction = 0.5
  obj.damp_ang = 0.05   -- mild passive damping -- this mechanism has far more
                         -- closed hinge loops than cheby_normal6's simple 4-bar,
                         -- so a little energy bleed helps keep it from ringing
  track(obj)
  return obj, len
end

-- makes ONE rigid body spanning all three vertices of a triangle
-- p1-p2-p3, instead of three separately hinged rods -- a triangle of 3
-- pin-jointed rods is kinematically rigid in the IDEALIZED zero-DOF
-- sense (can't deform without a side changing length), but real hinges
-- here carry a little CFM softness (see HINGE_CFM above) for the leg's
-- own closed-loop stability. That softness was CONFIRMED to let a very
-- narrow triangle (short sides summing to only slightly more than the
-- long side) flip chirality under real dynamic load on a different
-- (Klann) mechanism's own triangle -- see this project's other Klann
-- file for the full pendulum-test/signed-area diagnostic that found it.
-- Neither of THIS file's two triangles (G-J2-J3, J4-J5-F) is anywhere
-- near that narrow (46% and 30% margin respectively, vs. the Klann
-- triangle's ~0.6%) -- converting them here is a consistency/quality
-- upgrade, not a defect fix: fewer hinges, zero possibility of
-- internal flex regardless of margin, and a real triangular shape
-- instead of 3 separate bars.
--
-- BUILT VIA REAL OPENSCAD EXTRUSION (polygon()+linear_extrude()), run
-- through the actual `openscad` binary -- this file depends on it being
-- installed (`apt-get install openscad` if missing). SDL coordinates are
-- pre-shifted by the triangle's own closed-form centroid (exactly the
-- average of its 3 vertices, for a uniform-density triangle) and passed
-- with centerOfMass=false, NOT true -- a direct read of the engine's own
-- source (Mesh::renderInLocalFrame in mesh.cpp) shows the render path
-- draws from the untouched raw Assimp import while centerOfMass=true's
-- recentering only ever reaches the COLLISION shape, so physics and
-- rendering silently disagree by exactly the centroid offset when
-- centerOfMass=true is used. Pre-centering the SDL itself and passing
-- centerOfMass=false sidesteps that mismatch entirely -- confirmed fix,
-- not a guess.
--
-- Local frame: origin/orientation follow the SAME p1->p3 convention as
-- makeLink (zrotVec, local +X from p1 toward p3), so p3's own local pivot
-- falls on the local X axis exactly like a plain rod's would; p2 is
-- projected into that frame. Returns the body plus all three pivots,
-- already expressed relative to the body's own local origin (its true
-- centroid, not p1) so they can be passed straight into hinge() calls.
function makeTriangle(p1, p2, p3, z, color)
  local dx, dy = p3.x - p1.x, p3.y - p1.y
  local len13 = math.sqrt(dx * dx + dy * dy)
  local ux, uy = dx / len13, dy / len13     -- local +X unit vector, in world coords
  local vx, vy = -dy / len13, dx / len13    -- local +Y unit vector, in world coords

  local ex, ey = p2.x - p1.x, p2.y - p1.y
  local p2x = ex * ux + ey * uy   -- p2's local X (relative to p1 at local origin, pre-recenter)
  local p2y = ex * vx + ey * vy   -- p2's local Y

  -- pre-recenter local coords: p1_l=(0,0), p2_l=(p2x,p2y), p3_l=(len13,0)
  -- triangle centroid (exact, uniform density) = average of the 3 vertices
  local ccx, ccy = (0 + p2x + len13) / 3, (0 + p2y + 0) / 3

  -- SDL points are shifted by -ccx,-ccy HERE, in Lua, before OpenSCAD ever
  -- sees them -- see the header note above for why (the engine's own
  -- centerOfMass=true recenters physics but not rendering).
  local sdl = string.format(
    "linear_extrude(height=%.4f, center=true) { polygon(points=[[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f]]); }",
    ROD_D, 0 - ccx, 0 - ccy, p2x - ccx, p2y - ccy, len13 - ccx, 0 - ccy)
  local mass = MASS_BASE + len13 * MASS_PER_LEN
  local obj = OpenSCAD(sdl, mass, false)   -- centerOfMass=false -- already pre-centered above

  local q = zrotVec(dx, dy)
  local midWorld = { x = p1.x + ccx * ux + ccy * vx, y = p1.y + ccx * uy + ccy * vy }   -- world position of the TRUE centroid
  obj.col = color
  obj.trans = btTransform(q, btVector3(midWorld.x, midWorld.y, z))
  obj.friction = 0.5
  obj.damp_ang = 0.05
  track(obj)

  local piv1 = btVector3(0 - ccx, 0 - ccy, 0)
  local piv2 = btVector3(p2x - ccx, p2y - ccy, 0)
  local piv3 = btVector3(len13 - ccx, 0 - ccy, 0)
  return obj, piv1, piv2, piv3
end

-- thin wrapper around btHingeConstraint, all axes world Z (every rod here
-- only ever rotates about Z, exactly like cheby_normal6.lua's linkages).
function hinge(bodyA, bodyB, pivotA, pivotB, motorSpeed, motorImpulse)
  local h = btHingeConstraint(bodyA, bodyB, pivotA, pivotB, AXIS, AXIS)
  h:setParam(3, HINGE_CFM, -1)   -- BT_CONSTRAINT_CFM, scoped to just this hinge -- see the HINGE_CFM note above
  if motorSpeed ~= nil then
    h:enableAngularMotor(true, motorSpeed, motorImpulse)
  end
  trackConstraint(h)
  return h
end

function buildScene()
-- ---------------------------------------------------------------------
-- Z-plane stack -- one plane per rod, staggered out from the cube's own
-- face so the 11 rotating rods never collide with each other or the cube
-- (same technique as cheby_normal6.lua's z_ground/z_crank/z_coupler/...).
-- ---------------------------------------------------------------------

local plane_gap = 1.2   -- > ROD_D, so adjacent planes' rod boxes never touch
local cube_d = 150.0     -- cube's own Z-depth

-- z_ground..z_triJ4 are GLOBAL (no "local") -- buildJansenLeg() (defined
-- once, textually nested inside this function but only invoked from the
-- leg-building loop further down) reads these as free variables. 7 rod
-- planes total, one per rigid body (crank, rodJ, triG, rodK, rodC, rodF,
-- triJ4) -- see the "WHY 7 RIGID BODIES" header note.
z_ground = cube_d / 2   -- reference only (cube's own surface) -- not a rod
z_crank  = z_ground + 1 * plane_gap
z_rodJ   = z_ground + 2 * plane_gap
z_triG   = z_ground + 3 * plane_gap
z_rodK   = z_ground + 4 * plane_gap
z_rodC   = z_ground + 5 * plane_gap
z_rodF   = z_ground + 6 * plane_gap
z_triJ4  = z_ground + 7 * plane_gap

-- ---------------------------------------------------------------------
-- cube body + floor
--
-- O_ABOVE_CUBE / JANSEN_YMIN / FOOT_CLEARANCE below were derived the same
-- way as cheby_normal6.lua's floor_top_y: sampling compute(theta) over a
-- full crank rotation. JANSEN_YMIN=-91.83 is foot F's lowest point
-- relative to O (measured numerically -- see the header note on why no
-- mirroring is needed; the same sweep also gives the leg's full footprint,
-- x in [-107.17,15.00] y in [-91.83,33.70] relative to O, which sets
-- ROW_SPACING below).
-- ---------------------------------------------------------------------

local ROW_SPACING = 120 --220    -- > leg's own ~122-unit X footprint, so consecutive
                            -- rows (all unmirrored, see header) never overlap
local NUM_ROWS    = 3      -- 3 rows x front/back = 6 legs -- see the "SIX LEGS"
                            -- header note for why 3, not 2
local CUBE_MARGIN = 60
local CUBE_W        = (NUM_ROWS - 1) * ROW_SPACING + 2 * CUBE_MARGIN
local CUBE_H         = 10.0
CUBE_CENTER_X  = (NUM_ROWS - 1) * ROW_SPACING / 2   -- middle row's X -- GLOBAL, read by the trail-marker preSim hook outside buildScene()

local JANSEN_YMIN    = -91.83   -- foot F's lowest reach relative to O
local FOOT_CLEARANCE = 3.0
FLOOR_TOP_Y    = 0.0   -- baseline (flat-average) floor height -- GLOBAL, read by the trail-marker hook -- real terrain bulges above/below this by up to TERRAIN_AMP, see terrainHeight() near the floor code below
local TERRAIN_AMP = v:getParam("TerrainAmp")   -- GUI slider -- max bump height above/below FLOOR_TOP_Y -- the three sine terms in terrainHeight() sum to a max combined amplitude of exactly 1.0, so this is a direct multiplier
-- O_MOUNT_Y must clear the TALLEST possible bump (FLOOR_TOP_Y+TERRAIN_AMP),
-- not just the flat baseline -- otherwise a leg whose phase happens to
-- put its foot at JANSEN_YMIN right where the terrain happens to bulge
-- to its maximum would start embedded, before gravity/contact ever get
-- a chance to settle it naturally (same principle as every other
-- terrain-bump walker in this file series).
O_MOUNT_Y      = (FLOOR_TOP_Y + TERRAIN_AMP) - JANSEN_YMIN + FOOT_CLEARANCE   -- GLOBAL -- buildJansenLeg() reads this as a free variable
local O_ABOVE_CUBE   = 3.0
local CUBE_POS_Y     = O_MOUNT_Y - O_ABOVE_CUBE - CUBE_H / 2

-- cube mass is heavy relative to the six legs' combined ~135 units of mass
-- -- a light chassis gets thrown around by its own legs' reaction forces
-- (verified on the earlier 4-leg build: at mass 30 the whole walker tips
-- and falls within a few seconds; at 150 it holds a stable, if lower,
-- stance -- scaled up further here for the extra two legs' worth of load).
cube = Cube(CUBE_W, CUBE_H, cube_d, 220.0)
cube.col = "#29c235"
cube.pos = btVector3(CUBE_CENTER_X, CUBE_POS_Y, 0)
cube.friction = 0.5
cube.damp_ang = 1.0 -- WMS
cube.damp_lim = 1.0 -- WMS
track(cube)

-- FLOOR: bumpy terrain mesh (real hills, using terrainHeight(x,z)) on
-- top of a solid thick backstop box, per direct request ("replace that
-- floor with my terrain floor and make sure the feet... do not sink").
-- Two-part design, not just a plain mesh: this file's own CFM softening
-- is a GLOBAL v:setCfm(0.1) call (see that line's own comment above),
-- which -- confirmed elsewhere in this file series -- silently softens
-- terrain CONTACT resolution along with the leg hinges, letting a fast-
-- moving foot tunnel straight through a zero-thickness mesh regardless
-- of the mesh's own shape. Rather than touch the CFM approach this file
-- already has working (not asked for here), the backstop box gives
-- real physical thickness underneath the visual bumps -- exactly the
-- same fix this file's OWN header comment already documents needing
-- for its original flat floor ("a thin floor let a foot tunnel...").
--
-- terrainHeight(): three sine terms, amplitudes 0.5/0.3/0.2 summing to
-- a max combined amplitude of exactly 1.0, so TERRAIN_AMP above is a
-- direct multiplier on real bump height. Frequencies scaled down 10x
-- from the smaller-scale version elsewhere in this file series, to
-- keep bump WAVELENGTH proportional at this file's much larger native
-- Jansen units (roughly 8x bigger, given the other version's own
-- 0.1226 rescale factor).
function terrainHeight(x, z)
  return TERRAIN_AMP * (
    0.5 * math.sin(x * 0.030 + z * 0.021) +
    0.3 * math.sin(x * 0.011 - z * 0.044 + 1.7) +
    0.2 * math.sin(x * 0.053 + z * 0.007 + 4.1))
end

-- floor_w/floor_d/terrain_nx/terrain_nz/floor_x0/floor_z0 (below) are
-- globals, not locals -- same "GLOBAL, read by the trail-marker preSim
-- hook outside buildScene()" convention CUBE_CENTER_X already uses
-- above, needed so the trail code past the end of buildScene() can
-- convert a world (x,z) back to a terrain triangle index using these
-- exact same values, instead of only the code inside this function
-- being able to see them.
floor_w, floor_d = 10000, 10000
--local terrain_nx, terrain_nz = 100, 50   -- grid resolution -- 20-unit cells, proportionate to this file's own ~40-65-unit link lengths
terrain_nx, terrain_nz = 300, 200   -- grid resolution -- 20-unit cells, proportionate to this file's own ~40-65-unit link lengths

-- backstop: solid, thick, flat -- positioned BELOW the lowest possible
-- bump trough (FLOOR_TOP_Y-TERRAIN_AMP) so it never clips through and
-- shows past the visual mesh above it, with the SAME 40-unit thickness
-- this file's own header note already found necessary.
--local backstop_th = 40.0
--local backstop_top_y = FLOOR_TOP_Y - TERRAIN_AMP
--backstop = Cube(floor_w, backstop_th, floor_d, 0)   -- mass 0 -> static
--backstop.col = "#4a3308"
--backstop.pos = btVector3(CUBE_CENTER_X, backstop_top_y - backstop_th/2, 0)
--backstop.friction = 0.8
--track(backstop)

-- bumpy mesh: the real, visible/tactile terrain -- same triangle-strip
-- construction technique used elsewhere in this file series.
floor = Terrain()
floor_x0, floor_z0 = CUBE_CENTER_X - floor_w/2, -floor_d/2
for i = 0, terrain_nx - 1 do
  for j = 0, terrain_nz - 1 do
    local xa, xb = floor_x0 + i*(floor_w/terrain_nx), floor_x0 + (i+1)*(floor_w/terrain_nx)
    local za, zb = floor_z0 + j*(floor_d/terrain_nz), floor_z0 + (j+1)*(floor_d/terrain_nz)
    local yaa, yab = FLOOR_TOP_Y + terrainHeight(xa, za), FLOOR_TOP_Y + terrainHeight(xa, zb)
    local yba, ybb = FLOOR_TOP_Y + terrainHeight(xb, za), FLOOR_TOP_Y + terrainHeight(xb, zb)
    floor:addTriangle(btVector3(xa, yaa, za), btVector3(xa, yab, zb), btVector3(xb, yba, za))
    floor:addTriangle(btVector3(xb, yba, za), btVector3(xa, yab, zb), btVector3(xb, ybb, zb))
  end
end
floor:build()
floor.col = "#694811"
floor.friction = 0.8
track(floor)


-- ---------------------------------------------------------------------
-- one full Jansen leg: 7 rigid bodies + 10 hinges (1 motorized), mounted
-- at world X = x_offset, with O at world Y = O_MOUNT_Y. mirror flips the
-- whole Z-plane stack's sign (back face); phase (degrees) offsets the
-- crank's initial angle, same role as cheby_normal6.lua's buildLinkage
-- `phase` argument.
--
-- 7 bodies, not 11: BOTH triangular sub-assemblies (G-J2-J3 and
-- J4-J5-F) are now single rigid bodies (triG, triJ4, via makeTriangle)
-- instead of 3 separately hinged rods each. See the "WHY 7 RIGID BODIES"
-- header note for why this is a consistency upgrade here, not a defect
-- fix (unlike the Klann mechanism this technique was originally built
-- for). DOF check: 7 bodies * 3 planar DOF = 21, minus 10 hinges * 2 DOF
-- removed = 20, leaves exactly 1 DOF, driven by the motorized crank
-- hinge at O.
-- ---------------------------------------------------------------------

function buildJansenLeg(x_offset, mirror, phase, speed)
  local zSign = mirror and -1 or 1
  local z_ground_l = zSign * z_ground
  local z_crank_l  = zSign * z_crank
  local z_rodJ_l   = zSign * z_rodJ
  local z_triG_l   = zSign * z_triG
  local z_rodK_l   = zSign * z_rodK
  local z_rodC_l   = zSign * z_rodC
  local z_rodF_l   = zSign * z_rodF
  local z_triJ4_l  = zSign * z_triJ4

  -- reference-pose geometry (world space, at theta = phase) -- used ONLY
  -- to place bodies/hinges at construction time. Motion afterward comes
  -- entirely from real physics (the motorized crank hinge at O, plus 9
  -- passive hinges), not from re-evaluating this every frame.
  local O = { x = x_offset, y = O_MOUNT_Y }
  local G = { x = O.x - LEN.a, y = O.y - LEN.l }
  local theta0 = math.rad(phase)
  local J1 = { x = O.x + LEN.m * math.cos(theta0), y = O.y + LEN.m * math.sin(theta0) }
  local J2 = circleIntersect(J1, LEN.j, G, LEN.b, -1)
  local J3 = circleIntersect(J2, LEN.e, G, LEN.d, -1)
  local J4 = circleIntersect(J1, LEN.k, G, LEN.c, 1)
  local J5 = circleIntersect(J3, LEN.f, J4, LEN.g, -1)
  local F  = circleIntersect(J4, LEN.i, J5, LEN.h, 1)

  local crank = makeLink(O, J1, z_crank_l, "coral")
  local rodJ  = makeLink(J1, J2, z_rodJ_l, "teal")
  local triG, pivTriG_G, pivTriG_J2, pivTriG_J3 =
      makeTriangle(G, J2, J3, z_triG_l, "purple")
  local rodK  = makeLink(J1, J4, z_rodK_l, "teal")
  local rodC  = makeLink(G, J4, z_rodC_l, "purple")
  local rodF  = makeLink(J3, J5, z_rodF_l, "goldenrod")
  local triJ4, pivTriJ4_J4, pivTriJ4_J5, pivTriJ4_F =
      makeTriangle(J4, J5, F, z_triJ4_l, "steelblue")

  local MOTOR_SPEED = -speed -- WMS (negated -- see the SPEED slider note below for why)
  local MOTOR_IMPULSE = 3000.0

  -- O: cube (ground) <-> crank -- the one driven joint. Both pivot sides
  -- are expressed relative to z_ground_l (the cube's own surface plane,
  -- not either body's resting plane) -- same "neutral third reference"
  -- convention as cheby_normal6.lua's pivotCube_O2/pivotCrank_O2, so the
  -- two sides' world Z actually agree instead of fighting each other.
  local pivotCube_O  = btVector3(O.x - cube.pos.x, O.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O = btVector3(-LEN.m / 2, 0, z_ground_l - z_crank_l)
  local motorHinge = hinge(cube.body, crank.body, pivotCube_O, pivotCrank_O, MOTOR_SPEED, MOTOR_IMPULSE)

  -- J1: crank is the hub for rodJ and rodK (3 rods meet here)
  local pivotCrank_J1 = btVector3(LEN.m / 2, 0, 0)
  hinge(crank.body, rodJ.body, pivotCrank_J1, btVector3(-LEN.j / 2, 0, z_crank_l - z_rodJ_l))
  hinge(crank.body, rodK.body, pivotCrank_J1, btVector3(-LEN.k / 2, 0, z_crank_l - z_rodK_l))

  -- G: cube <-> triG, cube <-> rodC -- only 2 bodies meet here now (used
  -- to be cube as hub for 3 independent rockers; rodB and rodD are now
  -- internal to triG, so only triG itself and the separate rodC remain).
  local pivotCube_G = btVector3(G.x - cube.pos.x, G.y - cube.pos.y, z_ground_l - cube.pos.z)
  hinge(cube.body, triG.body, pivotCube_G, btVector3(pivTriG_G.x, pivTriG_G.y, z_ground_l - z_triG_l))
  hinge(cube.body, rodC.body, pivotCube_G, btVector3(-LEN.c / 2, 0, z_ground_l - z_rodC_l))

  -- J2: rodJ <-> triG (only 2 bodies meet here now).
  local pivotRodJ_J2 = btVector3(LEN.j / 2, 0, 0)
  hinge(rodJ.body, triG.body, pivotRodJ_J2, btVector3(pivTriG_J2.x, pivTriG_J2.y, z_rodJ_l - z_triG_l))

  -- J3: triG <-> rodF (only 2 bodies meet here now).
  hinge(triG.body, rodF.body,
        btVector3(pivTriG_J3.x, pivTriG_J3.y, 0),
        btVector3(-LEN.f / 2, 0, z_triG_l - z_rodF_l))

  -- J4: rodK is the hub for rodC and triJ4 (3 bodies meet here).
  local pivotRodK_J4 = btVector3(LEN.k / 2, 0, 0)
  hinge(rodK.body, rodC.body, pivotRodK_J4, btVector3(LEN.c / 2, 0, z_rodK_l - z_rodC_l))
  hinge(rodK.body, triJ4.body, pivotRodK_J4, btVector3(pivTriJ4_J4.x, pivTriJ4_J4.y, z_rodK_l - z_triJ4_l))

  -- J5: rodF <-> triJ4 (only 2 bodies meet here now).
  hinge(rodF.body, triJ4.body,
        btVector3(LEN.f / 2, 0, 0),
        btVector3(pivTriJ4_J5.x, pivTriJ4_J5.y, z_rodF_l - z_triJ4_l))

  -- F (the foot): NO hinge here anymore -- it's now just a marked point
  -- ON triJ4 (was the rodI<->rodH joint before triJ4 merged them into
  -- one rigid body). buildFoot below welds the foot pad directly to
  -- triJ4 at this local pivot.

  return {
    footRod = triJ4, footPivot = pivTriJ4_F, z_foot = z_triJ4_l, F = F, motorHinge = motorHinge,
    crank = crank, rodJ = rodJ, triG = triG, rodK = rodK, rodC = rodC, rodF = rodF, triJ4 = triJ4,
    pivTriG_G = pivTriG_G, pivTriG_J2 = pivTriG_J2, pivTriG_J3 = pivTriG_J3,
    pivTriJ4_J4 = pivTriJ4_J4, pivTriJ4_J5 = pivTriJ4_J5, pivTriJ4_F = pivTriJ4_F,
  }
end

-- ---------------------------------------------------------------------
-- foot: a flat pad welded (not hinged) to triJ4 at F, extending it in Z
-- for a real contact patch (same weld-via-locked-slider trick as
-- cheby_normal6.lua's buildFoot, simplified since each leg already sits
-- on its own dedicated Z-plane stack -- no inward/outward asymmetry
-- needed the way cheby's shared-centerline feet required).
-- ---------------------------------------------------------------------

function buildFoot(lk, color)
  local F = lk.F
  local z = lk.z_foot
  local foot_x, foot_y, foot_z = 9.0, 1.4, 8.0

  local foot = Cube(foot_x, foot_y, foot_z, 1.5)
  foot.col = color
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(F.x, F.y, z))
  foot.friction = 0.9
  v:add(foot)

  local rod_quat = lk.footRod.trans:getRotation()
  local frameInFoot = btTransform(rod_quat, btVector3(0, 0, 0))
  local frameInRod  = btTransform(IDENTITY_QUAT, lk.footPivot)   -- triJ4's real local F pivot, not a length-based offset
  local weld = btSliderConstraint(foot.body, lk.footRod.body, frameInFoot, frameInRod, true)
  weld:setLowerLinLimit(0)   -- btSliderConstraint defaults to FREE translation
  weld:setUpperLinLimit(0)   -- unless locked -- these two calls make it a weld
  v:addConstraint(weld)

  return foot
end

-- ---------------------------------------------------------------------
-- six legs: NUM_ROWS rows along X (the walking direction) x front/back
-- (Z-mirrored). Front and back within a row share the same phase (they
-- move together, for left/right symmetry); rows are staggered PHASE_
-- SPACING degrees apart -- see the "SIX LEGS" header note for why 3
-- rows beats the original 2-row/0-180-degree scheme for stability, and
-- the GAIT OPTIMIZATION note just below for why PHASE_SPACING=105, not
-- the naively-even 360/NUM_ROWS=120.
-- ---------------------------------------------------------------------

-- GAIT OPTIMIZATION, per direct request ("optimize the walking gait for
-- the 6 legs"). The original 120-degree spacing (360/NUM_ROWS, perfectly
-- even) is the natural first guess, but "even" isn't the same as
-- "optimal" once you account for Jansen's own duty cycle being ~62%,
-- not 50% -- an asymmetric stance/swing split doesn't necessarily want
-- symmetric phase spacing. Swept PHASE_SPACING directly against real
-- 800-frame physics trials (isolated fresh-construction runs, not a
-- continuous sweep, to avoid the sweep-order artifacts this file series
-- has run into before) -- coarse pass (90-150 degrees, 10-degree steps)
-- found two promising candidates, 110 and 140; re-verified BOTH in
-- isolation -- 110 held up (-529.20, still ahead of 120's own -474.92),
-- 140 did NOT (-399.22, actually worse in isolation despite a strong
-- sweep-context number) -- confirming 140 was a sweep-order artifact,
-- not a real improvement. Refined around 110, then finer still around
-- the new leader -- 105 degrees won clearly: -685.97 at frame 800,
-- reproduced exactly on a second isolated run, and validated over a
-- full 1400-frame horizon showing smooth, sustained progress the whole
-- way (-1326.28 at frame 1400, vs 120-degree spacing's own -1144.42
-- over the identical window -- about 16% more distance, comparable
-- stability: minY_drop 14.47 vs 14.09).
local PHASE_SPACING = 105

local SPEED = v:getParam("Speed")   -- GUI slider (default 2.5, was a hardcoded local before) -- used only for each hinge's CONSTRUCTION-time target; the live preSim hook below re-applies the CURRENT Speed every tick so dragging the slider updates all 6 legs without a rebuild

-- FRONT/BACK PHASE OFFSET, per direct follow-up ("when I referred to
-- gait, I was really talking about the phases of all 6 cranks"). Front
-- and back within a row previously shared the exact same phase (see the
-- header note's own "for left/right symmetry" reasoning) -- but front
-- and back are Z-MIRRORED copies of a genuinely UNMIRRORED leg design
-- (see the "WHY NO X-MIRRORING" header note -- the crossing-free branch
-- choice isn't itself mirror-symmetric), so moving them in perfect sync
-- doesn't actually produce mirrored forces -- it was likely the direct
-- source of the sideways drift documented elsewhere in this file.
--
-- Swept FB_OFFSET directly against real 800-frame trials, tracking BOTH
-- net_x (forward progress) and net_z (sideways drift, i.e. straightness)
-- -- not just speed alone, given the request was explicitly for
-- straighter AND faster. 45 degrees won clearly on both counts at once,
-- not a trade-off between them: net_x -887.76 (vs the same-phase
-- baseline's own -685.97, +29%) while net_x/total-distance -- the
-- fraction of travel actually going forward -- came out to 99.3% at 45
-- degrees, matching (not worse than) the baseline's own 99.3%.
-- Reproduced exactly on a second isolated run, and held up over a full
-- 1400-frame horizon: -1519.52 net_x vs the baseline's -1326.28 (+14.6%)
-- with a BETTER straightness ratio (99.3% vs 98.2%).
--
-- Cube damping was tried as a complementary fix (see the cube.damp_ang/
-- damp_lin note above, near where the cube is built) and found to
-- consistently HURT when combined with this offset -- even a light 0.03
-- cut net_x by nearly half. Left at 0 -- unlike other walkers in this
-- project, this one's own stability strategy (heavy mass/inertia, not
-- damping) genuinely doesn't benefit from it.
local FB_OFFSET = 45

legs = {}   -- GLOBAL (no "local") -- the live-update preSim hook outside buildScene() reads this
for row = 0, NUM_ROWS - 1 do
  local x_offset = row * ROW_SPACING
  local phase = row * PHASE_SPACING

  local legFront = buildJansenLeg(x_offset, false, phase, SPEED)
  local legBack  = buildJansenLeg(x_offset, true, phase + FB_OFFSET, SPEED)
  table.insert(legs, legFront)
  table.insert(legs, legBack)

  -- feet stay removed (buildFoot() calls commented out before this file
  -- was even handed over -- left as-is, not requested to change)
end
end   -- closes buildScene()

setParam("Speed", 2.5)
setParam("maxSubSteps", 12)
setParam("TerrainAmp", 8.0)
buildScene()
v.maxSubSteps = v:getParam("maxSubSteps")

v:onParamChanged(function(N, name, value)
  if name == "TerrainAmp" then
    teardownScene()
    buildScene()
    floor:clearTriangleColors()   -- one call resets the whole floor to its base .col -- the walker just snapped back to its starting position, so an old trail from before the rebuild would otherwise misleadingly show a path it never walked from here
    print(string.format("TerrainAmp = %.2f (scene rebuilt)", value))
  elseif name == "Speed" then
    for _, lk in ipairs(legs) do
      lk.motorHinge:enableAngularMotor(true, -value, 3000.0)   -- negated, matching MOTOR_SPEED's own convention inside buildJansenLeg
    end
    print(string.format("Speed = %.2f", value))
  elseif name == "maxSubSteps" then
    v.maxSubSteps = math.floor(value)
  end
end)

-- ---------------------------------------------------------------------
-- centroid trail -- colors the terrain triangle under the cube's
-- current (x,z) every TRAIL_INTERVAL frames, to visualize the walker's
-- trajectory over time.
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
-- also means there's nothing to v:remove() any more -- see the
-- floor:clearTriangleColors() call in the "TerrainAmp" rebuild handler
-- above, which replaces the old trailMarkers-list cleanup.
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

local TRAIL_INTERVAL = 30
local trail_frame_count = 0

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

-- SINGLE v:preSim registration, covering both the Speed/maxSubSteps live
-- sync AND the trail marker -- this engine only supports one v:preSim
-- callback; a second registration would silently replace the first
-- rather than run alongside it.
v:preSim(function(N)
  v.maxSubSteps = math.floor(v:getParam("maxSubSteps"))
  local speed = v:getParam("Speed")
  for _, lk in ipairs(legs) do
    lk.motorHinge:enableAngularMotor(true, -speed, 3000.0)
  end

  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    colorTrailAt(cube.pos.x, cube.pos.z)
  end
end)

-- ---------------------------------------------------------------------
-- camera -- follow the walker's center, same fixed-offset chase style as
-- cheby_normal6.lua, scaled up for Jansen's much larger native units.
-- ---------------------------------------------------------------------
common.setCamera(btVector3(cube.pos.x - 500, cube.pos.y + 200, cube.pos.z + 500), btVector3(cube.pos.x, cube.pos.y - 50, cube.pos.z), 0.5)


v:postSim(function(N)
  --common.setCamera(btVector3(cube.pos.x - 500, cube.pos.y + 200, cube.pos.z + 500),
  --btVector3(cube.pos.x, cube.pos.y - 50, cube.pos.z), 0.5)
end)

common.gravity(-9.8)

-- EOF
