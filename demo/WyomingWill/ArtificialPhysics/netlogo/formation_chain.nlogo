; William M. Spears and Diana F. Spears September 2011
; Chain Formation Tutorial, with Obstacles
; For research and educational use only

breed [particles particle]                              ; Introduce the "particle" breed
breed [obstacles obstacle]                              ; Introduce the "obstacle" breed

globals [total_lmx total_lmy total_angular_mom G p FR D maxr obstacleF
         center_of_mass_x center_of_mass_y FMAX DeltaT a2 b2 heavy]

turtles-own [hood deltax deltay r F Fx Fy v vx vy dvx dvy mass theta c1 s1
             lmx lmy lever_arm_x lever_arm_y lever_arm_r angular_mom dradius]

to setup                                                ; Clear everything
   clear-all
   set maxr 0
   set heavy 100000                                     ; Used for obstacles
                                                        ; Create and initialize particles
   create-particles Number_of_Particles [setup-particles]
   update-info
                                                        ; Computes center of mass and displays location
   set center_of_mass_x (sum [xcor * mass] of particles) / (sum [mass] of particles)
   set center_of_mass_y (sum [ycor * mass] of particles) / (sum [mass] of particles)
   ask patch (round center_of_mass_x) (round center_of_mass_y)
      [ask patches in-radius 6 [set pcolor yellow]]     ; Initial center of mass is displayed in yellow
   reset-ticks
end

to run-and-monitor
   if (count turtles < 1) [user-message "Please click HALT and then SETUP AGENTS first" stop]
   update-info
   ask particles [ap-particles]
   ask obstacles [ap-obstacles]
   ask turtles   [move]

   ; Use mouse click to create obstacles. Must make sure that mouse is within black graphics pane.
   if (mouse-down? and mouse-inside?) [
      ifelse ((count obstacles) = 0)
          [create-obstacles 1 [setxy mouse-xcor mouse-ycor set vx 0 set vy 0 set shape "circle"
                               set size (2 * obstacleF) set mass heavy set color green]]
          [ask one-of obstacles [hatch 1 [setxy mouse-xcor mouse-ycor set vx 0 set vy 0]]]
      ;wait 0.2                                          ; Pause so don't get a bunch of obstacles at once
   ]

                                                        ; Computes center of mass and displays location
   set center_of_mass_x (sum [xcor * mass] of particles) / (sum [mass] of particles)
   set center_of_mass_y (sum [ycor * mass] of particles) / (sum [mass] of particles)
   ask patch (round center_of_mass_x) (round center_of_mass_y) [set pcolor red]

   set total_lmx sum [lmx] of particles                 ; Total linear momentum, x-component
   set total_lmy sum [lmy] of particles                 ; Total linear momentum, y-component
   set total_angular_mom sum [angular_mom] of particles ; Total angular momentum of objects
   tick
   do-plots
end

to setup-particles                                      ; Set up the particles
   setxy (random-normal 0 4) (random-normal 0 4)        ; Start in a cluster
   set heading random 360                               ; Everyone has a random heading
   set vx 0 set vy 0 set mass 1                         ; Start with no motion and mass = 1
   set size 8 set color white set theta 0
end

to ap-particles                                         ; Run artificial physics on the particles
   set Fx 0 set Fy 0                                    ; Initialize force components to zero
   set vx (1 - FR) * vx                                 ; Slow down according to friction
   set vy (1 - FR) * vy

   set hood [who] of other particles                    ; Get the IDs of all other particles
   foreach hood [ [?1] ->
      set deltax (([xcor] of particle ?1) - xcor)
      set deltay (([ycor] of particle ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)
      if (r > maxr) [set maxr r]

      if (r < D) [                                      ; The generalized split Newtonian law
         set F (G * mass * ([mass] of turtle ?1) / (r ^ p))
         if (F > FMAX) [set F FMAX]                     ; Bounds check on force magnitude
         if ((deltax != 0) or (deltay != 0))
            [set theta (atan deltay deltax)]            ; The bearing to the neighbor
         set c1 (sin (heading + theta))
         set s1 (cos (heading + theta))                 ; See Chapter 4 for details
         set dradius (sqrt (1.0 / ((c1 * c1 / a2) + (s1 * s1 / b2))))
         ifelse (r > dradius)                           ; Creates elliptical force law
            [set Fx (Fx + F * (deltax / r))             ; Attractive force, x-component
             set Fy (Fy + F * (deltay / r))]            ; Attractive force, y-component
            [set Fx (Fx - F * (deltax / r))             ; Repulsive force, x-component
             set Fy (Fy - F * (deltay / r))]            ; Repulsive force, y-component
      ]
   ]

   ; Now include obstacles
   set hood [who] of obstacles                          ; Get the IDs of obstacles
   foreach hood [ [?1] ->
      set deltax (([xcor] of obstacle ?1) - xcor)
      set deltay (([ycor] of obstacle ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)
      if (r <= obstacleF) [
         set F (obstacleF - r)                          ; Simple linear force law
         set Fx (Fx - (F * (deltax / r)))               ; Repulsive force, x-component
         set Fy (Fy - (F * (deltay / r)))               ; Repulsive force, y-component
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

to ap-obstacles                                         ; Run artificial physics on the obstacles
   set Fx 0 set Fy 0                                    ; Initialize force components to zero
   set vx (1 - FR) * vx                                 ; Slow down according to friction
   set vy (1 - FR) * vy

   set hood [who] of particles                          ; Get the IDs of all particles
   foreach hood [ [?1] ->
      set deltax (([xcor] of particle ?1) - xcor)
      set deltay (([ycor] of particle ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)
      if (r <= obstacleF) [
         set F (obstacleF - r)                          ; Simple linear force law
         set Fx (Fx - F * (deltax / r))                 ; Repulsive force, x-component
         set Fy (Fy - F * (deltay / r))                 ; Repulsive force, y-component
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

to move
   fd sqrt (deltax * deltax + deltay * deltay)          ; Move the turtle

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
   set a2 (Major_Axis ^ 2) / 4
   set b2 (Minor_Axis ^ 2) / 4
   set p Power
   set FMAX Force_Maximum
   set FR Friction
   set DeltaT Time_Step
   set D Desired_Separation
   set obstacleF Obstacle_Force
   set G (0.3 * FMAX * (D ^ p))                         ; Compute best G from theory!
   ask obstacles [set size (2 * obstacleF)]             ; Update obstacle size if necessary
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
      ask one-of particles with [mass = 1]              ; Clone an existing particle
         [hatch 1 [set deltax 0 set deltay 0 pd
                   setxy (xcor + (random-normal 0 0.1))
                         (ycor + (random-normal 0 0.1))]]
   ]
end
@#$#@#$#@
GRAPHICS-WINDOW
298
58
927
688
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
-310
310
-310
310
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
11
211
288
244
Force_Maximum
Force_Maximum
0.01
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
9
95
288
128
Major_Axis
Major_Axis
10
1000
1000.0
10
1
NIL
HORIZONTAL

SLIDER
11
252
289
285
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
11
291
289
324
Time_Step
Time_Step
0.01
0.25
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
11
332
286
365
Desired_Separation
Desired_Separation
5
15
15.0
1
1
NIL
HORIZONTAL

PLOT
5
419
293
601
Linear and Angular Momenta
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
"Lmx" 1.0 0 -2674135 true "" ""
"Lmy" 1.0 0 -10899396 true "" ""
"Angular" 1.0 0 -13345367 true "" ""

SLIDER
9
58
288
91
Number_of_Particles
Number_of_Particles
2
40
40.0
1
1
NIL
HORIZONTAL

BUTTON
166
605
281
649
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
10
606
124
650
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
10
656
125
701
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
clear-drawing clear-all-plots
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
9
173
288
206
Power
Power
1
3
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
9
134
288
167
Minor_Axis
Minor_Axis
1
5
1.0
0.5
1
NIL
HORIZONTAL

MONITOR
167
657
282
702
Max Distance
maxr
17
1
11

SLIDER
12
372
287
405
Obstacle_Force
Obstacle_Force
0
100
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
364
10
859
43
After clicking \"Move Agents\", move the mouse into the black graphics\n                   pane and left-click to introduce obstacles.
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is an extension of "formation_newton.nlogo," for the book entitled "Physicomimetics: Physics-Based Swarm Intelligence."

## HOW IT WORKS

Multiple particles use F = ma and an elliptical "split Newtonian" force law to self-organize into chain formations. 

## WHAT IS NEW

This is the second simulation for Chapter 4 of the book, which pushes the envelope of physicomimetics.  This simulation creates chain formations using a simple and elegant change to the standard physicomimetics model.

In the previous simulations we assume that the force laws are "circularly symmetric," which means that the force is the same regardless of direction. If we want chain formations, it is possible to create them using force laws that are elliptical rather than circular. In this implementation the major axis of the ellipse is aligned with the heading of the particle (robot).

Once again, we deliberately break Newton's third law. This occurs because the force law is no longer circularly symmetric and particles do not necessarily experience equal and opposite forces.  Hence linear and angular momenta will not be conserved. Given that, what should we expect from our simulation? First, if angular momentum is violated, this should create chains that are curved. But that isn't an issue, because we don't want our chains to be straight lines - we want them to be able to bend according to the environment. A violation of linear momentum is more important, because the center of mass will move. However, this is not catastrophic. It suffices to have some nodes in the chain remain close to the initial cluster. In terms of practical use, we are assuming (as we have throughout this book) that robots are initially deployed from a central location. Since the applications of interest include surveillance of sewers, tunnels and caves, it is imperative that some robots remain near their original location, so that the eventual communication chain can be easily monitored.

You can place obstacles in the environment with your mouse, to create an obstacle course. The OBSTACLE_FORCE slider controls the size of the obstacles (i.e., the extent at which the repulsive obstacle force is felt).

A MAX DISTANCE monitor shows the distance between the two particles that are farthest from each other.  This gives an indication of how straight (or curved) the chain formation is.

## HOW TO USE IT

Click SETUP AGENTS to initialize the particles, and click MOVE AGENTS to have them move.

The CLEAR button will erase the particle paths, which becomes handy when particles have their pens down (more on this below).

The NUMBER_OF_PARTICLES slider allows you to control the number of particles created at initialization. Changing this slider while the simulation is running will have no effect. You can change the number of particles while the simulation is running by using the ONE IS BORN and KILL ONE buttons. However, the ONE IS BORN and KILL ONE buttons do not change the number of initial particles when the simulation is restarted by clicking SETUP AGENTS.

The ONE IS BORN button creates a new particle.

The KILL ONE button randomly kills an existing particle.

Obstacles can be placed in the environment by placing the mouse where you want the obstacle to be, and then clicking the mouse. The obstacle is shown as a green disk. The OBSTACLE_FORCE slider changes the size of the obstacle. This affects all obstacles and the change is shown visually as the sizes of the disks change.

All other sliders will affect the simulation when it is running.

## THINGS TO NOTICE

Particles are initialized in a random cluster in the middle of the graphics pane, and self-organize into a chain formation. First, the particles collapse into a small linear structure. The orientation of that structure depends on the initial positions of the particles. Then the small structure slowly expands into a chain. The behavior is quite emergent.

The POWER controls the value of "p" in the generalized law. The DESIRED_SEPARATION is the desired distance between neighboring particles. The gravitational constant is computed automatically, using the theory established in Chapter 3.

Again, FRICTION is enabled. This allows the system to stabilize.

Note that when creating chain formations, angular and linear momenta are not conserved. The reason for this is explained in Chapter 4 of the book.

The large yellow circle in the simulation shows the initial center of mass of the system. A small red dot shows the current center of mass. Because linear momentum is not conserved the red dot will usually move away from the large yellow circle.  However, it suffices to have some particles remain close to the large yellow circle, since that is where they are initially dispersed.

This model allows you to add and remove particles. Removing particles allows you to test how robust the system is to particle failure. Adding particles allows you to see how scalable the system is, and illustrates just how nicely new particles are incorporated into the formation. 

## THINGS TO TRY

Add particles and see what happens.  Usually they are incorporated easily into the chain.

Remove particles. What happens and why?

Add obstacles while the chain is expanding.

What happens when you increase the MINOR_AXIS at the beginning of a simulation run? This parameter adjusts the width of the elliptical force law.  You may need to try this a few times to get a feel for how the behavior changes.

What happens if you start with a large DESIRED_SEPARATION and then decrease the value?

What happens if you start with a small DESIRED_SEPARATION and then increase the value?

## EXTENDING THE MODEL

Extend the simulation so that it copes with the removal of particles and a decreasing DESIRED_SEPARATION. Chapter 12 will provide some hints.

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "formation_chain.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

This simulation allows the user to create new particles and kill existing ones.

Killing a particle is accomplished via a call to the NetLogo procedure "die."

To create a particle, the "hatch" command is used - this clones an existing particle and moves it away from the original. Also, the new particle has the "pen down," which means that you will see the path that the particle takes. If the graphics pane becomes too busy, click on the CLEAR button.

This simulation makes use of NetLogo mouse events to allow the user to place obstacles in the environment.

## RELATED MODELS

This is an extension of "formation_newton.nlogo" to create chain formations.
 

## CREDITS AND REFERENCES

To see the first papers that outlined the work presented in this simulation:

Hettiarachchi, S., Maxim, P., Spears, W. M., and Spears, D. F. (2008) Connectivity of collaborative robots in partially observable domains. In Proceedings of the International Conference on Control, Automation, and Systems.

Maxim, P., Spears, W. M., and Spears, D. F. (2009) Robotic chain formations. In Proceedings of the IFAC Workshop on Networked Robotics.

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
