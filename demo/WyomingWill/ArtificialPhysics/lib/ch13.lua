--
-- lib/ch13.lua -- Ch. 13's motion-control mechanisms (Apker and Potter),
-- one function each, shared by every vehicle (BOOK.md §1 item 1, build
-- step 1, book/ch13.md E5 and E11)
--
-- DEFINITIONS. Forces follow swarm.lua's convention: a pair force f > 0
-- repels, f < 0 attracts; D is the attract-repel (AR) boundary, r the
-- (possibly spin-modified) distance between the pair, both in AP units.
--
--   eta(r, D, pd, w)     AR damping factor. The book's Eq. 13.9 (PDF 454)
--                        is w = 1 (the default):
--                          eta = (|D - r| / D)^pd   for r < 2D
--                          eta = 1                  for r >= 2D
--                        Generalised (William, 2026-10-18) to a band of
--                        half-width w x D round D:
--                          eta = (|D - r| / (w D))^pd  for |D - r| < w D
--                          eta = 1                     otherwise
--                        dimensionless, in [0, 1]; 0 at r = D. pd = 0
--                        gives eta = 1 everywhere (switched off). The book
--                        uses pd = the law's distance power p_d.
--   damp(f, r, D, pd, w) the damped pair force, Eq. 13.10: f x eta
--   stopped(fx, fy, fz, threshold)
--                        the stop rule of §13.2.2 (PDF 454): true when the
--                        summed force |F| = sqrt(fx^2 + fy^2 + fz^2) is
--                        below threshold (AP force units); the vehicle is
--                        then told to stop. threshold <= 0 never stops.
--
--   adaptMu(mu, uNew, uOld, kMore, kLess)
--                        adaptive friction, Eq. 13.23 (PDF 464): the new
--                        friction coefficient for one command channel
--                          mu + kMore (1 - mu)   if uNew * uOld < 0
--                          mu - kLess mu         otherwise (same sign or 0)
--                        mu in [0, 1] stays there for 0 <= k <= 1. The
--                        command is used as u (1 - mu) (Eq. 13.21). The
--                        book needs kMore / kLess > 10 (PDF 464) and gives
--                        no absolute gains.
--
--   staticMoves(mu, m, g, f)
--                        static friction, Eq. 13.25 (PDF 465) with its
--                        corrected condition: true (the channel may move)
--                        when mu m g < |f|, f the channel's force; false
--                        sets that command to 0. The printed form compares
--                        with f m and has no absolute value (book/ch13.md
--                        E11d).
--   adaptCap(uMax, near, uHi, uLo, rNear, kMore, kLess)
--                        adaptive speed cap, Eq. 13.24 (PDF 465): for one
--                        range reading `near`,
--                          uMax + kMore (uHi - uMax)   if near > rNear
--                          uMax - kLess (uMax - uLo)   otherwise
--                        (the Pioneer: uHi 0.5, uLo 0.1 m/s, rNear 1 m,
--                        kLess / kMore > 10).
--
-- WHERE EACH IS NEEDED (milestone M1, FINDINGS F43-F55): on the drones,
-- with perfect sensing and no minimum speed, eta (in a band of 0.2 D)
-- is what settles the split-Newtonian law; adaptive and static friction
-- do not, and freeze the swarm; the stop rule only holds an eta swarm
-- still. Static friction and the adaptive cap are written for vehicles
-- with a minimum speed and real ranging (the Pioneer and Maxelbot of M2),
-- and for sensor noise (G7).
--
-- Plain Lua 5.1-5.4; checks/ch13.lua tests it against Figs. 13.3 and 13.8.
--

local M = {}

function M.eta(r, D, pd, w)
  if not pd or pd <= 0 then return 1 end
  w = w or 1
  local band = w * D
  local dist = math.abs(D - r)
  if dist >= band then return 1 end
  return (dist / band) ^ pd
end

function M.damp(f, r, D, pd, w)
  return f * M.eta(r, D, pd, w)
end

function M.adaptMu(mu, uNew, uOld, kMore, kLess)
  if uNew * uOld < 0 then return mu + kMore * (1 - mu) end
  return mu - kLess * mu
end

function M.staticMoves(mu, m, g, f)
  return mu * m * g < math.abs(f)
end

function M.adaptCap(uMax, near, uHi, uLo, rNear, kMore, kLess)
  if near > rNear then return uMax + kMore * (uHi - uMax) end
  return uMax - kLess * (uMax - uLo)
end

function M.stopped(fx, fy, fz, threshold)
  if not threshold or threshold <= 0 then return false end
  return fx * fx + fy * fy + fz * fz < threshold * threshold
end

return M
