// Persistence of Vision Ray Tracer Scene Include File
// File: bpp_CIE_Skylight.inc
// Desc: Sky model include file (for LightsysIV)
// Date: 2002 dev 05
// First version : 2002 nov 14
// Version : 0.61b  THIS IS A BETA VERSION! 
// POV-Ray version : 3.5

// Auth: Philippe Debar phdebar@yahoo.fr

// Modified for the use with LightsysIV and CIE.inc
// -Ive, April-2003
// -Ive, nov-2003 : last minute hack to avoid PoV warning messages 


// Sources : Preetham
//           "A practical analytical model for daylight"
//           http://www.cs.utah.edu/vissim/papers/sunsky/index.html

//           Charles Poynton
//           Color and Gamma FAQ
//           http://www.inforamp.net/~poynton/ColorFAQ.html
//           http://www.inforamp.net/~poynton/GammaFAQ.html 

//           Adrian Ford & Alan Roberts
//           Colour Space Conversions
//           Can be found at Poynton's website : http://www.inforamp.net/~poynton/PDFs/coloureq.pdf

//           Colourware
//           Color Physic Faq
//           http://www.colourware.co.uk/cpfaq.htm

// ======================================================
// Warning : These conversions assume POV is working with
// a linear colour space - i.e. assumed_gamma 1.0
// ======================================================
// "internal" identifiers will begin with SkL
// ======================================================
          

// Standard include file beginning stuff
#ifdef(View_POV_Include_Stack)
  #debug "Including Skylight.inc\n"
#end

// Set new line
#debug "\n"


// ======================================================
// Primary Default values
// ======================================================

#ifndef(DomeSize) #declare DomeSize=1e5; #end

#ifndef(North) #local North=-z; #end
#ifndef(Al) #local Al=35; #end
#ifndef(Az) #local Az=45; #end

#ifndef (Intensity_Mult) #local Intensity_Mult=.75; #end        
#ifndef(Int_Sun_weight) #local Int_Sun_weight=2; #end
#ifndef(Int_Zenith_weight) #local Int_Zenith_weight=1; #end
#ifndef(Int_Horizon_weight) #local Int_Horizon_weight=1; #end


#ifndef(Current_Turbidity) #local Current_Turbidity=3.0; #end

#ifndef(Tesselation_Trigger) #local Tesselation_Trigger=0.95; #end

#ifndef(Max_Vertices) #local Max_Vertices=12+4*1247; #end

#ifndef(Min_Vertices) #local Min_Vertices=12+60; #end // update to 12+30*1 when remove duplicate vertices
                                                      //(12 vtx + 30 edges * 1 new vertices)

#ifndef(UnderHorizonCorrection) #local UnderHorizonCorrection=true; #end

#ifndef(Horizon_Epsilon) #local Horizon_Epsilon=1e-3; #end


// ======================================================
// Secondary Default values
// ======================================================

// fiLuminous corrected for allowing user to specify its own value and
// to prevent #default{} from spewing troubles here - Philippe 08 june 2003
#ifndef (fiLuminous)
  #local fiLuminous=finish{ambient 1 diffuse 0 specular 0 phong 0 reflection 0 crand 0 irid{0} emission 0}
#end

#ifdef(Turb_amount)
  #local Turb_param=<2.0, 0.5, 6>; // <lambda, omega, octaves>
  #local Turb_scale=5;
#end

#ifdef(UseSolarPosition)
  #if (UseSolarPosition) 
    #ifdef(SolarPosition)
      #declare Az=degrees(atan2( SolarPosition.x, SolarPosition.z))-degrees(atan2( North.x, North.z));
      #declare Al=degrees(atan2( SolarPosition.y, vlength(SolarPosition*<1,0,1>)));
    #else
      #error "UseSolarPosition declared but SolarPosition undeclared."
    #end
  #end
#end


#local Current_Ts=radians(Al);
#local Current_Azimuth=radians(Az);


#declare Max_Vertices=max(Max_Vertices,12);

#ifndef(Max_Faces) #local Max_Faces=20+4/3*(Max_Vertices-12)+1; #end // update when remove duplicate vertices
//                                                           ^ +1 to remove #debug about max faces when user did not specify Max_Faces

#if (vlength(y*North)>1e6)
  #debug "Warning: North vector is not horizontal; results may not be what you want.\n"
#end
#if (vlength(North)<1e-6)
  #debug "Warning: North vector is null; <0,0,-1> used instead.\n"
  #local North=-z;
#end

#declare North=vnormalize(North);

#local Current_SolarPos=vrotate(z,-Al*x); // for mesh building
#local Norm_SolarPos = vnormalize(Current_SolarPos);
#declare SolarPosition=vrotate(z,<-Al, Az+degrees(atan2( North.x, North.z)),0>)*DomeSize; // where Current_SolarPos will end when mesh is rotated

  
// ======================================================
// Quick and dirty color conversion macros
//
// No need to do xyz->LCH conversion via CIE.inc because 
// 1) for speed 
// 2) we are only interested in DeltaE (the color difference)
//    so no chromatic adaption is needed.
// The final xyz->RGB conversion is done by CIE.inc so
// all settings from there are used and should be applied
// BEFORE including CIE_Skylight.inc 
// -Ive
// ======================================================

#macro Yxy_to_XYZ (c3Yxy)    
 (<c3Yxy.y/c3Yxy.z*c3Yxy.x, c3Yxy.x, (1-c3Yxy.y-c3Yxy.z)/c3Yxy.z*c3Yxy.x>)
#end   

#local EK  = 216/24389;
#local LK  = 16/116;
#local KK  = 24389/27;
#local M13 = 1/3;
    
#macro XYZ2LCH(XYZ)
  #if (XYZ.y > EK)
    #local F = pow(XYZ.y,M13);
    #local L = 116*F-16;
  #else
    #local F = 7.787*XYZ.y+LK;
    #local L = KK*XYZ.y;
  #end 
  #local A = 500*((XYZ.x>EK ? pow(XYZ.x,M13) : 7.787*XYZ.x+LK) - F);
  #local B = 200*(F - (XYZ.z>EK ? pow(XYZ.z,M13) : 7.787*XYZ.z+LK));
  #local C = sqrt(A*A+B*B);
  #if (A>0) #local H = atan2(A,B); #else #local H=0;  #end
  <L,C,H>
#end

#macro DeltaE_CMC(col1,col2)
  #local LCH1=XYZ2LCH(col1);
  #local DeltaLCH=XYZ2LCH(col2)-LCH1;
  #local S_C=(0.0638*LCH1.y/(1+0.0131*LCH1.y)+0.638);
  #local S_C_f=sqrt(pow(LCH1.y,4)/(pow(LCH1.y,4)+1900));
  #local S_C_T=( (LCH1.z>radians(164))&(LCH1.z<radians(345)) ? 0.56+abs(0.2*cos(LCH1.z+168)) : 0.36+abs(0.4*cos(LCH1.z+35)) );
  #local S_LCH=<( (LCH1.x<16) ? 0.511 : 0.040975*LCH1.x/(1+0.01765*LCH1.x) ), S_C, S_C*(1+S_C_f*(S_C_T-1))>;
  vlength(DeltaLCH/S_LCH)
#end


// ======================================================
// Preetham's skylight color equations
// ======================================================

// Should reorganise this to reduce the number of functions, macros
// maybe put some in external include file - Philippe

// Preetham's uses :
// Perez, Seals, J.M. and Ineichen model for sky luminance distribution
#local PSJI_F=function(T, G, A, B, C, D, E){
  (1 + A*exp(B/cos(T)) ) * (1+ C*exp(D*G) + E*pow(cos(G),2) )
}
  // T: theta, angle in radians
  // G: gamma, angle in radians
  // A, B, C, D, E: distribution coefficients
  // ÀA: darkening or brightening of the horizon?
  // ÀB: luminance gradient near the horizon?
  // ÀC: realtive intensity of the circumsolar region?
  // ÀD: width of the circumsolar region?
  // ÀE: relative backscattered light?

    
#local PSJI_Y=function(Yz, T, G, Ts, A, B, C, D, E){
  Yz * PSJI_F(T, G, A, B, C, D, E) / PSJI_F(0, Ts, A, B, C, D, E)
}
  // Yz: zenith luminance (or chromacity)
  // T:  theta, angle (in radians) from vertical to observed direction
  // G:  gamma, angle (in radians) between observed direction and sun
  // Ts: theta_s, angle (in radians) from vertical to sun direction
  // A, B, C, D, E: distribution coefficients

  
// Preetham's distribution coefficients

// For Y luminance
#local Preetham_Y_ABCDE=
    <  0.1787, -0.3554, -0.0227,  0.1206, -0.0670 > * Current_Turbidity
  + < -1.4630,  0.4275,  5.3251, -2.5771,  0.3703 >;

// For x chromacity
#local Preetham_x_ABCDE=
    < -0.0193, -0.0665, -0.0004, -0.0641, -0.0033 > * Current_Turbidity
  + < -0.2592,  0.0008,  0.2125, -0.8989,  0.0452 >;

// For y chromacity
#local Preetham_y_ABCDE=
    < -0.0167, -0.0950, -0.0079, -0.0441, -0.0109 > * Current_Turbidity
  + < -0.2608,  0.0092,  0.2102, -1.6537,  0.0529 >;

// Preetham's zenith values

// Zenith luminance
#local Preetham_Yz=function(T, Ts){ // T turbidity, Ts angle vertical-sun
    (4.0453*T-4.9710)*tan((4/9-T/120)*(pi-2*Ts))
    -0.2455*T + 2.4192
}

// Zenith x chromacity
#local Preetham_xz=function(T, Ts){ // T turbidity, Ts angle vertical-sun
     Ts*Ts*Ts *( 0.00166*T*T -0.02903*T +0.11693 ) 
    +Ts*Ts    *(-0.00375*T*T +0.06377*T -0.21196 )
    +Ts       *( 0.00209*T*T -0.03202*T +0.06052 )
    +          (              0.00394*T +0.25886 )
}

// Zenith y chromacity
#declare Preetham_yz=function(T, Ts){ // T turbidity, Ts angle vertical-sun
   Ts*Ts*Ts *( 0.00275*T*T -0.04214*T +0.15346 ) 
  +Ts*Ts    *(-0.00610*T*T +0.08970*T -0.26756 )
  +Ts       *( 0.00317*T*T -0.04153*T +0.06670 )
  +          (              0.00516*T +0.26688 )
}


// Declare current values
#ifndef(Current_Yz) #local Current_Yz=Preetham_Yz(Current_Turbidity,pi/2-Current_Ts); #end
#ifndef(Current_xz) #local Current_xz=Preetham_xz(Current_Turbidity,pi/2-Current_Ts); #end
#ifndef(Current_yz) #local Current_yz=Preetham_yz(Current_Turbidity,pi/2-Current_Ts); #end


// ======================================================
// Application
// ======================================================

// Get a point color,
// function of <0,0,0> -> v3Point direction
#macro SkyXYZ(v3Point) // rename Pigment-> color
  #ifdef (Turb_amount)
    #local v3Point2=vnormalize(v3Point+Turb_amount*vturbulence(Turb_param.x, Turb_param.y, Turb_param.z, v3Point/Turb_scale));
  #else
    #local v3Point2=vnormalize(v3Point);
  #end
  #local Theta=acos(min(1,vdot(y, v3Point2)));
       
  // Correction for what happens under the horizon
  #if ( (Theta>(pi/2-Horizon_Epsilon)) & UnderHorizonCorrection )
    #local Y_Mult=pow(sin(Theta),10);  // set a light attenuation
    #local Theta=pi/2-Horizon_Epsilon; // keep horizon color
  #else
    #local Y_Mult=1; // else do nothing
  #end
  
  // last minute hack to avoid PoV warning messages - Ive nov-2003
  #local Gamma=acos(min(1,max(0.00001,vdot(Norm_SolarPos, v3Point2))));

  Yxy_to_XYZ(
    <
     // Y luminance
     Y_Mult* // Correction for what happens under the horizon
     flIntensity_Final* // Intensity correction to get vuable results
     PSJI_Y(
       Current_Yz,
       Theta,
       Gamma,
       Current_Ts,
       Preetham_Y_ABCDE.red,
       Preetham_Y_ABCDE.green,
       Preetham_Y_ABCDE.blue,
       Preetham_Y_ABCDE.filter,
       Preetham_Y_ABCDE.transmit
     ),
     // x chorminance
     PSJI_Y(
       Current_xz,
       Theta,
       Gamma,
       Current_Ts,
       Preetham_x_ABCDE.red,
       Preetham_x_ABCDE.green,
       Preetham_x_ABCDE.blue,
       Preetham_x_ABCDE.filter,
       Preetham_x_ABCDE.transmit
     ),
     // y chrominance
     PSJI_Y(
       Current_yz,
       Theta,
       Gamma,
       Current_Ts,
       Preetham_y_ABCDE.red,
       Preetham_y_ABCDE.green,
       Preetham_y_ABCDE.blue,
       Preetham_y_ABCDE.filter,
       Preetham_y_ABCDE.transmit
     ),
    >  
  )
#end 


// ======================================================
// Compute some needed or useful values
// ======================================================

#local flIntensity_Final=1;
#local SunColorXYZ  = SkyXYZ(Current_SolarPos);
#declare ZenithColor  = SkyXYZ(y);
#declare HorizonColor = SkyXYZ(vrotate(-z,-Al*x)); // horizon opposing the sun

#local flIntensity_Final = Intensity_Mult /(
    Int_Sun_weight*SunColorXYZ.y + Int_Zenith_weight*ZenithColor.y + Int_Horizon_weight*HorizonColor.y
  )*( Int_Sun_weight + Int_Zenith_weight + Int_Horizon_weight )
;

// a simple way to integate with LightsysIV
#ifndef(Lightsys_Filter)
  #declare Lightsys_Filter=<1,1,1>;
#else  
  #declare Lightsys_Filter=Lightsys_Filter*<1,1,1>;
#end 
#ifndef(Lightsys_Brightness)
  #declare Lightsys_Brightness=1;
#end  

#declare Lightsys_FB = Lightsys_Filter*Lightsys_Brightness;

// NOTE: 
// I do NOT use filter and brightness from
// Lightsys here because SunColor is most useful
// for the Light_Color() macro and doing already
// here the color correction would result in 
// using Lightsys_Filter and Lightsys_Brightnes
// twice. -Ive
#declare SunColor = xyz2RGB(SkyXYZ(Current_SolarPos));

// ======================================================
// The building of the tesselated icosahedron dome
// ======================================================

#local IcoVtx=array[Max_Vertices][2];  // IcoVtx[n][0]=vertex ; IcoVtx[n][1]=color
#local IcoMesh=array[Max_Faces][3]; // three vertices per triangle
#local IcoMeshFlag=array[Max_Faces];// use this triangle or was is tesselated ?
#local IcoNumFaces=0;          // number of face to use

#local IcoVtxIndex=0;          // current vertices index
#local IcoMeshIndex=0;         // current faces index

//#local IcoEdges=array[Max_Vertices*6][2]; // 


#macro AddPointAndColToMesh(vtx,col)
  #declare IcoVtx[IcoVtxIndex][0]=vtx;
  #declare IcoVtx[IcoVtxIndex][1]=col;
  #declare IcoVtxIndex=IcoVtxIndex+1;
#end

#macro AddPointToMesh(vtx)
  AddPointAndColToMesh(vtx,SkyXYZ(vtx))
#end

#macro AddTriangleToMesh(idx1,idx2, idx3)
  #declare IcoMesh[IcoMeshIndex][0]=idx1;
  #declare IcoMesh[IcoMeshIndex][1]=idx2;
  #declare IcoMesh[IcoMeshIndex][2]=idx3;
  #declare IcoMeshFlag[IcoMeshIndex]=true;
  #declare IcoNumFaces=IcoNumFaces+1;
  #declare IcoMeshIndex=IcoMeshIndex+1;
#end

// the base icosahedron
#local phi=(sqrt(5)+1)/2;
#local BringToHorizonAngle=degrees(atan(phi));
AddPointToMesh(vrotate(vnormalize(<    0,    phi,  1>),<BringToHorizonAngle-Al,0,0>)) //  0
AddPointToMesh(vrotate(vnormalize(<    0,    phi, -1>),<BringToHorizonAngle-Al,0,0>)) //  1
AddPointToMesh(vrotate(vnormalize(<    0,   -phi,  1>),<BringToHorizonAngle-Al,0,0>)) //  2
AddPointToMesh(vrotate(vnormalize(<    0,   -phi, -1>),<BringToHorizonAngle-Al,0,0>)) //  3
AddPointToMesh(vrotate(vnormalize(<  phi,    1,    0>),<BringToHorizonAngle-Al,0,0>)) //  4
AddPointToMesh(vrotate(vnormalize(<  phi,   -1,    0>),<BringToHorizonAngle-Al,0,0>)) //  5
AddPointToMesh(vrotate(vnormalize(< -phi,    1,    0>),<BringToHorizonAngle-Al,0,0>)) //  6
AddPointToMesh(vrotate(vnormalize(< -phi,   -1,    0>),<BringToHorizonAngle-Al,0,0>)) //  7
AddPointToMesh(vrotate(vnormalize(<    1,    0,  phi>),<BringToHorizonAngle-Al,0,0>)) //  8
AddPointToMesh(vrotate(vnormalize(<   -1,    0,  phi>),<BringToHorizonAngle-Al,0,0>)) //  9
AddPointToMesh(vrotate(vnormalize(<    1,    0, -phi>),<BringToHorizonAngle-Al,0,0>)) // 10
AddPointToMesh(vrotate(vnormalize(<   -1,    0, -phi>),<BringToHorizonAngle-Al,0,0>)) // 11

AddTriangleToMesh( 0, 8, 9)
AddTriangleToMesh( 9, 8, 2)
AddTriangleToMesh( 0, 8, 4)
AddTriangleToMesh( 0, 9, 6)
AddTriangleToMesh( 8, 2, 5)
AddTriangleToMesh( 8, 4, 5)
AddTriangleToMesh( 9, 2, 7)
AddTriangleToMesh( 9, 6, 7)
AddTriangleToMesh( 0, 1, 4)
AddTriangleToMesh( 0, 1, 6)
AddTriangleToMesh( 2, 3, 5)
AddTriangleToMesh( 2, 3, 7)
AddTriangleToMesh( 1,10,11)
AddTriangleToMesh(10,11, 3)
AddTriangleToMesh( 1, 4,10)
AddTriangleToMesh( 4,10, 5)
AddTriangleToMesh( 5,10, 3)
AddTriangleToMesh( 1, 11,6)
AddTriangleToMesh(11, 6, 7)
AddTriangleToMesh( 7,11, 3)


// Tesselation loop
// This produce many duplicated vertices (probably 1/2)
#local ite0=0;
#while ( (ite0<IcoMeshIndex) & (IcoMeshIndex<(Max_Faces-3)) & (IcoVtxIndex<(Max_Vertices-3)) )
  // Prepare tesselation test :
  // If linear interpolation (as performed by the mesh)
  // isn't correct enough (Tesselation_Trigger), tesselate ;
  // else validate current triangle (=do nothing)
  
  // Data for existing vertices
  #local idx1=IcoMesh[ite0][0];
  #local idx2=IcoMesh[ite0][1];
  #local idx3=IcoMesh[ite0][2];
  
  #local vtx1=IcoVtx[idx1][0];
  #local vtx2=IcoVtx[idx2][0];
  #local vtx3=IcoVtx[idx3][0];
  
  #local col1=IcoVtx[idx1][1];
  #local col2=IcoVtx[idx2][1];
  #local col3=IcoVtx[idx3][1];
  
  // Potential vertices for tesselation
  #local vtx12=vnormalize((vtx1+vtx2)/2);
  #local vtx23=vnormalize((vtx2+vtx3)/2);
  #local vtx31=vnormalize((vtx3+vtx1)/2);
  
  // What colors the model gives them
  #local col12=SkyXYZ(vtx12);
  #local col23=SkyXYZ(vtx23);
  #local col31=SkyXYZ(vtx31);
  
  // What colors the interpolation gives them
  #local colM12=(col1+col2)/2;
  #local colM23=(col2+col3)/2;
  #local colM31=(col3+col1)/2;
  
  // Compute color differences using CMC equation
  #local colM12=DeltaE_CMC(col12, colM12);// *sqrt(vlength(vtx2-vtx1)/VtxLength);
  #local colM23=DeltaE_CMC(col23, colM23);// *sqrt(vlength(vtx3-vtx2)/VtxLength);
  #local colM31=DeltaE_CMC(col31, colM31);// *sqrt(vlength(vtx1-vtx3)/VtxLength);
  
  
  // Test if >= Tesselation_Trigger
  // if that is the case, tesselate
  // Tesselates also if not enough vertices
  #local colM12=( colM12>=Tesselation_Trigger ) ;
  #local colM23=( colM23>=Tesselation_Trigger ) ;
  #local colM31=( colM31>=Tesselation_Trigger ) ;
  #if (colM12 | colM23 | colM31 | (IcoVtxIndex<Min_Vertices) )
    // Tesselate
    // Invalidate the tesselated triangle
    #declare IcoMeshFlag[ite0]=false;
    #declare IcoNumFaces=IcoNumFaces-1;
    // Add 4 new triangles
    #local idx12=IcoVtxIndex;
    AddPointAndColToMesh(vtx12,col12)
    #local idx23=IcoVtxIndex;
    AddPointAndColToMesh(vtx23,col23)
    #local idx31=IcoVtxIndex;
    AddPointAndColToMesh(vtx31,col31)
    AddTriangleToMesh(idx1, idx12, idx31)
    AddTriangleToMesh(idx2, idx23, idx12)
    AddTriangleToMesh(idx3, idx31, idx23)
    AddTriangleToMesh(idx12, idx23, idx31)
    
    #if (IcoMeshIndex>=(Max_Faces-3))
      #debug "Warning: Tesselation ended while tesselation wasn't complete : maximum number of faces is met.\n"
    #end
    #if (IcoVtxIndex>=(Max_Vertices-3))
      #debug "Warning: Tesselation ended while tesselation wasn't complete : maximum number of vertices is met.\n"
    #end
      
  /*
  #else // This is useless : triangle is validated by AddTriangleToMesh()
        // to guarantee that triangles that aren't tested because we've run
        // out of vertices are traced.
    #declare IcoMeshFlag[ite0]=true;
  */
  #end // end tesselation test 
  #local ite0=ite0+1;
#end // #while (ite0<IcoVtxIndex)




// Build mesh
//#declare IcoDome=
mesh2{
  // Vertices
  vertex_vectors {
    IcoVtxIndex
    #local ite0=0;
    #while (ite0<IcoVtxIndex)
      , IcoVtx[ite0][0]
      #local ite0=ite0+1;
    #end // #while (ite0<IcoVtxIndex)
  }
 
  // Vertices' colors
  texture_list {
    IcoVtxIndex
    #local ite0=0;
    #while (ite0<IcoVtxIndex)
       , texture{pigment{rgb xyz2RGB(IcoVtx[ite0][1])*Lightsys_FB} finish{fiLuminous}}
      #local ite0=ite0+1;
    #end // #while (ite0<IcoVtxIndex)
  }
  
  // Faces
  face_indices{
  IcoNumFaces
    #local ite0=0;
    #while (ite0<IcoMeshIndex)
      #if(IcoMeshFlag[ite0])
        ,<IcoMesh[ite0][0], IcoMesh[ite0][1], IcoMesh[ite0][2]>
        , IcoMesh[ite0][0], IcoMesh[ite0][1], IcoMesh[ite0][2]
      #end
      #local ite0=ite0+1;
    #end // #while (ite0<IcoVtxIndex)
  }
  no_shadow
  scale DomeSize
  rotate (Az+degrees(atan2( North.x, North.z)))*y
} // mesh2

// There are many duplicates vertices - up to 50%
//#debug concat("Sky dome has ",str(IcoVtxIndex,1,0)," vertices.\n")
// use  Faces-Edges-Vertices formula to compute number of different vertices
// or change tesselation to remove duplicated vertices
#debug concat("Sky dome _uses_ ",str(IcoVtxIndex,1,0)," vertices, ")

#debug concat("has ",str(IcoNumFaces,1,0)," faces and ")
#debug concat("_uses_ ",str(IcoMeshIndex,1,0)," faces.\n")

// usefull objects for working on the file
//sphere{vnormalize(SolarPosition)*100, 10 texture{pigment{green 1} finish{ambient 1}} }
//sphere{5*z, 1 texture{finish{reflection 1}}}

// ======================================================

// ======================================================
// Cleaning and exiting
// ======================================================

// Clean unecessary declaration : #undef
// TO DO

#undef Lightsys_FB  // - Ive

// I added the 'necessary' #undef - Philippe 08 june 2003
#undef Yxy_to_XYZ
#undef XYZ2LCH
#undef DeltaE_CMC
#undef PSJI_F
#undef PSJI_Y
#undef SkyXYZ
#undef AddPointAndColToMesh
#undef AddPointToMesh
#undef AddTriangleToMesh

  
// EOF Skylight.inc
  


