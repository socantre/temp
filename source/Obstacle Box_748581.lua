-- Data

all_bags = {}

use_bags = {}

owned_obstacles = {}

-- Events

function onLoad(save_state)
  all_bags = {
    core = getObjectFromGUID('521a6a'),
    tfa = getObjectFromGUID('3bac58'),
    debris = getObjectFromGUID('065d51'),
    gas = getObjectFromGUID('8b1614')
  }

  local data = JSON.decode(save_state) or {}

  self.UI.setAttribute('toggle1', 'isOn', data.enable_asteroids or 'True')
  self.UI.setAttribute('toggle2', 'isOn', data.enable_debris or 'True')
  self.UI.setAttribute('toggle3', 'isOn', data.enable_gas or 'True')

  if (data.enable_asteroids or 'True') =='True' then
    table.insert(use_bags, all_bags.core)
    table.insert(use_bags, all_bags.tfa)
  end
  if (data.enable_debris or 'True') =='True' then
    table.insert(use_bags, all_bags.debris)
  end
  if (data.enable_gas or 'True') =='True' then
    table.insert(use_bags, all_bags.gas)
  end
end

function onSave()
  local data = {
    enable_asteroids = self.UI.getAttribute('toggle1','isOn'),
    enable_debris = self.UI.getAttribute('toggle2','isOn'),
    enable_gas = self.UI.getAttribute('toggle3','isOn')
  }

  return JSON.encode(data)
end

-- UI functions

function toggle_asteroids (luaPlayer, isOn)
  toggle("core", isOn=="True")
  toggle("tfa", isOn=="True")
end
function toggle_debris (luaPlayer, isOn) toggle("debris", isOn=="True") end
function toggle_gas (luaPlayer, isOn) toggle("gas", isOn=="True") end

function toggle(obstacle_type, isOn)
  local found_index = -1
  for i, bag in ipairs(use_bags) do
    if bag == all_bags[obstacle_type] then
      found_index = i
    end
  end
  if isOn and found_index < 0 then
    table.insert(use_bags, all_bags[obstacle_type])
  end
  if not isOn and found_index > 0 then
    table.remove(use_bags, found_index)
  end
end

function button1_click ()
  if #use_bags < 1 then
    print("No obstacle types are enabled.")
    return
  end

  for i = 1, 6 do
    local obstacle = getRandomItemState(use_bags)
    table.insert(owned_obstacles, obstacle)
  end

  Wait.time(function () placeObstacles(owned_obstacles) end, 1)
  --Wait.time(button3_click, 3)
end

function button2_click ()
  for i, obstacle in ipairs(owned_obstacles) do
    if obstacle then
      pcall(destroyObject, obstacle)
    end
  end

  if #owned_obstacles == 1 then
    print("Deleted 1 obstacle.")
  else
    print("Deleted " .. #owned_obstacles .. " obstacles.")
  end
  for i = 1, #owned_obstacles do
    owned_obstacles[i] = nil
  end
end

function button3_click ()
  -- outlineObstacles()
  WebRequest.get('https://raw.githubusercontent.com/socantre/temp/main/test_object.json', function (request)
    if request.is_error then
      log(request.error)
    else
      -- broadcastToAll(request.text)
      print(request.text)
      spawnObjectJSON({json = request.text, callback_function = function (obj) print('spawned') end})
    end
  end)

  -- local id = '8342fd'
  -- local obj = getObjectFromGUID(id)
  -- local json = obj.getJSON(false)
end

-- Other functions

function outlineObstacles()
  local lines = {}

  repeat
  local bounds = {left = -29.57, right = -11.45, top = 9.06, bottom = -9.10}
  local ul = {bounds.left, 1, bounds.top}
  local ur = {bounds.right, 1, bounds.top}
  local ll = {bounds.left, 1, bounds.bottom}
  local lr = {bounds.right, 1, bounds.bottom}
  table.insert(lines, {points = {ul,ur}})
  table.insert(lines, {points = {ur,lr}})
  table.insert(lines, {points = {lr,ll}})
  table.insert(lines, {points = {ll,ul}})
  until true

  for i = 1, #owned_obstacles do
    local bounds = owned_obstacles[i].getBounds()
    local left = bounds.center.x - bounds.size.x/2
    local right = bounds.center.x + bounds.size.x/2
    local top = bounds.center.z + bounds.size.z/2
    local bottom = bounds.center.z - bounds.size.z/2
    local ul = {left, 1, top}
    local ur = {right, 1, top}
    local ll = {left, 1, bottom}
    local lr = {right, 1, bottom}
    table.insert(lines, {points = {ul,ur}})
    table.insert(lines, {points = {ur,lr}})
    table.insert(lines, {points = {lr,ll}})
    table.insert(lines, {points = {ll,ul}})
  end
  Global.setVectorLines(lines)
end

function placeObstacles(to_place)
  local bounds = {left = -29.57, right = -11.45, top = 9.06, bottom = -9.10}

  local placed = {}
  for i = 1, #to_place do
    local o = to_place[i]
    placeNewObstacle(o, bounds, placed, 0)
    table.insert(placed, o)
  end
end

function min_distance(tblr, other)
  assert(tblr.top ~= nil and tblr.bottom ~= nil and tblr.left ~= nil and tblr.right ~= nil)
  if #other == 0 then
    return 10000
  end

  local dist = distance(tblr, top_bottom_left_right(other[1]))
  for i = 2, #other do
    dist = math.min(dist, distance(tblr, top_bottom_left_right(other[i])))
  end
  return dist
end

-- bounds = {top = float, bottom = float, right = float, left = float}
function placeNewObstacle(new_obstacle, bounds, existing_obstacles, min_dist)
  local rot = {x = 0, y = math.random(0, 259), z = ({0, 180})[math.random(2)]}
  new_obstacle.setRotation(rot)

  local A = new_obstacle.getBounds()

  local bounds2 = bounds
  bounds = {
    left = bounds2.left + A.size.x/2,
    right = bounds2.right - A.size.x/2,
    top = bounds2.top - A.size.z/2,
    bottom = bounds2.bottom + A.size.z/2
  }

  local tries = 0
  local max_tries = 20
  local x, z
  repeat
    x = bounds.left + (bounds.right - bounds.left)*math.random()
    z = bounds.top + (bounds.bottom - bounds.top)*math.random()
    tries = tries + 1
    local new_A = {
      top = z + A.size.z/2,
      bottom = z - A.size.z/2,
      left = x - A.size.x/2,
      right = x + A.size.x/2
    }
  until #existing_obstacles == 0 or tries >= max_tries or min_distance(new_A, existing_obstacles) > 0
  if tries >= max_tries then
    print('too many tries. giving up.')
  end

  new_obstacle.setPosition({x=x, y=1.5, z=z})

--[[
  local row = math.floor(#existing_obstacles / 6)
  local col = #existing_obstacles % 6
  local pos = {x = bounds.left + (bounds.right - bounds.left)/5 * col,
               y = 4,
               z = bounds.top + (bounds.bottom - bounds.top)/5 * row}

  new_obstacle.setPositionSmooth(pos)
]]

end

function getRandomItemState (bags, callback_function)
  assert(#bags > 0)

  local bag = bags[math.random(#bags)]
  local taken_object = bag.takeObject({callback_function=callback_function})

  local states = taken_object.getStates() -- only alternative states
  local new_state_index = math.random(0, #states)
  --local new_state_index = 0
  if new_state_index ~= 0 then
    taken_object = taken_object.setState(states[new_state_index].id)
  end

  local pos = self.getPosition()
  pos.y = pos.y + 4
  pos.z = pos.z - 1
  taken_object.setPosition(pos)
  taken_object.setLock(true)

  return taken_object
end

function top_bottom_left_right(v)
  local bounds = v.getBounds()

  return {
    top = bounds.center.z + bounds.size.z/2,
    bottom = bounds.center.z - bounds.size.z/2,
    left = bounds.center.x - bounds.size.x/2,
    right = bounds.center.z + bounds.size.x/2,
  }
end

function distance(A, B)
  assert(A.top ~= nil and A.bottom ~= nil and A.left ~= nil and A.right ~= nil)
  assert(B.top ~= nil and B.bottom ~= nil and B.left ~= nil and B.right ~= nil)

  if not (A.top < B.bottom or B.top < A.bottom or A.right < B.left or B.right < A.left) then
    -- overlapping
    return 0
  end

  if math.min(A.top, B.top) >= math.max(A.bottom, B.bottom) then
    local dist = math.max(A.left, B.left) - math.min(A.right, B.right)
    assert(dist >= 0)
    return dist
  end

  if math.min(A.right, B.right) >= math.max(A.left, B.left) then
    local dist = math.max(A.bottom, B.bottom) - math.min(A.top, B.top)
    assert(dist >= 0)
    return dist
  end

  local x, y
  if A.right < B.left then
    x = B.left - A.right
  else
    x = A.left - B.right
  end
  assert(x >= 0)

  if A.top < B.bottom then
    y = B.bottom - A.top
  else
    y = A.bottom - B.top
  end
  assert(y >= 0)

  return math.sqrt(x*x + y*y)
end