//==================================================
//POV-Ray Materials list
//==================================================
//This file has been created by PoseRay v3.8.18.390
//3D model to POV-Ray/Moray Converter.
//Author: FlyerX
//Email: flyerx_2000@yahoo.com
//Web: http://mysite.verizon.net/sfg0000/
//==================================================
// File: wunderbaum_POV_mat.inc
// Vers: 3.5-3.6
// Desc: for Nissan Micra (k11)
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
#declare p_map1=pigment {uv_mapping image_map{jpeg "wunderbaum.jpg" interpolate 2 transmit all 0 filter all 0} }
 
//==================================================
//Material definitions
#declare Tex_grey2_= 
texture{pigment {color rgb <1,1,1> transmit  0} 
        finish{phong 1 phong_size 10.1753 diffuse 0.6*1 ambient rgb <1,1,1> reflection{0 }}}
//==================================================
#declare wunderbaum_auv_= 
texture{pigment {color rgb <1,1,1> transmit  0} 
        finish{phong 1 phong_size 10.1753 diffuse 0.6*1 ambient rgb <1,1,1> reflection{0 }}}
texture{pigment{p_map1} 
        finish{ phong 1 phong_size 10.1753 diffuse 0.6*1 ambient rgb <1,1,1> reflection{0 }}}
//==================================================
