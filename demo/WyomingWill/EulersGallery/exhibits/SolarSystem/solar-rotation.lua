--
-- How the Sun, the planets, Pluto and the moons turn: the IAU Working
-- Group on Cartographic Coordinates and Rotational Elements' models
-- (Archinal et al. 2018, "Report of the IAU WGCCRE: 2015", Celest. Mech.
-- Dyn. Astr. 130:22; Mars and its moons, and the Moon's terms, from the
-- 2009 report, Celest. Mech. Dyn. Astr. 109:101, as the engine's Mars is).
--
-- Each body's north pole is at right ascension a0 and declination d0 (in
-- the ICRF), and its prime meridian is W degrees round from where its
-- equator crosses the ICRF's, eastward along it. d is days from J2000
-- (JD 2451545.0, TDB), T Julian centuries. Only the main periodic terms
-- are kept (the Moon's libration's, Neptune's and Triton's precession);
-- the rest are below a tenth of a degree.
--
-- rotation(name, jd) returns the body's axes in the ICRF: its prime
-- meridian on its equator, 90 degrees east of that, and its north pole,
-- as three unit vectors; or nil for a body with no model here.
--

local rad, sin, cos = math.rad, math.sin, math.cos

local function E(d)                        -- the Moon's arguments (degrees)
  return {
    125.045 - 0.0529921 * d, 250.089 - 0.1059842 * d, 260.008 + 13.0120009 * d,
    176.625 + 13.3407154 * d, 357.529 + 0.9856003 * d, 311.589 + 26.4057084 * d,
    134.963 + 13.0649930 * d, 276.617 + 0.3287146 * d, 34.226 + 1.7484877 * d,
    15.134 - 0.1589763 * d, 119.743 + 0.0036096 * d, 239.961 + 0.1643573 * d,
    25.053 + 12.9590088 * d,
  }
end
local function sd(x) return sin(rad(x)) end
local function cd(x) return cos(rad(x)) end

-- each: function(d, T) -> a0, d0, W (degrees)
local M = {}
M.Sun = function(d, T) return 286.13, 63.87, 84.176 + 14.1844000 * d end
M.Mercury = function(d, T)
  local M1, M2, M3, M4, M5 = 174.7910857 + 4.092335 * d, 349.5821714 + 8.184670 * d, 164.3732571 + 12.277005 * d,
                             339.1643429 + 16.369340 * d, 153.9554286 + 20.461675 * d
  return 281.0103 - 0.0328 * T, 61.4155 - 0.0049 * T,
         329.5988 + 6.1385108 * d + 0.01067257 * sd(M1) - 0.00112309 * sd(M2) - 0.00011040 * sd(M3)
         - 0.00002539 * sd(M4) - 0.00000571 * sd(M5)
end
M.Venus = function(d, T) return 272.76, 67.16, 160.20 - 1.4813688 * d end
M.Earth = function(d, T) return 0.00 - 0.641 * T, 90.00 - 0.557 * T, 190.147 + 360.9856235 * d end
M.Moon = function(d, T)
  local e = E(d)
  local a0 = 269.9949 + 0.0031 * T - 3.8787 * sd(e[1]) - 0.1204 * sd(e[2]) + 0.0700 * sd(e[3]) - 0.0172 * sd(e[4])
             + 0.0072 * sd(e[6]) - 0.0052 * sd(e[10]) + 0.0043 * sd(e[13])
  local d0 = 66.5392 + 0.0130 * T + 1.5419 * cd(e[1]) + 0.0239 * cd(e[2]) - 0.0278 * cd(e[3]) + 0.0068 * cd(e[4])
             - 0.0029 * cd(e[6]) + 0.0009 * cd(e[7]) + 0.0008 * cd(e[10]) - 0.0009 * cd(e[13])
  local W = 38.3213 + 13.17635815 * d - 1.4e-12 * d * d + 3.5610 * sd(e[1]) + 0.1208 * sd(e[2]) - 0.0642 * sd(e[3])
            + 0.0158 * sd(e[4]) + 0.0252 * sd(e[5]) - 0.0066 * sd(e[6]) - 0.0047 * sd(e[7]) - 0.0046 * sd(e[8])
            + 0.0028 * sd(e[9]) + 0.0052 * sd(e[10]) + 0.0040 * sd(e[11]) + 0.0019 * sd(e[12]) - 0.0044 * sd(e[13])
  return a0, d0, W
end
M.Mars = function(d, T) return 317.68143 - 0.1061 * T, 52.88650 - 0.0609 * T, 176.630 + 350.89198226 * d end
M.Jupiter = function(d, T) return 268.056595 - 0.006499 * T, 64.495303 + 0.002413 * T, 284.95 + 870.5360000 * d end
M.Saturn = function(d, T) return 40.589 - 0.036 * T, 83.537 - 0.004 * T, 38.90 + 810.7939024 * d end
M.Uranus = function(d, T) return 257.311, -15.175, 203.81 - 501.1600928 * d end
M.Neptune = function(d, T)
  local N = 357.85 + 52.316 * T
  return 299.36 + 0.70 * sd(N), 43.46 - 0.51 * cd(N), 249.978 + 541.1397757 * d - 0.48 * sd(N)
end
M.Pluto = function(d, T) return 132.993, -6.163, 302.695 + 56.3625225 * d end
M.Charon = function(d, T) return 132.993, -6.163, 122.695 + 56.3625225 * d end
M.Phobos = function(d, T)
  local M1, M2, M3 = 169.51 - 0.4357640 * d, 192.93 + 1128.4096700 * d + 8.864 * T * T, 53.47 - 0.0181510 * d
  return 317.68 - 0.108 * T + 1.79 * sd(M1), 52.90 - 0.061 * T - 1.08 * cd(M1),
         35.06 + 1128.8445850 * d + 8.864 * T * T - 1.42 * sd(M1) - 0.78 * sd(M2)
end
M.Deimos = function(d, T)
  local M3 = 53.47 - 0.0181510 * d
  return 316.65 - 0.108 * T + 2.98 * sd(M3), 53.52 - 0.061 * T - 1.78 * cd(M3),
         79.41 + 285.1618970 * d - 0.520 * T * T - 2.58 * sd(M3) + 0.19 * cd(M3)
end
-- the Galilean moons (their small terms, under a tenth of a degree, left out)
M.Io = function(d, T) return 268.05 - 0.009 * T, 64.50 + 0.003 * T, 200.39 + 203.4889538 * d end
M.Europa = function(d, T) return 268.08 - 0.009 * T, 64.51 + 0.003 * T, 36.022 + 101.3747235 * d end
M.Ganymede = function(d, T) return 268.20 - 0.009 * T, 64.57 + 0.003 * T, 44.064 + 50.3176081 * d end
M.Callisto = function(d, T) return 268.72 - 0.009 * T, 64.83 + 0.003 * T, 259.51 + 21.5710715 * d end
M.Mimas = function(d, T)
  local S3, S5 = 177.40 - 36505.5 * T, 316.45 + 506.2 * T
  return 40.66 - 0.036 * T + 13.56 * sd(S3), 83.52 - 0.004 * T - 1.53 * cd(S3),
         333.46 + 381.9945550 * d - 13.48 * sd(S3) - 44.85 * sd(S5)
end
M.Enceladus = function(d, T) return 40.66 - 0.036 * T, 83.52 - 0.004 * T, 6.32 + 262.7318996 * d end
M.Tethys = function(d, T)
  local S4, S5 = 300.00 - 7225.9 * T, 316.45 + 506.2 * T
  return 40.66 - 0.036 * T + 9.66 * sd(S4), 83.52 - 0.004 * T - 1.09 * cd(S4),
         8.95 + 190.6979085 * d - 9.60 * sd(S4) + 2.23 * sd(S5)
end
M.Dione = function(d, T) return 40.66 - 0.036 * T, 83.52 - 0.004 * T, 357.6 + 131.5349316 * d end
M.Rhea = function(d, T)
  local S6 = 345.20 - 1016.3 * T
  return 40.38 - 0.036 * T + 3.10 * sd(S6), 83.55 - 0.004 * T - 0.35 * cd(S6), 235.16 + 79.6900478 * d - 3.08 * sd(S6)
end
M.Titan = function(d, T) return 39.4827, 83.4279, 186.5855 + 22.5769768 * d end
M.Iapetus = function(d, T) return 318.16 - 3.949 * T, 75.03 - 1.143 * T, 355.2 + 4.5379572 * d end
-- Uranus's moons (the small terms left out)
M.Miranda = function(d, T) return 257.43, -15.08, 30.70 - 254.6906892 * d end
M.Ariel = function(d, T) return 257.43, -15.10, 156.22 - 142.8356681 * d end
M.Umbriel = function(d, T) return 257.43, -15.10, 108.05 - 86.8688923 * d end
M.Titania = function(d, T) return 257.43, -15.10, 77.74 - 41.3514316 * d end
M.Oberon = function(d, T) return 257.43, -15.10, 6.77 - 26.7394932 * d end
M.Triton = function(d, T)
  local N7 = 177.85 + 52.316 * T
  return 299.36 - 32.35 * sd(N7), 41.17 + 22.55 * cd(N7), 296.53 - 61.2572637 * d + 22.25 * sd(N7)
end

local R = {}
R.models = M
-- the period of turning, in days (negative: backwards, east to west), from W's rate
function R.period(name)
  local f = M[name]
  if not f then return nil end
  local _, _, w0 = f(0, 0)
  local _, _, w1 = f(1, 1 / 36525)
  return 360 / (w1 - w0)
end
function R.rotation(name, jd)
  local f = M[name]
  if not f then return nil end
  local d = jd - 2451545.0
  local a0, d0, W = f(d, d / 36525)
  a0, d0, W = rad(a0), rad(d0), rad(W)
  local p = { cos(d0) * cos(a0), cos(d0) * sin(a0), sin(d0) }
  local n = { -sin(a0), cos(a0), 0 }                    -- where its equator crosses the ICRF's, going north
  local q = { p[2] * n[3] - p[3] * n[2], p[3] * n[1] - p[1] * n[3], p[1] * n[2] - p[2] * n[1] }   -- p x n
  local cw, sw = cos(W), sin(W)
  local x = { n[1] * cw + q[1] * sw, n[2] * cw + q[2] * sw, n[3] * cw + q[3] * sw }
  local y = { p[2] * x[3] - p[3] * x[2], p[3] * x[1] - p[1] * x[3], p[1] * x[2] - p[2] * x[1] }   -- p x x: 90 degrees east
  return x, y, p
end
return R
