; William M. Spears, September 2011
; Uniform Coverage Tutorial Code, Version 2
; For research and educational use only

extensions[array]                                  ; This extension adds arrays to NetLogo

globals [boundary b1 b2 uhist]                     ; uhist is the uniform distribution histogram

turtles-own [steps]

; Called by "Setup Agents"
; Assumes max-pxcor = -min-pxcor, and max-pycor = -min-pycor
to setup
   clear-all                                       ; Clear everything
   set uhist array:from-list n-values 9 [0]        ; Used to break the environment into nine 3x3 cells
   set boundary (max-pxcor - 2)                    ; Set the boundaries of the cells
   set b1 ((2 * boundary) / 3) - boundary
   set b2 ((4 * boundary) / 3) - boundary
   crt Number_of_Particles                         ; Create and initialize particles throughout the environment
      [setxy (15 * random-xcor / 16) (15 * random-ycor / 16)
       set color white set size 2 monitor]

   ask patches [setup-patches]                     ; Ask patches to color themselves
   setup-plot                                      ; Initialize the uniform distribution histogram
   reset-ticks
   tick
end

to setup-patches                                   ; Use different colors for the three classes of cells
   ifelse ((pxcor < b1) and (pycor < b1)) [set pcolor blue] [
   ifelse ((pxcor < b1) and (pycor < b2)) [set pcolor green] [
   ifelse (pxcor < b1) [set pcolor blue] [

   ifelse ((pxcor < b2) and (pycor < b1)) [set pcolor green] [
   ifelse ((pxcor < b2) and (pycor < b2)) [set pcolor red] [
   ifelse (pxcor < b2) [set pcolor green] [

   ifelse (pycor < b1) [set pcolor blue] [
   ifelse (pycor < b2) [set pcolor green] [set pcolor blue]]]]]]]]
                                                   ; Draw the yellow boundary for the environment
   if ((pxcor = max-pxcor) or (pxcor = min-pxcor) or
       (pycor = max-pycor) or (pycor = min-pycor))
      [set pcolor yellow]
end

; Called forever by "Move Agents"
to go
   if (count turtles < 1) [user-message "Please click HALT and then SETUP AGENTS first" stop]
   ask turtles [go-particles]                      ; All particles try to move
   do-plot                                         ; Redraw the histogram
   tick
end

to go-particles
   let tries 1                                     ; The particles try 10 times to move forward
   set steps steps + 1                             ; They can move forward if there is nothing in the way
   while [(tries < 10) and (([pcolor] of patch-ahead 1 = yellow) or
                             ([pcolor] of patch-left-and-ahead 45 2 = yellow) or
                             ([pcolor] of patch-right-and-ahead 45 2 = yellow) or
                             (any? other turtles in-cone 3 30) or
                             (steps = Mean_Free_Path_Length))]
      [set heading random 360 set steps 0          ; If obstacle in the way or have traveled far enough,
                                                   ; make a random turn and try again
       set tries tries + 1]
   if (tries < 10) [fd 1]                          ; If you can move forward, do so
   monitor                                         ; This updates the cell counts for the histogram
end

to monitor                                         ; Update the histogram bins (cell counts)
   let x 0
   let y 0
                                                   ; Left, center, or right column?
   ifelse (xcor < b1)  [set x 0] [
   ifelse (xcor <= b2) [set x 1] [set x 2]]
                                                   ; Bottom, center, or top row?
   ifelse (ycor < b1)  [set y 0] [
   ifelse (ycor <= b2) [set y 1] [set y 2]]

   array:set uhist (x + (3 * y)) (1 + array:item uhist (x + (3 * y)))
end

to setup-plot                                      ; Setup the histogram
   set-current-plot "Distribution of Coverage"
end

to do-plot                                         ; The histogram, using pens of different colors
   clear-plot
   let temp (ticks * Number_of_Particles)
   set-plot-x-range 0 540
   set-plot-y-range 0 (1 / 9)

   set-current-plot-pen "pen0"
   plotxy 0 (array:item uhist 0 / temp)
   set-current-plot-pen "pen1"
   plotxy 60 (array:item uhist 1 / temp)
   set-current-plot-pen "pen2"
   plotxy 120 (array:item uhist 2 / temp)
   set-current-plot-pen "pen3"
   plotxy 180 (array:item uhist 3 / temp)
   set-current-plot-pen "pen4"
   plotxy 240 (array:item uhist 4 / temp)
   set-current-plot-pen "pen5"
   plotxy 300 (array:item uhist 5 / temp)
   set-current-plot-pen "pen6"
   plotxy 360 (array:item uhist 6 / temp)
   set-current-plot-pen "pen7"
   plotxy 420 (array:item uhist 7 / temp)
   set-current-plot-pen "pen8"
   plotxy 480 (array:item uhist 8 / temp)
end

to-report uniform                                  ; Compute Euclidean distance metric for uniformity over nine cells
                                                   ; 0.94280 is the worst value while 0.000 is the best
   let my_sum 0 let temp (ticks * Number_of_Particles)
   foreach [0 1 2 3 4 5 6 7 8]
      [ [?1] -> set my_sum my_sum + ((array:item uhist ?1 / temp) - (1 / 9)) ^ 2 ]
   report sqrt my_sum                              ; See Chapter 4 for details
end
@#$#@#$#@
GRAPHICS-WINDOW
394
10
827
444
-1
-1
5.0
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
76
19
188
52
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
193
19
304
52
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
377
100
Number_of_Particles
Number_of_Particles
1.0
100.0
75.0
1.0
1
NIL
HORIZONTAL

PLOT
5
207
388
444
Distribution of Coverage
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
"pen0" 60.0 1 -13345367 true "" ""
"pen1" 60.0 1 -10899396 true "" ""
"pen2" 60.0 1 -13345367 true "" ""
"pen3" 60.0 1 -10899396 true "" ""
"pen4" 60.0 1 -2674135 true "" ""
"pen5" 60.0 1 -10899396 true "" ""
"pen6" 60.0 1 -13345367 true "" ""
"pen7" 60.0 1 -10899396 true "" ""
"pen8" 60.0 1 -13345367 true "" ""

MONITOR
7
150
217
195
Theoretical Mean Free Path Length
0.65 * (2 * boundary / 3)
2
1
11

SLIDER
4
107
377
140
Mean_Free_Path_Length
Mean_Free_Path_Length
1
120
15.0
1
1
NIL
HORIZONTAL

MONITOR
225
150
388
195
Deviation from Uniformity
uniform
10
1
11

@#$#@#$#@
## WHAT IS IT?

This model is an attempt to provide "uniform coverage" of a region.  The goal is to have one or more agents move throughout a region, exploring all parts with equal frequency.

Our region is very simple - it is a square divided into nine "cells." The center cell is colored "red," the corner cells are colored "blue," and the remaining cells are colored "green." The yellow boundary prevents agents from escaping the region.

This is our second attempt, which merges physicomimetics with the prior biomimetics approach. Our first approach is in "uniform.nlogo."

## HOW IT WORKS

If an agent moves a certain distance, or senses a wall or another agent in front of it, the agent makes a random turn. Otherwise the agent moves forward. This is motivated by similar behaviors used to model termites in NetLogo.

Every time step, if an agent is in a particular cell, a counter for that cell is incremented by one. This records the number of times that cell has been visited. A histogram displays how often all cells have been visited.

## WHAT IS NEW

This approach adds a physics-based component to the prior biomimetics approach. In gases, molecules travel a distance referred to as the "mean free path" before they collide with another molecule.  We can mimic this concept by having each agent note how far it has traveled between collisions with other particles and walls.  If it has traveled far enough (the "mean free path" length), the agent makes a random turn.

The effect of this additional component is to prevent agents from simply moving across the region from one side to another.  Hence, they will spend more time in cells with fewer walls. This provides coverage that is much more uniform.  This simulation shows that sometimes we can obtain better solutions to problems by combining biomimetics with physicomimetics.

A monitor gives the theoretically derived value for the mean free path that will yield good uniform coverage (see Chapter 4 for details).

## HOW TO USE IT

Click SETUP AGENTS to initialize the particles, and click MOVE AGENTS to have them move.

The NUMBER_OF_PARTICLES slider allows you to control the number of particles created at initialization. Changing this slider while the simulation is running will have no effect.

The MEAN_FREE_PATH_LENGTH slider controls the distance an agent will travel in a straight line before making a random turn. This slider is always monitored, so changing this slider will affect the simulation when it is running.  If the slider is all the way to the right, this is equivalent to the prior simulation "uniform.nlogo."

A histogram shows the distribution of the coverage as nine vertical bars, one bar for each cell. Higher bars represent larger frequencies of exploration. The bars are given the same color as the cell they represent. Qualitatively, the ideal model would yield a very "flat" histogram, showing that all cells have been visited equally often. In the perfect case, each bar would have height 1/9 = .1111... because there are nine cells.

A monitor called DEVIATION FROM UNIFORMITY provides a quantitative metric of how well the model works.  The optimum value is 0.0, while the worst value is 0.9428. Chapter 4 provides an explanation of this metric.

Once you understand the behavior of an agent (or a set of agents), it is generally a good idea to speed up the simulation by moving the speed slider (at the top) to the right. 

## THINGS TO NOTICE

After running the simulation for a while, what does the histogram look like? Does this model favor certain cells over others? If so, why does this occur?

Is the performance better than the previous purely biomimetic approach?

## THINGS TO TRY

Trying running the simulation with one agent and try running with 100 agents. What  
difference does this make in the behavior?

Change the MEAN_FREE_PATH_LENGTH slider. How does this affect performance?

## EXTENDING THE MODEL

How could this model be improved, in terms of achieving better uniform coverage? Try different approaches.

Create a more interesting region (e.g., a rectangle or L-shaped region).

Create a button to add particles and a button to remove particles (you can get the code from prior simulations). Does the behavior change when you add or remove particles?

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "uniform_mfpl.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

The "extensions[array]" command adds the ability to use arrays in NetLogo. An array is used to maintain the cell counts for the nine cells in the environment.

The "do-plot" procedure provides extensive detail on how to create a very useful histogram, using colored pens.

## RELATED MODELS

The NetLogo termite model is provided by:

Wilensky, U.: NetLogo termites model (1997).  http://ccl.northwestern.edu/netlogo/models/Termites. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL

Our less sophisticated model for uniform coverage is in "uniform.nlogo."

## CREDITS AND REFERENCES

Maxim, P., and Spears, W. M. (2009) Robotic Uniform Coverage of Arbitrary-Shaped Connected Regions. Carpathian Journal of Electronic and Computer Engineering, 2 (1).

Maxim, P., Spears, W. M., and Spears, D. F. (2009) Robotic chain formations. In Proceedings of the IFAC Workshop on Networked Robotics.

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
