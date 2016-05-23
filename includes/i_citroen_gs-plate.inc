// *********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : i_citroen_gs-plate.inc
// Version    : 3.6.1
// Description: Citroen GS piece: spanish-like plate
// Date       : Jul-Oct. 2005
// Author     : Jaime Vives Piqueres
// *********************************************************

#declare carplate=
height_field{
 png "hf_gs-plate"
 translate -.5
 rotate -90*x
 texture{t_gs_plate}
 scale <5,1.05,.05>*.1
}

