# syntax=docker/dockerfile:1

# Bullet Physics Playground as a headless batch worker for Kubernetes (Talos
# Linux included): runs a Lua simulation without a display and, with -e,
# exports the frames as POV-Ray scenes for a renderer such as povomatic.
#
#   docker build -t koppi/bpp .
#   docker run --rm -v "$PWD/out:/work" koppi/bpp \
#       -n 278 -e -f /usr/share/bpp/demo/basic/00-hello.lua
#
# The image runs as the unprivileged uid 10001 and needs no capabilities,
# host access or writable root filesystem. Mount a volume at /work for the
# output: bpp exports into ./export below its working directory, and HOME
# (where it keeps its settings) is /work as well.

# The package is built with the project's own debian/ packaging, as the
# release workflow does, so the runtime image gets exactly the dependencies
# dpkg-shlibdeps computes for it.
FROM debian:trixie AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential devscripts equivs debhelper ca-certificates

WORKDIR /src

# Build dependencies first, so this layer only changes with debian/control.
COPY debian/control debian/control
RUN mk-build-deps --install --remove \
      --tool "apt-get -y --no-install-recommends" debian/control \
 && rm -f bpp-build-deps_*

COPY . .
RUN DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -b -uc -us -d -j"$(nproc)"


FROM debian:trixie-slim

LABEL org.opencontainers.image.title="Bullet Physics Playground" \
      org.opencontainers.image.source="https://github.com/bullet-physics-playground/bpp"

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=build /bpp_*.deb /tmp/
# openscad and povray are the package's Recommends: OpenSCAD for the demos
# that build their meshes from it, POV-Ray (with the standard includes that
# settings.inc needs) for rendering an export in place.
RUN apt-get update \
 && apt-get install -y --no-install-recommends /tmp/bpp_*.deb \
      openscad povray povray-includes \
 && rm -rf /var/lib/apt/lists/* /tmp/bpp_*.deb

# A numeric USER lets the kubelet verify runAsNonRoot.
RUN useradd --uid 10001 --user-group --home-dir /work --no-create-home \
      --shell /usr/sbin/nologin bpp \
 && install -d -o bpp -g bpp /work

# A pod has no sound card. With SDL's dummy driver audio still initialises, so
# a script's loadSound/playSound keeps working and an export gets its .wav.
ENV HOME=/work SDL_AUDIODRIVER=dummy
WORKDIR /work
USER 10001:10001

ENTRYPOINT ["bpp"]
CMD ["--help"]
