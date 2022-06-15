/*
Unfinished OpenSCAD model of the LEGO 8865 Test Car (B side)

Set 8865, released in 1988, was the third generation auto chassis and improved upon the technology in the previous version, set 8860, in many ways. More details about the set at http://www.technicopedia.com/8865.html

© 1997 – 2021 [Jakob Flierl](https://github.com/koppi)
*/

rundung = 0.03;    // corner antialiasing of a lego stone
b = 0.7;           // width of one s1x1x1
h = 0.28;          // height of one s1x1x1
nh = h*0.5;
$fn = 15;

module noppe() {
    rotate(90, [ 1, 0, 0 ])translate([0, h/2+nh+nh-0.005-rundung, 0]) 
    color("Yellow")
    cylinder(h = h/2+nh-rundung, r = 0.21, center = false);
}

module st(XSIZE,YSIZE,ZSIZE,NOPPEN,WHOLE) {
    translate ([b*XSIZE/2-b/2, h/2*YSIZE, b*ZSIZE/2-b/2]) union() {
      cube([b*XSIZE+0.007, h*YSIZE+0.015, b*ZSIZE+0.007], center=true);
          /*for (J = [0, 1, ZSIZE-1])
            for (I = [0, 1, XSIZE-1])
               translate([I*b, h*(YSIZE-1), J*b]) noppe();*/
   }
}

module sf1x1x1() { union() {st(1,1,1,false,false); } }
module sf2x1x1() { union() {st(2,1,1,false,false); } }
module sf3x1x1() { union() {st(3,1,1,false,false); } }
module sf4x1x1() { union() {st(4,1,1,false,false); } }
module sf6x1x1() { union() {st(6,1,1,false,false); } }
module sf8x1x1() { union() {st(8,1,1,false,false); } }
module sf10x1x1() { union() {st(10,1,1,false,false); } }
module sf12x1x1() { union() {st(12,1,1,false,false); } }

module s1x1x1() { union() { st(1,1,1,true,false); } }
module s1x3x1() { union() { st(1,3,1,true,false); } }
module s2x1x1() { union() { st(2,1,1,true,false); } }
module s2x1x2() { union() { st(2,1,2,true,false); } }
module s2x1x3() { union() { st(2,1,3,true,false); } }
module s2x1x4() { union() { st(2,1,4,true,false); } }
module s2x1x8() { union() { st(2,1,8,true,false); } }
module s2x3x1() { union() { st(2,3,1,true,false); } }
module s3x1x1() { union() { st(3,1,1,true,false); } }
module s4x1x1() { union() { st(4,1,1,true,false); } }
module s4x3x1() { union() { st(4,3,1,true,false); } }
module s6x1x1() { union() { st(6,1,1,true,false); } }
module s6x3x1() { union() { st(6,3,1,true,false); } }
module s8x1x1() { union() { st(8,1,1,true,false); } }
module s8x1x6() { union() { st(8,1,6,true,false); } }
module s6x1x6() { union() { st(6,1,6,true,false); } }
module s10x1x1() { union() { st(10,1,1,true,false); } }
module s10x1x6() { union() { st(10,1,6,true,false); } }
module t2x3x1() { union() { st(2,3,1, true, true); } }
module t4x3x1() { union() { st(4,3,1, true, true); } }
module t6x3x1() { union() { st(6,3,1, true, true); } }
module t8x3x1() { union() { st(8,3,1, true, true); } }
module t12x3x1() { union() { st(12,3,1, true, true); } }
module t16x3x1() { union() { st(16,3,1, true, true); } }

module lego_buggy_seat() {
    color("Blue") union() {
        s6x1x6();
        translate ([b*3,h,0]) s3x1x1();
        translate ([b,h*2,0]) s4x1x1();
        translate ([b*3,h,b*5]) s3x1x1();
        translate ([b,h*2,b*5]) s4x1x1();
        rotate(-65, [0,0,1]) union() {
            translate([-b*8.25,0,0]) s8x1x6();
            translate([-b*8.25,h,0]) s6x1x1();
            translate([-b*8.25,h,b*5]) s6x1x1();
            translate([-b*4.25,2*h,0]) s4x1x1();
            translate([-b*4.25,2*h,b*5]) s4x1x1();
        }
    }
}

module stossstange() {
    color("Red")
        union() {
            translate([b*17,8*h,b*3.5]) rotate(90, [ 0, 1, 0 ]) s8x1x1();
            translate([b*12,14*h,b*3.5]) s6x1x1();
            translate([b*12,14*h,-b*3.5]) s6x1x1();
            
            translate([b*12,30*h,b*4.5]) rotate(90, [ 0, 1, 0 ]) s10x1x6();
            translate([b*6,30*h,b*4.5]) rotate(90, [ 0, 1, 0 ]) s10x1x6();
            translate ([b*17,19*h,b*3.5]) s1x1x1();
            translate ([b*17,19*h,-b*3.5]) s1x1x1();
            translate ([b*17,20*h,b*3.5]) rotate (-90, [0,1,0]) s3x1x1();
            translate ([b*17,20*h,-b*3.5]) rotate ( 90, [0,1,0]) s3x1x1();
            
            translate ([b*17,21*h,b*3.5]) rotate (-90, [0,1,0]) t2x3x1();
            translate ([b*17,21*h,-b*3.5]) rotate ( 90, [0,1,0]) t2x3x1();
            
            translate ([b*6,21*h,b*5.5]) t12x3x1();
            translate ([b*6,21*h,-b*5.5]) t12x3x1();
            translate ([b*8,24*h,b*4.5]) s10x1x6();
            translate ([b*8,24*h,-b*9.5]) s10x1x6();
            translate ([b*8,25*h,b*5.5]) s10x1x1();
            translate ([b*8,25*h,-b*5.5]) s10x1x1();
            translate ([b*6,26*h,b*5.5]) t12x3x1();
            translate ([b*6,26*h,-b*5.5]) t12x3x1();
            
            translate ([b*17,29*h,b*3.5]) rotate (90, [0,1,0]) s4x1x1();
            translate ([b*17,29*h,-b*3.5])rotate (-90, [0,1,0]) s4x1x1();
            translate ([b*14,29*h,b*5.5]) rotate (90, [0,1,0]) s2x1x4();
            translate ([b*17,29*h,-b*5.5])rotate (-90, [0,1,0]) s2x1x4();
            translate ([b*6,29*h,b*5.5]) rotate (90, [0,1,0]) s2x1x8();
            translate ([b*13,29*h,-b*5.5])rotate (-90, [0,1,0]) s2x1x8();
            translate ([b*12,30*h,b*4.5]) rotate (90, [0,1,0]) s10x1x6();
            translate ([b*6,30*h,b*4.5]) rotate (90, [0,1,0]) s10x1x6();
            
            // the following should be gray
            translate ([b*12,14*h,b*.5]) rotate (90, [0,1,0]) s4x1x1();
            translate ([b*17,18*h,b*3.5]) s1x1x1();
            translate ([b*17,18*h,-b*3.5]) s1x1x1();
            translate ([b*17,24*h,b*3.5]) rotate (90, [0,1,0]) s8x1x1();
            translate ([b*17,25*h,b*2.5]) rotate (90, [0,1,0]) t6x3x1();
            
            // the following should be black
            translate ([b*17,9*h,b*3.5]) s4x1x1();
            translate ([b*17,9*h,-b*3.5]) s4x1x1();
            translate ([b*20,9*h,b*2.5]) rotate (90, [0,1,0]) s6x1x1();
            translate ([b*16,10*h,b*3.5]) t4x3x1();
            translate ([b*16,10*h,-b*3.5]) t4x3x1();
            translate ([b*20,10*h,b*1.5]) rotate (90, [0,1,0]) t4x3x1();
            translate ([b*20,10*h,b*9.5]) rotate (90, [0,1,0]) t8x3x1();
            translate ([b*20,10*h,-b*9.5]) rotate (-90, [0,1,0]) t8x3x1();
            translate ([b*17,13*h,-b*3.5]) s4x1x1();
            translate ([b*17,13*h,b*3.5]) s4x1x1();
            translate ([b*20,13*h,b*2.5]) rotate (90, [0,1,0]) s3x1x1();
            translate ([b*20,13*h,-b*2.5]) rotate (-90, [0,1,0]) s3x1x1();
            translate ([b*12,14*h,b*1.5]) s2x1x2();
            translate ([b*17,9*h,b*2.5]) rotate (90, [0,1,0]) s2x1x1();
            translate ([b*17,9*h,-b*2.5]) rotate (-90, [0,1,0]) s2x1x1();
            translate ([b*17,10*h,b*2.5]) rotate (90, [0,1,0]) t2x3x1();
            translate ([b*17,10*h,-b*2.5]) rotate (-90, [0,1,0]) t2x3x1();
            translate ([b*17,13*h,b*2.5]) rotate (90, [0,1,0])  s6x1x1();
            translate ([b*16,12.4*h,b*4.5]) rotate (-90, [0,0,1]) t4x3x1();
            translate ([b*16,12.4*h,-b*4.5]) rotate (-90, [0,0,1]) t4x3x1();
            translate ([b*17,28*h,b*4.5]) rotate (90, [0,1,0]) s10x1x1();
            translate ([b*17.5,26.5*h,4.5*b]) rotate (90, [0,1,0])  rotate (90, [1,0,0]) s2x1x1();
            translate ([b*17.5,26.5*h,-3.5*b])  rotate (90, [0,1,0]) rotate (90, [1,0,0]) s2x1x1();
  }
}

module carosserie() {
    color("Gray") union() {
        translate([-b*2,0,-b*2.5]) t6x3x1();
        translate([-b*2,0,b*2.5]) t6x3x1();
        
        translate([-b*2,3*h,-b*2.5]) s2x1x1();
        translate([-b*2,3*h,b*2.5]) s2x1x1();

        translate([b*10,3*h,-b*1.5]) s4x1x1();
        translate([b*10,3*h,b*1.5]) s4x1x1();

        translate([b*10,4*h,-b*1.5]) s4x1x1();
        translate([b*10,4*h,b*1.5]) s4x1x1();

        translate ([0,0,-b*1.5]) t12x3x1();
        translate ([0,0,b*1.5]) t12x3x1();
        
        translate ([b*10,b*3,-b/2]) rotate(-90, [0,0,1]) t4x3x1();
        translate ([b*10,b*3,b/2]) rotate(-90, [0,0,1]) t4x3x1();
        
        translate ([b*3,3*h,b*2.5]) rotate(90, [0,1,0]) s6x1x1();   
        
        translate ([b*12,0,b*3.5]) rotate(90, [0,1,0]) t8x3x1();
        translate ([b*12,10*h,b*3.5]) rotate(90, [0,1,0]) t8x3x1();
        
        translate ([-b*2,4*h,-b*2.5]) s6x1x1();
        translate ([-b*2,4*h,b*2.5]) s6x1x1();
        
        translate ([-b*2,10*h,-b*2.5]) s6x3x1();
        translate ([-b*2,10*h,b*2.5]) s6x3x1();
        
        translate ([-b*2,8*h,-b*2.5]) s6x1x1();
        translate ([-b*2,8*h,b*2.5]) s6x1x1();
        
        color("Black") union() {
            translate([b*10,5*h,-b*1.5]) t8x3x1();
            translate([b*10,5*h,b*1.5]) t8x3x1();
            }
        }        
}

module hinterteil() {
    color("Gray") union() {
        translate([-b*12,10*h,-b*4.5]) t16x3x1();
        translate([-b*12,10*h,b*4.5]) t16x3x1();
        translate([-b*2,13*h,-b*4.5]) s2x1x3();
        translate([-b*2,13*h,b*2.5]) s2x1x3();
        translate([0,13*h,b*4.5]) s4x1x1();
        translate([0,13*h,b*2.5]) s4x1x1();
        translate([0,13*h,-b*4.5]) s4x1x1();
        translate([0,13*h,-b*2.5]) s4x1x1();
        
        translate([-b*8,10*h,b*5.5]) t4x3x1();
        translate([-b*8,10*h,-b*5.5]) t4x3x1();
        
        translate([-b*12,7*h,b*4.5]) rotate(90,[0,1,0]) t2x3x1();
        translate([-b*12,7*h,-b*4.5]) rotate(-90,[0,1,0]) t2x3x1();
        
        translate([-b*12,10*h,b*3.5]) s1x3x1();
        translate([-b*12,10*h,-b*3.5]) s1x3x1();
        
        color("Red") union() {
            translate ([-b,14*h,b*2.5]) rotate(-90,[0,1,0]) s4x1x1();
            translate ([0,14*h,b*2.5])rotate(-90,[0,1,0]) s4x1x1();
            translate ([b,14*h,b*2.5])rotate(-90,[0,1,0]) s4x1x1();
            translate ([-b,14*h,-b*2.5])rotate(90,[0,1,0]) s4x1x1();
            translate ([0,14*h,-b*2.5])rotate(90,[0,1,0]) s4x1x1();
            translate ([b,14*h,-b*2.5])rotate(90,[0,1,0]) s4x1x1();
            translate ([-b*12,h*17,b*7.5])rotate(90,[0,1,0]) t16x3x1();
            translate ([-b*12,h*22,b*7.5])rotate(90,[0,1,0]) t16x3x1();
            translate ([-b*12,20*h,b*7.5]) s2x1x1();
            translate ([-b*12,21*h,b*7.5]) s2x1x1();
            translate ([-b*12,20*h,-b*7.5]) s2x1x1();
            translate ([-b*12,21*h,-b*7.5]) s2x1x1();
            //XXX clip
            translate ([-b*13,17*h,6.5*b])rotate(90,[0,0,1])rotate(90,[1,0,0]) t4x3x1();
            translate ([-b*13,17*h,-6.5*b])rotate(90,[0,0,1])rotate(-90,[1,0,0])  t4x3x1();
            translate ([-b*13,7*h,3.5*b])rotate(90,[0,0,1])rotate(90,[1,0,0]) t6x3x1();
            translate ([-b*13,7*h,-3.5*b])rotate(90,[0,0,1])rotate(-90,[1,0,0]) t6x3x1();

            translate ([-b*11,22*h,b*7.5]) t8x3x1();
            translate ([-b*11,22*h,-b*7.5]) t8x3x1();
            //XXX clip
            translate ([-b*2.6,14.4*h,b*7.5]) t8x3x1();
            translate ([-b*2.6,14.4*h,-b*7.5]) t8x3x1();
            translate ([-b*5.2,23.5*h,b*8.5])rotate(-52,[0,0,1]) t6x3x1();
            translate ([-b*5.2,23.5*h,-b*8.5])rotate(-52,[0,0,1]) t6x3x1();
        }
    }
}

module hinterradlager() {
    union() {
        // left
        t6x3x1();
        translate([0,0,b]) t6x3x1();
        translate([-b,3*h,b]) rotate(90, [0,1,0]) s2x1x3();
        translate([-b,4*h,0]) s2x1x2();
        //XXX
        translate([-b,8*h,0]) s2x1x2();
        translate ([0,10*h,0]) t6x3x1();
        translate ([0,10*h,b]) t6x3x1();
        
        translate ([b,0,-b]) rotate(90, [0,0,1]) t6x3x1();
        translate ([4*b,0,-b]) rotate(90, [0,0,1]) t6x3x1();
        translate ([b,0,2*b]) rotate(90, [0,0,1]) t6x3x1();
        translate ([4*b,0,2*b]) rotate(90, [0,0,1]) t6x3x1();
  
        //right
        translate([12*b,0,0]) t6x3x1();
        translate([12*b,0,b]) t6x3x1();
        translate([-b+17*b,3*h,b]) rotate(90, [0,1,0]) s2x1x3();
        
        translate([-b+18*b,4*h,0]) s2x1x2();
        translate([5*b+7*b,3*h,b]) rotate(90, [0,1,0]) s2x1x1();
        translate([5*b+7*b,4*h,b]) rotate(90, [0,1,0]) s2x1x1();
        
        translate ([-b+18*b,5*h,b]) rotate(90, [0,1,0]) t2x3x1();
        translate ([0+18*b,5*h,b]) rotate(90, [0,1,0]) t2x3x1();
        translate ([-b+17*b,9*h,b]) rotate(90, [0,1,0]) s2x1x3();
        translate ([-b+18*b,8*h,0]) s2x1x2();
        translate ([0+12*b,10*h,0]) t6x3x1();
        translate ([0+12*b,10*h,b]) t6x3x1();

        translate ([b+12*b,12.5*h,-b]) rotate(-90, [0,0,1]) t6x3x1();
        translate ([4*b+12*b,12.5*h,-b]) rotate(-90, [0,0,1]) t6x3x1();
        translate ([b+12*b,12.5*h,2*b]) rotate(-90, [0,0,1]) t6x3x1();
        translate ([4*b+12*b,12.5*h,2*b]) rotate(-90, [0,0,1]) t6x3x1();

    }
}

module lenklager() {
    translate([0,0,-b*1.5]) s2x1x4();
    translate([-b,0,-b*1.5]) s1x1x1();
    translate([-b,0,b*1.5]) s1x1x1();
    color("Gray") union() {
        translate([b,h,b*.5]) sf1x1x1();
        translate([b,h,-b*.5]) sf1x1x1();
        translate([0,20*h,-b*4.5]) rotate(-90, [0,1,0]) s10x1x1();
        translate([0,21*h,-b*3.5]) rotate(-90, [0,1,0]) s8x1x1();
        translate([0,22*h,-b*2.5]) rotate(-90, [0,1,0]) s6x1x1();
        //XXX t12x3x1
        };
    union() {
        translate([-b,h,-b*1.5]) s2x1x1();
        translate([-b,h,b*1.5]) s2x1x1();
        translate([0,2*h,-b*1.5]) rotate(-90, [0,1,0]) t4x3x1();
        translate([-b,2*h,-b*1.5]) s1x3x1();
        translate([-b,2*h,b*1.5]) s1x3x1();
        translate([0,5*h,-b*.5]) rotate(-90, [0,1,0]) s2x1x1();
        translate([-b,5*h,-b*1.5]) s2x1x1();
        translate([-b,5*h,b*1.5]) s2x1x1();
        translate([0,6*h,-b*1.5]) rotate(-90, [0,1,0]) s4x1x1();
        translate([-b,6*h,-b*1.5]) s1x1x1();
        translate([-b,6*h,b*1.5]) s1x1x1();
        translate([0,7*h,-b*.5]) rotate(-90, [0,1,0]) t2x3x1();
        translate([-b,7*h,-b*1.5]) t2x3x1();
        translate([-b,7*h,b*1.5]) t2x3x1();
        translate([0,10*h,-b*1.5]) rotate(-90, [0,1,0]) s4x3x1();
        translate([0,13*h,b*.5]) rotate(-90, [0,1,0]) s6x1x1();
        translate([0,13*h,-b*.5]) rotate(90, [0,1,0]) s6x1x1();
        translate([0,14*h,-b*.5]) rotate(-90, [0,1,0]) s2x3x1();
        translate([0,17*h,-b*.5]) rotate(-90, [0,1,0]) t2x3x1();
        translate([0,14*h,-b*4.5]) rotate(90, [0,1,0]) s2x3x1();
        translate([0,17*h,-b*4.5]) rotate(90, [0,1,0]) s2x1x1();
        
        translate([0,14*h,b*4.5]) rotate(-90, [0,1,0]) s2x3x1();
        translate([0,17*h,b*4.5]) rotate(-90, [0,1,0]) s2x1x1();
    }
}

module lego_buggy() {
    union() {
        translate([-3*b,15*h,b*1.5]) lego_buggy_seat();
        translate([-3*b,15*h,-b*6.5]) lego_buggy_seat();
        
        stossstange();
        hinterteil();
        carosserie();
        
        //translate([-9*b,-5*h,8.5*b]) rotate(90, [0,1,0]) hinterradlager();
        translate([8*b,3*h,0]) lenklager();
    }
}

lego_buggy();

