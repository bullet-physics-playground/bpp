; William M. Spears September 2011
; Solar System Tutorial Code
; For research and educational use only

globals [total_lmx total_lmy total_angular_mom total_ke total_pe total_energy
         FMAX VMAX center_of_mass_x center_of_mass_y rprime G DeltaT S]

turtles-own [hood deltax deltay r F Fx Fy v vx vy dvx dvy mass ke
             lmx lmy theta lever_arm_x lever_arm_y lever_arm_r angular_mom]

to setup
   clear-all                                   ; Clear everything
   crt 2                                       ; Create two turtles (particles)
   update-info

   ask turtles [setup-turtles]                 ; Set up the two particles
                                               ; Compute initial separation
   set S sqrt (((([xcor] of turtle 1) - ([xcor] of turtle 0)) *
                (([xcor] of turtle 1) - ([xcor] of turtle 0))) +
               ((([ycor] of turtle 1) - ([ycor] of turtle 0)) *
                (([ycor] of turtle 1) - ([ycor] of turtle 0))))

                                               ; Computes center of mass and displays location
   set center_of_mass_x (([mass] of turtle 0) * ([xcor] of turtle 0) +
                         ([mass] of turtle 1) * ([xcor] of turtle 1)) /
                        (([mass] of turtle 0) + ([mass] of turtle 1))
   set center_of_mass_y (([mass] of turtle 0) * ([ycor] of turtle 0) +
                         ([mass] of turtle 1) * ([ycor] of turtle 1)) /
                        (([mass] of turtle 0) + ([mass] of turtle 1))
   ask patch (round center_of_mass_x) (round center_of_mass_y)
      [ask patches in-radius 4 [set pcolor red]]
   reset-ticks
end

to run-and-monitor
   if (count turtles < 1) [user-message "Please click HALT and then SETUP AGENTS first" stop]
   update-info
   ask turtles [ap]
   ask turtles [move]
                                               ; Computes center of mass and displays location
   set center_of_mass_x (([mass] of turtle 0) * ([xcor] of turtle 0) +
                         ([mass] of turtle 1) * ([xcor] of turtle 1)) /
                        (([mass] of turtle 0) + ([mass] of turtle 1))
   set center_of_mass_y (([mass] of turtle 0) * ([ycor] of turtle 0) +
                         ([mass] of turtle 1) * ([ycor] of turtle 1)) /
                        (([mass] of turtle 0) + ([mass] of turtle 1))
   ask patch (round center_of_mass_x) (round center_of_mass_y)
      [ask patches in-radius 4 [set pcolor red]]

   set total_lmx sum [lmx] of turtles          ; Total linear momentum, x-component
   set total_lmy sum [lmy] of turtles          ; Total linear momentum, y-component
   set total_angular_mom sum [angular_mom] of turtles
   set total_ke sum [ke] of turtles            ; Total kinetic energy of both particles

   ; The following code is used to calculate the potential energy of the system
   ; The paper mentioned in the References of the Information tab provides a similar
   ; derivation of potential energy
   set rprime sqrt (G * ([mass] of turtle 0) * ([mass] of turtle 1) / FMAX)
   ifelse (S >= rprime)
      [set total_pe ((G * ([mass] of turtle 0) * ([mass] of turtle 1) * ((1 / rprime) - (1 / S))) +
                     (FMAX * rprime))]
      [set total_pe (FMAX * S)]

   set total_energy (total_ke + total_pe)      ; Total energy of two particle system
   tick
   do-plots
end

to setup-turtles
   home set shape "circle" set size 5 set vx 0 ; Start with no x motion on either particle

   ifelse (who = 0)                            ; To allow for unequal masses of the two particles
      [set color yellow set mass Mass_of_Sun set vy ((- Angular_Motion) / Mass_of_Sun)]
      [set color white set xcor 15 set mass 1 set vy Angular_Motion pd]
   set theta 0
end

to ap                                          ; Run artificial physics
   if (who = 0) [set mass Mass_of_Sun]         ; Monitor this slider always

   set hood [who] of other turtles             ; Get the IDs of your neighbors
   foreach hood [ [?1] ->
      set deltax (([xcor] of turtle ?1) - xcor)
      set deltay (([ycor] of turtle ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)
      set S r
                                               ; Newton's gravitational force law
      set F (G * mass * ([mass] of turtle ?1) / (r * r))
      if (F > FMAX) [set F FMAX]
      set Fx (F * (deltax / r))                ; The x-component of force
      set Fy (F * (deltay / r))                ; The y-component of force
   ]

   set dvx DeltaT * (Fx / mass)
   set dvy DeltaT * (Fy / mass)
   set vx  (vx + dvx)                          ; The x-component of velocity
   set vy  (vy + dvy)                          ; The y-component of velocity
   set v sqrt (vx * vx + vy * vy)
   if (v > VMAX) [set vx (VMAX * vx / v) set vy (VMAX * vy / v) set v VMAX]

   set deltax DeltaT * vx
   set deltay DeltaT * vy
   if ((deltax != 0) or (deltay != 0))
      [set heading (atan deltax deltay)]       ; Because heading = 0 means turtle faces straight up!
end

to move                                        ; Move the turtle
   fd (sqrt (deltax * deltax + deltay * deltay))

   set lmx (mass * vx)                         ; Linear momentum of the turtle
   set lmy (mass * vy)

   set ke (v * v * mass / 2)                   ; Kinetic energy of the turtle
   set lever_arm_x (xcor - center_of_mass_x)
   set lever_arm_y (ycor - center_of_mass_y)
   set lever_arm_r sqrt (lever_arm_x * lever_arm_x + lever_arm_y * lever_arm_y)
   if (((vx != 0) or (vy != 0)) and ((lever_arm_x != 0) or (lever_arm_y != 0)))
      [set theta (atan (mass * vy) (mass * vx)) - (atan lever_arm_y lever_arm_x)]
   set angular_mom (lever_arm_r * mass * v * (sin theta)) ; Angular momentum of the turtle
end

to update-info                                 ; Update information from the sliders
   set G Gravitational_Constant
   set FMAX Force_Maximum
   set VMAX Velocity_Maximum
   set DeltaT Time_Step
end

to do-plots
   set-current-plot "Energy"                   ; Select the Energy plot
   set-current-plot-pen "Total"                ; Select the Total Energy Pen
   plot total_energy                           ; Plot the total_energy
   set-current-plot-pen "Potential"
   plot total_pe                               ; Plot the potential energy
   set-current-plot-pen "Kinetic"
   plot total_ke                               ; Plot the kinetic energy

   set-current-plot "Linear and Angular Momenta"
   set-current-plot-pen "Lmx"
   plot total_lmx                              ; Plot the linear momentum, x-component
   set-current-plot-pen "Lmy"
   plot total_lmy                              ; Plot the linear momentum, y-component
   set-current-plot-pen "Angular"
   plot total_angular_mom                      ; Plot the angular momentum
end
@#$#@#$#@
GRAPHICS-WINDOW
362
16
749
404
-1
-1
1.0
1
10
1
1
1
0
1
1
1
-189
189
-189
189
1
1
1
ticks
30.0

BUTTON
29
13
122
46
Setup Agents
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
133
13
240
46
Move Agents
run-and-monitor
T
1
T
OBSERVER
NIL
M
NIL
NIL
1

SLIDER
10
102
354
135
Mass_of_Sun
Mass_of_Sun
1
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
11
149
353
182
Gravitational_Constant
Gravitational_Constant
1
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
12
194
353
227
Force_Maximum
Force_Maximum
1
1000000
1000000.0
1
1
NIL
HORIZONTAL

SLIDER
15
280
354
313
Time_Step
Time_Step
0.001
0.1
0.1
0.001
1
NIL
HORIZONTAL

SLIDER
13
235
352
268
Velocity_Maximum
Velocity_Maximum
1
1000
1000.0
1
1
NIL
HORIZONTAL

PLOT
377
493
750
670
Energy
Time
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total" 1.0 0 -6459832 true "" ""
"Potential" 1.0 0 -13345367 true "" ""
"Kinetic" 1.0 0 -10899396 true "" ""

PLOT
6
492
368
672
Linear and Angular Momenta
Time
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Lmx" 1.0 0 -2674135 true "" ""
"Lmy" 1.0 0 -10899396 true "" ""
"Angular" 1.0 0 -13345367 true "" ""

MONITOR
56
388
200
433
Linear Momentum X
total_lmx
10
1
11

MONITOR
202
388
331
433
Particle Separation
S
2
1
11

SLIDER
9
58
354
91
Angular_Motion
Angular_Motion
0
15
15.0
1
1
NIL
HORIZONTAL

MONITOR
56
434
200
479
Linear Momentum Y
total_lmy
10
1
11

MONITOR
202
434
331
479
Angular Momentum
total_angular_mom
2
1
11

BUTTON
254
13
323
46
Clear
clear-drawing
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

MONITOR
373
434
488
479
Total Energy
total_energy
2
1
11

MONITOR
504
435
612
480
Planet Velocity
[v] of turtle 1
2
1
11

MONITOR
629
435
743
480
Force on Planet
[F] of turtle 1
2
1
11

@#$#@#$#@
## WHAT IS IT?

This is a model of a simple solar system with one sun and one planet, for the book entitled "Physicomimetics: Physics-Based Swarm Intelligence."

## HOW IT WORKS

Two particles use F = ma and Newton's gravitational force law to simulate a planet orbiting a sun.  The sun has a much higher mass than the planet.

## HOW TO USE IT

Click SETUP AGENTS to initialize the sun and planet, and click MOVE AGENTS to have them move. The sun is the yellow dot and the planet is the white dot.

The ANGULAR_MOTION slider allows you to impart a spin to the system at initialization, causing the planet to orbit the sun. The amount of ANGULAR_MOTION has a very large impact on the shape of the orbit. The spin is established very carefully to make sure that there is no linear momentum at initialization. Changing this slider while the simulation is running will have no effect.

The MASS_OF_SUN slider allows you to control the mass of the sun (the planet has a mass of one). This slider is continually monitored, so moving the slider while the simulation is running will affect the simulation.

All other sliders will affect the simulation when it is running.

## THINGS TO NOTICE

This simulation serves to teach you a simple model of a solar system, as well as to continue with more advanced topics, such the Conservation of Linear and Angular Momenta and the Conservation of Energy. This is covered in detail in Chapter 2 of the book. 

There is no random component to this code, so it will run the same way each time, if you don't change the settings. 

There are additional monitors in this simulation.  One computes the current total energy of the system.  Another displays the velocity of the planet.  The third shows the magnitude of the force on the planet.

This simulation introduces two new sliders, FORCE_MAXIMUM and VELOCITY_MAXIMUM, to reflect that when working with robots, they can only achieve some maximum velocity.  When using a 1/r^2 force law, the force can potentially go to infinity, creating velocities that no real robot can obtain. But what if the robot can't go that fast? How should we deal with that? We investigate two ways: (1) limiting the velocity, and (2) limiting the force.

Note how lowering the TIME_STEP causes the total energy monitor to fluctuate less, indicating that the Conservation of Energy is holding better.  In the graph, the total energy is shown in brown, the kinetic energy is in green, and the potential energy is in blue. The total energy stays relatively constant while there is a constant tradeoff between potential and kinetic energy. This is best seen when FORCE_MAXIMUM is set to one and ANGULAR_MOTION is set to 10. Watch the simulation - when is kinetic energy high? When is potential energy high? 

The red dot in the simulation shows the center of mass of the system. If the Conservation of Linear Momentum holds in both the x- and y-dimensions the red dot will not move. The graph shows that the linear momenta stay extremely close to zero, which is what we should expect if the system is programmed properly. This simulation also includes a monitor for the Angular Momentum and you will see that it does not change over time.  If, however, the planet crosses the boundary of the world (re-entering from the other side) the conservation laws can be broken, because the standard physics assumption of an Euclidean geometry no longer holds (as explained in Chapter 2).

## THINGS TO TRY

See how the GRAVITATIONAL_CONSTANT changes behavior. 

Try different values of ANGULAR_MOMENTUM (even zero). 

Change the FORCE_MAXIMUM and VELOCITY_MAXIMUM. What happens? 

What if you change the MASS_OF_SUN?

It is somewhat hard to set the sliders so that you get orbits that stay within the graphics pane.  If you are running the simulation on your computer directly (by using "solar_system.nlogo") you can increase the pane size by clicking on "settings" and then increasing max-pxcor and max-pycor.

## EXTENDING THE MODEL

Introduce a second planet. How difficult is it to create a stable solar system?

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "solar_system.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

Since we are using a patch size of one, we wanted the particles to be more visible. This is done with "set size 5" in the code. However, they are still considered to be point particles (with no size) in the simulation.

This simulation introduces the "pen down" (pd) command to draw the orbit of the planet. You could make a similar change to the "spring2D" simulation also, if you want. The new CLEAR button allows you to erase this orbit.  

Note how the "do-plots" procedure draws the Energy graph and the Momenta graph.

Now we can see why we didn't use the built-in NetLogo commands to model springs. By modeling springs from first principles, it was trivial to change the previous two-dimensional spring model to use Newton's gravitational force law instead of Hooke's spring law. Working from first principles allows us to have more flexibility in what we are modeling.

## RELATED MODELS

This is our third simulation, which builds on the two-dimensional spring model. It will be generalized more and more throughout the book.

## CREDITS AND REFERENCES

For a similar analysis of potential energy, see:

Spears, W. M., Spears, D. F., Hamann, J., and Heil, R. (2004) Distributed, physics-based control of swarms of vehicles. Autonomous Robots, 17 (2-3).

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Spears, William M. and Spears, Diana F. (eds.) Physicomimetics: Physics-Based Swarm Intelligence, Springer-Verlag, (2011).  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT NOTICE

Copyright 2011 William M. Spears. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:  
a) this copyright notice is included, and  
b) this model will not be redistributed for profit without permission from William M. Spears. Contact William M. Spears for appropriate licenses for redistribution for profit.

http://www.swarmotics.com
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0
@#$#@#$#@
set population 200
setup
repeat 200 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
