 
#declare DiceColor = color red 1 green .95 blue .65;
#declare DotColor = color red .1 green .1 blue .1;
 
#declare DiceBody = intersection {
  box { <-1, -1, -1>, <1, 1, 1> scale 0.5 }
  superellipsoid { <0.7, 0.7>  scale .63 }
}
 
#declare Middle = sphere { <0, .6, 0>, .13}
 
#declare Corners1 = union {
  sphere { <-.25, .6, -.25>, .13 }
  sphere { <.25, .6, .25>, .13 }
}
 
#declare Corners2 = union {
  sphere { <-.25, .6, .25>, .13 }
  sphere { <.25, .6, -.25>, .13 }
}
 
#declare Middles = union {
  sphere { <-.25, .6, 0>, .13 }
  sphere { <.25, .6, 0>, .13 }
}
 
#declare One = Middle
 
#declare Two = Corners1
 
#declare Three = union {
  object { Middle }
  object { Corners1 }
}
 
#declare Four = union {
  object { Corners1 }
  object { Corners2 }
}
 
#declare Five = union {
  object { Four }
  object { One }
}
 
#declare Six = union {
  object { Corners1 }
  object { Corners2 }
  object { Middles }
}
 
#declare DiceInterior = interior { ior 1.5 }
 
#macro Dice(Color)
difference {
  object {
    DiceBody
    texture {
    pigment {color Color}
//    pigment { color Color filter 0.4 transmit 0.3}
      finish{
        specular albedo 0.05 roughness 0.02
        conserve_energy
      }
    }
//    interior { DiceInterior }
  }
  union {
    object { One rotate -90*z }
    object { Two }
    object { Three rotate -90*x }
    object { Four rotate 90*x }
    object { Five rotate 180*x }
    object { Six rotate 90*z }
    pigment { White }
    finish { roughness 0.5 specular albedo 0.05 conserve_energy }
 
  }
  bounded_by { box { <-.52, -.52, -.52>, <.52, .52, .52> } }
}
#end
 
// object { Dice(color rgb <.7, 0, 0>)  rotate <195, -30, 10>}
// object { Dice(color rgb <0, 0, .7>)  rotate <30,40,50> translate <3.5,1,1>}
// object { Dice(color rgb <0, .5, 0>)  rotate <-40,20,-120> translate <4.5,1,-1>}
// object { Dice(color rgb <.5,.5, 0>)  rotate <-10,290,-30> translate <5.5,-.8,0>}
