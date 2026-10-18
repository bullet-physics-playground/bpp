# gen.py: writes src/demcore.h and src/demcore.cpp from bead-bed.c (via
# port.py's members.inc / defs.inc) and the hand-written templates.
#   python3 gen.py <the repository's top folder>
import re, sys
up = sys.argv[1]
mem = open('members.inc').read()
for a, b in [('MAXB', 'DEM_MAXB'), ('NCXMAX', 'DEM_NCXMAX'), ('NCY', 'DEM_NCY'), ('MAXG', 'DEM_MAXG')]:
    mem = re.sub(r'\b' + a + r'\b', b, mem)
h = open('demcore.h.in').read()
h = h.replace('#include "demcore-members.inc"\n', '  // (lifted from bead-bed.c)\n' + mem)
open(up + '/src/demcore.h', 'w').write(h)
c = open('demcore.cpp.in').read().replace('@@DEFS@@\n', open('defs.inc').read())
open(up + '/src/demcore.cpp', 'w').write(c)
