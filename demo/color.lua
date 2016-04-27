module("color", package.seeall);

red = "#ff0000"
green = "#00ff00"
blue = "#0000ff"
white = "#ffffff"
gray = "#101010"

function num2hex(num)
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

function rgb2col(r,g,b)
  return string.format("#%s%s%s", num2hex(r), num2hex(g), num2hex(b))
end

function rgbt2col(r,g,b,t)
  return string.format("#%s%s%s%s", num2hex(r), num2hex(g), num2hex(b), num2hex(t))
end

-- from http://stackoverflow.com/questions/43044
random_pastel = function()
  return rgb2col(math.random(127)+127,math.random(127)+127,math.random(127)+127)
end

-- print(rgb2col(255,255,255))
-- print(rgbt2col(255,255,255,0))
