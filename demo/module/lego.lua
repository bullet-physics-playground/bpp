--
-- Lego Brick Parametric OpenScad
-- by stalkerface, published Nov 26, 2013
--
-- based on Lego_Tech.scad in the downloaded zip file
--
-- http://www.thingiverse.com/thing:191146
--
module("lego", package.seeall)

function new(params)

   params = params or {}
   options = {
      fn   = 50,
      fun  = "KLOTZ(1, 2, 3, Tile=false, Technic=false);",
      mass = 1,
   }

   for k,v in pairs(params) do options[k] = v end

   fn   = options.fn
   fun  = options.fun

   mass = options.mass

   return OpenSCAD(fun..lib, mass)
end

lib = [===[

// 5 Basic dimensions

hori_pitch=8; //The horizontal pitch, or distance between knobs:  8mm.

vert_pitch=9.6; //The vertical pitch, or height of a classic brick:  9.6mm.

play=0.1; //The horizontal tolerance:  0.1mm. This is half the gap between bricks in the horizontal plane.  The horizontal tolerance prevents friction between bricks during building.

axle_D=6*FLU; //This is also the diameter of axles and holes.  Actually a knob must be slightly larger and an axle slightly smaller (4.85 and 4.75 respectively, otherwise axles would not turn in bearing holes and knobs would not stick in them) but we will ignore this difference here.

hole_D=4.8;

knob_h=1.8; //The height of a knob:  1.8mm

// ###########################################

FLU =0.8; // Fundamental Lego Unit

knob_D=6*FLU; //=4.8mm
knob_id=3.75*FLU; //=3mm
knob_innerD=3.25*FLU; //=2.8mm für Löcher im Stein unter den Knobs

plate_h=4*FLU; //3.2mm
brick_w=10*FLU; //=8mm
Wall=1.5*FLU;   //=1.2mm
Wall_Technic=1.875*FLU; //=1.5mm

cont_w=0.6;
cont_b=0.3;

Inner_cyl1_D=3.75*FLU; //=3mm
Inner_cyl2_r=6.51371/2;
Inner_cyl2_wall=0.75;


// ############################################
// Technic Dimensions #########################

axle_base=7.25*FLU; //The distance of axle holes from the base: 5.8mm This is in fact a derived number.

recess_D=7.75*FLU; // =6.2mm The diameter of the recess of a Technics hole:  6.0mm and the recess amount of the same.

smooth=50;

// ###################################

// KLOTZ(1, 2, 3, Tile=false, Technic=false); //X_Noppen, Y_Noppen, Höhe in Legolayer (*3,2), glatte Fliese=nein/ja, Technikstein =ja/nein)


// ###################################

module KLOTZ(X, Y, H){
difference(){
union(){
	difference(){
	translate([0,0,-plate_h/2*H]) cube([brick_w*X-play*2, brick_w*Y-play*2, plate_h*H], center=true);
	translate([0,0,-plate_h/2*H-1]) cube([brick_w*X-2*Wall_Technic, brick_w*Y-2*Wall_Technic, plate_h*H], center=true);

knob_innerD(X, Y);


	} // ende diff
if(Y>=2){
tech_cyl(Y-1);}
else {tech_cyl(Y);}

		if(X==1 && Y>1) // Wenn X=1 und Y>1 
			InnenZyl1(Y-1, H);
		if(Tile==false){
		NIP_Aussen(X, Y);}

} // ende Union
if(Y>=2){
tech_hole(Y-1);}
else {tech_hole(Y);}
}
} // ende Module


// Module ###########################

module NIP_Aussen(X, Y){
translate([(-brick_w*X)/2+brick_w/2, 0, 0])
for(f=[0:1:X-1])
translate([brick_w*f, -brick_w/2*Y+brick_w/2, 0])
for(i=[0:1:Y-1])
translate([0, brick_w*i, knob_h/2])
difference(){
cylinder(r=knob_D/2, h=knob_h, center=true, $fn=smooth);
cylinder(r=knob_id/2, h=knob_h+1, center=true, $fn=smooth);}
}

module knob_innerD(X, Y){
translate([(-brick_w*X)/2+brick_w/2, 0, -2.5])
for(f=[0:1:X-1])
translate([brick_w*f, -brick_w/2*Y+brick_w/2, 0])
for(i=[0:1:Y-1])
translate([0, brick_w*i, knob_h/2])
cylinder(r=knob_innerD/2, h=knob_h, center=true, $fn=smooth);
}

module InnenZyl1(Y, H){ //Höhe in Legohöhe
translate([0, (brick_w*Y)/2-brick_w/2, 0])
for(i=[0:1:Y-1])
translate([0, -brick_w*i, -plate_h/2*H])
cylinder(r=Inner_cyl1_D/2, h=plate_h*H, center=true, $fn=smooth/3);
}

module tech_hole(Y){
translate([0,(brick_w*Y)/2-brick_w/2, 0])
for(i=[0:1:Y-1])
translate([0, -brick_w*i, -vert_pitch+axle_base])
union(){
rotate([0,90,0]) cylinder(r=hole_D/2, h=brick_w, center=true, $fn=smooth);
translate([brick_w-0.9,0,0]) rotate([0,90,0]) cylinder(r=recess_D/2, h=brick_w, center=true, $fn=smooth);
mirror([1,0,0]){
translate([brick_w-0.9,0,0]) rotate([0,90,0]) cylinder(r=recess_D/2, h=brick_w, center=true, $fn=smooth);
}}}

module tech_cyl(Y){
translate([0,(brick_w*Y)/2-brick_w/2, 0])
for(i=[0:1:Y-1])
translate([0, -brick_w*i, -vert_pitch+axle_base])
rotate([0,90,0]) cylinder(r=recess_D/2, h=brick_w-Wall, center=true, $fn=smooth);
}

]===]

