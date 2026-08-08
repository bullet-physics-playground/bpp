--
-- Demo: DNA double helix + semi-conservative replication, with quantitative
-- kinetics, fidelity and ARCH x Phi origin-initiation gating
--
-- Replication happens before every cell division, so each new cell gets an
-- exact copy of the DNA. It is semi-conservative: each of the two original
-- ("parental") strands serves as a template for one new strand, so each of
-- the two resulting double helices ends up half old strand, half newly
-- synthesized strand. The simulation walks through the four phases of
-- replication (Initiation, Priming, Elongation, Termination -- see the
-- fork/origin machinery below), and layers three quantitative models on
-- top of that mechanical picture:
--
--   1. Elongation kinetics: fork velocity is not constant. It follows
--      Michaelis-Menten enzyme kinetics, v = Vmax*[dNTP] / (Km+[dNTP]).
--      Vmax is organism-dependent (E. coli ~1000 nt/s, human ~50 nt/s);
--      if the free nucleotide pool [dNTP] runs low, v drops sharply. Both
--      are live Lua params (eukaryote, dNTP_uM) -- lower dNTP_uM while the
--      demo runs to watch every active fork visibly slow down.
--   2. Fidelity, from real thermodynamics: incorporating a dNTP is driven
--      forward by DG_total = DG_hydrolysis + DG_pairing + DG_conformation,
--      all favorable (PPi release/hydrolysis, -30 to -40 kJ/mol, alone
--      makes it essentially irreversible), so *some* base always gets
--      added -- what determines whether it is the *correct* one is
--      DG_pairing, computed genuinely per real dinucleotide step from the
--      standard nearest-neighbor duplex-stacking table (SantaLucia 1998;
--      see NN_STACKING_KJ), which ranges from about -2.4 kJ/mol for a weak
--      A-T-rich step up to -9.4 kJ/mol for a strong G-C-rich one -- the
--      same instability that makes A-T-rich stretches favored replication
--      origins. Polymerase discriminates correct from incorrect pairing
--      via the free-energy gap DDG between them; a representative
--      DDG~11-17 kJ/mol, run through the Boltzmann relation
--      k_incorrect/k_correct = exp(-DDG/RT) at 37 C, gives an intrinsic
--      misincorporation rate of roughly 1 in 300 to 1000 -- thermodynamics
--      alone, before any enzyme does a thing. This demo genuinely computes
--      that ratio per real synthesized dinucleotide step (see
--      pickBaseWithFidelity/stackingDG), amplified by thermoAmplification
--      purely so a mutation is visible within a few hundred steps; real
--      cells then reach the final 10^-9 to 10^-10 error rate via kinetic
--      (induced-fit) selectivity and 3'->5' exonuclease proofreading --
--      modeled here as the live proofreadingEfficiency param.
--   3. Origin initiation (ARCH x Phi model, Rahman 2025, "A multiplicative
--      behavioral model of DNA replication initiation in cells", Open Life
--      Sciences 20): each origin fires only once its readiness product
--      R = Phi(t) * A_i * D(t) * C_i crosses a threshold T, where A_i is
--      the origin's fixed licensing architecture (ORC/MCM occupancy),
--      C_i its fixed chromatin accessibility (euchromatin vs.
--      heterochromatin), D(t) the shared, live-tunable metabolic/kinase
--      drive (CDK activity x [dNTP] availability -- reusing dNTP_uM from
--      the kinetics model above, since real Drive really is gated by the
--      same nucleotide pool), and Phi(t) the shared cell-cycle phase
--      permissiveness, which ramps up like a G1->S transition and can be
--      slammed toward zero with the dnaDamageCheckpoint param to model a
--      reversible DNA-damage-checkpoint arrest. Because the product is
--      multiplicative, any single term collapsing to zero categorically
--      blocks initiation (the model's "zero-term veto"), and two
--      partially-reduced terms together suppress firing more than either
--      alone (its predicted synergistic/supra-additive inhibition) -- see
--      pickBaseWithFidelity's sibling below, the origins-loop in postSim,
--      for the live R_i(t) computation. If a fork from an already-fired
--      neighboring origin reaches an origin's position before its own R_i
--      crosses T, that origin is "passively replicated" and never gets
--      its own fork. Firing itself is gated behind an explicit licensing
--      step modeled after real pre-replication-complex (pre-RC) assembly:
--      ORC marks each origin's sequence from frame 1, then Cdc6/Cdt1 load
--      the MCM2-7 double hexamer -- a ring-shaped helicase -- around the
--      duplex a short, fixed delay later (see LICENSING_STEP); only once
--      an origin is licensed is its R_i(t) even evaluated against T, and
--      firing itself represents Cdc45/GINS joining the loaded hexamers to
--      form two active CMG helicases, which is what actually splits into
--      the two bidirectional forks below.
--
--      Each origin that does fire spawns two independent
--      forks, one walking toward increasing bp index and one toward
--      decreasing bp index (real origins fire bidirectionally, opening a
--      "replication bubble" that grows in both directions) -- each with
--      its own topoisomerase and helicase markers, its own leading
--      (continuous) and lagging (Okazaki-fragmented) daughter-strand
--      physics chains, all governed by the same shared Michaelis-Menten
--      rate and fidelity model above.
--
-- The double helix itself is built out of small-mass nucleotide spheres,
-- each tethered by a btPoint2PointConstraint to a fixed anchor at its rest
-- position (see tetherToRestPosition) and nudged every step by a small
-- random force (see the thermal wobble preSim below) -- like molecules
-- jiggling around their lattice positions in a liquid. The whole assembly
-- also spins slowly around its own vertical axis (see rotateSceneGeometry
-- in the postSim callback): every fixed anchor and decorative cylinder is
-- rotated in place each step, and the dynamic bases/daughter strands
-- simply follow along through their existing tether/chain constraints.
-- Both daughter strands are real, gravity-sagging physics chains, drawn
-- growing outward from their own template, one on each side of the
-- original helix, rather than the whole helix visually splitting in two.
--
-- Usage: bpp -n 600 -f demo/koppi/dna-replication.lua
--

local color  = require "color"
local common = require "common"

math.randomseed(12) -- reproducible; chosen for a clean, readable template strand

common.setTiming(1/25, 30, 1/120)
common.gravity(-9.81)

--
-- POV-Ray blob rendering: every Sphere() in this demo goes through
-- MoleculeBlob() (or its single-atom shorthand, BlobSphere()) so its
-- exported frames use a POV "blob" object (a metaball isosurface) instead
-- of a plain sphere primitive, via the pre_sdl hook that overrides the
-- default "sphere { ... }" opening text -- pigment, transform matrix and
-- closing brace still come from the normal object defaults, so only the
-- primitive type changes. A blob's visible surface sits INSIDE its
-- component sphere's own radius (POV's field function reaches 0 at that
-- radius and only equals `threshold` partway in), so BLOB_R_SCALE inflates
-- each component radius just enough that the rendered blob still matches
-- the object's real (interactive-view) size.
--
-- MoleculeBlob goes one step further: its `atoms` argument lists several
-- sub-spheres, each offset/sized as a multiple of the object's own physics
-- radius in its own local frame, so they all still move and rotate
-- together as the single rigid body Sphere() creates. The result reads as
-- a small cluster of fused atoms loosely resembling the real molecule's
-- shape -- a bent water triatomic, a nucleotide's ring, ATP's
-- head-and-tail -- instead of a featureless sphere. Physics (the collision
-- radius/mass Sphere() is actually built with) is entirely unaffected;
-- only what POV-Ray draws changes.
--
-- The same trick replaces every cylinder in this demo too: BlobCylinder()
-- builds a fixed Cylinder() body whose exported shape is a blob rod -- an
-- array of blob component spheres strung along the cylinder's local +Z axis
-- (the axis a cylinder already rests along), spaced tightly enough that the
-- metaball fields stay above threshold between neighbors and the whole thing
-- reads as one smooth, slightly beaded strand rather than the default POV
-- `cylinder { }` primitive. Backbones, rungs and the MCM2-7 ring markers are
-- all drawn this way; their lengths, orientations and mass are unchanged.
--
local BLOB_THRESHOLD = 0.6
local BLOB_R_SCALE = 1 / math.sqrt(1 - math.sqrt(BLOB_THRESHOLD))

local function MoleculeBlob(radius, mass, atoms)
  local obj = Sphere(radius, mass)
  local parts = { string.format("blob {\n  threshold %.3f", BLOB_THRESHOLD) }
  for _, a in ipairs(atoms) do
    parts[#parts + 1] = string.format(
      "  sphere { <%.5f,%.5f,%.5f>, %.5f, 1 }",
      radius * a[1], radius * a[2], radius * a[3], radius * a[4] * BLOB_R_SCALE)
  end
  obj.pre_sdl = table.concat(parts, "\n")
  return obj
end

local SINGLE_ATOM = { { 0, 0, 0, 1.0 } }
local ION_ATOMS   = SINGLE_ATOM -- a bare ion (Mg2+) genuinely is just one atom

local function BlobSphere(radius, mass)
  return MoleculeBlob(radius, mass, SINGLE_ATOM)
end

-- The cylinder equivalent of MoleculeBlob: a plain Cylinder physics body
-- whose POV-Ray export is a blob rod -- `n` component spheres of the
-- cylinder's radius strung down its local +Z axis from -depth/2 to
-- +depth/2 (exactly where the default `cylinder { ... }` primitive would
-- run), spaced close enough that the fields fuse into one smooth bead of a
-- strand. The physics object underneath is still an ordinary Cylinder of
-- the same radius/depth, so lengths, masses, orientations and every
-- reposition/rotation call below are completely unaffected.
local BLOB_ROD_SPACING = 0.5 -- center-to-center spacing of the bead spheres, as a fraction
                             -- of each bead's blob radius (BLOB_R_SCALE * radius)

local function BlobCylinder(radius, depth, mass)
  local obj = Cylinder(radius, depth, mass)
  local beadR = radius * BLOB_R_SCALE
  local n = math.max(2, math.ceil(depth / (beadR * BLOB_ROD_SPACING)) + 1)
  local parts = { string.format("blob {\n  threshold %.3f", BLOB_THRESHOLD) }
  for k = 1, n do
    local z = -depth / 2 + (k - 1) * (depth / (n - 1))
    parts[#parts + 1] = string.format("  sphere { <0,0,%.5f>, %.5f, 1 }", z, beadR)
  end
  obj.pre_sdl = table.concat(parts, "\n")
  return obj
end

-- n atoms evenly spaced around a ring of radius `ringR` (a multiple of the
-- eventual object's physics radius), each of radius `atomR`, centered at
-- (cx, cy) in the object's local XY plane -- the building block for both
-- base-ring shapes below.
local function ringAtomsAt(n, ringR, atomR, cx, cy)
  local atoms = {}
  for k = 0, n - 1 do
    local a = k * (2 * math.pi / n)
    atoms[#atoms + 1] = { cx + ringR * math.cos(a), cy + ringR * math.sin(a), 0, atomR }
  end
  return atoms
end

-- A pyrimidine base (T, C): one real six-membered ring, drawn as 5 fused
-- atoms.
local PYRIMIDINE_ATOMS = ringAtomsAt(5, 0.85, 0.55, 0, 0)

-- A purine base (A, G): two real fused rings (six- and five-membered) --
-- visibly bigger and more complex than a pyrimidine's single ring, same as
-- the real chemistry.
local PURINE_ATOMS = {}
for _, a in ipairs(ringAtomsAt(4, 0.62, 0.48, -0.55, 0)) do PURINE_ATOMS[#PURINE_ATOMS + 1] = a end
for _, a in ipairs(ringAtomsAt(5, 0.75, 0.48, 0.5, 0))  do PURINE_ATOMS[#PURINE_ATOMS + 1] = a end

-- Picks the right ring shape for a base letter -- used for every base
-- sphere below, whether on the original helix or freshly synthesized.
local function baseAtoms(letter)
  if letter == "A" or letter == "G" then return PURINE_ATOMS end
  return PYRIMIDINE_ATOMS
end

-- Water (H2O): one large O atom plus two smaller H atoms at the real
-- ~104.5-degree bond angle.
local WATER_ATOMS = {
  { 0, 0, 0, 1.0 },
  { 0.60, 0.98, 0, 0.5 },
  { 0.60, -0.98, 0, 0.5 },
}

-- ATP: a small adenine (purine) ring, a ribose, and a triphosphate tail,
-- strung out along local X -- an elongated head-and-tail shape rather than
-- a round blob, like the real molecule.
local ATP_ATOMS = {}
for _, a in ipairs(ringAtomsAt(4, 0.4, 0.32, -1.35, 0)) do ATP_ATOMS[#ATP_ATOMS + 1] = a end
for _, a in ipairs(ringAtomsAt(5, 0.5, 0.32, -0.85, 0)) do ATP_ATOMS[#ATP_ATOMS + 1] = a end
ATP_ATOMS[#ATP_ATOMS + 1] = { -0.15, 0, 0, 0.55 } -- ribose
ATP_ATOMS[#ATP_ATOMS + 1] = { 0.45, 0, 0, 0.55 }  -- phosphate, alpha
ATP_ATOMS[#ATP_ATOMS + 1] = { 1.0, 0.1, 0, 0.55 } -- phosphate, beta
ATP_ATOMS[#ATP_ATOMS + 1] = { 1.55, 0, 0, 0.55 }  -- phosphate, gamma

-- A generic globular protein: an irregular multi-lobe cluster -- real
-- proteins fold into multi-domain globular shapes, not smooth spheres.
local PROTEIN_ATOMS = {
  { 0, 0, 0, 1.0 }, { 0.55, 0.35, 0.15, 0.75 }, { -0.45, 0.4, -0.3, 0.7 },
  { 0.2, -0.5, 0.35, 0.7 }, { -0.35, -0.3, -0.45, 0.65 },
}

-- A small protein domain: two fused lobes, reused below for the helicase
-- ring's subunits, each enzyme cluster's individual domains, and the SSB
-- markers -- enough to read as "protein" without PROTEIN_ATOMS' extra cost
-- repeated dozens of times a frame.
local PROTEIN_DOMAIN_ATOMS = {
  { 0, 0, 0, 1.0 }, { 0.5, 0.3, 0.25, 0.7 }, { -0.3, -0.35, 0.2, 0.6 },
}

--
-- Biology tables
--

-- DNA base pairing (Watson-Crick): A-T and G-C. Used both to build the
-- original double helix and, during replication, to synthesize each new
-- strand from its template.
local DNA_COMPLEMENT = { A = "T", T = "A", G = "C", C = "G" }

-- Base and backbone colors sampled directly from yourgenome.org's DNA
-- structure render (20-c0379432, "molecular machines at a replication
-- fork"): a sage green, brick red, olive gold and navy blue for the four
-- bases, and a light steel blue-gray for the sugar-phosphate backbone.
local BASE_COLOR = {
  A = "#5a9666",
  T = "#8f3a3a",
  G = "#84824c",
  C = "#2f3d94",
}
local BACKBONE_COL     = "#8aabaf" -- template helix backbone
local LEADING_STRAND_COL = "#e0a030" -- leading-strand (continuous) daughter backbone, amber
local LAGGING_STRAND_COL = "#30a0a0" -- lagging-strand (Okazaki) daughter backbone, teal
local PRIMER_COL       = "#ff44aa" -- short RNA primer, before it is replaced by DNA
local HELICASE_COL     = "#eeeeee"
local TOPO_COL         = "#66ddcc" -- topoisomerase, leads the fork
local SSB_COL          = "#f5f0b0" -- single-strand binding proteins
local MUTATION_COL     = "#111111" -- an uncorrected replication error
local PRIMASE_COL      = "#ff8800" -- primase, lays each RNA primer
local POLYMERASE_COL   = "#5599ff" -- DNA polymerase, actively extending a strand
local EXONUCLEASE_COL  = "#aa4477" -- 5'->3' exonuclease, removes each RNA primer
local LIGASE_COL       = "#ccdd33" -- DNA ligase, welds Okazaki fragments together

--
-- 1. Elongation kinetics (Michaelis-Menten): v = Vmax*[dNTP] / (Km+[dNTP]).
-- TIME_SCALE compresses real nt/s into bp/simulation-step purely so a
-- 1000 nt/s fork doesn't finish a 48 bp toy helix in a single frame -- the
-- *shape* of the response (organism choice, [dNTP] scarcity) is unaffected.
--
local VMAX_PROKARYOTE_NT_S = 1000 -- E. coli, nt/s
local VMAX_EUKARYOTE_NT_S  = 50   -- human, nt/s
local KM_DNTP               = 10  -- representative Michaelis constant, uM
local TIME_SCALE            = 0.09 -- tuned so the default (eukaryote, dNTP_uM=40) pace
                                    -- covers the 48 bp helix in a few hundred steps

--
-- 2. Fidelity thermodynamics. See the header comment above for the overall
-- picture; GAS_CONSTANT_J_MOL_K/TEMPERATURE_K/MISMATCH_DDG_KJ feed the
-- Boltzmann selectivity ratio, DG_REFERENCE_KJ is the stacking strength
-- MISMATCH_DDG_KJ was calibrated against, and NN_STACKING_KJ is the real
-- nearest-neighbor duplex-step table DG_pairing is looked up from.
--
local GAS_CONSTANT_J_MOL_K = 8.314   -- R, J/(mol*K)
local TEMPERATURE_K        = 310.15  -- 37 C, physiological
local DG_HYDROLYSIS_KJ     = -35     -- representative dNTP -> dNMP + PPi, within -30..-40
local DG_CONFORMATION_KJ   = -4      -- representative induced-fit closure contribution
local MISMATCH_DDG_KJ      = 15      -- representative correct-vs-incorrect penalty, 11-17 range
local DG_REFERENCE_KJ      = -6      -- stacking strength MISMATCH_DDG_KJ is calibrated against

-- Nearest-neighbor duplex-step stacking free energies at 37 C, kJ/mol
-- (SantaLucia 1998 unified NN parameters, kcal/mol x 4.184). Keyed by the
-- two bases read 5'->3' on one strand of the step; a step and its reverse
-- complement (the same physical duplex step read from the other strand)
-- share one value, e.g. AA==TT, CA==TG, CG is its own palindrome, etc.
local NN_STACKING_KJ = {
  AA = -4.18, TT = -4.18,
  AT = -3.68,
  TA = -2.43,
  CA = -6.07, TG = -6.07,
  GT = -6.03, AC = -6.03,
  CT = -5.36, AG = -5.36,
  GA = -5.44, TC = -5.44,
  CG = -9.08,
  GC = -9.37,
  GG = -7.70, CC = -7.70,
}

--
-- 3. ARCH x Phi origin initiation: where origins sit, each one's fixed
-- licensing (A_i) and chromatin (C_i) readiness, and the shared threshold
-- T that Phi(t)*A_i*D(t)*C_i must cross to fire. A_i/C_i step down from
-- origin to origin (strong, euchromatic -> weak, heterochromatic) purely
-- to illustrate the model's own "early vs. late S-phase domains" claim:
-- higher-A*C origins cross T earlier and so replicate earlier, without
-- needing a separate timing mechanism.
--
local ORIGIN_INDICES  = { 6, 24, 42 }
local ORIGIN_A        = { 0.9, 0.8, 0.7 }  -- A_i: origin-licensing architecture (ORC/MCM)
local ORIGIN_C        = { 0.9, 0.7, 0.5 }  -- C_i: chromatin accessibility (euchromatin->hetero)
local INIT_THRESHOLD  = 0.12   -- T: minimum R = Phi*A*D*C required to fire
local PHI_RAMP_STEPS  = 150    -- simulation steps for Phi to ramp 0 -> 1 (G1 -> S)
local CHECKPOINT_PHI  = 0.02   -- Phi is clamped to this while dnaDamageCheckpoint is set
local DRIVE_NOISE     = 0.01   -- small per-step jitter on D(t), for realism (not bias)
local ORIGIN_COL      = "#ff9922" -- marks every origin, before it fires
local LICENSING_STEP  = 15     -- steps for Cdc6/Cdt1 to load the MCM2-7 double hexamer
local ORC_COL         = "#8855cc" -- Origin Recognition Complex: binds the origin sequence
local MCM_COL         = "#ccaaff" -- MCM2-7 double hexamer: the loaded, still-inactive helicase ring

--
-- Helix geometry (roughly to scale with real B-DNA: ~10.5 bp/turn, 0.34
-- rise per bp; radius/sphere sizes are stylized for readability)
--

local NBP           = 48          -- number of base pairs
local RISE          = 0.34        -- vertical rise per base pair
local TWIST         = 2 * math.pi / 10.5  -- radians per base pair
local RADIUS        = 1.0         -- helix radius
local BASE_R        = 0.16        -- nucleotide sphere radius
local BACKBONE_R    = 0.05        -- backbone cylinder radius
local RUNG_R_WEAK    = 0.035      -- rung cylinder radius, A-T's two hydrogen bonds
local RUNG_R_STRONG  = 0.05       -- rung cylinder radius, G-C's three hydrogen bonds
local FRAGMENT_SIZE = 5           -- nucleotides per Okazaki fragment
local WOBBLE_MASS   = 0.03        -- tiny mass so each base can be nudged by small forces
local SSB_LOOKAHEAD = 3           -- bp topoisomerase/helicase stay ahead of the polymerases
local HELICASE_SUBUNIT_COUNT = 6  -- the CMG helicase is modeled as a hexameric ring
local HELICASE_SUBUNIT_R     = 0.2
local HELICASE_RING_R        = 0.55 -- ring radius, matching the pre-fired MCM marker's size
local ENZYME_MARKER_DURATION = 20 -- steps a transient enzyme marker (primase/exonuclease/
                                   -- ligase) stays visible before it is removed
local ROTATION_SPEED = 0.006      -- radians the whole helix turns per simulation step

-- Current spin of the whole helix around its own vertical (Y) axis, updated
-- once per postSim step below. Every position derived from basePos() is
-- rotated by this angle (via rotateY) before being applied to an object.
local rotationAngle = 0

-- Rotates pos by `angle` radians around the vertical (Y) axis.
local rotateY = common.rotateY

-- Clamps a bp index into the valid [1, NBP] range.
local function clampBp(i)
  return math.max(1, math.min(NBP, i))
end

-- True while `pos` still has ground to cover before reaching `target`,
-- walking in direction `dir` (+1 = increasing bp index, -1 = decreasing).
-- Used by both fork machinery loops below, since every fork walks outward
-- from its origin in one or the other direction.
local function towardBoundary(pos, target, dir)
  return (dir > 0 and pos < target) or (dir < 0 and pos > target)
end

-- Standard normal sample via the Box-Muller transform, used to add a small
-- realistic jitter to the ARCH x Phi model's Drive term D(t) each step.
local function gaussianRandom()
  local u1 = math.max(math.random(), 1e-12)
  local u2 = math.random()
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
end

-- Random template strand 1; strand 2 is its Watson-Crick complement. Both
-- serve as templates during replication (semi-conservative).
local BASES = { "A", "T", "G", "C" }
local strand1 = {}
for i = 1, NBP do
  strand1[i] = BASES[math.random(1, 4)]
end
local function strand2Base(i) return DNA_COMPLEMENT[strand1[i]] end

-- Fixes each origin's ARCH x Phi licensing (A_i) and chromatin (C_i)
-- readiness once, up front. Whether and when each one actually fires is
-- decided live in postSim, once Phi(t) and D(t) are known, and only after
-- it has been licensed (see LICENSING_STEP and the pre-RC markers below).
local origins = {}
for k, index in ipairs(ORIGIN_INDICES) do
  origins[k] = {
    index = index,
    A = ORIGIN_A[k],
    C = ORIGIN_C[k],
    resolved = false,
    licensed = false,
    orcMarker = nil,
    mcmMarker = nil,
  }
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

-- Point on the helix's own central (vertical) axis at base-pair index i --
-- where pre-RC proteins (ORC, the MCM2-7 double hexamer) sit, since they
-- encircle the whole duplex rather than binding to one strand's side. A
-- rotation about that same axis (rotateY) leaves such a point fixed, so
-- these markers need no per-frame repositioning as the helix spins.
local function originAxisPos(i)
  return btVector3(0, (i - 1) * RISE, 0)
end

-- Pushes a point further out, away from the helix's central (vertical) axis,
-- used to place each new daughter strand clear of the original DNA geometry.
local outwardOffset = common.outwardOffset

-- Quaternion that rotates a Cylinder's local +Z axis (its default, resting
-- orientation, see Cylinder::renderInLocalFrame) to point from p1 to p2, so
-- a Cylinder(radius, length, 0) placed at their midpoint spans exactly
-- between them.
local orientBetween = common.orientBetween

-- Orientation for a Cylinder standing with its axis vertical (along global
-- Y), computed once and reused for every MCM2-7 double-hexamer ring marker
-- below, so each one reads as a flat collar encircling the helix's own
-- vertical axis rather than a cylinder lying on its side.
local VERTICAL_RING_ROT = orientBetween(btVector3(0, 0, 0), btVector3(0, 1, 0))

-- Places a fixed (mass 0) blob rod spanning p1..p2 and returns it -- the
-- blob-rendered stand-in for common.placeCylinder (see BlobCylinder). The
-- orientation from orientBetween, the midpoint placement, and the rigid
-- repositionCylinder updates in rotateSceneGeometry all work exactly the
-- same, because the object underneath is still a plain Cylinder.
local function placeBlobCylinder(p1, p2, radius, col)
  local rot, len, mid = orientBetween(p1, p2)
  if len < 1e-6 then return nil end
  local cy = BlobCylinder(radius, len, 0.01)
  cy.col = col
  cy.trans = btTransform(rot, mid)
  v:add(cy)
  return cy
end

-- Re-orients an already-placed cylinder to span p1..p2 (its length is
-- fixed at creation, but rotateY is a rigid transform, so the distance
-- between any two rotated points never changes -- only its position and
-- orientation need updating). Used to spin the helix's backbone/rung
-- cylinders in place; see rotateSceneGeometry below.
local repositionCylinder = common.repositionCylinder

-- Rebuilds a daughter-strand backbone cylinder to freshly span its two
-- endpoint objects' current live positions. Unlike repositionCylinder,
-- this cannot just reorient the existing shape: a Cylinder's length is
-- baked into its collision shape at construction, but the endpoints here
-- are real dynamic (or anchor) bodies whose separation genuinely changes
-- as the chain sags/wobbles, not just rigidly rotates -- a stale fixed
-- length would leave the cylinder visibly dangling short of, or jutting
-- past, the bases it is meant to connect. `record` is one entry of a
-- fork's leadBackbone/lagBackbone list: { cy=, a=, b= }.
local function updateDynamicBackbone(record)
  if record.cy ~= nil then
    v:remove(record.cy)
  end
  record.cy = placeBlobCylinder(record.a.pos, record.b.pos, BACKBONE_R, BACKBONE_COL)
end

-- Tethers `nuc` to a fixed, invisible-sized anchor at its rest position
-- `pos` with a btPoint2PointConstraint. A point2point constraint with both
-- pivots at each body's own origin locks the two origins together exactly
-- (zero play), which would make `nuc` immovable -- a pure central force
-- has no lever arm to fight a fully rigid position lock. Softening it with
-- a nonzero CFM (constraint force mixing) turns it into a spring-like
-- tether instead: it still pulls `nuc` back toward `pos`, but lets small
-- forces (see the thermal wobble preSim below) visibly displace it first,
-- which is what makes the helix wobble like molecules jiggling around
-- their lattice positions in a liquid, rather than sagging apart or being
-- welded rigidly in place. DISABLE_DEACTIVATION keeps `nuc` from falling
-- asleep between nudges (a sleeping body ignores applied forces).
local function tetherToRestPosition(nuc, pos)
  local anchor = BlobSphere(0.02, 0)
  anchor.col = nuc.col
  anchor.pos = pos
  v:add(anchor)
  local con = btPoint2PointConstraint(anchor.body, nuc.body,
                                       btVector3(0, 0, 0), btVector3(0, 0, 0))
  con:setParam(3, 0.8, -1) -- BT_CONSTRAINT_CFM, axis -1 = all axes
  v:addConstraint(con)
  nuc.body:setActivationState(4) -- DISABLE_DEACTIVATION
  return anchor
end

-- Builds the hydrogen-bond "rung" between base1 (template strand 1) and
-- base2 (template strand 2) at a bp as two colored cylinders meeting at
-- the midpoint -- one per base, each colored to match its own base, so
-- the rung visually blends from one base's color to its complement's
-- (thicker for G-C's third hydrogen bond). Returns { cy1=, cy2=, col1=,
-- col2=, r= }; see updateRungCylinders/removeRungCylinders.
local function createRungCylinders(pos1, pos2, col1, col2, radius)
  local mid = btVector3((pos1.x + pos2.x) * 0.5, (pos1.y + pos2.y) * 0.5, (pos1.z + pos2.z) * 0.5)
  local cy1 = placeBlobCylinder(pos1, mid, radius, col1)
  local cy2 = placeBlobCylinder(mid, pos2, radius, col2)
  return { cy1 = cy1, cy2 = cy2, col1 = col1, col2 = col2, r = radius }
end

-- Rebuilds a rung's two cylinders to freshly span the two bases' current
-- live positions. Like updateDynamicBackbone, this recreates rather than
-- reorients: the bases wobble independently, so both the cylinders'
-- lengths and the shared midpoint they meet at genuinely change frame to
-- frame, not just rotate rigidly.
local function updateRungCylinders(rung, pos1, pos2)
  if rung == nil then return end
  if rung.cy1 ~= nil then v:remove(rung.cy1) end
  if rung.cy2 ~= nil then v:remove(rung.cy2) end
  local mid = btVector3((pos1.x + pos2.x) * 0.5, (pos1.y + pos2.y) * 0.5, (pos1.z + pos2.z) * 0.5)
  rung.cy1 = placeBlobCylinder(pos1, mid, rung.r, rung.col1)
  rung.cy2 = placeBlobCylinder(mid, pos2, rung.r, rung.col2)
end

local function removeRungCylinders(rung)
  if rung == nil then return end
  if rung.cy1 ~= nil then v:remove(rung.cy1) end
  if rung.cy2 ~= nil then v:remove(rung.cy2) end
end

-- World-space positions of each subunit in a hexameric CMG-helicase ring
-- centered on `axisPos` (the helix's own central axis at the fork's
-- current position -- see forkLivePos/originAxisPos), rotated by the
-- helix's current spin angle so the ring turns along with everything else.
local function helicaseRingPositions(axisPos, angle)
  local positions = {}
  for k = 1, HELICASE_SUBUNIT_COUNT do
    local a = (k - 1) * (2 * math.pi / HELICASE_SUBUNIT_COUNT)
    local localPos = btVector3(axisPos.x + HELICASE_RING_R * math.cos(a), axisPos.y,
                                axisPos.z + HELICASE_RING_R * math.sin(a))
    positions[k] = rotateY(localPos, angle)
  end
  return positions
end

-- A small stylized multi-sphere "enzyme" marker: a tight, fixed-shape
-- cluster of small spheres around a moving center point, used below for
-- primase/DNA polymerase/exonuclease/ligase markers -- all real
-- multi-subunit protein complexes rather than single points.
local ENZYME_CLUSTER_OFFSETS = {
  { 0.00, 0.00, 0.00 }, { 0.20, 0.10, 0.05 }, { -0.16, 0.13, -0.09 },
  { 0.06, -0.17, 0.11 }, { -0.11, -0.09, -0.16 }, { 0.16, -0.06, 0.13 },
}

local function createEnzymeCluster(pos, col, sphereR, count)
  local spheres = {}
  for k = 1, count do
    local off = ENZYME_CLUSTER_OFFSETS[k]
    local s = MoleculeBlob(sphereR, 0, PROTEIN_DOMAIN_ATOMS)
    s.col = col
    s.pos = btVector3(pos.x + off[1], pos.y + off[2], pos.z + off[3])
    v:add(s)
    spheres[#spheres + 1] = s
  end
  return spheres
end

local function repositionEnzymeCluster(cluster, pos)
  if cluster == nil then return end
  for k, s in ipairs(cluster) do
    local off = ENZYME_CLUSTER_OFFSETS[k]
    s.pos = btVector3(pos.x + off[1], pos.y + off[2], pos.z + off[3])
  end
end

local function removeEnzymeCluster(cluster)
  if cluster == nil then return end
  for _, s in ipairs(cluster) do v:remove(s) end
end

-- Transient enzyme markers (primase, exonuclease, ligase) that flash at
-- the site of their action and disappear again -- unlike the persistent,
-- fork-tracking helicase/polymerase markers. `currentStep` is refreshed
-- once per postSim call; spawnTimedEnzyme reads it directly so callers
-- deep inside the fork machinery do not need to thread N through.
local currentStep = 0
local timedMarkers = {} -- { cluster=, removeAtStep= }

local function spawnTimedEnzyme(pos, col, sphereR, count)
  local cluster = createEnzymeCluster(pos, col, sphereR, count)
  timedMarkers[#timedMarkers + 1] = { cluster = cluster, removeAtStep = currentStep + ENZYME_MARKER_DURATION }
end

local function updateTimedMarkers()
  local i = 1
  while i <= #timedMarkers do
    if currentStep >= timedMarkers[i].removeAtStep then
      removeEnzymeCluster(timedMarkers[i].cluster)
      table.remove(timedMarkers, i)
    else
      i = i + 1
    end
  end
end

-- Build the original double helix: two backbones of colored nucleotide
-- spheres linked to their neighbor by a backbone cylinder, plus a
-- hydrogen-bond rung between each base pair -- two colored cylinders
-- meeting at the midpoint (see createRungCylinders), thicker for G-C's
-- third bond. Rungs, backbone cylinders and each base's tether anchor are
-- all kept in tables: rungs so a fork can remove them one at a time as it
-- unwinds the strand (see removeRungCylinders), baseSpheres1/2 so
-- rotateSceneGeometry can rebuild each rung from the bases' real, live
-- (wobbling) positions every frame, and the rest so it can spin the whole
-- assembly in place. Every base is also collected into `wobblers` so it
-- can be jostled by a small thermal-like force every step, making the
-- whole helix wobble gently like a liquid rather than sitting perfectly
-- rigid.
local rungs = {}
local backbone1, backbone2 = {}, {}
local anchor1, anchor2 = {}, {}
local baseSpheres1, baseSpheres2 = {}, {}
local wobblers = {}

for i = 1, NBP do
  local pos1, pos2 = basePos(i, 1), basePos(i, 2)

  local s1 = MoleculeBlob(BASE_R, WOBBLE_MASS, baseAtoms(strand1[i]))
  s1.col = BASE_COLOR[strand1[i]]
  s1.pos = pos1
  v:add(s1)
  anchor1[i] = tetherToRestPosition(s1, pos1)
  wobblers[#wobblers + 1] = s1
  baseSpheres1[i] = s1

  local s2 = MoleculeBlob(BASE_R, WOBBLE_MASS, baseAtoms(strand2Base(i)))
  s2.col = BASE_COLOR[strand2Base(i)]
  s2.pos = pos2
  v:add(s2)
  anchor2[i] = tetherToRestPosition(s2, pos2)
  wobblers[#wobblers + 1] = s2
  baseSpheres2[i] = s2

  local rungR = (strand1[i] == "A" or strand1[i] == "T") and RUNG_R_WEAK or RUNG_R_STRONG
  rungs[i] = createRungCylinders(pos1, pos2, BASE_COLOR[strand1[i]], BASE_COLOR[strand2Base(i)], rungR)

  if i > 1 then
    backbone1[i] = placeBlobCylinder(basePos(i - 1, 1), pos1, BACKBONE_R, BACKBONE_COL)
    backbone2[i] = placeBlobCylinder(basePos(i - 1, 2), pos2, BACKBONE_R, BACKBONE_COL)
  end
end

-- Mark each origin's rung bright orange so it is visible from frame 1, and
-- place its ORC (Origin Recognition Complex) marker -- ORC binding its
-- sequence is essentially immediate, unlike the slower MCM2-7 loading that
-- follows it later in postSim (see LICENSING_STEP).
for _, o in ipairs(origins) do
  if rungs[o.index] ~= nil then
    local rung = rungs[o.index]
    rung.col1, rung.col2 = ORIGIN_COL, ORIGIN_COL
    if rung.cy1 ~= nil then rung.cy1.col = ORIGIN_COL end
    if rung.cy2 ~= nil then rung.cy2.col = ORIGIN_COL end
  end
  local orc = Cube(0.2, 0.2, 0.2, 0)
  orc.col = ORC_COL
  orc.pos = originAxisPos(o.index)
  v:add(orc)
  o.orcMarker = orc
end

--
-- Background molecular crowding: real cells are packed with far more than
-- DNA and its replication machinery. A representative slice of that --
-- water forming the hydration shell that keeps the helix thermodynamically
-- stable, Mg2+ shielding the backbone's phosphate charges and serving as
-- polymerase's two-metal-ion cofactor, the free dNTP/ATP pool (ATP being
-- the most abundant, since nearly every DNA-processing enzyme consumes
-- it), and a generic stand-in for the crowd of DNA-scanning proteins
-- (transcription factors, repair enzymes, remodelers) -- floats and
-- jitters around the helix. Each is a real dynamic body, exempted from
-- world gravity and given damping so it does not simply fall or fly off,
-- nudged every preSim step by a small random (Brownian-like) force plus a
-- weak spring back toward its own random "home" point, so it drifts and
-- jiggles in place nearby rather than raining down or wandering away.
--
local FLOATING_MASS      = 0.01
local FLOATING_HOME_PULL = 0.4    -- spring constant pulling back toward home
local CLOUD_MIN_R        = 2.0    -- stays clear of the helix + daughter strands
local CLOUD_MAX_R        = 3.2
local SHELL_MIN_R        = RADIUS + 0.15 -- water hugs the helix's own surface
local SHELL_MAX_R        = RADIUS + 0.5
local WATER_COL          = "#cfe9ff"
local MG_COL             = "#77ee88" -- Mg2+, conventionally green in molecular viewers
local ATP_COL            = "#ffcc22"
local PROTEIN_COL        = "#df9aa0" -- generic transcription factor / repair enzyme / remodeler --
                                      -- salmon, sampled from the reference image's protein complexes

local function randomCloudPos(minR, maxR)
  local r = minR + math.random() * (maxR - minR)
  local theta = math.random() * 2 * math.pi
  local y = math.random() * (NBP - 1) * RISE
  return btVector3(r * math.cos(theta), y, r * math.sin(theta))
end

local floatingMolecules = {}

local function spawnFloatingMolecule(radius, col, minR, maxR, atoms)
  local home = randomCloudPos(minR, maxR)
  local m = MoleculeBlob(radius, FLOATING_MASS, atoms or ION_ATOMS)
  m.col = col
  m.pos = home
  v:add(m)
  m.body:setGravity(btVector3(0, 0, 0))
  m.body:setDamping(0.7, 0.7)
  m.body:setActivationState(4) -- DISABLE_DEACTIVATION
  floatingMolecules[#floatingMolecules + 1] = { obj = m, home = home }
end

for _ = 1, 50 do
  spawnFloatingMolecule(0.05, WATER_COL, SHELL_MIN_R, SHELL_MAX_R, WATER_ATOMS)
end
for _ = 1, 14 do
  spawnFloatingMolecule(0.06, MG_COL, CLOUD_MIN_R, CLOUD_MAX_R, ION_ATOMS)
end
for _ = 1, 30 do
  local dntpBase = BASES[math.random(1, 4)]
  spawnFloatingMolecule(0.09, BASE_COLOR[dntpBase], CLOUD_MIN_R, CLOUD_MAX_R, baseAtoms(dntpBase))
end
for _ = 1, 20 do
  spawnFloatingMolecule(0.11, ATP_COL, CLOUD_MIN_R, CLOUD_MAX_R, ATP_ATOMS)
end
for _ = 1, 6 do
  spawnFloatingMolecule(0.22, PROTEIN_COL, CLOUD_MIN_R, CLOUD_MAX_R, PROTEIN_ATOMS)
end

--
-- Fidelity model (see header comment for the thermodynamic derivation).
-- Every synthesized nucleotide's intrinsic misincorporation odds are
-- computed fresh from the real local stacking context, then rolled
-- against the live thermoAmplification/proofreadingEfficiency params.
--
local mutationStats = { attempted = 0, caught = 0, escaped = 0 }
local totalPairingEnergyKJ = 0 -- running DG_pairing of the two new strands, for the final summary

-- Nearest-neighbor stacking DG for the duplex step formed by `prevBase`
-- (the last base already incorporated on this new strand) followed by
-- `base`. Right after a primer there is no real DNA-DNA stacking context
-- yet (the primer is RNA), so fall back to DG_REFERENCE_KJ, an unbiased
-- midpoint between the weakest and strongest real steps.
local function stackingDG(prevBase, base)
  if prevBase == nil then return DG_REFERENCE_KJ end
  return NN_STACKING_KJ[prevBase .. base]
end

local function pickBaseWithFidelity(correctBase, prevBase)
  local proofreadEff = v:getParam("proofreadingEfficiency")
  local thermoAmp = v:getParam("thermoAmplification")

  -- DG_pairing for the correct step, genuinely computed from the actual
  -- local sequence context. Stronger stacking (more negative DG, e.g. a
  -- G-C-rich step) locks the correct base in harder, widening the
  -- effective DDG polymerase has to work with; weaker stacking (A-T-rich,
  -- the same instability that makes A-T-rich stretches favored
  -- replication origins) narrows it, letting more mismatches slip past
  -- selection -- both ends of this range stay within the representative
  -- 11-17 kJ/mol span the header comment cites.
  local dgCorrect = stackingDG(prevBase, correctBase)
  local effectiveDDG = MISMATCH_DDG_KJ + (DG_REFERENCE_KJ - dgCorrect) * 0.5
  local ratio = math.exp(-(effectiveDDG * 1000) / (GAS_CONSTANT_J_MOL_K * TEMPERATURE_K))
  local pThermo = math.min(1, ratio * thermoAmp)

  if math.random() >= pThermo then
    totalPairingEnergyKJ = totalPairingEnergyKJ + dgCorrect
    return correctBase, false -- correct base selected first try, nothing to proofread
  end

  mutationStats.attempted = mutationStats.attempted + 1
  if math.random() < proofreadEff then
    mutationStats.caught = mutationStats.caught + 1
    totalPairingEnergyKJ = totalPairingEnergyKJ + dgCorrect
    return correctBase, false -- exonuclease removed the mismatch before it stuck
  end

  mutationStats.escaped = mutationStats.escaped + 1
  local wrongOptions = {}
  for _, b in ipairs(BASES) do
    if b ~= correctBase then wrongOptions[#wrongOptions + 1] = b end
  end
  return wrongOptions[math.random(1, #wrongOptions)], true
end

--
-- Fork + origin machinery (phases 1-4, per fork). Each element of `forks`
-- owns its own topoisomerase/helicase markers and its own leading/lagging
-- daughter-strand chains; `claimedUnwind`/`claimedSynth` are shared across
-- all forks so two forks converging on the same bp only process it once.
--
local forks = {}
local claimedUnwind = {}
local claimedSynth = {}

-- Melts a freshly fired origin's own rung (that is what "firing" means) and
-- marks its bp as already unwound, before its two forks are spawned. Safe
-- to call once per origin even though two forks both start from here.
local function meltOrigin(originIndex)
  removeRungCylinders(rungs[originIndex])
  rungs[originIndex] = nil
  claimedUnwind[originIndex] = true
end

-- Spawns one of a freshly fired origin's two forks, walking in direction
-- `dir` (+1 = toward increasing bp index, -1 = toward decreasing). Each
-- fork gets its own topoisomerase marker and a multi-sphere hexameric
-- CMG-helicase ring (see helicaseRingPositions), and starts with its own
-- leading-strand primer (phase 2) at the origin. DNA polymerase markers
-- for each strand are created lazily (see extendLeadingStrand/
-- extendLaggingStrand) once there is actually a primer for them to bind.
local function createFork(originIndex, dir)
  local topo = Cone(0.3, 0.7, 0)
  topo.col = TOPO_COL
  topo.pos = rotateY(basePos(originIndex, 1), rotationAngle)
  v:add(topo)

  local helicaseSpheres = {}
  local ringPositions = helicaseRingPositions(originAxisPos(originIndex), rotationAngle)
  for k = 1, HELICASE_SUBUNIT_COUNT do
    local hs = MoleculeBlob(HELICASE_SUBUNIT_R, 0, PROTEIN_DOMAIN_ATOMS)
    hs.col = HELICASE_COL
    hs.pos = ringPositions[k]
    v:add(hs)
    helicaseSpheres[k] = hs
  end

  local leadAnchor = MoleculeBlob(0.1, 0, PYRIMIDINE_ATOMS)
  leadAnchor.col = PRIMER_COL
  leadAnchor.pos = rotateY(outwardOffset(basePos(originIndex, 1), 0.8), rotationAngle)
  v:add(leadAnchor)
  -- Primase lays this leading-strand primer too -- the very first one at
  -- this origin -- exactly like it does for every lagging-strand
  -- Okazaki fragment later (see extendLaggingStrand).
  spawnTimedEnzyme(leadAnchor.pos, PRIMASE_COL, 0.08, 4)

  return {
    startIndex = originIndex,
    dir = dir,                        -- +1 or -1, which way this fork walks
    boundary = dir > 0 and NBP or 1,  -- bp index where this fork terminates
    pos = originIndex,           -- last bp index this fork has unwound
    unwoundProgress = 0,         -- fractional bp accumulator (Michaelis-Menten)
    synthPos = originIndex - dir, -- last bp index this fork has synthesized
    unwinding = true,            -- false once it hits its boundary or meets another fork
    topoisomerase = topo,
    helicase = helicaseSpheres,  -- hexameric ring, one entry per subunit sphere
    leadAnchor = leadAnchor,
    leadChainEnd = leadAnchor,
    leadPrimerReplaced = false,
    leadPrevBase = nil, -- last base incorporated on the leading strand, for NN stacking context
    leadPolymerase = nil, -- DNA polymerase marker, created once the leading primer is bound
    lagPrimer = nil,
    lagChainEnd = nil,
    lagFragmentLen = 0,
    lagPrevBase = nil, -- resets to nil at each new Okazaki fragment's primer
    lagPolymerase = nil, -- DNA polymerase marker, follows each new lagging-strand primer
    lastLigatedEnd = nil,
    lagPrimers = {}, -- every primer this fork ever placed: {obj=sphere, i=bp}
    leadBackbone = {}, -- connecting cylinders for the leading strand: {cy=, a=, b=}
    lagBackbone = {},  -- same, for the lagging strand (incl. ligase-weld segments)
  }
end

-- Phase 2/3/4 for the leading strand (template: strand1), one nucleotide.
local function extendLeadingStrand(fork, i)
  if not fork.leadPrimerReplaced then
    fork.leadAnchor.col = LEADING_STRAND_COL
    fork.leadPrimerReplaced = true
    -- Exonuclease removes the RNA primer; DNA polymerase then binds right
    -- there and rides along the strand as it grows (see the reposition
    -- call below, run every time this strand gains a nucleotide).
    spawnTimedEnzyme(fork.leadAnchor.pos, EXONUCLEASE_COL, 0.06, 4)
    fork.leadPolymerase = createEnzymeCluster(fork.leadAnchor.pos, POLYMERASE_COL, 0.09, 5)
    print("DNA polymerase I replaces the leading strand's primer with DNA (fork from bp " ..
          fork.startIndex .. ")")
  end

  local correctBase = DNA_COMPLEMENT[strand1[i]]
  local base, isMutation = pickBaseWithFidelity(correctBase, fork.leadPrevBase)
  fork.leadPrevBase = base

  local nuc = MoleculeBlob(0.13, 0.05, baseAtoms(base))
  nuc.col = isMutation and MUTATION_COL or BASE_COLOR[base]
  nuc.pos = rotateY(outwardOffset(basePos(i, 1), 0.8), rotationAngle)
  v:add(nuc)
  if isMutation then
    print(string.format(
      "UNCORRECTED replication error at bp %d (leading strand): inserted %s instead of %s",
      i, base, correctBase))
  end

  local con = btPoint2PointConstraint(fork.leadChainEnd.body, nuc.body,
                                       btVector3(0, 0, 0), btVector3(0, 0, 0))
  v:addConstraint(con)
  local backbone = placeBlobCylinder(fork.leadChainEnd.pos, nuc.pos, BACKBONE_R, LEADING_STRAND_COL)
  fork.leadBackbone[#fork.leadBackbone + 1] = { cy = backbone, a = fork.leadChainEnd, b = nuc }
  fork.leadChainEnd = nuc
  repositionEnzymeCluster(fork.leadPolymerase, nuc.pos)
end

-- Phase 2/3/4 for the lagging strand (template: strand2), one nucleotide,
-- grouped into Okazaki fragments.
local function extendLaggingStrand(fork, i)
  if fork.lagPrimer == nil then
    fork.lagPrimer = MoleculeBlob(0.1, 0, PYRIMIDINE_ATOMS)
    fork.lagPrimer.col = PRIMER_COL
    fork.lagPrimer.pos = rotateY(outwardOffset(basePos(i, 2), 0.8), rotationAngle)
    v:add(fork.lagPrimer)
    fork.lagPrimers[#fork.lagPrimers + 1] = { obj = fork.lagPrimer, i = i }
    fork.lagChainEnd = fork.lagPrimer
    fork.lagFragmentLen = 0
    fork.lagPrevBase = nil -- new RNA primer boundary; no DNA-DNA stacking context yet
    -- Primase flashes at the new primer site; DNA polymerase then binds
    -- there too (creating the marker on this fork's first fragment,
    -- otherwise just moving the existing one to the new primer).
    spawnTimedEnzyme(fork.lagPrimer.pos, PRIMASE_COL, 0.08, 4)
    if fork.lagPolymerase == nil then
      fork.lagPolymerase = createEnzymeCluster(fork.lagPrimer.pos, POLYMERASE_COL, 0.09, 5)
    else
      repositionEnzymeCluster(fork.lagPolymerase, fork.lagPrimer.pos)
    end
    print("Primase lays an RNA primer for a new Okazaki fragment at bp " .. i ..
          " (fork from bp " .. fork.startIndex .. ")")
  end

  local correctBase = DNA_COMPLEMENT[strand2Base(i)]
  local base, isMutation = pickBaseWithFidelity(correctBase, fork.lagPrevBase)
  fork.lagPrevBase = base

  local nuc = MoleculeBlob(0.13, 0.05, baseAtoms(base))
  nuc.col = isMutation and MUTATION_COL or BASE_COLOR[base]
  nuc.pos = rotateY(outwardOffset(basePos(i, 2), 0.8), rotationAngle)
  v:add(nuc)
  if isMutation then
    print(string.format(
      "UNCORRECTED replication error at bp %d (lagging strand): inserted %s instead of %s",
      i, base, correctBase))
  end

  local con = btPoint2PointConstraint(fork.lagChainEnd.body, nuc.body,
                                       btVector3(0, 0, 0), btVector3(0, 0, 0))
  v:addConstraint(con)
  local backbone = placeBlobCylinder(fork.lagChainEnd.pos, nuc.pos, BACKBONE_R, LAGGING_STRAND_COL)
  fork.lagBackbone[#fork.lagBackbone + 1] = { cy = backbone, a = fork.lagChainEnd, b = nuc }
  fork.lagChainEnd = nuc
  fork.lagFragmentLen = fork.lagFragmentLen + 1
  repositionEnzymeCluster(fork.lagPolymerase, nuc.pos)

  if fork.lagFragmentLen >= FRAGMENT_SIZE or i == fork.boundary or
     (not fork.unwinding and i == fork.pos) then
    -- Phase 4 (Termination): exonuclease removes this fragment's RNA
    -- primer, DNA polymerase I fills the gap, then ligase welds it onto
    -- the previous fragment. (The (not fork.unwinding and i == fork.pos)
    -- check closes out the fragment early if this fork stopped unwinding
    -- mid-fragment, e.g. by meeting another fork, so no fragment is left
    -- permanently unfinished.)
    fork.lagPrimer.col = LAGGING_STRAND_COL
    spawnTimedEnzyme(fork.lagPrimer.pos, EXONUCLEASE_COL, 0.06, 4)
    print("DNA polymerase I replaces the RNA primer at bp " .. i .. " with DNA")
    if fork.lastLigatedEnd ~= nil then
      local ligaseCon = btPoint2PointConstraint(fork.lastLigatedEnd.body, fork.lagPrimer.body,
                                                 btVector3(0, 0, 0), btVector3(0, 0, 0))
      v:addConstraint(ligaseCon)
      local ligaseBackbone = placeBlobCylinder(fork.lastLigatedEnd.pos, fork.lagPrimer.pos,
                                            BACKBONE_R, LAGGING_STRAND_COL)
      fork.lagBackbone[#fork.lagBackbone + 1] =
        { cy = ligaseBackbone, a = fork.lastLigatedEnd, b = fork.lagPrimer }
      spawnTimedEnzyme(fork.lagPrimer.pos, LIGASE_COL, 0.08, 4)
      print("Ligase welds the Okazaki fragment ending at bp " .. i .. " onto the lagging strand")
    end
    fork.lastLigatedEnd = fork.lagChainEnd
    fork.lagPrimer = nil -- the next bp starts a fresh fragment
  end
end

-- preStart: Called once before simulation starts
v:preStart(function(N)
  print("preStart(" .. tostring(N) .. ")")
  print("Phase 1 Initiation:  topoisomerase + helicase unwind the helix, SSB proteins")
  print("                     coat the exposed single strands")
  print("Phase 2 Priming:     primase lays an RNA primer for polymerase to extend from")
  print("Phase 3 Elongation:  polymerase synthesizes 5'->3' -- continuous on the leading")
  print("                     strand, in Okazaki fragments on the lagging strand")
  print("Phase 4 Termination: polymerase I replaces primers with DNA, ligase welds the")
  print("                     Okazaki fragments into one continuous strand")
  print("")
  print(string.format(
    "1. Kinetics: v = Vmax*[dNTP]/(Km+[dNTP]); Vmax = %d nt/s (prokaryote) or %d nt/s " ..
    "(eukaryote), Km = %g uM -- tune eukaryote/dNTP_uM live to change fork speed",
    VMAX_PROKARYOTE_NT_S, VMAX_EUKARYOTE_NT_S, KM_DNTP))
  local referenceRatio = math.exp(-(MISMATCH_DDG_KJ * 1000) / (GAS_CONSTANT_J_MOL_K * TEMPERATURE_K))
  print(string.format(
    "2. Fidelity (thermodynamics): DG_pairing via nearest-neighbor stacking (%.2f to %.2f " ..
    "kJ/mol, A-T-rich to G-C-rich) sets DDG per real dinucleotide step; at DDG~%.0f kJ/mol, " ..
    "Boltzmann gives k_incorrect/k_correct = exp(-DDG/RT) ~ %.2e (~1 in %.0f) -- thermodynamics " ..
    "alone, before any enzyme acts. thermoAmplification scales this up so mutations are " ..
    "visible; proofreadingEfficiency is the enzymatic layer on top (cells reach 10^-9 to " ..
    "10^-10 only with both, plus mismatch repair, not modeled here)",
    NN_STACKING_KJ.TA, NN_STACKING_KJ.GC, MISMATCH_DDG_KJ, referenceRatio, 1 / referenceRatio))
  print(string.format(
    "   Overall: DG_total = DG_hydrolysis(%.0f) + DG_pairing(~%.0f) + DG_conformation(%.0f) " ..
    "~ %.0f kJ/mol -- strongly favorable, so PPi release/hydrolysis alone makes every " ..
    "incorporation essentially irreversible once a base is selected",
    DG_HYDROLYSIS_KJ, DG_REFERENCE_KJ, DG_CONFORMATION_KJ,
    DG_HYDROLYSIS_KJ + DG_REFERENCE_KJ + DG_CONFORMATION_KJ))
  print(string.format(
    "3. Origin initiation (ARCH x Phi model): fires bp when R=Phi(t)*A*D(t)*C >= T=%.2f; " ..
    "D(t)=cdkActivity*(dNTP_uM/100)+noise, Phi(t) ramps 0->1 over %d steps unless " ..
    "dnaDamageCheckpoint clamps it near 0 (reversible arrest)",
    INIT_THRESHOLD, PHI_RAMP_STEPS))
  for _, o in ipairs(origins) do
    print(string.format("   bp %d: A=%.2f (licensing), C=%.2f (chromatin accessibility)",
                         o.index, o.A, o.C))
  end
  print(string.format(
    "   Pre-RC assembly: ORC already bound every origin above at frame 1 (purple markers); " ..
    "Cdc6/Cdt1 load the MCM2-7 double hexamer -- a ring-shaped helicase -- around each " ..
    "duplex at step %d (lavender rings). Only a licensed origin's R_i(t) is evaluated " ..
    "against T; firing then means Cdc45/GINS join the hexamers into two active CMG " ..
    "helicases, which is what actually splits into the bidirectional forks.",
    LICENSING_STEP))
  print(string.format(
    "   Background: %d floating molecules jitter around the helix -- water (hydration " ..
    "shell), Mg2+ (backbone charge shielding + polymerase cofactor), free dNTP/ATP pool, " ..
    "and generic DNA-scanning proteins (transcription factors, repair enzymes) -- tune " ..
    "brownianForce live to see them jostle more or less",
    #floatingMolecules))
  print("")
  print("Strand 1 (template for the lagging daughter, 5'->3'): " .. table.concat(strand1))
  local s2 = {}
  for i = 1, NBP do s2[i] = strand2Base(i) end
  print("Strand 2 (template for the leading daughter, 5'->3'):  " .. table.concat(s2))
end)

v:addParam("dNTP_uM", 40, 0, 100)               -- [dNTP], Michaelis-Menten input, also feeds D(t)
v:addParam("eukaryote", true)                   -- Vmax = human (true) or E. coli (false) speed
v:addParam("thermoAmplification", 25, 1, 100)    -- scales the computed thermodynamic misincorporation
                                                  -- ratio up so a mutation is visible in a 48 bp demo
v:addParam("proofreadingEfficiency", 0.85, 0, 0.999) -- chance an attempt gets caught
v:addParam("wobbleForce", 3.0, 0, 8)             -- magnitude of the per-step random thermal force
v:addParam("brownianForce", 0.5, 0, 3)           -- jitter magnitude for floating background molecules
v:addParam("cdkActivity", 1.0, 0, 1.5)           -- CDK2/4/6 activity, the other half of Drive D(t)
v:addParam("dnaDamageCheckpoint", false)         -- ATR/ATM-style checkpoint: clamps Phi(t) near 0,
                                                  -- reversibly arresting all NEW origin firing

-- preSim: Called before each physics step. Nudges every base of the
-- original helix with a small random force, like the thermal jostling of
-- molecules in solution. Each base is tethered (tetherToRestPosition) to
-- an anchor at its rest position, so this makes the helix visibly and
-- continuously wobble in place -- like a liquid -- instead of the forces
-- just dragging it apart. Every free-floating background molecule gets
-- its own random Brownian-style kick here too, plus a weak pull back
-- toward its home point (see spawnFloatingMolecule above).
v:preSim(function(N)
  local force = v:getParam("wobbleForce")
  for _, nuc in ipairs(wobblers) do
    nuc.body:applyCentralForce(btVector3(
      (math.random() * 2 - 1) * force,
      (math.random() * 2 - 1) * force,
      (math.random() * 2 - 1) * force))
  end

  local brownian = v:getParam("brownianForce")
  for _, m in ipairs(floatingMolecules) do
    local pos = m.obj.pos
    m.obj.body:applyCentralForce(btVector3(
      (m.home.x - pos.x) * FLOATING_HOME_PULL + (math.random() * 2 - 1) * brownian,
      (m.home.y - pos.y) * FLOATING_HOME_PULL + (math.random() * 2 - 1) * brownian,
      (m.home.z - pos.z) * FLOATING_HOME_PULL + (math.random() * 2 - 1) * brownian))
  end
end)

-- Repositions every fixed (mass 0) reference point in the scene -- base
-- tether anchors, backbone/rung cylinders, SSB proteins still on display,
-- and every fork's own markers/primer anchors -- to match the current
-- rotationAngle. The dynamic, wobbling base spheres and the daughter-chain
-- nucleotides are deliberately NOT repositioned here: they follow their
-- (now-rotated) anchor via the existing btPoint2PointConstraint, exactly
-- as they already follow it when the thermal wobble force nudges them.
local ssbMarkers = {} -- ssbMarkers[i] = {marker1, marker2}, the SSB proteins at bp i

-- Continuous (fractional) bp position of a fork's CMG helicase -- the
-- activated MCM2-7 double hexamer, once Cdc45/GINS have joined it -- so it
-- glides smoothly along the helix as it unwinds instead of snapping
-- between the discrete integer bp positions in f.pos (which only
-- advances in whole steps every few frames, once f.unwoundProgress
-- crosses the next integer). Frozen exactly at f.pos once the fork has
-- stopped unwinding (met another fork, or reached its boundary).
local function forkLivePos(f)
  if not f.unwinding then return f.pos end
  local raw = f.startIndex + f.dir * f.unwoundProgress
  if f.dir > 0 then
    return math.min(f.boundary, raw)
  else
    return math.max(f.boundary, raw)
  end
end

local function rotateSceneGeometry()
  for i = 1, NBP do
    local pos1 = rotateY(basePos(i, 1), rotationAngle)
    local pos2 = rotateY(basePos(i, 2), rotationAngle)

    anchor1[i].pos = pos1
    anchor2[i].pos = pos2
    -- Rung cylinders (see createRungCylinders) are rebuilt from the two
    -- bases' real, live (wobbling) positions every frame, not the
    -- analytic pos1/pos2 -- so they visibly connect wherever the bases
    -- currently are, exactly like the daughter-strand backbone.
    updateRungCylinders(rungs[i], baseSpheres1[i].pos, baseSpheres2[i].pos)

    if i > 1 then
      local prev1 = rotateY(basePos(i - 1, 1), rotationAngle)
      local prev2 = rotateY(basePos(i - 1, 2), rotationAngle)
      repositionCylinder(backbone1[i], prev1, pos1)
      repositionCylinder(backbone2[i], prev2, pos2)
    end

    local markers = ssbMarkers[i]
    if markers ~= nil then
      markers[1].pos = pos1
      markers[2].pos = pos2
    end
  end

  for _, f in ipairs(forks) do
    local livePos = forkLivePos(f)
    f.topoisomerase.pos = rotateY(basePos(clampBp(livePos + f.dir * SSB_LOOKAHEAD), 1), rotationAngle)
    -- The CMG helicase's hexameric ring stays centered on the helix's own
    -- axis (encircling the whole duplex) at the fork's current position,
    -- and spins along with rotationAngle like everything else.
    local ringPositions = helicaseRingPositions(originAxisPos(livePos), rotationAngle)
    for k, hs in ipairs(f.helicase) do
      hs.pos = ringPositions[k]
    end
    f.leadAnchor.pos = rotateY(outwardOffset(basePos(f.startIndex, 1), 0.8), rotationAngle)
    for _, p in ipairs(f.lagPrimers) do
      p.obj.pos = rotateY(outwardOffset(basePos(p.i, 2), 0.8), rotationAngle)
    end

    -- Daughter-strand backbone cylinders connect two real dynamic (or
    -- anchor) bodies, so -- unlike the original helix's backbone, whose
    -- endpoints move only by rigid rotation -- both their orientation AND
    -- length need refreshing from each endpoint's live, physics-driven
    -- position every frame (see updateDynamicBackbone). The anchor/primer
    -- endpoints above are already updated for this frame, so this always
    -- reads current positions.
    for _, b in ipairs(f.leadBackbone) do
      updateDynamicBackbone(b)
    end
    for _, b in ipairs(f.lagBackbone) do
      updateDynamicBackbone(b)
    end
  end
end

local totalSynthesized = 0
local replicationAnnounced = false
local phiRampProgress = 0 -- steps of G1->S progress banked so far (frozen during checkpoint arrest)

-- postSim: Called after each simulation step.
--
-- 0. Spin the whole helix a little further (rotateSceneGeometry).
-- 1. Compute this step's Michaelis-Menten fork velocity from the current
--    organism/[dNTP] params, shared by every active fork (they all draw
--    from the same free-nucleotide pool).
-- 2. Compute the ARCH x Phi model's shared Phi(t) and D(t), then check
--    every unresolved origin: if a fork already reached it, it is
--    passively replicated; otherwise it fires the moment its own
--    R_i(t) = Phi(t)*A_i*D(t)*C_i crosses the threshold T.
-- 3. Advance every fork's unwinding up to its kinetic budget, stopping if
--    it catches up to territory another fork already claimed (the forks
--    "meet"). Independently, let synthesis catch up to within
--    SSB_LOOKAHEAD bp of each fork's unwound position (or fully catch up,
--    once that fork has stopped unwinding for good).
v:postSim(function(N)
  currentStep = N
  updateTimedMarkers()
  rotationAngle = rotationAngle + ROTATION_SPEED
  rotateSceneGeometry()

  local dNTP = v:getParam("dNTP_uM")
  local vmax = v:getParam("eukaryote") and VMAX_EUKARYOTE_NT_S or VMAX_PROKARYOTE_NT_S
  local rateNtPerSec = vmax * dNTP / (KM_DNTP + dNTP)
  local bpPerStep = rateNtPerSec * v.timeStep * TIME_SCALE

  -- ARCH x Phi: Phi(t) is the shared phase-control term (G1->S ramp,
  -- clamped near 0 during a checkpoint arrest); D(t) is the shared
  -- metabolic/kinase Drive, reusing dNTP_uM so scarce nucleotides delay
  -- both elongation (above) and new origin firing (below) at once -- the
  -- model's predicted synergy between pathways.
  local checkpointActive = v:getParam("dnaDamageCheckpoint")
  if not checkpointActive then
    phiRampProgress = phiRampProgress + 1
  end
  local phi = checkpointActive and CHECKPOINT_PHI or math.min(1, phiRampProgress / PHI_RAMP_STEPS)
  local cdk = v:getParam("cdkActivity")
  local drive = math.max(0, cdk * (dNTP / 100) + gaussianRandom() * DRIVE_NOISE)

  for _, o in ipairs(origins) do
    if not o.resolved then
      -- Pre-RC assembly: Cdc6/Cdt1 load the MCM2-7 double hexamer (a
      -- ring-shaped helicase) around the duplex a fixed delay after ORC
      -- bound it. An origin's R_i(t) is not even evaluated below until
      -- this has happened -- the licensing step is a hard prerequisite
      -- for initiation, not just another multiplicative factor.
      if not o.licensed and N >= LICENSING_STEP then
        o.licensed = true
        local mcm = BlobCylinder(0.55, 0.2, 0)
        mcm.col = MCM_COL
        mcm.trans = btTransform(VERTICAL_RING_ROT, originAxisPos(o.index))
        v:add(mcm)
        o.mcmMarker = mcm
        print("Cdc6/Cdt1 load the MCM2-7 double hexamer onto origin bp " .. o.index ..
              " -- pre-RC licensed")
      end

      local reached = false
      for _, f in ipairs(forks) do
        -- o.index must lie on the side of f.startIndex that f actually
        -- travels toward (dir), and pos must have gotten there or past it --
        -- otherwise a fork moving away from an origin would look "reached"
        -- simply because pos and o.index happen to compare that way.
        if f.dir > 0 and o.index >= f.startIndex and f.pos >= o.index then
          reached = true
        elseif f.dir < 0 and o.index <= f.startIndex and f.pos <= o.index then
          reached = true
        end
      end
      if reached then
        o.resolved = true
        if o.mcmMarker ~= nil then v:remove(o.mcmMarker) end
        v:remove(o.orcMarker)
        print("Origin at bp " .. o.index .. " was passively replicated before it could fire")
      elseif o.licensed then
        local r = phi * o.A * drive * o.C
        if r >= INIT_THRESHOLD then
          o.resolved = true
          v:remove(o.mcmMarker)
          v:remove(o.orcMarker)
          meltOrigin(o.index)
          forks[#forks + 1] = createFork(o.index, 1)
          forks[#forks + 1] = createFork(o.index, -1)
          print(string.format(
            "Cdc45/GINS join the loaded hexamers, forming two CMG helicases -- origin at " ..
            "bp %d fires at step %d: R = %.2f(Phi)*%.2f(A)*%.2f(D)*%.2f(C) = " ..
            "%.3f >= T=%.2f, forks head both ways",
            o.index, N, phi, o.A, drive, o.C, r, INIT_THRESHOLD))
        end
      end
    end
  end

  for _, f in ipairs(forks) do
    if f.unwinding then
      f.unwoundProgress = f.unwoundProgress + bpPerStep
      local target
      if f.dir > 0 then
        target = math.min(f.boundary, f.startIndex + math.floor(f.unwoundProgress))
      else
        target = math.max(f.boundary, f.startIndex - math.floor(f.unwoundProgress))
      end
      while towardBoundary(f.pos, target, f.dir) do
        local nextI = f.pos + f.dir
        if claimedUnwind[nextI] then
          f.unwinding = false
          print("Fork from bp " .. f.startIndex .. " meets another fork at bp " .. nextI ..
                " and stops unwinding")
          break
        end
        claimedUnwind[nextI] = true
        f.pos = nextI
        removeRungCylinders(rungs[nextI])
        rungs[nextI] = nil
        local m1 = MoleculeBlob(0.06, 0, PROTEIN_DOMAIN_ATOMS)
        m1.col = SSB_COL
        m1.pos = rotateY(basePos(nextI, 1), rotationAngle)
        v:add(m1)
        local m2 = MoleculeBlob(0.06, 0, PROTEIN_DOMAIN_ATOMS)
        m2.col = SSB_COL
        m2.pos = rotateY(basePos(nextI, 2), rotationAngle)
        v:add(m2)
        ssbMarkers[nextI] = { m1, m2 }
      end
      if f.pos == f.boundary then f.unwinding = false end
    end

    local synthTarget
    if f.unwinding then
      if f.dir > 0 then
        synthTarget = math.max(f.startIndex - 1, f.pos - SSB_LOOKAHEAD)
      else
        synthTarget = math.min(f.startIndex + 1, f.pos + SSB_LOOKAHEAD)
      end
    else
      synthTarget = f.pos
    end
    while towardBoundary(f.synthPos, synthTarget, f.dir) do
      local nextI = f.synthPos + f.dir
      if claimedSynth[nextI] then
        f.synthPos = nextI -- already handled by the other fork from this same origin
      else
        claimedSynth[nextI] = true
        local markers = ssbMarkers[nextI]
        if markers ~= nil then
          v:remove(markers[1])
          v:remove(markers[2])
          ssbMarkers[nextI] = nil
        end
        extendLeadingStrand(f, nextI)
        extendLaggingStrand(f, nextI)
        f.synthPos = nextI
        totalSynthesized = totalSynthesized + 1
      end
    end
  end

  if totalSynthesized >= NBP and not replicationAnnounced then
    replicationAnnounced = true
    print("Replication complete: two double helices now exist, each with " ..
          "one original strand and one newly synthesized strand.")
    print(string.format(
      "Fidelity summary: %d attempted misincorporations, %d caught by proofreading, " ..
      "%d escaped as mutations (observed rate %.4f per base, driven by real per-step " ..
      "nearest-neighbor thermodynamics x thermoAmplification)",
      mutationStats.attempted, mutationStats.caught, mutationStats.escaped,
      mutationStats.escaped / NBP))
    print(string.format(
      "Total DG_pairing of the two new daughter strands: %.1f kJ/mol (sum of every " ..
      "correctly incorporated step's real nearest-neighbor stacking energy)",
      totalPairingEnergyKJ))
  end
end)

common.setCamera(btVector3(48, 10, 0), btVector3(0, 8, 0), 0.1)

-- EOF
