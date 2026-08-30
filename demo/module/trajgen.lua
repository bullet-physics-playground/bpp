--
-- trajgen.lua - trajectory generator
--
-- A Lua port of rm501/trajgen.c / trajgen.h by Stefan Wilhelm
-- (cerberos@atwillys.de), BSD licensed. See that source for the full design
-- notes; the short version:
--
--   * The generator moves a virtual machine "pose" (tool tip position/
--     orientation) every cycle. Coordinated motion first updates the pose,
--     then runs inverse kinematics to get joint positions; the free-joint
--     and manual (tele-op) planers update joint / pose directly.
--   * Joint positions are then fed through a per-joint cubic interpolator so
--     the servo update rate can exceed the planer rate (interpolation_rate).
--   * A small finite state machine (trajgen_switch_state) wraps the sub
--     planers: DISABLED, JOINT, COORDINATED, MAN, with enter/leave states.
--
-- The C file uses one process-wide static generator; here trajgen.new(config)
-- returns an instance and the sub-planer functions take their struct as the
-- first argument, mirroring the C call convention.
--
-- Load with:  local trajgen = require "trajgen"
--
--   local tg = trajgen.new{
--     sample_interval        = 1/50,
--     interpolation_rate     = 1,
--     number_of_used_joints  = 3,
--     max_coord_velocity     = 100,
--     max_coord_acceleration = 5000,
--     joints = { {max_velocity=1e4, max_acceleration=1e4}, ... },
--     kinematics = { forward = fn, inverse = fn },   -- optional, identity default
--   }
--   tg:switch_state(trajgen.TRAJ_STATE_COORDINATED)
--   while not tg.is_done do tg:tick() end
--   tg:add_line({x=1.6, y=3.2, z=0}, 100, 5000)
--   while not tg.is_done do tg:tick(); --[[ read tg.joints[i].position ]] end
--

local M = {}

-- ===========================================================================
-- Build config: constants (trajgen.h "Build config" section)
-- ===========================================================================

local JOINT_MAX_JOINTS = 9
local TG_MAX_JOINTS    = JOINT_MAX_JOINTS
local TG_QUEUE_SIZE    = 32
local TG_RESOLUTION    = 1e-6
local FLOAT_EPS        = 1.1920929e-7   -- FLT_EPSILON (real_t is treated as double here)
local TG_CURVE_ACC     = 16
local TG_D_RES         = TG_RESOLUTION
local TG_A_RES         = TG_RESOLUTION

local MAX_ALLOWED_BLENDING_ANGLE_DEG = 85
local STRAIGHT_BLENDING_ANGLE        = 1

local NO_MOTION_BLENDING = 0            -- 0 = blending compiled in (see trajgen.c)

local TG_VERSION = "1.0b-lua"

M.TG_MAX_JOINTS = TG_MAX_JOINTS
M.TG_QUEUE_SIZE = TG_QUEUE_SIZE

local M_PI  = math.pi
local sqrt  = math.sqrt
local sin   = math.sin
local cos   = math.cos
local acos  = math.acos
local fabs  = math.abs
local floor = math.floor
local huge  = math.huge
local NAN   = 0 / 0

local function isfinite(x) return x == x and x ~= huge and x ~= -huge end
local function isnan(x)    return x ~= x end
local function sqr(x)      return x * x end

-- 16-bit bitwise helpers for the synchronised DIO word (Lua 5.1 has no bit ops)
local function band(a, b)
  local r, bit = 0, 1
  for _ = 1, 16 do
    if (a % 2 == 1) and (b % 2 == 1) then r = r + bit end
    a, b, bit = floor(a / 2), floor(b / 2), bit * 2
  end
  return r
end
local function bor(a, b)
  local r, bit = 0, 1
  for _ = 1, 16 do
    if (a % 2 == 1) or (b % 2 == 1) then r = r + bit end
    a, b, bit = floor(a / 2), floor(b / 2), bit * 2
  end
  return r
end
local function bnot(a) return 65535 - band(a, 65535) end

-- sqrtz(X): sqrt for values that may be a hair below zero from rounding
local function sqrtz(x)
  if x > 0 then return sqrt(x) end
  if x > -TG_RESOLUTION then return 0 end
  return NAN
end

-- SINCOS
local function sincos(x) return sin(x), cos(x) end

-- ===========================================================================
-- pose_*: robot pose types and operations (trajgen.h)
--
-- A pose is a plain table with fields x,y,z (translation), a,b,c (rotation)
-- and u,v,w (auxiliary translation). pose_vector is just {x,y,z}.
-- ===========================================================================

M.POSE_X_AXIS, M.POSE_Y_AXIS, M.POSE_Z_AXIS = 0, 1, 2
M.POSE_A_AXIS, M.POSE_B_AXIS, M.POSE_C_AXIS = 3, 4, 5
M.POSE_U_AXIS, M.POSE_V_AXIS, M.POSE_W_AXIS = 6, 7, 8

local function pose_new(t)
  t = t or {}
  return {
    x = t.x or 0, y = t.y or 0, z = t.z or 0,
    a = t.a or 0, b = t.b or 0, c = t.c or 0,
    u = t.u or 0, v = t.v or 0, w = t.w or 0,
  }
end
M.pose = pose_new

local function pose_set_zero(p)
  p.x, p.y, p.z, p.a, p.b, p.c, p.u, p.v, p.w = 0, 0, 0, 0, 0, 0, 0, 0, 0
end

local function pose_set_all(p, val)
  p.x, p.y, p.z, p.a, p.b, p.c, p.u, p.v, p.w = val, val, val, val, val, val, val, val, val
end

local function pose_isfinite(p)
  return isfinite(p.x) and isfinite(p.y) and isfinite(p.z)
     and isfinite(p.a) and isfinite(p.b) and isfinite(p.c)
     and isfinite(p.u) and isfinite(p.v) and isfinite(p.w)
end

-- dst = src
local function pose_set(dst, src)
  dst.x, dst.y, dst.z = src.x, src.y, src.z
  dst.a, dst.b, dst.c = src.a, src.b, src.c
  dst.u, dst.v, dst.w = src.u, src.v, src.w
end

-- po = p1 - p2
local function pose_diff(p1, p2, po)
  po.x, po.y, po.z = p1.x - p2.x, p1.y - p2.y, p1.z - p2.z
  po.a, po.b, po.c = p1.a - p2.a, p1.b - p2.b, p1.c - p2.c
  po.u, po.v, po.w = p1.u - p2.u, p1.v - p2.v, p1.w - p2.w
end

-- po += p2
local function pose_acc(po, p2)
  po.x, po.y, po.z = po.x + p2.x, po.y + p2.y, po.z + p2.z
  po.a, po.b, po.c = po.a + p2.a, po.b + p2.b, po.c + p2.c
  po.u, po.v, po.w = po.u + p2.u, po.v + p2.v, po.w + p2.w
end

-- po -= p2
local function pose_sub(po, p2)
  po.x, po.y, po.z = po.x - p2.x, po.y - p2.y, po.z - p2.z
  po.a, po.b, po.c = po.a - p2.a, po.b - p2.b, po.c - p2.c
  po.u, po.v, po.w = po.u - p2.u, po.v - p2.v, po.w - p2.w
end

local function pose_neg(po)
  po.x, po.y, po.z = -po.x, -po.y, -po.z
  po.a, po.b, po.c = -po.a, -po.b, -po.c
  po.u, po.v, po.w = -po.u, -po.v, -po.w
end

local function pose_scale(po, d)
  po.x, po.y, po.z = po.x * d, po.y * d, po.z * d
  po.a, po.b, po.c = po.a * d, po.b * d, po.c * d
  po.u, po.v, po.w = po.u * d, po.v * d, po.w * d
end

local function pose_trim_all_upper(po, mx)
  if po.x > mx.x then po.x = mx.x end
  if po.y > mx.y then po.y = mx.y end
  if po.z > mx.z then po.z = mx.z end
  if po.a > mx.a then po.a = mx.a end
  if po.b > mx.b then po.b = mx.b end
  if po.c > mx.c then po.c = mx.c end
  if po.u > mx.u then po.u = mx.u end
  if po.v > mx.v then po.v = mx.v end
  if po.w > mx.w then po.w = mx.w end
end

local function pose_trim_all_lower(po, mn)
  if po.x < mn.x then po.x = mn.x end
  if po.y < mn.y then po.y = mn.y end
  if po.z < mn.z then po.z = mn.z end
  if po.a < mn.a then po.a = mn.a end
  if po.b < mn.b then po.b = mn.b end
  if po.c < mn.c then po.c = mn.c end
  if po.u < mn.u then po.u = mn.u end
  if po.v < mn.v then po.v = mn.v end
  if po.w < mn.w then po.w = mn.w end
end

local function pose_is_zero(p)
  return p.x == 0 and p.y == 0 and p.z == 0
     and p.a == 0 and p.b == 0 and p.c == 0
     and p.u == 0 and p.v == 0 and p.w == 0
end

local function pose_is_all_greater_equal_zero(p)
  return p.x >= 0 and p.y >= 0 and p.z >= 0
     and p.a >= 0 and p.b >= 0 and p.c >= 0
     and p.u >= 0 and p.v >= 0 and p.w >= 0
end

-- ===========================================================================
-- trajgen_error_*: error codes and text (trajgen.h / trajgen.c)
-- ===========================================================================

local E = {}
do
  local names = {
    -- Main controller
    "TRAJ_ERROR_OK", "TRAJ_ERROR_ERROR", "TRAJ_ERROR_NULL_POINTER",
    "TRAJ_ERROR_NUMERIC", "TRAJ_ERROR_CONFIG_LAST_USED_JOINT_INVALID",
    "TRAJ_ERROR_CONFIG_INTERPOLATION_RATE_INVALID",
    "TRAJ_ERROR_CONFIG_OVERRIDE_INVALID",
    "TRAJ_ERROR_CONFIG_COMPILE_SETTING_INVALID", "TRAJ_ERROR_INVALID_STATE",
    "TRAJ_ERROR_INVALID_SWITCHING_STATE", "TRAJ_ERROR_INVALID_JOINT_NO",
    -- Kinematics
    "KINEMATICS_ERR_ERROR", "KINEMATICS_ERR_NULL_POINTER",
    "KINEMATICS_ERR_INIT_FUNCTION_NULL", "KINEMATICS_ERR_FORWARD_FAILED",
    "KINEMATICS_ERR_INVERSE_FAILED", "KINEMATICS_ERR_RESET_FAILED",
    -- Interpolators
    "INTERPOLATOR_ERROR", "INTERPOLATOR_ERROR_INIT_ARG_INVALID",
    "INTERPOLATOR_ERROR_QUEUE_FULL", "INTERPOLATOR_ERROR_OFFSET_IP_NULLPOINTER",
    "INTERPOLATOR_ERROR_INTERPOLATE_ARG_NULLPOINTER",
    "INTERPOLATOR_ERROR_NOT_RESET", "INTERPOLATOR_ERROR_NULLPOINTER",
    -- Coordinated planer
    "TP_ERR_ERROR", "TP_ERR_TP_NULL_POINTER", "TP_ERR_ABORTING",
    "TP_ERR_QUEUE_PUT_FAILED", "TP_ERR_INVALID_PARAM", "TP_ERR_QUEUE_FULL",
    "TP_ERR_QUEUE_TO_MANY_ELEMENTS_TO_REMOVE", "TP_ERR_INVALID_MOTION_TYPE",
    "TP_ERR_INVALID_SPEED", "TP_ERR_INVALID_ACCEL", "TP_ERR_INVALID_POSE",
    "TP_ERR_SEGMENT_LENGTH_ZERO", "TP_ERR_INVALID_SAMPLE_INTERVAL",
    "TP_ERR_ALREADY_MOVING", "TP_ERR_UNIT_VECTOR_CALC_INVALID_TYPE",
    "TP_ERR_REF_POSITION_INVALIDATED_DURING_MOTION",
    -- Joint planers
    "TRAJGEN_FREE_ERROR_ERROR", "TRAJGEN_FREE_ERROR_INIT_NULLPOINTER",
    "TRAJGEN_FREE_ERROR_INIT_INVALID_MAX_ACCEL",
    "TRAJGEN_FREE_ERROR_INIT_INVALID_MAX_VELOCITY",
    "TRAJGEN_FREE_ERROR_INIT_INVALID_SAMPLE_INTERVAL",
    "TRAJGEN_FREE_ERROR_INVALID_ACCELERATION",
    -- Manual operation planer
    "TG_MAN_ERROR_ERROR", "TG_MAN_ERROR_INIT_NULLPOINTER",
    "TG_MAN_ERROR_INIT_INVALID_MAX_ACCEL", "TG_MAN_ERROR_INIT_INVALID_MAX_VELOCITY",
    "TG_MAN_ERROR_INIT_INVALID_SAMPLE_INTERVAL", "TG_MAN_ERROR_INVALID_ACCELERATION",
  }
  for i, n in ipairs(names) do E[n] = i - 1 end
  -- The C aliases these "OK" codes all to 0.
  E.KINEMATICS_ERR_OK      = 0
  E.INTERPOLATOR_OK        = 0
  E.TP_ERR_OK              = 0
  E.TRAJGEN_FREE_ERROR_OK  = 0
  E.TG_MAN_ERROR_OK        = 0
end
M.error = E

local ERRSTR = {
  [E.TRAJ_ERROR_OK] = "(ok)",
  [E.TRAJ_ERROR_ERROR] = "[main trajgen] General error",
  [E.TRAJ_ERROR_NULL_POINTER] = "[main trajgen] Null pointer",
  [E.TRAJ_ERROR_NUMERIC] = "[main trajgen] Numeric error",
  [E.TRAJ_ERROR_CONFIG_LAST_USED_JOINT_INVALID] = "[main trajgen] Invalid last used joint value",
  [E.TRAJ_ERROR_CONFIG_INTERPOLATION_RATE_INVALID] = "[main trajgen] Invalid interpolation rate setting",
  [E.TRAJ_ERROR_CONFIG_COMPILE_SETTING_INVALID] = "[main trajgen] Invalid compilation setting",
  [E.TRAJ_ERROR_CONFIG_OVERRIDE_INVALID] = "[main trajgen] Invalid override",
  [E.TRAJ_ERROR_INVALID_STATE] = "[main trajgen] Invalid state",
  [E.TRAJ_ERROR_INVALID_SWITCHING_STATE] = "[main trajgen] Invalid switching state",
  [E.TRAJ_ERROR_INVALID_JOINT_NO] = "[main trajgen] Invalid joint index",
  [E.KINEMATICS_ERR_ERROR] = "[kinematics] General error",
  [E.KINEMATICS_ERR_NULL_POINTER] = "[kinematics] Null pointer",
  [E.KINEMATICS_ERR_INIT_FUNCTION_NULL] = "[kinematics] Invalid kinematics definition (function null-pointer)",
  [E.KINEMATICS_ERR_FORWARD_FAILED] = "[kinematics] Forward kinematics failed",
  [E.KINEMATICS_ERR_INVERSE_FAILED] = "[kinematics] Inverse kinematics failed",
  [E.KINEMATICS_ERR_RESET_FAILED] = "[kinematics] Reset setting failed",
  [E.INTERPOLATOR_ERROR] = "[interpolator] General error",
  [E.INTERPOLATOR_ERROR_INIT_ARG_INVALID] = "[interpolator] Invalid initialisation argument",
  [E.INTERPOLATOR_ERROR_QUEUE_FULL] = "[interpolator] Queue full",
  [E.INTERPOLATOR_ERROR_OFFSET_IP_NULLPOINTER] = "[interpolator] Offset CI null pointer",
  [E.INTERPOLATOR_ERROR_INTERPOLATE_ARG_NULLPOINTER] = "[interpolator] Interpolate: Null pointer",
  [E.INTERPOLATOR_ERROR_NOT_RESET] = "[interpolator] Not initialised",
  [E.TRAJGEN_FREE_ERROR_ERROR] = "[joint tg] General error",
  [E.TRAJGEN_FREE_ERROR_INIT_NULLPOINTER] = "[joint tg] Initialisation null pointer",
  [E.TRAJGEN_FREE_ERROR_INIT_INVALID_MAX_ACCEL] = "[joint tg] Invalid maximum acceleration",
  [E.TRAJGEN_FREE_ERROR_INIT_INVALID_MAX_VELOCITY] = "[joint tg] Invalid maximum velocity",
  [E.TRAJGEN_FREE_ERROR_INIT_INVALID_SAMPLE_INTERVAL] = "[joint tg] Invalid sample interval",
  [E.TRAJGEN_FREE_ERROR_INVALID_ACCELERATION] = "[joint tg] Invalid acceleration",
  [E.TP_ERR_ERROR] = "[coord tg] General error",
  [E.TP_ERR_TP_NULL_POINTER] = "[coord tg] Null pointer",
  [E.TP_ERR_ABORTING] = "[coord tg] Aborting",
  [E.TP_ERR_QUEUE_PUT_FAILED] = "[coord tg] Queue push failed",
  [E.TP_ERR_INVALID_PARAM] = "[coord tg] Invalid argument",
  [E.TP_ERR_QUEUE_FULL] = "[coord tg] Queue full",
  [E.TP_ERR_QUEUE_TO_MANY_ELEMENTS_TO_REMOVE] = "[coord tg] Too many items to remove",
  [E.TP_ERR_INVALID_MOTION_TYPE] = "[coord tg] Invalid motion type",
  [E.TP_ERR_INVALID_SPEED] = "[coord tg] Invalid velocity",
  [E.TP_ERR_INVALID_ACCEL] = "[coord tg] Invalid acceleration",
  [E.TP_ERR_INVALID_POSE] = "[coord tg] Invalid argument pose",
  [E.TP_ERR_INVALID_SAMPLE_INTERVAL] = "[coord tg] Invalid sample interval",
  [E.TP_ERR_ALREADY_MOVING] = "[coord tg] Already moving",
  [E.TP_ERR_SEGMENT_LENGTH_ZERO] = "[coord tg] Segment to move has a length of zero",
  [E.TP_ERR_UNIT_VECTOR_CALC_INVALID_TYPE] = "[coord tg] Unit vector calculation failed",
  [E.TP_ERR_REF_POSITION_INVALIDATED_DURING_MOTION] = "[coord tg] Ref-position invalidated during motion",
  [E.TG_MAN_ERROR_ERROR] = "[manual tg] General error",
  [E.TG_MAN_ERROR_INIT_NULLPOINTER] = "[manual tg] Initialisation: null pointer",
  [E.TG_MAN_ERROR_INIT_INVALID_MAX_ACCEL] = "[manual tg] Invalid maximum acceleration",
  [E.TG_MAN_ERROR_INIT_INVALID_MAX_VELOCITY] = "[manual tg] Invalid maximum velocity",
  [E.TG_MAN_ERROR_INIT_INVALID_SAMPLE_INTERVAL] = "[manual tg] Invalid sample interval",
  [E.TG_MAN_ERROR_INVALID_ACCELERATION] = "[manual tg] Invalid acceleration",
}

-- trajgen_errstr(): the C packs code (12 bit) and joint (4 bit) into one
-- 16 bit number. errnom == code | (joint << 12).
function M.errstr(errnom)
  errnom = errnom or 0
  local code  = errnom % 4096
  local joint = floor(errnom / 4096) % 16
  local s = ERRSTR[code] or "Unknown error code"
  -- interpolator / joint-tg errors also carry the joint index
  if code >= E.INTERPOLATOR_ERROR and code <= E.INTERPOLATOR_ERROR_NOT_RESET then
    s = s .. "[" .. joint .. "]"
  elseif code >= E.TRAJGEN_FREE_ERROR_ERROR and code <= E.TRAJGEN_FREE_ERROR_INVALID_ACCELERATION then
    s = s .. "[" .. joint .. "]"
  end
  return s
end

local function err_encode(code, joint)
  return (code % 4096) + (((joint or 0) % 16) * 4096)
end

-- ===========================================================================
-- Math / vector auxiliaries (trajgen.c "Math/vector auxiliaries")
-- ===========================================================================

local function v_new(x, y, z) return { x = x or 0, y = y or 0, z = z or 0 } end
local function v_cpy(vs, vd) vd.x, vd.y, vd.z = vs.x, vs.y, vs.z end

local function v_magnitude(v) return sqrtz(sqr(v.x) + sqr(v.y) + sqr(v.z)) end
local function v_magnitude_sq(v) return sqr(v.x) + sqr(v.y) + sqr(v.z) end
local function v_distance(v1, v2)
  return sqrtz(sqr(v2.x - v1.x) + sqr(v2.y - v1.y) + sqr(v2.z - v1.z))
end
local function v_dot(v1, v2) return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z end
local function v_isfinite(p) return isfinite(p.x) and isfinite(p.y) and isfinite(p.z) end
local function v_invalidate(p) p.x, p.y, p.z = NAN, NAN, NAN end
local function v_setzero(p) p.x, p.y, p.z = 0, 0, 0 end

local function v_pose_split(pose, xyz, abc, uvw)
  xyz.x, xyz.y, xyz.z = pose.x, pose.y, pose.z
  uvw.x, uvw.y, uvw.z = pose.u, pose.v, pose.w
  abc.x, abc.y, abc.z = pose.a, pose.b, pose.c
end

local function v_pose_merge(xyz, abc, uvw, pose)
  pose.x, pose.y, pose.z = xyz.x, xyz.y, xyz.z
  pose.u, pose.v, pose.w = uvw.x, uvw.y, uvw.z
  pose.a, pose.b, pose.c = abc.x, abc.y, abc.z
end

local function v_scale(v1, d, r) r.x, r.y, r.z = v1.x * d, v1.y * d, v1.z * d; return 0 end
local function v_sum(v1, v2, r) r.x, r.y, r.z = v1.x + v2.x, v1.y + v2.y, v1.z + v2.z; return 0 end
local function v_sub(v1, v2, r) r.x, r.y, r.z = v1.x - v2.x, v1.y - v2.y, v1.z - v2.z; return 0 end

local function v_cross(v1, v2, r)
  local x = v1.y * v2.z - v1.z * v2.y
  local y = v1.z * v2.x - v1.x * v2.z
  local z = v1.x * v2.y - v1.y * v2.x
  r.x, r.y, r.z = x, y, z
  return 0
end

local function v_unit(v, r)
  local l = v_magnitude(v)
  if l == 0.0 then
    r.x, r.y, r.z = 0, 0, 0
    return 1
  end
  r.x, r.y, r.z = v.x / l, v.y / l, v.z / l
  return 0
end

local function v_project(v1, v2, r)
  local u = v_new()
  v_cpy(v2, u)
  if v_unit(u, u) ~= 0 then return 1 end
  v_scale(u, v_dot(v1, u), r)
  return 0
end

local function v_plane_project(v, normal, r)
  local p = v_new()
  if v_project(v, normal, p) ~= 0 then return 1 end
  return v_sub(v, p, r)
end

-- v_lin_define(line, start, e): precalculate a line's unit vector + length.
-- line fields: p0 (start), p1 (end), u (unit dir), tm (length).
local function v_lin_define(line, start, e)
  line.p0 = v_new(start.x, start.y, start.z)
  line.p1 = v_new(e.x, e.y, e.z)
  line.u  = v_new()
  v_sub(e, start, line.u)
  line.tm = v_magnitude(line.u)
  if line.tm < TG_D_RES then
    line.u.x = 1
    line.tm, line.u.y, line.u.z = 0, 0, 0
  elseif v_unit(line.u, line.u) ~= 0 then
    line.tm, line.u.x, line.u.y, line.u.z = 0, 0, 0, 0
    return 1
  end
  return 0
end

local function v_lin_get(line, progress, point)
  if line.tm <= 0 or progress >= line.tm then
    point.x, point.y, point.z = line.p1.x, line.p1.y, line.p1.z
  else
    v_scale(line.u, progress, point)
    v_sum(line.p0, point, point)
  end
  return 0
end

-- v_arc_define / v_arc_get: circle/arc/helix (used by add_arc).
-- circle fields: cp (centre), nv (unit normal), rt/rp/rh (radius vectors),
-- l (segment length), r (start radius), a (angle), s (parallel coeff).
local function v_arc_define(circle, start, e, center, normal, n_turns)
  local v = v_new()
  local ee = v_new(0, 0, 0)
  circle.cp = circle.cp or v_new()
  circle.nv = circle.nv or v_new()
  circle.rt = circle.rt or v_new()
  circle.rp = circle.rp or v_new()
  circle.rh = circle.rh or v_new()

  v_sub(start, center, v)
  if v_project(v, normal, v) ~= 0 then return 1 end
  v_sum(v, center, circle.cp)
  v_unit(normal, circle.nv)
  circle.r = v_distance(start, circle.cp)
  if circle.r < TG_D_RES then return 1 end
  v_sub(e, center, v)
  if v_project(v, normal, v) ~= 0 then return 1 end
  v_sub(start, circle.cp, circle.rt)
  v_cross(circle.nv, circle.rt, circle.rp)
  v_sub(e, circle.cp, circle.rh)
  v_plane_project(circle.rh, circle.nv, ee)
  circle.s = v_magnitude(ee) - circle.r
  v_sub(circle.rh, ee, circle.rh)
  v_unit(ee, ee)
  v_scale(ee, circle.r, ee)
  if v_magnitude(ee) == 0 then
    v_scale(circle.nv, FLOAT_EPS, v)
    v_sum(ee, v, ee)
  end
  local d = v_dot(circle.rt, ee) / sqr(circle.r)
  circle.a = (d > 1.0) and 0.0 or ((d < -1) and M_PI or acos(d))
  v_cross(circle.rt, ee, v)
  if v_dot(v, circle.nv) < 0 then circle.a = (2.0 * M_PI) - circle.a end
  if circle.a > -TG_A_RES and circle.a < TG_A_RES then circle.a = 0 end
  if n_turns > 0 then circle.a = circle.a + n_turns * 2.0 * M_PI end
  circle.l = sqrtz(sqr(circle.a * circle.r) + sqr(v_magnitude(circle.rh)))
  return (circle.a == 0) and 1 or 0
end

local function v_arc_get(circle, progress, point)
  local p, s = v_new(), v_new()
  progress = progress / circle.l
  local sx, cx = sincos(progress * circle.a)
  v_scale(circle.rp, sx, s)
  v_scale(circle.rt, cx, p)
  v_sum(p, s, point)
  v_unit(point, p)
  v_scale(p, progress * circle.s, p)
  v_sum(point, p, point)
  v_scale(circle.rh, progress, s)
  v_sum(point, s, point)
  v_sum(circle.cp, point, point)
  return 0
end

-- ===========================================================================
-- interpolator_*: cyclic cubic interpolation (trajgen.c, NO_INTERPOLATION off)
-- ===========================================================================

local Interpolator = {}
Interpolator.__index = Interpolator

local function interpolator_new()
  return setmetatable({
    n = 0, T = 0, Ti = 0, t = 0,
    x0 = 0, x1 = 0, x2 = 0, x3 = 0,
    w0 = 0, w1 = 0, v0 = 0, v1 = 0,
    a = 0, b = 0, c = 0, d = 0,
  }, Interpolator)
end

local function interpolator_need_update(ci) return (ci.n < 4) end

local function interpolator_push(ip, point)
  if ip.n >= 4 then
    return E.INTERPOLATOR_ERROR_QUEUE_FULL
  elseif ip.n == 0 then
    return E.INTERPOLATOR_ERROR_NOT_RESET
  else
    ip.x0 = ip.x1
    ip.x1 = ip.x2
    ip.x2 = ip.x3
    ip.x3 = point
    ip.n = ip.n + 1
  end
  local T = ip.T
  ip.w0 = (ip.x0 + 4.0 * ip.x1 + ip.x2) / 6.0
  ip.w1 = (ip.x1 + 4.0 * ip.x2 + ip.x3) / 6.0
  ip.v0 = (ip.x2 - ip.x0) / (2.0 * T)
  ip.v1 = (ip.x3 - ip.x1) / (2.0 * T)
  ip.d  = ip.w0
  ip.c  = ip.v0
  ip.b  = 3 * (ip.w1 - ip.w0) / (T * T) - (2 * ip.v0 + ip.v1) / T
  ip.a  = (ip.v1 - ip.v0) / (3.0 * (T * T)) - (2.0 * ip.b) / (3.0 * T)
  ip.t  = 0.0
  return E.INTERPOLATOR_OK
end

local function interpolator_reset(ip, initial_position)
  ip.n = 1
  ip.t = 0.0
  ip.x0, ip.x1, ip.x2, ip.x3 = initial_position, initial_position, initial_position, initial_position
  ip.w0, ip.w1, ip.d = initial_position, initial_position, initial_position
  ip.v0, ip.v1, ip.a, ip.b, ip.c = 0, 0, 0, 0, 0
  return interpolator_push(ip, initial_position)
end

local function interpolator_init(ip, sample_interval, interpolation_rate)
  if sample_interval <= 0.0 or interpolation_rate < 1 then
    return E.INTERPOLATOR_ERROR_INIT_ARG_INVALID
  end
  ip.T = sample_interval
  ip.Ti = ip.T / interpolation_rate
  interpolator_reset(ip, 0)
  return E.INTERPOLATOR_OK
end

-- returns err, x, v, a, j
local function interpolator_interpolate(ip)
  if ip.n < 4 then interpolator_push(ip, ip.x3) end -- auto refill
  local x, v, a, j
  if ip.x3 == ip.x2 and ip.x1 == ip.x3 then
    x, v, a, j = ip.x3, 0, 0, 0
  else
    local t = ip.t
    x = (((ip.a * t + ip.b) * t) + ip.c) * t + ip.d
    v = ((3.0 * ip.a * t) + 2.0 * ip.b) * t + ip.c
    a = 6.0 * ip.a * t + 2.0 * ip.b
    j = 6.0 * ip.a
  end
  ip.t = ip.t + ip.Ti
  if fabs(ip.T - ip.t) < 0.5 * ip.Ti then ip.n = ip.n - 1 end
  return E.INTERPOLATOR_OK, x, v, a, j
end

M.interpolator = {
  new           = interpolator_new,
  init          = interpolator_init,
  reset         = interpolator_reset,
  push          = interpolator_push,
  interpolate   = interpolator_interpolate,
  need_update   = interpolator_need_update,
}

-- ===========================================================================
-- kinematics_*: default identity model + manager (trajgen.c)
-- ===========================================================================

-- forward(joints) -> pose : joints is a 1..TG_MAX_JOINTS array of numbers.
local function kinematics_identity_forward(joints)
  return pose_new{
    x = joints[1], y = joints[2], z = joints[3],
    a = joints[4], b = joints[5], c = joints[6],
    u = joints[7], v = joints[8], w = joints[9],
  }
end

-- inverse(pose) -> joints
local function kinematics_identity_inverse(pose)
  return { pose.x, pose.y, pose.z, pose.a, pose.b, pose.c, pose.u, pose.v, pose.w }
end

local function kinematics_initialize(kin, device)
  device = device or {}
  -- both or neither of forward/inverse
  if (device.forward == nil) ~= (device.inverse == nil) then
    return E.KINEMATICS_ERR_INIT_FUNCTION_NULL
  end
  local fwd = device.forward or kinematics_identity_forward
  local inv = device.inverse or kinematics_identity_inverse
  -- Wrap forward so a user callback that returns a partial pose table
  -- (e.g. just {x,y,z,a}) is normalised to a full pose; the C version
  -- always writes into a fixed pose_t.
  kin.forward = function(joints) return pose_new(fwd(joints)) end
  kin.inverse = inv
  kin.reset = device.reset and function(j) return pose_new(device.reset(j)) end or kin.forward
  return E.KINEMATICS_ERR_OK
end

M.kinematics_identity_forward = kinematics_identity_forward
M.kinematics_identity_inverse = kinematics_identity_inverse

-- ===========================================================================
-- trajgen_coord_*: coordinated motion planner (trajgen.c)
-- ===========================================================================

-- motion type
local SG_INVALID, SG_LINEAR, SG_CIRCULAR, SG_CURVE, SG_END_OF_MOTION = 0, 1, 2, 3, 4
-- motion sync type
local TP_SYNC_NONE, TP_SYNC_VELOCITY, TP_SYNC_POSITION = 0, 1, 2
M.SG_LINEAR, M.SG_CIRCULAR = SG_LINEAR, SG_CIRCULAR
M.TP_SYNC_NONE, M.TP_SYNC_VELOCITY, M.TP_SYNC_POSITION = TP_SYNC_NONE, TP_SYNC_VELOCITY, TP_SYNC_POSITION

local Coord = {}
Coord.__index = Coord

local function coord_raise_error(tp, e)
  if tp._tg then tp._tg:_tg_err(e, 0) end
  tp.last_error = e
  return e
end

local function coord_new()
  local tp = setmetatable({
    config = { sample_interval = 0, max_velocity = 0, max_acceleration = 0 },
    last_error = 0,
    queue = { q = {}, size = TG_QUEUE_SIZE, num_elements = 0, start = 0, ["end"] = 0 },
    sync = { scaler = 0, reference = 0, i_offset = 0, type = TP_SYNC_NONE, i_isset = 0 },
    sync_dio_command = { set = 0, clear = 0 },
    sync_dio_current = 0,
    _i = { override = 1.0, last_position = pose_new() },
    num_queued_active = 0,
    sg_id = 0, next_sg_id = 0,
    blending_tolerance = 0,
    pose = pose_new(),
    end_pose = pose_new(),
    override = 1.0,
    is_aborting = false, is_pausing = false, is_done = true,
    override_enabled = 1,
    _tg = nil,
  }, Coord)
  return tp
end

-- new empty segment
local function sg_new()
  return {
    coords = { line = {}, arc = {}, curve = {} },
    id = 0, progress = 0, length = 0, v = 0, a = 0,
    current_velocity = 0, blending_tolerance = 0, blending_velocity = 0,
    sync_dio = { set = 0, clear = 0 },
    motion_type = SG_INVALID, sync_type = TP_SYNC_NONE,
    is_active = false, is_blending = false, override_enabled = 1,
  }
end

-- --- queue ------------------------------------------------------------------

local function queue_push_back(tp, sg)
  local q = tp.queue
  local nxt = (q["end"] + 1) % q.size
  if nxt == q.start then return coord_raise_error(tp, E.TP_ERR_QUEUE_FULL) end
  q.q[q["end"]] = sg
  q.num_elements = q.num_elements + 1
  q["end"] = nxt
  return E.TP_ERR_OK
end

local function queue_pop_front(tp, n)
  local q = tp.queue
  if n <= 0 then return E.TP_ERR_OK end
  if n > q.num_elements then
    return coord_raise_error(tp, E.TP_ERR_QUEUE_TO_MANY_ELEMENTS_TO_REMOVE)
  end
  q.start = (q.start + n) % q.size
  q.num_elements = q.num_elements - n
  return E.TP_ERR_OK
end

local function queue_front(tp)
  local q = tp.queue
  if q.num_elements == 0 then return nil end
  return q.q[q.start]
end

local function queue_get(tp, n)
  local q = tp.queue
  if n >= q.num_elements then return nil end
  return q.q[(q.start + n) % q.size]
end

function Coord:is_queue_full() return self.queue.num_elements >= self.queue.size - 1 end
function Coord:get_queue_size() return self.queue.size end
function Coord:get_current_id() return self.sg_id end
function Coord:get_position() return self.pose end
function Coord:is_done_() return self.is_done end
function Coord:get_num_queued() return self.queue.num_elements end
function Coord:get_num_queued_active() return self.num_queued_active end

function Coord:reset()
  self.last_error = E.TP_ERR_OK
  pose_set(self.end_pose, self.pose)
  pose_set(self._i.last_position, self.pose)
  self.queue.num_elements, self.queue.start, self.queue["end"] = 0, 0, 0
  self.queue.q = {}
  self.sg_id, self.next_sg_id, self.num_queued_active = 0, 0, 0
  self.is_aborting, self.is_pausing = false, false
  self.sync_dio_current, self.sync_dio_command.clear, self.sync_dio_command.set = 0, 0, 0
  self.override, self._i.override = 1.0, 1.0
  self.override_enabled = 1
  self.sync.type = TP_SYNC_NONE
  self.sync.reference = 0
  self.sync.i_offset, self.sync.i_isset = 0, 0
  self.is_done = true
  return E.TP_ERR_OK
end

function Coord:init(config)
  self:reset()
  self.queue.size = TG_QUEUE_SIZE
  self.config = { sample_interval = config.sample_interval,
                  max_velocity = config.max_velocity,
                  max_acceleration = config.max_acceleration }
  if config.max_acceleration <= 0.0 then
    return coord_raise_error(self, E.TP_ERR_INVALID_ACCEL)
  elseif config.max_velocity <= 0.0 then
    return coord_raise_error(self, E.TP_ERR_INVALID_SPEED)
  elseif config.sample_interval <= 0.0 then
    return coord_raise_error(self, E.TP_ERR_INVALID_SAMPLE_INTERVAL)
  end
  return E.TP_ERR_OK
end

function Coord:set_position(p)
  pose_set(self.pose, p)
  pose_set(self.end_pose, p)
  return E.TP_ERR_OK
end

function Coord:pause() self.is_pausing = true; return E.TP_ERR_OK end
function Coord:resume() self.is_pausing = false; return E.TP_ERR_OK end

function Coord:abort()
  if not self.is_aborting then
    self.is_pausing, self.is_aborting = true, true
  end
  self.sync_dio_command.clear, self.sync_dio_command.set = 0, 0
  return E.TP_ERR_OK
end

-- --- segment helpers ------------------------------------------------------

local function sg_start_direction(tp, sg, result)
  if sg.motion_type == SG_LINEAR then
    v_sub(sg.coords.line.xyz.p1, sg.coords.line.xyz.p0, result)
    v_unit(result, result)
    return E.TP_ERR_OK
  elseif sg.motion_type == SG_CIRCULAR then
    local startpoint, radius, tan, perp = v_new(), v_new(), v_new(), v_new()
    v_arc_get(sg.coords.arc.xyz, 0.0, startpoint)
    v_sub(startpoint, sg.coords.arc.xyz.cp, radius)
    v_cross(sg.coords.arc.xyz.nv, radius, tan)
    v_unit(tan, tan)
    v_sub(sg.coords.arc.xyz.cp, startpoint, perp)
    v_unit(perp, perp)
    v_scale(tan, sg.a, tan)
    v_scale(perp, sqr(0.5 * sg.v) / sg.coords.arc.xyz.r, perp)
    v_sum(tan, perp, result)
    v_unit(result, result)
    return E.TP_ERR_OK
  end
  return coord_raise_error(tp, E.TP_ERR_INVALID_MOTION_TYPE)
end

local function sg_end_direction(tp, sg, result)
  if sg.motion_type == SG_LINEAR then
    v_sub(sg.coords.line.xyz.p1, sg.coords.line.xyz.p0, result)
    v_unit(result, result)
    return E.TP_ERR_OK
  elseif sg.motion_type == SG_CIRCULAR then
    local endpoint, radius = v_new(), v_new()
    v_arc_get(sg.coords.arc.xyz, sg.coords.arc.xyz.a, endpoint)
    v_sub(endpoint, sg.coords.arc.xyz.cp, radius)
    v_cross(sg.coords.arc.xyz.nv, radius, result)
    v_unit(result, result)
    return E.TP_ERR_OK
  end
  return coord_raise_error(tp, E.TP_ERR_INVALID_MOTION_TYPE)
end

local function sg_activate(sg)
  if sg.is_active then return E.TP_ERR_OK end
  sg.is_active = true
  sg.is_blending = false
  sg.blending_velocity = 0.0
  sg.progress = 0.0
  sg.current_velocity = 0.0
  return E.TP_ERR_OK
end

local SG_OF_CURR, SG_OF_END = 0, 1

-- writes start/current/end pose of a segment into pos
local function sg_get_pose(tp, sg, of_endpoint, pos)
  local xyz, abc, uvw = v_new(), v_new(), v_new()
  local progress = (of_endpoint == SG_OF_END) and sg.length or sg.progress
  local mt = sg.motion_type
  if mt == SG_LINEAR then
    local L = sg.coords.line
    if L.xyz.tm > 0. then
      v_lin_get(L.xyz, progress, xyz)
      v_lin_get(L.abc, progress * L.abc.tm / sg.length, abc)
      v_lin_get(L.uvw, progress * L.uvw.tm / sg.length, uvw)
    elseif L.abc.tm > 0. then
      v_lin_get(L.abc, progress, abc)
      v_cpy(L.xyz.p0, xyz)
      v_cpy(L.uvw.p0, uvw)
    elseif L.uvw.tm > 0. then
      v_lin_get(L.uvw, progress, uvw)
      v_cpy(L.xyz.p0, xyz)
      v_cpy(L.abc.p0, abc)
    else
      v_cpy(L.xyz.p0, xyz)
      v_cpy(L.abc.p0, abc)
      v_cpy(L.uvw.p0, uvw)
    end
  elseif mt == SG_CIRCULAR then
    local A = sg.coords.arc
    v_arc_get(A.xyz, progress, xyz)
    v_lin_get(A.abc, progress * A.abc.tm / sg.length, abc)
    v_lin_get(A.uvw, progress * A.uvw.tm / sg.length, uvw)
  else
    v_invalidate(xyz); v_invalidate(abc); v_invalidate(uvw)
    coord_raise_error(tp, E.TP_ERR_INVALID_MOTION_TYPE)
  end
  v_pose_merge(xyz, abc, uvw, pos)
  return E.TP_ERR_OK
end

-- calculate next linearised position for a segment.
-- returns err, overrun, v, a, v0
local function sg_tick(tp, sg)
  local T = tp.config.sample_interval
  local d, vn0, vn, an = 0, 0, 0, 0
  local overrun = 0
  local branch_stop
  if sg.progress >= sg.length then
    branch_stop = true
  else
    d = sg.current_velocity * T + 2. * (sg.progress - sg.length)
    if d >= 0 then
      branch_stop = true
    else
      vn0 = (sqrtz(T * T / 4 - d / sg.a) - T / 2) * sg.a
      if vn0 < TG_RESOLUTION then branch_stop = true end
    end
  end

  if branch_stop then
    an, vn, vn0 = 0.0, 0.0, 0.0
    d = sg.progress - sg.length
    sg.progress = sg.length
  else
    if vn0 > tp.config.max_velocity then vn0 = tp.config.max_velocity end
    if vn0 > sg.v then vn0 = sg.v end
    vn = vn0
    if vn > sg.v * tp._i.override then vn = sg.v * tp._i.override end
    an = (vn - sg.current_velocity) / T
    local aa = sg.a
    an = (an > aa) and aa or ((an < -aa) and -aa or an)
    vn = sg.current_velocity + an * T
    sg.progress = sg.progress + (vn + sg.current_velocity) * T / 2
    d = sg.progress - sg.length
    if d >= 0 then
      sg.progress = sg.length
      vn, an, vn0 = 0, 0, 0
    end
  end
  sg.current_velocity = vn
  if d > 0 then overrun = d end
  return E.TP_ERR_OK, overrun, vn, an, vn0
end

-- --- add_line / add_arc --------------------------------------------------

function Coord:add_line(end_point, velocity, acceleration)
  local sg = sg_new()
  sg.sync_dio = { set = self.sync_dio_command.set, clear = self.sync_dio_command.clear }
  self.sync_dio_command.clear, self.sync_dio_command.set = 0, 0
  if self.is_aborting then return coord_raise_error(self, E.TP_ERR_ABORTING) end
  if self:is_queue_full() then return coord_raise_error(self, E.TP_ERR_QUEUE_FULL) end
  acceleration = (acceleration == 0) and self.config.max_acceleration or acceleration
  if velocity < TG_RESOLUTION or velocity > self.config.max_velocity then
    return coord_raise_error(self, E.TP_ERR_INVALID_SPEED)
  elseif acceleration < TG_RESOLUTION or acceleration > self.config.max_acceleration then
    return coord_raise_error(self, E.TP_ERR_INVALID_ACCEL)
  elseif not pose_isfinite(end_point) then
    return coord_raise_error(self, E.TP_ERR_INVALID_POSE)
  end

  local sxyz, sabc, suvw = v_new(), v_new(), v_new()
  local exyz, eabc, euvw = v_new(), v_new(), v_new()
  v_pose_split(self.end_pose, sxyz, sabc, suvw)
  v_pose_split(end_point, exyz, eabc, euvw)

  local L = sg.coords.line
  L.xyz, L.abc, L.uvw = {}, {}, {}
  if v_lin_define(L.xyz, sxyz, exyz) ~= 0
     or v_lin_define(L.uvw, suvw, euvw) ~= 0
     or v_lin_define(L.abc, sabc, eabc) ~= 0 then
    return coord_raise_error(self, E.TP_ERR_INVALID_PARAM)
  end

  sg.length = (L.xyz.tm > TG_D_RES) and L.xyz.tm
              or ((L.uvw.tm > TG_D_RES) and L.uvw.tm or L.abc.tm)
  if sg.length < TG_RESOLUTION then
    sg.length = 0
    return coord_raise_error(self, E.TP_ERR_SEGMENT_LENGTH_ZERO)
  end
  sg.id = self.next_sg_id
  sg.is_active = false
  sg.v = velocity
  sg.a = acceleration
  sg.blending_tolerance = (self.blending_tolerance < TG_RESOLUTION) and 0 or self.blending_tolerance
  sg.sync_type = self.sync.type
  sg.override_enabled = self.override_enabled
  sg.motion_type = SG_LINEAR
  if queue_push_back(self, sg) ~= 0 then return self.last_error end
  pose_set(self.end_pose, end_point)
  self.next_sg_id = self.next_sg_id + 1
  self.is_done = false
  return E.TP_ERR_OK
end

function Coord:add_arc(end_point, center, normal, n_turns, velocity, acceleration)
  local sg = sg_new()
  sg.sync_dio = { set = self.sync_dio_command.set, clear = self.sync_dio_command.clear }
  self.sync_dio_command.clear, self.sync_dio_command.set = 0, 0
  sg.motion_type = SG_CIRCULAR
  sg.id = self.next_sg_id
  sg.is_active = false
  sg.sync_type = self.sync.type
  sg.override_enabled = self.override_enabled
  sg.blending_tolerance = (self.blending_tolerance < TG_RESOLUTION) and 0 or self.blending_tolerance
  if self.is_aborting then return coord_raise_error(self, E.TP_ERR_ABORTING) end
  if self:is_queue_full() then return coord_raise_error(self, E.TP_ERR_QUEUE_FULL) end
  acceleration = (acceleration == 0) and self.config.max_acceleration or acceleration
  if velocity < TG_RESOLUTION or velocity > self.config.max_velocity then
    return coord_raise_error(self, E.TP_ERR_INVALID_SPEED)
  elseif acceleration < TG_RESOLUTION or acceleration > self.config.max_acceleration then
    return coord_raise_error(self, E.TP_ERR_INVALID_ACCEL)
  elseif not pose_isfinite(end_point) or not v_isfinite(center) or not v_isfinite(normal) then
    return coord_raise_error(self, E.TP_ERR_INVALID_POSE)
  end
  sg.v = velocity
  sg.a = acceleration
  local sxyz, sabc, suvw = v_new(), v_new(), v_new()
  local exyz, eabc, euvw = v_new(), v_new(), v_new()
  v_pose_split(self.end_pose, sxyz, sabc, suvw)
  v_pose_split(end_point, exyz, eabc, euvw)

  local A = sg.coords.arc
  A.xyz, A.abc, A.uvw = {}, {}, {}
  if v_distance(sxyz, center) < TG_RESOLUTION or v_distance(exyz, center) < TG_RESOLUTION then
    return coord_raise_error(self, E.TP_ERR_SEGMENT_LENGTH_ZERO)
  elseif v_arc_define(A.xyz, sxyz, exyz, center, normal, n_turns) ~= 0
      or v_lin_define(A.abc, sabc, eabc) ~= 0
      or v_lin_define(A.uvw, suvw, euvw) ~= 0 then
    return coord_raise_error(self, E.TP_ERR_INVALID_PARAM)
  elseif A.xyz.a == 0 then
    return coord_raise_error(self, E.TP_ERR_SEGMENT_LENGTH_ZERO)
  end
  sg.length = A.xyz.l
  if sg.length < TG_RESOLUTION then
    sg.length = 0
    return coord_raise_error(self, E.TP_ERR_SEGMENT_LENGTH_ZERO)
  end
  if queue_push_back(self, sg) ~= 0 then return self.last_error end
  pose_set(self.end_pose, end_point)
  self.next_sg_id = self.next_sg_id + 1
  self.is_done = false
  return E.TP_ERR_OK
end

-- --- coordinated tick ---------------------------------------------------

function Coord:tick()
  local tp = self
  local err = E.TP_ERR_OK

  tp._i.override = tp.override
  pose_set(tp._i.last_position, tp.pose)

  local sg = queue_front(tp)
  if not sg then
    tp.queue.num_elements, tp.queue.start, tp.queue["end"] = 0, 0, 0
    tp.queue.q = {}
    pose_set(tp.end_pose, tp.pose)
    tp.is_done = true
    tp.num_queued_active, tp.sg_id = 0, 0
    tp.is_pausing, tp.is_aborting = false, false
    tp.sync.i_offset, tp.sync.i_isset = 0, 0
    return E.TP_ERR_OK
  elseif sg.progress == sg.length then
    queue_pop_front(tp, 1)
    sg = queue_front(tp)
    if not sg then return E.TP_ERR_OK end
  end

  local nextsg = nil
  if NO_MOTION_BLENDING == 0 and sg.blending_tolerance > 0 then
    nextsg = queue_get(tp, 1)
  end

  -- abort handling
  if tp.is_aborting then
    if sg.current_velocity == 0.0 and (not nextsg or nextsg.current_velocity == 0.0) then
      tp.queue.num_elements, tp.queue.start, tp.queue["end"] = 0, 0, 0
      tp.queue.q = {}
      pose_set(tp.end_pose, tp.pose)
      tp.is_done = true
      tp.is_aborting, tp.is_pausing = false, false
      tp.num_queued_active, tp.sg_id, tp.sync_dio_current = 0, 0, 0
      return E.TP_ERR_OK
    else
      sg.v = 0.0
      sg.a = tp.config.max_acceleration
      if nextsg then
        nextsg.v = 0.0
        nextsg.a = tp.config.max_acceleration
      end
    end
  end

  -- start of motion
  if not sg.is_active then
    sg_activate(sg)
    tp.sg_id = sg.id
    tp.num_queued_active = 1
    tp.sync_dio_current = band(bor(tp.sync_dio_current, sg.sync_dio.set), bnot(sg.sync_dio.clear))
  end

  if sg.override_enabled == 0 then tp._i.override = 1.0 end

  -- handle next queued segment (blending)
  if nextsg and not nextsg.is_active then
    if (nextsg.sync_type ~= TP_SYNC_NONE and not isfinite(tp.sync.reference * tp.sync.scaler))
       or (nextsg.sync_type ~= TP_SYNC_NONE and tp.sync.scaler == 0)
       or (nextsg.sync_type == TP_SYNC_VELOCITY and tp.sync.reference <= 0) then
      sg.blending_tolerance = 0
      nextsg = nil
    else
      local v1, v2 = v_new(), v_new()
      if sg_end_direction(tp, sg, v1) ~= E.TP_ERR_OK
         or sg_start_direction(tp, nextsg, v2) ~= E.TP_ERR_OK then
        return coord_raise_error(tp, E.TP_ERR_UNIT_VECTOR_CALC_INVALID_TYPE)
      end
      local cos_phi = v_dot(v1, v2)
      local phi
      if cos_phi < 0 then
        sg.blending_tolerance = 0
        nextsg = nil
      else
        phi = acos(cos_phi > 1 and 1 or cos_phi)
        if phi > M_PI / 180. * MAX_ALLOWED_BLENDING_ANGLE_DEG then
          sg.blending_tolerance = 0
          nextsg = nil
        else
          local vblend = sqrtz(nextsg.length / 2 * (sg.a < nextsg.a and sg.a or nextsg.a))
          if cos_phi > 1 then cos_phi = 1 end
          if cos_phi > 0 and phi > M_PI / 180 * STRAIGHT_BLENDING_ANGLE then
            local vv = 2.0 * sqrtz(sg.a * sg.blending_tolerance / cos_phi)
            if vblend > vv then vblend = vv end
          else
            sg.blending_tolerance = TG_RESOLUTION
          end
          if vblend > nextsg.v then vblend = nextsg.v end
          if vblend > sg.v then vblend = sg.v end
          sg.blending_velocity = vblend
          sg_activate(nextsg)
          tp.num_queued_active = 2
        end
      end
    end
  end

  -- syncing
  tp.sync.i_isset = (sg.sync_type == TP_SYNC_POSITION) and tp.sync.i_isset or 0
  local handled_sync = false
  if sg.sync_type == TP_SYNC_VELOCITY and not tp.is_aborting then
    handled_sync = true
    local vv = tp.sync.scaler * tp.sync.reference
    if tp.is_pausing or not isfinite(vv) or vv < 0 then vv = 0 end
    if vv < sg.v then tp._i.override = tp._i.override * (vv / sg.v) end
  elseif sg.sync_type == TP_SYNC_POSITION then
    handled_sync = true
    if sg.progress >= sg.length then
      tp.sync.i_isset = (isfinite(tp.sync.reference * tp.sync.scaler) and tp.sync.scaler ~= 0) and 1 or 0
      tp.sync.i_offset = tp.sync.i_offset + ((tp.sync.i_isset ~= 0) and sg.length or 0.0)
    elseif tp.sync.i_isset == 0 and isfinite(tp.sync.reference * tp.sync.scaler) and tp.sync.scaler ~= 0 then
      tp.sync.i_offset = (tp.sync.reference * tp.sync.scaler) - sg.progress
      tp.sync.i_isset = 1
    end
    if tp.sync.i_isset == 0 then
      tp._i.override = 0
    else
      local ds = (tp.sync.reference * tp.sync.scaler) - tp.sync.i_offset
                 - sg.progress - (nextsg and nextsg.progress or 0.0)
      if not isfinite(ds) or tp.sync.scaler == 0 then
        err = coord_raise_error(tp, E.TP_ERR_REF_POSITION_INVALIDATED_DURING_MOTION)
        tp:abort()
        tp._i.override = 0
      elseif ds < 0 then
        tp._i.override = 0
      else
        local T = tp.config.sample_interval
        local dv = ds / T - sg.a * T / 2.0
        local o = (sg.current_velocity + dv) / sg.v
        tp._i.override = (o < 0) and 0 or ((o > 1) and 1 or o)
      end
    end
  end
  if not handled_sync and tp.is_pausing then
    tp._i.override = 0
  end

  if not nextsg then
    sg_tick(tp, sg)
    sg_get_pose(tp, sg, SG_OF_CURR, tp.pose)
    return err
  elseif not sg.is_blending then
    local _, _, v, _, vn = sg_tick(tp, sg)
    sg_get_pose(tp, sg, SG_OF_CURR, tp.pose)
    if (sg.progress / sg.length > 0.5) and (vn < sg.blending_velocity) then
      nextsg.current_velocity = sg.blending_velocity - sg.current_velocity
      sg.is_blending = true
    end
  else
    local last_pose, curr_pose = pose_new(), pose_new()
    local nextsg_last_pose, nextsg_curr_pose = pose_new(), pose_new()
    sg_get_pose(tp, sg, SG_OF_CURR, last_pose)
    local _, _, v = sg_tick(tp, sg)
    sg_get_pose(tp, sg, SG_OF_CURR, curr_pose)
    if tp.sg_id ~= nextsg.id and sg.current_velocity < nextsg.current_velocity then
      tp.sync_dio_current = band(bor(tp.sync_dio_current, nextsg.sync_dio.set), bnot(nextsg.sync_dio.clear))
      tp.sg_id = nextsg.id
    end
    sg_get_pose(tp, nextsg, SG_OF_CURR, nextsg_last_pose)
    local vv = nextsg.v
    nextsg.v = sg.blending_velocity - v
    if nextsg.v < 0.0 then nextsg.v = 0 end
    sg_tick(tp, nextsg)
    nextsg.v = vv
    sg_get_pose(tp, nextsg, SG_OF_CURR, nextsg_curr_pose)
    pose_set(tp.pose, tp._i.last_position)
    pose_acc(tp.pose, curr_pose)
    pose_sub(tp.pose, last_pose)
    pose_acc(tp.pose, nextsg_curr_pose)
    pose_sub(tp.pose, nextsg_last_pose)
  end
  return err
end

M.coord = {
  new = coord_new,
}

-- ===========================================================================
-- trajgen_jointtg_*: free single-axis planner (trajgen.c)
-- ===========================================================================

local JointTg = {}
JointTg.__index = JointTg

local function jointtg_new()
  return setmetatable({
    last_error = 0,
    config = { max_acceleration = 0, max_velocity = 0, sample_interval = 0 },
    velocity = 0, position = 0,
    command_position = 0, command_velocity = 0,
    is_enabled = false, is_pause = false, is_done = true,
  }, JointTg)
end

local function jointtg_err(tp, e) tp.last_error = e; return e end

function JointTg:initialize(config)
  self.config = { max_acceleration = config.max_acceleration or 0,
                  max_velocity = config.max_velocity or 0,
                  sample_interval = config.sample_interval or 0 }
  self.velocity, self.position = 0.0, 0.0
  self.is_enabled = false
  self.last_error = E.TRAJGEN_FREE_ERROR_OK
  if self.config.max_acceleration < 0.0 then
    return jointtg_err(self, E.TRAJGEN_FREE_ERROR_INIT_INVALID_MAX_ACCEL)
  elseif self.config.max_velocity < 0.0 then
    return jointtg_err(self, E.TRAJGEN_FREE_ERROR_INIT_INVALID_MAX_VELOCITY)
  elseif self.config.sample_interval <= 0 then
    return jointtg_err(self, E.TRAJGEN_FREE_ERROR_INIT_INVALID_SAMPLE_INTERVAL)
  end
  return E.TRAJGEN_FREE_ERROR_OK
end

function JointTg:reset()
  self.velocity = 0.0
  self.command_position = self.position
  self.last_error = E.TRAJGEN_FREE_ERROR_OK
  self.is_pause = false
  self.is_done = true
  return E.TRAJGEN_FREE_ERROR_OK
end

function JointTg:set_enabled(enabled)
  if enabled == self.is_enabled then
    return E.TRAJGEN_FREE_ERROR_OK
  elseif not enabled then
    self.is_enabled = false
  else
    if self.is_done then self:reset() end
    self.is_enabled = true
  end
  return E.TRAJGEN_FREE_ERROR_OK
end

function JointTg:set_command_position(position)
  self.command_position = position
  return E.TRAJGEN_FREE_ERROR_OK
end

function JointTg:set_command_velocity(velocity)
  if velocity > self.config.max_velocity then
    velocity = self.config.max_velocity
  elseif velocity < -self.config.max_velocity then
    velocity = -self.config.max_velocity
  end
  self.command_velocity = velocity
  return E.TRAJGEN_FREE_ERROR_OK
end

function JointTg:get_current_position() return self.position end
function JointTg:set_current_position(position) self.position = position; return E.TRAJGEN_FREE_ERROR_OK end
function JointTg:is_done_() return self.is_done and self.velocity == 0.0 end

function JointTg:tick()
  if self.command_velocity < 0 then self.is_enabled = false end
  if not self.is_enabled then self.command_position = self.position end
  if self.is_enabled or self.velocity ~= 0 or self.command_position ~= self.position then
    local T = self.config.sample_interval
    local dp = self.command_position - self.position
    local vd = self.config.max_acceleration * T
    local dir = dp > 0 and 1 or -1
    local v
    dp = dp * dir
    if dp < TG_RESOLUTION then dp = 0 end
    v = (dp <= 0) and 0 or (sqrt(2.0 * self.config.max_acceleration * dp + vd * vd) - vd)
    if self.is_pause then v = 0 end
    if v > self.config.max_velocity and self.config.max_velocity > 0 then v = self.config.max_velocity end
    if v > self.command_velocity and self.command_velocity > 0 then v = self.command_velocity end
    v = v * dir
    if v > self.velocity + vd then
      self.velocity = self.velocity + vd
    elseif v < self.velocity - vd then
      self.velocity = self.velocity - vd
    else
      self.velocity = v
    end
    self.position = self.position + self.velocity * T
    if v < TG_RESOLUTION and fabs(self.position - self.command_position) < TG_RESOLUTION then
      self.position = self.command_position
      self.velocity = 0.0
    end
  end
  self.is_done = (self.velocity == 0.0 and self.position == self.command_position)
  return E.TRAJGEN_FREE_ERROR_OK
end

M.jointtg = { new = jointtg_new }

-- ===========================================================================
-- trajgen_man_*: manual / tele-operation planner (trajgen.c)
-- ===========================================================================

local Man = {}
Man.__index = Man

local function man_new()
  return setmetatable({
    last_error = 0,
    config = { max_velocity = pose_new(), max_acceleration = pose_new(), sample_interval = 0 },
    velocity = pose_new(),
    current_velocity = pose_new(),
    pose = pose_new(),
    is_enabled = false,
  }, Man)
end

local function man_err(mtp, e) mtp.last_error = e; return e end

function Man:initialize(config)
  pose_set_zero(self.velocity)
  pose_set_zero(self.current_velocity)
  pose_set_zero(self.pose)
  self.is_enabled = false
  if not pose_is_all_greater_equal_zero(config.max_acceleration) then
    return man_err(self, E.TG_MAN_ERROR_INIT_INVALID_MAX_ACCEL)
  elseif not pose_is_all_greater_equal_zero(config.max_velocity) then
    return man_err(self, E.TG_MAN_ERROR_INIT_INVALID_MAX_VELOCITY)
  elseif config.sample_interval <= 0 then
    return man_err(self, E.TG_MAN_ERROR_INIT_INVALID_SAMPLE_INTERVAL)
  end
  self.config = {
    max_velocity = pose_new(config.max_velocity),
    max_acceleration = pose_new(config.max_acceleration),
    sample_interval = config.sample_interval,
  }
  return E.TG_MAN_ERROR_OK
end

function Man:reset()
  pose_set_zero(self.velocity)
  pose_set_zero(self.current_velocity)
  self.is_enabled = false
  self.last_error = E.TG_MAN_ERROR_OK
  return E.TG_MAN_ERROR_OK
end

function Man:abort() self.is_enabled = false; return E.TG_MAN_ERROR_OK end
function Man:is_done_() return pose_is_zero(self.velocity) and pose_is_zero(self.current_velocity) end
function Man:get_position() return self.pose end
function Man:set_position(position) pose_set(self.pose, position); return E.TG_MAN_ERROR_OK end

function Man:set_velocity(speed)
  local s = pose_new(speed)
  pose_trim_all_upper(s, self.config.max_velocity)
  pose_neg(s)
  pose_trim_all_upper(s, self.config.max_velocity)
  pose_neg(s)
  pose_set(self.velocity, s)
  return E.TG_MAN_ERROR_OK
end

function Man:tick()
  local T = self.config.sample_interval
  local dv = pose_new()
  if not self.is_enabled then pose_set_zero(self.velocity) end
  pose_diff(self.velocity, self.current_velocity, dv)
  if not pose_is_zero(dv) then
    local d, scl = 0, 1.
    pose_scale(dv, 1. / T)
    local ma = self.config.max_acceleration
    if dv.x ~= 0 then d = fabs(ma.x / dv.x); if d < scl then scl = d end end
    if dv.y ~= 0 then d = fabs(ma.y / dv.y); if d < scl then scl = d end end
    if dv.z ~= 0 then d = fabs(ma.z / dv.z); if d < scl then scl = d end end
    if dv.a ~= 0 then d = fabs(ma.a / dv.a); if d < scl then scl = d end end
    if dv.b ~= 0 then d = fabs(ma.b / dv.b); if d < scl then scl = d end end
    if dv.c ~= 0 then d = fabs(ma.c / dv.c); if d < scl then scl = d end end
    if dv.u ~= 0 then d = fabs(ma.u / dv.u); if d < scl then scl = d end end
    if dv.v ~= 0 then d = fabs(ma.v / dv.v); if d < scl then scl = d end end
    if dv.w ~= 0 then d = fabs(ma.w / dv.w); if d < scl then scl = d end end
    if scl < 1.0 then
      d = scl * T
      pose_scale(dv, d)
      pose_acc(self.current_velocity, dv)
    else
      pose_set(self.current_velocity, self.velocity)
    end
  end
  pose_set(dv, self.current_velocity)
  pose_scale(dv, T)
  pose_acc(self.pose, dv)
  return E.TG_MAN_ERROR_OK
end

M.man = { new = man_new }

-- ===========================================================================
-- trajgen_*: main trajectory generation coordinator (trajgen.c)
-- ===========================================================================

-- operating mode states
local S = {
  TRAJ_STATE_DISABLED = 0,
  TRAJ_STATE_JOINT = 1,
  TRAJ_STATE_COORDINATED = 2,
  TRAJ_STATE_MAN = 3,
  TRAJ______INTERNAL_STATES = 4,
  TRAJ_STATE_OK_TO_SWITCH = 5,
  TRAJ_STATE_DISABLING = 6,
  TRAJ_STATE_JOINT_ENTER = 7,
  TRAJ_STATE_JOINT_LEAVE = 8,
  TRAJ_STATE_COORDINATED_ENTER = 9,
  TRAJ_STATE_COORDINATED_LEAVE = 10,
  TRAJ_STATE_TG_MAN_ENTER = 11,
  TRAJ_STATE_TG_MAN_LEAVE = 12,
}
for k, val in pairs(S) do M[k] = val end

local STATE_NAMES = {
  [0] = "disabled", "jointtg", "coordinated", "manual", "INVALID",
  "(ok-to-switch)", "(disabling)", "(jointtg enter)", "(jointtg leave)",
  "(coordinated enter)", "(coordinated leave)", "(manual enter)", "(manual leave)",
}
function M.state_name(s) return STATE_NAMES[s] or "INVALID" end

local Trajgen = {}
Trajgen.__index = Trajgen

function Trajgen:_tg_err(code, joint)
  self.last_error = err_encode(code, joint)
  return code
end

-- --- coordinated planer wrappers (APPLY COORDINATED MOTION PLANER ONLY) ---

function Trajgen:queue_full()  return self.coord_planer:is_queue_full() end
function Trajgen:current_id()   return self.coord_planer:get_current_id() end
function Trajgen:num_queued()   return self.coord_planer:get_num_queued() end
function Trajgen:queue_size()   return self.coord_planer:get_queue_size() end

function Trajgen:pause()
  for i = 1, self.config.number_of_used_joints do self.joints[i].tg.is_pause = true end
  return self:_tg_err(self.coord_planer:pause(), 0)
end

function Trajgen:resume()
  for i = 1, self.config.number_of_used_joints do self.joints[i].tg.is_pause = false end
  return self:_tg_err(self.coord_planer:resume(), 0)
end

function Trajgen:add_line(end_pose, velocity, acceleration)
  local e = self:_tg_err(self.coord_planer:add_line(pose_new(end_pose), velocity, acceleration or 0), 0)
  if e == 0 then self.is_done = false end
  return e
end

function Trajgen:add_arc(end_pose, center, normal, n_turns, velocity, acceleration)
  local e = self:_tg_err(self.coord_planer:add_arc(pose_new(end_pose), v_new(center.x, center.y, center.z),
      v_new(normal.x, normal.y, normal.z), n_turns or 0, velocity, acceleration or 0), 0)
  if e == 0 then self.is_done = false end
  return e
end

function Trajgen:set_blending_tolerance(t)
  self.coord_planer.blending_tolerance = t or 0
end

function Trajgen:joint_command_velocity(joint, v)
  if joint > self.config.number_of_used_joints then
    return self:_tg_err(E.TRAJ_ERROR_INVALID_JOINT_NO, 0)
  end
  return self:_tg_err(self.joints[joint].tg:set_command_velocity(v), 0)
end

function Trajgen:get_tick() return self._internals.tick end

function Trajgen:abort()
  self.coord_planer:abort()
  self.man_planer:abort()
  for i = 1, TG_MAX_JOINTS do self.joints[i].tg.is_enabled = false end
  self.is_done = false
  self.requested_state = S.TRAJ_STATE_DISABLED
  return E.TRAJ_ERROR_OK
end

function Trajgen:switch_state(state)
  if state < S.TRAJ_STATE_DISABLED or state >= S.TRAJ______INTERNAL_STATES then
    return self:_tg_err(E.TRAJ_ERROR_INVALID_SWITCHING_STATE, 0)
  end
  self.is_done = false
  self.requested_state = state
  return E.TRAJ_ERROR_OK
end

-- joint_positions() / planer_positions() build the 1..TG_MAX_JOINTS arrays the
-- kinematics callbacks take (the C passes an array of pointers into the joints).
local function joint_positions(self)
  local t = {}
  for i = 1, TG_MAX_JOINTS do t[i] = self.joints[i].position end
  return t
end

local function apply_planer_positions(self, joints)
  for i = 1, self.config.number_of_used_joints do
    self.joints[i].planer_position = joints[i] or 0
  end
end

function Trajgen:reset()
  for i = 1, self.config.number_of_used_joints do
    self.joints[i].planer_position = self.joints[i].position
    self.joints[i].tg.command_position = self.joints[i].position
    self.joints[i].tg:reset()
    interpolator_reset(self.joints[i].interpolator, self.joints[i].planer_position)
  end
  self.planer_pose = self.kinematics.forward(joint_positions(self))
  self._internals.tick = 0
  self.coord_planer:reset()
  self.man_planer:reset()
  self.is_done = true
  self.state = S.TRAJ_STATE_DISABLED
  return E.TRAJ_ERROR_OK
end

function Trajgen:_reset_positions()
  for i = 1, self.config.number_of_used_joints do
    self.joints[i].planer_position = self.joints[i].position
    self.joints[i].tg.command_position = self.joints[i].position
    self.joints[i].acceleration, self.joints[i].velocity, self.joints[i].jerk = 0, 0, 0
    interpolator_reset(self.joints[i].interpolator, self.joints[i].position)
  end
  self.planer_pose = self.kinematics.forward(joint_positions(self))
  self.coord_planer:set_position(self.planer_pose)
  self.man_planer:set_position(self.planer_pose)
  return E.TRAJ_ERROR_OK
end

function Trajgen:tick()
  local err
  self._internals.tick = self._internals.tick + 1

  -- Commanded state switching
  if self.state ~= self.requested_state then
    local st = self.state
    if st == S.TRAJ_STATE_DISABLED or st == S.TRAJ_STATE_OK_TO_SWITCH then
      local rs = self.requested_state
      if rs == S.TRAJ_STATE_COORDINATED then
        self.state = S.TRAJ_STATE_COORDINATED_ENTER; self.is_done = false
      elseif rs == S.TRAJ_STATE_JOINT then
        self.state = S.TRAJ_STATE_JOINT_ENTER; self.is_done = false
      elseif rs == S.TRAJ_STATE_MAN then
        self.state = S.TRAJ_STATE_TG_MAN_ENTER; self.is_done = false
      elseif rs == S.TRAJ_STATE_DISABLED then
        -- nothing
      else
        self.requested_state = S.TRAJ_STATE_DISABLED
        return self:_tg_err(E.TRAJ_ERROR_INVALID_SWITCHING_STATE, 0)
      end
    elseif st == S.TRAJ_STATE_COORDINATED then
      self.state = S.TRAJ_STATE_COORDINATED_LEAVE
    elseif st == S.TRAJ_STATE_JOINT then
      self.state = S.TRAJ_STATE_JOINT_LEAVE
    elseif st == S.TRAJ_STATE_MAN then
      self.state = S.TRAJ_STATE_TG_MAN_LEAVE
    end
  end

  local st = self.state
  local cfg = self.config
  local njoints = cfg.number_of_used_joints

  -- ---- COORDINATED family --------------------------------------------------
  if st == S.TRAJ_STATE_COORDINATED_ENTER then
    -- Reset the coord planer position to the main generator position.
    self:_reset_positions()
    self.state = S.TRAJ_STATE_COORDINATED
    self.is_done = true
    return E.TRAJ_ERROR_OK -- C: break
  end

  if st == S.TRAJ_STATE_COORDINATED_LEAVE or st == S.TRAJ_STATE_COORDINATED then
    if st == S.TRAJ_STATE_COORDINATED_LEAVE then
      -- Stop the motion; can be called every cycle until done. C: no break,
      -- the planer keeps running below until the motion is finished.
      self.coord_planer:abort()
      if self.is_done then self.state = S.TRAJ_STATE_OK_TO_SWITCH end
    end
    if interpolator_need_update(self.joints[1].interpolator) then
      err = self.coord_planer:tick()
      if err ~= 0 then return self:_tg_err(err, 0) end
      self.planer_pose = self.coord_planer:get_position()
      local jp = self.kinematics.inverse(self.planer_pose)
      apply_planer_positions(self, jp)
      for i = 1, njoints do
        local e = interpolator_push(self.joints[i].interpolator, self.joints[i].planer_position)
        if e ~= 0 then return self:_tg_err(e, i - 1) end
      end
    end
    local v0 = true
    if not interpolator_need_update(self.joints[1].interpolator) then
      for i = 1, njoints do
        local joint = self.joints[i]
        local e, x, vel, a, j = interpolator_interpolate(joint.interpolator)
        if e ~= 0 then return self:_tg_err(e, i - 1) end
        joint.position, joint.velocity, joint.acceleration, joint.jerk = x, vel, a, j
        v0 = v0 and (vel < TG_RESOLUTION)
        if not isfinite(joint.position) then return self:_tg_err(E.TRAJ_ERROR_NUMERIC, i - 1) end
      end
    end
    self.is_done = self.coord_planer:is_done_() and v0
    return E.TRAJ_ERROR_OK

  -- ---- JOINT family ------------------------------------------------------
  elseif st == S.TRAJ_STATE_JOINT_ENTER or st == S.TRAJ_STATE_JOINT_LEAVE or st == S.TRAJ_STATE_JOINT then
    if st == S.TRAJ_STATE_JOINT_ENTER then
      self:_reset_positions()
      for i = 1, njoints do
        local e = self.joints[i].tg:reset()
        if e ~= 0 then
          self:_tg_err(e, i - 1)
        else
          if cfg.joints[i].max_acceleration > 0 and cfg.joints[i].max_velocity > 0 then
            self.joints[i].tg.is_enabled = true
            self.joints[i].tg.is_done = false
          else
            self.joints[i].tg.is_enabled = false
          end
        end
      end
      self.state = S.TRAJ_STATE_JOINT
      return E.TRAJ_ERROR_OK -- C: break
    end
    if st == S.TRAJ_STATE_JOINT_LEAVE then
      for i = 1, njoints do self.joints[i].tg.is_enabled = false end
      if self.is_done then self.state = S.TRAJ_STATE_OK_TO_SWITCH end
      st = S.TRAJ_STATE_JOINT
    end
    -- TRAJ_STATE_JOINT body
    local n_done = 0
    for i = 1, njoints do
      local joint = self.joints[i]
      if interpolator_need_update(joint.interpolator) then
        local e = joint.tg:tick()
        if e ~= 0 then return self:_tg_err(e, i - 1) end
        joint.planer_position = joint.tg.position
        if joint.tg.is_done then n_done = n_done + 1 end
        e = interpolator_push(joint.interpolator, joint.planer_position)
        if e ~= 0 then return self:_tg_err(e, i - 1) end
      end
      local e, x, vel, a, j = interpolator_interpolate(joint.interpolator)
      if e ~= 0 then return self:_tg_err(e, i - 1) end
      joint.position, joint.velocity, joint.acceleration, joint.jerk = x, vel, a, j
      if not isfinite(joint.position) then return self:_tg_err(E.TRAJ_ERROR_NUMERIC, i - 1) end
    end
    self.is_done = n_done >= njoints
    return E.TRAJ_ERROR_OK

  -- ---- MAN family -------------------------------------------------------
  elseif st == S.TRAJ_STATE_TG_MAN_ENTER or st == S.TRAJ_STATE_TG_MAN_LEAVE or st == S.TRAJ_STATE_MAN then
    if st == S.TRAJ_STATE_TG_MAN_ENTER then
      self.man_planer:reset()
      self:_reset_positions()
      self.man_planer.is_enabled = true
      self.state = S.TRAJ_STATE_MAN
      return E.TRAJ_ERROR_OK -- C: break
    end
    if st == S.TRAJ_STATE_TG_MAN_LEAVE then
      self.man_planer:abort()
      if self.is_done then self.state = S.TRAJ_STATE_OK_TO_SWITCH end
      st = S.TRAJ_STATE_MAN
    end
    while interpolator_need_update(self.joints[1].interpolator) do
      local e = self.man_planer:tick()
      if e ~= 0 then return self:_tg_err(e, 0) end
      self.planer_pose = self.man_planer:get_position()
      local jp = self.kinematics.inverse(self.planer_pose)
      apply_planer_positions(self, jp)
      for i = 1, njoints do
        e = interpolator_push(self.joints[i].interpolator, self.joints[i].planer_position)
        if e ~= 0 then return self:_tg_err(e, i - 1) end
      end
    end
    for i = 1, njoints do
      local joint = self.joints[i]
      local _, x, vel, a, j = interpolator_interpolate(joint.interpolator)
      joint.position, joint.velocity, joint.acceleration, joint.jerk = x, vel, a, j
      if not isfinite(joint.position) then return self:_tg_err(E.TRAJ_ERROR_NUMERIC, i - 1) end
    end
    self.is_done = self.man_planer:is_done_()
    return E.TRAJ_ERROR_OK

  -- ---- DISABLED family ------------------------------------------------
  elseif st == S.TRAJ_STATE_DISABLING then
    self:reset()
    self.state = S.TRAJ_STATE_DISABLED
    self.is_done = true
    return E.TRAJ_ERROR_OK
  elseif st == S.TRAJ_STATE_DISABLED then
    self.is_done = true
    return E.TRAJ_ERROR_OK
  elseif st == S.TRAJ_STATE_OK_TO_SWITCH then
    return E.TRAJ_ERROR_OK
  else
    self.state = S.TRAJ_STATE_DISABLING
    return self:_tg_err(E.TRAJ_ERROR_INVALID_STATE, 0)
  end
end

function Trajgen:info()
  return string.format(
    "trajgen.lua, version %s, with-interpolation, %s, without-curves, with-syncing, "
    .. "float-type=double, max-joints=%d, queue-size=%d",
    TG_VERSION, (NO_MOTION_BLENDING == 0) and "with-blending" or "without-blending",
    TG_MAX_JOINTS, TG_QUEUE_SIZE)
end

-- ---------------------------------------------------------------------------
-- trajgen.new(config): build and initialise a generator (trajgen_initialize)
-- ---------------------------------------------------------------------------

function M.new(config)
  assert(type(config) == "table", "trajgen.new: config table required")

  local tg = setmetatable({
    config = {},
    last_error = 0,
    state = S.TRAJ_STATE_DISABLED,
    requested_state = S.TRAJ_STATE_DISABLED,
    joints = {},
    coord_planer = coord_new(),
    man_planer = man_new(),
    _internals = { tick = 0 },
    kinematics = {},
    planer_pose = pose_new(),
    is_done = true,
  }, Trajgen)
  tg.coord_planer._tg = tg

  -- fixed configuration checks
  if FLOAT_EPS <= 0 or TG_RESOLUTION <= FLOAT_EPS or TG_D_RES <= FLOAT_EPS
     or TG_A_RES <= FLOAT_EPS or TG_QUEUE_SIZE < 4 or TG_MAX_JOINTS > JOINT_MAX_JOINTS then
    return nil, tg:_tg_err(E.TRAJ_ERROR_CONFIG_COMPILE_SETTING_INVALID, 0)
  end

  local njoints = config.number_of_used_joints or 0
  local irate   = config.interpolation_rate or 0
  local sample  = config.sample_interval or 0

  if njoints > TG_MAX_JOINTS or njoints == 0 then
    return nil, tg:_tg_err(E.TRAJ_ERROR_CONFIG_LAST_USED_JOINT_INVALID, 0)
  end
  if irate == 0 then
    return nil, tg:_tg_err(E.TRAJ_ERROR_CONFIG_INTERPOLATION_RATE_INVALID, 0)
  end

  local cfg = {
    number_of_used_joints = njoints,
    interpolation_rate    = irate,
    sample_interval        = sample,
    max_coord_velocity     = config.max_coord_velocity or 0,
    max_coord_acceleration = config.max_coord_acceleration or 0,
    max_manual_velocities  = pose_new(config.max_manual_velocities),
    max_manual_accelerations = pose_new(config.max_manual_accelerations),
    joints = {},
  }
  for i = 1, TG_MAX_JOINTS do
    local jc = (config.joints and config.joints[i]) or {}
    cfg.joints[i] = {
      max_velocity     = jc.max_velocity or 0,
      max_acceleration = jc.max_acceleration or 0,
      sample_interval  = 0,
    }
  end
  tg.config = cfg

  -- coordinated planner
  local err = tg.coord_planer:init{
    sample_interval  = sample * irate,
    max_velocity     = cfg.max_coord_velocity,
    max_acceleration = cfg.max_coord_acceleration,
  }
  if err ~= 0 then return nil, tg:_tg_err(err, 0) end

  -- manual planner
  err = tg.man_planer:initialize{
    max_acceleration = cfg.max_manual_accelerations,
    max_velocity     = cfg.max_manual_velocities,
    sample_interval  = sample * irate,
  }
  if err ~= 0 then return nil, tg:_tg_err(err, 0) end

  -- interpolators + free joint planners
  for i = 1, TG_MAX_JOINTS do
    cfg.joints[i].sample_interval = sample * irate
    if i > njoints then
      cfg.joints[i].max_acceleration, cfg.joints[i].max_velocity = 0, 0
    end
    tg.joints[i] = {
      interpolator = interpolator_new(),
      tg = jointtg_new(),
      planer_position = 0, position = 0,
      velocity = 0, acceleration = 0, jerk = 0,
    }
    err = interpolator_init(tg.joints[i].interpolator, sample * irate, irate)
    if err ~= 0 then return nil, tg:_tg_err(err, i - 1) end
    err = tg.joints[i].tg:initialize(cfg.joints[i])
    if err ~= 0 then return nil, tg:_tg_err(err, i - 1) end
  end

  -- kinematics
  err = kinematics_initialize(tg.kinematics, config.kinematics)
  if err ~= 0 then return nil, tg:_tg_err(err, 0) end

  tg:reset()
  return tg
end

return M
