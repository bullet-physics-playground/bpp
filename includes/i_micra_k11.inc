// *********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : i_micra_k11.inc
// Version    : 3.6.1
// Description: Micra K11 : main include to join the pieces
// Date       : Mai 2016
// Author     : Jakob Flierl
// *********************************************************

#include "i_micra_body.inc"
#include "i_micra_accessories.inc"
#include "i_micra_glass.inc"
#include "i_micra_plates.inc"
#include "i_micra_r_wheel.inc"
#include "i_micra_lf_wheel.inc"
#include "i_micra_rf_wheel.inc"
#include "i_micra_inner.inc"
#include "i_wunderbaum.inc"

#declare micra_k11 = union{
  object{micra_body_}
  object{micra_inner_}
  object{micra_accessories_}
  object{micra_glass_ interior{fade_power 1001 fade_distance 10}}
  object{micra_plates_}
  //  object{micra_R_wheel_}
  //  object{micra_LF_wheel_ Rotate_Around_Trans(y*20, <-1, 0, 1.55>)} // rotate front left wheel
  //  object{micra_RF_wheel_ Rotate_Around_Trans(y*20, <1, 0, 1.55>)}  // rotate front right wheel
  object{wunderbaum_}
}

