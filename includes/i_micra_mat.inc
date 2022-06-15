//==================================================
//POV-Ray Materials list
//==================================================
// File: micra_POV_mat.inc
// Vers: 3.5-3.6
// Desc: Nissan Micra (k11)
// Date: may 2006
// Auth: Rene Bui - http://rene.bui.free.fr
//
// Copyright 2006 Rene Bui - http://rene.bui.free.fr
// This work is licensed under the Creative Commons Attribution License. 
// To view a copy of this license, visit http://creativecommons.org/licenses/by/2.0/ 
// or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
// You are free:
// - to copy, distribute, display, and perform the work
// - to make derivative works
// - to make commercial use of the work
// Under the following conditions:
// - Attribution. You must give the original author credit.
// - For any reuse or distribution, you must make clear to others the license terms of this work.
// - Any of these conditions can be waived if you get permission from the copyright holder.
// Your fair use and other rights are in no way affected by the above. 
//==================================================
//Map definitions
#declare p_map1=normal {bump_map{jpeg "micra_cover_lr.jpg" interpolate 2 }}
#declare p_map2=normal {bump_map{jpeg "micra_cover_rr.jpg" interpolate 2 }}
#declare p_map3=normal {bump_map{jpeg "micra_cover_lf.jpg" interpolate 2 }}
#declare p_map4=normal {bump_map{jpeg "micra_cover_rf.jpg" interpolate 2 }}
#declare p_map5=normal {bump_map{jpeg "micra_blinker_l.jpg" interpolate 2 }}
#declare p_map6=normal {bump_map{jpeg "micra_blinker_r.jpg" interpolate 2 }}

#declare p_map7=normal {bump_map{jpeg "micra_headlight_l.jpg" interpolate 2 }}
#declare p_map8=normal {bump_map{jpeg "micra_headlight_r.jpg" interpolate 2 }}
#declare p_map9=pigment {uv_mapping image_map{png "micra_rearwindow_1.png" interpolate 2 transmit all 0 filter all 0} }
#declare p_map10=pigment {uv_mapping image_map{jpeg "micra_taillight_l.jpg" interpolate 2 transmit all 0 filter all 0} }
#declare p_map11=pigment {uv_mapping image_map{jpeg "micra_taillight_r.jpg" interpolate 2 transmit all 0 filter all 0} }
#declare p_map12=pigment {uv_mapping image_map{png "micra_windshield.png" interpolate 2 transmit all 0 filter all 0} }
#declare p_map13=pigment {uv_mapping image_map{png "micra_rearwindow_2.png" interpolate 2 transmit all 0 filter all 0} }
#declare p_map14=pigment {uv_mapping image_map{jpeg "wunderbaum.jpg" interpolate 2 transmit all 0 filter all 0} }

//==================================================
//Material definitions
//==================================================

#declare Dirt_= 
texture{pigment {color rgb .2} // color rgb .5
        finish{diffuse 0.6*1 ambient rgb 0 }
        //normal{ granite .1}
        }
//==================================================



//==================================================
// Headlights
#declare Glass_light_= 
texture{pigment {color rgb .5 filter .4} 
        finish{phong 1 phong_size 10 diffuse 0.6*1 ambient rgb 0 reflection{0, .08} conserve_energy}}
//==================================================
// Windows
#declare Glass_window_= 
//texture{pigment {color rgbf <.78, 1, .72, .98>}
//texture{pigment {color rgbf <.95, 1, .97, .98>}
texture{pigment {color rgbf <.85, .95, .87, .95>}
        finish{specular 1 roughness .001 diffuse 0 ambient 0 reflection {0, .14} conserve_energy}}  // reflection {0, .2}          
//==================================================



//==================================================
#declare Gum1_= 
texture{pigment {color rgb .2} 
        finish{diffuse 0.6*1 specular .8 roughness .05 ambient rgb 0}}
//==================================================
// Tyres
#declare Gum2_= 
texture{pigment {color rgb .4} 
        finish{diffuse 0.6*1 specular .2 roughness .005 ambient rgb 0}}
//==================================================



//==================================================
// Car color
#declare Paint_car_= 
texture{pigment {color rgb <89,83,91>/255} 
        finish{diffuse 0.6*1 specular .5 roughness .05 ambient rgb 0 reflection{0, .15 }}} //reflection{0, .15 } reflection{0, .05 } reflection{0, .08 }
//==================================================
#declare Paint_black_= 
texture{pigment {color rgb .3 transmit  0} 
        finish{diffuse 0.6*1 specular .8 roughness .05 ambient rgb 0 reflection{0 }}}
//==================================================
#declare Paint_silver_= 
texture{pigment {color rgb 1} 
        finish{diffuse 0.7*1 specular .9 roughness .05 brilliance 1 ambient rgb .02 }}
//==================================================
#declare Paint_white_= 
texture{pigment {color rgb 1} 
        finish{phong 0.5 phong_size 10 diffuse 0.6*1 ambient rgb .1 reflection{0.06 }}}
//==================================================
#declare Paint_yellow_= 
texture{pigment {color rgb <1, .88, .22> transmit  0} 
        finish{phong 0.5 phong_size 10 diffuse 0.6*1 ambient rgb .1 reflection{0.06 }}}
//==================================================



//==================================================
#declare Plastic_black_= 
texture{pigment {color rgb .25} 
        finish{phong .7 phong_size 10 diffuse 0.6*1 specular .5 roughness .05 ambient rgb 0}}
//==================================================
#declare Plastic_blacklig_= 
texture{pigment {color rgb .3 transmit  0} 
        finish{diffuse 0.6*1 specular .8 roughness .05 ambient rgb 0 reflection{0 }}}
//==================================================
#declare Plastic_grey_= 
texture{pigment {color rgb .47 transmit  0} 
        finish{diffuse 0.6*1 specular .2 roughness .001 ambient rgb 0 reflection{0 }}}
//==================================================
#declare Plastic_orange_= 
texture{pigment {color rgb <1, .68, 0> transmit  0.3} 
        finish{phong .7 phong_size 20 diffuse 0.7*1 ambient rgb 0 reflection{0, .2}}}
//==================================================
#declare Plastic_orlight_= 
texture{pigment {color rgb <1, .68, 0> filter  0.3} 
        finish{phong 1 phong_size 10 diffuse 0.6*1 ambient rgb .2 reflection{0, .3}}}
//==================================================
#declare Plastic_red_= 
texture{pigment {color rgb <1, .12, 0> transmit  0.19} 
        finish{phong 1 phong_size 20 diffuse 0.6*1 ambient rgb 0 reflection{0, .2}}}
//==================================================
#declare Plastica_transp_= 
texture{pigment {color rgb 1 transmit  0.5} 
        finish{phong 1 phong_size 10 diffuse 0.6*1 ambient rgb 0 reflection .08}}
//==================================================



//==================================================
#declare Metal_alu_= 
texture{pigment {color rgb <1,1,1> transmit  0} 
        finish{diffuse 0.7*1 specular .9 roughness .05 metallic ambient rgb .1 reflection{0, .1 }}}
//==================================================
#declare Metal_chrome_= 
texture{pigment {color rgb 1 transmit  0} 
        finish{diffuse 0.6*1 specular .9 roughness .001 brilliance 2 ambient rgb 0 reflection .5 }}
//==================================================



//==================================================
#declare Mirror_= 

texture{pigment {color rgb <.95,.98,1> transmit  0} 
        finish{specular 1 roughness .001 diffuse 0.6*1 ambient rgb 0 reflection 1}}

// texture{Mirror}        
//==================================================
#declare Carpet_= 
texture{pigment {color rgb .54 transmit  0} 
        finish{phong 0 diffuse 0.6*1 ambient rgb 0 }}
//==================================================
#declare Tex_grey_= 
texture{pigment {color rgb .6 transmit  0} 
        finish{phong 0 diffuse 0.6*1 ambient rgb 0 }}
//==================================================        



//==================================================
#declare cover_LR_auv_= 
texture{pigment {color rgb <1,1,1> transmit  0} 
        finish{diffuse 0.7*1 specular .9 roughness .05 metallic ambient rgb .1 reflection{0, .1 }}
        normal{uv_mapping p_map1 bump_size -3} 
        }
//==================================================
#declare cover_RR_auv_= 
texture{pigment {color rgb <1,1,1> transmit  0} 
        finish{diffuse 0.7*1 specular .9 roughness .05 metallic ambient rgb .1 reflection{0, .1 }}
        normal{uv_mapping p_map2 bump_size -3} 
        }
//==================================================
#declare cover_LF_auv_=
texture{pigment {color rgb <1,1,1> transmit  0} 
        finish{diffuse 0.7*1 specular .9 roughness .05 metallic ambient rgb .1 reflection{0, .1 }}
        normal{uv_mapping p_map3 bump_size -3} 
        }
//==================================================
#declare cover_RF_auv_=
texture{pigment {color rgb <1,1,1> transmit  0} 
        finish{diffuse 0.7*1 specular .9 roughness .05 metallic ambient rgb .1 reflection{0, .1 }}
        normal{uv_mapping p_map4 bump_size -3} 
        }
//==================================================
#declare blinker_L_auv_=
texture{pigment {color rgb <1, .68, 0> filter  0.3} 
        finish{phong .7 phong_size 20 diffuse 0.7*1 ambient rgb 0 reflection{0, .2} }
        normal{uv_mapping p_map5 bump_size 3}
        }
//==================================================
#declare blinker_R_auv_= 
texture{pigment {color rgb <1, .68, 0> filter  0.3} 
        finish{phong .7 phong_size 20 diffuse 0.7*1 ambient rgb 0 reflection{0, .2} }
        normal{uv_mapping p_map6 bump_size 3}
        }
//==================================================
#declare headlight_L_auv_= 
texture{pigment {color rgb <182,178,169>/255 filter .9} 
        finish{diffuse 0.6*1 specular .8 roughness .005 ambient rgb 0 reflection{0, .3}}
        normal{uv_mapping p_map7 bump_size -16} 
        }
//==================================================
#declare headlight_R_auv_= 
texture{pigment {color rgb <182,178,169>/255 filter .9} 
        finish{diffuse 0.6*1 specular .8 roughness .005 ambient rgb 0 reflection{0, .3}}
        normal{uv_mapping p_map8 bump_size -16} 
        }
//==================================================
#declare taillight_L_auv_= 
texture{pigment {color rgb <1, .12, 0> transmit  0.19} 
        finish{phong 1 phong_size 20 diffuse 0.6*1 ambient rgb 0 reflection{0, .2}}}
texture{pigment{p_map10} 
        finish{phong 1 phong_size 60 diffuse 0.6*1 ambient rgb 0.06 reflection{0, .5} }} // diffuse 7 reflection{0, .2}
//==================================================
#declare taillight_R_auv_= 
texture{pigment {color rgb <1, .12, 0> transmit  0.19} 
        finish{phong 1 phong_size 20 diffuse 0.6*1 ambient rgb 0 reflection{0, .2}}}
texture{pigment{p_map11} 
        finish{phong 1 phong_size 60 diffuse 0.6*1 ambient rgb 0.06 reflection{0, .5} }} // diffuse 7 reflection{0, .2}
//==================================================
#declare rearwindow_auv_= 
texture{pigment{p_map13} 
        finish{specular 0 roughness .001 diffuse .9 ambient 0 reflection {0}}}
texture{pigment{p_map9} 
        finish{specular 0 roughness .001 diffuse .6 ambient 0 reflection {0}}}       
texture{Glass_window_}
               
//==================================================
#declare windshield_auv_=
texture{pigment{p_map12} 
        finish{specular 0 roughness .001 diffuse .6 ambient 0 reflection {0}}}
texture {Glass_window_} 

//================================================== 
#declare wunderbaum_auv_= 
texture{pigment {color rgb <1,1,1> transmit  0} 
        finish{diffuse 0.6*1 ambient rgb 0 reflection{0 }}}
texture{pigment{p_map14} 
        finish{specular .1 roughness .001 diffuse 0.6*1 ambient rgb 0 reflection{0 }}}
//==================================================    
