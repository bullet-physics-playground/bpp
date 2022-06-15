module("povray", package.seeall);

function render(opt,d,f,N)
  file = io.open("scene.pov", "w")
  file:write(v.pov)
  file:close()
  os.execute("povray scene.pov "..opt.." +O"..d.."/"..f.."-"..string.format("%06d", N)..".png")
end
