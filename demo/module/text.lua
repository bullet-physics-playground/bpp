local M = {}

function M.new(params)
    params    = params or {}
   options   = {
      str    = "ABC",
      font   = "Arial",
      height = 0.5,
      size   = 0.5,
      mass   = 0,
      col    = "#ffffff",
      x      = 0,
      y      = 0,
      z      = 0,
      post_sdl = [[
        no_shadow
        no_reflection
        no_radiosity
      }]]
   }

   for k,v in pairs(params) do options[k] = v end

   str  = options.str
   font = options.font
   height = options.height
   size = options.size
   mass = options.mass
   col  = options.col
   x    = options.x
   y    = options.y
   z    = options.z
   post_sdl = options.post_sdl

  t = OpenSCAD([[
  text = "]]..str..[[";
  font = "]]..font..[[";
  linear_extrude(height = ]]..height..[[) {
    text(
      text = text, font = font,
      size = ]]..size..[[, halign = "center");
  }]],0)
  t.pos = btVector3(x,y,z)
  t.col = col
  t.post_sdl = post_sdl
  return t
end

return M

