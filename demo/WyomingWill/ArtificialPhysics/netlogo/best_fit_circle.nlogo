; William M. Spears May 2012
; Idea and algorithm by Rodney Heil April 2012
; Finding the "best fit" circle for a set of fixed_points!
; You introduce the fixed_points with your mouse.
; For research and educational use only

breed [particles particle]                            ; Introduce the "particle" breed
breed [fixed_points fixed_point]                      ; Introduce the "fixed_point" breed

globals [ave_dist center_of_mass_x center_of_mass_y]

turtles-own [hood deltax deltay r F Fx Fy v vx vy dvx dvy mass]

to setup
   clear-all                                          ; Clear everything
   create-particles 1 [setup-particles]               ; Setup only one particle
   reset-ticks
end

; Note, the code can be modified for an arbitrary number of moving particles,
; but for this application we only need one.
to setup-particles                                    ; Set up the particles
   setxy (random-normal 0 10)
         (random-normal 0 10)                         ; Start near the center
   set heading random 360                             ; Everyone has a random heading
   set vx 0 set vy 0 set mass 1                       ; Start with no motion and mass = 1
   set color white set shape "circle" set size 5
end

to run-and-monitor
   if ((count turtles) < 1) [user-message "Please click HALT and then SETUP AGENTS first" stop]

   if ((count fixed_points) > 0) [
      ask fixed_points [compute_distance]             ; Compute r
      set ave_dist mean [r] of fixed_points           ; Compute mean r

      ask particles [ap-particles]
      ; Display circle of average radius around particle
      ask particles [draw-circle who (round xcor) (round ycor) (round ave_dist)]

      ; Computes center of mass and displays location
      set center_of_mass_x (sum [xcor * mass] of fixed_points) / (sum [mass] of fixed_points)
      set center_of_mass_y (sum [ycor * mass] of fixed_points) / (sum [mass] of fixed_points)
      ask patch (round center_of_mass_x) (round center_of_mass_y)
         [ask patches in-radius 4 [set pcolor red]]
      ; Graph the plot
      do-plots
   ]

   ; Use mouse click to create fixed_points. Must make sure that mouse is within black graphics pane.
   if (mouse-down? and mouse-inside?) [
      ifelse ((count fixed_points) = 0)
          [create-fixed_points 1 [setxy mouse-xcor mouse-ycor set vx 0 set vy 0 set shape "circle"
                                  set size 10 set mass 1 set color green]]
          [ask one-of fixed_points [hatch 1 [setxy mouse-xcor mouse-ycor]]]
      ;wait 0.2                                        ; Pause so don't get a bunch of fixed_points at once
   ]

   tick
end

; Draw circle around particle w at (x, y) with radius d
to draw-circle [w x y d]
   ask patch x y
      [ask patches in-radius (d + 1) [if ((round distance particle w) = d) [set pcolor yellow]]]
end

to compute_distance                                   ; Compute distance of particle to the fixed_points
   set hood [who] of particles                        ; Get the IDs of all particles
   foreach hood [ [?1] ->
      set deltax (([xcor] of particle ?1) - xcor)
      set deltay (([ycor] of particle ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)  ; Compute the distance to each particle
   ]
end

to ap-particles                                       ; Run artificial physics on the particle
   set Fx 0 set Fy 0                                  ; Initialize force components to zero
   set vx (1 - Friction) * vx                         ; Slow down according to friction
   set vy (1 - Friction) * vy

   set hood [who] of fixed_points                     ; Get the IDs of the fixed_points
   foreach hood [ [?1] ->
      set deltax (([xcor] of fixed_point ?1) - xcor)
      set deltay (([ycor] of fixed_point ?1) - ycor)
      set r ([r] of fixed_point ?1)                    ; No need to recompute r
      set F (ave_dist - r) * Spring_Constant          ; Simple linear force law
      set Fx (Fx - (F * (deltax / r)))                ; Repulsive force, x-component
      set Fy (Fy - (F * (deltay / r)))                ; Repulsive force, y-component
   ]

   set dvx Time_Step * (Fx / mass)
   set dvy Time_Step * (Fy / mass)
   set vx  (vx + dvx)                                 ; The x-component of velocity
   set vy  (vy + dvy)                                 ; The y-component of velocity
   set v sqrt (vx * vx + vy * vy)

   set deltax Time_Step * vx
   set deltay Time_Step * vy
   if ((deltax != 0) or (deltay != 0))
      [set heading (atan deltax deltay)]
   fd sqrt (deltax * deltax + deltay * deltay)        ; Move the particle
end

to do-plots
   set-current-plot "Average Radius"                  ; Select the Average Radius Plot
   set-current-plot-pen "Ave Radius"                  ; Select the Ave Radius pen
   plot ave_dist                                      ; Plot the average radius
end

@#$#@#$#@
GRAPHICS-WINDOW
407
53
816
463
-1
-1
1.0
1
10
1
1
1
0
0
0
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
61
36
164
69
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
168
36
275
69
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
63
85
338
118
Spring_Constant
Spring_Constant
0
1
0.15
.01
1
NIL
HORIZONTAL

SLIDER
62
128
337
161
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
62
173
337
206
Time_Step
Time_Step
0.01
1.0
1.0
0.01
1
NIL
HORIZONTAL

PLOT
16
275
376
462
Average Radius
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
"Ave Radius" 1.0 0 -2674135 true "" ""

BUTTON
278
36
340
69
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

TEXTBOX
409
10
827
61
After clicking \"Move Agents\", move the mouse into the black \ngraphics pane and left-click to introduce the fixed points.
14
0.0
1

MONITOR
144
221
246
266
#Fixed Points
count fixed_points
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is a demonstration of using physicomimetics to find the best fit circle for a set of fixed points.

## HOW IT WORKS

Initially the center of the circle is placed near the center of the graphics pane. At each iteration this virtual center moves closer to a solution.

The fixed points we are trying to fit do not move.  Rather, the agents in this demo are line segments that run between those fixed points and our virtual center.  These line segments (called virtual radii or v.r.) change in length and direction as the virtual center moves, but they always have one end anchored on the fixed points we are trying to fit.

In the best fit circle, the differences between the virtual radii will be minimized, i.e. they will all be as close to being the same length as possible.  So we create a system in which they all strive to be the same length.  In each iteration, we compute the length of each v.r. and their average length.  Then we compute a force that tends to expand or compress each v.r. in the direction of that average length.

Changing the length of the v.r. moves the endpoint that was formerly attached to the virtual center, creating a new endpoint that either projects beyond that center or falls short of that center.  All of these new endpoints are computed, and their x- and y-coordinates are averaged to create a new virtual center that is closer to the solution than the previous virtual center was.

The next iteration begins by computing the new virtual radii, and iteration continues until the virtual center stops moving*.

*The phrase "stops moving" is necessarily vague.  The virtual center seems to asymptotically approach the solution center with the force law I have selected, so it never really stops, it just becomes slower and slower.  Maybe it's better to say that the iteration continues until the rate of change is below the desired level of precision.

## WHAT IS NEW

This simulation treats line segments as our agents, instead of particles. This simulation is *not* toroidal.

## HOW TO USE IT

Click SETUP AGENTS to initialize the virtual center. Then click MOVE AGENTS. Fixed points can be put in the environment by placing the mouse where you want the fixed point to be, and then clicking the mouse.

The CLEAR button will clear the graphics, which becomes handy when a lot of circles have been drawn.


The SPRING_CONSTANT slider controls the strength of the spring-like force law, FRICTION
controls the amount of friction, and TIME_STEP controls the time granularity of the simulation. All three of these sliders will affect the simulation when it is running.

## THINGS TO NOTICE

When you place your first fixed point into the system, what happens? Is this problem very interesting?

Now what happens when you place a second fixed point in the system? How many solutions are there to this problem?

As you keep adding fixed points, do you think there is only one unique solution?

The graph shows the average of the virtual radii. How does this graph change as you add new fixed points? 

The red dot shows the center of mass of the fixed points. Note that the virtual center of the best fit circle is *not* usually at the center of mass. Why is that?

## THINGS TO TRY

See how the FRICTION changes behavior. 

Similarly, try different values for the SPRING_CONSTANT.

Put all your fixed points in a straight line to send the virtual center to the opposite edge of the graphics pane.

## EXTENDING THE MODEL

Try a different force law.

Try making the value of the SPRING_CONSTANT a function of the number of points and their distance from each other.

Allow fixed points to have different masses. Note that you can achieve a similar effect by clicking multiple times with your mouse in one location on the graphics pane.

Extend the simulation to have multiple virtual centers all independently trying to find
solutions (or see "best_fit_circles.html").

Can you change the algorithm so that it will compute the smallest circle that encompasses all the fixed points?

Similarly, can you define an algorithm that tries to give the largest circle within the fixed points that does not include the fixed points? 

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "best_fit_circle.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

## RELATED MODELS

## CREDITS AND REFERENCES

The idea and the algorithm by Rodney Heil. NetLogo code by W. M. Spears.

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Spears, W. M. and Spears, D. F. (eds.) Physicomimetics: Physics-Based Swarm Intelligence, Springer-Verlag, (2012).  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT NOTICE

Copyright 2012 William M. Spears. All rights reserved.

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
