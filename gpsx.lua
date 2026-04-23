local c = gps.CHANNEL_GPS

local lib = {}

local function trilaterate(A, B, C)
    local a2b = B.vPosition - A.vPosition
    local a2c = C.vPosition - A.vPosition

    if math.abs(a2b:normalize():dot(a2c:normalize())) > 0.999 then
        return nil
    end

    local d = a2b:length()
    local ex = a2b:normalize( )
    local i = ex:dot(a2c)
    local ey = (a2c - ex * i):normalize()
    local j = ey:dot(a2c)
    local ez = ex:cross(ey)

    local r1 = A.nDistance
    local r2 = B.nDistance
    local r3 = C.nDistance

    local x = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    local y = (r1 * r1 - r3 * r3 - x * x + (x - i) * (x - i) + j * j) / (2 * j)

    local result = A.vPosition + ex * x + ey * y

    local zSquared = r1 * r1 - x * x - y * y
    if zSquared > 0 then
        local z = math.sqrt(zSquared)
        local result1 = result + ez * z
        local result2 = result - ez * z

        local rounded1, rounded2 = result1, result2
        if rounded1.x ~= rounded2.x or rounded1.y ~= rounded2.y or rounded1.z ~= rounded2.z then
            return rounded1, rounded2
        else
            return rounded1
        end
    end
    return result

end

local function narrow(p1, p2, fix)
    local dist1 = math.abs((p1 - fix.vPosition):length() - fix.nDistance)
    local dist2 = math.abs((p2 - fix.vPosition):length() - fix.nDistance)

    if dist1 < dist2 then
        return p1
    end
    return p2
end

function lib.ping(m)
  if type(m) == "string" then
    m = peripheral.wrap(m)
  end
  m.transmit(c, c, "PING")
end

function lib.locate(m, close, noping)
  local name
  if type(m) == "string" then
    name = m
    m = peripheral.wrap(m)
  else
    name = peripheral.getName(m)
  end
  _ = m.isOpen(c) or m.close(c)
  m.open(c)

  if not noping then
	m.transmit(c, c, "PING")
  end
  local resp = {}
  local i = 1
  while i <= 4 do
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    if side == name and channel == c and replyChannel == c and type(message) == "table" then
      resp[i] = {vPosition = vector.new(unpack(message)), nDistance = distance}
      i = i + 1
    end
  end
  local p1, p2 = trilaterate(unpack(resp))
  local pos = narrow(p1, p2, resp[4])
  if close then
    m.close(c)
  end
  return pos
end

if peripheral.wrap(...) then
  for _, v in ipairs({...}) do
    print(locate(v))
  end
end

return lib
