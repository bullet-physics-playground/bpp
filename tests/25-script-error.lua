-- expect-error: ^error: \[string ".*"\]:13: attempt to index upvalue 'nothing' \(a nil value\)$
-- not-printed: after the error
--
-- A script that fails as it runs (Viewer::parse): bpp reports it on the
-- console as "error: " and Lua's message, which names the line; the
-- script stops there; and bpp, run from the command line, exits 1. The
-- harness checks all three (the lines above; a test like this one prints
-- no "N passed" line).

print("before the error")
local nothing = nil
local function fails()
  return nothing.field              -- (line 13: the error the first line names)
end
fails()
print("after the error")
