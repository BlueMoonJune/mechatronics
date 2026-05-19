local lib = {}

lib.CHANNEL_GPS = gps.CHANNEL_GPS + 1
local c = lib.CHANNEL_GPS
function lib.locate(m)
  local name
  if type(m) == "string" then
    name = m
    m = peripheral.wrap(m)
  else
    name = peripheral.getName(m)
  end
  _ = m.isOpen(c) or m.close(c)
  m.open(c)
  m.transmit(c, c, name)
  while true do
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    if side == name and channel == c and replyChannel == 0 and type(message) == "table" and message.id == name then
      local v = message.pos
      return vector.new(v.x, v.y, v.z)
    end
  end
end

if peripheral.wrap(...) then
  for _, v in ipairs({...}) do
    print(lib.locate(v))
  end
end

return lib

