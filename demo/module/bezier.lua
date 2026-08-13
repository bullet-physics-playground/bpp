local M = {}

-- Linear (degree-1) Bezier between two points -- a straight line, useful
-- as a building block for paths that need an exactly-straight segment
-- (e.g. rising/falling vertically, with no lateral drift at all).
function M.Linear(p0, p1)
  local curve = {}
  curve.p0, curve.p1 = p0, p1
  curve.num_segments = 1

  function curve:eval(t)
    t = math.max(0, math.min(t, 1))
    return {
      x = p0.x + (p1.x - p0.x) * t,
      y = p0.y + (p1.y - p0.y) * t,
      z = p0.z + (p1.z - p0.z) * t,
    }
  end

  function curve:eval_range(t_start, t_end, steps)
    local result = {}
    for i = 0, steps do
      local t = t_start + (t_end - t_start) * i / steps
      table.insert(result, self:eval(t))
    end
    return result
  end

  return curve
end

-- Cubic (degree-3) Bezier through 4 control points in Bernstein form. The
-- curve touches p0 at t=0 and p3 at t=1, and is tangent there to the
-- (p1-p0) / (p3-p2) legs of the control polygon -- p1/p2 are handles that
-- pull the curve without necessarily being touched by it.
function M.Cubic(p0, p1, p2, p3)
  local curve = {}
  curve.p0, curve.p1, curve.p2, curve.p3 = p0, p1, p2, p3
  curve.num_segments = 1

  function curve:eval(t)
    t = math.max(0, math.min(t, 1))
    local mt = 1 - t
    local a = mt * mt * mt
    local b = 3 * mt * mt * t
    local c = 3 * mt * t * t
    local d = t * t * t
    return {
      x = a * p0.x + b * p1.x + c * p2.x + d * p3.x,
      y = a * p0.y + b * p1.y + c * p2.y + d * p3.y,
      z = a * p0.z + b * p1.z + c * p2.z + d * p3.z,
    }
  end

  function curve:eval_range(t_start, t_end, steps)
    local result = {}
    for i = 0, steps do
      local t = t_start + (t_end - t_start) * i / steps
      table.insert(result, self:eval(t))
    end
    return result
  end

  return curve
end

return M
