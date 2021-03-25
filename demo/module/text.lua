module("text", package.seeall)

function txt(t, x, y, z)
  t = OpenSCAD([[
  text = "]]..t..[[";
  font = "Arial";
  linear_extrude(height = 0.5) {
    text(
      text = text, font = font,
      size = 0.5, halign = "center");
  }]],0)
  t.pos = btVector3(x,y,z)
  t.col = "#ffffff"
  t.post_sdl = [[
    no_shadow
    no_reflection
    no_radiosity
  }]]
  return t
end