-- expect-error: ^error: \[string ".*"\]:16: attempt to index upvalue 'nothing' \(a nil value\)$
-- not-printed: after the error
-- expect-line: ^\[fails\] \[string ".*"\] \(16\)$
-- expect-line: ^\[\?\] \[string ".*"\] \(18\)$
--
-- A script that fails as it runs (Viewer::parse): bpp reports it on the
-- console as "error: " and Lua's message, which names the line, then where
-- the script was, a line a function from where it failed out (the function
-- that failed, and the line that called it); the script stops there; and
-- bpp, run from the command line, exits 1. The harness checks them all
-- (the lines above; a test like this one prints no "N passed" line).

print("before the error")
local nothing = nil
local function fails()
  return nothing.field              -- (line 16: the error the first line names)
end
fails()
print("after the error")
