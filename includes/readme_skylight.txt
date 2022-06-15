bpp_CIE_Skylight.inc 0.6b-CIE, by Philippe Debar phdebar@yahoo.fr 
Modified for the use with LightsysIV and CIE.inc by Ive, April-2003.
Corrected some warnings by Ive, Nov-2003.
Modified for use with Bullet Physics Playground  by koppi, June-2016.

The following is the original readme from Philippe, as the modifications are
internal and do not affect the use of the include file.

==

bpp_Skylight.inc is an include file for POV-Ray 3.5 for creating realistic skies.
It implements in povray SDL the sky model Preetham describes in "A practical
analytical model for daylight"
(http://www.cs.utah.edu/vissim/papers/sunsky/index.html).

Features (in no particular order):
* Main sky parameters: solar altitude and sky turbidity;
* Some additional parameters: north, solar azimuth, turbulence;
* "Smart" (er...) global luminosity control;
* Turbulence;
* Compatible with and improves sunpos.inc (adds north);
* Compatible with Jaime Vives Piqueres' excellent lighting macros;
* Quick hack to correct Preetham's model under the horizon;
* Quick to trace: uses a mesh;
* Most, if not all, features are easy to override;
* Overall_Filter macro to change the outputted colours the way you want;
* Outputs sun colour to light your scenes coherently with your skies;
* Easy to use: you can just include the file and get a default sky or set
any combination of parameters you want;
* I tried to keep the code legible and well commented.

Tessellation features:
* Minimum and maximum tessellation controls;
* Adaptive tessellation using CMC(1:1) colour difference formula;
* Information if tessellation isn't complete.

Bonus:
* Macros to convert from RGB to CIE XYZ and Yxy colour spaces and back;
* CMC(1:1) colour difference macro.


In next releases, probably:
* Better identifiers names, cleaner implementation;
* Tools to easily adapt the models default values to your needs (change
colours, saturate, change sun corona, change horizon sky behaviour, ...);
* Documentation and example scenes, including reasonable parameters range;
* Save the sky dome mesh to an include file (should save parsing time);
* Better (and maybe quicker) tessellation;
* Ability to remove bottom slice of the dome to save needless work and data;
* Overcast parameter;
* Better integration with Jaime Vives Piqueres lighting macros and smarter
luminosity control - I will try to find and use realistic luminosities for
sky and sun.

Later, maybe:
* Atmospheric media settings;
* Clouds.


Known problems/bugs:
* Black dots sometimes show in the sky. I believe this happens whenever a
ray is shot "between" two triangles. Up to now, anti-alias always got rid of
this annoyance.
* Tessellation isn't optimised: it uses more vertices and faces than it
could (hence the uses / has #debug messages) and wastes some computations.
However I am not sure it is worth optimising.
* Integration with Jaime's lightsys isn't complete : MAX_LUMEN / EXPOSURE
have no effects yet, as I do not now how to convert CIE trichromacity values
to lumens.


In the meantime, I hope you will enjoy this file and find it useful. I
really am impatient to read your comments, criticisms and suggestions. And
to see your images.


Povingly,

Philippe
phdebar@yahoo.fr


===============
DOCUMENTATION
===============

In the following text, default values are noted [like this].          
Warning: this is still a beta, do not expect any backward compatibility
with next releases.


== How to use ==

As all settings have default values, you can simply use :
#include "skylight.inc"

Else, you #declare any setting you want to override before including the
file.


== Sky dome geometry ==

DomeSize [1e5]
The radius of the generated dome (this is the distance between a vertex and
the origin <0,0,0>, face centres are nearer).

North [-z]
An horizontal vector (North.y=0) that gives the orientation of the scene.

Al[35]
Az[45]
Altitude and azimuth of the sun in degrees. These parameters can be computed
using sunpos.inc (standard POV_Ray 3.5 distribution).

UseSolarPosition [undefined]
SolarPosition [computed from Al and Az]
Al and Az are used by default to build the skydome. If you want to use
SolarPosition, you have to #declare UseSolarPosition=true; and #declare a
position vector for SolarPosition.


== Atmospheric parameters ==

Current_Turbidity [3]
The sky turbidity. Low values give a clear blue sky, higher values
a dustier, redder one. I found that good values are from 2 to 8.
Not that this does not produce clouds, mist and that there is
currently no way short of tempering with ABCDE parameters (see
inside Skylight.inc to find them) to produce an overcast sky.


== Luminosity ==

Intensity_Mult [.75]
Int_Sun_weight [2]
Int_Zenith_weight [1]
Int_Horizon_weight [1]

I tried to implement a kind of smart luminosity adjustment. Skylight
multiply the model's luminosity (Y) values to get Intensity_Mult at a target
value, which is a weighted mean of the luminosity of the sky at the sun's
position, at the zenith and on the horizon opposite to the sun. Adjust
Intensity_Mult to change the overall sky luminosity.


== Jaime Vives Piqueres' excellent lighting macros ==

Include them before Skylight.inc and the sky dome is automatically colour
adjusted and filtered. Luminosity interaction is really basic and you will
need to tweak Intensity_Mult.


== Overall light filter ==

Overall_Filter(lct) is a macro that does nothing that wraps the color
generation code before Jaime Vives Piqueres' macro are applied. You can
override it to change colors the way you like. Beware that too strong
transformations can make artefacts visible.


== Tesselation ==

Tesselation_Trigger [.95]
A float controlling the adaptive tessellation through the CMC(1:1) colour
difference formula. Use lower values if you need to eliminate visible
tessellation artefacts (I think these should not happen with the default
value), higher values to get a quicker parsing but dirtier result (although
it can be pleasant). Be aware that you may have to raise Max_Vertices to
allow tessellation to proceed up to your chosen Tesselation_Trigger.

Max_Vertices [5000]
Controls the maximum number of vertices generated (which is not the number
of vertices used, as there are many duplicates). Lower values lead to
dirtier but quicker results ; higher ones give the possibility to more
tessellation. Augment Max_Vertices if you get a "Warning: Tesselation ended
while tesselation wasn't complete : maximum number of vertices is met."
Message and want to get more details.

Min_Vertices [72]
Controls the minimum number of vertices generated. Tesselation is forced
while the number of generated vertices is under this trigger. Values of 12
or less have no effects. The default value forces one complete tessellation
of the base icosahedron.

Max_Faces [20+4/3*(Max_Vertices-12)+1]
Controls the maximum number of faces generated. You should use Max_Vertices
instead.


== Turbulence ==

Turb_amount [undefined]
Turb_param [<2.0, 0.5, 6>]; //<lambda, omega, octaves>
Turb_scale [5]
Define Turb_amount to get some turbulence in the sky. Be prepared to ramp
Max_Vertices up.


== Outputs ==

Skylight.inc outputs (#declares) the following identifiers :
SolarPosition : the sun's position vector (on the dome).
SunColor : the sun's colour (really the sky's colour at sun's position).

bpp_Skylight.inc may change some declared values (eg : SolarPosition, North)
