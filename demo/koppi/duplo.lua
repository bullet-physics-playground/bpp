module("duplo", package.seeall)

lib = [===[

// Duplo-compatible marble run pieces (C) by Joachim Eibl 2013
// Licence: CC BY-NC-SA 3.0 
// Creative Commons: attribution, non commercial, share alike
// See: http://creativecommons.org/licenses/by-nc-sa/3.0/
// LEGO and DUPLO are trademarks of the Lego group.

// Version 2 (added longRampPiece and cosinusSlopedRampPiece)

// The duplo-block-lib is derived from http://www.thingiverse.com/thing:1778

// Duplo-compatible block library (C) by Joachim Eibl 2013
// Licence: CC BY-NC-SA 3.0 
// Creative Commons: attribution, non commercial, share alike
// See: http://creativecommons.org/licenses/by-nc-sa/3.0/
// This lib is derived from http://www.thingiverse.com/thing:1778
// LEGO and DUPLO are trademarks of the Lego group.

duploRaster = 16;
dr = duploRaster;
duploHeight=duploRaster * 0.6;

quality = 10; // quality: low/fast (e.g. 10) for design, high/slow (e.g. 50) for final rendering 
innerRadius=14*dr/16;

pr = 2*dr + 2; // plate raster

// if some pieces are missing: "Edit"->"Preferences"->"Advanced"->"Turn off rendering at: " [1000000] "elements"

// Choose either plate or individual pieces from the plates.
//smallPlate(); // simple pieces, each only once
//bigPlate();     // more straight and corner pieces

//straightPiece();
//cornerPiece();
//rampPiece();
//ramp2Piece();
//longRampPiece();
//cosinusSlopedRampPiece();
//crossingPiece();
//straightHolePiece(); 
//cornerHolePiece(); 
//rampCornerPiece(steps=quality);
//mirror([0,1,0]) rampCornerPiece(steps=quality);
//endPiece();

//the duplo itself
// parameters are: 
// width: 1 =standard 4x4 duplo width.
// length: 1= standard 4x4 duplo length
// height: 1= minimal duplo height


// nibble radius: a square brick with size (dr x dr) turned by 45° on a neighbor nibble fits exactly:
duploNibbleRadius = dr * (1-1/1.41421) +0.1; // = 4.686+0.1,  dr*(1-1/sqrt(2))
duploBottomNibbleRadius = dr*(1.41421-1); //= dr * 1.41421 / 2  - duploNibbleRadius = 6.6277
duploGapBottom = -0.05; // recommended range from -0.1 to 0.1 with lower values for tighter fit.
gapBetweenBricks = 0.3; // real duplo probably has 0.4
duploWall = 1.55;// For duplo compatibility this is not so important, only if smaller lego should fit.
                   // (dr/2 - duploNibbleRadius - gapBetweenBricks)/2 = 1.507
firstLayerGap = 0.2; // for easier fit and to compensate for printers that print a thicker bottom
firstLayerGapHeight = 0.3;

quality = 10; // quality: low/fast (e.g. 10) for design, high/slow (e.g. 50) for final rendering 


// if some pieces are missing: "Edit"->"Preferences"->"Advanced"->"Turn off rendering at: " [1000000] "elements"


//duplo(2,2,1,true,false);



module duplo(width,length,height,topNibbles,bottomHoles) 
{
   //size definitions
   
   ns = duploRaster / 2;  //nibble start offset
   nbo = duploRaster;  // nibble bottom offset
   effWidth = width * duploRaster-gapBetweenBricks;
   effLength = length*duploRaster-gapBetweenBricks;
   littleWallThickness = 2.35; // 1.35 is standard but bigger is better for printing

   //the cube
   difference() {
      cube([effWidth,effLength,height*duploHeight],true);
      translate([0,0,-duploWall])    
         cube([width*duploRaster - 2*duploWall,length*duploRaster-2*duploWall,height*duploHeight],true);
   }

   if(topNibbles)
   {
      //nibbles on top
      for(j=[1:length])
      {
         for (i = [1:width])
         {
            // disabled
            translate([ns-(i-width*0.5)*dr,ns-(j-length*0.5)*dr,6.9+(height-1)*duploHeight/2]) duplonibble();
         }
      }
   }

   if(bottomHoles)
   {
      difference() {
         cube([effWidth,effLength,height*duploHeight],true);
      
         //nibbles on bottom
         for(j=[1:length])
         {
            for (i = [1:width])
            {
               // disabled
               translate([ns-(i-width*0.5)*dr,ns-(j-length*0.5)*dr,-0.1-height*duploHeight/2])
               {
                  cylinder(r=duploNibbleRadius+0.2,h=6,center=false,$fn = quality);
                  cylinder(r=duploNibbleRadius+0.4,h=0.5,center=false,$fn = quality);
               }
            }
         }
      }
   }
   else
   {
   //nibble bottom
   if ( length > 1 && width > 1 )
   {
      for(j=[1:length-1])
      {
         for (i = [1:width-1])
         {
            translate([(i-width*0.5)*dr,(j-length*0.5)*dr,0]) duplobottomnibble(height*duploHeight);
         }
      }
   }
   //little walls inside
   difference() 
   {
      union()
       {
         for(j=[1:length])
         {   
            translate([0,ns-(j-length/2)*dr,0 ]) cube([effWidth,littleWallThickness,height*duploHeight],true);
         }
         for (i = [1:width])
         {
            translate([ns-(i-width/2)*dr,0,0 ]) cube([littleWallThickness,effLength,height*duploHeight],true);
         }
         for(j=[1:length-1])
         {   
            if (width==1)
               translate([0,ns-(j-length/2+0.5)*dr,0 ]) cube([effWidth,littleWallThickness,height*duploHeight],true);
         }
      }
      if ( width > 1 )
      {
         cube([(width-1)*dr + duploNibbleRadius*2+duploGapBottom,(length-1)*dr+duploNibbleRadius*2+duploGapBottom,height*duploHeight+2],true);
         translate([0,0,-height*duploHeight/2+firstLayerGapHeight/2]) 
         cube([(width-1)*dr + duploNibbleRadius*2+duploGapBottom+firstLayerGap,(length-1)*dr+duploNibbleRadius*2+duploGapBottom+0.2,firstLayerGapHeight+0.01],true);
      }
      else
         for(j=[1:length])
         {   
            translate([0,(+j-length/2 - 0.5)*dr,0 ])
               cube([ duploNibbleRadius*2+duploGapBottom,duploNibbleRadius*2+duploGapBottom,height*duploHeight+2],true);
         }
   }
   }
}


module duplonibble()
{
   difference() {
      union() {
         translate([0,0,-0.5/2]) cylinder(r=duploNibbleRadius,h=4.5-1,center=true,$fn = quality);
         translate([0,0,4.5/2-1]) cylinder(r1=duploNibbleRadius,r2=duploNibbleRadius-0.2,h=1,$fn = quality);
      }
      cylinder(r=duploNibbleRadius-1.3,h=5.5,center=true,$fn = quality);
   }
}

module duplobottomnibble(height)
{
   difference() {
      union(){
         cylinder(r=duploBottomNibbleRadius-firstLayerGap,h=height,center=true,$fn = quality);
         translate([0,0,bottomGapHeight/2]) cylinder(r=duploBottomNibbleRadius,h=height-firstLayerGapHeight,center=true,$fn = quality);
      }
      cylinder(r=duploBottomNibbleRadius-1.3,h=height+1,center=true,$fn = quality);
   }

}


module smallPlate()
{
   translate([pr,pr,0])            straightPiece();
   translate([pr,0,0])             cornerPiece();
   translate([0,0,duploHeight])    rampPiece();
   translate([0,pr,0])             endPiece();
}

module bigPlate()
{
   for( i=[0:1]) {
      translate([pr,pr*i,0])                       straightPiece(); 
      translate([2*pr ,pr*i,0])                    cornerPiece(); 
   }
   translate([pr,pr*2,0])                          straightPiece();
   translate([pr,pr*3,0])                          crossingPiece();
   for( i=[2:3]) { 
      translate([2*pr ,pr*i,0])                    endPiece(); 
   }
   translate([0*pr,pr*1,duploHeight])              rampPiece();
   translate([0*pr,pr*0,duploHeight])              ramp2Piece();
   for( i=[0:1]) {
      translate([-pr,pr*(i+2),duploHeight])        straightHolePiece(); 
      translate([0*pr,pr*(i+2),duploHeight])       cornerHolePiece(); 
   }

   translate([-pr,0,duploHeight])                  rampCornerPiece(steps=quality); 
   translate([-pr,pr,duploHeight]) mirror([0,1,0]) rampCornerPiece(steps=quality); 
}

module duploMarbleRunBase(width,length,height,topNibbles,bottomHoles)
{
   union() {
      duplo(width,length,height,topNibbles,bottomHoles);
      translate([0,0,3])
         cube([width*duploRaster-0.4,length*duploRaster-0.4,duploHeight*height-6],center=true);
   }
}

module straightPiece()
{
   difference() {
      duploMarbleRunBase(2,2,2,false);
      translate([0,dr+1, duploHeight+2]) rotate([90,0,0])
         cylinder( duploRaster*4, innerRadius, innerRadius,$fn = quality*2 );
   }
}

module straightHolePiece()
{
   difference() {
      duploMarbleRunBase(2,2,4,true);
      translate([0,dr+1, 0*duploHeight+2]) rotate([90,0,0])
         cylinder( duploRaster*4, innerRadius, innerRadius,$fn = quality*2 );
   }
}

module crossingPiece()
{
   difference() {
      duploMarbleRunBase(2,2,2,false);
      translate([0,dr+1, duploHeight+2]) rotate([90,0,0])
         cylinder( duploRaster*4, innerRadius, innerRadius,$fn = quality*2 );
      translate([-dr-1,0, duploHeight+2]) rotate([0,90,0])
         cylinder( duploRaster*4, innerRadius, innerRadius,$fn = quality*2 );
   }
}

module endPiece()
{
   difference() {
      duploMarbleRunBase(2,2,2,false);
      union() {
         translate([0,dr+2, duploHeight+2]) rotate([90,0,0])
            cylinder( dr+2, innerRadius, innerRadius,$fn = quality*2 );
         translate([0,0, duploHeight+2]) rotate([90,0,0])
            sphere( innerRadius, $fn = quality*2 );
      }
   }
}

module cornerPiece()
{
   difference() {
      duploMarbleRunBase(2,2,2,false);
      translate([-dr,-dr,duploHeight+2])rotate_extrude(convexity = 10, $fn = quality*2)
         translate([dr, 0, 0]) circle(r = innerRadius, $fn = quality*2);
   }
}

module cornerHolePiece()
{
   difference() {
      duploMarbleRunBase(2,2,4,true);
      translate([-dr,-dr,0*duploHeight+2])rotate_extrude(convexity = 10, $fn = quality*2)
         translate([dr, 0, 0]) circle(r = innerRadius, $fn = quality*2);
   }
}

module rampPiece()
{
   angle = 30.964; // 180 / 3.14159 * atan(duploHeight/duploRaster);
   vscale = 0.8575; // cos(angle);
   difference() {
      duploMarbleRunBase(2,2,4,false);
      
      union() {
         translate([0,dr+1, 2*duploHeight+2]) rotate([90+angle,0,0]) scale([1,vscale,1])
            cylinder( duploRaster*4, innerRadius, innerRadius,$fn = quality*2 );   
         translate([-2*dr,dr+0, 2*duploHeight+0]) rotate([90+angle,0,0])
            cube( [duploRaster*4,duploRaster*8,duploRaster*4] );   
      }
   }
}

module ramp2Piece()
{
   angle = 16.699; // 180 / 3.14159 * atan(0.5*duploHeight/duploRaster);
   vscale = 0.9578; // cos(angle);
   difference() {
      duploMarbleRunBase(2,2,4,false);      
      union() {
         translate([0,dr+1, duploHeight+2]) rotate([90+angle,0,0]) scale([1,vscale,1])
                  cylinder( duploRaster*6, innerRadius, innerRadius,, center=true, $fn = quality*2 );     
         translate([-2*dr,2*dr+0, 1.5*duploHeight+0]) rotate([90+angle,0,0])
                  cube( [duploRaster*4,duploRaster*4,duploRaster*4] );       
      }
   }
}

module longRampPiece()
{
   angle = 16.699; // 180 / 3.14159 * atan(0.5*duploHeight/duploRaster);
   vscale = 0.9578; // cos(angle);
   difference() {
      duploMarbleRunBase(2,4,4,false);      
      union() {
         translate([0,0*dr+1, duploHeight+2]) rotate([90+angle,0,0]) scale([1,vscale,1])
                  cylinder( duploRaster*6, innerRadius, innerRadius,, center=true, $fn = quality*2 );     
         translate([-2*dr,4*dr+0, 3*duploHeight+0]) rotate([90+angle,0,0])
                  cube( [duploRaster*4,duploRaster*4,duploRaster*8] );       
      }
   }
}

module cosinusSlopedRampPiece()
{
   difference() {
      duploMarbleRunBase(2,4,4,false);
      cosinusSlopedRamp(quality);      
   }
}

module cosinusSlopedRamp(steps) // nr of steps: e.g. coarse=10, fine=90
{
   translate([0,-2*dr,duploHeight])
   for(i=[0:180/steps:180])
   {
      translate([0,+i/180*dr*4-0.01,-cos(i)*duploHeight+2]) 
      multmatrix(m = [ [1, 0, 0, 0], [0, 1, 0, 0], [0, sin(i)*0.5, 1, 0], [0, 0, 0, 1] ]) 
      union() {
         rotate([-90,0,0]) cylinder(h=4.1*dr/steps,r=innerRadius, $fn=steps);
         translate([-dr,0,-2]) cube([4*dr,4.1*dr/steps,2*dr]);
      }
   }
}

module rampCornerPiece(steps)
{
   difference() {
      duploMarbleRunBase(2,2,4,false);
      cornerRamp(steps);      
   }
}

module cornerRamp(steps) // nr of steps: e.g. coarse=10, fine=90
{
   translate([-dr,-dr,2])
   for(i=[0:90/steps:90])
   {
      rotate([0,0,i]) translate([dr,0,i/90*2*duploHeight]) {
         // Using the rotate&shearing matrix produces nicer results with less steps.
         multmatrix(m = [ [1, 0, 0, 0], [0, 0, 1, -50/steps], [0, 1, 0.4, 0], [0, 0, 0, 1] ]) 
             union() {
                cylinder(h=50/steps,r=innerRadius, $fn=steps);
                translate([-dr,-2,0]) cube([4*duploRaster,4*duploRaster,70/steps]);
             }
      }
   }
}

]===]

function new(params)
   params    = params or {}
   options   = {
      fun  = "cosinusSlopedRampPiece();",
      fn   = 10,
      mass = .1,
   }

   for k,v in pairs(params) do options[k] = v end

   fn   = options.fn
   fun  = options.fun

   mass = options.mass

   return OpenSCAD(lib..options.fun, mass)
end

