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

## Download

Release builds are attached to each [release](https://github.com/bullet-physics-playground/bpp/releases).
The macOS disk images bundle their Homebrew dependencies, so each one requires
at least the macOS version its build machine used:

| Disk image | Requires |
| --- | --- |
| `bpp-<version>-macos-arm64.dmg` (Apple Silicon) | macOS 14 or later |
| `bpp-<version>-macos-x86_64.dmg` (Intel) | macOS 15 or later |

On an older macOS, build from source instead.

## Build

Select your operating system:

 * [Build on Linux](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Linux)
 * [Build on Windows](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Windows)
 * [Build on Mac OS-X](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Mac-OS-X)

### Optional: embedded POV-Ray VFE rendering (experimental)

By default, F6 quick-render shells out to an external `povray`/`pvengine`
executable, same as it always has. There is an experimental alternative
build flag, `USE_VFE`, that instead embeds POV-Ray's own VFE (Virtual Front
End) API directly into bpp, so F6 renders in-process with a live pixel
preview inside the 3D view, and a real cancel (Esc) instead of only killing
a subprocess.

`USE_VFE` defaults to `0` (off) and building bpp normally is unaffected by
it either way. Turning it on requires a sibling
[POV-Ray source checkout](https://github.com/POV-Ray/povray) and a prebuilt
static library — see [`povray-mingw/README.md`](povray-mingw/README.md)
(Windows/MSYS2 MinGW-w64) or [`povray-linux/README.md`](povray-linux/README.md)
(Linux) for the full build steps. Once that's in place:

```bash
qmake "USE_VFE=1" bpp.pro
```

This is a prototype, and statically linking POV-Ray's AGPLv3-licensed core
into bpp's AGPLv3 binary means the resulting binary is bound by AGPLv3
obligations — worth deciding deliberately before shipping a
`USE_VFE=1` build beyond a local build.

The Linux build has been verified end-to-end (builds, links, and renders via
F6 without crashing); see [`povray-linux/README.md`](povray-linux/README.md)
for the gotchas that took to get there. The Windows/MSYS2 path is untested
beyond compiling — see [`povray-mingw/README.md`](povray-mingw/README.md).

## Docker

The [`Dockerfile`](Dockerfile) packages bpp as a headless worker for running on
a server or a Kubernetes cluster ([Talos Linux](https://www.talos.dev/)
included). It needs no display: it runs a Lua script and, with `-e`, exports
the frames as POV-Ray scenes for a renderer such as
[povomatic](#distributed-rendering-with-povomatic). The image ships the demos
under `/usr/share/bpp/demo`, plus OpenSCAD and POV-Ray.

```bash
mkdir -p out
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD/out:/work" koppi/bpp \
    -n 278 -e -f /usr/share/bpp/demo/basic/00-hello.lua   # writes out/export/00-hello/
```

Arguments are the [command-line](#command-line) ones, and without any the image
prints `--help`. To run your own script, mount it and pass its path. The
container runs as the unprivileged uid 10001 and `/work` is its working
directory and home, where the export (`/work/export`) and bpp's settings and
cache go. That is the only place it writes, so it also runs with a read-only
root filesystem and all capabilities dropped. `/work` must be writable by the
container's user: hence `--user` above, or `fsGroup` on a Kubernetes volume.

A headless `-f` run starts in the container's working directory, not in the
script's folder, so a script that loads files lying next to it (the meshes of
the [Dzhanibekov demo](demo/WyomingWill/Dzhanibekov), say) fails with
`... not found` unless its folder is the working directory. Without `-e`, set
that with `-w`, which is `workingDir` in a Kubernetes container:

```bash
docker run --rm -w /usr/share/bpp/demo/WyomingWill/Dzhanibekov koppi/bpp \
    -n 100 -f dzhanibekov.lua
```

An export is written to `export/` below the working directory, which has to be
writable, and the installed demos are not. So with `-e`, mount the script's
folder (or a copy of it) as `/work` instead:

```bash
docker run --rm --user "$(id -u):$(id -g)" \
    -v "$PWD/demo/WyomingWill/Dzhanibekov:/work" koppi/bpp \
    -n 278 -e -f dzhanibekov.lua      # writes demo/WyomingWill/Dzhanibekov/export/
```

On Kubernetes, a Job that runs under the *restricted* Pod Security profile:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: bpp-hello
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      securityContext:
        runAsNonRoot: true
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: bpp
          image: koppi/bpp:latest
          args: ["-n", "278", "-e", "-f", "/usr/share/bpp/demo/basic/00-hello.lua"]
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: work
              mountPath: /work
      volumes:
        - name: work
          emptyDir: {}   # use a PersistentVolumeClaim to keep the export
```

The published image is `linux/amd64`. To build it yourself, for example for
another architecture, run `docker build -t koppi/bpp .`: a first stage builds
the Debian package from [`debian/`](debian), the way the release workflow
does, and the runtime image installs it.

## Usage

### GUI

#### Menu shortcuts

These work anywhere in the main window (including while editing the Lua
script):

*   **Ctrl+N:** New file.
*   **Ctrl+O:** Open file.
*   **Ctrl+S:** Save file.
*   **Ctrl+A:** Save file as.
*   **Ctrl+Q:** Exit.
*   **F12:** Preferences.
*   **Ctrl+C:** Start/pause the physics simulation.
*   **Ctrl+R:** Restart the simulation.
*   **F6:** Quick render current frame with POV-Ray (or in-process via the
    experimental embedded VFE API, if enabled — see
    [Optional: embedded POV-Ray VFE rendering](#optional-embedded-pov-ray-vfe-rendering-experimental-windows-only)
    above).
*   **F11:** Toggle full screen.

#### 3D view shortcuts

These require the 3D view to have keyboard focus:

*   **S:** Start/stop the physics simulation.
*   **P:** Toggle POV-Ray export mode.
*   **G:** Toggle PNG screenshot saving mode.
*   **A:** Toggle display of the world axis.
*   **F:** Toggle FPS display.
*   **Enter:** Start/stop the animation.
*   **Space:** Toggle between fly and revolve camera modes; while an
    embedded VFE render (see above) is in progress, pauses/resumes it
    instead.
*   **Esc:** Cancel an in-progress embedded VFE render.
*   **Arrow Keys:** Move the camera.
*   **Tab:** Toggle between the single perspective view and a 4-view
    CAD-style layout (perspective, top, front, right). Scroll to zoom and
    drag to pan in the top/front/right views.
*   **H:** Show the QGLViewer help window.

### Command-Line

The command-line interface allows you to run simulations without the GUI. For
example, you can pipe the simulation data to `gnuplot` to visualize the results:

```bash
bpp -n 200 -f demo/basic/01-hello-cmdline.lua | \
    gnuplot -e "set terminal dumb; plot for[col=3:3] '/dev/stdin' using 1:col title columnheader(col) with lines"
```

### Distributed rendering with povomatic

[povomatic](https://github.com/koppi/povomatic) renders a POV-Ray animation
across a Kubernetes cluster, one job per frame. To send it a bpp scene, export
the frames and submit from the export directory:

```bash
bpp -f demo/basic/00-hello.lua -n 278 -e       # writes export/00-hello/
make -C export/00-hello povomatic              # rsync + submit via povomatic.py
```

`make povomatic` runs [`scripts/povomatic-job.py`](scripts/povomatic-job.py),
which copies `includes/` **and POV-Ray's own standard includes** (`colors.inc`
etc., which `settings.inc` pulls in and the render image does not ship) to
povomatic's shared asset volume, copies the exported scene to its input volume,
and calls `povomatic.py` with the frame count and clock range read from the
generated `.ini` (bpp exports each frame so that POV-Ray's `clock` equals the
frame number). Pass extra options through
`POVOMATIC_ARGS`, e.g. `make -C export/00-hello povomatic POVOMATIC_ARGS="--res 1080p --priority 5"`;
run `scripts/povomatic-job.py --help` for the full list. The API URL comes from
`$POVOMATIC_API` (or `--api-url`); `$POVOMATIC_INPUT`, `$POVOMATIC_ASSETS`,
`$POVOMATIC_REMOTE_INPUT` and `$POVRAY_INCLUDE_DIR` override the volume and
include paths.

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
[GNU Affero General Public License v3](LICENSE). Bundled third-party content
retains its own license as noted above.
