local channel = gps.CHANNEL_GPS + 1

local config = require "config"
local log = {}
if fs.exists("log.pan") then
  local logFile = fs.open("log.pan", "r")
  local line = logFile.readLine()
  while line do
    local id, x, y, z = line:match('"([^"]*)" {([-%d.]+) ([-%d.]+) ([-%d.]+)}')
    log[id] = vector.new(
      tonumber(x),
      tonumber(y),
      tonumber(z)
    )
    line = logFile.readLine()
  end
end

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
    if not p2 then print(p1) p2 = p1 end
    local dist1 = math.abs((p1 - fix.vPosition):length() - fix.nDistance)
    local dist2 = math.abs((p2 - fix.vPosition):length() - fix.nDistance)

    if dist1 < dist2 then
        return p1
    end
    return p2
end

local pings = {}

local transmitModem = peripheral.wrap(config.transmitModem)

for modem, _ in pairs(config.modems) do
  peripheral.call(modem, "open", channel)
end

local logDirty = false

parallel.waitForAny(
  function()
    while true do
      local _, modem, sendCH, respCH, message, distance = os.pullEvent("modem_message")
      if sendCH == channel and type(message) ~= "table" then
        local ping = {
          vPosition = config.modems[modem],
          nDistance = distance
        }
        local mpings = pings[message]
        if mpings then
          table.insert(mpings, ping)
          if #mpings == 4 then
            local p1, p2 = trilaterate(unpack(mpings))
            local pos = narrow(p1, p2, mpings[4]):round(0.0001)
            transmitModem.transmit(respCH, 0, {id = message, pos = pos})
            pings[message] = nil
            logDirty = logDirty or log[message] ~= pos
            log[message] = pos
          end
        else
          pings[message] = {ping}
        end
      end
    end
  end,
  function ()
    while true do
      if logDirty then
        logDirty = false
        local logFile = fs.open("log.pan", "w")
        for id, pos in pairs(log) do
          logFile.write(('"%s" {%g %g %g}'):format(id, pos.x, pos.y, pos.z))
        end
        logFile.close()
      end
      os.sleep(10)
    end
  end
)

