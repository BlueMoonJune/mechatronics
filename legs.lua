local legMeta = {
  __index = {
    setTarget = function(self, v)
      v = v - self.anchor
      local theta = math.atan2(v.x, -v.y)

      local phi = math.atan2(math.sqrt(v.x^2+v.y^2), v.z)
      local a, b = self.lengths[1], self.lengths[2]
      local c = math.min(v:length(), a+b)
      local omega = math.pi - math.acos((a^2+b^2-c^2)/(2*a*b))

      phi = phi - omega / 2

      self:setJoint(1, theta)
      self:setJoint(2, phi)
      self:setJoint(3, omega)

    end,
    setJoint = function (self, idx, angle)
      local joint = self.joints[idx]
      rednet.send(joint.id, math.deg(angle) * joint.sign + joint.offset, "setJointAngle")
    end
  }
}

return function (t)
  return setmetatable(t, legMeta)
end
