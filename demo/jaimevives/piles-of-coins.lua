--
-- Piles of coins
--

local color  = require "color"
local common = require "common"

common.setTiming(1/5, 200, 1/300)

plane = Plane(0,1,0,0,100)
plane.col = color.darkgray
plane.friction=5
v:add(plane)

function coins_pile(coin_type,N,xp,zp)

  if(coin_type==1) then
    coin_width=7.0
    coin_height=1.1
  end
  if(coin_type==2) then
    coin_width=6.0
    coin_height=1.0
  end
  if(coin_type==3) then
    coin_width=5.0
    coin_height=0.9
  end
  if(coin_type==4) then
    coin_width=4.0
    coin_height=0.8
  end
  if(coin_type==5) then
    coin_width=3.5
    coin_height=0.75
  end

  for i = 0,N do
    q = btQuaternion(1,0,0,1)
    o = btVector3(xp-.5+math.random(0,10)*.1,
                  .6+i*coin_height,
                  zp-.5+math.random(0,10)*.1) 
    d = Cylinder(coin_width,coin_height,1)
    d.mass=coin_width*coin_height*.1
    d.col = color.darkgoldenrod
    d.trans=btTransform(q,o)
    d.friction=0.5
    d.restitution=.1
--    d.pre_sdl="object{coin("..coin_type..")"
--    d.post_sdl="}\n"
    v:add(d)
  end
end

coins_pile(1,45,0,15)
coins_pile(2,41,0,-15)
coins_pile(3,43,15,0)
coins_pile(4,48,-15,0)
coins_pile(5,46,0,0)
coins_pile(1,45,15,15)
coins_pile(2,41,15,-15)
coins_pile(3,43,-15,15)
coins_pile(4,48,-15,-15)

common.setCamera(btVector3(76.6849, 2008.08, 2609.51),
                 btVector3(-23345.7, -603585, -792820), nil,
                 { up = btVector3(-0.0123214, 0.795762, -0.605484) })

-- EOF