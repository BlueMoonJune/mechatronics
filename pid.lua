local pidMeta = {
	__index = {
		update = function (self, err)
			self.deriv, self.cur = (err - self.cur) / self.dt, err
			self.int = self.int + err * self.dt
			return self.getValue()
		end,
		getValue = function (self)
			return self.cur * self.P + self.int * self.I + self.deriv * self.D
		end
	}
}

local function new(dt, P, I, D, v)
	return setmetatable(
		{
			dt = dt,
			P = P,
			I = I,
			D = D,
			deriv = 0,
			cur = v or 0,
			int = 0
		},
		pidMeta
	)
end

return {new = new}


