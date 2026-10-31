# One link-damping rule: the six builds it changes (31 October 2026, here; warm40fast, seed 1, single runs)

LINK_DAMP=0 (the rule) against LINK_DAMP=false (each file's own damping). Speed cm/s, cranks as a share of driven speed.

```
Chebyshev-Spears diag flat0 damp=0: speed 9.066 cranks 0.87..1.29
Chebyshev-Spears diag flat0 damp=false: speed 9.067 cranks 0.87..1.29
Chebyshev-Spears diag logs7 damp=0: speed -0.327 cranks -0.32..1.38
Chebyshev-Spears diag logs7 damp=false: speed 4.004 cranks -0.12..1.42
Chebyshev-Spears diag waves6 damp=0: speed 5.031 cranks -0.63..1.74
Chebyshev-Spears diag waves6 damp=false: speed 5.139 cranks -0.10..1.82
Hoecken-Spears slider diag flat0 damp=0: speed 9.019 cranks 1.00..1.00
Hoecken-Spears slider diag flat0 damp=false: speed 9.021 cranks 1.00..1.00
Hoecken-Spears slider diag logs7 damp=0: speed 4.658 cranks -0.22..1.05
Hoecken-Spears slider diag logs7 damp=false: speed 4.834 cranks -0.45..1.05
Hoecken-Spears slider diag waves6 damp=0: speed 5.250 cranks 0.23..1.04
Hoecken-Spears slider diag waves6 damp=false: speed 5.601 cranks -0.34..1.08
Hoecken-Spears slider flat0 damp=0: speed 9.017 cranks 0.97..1.04
Hoecken-Spears slider flat0 damp=false: speed 9.015 cranks 0.97..1.04
Hoecken-Spears slider logs7 damp=0: speed 2.034 cranks -3.69..1.29
Hoecken-Spears slider logs7 damp=false: speed 4.261 cranks -3.46..1.49
Hoecken-Spears slider waves6 damp=0: speed 4.548 cranks -1.47..1.68
Hoecken-Spears slider waves6 damp=false: speed 5.807 cranks -0.83..1.11
Jansen flat0 damp=0: speed 8.951 cranks 0.96..1.03
Jansen flat0 damp=false: speed 8.955 cranks 0.95..1.03
Jansen logs7 damp=0: speed -0.145 cranks -0.68..1.74
Jansen logs7 damp=false: speed -0.137 cranks -0.72..1.74
Jansen waves6 damp=0: speed 4.730 cranks -0.58..1.63
Jansen waves6 damp=false: speed 4.607 cranks -1.20..1.59
Klann flat0 damp=0: speed 8.931 cranks -1.31..1.19
Klann flat0 damp=false: speed 8.861 cranks -1.22..1.18
Klann logs7 damp=0: speed -0.156 cranks -0.22..1.00
Klann logs7 damp=false: speed 0.070 cranks -0.06..1.87
Klann waves6 damp=0: speed 4.629 cranks -2.10..1.22
Klann waves6 damp=false: speed 4.410 cranks -0.86..1.67
Spears 4-bar flat0 damp=0: speed 9.241 cranks -0.71..1.12
Spears 4-bar flat0 damp=false: speed 9.127 cranks -0.73..1.14
Spears 4-bar logs7 damp=0: speed 0.116 cranks -0.92..1.65
Spears 4-bar logs7 damp=false: speed 0.094 cranks -0.85..1.33
Spears 4-bar waves6 damp=0: speed 3.410 cranks -1.38..1.70
Spears 4-bar waves6 damp=false: speed 1.716 cranks -1.55..1.71
```
