/* Geneva Drive
 * v 202608.1
 */
// +w720 +h960 +am3 +a

#version 3.8;

global_settings {assumed_gamma srgb}

/* background, the objects */
#include "ruled.inc"
#include "gdr.inc"


/* camera, lights, action ... */

#switch (frame_number)
  #range (0,89)
    #declare rmx_ = .5 * frame_number;
    #declare rpd_ = .5 * frame_number;
    #break
  #range (90,629)
    #declare rmx_ = 45;
    #declare rpd_ = .5 * frame_number;
    #break
  #range (630,719)
    #declare rmx_ = 45 + .5 * frame_number;
    #declare rpd_ = .5 * frame_number;
    #break
  #else
    #error "oops, SNAFU.."
#end

// switch to perspective, at some point.
camera {
  orthographic
  location <0,0,5>
  right x * (3/4)
  up y
  angle 50
  look_at <0,0,0>
}

light_source {<-1,1,1>*1e3 color srgb 1 parallel}
light_source {<-1,-1,1>*1e3 color srgb 1 parallel}
light_source {<1,1,1>*1e3 color srgb 1 parallel}
light_source {<1,-1,1>*1e3 color srgb 1 parallel}

Ruled(dictionary {.norm: z, .offs: -2.5})

union {
  object {gdr_obj_mx_ material {gdr_mat_mx_}}
  object {gdr_obj_bb_}
  rotate <0,0,rmx_>
  translate <0,1.71,0>
}

union {
  object {gdr_obj_pd_}
  object {gdr_obj_bb_}
  rotate <0,0,rpd_>
}

