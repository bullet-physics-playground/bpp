# BPP Basic Demos

This directory contains a collection of basic examples for the Bullet Physics Playground (BPP).

## File Descriptions

*   `00-hello.lua`: A comprehensive demonstration of various BPP features, including different shapes, lighting, and advanced POV-Ray settings.
*   `01-hello-cmdline.lua`: A simple script showing a sphere dropping onto a plane. This example is designed to be run from the command line and can be used to plot the sphere's trajectory.
*   `02-luabind.lua`: A utility script that prints information about the available Lua classes and their properties and methods.
*   `03-callback.lua`: This script demonstrates the use of BPP's callback functions, such as `preStart`, `preSim`, and `onCommand`.
*   `04-math.lua`: A simple example that uses Lua's built-in `math` library to arrange spheres in a circle.
*   `05-module.lua`: A basic demonstration of how to load and use Lua modules within BPP.
*   `06-mesh.lua`: This script shows how to load and simulate 3D mesh files in various formats like `.3ds` and `.stl`.
*   `07-scad.lua`: An example of how to use OpenSCAD to create and simulate 3D models within BPP.
*   `08-trimesh.lua`: A demonstration of creating and simulating a `btTriangleMesh`, which is a more complex type of 3D shape.
*   `09-trans.lua`: This script showcases the `trans.lua` utility library for performing transformations like rotation and translation on objects.
*   `10-dice.lua`: A fun example that simulates rolling dice.
*   `11-domino.lua`: A classic physics simulation of a chain of falling dominos.
*   `12-input-joystick.lua`: This script demonstrates how to capture and respond to joystick input.
*   `13-pyramid.lua`: A demo that creates tetrahedra and square-based pyramids as compound rigid bodies.
*   `14-spline-flythrough.lua`: A demo that animates the camera along a spline path, tracking different objects.
*   `15-space-navigator.lua`: This script demonstrates how to capture and respond to SpaceNavigator 3D mouse input. Without a registered callback the 3D mouse navigates the camera: X/Y/Z push translates (X strafes right, Y moves along the view direction, Z moves up/down) and RX/RY/RZ rotates, in both Fly (first-person) and Object (orbit) modes. Navigation is configurable via the SpaceNavigator page of the Preferences dialog (Fly/Object mode, lock horizon, auto fly speed, show orbit axis, forward/back direction, pan) and via the `v.snMode`, `v.snLockHorizon`, `v.snAutoFlySpeed`, `v.snShowOrbitAxis`, `v.snZoomForward` and `v.snPanZoom` Lua properties.
*   `16-softbody.lua`: This demo shows the basic usage of the `SoftBody` class (a Bullet cloth patch): a cloth sheet dropped onto a static box and the ground so it drapes and deforms, plus a smaller patch pinned along one edge and blown by a constant wind force to make a waving flag.

## How to Run

You can run these examples by passing the Lua script to the `bpp` executable. For example:

```bash
bpp -f demo/basic/00-hello.lua
```

Some scripts may have additional instructions in their comments on how to run them with different options.
