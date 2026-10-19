"""Stock weights (nominal masses from density x volume unless a vendor mass is given;
WEIGH THEM: real alloys vary). Sources in the build guide."""
import numpy as np
from w37 import Weight
IN = 25.4
def ball(name, d, rho, **kw): return Weight(name, 'sphere', [d], rho * np.pi * d ** 3 / 6 / 1000, **kw)
CAT = {
 # tungsten
 'W-cube-1/4':   Weight('W-cube-1/4', 'cube', [0.25 * IN], 4.72),   # pinewood-derby 1/4" cube: 2 oz / 12 = 4.72 g (=> 18.4 g/cm3 alloy)
 'W-cyl-3/8x.44': Weight('W-cyl-3/8x.44', 'cyl', [0.375 * IN, 0.44 * IN], 14.17),  # pinewood-derby 3/8" cylinder, 0.5 oz (vendor), 0.44" long
 'W-ball-10':    ball('W-ball-10', 10.0, 18.0),                     # tungsten heavy alloy (W-Ni-Fe ~18.0), 9.42 g
 'W-ball-12':    ball('W-ball-12', 12.0, 18.0),                     # 16.29 g
 'WC-ball-1/2':  ball('WC-ball-1/2', 0.5 * IN, 15.63),              # tungsten carbide, 16.8 g
 'WC-ball-3/8':  ball('WC-ball-3/8', 0.375 * IN, 15.63),            # tungsten-carbide bearing ball, 7.08 g
 'WC-ball-5/16': ball('WC-ball-5/16', 0.3125 * IN, 15.63),          # 4.10 g
 # steel bearing balls (AISI 52100 / chrome steel, 7.83 g/cm3)
 'St-ball-3/8':  ball('St-ball-3/8', 0.375 * IN, 7.83),             # 3.53 g
 'St-ball-7/16': ball('St-ball-7/16', 0.4375 * IN, 7.83),           # 5.60 g
 'St-ball-1/2':  ball('St-ball-1/2', 0.5 * IN, 7.83),               # 8.36 g
 'St-ball-9/16': ball('St-ball-9/16', 0.5625 * IN, 7.83),           # 11.9 g
 'St-ball-5/8':  ball('St-ball-5/8', 0.625 * IN, 7.83),             # 16.3 g
 'St-ball-11/16': ball('St-ball-11/16', 0.6875 * IN, 7.83),        # 21.8 g
 'St-ball-3/4':  ball('St-ball-3/4', 0.75 * IN, 7.83),              # 28.2 g
 'St-ball-12':   ball('St-ball-12', 12.0, 7.83),                    # 7.08 g
 'St-ball-14':   ball('St-ball-14', 14.0, 7.83),                    # 11.25 g
 # pure lead swaged round balls (muzzleloader), 11.34 g/cm3: .440" = 128 gr as sold
 'Pb-ball-.375': ball('Pb-ball-.375', 0.375 * IN, 11.34),           # 5.12 g
 'Pb-ball-.440': ball('Pb-ball-.440', 0.440 * IN, 11.34),           # 8.29 g
 'Pb-ball-.490': ball('Pb-ball-.490', 0.490 * IN, 11.34),           # 11.45 g
 'Pb-ball-.535': ball('Pb-ball-.535', 0.535 * IN, 11.34),           # 14.9 g (230 gr)
 'Pb-ball-.570': ball('Pb-ball-.570', 0.570 * IN, 11.34),           # 18.0 g (278 gr)
 # cylinders (axis vertical in the pocket)
 'St-dowel-10x16': Weight('St-dowel-10x16', 'cyl', [10.0, 16.0], 7.85 * np.pi * 25 * 16 / 1000),   # hardened steel dowel pin ISO 8734/DIN 6325, 9.86 g
 'St-dowel-10x20': Weight('St-dowel-10x20', 'cyl', [10.0, 20.0], 7.85 * np.pi * 25 * 20 / 1000),   # 12.33 g
 'St-dowel-10x24': Weight('St-dowel-10x24', 'cyl', [10.0, 24.0], 7.85 * np.pi * 25 * 24 / 1000),   # 14.80 g
 'St-dowel-8x24': Weight('St-dowel-8x24', 'cyl', [8.0, 24.0], 7.85 * np.pi * 16 * 24 / 1000),     # 9.47 g
 'Pb-cyl-3/8x.6': Weight('Pb-cyl-3/8x.6', 'cyl', [0.375 * IN, 0.6 * IN], 11.34 * np.pi * (0.375 * IN) ** 2 / 4 * 0.6 * IN / 1000),  # cut from 3/8" lead rod, 12.1 g
 'Wputty-cyl-10x12': Weight('Wputty-cyl-10x12', 'cyl', [10.0, 12.0], 10.5 * np.pi * 25 * 12 / 1000, clr=0.0),  # tungsten putty pressed into the pocket, ~10.5 g/cm3: 9.9 g
 'Bi-cyl-10x12': Weight('Bi-cyl-10x12', 'cyl', [10.0, 12.0], 9.78 * np.pi * 25 * 12 / 1000),   # bismuth cast/cut cylinder 10 x 12 mm, 9.22 g
 # brass balls 8.5
 'Br-ball-1/2':  ball('Br-ball-1/2', 0.5 * IN, 8.5),                # 9.08 g
}
if __name__ == "__main__":
    for k, w in CAT.items(): print(f"{k:14s} {w.kind:6s} {w.dims[0]:6.2f} mm  {w.m:6.2f} g  pocket a {w.a:.2f} L {w.L:.2f}")
