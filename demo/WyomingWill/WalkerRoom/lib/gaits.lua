-- Each walker's best gait for each ground (made by runs/best-gaits.sh, chosen on seeds 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16):
-- another gait only where it beat the walker's trot by more than two standard errors; else a trot. BEST_GAITS
-- (13 November: checked on fresh seeds 17-32; the four that came out below their trot there -- Chebyshev-Spears diag
-- on random 5, lift 51 diag on waves 3, Hoecken-Spears slider diag on logs 3, Hoecken-Spears 4-bar diag on steps 3 --
-- taken out: 33 left, every one better than its trot on both sets of seeds)
GROUND_GAITS = {
  ["Chebyshev diag"] = {
    ["steps 6"] = { offset = 150 },
    ["waves 7"] = { offset = 120 },
  },
  ["Chebyshev-Spears diag"] = {
    ["flat 0"] = { offset = 120 },
    ["logs 1"] = { offset = 90 },
    ["steps 1"] = { offset = 90 },
    ["steps 2"] = { offset = 90 },
  },
  ["Chebyshev-Spears lift 51 diag"] = {
    ["waves 4"] = { offset = 150 },
    ["waves 5"] = { offset = 90 },
  },
  ["Chebyshev-Spears lift 62 diag"] = {
    ["random 7"] = { offset = 90 },
    ["random 8"] = { offset = 120 },
    ["waves 3"] = { offset = 150 },
    ["waves 4"] = { offset = 90 },
    ["waves 5"] = { offset = 120 },
    ["waves 6"] = { offset = 120 },
  },
  ["Hoecken-Spears 4-bar diag"] = {
    ["logs 1"] = { offset = 120 },
    ["random 1"] = { offset = 150 },
    ["steps 1"] = { offset = 120 },
    ["steps 2"] = { offset = 120 },
  },
  ["Hoecken-Spears slider diag"] = {
    ["flat 0"] = { offset = 150 },
    ["logs 1"] = { offset = 90 },
    ["logs 2"] = { offset = 90 },
    ["random 1"] = { offset = 90 },
    ["steps 1"] = { offset = 90 },
    ["steps 2"] = { offset = 90 },
    ["steps 3"] = { offset = 90 },
  },
  ["Spears 4-bar"] = {
    ["flat 0"] = { gait = { 0, 90, 180, 270 } },
    ["logs 1"] = { gait = { 0, 90, 180, 270 } },
    ["random 1"] = { gait = { 0, 90, 180, 270 } },
    ["random 2"] = { gait = { 0, 90, 180, 270 } },
    ["steps 1"] = { gait = { 0, 90, 180, 270 } },
    ["steps 2"] = { gait = { 0, 90, 180, 270 } },
    ["steps 3"] = { gait = { 0, 90, 180, 270 } },
    ["steps 4"] = { gait = { 0, 90, 180, 270 } },
  },
}
