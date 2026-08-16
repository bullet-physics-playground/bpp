// qmake's SOURCES duplicate-object-name detection appears to match on
// basename suffix, not just exact basename: source/core/material/portablenoise.cpp
// and platform/x86/avx/avxportablenoise.cpp were treated as colliding (the
// latter's basename ends with the former's), and portablenoise.cpp was
// silently dropped from the generated Makefile entirely -- same class of
// bug as povms.c vs povms.cpp, see povms_c_shim.cpp. This shim gives
// portablenoise.cpp a non-colliding basename so it actually gets compiled.
#include "../../povray/source/core/material/portablenoise.cpp"
