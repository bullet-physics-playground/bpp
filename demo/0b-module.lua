--
-- Lua module demo
--

-- adjust the package path to include
-- the demo/ directory

package.path = "demo/?.lua;"..package.path

-- load the package
col = require "color"

-- use the package
print(col.red)
print(col.green)

--print(package.path)
