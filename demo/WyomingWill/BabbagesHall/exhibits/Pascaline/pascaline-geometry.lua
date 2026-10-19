-- pascaline-geometry.lua -- Babbage's Hall, the Pascaline
--
-- Every moving part's shape, as primitives with masses, in one place: the
-- simulation builds its bodies from these, and make-stls.sh writes them out
-- for OpenSCAD (parts/geometry.scad), which builds the printed parts from
-- the same primitives. So what is printed is what was simulated.
--
-- The machine as you face it (cm): x to the right, y up, z toward you. The
-- digits' axles run along z at height Y0; units on the right (x = 0), tens
-- and hundreds to the left, D apart. A digit turns CLOCKWISE (as you see
-- it) to count up. Behind each digit's pins is its snail cam; behind the
-- cams, in planes of their own, the sautoirs (one for each carry).
--
-- Primitives: { "box", cx, cy, cz, sx, sy, sz, mass }
--             { "cylz", cx, cy, cz, r, h, mass }        (a cylinder along z)
--             { "hull", { {x,y,z}, ... }, mass, cx, cy, cz } (cx..: where its mass is)
--
-- Every number here was tuned in the simulation (see FINDINGS.md).

local G = {}

G.ND = 3                      -- digits: units, tens, hundreds
G.D = 11.0                    -- the axles' spacing (cams of radius R1 must clear their neighbours and the carriers)
G.Y0 = 0                      -- the axles' height, in the machine's own frame
G.STEP = 36                   -- degrees a digit turns per unit

-- a digit: ten pins round a circle, and (except the last) its snail cam
G.RP, G.PIN_R = 2.4, 0.25     -- the pins' circle, their radius
G.PZ0, G.PZ1 = 0.0, 1.0       -- the pins' z range
G.CZ0, G.CZ1 = -1.6, -0.6     -- the cam's
G.R0, G.R1 = 1.5, 5.0         -- the snail: radius at 0, at its top (the pawl clears the pins by digit 7)
G.PSID = 350                  -- ... rising over this many degrees of the digit's turn, then dropping back
G.DIGIT_MASS = 0.03           -- (a digit's moving parts: wheel, pins, cam, axle, dial)

-- the sautoirs: lever i rides on digit i's cam and kicks digit i+1
G.PA = 10.0                   -- its pivot, this far left of digit i+1's axle, at the axles' height
G.NOSE_R = 0.3                -- the follower's nose
G.NOSEGAP = 0.05              -- (the nose starts this far above the cam)
G.WEIGHT = 0.06               -- the sautoir's weight (kg): a steel weight on a bolt
G.HX, G.HY = 3.4, 1.4         -- the pawl's hinge, from digit i+1's axle
G.TIPX, G.TIPY = 2.25, -0.17  -- the pawl's tip at rest, from digit i+1's axle
G.TAIL = 0.008                -- the pawl's tail weight (kg): it holds the pawl against its stop
G.PAWL_LO, G.PAWL_HI = -50, 0 -- the pawl's swing (degrees): it yields one way only

-- the click on each digit (a spring detent, simulated as a weak pull to the
-- nearest unit): its stiffness and its strength
G.CLICK_K, G.CLICK_IMP = 30, 0.03

function G.xd(i) return -i * G.D end
local function zPlane(i) return -2.1 - 1.2 * i end    -- lever i's plane (behind the cams, staggered)
G.zPlane = zPlane

-- a digit's primitives, in its own frame (its axle along z through the
-- origin, its 0 at the top)
function G.digit(i)
  local P = {}
  local pm = 0.0006
  for k = 0, 9 do
    local a = math.rad(90 + k * G.STEP)
    P[#P + 1] = { "cylz", G.RP * math.cos(a), G.RP * math.sin(a), (G.PZ0 + G.PZ1) / 2, G.PIN_R, G.PZ1 - G.PZ0, pm }
  end
  if i < G.ND - 1 then
    -- the snail: at the digit's angle psi (counterclockwise from the top, in
    -- its own frame) its radius is R0 + (R1 - R0) psi / PSID, up to PSID,
    -- then R0 again; in convex wedges
    local NW = 36
    local function r(psi) if psi <= G.PSID then return G.R0 + (G.R1 - G.R0) * psi / G.PSID end return G.R0 end
    local function pt(psi, rr) local a = math.rad(90 + psi); return rr * math.cos(a), rr * math.sin(a) end
    local function wedge(p0, r0, p1, r1)
      local ax, ay = pt(p0, r0)
      local bx, by = pt(p1, r1)
      local pts = {}
      for _, z in ipairs({ G.CZ0, G.CZ1 }) do
        pts[#pts + 1] = { 0, 0, z }; pts[#pts + 1] = { ax, ay, z }; pts[#pts + 1] = { bx, by, z }
      end
      P[#P + 1] = { "hull", pts, 0.0004, (ax + bx) / 3, (ay + by) / 3, (G.CZ0 + G.CZ1) / 2 }
    end
    for k = 0, NW - 1 do
      local p0, p1 = k * 360 / NW, (k + 1) * 360 / NW
      if p1 <= G.PSID then wedge(p0, r(p0), p1, r(p1))
      elseif p0 >= G.PSID then wedge(p0, G.R0, p1, G.R0)
      else
        wedge(p0, r(p0), G.PSID, G.R1)
        wedge(G.PSID, G.R0, p1, G.R0)
      end
    end
  end
  return P
end

-- lever i (the sautoir for the carry from digit i to digit i+1), in the
-- machine's frame at rest, and where it turns
function G.lever(i)
  local Y0, xd = G.Y0, G.xd
  local zc = zPlane(i)
  local px, py = xd(i + 1) - G.PA, Y0
  local fx = xd(i)
  local noseY = Y0 + G.R0 + G.NOSE_R + G.NOSEGAP
  local L = fx - px
  local P = {
    { "box", px + L / 2, py, zc, L + 0.3, 0.6, 0.6, 0.010 },                          -- the arm, at the axles' height
    { "box", fx, (py + noseY) / 2, zc, 0.4, noseY - py, 0.6, 0.003 },                -- the follower's strut
    { "cylz", fx, noseY, (zc - 0.3 + G.CZ1) / 2, G.NOSE_R, G.CZ1 - (zc - 0.3), 0.002 },  -- its nose, reaching the cam
    { "box", fx - 1.5, py, zc, 1.2, 1.2, 0.6, G.WEIGHT },                            -- the weight
  }
  -- the pawl's carrier: up outside digit i+1's cam, forward to the pins'
  -- plane, in to the pawl's hinge
  local ax, hy = xd(i + 1) + G.HX, Y0 + G.HY
  local cx = xd(i + 1) + G.R1 + 0.6
  local pz = (G.PZ0 + G.PZ1) / 2
  P[#P + 1] = { "box", cx, (py + hy) / 2, zc, 0.5, hy - py + 0.25, 0.5, 0.002 }
  P[#P + 1] = { "box", cx, hy, (zc + pz + 1.0) / 2, 0.5, 0.5, pz + 1.0 - zc + 0.25, 0.002 }   -- (on to meet the bar in)
  P[#P + 1] = { "box", (cx + ax) / 2, hy, pz + 0.75, cx - ax + 0.25, 0.5, 0.5, 0.001 }
  return P, { x = px, y = py, z = zc }, { x = ax, y = hy, z = pz }
end

-- pawl i, in the machine's frame at rest, and its hinge
function G.pawl(i)
  local Y0, xd = G.Y0, G.xd
  local ax, hy = xd(i + 1) + G.HX, Y0 + G.HY
  local pz = (G.PZ0 + G.PZ1) / 2
  local tipx, tipy = xd(i + 1) + G.TIPX, Y0 + G.TIPY
  local P = {
    { "box", tipx, tipy, pz, 0.7, 0.6, 0.8, 0.001 },                                 -- the tip
    { "hull", { { tipx + 0.2, tipy + 0.3, pz - 0.3 }, { tipx + 0.2, tipy + 0.3, pz + 0.3 },
                { ax + 0.2, hy + 0.2, pz - 0.3 }, { ax + 0.2, hy + 0.2, pz + 0.3 },
                { ax - 0.2, hy - 0.2, pz - 0.3 }, { ax - 0.2, hy - 0.2, pz + 0.3 },
                { tipx - 0.2, tipy - 0.1, pz - 0.3 }, { tipx - 0.2, tipy - 0.1, pz + 0.3 } },
      0.001, (tipx + ax) / 2, (tipy + hy) / 2, pz },                                  -- the link
    { "box", ax + 0.9, hy, pz, 1.4, 0.6, 0.6, G.TAIL },                              -- the tail weight (its mass at ax + 0.9; the block reaches back to the link)
  }
  return P, { x = ax, y = hy, z = pz }
end

-- where a primitive's mass is
function G.centre(p)
  if p[1] == "hull" then return p[4], p[5], p[6], p[3] end
  if p[1] == "box" then return p[2], p[3], p[4], p[8] end
  return p[2], p[3], p[4], p[7]                                                         -- cylz
end

return G
