globals [
  ; global variables
  ;num-turtles          ; Number of individuals
  ;arena-radius         ; Radius of the arena
  ;vision-radius        ; Individual's vision radius
  ;initial-speed        ; Initial speed
  ;speed-increase       ; Percentage increase in speed during panic state
  ;speed-decrease       ; Percentage decrease in speed during panic state
  ;distance-threshold   ; Distance threshold between individuals
  ;pause-time           ; Pause time after collision
  ;event-time           ; Time when the event occurs
  ;effect-radius        ; Effect radius of dead individuals
  vision-angle   ; Size of individual's vision angle
]

patches-own [
  affected?  ; Mark whether the patch is affected by dead individuals
]

turtles-own [
  ; Individual properties
  vision         ; Vision length
  status         ; Individual's state: normal, panic, injured, dead, safe
  direction      ; Individual's heading
  speed          ; Individual's current speed
  collided?      ; Mark whether the individual has collided
]

to setup
  clear-all
  reset-ticks

  ; Initialize environment
  ask patches [
    set pcolor white
  ]

  ; Initialize affected-patches
  ask patches [
    set affected? false
  ]


  ; Create individuals
  create-turtles num-turtles [
    set size 1
    set color blue
    set status "normal"
    set vision vision-radius
    set direction random-direction
    set speed initial-speed
    setxy random-xcor random-ycor
    set vision-angle 120
    set collided? false
    set affected? false
    set hidden? false

    ; Ensure individuals are within the circular arena
    while [distancexy 0 0 > arena-radius] [
      setxy random-xcor random-ycor
    ]
  ]

  ; Draw initial state
  draw-arena
  draw-turtles
end

; Draw circular arena
to draw-arena
  ask patches [
    if distancexy 0 0 > arena-radius [
      set pcolor gray
    ]
  ]
end

; Draw individuals
to draw-turtles
  ask turtles [
    if status = "normal" [set color blue]
    if status = "panic" [set color yellow]
    if status = "injured" [set color orange]
    if status = "dead" [set color red]
    if status = "safe" [set color green]
  ]
end

to go
  ; Stop condition: all individuals have reached "safe" state or "dead" state
  if all? turtles [status = "safe" or status = "dead"] [stop]

  ; Event occurrence
  if ticks = event-time [
    ask one-of turtles with [status != "dead"] [
      set status "dead"
      ask other turtles in-radius effect-radius [
        if status != "dead" [set status "panic"]
      ]
    ]
  ]

  ; Hide individuals that have become safe
  ask turtles with [status = "safe"] [
    set hidden? true
  ]

  ; Status decision phase
  ask turtles with [not hidden?] [
    update-status
  ]

  ; Behavior execution phase
  ask turtles with [not hidden?] [
    execute-behavior
  ]

    ; Update position
  ask turtles [
    check-boundary
  ]

    ; Update affected-patches
  ask patches [
    set affected? false
  ]

  ask turtles with [status = "dead"] [
    ask patches in-radius effect-radius [
      set affected? true
    ]
  ]

  ask turtles [
    if status != "safe" and not affected? and (status = "panic" or status = "injured") [
      if any? other turtles with [status != "safe"] in-radius 1 [
        set status "injured"
        ; If the individual has reached the boundary, even injured, set its status to "safe"
        if distancexy 0 0 >= arena-radius [
          set status "safe"
        ]
      ]
    ]
  ]

  ; Draw current state
  draw-turtles

  tick
end

; Update individual's status
to update-status
  let visible-turtles other turtles in-cone vision-radius vision-angle

  if status = "normal" [
    ; Decision-making in normal state
    ifelse any? patches in-radius vision-radius with [affected?] [
      set status "panic"
    ] [
    let nearest-panic-turtle min-one-of visible-turtles with [status = "panic"] [distance myself]
    if nearest-panic-turtle != nobody [set status "panic"]
  ]
  ]

  if status = "panic" [
    ; Decision-making in panic state
    ifelse any? patches in-radius vision-radius with [affected?] [
      set affected? true
    ] [
      set affected? false
    ]
    if status != "safe" and any? other turtles in-radius 1 with [status != "dead"] [
      if not collided? [set collided? true]
    ]
  ]

  if status = "injured" [
    ; Decision-making in injured state
    if ticks mod pause-time = 0 and status != "safe" [
      set status "panic"
      ; If the individual has reached the boundary, directly set its status to "safe"
      if distancexy 0 0 >= arena-radius [
        set status "safe"
      ]
    ]
  ]
end

; Execute behavior corresponding to status
to execute-behavior
  if status = "normal" [
    ; Behavior in normal state
    rt random 90
    lt random 90
    check-boundary
    fd speed
  ]

  if status = "panic" [
    ; Behavior in panic state
    ifelse affected? [
      away-direction one-of turtles with [status = "dead"]
    ] [
      nearest-exit
    ]

    ; Update position
    check-boundary
    update-speed
    fd speed
  ]

  if status = "injured" [
    ; Behavior in injured state
    set speed 0
  ]

  ; If the individual has reached the safe state or is dead, do not execute subsequent behaviors
  if status != "safe" and status != "dead" [
    ; Update position
    check-boundary
    update-speed
    fd speed
  ]
end

; Calculate the direction towards the nearest arena boundary
to nearest-exit
  let center-dx xcor
  let center-dy ycor
  let dist-to-boundary arena-radius - sqrt(center-dx ^ 2 + center-dy ^ 2)
  let boundary-x center-dx * (arena-radius / sqrt(center-dx ^ 2 + center-dy ^ 2))
  let boundary-y center-dy * (arena-radius / sqrt(center-dx ^ 2 + center-dy ^ 2))
  face patch boundary-x boundary-y
end

; Calculate the direction away from a specified individual
; This is designed for leaving the dead individual
to away-direction [a-turtle]
  ifelse (xcor = [xcor] of a-turtle) and (ycor = [ycor] of a-turtle) [
    rt random 360  ; If the positions are exactly the same, randomly choose a direction to turn right
  ] [
    ; Calculate the relative position (delta-x, delta-y) to the other turtle
    let delta-x xcor - [xcor] of a-turtle
    let delta-y ycor - [ycor] of a-turtle
    ; Convert the relative position to a direction angle (0-360) and set heading
    let adjusted-direction (atan delta-y delta-x + 180) mod 360
    set heading adjusted-direction
  ]
end

; Adjust speed based on the distance from other individuals within the vision range
to update-speed
  ; Find other turtles within vision cone
  let visible-turtles other turtles in-cone vision-radius vision-angle
  ifelse any? visible-turtles with [distance myself <= distance-threshold] [
    ; If any visible turtle is within distance threshold, decrease speed
    set speed initial-speed * (1 - speed-decrease / 100)
  ] [
    ; If no visible turtle is within distance threshold, increase speed
    set speed initial-speed * (1 + speed-increase / 100)
  ]
end

; Check if individual reached the boundary
; If not "normal", set status to "safe" and stop at boundary
; If "normal", change direction to go back into arena
to check-boundary
  if distancexy 0 0 >= arena-radius [
    set heading (heading + 180) mod 360 ; Turn around
    fd (distancexy 0 0 - arena-radius) ; Move back into arena
    if status != "normal" [
      set status "safe" ; Mark as safe if not normal
    ]
  ]
end

; Randomly generate a direction angle (0-359)
to-report random-direction
  report random 360
end
@#$#@#$#@
GRAPHICS-WINDOW
213
10
709
507
-1
-1
8.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
0
0
1
ticks
30.0

BUTTON
15
47
84
80
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
123
46
186
79
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
85
186
118
num-turtles
num-turtles
10
500
100.0
10
1
NIL
HORIZONTAL

SLIDER
14
124
186
157
arena-radius
arena-radius
0
30
28.0
1
1
NIL
HORIZONTAL

SLIDER
14
163
186
196
vision-radius
vision-radius
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
14
203
186
236
initial-speed
initial-speed
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
14
282
186
315
speed-decrease
speed-decrease
0
50
20.0
10
1
NIL
HORIZONTAL

SLIDER
8
452
192
485
distance-threshold
distance-threshold
0
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
13
324
185
357
pause-time
pause-time
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
13
365
185
398
event-time
event-time
1
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
13
409
185
442
effect-radius
effect-radius
0
30
5.0
1
1
NIL
HORIZONTAL

PLOT
730
65
1161
262
Population of Different Status
ticks
Population
0.0
50.0
0.0
50.0
true
true
"" ""
PENS
"Normal" 1.0 0 -7500403 true "" "plot count turtles with [status = \"normal\"]"
"Panic" 1.0 0 -2674135 true "" "plot count turtles with [status = \"panic\""
"Injured" 1.0 0 -955883 true "" "plot count turtles with [status = \"injured\"]"
"Safe" 1.0 0 -13840069 true "" "plot count turtles with [status = \"safe\"]"

MONITOR
731
13
788
58
Normal
count turtles with [status = \"normal\"]
1
1
11

MONITOR
800
13
858
58
Injured
count turtles with [status = \"injured\"]
1
1
11

MONITOR
871
13
928
58
Panic
count turtles with [status = \"panic\"]
1
1
11

MONITOR
941
13
998
58
Safe
count turtles with [status = \"safe\"]
1
1
11

BUTTON
61
10
144
43
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
243
186
276
speed-increase
speed-increase
10
50
50.0
10
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

The model aims to simulate and understand the behavior and interactions of individuals in an open space during an emergency event. It investigates how factors such as population size, space area, event timing, and individual perception and action capabilities influence the evacuation time. By identifying key factors affecting evacuation efficiency through simulation, the model provides insights for emergency evacuation planning.

## HOW IT WORKS

The model consists of individuals (turtles) moving in an open space (patches). Each individual has a state (normal, panic, injured, dead, or safe) and follows specific rules based on their state and environmental factors. The key rules are:

1. At a specified event-time, an individual turns "dead", and surrounding individuals within a certain radius turn "panic".
2. Normal individuals move randomly, while panicked individuals try to avoid dead individuals and move towards the nearest boundary.
3. Individuals update their states based on their interactions and perceptions. Normal individuals become panic when seeing panicked or dead individuals, and panicked individuals may get injured in collisions.
4. The simulation ends when all individuals are either "safe" (evacuated) or "dead".

## HOW TO USE IT

1. Set the model parameters in the Interface tab, such as num-turtles, arena-radius, vision-radius, etc.
2. Click the "Setup" button to initialize the model.
3. Click the "Go" button to run the simulation.
4. Observe the model's behavior in the View window and plots.

## THINGS TO NOTICE

1. The spatial distribution of individuals at different time steps, including clustering, congestion, and the final distribution of safe individuals relative to the location of dead individuals.
2. The time series of the number of individuals in different states throughout the evacuation process.
3. The relationship between model parameters and the total evacuation time.
4. Under specific circumstances the model will reach a loop kept running forever!

## THINGS TO TRY
1. Vary the num-turtles, arena-radius, and event-time to see how they affect the evacuation process and total evacuation time.
2. Change the vision-radius and vision-angle to investigate the impact of individual perception capabilities on the model's behavior.
3. Adjust the panic-speed-increase and speed-decrease to observe how changes in individual action capabilities influence the evacuation dynamics.
4. Investigate what kinds of situation this model will into a loop.

## EXTENDING THE MODEL

1. Add more complex individual behaviors, such as group formation or leader-follower dynamics.
2. Introduce heterogeneity in individual characteristics, such as different walking speeds or panic thresholds.
3. Incorporate more realistic space layouts, such as obstacles or multiple exits.
4. Implement multiple event epicenters to simulate more complex emergency scenarios.

## NETLOGO FEATURES

No unusual features used.

## RELATED MODELS

No models related.

## CREDITS AND REFERENCES

Github link of this model can be found at:
https://github.com/MengyuanHan1/Agent-Based-Modeling
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
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
