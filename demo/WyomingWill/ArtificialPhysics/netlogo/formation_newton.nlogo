; William M. Spears September 2011
; Triangular and Square Lattices Using the Split Newtonian Force Law
; For research and educational use only

breed [particles particle]                              ; Introduce the "particle" breed

globals [total_lmx total_lmy total_angular_mom G p FR D
         center_of_mass_x center_of_mass_y FMAX DeltaT
         square? square_button? Gt]

turtles-own [hood deltax deltay r F Fx Fy v vx vy dvx dvy mass view
             lmx lmy theta lever_arm_x lever_arm_y lever_arm_r angular_mom]

to setup
   clear-all                                            ; Clear everything
                                                        ; Create and initialize particles
   create-particles Number_of_Particles [setup-particles]
   set square_button? false                             ; Start with a triangular lattice
   update-info
                                                        ; Computes center of mass and displays location
   set center_of_mass_x (sum [xcor * mass] of particles) / (sum [mass] of particles)
   set center_of_mass_y (sum [ycor * mass] of particles) / (sum [mass] of particles)
   ask patch (round center_of_mass_x) (round center_of_mass_y)
      [ask patches in-radius 4 [set pcolor red]]
   reset-ticks
end

to run-and-monitor
   if (count turtles < 1) [user-message "Please click HALT and then SETUP AGENTS first" stop]
   update-info
   ask particles [ap-particles]
   ask turtles [move]
                                                        ; Computes center of mass and displays location
   set center_of_mass_x (sum [xcor * mass] of particles) / (sum [mass] of particles)
   set center_of_mass_y (sum [ycor * mass] of particles) / (sum [mass] of particles)
   ask patch (round center_of_mass_x) (round center_of_mass_y)
      [ask patches in-radius 4 [set pcolor red]]

   set total_lmx sum [lmx] of particles                 ; Total linear momentum, x-component
   set total_lmy sum [lmy] of particles                 ; Total linear momentum, y-component
   set total_angular_mom sum [angular_mom] of particles ; Total angular momentum of objects
   tick
   do-plots
end

to setup-particles                                      ; Set up the particles
   setxy (random-normal 0 20)
         (random-normal 0 20)                           ; Start in a cluster
   set heading random 360                               ; Everyone has a random heading
   set vx 0 set vy 0 set mass 1                         ; Start with no motion and mass = 1
   set shape "circle" set size 5
   ifelse ((who mod 2) = 0)
      [set color white]
      [set color yellow]                                ; Different colors for square formations
   set theta 0
end

to ap-particles                                         ; Run artificial physics
   set Fx 0 set Fy 0                                    ; Initialize force components to zero
   set vx (1 - FR) * vx                                 ; Slow down according to friction
   set vy (1 - FR) * vy

   set hood [who] of other particles                    ; Get the IDs of your neighbors
   foreach hood [ [?1] ->
      set deltax (([xcor] of particle ?1) - xcor)
      set deltay (([ycor] of particle ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)
      set view 1.5                                      ; For triangular lattice
      if (square?) [                                    ; For square lattice
      ifelse ((who mod 2) = (?1 mod 2))
         [set view 1.3 set r (r / (sqrt 2))]            ; See Chapter 3 for details
         [set view 1.7]
      ]

      if (r < view * D) [                               ; The generalized split Newtonian law
         set F (G * mass * ([mass] of turtle ?1) / (r ^ p))
         if (F > FMAX) [set F FMAX]                     ; Bounds check on force magnitude
         ifelse (r > D)
            [set Fx (Fx + F * (deltax / r))             ; Attractive force, x-component
             set Fy (Fy + F * (deltay / r))]            ; Attractive force, y-component
            [set Fx (Fx - F * (deltax / r))             ; Repulsive force, x-component
             set Fy (Fy - F * (deltay / r))]            ; Repulsive force, y-component
      ]
   ]

   set dvx DeltaT * (Fx / mass)
   set dvy DeltaT * (Fy / mass)
   set vx  (vx + dvx)                                   ; The x-component of velocity
   set vy  (vy + dvy)                                   ; The y-component of velocity
   set v sqrt (vx * vx + vy * vy)

   set deltax DeltaT * vx
   set deltay DeltaT * vy
   if ((deltax != 0) or (deltay != 0))
      [set heading (atan deltax deltay)]
end

to move                                                 ; Move the turtle
   fd (sqrt (deltax * deltax + deltay * deltay))

   set lmx (mass * vx)                                  ; Linear momentum of the turtle
   set lmy (mass * vy)

   set lever_arm_x (xcor - center_of_mass_x)
   set lever_arm_y (ycor - center_of_mass_y)
   set lever_arm_r sqrt (lever_arm_x * lever_arm_x + lever_arm_y * lever_arm_y)
   if (((vx != 0) or (vy != 0)) and ((lever_arm_x != 0) or (lever_arm_y != 0)))
      [set theta (atan (mass * vy) (mass * vx)) - (atan lever_arm_y lever_arm_x)]
   set angular_mom (lever_arm_r * mass * v * (sin theta)) ; Angular momentum of the turtle
end

to update-info                                          ; Update information from the sliders
   set G Gravitational_Constant
   set p Power
   set FMAX Force_Maximum
   set FR Friction
   set DeltaT Time_Step
   set D Desired_Separation
   set square? square_button?
   ifelse square?                                       ; G phase transition computation, for
      [set Gt (FMAX * (D ^ p) / ((2 * sqrt(2)) + 2))]   ; square lattice, and for
      [set Gt (FMAX * (D ^ p) / (2 * sqrt(3)))]         ; triangular lattice (see Chapter 3 for details)
end

to do-plots
   set-current-plot "Linear and Angular Momenta"        ; Select the Momenta plot
   set-current-plot-pen "Lmx"                           ; Select the Lmx pen
   plot total_lmx                                       ; Plot the linear momentum, x-component
   set-current-plot-pen "Lmy"
   plot total_lmy                                       ; Plot the linear momentum, y-component
   set-current-plot-pen "Angular"
   plot total_angular_mom                               ; Plot the angular momentum
end

; Kill a particle
to one-dies
   if (count (particles with [mass = 1]) > 1) [         ; Don't kill last particle
      ask one-of particles with [mass = 1] [die]        ; Ask one particle to die
      clear-drawing                                     ; A little cleanup is required
   ]
end

; Create a new particle
to one-is-born
   if (count (particles with [mass = 1]) > 0) [
      ask one-of particles with [mass = 1]
         [hatch 1 [set deltax 0 set deltay 0 pd         ; Clone an existing particle
                   ifelse ((who mod 2) = 0)
                     [set color white]
                     [set color yellow]                 ; Different colors for square formations
                   setxy xcor + (random-normal 0 (D / 2))
                         ycor + (random-normal 0 (D / 2))]]
   ]
end

; Toggle between triangular and square formations
to toggle-formation
  if (square_button? != 0) [set square_button? not square_button?]
end
@#$#@#$#@
GRAPHICS-WINDOW
386
15
1087
717
-1
-1
1.73
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
8
15
111
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
115
15
222
48
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
12
176
287
209
Force_Maximum
Force_Maximum
1
5
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
10
101
285
134
Gravitational_Constant
Gravitational_Constant
10
2000
310.0
10
1
NIL
HORIZONTAL

SLIDER
13
217
288
250
Friction
Friction
0
1.0
0.15
0.01
1
NIL
HORIZONTAL

SLIDER
13
263
288
296
Time_Step
Time_Step
0.01
2.0
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
13
304
288
337
Desired_Separation
Desired_Separation
2
50
30.0
1
1
NIL
HORIZONTAL

PLOT
17
451
380
633
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
16
347
160
392
Linear Momentum X
total_lmx
15
1
11

SLIDER
9
58
288
91
Number_of_Particles
Number_of_Particles
1
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
16
393
160
438
Linear Momentum Y
total_lmy
15
1
11

MONITOR
162
393
291
438
Angular Momentum
total_angular_mom
15
1
11

BUTTON
131
690
246
734
Kill One
one-dies
NIL
1
T
OBSERVER
NIL
K
NIL
NIL
1

BUTTON
16
690
130
734
One is Born
one-is-born
NIL
1
T
OBSERVER
NIL
B
NIL
NIL
1

MONITOR
17
638
147
683
#Particles
count particles
3
1
11

BUTTON
225
15
287
48
Clear
clear-drawing clear-all-plots clear-patches
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

SLIDER
10
138
286
171
Power
Power
1
2
2.0
0.1
1
NIL
HORIZONTAL

BUTTON
246
689
381
734
Toggle Formation
toggle-formation
NIL
1
T
OBSERVER
NIL
F
NIL
NIL
1

MONITOR
162
346
290
391
G Phase Transition
Gt
2
1
11

MONITOR
256
638
380
683
Square Formation?
square_button?
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is our second physics-based model of a swarm, for the book entitled "Physicomimetics: Physics-Based Swarm Intelligence."

## HOW IT WORKS

Multiple particles use F = ma and a "split Newtonian" force law to self-organize into a triangular lattice or a square lattice. 

## WHAT IS NEW

As opposed to Hooke's law, this simulation uses a "Newtonian" force law that has been modified to include a repulsive component in addition to the normal gravitational attraction.  It has also been generalized by allowing the force law to be 1/r^p as opposed to just 1/r^2. 

In addition, the simulation model is extended to include square lattices by having two types of particles, as explained in Chapter 3 of the book.

Finally, notice that clustering of particles occurs in the simulation, whereas it did not when Hooke's law was used.  Try lowering the GRAVITATIONAL_CONSTANT. You will notice that the clusters will exhibit a "phase transition" and fall apart suddenly. The book provides an elegant explanation for why this occurs, and shows that clustering depends on the values of the force parameters.  The G PHASE TRANSITION monitor gives the approximate value of the gravitational constant where the phase transition occurs.  Above this value, clustering occurs.  Below this value, the clusters fall apart. 

## HOW TO USE IT

Click SETUP AGENTS to initialize the particles, and click MOVE AGENTS to have them move.

The CLEAR button will clear the graphics, which becomes handy when particles have their pens down (more on this below).

The NUMBER_OF_PARTICLES slider allows you to control the number of particles created at initialization. Changing this slider while the simulation is running will have no effect. You can change the number of particles while the simulation is running by using the ONE IS BORN and KILL ONE buttons. However, the ONE IS BORN and KILL ONE buttons do not change the number of initial particles when the simulation is restarted by clicking SETUP AGENTS.

The ONE IS BORN button creates a new particle.

The KILL ONE button randomly kills an existing particle.

There is also a TOGGLE FORMATION button that allows you to choose between square and triangular lattices. A monitor indicates whether the square or triangular lattice has been selected.

All other sliders will affect the simulation when it is running.

## THINGS TO NOTICE

Particles are initialized in a random cluster in the middle of the graphics pane, and self-organize into a triangular lattice. The lattice is not perfect, but that is OK because we are interested in "satisficing systems," as opposed to "optimal systems."

The GRAVITATIONAL_CONSTANT controls the G parameter in the split Newtonian force law. The POWER controls the value of "p" in the generalized law. The DESIRED_SEPARATION is the desired distance between neighboring particles.

Again, FRICTION is enabled. This allows the system to stabilize.

This simulation serves to teach you about physics-based swarms, as well as the Conservation of Linear and Angular Momenta. This is covered in detail in Chapter 3 of the book.

The red dot in the simulation shows the center of mass of the system. If the Conservation of Linear Momentum holds in both the x- and y-dimensions, the red dot will not move. This simulation includes a monitor for the Angular Momentum and you will see that it does not change over time, if the system is closed.

This model allows you to add and remove particles. Removing particles allows you to test how robust the system is to particle failure. Adding particles allows you to see how scalable the system is, and illustrates just how nicely new particles are incorporated into the lattice. Adding and removing particles opens the system, and temporary changes in the momenta can occur during these events.

Although it doesn't look like the linear momentum is shown on the graph, this is because it is overdrawn by the angular momentum curve. If you slow the simulation down (with the speed slider) and add a particle, you will usually see all three curves.

## THINGS TO TRY

See how the FRICTION changes behavior. Click SETUP AGENTS, lower the friction, and click MOVE AGENTS.  What happens?  

Similarly, change the GRAVITATIONAL_CONSTANT or the POWER.

Change the DESIRED_SEPARATION while the system is running. Try changing it slowly and then change it quickly. What happens?

Add and remove particles.
   
See how the G PHASE TRANSITION value is affected when you change the GRAVITATIONAL_CONSTANT, the POWER, and the FORCE_MAXIMUM.

In "formation_hooke.nlogo" we noted that unusual behavior can occur with certain parameter settings.  Try similar settings with this simulation (which uses the split Newtonian force law). Do you see the same behavior? 

## EXTENDING THE MODEL

In this model, all particles have the same mass. What happens if particles have different masses? 

What happens when you change the sensor view? 

What other formations can you create by extending the code to include more types of particles?

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "formation_newton.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

This simulation allows the user to create new particles and kill existing ones.

Killing a particle is accomplished via a call to the NetLogo procedure "die."

To create a particle, the "hatch" command is used - this clones an existing particle and moves it away from the original. Also, the new particle has the "pen down," which means that you will see the path that the particle takes. If the graphics pane becomes too busy, click on the CLEAR button.

## RELATED MODELS

This is our second physics-based swarm simulation, which modifies the force law from Hooke's law to a generalized split Newtonian force law. 

## CREDITS AND REFERENCES

To see our implementation on seven simple robots:

Spears, W. M., Spears, D. F., Hamann, J., and Heil, R. (2004) Distributed, physics-based control of swarms of vehicles. Autonomous Robots, 17 (2-3).

For an explanation of the phase transition:

Gordon-Spears, D. F., and Spears, W. M. (2003) Analysis of a phase transition in a physics-based multiagent system. Lecture Notes in Computer Science, Volume 2699.

To see the first papers that outlined the work presented in this simulation:

Gordon, D. F., Spears, W. M., Sokolsky, O., and Lee, I. (1999) Distributed spatial control, global monitoring and steering of mobile physical agents. In Proceedings of IEEE International Conference on Information, Intelligence, and Systems.

Spears, W. M., and Gordon, D. F. (1999) Using Artificial Physics to control agents. In Proceedings of IEEE International Conference on Information, Intelligence, and Systems.

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Spears, W. M. and Spears, D. F. (eds.) Physicomimetics: Physics-Based Swarm Intelligence, Springer-Verlag, (2011).  
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
