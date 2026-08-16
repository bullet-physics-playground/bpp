# POV-Ray core + VFE, built as a single static library under MSYS2 MinGW-w64.
#
# Prototype build glue for embedding POV-Ray's VFE (Virtual Front End) API
# into bpp instead of shelling out to the povray executable. See
# povray-mingw/README.md for the full build steps.
#
# There is no upstream MinGW/qmake build of POV-Ray; this project reuses the
# exact source file lists from windows/vs2015/{povbase,povcore,povbackend,
# povfrontend,povms,povparser,povvm,povplatform,vfewin}.vcxproj, minus the
# per-module precomp.cpp PCH stubs (not needed under GCC) and platform/x86/*
# (AVX/FMA hand-optimized noise, excluded via not defining TRY_OPTIMIZED_NOISE*
# in windows/povconfig/syspovconfig_mingw32.h) and source/povmain.cpp (that's
# console/GUI main(), not needed here).
#
# Built as one combined archive rather than mirroring the core/vfe project
# split: core and vfe are circularly dependent (see unix/prebuild.sh), and a
# single archive sidesteps GNU ar/ld link-order problems entirely.

TEMPLATE = lib
CONFIG += staticlib c++11 warn_off
CONFIG -= qt
TARGET = povvfe

DEFINES += _CONSOLE OPENEXR_MISSING BUILDING_AMD64
DEFINES += BUILT_BY=\\\"bpp-povvfe-prototype\\\"
DEFINES += BOOST_BIND_GLOBAL_PLACEHOLDERS
# POV-Ray's Windows platform code (vfe/win/vfeplatform.cpp) is written against
# the ANSI (char*) Win32 API, but qmake's win32-g++ mkspec defines UNICODE/
# _UNICODE by default, which flips GetTempPath/CreateDirectory/etc to their
# wide-string (...W) variants and breaks char*-vs-LPCWSTR overload resolution.
DEFINES -= UNICODE _UNICODE

POVRAY = $$PWD/../../povray

INCLUDEPATH += \
    $$POVRAY/source \
    $$POVRAY/vfe \
    $$POVRAY/vfe/win \
    $$POVRAY/platform/windows \
    $$POVRAY/platform \
    $$POVRAY/windows/povconfig

CONFIG += link_pkgconfig
PKGCONFIG += zlib libpng libjpeg libtiff-4

QMAKE_CXXFLAGS += -std=gnu++11

LIBS += -lole32

SOURCES += \
    $$POVRAY/platform/windows/osversioninfo.cpp \
    $$POVRAY/platform/windows/syspovfilesystem.cpp \
    $$POVRAY/platform/windows/syspovpath.cpp \
    $$POVRAY/platform/windows/syspovtask.cpp \
    $$POVRAY/platform/windows/syspovtimer.cpp \
    $$POVRAY/source/backend/bounding/boundingtask.cpp \
    $$POVRAY/source/backend/control/benchmark.cpp \
    $$POVRAY/source/backend/control/benchmark_ini.cpp \
    $$POVRAY/source/backend/control/benchmark_pov.cpp \
    $$POVRAY/source/backend/control/messagefactory.cpp \
    $$POVRAY/source/backend/control/parsertask.cpp \
    $$POVRAY/source/backend/control/renderbackend.cpp \
    $$POVRAY/source/backend/control/scene.cpp \
    $$POVRAY/source/backend/lighting/photonestimationtask.cpp \
    $$POVRAY/source/backend/lighting/photonshootingstrategy.cpp \
    $$POVRAY/source/backend/lighting/photonshootingtask.cpp \
    $$POVRAY/source/backend/lighting/photonsortingtask.cpp \
    $$POVRAY/source/backend/lighting/photonstrategytask.cpp \
    $$POVRAY/source/backend/povray.cpp \
    $$POVRAY/source/backend/render/radiositytask.cpp \
    $$POVRAY/source/backend/render/rendertask.cpp \
    $$POVRAY/source/backend/render/tracetask.cpp \
    $$POVRAY/source/backend/scene/backendscenedata.cpp \
    $$POVRAY/source/backend/scene/view.cpp \
    $$POVRAY/source/backend/scene/viewthreaddata.cpp \
    $$POVRAY/source/backend/support/task.cpp \
    $$POVRAY/source/backend/support/taskqueue.cpp \
    $$POVRAY/source/base/animation/animation.cpp \
    $$POVRAY/source/base/animation/moov.cpp \
    $$POVRAY/source/base/colour.cpp \
    $$POVRAY/source/base/data/bluenoise64a.cpp \
    $$POVRAY/source/base/fileinputoutput.cpp \
    $$POVRAY/source/base/filesystem.cpp \
    $$POVRAY/source/base/fileutil.cpp \
    $$POVRAY/source/base/font/crystal.cpp \
    $$POVRAY/source/base/font/cyrvetic.cpp \
    $$POVRAY/source/base/font/povlogo.cpp \
    $$POVRAY/source/base/font/timrom.cpp \
    $$POVRAY/source/base/image/bmp.cpp \
    $$POVRAY/source/base/image/colourspace.cpp \
    $$POVRAY/source/base/image/dither.cpp \
    $$POVRAY/source/base/image/encoding.cpp \
    $$POVRAY/source/base/image/gif.cpp \
    $$POVRAY/source/base/image/gifdecod.cpp \
    $$POVRAY/source/base/image/hdr.cpp \
    $$POVRAY/source/base/image/iff.cpp \
    $$POVRAY/source/base/image/image.cpp \
    $$POVRAY/source/base/image/jpeg.cpp \
    $$POVRAY/source/base/image/metadata.cpp \
    $$POVRAY/source/base/image/openexr.cpp \
    $$POVRAY/source/base/image/png.cpp \
    $$POVRAY/source/base/image/ppm.cpp \
    $$POVRAY/source/base/image/targa.cpp \
    $$POVRAY/source/base/image/tiff.cpp \
    $$POVRAY/source/base/mathutil.cpp \
    $$POVRAY/source/base/messenger.cpp \
    $$POVRAY/source/base/path.cpp \
    $$POVRAY/source/base/platformbase.cpp \
    $$POVRAY/source/base/pov_err.cpp \
    $$POVRAY/source/base/pov_mem.cpp \
    $$POVRAY/source/base/stringutilities.cpp \
    $$POVRAY/source/base/textstream.cpp \
    $$POVRAY/source/base/textstreambuffer.cpp \
    $$POVRAY/source/base/timer.cpp \
    $$POVRAY/source/core/bounding/bounding.cpp \
    $$POVRAY/source/core/bounding/boundingbox.cpp \
    $$POVRAY/source/core/bounding/boundingcylinder.cpp \
    $$POVRAY/source/core/bounding/boundingsphere.cpp \
    $$POVRAY/source/core/bounding/bsptree.cpp \
    $$POVRAY/source/core/colour/spectral.cpp \
    $$POVRAY/source/core/lighting/lightgroup.cpp \
    $$POVRAY/source/core/lighting/lightsource.cpp \
    $$POVRAY/source/core/lighting/photons.cpp \
    $$POVRAY/source/core/lighting/radiosity.cpp \
    $$POVRAY/source/core/lighting/subsurface.cpp \
    $$POVRAY/source/core/material/blendmap.cpp \
    $$POVRAY/source/core/material/interior.cpp \
    $$POVRAY/source/core/material/media.cpp \
    $$POVRAY/source/core/material/noise.cpp \
    $$POVRAY/source/core/material/normal.cpp \
    $$POVRAY/source/core/material/pattern.cpp \
    $$POVRAY/source/core/material/pigment.cpp \
    $$POVRAY/source/core/material/portablenoise.cpp \
    $$POVRAY/source/core/material/texture.cpp \
    $$POVRAY/source/core/material/warp.cpp \
    $$POVRAY/source/core/math/chi2.cpp \
    $$POVRAY/source/core/math/hypercomplex.cpp \
    $$POVRAY/source/core/math/jitter.cpp \
    $$POVRAY/source/core/math/matrix.cpp \
    $$POVRAY/source/core/math/polynomialsolver.cpp \
    $$POVRAY/source/core/math/quaternion.cpp \
    $$POVRAY/source/core/math/randcosweighted.cpp \
    $$POVRAY/source/core/math/randomsequence.cpp \
    $$POVRAY/source/core/math/spline.cpp \
    $$POVRAY/source/core/math/vector.cpp \
    $$POVRAY/source/core/render/ray.cpp \
    $$POVRAY/source/core/render/trace.cpp \
    $$POVRAY/source/core/render/tracepixel.cpp \
    $$POVRAY/source/core/scene/atmosphere.cpp \
    $$POVRAY/source/core/scene/camera.cpp \
    $$POVRAY/source/core/scene/object.cpp \
    $$POVRAY/source/core/scene/scenedata.cpp \
    $$POVRAY/source/core/scene/tracethreaddata.cpp \
    $$POVRAY/source/core/shape/bezier.cpp \
    $$POVRAY/source/core/shape/blob.cpp \
    $$POVRAY/source/core/shape/box.cpp \
    $$POVRAY/source/core/shape/cone.cpp \
    $$POVRAY/source/core/shape/csg.cpp \
    $$POVRAY/source/core/shape/disc.cpp \
    $$POVRAY/source/core/shape/fractal.cpp \
    $$POVRAY/source/core/shape/heightfield.cpp \
    $$POVRAY/source/core/shape/isosurface.cpp \
    $$POVRAY/source/core/shape/lathe.cpp \
    $$POVRAY/source/core/shape/lemon.cpp \
    $$POVRAY/source/core/shape/mesh.cpp \
    $$POVRAY/source/core/shape/ovus.cpp \
    $$POVRAY/source/core/shape/parametric.cpp \
    $$POVRAY/source/core/shape/plane.cpp \
    $$POVRAY/source/core/shape/polygon.cpp \
    $$POVRAY/source/core/shape/polynomial.cpp \
    $$POVRAY/source/core/shape/prism.cpp \
    $$POVRAY/source/core/shape/quadric.cpp \
    $$POVRAY/source/core/shape/sor.cpp \
    $$POVRAY/source/core/shape/sphere.cpp \
    $$POVRAY/source/core/shape/spheresweep.cpp \
    $$POVRAY/source/core/shape/superellipsoid.cpp \
    $$POVRAY/source/core/shape/torus.cpp \
    $$POVRAY/source/core/shape/triangle.cpp \
    $$POVRAY/source/core/shape/truetype.cpp \
    $$POVRAY/source/core/support/cracklecache.cpp \
    $$POVRAY/source/core/support/imageutil.cpp \
    $$POVRAY/source/core/support/octree.cpp \
    $$POVRAY/source/core/support/statisticids.cpp \
    $$POVRAY/source/core/support/statistics.cpp \
    $$POVRAY/source/frontend/animationprocessing.cpp \
    $$POVRAY/source/frontend/console.cpp \
    $$POVRAY/source/frontend/display.cpp \
    $$POVRAY/source/frontend/filemessagehandler.cpp \
    $$POVRAY/source/frontend/imagemessagehandler.cpp \
    $$POVRAY/source/frontend/imageprocessing.cpp \
    $$POVRAY/source/frontend/parsermessagehandler.cpp \
    $$POVRAY/source/frontend/processoptions.cpp \
    $$POVRAY/source/frontend/processrenderoptions.cpp \
    $$POVRAY/source/frontend/renderfrontend.cpp \
    $$POVRAY/source/frontend/rendermessagehandler.cpp \
    $$POVRAY/source/frontend/shelloutprocessing.cpp \
    $$POVRAY/source/parser/fncode.cpp \
    $$POVRAY/source/parser/parser.cpp \
    $$POVRAY/source/parser/parser_expressions.cpp \
    $$POVRAY/source/parser/parser_functions.cpp \
    $$POVRAY/source/parser/parser_functions_utilities.cpp \
    $$POVRAY/source/parser/parser_materials.cpp \
    $$POVRAY/source/parser/parser_obj.cpp \
    $$POVRAY/source/parser/parser_strings.cpp \
    $$POVRAY/source/parser/parser_tokenizer.cpp \
    $$POVRAY/source/parser/parsertypes.cpp \
    $$POVRAY/source/parser/rawtokenizer.cpp \
    $$POVRAY/source/parser/reservedwords.cpp \
    $$POVRAY/source/parser/scanner.cpp \
    $$POVRAY/source/parser/symboltable.cpp \
    $$POVRAY/source/povms/povms.c \
    $$POVRAY/source/povms/povms.cpp \
    $$POVRAY/source/povms/povmscpp.cpp \
    $$POVRAY/source/povms/povmsutil.cpp \
    $$POVRAY/source/vm/fnintern.cpp \
    $$POVRAY/source/vm/fnpovfpu.cpp \
    $$POVRAY/vfe/vfe.cpp \
    $$POVRAY/vfe/vfecontrol.cpp \
    $$POVRAY/vfe/vfedisplay.cpp \
    $$POVRAY/vfe/vfepovms.cpp \
    $$POVRAY/vfe/vfesession.cpp \
    $$POVRAY/vfe/win/vfeplatform.cpp
