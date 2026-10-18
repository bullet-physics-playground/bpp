; William M. Spears, September 2011
; Artificial Physics Optimization Tutorial Code
; For research and educational use only

breed [apo-robots apo-robot]                          ; Introduce the "apo-robot" breed
globals [center_of_mass_x center_of_mass_y Noise_Level
         G FR D FMAX DeltaT apoF APOMIN OPTX OPTY zoom numbots]

turtles-own [hood r F Fx Fy v vx vy dvx dvy deltax deltay]

patches-own [fitness]                                 ; Store fitness landscape for visualization

;; This code assumes APO is minimizing
to setup
   clear-all                                          ; Clear everything
   set numbots Number_of_Robots
   set Noise_Level Noise                              ; Used to detect if the Noise slider changes
   update-info

   set OPTX -125                                      ; Location of optimum
   set OPTY -125
   set apoF 0.10                                      ; See theory in Chapter 6
   set zoom 1
                                                      ; Create and initialize particles
   create-apo-robots Number_of_Robots [setup-apo-robots]
                                                      ; Computes center of mass and displays location
   set center_of_mass_x (sum [xcor] of apo-robots) / numbots
   set center_of_mass_y (sum [ycor] of apo-robots) / numbots
   ask patch (round center_of_mass_x) (round center_of_mass_y) [set pcolor magenta]
                                                      ; Distance of center of mass to optimum
   set APOMIN sqrt((center_of_mass_x - OPTX) * (center_of_mass_x - OPTX) +
                   (center_of_mass_y - OPTY) * (center_of_mass_y - OPTY))

   calculate-patches
   reset-ticks
end

to run-and-monitor
   if (count turtles < 1) [user-message "Please click HALT and then SETUP first" stop]

   update-info
   set G (0.9 * FMAX * (D ^ 2) / (2 * (sqrt 3)))      ; Gravitational constant set by theory
   ask apo-robots [update-apo-robots]
   ask turtles   [move]

   if (mouse-down? and mouse-inside?) [               ; Use mouse click to move optimum
      ask patch OPTX OPTY [ask patches in-radius 6 [set pcolor black]]
      set OPTX mouse-xcor                             ; Reset x-coordinate of optimum
      set OPTY mouse-ycor                             ; Reset y-coordinate of optimum
      calculate-patches
   ]
                                                      ; Draw the location of the optimum
   ask patch OPTX OPTY [ask patches in-radius 6 [set pcolor blue]]
                                                      ; Computes center of mass and displays location
   set center_of_mass_x (sum [xcor] of apo-robots) / numbots
   set center_of_mass_y (sum [ycor] of apo-robots) / numbots
   ask patch (round center_of_mass_x) (round center_of_mass_y) [set pcolor magenta]
                                                      ; Distance of center of mass to optimum
   set APOMIN sqrt((center_of_mass_x - OPTX) * (center_of_mass_x - OPTX) +
                   (center_of_mass_y - OPTY) * (center_of_mass_y - OPTY))
   do-plot                                            ; Update graph
   tick
end

to setup-apo-robots                                   ; Set up the robots
   setxy ((world-width / 3) + (random-normal 0 1))
         ((world-height / 3) + (random-normal 0 1))   ; Place at upper right
   set vx 0 set vy 0                                  ; Start with no motion (and no linear momentum)
   set shape "circle" set color magenta set size 6
end

to update-apo-robots                                  ; Run artificial physics
   set Fx 0 set Fy 0                                  ; Initialize force components to zero
   set vx (1 - FR) * vx                               ; Slow down according to friction
   set vy (1 - FR) * vy

   set hood [who] of other apo-robots                 ; Get the IDs of your neighbors
   foreach hood [ [?1] ->
      set deltax (([xcor] of apo-robot ?1) - xcor)
      set deltay (([ycor] of apo-robot ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)

      if (r < 1.5 * D) [                              ; The generalized split Newtonian law
         set F (G / (r ^ 2))
         if (F > FMAX) [set F FMAX]                   ; Bounds check on force magnitude
         ifelse (r > D)
            [set Fx (Fx + F * (deltax / r))           ; Attractive force, x-component
             set Fy (Fy + F * (deltay / r))]          ; Attractive force, y-component
            [set Fx (Fx - F * (deltax / r))           ; Repulsive force, x-component
             set Fy (Fy - F * (deltay / r))]          ; Repulsive force, y-component
                                                      ; The modification to AP that performs optimization!
         ifelse ((rastrigan xcor ycor Noise_Level) <  ; Move towards fitness minimum
                 (rastrigan ([xcor] of apo-robot ?1)
                            ([ycor] of apo-robot ?1) Noise_Level))
            [set Fx (Fx - (apoF * (deltax / r)))      ; Repulsive force, x-component
             set Fy (Fy - (apoF * (deltay / r)))]     ; Repulsive force, y-component
            [set Fx (Fx + (apoF * (deltax / r)))      ; Attractive force, x-component
             set Fy (Fy + (apoF * (deltay / r)))]     ; Attractive force, y-component
      ]
   ]

   set dvx DeltaT * Fx
   set dvy DeltaT * Fy
   set vx  (vx + dvx)                                 ; The x-component of velocity
   set vy  (vy + dvy)                                 ; The y-component of velocity

   set deltax DeltaT * vx
   set deltay DeltaT * vy
   if ((deltax != 0) or (deltay != 0))
      [set heading (atan deltax deltay)]
end

to move
   fd (sqrt (deltax * deltax + deltay * deltay))      ; Move the robot
end

to update-info                                        ; Update information from the sliders
   set FMAX Force_Maximum
   set FR Friction
   set DeltaT Time_Step
   set D Desired_Separation
   if (Noise != Noise_Level) [                        ; If the amount of noise changes,
      set Noise_Level Noise                           ; note this fact, and
      calculate-patches                               ; recalculate the fitness values of the patches
   ]
end

to-report rastrigan [x y n]                           ; Computes the Rastrigan function (n = noise level)
   set x (x / zoom)
   set y (y / zoom)
   let tempx ((x - OPTX / zoom) ^ 2 - (10 * cos (360 * (x - OPTX / zoom))) + 10)
   let tempy ((y - OPTY / zoom) ^ 2 - (10 * cos (360 * (y - OPTY / zoom))) + 10)
   report (tempx + tempy + (n * ((random-float 1.0) - 0.5)))
end

to zoom-in                                            ; Increase the zoom by a factor of 10
   if (zoom = 0) [user-message "Please click HALT and then SETUP first" stop]
   set zoom 10 * zoom
   calculate-patches                                  ; Recalculate the fitness values of the patches
end

to reset-zoom                                         ; Reset the zoom back to 1
   set zoom 1
   calculate-patches                                  ; Recalculate the fitness values of the patches
end

to calculate-patches                                  ; Calculate the fitness values of the patches
   ask patches [set fitness (rastrigan pxcor pycor Noise_Level)]
   let lower min [fitness] of patches                 ; Find the minimum value
   let upper max [fitness] of patches                 ; Find the maximum value
                                                      ; Color the patches shades of yellow, scaled by the min and max
   ask patches [set pcolor (scale-color yellow fitness lower upper)]
                                                      ; Draw the location of the optimum
   ask patch OPTX OPTY [ask patches in-radius 6 [set pcolor blue]]
end

to do-plot
   set-current-plot "Distance to Optimum"             ; Select the "Distance to Optimum" plot
   set-current-plot-pen "apopen"                      ; Select the apo pen
   plot APOMIN                                        ; Plot the distance of the center of mass from the optimum
end
@#$#@#$#@
GRAPHICS-WINDOW
316
10
825
520
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
-250
250
-250
250
1
1
1
ticks
30.0

BUTTON
2
15
77
48
Setup
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

SLIDER
2
99
310
132
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
2
140
311
173
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
2
186
311
219
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
2
227
311
260
Desired_Separation
Desired_Separation
20
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
2
58
310
91
Number_of_Robots
Number_of_Robots
2
20
7.0
1
1
NIL
HORIZONTAL

SLIDER
1
267
311
300
Noise
Noise
0
5000000
0.0
100000
1
NIL
HORIZONTAL

BUTTON
83
15
190
48
Move Robots
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

MONITOR
2
317
131
362
Distance to Optimum
APOMIN
2
1
11

PLOT
3
369
312
542
Distance to Optimum
Iterations
Distance
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"apopen" 1.0 0 -5825686 true "" ""
"psopen" 1.0 0 -955883 true "" ""

BUTTON
198
15
309
48
Clear Patches
cp
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

BUTTON
192
317
254
362
Zoom In
zoom-in
NIL
1
T
OBSERVER
NIL
Z
NIL
NIL
1

BUTTON
256
317
311
362
Reset
reset-zoom
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

MONITOR
134
317
191
362
Zoom
zoom
17
1
11

@#$#@#$#@
## WHAT IS IT?

This simulation examines the application of artificial physics to the task of noisy function optimization. We call this "artificial physics optimization" (APO).

## HOW IT WORKS

Multiple particles use F = ma and a "split Newtonian" force law to self-organize into a triangular lattice.  However, the algorithm has been extended to perform function optimization as follows.

There is a function f(x, y) defined for all (x, y) points in the environment. Furthermore, this function is noisy, i.e., if you compute f(x, y) multiple times, you will get multiple function values for the same values of x and y. This occurs in the real world because the function values can only be measured via noisy sensors, or because the function is itself changing over time.

Suppose two neighboring particles in the lattice are labeled 'a' and 'b.' These two particles are at coordinate positions (x_a, y_a) and (x_b, y_b) respectively.  Let f_a = f(x_a, y_a) and f_b = f(x_b, y_b) be the (noisy) fitness values associated with particles 'a' and 'b.'

In addition to the normal split Newtonian force that creates triangular lattices, one more force is applied to neighboring pairs of particles that depends on the function values. Suppose that we want to find the minimum of the function.  Then if f_a < f_b, particle 'b' is attracted to 'a,' while particle 'a' is repelled from 'b.' Otherwise, particle 'a' is attracted to 'b,' while particle 'b' is repelled from 'a.' If we want to find the maximum of the function, this logic is reversed. Note that this is a deliberate breaking of the Newtonian assumption that forces are "equal and opposite."

In this simulation we assume that our particles are robots that are trying to find the minimum amount of chemical in some region. Chapter 19 extends this work to multiple dimensions and considers the situation when the optimum moves, thereby making the task much more difficult.

## HOW TO USE IT

Press SETUP to initialize the particles and the patches.  The color of each patch is determined by the value of the function at that patch. You will notice a small delay, because it takes a while to compute the value of the function at every patch. 

Once SETUP is complete, click MOVE ROBOTS. They will move towards the optimum of the function. In this simulation we are minimizing, and the minimal point is shown as a blue disk in the simulation.

The CLEAR PATCHES button will erase the patches, turning them black.

The NUMBER_OF_ROBOTS slider allows you to control the number of robots created at initialization. Changing this slider while the simulation is running will have no effect.

All other sliders will affect the simulation when it is running.

The most important slider is the NOISE slider. This controls the amount of noise in the function. If you move the NOISE slider all the way to the right, the amount of noise is 5,000,000. This is a very high level of noise.

The DISTANCE TO OPTIMUM monitor indicates the distance of the center of mass of the formation from the minimum at the current moment. The DISTANCE TO OPTIMUM graph displays the distance as a function of time.

This simulation has two other nice features.  First, you can "zoom" into the function, allowing you to see fine-level structure embedded in the function.  Each time you click ZOOM IN you "zoom" closer by a factor of 10.  The RESET button brings you back to the default view. The ZOOM IN button should be clicked after SETUP has been clicked and before you click MOVE ROBOTS.

Also, when the simulation is running, you can mouse click in the graphics pane. This moves the optimum to the location of your mouse. This allows you to move the optimum in real time, so you can see whether the formation of robots can resume its search for the optimum. NOTE: you are not "dragging" the goal with the mouse - you merely click once in the location where you want the goal to move to. This can be a slow process, because the values of the patches need to be recomputed.

## THINGS TO NOTICE

Particles are initialized in a random cluster in the upper right portion of the graphics pane, and self-organize into a triangular lattice.  The default position of the optimum is at the lower left portion of the graphics pane.

Try running the simulation with the default settings.  You will see that the formation quickly locates the optimum.  The center of mass of the formation is drawn at each time step so you can see the trajectory that the formation follows. The function looks like a simple bowl, with the bottom of the bowl located at the lower left.  Brighter yellow patches are "higher," whereas darker patches are "lower."

If you move the NOISE slider while the simulation is running, the simulation will pause as the fitness values of all the patches are recomputed.

## THINGS TO TRY

Start with the default zoom level of one. Run the simulation several times. Gradually increase the amount of noise. Look at the depiction of the function in the graphics pane (the yellow patches).  Is the global structure of the function still discernable? Can the robots find the optimum? How would you describe the trajectory? You might want to move the speed slider to the right when you increase the noise. 

Zoom in once, so that the amount of zoom is 10. When there is no noise you will start to see some structure in the function. Run the simulation several times, gradually increasing the amount of noise. Is the optimization task more difficult? Why? An alternative way of viewing the "zoom" factor is that the function has not really changed, but that the spacing between particles has been reduced by a factor of 10. Does that viewpoint help explain the results?

Zoom in once more, so that the amount of zoom is 100. Now you should see definite structure (when there is no noise). Can the robots find the global minimum? If not, what happens and why? 

Does increasing the number of robots and/or increasing the DESIRED_SEPARATION help the search process? If it does, explain why.

Regardless of the amount of zoom, you can always use the mouse to move the optimum. When you click in the graphic pane, the optimum moves to that location. Will the formation move towards the new location? This task is referred to as "tracking." 

## EXTENDING THE MODEL

The noise used in this simulation is drawn from a uniform distribution. Try alternative forms of noise, such as Gaussian.

This simulation uses the "Rastrigan" function to optimize.  Try other functions - Chapters 18 and 19 provide a suite of commonly used functions.

The natural extension of this model is to higher dimensions. This is hard to do with NetLogo. See Chapter 19 for details about how to do this in C, where a comparison is made with particle swarm optimization (PSO) on nonstationary environments.

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "apo.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

This simulation makes use of a NetLogo feature that allows the toroidal nature of the world to be turned off, creating an environment with strict boundaries.

This simulation also creates the variable "fitness" for every patch. This variable is used to store the function value f(x,y) at every patch.

Also, mouse events are used to move the global optimum of the function, allowing you to "translate" the function in the Cartesian coordinate system.

## RELATED MODELS

Chapter 18 of the book provides an alternative approach towards using artificial physics for function optimization. You might be interested in modifying this version of APO to run as described in Chapter 18.

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Spears, W. M. and Spears, D. F. (eds.) Physics-based Swarm Intelligence: From Theory to Practice, Springer-Verlag, (2011).  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT NOTICE

Copyright 2011 William M. Spears. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:  
a) this copyright notice is included.  
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
