// Split a self-righting body (GOMBOC900, candidate L4, GOMBOC-F2, or the mono-p1 / s2 / s4 loaves) for FDM printing, with pin holes and an edge chamfer
// on the cut faces. Needs gomboc900_90mm.stl and/or l4_90mm.stl in the same folder
// and/or mono_p1/s2/s4_90mm.stl (90 mm long, balance point at the origin, upright = +Y). GOMBOC900 and L4
// share one pin layout; each mono loaf has its own (across cut only). The s2 and s4 meshes are the
// shape chat's genomes rebuilt on a 163,842-plane icosphere (facets under 2 mm at 90 mm).
//
// Size, pin holes and chamfer are independent: change `size` and the holes stay the same diameter
// and depth. Pin positions scale with the body so they stay inside the cut face.
//
// Rendering is fast in OpenSCAD 2024+ with Preferences > Advanced > Backend = Manifold.
// The 2021 release (CGAL) works but can take several minutes per half.

/* [Shape] */
// Which body
shape = "l4";         // [gomboc900:GOMBOC900, l4:Candidate L4 (larger roll margin), f2:GOMBOC-F2 (October, flat-spot resistant), mono_p1:mono-p1 loaf (across cut), mono_s2:mono-s2 loaf (across cut), mono_s4:mono-s4 loaf (across cut)]
// Long-axis length of the finished gomboc, mm
size = 36;            // [20:1:120]
// Which cut
cut = "current";      // [current:Current tilted cut, across:Across - split at the waist, along:Along - split lengthwise, old8:Old 8 degree cut, custom:Custom]
// Which piece to render
part = "both";        // [top, bottom, both]

/* [Pin holes (not scaled)] */
hole_d = 1.9;         // hole diameter, mm (1.75 mm filament pins)
hole_depth = 7;       // hole depth in EACH half, mm (pin length = 2 x depth - 1)
hole_fn = 48;
// Spread of the pins, as a multiple of the default layout (1 = as supplied)
pin_spread = 1.0;     // [0.5:0.05:1.3]

/* [Seam placement] */
// Where the Z-seam line should run on the body. auto = top for GOMBOC900/L4, underside for the loaves
seam_line = "auto";        // [auto, top, underside]
// Which side of each part your slicer puts the seam (supplied Cura profile: front)
slicer_seam = "front";     // [front, back]

/* [Plumb mark (not scaled)] */
// Shallow dent at the top of the body's vertical through the centre of mass. When the body rests
// upright it sits straight above the contact point; with the across cut it lies on the seam.
// The body rolls on its convex hull, which bridges the dent, so self-righting is unchanged.
plumb_mark = true;
plumb_d = 1.6;        // dent diameter, mm (depth = half of this)

/* [Cut-face edge chamfer (not scaled)] */
chamfer = 0.4;        // mm, 45 degrees. 0 = none

/* [Custom cut (used when cut = custom)] */
// Normal n = Rz(beta) * (0, cos(alpha), -sin(alpha)); top piece is the side n points to
custom_alpha = -12;
custom_beta = -15;
// Plane offset from the balance point along n, in mm at 90 mm size (scales with size)
custom_offset90 = 0;

/* [Hidden] */
mono = shape == "mono_p1" || shape == "mono_s2" || shape == "mono_s4";
// Distance from the centre of mass straight up (+Y) to the surface, mm at 90 mm
plumb_y90 = shape == "l4" ? 46.07 : shape == "f2" ? 45.87 : shape == "mono_p1" ? 22.70 :
            shape == "mono_s2" ? 17.76 : shape == "mono_s4" ? 17.65 : 46.15;
mesh_file = shape == "l4" ? "l4_90mm.stl" : shape == "f2" ? "f2_90mm.stl" : mono ? str(shape, "_90mm.stl") : "gomboc900_90mm.stl";
s = size / 90;

// GOMBOC900, L4 and F2 share this table: their own pin positions differ by < 0.2 mm at 90 mm.
// Per cut: [alpha, beta, offset at 90 mm, pin positions at 90 mm (in the cut plane), least
// material along the hole axis at the pins at 90 mm]
// The mono loaves are different bodies: only their across cut has been checked (no overhangs, pins fit)
function monopins(sh) =
    sh == "mono_p1" ? [[[-11.94, 2.27],[8.88, 2.27],[-1.53,-7.45],[-1.53,11.99]], 25.1] :
    sh == "mono_s2" ? [[[ -9.58, 1.71],[6.61, 1.71],[-1.48,-6.33],[-1.48, 9.74]], 22.7] :
                      [[[ -9.33, 1.65],[6.97, 1.65],[-1.18,-5.89],[-1.18, 9.19]], 25.9];
function cutdef(c) = mono ?
    (c == "across" ? [0, -90, 0, monopins(shape)[0], monopins(shape)[1]]
                   : [custom_alpha, custom_beta, custom_offset90, [[-8,0],[8,0],[0,-6],[0,6]], 15]) :
    c == "current" ? [-12, -15, 0,  [[-20.41,-0.70],[24.57,-0.70],[2.08,-15.31],[2.08,13.91]], 29.5] :
    c == "across"  ? [  0, -90, 0,  [[-22.64, 0.00],[17.86, 0.00],[-2.39,-14.40],[-2.39,14.40]], 38.2] :
    c == "along"   ? [-90,   0, 0,  [[-22.50, 3.34],[22.50, 3.34],[0.00,-12.86],[0.00,19.54]], 30.9] :
    c == "old8"    ? [  8,   0, -3, [[-22.40, 0.98],[22.40, 0.98],[0.00,-13.33],[0.00,15.28]], 28.4] :
                     [custom_alpha, custom_beta, custom_offset90,
                      [[-20,0],[20,0],[0,-14],[0,14]], 25];   // custom: check pins in preview

D      = cutdef(cut);
alpha  = D[0];
beta   = D[1];
off    = D[2] * s;
pins   = D[3];
pc     = [for (p = pins) p[0]] * [1,1,1,1] / 4;   // centre x of pin pattern
pcy    = [for (p = pins) p[1]] * [1,1,1,1] / 4;
pins_s = [for (p = pins) [pc + (p[0]-pc)*pin_spread, pcy + (p[1]-pcy)*pin_spread] * s];
// Leave at least 2 mm of plastic beyond the end of each hole
depth  = min(hole_depth, D[4]*s - 2);

echo(str("seam line on the ", seam_on, "  shape=", shape, "  cut=", cut, "  size=", size, " mm  hole ", hole_d, " x ", depth, " mm per half  ->  pins of ",
         2*depth - 1, " mm  chamfer ", chamfer, " mm"));
if (mono && cut != "across") echo("WARNING: only the across cut is checked for the mono loaves; pins and overhangs are NOT checked for this cut");
if (depth < hole_depth) echo("NOTE: hole depth reduced to keep 2 mm of plastic beyond the hole");

// Body in the cut frame: cut normal along +Z, cut plane at z = off
module body_cut_frame() {
    rotate([alpha + 90, 0, 0]) rotate([0, 0, -beta]) scale(s) import(mesh_file, convexity = 4);
}

module drilled() {
    difference() {
        body_cut_frame();
        for (p = pins_s) translate([p[0], p[1], off])
            cylinder(d = hole_d, h = 2*depth, center = true, $fn = hole_fn);
        if (plumb_mark)
            rotate([alpha + 90, 0, 0]) rotate([0, 0, -beta]) translate([0, plumb_y90 * s, 0])
                sphere(d = plumb_d, $fn = 32);
    }
}

// Section of the body at height z (cut frame), as 2D
module section_at(z) { projection(cut = true) translate([0, 0, -z]) body_cut_frame(); }

// Everything kept by the chamfer on one side (sg = +1 top, -1 bottom): a 45 degree frustum from the
// cut face out to `chamfer`, plus everything beyond. The section of a convex body is convex, so the
// hull of the two outlines is the correct loft.
module chamfer_keep(sg) {
    e = 0.001;
    hull() {
        translate([0, 0, off - (sg < 0 ? e : 0)])
            linear_extrude(e) offset(delta = -chamfer) section_at(off + sg*chamfer);
        translate([0, 0, off + sg*chamfer - (sg < 0 ? e : 0)])
            linear_extrude(e) section_at(off + sg*chamfer);
    }
    // starts 0.02 mm inside the frustum so the two never meet edge to edge on the surface
    translate([-500, -500, sg > 0 ? off + chamfer - 0.02 : off - chamfer + 0.02 - 1000]) cube([1000, 1000, 1000]);
}

module half(sg) {
    intersection() {
        drilled();
        if (chamfer > 0) chamfer_keep(sg);
        translate([-500, -500, sg > 0 ? off : off - 1000]) cube([1000, 1000, 1000]);
    }
}

// Each piece lies cut face down at z = 0
// Bed orientation. The supplied Cura profile puts the Z seam at the FRONT of each part
// (user specified, relative, z_seam_y = -500). Each piece is turned so the chosen seam line faces that
// side; the bottom piece is flipped about the bed's Y axis so both halves match.
// Static check with 0.1 mm seam dots: on GOMBOC900/L4 a seam on the top is clean (underside: trap at
// 17-27 deg; side of the cylinder: trap at ~100 deg). On the loaves a seam on the top makes a trap at
// ~162 deg (lying on its back) and the underside is clean.
seam_on   = seam_line == "auto" ? (mono ? "underside" : "top") : seam_line;
up_front  = (seam_on == "top") == (slicer_seam == "front");    // body top faces the bed front?
function rotx(a, v) = [v[0], v[1]*cos(a) - v[2]*sin(a), v[1]*sin(a) + v[2]*cos(a)];
function rotz(a, v) = [v[0]*cos(a) - v[1]*sin(a), v[0]*sin(a) + v[1]*cos(a), v[2]];
up_cf  = rotx(alpha + 90, rotz(-beta, [0, 1, 0]));      // body "up" in the cut frame
up_len = sqrt(up_cf[0]*up_cf[0] + up_cf[1]*up_cf[1]);
spin   = up_len > 0.2 ? (up_front ? -90 : 90) - atan2(up_cf[1], up_cf[0]) : 0;
if (up_len <= 0.2) echo("NOTE: for this cut the body's top is on the cut face, not the side wall; seam placement is not controlled");

module top_piece()    { rotate([0, 0, spin]) translate([0, 0, -off]) half(1); }
module bottom_piece() { rotate([0, 180, 0]) rotate([0, 0, spin]) translate([0, 0, -off]) half(-1); }

if (part == "top")    top_piece();
if (part == "bottom") bottom_piece();
if (part == "both") {
    translate([-0.55*size, 0, 0]) top_piece();
    translate([ 0.55*size, 0, 0]) bottom_piece();
}
