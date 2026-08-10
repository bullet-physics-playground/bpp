# The Bullet Physics Playground

A simple physics simulation software for prototyping and experimenting with the
[Bullet Physics](http://bulletphysics.org) library. It provides a graphical user
interface (GUI) for real-time interaction and a command-line interface (CLI) for
batch processing and scripting.

![GitHub last commit](https://img.shields.io/github/last-commit/bullet-physics-playground/bpp)
![GitHub commit activity](https://img.shields.io/github/commit-activity/w/bullet-physics-playground/bpp)
[![GitHub issues](https://img.shields.io/github/issues/bullet-physics-playground/bpp)](https://github.com/bullet-physics-playground/bpp/issues)

## Features

*   **Physics Simulation:** Powered by the robust and widely-used Bullet
    Physics library.
*   **Cross-Platform:** Builds and runs on Linux, Windows, and macOS.
*   **GUI:** An OpenGL-based GUI for visualizing and interacting with the
    simulations in real-time.
*   **Scripting:** Extend and control simulations using Lua scripting.
*   **Import/Export:**
    *   Import models from [OpenSCAD](http://www.openscad.org/).
    *   Export scenes to [POV-Ray](http://www.povray.org/) for high-quality
        rendering.
*   **Command-Line Interface:** A powerful CLI for running simulations, rendering
    animations, and piping data to other tools like
    [gnuplot](http://www.gnuplot.info/).

## Videos on YouTube

<a href="https://www.youtube.com/watch?v=RwMhyvVPsQI&list=PL-OhsevLGGI2bFpOqzqnWsGILh9a5YkDr" target="_blank"><img src="http://img.youtube.com/vi/RwMhyvVPsQI/maxresdefault.jpg" alt="Bullet Physics Playground" width="640" border="10" /></a>

## Build

Select your operating system:

 * [Build on Linux](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Linux)
 * [Build on Windows](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Windows)
 * [Build on Mac OS-X](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Mac-OS-X)

## Usage

### GUI

*   **S:** Start/stop the physics simulation.
*   **P:** Toggle POV-Ray export mode.
*   **G:** Toggle PNG screenshot saving mode.
*   **A:** Toggle display of the world axis.
*   **F:** Toggle FPS display.
*   **Enter:** Start/stop the animation.
*   **Space:** Toggle between fly and revolve camera modes.
*   **Arrow Keys:** Move the camera.
*   **H:** Show the QGLViewer help window.

### Command-Line

The command-line interface allows you to run simulations without the GUI. For
example, you can pipe the simulation data to `gnuplot` to visualize the results:

```bash
bpp -n 200 -f demo/basic/01-hello-cmdline.lua | \
    gnuplot -e "set terminal dumb; plot for[col=3:3] '/dev/stdin' using 1:col title columnheader(col) with lines"
```

## Documentation / Wiki

* [Basic Usage HOWTO](https://github.com/bullet-physics-playground/bpp/wiki/Basic-Usage-HOWTO)
* [LUA Bindings Reference](https://github.com/bullet-physics-playground/bpp/wiki/LUA-Bindings-Reference)

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an
issue on the [GitHub repository](https://github.com/bullet-physics-playground/bpp).

## Contributions

### People

*   **Jakob Flierl** – [koppi](https://github.com/koppi) – Creator and
    primary maintainer since 2011.
*   **Jaime Vives Piqueres** – [jaimevives](https://github.com/jaimevives) –
    POV-Ray export, the [Citroën GS](demo/jaimevives) and
    [box-with-oranges](includes/README.md) demo scenes, and his
    [latest computer generated images](http://www.ignorancia.org/index.php?page=latest-images).
*   **WyomingWill** – the [Chebyshev four-bar linkage walker
    demos](demo/WyomingWill).
*   Demos in [`demo/claude`](demo/claude) and select other scripts were
    developed with the assistance of
    [Claude Code](https://claude.com/claude-code).

### Bundled third-party content

The [`includes/`](includes/) directory bundles POV-Ray assets and lighting
macros from other authors, each under its own terms; see
[includes/README.md](includes/README.md) for full details.

| Content | Author(s) | License |
| --- | --- | --- |
| [LightSys 4](includes/readme_lightsys.txt) lighting macros | Jaime Vives Piqueres, with Ive and Philippe Debar | not stated in-repo; used with attribution |
| [CIE XYZ color model](includes/readme_cie.txt) | Ive | not stated in-repo; used with attribution |
| [Skylight model](includes/readme_skylight.txt) | Philippe Debar, adapted by Ive | not stated in-repo; used with attribution |
| [Studio Lighting Kit](includes/studio-light-readme.txt) | Jaime Vives Piqueres | not stated in-repo; used with attribution |
| Box-of-oranges scene | Jaime Vives Piqueres | [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0) |
| Citroën GS car model | Jaime Vives Piqueres | [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0) |
| Nissan Micra K11 car model | Rene Bui | [CC BY-NC 3.0](http://creativecommons.org/licenses/by-nc/3.0/) |
| Dice model | found on Wikipedia | [Public Domain](https://creativecommons.org/publicdomain/zero/1.0/) |
| Humanity icon theme | Canonical / Ubuntu | not stated in-repo; used with attribution |

A few other bundled POV-Ray assets (e.g. the LEGO buggy, Wunderbaum, and
cajón meshes under `includes/`) carry no attribution or license information
in this repository.

## License

The Bullet Physics Playground itself is licensed under the
[GNU Lesser General Public License](LICENSE). Bundled third-party content
retains its own license as noted above.
