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

   local str  = options.str
   local font = options.font
   local height = options.height
   local size = options.size
   local mass = options.mass
   local col  = options.col
   local x    = options.x
   local y    = options.y
   local z    = options.z
   local post_sdl = options.post_sdl

  local t = OpenSCAD([[
  text = "]]..str..[[";
  font = "]]..font..[[";
  linear_extrude(height = ]]..height..[[) {
    text(
      text = text, font = font,
      size = ]]..size..[[, halign = "center");
  }]], mass, false)
  t.pos = btVector3(x,y,z)
  t.col = col
  t.post_sdl = post_sdl
  return t
end

return M

