# Why the Hoecken-Spears 4-bar guides builds stall (31 October 2026, here; warm40fast, trot, forward)

## Each run's speed (cm/s), logs 7 and steps 7, seeds 1-5

```
Hoecken-Spears_4-bar_diag_logs7_s1 3.440
Hoecken-Spears_4-bar_diag_logs7_s2 4.347
Hoecken-Spears_4-bar_diag_logs7_s3 6.283
Hoecken-Spears_4-bar_diag_logs7_s4 4.229
Hoecken-Spears_4-bar_diag_logs7_s5 0.043
Hoecken-Spears_4-bar_diag_steps7_s1 2.676
Hoecken-Spears_4-bar_diag_steps7_s2 7.276
Hoecken-Spears_4-bar_diag_steps7_s3 5.518
Hoecken-Spears_4-bar_diag_steps7_s4 5.684
Hoecken-Spears_4-bar_diag_steps7_s5 7.112
Hoecken-Spears_4-bar_duty_85_diag_logs7_s1 3.127
Hoecken-Spears_4-bar_duty_85_diag_logs7_s2 -0.282
Hoecken-Spears_4-bar_duty_85_diag_logs7_s3 3.087
Hoecken-Spears_4-bar_duty_85_diag_logs7_s4 -0.313
Hoecken-Spears_4-bar_duty_85_diag_logs7_s5 0.293
Hoecken-Spears_4-bar_duty_85_diag_steps7_s1 4.789
Hoecken-Spears_4-bar_duty_85_diag_steps7_s2 7.498
Hoecken-Spears_4-bar_duty_85_diag_steps7_s3 5.120
Hoecken-Spears_4-bar_duty_85_diag_steps7_s4 7.465
Hoecken-Spears_4-bar_duty_85_diag_steps7_s5 3.769
Hoecken-Spears_4-bar_duty_85_logs7_s1 -0.020
Hoecken-Spears_4-bar_duty_85_logs7_s2 0.014
Hoecken-Spears_4-bar_duty_85_logs7_s3 -0.237
Hoecken-Spears_4-bar_duty_85_logs7_s4 -0.052
Hoecken-Spears_4-bar_duty_85_logs7_s5 0.411
Hoecken-Spears_4-bar_duty_85_steps7_s1 0.088
Hoecken-Spears_4-bar_duty_85_steps7_s2 -0.105
Hoecken-Spears_4-bar_duty_85_steps7_s3 1.795
Hoecken-Spears_4-bar_duty_85_steps7_s4 1.906
Hoecken-Spears_4-bar_duty_85_steps7_s5 0.019
Hoecken-Spears_4-bar_logs7_s1 0.814
Hoecken-Spears_4-bar_logs7_s2 1.980
Hoecken-Spears_4-bar_logs7_s3 -0.073
Hoecken-Spears_4-bar_logs7_s4 0.066
Hoecken-Spears_4-bar_logs7_s5 0.891
Hoecken-Spears_4-bar_steps7_s1 6.368
Hoecken-Spears_4-bar_steps7_s2 6.533
Hoecken-Spears_4-bar_steps7_s3 4.909
Hoecken-Spears_4-bar_steps7_s4 5.689
Hoecken-Spears_4-bar_steps7_s5 5.216
```

## Trace: duty 85, guides, steps 7, seed 1 (tools/stalltrace.lua; every half second: body x, its cranks' turning as a share of driven speed, the feet's x and height, what touched the ground)

```
TRACE 0.5s x 0.9 body y 16.6 cranks  | f1(22.0,7.3) f2(-10.7,5.2) f3(23.1,13.0) f4(-12.5,0.3) | ground-foot1 43%, ground-foot2 50%, ground-foot3 60%, ground-foot4 43%
TRACE 1.0s x 5.1 body y 16.7 cranks 1.01 1.02 1.02 1.01 | f1(21.2,7.2) f2(-5.0,1.9) f3(29.5,8.8) f4(-13.0,0.2) | ground-foot1 100%, ground-foot2 93%, ground-foot4 100%
TRACE 1.5s x 7.7 body y 16.7 cranks 1.00 0.99 0.99 0.82 | f1(34.9,10.7) f2(-6.2,0.4) f3(28.3,7.3) f4(-9.9,4.0) | ground-foot1 67%, ground-foot2 100%, ground-foot3 40%, ground-foot4 77%
TRACE 2.0s x 10.5 body y 16.5 cranks 0.72 0.72 0.72 -0.03 | f1(36.0,8.7) f2(-6.5,0.3) f3(27.7,7.3) f4(-8.8,2.8) | ground-foot2 100%, ground-foot3 100%, ground-foot4 100%
TRACE 2.5s x 12.0 body y 17.5 cranks 0.55 0.54 0.54 -0.00 | f1(35.2,8.9) f2(-7.4,0.2) f3(25.8,7.2) f4(-7.8,3.4) | ground-foot2 100%, ground-foot3 100%, ground-foot4 100%
TRACE 3.0s x 7.8 body y 15.5 cranks 0.53 0.52 0.54 0.09 | f1(30.7,7.4) f2(-4.0,3.0) f3(28.1,13.2) f4(-6.0,3.8) | ground-foot1 47%, ground-foot2 63%, ground-foot3 63%, ground-foot4 100%
TRACE 3.5s x 0.7 body y 16.0 cranks 0.53 0.45 0.54 1.13 | f1(21.2,7.5) f2(-4.0,1.9) f3(26.1,8.1) f4(-11.1,0.5) | ground-foot1 97%, ground-foot2 97%, ground-foot3 10%, ground-foot4 93%
TRACE 4.0s x 4.5 body y 16.7 cranks 0.60 0.67 0.59 1.44 | f1(21.5,7.2) f2(-4.2,1.6) f3(27.0,9.0) f4(-12.5,0.3) | ground-foot1 100%, ground-foot2 100%, ground-foot4 100%
TRACE 4.5s x 7.4 body y 16.8 cranks 0.88 0.90 0.88 1.21 | f1(35.2,11.8) f2(-5.0,0.6) f3(27.0,7.4) f4(-10.1,4.2) | ground-foot1 70%, ground-foot2 100%, ground-foot3 37%, ground-foot4 73%
TRACE 5.0s x 10.4 body y 16.5 cranks 0.74 0.74 0.74 -0.01 | f1(36.9,8.9) f2(-5.3,0.2) f3(26.4,7.2) f4(-8.3,4.1) | ground-foot2 100%, ground-foot3 100%, ground-foot4 80%
TRACE 5.5s x 13.1 body y 17.5 cranks 0.55 0.54 0.54 -0.03 | f1(37.0,8.9) f2(-5.4,0.2) f3(26.1,7.2) f4(-7.0,3.9) | ground-foot2 100%, ground-foot3 100%, ground-foot4 100%
TRACE 6.0s x 8.8 body y 15.4 cranks 0.53 0.51 0.54 0.09 | f1(32.2,7.3) f2(-3.0,3.0) f3(28.2,12.9) f4(-5.0,3.8) | ground-foot1 47%, ground-foot2 70%, ground-foot3 63%, ground-foot4 100%
TRACE 6.5s x 3.4 body y 16.6 cranks 0.54 0.47 0.54 1.19 | f1(23.6,7.5) f2(-1.8,2.6) f3(28.5,8.0) f4(-9.3,1.3) | ground-foot1 97%, ground-foot2 93%, ground-foot3 10%, ground-foot4 100%
TRACE 7.0s x 6.6 body y 16.8 cranks 0.61 0.68 0.60 1.45 | f1(23.4,7.3) f2(-2.5,2.0) f3(28.8,8.5) f4(-11.1,0.3) | ground-foot1 100%, ground-foot2 100%, ground-foot3 13%, ground-foot4 100%
```

## The same seed, diag build

```
TRACE 0.5s x 1.4 body y 16.5 cranks  | f1(22.7,7.4) f2(-12.9,4.6) f3(20.8,13.1) f4(-11.8,0.4) | ground-foot1 50%, ground-foot2 63%, ground-foot3 70%, ground-foot4 40%
TRACE 1.0s x 5.5 body y 16.6 cranks 0.99 1.03 1.03 0.99 | f1(21.8,7.3) f2(-4.4,2.2) f3(29.9,8.5) f4(-12.6,0.3) | ground-foot1 100%, ground-foot2 90%, ground-foot3 17%, ground-foot4 100%
TRACE 1.5s x 8.1 body y 16.9 cranks 0.87 0.99 0.98 0.87 | f1(26.4,11.0) f2(-5.7,0.7) f3(28.0,7.5) f4(-9.0,6.4) | ground-foot1 67%, ground-foot2 97%, ground-foot3 40%, ground-foot4 73%
TRACE 2.0s x 8.8 body y 16.4 cranks 0.04 0.62 0.62 0.03 | f1(30.8,11.9) f2(-6.7,0.4) f3(25.7,7.4) f4(-5.4,6.1) | ground-foot2 100%, ground-foot3 100%, ground-foot4 93%
TRACE 2.5s x 11.2 body y 17.2 cranks 0.01 0.52 0.52 0.01 | f1(34.5,11.4) f2(-7.4,0.6) f3(24.3,7.6) f4(-2.7,7.7) | ground-foot2 100%, ground-foot3 100%, ground-foot4 100%
TRACE 3.0s x 12.4 body y 19.7 cranks 1.02 0.53 0.54 1.02 | f1(37.7,8.6) f2(-7.2,2.0) f3(24.1,13.8) f4(0.2,8.6) | ground-foot1 83%, ground-foot2 57%, ground-foot3 23%, ground-foot4 97%
TRACE 3.5s x 14.9 body y 21.0 cranks 1.13 0.08 0.08 1.13 | f1(36.3,9.0) f2(-2.3,3.9) f3(29.4,19.6) f4(-0.3,9.0) | ground-foot1 100%, ground-foot2 80%, ground-foot4 100%
TRACE 4.0s x 17.7 body y 20.7 cranks 0.55 0.04 0.04 0.55 | f1(35.5,8.4) f2(2.0,7.6) f3(35.0,18.1) f4(-0.7,8.4) | ground-foot1 100%, ground-foot2 100%, ground-foot4 100%
TRACE 4.5s x 24.5 body y 20.0 cranks 0.59 1.20 1.20 0.59 | f1(37.0,7.3) f2(11.5,7.5) f3(45.6,7.4) f4(1.1,7.3) | ground-foot1 63%, ground-foot2 67%, ground-foot3 50%, ground-foot4 77%
TRACE 5.0s x 28.0 body y 20.1 cranks 0.93 1.09 1.09 0.93 | f1(54.3,7.2) f2(11.0,7.3) f3(45.1,7.3) f4(18.4,7.3) | ground-foot1 23%, ground-foot2 80%, ground-foot3 87%, ground-foot4 27%
```

## Pose (tools/snapshot.lua): body pitch and the four ankles' angle against their legs (degrees)

```
guides 1.00 s: pitch 11.5 up | ankles 101 83 90 102
guides 1.75 s: 11.5 | 90 102 102 72
guides 2.25 s: 10.9 | 90 101 101 58
guides 2.75 s: 11.5 | 90 101 101 33   (at the 30 degree ankle stop)
diag   1.00 s: 10.9 | 101 73 91 101
diag   2.25 s: 10.1 | 90 100 100 59
diag   3.00 s: 9.7  | 100 95 90 100   (unfolded, stepping up)
```

## One change at a time, duty 85 guides, mean of seeds 1-5 (cm/s)

| Change | Logs 7 | Steps 7 |
|---|---|---|
| as built (ankle spring 42000) | 0.02 | 0.74 |
| ankle spring 10500 (damping 1050) | 0.02 | 2.32 |
| ankle spring 2600 (damping 260) | 0.19 | 2.47 |
| guides with 5 degrees of give about the side-to-side axis | -0.16 | 1.49 |
| the diag build, unchanged | 1.18 | 5.73 |
