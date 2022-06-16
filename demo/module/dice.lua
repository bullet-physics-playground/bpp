local M = {}

color = require "module/color"

function M.new(params)
   params    = params or {}
   options   = {
      mass   = 1,
      col    = "#ff0000"
   }

   for k,v in pairs(params) do options[k] = v end

   mass = options.mass
   col  = options.col

   s = Cube(1.04,1.04,1.04, mass)

   s.col = col
   r,g,b = color.col2rgb(col)

   s.pre_sdl = "object { Dice(color rgb <"
     ..tostring(r/255)..", "
     ..tostring(g/255)..", "
     ..tostring(b/255)..">)"

   return s
end

return M

