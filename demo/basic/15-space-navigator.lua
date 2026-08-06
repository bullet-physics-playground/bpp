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
-- built-in Blender-style camera control, so this script only prints axes.
-- Without registering a callback, the 3D mouse navigates the camera exactly
-- like Blender's default NDOF mode ("Orbit about view centre" + Turntable +
-- Dolly): X strafes, Y dollies in/out (push forward to zoom in), Z pans up,
-- and RX/RY/RZ orbit the camera turntable-style around whatever it is
-- looking at (yaw keeps the horizon level).

v:onSpaceNavigator(function(N, sn)
  v:clearDebugText()
  print("onSpaceNavigator("..tostring(N)..")")
  print("trans (x, y, z): "..sn.x..", "..sn.y..", "..sn.z)
  print("rot   (rx, ry, rz): "..sn.rx..", "..sn.ry..", "..sn.rz)
end)
