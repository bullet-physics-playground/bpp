# BPP Demos

This directory contains the Lua demo scripts for [Bullet Physics Playground](https://github.com/bullet-physics-playground/bpp) (BPP). Run any of them with `bpp -f <path>`, e.g. `bpp -f demo/basic/00-hello.lua`.

### Basic demos

* [basic/](https://github.com/bullet-physics-playground/bpp/tree/master/demo/basic) - [README.md](https://github.com/bullet-physics-playground/bpp/blob/master/demo/basic/README.md) - introductory examples covering shapes, callbacks, meshes, and OpenSCAD models
* [constraint/](https://github.com/bullet-physics-playground/bpp/tree/master/demo/constraint) - [README.md](https://github.com/bullet-physics-playground/bpp/blob/master/demo/constraint/README.md) - demos of the Bullet Physics constraint types (hinge, slider, gear, point2point, and more)

### Extra demos

* [jaimevives/](https://github.com/bullet-physics-playground/bpp/tree/master/demo/jaimevives) by [@jaimevives](https://github.com/jaimevives) - [README.md](https://github.com/bullet-physics-playground/bpp/blob/master/demo/jaimevives/README.md) - vehicle, chain, and coin-pile demos
* [koppi/](https://github.com/bullet-physics-playground/bpp/tree/master/demo/koppi) by [@koppi](https://github.com/koppi) - [README.md](https://github.com/bullet-physics-playground/bpp/blob/master/demo/koppi/README.md) - a broad collection of demos, including gears, DNA replication/transcription, and Towers of Hanoi
* [WyomingWill/](https://github.com/bullet-physics-playground/bpp/tree/master/demo/WyomingWill) by [@WyomingWill](https://github.com/WyomingWill) - [README.md](https://github.com/bullet-physics-playground/bpp/blob/master/demo/WyomingWill/README.md) - Chebyshev four-bar linkage walker demos
* [claude/](https://github.com/bullet-physics-playground/bpp/tree/master/demo/claude) - demos generated with [Claude Code](https://docs.anthropic.com/en/docs/claude-code), including `jansen-walker.lua`, a six-legged Theo Jansen ("Strandbeest") walker built from real Bullet rigid bodies and hinge constraints, and `physicomimetics.lua`, a physics-based swarm that self-assembles into a hexagonal lattice from Artificial Physics force laws

### Meshes

* [mesh/](https://github.com/bullet-physics-playground/bpp/tree/master/demo/mesh) - 3ds, STL, and OpenSCAD meshes used by the demos above

### Lua modules

* [module/](https://github.com/bullet-physics-playground/bpp/tree/master/demo/module) - shared Lua modules (colors, common transform/camera helpers, splines, OpenSCAD wrappers, POV-Ray materials) used by the demos above
