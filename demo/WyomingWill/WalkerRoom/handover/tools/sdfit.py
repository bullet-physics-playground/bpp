import sys; sys.path.insert(0, "/home/claude/work")
import outz5
outz5.SWEEPS = __import__("os").environ.get("SW", "sweepSD")
import outz; outz.M = 0.4; outz5.M = 0.4
for b in ["Hoecken_slider_diag", "Hoecken-Spears_slider_diag"]:
    outz5.LETTERS[b] = float(sys.argv[1]) if len(sys.argv) > 1 else 1.51
    W, r = outz5.fit(b)
    c = r["checks"]
    print(f"\n== {W['name']}: body y {W['bb'][2]:.2f}..{W['bb'][3]:.2f}; lift top {r['lift']['top']:.2f} bottom {r['lift']['bottom']:.2f}")
    for nm in ("top", "bottom"):
        e = r[nm]; k = c[nm]
        print(f"  {nm}: pendants {k['length']:.2f} long, turn {k['turn']:.2f} deg, part {k['part']:.3f} cm; brace bottom {e['yb']:.2f} (pendant {e['pend_low'][0]:.2f}..{e['pend_top'][0]:.2f})")
        print("    ", (f"diag {e['best'][0]:.1f}: yRel {e['yRel']:.2f} runFront {e['runFront']:.2f} runBack {e['runBack']:.2f} toward {e['toward']}" if e['best'] else "NO diagonal fits"), "| straight", e["straight"])
