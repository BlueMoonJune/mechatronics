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
	if side == m and channel == c and replyChannel == c and type(message) == "table" and message.id == name then
		return message.pos
	end
  end
end

if peripheral.wrap(...) then
  for _, v in ipairs({...}) do
    print(locate(v))
  end
end

return lib
