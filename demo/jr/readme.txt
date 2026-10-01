NB.  as this is "work-in-progress", I use flat placeholder
textures and an orthographic camera.  the lights too are not
yet 'shadowless', I use the shadows as visual guide.
(and the code has only been written, not thought sbout :-))

re the pov/inc/ini combo, you'll need to adjust the path of
the 'output_file_name' in the ini.  all else should work as is.

the include file is simply a container for the CSG objects,
the materials, and a few constants.

the scene file is straightforward.  the two components turn
by increment per frame.  _but_..  although both components
turn by the same angle, the "angular velocity" of the Maltese
Cross shape is not constant, unlike the the "pin disk".

I have tried to fathom what Keith did, but man, the code is
formatted so .. unfriendly, I can't get myself to study it;
from my cursory explorations I came away with the impression
that he used (somehow) gear ratios to compute the movement.

the switch is arranged to process the first 45° degrees,
then 270° where the cross is in a fixed position, and last
another 45° to complete the turn.

when you try the first run you will see the problem; on an
"elderly" i5 all frames take less than one second render.

looking at a quick run just now, there's also a "jump"
where I've not updated the angle correctly.  sorry, hope
it won't distract from "our" problem.

