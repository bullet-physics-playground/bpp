; William M. Spears and Christer Karlsson, September 2011
; Bioluminescence Tutorial Code
; The variable "dinos" refers to "dinoflagellates"
; For research and educational use only

; Version history
; Initial version of artificial physics by Brian Zuelke
; Extensive modifications by William M. Spears, September 2003
; Minor modifications to artificial physics by Christer Karlsson, February 2007
; Extensive modifications by Christer Karlsson, February - June 2007

breed [drones drone]                                  ; Introduce the "drone" breed
breed [goals goal]                                    ; Introduce the "goal" breed
breed [dinos dino]                                    ; Introduce the "dinoflagellates" breed

globals [total_chemical G goal? goalF minimum? all_done? apoF
         center_of_mass_x center_of_mass_y FR D FMAX DeltaT]

turtles-own [hood deltax deltay r F Fx Fy vx vy dvx dvy mass]

patches-own [chemical]

to setup
   clear-all                                          ; Clear everything
   update-info
   random-seed Random_Seed                            ; Initialize the random number seed
                                                      ; Create and initialize drones
   create-drones Number_of_Drones [setup-drones]
                                                      ; Create the goal at lower left of graphics pane
   create-goals 1 [set color sky set size 2 set shape "circle"
                   setxy (- world-width / 2.5) (- world-height / 2.5)]
                                                      ; Create and initialize dinoflagellates
   create-dinos Number_of_Dinos [set color yellow set shape "circle" set chemical 2
                                 setxy (random world-height) (random world-width)]
   ask patches [set chemical 0]                       ; Initialize with no toxin anywhere

   set goal? true                                     ; Goal force is on
   set minimum? false                                 ; Maximum or minumum chemical concentration?
   set all_done? false                                ; Not done yet!
   set total_chemical 0                               ; Initialize total amount of chemical seen
   set apoF 0.10                                      ; Set APO force to 0.1 (see Chapter 6)
                                                      ; Compute and display the center of mass of the drones
   set center_of_mass_x (sum [xcor * mass] of drones) / (sum [mass] of drones)
   set center_of_mass_y (sum [ycor * mass] of drones) / (sum [mass] of drones)
   ask patch (round center_of_mass_x) (round center_of_mass_y) [set pcolor red]
   reset-ticks
end

to run-dinos                                          ; Runs dinoflagellates
   if (count turtles < 1) [user-message "Please click HALT and then SETUP first" stop]
   repeat 100 [
      diffuse chemical 1                              ; For 100 steps, diffuse and evaporate the toxin
      ask patches [set chemical (chemical * 0.995) set pcolor (scale-color green chemical 0 6)]
      ask dinos [dino-life]                           ; Move the dinoflagellates
      tick
   ]
end

to run-and-monitor                                    ; Runs and monitors the drones
   if (count turtles < 1) [user-message "Please click HALT and then SETUP, and then RUN DINOS" stop]
   ifelse (not all_done?) [                           ; Run until the goal is reached
      update-info
      set G (0.9 * FMAX * (D ^ 2) / (2 * (sqrt 3)))   ; The gravitational constant is set according to theory
      ask drones [ap-drones]                          ; All drones compute where to move
      ask turtles   [move]                            ; All drones move

                                                      ; Compute and display the center of mass of the drones
      set center_of_mass_x (sum [xcor * mass] of drones) / (sum [mass] of drones)
      set center_of_mass_y (sum [ycor * mass] of drones) / (sum [mass] of drones)
      ask patch (round center_of_mass_x) (round center_of_mass_y) [set pcolor red]
      tick
   ]
   [stop]
end

to setup-drones                                       ; Setup the drones
   setxy (world-width / 2.5) (world-height / 2.5)     ; Place at upper right of graphics pane
   set heading random 360                             ; Everyone has a random heading
   set vx 0 set vy 0 set mass 1                       ; Start with no motion and mass = 1
   set shape "circle" set color orange set size 2
   ifelse (who = 0) [] [                              ; Carefully initialize the placement of the drones
      ifelse (who = 1) [setxy (xcor - 1) (ycor + 1)] [
         ifelse (who = 2) [set xcor (xcor - 2)] [
            ifelse (who = 3) [setxy (xcor + 1) (ycor + 1)] [
               ifelse (who = 4) [setxy (xcor - 1) (ycor - 1)] [
                  ifelse (who = 5) [setxy (xcor + 1) (ycor - 1)] [
                     ifelse (who = 6) [set xcor (xcor + 2)] [
                  ]]]]]]]
end

to ap-drones                                          ; Run artificial physics on the drones
   set Fx 0 set Fy 0                                  ; Initialize force components to zero
   set vx (1 - FR) * vx                               ; Slow down according to friction
   set vy (1 - FR) * vy
   let ncount 0

   set hood [who] of other drones                     ; Get the IDs of all other drones
   foreach hood [ [?1] ->
      set deltax (([xcor] of drone ?1) - xcor)
      set deltay (([ycor] of drone ?1) - ycor)
      set r sqrt (deltax * deltax + deltay * deltay)

      if (r < 1.5 * D) [                              ; The generalized split Newtonian law
         set ncount (ncount + 1)
         set F (G * mass * ([mass] of turtle ?1) / (r ^ 2))
         if (F > FMAX) [set F FMAX]                   ; Bounds check on force magnitude
         ifelse (r > D)
            [set Fx (Fx + F * (deltax / r))           ; Attractive force, x-component
             set Fy (Fy + F * (deltay / r))]          ; Attractive force, y-component
            [set Fx (Fx - F * (deltax / r))           ; Repulsive force, x-component
             set Fy (Fy - F * (deltay / r))]          ; Repulsive force, y-component

         ; Move towards chemical minimum or maximum
         ifelse ((minimum? and (chemical < ([chemical] of drone ?1))) or
                 ((not minimum?) and (chemical > ([chemical] of drone ?1))))
            [set Fx (Fx - (apoF * (deltax / r)))
             set Fy (Fy - (apoF * (deltay / r)))]
            [set Fx (Fx + (apoF * (deltax / r)))
             set Fy (Fy + (apoF * (deltay / r)))]
      ]
   ]
   ; Now include goal force, if toggled on and more than one particle
   if (goal? and (ncount > 0)) [
      set hood [who] of goals                         ; Get the IDs of the goal
      foreach hood [ [?1] ->
         set deltax (([xcor] of goal ?1) - xcor)
         set deltay (([ycor] of goal ?1) - ycor)
         set r sqrt (deltax * deltax + deltay * deltay)
         if (r < 2) [set all_done? true]              ; Reached the goal
         set Fx (Fx + (goalF * (deltax / r)))         ; Attractive force, x-component
         set Fy (Fy + (goalF * (deltay / r)))         ; Attractive force, y-component
      ]
   ]

   set total_chemical (total_chemical + chemical)     ; Keep track of all chemical seen

   set dvx DeltaT * (Fx / mass)
   set dvy DeltaT * (Fy / mass)
   set vx  (vx + dvx)                                 ; The x-component of velocity
   set vy  (vy + dvy)                                 ; The y-component of velocity

   set deltax DeltaT * vx
   set deltay DeltaT * vy
   if ((deltax != 0) or (deltay != 0))
      [set heading (atan deltax deltay)]
end

to move
   fd (sqrt (deltax * deltax + deltay * deltay))      ; Move the drone
end

to update-info                                        ; Update information from the sliders
   set FMAX Force_Maximum
   set FR Friction
   set DeltaT Time_Step
   set D Desired_Separation
   set goalF Goal_Force
end

; Moves dinoflagellates. Really, the same model as the original Starlogo slime mold at
; http://education.mit.edu/starlogo/samples/slime.htm, which suffices for dinoflagellates.
to dino-life
   turn-toward-max-chemical                           ; Turn towards maximum chemical concentration
   rt random 40                                       ; Make a random wiggle
   lt random 40
   fd 1                                               ; Forward one step
   set chemical chemical + 2                          ; Replenish chemical
end

; This portion of code is from the NetLogo code at http://ccl.northwestern.edu/netlogo/models/Slime
to turn-toward-max-chemical
   let ahead   [chemical] of patch-ahead 1
   let myright [chemical] of patch-right-and-ahead 45 1
   let myleft  [chemical] of patch-left-and-ahead 45 1
   ifelse ((myright >= ahead) and (myright >= myleft))
      [rt 45]
      [if (myleft >= ahead) [lt 45]]
end

; Turn the goal force on or off
to toggle-goal
   if (goal? != 0) [set goal? not goal?]
end

; Are the drones searching for maximum or minimum toxin?
to toggle-minmax
   if (minimum? != 0) [set minimum? not minimum?]
end
@#$#@#$#@
GRAPHICS-WINDOW
299
10
911
623
-1
-1
4.0
1
10
1
1
1
0
1
1
1
-75
75
-75
75
1
1
1
ticks
30.0

BUTTON
9
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

BUTTON
81
15
176
48
Run Dinos
run-dinos
NIL
1
T
OBSERVER
NIL
D
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
Random_Seed
Random_Seed
1
100
79.0
1
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
0.5
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
20
4.0
1
1
NIL
HORIZONTAL

SLIDER
9
58
288
91
Number_of_Drones
Number_of_Drones
1
7
7.0
1
1
NIL
HORIZONTAL

BUTTON
146
397
287
430
Toggle Min/Max
toggle-minmax
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

SLIDER
10
138
286
171
Number_of_Dinos
Number_of_Dinos
0
500
280.0
10
1
NIL
HORIZONTAL

SLIDER
13
346
288
379
Goal_Force
Goal_Force
0
1
0.3
0.01
1
NIL
HORIZONTAL

BUTTON
182
15
288
48
Move Drones
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

BUTTON
13
397
130
430
Toggle Goal
toggle-goal
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

MONITOR
13
442
131
487
Goal Force on?
goal?
17
1
11

MONITOR
146
443
288
488
Minimum Path?
minimum?
17
1
11

MONITOR
58
505
227
550
Average Chemical Seen
total_chemical / (count drones)
5
1
11

MONITOR
146
599
279
644
Goal Force Theory
2.0 * apoF
17
1
11

MONITOR
15
599
98
644
Goal Force
goalF
17
1
11

TEXTBOX
116
614
216
632
>
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model is an extension of the "split Newtonian" (formation_newton.nlogo) physics-based model of a swarm, for the book entitled "Physicomimetics: Physics-Based Swarm Intelligence." We consider an application of autonomous surface vehicles (called "drones") that float in the ocean and other bodies of water containing dinoflagellates.   Dinoflagellates are single-celled organisms that are bioluminescent (i.e., they produce light when disturbed). 

We focus on two real-world tasks.  In the first task, a swarm of drones should move towards a goal location, while touching as few dinoflagellates as possible.  This is useful for military applications where stealth is desired. A warship, submarine, or special forces team moving through a bioluminescent "hot spot" can easily generate enough light (by disturbing dinoflagellates) to be seen from high points on a nearby shoreline or via aircraft or satellite. The objective of the drones is to find a path through the dinoflagellates that a larger vehicle can follow, while minimally disturbing the organisms.

On the other hand, many dinoflagellate species are responsible for harmful algal blooms (HABs). HABs can produce neurotoxins that are dangerous to other marine organisms and to people swimming in the water. Hence, our second task is to find a path towards a goal that maximizes the collection of dinoflagellates along the way - for the sake of creating a dinoflagellate density map that can be used to forecast the movement of HABs and warn swimmers away from hazardous areas.

## HOW IT WORKS

Multiple drones use F = ma and a "split Newtonian" force law to self-organize into a triangular lattice and move towards a goal.  Depending on how the simulation is run, the drones can either seek to maximize or minimize their exposure to the dinoflagellates, while moving towards the goal.

## WHAT IS NEW

There are two levels of "events" in the simulation.  At the lower level are dinoflagellates that move and leave deposits of chemical toxins in the water.  At the higher level there are aquatic drones that can detect, and track or avoid, the chemical traces.  

This simulation allows you to control the random number "seed." The seed uniquely determines the sequence of random events in the simulation.  Hence, if you run the simulation twice with the same seed, the results will be identical.  This is important when properly designing scientific experiments.

The code automatically computes the proper value for the gravitational constant G, using the theory established in Chapter 3. It also provides theoretical guidance for the magnitude of the force that pulls the swarm towards the goal. 

## HOW TO USE IT

Click SETUP to initialize the drones and the initial positions of the dinoflagellates. Then, click RUN DINOS to make the dinoflagellates move and produce a chemical toxin for 100 time steps. Finally, click MOVE DRONES to have them move through the environment towards the goal. The simulation ends when a drone makes it to the goal.

The NUMBER_OF_DRONES slider allows you to control the number of aquatic drones created at initialization. Changing this slider while the simulation is running will have no effect.

The RANDOM_SEED slider sets the random seed at the beginning of the simulation. If you always use the same random seed, the simulation will run the same way (assuming all other parameters are kept the same). Changing this slider while the simulation is running will have no effect.

The NUMBER_OF_DINOS slider allows you to control the number of dinoflagellates created at initialization. Changing this slider while the simulation is running will have no effect.

All other sliders will affect the simulation when it is running.

The TOGGLE GOAL button allows you to toggle the goal force on and off. The default is for it to be turned on.

The TOGGLE MIN/MAX button allows you to control whether the drones attempt to find a path to the goal that minimizes or maximizes exposure to the toxin. The default is to try to find the maximum path.

## THINGS TO NOTICE

Drones are initialized in a cluster at the top right of the graphics pane, and self-organize into a triangular lattice. The goal is placed at the lower left, in order to make the drones move through as much of the environment as possible.

At each time step, the center of mass of the drones is computed and the location is shown as a red dot on the graphics pane. The sequence of red dots shows the trajectory of the center of mass of the drones.

The GOAL FORCE THEORY monitor provides an estimate of the strength of the goal force that is required to successfully pull the drones through the environment to the goal.

The AVERAGE CHEMICAL SEEN monitor reports the average amount of chemical toxin measured by the drones.

## THINGS TO TRY

Run the simulation and note how much chemical was measured by the drones.  Then, keeping the random seed the same, click the TOGGLE MIN/MAX button, and rerun the experiment. How much chemical is measured now? 

Repeat the above experiment with different random seeds.

Try different values for the goal force. What happens?

Try different values for the DESIRED_SEPARATION.

Try different values for the NUMBER_OF_DRONES.  Does varying the number of drones alter the robots' effectiveness at the two tasks (i.e., maximization and minimization of chemical encountered on the way to the goal)?

Vary the NUMBER_OF_DINOS and determine how this affects performance on the two tasks.

What is the difference between the role played by virtual friction (which is set by the FRICTION slider) and real friction that would be encountered between a drone and the water?
    How critical is virtual friction to mission success, and what level is needed for adequate performance?

In general, can you identify those parameter settings that result in (1) poor, (2) adequate, and (3) excellent performance at each of the two tasks?  Explain why these parameter values lead to better/worse performance.


## EXTENDING THE MODEL

Try adding obstacles, such as buoys to avoid, including obstacles of different sizes and shapes.   See how this increases the difficulty of the tasks.

Introduce currents into the water that affect both the dinoflagellates and the drones.  Run experiments that measure the drones' performance as a function of the spatial and temporal extent, as well as the strength, of the currents.

Increase the number of agents beyond seven, and then test some of the hypotheses in Chapter 6 on your own.   Create and then experimentally test new hypotheses that you invent based on your experiences with the simulator.

Note, in order to change any NetLogo simulation, you must have the source code (i.e., "dinos.nlogo") downloaded to your computer, as well as NetLogo itself. You can not change the code when you are running the simulation with your browser.

## NETLOGO FEATURES

## RELATED MODELS

This is an extension of our generalized split Newtonian force law model, for real-world applications. 

This model provides insight into how we might apply artificial physics for function optimization, which will be shown in "apo.nlogo."

## CREDITS AND REFERENCES

For a discussion of a more real-world faithful simulation of the dinoflagellates and drones (as well as a description of the physical drone), see:

Frey, C. Zarzhitsky, D., Spears, W. M., Spears, D. F., Karlsson, C., Ramos, B., Hamann, J., and Widder, E. (2008) A physicomimetics control framework for swarms of autonomous vehicles. In Proceedings of the Oceans'08 Conference.

The NetLogo slime mold model is at:

Wilensky, U. (1997). NetLogo Slime model. http://ccl.northwestern.edu/netlogo/models/Slime. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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
