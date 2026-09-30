// ivory finish
#declare f_ivory1=
finish{
  phong 1 phong_size 200
  reflection{0,1 fresnel}  
  conserve_energy
}
#declare f_ivory2=
finish{
  phong 1 phong_size 50
  reflection{0,0.25 fresnel}  
  conserve_energy
}

#declare n_ivory=
normal{ uv_mapping
 bump_map{
  jpeg "b16walls014-bm.jpg" interpolate 2
 }
 scale 2
}

#declare p_dirt=pigment{
  //wrinkles turbulence 2
  spotted turbulence 3
}
#declare dirt_level=0.33;

// + declare the final textures
#declare mfa=.33;

#declare t_ivory0=
texture{
  pigment{
    image_map{jpeg "ball0" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}

#declare t_ivory1a=
texture{
  pigment{
    image_map{jpeg "ball1" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory1b=
texture{
  pigment{
    image_map{jpeg "ball1" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory1=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory1a]
    [1.0 t_ivory1b]
  }
}

#declare t_ivory2a=
texture{
  pigment{
    image_map{jpeg "ball2" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory2b=
texture{
  pigment{
    image_map{jpeg "ball2" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory2=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory2a]
    [1.0 t_ivory2b]
  }
}

#declare t_ivory3a=
texture{
  pigment{
    image_map{jpeg "ball3" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory3b=
texture{
  pigment{
    image_map{jpeg "ball3" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory3=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory3a]
    [1.0 t_ivory3b]
  }
}

#declare t_ivory4a=
texture{
  pigment{
    image_map{jpeg "ball4" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory4b=
texture{
  pigment{
    image_map{jpeg "ball4" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory4=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory4a]
    [1.0 t_ivory4b]
  }
}

#declare t_ivory5a=
texture{
  pigment{
    image_map{jpeg "ball5" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory5b=
texture{
  pigment{
    image_map{jpeg "ball5" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory5=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory5a]
    [1.0 t_ivory5b]
  }
}

#declare t_ivory6a=
texture{
  pigment{
    image_map{jpeg "ball6" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory6b=
texture{
  pigment{
    image_map{jpeg "ball6" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory6=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory6a]
    [1.0 t_ivory6b]
  }
}

#declare t_ivory7a=
texture{
  pigment{
    image_map{jpeg "ball7" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory7b=
texture{
  pigment{
    image_map{jpeg "ball7" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory7=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory7a]
    [1.0 t_ivory7b]
  }
}

#declare t_ivory8a=
texture{
  pigment{
    image_map{jpeg "ball8" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory8b=
texture{
  pigment{
    image_map{jpeg "ball8" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory8=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory8a]
    [1.0 t_ivory8b]
  }
}

#declare t_ivory9a=
texture{
  pigment{
    image_map{jpeg "ball9" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory9b=
texture{
  pigment{
    image_map{jpeg "ball9" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory9=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory9a]
    [1.0 t_ivory9b]
  }
}

#declare t_ivory10a=
texture{
  pigment{
    image_map{jpeg "ball10" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory10b=
texture{
  pigment{
    image_map{jpeg "ball10" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory10=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory10a]
    [1.0 t_ivory10b]
  }
}

#declare t_ivory11a=
texture{
  pigment{
    image_map{jpeg "ball11" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory11b=
texture{
  pigment{
    image_map{jpeg "ball11" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory11=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory11a]
    [1.0 t_ivory11b]
  }
}

#declare t_ivory12a=
texture{
  pigment{
    image_map{jpeg "ball12" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory12b=
texture{
  pigment{
    image_map{jpeg "ball12" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory12=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory12a]
    [1.0 t_ivory12b]
  }
}

#declare t_ivory13a=
texture{
  pigment{
    image_map{jpeg "ball13" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory13b=
texture{
  pigment{
    image_map{jpeg "ball13" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory13=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory13a]
    [1.0 t_ivory13b]
  }
}

#declare t_ivory14a=
texture{
  pigment{
    image_map{jpeg "ball14" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory14b=
texture{
  pigment{
    image_map{jpeg "ball14" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory14=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory14a]
    [1.0 t_ivory14b]
  }
}

#declare t_ivory15a=
texture{
  pigment{
    image_map{jpeg "ball15" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory1}
}
#declare t_ivory15b=
texture{
  pigment{
    image_map{jpeg "ball15" map_type 1 interpolate 2 #if(use_media) filter all mfa #end}
  }
  normal{n_ivory} 
  finish{f_ivory2}
}
#declare t_ivory15=
texture{
  pigment_pattern{p_dirt}
  texture_map{
    [dirt_level t_ivory15a]
    [1.0 t_ivory15b]
  }
}
