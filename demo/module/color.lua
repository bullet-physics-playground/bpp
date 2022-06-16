local M = {}

M.red = "#ff0000"
M.green = "#00ff00"
M.blue = "#0000ff"
M.white = "#ffffff"
M.gray = "#101010"

function M.num2hex(num)
    local hexstr = '0123456789abcdef'
    local s = ''
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == '' then s = '00' end
    return s
end

function M.rgb2col(r,g,b)
  return string.format("#%s%s%s", M.num2hex(r), M.num2hex(g), M.num2hex(b))
end

function M.rgbt2col(r,g,b,t)
  return string.format("#%s%s%s%s", M.num2hex(r), M.num2hex(g), M.num2hex(b), M.num2hex(t))
end

function M.col2rgb(col)
  c = QColor(col)
  return c.r, c.g, c.b
end

-- from http://stackoverflow.com/questions/43044
M.random_pastel = function()
  return M.rgb2col(math.random(127)+127,math.random(127)+127,math.random(127)+127)
end

-- print(rgb2col(255,255,255))
-- print(rgbt2col(255,255,255,0))

function M.random_bpp()
   local scheme = {
      "#3a8581",
      "#71b04b",
      "#00a651",
      "#29a969",
      "#6e2c90",
      "#4f6ab1",
      "#86733d",
      "#ef4927",
      "#895781",
      "#ec2290",
      "#d76048",
      "#72c59a",
      "#4ec2c6",
      "#8ea0c8",
      "#eec343",
      "#d0b05f",
      "#f9b598",
      "#aa7694",
      "#abdddf",
      "#80ffff",
      "#b3b08f",
   }
   
   return scheme[ math.random( #scheme ) ]
end

function M.random_chrome()
   local scheme = {
      "#698153",
      "#177646",
      "#13864c",
      "#159053",
      "#169f5c",
      "#1da362",
      "#39ac74",
      "#b44438",
      "#d54b3e",
      "#dc5044",
      "#c77067",
      "#e27066",
      "#4b8bf4",
      "#e5a738",
      "#fbc03d",
      "#fecd42",
      "#c8b763",
      "#fbd366",
      "#79a7f3",
      "#7ebd9d",
      "#aecae8",
      "#dec1aa",
      "#d9dfe4",
   }

   return scheme[ math.random( #scheme ) ]
end

function M.random_google()
   local scheme = {
      "#ff0000",
      "#34a853",
      "#fbbb04",
      "#4285f4",
   }

   return scheme[ math.random( #scheme ) ]
end

return M

