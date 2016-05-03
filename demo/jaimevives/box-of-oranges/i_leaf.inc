// grass leaf, called within the grass patch macro 
#declare r_leaf=seed(1000*rand(ry));
#declare cnt_sections=0;
#declare leaf_height=min_height+(max_height-min_height)*rand(r_leaf);
#declare sect_height=.5*leaf_height/num_sections;
#declare leaf_radius=medium_radius*.5+medium_radius*rand(r_leaf);
#declare leaf_radius_ant=leaf_radius;
#declare leaf_decr=(.5*leaf_radius+.5*leaf_radius*rand(r_leaf))/num_sections;
#declare act_height=0; //sect_height;
#declare ant_height=0;
#declare act_z=0;
#declare ant_z=0;
#declare act_z2=leaf_radius*.25;
#declare ant_z2=leaf_radius*.25;
#declare curve_rad=leaf_height*.8+leaf_height*.2*rand(r_leaf);
#declare z_decr=2*sect_height*rand(r_leaf);
 #local rpl=rand(r_leaf);
 #local kk=.2+.5*rand(r_leaf);
 #local displ=10*rand(r_leaf);
 #while (cnt_sections<=num_sections)
  triangle{
   vrotate(<-leaf_radius_ant,ant_height,ant_z-(base_radius*rpl)>,<0,0*rpl,0>),
   vrotate(<-leaf_radius,act_height,act_z-(base_radius*rpl)>,<0,0*rpl,0>),
   vrotate(< 0,ant_height,ant_z2-(base_radius*rpl)>,<0,0*rpl,0>)
   uv_vectors <-leaf_radius+displ,ant_height>,<-leaf_radius+displ,act_height>,<0+displ,ant_height>
  }
  triangle{
   vrotate(< 0,ant_height,ant_z2-(base_radius*rpl)>,<0,0*rpl,0>),
   vrotate(<-leaf_radius,act_height,act_z-(base_radius*rpl)>,<0,0*rpl,0>),
   vrotate(<0,act_height,act_z2-(base_radius*rpl)>,<0,0*rpl,0>)
   uv_vectors <0+displ,ant_height>,<-leaf_radius+displ,act_height>,<0+displ,act_height>
  }
  triangle{
   vrotate(<0,ant_height,ant_z2-(base_radius*rpl)>,<0,0*rpl,0>),
   vrotate(<0,act_height,act_z2-(base_radius*rpl)>,<0,0*rpl,0>),
   vrotate(< leaf_radius,act_height,act_z-(base_radius*rpl)>,<0,0*rpl,0>)
   uv_vectors <0+displ,ant_height>,<0+displ,act_height>,<leaf_radius+displ,act_height>
  }
  triangle{
   vrotate(<0,ant_height,ant_z2-(base_radius*rpl)>,<0,0*rpl,0>),
   vrotate(<leaf_radius,act_height,act_z-(base_radius*rpl)>,<0,0*rpl,0>),
   vrotate(<leaf_radius_ant,ant_height,ant_z-(base_radius*rpl)>,<0,0*rpl,0>)
   uv_vectors <0+displ,ant_height>,<leaf_radius+displ,act_height>,<leaf_radius+displ,ant_height>
  }
  #declare ant_z=act_z;
  #declare act_z=act_z-z_decr;
  #declare ant_z2=act_z2;
  #declare act_z2=act_z2-z_decr;
  #declare ant_height=act_height;
  #declare act_height=curve_rad*sin((pi*kk)*cnt_sections/num_sections);
  #declare leaf_radius_ant=leaf_radius;
  #declare leaf_radius=leaf_radius-leaf_decr;
  #declare cnt_sections=cnt_sections+1;
 #end

