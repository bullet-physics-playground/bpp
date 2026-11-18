--
-- layout.lua -- the Domino Half Adder's layout, for the manual's figures
-- (Babbage's Hall). From the exhibit's folder: lua manual/layout.lua
-- Prints  line|x|z|h  for every domino, then  switch|line|i  and
-- tell|name|x|z|h: the same layout the simulation stands up.
--
local L = dofile("domino-lines.lua")
local LINES, STARTS, INFO = dofile("domino-layout.lua")(L).machine()
for _, n in ipairs({ "GO", "Ain", "Bin", "A", "B", "C", "Tl", "Tr", "SUM", "INH", "A3" }) do
  for _, p in ipairs(LINES[n]) do print(string.format("%s|%.3f|%.3f|%.4f", n, p.x, p.z, p.h)) end
end
for n, ks in pairs(INFO.switch) do for _, k in ipairs(ks) do print("switch|" .. n .. "|" .. k) end end
for n, p in pairs(INFO.tell) do print(string.format("tell|%s|%.3f|%.3f|%.4f", n, p.x, p.z, p.h)) end
print(string.format("dims|%.3f|%.3f|%.3f", L.W, L.H, L.T))
