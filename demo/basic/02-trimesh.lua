--
-- btTriangleMesh pyramids
--
-- This demo crashes randomly at startup.
--
-- Needs more investigation (koppi).
--

v.gravity = btVector3(0,-9.81,0)

v.timeStep      = 1/5
v.maxSubSteps   = 6
v.fixedTimeStep = 1/120

v.pre_sdl = v.pre_sdl..[==[

// ground 

#declare RasterScale = 1 ;
#declare RasterHalfLine  = 0.045;
#declare RasterHalfLineZ = 0.045;

#macro Raster(RScale, HLine)
   pigment{ gradient x scale RScale
            color_map{[0.000   color rgbt<1,1,1,1>*0.6]
                      [0+HLine color rgbt<1,1,1,1>*0.6]
                      [0+HLine color rgbt<1,1,1,1>]
                      [1-HLine color rgbt<1,1,1,1>]
                      [1-HLine color rgbt<1,1,1,1>*0.6]
                      [1.000   color rgbt<1,1,1,1>*0.6]} }
   finish { ambient 0.15 diffuse 0.85}
#end

]==]

p = Plane(0,1,0,0,100)
p.pos = btVector3(0,-2,0)
p.col = "#101010"
p.sdl = [[
  texture { pigment{color rgbt<1,1,1,0.7>*1.1}
            finish {ambient 0.45 diffuse 0.85}}
  texture { Raster(RasterScale,RasterHalfLine ) rotate<0,0,0> }
  texture { Raster(RasterScale,RasterHalfLineZ) rotate<0,90,0>}
  rotate<0,0,0>
  // no_shadow
]]
v:add(p)

function mesh()
   m = btTriangleMesh()

  local l = 5

  local a = btVector3(0, l*2,0)
  local b = btVector3(-0, 2, l*2)
  local c = btVector3(-l, 0,-l)
  local d = btVector3( l*2, 0, 0)

  m:addTriangle(a, b, c, true)
  m:addTriangle(b, c, d, true)
  m:addTriangle(c, d, a, true)
  m:addTriangle(d, a, b, true)

 qtn = btQuaternion()
 trans = btTransform()

trans:setIdentity()
qtn:setEuler(0.0, 20, 0.0);
trans:setRotation(qtn)
trans:setOrigin(btVector3(0, 2, 0))

ms    = btDefaultMotionState(trans)

shape = btGImpactMeshShape(m)

shape:updateBound()

mass = 100

inertia = btVector3()
shape:calculateLocalInertia(mass, inertia)
body = btRigidBody(mass, ms, shape, inertia)

mm = Mesh()
mm.col   = "#ff0000"
mm.shape = shape
mm.body  = body
mm.mass     = 10
mm.inertia  = 2.9
mm.damp_lin = 0.5
mm.damp_ang = 0.5
v:add(mm)
return mm
end

--v:add(mesh())
--v:add(mesh())

function tst()
  for i = 0,70 do
    m = mesh()
    m.pos = btVector3(0,i,0)
  end
end

tst()
