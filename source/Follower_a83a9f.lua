function onLoad()
  self.addContextMenuItem("Farmer", setFarmer, false)
end

function setFarmer()
  local p = self.getPosition()
  self.setPositionSmooth({p.x, p.y + 1, p.z}, false, true)
  self.setRotationSmooth({90,0,0}, false, true)
end