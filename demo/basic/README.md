# BPP Basic Demos

This directory contains a collection of basic examples for the Bullet Physics Playground (BPP).

## File Descriptions

*   `00-hello-cmdline.lua`: A simple script showing a sphere dropping onto a plane. This example is designed to be run from the command line and can be used to plot the sphere's trajectory.
*   `00-hello-pov.lua`: Similar to the `hello-cmdline.lua` example, but this script is set up to render the animation using POV-Ray.
*   `00-hello.lua`: A comprehensive demonstration of various BPP features, including different shapes, lighting, and advanced POV-Ray settings.
*   `00-luabind.lua`: A utility script that prints information about the available Lua classes and their properties and methods.
*   `01-callback.lua`: This script demonstrates the use of BPP's callback functions, such as `preStart`, `preSim`, and `onCommand`.
*   `01-math.lua`: A simple example that uses Lua's built-in `math` library to arrange spheres in a circle.
*   `01-module.lua`: A basic demonstration of how to load and use Lua modules within BPP.
*   `02-mesh.lua`: This script shows how to load and simulate 3D mesh files in various formats like `.3ds` and `.stl`.
*   `02-scad.lua`: An example of how to use OpenSCAD to create and simulate 3D models within BPP.
*   `02-trimesh.lua`: A demonstration of creating and simulating a `btTriangleMesh`, which is a more complex type of 3D shape.
*   `03-trans.lua`: This script showcases the `trans.lua` utility library for performing transformations like rotation and translation on objects.
*   `04-dice.lua`: A fun example that simulates rolling dice.
*   `04-domino.lua`: A classic physics simulation of a chain of falling dominos.
*   `05-input-joystick.lua`: This script demonstrates how to capture and respond to joystick input.

## How to Run

You can run these examples by passing the Lua script to the `bpp` executable. For example:

```bash
release/bpp -f demo/basic/00-hello.lua
```

Some scripts may have additional instructions in their comments on how to run them with different options.
