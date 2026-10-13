# Walkers for the walker room

Copies of `../Walkers/<name>_parts.lua`, built by `../WalkerRoom/walker-room.lua`.
The walkers in `../Walkers/` are left as they are; changes made only so the
room can compare linkages fairly go here.

The one change: `M.build` takes an option `bodyRaise` (default 0, the
walker's own units) that raises its body that much further above its feet
without changing its foot path, so every walker in the room can be given
the same body clearance.

| Build | How `bodyRaise` does it |
|-------|-------------------------|
| Chebyshev, Chebyshev diag, Hoecken, Hoecken slider, Hoecken-Spears slider | lengthens each pendant (`p_len`) |
| Chebyshev-Spears, Chebyshev-Spears diag | lengthens each pendant below C (`EXT_DOWN`) |
| Spears 4-bar, Jansen, Klann | moves the body relative to its crank mounts (no pendant: the leg is part of the linkage) |

Where a crossbar, a brace or the floor height (`FLOOR_TOP_Y`) depended on the
pendant's length, it follows it. With `bodyRaise` 0 every build is the same as
in `../Walkers/`. The 2-leg Spears builds are unchanged copies.
