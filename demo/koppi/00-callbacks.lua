v:preStart(function() 
  print("preStart")
end)

v:preStop(function() 
  print("preStop")
end)

c = Cube(1,1,1,0)

v:onCommand(function(cmd)
--  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)
