--
-- ch07/kerr2005_run.lua -- one run of Kerr's 2005 corridor sweep on the
-- Lua port (ch07/kerr2005.lua), from his drivers' seed, printing his log
-- line (and the fixes, if any). Any Lua 5.1-5.4; from the ArtificialPhysics
-- folder:
--   lua5.1 ch07/kerr2005_run.lua CONTROLLER N PCT COURSE [RUN] [FIXES]
-- CONTROLLER KTRobot | AntRobot | Simple2; N robots; PCT obstacles (0, or
-- 10-40: his data/course_PCT_COURSE.txt); RUN 0-9 (seed 100 + 10 COURSE +
-- RUN, as his drivers); FIXES a comma list of kerr2005.lua's o.fix switches
-- (seeds, messages, wallfit), or nothing for his code.
--
-- DEFINITIONS (the line): Behind = shadow cells covered (% of the shadow
-- cells), Total = cells covered (% of the cells not inside obstacles), Time
-- = steps until every robot was done (at most 150,000); as his drivers.
--
local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]ch07[/\\][^/\\]*$")) or "."
package.path = here .. "/?.lua;" .. package.path
local R = require "ch07.kerr2005"
local ctl, n, pct, k = arg[1], tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4])
local run = tonumber(arg[5] or 0)
local fix, names = {}, {}
for f in (arg[6] or ""):gmatch("[^,]+") do fix[f] = true; names[#names + 1] = f end
local o = { controller = ctl, n = n, pct = pct, k = k, run = run, seed = 100 + 10 * k + run, fix = fix,
            course = R.coursePath(here .. "/ch07/kerr2005/data", pct, k) }
local res = R.run(o)
print(R.line(res, o) .. (#names > 0 and (" Fix " .. table.concat(names, ",")) or ""))
