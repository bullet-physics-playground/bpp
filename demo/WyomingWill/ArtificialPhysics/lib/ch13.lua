--
-- lib/ch13.lua -- Ch. 13's motion-control mechanisms (Apker and Potter),
-- one function each, shared by every vehicle (BOOK.md §1 item 1, build
-- step 1, book/ch13.md E5 and E11)
--
-- DEFINITIONS. Forces follow swarm.lua's convention: a pair force f > 0
-- repels, f < 0 attracts; D is the attract-repel (AR) boundary, r the
-- (possibly spin-modified) distance between the pair, both in AP units.
--
--   eta(r, D, pd)        AR damping factor, Eq. 13.9 (PDF 454):
--                          eta = (|D - r| / D)^pd   for r < 2D
--                          eta = 1                  for r >= 2D
--                        dimensionless, in [0, 1]; 0 at r = D. pd = 0
--                        gives eta = 1 everywhere (switched off). The book
--                        uses pd = the law's distance power p_d.
--   damp(f, r, D, pd)    the damped pair force, Eq. 13.10: f x eta
--   stopped(fx, fy, fz, threshold)
--                        the stop rule of §13.2.2 (PDF 454): true when the
--                        summed force |F| = sqrt(fx^2 + fy^2 + fz^2) is
--                        below threshold (AP force units); the vehicle is
--                        then told to stop. threshold <= 0 never stops.
--
-- Not yet here (later steps of milestone M1): adaptive friction
-- (Eq. 13.23), static friction (Eq. 13.25), adaptive speed cap (Eq. 13.24).
--
-- Plain Lua 5.1-5.4; checks/ch13.lua tests it against Figs. 13.3 and 13.8.
--

local M = {}

function M.eta(r, D, pd)
  if not pd or pd <= 0 or r >= 2 * D then return 1 end
  return (math.abs(D - r) / D) ^ pd
end

function M.damp(f, r, D, pd)
  return f * M.eta(r, D, pd)
end

function M.stopped(fx, fy, fz, threshold)
  if not threshold or threshold <= 0 then return false end
  return fx * fx + fy * fy + fz * fz < threshold * threshold
end

return M
