# port.py: lifts bead-bed.c's physics into a C++ class (DemCore), bodies
# unchanged: its globals become members, its functions member functions,
# its printf()s the test output. Writes members.inc, defs.inc and
# defines.inc here; gen.py then puts them into src/demcore.h and
# src/demcore.cpp with the hand-written parts (demcore.h.in, demcore.cpp.in:
# the frame loop, the API). From this folder:
#   python3 port.py ../bead-bed.c && python3 gen.py ../../../../..
import re, sys
src = open(sys.argv[1]).read().split('\n')
L = lambda a, b: src[a - 1:b]          # 1-based inclusive
FREE = {'dot', 'cross', 'collide_e', 'damping_for', 'hash01'}
members, defs, defines = [], [], []
def take(lines):
    i = 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith('#define') and not ln.startswith('#define ACC'):
            defines.append(ln); i += 1; continue
        m = re.match(r'static (const )?(int|double|char|unsigned|void|Hist)\b(.*)$', ln)
        if m:
            # a function? (a '(' before any '=' or ';' and then a body)
            fm = re.match(r'static (double|void|int)\s*\*?\s*(\w+)\(', ln)
            if fm:
                name = fm.group(2)
                # its whole signature, up to the line that ends with ')' or '{'
                sig = [ln]
                while not (sig[-1].rstrip().endswith(')') or sig[-1].rstrip().endswith('}') or sig[-1].rstrip().endswith(';')):
                    i += 1; sig.append(lines[i])
                if sig[-1].rstrip().endswith(';'):        # a forward declaration: drop
                    i += 1; continue
                if name in FREE:
                    defs.extend(sig)
                else:
                    first = re.sub(r'^static (double|void|int)(\s*\*?\s*)(\w+)\(', lambda q: q.group(1) + q.group(2) + 'DemCore::' + q.group(3) + '(', sig[0])
                    proto = [re.sub(r'^static ', '  ', sig[0])] + ['  ' + s for s in sig[1:]]
                    p = '\n'.join(proto)
                    if p.rstrip().endswith('}'):          # a one-line body: declare only the signature
                        p = p[:p.index('{')].rstrip() + ';'
                    else:
                        p += ';'
                    members.append(p)
                    defs.append('\n'.join([first] + sig[1:]))
                i += 1; continue
            members.append('  ' + ln[len('static '):]); i += 1; continue
        defs.append(ln); i += 1
take(L(155, 603))
take(L(627, 790))
out = '\n'.join(defs)
# tests: printf -> out(); the two exits -> a message and return
out = re.sub(r'\{ fprintf\(stderr, ("[^"]*")\); exit\(1\); \}', r'{ out(\1); return; }', out)
out = re.sub(r'\bprintf\(', 'out(', out)
open('members.inc', 'w').write('\n'.join(members) + '\n')
open('defs.inc', 'w').write(out + '\n')
open('defines.inc', 'w').write('\n'.join(defines) + '\n')
