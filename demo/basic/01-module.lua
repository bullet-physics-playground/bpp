--
-- Basic Lua module demo
--

-- adjust the module path to include
-- the demo/ directory
package.path = "C:\\msys64\\home\\koppi\\bpp\\demo\\?.lua;"..package.path

-- print the package path
print("Lua package path: "..package.path)

-- load the module "color.lua"
color = require "module/color"

-- use the color module
print(color.red)
print(color.green)
