/* Geneva Drive
 * v 202608.1
 */

#ifndef (gdrive_include_temp)
#declare gdrive_include_temp = version;

#ifdef (POV_Include_Stack_View)
  #debug "including 'gdr.inc'\n"
#end

/* constants & helpers */

#declare gdr_epsilon_ = 1e-4;
#declare gdr_mx_halflen_ = 1.3;
#declare gdr_pin_radius_ = .030;
#declare gdr_bb_radius_ = .105;

/* materials */

#declare gdr_mat_bb_ = material {
  texture {
    pigment {color srgb .15}
    finish {ambient 0 diffuse .4 emission 0}
  }
  interior {ior 1.5}
};

#declare gdr_mat_mx_ = material {
  texture {
    pigment {color srgb x}
    finish {ambient 0 diffuse .4 emission 0}
  }
  interior {ior 1.5}
};

#declare gdr_mat_pin_ = material {
  texture {
    pigment {color srgb .95}
    finish {ambient 0 diffuse .4 emission 0}
  }
  interior {ior 1.5}
};

#declare gdr_mat_pd_ = material {
  texture {
    pigment {color srgb x+y}
    finish {ambient 0 diffuse .4 emission 0}
  }
  interior {ior 1.5}
};


/* "pin & bearing" */

#declare gdr_obj_bb_ = union {
  difference {
    cylinder {<0,0,0>, <0,0,-(gdr_mx_halflen_/2)>, gdr_bb_radius_}
    cylinder {
      <0,0,gdr_epsilon_>, <0,0,-(gdr_mx_halflen_/2)>,
      (gdr_pin_radius_ + gdr_epsilon_)
      no_image
    }
    material {gdr_mat_bb_}
  }
  cylinder {
    <0,0,gdr_epsilon_>, <0,0,-(gdr_mx_halflen_/2)>, gdr_pin_radius_
    material {gdr_mat_pin_}
  }
};


/* "cross-disk" */

#declare gdr_box_cutaway_ = box {<-.120,-2,-1>, <.120,2,1>};

#declare gdr_cyl_cutaway_ = cylinder {<0,0,-2>, <0,0,2>, 1};

#declare gdr_bb_cutaway_ = cylinder {
  <0,0,gdr_epsilon_>, <0,0,-(gdr_mx_halflen_/2)>,
  (gdr_bb_radius_ + gdr_epsilon_)
};

#declare gdr_obj_mx_ = difference {
  box {
    <-gdr_mx_halflen_, -gdr_mx_halflen_, 0>,
    <gdr_mx_halflen_, gdr_mx_halflen_, -(gdr_mx_halflen_/2)>
  }
  object {gdr_box_cutaway_ no_image translate <0,-2.39,0>}
  object {gdr_box_cutaway_ no_image translate <0,2.39,0>}
  object {gdr_box_cutaway_ no_image rotate z * 90 translate <-2.39,0,0>}
  object {gdr_box_cutaway_ no_image rotate z * 90 translate <2.39,0,0>}
  object {gdr_cyl_cutaway_ no_image translate <-1.2,-1.2,0>}
  object {gdr_cyl_cutaway_ no_image translate <1.2,-1.2,0>}
  object {gdr_cyl_cutaway_ no_image translate <-1.2,1.2,0>}
  object {gdr_cyl_cutaway_ no_image translate <1.2,1.2,0>}
  object {gdr_bb_cutaway_ no_image}
};


/* "pin-disk" */

#declare gdr_disk_cutaway_ = cylinder {<0,0,-2>, <0,0,2>, 1.5};

#declare gdr_obj_pd_base_ = union {
  cylinder {<0,0,-(gdr_mx_halflen_/2)>, <0,0,-gdr_mx_halflen_>, 1.75}
  difference {
    cylinder {<0,0,-gdr_epsilon_>, <0,0,-(gdr_mx_halflen_/2)>, (1-gdr_epsilon_)}
    cylinder {gdr_disk_cutaway_ no_image translate <0,1.80,0>}
    object {gdr_bb_cutaway_ no_image}
  }
  material {gdr_mat_pd_}
};

#declare gdr_obj_pd_ = union {
  object {gdr_obj_pd_base_}
  object {
    gdr_obj_bb_
    translate <0,1.21,0>
  }
};


#version gdrive_include_temp;

#end

