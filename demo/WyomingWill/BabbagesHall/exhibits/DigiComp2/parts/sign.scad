// The Digi-Comp II's sign (the exhibit's, beside the machine; not part of it,
// and not printed): a line of text. Kept apart from digicomp2.scad so that
// changing the machine doesn't make bpp draw the sign's letters again.
FONT = "DejaVu Sans:style=Bold";
module signText(t, size = 16) linear_extrude(1) text(t, size = size, halign = "left", valign = "center", font = FONT);
// (the program board: a line of a program, in letters all the same width,
// so the comments line up as in the file)
MONO = "DejaVu Sans Mono:style=Bold";
module listText(t, size = 16) linear_extrude(1) text(t, size = size, halign = "left", valign = "center", font = MONO);
