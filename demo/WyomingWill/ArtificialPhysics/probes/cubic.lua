-- lattice quality: pts = {{x,y,z,spin}}, R = edge length
function cubicStats(pts, R)
  local n = #pts
  local edges, opp, ang9018, angAll, six, angHist = 0, 0, 0, 0, 0, {}
  local diag, nb = 0, 0
  for i = 1, n do
    local a = pts[i]
    local nbr = {}
    for j = 1, n do
      if j ~= i then
        local b = pts[j]
        local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
        local r = math.sqrt(dx * dx + dy * dy + dz * dz)
        if r > 0.8 * R and r < 1.2 * R then
          nbr[#nbr + 1] = { dx / r, dy / r, dz / r }
          edges = edges + 1
          if a[4] ~= b[4] then opp = opp + 1 end
        elseif r > 1.25 * R and r < 1.6 * R then
          diag = diag + 1
          if a[4] == b[4] then nb = nb + 1 end
        end
      end
    end
    if #nbr == 6 then six = six + 1 end
    for p = 1, #nbr do for q = p + 1, #nbr do
      local c = nbr[p][1] * nbr[q][1] + nbr[p][2] * nbr[q][2] + nbr[p][3] * nbr[q][3]
      local deg = math.deg(math.acos(math.max(-1, math.min(1, c))))
      angAll = angAll + 1
      if math.abs(deg - 90) < 15 or deg > 165 then ang9018 = ang9018 + 1 end
      local b = math.floor(deg / 30) * 30
      angHist[b] = (angHist[b] or 0) + 1
    end end
  end
  local h = {}
  for b = 0, 150, 30 do h[#h + 1] = string.format("%d:%d%%", b, math.floor(100 * (angHist[b] or 0) / math.max(angAll, 1) + 0.5)) end
  return string.format("edges/pt=%.2f (opp spin %.0f%%) six-edge pts=%d/%d | square angles=%.0f%% [%s] | diag(1.25-1.6R)/pt=%.2f same-spin %.0f%%",
    edges / n, 100 * opp / math.max(edges, 1), six, n, 100 * ang9018 / math.max(angAll, 1), table.concat(h, " "),
    diag / n, 100 * nb / math.max(diag, 1))
end
