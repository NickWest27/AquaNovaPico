pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- aqua nova pico
-- submarine strategy game

-- === game state ===
gamestate = "bridge"
station_index = 1
stations = {
  "bridge",
  "helm",
  "science",
  "engineering",
  "quarters"
}

-- === resources ===
resources = {
  money = 1000,
  food = 50,
  supplies = 20,
  reactor = 100,
  o2_scrubbers = 100,
  reputation = 0
}

-- === time ===
game_time = 0
day_length = 1800 -- frames per day (60 seconds at 30fps)
current_day = 1
current_hour = 0
current_minute = 0

-- === submarine ===
sub = {
  x = 0,
  y = 0,
  heading = 0, -- degrees 0-360
  speed = 0, -- knots 0-160
  depth = 0 -- meters 0-1200
}

-- === field selection ===
current_field = 1
field_count = 1

-- === map and locations ===
world_size = 2000 -- world is 2000x2000 units
map_size = 96 -- map display is 96x96 pixels

-- sample sites
sample_sites = {
  {x=500, y=300, collected=false},
  {x=-400, y=200, collected=false},
  {x=300, y=-500, collected=false}
}

-- waypoint system
waypoint = {
  x = 0,
  y = 0,
  active = false
}

-- cursor for bridge map
cursor = {
  x = 0,
  y = 0
}

-- === initialization ===
function _init()
  -- resources initialized above
  update_field_count()
end

-- === update loop (30 times a second) ===
function _update()
  handle_input()
  update_time()
  update_movement()
end

function handle_input()
  -- field navigation (up/down)
  if btnp(2) then -- up arrow
    current_field -= 1
    if current_field < 1 then
      current_field = field_count
    end
  elseif btnp(3) then -- down arrow
    current_field += 1
    if current_field > field_count then
      current_field = 1
    end
  end

  -- field value adjustment (left/right)
  if btnp(0) or btnp(1) then
    if gamestate == "helm" then
      handle_helm_fields()
    elseif gamestate == "bridge" then
      handle_bridge_fields()
    elseif gamestate == "quarters" then
      handle_quarters_fields()
    elseif gamestate == "science" then
      handle_science_fields()
    elseif gamestate == "engineering" then
      handle_engineering_fields()
    end
  end

  -- x button: place waypoint on bridge
  if btnp(4) and gamestate == "bridge" then
    waypoint.x = cursor.x
    waypoint.y = cursor.y
    waypoint.active = true
  end
end

function handle_helm_fields()
  if current_field == 1 then -- station
    cycle_station()
  elseif current_field == 2 then -- heading
    if btnp(1) then -- right
      sub.heading += 15
      if sub.heading >= 360 then sub.heading -= 360 end
    else -- left
      sub.heading -= 15
      if sub.heading < 0 then sub.heading += 360 end
    end
  elseif current_field == 3 then -- speed
    if btnp(1) then -- right
      sub.speed += 10
      if sub.speed > 160 then sub.speed = 160 end
    else -- left
      sub.speed -= 10
      if sub.speed < 0 then sub.speed = 0 end
    end
  elseif current_field == 4 then -- depth
    if btnp(1) then -- right
      sub.depth += 50
      if sub.depth > 1200 then sub.depth = 1200 end
    else -- left
      sub.depth -= 50
      if sub.depth < 0 then sub.depth = 0 end
    end
  end
end

function handle_bridge_fields()
  if current_field == 1 then -- station
    cycle_station()
  elseif current_field == 2 then -- cursor x (lat)
    if btnp(1) then -- right
      cursor.x += 100
      if cursor.x > 1000 then cursor.x = 1000 end
    else -- left
      cursor.x -= 100
      if cursor.x < -1000 then cursor.x = -1000 end
    end
  elseif current_field == 3 then -- cursor y (lon)
    if btnp(1) then -- right
      cursor.y += 100
      if cursor.y > 1000 then cursor.y = 1000 end
    else -- left
      cursor.y -= 100
      if cursor.y < -1000 then cursor.y = -1000 end
    end
  end
end

function handle_quarters_fields()
  if current_field == 1 then -- station
    cycle_station()
  end
end

function handle_science_fields()
  if current_field == 1 then -- station
    cycle_station()
  end
end

function handle_engineering_fields()
  if current_field == 1 then -- station
    cycle_station()
  end
end

function cycle_station()
  if btnp(0) then -- left
    station_index -= 1
    if station_index < 1 then
      station_index = #stations
    end
  else -- right
    station_index += 1
    if station_index > #stations then
      station_index = 1
    end
  end
  gamestate = stations[station_index]
  current_field = 1
  update_field_count()
end

function update_field_count()
  if gamestate == "helm" then
    field_count = 4
  elseif gamestate == "bridge" then
    field_count = 3
  else
    field_count = 1
  end
end

function update_time()
  -- time progression
  game_time += 1

  -- update hours and minutes (30 frames = 1 minute)
  local total_minutes = flr(game_time / 30)
  current_hour = flr(total_minutes / 60) % 24
  current_minute = total_minutes % 60

  -- new day check
  if game_time >= day_length then
    game_time = 0
    current_day += 1
    current_hour = 0
    current_minute = 0

    -- daily resource consumption
    resources.food -= 1

    -- game over check
    if resources.food <= 0 then
      resources.food = 0
    end
  end
end

function update_movement()
  -- auto-navigate to waypoint if active
  if waypoint.active then
    local dx = waypoint.x - sub.x
    local dy = waypoint.y - sub.y
    local dist = sqrt(dx * dx + dy * dy)

    -- check if arrived
    if dist < 10 then
      waypoint.active = false
    else
      -- calculate desired heading to waypoint
      local desired_angle = atan2(dy, dx)
      local desired_heading = desired_angle * 360

      -- gradually adjust heading toward waypoint
      local heading_diff = desired_heading - sub.heading
      -- normalize to -180 to 180
      if heading_diff > 180 then heading_diff -= 360 end
      if heading_diff < -180 then heading_diff += 360 end

      -- adjust heading (5 degrees per frame max turn rate)
      if abs(heading_diff) > 5 then
        if heading_diff > 0 then
          sub.heading += 5
        else
          sub.heading -= 5
        end
      else
        sub.heading = desired_heading
      end

      -- wrap heading
      if sub.heading >= 360 then sub.heading -= 360 end
      if sub.heading < 0 then sub.heading += 360 end
    end
  end

  -- convert heading (0-360 degrees) to pico-8 angle (0.0-1.0)
  local angle = sub.heading / 360

  -- calculate velocity based on heading and speed
  -- speed is in knots, scale by time (1 frame at 60 knots = 1 unit per 30 frames)
  local speed_scale = sub.speed / 30

  -- pico-8 cos/sin: 0=right, 0.25=down, 0.5=left, 0.75=up
  local dx = cos(angle) * speed_scale
  local dy = sin(angle) * speed_scale

  -- update submarine position
  sub.x += dx
  sub.y += dy
end

-- === helper functions ===
function world_to_screen(world_x, world_y)
  -- convert world coordinates to screen coordinates
  -- map is centered on screen at (16, 16) to (112, 112)
  local screen_x = 16 + (world_x / world_size + 0.5) * map_size
  local screen_y = 16 + (world_y / world_size + 0.5) * map_size
  return screen_x, screen_y
end

-- === draw loop (30fps) ===
function _draw()
  cls()

  -- draw current station
  if gamestate == "bridge" then
    draw_bridge()
  elseif gamestate == "helm" then
    draw_helm()
  elseif gamestate == "science" then
    draw_science()
  elseif gamestate == "engineering" then
    draw_engineering()
  elseif gamestate == "quarters" then
    draw_quarters()
  end

  -- draw station name at top
  print("=== " .. gamestate .. " ===", 32, 0, 7)
end

-- === station screens ===
function draw_bridge()
  print("tactical map", 36, 6, 7)

  local y = 17

  -- cursor position fields
  draw_field(2, "lon", cursor.x, 13, y)
  y += 6
  draw_field(3, "lat", cursor.y, 13, y)
  y += 10

  -- draw map border
  rect(15, 15, 113, 113, 12)

  -- draw grid lines
  line(64, 15, 64, 113, 5) -- vertical center
  line(15, 64, 113, 64, 5) -- horizontal center

  -- draw port at (0,0)
  local port_x, port_y = world_to_screen(0, 0)
  rectfill(port_x-2, port_y-2, port_x+2, port_y+2, 10)
  print("p", port_x-1, port_y-1, 0)

  -- draw sample sites
  for site in all(sample_sites) do
    if not site.collected then
      local sx, sy = world_to_screen(site.x, site.y)
      circfill(sx, sy, 2, 12)
      print("s", sx-1, sy-1, 7)
    end
  end

  -- draw waypoint if active
  if waypoint.active then
    local wx, wy = world_to_screen(waypoint.x, waypoint.y)
    circfill(wx, wy, 3, 11)
    print("w", wx-1, wy-1, 0)
  end

  -- draw cursor
  local cx, cy = world_to_screen(cursor.x, cursor.y)
  rect(cx-3, cy-3, cx+3, cy+3, 7)
  line(cx-5, cy, cx-3, cy, 7) -- left
  line(cx+3, cy, cx+5, cy, 7) -- right
  line(cx, cy-5, cx, cy-3, 7) -- up
  line(cx, cy+3, cx, cy+5, 7) -- down

  -- draw submarine
  local sub_x, sub_y = world_to_screen(sub.x, sub.y)
  circfill(sub_x, sub_y, 2, 8)

  -- draw heading indicator
  local heading_angle = sub.heading / 360
  local hx = sub_x + cos(heading_angle) * 4
  local hy = sub_y + sin(heading_angle) * 4
  line(sub_x, sub_y, hx, hy, 7)

  -- display info below map
  print("x to set waypoint", 26, 116, 6)
  if waypoint.active then
    print("navigating...", 32, 100, 11)
  end

  -- station field at bottom
  draw_field(1, "station", gamestate, 26, 122)
end

function draw_helm()
  print("helm controls", 32, 12, 7)

  local y = 25

  -- display position
  print("position: x: " .. flr(sub.x) .. " y: " .. flr(sub.y), 10, y, 7)
  y += 15

  -- field 2: heading
  local compass = {"n", "ne", "e", "se", "s", "sw", "w", "nw"}
  local dir_idx = flr((sub.heading + 22.5) / 45) % 8 + 1
  draw_field(2, "heading", sub.heading .. "deg " .. compass[dir_idx], 10, y)
  y += 15

  -- field 3: speed
  draw_field(3, "speed", sub.speed .. " knots", 10, y)
  y += 15

  -- field 4: depth
  draw_field(4, "depth", sub.depth .. " m", 10, y)
  y += 20

  -- controls help
  print("up/down: cycle field", 8, y, 6)
  print("left/right: adjust value", 8, y+8, 6)

  -- station field at bottom
  draw_field(1, "station", gamestate, 26, 122)
end

function draw_field(field_num, label, value, x, y)
  local color = 6 -- gray when not selected
  local prefix = " "

  if current_field == field_num then
    color = 7 -- white when selected
    prefix = ">"
  end

  print(prefix .. label .. ": " .. value, x, y, color)
end

function draw_science()
  print("science", 42, 12, 7)

  local y = 30
  print("(sample analysis soon)", 16, y, 6)

  -- station field at bottom
  draw_field(1, "station", gamestate, 26, 122)
end

function draw_engineering()
  print("engineering", 34, 12, 7)

  local y = 30
  print("(power management soon)", 12, y, 6)

  -- station field at bottom
  draw_field(1, "station", gamestate, 26, 122)
end

function draw_quarters()
  print("captain's quarters", 16, 12, 7)

  local y = 25

  -- display mission clock (day and time)
  local hour_str = current_hour
  if current_hour < 10 then
    hour_str = "0" .. current_hour
  end
  local min_str = current_minute
  if current_minute < 10 then
    min_str = "0" .. current_minute
  end
  print("mission clock", 10, y, 6)
  y += 8
  print("day: " .. current_day .. " " .. hour_str .. ":" .. min_str, 10, y, 7)
  y += 15

  -- display position
  print("position", 10, y, 6)
  y += 8
  print("x: " .. flr(sub.x) .. " y: " .. flr(sub.y), 10, y, 7)
  y += 15

  -- display resources
  print("money: $" .. resources.money, 10, y, 10)
  y += 8
  print("food: " .. resources.food, 10, y, 8)
  y += 8
  print("supplies: " .. resources.supplies, 10, y, 12)
  y += 8
  print("reactor: " .. resources.reactor .. "%", 10, y, 11)
  y += 8
  print("o2 scrub: " .. resources.o2_scrubbers .. "%", 10, y, 7)
  y += 8
  print("reputation: " .. resources.reputation, 10, y, 14)

  -- game over warning
  if resources.food <= 0 then
    print("out of food!", 30, 110, 8)
    print("game over", 35, 116, 8)
  end

  -- station field at bottom
  draw_field(1, "station", gamestate, 26, 122)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
