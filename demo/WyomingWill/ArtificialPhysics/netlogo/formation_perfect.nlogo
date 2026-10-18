; William M. Spears September 2011
; Perfect Triangular and Square Lattices Using the Split Newtonian Force Law
; For research and educational use only

breed [particles particle]                                ; Introduce the "particle" breed

globals [total_lmx total_lmy total_angular_mom G p FR D
         center_of_mass_x center_of_mass_y FMAX DeltaT
         square? square_button?]

turtles-own [hood deltax deltay r F Fx Fy v vx vy dvx dvy mass view
             lmx lmy theta lever_arm_x lever_arm_y lever_arm_r angular_mom
             squarem squaren hexm hexn pm pn km kn cx cy]

to setup
   clear-all                                              ; Clear everything
                                                          ; Create and initialize particles
   create-particles Number_of_Particles [setup-particles]
   set square_button? true                                ; Start with a square lattice
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

   set total_lmx sum [lmx] of particles                   ; Total linear momentum, x-component
   set total_lmy sum [lmy] of particles                   ; Total linear momentum, y-component
   set total_angular_mom sum [angular_mom] of particles   ; Total angular momentum of objects
   tick
   do-plots
end

to setup-particles                                        ; Set up the particles
   setxy (random-normal 0 20) (random-normal 0 20)        ; Start in a cluster
   set heading random 360                                 ; Everyone has a random heading
   set vx 0 set vy 0 set mass 1                           ; Start with no motion and mass = 1
   set shape "circle" set size 5
   ifelse ((who mod 2) = 0)
      [set color white]
      [set color yellow]                                  ; Different colors for square formations
   set theta 0
   init-m-n
end

; Terribly ugly code to set up the (m,n) attributes. It would
; be wonderful if someone could make this more elegant - hint hint.
to init-m-n
   ; For square lattices
   let ring (1 + (floor (sqrt (who / 4))))
   let index (who - ((ring - 1) * (ring - 1) * 4))

   ifelse (index < (2 * ring - 1))  [set squarem (1 + index - ring)] [
   ifelse (index <= (4 * ring - 2)) [set squarem ring] [
   ifelse (index < (6 * ring - 3))  [set squarem (5 * ring - index - 2)] [set squarem (1 - ring)]]]

   ifelse (index < ( 2 * ring))     [set squaren (ring - 1)] [
   ifelse (index < (4 * ring - 2))  [set squaren (3 * ring - 2 - index)] [
   ifelse (index < (6 * ring - 2))  [set squaren (0 - ring)] [set squaren (index - 7 * ring + 3)]]]

   ; For triangular lattices, good up to 126 particles
   ifelse (who = 0)  [set ring 1] [
   ifelse (who < 7)  [set ring 2] [
   ifelse (who < 19) [set ring 3] [
   ifelse (who < 37) [set ring 4] [
   ifelse (who < 61) [set ring 5] [
   ifelse (who < 91) [set ring 6] [set ring 7]]]]]]

   ifelse (who = 0)
      [set index 0]
      [set index (who - ((3 * ring * ring) - (9 * ring) + 7))]

   ifelse (index < ring) [set hexm (2 * index - (ring - 1))] [
   ifelse (((3 * ring - 3) <= index) and (index <= (4 * ring - 4))) [set hexm ((8 * ring) - 8 - (2 * index) - (ring - 1))] [
   ifelse ((ring <= index) and (index < (2 * ring - 2))) [set hexm index] [
   ifelse (index = (2 * ring - 2)) [set hexm (2 * ring - 2)] [
   ifelse (((2 * ring - 2) < index) and (index < (3 * ring - 3))) [set hexm ((4 * ring) - index - 4)] [
   ifelse (((4 * ring - 4) < index) and (index < (5 * ring - 5))) [set hexm (3 * ring - index - 3)] [
   ifelse ((5 * ring - 5) < index) [set hexm (index - (7 * ring) + 7)] [
   if (index = (5 * ring - 5)) [set hexm (2 - 2 * ring)]]]]]]]]

   ifelse (index < ring) [set hexn ring - 1] [
   ifelse (((3 * ring - 3) <= index) and (index <= (4 * ring - 4))) [set hexn 1 - ring] [
   ifelse ((ring <= index) and (index < (3 * ring - 3))) [set hexn (2 * ring - index - 2)] [
   if (index > (4 * ring - 4)) [set hexn (index + 5 - 5 * ring)]]]]
end

; Attractive force, x- and y-components
to attract [wx wy]
   set Fx (Fx + wx * F * (deltax / r))
   set Fy (Fy + wy * F * (deltay / r))
end

; Repulsive force, x- and y-components
to repulse [wx wy]
   set Fx (Fx - wx * F * (deltax / r))
   set Fy (Fy - wy * F * (deltay / r))
end

to ap-particles                                           ; Run artificial physics
   set Fx 0 set Fy 0                                      ; Initialize force components to zero
   set vx (1 - FR) * vx                                   ; Slow down according to friction
   set vy (1 - FR) * vy

   set hood [who] of other particles                      ; Get the IDs of everyone else
   foreach hood [ [?1] ->
      set deltax (([xcor] of particle ?1) - xcor)
      set deltay (([ycor] of particle ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)
      set view 1.5                                        ; For triangular lattice
      if (square?) [                                      ; For square lattice
      ifelse ((who mod 2) = (?1 mod 2))
         [set view 1.3 set r (r / (sqrt 2))]              ; See Chapter 3 for details
         [set view 1.7]
      ]

      ifelse (square?)
         [set pm squarem set pn squaren set cx 0.5 set cy 0.5
          set km ([squarem] of particle ?1) set kn ([squaren] of particle ?1)]
         [set pm hexm set pn hexn set cx 0.25 set cy 0.433
           set km ([hexm] of particle ?1) set kn ([hexn] of particle ?1)]

      if (r < view * D) [                                 ; The generalized split Newtonian law
         set F (G * mass * ([mass] of turtle ?1) / (r ^ p))
         if (F > FMAX) [set F FMAX]                       ; Bounds check on force magnitude

         ifelse (r > D) [attract 1 1] [
         ifelse (((deltax < 0) and (pm < km) and (deltay < 0) and (pn < kn)) or
                 ((deltax > 0) and (pm > km) and (deltay > 0) and (pn > kn))) [attract 2 2] [
         ifelse (((deltax < 0) and (pm < km)) or ((deltax > 0) and (pm > km))) [attract 2 2] [
         ifelse (((deltay < 0) and (pn < kn)) or ((deltay > 0) and (pn > kn))) [attract 2 2] [
         ifelse (((pn = kn) and (abs(deltay) > cy * D)) or ((pm = km) and (abs(deltax) > cx * D))) [attract 2 2] [
         ifelse ((not square?) and (pn != kn) and (abs(deltay) < cy * D)) [repulse 0 3] [
         ifelse ((not square?) and (pm != km) and (abs(deltax) < cx * D)) [repulse 3 0] [repulse 1 1]]]]]]]]
   ]

   set dvx DeltaT * (Fx / mass)
   set dvy DeltaT * (Fy / mass)
   set vx  (vx + dvx)                                     ; The x-component of velocity
   set vy  (vy + dvy)                                     ; The y-component of velocity
   set v sqrt (vx * vx + vy * vy)

   set deltax DeltaT * vx
   set deltay DeltaT * vy
   if ((deltax != 0) or (deltay != 0))
      [set heading (atan deltax deltay)]
end

to move                                                   ; Move the turtle
   fd (sqrt (deltax * deltax + deltay * deltay))

   set lmx (mass * vx)                                    ; Linear momentum of the turtle
   set lmy (mass * vy)

   set lever_arm_x (xcor - center_of_mass_x)
   set lever_arm_y (ycor - center_of_mass_y)
   set lever_arm_r sqrt (lever_arm_x * lever_arm_x + lever_arm_y * lever_arm_y)
   if (((vx != 0) or (vy != 0)) and ((lever_arm_x != 0) or (lever_arm_y != 0)))
      [set theta (atan (mass * vy) (mass * vx)) - (atan lever_arm_y lever_arm_x)]
   set angular_mom (lever_arm_r * mass * v * (sin theta)) ; Angular momentum of the turtle
end

to update-info                                            ; Update information from the sliders
   set G Gravitational_Constant
   set p Power
   set FMAX Force_Maximum
   set FR Friction
   set DeltaT Time_Step
   set D Desired_Separation
   set square? square_button?
end

to do-plots
   set-current-plot "Linear and Angular Momenta"          ; Select the Momenta plot
   set-current-plot-pen "Lmx"                             ; Select the Lmx pen
   plot total_lmx                                         ; Plot the linear momentum, x-component
   set-current-plot-pen "Lmy"
   plot total_lmy                                         ; Plot the linear momentum, y-component
   set-current-plot-pen "Angular"
   plot total_angular_mom                                 ; Plot the angular momentum
end

; Create a new particle
to one-is-born
   if (count (particles with [mass = 1]) > 0) [
      ask one-of particles with [mass = 1]
         [hatch 1 [set deltax 0 set deltay 0 pd init-m-n  ; Clone an existing particle
                   ifelse ((who mod 2) = 0)
                     [set color white]
                     [set color yellow]                   ; Different colors for square formations
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
100
2000
1000.0
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
0.5
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
1.0
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
10
30
25.0
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
285
91
Number_of_Particles
Number_of_Particles
3
100
100.0
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
388
451
502
495
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
508
451
638
496
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
4
2.5
0.1
1
NIL
HORIZONTAL

BUTTON
162
347
290
391
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
388
589
568
634
Good Gravitational Constant
FMAX * (D ^ p) / (2 * sqrt 3)
2
1
11

MONITOR
387
534
567
579
Square Formation?
square_button?
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is an extension of "formation_newton.nlogo," for the book entitled "Physicomimetics: Physics-Based Swarm Intelligence."

## HOW IT WORKS

Multiple particles use F = ma and a "split Newtonian" force law to self-organize into a perfect triangular or square lattice. 

## WHAT IS NEW

This is the first simulation for Chapter 4 of the book, which pushes the envelope of physicomimetics.  This simulation creates perfect lattices, by making minor modifications to the existing framework. 

First, we assume that each particle has an attribute assigned to it at initialization. This attribute is composed of two integers: m and n.  This attribute serves to indicate where a particle should be with respect to another particle.

Second, we require that all particles share a global coordinate system (which was never assumed in the prior simulations).  This can be accomplished easily - each particle is assumed to have a digital compass that tells the particle which way is north. 

Finally, we deliberately break Newton's third law to a small degree, by modifying the force law. We do this to improve performance. The reason this is important is because we want to stress that physicomimetics "mimics" physics, as opposed to merely copying physics.  We are task-driven.  If alterations to standard physics improves performance, that is quite acceptable.

## HOW TO USE IT

Click SETUP AGENTS to initialize the particles, and click MOVE AGENTS to have them move.

The CLEAR button will clear the graphics, which becomes handy when particles have their pens down (more on this below).

The NUMBER_OF_PARTICLES slider allows you to control the number of particles created at initialization. Changing this slider while the simulation is running will have no effect. However, you can increase the number of particles while the simulation is running by using the ONE IS BORN button. However, the ONE IS BORN button does not change the number of initial particles when the simulation is restarted by clicking SETUP AGENTS.

The ONE IS BORN button creates a new particle.

There is also a TOGGLE FORMATION button that allows you to choose between square and triangular lattices. 

All other sliders will affect the simulation when it is running.

## THINGS TO NOTICE

Particles are initialized in a random cluster in the middle of the graphics pane, and self-organize into a perfect square or triangular lattice. 

The GRAVITATIONAL_CONSTANT controls the G parameter in the split Newtonian force law. The POWER controls the value of "p" in the generalized law. The DESIRED_SEPARATION is the desired distance between neighboring particles.

The GOOD GRAVITATIONAL CONSTANT monitor uses the theory established in Chapter 3 to provide guidance on a good value of G, when you change the DESIRED_SEPARATION.

Again, FRICTION is enabled. This allows the system to stabilize.

Note that when creating triangular lattices, angular momentum is not conserved. But note that linear momentum is still conserved. The reason for this is explained in Chapter 4 of the book.

The red dot in the simulation shows the center of mass of the system. If the Conservation of Linear Momentum holds in both the x- and y-dimensions, the red dot will not move. This simulation includes a monitor for the Angular Momentum.

This model allows you to add particles. Adding particles allows you to see how scalable the system is, and illustrates just how nicely new particles are incorporated into the lattice. 

## THINGS TO TRY

See how the FRICTION changes behavior. Click SETUP AGENTS, lower the friction, and click MOVE AGENTS.  What happens?  

Similarly, change the GRAVITATIONAL_CONSTANT or the POWER.

Change the DESIRED_SEPARATION while the system is running. Try changing it slowly and then change it quickly. What happens?

Add particles and watch their trajectories.
   
See how the G PHASE TRANSITION value is affected when you change the GRAVITATIONAL_CONSTANT, the POWER and the FORCE_MAXIMUM.

Toggle between triangular and square formations.  Note how robust the system is - the formations are torn apart and then self-repair.

## EXTENDING THE MODEL

Find a more elegant way to compute the (m, n) attribute. 

Consider changing the model so that the (m, n) attribute is swapped between particles, as opposed to having particles move so much.

Extend this model to create perfect honeycomb formations.

Try the Lennard-Jones force law instead.

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "formation_perfect.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

This simulation allows the user to create new particles.

To create a particle, the "hatch" command is used - this clones an existing particle and moves it away from the original. Also, the new particle has the "pen down," which means that you will see the path that the particle takes. If the graphics pane becomes too busy, click on the CLEAR button.

This code has two procedures ("attract" and "repulse") where values of arguments are passed to the procedures.

## RELATED MODELS

This is an extension of "formation_newton.nlogo" to create perfect lattices.
   
Chapter 17 (by Sanza Kazadi) provides alternative mechanisms for creating perfect lattices.  His chapter includes videos of these techniques.

## CREDITS AND REFERENCES

To see the first papers that outlined the work presented in this simulation:

Gordon, D. F., Spears, W. M., Sokolsky, O., and Lee, I. (1999) Distributed spatial control, global monitoring and steering of mobile physical agents. In Proceedings of IEEE International Conference on Information, Intelligence, and Systems.

Spears, W. M., and Gordon, D. F. (1999) Using Artificial Physics to control agents. In Proceedings of IEEE International Conference on Information, Intelligence, and Systems.

The latter paper is the first to show the perfect formations.

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
