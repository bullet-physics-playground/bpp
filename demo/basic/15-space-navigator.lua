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
-- built-in camera control, so this script only prints axes.  Without
-- registering a callback, the 3D mouse navigates the camera with the
-- built-in navigation: X/Y/Z push translates the camera (X strafes right,
-- Y moves along the view direction, Z moves up/down) and RX/RY/RZ rotates,
-- in both Fly (first-person) and Object (orbit) modes.  Configurable from the
-- SpaceNavigator page of the Preferences dialog, or in a script via the
-- Viewer properties
--   v.snMode = 0            -- 0 = Fly, 1 = Object (orbit)
--   v.snLockHorizon = true
--   v.snAutoFlySpeed = true
--   v.snShowOrbitAxis = true
--   v.snZoomForward = true
--   v.snPanZoom = true

v:onSpaceNavigator(function(N, sn)
  v:clearDebugText()
  print("onSpaceNavigator("..tostring(N)..")")
  print("trans (x, y, z): "..sn.x..", "..sn.y..", "..sn.z)
  print("rot   (rx, ry, rz): "..sn.rx..", "..sn.ry..", "..sn.rz)
end)
