"""Checks for a family-0 genome: counts on levels 5-7, exact lever floor, printed hulls with slips.
  python3 check0.py GENOME.npy ..."""
import os, sys, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../monostable-search')); sys.path.insert(0, os.path.join(HERE, '../mono-e2/scripts'))
sys.path.insert(0, HERE)
import edged, prescreen, search0
from sphere_metrics import Body

for fn in sys.argv[1:]:
    a = np.load(fn); print(os.path.basename(fn))
    for lev in (5, 6, 7): print('  ' + edged.report(a, 3, 4, lev)[3])
    lv, tilt, rr = search0.face_lever(a, 7); far = tilt > 25; k = np.argmin(np.where(far, lv, np.inf))
    print(f'  max/min radius {rr:.3f}; exact lever beyond 25 deg: min {0.4 * lv[k]:.3f} mm at 36, at {tilt[k]:.0f} deg')
    B = Body(edged.body(a, 3, 4, 6)['X'], 6)
    print(f'  rest-top angle {np.degrees(np.arccos(B.rest @ B.top)):.0f} deg; rest {B.h.min():.2f}, top {B.h.max():.2f} mm at 90')
    P = B.P * 90.0 / np.ptp(B.P, 0).max(); hv = prescreen.layered(prescreen.to_frame(P))
    for c in ('al', 'sy', 'sz'):
        Pp = prescreen.prep(prescreen.printed(hv, c) / 0.4); er = prescreen.extra_rests(Pp)
        where = [f'{d * 1000:.0f} um at {np.degrees(np.arccos(Pp["n"][i] @ Pp["down"])):.0f} deg'
                 for i in np.where(Pp['rest'] > 0.002)[0] for d in [Pp['rest'][i]]]
        print(f'  {c}: extra rests {where or "none"}; stall at mu 0.05/0.15: '
              + '/'.join(f'{100 * x:.1f}%' for x in prescreen.stall(Pp, (0.05, 0.15))), flush=True)
