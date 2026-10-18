; William M. Spears May 2012
; As per the robot algorithm described on pages 9, 10 and 31 of
; "Autonomous Recharging of Swarm Robots" by Jonathan Mullins,
; Bachelor of Software Engineering thesis from Clayton School
; of Information Technology Monash University, June, 2011
; A crude implementation of Diffusion Limited Aggregation
; For research and educational use only

breed [robots robot]                              ; Introduce the "robot" breed

robots-own [done]

to setup
   clear-all                                      ; Clear everything
   create-robots 1 [setxy 0 0 set done true       ; Create and initialize center robot
                    set shape "circle" set color white set size 5]
   reset-ticks
end

to run-and-monitor
   if (count robots < 1) [user-message "Please click HALT and then SETUP AGENTS first" stop]
   ask robots [move-robots]
   tick
end

to move-robots
   if (not done) [                                ; If not part of structure
      let friends other robots in-radius Desired_Separation with [color = white]
      ; If no friends nearby, or too many friends, random walk.
      ifelse ((count friends < 1) or (count friends > Beta)) [
         ; Parameterized Random walk
         set heading heading + (random (2 * Wiggle_Amount) - Wiggle_Amount)
         fd 1
         ; If boundary is hit, remove particle from world but create a new one also
         ifelse ((round xcor) = max-pxcor) [create 1 die]
            [ifelse ((round xcor) = (0 - max-pxcor)) [create 1 die]
                [ifelse ((round ycor) = max-pycor) [create 1 die]
                    [if ((round ycor) = (0 - max-pycor)) [create 1 die]]]]
      ]
      [
         let friend one-of friends                ; If friends nearby
         let deltax (([xcor] of friend) - xcor)
         let deltay (([ycor] of friend) - ycor)
         let r sqrt (deltax * deltax + deltay * deltay)
         ; Create a "virtual" robot with a green pen down to draw the line
         hatch 1 [pd set color green set heading (atan deltax deltay) fd r die]
         set done true
         set color white                          ; Now part of the DLA structure
      ]
   ]
end

; Create n new robots
to create [n]
   ask one-of robots
      [hatch n [
           setxy (15 * random-xcor / 16) (15 * random-ycor / 16)
           set heading (atan (0 - xcor) (0 - ycor))
           set color yellow set done false
      ]]
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
7
17
80
50
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

BUTTON
86
17
160
50
Move
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
8
110
283
143
Desired_Separation
Desired_Separation
2
10
6.0
1
1
NIL
HORIZONTAL

BUTTON
167
17
280
51
Add 100
create 100
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

MONITOR
83
196
213
241
#Robots
count robots
3
1
11

SLIDER
8
67
282
100
Wiggle_Amount
Wiggle_Amount
0
180
180.0
1
1
NIL
HORIZONTAL

SLIDER
9
152
284
185
Beta
Beta
1
5
1.0
1
1
NIL
HORIZONTAL

PLOT
8
292
287
442
Number of Moving Robots
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
"default" 1.0 0 -16777216 true "" "plot count turtles with [color = yellow]"

@#$#@#$#@
## WHAT IS IT?

This is a simulation of diffusion limited aggregation (DLA), based on the description provided by Mullins (2011). According to Mullins, "DLA is a process 
first discussed in Witten and Meakin (1983), where particles moving about randomly aggregate to form Brownian trees, a type of fractal structure found in nature (e.g. crystal growth, dust coalescence and snow flakes). To clarify the meaning of DLA, diffusion refers to the movement of particles due to temperature fluctuations, limited refers to the increase in size by one particle at a time, and aggregation refers to the collection of particles connected together."

## HOW IT WORKS

A stationary particle is placed at the center of the graphics pane. This is the start of the DLA structure. You can use a button to introduce more particles. These particles perform a random walk. If a particle gets within a used-specified distance of a particle in the DLA structure it stops moving and is now a part of the DLA structure.

If a particle moves outside the graphics pane boundaries it is moved to a random location within the graphics pane (more precisely it is killed and a new particle is created).

## HOW TO USE IT

Click SETUP to initialize the center particle. This particle is white to denote that it is part of the DLA structure.

Click MOVE to have the simulation start. Note that nothing will happen until the ADD 100 button is clicked. 

When ADD 100 is clicked 100 particles are randomly placed in the graphics pane. These particles are yellow until they become part of the DLA structure, at which point they become white. The initial heading of each particle is towards the center of the graphics pane.

Every time step each particle that is not part of the DLA structure performs a parameterized random walk. The parameter is controlled with the WIGGLE_AMOUNT slider. Particles uniformly turn left or right from -WIGGLE_AMOUNT to WIGGLE_AMOUNT degrees. Hence, if WIGGLE_AMOUNT is set to zero, the particles move straight to the center. If WIGGLE_AMOUNT is set to 180, then this is a random walk.

When a particle gets within DESIRED_SEPARATION of a particle in the DLA structure it stops moving and is incorporated into the structure. If there is no particle within distance DESIRED_SEPARATION, the random walk is performed. Similarly, if too many particles are within DESIRED_SEPARATION distance the random walk is performed. The BETA slider controls the number of particles that are considered to be too many.

All the sliders will affect the simulation while yellow particles remain.

## THINGS TO NOTICE

If a particle moves to the edge of the graphics pane it dies, but is immediately replaced by a new particle that is randomly placed within the graphics pane. Hence the number of particles remains constant.

Usually it is reasonable to press "ADD 100" numerous times to get a sufficient number of particles into the simulation. Roughly 1000 is reasonable.

If the DESIRED_SEPARATION is large enough you will see green lines between pairs of white particles in the DLA structure. This helps to better show the precise structure of the DLA.

## THINGS TO TRY

See how WIGGLE_AMOUNT changes behavior. Similarly, change DESIRED_SEPARATION and BETA.

## EXTENDING THE MODEL

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "dla.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.


## NETLOGO FEATURES

This simulation makes good use of the "hatch" command, both to re-introduce particles that stray out of the graphics pane, and to draw the green lines between pairs of white particles in the DLA structure.

## RELATED MODELS


## CREDITS AND REFERENCES

This code is based on the description of DLA provided by "Autonomous Recharging of Swarm Robots" by Jonathan Mullins, Bachelor of Software Engineering thesis from Clayton School of Information Technology Monash University, June, 2011

Witten, T. A. and Meakin, P. (1983). Diffusion-limited aggregation at multiple growth
sites, Phys. Rev. B 28(10): 5632-5642.

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Spears, William M. (2012) Diffusion Limited Aggregation Algorithm in NetLogo.  
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
