// main floor texture
#declare t_floor=
texture{
  pigment{
    image_map{jpeg "grassy_bank_7160794" interpolate 2}
  }
  finish{diffuse 0.7}
  rotate 90*x
  scale 50
  rotate 90*y
}
// texture for the grass blades
#declare t_floorf=
texture{
  uv_mapping
  pigment{
    image_map{jpeg "grassy_bank_7160794b" interpolate 2 filter all .33}
    translate .1
    scale 10
  }
  finish{diffuse 1}
}

// *** old grass patch macro ***
// normally used to create grass patches consisting on a few blades
// bus this time I used it for individual blades
#macro grass(rg,num_leaves)

#local ry=seed(1000*rg);
#local cnt_leaves=1;
#local min_height=3;
#local max_height=9;
#local medium_radius=.5;
#local base_radius=.1;
#declare num_sections=2;

mesh{
#while (cnt_leaves<=num_leaves)
 #include "i_leaf.inc"
 #declare cnt_leaves=cnt_leaves+1;
#end
}

#end

// *** create a distribution of blades ***
#declare grassw=180;
#declare f_distrib=
  function{
   pigment{
     granite scale grassw
   }
  }
#declare r_grass=seed(667);
#declare i_blades=0;
#declare grass_bank=
union{
#while (i_blades<n_blades)
  #declare grassl=<-grassw*.5+grassw*rand(r_grass),0,-grassw*.5+grassw*rand(r_grass)>;
  object{
    grass(rand(r_grass),1) // just one blade
    scale .5
    rotate -(45+45*rand(r_grass))*x
    rotate 360*f_distrib(grassl.x,0,grassl.z).gray*y
    translate grassl
  }
  #declare i_blades=i_blades+1;
#end
  double_illuminate
}

// *** put a few copies of the grass_bank over a plane ***
#declare r_floor=seed(562);
union{
  plane{y,0
    texture{
      pigment_pattern{bumps turbulence 1 scale 10}
      texture_map{
        [0.0 t_floor]
        [0.2 t_floor translate 100*rand(r_floor) rotate 360*rand(r_floor)*y]
        [0.4 t_floor translate 100*rand(r_floor) rotate 360*rand(r_floor)*y]
        [0.6 t_floor translate 100*rand(r_floor) rotate 360*rand(r_floor)*y]
        [0.8 t_floor translate 100*rand(r_floor) rotate 360*rand(r_floor)*y]
        [1.0 t_floor translate 100*rand(r_floor) rotate 360*rand(r_floor)*y]
      }
    }
  }
  union{
    object{grass_bank texture{t_floorf}} 
    object{grass_bank rotate 90*y texture{t_floorf}} 
    object{grass_bank rotate 90*2*y texture{t_floorf}} 
    object{grass_bank rotate 90*3*y texture{t_floorf}} 
    translate <-25,0,15>
  }
}

