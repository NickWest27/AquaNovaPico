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

-- === initialization ===
function _init()
  -- resources initialized above
end

-- === update loop (30 times a second) ===
function _update()
  -- station switching (x button always works)
  if btnp(5) then -- x button
    station_index += 1
    if station_index > #stations then
      station_index = 1
    end
    gamestate = stations[station_index]
  end

  -- helm controls (only when on helm station)
  if gamestate == "helm" then
    if btnp(0) then -- left arrow
      sub.heading -= 15
      if sub.heading < 0 then
        sub.heading += 360
      end
    elseif btnp(1) then -- right arrow
      sub.heading += 15
      if sub.heading >= 360 then
        sub.heading -= 360
      end
    end

    if btnp(2) then -- up arrow
      sub.speed += 10
      if sub.speed > 160 then
        sub.speed = 160
      end
    elseif btnp(3) then -- down arrow
      sub.speed -= 10
      if sub.speed < 0 then
        sub.speed = 0
      end
    end
  end

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
  print("bridge", 40, 60, 7)
  print("(navigation)", 30, 68, 6)
end

function draw_helm()
  print("helm controls", 32, 12, 7)

  -- display heading
  local y = 35
  print("heading:", 10, y, 6)
  print(sub.heading .. " deg", 70, y, 7)

  -- heading indicator (simple compass)
  y += 15
  local compass = {"n", "ne", "e", "se", "s", "sw", "w", "nw"}
  local dir_idx = flr((sub.heading + 22.5) / 45) % 8 + 1
  print("direction: " .. compass[dir_idx], 10, y, 12)

  -- display speed
  y += 20
  print("speed:", 10, y, 6)
  print(sub.speed .. " knots", 70, y, 7)

  -- display depth
  y += 15
  print("depth:", 10, y, 6)
  print(sub.depth .. " m", 70, y, 7)

  -- controls help
  y += 25
  print("arrows: turn/speed", 20, y, 6)
  print("left/right: heading", 20, y+8, 6)
  print("up/down: speed", 20, y+16, 6)
end

function draw_science()
  print("science", 38, 60, 7)
  print("(samples)", 32, 68, 6)
end

function draw_engineering()
  print("engineering", 42, 60, 7)
  print("(management)", 28, 68, 6)
end

function draw_quarters()
  print("captain's quarters", 16, 12, 7)

  -- display mission clock (day and time)
  local hour_str = current_hour
  if current_hour < 10 then
    hour_str = "0" .. current_hour
  end
  local min_str = current_minute
  if current_minute < 10 then
    min_str = "0" .. current_minute
  end
  print("mission clock", 10, 22, 6)
  print("day: " .. current_day .. " time: " .. hour_str .. ":" .. min_str, 10, 30, 7)

  -- display resources
  local y = 45
  print("money: $" .. resources.money, 10, y, 10)
  y += 10
  print("food: " .. resources.food, 10, y, 8)
  y += 10
  print("supplies: " .. resources.supplies, 10, y, 12)
  y += 10
  print("reactor: " .. resources.reactor .. "%", 10, y, 11)
  y += 10
  print("o2 scrub: " .. resources.o2_scrubbers .. "%", 10, y, 7)
  y += 10
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
