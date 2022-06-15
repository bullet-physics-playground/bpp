// *********************************************************
// Persistence Of Vision Ray Tracer Scene Description File
// File name  : i_rad.inc
// Version    : 3.6.1
// Description: outdoor rad settings (2-pass rendering)
// Date       : Jul-Oct. 2005
// Author     : Jaime Vives Piqueres
// *********************************************************

   #if (use_radiosity=1)
    // 1st pass: save radiosity
    pretrace_start 0.05
    pretrace_end   0.01
    count 250
    nearest_count 10
    error_bound .5
    recursion_limit 1
    brightness rad_brightness
    save_file "saved.rad"
    normal off
    media off
  #else
    // 2nd pass : load settings  
    pretrace_start 1 pretrace_end 1 
    load_file "saved.rad" 
    error_bound .5
    recursion_limit 1
    always_sample off  
    brightness rad_brightness
    normal off
    media off
  #end

