local gps = require "gpsx"
local matrix = require "matrix"

local function orient(front, back, up, close)
  local f = gps.locate(front, close)
  local b = gps.locate(back, close)
  local u = gps.locate(up, close)
  parallel.waitForAll(
	function () f = gps.locate(front, close) end,
	function () b = gps.locate(back, close) end,
	function () u = gps.locate(up, close) end
  )
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

local function transform(vec, mat, w)
  local vm = (matrix{{vec.x, vec.y, vec.z, w or 1}} * mat^'T')[1]
  return vector.new(vm[1], vm[2], vm[3])
end

if peripheral.wrap(...) then
  local front, back, up = ...
  orient(front, back, up, true)
end

return {
	get = orient,
	transform = transform
}
