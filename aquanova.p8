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

-- === initialization ===
function _init()
  -- resources initialized above
  update_field_count()
end

-- === update loop (30 times a second) ===
function _update()
  handle_input()
  update_time()
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
  print("=== " .. gamestate .. " ===", 32, 2, 7)
end

-- === station screens ===
function draw_bridge()
  print("bridge", 40, 12, 7)

  local y = 30
  draw_field(1, "station", gamestate, 10, y)

  y += 20
  print("(navigation coming soon)", 18, y, 6)
end

function draw_helm()
  print("helm controls", 32, 12, 7)

  local y = 30

  -- field 1: station
  draw_field(1, "station", gamestate, 10, y)
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
end

function draw_field(field_num, label, value, x, y)
  local color = 6 -- gray when not selected
  local prefix = " "
  local suffix = " "

  if current_field == field_num then
    color = 7 -- white when selected
    prefix = ">"
    suffix = "<"
  end

  print(prefix .. label .. ": " .. value .. suffix, x, y, color)
end

function draw_science()
  print("science", 42, 12, 7)

  local y = 30
  draw_field(1, "station", gamestate, 10, y)

  y += 20
  print("(sample analysis soon)", 16, y, 6)
end

function draw_engineering()
  print("engineering", 34, 12, 7)

  local y = 30
  draw_field(1, "station", gamestate, 10, y)

  y += 20
  print("(power management soon)", 12, y, 6)
end

function draw_quarters()
  print("captain's quarters", 16, 12, 7)

  local y = 25
  draw_field(1, "station", gamestate, 10, y)
  y += 15

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
    print("game over", 35, 118, 8)
  end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
