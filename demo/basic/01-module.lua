--
-- Basic Lua module demo
--

-- adjust the module path to include
-- the demo/ directory
package.path = "demo/?.lua;"..package.path

-- print the package path
print("Lua package path: "..package.path)

-- load the module "module/color.lua"
require "module/color"

-- use the color module
print(color.red)
print(color.green)
