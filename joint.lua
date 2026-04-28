local bearing = peripheral.find("swivel_bearing")
local rsc = peripheral.find("Create_RotationSpeedController")

local targ = bearing.getTargetAngle()

local mult
local limit
local speedMult
local suc, res = pcall(require, "jointConfig")
if suc and type(res) == "table" and res.sign and res.limit and res.mult then
	mult = res.sign
	limit = res.limit
	speedMult = res.mult
else
	print("unable to get joint config")
	print(res)
	print("detecting joint sign")
    rsc.setTargetSpeed(5)
	os.sleep(1)
	mult = bearing.getTargetAngle() - targ
	mult = mult / math.abs(mult)
	term.write("Max RPM: ")
	limit = tonumber(read())
	term.write("Speed Multiplier: ")
	speedMult = tonumber(read()) or 1
	local conf = fs.open("jointConfig.lua", "w")
	conf.write(([[return {
		sign = %s,
		limit = %s,
		mult = %s
	}]]):format(mult, limit, speedMult))
	conf.close()
end

parallel.waitForAny(
    function ()
        while targ do
            print("Current angle:", targ)
            targ = tonumber(read())
        end
    end,
    function ()
        local found = false
        for _, v in ipairs(peripheral.getNames()) do
            local p = peripheral.wrap(v)
            if p.isWireless and p.isWireless() then
                rednet.open(v)
                found = true
                break
            end
        end
        while found do
            local id, message = rednet.receive("setJointAngle")
            targ = message
        end
    end,
    function ()
        while true do
            os.sleep(0.05)
            rsc.setTargetSpeed((targ - bearing.getTargetAngle())*mult*speedMult)
        end
    end
)
