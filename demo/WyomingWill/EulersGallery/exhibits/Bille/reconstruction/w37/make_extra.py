"""Text and tables for the build guide (final/extra.json), with every number taken
from the design summaries, robustness logs, slicer checks and simulation tallies."""
import json, re, os
from materials import CAT
F = "final"
PR = "../../print/w37"          # the published print files (STL, PDF, figures, slicer checks)
def src(fn):
    """a design output: final/ (where finalize.sh writes it) or ../../print/w37/ (where it is published)"""
    return f"{F}/{fn}" if os.path.exists(f"{F}/{fn}") else f"{PR}/{fn}"
def J(fn): return json.load(open(fn))
REC = J(f"{F}/w37-W-summary.json"); ALT = J(f"{F}/w37-St-summary.json")
SLC = J(src("w37-W.gcode.check.json")); SLA = J(src("w37-St.gcode.check.json"))
SIM = J(f"{F}/sim-tally.json") if os.path.exists(f"{F}/sim-tally.json") else None
MAT = J("runs/materials.json")
WR = CAT[REC['weight']]; WA = CAT[ALT['weight']]
COUP = J(f"{F}/coupons.json")

def robust_rows(fn):
    rows = {}
    for line in open(fn):
        m = re.match(r"(.{28}) +([\d.]+)% +([\d.]+)% +([\d.]+)% +([\d.]+)% +([-\d.na]+)", line)
        if m: rows[m.group(1).strip()] = [float(m.group(i)) for i in (2, 3, 4, 5)] + [m.group(6)]
    return rows
RR = robust_rows(f"{F}/robust-W.log"); RA = robust_rows(f"{F}/robust-St.log")
def pct(rows, k): return f"{rows[k][3]:.0f}" if k in rows else "–"
def best(w):
    c = [d for d in MAT if d['weight'] == w]
    return max(c, key=lambda d: d['margin']) if c else None

E = {}
import numpy as np
from w37 import Body
_B = Body(np.array(REC['x']), WR)
_nz = sorted(set(round(f[0][2], 4) for f in _B.faces if f[0][2] > -0.99999))
OVH = [np.degrees(np.arcsin(max(0, -z))) for z in _nz]           # S1, S2, ... overhang from vertical
Z1 = REC['x'][6]; Z2 = REC['x'][7]; R0 = REC['x'][0]
mrec = min(REC['face'], REC['vert']); malt = min(ALT['face'], ALT['vert'])
E["W"] = dict(wm=WR.m, comb3=pct(RR, "combined (planes 0.3)"), p2=f"{RR['planes 0.2 mm'][0]:.0f}")
E["St"] = dict(wm=WA.m, comb3=pct(RA, "combined (planes 0.3)"))
H = REC['H'] = REC['x'][-1]; ALT['H'] = ALT['x'][-1]
tW = SLC['meta'].get('time', '?'); tA = SLA['meta'].get('time', '?')

E["answer"] = (
 f"Yes, but the <b>shape</b> of the weight matters as much as its density. What has to fit is 37 equal weights, each pressed as close "
 f"to its corner as the walls allow, and the six corners of each of the three bottom rings sit in a nearly flat dish only "
 f"a few millimetres apart. Tall, narrow, dense pieces win. <b>Recommended:</b> 37 tungsten pinewood-derby cylinders, 3/8\" × 0.44\" "
 f"(0.5 oz, {WR.m:.2f} g), in a {H:.0f} mm body: smallest margin {mrec:.1f} mm. <b>Cheaper, and it works but with a third of the margin:</b> 37 hardened-steel "
 f"dowel pins 10 × 20 mm ({WA.m:.2f} g) in a {ALT['H']:.0f} mm body: margin {malt:.1f} mm. Tungsten putty (about 2.7 mm) and cut lead rod (about 2.7 mm) also work. "
 f"<b>Steel or lead balls do not:</b> no ball size we tried gives a monostable body that fits a 220 mm printer (best: lead .535\", +0.8 mm, too little; "
 f"steel balls −2 to −12 mm). Coins and bismuth shot do not fit or are too light (Section 2).")

E["sec1"] = [
 "This is a convex polyhedron with 37 flat faces and 37 corners: a pointed apex above six horizontal regular hexagons, "
 "each turned and sized so that the side faces form a spiral of bands (S1 next to the base, up to S6 under the apex). "
 "Set down on any face, it tips onto the face below it, band by band (S6 → S5 → … → S1 → base), and it stays only on its base. "
 "Stood on its apex it falls off; no other corner can balance it. So it has exactly <b>one stable</b> and <b>one unstable</b> equilibrium. "
 "That makes it a <i>mono-monostatic</i> body, a discrete relative of the Gömböc.",
 "The Gömböc (Várkonyi &amp; Domokos, 2006) is a smooth, uniform solid with one stable and one unstable balance point. "
 "For polyhedra, Conway and Guy (1969) built a uniform one that rests on only one face but has several unstable corners. "
 "Whether a <i>uniform</i> polyhedron can have one of each is still open. Domokos and Kovács (2023) showed that a polyhedron "
 "<b>can</b> if its mass is concentrated in equal point masses at its corners, with weightless faces. Their example is Conway's spiral with 21 corners. "
 "This body is the 37-corner (6,6) member of the same family, which is what the gallery uses. The extra corners make it far more tolerant of real faces "
 "that have weight. Here the 'point masses' are real tungsten (or steel) pieces in printed pockets, and the 'weightless faces' are 0.8 mm PLA walls, "
 f"which make up {100*REC['m_pla']/REC['M']:.0f}% of the mass. The ring sizes and heights were refitted for that real mass distribution."]

E["theory"] = [
 "<b>Faces.</b> A body can rest on a face only if the point straight below its centre of mass falls <i>inside</i> that face. "
 "If it falls outside, the body tips over the nearest edge. The design puts the foot of the centre of mass just outside every side face, on the side of the band below, "
 f"and well inside the base ({REC['base']:.1f} mm in from the base's edge).",
 "<b>Corners.</b> A corner can balance the body only if the centre of mass lies inside that corner's narrow 'balance cone', which is set by the faces that meet there. "
 "Only the apex's cone contains it.",
 f"<b>Margin.</b> This is how far the centre of mass would have to move before a second rest face or balance corner appeared. Every other face's foot is at least "
 f"<b>{REC['face']:.2f} mm</b> outside it, and the centre of mass is at least <b>{REC['vert']:.2f} mm</b> from any other corner's cone. "
 "Build errors move the centre of mass and tilt the faces. They break the body only if they add up to more than this.",
 "<b>Why weights in the corners.</b> Equal weights at the corners pull the centre of mass to where the spiral shape needs it: low, and close to the axis. "
 "Plastic spread over the faces pulls the centre of mass back toward the middle of the shape. The gallery's study found that the 37-corner spiral survives "
 "only up to about 18% of its mass spread evenly over the faces. Weights set in from the corners also work against it, because the design wants the mass "
 "<i>at</i> the corners. The design is a balance of these effects. A <b>denser</b> weight has a smaller volume for the same mass, so its centre can sit closer "
 "to the corner tip, and the plastic is a smaller share of the total mass."]

E["cap_section"] = (f"Cut through two opposite corners, as designed: PLA in blue, tungsten cylinders in grey, centre of mass (+) {REC['com'][2]:.1f} mm above the bed. "
 "Dashed lines mark the seven pauses. Each corner has a pocket in a small solid block whose underside slopes at 45°, so it prints without support. "
 "The rest of the inside is a closed, empty void.")

E["real"] = [
 "<b>The gallery's own 9 cm design cannot be built as stated.</b> A 5.2 g tungsten weight is an 8.0 mm ball or a 6.5 mm cube. It cannot sit 3 mm inside a corner, "
 "and the corners of the three bottom rings are only 2.8–3.8 mm apart, so neighbouring weights would overlap. The same holds for its 26-corner sibling "
 "(weights 3.8–4.1 mm apart near the base, centres 1.1–2.5 mm from the face planes). The gallery now describes both as idealised designs "
 "(exhibits/Bille/reconstruction/w37/fitcheck.py). Every design here uses real pocket geometry: "
 "each weight is placed as close to its corner as 0.8 mm walls allow (worked out exactly from the faces that meet there), with at least 0.8 mm of PLA "
 "between neighbouring pockets. The rings were then refitted.",
 f"<b>Size.</b> A bigger body makes the shell heavier (it grows with size²) while the weights stay the same. A smaller one crowds the bottom pockets. "
 f"For the 0.5 oz cylinders the best height is about 200 mm: the margin is 3.7, 3.9, 4.0, 4.0 and 2.5 mm at 180, 190, 200, 220 and 240 mm.",
 "<b>Printing.</b> The body is printed base-down in one piece, with a pause at each ring height to drop the weights into open pockets. "
 f"The bottom band S1 rises only {Z1:.2f} mm ({OVH[0]:.0f}° from vertical), so it is printed in the first {int(np.ceil(Z1/0.2))} layers, and S2 overhangs {OVH[1]:.0f}° up to {Z2:.1f} mm. "
 "Mid-layer slicing and some droop make these bands slightly flatter, which only enlarges the base (tested in Section 8)."]

E["sec2"] = [
 "Every option below was treated the same way. The weight's real shape sets its pocket, and its pocket sets how close to the corner it can sit. "
 "The ring radii and heights were refitted for that weight at the size shown, with exact mass properties: PLA shell, pocket blocks, pocket voids, weights and glue. "
 "The <b>margin</b> is the smallest distance the centre of mass could move before the body gains a second rest face or balance corner. "
 "Negative means the refitted body is still not monostable. Densities are nominal; <b>weigh your pieces</b>."]

def row(w, name, dens, form, note):
    d = best(w)
    if d is None: return None
    W = CAT[w]
    return [name, f"{dens}", f"{W.m:.1f} g", f"{d['H']}", f"<b>{d['margin']:+.1f}</b>", f"{100*d['pla']/d['mass']:.0f}%", note]
tab = [["weight (stock form)", "density g/cm³", "mass each", "height mm", "margin mm", "PLA share", "notes"]]
for args in [
 ("W-cyl-3/8x.44", "tungsten cylinder 3/8\" × 0.44\" (0.5 oz, pinewood derby)", "17.8", "", f"<b>recommended</b>; ≈ US$5 each in derby sets; {RR['planes 0.2 mm'][0]:.0f}% at 0.2 mm face errors"),
 ("W-ball-12", "tungsten-alloy ball 12 mm (W-Ni-Fe)", "≈18", "", "good; industrial or balancing suppliers"),
 ("Wputty-cyl-10x12", "tungsten putty, 9.9 g pressed into a 10 × 12 mm pocket", "≈10.5", "", "easy to make equal by weighing; density varies by brand"),
 ("Pb-cyl-3/8x.6", "lead rod 3/8\", cut 0.6\" long", "11.34", "", "cheap; toxic (Section 7); cut long and file down to the mass"),
 ("Bi-cyl-10x12", "bismuth cylinder 10 × 12 mm (cast or cut)", "9.78", "", "non-toxic; cast at 271 °C in a metal mould; weigh"),
 ("St-dowel-10x20", "hardened steel dowel pin 10 × 20 mm (ISO 8734)", "7.85", "", f"cheapest that works (≈ $0.2–0.5 each) but <b>fragile</b>: {RA['planes 0.1 mm'][0]:.0f}% at 0.1 mm, {RA['planes 0.2 mm'][0]:.0f}% at 0.2 mm face errors"),
 ("St-dowel-10x16", "steel dowel pin 10 × 16 mm", "7.85", "", "works, thin margin"),
 ("St-dowel-10x24", "steel dowel pin 10 × 24 mm", "7.85", "", "too tall: centre sits higher"),
 ("St-dowel-8x24", "steel dowel pin 8 × 24 mm", "7.85", "", "too light and tall: fails"),
 ("W-ball-10", "tungsten-alloy ball 10 mm", "≈18", "", "works; lighter and cheaper than 12 mm"),
 ("Pb-ball-.535", "lead round ball .535\" (230 gr)", "11.34", "", "marginal: not recommended"),
 ("Pb-ball-.440", "lead round ball .440\" (128 gr)", "11.34", "", "fails"),
 ("Pb-ball-.570", "lead round ball .570\" (278 gr)", "11.34", "", "fails"),
 ("St-ball-5/8", "steel bearing ball 5/8\"", "7.83", "", "fails"),
 ("St-ball-1/2", "steel bearing ball 1/2\"", "7.83", "", "fails"),
 ("St-ball-9/16", "steel bearing ball 9/16\"", "7.83", "", "fails"),
 ("St-ball-7/16", "steel bearing ball 7/16\"", "7.83", "", "fails"),
 ("St-ball-3/4", "steel bearing ball 3/4\"", "7.83", "", "fails badly"),
 ("W-cube-1/4", "tungsten cube 1/4\" (4.7 g)", "18.4", "", "too light: fails even at 180 mm"),
]:
    r = row(args[0], args[1], args[2], args[3], args[4])
    if r: tab.append(r)
E["mat_table"] = tab
E["mat_note"] = ("Each margin is the best of one to four local optimiser runs (Nelder–Mead from two different starting shapes). They are lower bounds and comparable to about ±0.5 mm. "
 "For the balls, starting from the cylinder optimum instead of the gallery's shape raised the 12 mm tungsten ball from +2.0 to +3.7 mm, so treat small differences with care. "
 "Tungsten 1/4\" cubes (4.7 g, the commonest derby weight): one run at 180 mm gave −0.8 mm, so they are too light. Not modelled numerically: bismuth shot (9.8 g/cm³ as metal, but loose shot packs to about 60%, so ≈6 g/cm³, worse than steel); "
 "brass balls (8.5 g/cm³, behave like steel balls: fail); coins (a US 5¢ coin is 5.000 g but 21.2 mm wide, far wider than the 10 mm the bottom rings allow).")
E["cap_mat"] = "Best margin for each stock weight after refitting the shape (exact mass model). Dense, narrow, upright cylinders do best. Balls need more room between the bottom-ring corners and a heavier pocket block."
E["sec2b"] = [
 "<b>Density is not everything.</b> Lead (11.3) as a round ball fails, but the same lead as a narrow rod gives +2.7 mm. Steel (7.85) balls all fail, but steel dowel pins work. "
 "The bottom three rings are a nearly flat dish, and their corners are about 15 mm apart along each spoke. A narrow piece fits there and its pocket block is light.",
 "<b>The physics behind the trade-off.</b> A lighter set of weights makes the plastic a bigger share of the mass (the 37-corner spiral fails above about 18% spread over the faces). "
 "A bulkier weight sits further from its corner tip and needs a heavier pocket block. Both move the centre of mass the wrong way.",
 "<b>Mixing is not allowed.</b> All 37 weights must be the same kind and matched in mass (Section 8: a ±3% spread is fine; ±5% starts to cost).",
 "<b>Tungsten putty</b> is non-toxic and easy to dose: weigh 9.90 g ± 0.05 g portions and press each one firmly into its pocket so it fills the bottom flat. Densities of 10–11 g/cm³ are claimed; "
 "a 9.9 g plug is 9–10 mm deep in the 10.0 mm pocket, so the pocket's 12.4 mm depth is enough. Its margin was computed for a full 12 mm plug at 10.5 g/cm³. A lower plug sits a little lower, which is not worse."]

def bom(R, W, key):
    pl = R['m_pla']; g = R['stl']
    rows = [["item", "qty", "spec", "mass"]]
    if key == "W":
        rows.append(["tungsten cylinder", "37 (+3 spare)", "3/8\" (9.53 mm) dia × 0.44\" (11.2 mm), 0.5 oz; e.g. pinewood-derby 'incremental' or 0.5 oz cylinder sets. "
                     "Must fit a 9.83 mm × 11.58 mm pocket", f"{W.m:.2f} g nominal each; 37 = {37*W.m:.1f} g. Weigh: all within ±1% (ideal ±0.5%)"])
    else:
        rows.append(["hardened steel dowel pin", "37 (+3 spare)", "10 mm × 20 mm, ISO 8734 / DIN 6325 (m6), plain steel (not stainless, which is lighter at 7.9–8.0: fine too). "
                     "Must fit a 10.30 mm × 20.40 mm pocket", f"{W.m:.2f} g nominal each; 37 = {37*W.m:.1f} g. Weigh: within ±1%"])
    rows.append(["PLA filament", "1 spool", "1.75 mm PLA, density 1.24 g/cm³ assumed (check the spool's datasheet)", f"{pl:.0f} g in the part (slicer: {(SLC if key=='W' else SLA)['meta'].get('g', 0):.0f} g incl. skirt)"])
    rows.append(["thin CA glue", "1 bottle", "one small drop per pocket (≤ 0.03 g), optional", f"{37*0.03:.1f} g allowed in the design"])
    rows.append(["finished body", "", f"{R['H']:.0f} mm tall, {2*max(R['x'][:6]):.0f} mm across corners", f"<b>{R['M']:.0f} g</b>"])
    return rows
E["bom_W"] = bom(REC, WR, "W"); E["bom_St"] = bom(ALT, WA, "St")
E["bom_notes"] = [
 "Also needed: a kitchen or jewellery scale reading 0.01 g, tweezers, a printer that can pause mid-print (M600/M601/M0 or the firmware's pause), and a flat, hard table for testing.",
 "Where to buy (types, not endorsements): tungsten cylinders from pinewood-derby suppliers (Pinewood Pro, Derby Worx, Maximum Velocity); tungsten-alloy balls and putty from "
 "fishing-tackle or industrial-ball suppliers; dowel pins from McMaster-Carr, Misumi, Accu or any fastener shop; lead rod from roofing or casting suppliers.",
 "Vendor masses are nominal. The 0.5 oz cylinder is 14.17 g, which implies 17.8 g/cm³ for its stated size. Alloys run from 17 to 18.5 g/cm³. "
 "If your pieces average more than 2% away from the design mass, see Section 6. A mass error shared equally by all 37 is fine (it is a scale factor, ±5% tested); a <i>spread</i> between pieces is what matters."]

E["settings"] = [["setting", "value", "why"],
 ["orientation", "base down, as the STL comes", "no supports needed; the base is the only face on the bed"],
 ["nozzle / layer", "0.4 mm / 0.2 mm (first layer 0.2)", "pause heights in Section 5 assume 0.2 mm layers"],
 ["perimeters", "2 (Arachne)", "walls are 0.8 mm = two 0.4 mm lines"],
 ["infill", "100 %", "the pocket blocks must be solid, as designed"],
 ["top / bottom layers", "5 / 4", "the base wall is 0.8 mm"],
 ["supports", "none", f"pocket blocks have 45° undersides; outer bands overhang S1 {OVH[0]:.0f}° (first {Z1:.1f} mm), S2 {OVH[1]:.0f}°, S3 {OVH[2]:.0f}° from vertical (printable with full cooling)"],
 ["brim", "8–10 mm, then trim", f"the base hexagon is only {2*R0:.0f} mm across corners under a {H:.0f} mm part"],
 ["cooling", "100 % after layer 3", "for the S2 overhang and the bridges over the pockets"],
 ["speed", "≤ 60 mm/s outer walls; slow above 150 mm", "a tall, narrow top; vibration at the tip"],
 ["elephant-foot comp.", "0 (or default)", "a slightly larger base is harmless"],
 ["XY hole compensation", "tune with the coupon", "the weights must drop in without force"],
 ["pauses", "7, at the Z heights in Section 5", "one per ring of pockets plus the apex"]]
E["slicer_notes"] = [
 f"<b>Checked with PrusaSlicer 2.7.2 (CLI)</b> using these settings: in every layer from each pocket's floor up to its pause, no extrusion lies within the pocket "
 f"(closest line {min(p['closest_extrusion_to_pocket_centre_while_open'] for p in SLC['pockets']):.2f} mm from the centre for a {WR.a:.2f} mm pocket radius). In the layer after each pause a bridge crosses the pocket. "
 f"The inner void stays empty (no extrusion within {SLC['void_closest_extrusion_to_axis_mm']:.0f} mm of the axis at mid-height). Filament {SLC['meta'].get('g',0):.0f} g "
 f"against {REC['m_pla']:.0f} g designed; time {tW}.",
 "<b>The slicer must keep the cavities.</b> The STL holds one outer surface and inner cavities as separate, inward-facing shells: the void and 37 pockets "
 "(in w37-W.stl also six thin closed slivers of air, 9.4 mm³ each, between the top ring's pocket blocks and the wall; if the slicer fills them the body gains 0.07 g, which does not matter). "
 "Do not use 'close holes' or any 'make solid' repair. In Cura, turn 'Union Overlapping Volumes' off and 'Remove All Holes' off (not tested in Cura). "
 "In the preview, scroll to mid-height: you should see only the two wall lines around an empty middle, plus small solid blocks at the six corners near the pause heights.",
 "If the slicer estimates about 1.7 kg of filament instead of about " + f"{SLC['meta'].get('g',0):.0f} g, it has filled the void. Re-slice."]

def pauses(R, W):
    rows = [["pockets", "count", "pocket floor (mm)", "weight top as printed", "pocket top (mm)", "<b>PAUSE after the layer ending at Z =</b>"]]
    order = ["ring 0", "ring 1", "ring 2", "ring 3", "ring 4", "ring 5", "apex"]
    pt = {p['name']: p for p in R['pauses']}
    for k in order:
        p = pt[k]
        rows.append([k.replace("ring", "ring"), str(p['n']), f"{p['floor']:.2f}", f"{p['printed_wtop']:.2f}", f"{p['top']:.2f}", f"<b>{p['pause_after']:.2f} mm</b> (layer {int(round(p['pause_after']/0.2))})"])
    return rows
E["pause_W"] = pauses(REC, WR); E["pause_St"] = pauses(ALT, WA)
E["pause_note"] = ("'Ring 0' is the base hexagon; 'ring 5' is the widest ring under the apex band. The layer number counts from 1 = the first layer (0–0.2 mm). "
 "PrusaSlicer, Orca and Cura slice at mid-layer, so the pocket is open in every layer whose middle lies inside it. The weight's top then lies at least 0.2 mm "
 "below the pause plane, so the nozzle cannot hit it. If your slicer shows Z as the top of the layer, use these numbers as they are. Always confirm in the preview.")
E["sec5"] = ("One piece, base down, printed straight through with seven pauses. At each pause the six (or one) pockets for the next ring are open-topped cylinders. "
 "Drop the weights in. The next layer bridges over them and seals them in for good. Nothing else needs gluing, and no part needs supports.")
cW = COUP['W']; cA = COUP['St']
E["steps"] = [
 f"<b>Fit test (30 min).</b> Print <i>coupon-W.stl</i> (three pockets exactly like the body's) with the same settings, pausing after the layer ending at Z = {cW:.2f} mm. "
 "A weight must drop in freely and sit flat, without being forced, and wobble by no more than about 0.3 mm. Resume and let it close. If the weights jam, raise "
 "'XY hole compensation' by 0.05–0.1 mm and repeat. If you can see daylight round the weight, the fit is still fine: a drop of glue holds it.",
 "<b>Weigh and match the weights.</b> Weigh every piece to 0.01 g and write the masses down. Use the 37 closest together; aim for all within ±0.5% (±0.07 g for 14.17 g). "
 "The shape tolerates ±3% at random (Section 8), but matching costs nothing. Keep 3 spares.",
 "<b>Slice</b> with the settings in Section 4 and add the seven pauses at the Z heights in the table. PrusaSlicer: in the preview, drag the slider to that layer → '+' → "
 "'Add pause print (M601)'. Orca/Bambu: right-click the layer → 'Add pause'. Cura: Extensions → Post Processing → 'Pause at height', once per pause, by layer number. "
 "Check in the preview that each pocket is open in the paused layer and bridged in the next one.",
 f"<b>Print</b> with a brim. Watch the first layers: the near-flat band S1 and the overhang S2 are printed in the first {Z2:.0f} mm.",
 "<b>At each pause</b> (the nozzle parks): optionally put one <i>small</i> drop of thin CA glue on each pocket floor, then lower each weight in with tweezers, flat end down. "
 "Press gently until it sits on the floor. Make sure nothing (weight, glue, strings) sticks up above the top layer, and that no glue is on the top surface. "
 "Do not push on the print or shift it on the bed. Resume. Do not forget a ring: count six weights per ring and one at the apex, 37 in all.",
 "<b>After printing</b>, let it cool, then lift it off and trim the brim with a deburring tool. Remove only the brim lip. Do not sand the base or any face flat: "
 "the margins are a few millimetres, and sanding a face changes its plane.",
 "<b>Check it</b> (Section 6): weigh it and test it on every band."]
E["cap_bottom"] = (f"Close-up of the bottom rings. Rings 0–2 lie within {REC['x'][7]:.1f} mm of the bed but their corners spread out to "
 f"{REC['x'][2]:.0f} mm radius, so their pockets stand side by side on the base wall, at least {REC['gap']:.1f} mm of PLA apart.")

E["checks"] = [["check", "expected", "if not"],
 ["weigh the body", f"<b>{REC['M']:.0f} g ± 15 g</b> (weights {37*WR.m:.0f} g + PLA {REC['m_pla']:.0f} g ± 8% + glue). Better: your weighed weights + slicer filament estimate, ± 8 g",
  f"≈ {REC['M']-WR.m:.0f} g: one weight missing (it will rest on faces on that side). Far more than expected: the void was filled; reprint after re-slicing."],
 ["shake gently", "no rattle, or a faint click if you skipped the glue", "a loud knock: a weight is loose. Usually harmless (≤ 0.4 mm of play, Section 8)."],
 ["set it on each band", "on a hard, flat table, put it down on a face of each band S6 … S1 (and on several faces round the body). It must always end on the base, "
  "tipping band by band", "see below"],
 ["drop it from 1–2 cm, many times", "it ends on the base every time", "see below"],
 ["balance on the apex", "it falls off (an unstable balance point)", "–"]]
E["fixes"] = [
 "<b>It stays on one of the lowest bands (S1/S2) all round.</b> The centre of mass is too high or the plastic too heavy. Check the mass. Check that the table is hard and flat: "
 "a cloth or soft mat can hold a body on a nearly flat face. " + f"The bottom band S1 leans only {90-OVH[0]:.0f}° from the base.",
 "<b>It stays on faces on one side only.</b> The centre of mass is off the axis: a light or missing weight, a weight from the wrong batch, or a large glue blob. "
 "A sealed body cannot be corrected from inside. Gluing a small counterweight on the outside opposite the problem side will shift the centre of mass, "
 "but it also changes a face, so put it on the base only, flat and thin (e.g. 0.1 mm lead or tungsten tape, a few grams, near the base's edge). "
 "That is a repair, not the design. The clean fix is a reprint with matched weights.",
 "<b>It rocks between the base and S1 before settling.</b> This is normal. S1 is almost coplanar with the base.",
 "<b>It ends on the base but tips slowly or hesitates on S5/S6.</b> This is normal. The upper bands tip over edges with leverage of only a few millimetres."]

E["safety"] = [
 "<b>Lead</b> (only if you choose the lead-rod option): toxic by ingestion. Wear gloves or wash your hands after handling; do not eat or drink while working with it. "
 "Cut it with a saw or cutter, never by melting or grinding. Collect swarf on paper and dispose of it as hazardous waste. Keep it away from children and pets. "
 "Label the finished body 'contains lead'. Once sealed in PLA it is not exposed, but a cracked body is.",
 "<b>Tungsten and steel</b> are not a chemical hazard in this form. Tungsten putty: wash your hands after use; some putties are not for children.",
 "<b>Weight.</b> The finished body is about " + f"{REC['M']/1000:.2f} kg" + " with a point on top. Do not drop it on glass tables or feet. The small dense weights are a swallowing hazard before they are sealed in.",
 "<b>During pauses</b> the nozzle stays at about 200 °C and the bed at 60 °C. Keep your fingers away from the nozzle and use tweezers. "
 "Some printers 'home' or move when you resume, so clear your hands first.",
 "<b>CA glue</b> bonds skin in seconds and gives off irritating fumes. Use a tiny drop and ventilate."]

def g(rows, k, i=3): return f"{rows[k][i]:.0f}" if k in rows else "–"
E["sec8"] = (f"Every number in this guide comes from an exact mass model. The PLA solid is the outer polyhedron minus the inner void, plus the union of the 37 pocket blocks, minus the 37 pocket voids. "
 "Weights and glue are added at their real positions, and the volume integrals are exact (no sampling). It was checked independently from the STL with trimesh "
 f"(volume {REC['stl']['volume']/1000:.3f} cm³ against {REC['stl']['exact_volume']/1000:.3f} cm³ exact; the difference is the polygonal pocket walls) and against the gallery's own 9 cm design "
 "(margin and mass reproduced). The equilibria of every simulated build were counted exactly: faces whose centre-of-mass foot falls inside, and corners whose balance cone contains the centre of mass.")
E["robust_note"] = ("'1 stable' = only the base is a rest face; '1 unstable' = only the apex balances; 'both' = a discrete Gömböc. Error models: weight masses × (1+N(0,s)); "
 "weight centres moved N(0,s) in x, y, z; a CA drop of U(0,g) g at a random point in every pocket; PLA density × (1+N(0,s)) and a linear density gradient; every outer face plane "
 "and every inner wall plane moved and tilted independently by N(0,s); all walls thicker or thinner; the bottom rings drooped toward the bed; 'combined' = planes s + walls N(0,s/2) "
 "+ weights 3% + positions 0.3 mm + glue 0.1 g + density 3% + gradient 2%. Most failures under plane errors split the apex into two unstable corners a fraction of a millimetre apart, "
 "not an extra rest face (compare the '1 stable' column).")

if SIM:
    E["dyn"] = SIM["text"]
else:
    E["dyn"] = ["(simulation pending)"]
E["unc"] = [
 "<b>Nothing here has been built yet.</b> All results are calculated: exact statics, Monte-Carlo build errors and rigid-body simulation.",
 "<b>The optimiser is local.</b> Margins are lower bounds. The material ranking is reliable at the level of 'works / marginal / fails', not to ±0.5 mm.",
 "<b>Weight masses and sizes</b> come from vendor statements and density. Real tungsten alloys run 17–18.5 g/cm³. Measure the pieces, run the coupon test, and match the masses.",
 "<b>PLA</b> was taken as solid at 1.24 g/cm³. Real prints have a few % voids and filaments run 1.21–1.30 g/cm³. Global density changes of ±5% and gradients were tested.",
 f"<b>Printing the bottom.</b> The bottom band S1 rises only {Z1:.1f} mm and S2 overhangs {OVH[1]:.0f}°. The as-printed planes there will be off by a few tenths of a millimetre. "
 "Drooping and plane errors were tested, and both make the near-flat bottom flatter, which is safe. A badly sagging S2 could change it more than modelled.",
 "<b>Surfaces.</b> On soft or rough surfaces, rolling resistance can hold a body on a nearly flat face. The statics assume a hard, flat table.",
 "<b>Dynamics</b> use Bullet (the gallery's harness, unchanged physics): rigid, convex-hull contact, the table's restitution and rolling friction as the gallery sets them. "
 "Real PLA is a little elastic. A falling body can hop, but where it ends is decided by the statics above."]
E["files"] = [["file (in exhibits/Bille/print/w37/ unless a folder is given)", "what"],
 ["w37-W.stl", f"recommended body, mm, base on z = 0; {REC['H']:.0f} mm tall; one outer shell + {REC['stl']['shells'] - 1} inner cavity shells (the void, 37 pockets, 6 thin air slivers by the top ring's pocket blocks); trimesh: watertight, consistent winding"],
 ["w37-St.stl", f"steel-dowel body (same layout; {ALT['stl']['shells'] - 1} inner cavity shells: the void and 37 pockets)"],
 ["coupon-W.stl, coupon-St.stl", "fit-test coupons, three pockets each"],
 ["w37-W-props.txt, w37-St-props.txt", "design numbers: ring radii/heights, every face and corner margin, pocket positions, pause table"],
 ["w37-W-*.png, materials.png", "the figures in this guide (cutaway, section, bottom close-up, materials chart); w37-St-*.png: the same for the steel-dowel body"],
 ["../../reconstruction/w37/final/robust-W.log, robust-St.log", "robustness runs (300 trials per row); robust-alt-*.log: the other working weights (200 per row)"],
 ["w37-W.gcode.check.json, w37-St.gcode.check.json", "PrusaSlicer check: pockets open/closed at the pauses, void empty, filament mass"],
 ["../../reconstruction/w37/sim/, sim-W/, sim-St/", "bpp harness copy (w37-drop.lua), run script and logs; final/sim-tally*.json"],
 ["../../reconstruction/w37/", "scripts: w37.py (mass model), opt.py (refit), robust.py, export.py, meshbuild.py, figs.py, slicecheck.py, coupon.py, gather.py, matfig.py, "
  "make_extra.py + build_guide.py (this guide); runs/ (optimiser logs, design vectors); README.md says how to run them"]]
E["refs"] = [
 "G. Domokos, F. Kovács, 'Conway's spiral and a discrete Gömböc with 21 point masses', Amer. Math. Monthly 130 (2023); arXiv:2103.13727.",
 "P. L. Várkonyi, G. Domokos, 'Mono-monostatic bodies: the answer to Arnold's question', Math. Intelligencer 28 (2006) 34–38.",
 "J. H. Conway, R. K. Guy, 'Stability of polyhedra', SIAM Review 11 (1969) 78–82.",
 "Euler's Gallery: exhibits/Bille (p37.lua, the idealised 9 cm shell-and-corner-weights design, not buildable as stated; reconstruction/pla, the PLA-only body) and exhibits/Gomboc/variety-reconstruction (optshell.py, robust2.py, frac.py).",
 "Stock data: pinewood-derby tungsten cubes and cylinders (derbydust.com, maximum-velocity.com, pinewoodpro.com); tungsten-alloy spheres (≈18 g/cm³); Hornady lead round balls (.440\" = 128 gr); "
 "52100 chrome-steel bearing balls; ISO 8734 dowel pins. Checked October 2026; prices and stock change."]

# ---------------------------------------------------------------- final wording (after the robustness runs)
ALTR = {}
for w in ["Pb-cyl-3/8x.6", "W-ball-12", "Wputty-cyl-10x12", "Bi-cyl-10x12"]:
    fn = f"{F}/robust-alt-{w.replace('/', '_')}.log"
    if os.path.exists(fn): ALTR[w] = robust_rows(fn)
def ar(w, k):
    r = ALTR.get(w, {}).get(k); return f"{r[0]:.0f}%" if r else "n/a"
p2W = RR['planes 0.2 mm'][0]; p3W = RR['planes 0.3 mm'][0]; p1A = RA['planes 0.1 mm'][0]; p2A = RA['planes 0.2 mm'][0]
E["answer"] = (
 f"Yes, but the <b>shape</b> of the weight matters as much as its density. All 37 weights must be equal, each pressed as close to its corner as the walls allow. "
 f"The three bottom rings form a nearly flat dish whose corners are only about 13 mm apart along each spoke. Tall, narrow, dense pieces win. "
 f"<b>Recommended:</b> tungsten pinewood-derby cylinders, 3/8\" × 0.44\" (0.5 oz, {WR.m:.2f} g), in a {H:.0f} mm body: smallest margin <b>{mrec:.1f} mm</b>. "
 f"<b>Other weights that work:</b> 12 mm tungsten-alloy balls (3.7 mm), tungsten putty (2.7 mm), 3/8\" lead rod cut to 0.6\" (2.7 mm; toxic), "
 f"and cast or cut bismuth cylinders 10 × 12 mm (2.3 mm; non-toxic). "
 f"<b>Steel only works as narrow dowel pins</b> (10 × 20 mm, {malt:.1f} mm), and that build is fragile: only {p1A:.0f}% of builds with 0.1 mm face errors and {p2A:.0f}% at 0.2 mm keep one rest face. "
 f"<b>Steel balls, lead balls, brass, coins and loose shot do not work</b> (Section 2).")
E["sec2b"] = [
 "<b>Density is not everything.</b> Lead (11.3 g/cm³) as round balls is marginal at best (+0.8 to +1.3 mm). The same lead as a narrow rod gives +2.7 mm. "
 "Every steel ball fails, but steel dowel pins work, just. The bottom three rings are a nearly flat dish. A narrow upright piece fits between their corners, "
 "sits low, and needs only a light pocket block. A ball as heavy needs a wider pocket, so the corners must be spread out, and that costs margin.",
 "<b>The physics behind the trade-off.</b> A lighter set of weights makes the plastic a bigger share of the mass (the 37-corner spiral fails above about 18% spread over the faces). "
 "A bulkier weight sits further from its corner tip and needs a heavier pocket block. Both move the centre of mass the wrong way.",
 f"<b>Margin and robustness go together.</b> With 0.2 mm random face errors, {p2W:.0f}% of tungsten builds keep a single rest face, against {p2A:.0f}% for steel dowels. "
 f"The other working options fall in between (200 trials each): lead rod {ar('Pb-cyl-3/8x.6','planes 0.2 mm')}, 12 mm tungsten balls {ar('W-ball-12','planes 0.2 mm')}, "
 f"tungsten putty {ar('Wputty-cyl-10x12','planes 0.2 mm')}, bismuth {ar('Bi-cyl-10x12','planes 0.2 mm')}. "
 "All of them are 100% under the layer-by-layer FDM error model (Section 8).",
 "<b>Mixing is not allowed.</b> All 37 weights must be the same kind and matched in mass (Section 8: a ±3% spread is fine; ±5% starts to cost).",
 "<b>Tungsten putty and bismuth</b> are the non-toxic ways to make weights by mass rather than by shape. With putty, weigh 9.90 g ± 0.05 g portions and press each one firmly into its 10 mm pocket. "
 "Bismuth melts at 271 °C and can be cast into 10 mm rod in a steel or high-temperature silicone mould (never in PLA), then cut and filed to 9.2 g. Both margins were computed for "
 "plugs that fill a 10 × 12 mm cylinder (putty at 10.5 g/cm³, bismuth at 9.78 g/cm³). Densities vary, so <b>weigh</b> every piece."]
E["real"][1] = (f"<b>Size.</b> A bigger body makes the shell heavier (it grows with size²) while the weights stay the same. A smaller one crowds the bottom pockets. "
 f"For the 0.5 oz cylinders the best height is about 200 mm. One optimiser run per size gave margins of 1.9, 3.7, 3.9, 4.0, 4.0 and 2.5 mm at 160, 180, 190, 200, 220 and 240 mm; "
 f"the refined 200 mm design reaches {mrec:.2f} mm.")
E["sec8"] = (E["sec8"] + " <b>The weak point is face accuracy.</b> The margin of a few millimetres is measured at the centre of mass, which sits 36 mm above the base. "
 "A face that is tilted or shifted by a fraction of a millimetre moves its own edges, and the foot of the centre of mass on it, by far more. This is worst between the "
 "nearly coplanar bottom bands and on the small upper faces. So random, independent errors on every face hurt most: the 'planes' rows. "
 "A real FDM print does not fail like that. Its faces are built from the same layers, so their errors are correlated. The 'as sliced' rows rebuild the outer surface layer by layer, "
 "as PrusaSlicer slices it, with random layer shifts and size errors, and every one of those builds keeps exactly one rest face.")
E["robust_note"] = ("'One rest face' = monostable (the body rests on one face only). 'One balance point' = only the tip balances it, counting unstable corners less than 1 mm apart as one; "
 "plane errors split the six-face apex into several corners, and the printed tip is a tiny flat. 'Strict' = exactly one unstable vertex as well, the mathematical definition of a discrete Gömböc. "
 "Error models: weight masses × (1+N(0,s)); weight centres moved N(0,s) in x, y, z; a CA drop of U(0,g) g at a random point in every pocket; PLA density × (1+N(0,s)) and a linear gradient; "
 "'planes': every outer face plane and every inner wall plane moved and tilted independently by N(0,s) (the gallery's PLA test); 'wall': all walls thicker or thinner; 'bottom droop': rings 1–3 lowered toward the bed; "
 "'rings': ring radii and heights N(0,s), with weights off by s and ±3% in mass (the gallery's robust2 test of its 9 cm design: 100/98/67% at 0.2/0.5/1.0 mm); "
 "'sliced': the outer surface rebuilt from 0.2 mm layers, each shifted N(0,xy) and grown by N(0,xy), first layer +0.4 mm; "
 "'combined' = planes s + walls N(0,s/2) + weights 3% + positions 0.3 mm + glue 0.1 g + density 3% + gradient 2%.")
E["ppla_note"] = ("The gallery also has a PLA-only design (exhibits/Bille/print/ppla37.stl, 150 mm, 331 g, no weights). It is solid up to the height of its centre of mass "
 "and hollow above. Its smallest margin is 12.3 mm and it passed 0.5 mm face errors in 100% of trials. It is much easier to print and far more forgiving, and it needs one print and no pauses. "
 "It is a different object, though: a faceted Weeble whose weight may go anywhere, not a body with equal masses at its corners. "
 "Build this weighted one if you want the Domokos–Kovács construction itself.")
E["unc"][1] = ("<b>The optimiser is local</b> (Nelder–Mead, one to four runs per option). Margins are lower bounds: restarting the 12 mm tungsten ball from a different shape raised it from 2.0 to 3.7 mm. "
 "The ranking is reliable at the level of 'works / marginal / fails', not to ±0.5 mm.")
E["unc"].insert(2, f"<b>Face accuracy is the limit.</b> With independent 0.2 / 0.3 / 0.5 mm errors on every face, {p2W:.0f} / {p3W:.0f} / {RR['planes 0.5 mm'][0]:.0f}% of tungsten builds keep a single rest face. "
 "With the layer-by-layer model it is 100%. Which is closer to your printer is the main open question. Print slowly, calibrate the extrusion, and test the faces (Section 6).")

json.dump(E, open(f"{F}/extra.json", "w"), indent=1)
print("extra.json written")
