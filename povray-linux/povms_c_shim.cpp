// qmake derives object file names from the source basename, and
// source/povms/povms.c and source/povms/povms.cpp share the basename
// "povms" -- qmake silently drops one of the two SOURCES entries instead
// of erroring, which left povms.c's symbols out of the archive. This shim
// gives povms.c a distinct basename so both get built and linked.
//
// It also has to be a .cpp, not a .c: configpovms.h #errors if povms.c is
// compiled by a C compiler ("povms.c must be compiled as a C++ file when
// used as part of the POV-Ray project") -- the real POV-Ray build always
// compiles it as C++ despite the .c extension.
#include "../../povray/source/povms/povms.c"
