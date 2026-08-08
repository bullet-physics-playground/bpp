--
-- Demo: DNA double helix + RNA polymerase transcription
--
-- A DNA strand is a polymer of nucleotides (phosphate + deoxyribose sugar +
-- base). The alternating phosphate/sugar groups form each strand's
-- "backbone"; two antiparallel backbones wind into a double helix, held
-- together by hydrogen bonds between complementary bases: adenine=thymine
-- (A=T, 2 bonds) and guanine#cytosine (G#C, 3 bonds).
--
-- This scene builds that double helix as fixed (mass 0) geometry -- spheres
-- for bases, cylinders for the backbone and for the hydrogen-bond rungs
-- (thicker rung = G-C's extra bond) -- and then genuinely simulates
-- transcription with real Bullet physics: a kinematic "RNA polymerase"
-- marker travels up the helix reading the template strand, and for every
-- base pair it passes, a new mRNA nucleotide (a real dynamic rigid body,
-- colored by its base -- note thymine is replaced by uracil, U) is spawned
-- and linked with a btPoint2PointConstraint to the previous one. The
-- growing mRNA is a real physics chain, anchored at its 5' end, and sags
-- under gravity as Bullet simulates it -- it is not just an animation.
--
-- Usage: bpp -n 400 -f demo/koppi/dna-transcription.lua
--

local color  = require "color"
local common = require "common"

math.randomseed(42) -- reproducible template strand

-- gentle gravity so the mRNA chain sags without whipping around
common.setTiming(1/25, 30, 1/120)
common.gravity(-9.81)

--
-- Biology tables
--

-- DNA base pairing (Watson-Crick): A-T and G-C
local DNA_COMPLEMENT = { A = "T", T = "A", G = "C", C = "G" }
-- Transcription rule: template base -> mRNA base (thymine is replaced by uracil)
local TRANSCRIBE     = { A = "U", T = "A", G = "C", C = "G" }

local BASE_COLOR = {
  A = "#22cc55",
  T = "#dd3333",
  G = "#ddaa11",
  C = "#3366ee",
  U = "#bb33cc",
}
local BACKBONE_COL     = "#999999"
local RNA_BACKBONE_COL = "#cc99dd"
local BUBBLE_COL       = "#eeeeee" -- locally "melted" open helix
local POLYMERASE_COL   = "#ff8800"

--
-- Helix geometry (roughly to scale with real B-DNA: ~10.5 bp/turn, 0.34
-- rise per bp; radius/sphere sizes are stylized for readability)
--

local NBP          = 32          -- number of base pairs
local RISE         = 0.34        -- vertical rise per base pair
local TWIST        = 2 * math.pi / 10.5  -- radians per base pair
local RADIUS       = 1.0         -- helix radius
local BASE_R       = 0.16        -- nucleotide sphere radius
local BACKBONE_R   = 0.05        -- backbone cylinder radius

-- Random template strand; strand 2 is its Watson-Crick complement.
local BASES = { "A", "T", "G", "C" }
local strand1 = {}
for i = 1, NBP do
  strand1[i] = BASES[math.random(1, 4)]
end

--
-- SCENE SETUP
--

-- World-space position of nucleotide `strand` (1 or 2) at base-pair index i.
local function basePos(i, strand)
  local angle = (i - 1) * TWIST
  if strand == 2 then angle = angle + math.pi end
  local y = (i - 1) * RISE
  return btVector3(RADIUS * math.cos(angle), y, RADIUS * math.sin(angle))
end

-- Pushes a point further out, away from the helix's central (vertical) axis,
-- used to place the emerging mRNA strand clear of the DNA geometry.
local outwardOffset = common.outwardOffset

-- Quaternion that rotates a Cylinder's local +Z axis to point from p1 to p2
-- (see common.orientBetween), plus a fixed cylinder spanning p1..p2.
-- Defined here so the whole helix reads as one block of placeCylinder calls.
local placeCylinder = common.placeCylinder

-- Build the double helix: two backbones of colored nucleotide spheres,
-- linked to their neighbor by a backbone cylinder, plus a hydrogen-bond
-- rung between each base pair (thicker for G-C's third bond).
local baseSpheres1, baseSpheres2 = {}, {}

local function baseColor1(i) return BASE_COLOR[strand1[i]] end
local function baseColor2(i) return BASE_COLOR[DNA_COMPLEMENT[strand1[i]]] end

for i = 1, NBP do
  local pos1, pos2 = basePos(i, 1), basePos(i, 2)

  local s1 = Sphere(BASE_R, 0)
  s1.col = baseColor1(i)
  s1.pos = pos1
  v:add(s1)
  baseSpheres1[i] = s1

  local s2 = Sphere(BASE_R, 0)
  s2.col = baseColor2(i)
  s2.pos = pos2
  v:add(s2)
  baseSpheres2[i] = s2

  local rungRadius = (strand1[i] == "A" or strand1[i] == "T") and 0.035 or 0.05
  placeCylinder(pos1, pos2, rungRadius, "#dddddd")

  if i > 1 then
    placeCylinder(basePos(i - 1, 1), pos1, BACKBONE_R, BACKBONE_COL)
    placeCylinder(basePos(i - 1, 2), pos2, BACKBONE_R, BACKBONE_COL)
  end
end

-- RNA polymerase: a purely visual, kinematic (mass 0) marker repositioned
-- every simulation step as it "reads" the template strand.
local polymerase = Cube(1.6, 0.5, 1.6, 0)
polymerase.col = POLYMERASE_COL
polymerase.pos = basePos(1, 1)
v:add(polymerase)

-- mRNA chain anchor (mass 0, fixed): the 5' end of the growing transcript.
local mrnaAnchor = Sphere(0.1, 0)
mrnaAnchor.col = RNA_BACKBONE_COL
mrnaAnchor.pos = outwardOffset(basePos(1, 1), 0.8)
v:add(mrnaAnchor)

local lastMrnaBody = mrnaAnchor
local BUBBLE = 2 -- how many base pairs on either side of the polymerase stay "open"

-- Reads base pair i off the template strand and grows the mRNA chain by one
-- real, dynamic, constrained nucleotide.
local function transcribeBasePair(i)
  local templateBase = strand1[i]
  local rnaBase = TRANSCRIBE[templateBase]

  local nuc = Sphere(0.13, 0.05)
  nuc.col = BASE_COLOR[rnaBase]
  nuc.pos = outwardOffset(basePos(i, 1), 0.8)
  v:add(nuc)

  local con = btPoint2PointConstraint(lastMrnaBody.body, nuc.body,
                                       btVector3(0, 0, 0), btVector3(0, 0, 0))
  v:addConstraint(con)
  lastMrnaBody = nuc

  print(string.format("Transcribing bp %d/%d: template=%s -> mRNA=%s",
                       i, NBP, templateBase, rnaBase))
end

-- preStart: Called once before simulation starts
v:preStart(function(N)
  print("preStart(" .. tostring(N) .. ")")
  print("Template strand (5'->3'): " .. table.concat(strand1))
end)

v:addParam("transcriptionRate", 0.12, 0.02, 0.5) -- base pairs per simulation step

local lastTranscribed = 0
local transcriptionAnnounced = false

-- postSim: Called after each simulation step. Advances the polymerase,
-- highlights the locally "open" (unwound) region of the helix, and
-- transcribes any base pairs the polymerase has newly passed.
v:postSim(function(N)
  local rate = v:getParam("transcriptionRate")
  local center = math.min(NBP, 1 + math.floor((N - 1) * rate))

  polymerase.pos = basePos(center, 1)

  for i = 1, NBP do
    if i >= center - BUBBLE and i <= center + BUBBLE then
      baseSpheres1[i].col = BUBBLE_COL
      baseSpheres2[i].col = BUBBLE_COL
    else
      baseSpheres1[i].col = baseColor1(i)
      baseSpheres2[i].col = baseColor2(i)
    end
  end

  while lastTranscribed < center do
    lastTranscribed = lastTranscribed + 1
    transcribeBasePair(lastTranscribed)
  end

  if lastTranscribed == NBP and not transcriptionAnnounced then
    local mrna = {}
    for i = 1, NBP do mrna[i] = TRANSCRIBE[strand1[i]] end
    print("Transcription complete: mRNA (5'->3') = " .. table.concat(mrna))
    transcriptionAnnounced = true
  end
end)

-- preDraw: slow orbiting camera around the helix
v:preDraw(function(N)
  local t = N * 0.01
  common.setCamera(btVector3(9 * math.cos(t), 6, 9 * math.sin(t)),
                   btVector3(0, 5, 0), 0.5)
end)

-- EOF
