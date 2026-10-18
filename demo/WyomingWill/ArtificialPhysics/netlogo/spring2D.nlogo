; William M. Spears September 2011
; 2D Spring Law Tutorial Code
; For research and educational use only

globals [total_lmx total_lmy total_angular_mom total_ke total_pe total_energy
         center_of_mass_x center_of_mass_y k FR DeltaT D S maxS minS]

turtles-own [hood deltax deltay r F Fx Fy v vx vy dvx dvy mass ke
             lmx lmy theta lever_arm_x lever_arm_y lever_arm_r angular_mom]

to setup
   clear-all                                   ; Clear everything
   crt 2                                       ; Create two turtles (particles)
   update-info
   set maxS 0 set minS 100000                  ; Initialize some variables
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

   if (S > maxS) [set maxS S]
   if (S < minS) [set minS S]

   set total_lmx sum [lmx] of turtles          ; Total linear momentum, x-component
   set total_lmy sum [lmy] of turtles          ; Total linear momentum, y-component
   set total_angular_mom sum [angular_mom] of turtles
   set total_ke sum [ke] of turtles            ; Total kinetic energy of both particles
   set total_pe (k * (S - D) * (S - D) / 2)    ; Compute potential energy
   set total_energy (total_ke + total_pe)      ; Total energy of the two-particle system
   tick
   do-plots
end

to setup-turtles
   set color white set vy 0                    ; Start with no y motion on either particle
   home                                        ; Set particles at (0,0) which is the center of the screen
   set shape "circle" set size 5               ; Draw the particle as a large circle
   set heading random 360 fd (1 + random D)    ; Each particle receives a random heading and moves forward

   ifelse (who = 0)                            ; To allow for unequal masses of the two-particle system
      [set mass 1 set vx Angular_Motion]       ; Particle 0 has mass = 1
      [set mass Mass_Ratio                     ; Particle 1 has mass = Mass_Ratio > 1
       set vx (- Angular_Motion) / Mass_Ratio]
   set theta 0
end

to ap                                          ; Run artificial physics
   set vx (1 - FR) * vx                        ; Slow down according to friction
   set vy (1 - FR) * vy

   set hood [who] of other turtles             ; Get the IDs of your neighbors
   foreach hood [ [?1] ->
      set deltax (([xcor] of turtle ?1) - xcor)
      set deltay (([ycor] of turtle ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)
      set S r
      set F (k * (r - D))                      ; The spring law
      set Fx (F * (deltax / r))                ; The x-component of force
      set Fy (F * (deltay / r))                ; The y-component of force
   ]

   set dvx DeltaT * (Fx / mass)
   set dvy DeltaT * (Fy / mass)
   set vx  (vx + dvx)                          ; The x-component of velocity
   set vy  (vy + dvy)                          ; The y-component of velocity
   set deltax DeltaT * vx
   set deltay DeltaT * vy
end

to move                                        ; Move the turtle
   set xcor (xcor + deltax)
   set ycor (ycor + deltay)

   set lmx (mass * vx)                         ; Linear momentum of the turtle
   set lmy (mass * vy)

   set v sqrt (vx * vx + vy * vy)
   set ke (v * v * mass / 2)                   ; Kinetic energy of the turtle
   set lever_arm_x (xcor - center_of_mass_x)
   set lever_arm_y (ycor - center_of_mass_y)
   set lever_arm_r sqrt (lever_arm_x * lever_arm_x + lever_arm_y * lever_arm_y)
   if (((vx != 0) or (vy != 0)) and ((lever_arm_x != 0) or (lever_arm_y != 0)))
      [set theta (atan (mass * vy) (mass * vx)) - (atan lever_arm_y lever_arm_x)]
   set angular_mom (lever_arm_r * mass * v * (sin theta)) ; Angular momentum of the turtle
end

to update-info                                 ; Update information from the sliders
   set k Spring_Constant
   set FR Friction
   set DeltaT Time_Step
   set D Desired_Spring_Length
end

to do-plots
   set-current-plot "Energy"                   ; Select the Energy plot
   set-current-plot-pen "Total"                ; Select the Total Energy Pen
   plot total_energy                           ; Plot the total_energy
   set-current-plot-pen "Potential"
   plot total_pe
   set-current-plot-pen "Kinetic"
   plot total_ke

   set-current-plot "Separation"               ; Select the Separation plot
   set-plot-y-range precision (minS - 1) 0     ; Set the range of the y-axis
                    precision (maxS + 1) 0
   set-current-plot-pen "Sep"                  ; Select the Sep pen
   plot S                                      ; Plot the separation
end
@#$#@#$#@
GRAPHICS-WINDOW
296
10
705
420
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
-200
200
-200
200
1
1
1
ticks
30.0

BUTTON
25
15
128
48
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
138
14
262
47
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
287
135
Mass_Ratio
Mass_Ratio
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
11
149
286
182
Spring_Constant
Spring_Constant
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
12
194
287
227
Friction
Friction
0
0.01
0.0
0.001
1
NIL
HORIZONTAL

SLIDER
12
240
287
273
Time_Step
Time_Step
0.001
0.01
0.001
0.001
1
NIL
HORIZONTAL

SLIDER
12
281
287
314
Desired_Spring_Length
Desired_Spring_Length
2
100
50.0
1
1
NIL
HORIZONTAL

PLOT
17
451
380
633
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
386
450
707
634
Separation
Time
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"sep" 1.0 0 -2674135 true "" ""

MONITOR
15
328
159
373
Linear Momentum X
total_lmx
10
1
11

MONITOR
161
328
290
373
Particle Separation
S
2
1
11

SLIDER
9
58
288
91
Angular_Motion
Angular_Motion
0
200
200.0
1
1
NIL
HORIZONTAL

MONITOR
15
374
159
419
Linear Momentum Y
total_lmy
10
1
11

MONITOR
161
374
290
419
Angular Momentum
total_angular_mom
2
1
11

@#$#@#$#@
## WHAT IS IT?

This is a model of a two-dimensional spring, for the book entitled "Physicomimetics: Physics-Based Swarm Intelligence."

## HOW IT WORKS

Two particles use F = ma and Hooke's law to move as a spring. But now the spring is given angular momentum, allowing it to spin around the center of mass.

## HOW TO USE IT

Click SETUP AGENTS to initialize the two particles, and click MOVE AGENTS to have them move. 

The MASS_RATIO slider allows you to control the relative masses of the particles at the ends of the spring, at initialization.  Changing this slider while the simulation is running will have no effect. 

The ANGULAR_MOTION slider allows you to impart a spin to the system at initialization. The spin is established very carefully to make sure that there is no linear momentum at initialization. Changing this slider while the simulation is running will have no effect.

All other sliders will affect the simulation when it is running.

## THINGS TO NOTICE

This simulation serves to teach you a simple model of a spring, as well as introduce you to more advanced concepts, such as the Conservation of Linear Momentum, Conservation of Angular Momentum, and the Conservation of Energy. This is covered in detail in Chapter 2 of the book. 

Note how raising the TIME_STEP introduces very mild variations into the Conservation of Energy graph.  The total energy is shown in brown, the kinetic energy is in green, and the potential energy is in blue. The total energy stays relatively constant while there is a constant tradeoff between potential and kinetic energy. Watch the simulation - when is kinetic energy high? When is potential energy high?

What happens when FRICTION is raised from 0.000 to 0.001? Where has the energy gone?

The red dot in the simulation shows the center of mass of the system. If the Conservation of Linear Momentum holds, the red dot will not move. In this simulation, if one of the particles crosses the boundary of the world (re-entering from the other side), the center of mass will change because the standard physics assumption of an Euclidean geometry has been broken (as explained in Chapter 2).

This simulation also includes a monitor for the Angular Momentum and you will see that it does not change over time, unless one of the particles crosses the boundary of the world (re-entering from the other side). Again, this is because the standard physics assumption of an Euclidean geometry has been broken (as explained in Chapter 2).

## THINGS TO TRY

See how the SPRING_CONSTANT changes behavior. 

What happens when you damp the spring with FRICTION? 

What happens if you make one of the particles heavier by using the MASS_RATIO slider (this must be done before you click SETUP AGENTS)?  

Try different values of ANGULAR_MOMENTUM (even zero).

## EXTENDING THE MODEL

Currently, the MASS_RATIO slider is only used during the initialization of the two particles. Hence, changing this slider while the simulation is running will have no effect. Modify the code to monitor this slider always (hint: you can do this in the "update-info" procedure), so that the mass of particle 1 can be changed dynamically.

Introduce a third particle and create a more complex structure that contains three springs. Use different spring constants for the three springs. One way to do this is to initially create three particles (by saying "crt 3"): 0, 1, and 2. Then you will need to modify "setup-turtles" so that it initializes all three particles in an appropriate manner. Finally, the "ap" procedure needs to be modified so that it knows which pair of particles are interacting (0 and 1, 0 and 2, or 1 and 2). You will want to have a different value of "k" for each pair. Impart a spin to the system. What happens? 

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "spring2D.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

Since we are using a patch size of one, we wanted the particles to be more visible. This is done with "set size 5" in the code. However, they are still considered to be point particles (with no size) in the simulation.

Note also how the "do-plots" procedure draws the Energy graph and the Separation graph.

NetLogo provides built-in commands to model springs, but for the purposes of this book it is better to see how a spring works from first principles. In fact, one of the core concepts of this book is that the better we understand first principles, the more elegant our solutions will be.

## RELATED MODELS

This is our second simulation, which builds on the one-dimensional spring model. It will be generalized more and more throughout the book.

## CREDITS AND REFERENCES

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
