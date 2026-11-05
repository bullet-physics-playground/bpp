--
-- Prints the Lua API bpp gives scripts, one "API ..." line per item, for
-- tests/harness.py api: every bound class, its properties, and its methods
-- with each overload's C++ signature, then the global functions.
--
-- luabind lists a method's overloads when a call matches none of them; a
-- call with no arguments at all (not even self) matches none, so each
-- method is called that way and its error message read. Only a function
-- that takes no arguments at all would actually run (today that is
-- btTransform.getIdentity); one with side effects should not be bound so.
--

local function sorted_keys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  return keys
end

local function signatures(fn)
  local ok, err = pcall(fn)
  if ok then return { "(accepts a call with no arguments)" } end
  local sigs = {}
  for line in tostring(err):gmatch("[^\n]+") do
    if not line:match("^No matching overload") then
      sigs[#sigs + 1] = line
    end
  end
  table.sort(sigs)
  return sigs
end

local names = {}
for _, c in ipairs(class_names()) do names[#names + 1] = c end
table.sort(names)

for _, cname in ipairs(names) do
  local cls = _G[cname]
  print("API class " .. cname)
  if cls ~= nil then
    local info = class_info(cls)
    local attrs = {}
    for _, a in pairs(info.attributes) do attrs[#attrs + 1] = a end
    table.sort(attrs)
    for _, a in ipairs(attrs) do
      print("API   ." .. a)
    end
    for _, m in ipairs(sorted_keys(info.methods)) do
      for _, sig in ipairs(signatures(info.methods[m])) do
        print("API   " .. m .. ": " .. sig)
      end
    end
  end
end

for _, g in ipairs(sorted_keys(_G)) do
  if type(_G[g]) == "function" then
    print("API global " .. g .. "()")
  end
end
