--
-- SpaceNavigator 3D mouse input demo
--
-- Demonstrates reading a 3Dconnexion SpaceNavigator 3D mouse.
-- The callback receives the six axis deltas (x, y, z, rx, ry, rz).
--
-- Usage: bpp -f demo/basic/15-space-navigator.lua
-- (Requires a connected 3Dconnexion SpaceNavigator; without a device the
--  callback simply never fires.)
--
-- Registering an onSpaceNavigator callback takes over the camera from the
-- built-in CAD-style camera control, so this script only prints axes.
-- Without registering a callback, the 3D mouse navigates the camera like
-- a professional CAD application: screen-space panning (X, Z), dolly
-- zoom (Y) and a pivot-based "turntable" orbit (RX, RY, RZ) around the
-- scene centre.

v:onSpaceNavigator(function(N, sn)
  v:clearDebugText()
  print("onSpaceNavigator("..tostring(N)..")")
  print("trans (x, y, z): "..sn.x..", "..sn.y..", "..sn.z)
  print("rot   (rx, ry, rz): "..sn.rx..", "..sn.ry..", "..sn.rz)
end)
