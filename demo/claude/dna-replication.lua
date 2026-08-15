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
-- also spins slowly around its own long axis, horizontal on screen (see rotateSceneGeometry
-- in the postSim callback): every fixed anchor and decorative cylinder is
-- rotated in place each step, and the dynamic bases/daughter strands
-- simply follow along through their existing tether/chain constraints.
-- Both daughter strands are real, gravity-sagging physics chains, drawn
-- growing outward from their own template, one on each side of the
-- original helix, rather than the whole helix visually splitting in two.
--
-- The whole cell cycle is gated by the cell cycle control system -- a
-- system of specialized "stop-sign" proteins. Three checkpoints monitor
-- critical transitions: the G1 (main) checkpoint before replication (size,
-- nutrients, intact DNA -- p53, the "guardian of the genome", either
-- initiates repair or, for severe damage, commits the cell to programmed
-- cell death / apoptosis), the G2 checkpoint before mitosis (DNA copied
-- completely and without errors), and the M (spindle) checkpoint at
-- metaphase (every chromosome correctly attached to the spindle, blocking
-- anaphase until it is). The molecular control center is the cyclin/CDK
-- system: cyclins rise and fall in waves, CDKs are always present but only
-- become active when a matching cyclin binds them, and an active cyclin-CDK
-- complex phosphorylates targets to trigger the next phase. When a
-- checkpoint detects damage, CDK inhibitors (CKI, e.g. p21/p27) bind the
-- complex and halt the cycle. Live params expose each gate: dnaDamageCheckpoint
-- (G1 arrest, p53-mediated, reversible on repair), apoptosis (p53 commits
-- the cell to death -- the cycle stops permanently), g2CheckpointDamage /
-- overrideG2Checkpoint (the G2 gate), and mCheckpointFail (the M gate).
--
-- Replication happens before every division, so the story does not stop at
-- the first cytokinesis: the demo follows the daughter cells' lineage into
-- a second generation. After the first division the whole cell cycle
-- (G1 -> S -> G2 -> M -> cytokinesis) genuinely re-runs on the
-- semi-conservatively inherited DNA -- whose sequence is unchanged, so the
-- exact same fork/origin machinery replays it -- with the new generation's
-- strands laid down as the next outer layer of the growing molecule stack.
-- The lineage is followed for MAX_GENERATIONS rounds of division (the two
-- daughters of a division are genetically identical, so one lineage is
-- exact); set the live enterG0 param to stop after the first division.
--
-- Usage: bpp -n 3200 -f demo/koppi/dna-replication.lua
--

local color  = require "color"
local common = require "common"
local text   = require "scad/text"

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

-- A mitochondrion: an elongated, slightly bent double-membrane rod -- the
-- classic bean-shaped organelle -- shown during cytokinesis as the
-- cytoplasm's organelles are shared out between the two daughter cells.
local MITO_ATOMS = {
  { 0, 0, 0, 1.0 },
  { 0.45, 0.12, 0.05, 0.7 },
  { -0.45, 0.12, 0.05, 0.7 },
  { 0.2, -0.35, 0.08, 0.6 },
  { -0.2, -0.3, -0.05, 0.55 },
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
local COL = {
  BACKBONE_COL = "#8aabaf", -- template helix backbone
  LEADING_STRAND_COL = "#e0a030", -- leading-strand (continuous) daughter backbone, amber
  LAGGING_STRAND_COL = "#30a0a0", -- lagging-strand (Okazaki) daughter backbone, teal
  PRIMER_COL = "#ff44aa", -- short RNA primer, before it is replaced by DNA
  HELICASE_COL = "#eeeeee",
  TOPO_COL = "#66ddcc", -- topoisomerase, leads the fork
  SSB_COL = "#f5f0b0", -- single-strand binding proteins
  MUTATION_COL = "#111111", -- an uncorrected replication error
  PRIMASE_COL = "#ff8800", -- primase, lays each RNA primer
  POLYMERASE_COL = "#5599ff", -- DNA polymerase, actively extending a strand
  EXONUCLEASE_COL = "#aa4477", -- 5'->3' exonuclease, removes each RNA primer
  LIGASE_COL = "#ccdd33", -- DNA ligase, welds Okazaki fragments together
  TOPO2_COL = "#2299aa", -- topoisomerase II, decatenates the two finished daughter helices
  HISTONE_COL = "#c9a876", -- histone octamer, DNA wraps around it to form a nucleosome
  COHESIN_COL = "#7788cc", -- cohesin, rings the two sister chromatids together
  MMR_COL = "#cc6699", -- mismatch repair complex, a second chance for escaped errors
  CHECKPOINT_COL = "#ffee66", -- G2/M checkpoint flash
  P53_COL = "#cc66ff", -- p53, the "guardian of the genome", at the G1 checkpoint
  CKI_COL = "#ff5555", -- CDK inhibitor (p21/p27), blocks cyclin-CDK to halt the cycle
  CYCLIN_CDK_COL = "#ff9966", -- an active cyclin-CDK complex (e.g. cyclin B-CDK1, MPF)
  ENVELOPE_COL = "#aaccee", -- nuclear envelope / cell membrane ring marker
  SPINDLE_POLE_COL = "#ffaa44", -- centrosome / spindle pole
  SPINDLE_FIBER_COL = "#eeeeaa", -- spindle fiber (microtubule)
  ORIGIN_COL = "#ff9922", -- marks every origin, before it fires
  ORC_COL = "#8855cc", -- Origin Recognition Complex: binds the origin sequence
  MCM_COL = "#ccaaff", -- MCM2-7 double hexamer: the loaded, still-inactive helicase ring
  CLEAVAGE_FURROW_COL = "#f0ecd0", -- the actin contractile ring, animal cells
  CELL_PLATE_COL = "#7fbf7f", -- the growing cell plate / new dividing wall, plant cells
  MITOCHONDRION_COL = "#d0525a", -- mitochondria, shared out between the daughter cells
  WATER_COL = "#cfe9ff",
  MG_COL = "#77ee88", -- Mg2+, conventionally green in molecular viewers
  ATP_COL = "#ffcc22",
  PROTEIN_COL = "#df9aa0", -- generic transcription factor / repair enzyme / remodeler --
}

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
local LICENSING_STEP  = 15     -- steps for Cdc6/Cdt1 to load the MCM2-7 double hexamer

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

-- Current spin of the whole helix around its own long (Z) axis, updated
-- once per postSim step below. Every position derived from basePos() is
-- rotated by this angle (via rotateY) before being applied to an object.
local rotationAngle = 0

-- Once replication finishes, both resulting double helices -- strand1 plus
-- its new outer partner, and strand2 plus its own -- untwist out of their
-- spiral shape: topoisomerase has already relieved all torsional stress by
-- then, so there is no more supercoiling tension holding the coil closed.
-- Ramped from 0 (the normal, fully twisted helix) to 1 (fully untwisted)
-- over UNTWIST_STEPS once postSim sees replication complete (see basePos()
-- below for how this actually straightens each strand).
local UNTWIST_STEPS   = 240
local M = {
  currentStage = nil, -- G1/S/G2/M/G0 -- see setStage below
  untwistProgress = 0,
  decatenationProgress = 0,
  condensationProgress = 0,
  anaphaseProgress = 0,
  recoilProgress = 0, -- post-mitotic re-coiling of the two daughter duplexes into visible
                      -- double helices (see basePos/updateRecoil): ramps 0->1 once anaphase ends
  recoilAnnounced = false,
  histoneMarkers = {}, -- { obj=, bp=, strand= }
  cohesinRing = nil,
  spindlePole1 = nil, spindlePole2 = nil,
  spindleFiber1 = nil, spindleFiber2 = nil,
  newEnvelopeRing1 = nil, newEnvelopeRing2 = nil,
  totalSynthesized = 0,
  replicationAnnounced = false,
  untwistAnnounced = false,
  decatenationAnnounced = false,
  phiRampProgress = 0, -- steps of G1->S progress banked so far (frozen during checkpoint arrest)
  chromatinStarted = false,
  chromatinStepCounter = 0,
  chromatinSpawnIndex = 0,
  chromatinAnnounced = false,
  mmrStarted = false,
  mmrStepCounter = 0,
  mmrIndex = 0,
  mmrMarker = nil,
  mmrAnnounced = false,
  prophaseStarted = false,
  prophaseStepCounter = 0,
  prophaseAnnounced = false,
  breakdownEnvelope = nil,
  metaphaseStarted = false,
  metaphaseStepCounter = 0,
  metaphaseAnnounced = false,
  anaphaseStarted = false,
  anaphaseAnnounced = false,
  telophaseStarted = false,
  telophaseStepCounter = 0,
  telophaseAnnounced = false,
  cytokinesisAnnounced = false,
  cytokinesisStarted = false,
  cytokinesisStepCounter = 0,
  cleavageFurrow = nil,   -- the constricting actin ring, animal cells (updateCytokinesis)
  cellPlate = nil,        -- the outward-growing dividing wall, plant cells (updateCytokinesis)
  mitochondria1 = {}, -- { obj=, dy=, dz= } -- organelles orbiting with daughter cell 1
  mitochondria2 = {}, -- same, for daughter cell 2
  cyclinB = 0,        -- the cyclin B wave, 0..1 (see updateCyclinWave)
  ckiActive = false,  -- a CDK inhibitor is currently blocking the cyclin-CDK complex
  g1CheckpointAnnounced = false, -- G1 (main) checkpoint has reported DNA damage (see updateG1Checkpoint)
  g1RepairAnnounced = false,
  p53Marker = nil,    -- p53, the "guardian of the genome", while the G1 checkpoint holds
  g1CkiMarker = nil,  -- the p21 CDK-inhibitor marker, while the G1 checkpoint holds
  g2Passed = false,   -- G2 checkpoint gate: replication verified, mitosis allowed
  g2Arrested = false,
  g2Announced = false,
  g2CkiMarker = nil,  -- CDK-inhibitor marker at the G2 checkpoint, while it blocks mitosis
  mCheckpointAnnounced = false, -- M (spindle) checkpoint has reported a misattachment
  mCheckpointPassed = false,    -- M checkpoint satisfied: anaphase may begin
  mArrested = false,
  mCkiMarker = nil,   -- CDK-inhibitor marker at the M checkpoint, while it blocks anaphase
  apoptosis = false,  -- p53-mediated programmed cell death has been triggered
  generation = 1,     -- which generation's cell cycle is running (see MAX_GENERATIONS /
                      -- transitionToNextGeneration): each is a fresh G1 -> S -> G2 -> M
  genOutwardOffset = 0.8, -- outward layer this generation's new strands are laid at (see
                          -- chainPos): generation 1 at 0.8, generation 2 at 1.6, etc.
  membraneRing1 = nil, -- daughter cell 1's cell membrane ring, created at cytokinesis
  membraneRing2 = nil, -- same, daughter cell 2 (both removed at the next generation's start)
  pendingTransition = false, -- a generation has finished; hold, then call transitionToNextGeneration
  genHoldCounter = 0,        -- steps remaining in the post-cytokinesis hold (see GEN_HOLD_STEPS)
  statusText = nil, -- floating status label, bottom of the display (see setPhase/updateCamera)
}

-- Once untwisting is done, the two straightened daughter duplexes are still
-- topologically interlinked (catenated) from having been wound around each
-- other -- real topoisomerase II resolves this by passing one duplex
-- through a transient double-strand break in the other, then resealing it,
-- letting the two molecules drift apart. Modeled here as a growing world-Z
-- offset -- +Z for strand 1's daughter duplex, -Z for strand 2's -- added
-- in basePos() below, ramped from 0 to 1 over DECATENATION_STEPS.
local DECATENATION_STEPS = 150
local DECATENATION_SEP   = 3.5    -- how far apart (world Z, each way) the two molecules end up

-- Chromatin repackaging: once decatenated, each daughter duplex gets a
-- histone marker every NUCLEOSOME_BP_STEP bp (nucleosomes are DNA wrapped
-- around a histone octamer -- see spawnChromatinStep below), spawned one at
-- a time every CHROMATIN_SPAWN_INTERVAL steps, plus a single cohesin ring
-- linking the two sister chromatids at the "centromere" bp (their midpoint).
local NUCLEOSOME_BP_STEP        = 6
local CHROMATIN_SPAWN_INTERVAL  = 12
local CENTROMERE_BP             = math.floor(NBP / 2)

-- Mismatch repair: after chromatin packaging, every base that escaped
-- proofreading (see pickBaseWithFidelity/COL.MUTATION_COL) gets one further,
-- independent chance at correction -- distinguishing the new strand from
-- the methylated template the way real MMR does, simplified here to a
-- straight live probability roll. One site is visited every
-- MMR_STEP_INTERVAL steps so the repair pass reads as a gradual scan of
-- the genome rather than an instant fix-up.
local MMR_STEP_INTERVAL = 15

-- Mitosis (PMAT + cytokinesis), once the checkpoint passes:
--
-- Prophase: M.condensationProgress (see basePos()) ramps 0->1 over
-- PROPHASE_STEPS, compressing each chromatid's length toward
-- CONDENSE_RISE_SCALE of its full extension, symmetrically around the
-- centromere (so it condenses in place rather than sliding toward one
-- end) -- the same trick M.untwistProgress already uses on TWIST, just
-- applied to RISE instead. The original nuclear envelope (both sister
-- chromatids' shared one) is shown briefly, then breaks down.
--
-- Metaphase: spindle fibers (pole-to-centromere) hold for METAPHASE_STEPS.
--
-- Anaphase: M.anaphaseProgress (see basePos()) ramps 0->1 over
-- ANAPHASE_STEPS, adding ANAPHASE_EXTRA_SEP more world-Z separation on
-- top of decatenation's own -- POLE_DISTANCE is set so each chromatid's
-- centromere reaches exactly its pole's position once anaphase completes.
--
-- Telophase: M.condensationProgress ramps back down over TELOPHASE_STEPS
-- (decondensing), and a new envelope ring forms around each pole's set.
--
-- Cytokinesis: unlike mitosis (which only duplicates the nucleus), this
-- divides the whole cell -- the cytoplasm and its organelles are shared
-- between the two daughter regions. Animal cells pinch apart via a
-- contractile actin ring (cleavage furrow, see updateCytokinesis); plant
-- cells instead grow a cell plate outward from the center to build a new
-- dividing wall. Each daughter then gets its own cell membrane, and the
-- two independent cells immediately begin the interphase (G1 -> S -> G2)
-- of their own new cell cycle -- or, with the enterG0 param, exit into the
-- G0 resting phase instead.
--
-- All of these are rendered as sparse RINGS of small marker spheres (see
-- createEnvelopeRing below), not one large solid sphere: an early
-- experiment confirmed that a big mass-0 sphere overlapping this scene's
-- many small dynamic bodies (wobbling bases, floating molecules) violently
-- ejects them every one of Bullet's contact solver -- btCollisionObject's
-- CF_NO_CONTACT_RESPONSE flag IS a real, working Lua-bound setter
-- (confirmed directly, unlike Object's own collision-type setter, which
-- isn't bound at all), but setting it made no measurable difference in
-- that same test, so a large solid collider had to be avoided outright
-- rather than merely flagged. A sparse ring of small markers (each about
-- the same scale as markers already used safely elsewhere in this file)
-- sidesteps the problem instead of trying to solve it.
local CONDENSE_RISE_SCALE    = 0.12
local PROPHASE_STEPS         = 200
local PROPHASE_ENVELOPE_HOLD = 30    -- steps the original envelope stays visible before breaking down
local METAPHASE_STEPS        = 100
local ANAPHASE_STEPS         = 150
local ANAPHASE_EXTRA_SEP     = 4.0
local POLE_DISTANCE          = DECATENATION_SEP + ANAPHASE_EXTRA_SEP
local TELOPHASE_STEPS        = 150
local ENVELOPE_RING_R        = 4.5   -- radius of the original (breaking-down) nuclear envelope ring
local NEW_ENVELOPE_RING_R    = 2.2   -- radius of each new nuclear envelope, around one decondensed set
local CELL_MEMBRANE_RING_R   = 3.5   -- radius of each daughter cell's own membrane, at cytokinesis
local ENVELOPE_RING_N        = 14    -- marker spheres per envelope/membrane ring

-- Cytokinesis (actual cell division) runs over CYTOKINESIS_STEPS once
-- telophase finishes. Animal cells (default): a contractile ring of actin
-- fibers constricts the cell in the middle (the cleavage furrow), shown
-- here as a marker ring shrinking from just outside the final membrane
-- radius down toward nothing at the cleavage plane. Plant cells (set the
-- live plantCell param): constriction is impossible through the rigid cell
-- wall, so instead a cell plate forms in the center and grows from the
-- inside out to build a new dividing wall -- a marker ring expanding from
-- the center out to the membrane radius. Either way the cytoplasm's
-- organelles (mitochondria, MITOCHONDRION_COUNT per cell) are distributed
-- between the two daughter regions while the division proceeds, and only
-- when it completes do the two independent cells each get their own cell
-- membrane (see updateCytokinesis).
local CYTOKINESIS_STEPS     = 120   -- steps for the furrow to constrict / the plate to form
local CYTOKINESIS_RING_N    = 18    -- marker spheres per cleavage-furrow / cell-plate ring
local MITOCHONDRION_COUNT   = 6     -- mitochondria spawned per daughter region

-- Cell lineage: after each cytokinesis the demo follows the daughter cells'
-- lineage into a new cell cycle -- see transitionToNextGeneration. The
-- whole S phase and mitosis machinery genuinely re-runs for the next
-- generation on the semi-conservatively inherited DNA, with its freshly
-- synthesized strands laid down as the next outer layer (GEN_LAYER_SPACING
-- further from the template helix, see chainPos). MAX_GENERATIONS caps the
-- demo at two rounds of division; the live enterG0 param stops after the
-- first division instead. (These three and the generation functions below
-- are deliberately global: Lua 5.1 caps the main chunk at 200 local
-- variables and this file already sits within a few of that limit.)
GEN_LAYER_SPACING = 0.8 -- outward offset between one generation's strands and the next
MAX_GENERATIONS   = 2   -- rounds of division modeled (generations 1 and 2)
GEN_HOLD_STEPS    = 90  -- steps the completed division stays visible before the next
                        -- generation re-coils and begins (see M.pendingTransition)
RECOIL_STEPS      = 150 -- steps for each finished daughter duplex to coil back into a
                        -- visible double helix after anaphase (see updateRecoil/basePos)

-- The cyclin/CDK control system (see updateCyclinWave): cyclin
-- concentrations rise and fall in waves through the cell cycle. M.cyclinB
-- (a representative cyclin B wave) accumulates through interphase, crests
-- at metaphase, and crashes at anaphase when APC/C degrades it. CDKs are
-- always present but only become active when the matching cyclin binds
-- them; an active cyclin-CDK complex then phosphorylates targets to
-- trigger the start of the next phase. When any checkpoint detects damage,
-- a CDK inhibitor (CKI, see COL.CKI_COL) binds the complex and the wave is
-- held back, halting the cycle.
local CYCLIN_B_RISE  = 1 / 1000     -- per-step accumulation of the cyclin B wave through interphase
local CYCLIN_B_DECAY = 1 / ANAPHASE_STEPS -- APC/C-mediated crash per step of anaphase


-- Rotates pos by `angle` radians around the helix's own long axis -- world
-- Z here, not common.lua's usual Y, so the helix reads horizontally from
-- this demo's fixed camera (positioned out along world X -- see
-- updateCamera far below) rather than vertically. A local override of
-- common.rotateY (X/Z-mixing, Y-preserving) rather than that shared
-- function itself, which other demos still use with the Y convention.
local function rotateY(pos, angle)
  local c, s = math.cos(angle), math.sin(angle)
  return btVector3(pos.x * c - pos.y * s, pos.x * s + pos.y * c, pos.z)
end

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
-- The whole helix runs along world Z here (horizontal, see rotateY above),
-- not the more usual Y -- X/Y are the small "radius" plane (the circular
-- cross-section, plus the daughter-duplex separation below), Z is the long
-- axis. The per-bp angular step scales with (1 - M.untwistProgress +
-- M.recoilProgress): normally (both 0) this is the full helical TWIST; once
-- replication finishes and M.untwistProgress ramps to 1 (see postSim),
-- every bp's angle collapses to the same constant (0 for strand 1, pi for
-- strand 2), so the strand straightens from a spiral into a flat
-- horizontal line. Once untwisted, M.decatenationProgress (see postSim)
-- then pushes each strand's whole daughter duplex further apart along
-- world Y -- +Y for strand 1, -Y for strand 2 -- so the two finished
-- molecules visibly separate; anaphase later adds ANAPHASE_EXTRA_SEP more
-- Y separation the same way. Z itself compresses symmetrically around the
-- centromere's own Z position as M.condensationProgress ramps 0->1 during
-- prophase (and back during telophase), so the chromatid
-- condenses/decondenses in place rather than sliding toward one end. Once
-- anaphase has separated the two finished duplexes, M.recoilProgress (see
-- updateRecoil) ramps 0->1, re-adding the full TWIST so each daughter
-- duplex coils back around its own center into a visible double helix --
-- the two helix structures each daughter cell carries away from the
-- division.
local function basePos(i, strand)
  local twistOn = 1 - M.untwistProgress + M.recoilProgress
  local angle = (i - 1) * TWIST * twistOn
  if strand == 2 then angle = angle + math.pi end
  local rawZ = (i - 1) * RISE
  local centromereZ = (CENTROMERE_BP - 1) * RISE
  local condenseScale = 1 - M.condensationProgress * (1 - CONDENSE_RISE_SCALE)
  local z = centromereZ + (rawZ - centromereZ) * condenseScale
  local ySep = (strand == 1 and 1 or -1) *
    (DECATENATION_SEP * M.decatenationProgress + ANAPHASE_EXTRA_SEP * M.anaphaseProgress)
  return btVector3(RADIUS * math.cos(angle), RADIUS * math.sin(angle) + ySep, z)
end

-- Point on the helix's own central (long, horizontal) axis at base-pair
-- index i -- where pre-RC proteins (ORC, the MCM2-7 double hexamer) sit,
-- since they encircle the whole duplex rather than binding to one
-- strand's side. A rotation about that same axis (rotateY) leaves such a
-- point fixed, so these markers need no per-frame repositioning as the
-- helix spins.
local function originAxisPos(i)
  return btVector3(0, 0, (i - 1) * RISE)
end

-- Pushes a point further out, away from the helix's central (long,
-- horizontal) axis, used to place each new daughter strand clear of the
-- original DNA geometry. A local override of common.outwardOffset (which
-- works in the X-Z plane, treating Y as the axis) for the same reason
-- rotateY above is: this file's own axis is X-Y, treating Z as the axis.
local function outwardOffset(pos, extra)
  local len = math.sqrt(pos.x * pos.x + pos.y * pos.y)
  if len < 1e-6 then
    return btVector3(pos.x + extra, pos.y, pos.z)
  end
  return btVector3(pos.x + pos.x / len * extra, pos.y + pos.y / len * extra, pos.z)
end

-- World-space position of a freshly synthesized nucleotide on the current
-- generation's new strand: pushed outward from its template base by this
-- generation's layer offset (M.genOutwardOffset). Generation 2's strands sit
-- one GEN_LAYER_SPACING further out than generation 1's, so the second
-- cycle's new chains never collide with the first cycle's (which stay in
-- the scene as the earlier generation's settled chromosomes -- see
-- transitionToNextGeneration).
function chainPos(i, strand)
  return rotateY(outwardOffset(basePos(i, strand), M.genOutwardOffset), rotationAngle)
end

-- Quaternion that rotates a Cylinder's local +Z axis (its default, resting
-- orientation, see Cylinder::renderInLocalFrame) to point from p1 to p2, so
-- a Cylinder(radius, length, 0) placed at their midpoint spans exactly
-- between them.
local orientBetween = common.orientBetween

-- Orientation for a Cylinder standing with its axis along the helix's own
-- long axis (global Z here -- see rotateY above), computed once and
-- reused for every MCM2-7 double-hexamer ring marker below, so each one
-- reads as a flat collar encircling that axis rather than a cylinder
-- lying on its side.
local AXIS_RING_ROT = orientBetween(btVector3(0, 0, 0), btVector3(0, 0, 1))

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
  record.cy = placeBlobCylinder(record.a.pos, record.b.pos, BACKBONE_R, COL.BACKBONE_COL)
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

-- A sparse ring of ENVELOPE_RING_N small marker spheres around `center`,
-- radius `ringR`, in the Y-Z plane (facing the fixed camera, which sits out
-- along +X) -- the nuclear envelope / cell membrane's visual stand-in. See
-- the mitosis header comment near CONDENSE_RISE_SCALE for why this is a
-- sparse ring rather than one large solid sphere.
local function createEnvelopeRing(center, ringR, col)
  local ring = {}
  for k = 0, ENVELOPE_RING_N - 1 do
    local a = k * (2 * math.pi / ENVELOPE_RING_N)
    local m = MoleculeBlob(0.12, 0, SINGLE_ATOM)
    m.col = col
    m.pos = btVector3(center.x, center.y + ringR * math.cos(a), center.z + ringR * math.sin(a))
    v:add(m)
    ring[#ring + 1] = m
  end
  return ring
end

local function removeEnvelopeRing(ring)
  if ring == nil then return end
  for _, m in ipairs(ring) do v:remove(m) end
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

-- A single GLOBAL "current phase" indicator, printed once whenever it
-- changes (see setPhase below) so the log gives an at-a-glance sense of how
-- far replication has progressed overall, alongside the more granular
-- per-event prints (a specific origin firing, one Okazaki fragment's
-- ligase weld, etc.) scattered through the fork machinery. With multiple
-- origins firing at different times, the four canonical phases genuinely
-- overlap across forks -- one fork can be elongating while another is
-- still priming -- so this tracks the FURTHEST phase reached by ANY fork
-- so far, monotonically, rather than trying to model each fork's own
-- (much noisier) independent phase separately. Phases 1-4 reuse the exact
-- wording already printed once in preStart's header; 5-16 cover what
-- happens after Phase 4 finishes in a real cell -- completion, untwisting,
-- decatenation, chromatin repackaging, mismatch repair, the G2/M
-- checkpoint gate, and then mitosis itself (PMAT + cytokinesis) -- see the
-- postSim block below for each one's own trigger.
local PHASE_NAMES = {
  [1]  = "Phase 1 Initiation: topoisomerase + helicase unwind the helix, SSB proteins coat the exposed single strands",
  [2]  = "Phase 2 Priming: primase lays an RNA primer for polymerase to extend from",
  [3]  = "Phase 3 Elongation: polymerase synthesizes 5'->3', continuous on the leading strand, in Okazaki fragments on the lagging strand",
  [4]  = "Phase 4 Termination: polymerase I replaces primers with DNA, ligase welds the Okazaki fragments into one continuous strand",
  [5]  = "Replication complete: both new strands are fully synthesized",
  [6]  = "Untwisting: both new double helices relax out of their spiral shape",
  [7]  = "Relaxed: both new double helices are fully untwisted",
  [8]  = "Decatenation: topoisomerase II unlinks the two interlinked daughter helices",
  [9]  = "Chromatin repackaging: histones reassemble into nucleosomes, cohesin links the sister chromatids",
  [10] = "Mismatch repair: escaped replication errors get one further chance at correction",
  [11] = "G2 checkpoint: the DNA must be copied completely and without errors -- only then does the cell proceed toward mitosis",
  [12] = "Prophase: chromatin condenses into a visible chromosome, the nuclear envelope breaks down, the spindle begins to form",
  [13] = "Metaphase: the spindle is fully formed and aligns the chromosome at the equatorial plane",
  [14] = "Anaphase: spindle fibers shorten and pull the separated sister chromatids toward opposite poles",
  [15] = "Telophase: chromosomes decondense at the poles and a new nuclear envelope forms around each set",
  [16] = "Cytokinesis: the cytoplasm divides -- a cleavage furrow pinches the cell apart (animal) or a cell plate builds a new wall (plant) -- producing two independent, genetically identical daughter cells",
}

local currentPhase = 0 -- 0 = nothing has happened yet; preStart below advances it to 1

-- Status text (bottom of the display): a floating OpenSCAD-extruded 3D
-- label naming whatever phase the simulation is currently in. Best-effort,
-- pcall'd like every other OpenSCAD text object in this codebase (see
-- demo/module/scad/text.lua's other callers), since it depends on an
-- external openscad binary that might not be installed/configured -- a
-- missing label just means one isn't shown, not that the whole demo
-- aborts. Only actually rebuilt (expensive: reruns OpenSCAD) when the
-- label text itself changes, from setPhase below; repositioning every
-- frame to stay pinned at the bottom of whatever the dynamic camera is
-- currently framing is a cheap plain transform update, done in
-- updateCamera, not here.
local function setStatusText(label)
  if M.statusText ~= nil then
    v:remove(M.statusText)
    M.statusText = nil
  end
  local ok, obj = pcall(function()
    return text.new({ str = label, size = 0.55, height = 0.1, mass = 0, col = "#ffffff" })
  end)
  if ok and obj ~= nil then
    -- Faces the camera, which always looks along roughly -X toward
    -- whatever updateCamera's `look` currently is (see its own fixed
    -- offset direction there) -- local +Z (OpenSCAD's extrusion axis)
    -- rotated to point along world +X, confirmed by render. Position is
    -- an arbitrary placeholder here: updateCamera repositions it (along
    -- with everything else about the camera) before this frame is over,
    -- since it always runs as postSim's last step.
    obj.trans = btTransform(common.orientBetween(btVector3(0, 0, 0), btVector3(1, 0, 0)), btVector3(0, 0, 0))
    v:add(obj)
    M.statusText = obj
  end
end

local function setPhase(n)
  if n <= currentPhase then return end -- monotonic: never re-announce an earlier/current phase
  currentPhase = n
  local label = PHASE_NAMES[n]
  print("[Phase] " .. label)
  setStatusText(label:match("^([^:]+)") or label)
end

-- A coarser G1/S/G2/M cell-cycle STAGE indicator, layered on top of
-- PHASE_NAMES/setPhase above rather than replacing it: G1 (growth -- the
-- cell grows, produces proteins, and multiplies its organelles) is the
-- window this demo already spends ramping Phi(t) up and licensing origins
-- before any actually fires, so no new mechanics are needed for it -- it's
-- simply relabeled. S (synthesis -- DNA is completely duplicated, one
-- chromatid becomes two) begins the moment the first origin actually
-- fires (Phase 2); G2 (preparation -- continued growth, checking the
-- freshly replicated DNA for errors, final preparation for mitosis) begins
-- once the core replication machinery finishes (Phase 5) and covers
-- untwisting/decatenation/chromatin/mismatch-repair/checkpoint; M
-- (mitosis) begins at Prophase (Phase 12). Once cytokinesis (Phase 16)
-- has actually divided the cell, the two independent daughter cells
-- immediately begin the interphase of their own new cell cycle -- G1 is
-- announced again, and the interphase runs G1 -> S -> G2 -> the next
-- mitosis. The G0 special case (not all cells keep dividing: mature nerve
-- and muscle cells exit after G1) is available through the live enterG0
-- param, which instead sends the daughters straight into the G0 resting
-- phase, performing their specialized functions and never dividing again.
-- Unlike setPhase, this isn't keyed by a monotonic number -- there are
-- only these few values, always visited in the same order, so a simple
-- "did it change" check is enough.
local function setStage(name, blurb)
  if M.currentStage == name then return end
  M.currentStage = name
  print("[Stage] " .. name .. ": " .. blurb)
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
    backbone1[i] = placeBlobCylinder(basePos(i - 1, 1), pos1, BACKBONE_R, COL.BACKBONE_COL)
    backbone2[i] = placeBlobCylinder(basePos(i - 1, 2), pos2, BACKBONE_R, COL.BACKBONE_COL)
  end
end

-- Mark each origin's rung bright orange so it is visible from frame 1, and
-- place its ORC (Origin Recognition Complex) marker -- ORC binding its
-- sequence is essentially immediate, unlike the slower MCM2-7 loading that
-- follows it later in postSim (see LICENSING_STEP).
for _, o in ipairs(origins) do
  if rungs[o.index] ~= nil then
    local rung = rungs[o.index]
    rung.col1, rung.col2 = COL.ORIGIN_COL, COL.ORIGIN_COL
    if rung.cy1 ~= nil then rung.cy1.col = COL.ORIGIN_COL end
    if rung.cy2 ~= nil then rung.cy2.col = COL.ORIGIN_COL end
  end
  local orc = Cube(0.2, 0.2, 0.2, 0)
  orc.col = COL.ORC_COL
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
                                      -- salmon, sampled from the reference image's protein complexes

local function randomCloudPos(minR, maxR)
  local r = minR + math.random() * (maxR - minR)
  local theta = math.random() * 2 * math.pi
  local z = math.random() * (NBP - 1) * RISE
  return btVector3(r * math.cos(theta), r * math.sin(theta), z)
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
  spawnFloatingMolecule(0.05, COL.WATER_COL, SHELL_MIN_R, SHELL_MAX_R, WATER_ATOMS)
end
for _ = 1, 14 do
  spawnFloatingMolecule(0.06, COL.MG_COL, CLOUD_MIN_R, CLOUD_MAX_R, ION_ATOMS)
end
for _ = 1, 30 do
  local dntpBase = BASES[math.random(1, 4)]
  spawnFloatingMolecule(0.09, BASE_COLOR[dntpBase], CLOUD_MIN_R, CLOUD_MAX_R, baseAtoms(dntpBase))
end
for _ = 1, 20 do
  spawnFloatingMolecule(0.11, COL.ATP_COL, CLOUD_MIN_R, CLOUD_MAX_R, ATP_ATOMS)
end
for _ = 1, 6 do
  spawnFloatingMolecule(0.22, COL.PROTEIN_COL, CLOUD_MIN_R, CLOUD_MAX_R, PROTEIN_ATOMS)
end

--
-- Fidelity model (see header comment for the thermodynamic derivation).
-- Every synthesized nucleotide's intrinsic misincorporation odds are
-- computed fresh from the real local stacking context, then rolled
-- against the live thermoAmplification/proofreadingEfficiency params.
--
local mutationStats = { attempted = 0, caught = 0, escaped = 0, mmrCaught = 0 }
local totalPairingEnergyKJ = 0 -- running DG_pairing of the two new strands, for the final summary

-- Every escaped mutation (see COL.MUTATION_COL below), recorded so the later
-- mismatch-repair pass (see postSim) has real sites to visit instead of
-- needing to rescan the whole molecule for COL.MUTATION_COL-colored spheres.
local mutationSites = {} -- { obj=, correctBase=, repaired= }

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

-- Every earlier generation's own forks table, kept around after
-- transitionToNextGeneration clears `forks` for the next generation's
-- fresh cycle. Those old fork objects (leadAnchor, every daughter-strand
-- chain node) are never removed from the scene -- removing a body while a
-- btPoint2PointConstraint still references it is a real crash/corruption
-- risk, and those constraints were never kept in a table to remove first
-- -- so they stay visible forever as that generation's settled, recoiled
-- daughter helix/helices. sceneReach (see updateCamera) needs to know
-- about them too, for the camera to keep them in frame.
local retiredForkGroups = {}

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
  topo.col = COL.TOPO_COL
  topo.pos = rotateY(basePos(originIndex, 1), rotationAngle)
  v:add(topo)

  local helicaseSpheres = {}
  local ringPositions = helicaseRingPositions(originAxisPos(originIndex), rotationAngle)
  for k = 1, HELICASE_SUBUNIT_COUNT do
    local hs = MoleculeBlob(HELICASE_SUBUNIT_R, 0, PROTEIN_DOMAIN_ATOMS)
    hs.col = COL.HELICASE_COL
    hs.pos = ringPositions[k]
    v:add(hs)
    helicaseSpheres[k] = hs
  end

  local leadAnchor = MoleculeBlob(0.1, 0, PYRIMIDINE_ATOMS)
  leadAnchor.col = COL.PRIMER_COL
  leadAnchor.pos = chainPos(originIndex, 1)
  v:add(leadAnchor)
  -- Primase lays this leading-strand primer too -- the very first one at
  -- this origin -- exactly like it does for every lagging-strand
  -- Okazaki fragment later (see extendLaggingStrand).
  spawnTimedEnzyme(leadAnchor.pos, COL.PRIMASE_COL, 0.08, 4)

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
    fork.leadAnchor.col = COL.LEADING_STRAND_COL
    fork.leadPrimerReplaced = true
    -- Exonuclease removes the RNA primer; DNA polymerase then binds right
    -- there and rides along the strand as it grows (see the reposition
    -- call below, run every time this strand gains a nucleotide).
    spawnTimedEnzyme(fork.leadAnchor.pos, COL.EXONUCLEASE_COL, 0.06, 4)
    fork.leadPolymerase = createEnzymeCluster(fork.leadAnchor.pos, COL.POLYMERASE_COL, 0.09, 5)
    setPhase(4)
    print("DNA polymerase I replaces the leading strand's primer with DNA (fork from bp " ..
          fork.startIndex .. ")")
  end

  local correctBase = DNA_COMPLEMENT[strand1[i]]
  local base, isMutation = pickBaseWithFidelity(correctBase, fork.leadPrevBase)
  fork.leadPrevBase = base

  local nuc = MoleculeBlob(0.13, 0.05, baseAtoms(base))
  nuc.col = isMutation and COL.MUTATION_COL or BASE_COLOR[base]
  nuc.pos = chainPos(i, 1)
  v:add(nuc)
  if isMutation then
    print(string.format(
      "UNCORRECTED replication error at bp %d (leading strand): inserted %s instead of %s",
      i, base, correctBase))
    mutationSites[#mutationSites + 1] = { obj = nuc, correctBase = correctBase, repaired = false }
  end

  local con = btPoint2PointConstraint(fork.leadChainEnd.body, nuc.body,
                                       btVector3(0, 0, 0), btVector3(0, 0, 0))
  v:addConstraint(con)
  local backbone = placeBlobCylinder(fork.leadChainEnd.pos, nuc.pos, BACKBONE_R, COL.LEADING_STRAND_COL)
  fork.leadBackbone[#fork.leadBackbone + 1] = { cy = backbone, a = fork.leadChainEnd, b = nuc }
  fork.leadChainEnd = nuc
  repositionEnzymeCluster(fork.leadPolymerase, nuc.pos)
end

-- Phase 2/3/4 for the lagging strand (template: strand2), one nucleotide,
-- grouped into Okazaki fragments.
local function extendLaggingStrand(fork, i)
  if fork.lagPrimer == nil then
    fork.lagPrimer = MoleculeBlob(0.1, 0, PYRIMIDINE_ATOMS)
    fork.lagPrimer.col = COL.PRIMER_COL
    fork.lagPrimer.pos = chainPos(i, 2)
    v:add(fork.lagPrimer)
    fork.lagPrimers[#fork.lagPrimers + 1] = { obj = fork.lagPrimer, i = i }
    fork.lagChainEnd = fork.lagPrimer
    fork.lagFragmentLen = 0
    fork.lagPrevBase = nil -- new RNA primer boundary; no DNA-DNA stacking context yet
    -- Primase flashes at the new primer site; DNA polymerase then binds
    -- there too (creating the marker on this fork's first fragment,
    -- otherwise just moving the existing one to the new primer).
    spawnTimedEnzyme(fork.lagPrimer.pos, COL.PRIMASE_COL, 0.08, 4)
    if fork.lagPolymerase == nil then
      fork.lagPolymerase = createEnzymeCluster(fork.lagPrimer.pos, COL.POLYMERASE_COL, 0.09, 5)
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
  nuc.col = isMutation and COL.MUTATION_COL or BASE_COLOR[base]
  nuc.pos = chainPos(i, 2)
  v:add(nuc)
  if isMutation then
    print(string.format(
      "UNCORRECTED replication error at bp %d (lagging strand): inserted %s instead of %s",
      i, base, correctBase))
    mutationSites[#mutationSites + 1] = { obj = nuc, correctBase = correctBase, repaired = false }
  end

  local con = btPoint2PointConstraint(fork.lagChainEnd.body, nuc.body,
                                       btVector3(0, 0, 0), btVector3(0, 0, 0))
  v:addConstraint(con)
  local backbone = placeBlobCylinder(fork.lagChainEnd.pos, nuc.pos, BACKBONE_R, COL.LAGGING_STRAND_COL)
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
    fork.lagPrimer.col = COL.LAGGING_STRAND_COL
    spawnTimedEnzyme(fork.lagPrimer.pos, COL.EXONUCLEASE_COL, 0.06, 4)
    setPhase(4)
    print("DNA polymerase I replaces the RNA primer at bp " .. i .. " with DNA")
    if fork.lastLigatedEnd ~= nil then
      local ligaseCon = btPoint2PointConstraint(fork.lastLigatedEnd.body, fork.lagPrimer.body,
                                                 btVector3(0, 0, 0), btVector3(0, 0, 0))
      v:addConstraint(ligaseCon)
      local ligaseBackbone = placeBlobCylinder(fork.lastLigatedEnd.pos, fork.lagPrimer.pos,
                                            BACKBONE_R, COL.LAGGING_STRAND_COL)
      fork.lagBackbone[#fork.lagBackbone + 1] =
        { cy = ligaseBackbone, a = fork.lastLigatedEnd, b = fork.lagPrimer }
      spawnTimedEnzyme(fork.lagPrimer.pos, COL.LIGASE_COL, 0.08, 4)
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
  print("4. Cell cycle control: three checkpoints -- G1 (main: size, nutrients, intact " ..
        "DNA before replication; p53 repairs or triggers apoptosis), G2 (DNA copied " ..
        "completely and without errors before mitosis), and M / spindle (every chromosome " ..
        "attached to the spindle before anaphase). Cyclins rise and fall in waves; CDKs " ..
        "are always present but only active when a cyclin binds, phosphorylating to start " ..
        "the next phase; CDK inhibitors (p21/p27) halt the cycle when a checkpoint fails. " ..
        "Live params: dnaDamageCheckpoint (G1 arrest), apoptosis (p53 commits the cell to " ..
        "death), g2CheckpointDamage/overrideG2Checkpoint (G2 gate), mCheckpointFail (M gate)")
  print("5. Cell lineage: the demo follows one cell's lineage across generations. After the " ..
        "first cytokinesis the daughter cells enter G1 of their own cycle, and the whole " ..
        "process re-runs for a second generation -- S replication of the same " ..
        "(semi-conservatively inherited) DNA, then G2 and the next mitosis, with the new " ..
        "strands laid down as a fresh outer layer. enterG0 stops after the first division.")
  print("")
  print("Strand 1 (template for the lagging daughter, 5'->3'): " .. table.concat(strand1))
  local s2 = {}
  for i = 1, NBP do s2[i] = strand2Base(i) end
  print("Strand 2 (template for the leading daughter, 5'->3'):  " .. table.concat(s2))
  print("")
  setStage("G1", "the cell grows, produces proteins, and multiplies its organelles")
  setPhase(1)
end)

v:addParam("dNTP_uM", 40, 0, 100, 1, "[dNTP], Michaelis-Menten input, also feeds D(t)")
v:addParam("eukaryote", true, "Vmax = human (true) or E. coli (false) speed")
v:addParam("thermoAmplification", 25, 1, 100, 1,
  "scales the computed thermodynamic misincorporation ratio up so a mutation is visible in a 48 bp demo")
v:addParam("proofreadingEfficiency", 0.85, 0, 0.999, 0.01, "chance an attempt gets caught")
v:addParam("mmrEfficiency", 0.7, 0, 0.999, 0.01,
  "post-replication mismatch repair's own, independent chance to still catch an escaped error")
v:addParam("wobbleForce", 3.0, 0, 8, 0.1, "magnitude of the per-step random thermal force")
v:addParam("brownianForce", 0.5, 0, 3, 0.1, "jitter magnitude for floating background molecules")
v:addParam("cdkActivity", 1.0, 0, 1.5, 0.1, "CDK2/4/6 activity, the other half of Drive D(t)")
v:addParam("dnaDamageCheckpoint", false,
  "G1 (main) checkpoint: DNA damage detected before replication. p53 induces p21, clamping Phi(t) near 0 and reversibly arresting all NEW origin firing (clear = damage repaired)")
v:addParam("apoptosis", false,
  "severe, irreparable damage at the G1 checkpoint: p53 commits the cell to programmed cell death -- the cycle halts permanently")
v:addParam("g2CheckpointDamage", false,
  "G2 checkpoint: extra damage detected after replication (besides any uncorrected mutations), blocking entry into mitosis")
v:addParam("overrideG2Checkpoint", false, "force-release the G2 checkpoint block, letting mitosis proceed")
v:addParam("mCheckpointFail", false,
  "M (spindle) checkpoint: a chromatid is not attached to the spindle, blocking anaphase (clear once every fiber is anchored)")
v:addParam("plantCell", false,
  "plant-style cytokinesis: an outward-growing cell plate instead of an animal actin cleavage furrow")
v:addParam("enterG0", false,
  "after cytokinesis the daughter cells exit into the G0 resting phase instead of entering a new G1 interphase")

-- onParamChanged: Called when a parameter value is changed in the GUI. All
-- the params above are read live via v:getParam() each frame, so this is
-- just user feedback in the command line -- no extra wiring needed.
v:onParamChanged(function(N, name, value)
  print("onParamChanged("..tostring(N).."): "..name.." = "..tostring(value))
end)

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

-- Chromatin repackaging markers (see postSim's spawnChromatinStep): every
-- bp in nucleosomeBps gets one histone marker per daughter duplex, plus a
-- single cohesin ring at the centromere -- both repositioned every frame
-- below, exactly like every other persistent marker in this function.
local nucleosomeBps = {}
for i = 1, NBP, NUCLEOSOME_BP_STEP do nucleosomeBps[#nucleosomeBps + 1] = i end

-- Mitosis markers (see postSim's updateProphase/updateMetaphase/
-- updateTelophase): spindle poles are fixed points that spin along with
-- rotationAngle like everything else; fibers connect a pole to its own
-- chromatid's centromere and are recreated each frame since that distance
-- genuinely changes (shortening through anaphase); the two new nuclear
-- envelope rings (telophase) each track their own chromatid the same way
-- the cohesin ring already tracks both.

-- Repositions every mitosis marker above, once per frame. Split out from
-- rotateSceneGeometry itself (called as its last step) rather than inlined
-- there, so rotateSceneGeometry's OWN upvalue count doesn't grow further --
-- see the postSim upvalue-limit note near CONDENSE_RISE_SCALE for why a
-- single closure capturing too much of this file's shared state is a real,
-- already-hit problem here (Lua 5.1 caps a closure at 60 upvalues).
local function repositionMitosisMarkers()
  local centromereZ = (CENTROMERE_BP - 1) * RISE
  if M.spindlePole1 ~= nil then
    M.spindlePole1.pos = rotateY(btVector3(0, POLE_DISTANCE, centromereZ), rotationAngle)
  end
  if M.spindlePole2 ~= nil then
    M.spindlePole2.pos = rotateY(btVector3(0, -POLE_DISTANCE, centromereZ), rotationAngle)
  end
  if M.spindleFiber1 ~= nil then
    local c1 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 0.8), rotationAngle)
    v:remove(M.spindleFiber1)
    M.spindleFiber1 = placeBlobCylinder(M.spindlePole1.pos, c1, BACKBONE_R, COL.SPINDLE_FIBER_COL)
  end
  if M.spindleFiber2 ~= nil then
    local c2 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 0.8), rotationAngle)
    v:remove(M.spindleFiber2)
    M.spindleFiber2 = placeBlobCylinder(M.spindlePole2.pos, c2, BACKBONE_R, COL.SPINDLE_FIBER_COL)
  end
  if M.newEnvelopeRing1 ~= nil then
    local c1 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 0.8), rotationAngle)
    for k, m in ipairs(M.newEnvelopeRing1) do
      local a = (k - 1) * (2 * math.pi / ENVELOPE_RING_N)
      m.pos = btVector3(c1.x, c1.y + NEW_ENVELOPE_RING_R * math.cos(a), c1.z + NEW_ENVELOPE_RING_R * math.sin(a))
    end
  end
  if M.newEnvelopeRing2 ~= nil then
    local c2 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 0.8), rotationAngle)
    for k, m in ipairs(M.newEnvelopeRing2) do
      local a = (k - 1) * (2 * math.pi / ENVELOPE_RING_N)
      m.pos = btVector3(c2.x, c2.y + NEW_ENVELOPE_RING_R * math.cos(a), c2.z + NEW_ENVELOPE_RING_R * math.sin(a))
    end
  end
  -- Cytokinesis organelles: the mitochondria distributed at the start of
  -- division orbit with their own daughter cell, which sits at roughly
  -- world Y = +/-POLE_DISTANCE once anaphase is done.
  for _, mito in ipairs(M.mitochondria1) do
    mito.obj.pos = rotateY(btVector3(0, POLE_DISTANCE + mito.dz, centromereZ + mito.dy), rotationAngle)
  end
  for _, mito in ipairs(M.mitochondria2) do
    mito.obj.pos = rotateY(btVector3(0, -POLE_DISTANCE + mito.dz, centromereZ + mito.dy), rotationAngle)
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
    -- topoisomerase is removed (set nil) once mitosis's prophase begins,
    -- vestigial by then -- see updateProphase.
    if f.topoisomerase ~= nil then
      f.topoisomerase.pos = rotateY(basePos(clampBp(livePos + f.dir * SSB_LOOKAHEAD), 1), rotationAngle)
    end
    -- The CMG helicase's hexameric ring stays centered on the helix's own
    -- axis (encircling the whole duplex) at the fork's current position,
    -- and spins along with rotationAngle like everything else.
    local ringPositions = helicaseRingPositions(originAxisPos(livePos), rotationAngle)
    for k, hs in ipairs(f.helicase) do
      hs.pos = ringPositions[k]
    end
    f.leadAnchor.pos = chainPos(f.startIndex, 1)
    for _, p in ipairs(f.lagPrimers) do
      p.obj.pos = chainPos(p.i, 2)
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

  for _, h in ipairs(M.histoneMarkers) do
    h.obj.pos = rotateY(outwardOffset(basePos(h.bp, h.strand), 0.8), rotationAngle)
  end
  if M.cohesinRing ~= nil then
    local posA = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 0.8), rotationAngle)
    local posB = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 0.8), rotationAngle)
    v:remove(M.cohesinRing)
    M.cohesinRing = placeBlobCylinder(posA, posB, BACKBONE_R * 1.5, COL.COHESIN_COL)
  end

  repositionMitosisMarkers()
end


-- Chromatin repackaging state (nucleosomeBps/M.histoneMarkers/M.cohesinRing are
-- declared earlier, right before rotateSceneGeometry, since that function
-- repositions M.histoneMarkers/M.cohesinRing every frame and needs them already
-- in scope): M.chromatinSpawnIndex walks through nucleosomeBps two-at-a-time
-- (one histone per strand per visited bp), CHROMATIN_SPAWN_INTERVAL steps apart.

-- Mismatch repair state: M.mmrIndex walks through mutationSites one at a
-- time, MMR_STEP_INTERVAL steps apart (see postSim); M.mmrMarker is the
-- transient repair-complex marker shown at whichever site is being visited.


-- Decatenation (see basePos()'s M.decatenationProgress-driven Z offset):
-- once untwisted, the two straight daughter duplexes are still catenated,
-- so topoisomerase II unlinks them and they drift apart.
local function updateDecatenation()
  if not (M.untwistAnnounced and M.decatenationProgress < 1) then return end
  if M.decatenationProgress == 0 then
    setPhase(8)
    print("Topoisomerase II passes one daughter helix through a transient break in " ..
          "the other, resolving their interlinking -- the two molecules drift apart.")
  end
  M.decatenationProgress = math.min(1, M.decatenationProgress + 1 / DECATENATION_STEPS)
  if M.decatenationProgress >= 1 and not M.decatenationAnnounced then
    M.decatenationAnnounced = true
    print("Decatenation complete: the two daughter double helices are now fully " ..
          "independent molecules.")
  end
end

-- Chromatin repackaging: once decatenated, spawn one histone marker per
-- strand at each bp in nucleosomeBps, CHROMATIN_SPAWN_INTERVAL steps
-- apart, plus a single cohesin ring at the centromere (created once, then
-- kept live every frame by rotateSceneGeometry).
local function updateChromatinPackaging()
  if not (M.decatenationAnnounced and not M.chromatinAnnounced) then return end
  if not M.chromatinStarted then
    M.chromatinStarted = true
    setPhase(9)
    print("Histones begin reassembling into nucleosomes along each daughter duplex, " ..
          "and cohesin rings the two sister chromatids together at the centromere.")
    local posA = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 0.8), rotationAngle)
    local posB = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 0.8), rotationAngle)
    M.cohesinRing = placeBlobCylinder(posA, posB, BACKBONE_R * 1.5, COL.COHESIN_COL)
  end
  M.chromatinStepCounter = M.chromatinStepCounter + 1
  if M.chromatinStepCounter >= CHROMATIN_SPAWN_INTERVAL and M.chromatinSpawnIndex < #nucleosomeBps then
    M.chromatinStepCounter = 0
    M.chromatinSpawnIndex = M.chromatinSpawnIndex + 1
    local bp = nucleosomeBps[M.chromatinSpawnIndex]
    for strand = 1, 2 do
      local h = MoleculeBlob(0.24, 0, PROTEIN_ATOMS)
      h.col = COL.HISTONE_COL
      h.pos = rotateY(outwardOffset(basePos(bp, strand), 0.8), rotationAngle)
      v:add(h)
      M.histoneMarkers[#M.histoneMarkers + 1] = { obj = h, bp = bp, strand = strand }
    end
    if M.chromatinSpawnIndex >= #nucleosomeBps then
      M.chromatinAnnounced = true
      print(string.format(
        "Chromatin repackaging complete: %d nucleosomes assembled per daughter strand.",
        #nucleosomeBps))
    end
  end
end

-- Mismatch repair: once chromatin is packaged, visit every escaped
-- mutation (mutationSites, recorded in extendLeadingStrand/
-- extendLaggingStrand) one at a time, MMR_STEP_INTERVAL steps apart, each
-- with its own independent (mmrEfficiency) chance at correction.
local function updateMismatchRepair()
  if not (M.chromatinAnnounced and not M.mmrAnnounced) then return end
  if not M.mmrStarted then
    M.mmrStarted = true
    setPhase(10)
    if #mutationSites == 0 then
      print("Mismatch repair scans the genome: no escaped errors remain to correct.")
    else
      print(string.format(
        "Mismatch repair scans the genome for the %d error(s) that escaped proofreading.",
        #mutationSites))
    end
  end
  M.mmrStepCounter = M.mmrStepCounter + 1
  if M.mmrStepCounter < MMR_STEP_INTERVAL then return end
  M.mmrStepCounter = 0
  if M.mmrMarker ~= nil then
    removeEnzymeCluster(M.mmrMarker)
    M.mmrMarker = nil
  end
  if M.mmrIndex < #mutationSites then
    M.mmrIndex = M.mmrIndex + 1
    local site = mutationSites[M.mmrIndex]
    M.mmrMarker = createEnzymeCluster(site.obj.pos, COL.MMR_COL, 0.09, 4)
    if math.random() < v:getParam("mmrEfficiency") then
      site.obj.col = BASE_COLOR[site.correctBase]
      site.repaired = true
      mutationStats.mmrCaught = mutationStats.mmrCaught + 1
      print("Mismatch repair corrects an escaped error to " .. site.correctBase)
    else
      print("Mismatch repair passes over an escaped error and leaves it uncorrected")
    end
  else
    M.mmrAnnounced = true
    print(string.format(
      "Mismatch repair complete: %d of %d escaped error(s) corrected, %d persist as " ..
      "permanent mutations in the final genome.",
      mutationStats.mmrCaught, mutationStats.escaped,
      mutationStats.escaped - mutationStats.mmrCaught))
  end
end

-- The cyclin/CDK wave (see the cyclin constants above): the representative
-- cyclin B concentration rises through interphase, holds at its peak
-- through prophase/metaphase, and crashes at anaphase as APC/C degrades
-- it. A CDK inhibitor (a failed G1/G2/M checkpoint) holds the wave back:
-- cyclin still accumulates, but the CKI blocks the active cyclin-CDK
-- complex, so the cycle cannot progress. Updates M.cyclinB each step.
local function updateCyclinWave()
  if M.apoptosis then return end
  if M.anaphaseStarted then
    M.cyclinB = math.max(0.05, M.cyclinB - CYCLIN_B_DECAY)
  elseif not M.ckiActive then
    M.cyclinB = math.min(1, M.cyclinB + CYCLIN_B_RISE)
  end
end

-- Apoptosis: if the G1 checkpoint's damage is severe and irreparable, p53
-- commits the cell to programmed cell death rather than repair. The cell
-- cycle freezes, the DNA condenses and darkens, and the background
-- molecular crowd is dismantled -- see the postSim guard below.
local function triggerApoptosis()
  M.apoptosis = true
  M.ckiActive = true
  setStage("apoptosis", "the damage is severe and irreparable: p53 activates programmed cell death")
  print("The damage is severe and irreparable: p53 activates apoptosis. The cell shrinks, " ..
        "its DNA condenses and fragments, and it is quietly dismantled -- a fail-safe " ..
        "that protects the organism from a damaged cell.")
  for _, nuc in ipairs(wobblers) do nuc.col = "#3a3a3a" end
  for _, m in ipairs(floatingMolecules) do v:remove(m.obj) end
end

-- G1 checkpoint (the main/restriction checkpoint): before replication the
-- cell checks whether it is large enough, has sufficient nutrients, and
-- possesses intact DNA. The live dnaDamageCheckpoint param simulates DNA
-- damage at this gate: p53 -- the "guardian of the genome" -- detects it,
-- induces the CDK inhibitor p21, and the cycle halts before any origin
-- fires (see postSim's Phi clamp). Clearing the param = the damage was
-- repaired; p53 clears, p21 is released, and cyclin E-CDK2 resumes driving
-- S-phase entry. The severe, irreparable case is the live apoptosis param:
-- p53 commits the cell to programmed cell death instead (triggerApoptosis)
-- and the cycle stops permanently.
local function updateG1Checkpoint()
  if M.apoptosis or currentPhase > 4 then return end -- the G1/S interphase window
  if v:getParam("apoptosis") then
    triggerApoptosis()
    return
  end
  local damaged = v:getParam("dnaDamageCheckpoint")
  if damaged and not M.g1CheckpointAnnounced then
    M.g1CheckpointAnnounced = true
    M.ckiActive = true
    local pos = originAxisPos(ORIGIN_INDICES[1])
    M.p53Marker = MoleculeBlob(0.18, 0, PROTEIN_ATOMS)
    M.p53Marker.col = COL.P53_COL
    M.p53Marker.pos = pos
    v:add(M.p53Marker)
    M.g1CkiMarker = createEnzymeCluster(btVector3(pos.x, pos.y - 0.6, pos.z), COL.CKI_COL, 0.09, 4)
    print("G1 checkpoint (main): the cell checks whether it is large enough, has " ..
          "sufficient nutrients, and possesses intact DNA before replication begins.")
    print("DNA damage is detected: p53 (the 'guardian of the genome') induces the CDK " ..
          "inhibitor p21, which blocks cyclin E-CDK2 -- the cycle halts and no origins fire.")
  elseif not damaged and M.g1CheckpointAnnounced and not M.g1RepairAnnounced then
    M.g1RepairAnnounced = true
    M.ckiActive = false
    if M.p53Marker ~= nil then v:remove(M.p53Marker); M.p53Marker = nil end
    if M.g1CkiMarker ~= nil then removeEnzymeCluster(M.g1CkiMarker); M.g1CkiMarker = nil end
    local pos = rotateY(originAxisPos(ORIGIN_INDICES[1]), rotationAngle)
    spawnTimedEnzyme(pos, COL.CYCLIN_CDK_COL, 0.12, 5)
    print("G1 checkpoint passes: the damage is repaired, p21 is cleared, and cyclin " ..
          "E-CDK2 becomes active again, driving S-phase entry.")
  end
end

-- G2 checkpoint (phase 11): immediately before mitosis, the cell verifies
-- that the DNA has been copied completely and without errors. Damage --
-- uncorrected mutations that escaped proofreading AND mismatch repair, or
-- the live g2CheckpointDamage param -- blocks entry into mitosis: the CDK
-- inhibitor keeps cyclin B-CDK1 (MPF) inactive until the damage is
-- rectified (clear g2CheckpointDamage) or the block is overridden (the
-- live overrideG2Checkpoint param). Once passed, active MPF phosphorylates
-- mitotic targets and drives the cell into mitosis.
local function updateCellCycleCheckpoint()
  if not (M.mmrAnnounced and not M.g2Passed) then return end
  setPhase(11)
  local persistent = mutationStats.escaped - mutationStats.mmrCaught
  local g2Damage = v:getParam("g2CheckpointDamage")
  if (persistent > 0 or g2Damage) and not v:getParam("overrideG2Checkpoint") then
    if not M.g2Announced then
      M.g2Announced = true
      M.g2Arrested = true
      M.ckiActive = true
      local ckiPos = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 1.6), rotationAngle)
      M.g2CkiMarker = createEnzymeCluster(ckiPos, COL.CKI_COL, 0.1, 4)
      print(string.format(
        "G2 checkpoint: DNA replication verified complete, but damage is still present " ..
        "(%d uncorrected mutation(s) persist in the final genome%s).",
        persistent, g2Damage and " and g2CheckpointDamage is set" or ""))
      print("The CDK inhibitor binds cyclin B-CDK1 (MPF): entry into mitosis is blocked " ..
            "until the damage is rectified. Clear g2CheckpointDamage or set " ..
            "overrideG2Checkpoint to release the block.")
    end
    return
  end
  if not M.g2Passed then
    M.g2Passed = true
    M.g2Arrested = false
    M.ckiActive = false
    if M.g2CkiMarker ~= nil then removeEnzymeCluster(M.g2CkiMarker); M.g2CkiMarker = nil end
    local checkpointPos = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 1.6), rotationAngle)
    spawnTimedEnzyme(checkpointPos, COL.CYCLIN_CDK_COL, 0.15, 5)
    if M.g2Announced then
      print("G2 checkpoint passes: the damage is rectified -- active cyclin B-CDK1 (MPF) " ..
            "phosphorylates mitotic targets and drives the cell into mitosis.")
    else
      print(string.format(
        "G2 checkpoint passes: the DNA was copied completely and without errors " ..
        "(%d mutation(s) persist in the final genome) -- active cyclin B-CDK1 (MPF) " ..
        "phosphorylates mitotic targets and drives the cell into mitosis.",
        persistent))
    end
  end
end

-- Prophase (12): chromatin begins condensing (M.condensationProgress, see
-- basePos()), the original nuclear envelope -- shared by both sister
-- chromatids up to this point -- is shown briefly, then breaks down, and
-- the spindle apparatus begins to form as two centrosomes take up position
-- at opposite poles. Leftover fork markers (topoisomerase/helicase) are
-- cleaned up here too: vestigial by this point, and safe to remove
-- outright since neither ever had a constraint attached to it (unlike the
-- daughter-strand chain nucleotides, which do, and are deliberately left
-- alone here for exactly that reason -- removing a body while a
-- btPoint2PointConstraint still references it is a real crash/corruption
-- risk this file has no way to clean up, since those constraints were
-- never kept in a table to remove them by).

local function updateProphase()
  if not (M.g2Passed and not M.prophaseAnnounced) then return end
  if not M.prophaseStarted then
    M.prophaseStarted = true
    setPhase(12)
    setStage("M", "mitosis: PMAT + cytokinesis, the two-chromatid 2C chromosomes return to 1C")
    print("Chromatin begins condensing into a compact, visible chromosome as the cell " ..
          "commits to mitosis.")
    print("The mitotic CDK wave crests: cyclin B-CDK1 (MPF) is at its peak as the cell " ..
          "enters prophase.")
    for _, f in ipairs(forks) do
      if f.topoisomerase ~= nil then
        v:remove(f.topoisomerase)
        f.topoisomerase = nil
      end
      for _, hs in ipairs(f.helicase) do v:remove(hs) end
      f.helicase = {}
    end
    local center = rotateY(btVector3(0, 0, (CENTROMERE_BP - 1) * RISE), rotationAngle)
    M.breakdownEnvelope = createEnvelopeRing(center, ENVELOPE_RING_R, COL.ENVELOPE_COL)
    M.spindlePole1 = MoleculeBlob(0.35, 0, PROTEIN_ATOMS)
    M.spindlePole1.col = COL.SPINDLE_POLE_COL
    v:add(M.spindlePole1)
    M.spindlePole2 = MoleculeBlob(0.35, 0, PROTEIN_ATOMS)
    M.spindlePole2.col = COL.SPINDLE_POLE_COL
    v:add(M.spindlePole2)
    repositionMitosisMarkers() -- give the poles their first real position immediately
    print("The spindle apparatus begins to form as two centrosomes take up position at " ..
          "opposite poles.")
  end
  M.prophaseStepCounter = M.prophaseStepCounter + 1
  if M.prophaseStepCounter == PROPHASE_ENVELOPE_HOLD and M.breakdownEnvelope ~= nil then
    removeEnvelopeRing(M.breakdownEnvelope)
    M.breakdownEnvelope = nil
    print("The nuclear envelope breaks down.")
  end
  M.condensationProgress = math.min(1, M.prophaseStepCounter / PROPHASE_STEPS)
  if M.prophaseStepCounter >= PROPHASE_STEPS and not M.prophaseAnnounced then
    M.prophaseAnnounced = true
    print("Prophase complete: the chromosome is fully condensed and clearly visible.")
  end
end

-- Metaphase (13): the spindle fully forms -- a fiber reaches from each
-- pole to capture its own chromatid's centromere -- and holds the
-- (already essentially centered) chromosome at the equatorial plane.

local function updateMetaphase()
  if not (M.prophaseAnnounced and not M.metaphaseAnnounced) then return end
  if not M.metaphaseStarted then
    M.metaphaseStarted = true
    setPhase(13)
    local c1 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 0.8), rotationAngle)
    local c2 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 0.8), rotationAngle)
    M.spindleFiber1 = placeBlobCylinder(M.spindlePole1.pos, c1, BACKBONE_R, COL.SPINDLE_FIBER_COL)
    M.spindleFiber2 = placeBlobCylinder(M.spindlePole2.pos, c2, BACKBONE_R, COL.SPINDLE_FIBER_COL)
    print("The spindle apparatus is fully formed, its fibers reaching in to capture each " ..
          "sister chromatid's centromere.")
  end
  M.metaphaseStepCounter = M.metaphaseStepCounter + 1
  -- M checkpoint (spindle checkpoint): the cell only gives the signal for
  -- anaphase once every chromosome is correctly attached to the spindle.
  -- The live mCheckpointFail param simulates a misattached chromatid: APC/C
  -- stays inhibited, cyclin B is not yet degraded, and anaphase is blocked
  -- until every fiber is anchored (clear the param). This prevents daughter
  -- cells from receiving too many or too few chromosomes.
  if M.metaphaseStepCounter >= METAPHASE_STEPS and not M.mCheckpointPassed then
    if v:getParam("mCheckpointFail") then
      if not M.mCheckpointAnnounced then
        M.mCheckpointAnnounced = true
        M.mArrested = true
        M.ckiActive = true
        local ckiPos = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 1.6), rotationAngle)
        M.mCkiMarker = createEnzymeCluster(ckiPos, COL.CKI_COL, 0.1, 4)
        print("M checkpoint (spindle checkpoint): a sister chromatid is not correctly " ..
              "attached to the spindle -- APC/C stays inhibited, cyclin B is not yet " ..
              "degraded, and anaphase is blocked, preventing daughter cells from " ..
              "receiving too many or too few chromosomes.")
        print("Clear mCheckpointFail once every fiber is properly anchored to release the block.")
      end
    else
      M.mCheckpointPassed = true
      M.metaphaseAnnounced = true
      M.mArrested = false
      M.ckiActive = false
      if M.mCkiMarker ~= nil then removeEnzymeCluster(M.mCkiMarker); M.mCkiMarker = nil end
      local ckiPos = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 1.6), rotationAngle)
      spawnTimedEnzyme(ckiPos, COL.CYCLIN_CDK_COL, 0.15, 5)
      if M.mCheckpointAnnounced then
        print("M checkpoint satisfied: every spindle fiber is now properly anchored -- " ..
              "APC/C is released and the signal to separate is given.")
      else
        print("M checkpoint (spindle checkpoint) satisfied: every chromosome is correctly " ..
              "attached to the spindle -- the signal to separate is given.")
      end
      print("Metaphase complete: both chromatids are aligned at the equatorial plane, " ..
            "held by cohesin and captured by spindle fibers from both poles.")
    end
  end
end

-- Anaphase (14): cohesin dissolves at the centromere, and the spindle
-- fibers shorten (see repositionMitosisMarkers) as M.anaphaseProgress (see
-- basePos()) pulls each sister chromatid the rest of the way to its pole.

local function updateAnaphase()
  if not (M.metaphaseAnnounced and not M.anaphaseAnnounced) then return end
  if not M.anaphaseStarted then
    M.anaphaseStarted = true
    setPhase(14)
    if M.cohesinRing ~= nil then
      v:remove(M.cohesinRing)
      M.cohesinRing = nil
    end
    print("APC/C releases its inhibition and degrades cyclin B: the mitotic CDK wave " ..
          "crashes, inactivating CDK1 and allowing the cell to exit mitosis.")
    print("Cohesin dissolves at the centromere -- the spindle fibers shorten, pulling " ..
          "the sister chromatids apart toward opposite poles.")
  end
  M.anaphaseProgress = math.min(1, M.anaphaseProgress + 1 / ANAPHASE_STEPS)
  if M.anaphaseProgress >= 1 and not M.anaphaseAnnounced then
    M.anaphaseAnnounced = true
    print("Anaphase complete: two full sets of chromosomes now sit at opposite poles.")
  end
end

-- Post-mitotic re-coiling (see basePos): once anaphase has fully separated
-- the two finished daughter duplexes, each coils back into a compact,
-- visible double helix around its own center -- the two helix structures
-- the daughter cells carry away -- ramping M.recoilProgress 0->1 over
-- RECOIL_STEPS while telophase decondenses them and the new envelopes form
-- around each one. Rendered as the two strands of each duplex (the original
-- template plus its freshly synthesized partner) spiraling together around
-- that duplex's own axis.
function updateRecoil()
  if not (M.anaphaseAnnounced and M.recoilProgress < 1) then return end
  M.recoilProgress = math.min(1, M.recoilProgress + 1 / RECOIL_STEPS)
  if M.recoilProgress >= 1 and not M.recoilAnnounced then
    M.recoilAnnounced = true
    print("The two finished daughter double helices coil back into their compact spiral " ..
          "forms -- a full double helix now sits at each pole, one per daughter cell.")
  end
end

-- Telophase (15): the spindle disassembles, each chromatid decondenses
-- back toward its original, relaxed length (M.condensationProgress reverses
-- here), and a new nuclear envelope ring forms around each pole's set.

local function updateTelophase()
  if not (M.anaphaseAnnounced and not M.telophaseAnnounced) then return end
  if not M.telophaseStarted then
    M.telophaseStarted = true
    setPhase(15)
    if M.spindleFiber1 ~= nil then v:remove(M.spindleFiber1); M.spindleFiber1 = nil end
    if M.spindleFiber2 ~= nil then v:remove(M.spindleFiber2); M.spindleFiber2 = nil end
    if M.spindlePole1 ~= nil then v:remove(M.spindlePole1); M.spindlePole1 = nil end
    if M.spindlePole2 ~= nil then v:remove(M.spindlePole2); M.spindlePole2 = nil end
    local c1 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 0.8), rotationAngle)
    local c2 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 0.8), rotationAngle)
    M.newEnvelopeRing1 = createEnvelopeRing(c1, NEW_ENVELOPE_RING_R, COL.ENVELOPE_COL)
    M.newEnvelopeRing2 = createEnvelopeRing(c2, NEW_ENVELOPE_RING_R, COL.ENVELOPE_COL)
    print("The spindle apparatus disassembles as the chromosomes begin to decondense " ..
          "and a new nuclear envelope forms around each pole's set.")
  end
  M.telophaseStepCounter = M.telophaseStepCounter + 1
  M.condensationProgress = math.max(0, 1 - M.telophaseStepCounter / TELOPHASE_STEPS)
  if M.telophaseStepCounter >= TELOPHASE_STEPS and not M.telophaseAnnounced then
    M.telophaseAnnounced = true
    print("Telophase complete: the chromosomes have decondensed and nuclear division " ..
          "is complete.")
  end
end

-- Cytokinesis (16): the cytoplasm itself divides, each new nucleus getting
-- its own cell membrane -- the final step, producing two independent,
-- genetically identical daughter cells.

-- A sparse ring of CYTOKINESIS_RING_N small markers centered at the
-- cleavage-plane midpoint (0, 0, centromere Z), offset in the Y-Z plane
-- (facing the camera, which sits out along world X -- see updateCamera),
-- at radius `ringR` -- the stand-in for both the animal cleavage furrow
-- (shrinking) and the plant cell plate (growing). The midpoint lies on
-- the helix's own Z axis, a fixed point under rotateY, so these markers
-- never need per-frame repositioning (same reasoning as originAxisPos).
local function setCytokinesisRingRadius(ring, ringR)
  for k, m in ipairs(ring) do
    local a = (k - 1) * (2 * math.pi / CYTOKINESIS_RING_N)
    m.pos = btVector3(0, ringR * math.cos(a), (CENTROMERE_BP - 1) * RISE + ringR * math.sin(a))
  end
end

local function createCytokinesisRing(ringR, col)
  local ring = {}
  for k = 0, CYTOKINESIS_RING_N - 1 do
    local m = MoleculeBlob(0.1, 0, SINGLE_ATOM)
    m.col = col
    v:add(m)
    ring[#ring + 1] = m
  end
  setCytokinesisRingRadius(ring, ringR)
  return ring
end

local function removeCytokinesisRing(ring)
  if ring == nil then return end
  for _, m in ipairs(ring) do v:remove(m) end
end

-- Spawns MITOCHONDRION_COUNT mitochondria near daughter cell `cellSign`
-- (+1 or -1, its Z sign from decatenation/anaphase separation), each at a
-- random (dy, dz) offset within its cell's membrane disk, in the
-- pre-rotation frame; repositionMitosisMarkers rotates them into place
-- every frame so they stay in step with the cell they belong to.
local function spawnMitochondria(list, cellSign)
  for _ = 1, MITOCHONDRION_COUNT do
    local m = MoleculeBlob(0.13, 0, MITO_ATOMS)
    m.col = COL.MITOCHONDRION_COL
    v:add(m)
    list[#list + 1] = {
      obj = m,
      dy = (math.random() * 2 - 1) * 2.2,
      dz = (math.random() * 2 - 1) * 2.2,
      cell = cellSign,
    }
  end
end

-- Rebuilds the hydrogen-bond rungs of the central double helix, which the
-- previous generation's forks removed one by one as they unwound it. The
-- two original strands are still present (their tether anchors follow
-- basePos), so a fresh, intact chromosome reappears -- the daughter cell's
-- own double helix beginning its cycle. rotateSceneGeometry re-spans every
-- rung from the live base positions each frame, so small settling errors
-- here self-correct immediately.
function rebuildRungs()
  for i = 1, NBP do
    if rungs[i] == nil then
      local rungR = (strand1[i] == "A" or strand1[i] == "T") and RUNG_R_WEAK or RUNG_R_STRONG
      rungs[i] = createRungCylinders(baseSpheres1[i].pos, baseSpheres2[i].pos,
                                     BASE_COLOR[strand1[i]], BASE_COLOR[strand2Base(i)], rungR)
    end
  end
end

-- Re-initializes the origin/ORC machinery for a fresh generation: rebuilds
-- the origins table (unresolved, unlicensed, no MCM markers yet) and places
-- a new ORC marker at each origin sequence, whose rung is re-marked bright
-- orange. Returns the fresh table; see transitionToNextGeneration.
function reinitOrigins()
  local fresh = {}
  for k, index in ipairs(ORIGIN_INDICES) do
    local rung = rungs[index]
    if rung ~= nil then
      rung.col1, rung.col2 = COL.ORIGIN_COL, COL.ORIGIN_COL
      if rung.cy1 ~= nil then rung.cy1.col = COL.ORIGIN_COL end
      if rung.cy2 ~= nil then rung.cy2.col = COL.ORIGIN_COL end
    end
    local orc = Cube(0.2, 0.2, 0.2, 0)
    orc.col = COL.ORC_COL
    orc.pos = originAxisPos(index)
    v:add(orc)
    fresh[k] = {
      index = index,
      A = ORIGIN_A[k],
      C = ORIGIN_C[k],
      resolved = false,
      licensed = false,
      orcMarker = orc,
      mcmMarker = nil,
    }
  end
  return fresh
end

-- Moves the demo into the next generation's cell cycle (see
-- updateCytokinesis): cleans up the finished generation's visual artifacts
-- (mitochondria, membrane/envelope rings, histones, cohesin, stray SSBs),
-- coils the daughter chromosome back into an intact double helix, rebuilds
-- its rungs and origin licensing markers, and resets every per-generation
-- piece of the fork/mitosis machinery -- so the G1 ramp, S-phase origin
-- firing and fork synthesis, G2 checkpoint, and the next PMAT + cytokinesis
-- all genuinely re-run. The previous generation's two daughter strands stay
-- in the scene (their physics constraints are not removable) as the settled
-- chromosomes of the earlier cell; this generation's new strands are laid
-- down as the next outer layer (M.genOutwardOffset). The two daughter cells
-- of a division carry the same genetic information (semi-conservative
-- replication of identical sequences), so following one lineage this way is
-- exact.
function transitionToNextGeneration()
  M.generation = M.generation + 1
  for _, mito in ipairs(M.mitochondria1) do v:remove(mito.obj) end
  for _, mito in ipairs(M.mitochondria2) do v:remove(mito.obj) end
  M.mitochondria1, M.mitochondria2 = {}, {}
  removeEnvelopeRing(M.membraneRing1); M.membraneRing1 = nil
  removeEnvelopeRing(M.membraneRing2); M.membraneRing2 = nil
  removeEnvelopeRing(M.newEnvelopeRing1); M.newEnvelopeRing1 = nil
  removeEnvelopeRing(M.newEnvelopeRing2); M.newEnvelopeRing2 = nil
  for _, h in ipairs(M.histoneMarkers) do v:remove(h.obj) end
  M.histoneMarkers = {}
  if M.cohesinRing ~= nil then v:remove(M.cohesinRing); M.cohesinRing = nil end
  for i = 1, NBP do
    local markers = ssbMarkers[i]
    if markers ~= nil then
      v:remove(markers[1]); v:remove(markers[2])
      ssbMarkers[i] = nil
    end
  end

  -- A fresh chromosome: the daughter cell's DNA coils back into its intact
  -- double helix before the new S phase re-unwinds it.
  M.untwistProgress = 0
  M.decatenationProgress = 0
  M.anaphaseProgress = 0
  M.condensationProgress = 0
  M.recoilProgress = 0
  M.recoilAnnounced = false
  rebuildRungs()
  origins = reinitOrigins()
  retiredForkGroups[#retiredForkGroups + 1] = forks
  forks = {}
  claimedUnwind = {}
  claimedSynth = {}
  mutationSites = {}
  mutationStats = { attempted = 0, caught = 0, escaped = 0, mmrCaught = 0 }
  M.totalSynthesized = 0
  M.replicationAnnounced = false
  M.untwistAnnounced = false
  M.decatenationAnnounced = false
  M.chromatinStarted = false
  M.chromatinStepCounter = 0
  M.chromatinSpawnIndex = 0
  M.chromatinAnnounced = false
  M.mmrStarted = false
  M.mmrStepCounter = 0
  M.mmrIndex = 0
  M.mmrMarker = nil
  M.mmrAnnounced = false
  M.prophaseStarted = false
  M.prophaseStepCounter = 0
  M.prophaseAnnounced = false
  M.breakdownEnvelope = nil
  M.metaphaseStarted = false
  M.metaphaseStepCounter = 0
  M.metaphaseAnnounced = false
  M.anaphaseStarted = false
  M.anaphaseAnnounced = false
  M.telophaseStarted = false
  M.telophaseStepCounter = 0
  M.telophaseAnnounced = false
  M.cytokinesisStarted = false
  M.cytokinesisStepCounter = 0
  M.cytokinesisAnnounced = false
  M.cleavageFurrow = nil
  M.cellPlate = nil
  M.cyclinB = 0
  M.ckiActive = false
  M.g1CheckpointAnnounced = false
  M.g1RepairAnnounced = false
  M.p53Marker = nil
  M.g1CkiMarker = nil
  M.g2Passed = false
  M.g2Arrested = false
  M.g2Announced = false
  M.g2CkiMarker = nil
  M.mCheckpointAnnounced = false
  M.mCheckpointPassed = false
  M.mArrested = false
  M.mCkiMarker = nil
  M.phiRampProgress = 0
  M.genOutwardOffset = M.genOutwardOffset + GEN_LAYER_SPACING
  currentPhase = 0
  M.currentStage = nil
  setStage("G1", "generation " .. M.generation .. ": the daughter cell begins the interphase " ..
           "of its own new cell cycle -- G1 growth -> S replication -> G2 preparation, " ..
           "then the next mitosis")
  print("Generation " .. M.generation .. " begins: we follow the daughter cell's lineage. " ..
        "Its chromosome, carried down intact from the first division, coils back into " ..
        "a fresh double helix and starts its own G1.")
end

-- Cytokinesis (16): the actual physical division of the whole cell --
-- mitosis only duplicated the nucleus; this divides the cytoplasm, sharing
-- its organelles between the two daughter regions. Animal cells pinch
-- themselves apart via a contractile actin ring (the cleavage furrow);
-- plant cells, unable to constrict through their rigid wall, instead grow
-- a cell plate outward from the center to build a new dividing wall. Only
-- once the furrow has closed / the plate has formed do the two independent
-- cells each get their own cell membrane. With the live enterG0 param set,
-- the daughters then exit the cycle into the G0 resting phase and never
-- divide again; otherwise the demo follows the lineage into the next
-- generation (see transitionToNextGeneration), re-running the full cycle on
-- the semi-conservatively inherited DNA until MAX_GENERATIONS is reached.
local function updateCytokinesis()
  if not (M.telophaseAnnounced and not M.cytokinesisAnnounced) then return end
  if not M.cytokinesisStarted then
    M.cytokinesisStarted = true
    setPhase(16)
    spawnMitochondria(M.mitochondria1, 1)
    spawnMitochondria(M.mitochondria2, -1)
    print("The cytoplasm and its organelles (mitochondria) are distributed between the " ..
          "two daughter regions as cell division proceeds.")
    if v:getParam("plantCell") then
      M.cellPlate = createCytokinesisRing(0.1, COL.CELL_PLATE_COL)
      print("Cytokinesis (plant cell): a cell plate forms in the center and grows from " ..
            "the inside out, building a new dividing wall through the rigid cell wall.")
    else
      M.cleavageFurrow = createCytokinesisRing(CELL_MEMBRANE_RING_R * 1.3, COL.CLEAVAGE_FURROW_COL)
      print("Cytokinesis (animal cell): a ring of actin fibers constricts the cell in the " ..
            "middle, forming a cleavage furrow that pinches the cytoplasm apart.")
    end
  end

  M.cytokinesisStepCounter = M.cytokinesisStepCounter + 1
  local progress = math.min(1, M.cytokinesisStepCounter / CYTOKINESIS_STEPS)
  if M.cleavageFurrow ~= nil then
    -- Constriction: the furrow shrinks from just outside the membrane
    -- radius down toward the cleavage plane as the ring tightens.
    setCytokinesisRingRadius(M.cleavageFurrow,
                             math.max(0.15, CELL_MEMBRANE_RING_R * 1.3 * (1 - progress)))
  elseif M.cellPlate ~= nil then
    -- The plate grows from the center outward until it spans the cell.
    setCytokinesisRingRadius(M.cellPlate, CELL_MEMBRANE_RING_R * progress)
  end

  if M.cytokinesisStepCounter >= CYTOKINESIS_STEPS and not M.cytokinesisAnnounced then
    M.cytokinesisAnnounced = true
    removeCytokinesisRing(M.cleavageFurrow)
    M.cleavageFurrow = nil
    removeCytokinesisRing(M.cellPlate)
    M.cellPlate = nil
    local c1 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 1), 0.8), rotationAngle)
    local c2 = rotateY(outwardOffset(basePos(CENTROMERE_BP, 2), 0.8), rotationAngle)
    M.membraneRing1 = createEnvelopeRing(c1, CELL_MEMBRANE_RING_R, COL.ENVELOPE_COL)
    M.membraneRing2 = createEnvelopeRing(c2, CELL_MEMBRANE_RING_R, COL.ENVELOPE_COL)
    print("Cytokinesis divides the cytoplasm: two independent, genetically identical " ..
          "daughter cells now exist -- mitosis of generation " .. M.generation .. " is complete.")
    if v:getParam("enterG0") then
      setStage("G0", "the daughter cells exit the cell cycle after G1 and enter the resting phase, performing their specialized functions and generally never dividing again")
      print("Both daughter cells leave the cell cycle and enter the G0 resting phase.")
    elseif M.generation < MAX_GENERATIONS then
      M.pendingTransition = true
      M.genHoldCounter = GEN_HOLD_STEPS
    else
      print("Generation " .. M.generation .. " complete: the two daughter cells of the first " ..
            "division have each divided again -- four double helices now exist, every one " ..
            "carrying the same genetic information. Two rounds of semi-conservative " ..
            "replication have propagated the genome intact.")
    end
  end
end

-- sceneReach helpers: reach starts as an accumulator and each call
-- returns the possibly-updated running max (Lua has no by-reference
-- numbers, so the return value IS the update).
local function trackPos(reach, look, pos)
  local dx, dy, dz = pos.x - look.x, pos.y - look.y, pos.z - look.z
  local d = math.sqrt(dx * dx + dy * dy + dz * dz)
  if d > reach then return d end
  return reach
end

local function trackObj(reach, look, obj)
  if obj == nil then return reach end
  return trackPos(reach, look, obj.pos)
end

-- A plain array of Objects, each with .pos directly -- the ring/cluster
-- lists (createEnvelopeRing/createCytokinesisRing/createEnzymeCluster)
-- used throughout this file.
local function trackObjList(reach, look, list)
  if list == nil then return reach end
  for _, obj in ipairs(list) do
    reach = trackPos(reach, look, obj.pos)
  end
  return reach
end

-- An array of { obj = Object, ... } wrapper records -- floatingMolecules/
-- histoneMarkers/mitochondria-style lists.
local function trackWrappedList(reach, look, list)
  if list == nil then return reach end
  for _, entry in ipairs(list) do
    reach = trackPos(reach, look, entry.obj.pos)
  end
  return reach
end

local function trackForkGroup(reach, look, forkList)
  for _, f in ipairs(forkList) do
    reach = trackObj(reach, look, f.leadAnchor)
    for _, p in ipairs(f.lagPrimers) do
      reach = trackObj(reach, look, p.obj)
    end
    for _, b in ipairs(f.leadBackbone) do
      reach = trackObj(reach, look, b.a)
      reach = trackObj(reach, look, b.b)
    end
    for _, b in ipairs(f.lagBackbone) do
      reach = trackObj(reach, look, b.a)
      reach = trackObj(reach, look, b.b)
    end
  end
  return reach
end

-- True (not heuristic) scene extent: the largest distance from `look`
-- among every object this file tracks in a Lua-side table. There's no
-- Viewer:getObjects() to enumerate the live scene generically, so this
-- walks the same collections rotateSceneGeometry/postSim already
-- maintain -- including every earlier generation's own retired forks
-- (see retiredForkGroups), which stay visible forever as that
-- generation's settled daughter helix/helices. A handful of small,
-- always-central markers (ORC/MCM origin flags, rung cylinders, SSB
-- pairs) are left out since they sit at or inside basePos-derived
-- positions already covered by the two template strands below.
local function sceneReach(look)
  local reach = 0
  for i = 1, NBP do
    reach = trackObj(reach, look, baseSpheres1[i])
    reach = trackObj(reach, look, baseSpheres2[i])
  end
  reach = trackWrappedList(reach, look, floatingMolecules)
  reach = trackWrappedList(reach, look, M.histoneMarkers)
  reach = trackWrappedList(reach, look, M.mitochondria1)
  reach = trackWrappedList(reach, look, M.mitochondria2)
  reach = trackForkGroup(reach, look, forks)
  for _, group in ipairs(retiredForkGroups) do
    reach = trackForkGroup(reach, look, group)
  end
  reach = trackObj(reach, look, M.spindlePole1)
  reach = trackObj(reach, look, M.spindlePole2)
  reach = trackObjList(reach, look, M.newEnvelopeRing1)
  reach = trackObjList(reach, look, M.newEnvelopeRing2)
  reach = trackObjList(reach, look, M.membraneRing1)
  reach = trackObjList(reach, look, M.membraneRing2)
  reach = trackObjList(reach, look, M.breakdownEnvelope)
  reach = trackObjList(reach, look, M.cleavageFurrow)
  reach = trackObjList(reach, look, M.cellPlate)
  reach = trackObj(reach, look, M.p53Marker)
  reach = trackObjList(reach, look, M.g1CkiMarker)
  reach = trackObjList(reach, look, M.g2CkiMarker)
  reach = trackObjList(reach, look, M.mCkiMarker)
  for _, tm in ipairs(timedMarkers) do
    reach = trackObjList(reach, look, tm.cluster)
  end
  return reach
end

-- Dynamic camera: keeps EVERY currently-live object framed as the scene's
-- spatial extent changes dramatically across phases -- a compact ~1-2
-- unit-radius helix during S phase, but a much wider mitotic spindle
-- apparatus by anaphase, at a different absolute position again once
-- generation 2 begins. The original single, fixed common.setCamera call
-- below (kept as the frame-1 default) could not keep pace with that range
-- once mitosis/generations were added -- confirmed by rendering: several
-- later frames showed nothing but background floating molecules, with the
-- real action having drifted entirely outside a fixed, narrow field of
-- view. A first fix used a small heuristic (centromere separation + a few
-- known marker radii); this is the genuinely robust version, built from
-- sceneReach's true max-distance-from-look sweep over every tracked
-- object.
--
-- look tracks the midpoint between both chromatids' centromere positions
-- -- the same CENTROMERE_BP reference point already used throughout the
-- mitosis machinery above -- so it's always defined, even before the two
-- chromatids exist as visibly separate things (both chainPos calls just
-- agree until decatenation actually starts pulling them apart), and stays
-- close to the true centroid of everything else being tracked. distance
-- grows along with reach (not just fov) so the camera never ends up
-- uncomfortably close to (or inside) its own bounding sphere once reach
-- gets large. halfWidth = 2.4 reproduces the original fixed camera's own
-- framing (48 * tan(0.1/2) ~= 2.4) when reach is 0, so early frames look
-- just like they did before this became dynamic.
local function updateCamera()
  local c1 = chainPos(CENTROMERE_BP, 1)
  local c2 = chainPos(CENTROMERE_BP, 2)
  local look = btVector3((c1.x + c2.x) * 0.5, (c1.y + c2.y) * 0.5, (c1.z + c2.z) * 0.5)

  local reach = sceneReach(look)
  local halfWidth = 2.4 + reach
  local distance = math.max(48, reach * 3)
  local fov = 2 * math.atan(halfWidth / distance)

  local offsetLen = math.sqrt(48 * 48 + 2 * 2) -- the original camera's own (48,10,0)-(0,8,0) offset
  local pos = btVector3(
    look.x + 48 / offsetLen * distance,
    look.y + 2 / offsetLen * distance,
    look.z)

  v.cam:setFieldOfView(fov)
  v.cam.pos = pos
  v.cam.look = look

  -- Status text: pinned near the bottom edge of whatever's currently in
  -- view -- visibleHalfHeight is the true (not approximated) vertical
  -- half-extent of the frame at the look plane, so this tracks the
  -- camera's own zoom exactly instead of drifting off-frame at some zoom
  -- levels and not others.
  if M.statusText ~= nil then
    local visibleHalfHeight = distance * math.tan(fov / 2)
    M.statusText.pos = btVector3(look.x, look.y - visibleHalfHeight * 0.82, look.z)
  end
end

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
  updateG1Checkpoint()
  if M.apoptosis then
    -- The cell is dying: keep the helix gently spinning but freeze the cell
    -- cycle -- no further phases, no new events.
    rotationAngle = rotationAngle + ROTATION_SPEED
    rotateSceneGeometry()
    return
  end
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
    M.phiRampProgress = M.phiRampProgress + 1
  end
  local phi = checkpointActive and CHECKPOINT_PHI or math.min(1, M.phiRampProgress / PHI_RAMP_STEPS)
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
        mcm.col = COL.MCM_COL
        mcm.trans = btTransform(AXIS_RING_ROT, originAxisPos(o.index))
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
          setPhase(2) -- this fork's createFork() already laid its first primer
          setStage("S", "the DNA is completely duplicated (replication): each 1C chromosome becomes a two-chromatid 2C chromosome once again")
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
        m1.col = COL.SSB_COL
        m1.pos = rotateY(basePos(nextI, 1), rotationAngle)
        v:add(m1)
        local m2 = MoleculeBlob(0.06, 0, PROTEIN_DOMAIN_ATOMS)
        m2.col = COL.SSB_COL
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
        -- Set before extending: extendLeadingStrand's very first call for a
        -- fork replaces that fork's leading primer immediately (see below)
        -- and would otherwise call setPhase(4) before Phase 3 ever got
        -- announced, silently skipping it under setPhase's monotonic guard.
        setPhase(3)
        extendLeadingStrand(f, nextI)
        extendLaggingStrand(f, nextI)
        f.synthPos = nextI
        M.totalSynthesized = M.totalSynthesized + 1
      end
    end
  end

  if M.totalSynthesized >= NBP and not M.replicationAnnounced then
    M.replicationAnnounced = true
    setPhase(5)
    setStage("G2", "the cell continues to grow, checks the replicated DNA for errors, and makes final preparations for mitosis")
    print("Generation " .. M.generation .. ": replication complete -- two double helices " ..
          "now exist, each with one original strand and one newly synthesized strand.")
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
    setPhase(6)
    print("Both new double helices begin to untwist, relaxing out of their spiral " ..
          "shape now that no more torsional stress needs to be held.")
  end

  -- Untwisting itself (see basePos()): ramps once replication is complete,
  -- independent of the announcement block above so it keeps advancing every
  -- step afterward, not just the one step M.replicationAnnounced flips.
  if M.replicationAnnounced and M.untwistProgress < 1 then
    M.untwistProgress = math.min(1, M.untwistProgress + 1 / UNTWIST_STEPS)
    if M.untwistProgress >= 1 and not M.untwistAnnounced then
      M.untwistAnnounced = true
      setPhase(7)
      print("Both new double helices have fully untwisted into straight, unwound strands.")
    end
  end

  -- Decatenation, chromatin repackaging, mismatch repair, and the final
  -- checkpoint (phases 8-11) each live in their own top-level function --
  -- see updateDecatenation/updateChromatinPackaging/updateMismatchRepair/
  -- updateCellCycleCheckpoint above -- rather than inline here. Lua 5.1
  -- cap: a single closure gets at most 60 upvalues, and postSim already
  -- captures most of this file's shared state directly; four more blocks
  -- of phase-8-11 locals pushed it over that limit. Splitting them into
  -- separate functions means postSim only needs one upvalue per function
  -- (the function reference itself) instead of one per local it touches.
  updateDecatenation()
  updateChromatinPackaging()
  updateMismatchRepair()
  updateCellCycleCheckpoint()
  -- Mitosis (phases 12-16): PMAT + cytokinesis, same split-into-functions
  -- reasoning as the four calls above.
  updateProphase()
  updateMetaphase()
  updateAnaphase()
  updateRecoil()
  updateTelophase()
  updateCytokinesis()
  -- The cyclin/CDK wave is updated last, so a checkpoint that fired during
  -- this same step immediately holds the wave back.
  updateCyclinWave()
  -- A finished generation holds a few steps so the completed division stays
  -- on screen, then coils back and begins the next generation's cycle.
  if M.pendingTransition then
    M.genHoldCounter = M.genHoldCounter - 1
    if M.genHoldCounter <= 0 then
      M.pendingTransition = false
      transitionToNextGeneration()
    end
  end

  updateCamera()
end)

-- Frame-1 fallback only -- updateCamera (see postSim) overrides pos/look/
-- fov on every step from the very first one, before any frame is ever
-- rendered/exported, so these particular numbers are never actually seen.
common.setCamera(btVector3(48, 10, 0), btVector3(0, 0, 8), 0.1)

-- EOF
