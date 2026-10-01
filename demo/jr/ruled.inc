/* ruled.inc
 *
 * ruled background sheets, for scale modelling.
 *
 * macro Ruled(dict)
 *   the argument is a dictionary with key parameters, the  macro
 *   expands to ("returns") an oriented and positioned, pigmented,
 *   'plane {}' object, clipped as specified.
 *
 *   keys ('norm' and 'offs' mandatory):
 *     .norm:   <x,y,z>       the normal perpendicular to the plane.
 *     
 *     .offs:   n.n           float, the distance from origin along
 *                            the 'norm' axis.
 *     
 *     .divs:   n             int, range: 1,..,10.  the number of
 *                            dividing lines per unit.
 *
 *     .bg:     pigment       replaces the (light gray) default.
 *
 *     .fg:     n             int, range: 0,..,7.
 *                            0 - black  4 - cyan
 *                            1 - red    5 - magenta
 *                            2 - green  6 - yellow
 *                            3 - blue   7 - white
 *
 *     .from:   <col,row>     the start and end coordinates for the
 *     .to:     <col,row>     clipped_by{} modifier.
 *
 *     .dim:    0|1           reduces 'fg' brightness when true (1).
 *
 * the code is based on Friedrich Lohmueller's 'Raster_{Lines,Plate}'
 * macros; url: www.f-lohmueller.de/pov_tut/scale_model/s_mod_100e.htm
 *
 * version 201911.3
 */

#ifndef (rld_include_temp)

#declare rld_include_temp = version;

#version 3.8;

#ifdef (View_POV_Include_Stack)
#debug "including ruled.inc\n"
#end

/* "sensible" defaults.  10 divs, blue on lightgray, 10e5 extent */
#macro rld__mkDflt(d_)
  #ifndef (d_.bg)
    #local d_.bg = pigment {color srgb .85};
  #end
  #ifndef (d_.fg)
    #local d_.fg = 3;
  #elseif (0 > d_.fg | 7 < d_.fg | d_.fg != int(d_.fg))
    #error concat("oops, 'fg' must be integer in range 0,..,7.")
  #end
  #ifndef (d_.dim)
    #local d_.dim = 0;
  #elseif (!(1 = d_.dim | 0 = d_.dim))
    #error concat("oops, expected boolean 'dim', ie '0' or '1'.")
  #end
  #local sc_ = 10e5;
  #ifndef (d_.from) #local d_.from = <-1,-1> * sc_; #end
  #ifndef (d_.to) #local d_.to = <1,1> * sc_; #end
  #ifndef (d_.divs)
    #local d_.divs = 10;
  #elseif (1 > d_.divs | 10 < d_.divs | d_.divs != int(d_.divs))
    #error concat("oops, 'divs' must be integer in range 1,..,10.")
  #end
#end

/* make clipped_by dims */
#macro rld__mkClip(d_)
  #local eps_ = .001;
  #if (d_.norm.x & !(d_.norm.y | d_.norm.z))
    #local d_.clip1 = <d_.offs, d_.from.x, d_.from.y> - eps_;
    #local d_.clip2 = <d_.offs, d_.to.x, d_.to.y> + eps_;
  #elseif (d_.norm.y & !(d_.norm.x | d_.norm.z))
    #local d_.clip1 = <d_.from.x, d_.offs, d_.from.y> - eps_;
    #local d_.clip2 = <d_.to.x, d_.offs, d_.to.y> + eps_;
  #elseif (d_.norm.z & !(d_.norm.x | d_.norm.y))
    #local d_.clip1 = <d_.from.x, d_.from.y, d_.offs> - eps_;
    #local d_.clip2 = <d_.to.x, d_.to.y, d_.offs> + eps_;
  #else
    #error concat("oops, expected normal (<0,1,0>, or permutation), got <",
            vstr(3,d_.norm,",",0,0),">.\n")
  #end
#end

/* was 'Raster_Lines' */
#macro rld__lines(c_,f_,w_,b_)
  #local cs_ = <c_.red,c_.green,c_.blue,0>;
  #local ct_ = <c_.red,c_.green,c_.blue,1>;
pigment {
  #if (orient_) gradient x #else gradient y #end
  frequency f_
  color_map {
    [0.0     color srgbt cs_ * b_]
    [0 + w_  color srgbt cs_ * b_]
    [0 + w_  color srgbt ct_]
    [1 - w_  color srgbt ct_]
    [1 - w_  color srgbt cs_ * b_]
    [1.0     color srgbt cs_ * b_]
  }
}
#end

/* was 'Raster_Plate' */
#macro Ruled(d_)
  rld__mkDflt(d_)
  rld__mkClip(d_)
  #local ca_ = array [8] {
    <0,0,0>,<1,0,0>,<0,1,0>,<0,0,1>,<0,1,1>,<1,0,1>,<1,1,0>,<1,1,1>
  };
  #if (d_.norm.x) #local orient_ = 0; #else #local orient_ = 1; #end
  #local w1_ = .01;
  #local w2_ = .015;
  #local b1_ = (d_.dim ? .45 : .95);
  #local b2_ = (d_.dim ? .45 : .85);
  #local tf_ = finish {ambient 0 diffuse .1 emission ca_[d_.fg]};
plane {
  d_.norm, d_.offs
  no_reflection
  no_shadow
  clipped_by {box {d_.clip1,d_.clip2}}
  texture {pigment {d_.bg}}
  texture {
    rld__lines(ca_[d_.fg],1,w1_,b1_)
    finish {tf_}
  }
  texture {
    rld__lines(ca_[d_.fg],1,w1_,b1_)
    finish {tf_}
    rotate d_.norm * 90
  }
  texture {
    rld__lines(ca_[d_.fg],d_.divs,w2_,b2_)
    finish {tf_}
  }
  texture {
    rld__lines(ca_[d_.fg],d_.divs,w2_,b2_)
    finish {tf_}
    rotate d_.norm * 90
  }
}
#end

#version rld_include_temp;

#end

/* --------------------------------------------------------------- *
  * the content above is covered by the GPLv3+, see file COPYING. * 
  * copyright (c) 2019-2021 jr <creature.eternal@gmail.com>.      * 
  * all rights reserved.                                          * 
 * --------------------------------------------------------------- */
