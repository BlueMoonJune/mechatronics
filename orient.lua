local gps = require "gpsx"
local matrix = require "matrix"

local function orient(front, back, up, close)
  local f = gps.locate(front, close)
  local b = gps.locate(back, close)
  local u = gps.locate(up, close)
  local w = ((f+b)/2):round(0.001)
  local y = (u - w):normalize():round(0.001)
  local z = (f - w):normalize():round(0.001)
  local x = y:cross(z):round(0.001)
  w = w + (x + y + z)*0.5
  local mat = matrix {
    {x.x, y.x, z.x, w.x},
    {x.y, y.y, z.y, w.y},
    {x.z, y.z, z.z, w.z},
    {  0,   0,   0,   1},
  }
  return(mat)
end

if peripheral.wrap(...) then
  local front, back, up = ...
  orient(front, back, up, true)
end

return orient
