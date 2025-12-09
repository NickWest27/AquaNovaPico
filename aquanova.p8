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
current_day = 0
current_hour = 0
current_minute = 0

-- === submarine ===
sub = {
  x = 0,
  y = 0,
  heading = 0, -- degrees 1-360 degrees True North
  speed = 0, -- knots 0-160
  depth = 0 -- meters 0-1200
}

-- === ui button system ===
input_mode = "navigate" -- "navigate" or "dpad_active"
ui_buttons = {} -- table of buttons on current screen
selected_button = 1 -- index of currently highlighted button

-- button types and their behavior
button_types = {
  -- single sprite buttons (8x8)
  up = "up",
  down = "down",
  left = "left",
  right = "right",
  action = "action",

  -- wide buttons (16x8) with optional labels
  left_big = "left_big",
  right_big = "right_big",

  -- composite controls
  dpad = "dpad",

  -- utility (keep for now, unused)
  simple_action = "simple_action",
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

-- cursor for bridge map (screen coordinates)
cursor = {
  x = 47,  -- start at submarine position
  y = 64
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

    -- reset cursor to home when activating cursor dpad
    if btn.label == "cursor" then
      cursor.x = 47
      cursor.y = 64
    end
  elseif btn.type == "up" or btn.type == "down" or btn.type == "left" or
         btn.type == "right" or btn.type == "action" or
         btn.type == "left_big" or btn.type == "right_big" then
    -- call on_press callback for sprite buttons
    if btn.on_press then btn.on_press() end
  elseif btn.type == "simple_action" or btn.type == "value" then
    if btn.on_press then btn.on_press() end
  end
end

-- === button setup functions ===
function setup_helm_buttons()
  add(ui_buttons, {
    type = "left_big",
    x = 101, y = 12,
    label = "HLM",
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
    type = "left_big",
    x = 101, y = 12,
    label = "BDG",
    on_press = cycle_station
  })

  add(ui_buttons, {
    type = "dpad",
    x = 108, y = 108, -- position of dpad on screen
    label = "cursor",
    sprite = 0,
    on_left = function()
      cursor.x -= 5
      if cursor.x < 0 then cursor.x = 0 end
    end,
    on_right = function()
      cursor.x += 5
      if cursor.x > 96 then cursor.x = 96 end
    end,
    on_up = function()
      cursor.y -= 5
      if cursor.y < 0 then cursor.y = 0 end
    end,
    on_down = function()
      cursor.y += 5
      if cursor.y > 96 then cursor.y = 96 end
    end,
    on_action = function()
      -- convert screen cursor to world waypoint
      local world_x, world_y = screen_to_world(cursor.x, cursor.y)
      waypoint.x = world_x
      waypoint.y = world_y
      waypoint.active = true
    end
  })
end

function setup_science_buttons()
  add(ui_buttons, {
    type = "left_big",
    x = 101, y = 12,
    label = "SCI",
    on_press = cycle_station
  })
end

function setup_engineering_buttons()
  add(ui_buttons, {
    type = "left_big",
    x = 101, y = 12,
    label = "ENG",
    on_press = cycle_station
  })
end

function setup_quarters_buttons()
  add(ui_buttons, {
    type = "left_big",
    x = 101, y = 12,
    label = "QTR",
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
function draw_button_sprite(x, y, type, state, label)
  -- sprite mapping table
  local sprite_map = {
    up = {normal=6, selected=1, active=11},
    down = {normal=7, selected=2, active=12},
    left = {normal=8, selected=3, active=13},
    right = {normal=9, selected=4, active=14},
    action = {normal=10, selected=5, active=15},
    left_big = {normal=8, selected=3, active=13},
    right_big = {normal=9, selected=4, active=14}
  }

  -- get sprite number from map
  local sprite_num = sprite_map[type][state]

  -- check if this is a big button
  if type == "left_big" or type == "right_big" then
    -- calculate sprite sheet pixel position
    local sx = (sprite_num % 16) * 8
    local sy = flr(sprite_num / 16) * 8

    -- draw stretched sprite (8x8 -> 16x8)
    sspr(sx, sy, 8, 8, x, y, 16, 8)

    -- draw label if provided
    if label then
      local text_color = 6 -- grey for normal
      if state == "selected" or state == "active" then
        text_color = 7 -- white for selected/active
      end

      -- center text over button
      local text_x = x + 8 - (#label * 4) / 2
      local text_y = y + 1
      print(label, text_x, text_y, text_color)
    end
  else
    -- regular 8x8 sprite button
    spr(sprite_num, x, y)
  end
end

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
  elseif btn.type == "up" or btn.type == "down" or btn.type == "left" or
         btn.type == "right" or btn.type == "action" then
    draw_button_sprite(btn.x, btn.y, btn.type, state)
  elseif btn.type == "left_big" or btn.type == "right_big" then
    -- determine which label to use based on state
    local display_label = btn.label_normal or btn.label
    if state == "selected" and btn.label_selected then
      display_label = btn.label_selected
    end
    draw_button_sprite(btn.x, btn.y, btn.type, state, display_label)
  elseif btn.type == "simple_action" then
    -- draw simple action button (rect-based)
    rect(btn.x, btn.y, btn.x+20, btn.y+10, color)
    print(btn.label, btn.x+2, btn.y+2, color)
  end
end

function draw_dpad_sprite(x, y, state)
  -- draw 5 sprites in cross pattern with 1px spacing
  draw_button_sprite(x, y-9, "up", state)      -- up
  draw_button_sprite(x, y+9, "down", state)    -- down
  draw_button_sprite(x-9, y, "left", state)    -- left
  draw_button_sprite(x+9, y, "right", state)   -- right
  draw_button_sprite(x, y, "action", state)    -- center
end

-- === helper functions ===
function pad_zeros(num, width)
  -- pad number with leading zeros to specified width
  local str = "" .. num
  while #str < width do
    str = "0" .. str
  end
  return str
end

function world_to_screen(world_x, world_y)
  -- submarine is fixed at screen position (47, 64)
  -- world scrolls around submarine
  -- world: x=longitude (+ east, - west), y=latitude (+ north, - south)
  -- screen: y increases downward, so flip y axis for latitude

  -- calculate offset from submarine in world units
  local dx = world_x - sub.x
  local dy = world_y - sub.y

  -- convert to screen pixels (scale factor = map_size / world_size)
  local scale = map_size / world_size
  local screen_x = 47 + dx * scale
  local screen_y = 64 - dy * scale  -- negative because screen Y is inverted

  return screen_x, screen_y
end

function screen_to_world(screen_x, screen_y)
  -- inverse of world_to_screen
  -- convert screen position to world coordinates
  local scale = map_size / world_size
  local world_x = sub.x + (screen_x - 47) / scale
  local world_y = sub.y - (screen_y - 64) / scale  -- negative for Y inversion
  return world_x, world_y
end

function draw_corner_mask()
  -- fill triangular corner mask
  -- covers area above diagonal from (0,32) to (32,0)
  for y=0,31 do
    line(0, y, 32-y, y, 1)
  end
end

function draw_rotated_sub(x, y, heading)
  -- draw submarine triangle pointing in direction of heading
  -- heading: 0=north, 90=east, 180=south, 270=west
  -- convert heading to pico-8 angle (0.0-1.0)
  local angle = (heading - 90) / 360

  -- define triangle points relative to center
  -- nose points forward, base is stern
  local nose_dist = 4
  local base_dist = 3
  local base_width = 2

  -- calculate nose point (forward)
  local nose_x = x + cos(angle) * nose_dist
  local nose_y = y + sin(angle) * nose_dist

  -- calculate base points (stern, perpendicular to heading)
  local perp_angle = angle + 0.25  -- perpendicular angle
  local base1_x = x - cos(angle) * base_dist + cos(perp_angle) * base_width
  local base1_y = y - sin(angle) * base_dist + sin(perp_angle) * base_width
  local base2_x = x - cos(angle) * base_dist - cos(perp_angle) * base_width
  local base2_y = y - sin(angle) * base_dist - sin(perp_angle) * base_width

  -- draw triangle
  line(nose_x, nose_y, base1_x, base1_y, 7)
  line(nose_x, nose_y, base2_x, base2_y, 7)
  line(base1_x, base1_y, base2_x, base2_y, 8)
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
  rect(0, 0, 127, 127, 13)
end

-- === station screens ===
function draw_bridge()

  -- right side info bar
  print(station, 101, 2, 7) -- station title

  -- bottom info bar
  print("navigation positionlog", 1, 98, 12) -- info bar title
  print("mission time: ", 1, 104, 12) 
  print(current_day .. " " .. pad_zeros(current_hour, 2) .. ":" .. pad_zeros(current_minute, 2), 53, 104, 6) -- mission time label
  print("currpos: " .. flr(sub.x) .. "," .. flr(sub.y), 1, 110, 6) -- current position label
  print("destpos: ", 1, 116, 12)
  if waypoint.active then 
    print(flr(waypoint.x) .. "," .. flr(waypoint.y), 37, 116, 6) -- destination position label
    else
    print(" - - - -", 37, 116, 6)
  end

  -- draw grid lines
  line(0, 32, 0, 96, 1) -- longitude major line
  line(32, 0, 32, 96, 1)
  line(64, 0, 64, 96, 1)
  line(96, 0, 96, 96, 1)
  line(32, 0, 96, 0, 1) -- latitude major line
  line(0, 32, 96, 32, 1)
  line(0, 64, 96, 64, 1)
  line(0, 96, 96, 96, 1)

  -- draw port at (0,0)
  local port_x, port_y = world_to_screen(0, 0)
  spr(33, port_x-4, port_y-4) -- subtract 4 to center


  -- draw sample sites
  for site in all(sample_sites) do
    if not site.collected then
      local sx, sy = world_to_screen(site.x, site.y)
      spr(35, sx-4, sy-4) -- subtract 4 to center
    end
  end

  -- draw waypoint if active
  if waypoint.active then
    local wx, wy = world_to_screen(waypoint.x, waypoint.y)
    circfill(wx, wy, 3, 11)
    print("w", wx-1, wy-1, 0)
  end

  -- draw cursor (only when cursor dpad is active)
  if input_mode == "dpad_active" and selected_button == 2 then
    local cx, cy = cursor.x, cursor.y
    rect(cx-3, cy-3, cx+3, cy+3, 7)
    line(cx-5, cy, cx-3, cy, 7) -- left
    line(cx+3, cy, cx+5, cy, 7) -- right
    line(cx, cy-5, cx, cy-3, 7) -- up
    line(cx, cy+3, cx, cy+5, 7) -- down
  end

  -- draw submarine (fixed at screen position)
  draw_rotated_sub(47, 64, sub.heading)

  -- cursor position info (show world coordinates)
  local cursor_world_x, cursor_world_y = screen_to_world(cursor.x, cursor.y)
  print("cursor: " .. flr(cursor_world_x) .. "," .. flr(cursor_world_y), 33, 1, 6)

  -- draw corner mask
  draw_corner_mask()

  -- draw submarine status info
  print("d" .. sub.depth, 1, 1, 7)
  print("h" .. pad_zeros(sub.heading, 3), 1, 7, 7)
  print("s" .. pad_zeros(sub.speed, 3), 1, 13, 7)

  -- draw map border
  line(32, 0, 96, 0, 12) -- top
  line(96, 0, 96, 96, 12) -- right
  line(0, 96, 96, 96, 12) -- bottom
  line(0, 32, 0, 96, 12) -- left
  line(0, 32, 32, 0, 12) -- top left corner

  -- draw d-pad control on right side
  draw_ui_buttons()

  if waypoint.active then
    print("navigating...", 2, 90, 11)
  end
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
00000000000777000000777007770000000770000006660000006660066600000006600000000000000000000000000000000000000000000000000000000000
0000000000770dddddddd077770dddddddd0770000660dddddddd066660dddddddd0660000000000000000000000000000000000000000000000000000000000
000000000770dddddddddd0770dddddddddd07700660dddddddddd0660dddddddddd066000000000000000000000000000000000000000000000000000000000
00000000770dddddddddddd77dddddddddddd077660dddddddddddd66dddddddddddd06600000000000000000000000000000000000000000000000000000000
00000000770dddddddddddd77dddddddddddd077660dddddddddddd66dddddddddddd06600000000000000000000000000000000000000000000000000000000
000000000770dddddddddd0770dddddddddd07700660dddddddddd0660dddddddddd066000000000000000000000000000000000000000000000000000000000
0000000000770dddddddd077770dddddddd0770000660dddddddd066660dddddddd0660000000000000000000000000000000000000000000000000000000000
00000000000777000000777007770000000770000006660000006660066600000006600000000000000000000000000000000000000000000000000000000000
0000000000066600000000000000dd000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000666666600000000006666600000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000606060000000000666666000b300b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000006000000000006560ddd000b000330eeee00e00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060060060000000066600d00b030b000eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066060660000000006600000b000b0b0e000ee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000666666600000000506ddddd33b030b000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000666000000000005555550003000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
