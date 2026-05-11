--
-- Dominos demo
--
-- Physics simulation of domino chains being struck by a sphere.
-- Demonstrates collision, friction, and restitution settings.

local scene = 0 --[[
 0: archimedean see: https://news.povray.org/povray.animations/message/%3Cweb.69fa66a1cea3e23ebe9d2d3f89db30a9%40news.povray.org%3E/#%3Cweb.69fa66a1cea3e23ebe9d2d3f89db30a9%40news.povray.org%3E
 1: random,
 2: fixed table,
 3: fermat,
 4: log spiral
]]

math.randomseed(42)

v.pre_sdl = [[
#include "textures.inc"
#include "domino.inc"
]]

plane = Plane(0,1,0,0,100)
plane.col = "#333333"
plane.friction = 2
plane.sdl = [[
   texture {
      pigment { Blue_Agate scale <5, 5, 5> }
      finish { Phong_Glossy }
   }
]]
v:add(plane)

v.timeStep      = 1/5
v.fixedTimeStep = v.timeStep / 4
v.maxSubSteps   = 10

local col = require("color")

-- Archimedean spiral functions (from POV-Ray code)
-- Growth rate: radius = g * theta, g = 60/tau mm/rad (pitch = 60mm per revolution)
local tau = 2 * math.pi
local GrowthRate = 50 / tau  -- mm/radian

-- Position functions: x = g*theta*cos(theta), z = g*theta*sin(theta)
local function FnX(g, th) return g * th * math.cos(th) end
local function FnZ(g, th) return g * th * math.sin(th) end

-- First derivatives (for tangent direction)
local function DerFnX(g, th) return g * (math.cos(th) - th * math.sin(th)) end
local function DerFnZ(g, th) return g * (math.sin(th) + th * math.cos(th)) end

-- Arc length function: distance along spiral from center to angle theta
local function ArcLengthFn(g, th)
    return g/2 * (th * math.sqrt(1 + th*th) + math.log(th + math.sqrt(1 + th*th)))
end

-- Derivative of arc length function
local function DerArcLengthFn(g, th)
    return g * math.sqrt(1 + th*th)
end

-- Newton-Raphson solver to find theta for a given arc length
local function NewtonRaphson(g, targetLength, estTheta, tol, maxIter)
    tol = tol or 1e-6
    maxIter = maxIter or 10
    local nil_val = 1e-12
    local theta = estTheta
    for i = 1, maxIter do
        local derVal = DerArcLengthFn(g, theta)
        if math.abs(derVal) <= nil_val then break end
        local closerTheta = theta - (ArcLengthFn(g, theta) - targetLength) / derVal
        if math.abs(closerTheta - theta) < tol then
            theta = closerTheta
            break
        end
        theta = closerTheta
    end
    return theta
end

-- Vector math helpers
local function vnormalize(x, y, z)
    local len = math.sqrt(x*x + y*y + z*z)
    return x/len, y/len, z/len
end

local function vcross(ax, ay, az, bx, by, bz)
    return ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx
end

-- Build Frenet frame and create transform matrix for Bullet
local function createFrenetTransform(px, py, pz, th)
    -- Tangent vector (forward direction along spiral)
    local tx, _, tz = vnormalize(DerFnX(GrowthRate, th), 0, DerFnZ(GrowthRate, th))
    -- Binormal (up) = <0, 1, 0>
    local bx, by, bz = 0, 1, 0
    -- Normal (side) = cross(binormal, tangent)
    local nx, ny, nz = vcross(bx, by, bz, tx, 0, tz)

    -- Build rotation matrix from Frenet frame
    -- POV-Ray matrix maps: local x -> Normal, local y -> Binormal, local z -> Tangent
    -- btMatrix3x3 constructor takes column vectors: (col0, col1, col2)
    local m = btMatrix3x3(
        nx, bx, tx,
        ny, by, 0,
        nz, bz, tz
    )
    local q = btQuaternion()
    m:getRotation(q)
    return btTransform(q, btVector3(px, py, pz))
end

local fixed_control_points = {
  {x =  0, y = 0, z =  0},
  {x =  10, y = 0, z =  0},
  {x =  10, y = 0, z =  10},
  {x =  0, y = 0, z =  10},
  {x =  0, y = 0, z =  0},
}

function spline_dominos(damp_lin, damp_ang, fri, res)

  if scene == 0 then
    -- Archimedean spiral using POV-Ray formulas
    local noOfPoints = 300
    local stepLength = 20

    -- Calculate thetas using Newton-Raphson
    local thetas = {}
    thetas[0] = 0
    for i = 1, noOfPoints - 1 do
        local targetLen = i * stepLength
        thetas[i] = NewtonRaphson(GrowthRate, targetLen, thetas[i-1], 1e-6, 10)
    end

    -- Impact sphere
    local s = Sphere(10, 5)
    local firstTheta = thetas[1]
    s.pos = btVector3(20, 5, 30)
    s.col = "#ff0000"
    s.vel = btVector3(-5, 0, -3)
    s.sdl = [[ texture { Polished_Chrome } ]]
    v:add(s)

    -- Render dominoes along spiral
    for i = 1, noOfPoints - 1 do
        local th = thetas[i]
        local px = FnX(GrowthRate, th)
        local py = 12.5
        local pz = FnZ(GrowthRate, th)

        local d = Cube(12, 22, 2.5, .1)
        d.col = col.random_chrome()
        d.pre_sdl = [[ object { domino]]..tostring(math.random(1,45))..
[[ scale 1 rotate x*90]]
        d.sdl = ""
        d.friction = fri
        d.restitution = res
        d.damp_lin = damp_lin
        d.damp_ang = damp_ang

        d.trans = createFrenetTransform(px, py, pz, th)
        v:add(d)
    end

    v.cam:setUpVector(btVector3(-0.0834355, 0.759854, 0.644717), true)
    v.cam.up   = btVector3(-0.0834355, 0.759854, 0.644717)
    v.cam.pos  = btVector3(57.2042, 302.164, -463.355)
    v.cam.look = btVector3(-67279.3, -649491, 756659)

  elseif scene == 2 then
    -- Fixed control points (spline-based)
    local spline = require("spline")
    local domino_height = 3
    local y_pos = domino_height / 2
    local control_points = {}
    for _, cp in ipairs(fixed_control_points) do
        control_points[#control_points+1] = {x=cp.x, y=y_pos, z=cp.z}
    end

    for i, cp in ipairs(control_points) do
        local marker = Sphere(0.1, 0)
        marker.pos = btVector3(cp.x, cp.y, cp.z)
        marker.col = "#ff0000"
    end

    local sp = spline.CatmullRom(control_points, 0.5)

    local s = Sphere(1, 5)
    s.pos = btVector3(25, 1, -20)
    s.col = "#ff0000"
    s.vel = btVector3(-2.5, 0, 0)
    s.sdl = [[ texture { Polished_Chrome } ]]
    v:add(s)

    local N = #control_points - 2
    for i = 1, N do
        local t = 1 + (i - 1)
        local p = sp:eval(t)
        local p_next = sp:eval(t + 0.1)

        local d = Cube(0.4, domino_height, 1.5, .1)
        d.col = col.random_chrome()
        d.pre_sdl = [[ object { domino]]..tostring(math.random(1,45))..
[[ scale 0.1275 rotate y*90 rotate z*90 ]]
        d.sdl = ""
        d.friction = fri
        d.restitution = res
        d.damp_lin = damp_lin
        d.damp_ang = damp_ang

        local dx = p_next.x - p.x
        local dz = p_next.z - p.z
        local normal_angle = math.atan2(dx, dz) + math.pi / 2
        local q = btQuaternion()
        q:setEulerZYX(0, normal_angle, 0)
        d.trans = btTransform(q, btVector3(p.x, p.y, p.z))
        v:add(d)
    end

  else
    -- Random, Fermat, or log spiral (original spline-based)
    local spline = require("spline")
    local domino_height = 3
    local y_pos = domino_height / 2
    local control_points = {}
    local num_control = 250

    for i = 1, num_control do
        local cp
        if scene == 1 then
            cp = {
                x = math.random(-20, 20),
                y = y_pos,
                z = math.random(-20, 20),
            }
        elseif scene == 3 then
            local angle = (i - 1) * 0.09
            local radius = 6 + math.sqrt(angle) * 4.2
            cp = {
                x = math.cos(angle) * radius,
                y = y_pos,
                z = math.sin(angle) * radius,
            }
        elseif scene == 4 then
            local angle = (i - 1) * 0.09
            local radius = 5 * math.exp(angle * 0.15)
            cp = {
                x = math.cos(angle) * radius,
                y = y_pos,
                z = math.sin(angle) * radius,
            }
        end
        control_points[i] = cp
    end

    for i, cp in ipairs(control_points) do
        local marker = Sphere(0.1, 0)
        marker.pos = btVector3(cp.x, cp.y, cp.z)
        marker.col = "#ff0000"
    end

    local sp = spline.CatmullRom(control_points, 0.5)

    local s = Sphere(1, 5)
    s.pos = btVector3(25, 1, -20)
    s.col = "#ff0000"
    s.vel = btVector3(-2.5, 0, 0)
    s.sdl = [[ texture { Polished_Chrome } ]]
    v:add(s)

    local N = #control_points - 2
    for i = 1, N do
        local t = 1 + (i - 1)
        local p = sp:eval(t)
        local p_next = sp:eval(t + 0.1)

        local d = Cube(0.4, domino_height, 1.5, .1)
        d.col = col.random_chrome()
        d.pre_sdl = [[ object { domino]]..tostring(math.random(1,45))..
[[ scale 0.1275 rotate y*90 rotate z*90 ]]
        d.sdl = ""
        d.friction = fri
        d.restitution = res
        d.damp_lin = damp_lin
        d.damp_ang = damp_ang

        local dx = p_next.x - p.x
        local dz = p_next.z - p.z
        local normal_angle = math.atan2(dx, dz) + math.pi / 2
        local q = btQuaternion()
        q:setEulerZYX(0, normal_angle, 0)
        d.trans = btTransform(q, btVector3(p.x, p.y, p.z))
        v:add(d)
    end
  end
end

spline_dominos(0.01,  0.01,  0.5, 0.01)
