pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- aqua nova pico
-- submarine strategy game

-- === game state ===
station = "bridge"
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

-- === ui button system ===
input_mode = "navigate" -- "navigate" or "dpad_active"
ui_buttons = {} -- table of buttons on current screen
selected_button = 1 -- index of currently highlighted button

-- button types and their behavior
button_types = {
  dpad = "dpad",
  station = "station",
  action = "action",
  value = "value"
}

-- === map and locations ===
world_size = 2000 -- world is 2000x2000 units
map_size = 96 -- map display is 96x96 pixels

-- sample sites
sample_sites = {
  {x=500, y=300, collected=false},
  {x=-400, y=200, collected=false},
  {x=300, y=-500, collected=false}
}

-- sample collection
samples_collected = 0
collection_range = 5  -- units within which to collect

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
  setup_station_buttons()
end

function setup_station_buttons()
  -- setup buttons based on current station
  ui_buttons = {}
  selected_button = 1
  input_mode = "navigate"

  if station == "helm" then
    setup_helm_buttons()
  elseif station == "bridge" then
    setup_bridge_buttons()
  elseif station == "science" then
    setup_science_buttons()
  elseif station == "engineering" then
    setup_engineering_buttons()
  elseif station == "quarters" then
    setup_quarters_buttons()
  end
end

-- === logic update loop (30 times a second) ===
function _update()
  handle_input()
  update_time()
  update_movement()
  update_sample_collection()
end

function handle_input()
  if input_mode == "navigate" then
    handle_navigation_input()
  elseif input_mode == "dpad_active" then
    handle_dpad_input()
  end
end

function handle_navigation_input()
  -- arrow keys navigate between ui buttons
  if btnp(2) then -- up arrow
    selected_button -= 1
    if selected_button < 1 then
      selected_button = #ui_buttons
    end
  elseif btnp(3) then -- down arrow
    selected_button += 1
    if selected_button > #ui_buttons then
      selected_button = 1
    end
  elseif btnp(0) then -- left arrow
    selected_button -= 1
    if selected_button < 1 then
      selected_button = #ui_buttons
    end
  elseif btnp(1) then -- right arrow
    selected_button += 1
    if selected_button > #ui_buttons then
      selected_button = 1
    end
  end

  -- x button activates selected button
  if btnp(5) then -- x key
    activate_button(ui_buttons[selected_button])
  end
end

function handle_dpad_input()
  -- when dpad is active, arrows control the dpad
  local dpad_btn = ui_buttons[selected_button]

  if dpad_btn and dpad_btn.type == "dpad" then
    -- call the button's action with direction
    if btnp(2) then -- up
      if dpad_btn.on_up then dpad_btn.on_up() end
    elseif btnp(3) then -- down
      if dpad_btn.on_down then dpad_btn.on_down() end
    elseif btnp(0) then -- left
      if dpad_btn.on_left then dpad_btn.on_left() end
    elseif btnp(1) then -- right
      if dpad_btn.on_right then dpad_btn.on_right() end
    end

    -- x button is action button when dpad active
    if btnp(5) then -- x key
      if dpad_btn.on_action then dpad_btn.on_action() end
    end

    -- z button deactivates dpad
    if btnp(4) then -- z key
      input_mode = "navigate"
    end
  end
end

function activate_button(btn)
  if not btn then return end

  if btn.type == "dpad" then
    -- activate dpad mode
    input_mode = "dpad_active"
  elseif btn.type == "station" then
    -- cycle station
    if btn.on_press then btn.on_press() end
  elseif btn.type == "action" then
    -- perform action
    if btn.on_press then btn.on_press() end
  elseif btn.type == "value" then
    -- toggle or cycle value
    if btn.on_press then btn.on_press() end
  end
end

-- === button setup functions ===
function setup_helm_buttons()
  add(ui_buttons, {
    type = "station",
    x = 26, y = 122,
    label = "station",
    on_press = cycle_station
  })

  add(ui_buttons, {
    type = "dpad",
    x = 18, y = 60,
    label = "heading",
    sprite = 0, -- sprite index for dpad
    on_left = function()
      sub.heading -= 15
      if sub.heading < 0 then sub.heading += 360 end
    end,
    on_right = function()
      sub.heading += 15
      if sub.heading >= 360 then sub.heading -= 360 end
    end
  })

  add(ui_buttons, {
    type = "dpad",
    x = 56, y = 60,
    label = "speed",
    sprite = 0,
    on_up = function()
      sub.speed += 10
      if sub.speed > 160 then sub.speed = 160 end
    end,
    on_down = function()
      sub.speed -= 10
      if sub.speed < 0 then sub.speed = 0 end
    end
  })

  add(ui_buttons, {
    type = "dpad",
    x = 94, y = 60,
    label = "depth",
    sprite = 0,
    on_up = function()
      sub.depth -= 50
      if sub.depth < 0 then sub.depth = 0 end
    end,
    on_down = function()
      sub.depth += 50
      if sub.depth > 1200 then sub.depth = 1200 end
    end
  })
end

function setup_bridge_buttons()
  add(ui_buttons, {
    type = "station",
    x = 26, y = 122,
    label = "station",
    on_press = cycle_station
  })

  add(ui_buttons, {
    type = "dpad",
    x = 106, y = 106,
    label = "cursor",
    sprite = 0,
    on_left = function()
      cursor.x -= 100
      if cursor.x < -1000 then cursor.x = -1000 end
    end,
    on_right = function()
      cursor.x += 100
      if cursor.x > 1000 then cursor.x = 1000 end
    end,
    on_up = function()
      cursor.y += 100
      if cursor.y > 1000 then cursor.y = 1000 end
    end,
    on_down = function()
      cursor.y -= 100
      if cursor.y < -1000 then cursor.y = -1000 end
    end,
    on_action = function()
      waypoint.x = cursor.x
      waypoint.y = cursor.y
      waypoint.active = true
    end
  })
end

function setup_science_buttons()
  add(ui_buttons, {
    type = "station",
    x = 26, y = 122,
    label = "station",
    on_press = cycle_station
  })
end

function setup_engineering_buttons()
  add(ui_buttons, {
    type = "station",
    x = 26, y = 122,
    label = "station",
    on_press = cycle_station
  })
end

function setup_quarters_buttons()
  add(ui_buttons, {
    type = "station",
    x = 26, y = 122,
    label = "station",
    on_press = cycle_station
  })
end

function cycle_station()
  station_index += 1
  if station_index > #stations then
    station_index = 1
  end
  station = stations[station_index]
  setup_station_buttons()
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
      sub.speed = 0  -- stop when arriving at waypoint
    else
      -- calculate desired heading to waypoint
      -- movement: angle = (heading-90)/360, dx=cos(angle), dy=sin(angle)
      -- reverse: heading = atan2(dy,dx)*360 + 90
      -- but atan2 seems inverted, try subtracting instead
      local desired_angle = atan2(dy, dx)
      local desired_heading = desired_angle * 360 - 90
      if desired_heading >= 360 then desired_heading -= 360 end
      if desired_heading < 0 then desired_heading += 360 end

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
  -- heading: 0=north, 90=east, 180=south, 270=west
  -- pico-8: 0=east, 0.25=south, 0.5=west, 0.75=north
  local angle = (sub.heading - 90) / 360

  -- calculate velocity based on heading and speed
  -- speed is in knots, scale by time (1 frame at 60 knots = 1 unit per 30 frames)
  local speed_scale = sub.speed / 30

  local dx = cos(angle) * speed_scale
  local dy = sin(angle) * speed_scale  -- positive because world Y+ = north (lat increases upward)

  -- update submarine position
  sub.x += dx
  sub.y += dy
end

function update_sample_collection()
  -- check if near any uncollected sample sites
  for site in all(sample_sites) do
    if not site.collected then
      local dx = site.x - sub.x
      local dy = site.y - sub.y
      local dist = sqrt(dx * dx + dy * dy)

      if dist < collection_range then
        site.collected = true
        samples_collected += 1
        resources.money += 100  -- reward for sample
      end
    end
  end
end

-- === button drawing ===
function draw_button(btn, is_selected)
  local color = 6 -- gray when not selected
  local state = "normal"

  if is_selected then
    if input_mode == "dpad_active" and btn.type == "dpad" then
      state = "active"
      color = 11
    else
      state = "selected"
      color = 7
    end
  end

  -- draw button based on type
  if btn.type == "dpad" then
    draw_dpad_sprite(btn.x, btn.y, state)
  elseif btn.type == "station" then
    -- draw as text button
    local prefix = " "
    if is_selected then prefix = ">" end
    print(prefix .. btn.label .. ": " .. station, btn.x, btn.y, color)
  elseif btn.type == "action" then
    -- draw action button
    rect(btn.x, btn.y, btn.x+20, btn.y+10, color)
    print(btn.label, btn.x+2, btn.y+2, color)
  end
end

function draw_dpad_sprite(x, y, state)
  -- state: "normal", "selected", or "active"
  -- determine sprite indices based on state
  local left_spr, right_spr, up_spr, down_spr, center_spr

  if state == "normal" then
    -- deselected sprites (6-10)
    up_spr = 6
    down_spr = 7
    left_spr = 8
    right_spr = 9
    center_spr = 10
  elseif state == "active" then
    -- pressed sprites (11-15)
    up_spr = 11
    down_spr = 12
    left_spr = 13
    right_spr = 14
    center_spr = 15
  else -- "selected"
    -- selected sprites (1-5)
    up_spr = 1
    down_spr = 2
    left_spr = 3
    right_spr = 4
    center_spr = 5
  end

  -- draw 5 sprites in cross pattern with 1px spacing
  spr(up_spr, x, y-9)        -- up
  spr(down_spr, x, y+9)      -- down
  spr(left_spr, x-9, y)      -- left
  spr(right_spr, x+9, y)     -- right
  spr(center_spr, x, y)      -- center
end

-- === helper functions ===
function world_to_screen(world_x, world_y)
  -- convert world coordinates to screen coordinates
  -- map is centered on screen at (16, 16) to (112, 112)
  -- world: x=longitude (+ east, - west), y=latitude (+ north, - south)
  -- screen: y increases downward, so flip y axis
  local screen_x = 16 + (world_x / world_size + 0.5) * map_size
  local screen_y = 16 + (-world_y / world_size + 0.5) * map_size
  return screen_x, screen_y
end

-- === draw loop (30fps) ===
function _draw()
  cls()
  draw_dev_grid()

  -- draw current station
  if station == "bridge" then
    draw_bridge()
  elseif station == "helm" then
    draw_helm()
  elseif station == "science" then
    draw_science()
  elseif station == "engineering" then
    draw_engineering()
  elseif station == "quarters" then
    draw_quarters()
  end
end

function draw_dev_grid()
  -- draw development layout guidline grid
  line(0, 32, 128, 32, 5)
  line(0, 64, 128, 64, 5)
  line(0, 96, 128, 96, 5)
  line(32, 0, 32, 128, 5)
  line(64, 0, 64, 128, 5)
  line(96, 0, 96, 128, 5)
end

-- === station screens ===
function draw_bridge()
    -- draw station name at top
  print(station, 101, 0, 7)

  -- draw grid lines
  line(0, 32, 0, 96, 1) -- vertical
  line(32, 0, 32, 96, 1)
  line(64, 0, 64, 96, 1)
  line(96, 0, 96, 96, 1)
  line(32, 0, 96, 0, 1) -- horizontal
  line(0, 32, 96, 32, 1)
  line(0, 64, 96, 64, 1)
  line(0, 96, 96, 96, 1)

  -- draw port at (0,0)
  local port_x, port_y = world_to_screen(0, 0)
  spr(17, port_x-4, port_y-4) -- subtract 4 to center


  -- draw sample sites
  for site in all(sample_sites) do
    if not site.collected then
      local sx, sy = world_to_screen(site.x, site.y)
      spr(19, sx-4, sy-4) -- subtract 4 to center
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
  line(sub_x, sub_y, sub_x+2, sub_y+4, 7) -- right side
  line(sub_x, sub_y, sub_x-2, sub_y+4, 7) -- left side
  line(sub_x-2, sub_y+4, sub_x+2, sub_y+4, 7) -- stern

  -- cursor position info
  print("cursor: " .. cursor.x .. "," .. cursor.y, 33, 1, 6)

  -- draw map border
  line(32, 0, 96, 0, 12) -- top
  line(96, 0, 96, 96, 12) -- right
  line(0, 96, 96, 96, 12) -- bottom
  line(0, 32, 0, 96, 12) -- left
  line(0, 32, 32, 0, 12) -- top left corner

  -- draw d-pad control on right side
  draw_ui_buttons()

  if waypoint.active then
    print("navigating...", 2, 100, 11)
  end
  print("x=set waypoint", 2, 106, 6)
end

function draw_helm()
  print("helm controls", 32, 12, 7)

  local y = 25

  -- display position
  print("position", 10, y, 6)
  print("x: " .. flr(sub.x) .. " y: " .. flr(sub.y), 10, y+6, 7)
  y += 20

  -- display current values above dpads
  local compass = {"n", "ne", "e", "se", "s", "sw", "w", "nw"}
  local dir_idx = flr((sub.heading + 22.5) / 45) % 8 + 1

  print("heading", 10, y, 6)
  print(sub.heading .. " " .. compass[dir_idx], 10, y+6, 7)

  print("speed", 60, y, 6)
  print(sub.speed .. " kts", 60, y+6, 7)

  print("depth", 95, y, 6)
  print(sub.depth .. " m", 95, y+6, 7)

  -- draw buttons (dpads will be drawn below labels)
  draw_ui_buttons()

  -- controls help
  print("arrows: navigate/use", 8, 105, 6)
  print("x: select/action", 8, 111, 6)
  print("z: deactivate dpad", 8, 117, 6)
end

function draw_ui_buttons()
  -- draw all buttons for current screen
  for i, btn in pairs(ui_buttons) do
    local is_selected = (i == selected_button)
    draw_button(btn, is_selected)
  end
end

function draw_science()
  print("science", 42, 12, 7)

  local y = 30
  print("samples collected", 18, y, 7)
  y += 8
  print(samples_collected .. " / " .. #sample_sites, 40, y, 11)
  y += 15

  -- list sample sites
  for i, site in pairs(sample_sites) do
    local status = "uncollected"
    local col = 8
    if site.collected then
      status = "collected"
      col = 11
    end
    print("site " .. i .. ": " .. status, 10, y, col)
    y += 8
  end

  -- draw buttons
  draw_ui_buttons()
end

function draw_engineering()
  print("engineering", 34, 12, 7)

  local y = 30
  print("(power management soon)", 12, y, 6)

  -- draw buttons
  draw_ui_buttons()
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

  -- draw buttons
  draw_ui_buttons()
end
__gfx__
00000000000770000777777000077070070770000077770000066000066666600006606006066000006666000007700007777770000770700707700000777700
0000000000777700770dd07700770007700077000700007000666600660dd06600660006600066000600006000777700770cc077007700077000770007000070
007007000770077000dddd000770dd0770dd0770700dd0070660066000dddd000660dd0660dd0660600dd0060770077000cccc000770cc0770cc0770700cc007
00077000770dd07700dddd00770dddd77dddd07770dddd07660dd06600dddd00660dddd66dddd06660dddd06770cc07700cccc00770cccc77cccc07770cccc07
0007700070dddd07770dd077770dddd77dddd07770dddd0760dddd06660dd066660dddd66dddd06660dddd0670cccc07770cc077770cccc77cccc07770cccc07
0070070000dddd00077007700770dd0770dd0770700dd00700dddd00066006600660dd0660dd0660600dd00600cccc00077007700770cc0770cc0770700cc007
00000000700dd00700777700007700077000770007000070600dd00600666600006600066000660006000060700cc00700777700007700077000770007000070
00000000077777700007700000077070070770000077770006666660000660000006606006066000006666000777777000077000000770700707700000777700
0000000066666666000066000000dd000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000700006600007660006666600000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007000006000070660666666000b300b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000999000060009aa066560ddd000b000330eeee00e00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000885558800000666600d00b030b000eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000009aa88885889aa0a006600000b000b0b0e000ee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008080885588808088506ddddd33b030b000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888880000888888005555550003000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
