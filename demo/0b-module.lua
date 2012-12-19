--
-- Lua module demo
--

-- adjust the package path to include the demo dir
package.path = "demo/?.lua;"..package.path

-- load the package
require "color"

-- use the package
print(color.red)
print(color.green)
