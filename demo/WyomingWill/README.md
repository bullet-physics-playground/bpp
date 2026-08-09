Demos by WyomingWill

* some of the Demos are work in progress (marked with WIP).
* the Demos were generated with [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Demos

*   `cheby_diag4.lua`: A Chebyshev (crank-rocker, Grashof) four-bar linkage walker with four copies of the linkage mounted on a cube body -- two on the front face, two mirrored on the back face. Pendants carry wide flat feet, and diagonal crossbars (with a small Z-axis "give") weld opposite pairs of legs together to keep the mechanism walking straight. A red marker trail records the body's trajectory.
*   `cheby_normal6.lua`: A Chebyshev (crank-rocker, Grashof) four-bar linkage walker with four copies of the linkage on a cube body -- the front pair runs in phase, the back pair 90 degrees out of phase. Front and back pairs are each joined by two rigid crossbars, and every pendant carries a wide flat foot so the walker stands on the floor. A red marker trail records the body's trajectory.
*   `linkage.lua`: A viewer for the 10 walking linkages compared in the linkage_c reference tool (Chebyshev-Spears, Hoeckens-Spears, Chebyshev Lambda, Original Hoecken Slider, True 4-Bar Hoekens, Spears 4Bar-1, Jansen, Klann, TrotBot, Strider), driven by the same analytic forward kinematics and duty/flatness/mono metrics, ported straight from that tool's C source rather than simulated with Bullet rigid bodies. Press **F1**/**F2** to step to the previous/next mechanism; each one is normalized to a consistent on-screen size with its full-cycle foot path traced as a static curve. Mechanism name, link/slider/twin counts, and metrics print to the console on every switch.
