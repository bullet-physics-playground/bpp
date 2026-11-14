-- Lua 5.1's names that 5.2 and later dropped, which bpp's scripts use:
-- bpp defines them where the Lua it is built with lacks them (Homebrew's
-- 5.4 on macOS; see Viewer::openLua). On 5.1 these are Lua's own.

local pass = 0
local fail = 0

local function check(name, ok, detail)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": " .. tostring(detail))
    fail = fail + 1
  end
end

local function near(name, got, want)
  check(name, math.abs(got - want) <= 1e-14 * math.max(1, math.abs(want)),
        string.format("got %.17g, want %.17g", got, want))
end

local a, b, c = unpack({1, 2, 3})
check("unpack", a == 1 and b == 2 and c == 3, tostring(a) .. tostring(b) .. tostring(c))
check("loadstring", loadstring("return 6 * 7")() == 42)

check("math.pow", math.pow(2, 10) == 1024, math.pow(2, 10))
near("math.log10", math.log10(1000), 3)
check("math.ldexp", math.ldexp(0.75, 4) == 12, math.ldexp(0.75, 4))
check("math.ldexp, past 2^1023 in one step", math.ldexp(0.5, 1024) == 2 ^ 1023)
local f, e = math.frexp(12)
check("math.frexp", f == 0.75 and e == 4, tostring(f) .. " " .. tostring(e))
f, e = math.frexp(-1e-310)
check("math.frexp of a subnormal", math.ldexp(f, e) == -1e-310 and f <= -0.5 and f > -1,
      tostring(f) .. " " .. tostring(e))

-- (values from the C library, %.17g)
near("math.sinh", math.sinh(0.5), 0.52109530549374738)
near("math.cosh", math.cosh(0.5), 1.1276259652063807)
near("math.tanh", math.tanh(0.5), 0.46211715726000974)
near("math.sinh near 0", math.sinh(1e-10), 1e-10)
near("math.tanh near 0", math.tanh(-1e-10), -1e-10)
check("math.tanh far out", math.tanh(40) == 1 and math.tanh(-40) == -1)
near("math.cosh where e^x overflows", math.cosh(710) / 1.1169973830808557e308, 1)

print(string.format("\n%d passed, %d failed", pass, fail))
