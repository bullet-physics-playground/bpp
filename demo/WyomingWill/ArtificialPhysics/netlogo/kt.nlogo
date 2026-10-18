; William M. Spears, Wesley Kerr, and Diana F. Spears, September 2011
; Kinetic Theory Tutorial Code
; Based on code from "Numerical Methods for Physics" by
; Alejandro L. Garcia, 2nd edition, Prentice Hall, 2000.
; Especially see pages 388 and 393 of Garcia for details.
; For research and educational use only

extensions[array]                                                 ; This extension adds arrays to NetLogo

globals [vel_hist slope corr sum_vel sample]                      ; vel_hist is the velocity distribution histogram

turtles-own [v vx vy]

; Called by "Setup Agents"
to setup
   clear-all                                                      ; Clear everything
   set sample 0
   set vel_hist array:from-list n-values 13 [0]                   ; Used to break the environment into 13 columns

   crt Number_of_Particles                                        ; Create and initialize particles throughout the environment
      [set heading (random 360) set v (sqrt Temperature) * 1.2533 ; Constant is from theory (see Chapter 4)
       set vx (v * cos heading) set vy (v * sin heading)
       set color white set size 1.5
       setxy (7 * random-xcor / 8) (7 * random-ycor / 8)]

   ask patches [setup-patches]                                    ; Ask patches to initialize two vertical walls
   setup-plot                                                     ; Initialize the velocity distribution histogram
   monitor                                                        ; Update the information for the histogram
   compute-stats                                                  ; Compute slope and correlation coefficient of velocity histogram
   reset-ticks
end

to setup-patches                                                  ; Setup two vertical walls
   if ((pxcor = (max-pxcor - 0)) or (pxcor = (max-pxcor - 1)) or (pxcor = (max-pxcor - 2))) [set pcolor red]
   if ((pxcor = (min-pxcor + 0)) or (pxcor = (min-pxcor + 1)) or (pxcor = (min-pxcor + 2))) [set pcolor yellow]
end

; Called forever by "Move Agents"
to go
   if (count turtles < 1) [user-message "Please click HALT and then SETUP AGENTS first" stop]

   tick
   ask turtles [go-particles]                                     ; All particles update their velocity
   ask turtles [move]                                             ; All particles move
   monitor                                                        ; Update the information for the histogram
   do-plot                                                        ; Redraw the histogram
   compute-stats                                                  ; Compute slope and correlation coefficient of velocity histogram
end

to go-particles
   let friends other turtles in-radius 2                          ; Anyone near you?
   if (any? friends) [                                            ; If so, assume a collision
     let friend [who] of one-of friends                           ; For details, see Chapter 4 of the book
     let rel_speed sqrt (((vx - ([vx] of turtle friend)) ^ 2 +
                         ((vy - ([vy] of turtle friend)) ^ 2)))
     let cm_vel_x 0.5 * (vx + ([vx] of turtle friend))
     let cm_vel_y 0.5 * (vy + ([vy] of turtle friend))
     let theta (random 360)
     let costh (cos theta)
     let sinth (sin theta)
     let vrel_x (rel_speed * sinth)
     let vrel_y (rel_speed * costh)
     set vx (cm_vel_x + 0.5 * vrel_x)                             ; Figure out the new velocities for yourself and your neighbor
     set vy (cm_vel_y + 0.5 * vrel_y)
     ask turtle friend [set vx (cm_vel_x - 0.5 * vrel_x)
                        set vy (cm_vel_y - 0.5 * vrel_y)]
   ]
                                                                  ; Compute the effect of the walls on particle velocity
   if (any? patches in-radius 1 with [pcolor = red])              ; The red wall moves up
      [set vx (- (sqrt (2 * Temperature)) * (sqrt (- ln (random-float 1.0))))
       set vy (((random-normal 0.0 1.0) * (sqrt Temperature)) + Wall_Velocity)]

   if (any? patches in-radius 1 with [pcolor = yellow])           ; The yellow wall moves down
      [set vx ((sqrt (2 * Temperature)) * (sqrt (- ln (random-float 1.0))))
       set vy (((random-normal 0.0 1.0) * (sqrt Temperature)) - Wall_Velocity)]
   if ((vx != 0) or (vy != 0)) [set heading atan vx vy]
end

to move                                                           ; The particles move with velocity v
   set v sqrt (vx * vx + vy * vy)
   fd v
end

to monitor                                                        ; Update the velocity distribution for the histogram
   if (sample = 0) [set sum_vel 0]
   foreach [0 1 2 3 4 5 6 7 8 9 10 11 12] [ [?1] ->
      if (sample = 0) [array:set vel_hist ?1 0]
      let column (turtles with [((xcor > (min-pxcor + (?1 * 2 * max-pxcor / 13))) and
                                 (xcor < (min-pxcor + ((?1 + 1) * 2 * max-pxcor / 13))))])
      if (any? column) [array:set vel_hist ?1 ((array:item vel_hist ?1) + (mean [vy] of column))]
   ]
   set sum_vel (sum_vel + (sum [v] of turtles))
   set sample sample + 1
end

to setup-plot                                                     ; Setup the histogram
   set-current-plot "Distribution of Velocities"
end

to do-plot                                                        ; Draw the histogram
   clear-plot
   set-plot-x-range 0 780 ; 540
   set-plot-y-range (- Wall_Velocity) (Wall_Velocity + 0.001)

   set-current-plot-pen "pen0"
   plotxy 0 (array:item vel_hist 0) / sample
   set-current-plot-pen "pen1"
   plotxy 60 (array:item vel_hist 1) / sample
   set-current-plot-pen "pen2"
   plotxy 120 (array:item vel_hist 2) / sample
   set-current-plot-pen "pen3"
   plotxy 180 (array:item vel_hist 3) / sample
   set-current-plot-pen "pen4"
   plotxy 240 (array:item vel_hist 4) / sample
   set-current-plot-pen "pen5"
   plotxy 300 (array:item vel_hist 5) / sample
   set-current-plot-pen "pen6"
   plotxy 360 (array:item vel_hist 6) / sample
   set-current-plot-pen "pen7"
   plotxy 420 (array:item vel_hist 7) / sample
   set-current-plot-pen "pen8"
   plotxy 480 (array:item vel_hist 8) / sample
   set-current-plot-pen "pen9"
   plotxy 540 (array:item vel_hist 9) / sample
   set-current-plot-pen "pen10"
   plotxy 600 (array:item vel_hist 10) / sample
   set-current-plot-pen "pen11"
   plotxy 660 (array:item vel_hist 11) / sample
   set-current-plot-pen "pen12"
   plotxy 720 (array:item vel_hist 12) / sample
end

to compute-stats                                                  ; Compute slope and correlation coefficient of velocity histogram
   let xbar 6.0 let ybar 0
   let sxy 0 let sx 0 let sy 0
   foreach [0 1 2 3 4 5 6 7 8 9 10 11 12] [ [?1] ->
      set ybar (ybar + (array:item vel_hist ?1) / sample)
   ]
   set ybar (ybar / 13)
   foreach [0 1 2 3 4 5 6 7 8 9 10 11 12] [ [?1] ->
      set sxy (sxy + ((?1 - xbar) * (((array:item vel_hist ?1) / sample) - ybar)))
      set sx (sx + ((?1 - xbar) ^ 2))
      set sy (sy + (((array:item vel_hist ?1) / sample) - ybar) ^ 2)
   ]
   set slope (sxy / sx)
   set corr (sxy / ((sqrt sx) * (sqrt sy)))
end
@#$#@#$#@
GRAPHICS-WINDOW
394
10
933
550
-1
-1
6.25
1
10
1
1
1
0
1
1
1
-42
42
-42
42
1
1
1
ticks
30.0

BUTTON
14
17
126
50
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
137
17
248
50
Move Agents
go
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
5
67
382
100
Number_of_Particles
Number_of_Particles
1.0
1000.0
1000.0
1.0
1
NIL
HORIZONTAL

PLOT
3
313
386
550
Distribution of Velocities
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen0" 60.0 1 -16777216 true "" ""
"pen1" 60.0 1 -16777216 true "" ""
"pen2" 60.0 1 -16777216 true "" ""
"pen3" 60.0 1 -16777216 true "" ""
"pen4" 60.0 1 -16777216 true "" ""
"pen5" 60.0 1 -16777216 true "" ""
"pen6" 60.0 1 -16777216 true "" ""
"pen7" 60.0 1 -16777216 true "" ""
"pen8" 60.0 1 -16777216 true "" ""
"pen9" 60.0 1 -16777216 true "" ""
"pen10" 60.0 1 -16777216 true "" ""
"pen11" 60.0 1 -16777216 true "" ""
"pen12" 60.0 1 -16777216 true "" ""

SLIDER
4
107
383
140
Wall_Velocity
Wall_Velocity
0
2
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
6
150
385
183
Temperature
Temperature
0.001
0.04
0.01
0.001
1
NIL
HORIZONTAL

MONITOR
209
203
356
248
Slope
slope
5
1
11

MONITOR
209
253
356
298
Correlation Coefficient
corr
5
1
11

BUTTON
266
17
374
50
Resample
set sample 0
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
45
202
183
247
Linear Momentum X
mean [vx] of turtles
5
1
11

MONITOR
46
253
184
298
Linear Momentum Y
mean [vy] of turtles
5
1
11

@#$#@#$#@
## WHAT IS IT?

This is a model of a physics-based approach to provide a "sweep" of a region.  The goal is to sweep a large group of robots through a long bounded region. This is especially useful for de-mining, searching for survivors after a disaster, and for robot sentries. 

We use a very different form of physicomimetics, based on "kinetic theory." In kinetic theory, particles are treated as possessing no potential energy. The system consists entirely of kinetic energy. In fact, kinetic theory does not typically deal with forces at all. Instead, increases in particle velocity are modeled as being caused by collisions and/or a system temperature increase. This is very different from the F = ma physics systems that we have examined earlier.
   
Our region is very simple - it is a vertical corridor. In the model, we treat the left boundary as an infinite-length wall that moves down, whereas the right boundary is an infinite-length wall that moves up. This creates an interesting sweep, where one-half of the corridor is swept in one direction while the other half is swept in the other direction. Chapter 4 discusses this particlar simulation in more detail. Chapter 7 provides a more sophisticated version of the simulator in which both walls move in the same direction and robots are modeled realistically.  Chapter 7 also provides experimental and theoretical results.

Kinetic theory is a stochastic approach.   The focus is on obtaining desirable bulk movement of the swarm. The movements of the individual agents are probabilistic and therefore unpredictable.  This is desirable for applications where stealth is required.

## HOW IT WORKS

If an agent senses another agent nearby, they both respond as if a virtual collision has occurred. If an agent senses a wall nearby, it changes its velocity in response to the virtual motion of the wall.  In addition, the temperature T of the walls adds kinetic energy to the particles.

## HOW TO USE IT

Click SETUP AGENTS to initialize the particles, and click MOVE AGENTS to have them move.

The NUMBER_OF_PARTICLES slider allows you to control the number of particles created at initialization. Changing this slider while the simulation is running will have no effect.

Two sliders affect the simulation when it is running.  The WALL_VELOCITY slider controls the velocity of both walls (i.e., the left wall moves down with velocity WALL_VELOCITY, and the right wall moves up with velocity WALL_VELOCITY). The TEMPERATURE slider controls the temperature T of both walls.

Two monitors show the x- and y-components of the linear momentum. These should remain close to zero because the particles are stationary when initialized, and kinetic theory conserves linear momentum.

A histogram shows the velocity distribution of the particles. The corridor is broken into  
13 vertical columns, and the histogram shows 13 bars that indicate the average velocity of the particles in each column. The leftmost bar gives the average velocity in the leftmost column, and the rightmost bar gives the average velocity in the rightmost column.  Since there is an odd number of columns, the central bar reflects the average velocity in the center column.

The velocity distribution is averaged during the running of the simulation.  If you click RESAMPLE, the previous data is thrown away and the averages are (re-)computed using the data accumulated after RESAMPLE is clicked. Hence, the averages will fluctuate until enough new samples are accumulated.

Two additional monitors give quantitative information about the bars of the histogram. One monitor shows the slope of the bars.  The other monitor gives the correlation coefficient - the maximum value is 1.0, indicating that the height of the bars has a relationship that is predicted by theory (see Chapters 4 and 7 for specifics).

Once you understand the behavior of the particles, it is generally a good idea to speed up the simulation by moving the speed slider (at the top) to the right. 

## THINGS TO NOTICE

After running the simulation for a while, what does the histogram look like?   Can you guess why it has this particular form?  Try guessing first, and then read Chapter 4 (or Chapter 7) to find the mathematical formula for the velocity distribution.  

Both the WALL_VELOCITY and the wall TEMPERATURE are controllable by sliders.  These parameters control the bulk movement of the robotic swarm.

Recall that a kinetic theory approach conserves linear momentum.  The book explains how collisions are implemented in a way that ensures this conservation.

## THINGS TO TRY

Trying running the simulation with 100 agents and try running with 1000 agents. What  
difference does this make in the behavior?

Change the WALL_VELOCITY. For an extreme case, set it to zero.

Change the TEMPERATURE.

How do these changes (of the WALL_VELOCITY and TEMPERATURE, going from low to high values) affect behavior?  Can you explain the differences in swarm behavior?
    
Try a wide variety of parameter settings and see if you can predict how the settings will affect the shape and slope of the histogram.

Figure out which parameter (slider) settings provide better horizontal corridor coverage, and which provide better vertical corridor coverage.   How would you recommend balancing the two?  Can you derive a formula for doing this?

## EXTENDING THE MODEL

Try adding obstacles, including obstacles of difference sizes and shapes.  Observe what happens in the "shadow regions" (see Chapter 7) as you vary the parameters.   Find the best settings for shadow region coverage, and determine how that affects the vertical and horizontal coverage of the corridor.

Create a button to add agents and a button to remove agents (you can get the code from prior simulations). Does the bulk swarm behavior change when you add or remove agents?  If yes, how?

For a more challenging project, invent a hybrid physicomimetic algorithm consisting of both forces and collisions.  Normal movement is driven by forces, whereas collisions are used to drive the particles out of enclosing "traps."   Start with code such as "formation_lj_goal_obs.nlogo" and add in some of the code from "kt.nlogo" as appropriate.  Note that you will have to add software procedures for an agent to detect when it is trapped and then to switch from forces to collisions (e.g., by raising the wall TEMPERATURE inside a cul-de-sac) to pop out of the "trap."

In order to change any NetLogo simulation, you must have the source code (i.e., "kt.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

The "extensions[array]" command adds the ability to use arrays in NetLogo. An array is used to compute the velocity distribution for the thirteen columns in the environment.

The "do-plot" procedure provides extensive detail on how to create a very useful histogram.

## CREDITS AND REFERENCES

Spears, D. F., Kerr, W., and Spears, W. M. (2009) Fluid-like swarms with predictable macroscopic behavior. Lecture Notes in Computer Science, Volume 4324.

Spears, D. F., Kerr, W., and Spears, W. M. (2006) Physics-based robot swarms for coverage problems. International Journal on Intelligent Control and Systems, 11(3).

Kerr, W. and Spears, D. F. (2005) Robotic simulation of gases for a surveillance task. In Proceedings of the IEEE/RSJ International Conference on Intelligent Robots and Systems.

Garcia, A. (2000) Numerical Methods for Physics, Second Edition.  New Jersey: Prentice Hall.  

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Spears, W. M. and Spears, D. F. (eds.) Physicomimetics: Physics-Based Swarm Intelligence, Springer-Verlag, (2011).  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT NOTICE

Copyright 2011 William M. Spears. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:   
a) this copyright notice is included, and   
b) this model will not be redistributed for profit without permission from William M. Spears.   
Contact William M. Spears for appropriate licenses for redistribution for profit.

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
