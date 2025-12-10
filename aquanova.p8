pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- aqua nova pico
-- submarine strategy game

-- =====================================================================
-- === game state ===
-- =====================================================================
station = "bridge"
station_index = 3
stations = {
  "communications",
  "sensors",
  "bridge",
  "helm",
  "engineering",
  "science",
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
-- scale: 1 world unit = 1 minute, 60 units = 1 degree
-- map zoom: 1 pixel = 1 minute (tactical zoom level)
world_size = 21600 -- world is full globe: 360° × 60 minutes
map_size = 96 -- map display is 96×96 pixels
zoom = 1.0 -- zoom level: 1.0 = 1 pixel per minute (96 pixels shows 96 minutes = 1.6°)
-- world coordinates (full globe):
-- x: longitude -10800 to +10800 (-180° to +180°, wraps at boundaries)
-- y: latitude -5400 to +5400 (-90° to +90°, clamps at poles)
-- at zoom=1.0, the 96×96 map shows 96×96 minutes (1.6° × 1.6°) centered on submarine

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
-- waypoint 0 = ownship present position (implicit)
-- waypoint 1, 2, 3... = user-defined waypoints
waypoints = {}
active_waypoint_index = 0  -- 0 = no active route, 1+ = navigating to waypoint N

-- cursor for bridge map (screen coordinates)
cursor = {
  x = 47,  -- start at submarine position
  y = 64
}
-- =====================================================================
-->8
-- === initialization ===
-- =====================================================================
function _init()
  -- resources initialized above
  setup_station_buttons()
end

function setup_station_buttons()
  -- setup buttons based on current station
  local prev_selected = selected_button
  ui_buttons = {}
  input_mode = "navigate"

  if station == "communications" then
    setup_comm_buttons()
  elseif station == "sensors" then
    setup_sensors_buttons()
  elseif station == "bridge" then
    setup_bridge_buttons()
  elseif station == "helm" then
    setup_helm_buttons()
  elseif station == "engineering" then
    setup_engineering_buttons()
  elseif station == "science" then
    setup_science_buttons()
  elseif station == "quarters" then
    setup_quarters_buttons()
  end

  -- validate and restore selection
  if prev_selected < 1 or prev_selected > #ui_buttons then
    selected_button = 1
  else
    selected_button = prev_selected
  end
end

-- =====================================================================
-->8
-- === logic update loop (30 times a second) ===
-- =====================================================================
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

-- === button helper functions ===
function button(btn_type, x, y, on_press, label_normal, color_normal, label_selected, color_selected)
  add(ui_buttons, {
    type = btn_type,
    x = x,
    y = y,
    on_press = on_press,
    label = label_normal,
    label_normal = label_normal,
    label_selected = label_selected,
    color_normal = color_normal,
    color_selected = color_selected
  })
end

function dpad(x, y, callbacks)
  add(ui_buttons, {
    type = "dpad",
    x = x,
    y = y,
    label = callbacks.label or "",
    on_left = callbacks.left,
    on_right = callbacks.right,
    on_up = callbacks.up,
    on_down = callbacks.down,
    on_action = callbacks.action
  })
end

-- === button setup functions ===
function setup_comm_buttons()
  button("left_big", 102, 12, cycle_station_backward, "QT")
  button("right_big", 102, 21, cycle_station_forward, "SR")
  -- placeholder for future comm buttons
end

function setup_sensors_buttons()
  button("left_big", 102, 12, cycle_station_backward, "CM")
  button("right_big", 102, 21, cycle_station_forward, "BR")
  -- placeholder for future sensor buttons
end

function setup_bridge_buttons()
  button("left_big", 102, 12, cycle_station_backward, "SR") -- station left
  button("right_big", 102, 21, cycle_station_forward, "HL") -- station right

  dpad(108, 108, {
    label = "cursor",
    left = function()
      -- move cursor in 1-minute increments
      -- 1 world unit = 1 minute
      -- 60 world units = 1 degree
      local world_x, world_y = screen_to_world(cursor.x, cursor.y)
      world_x -= 1  -- move 1 minute west
      cursor.x, cursor.y = world_to_screen(world_x, world_y)
      if cursor.x < 0 then cursor.x = 0 end
    end,
    right = function()
      local world_x, world_y = screen_to_world(cursor.x, cursor.y)
      world_x += 1  -- move 1 minute east
      cursor.x, cursor.y = world_to_screen(world_x, world_y)
      if cursor.x > 96 then cursor.x = 96 end
    end,
    up = function()
      local world_x, world_y = screen_to_world(cursor.x, cursor.y)
      world_y += 1  -- move 1 minute north (world Y+ = north)
      cursor.x, cursor.y = world_to_screen(world_x, world_y)
      if cursor.y < 0 then cursor.y = 0 end
    end,
    down = function()
      local world_x, world_y = screen_to_world(cursor.x, cursor.y)
      world_y -= 1  -- move 1 minute south
      cursor.x, cursor.y = world_to_screen(world_x, world_y)
      if cursor.y > 96 then cursor.y = 96 end
    end,
    action = function()
      -- convert screen cursor to world waypoint and add to route
      local world_x, world_y = screen_to_world(cursor.x, cursor.y)
      add(waypoints, {x=world_x, y=world_y})

      -- activate navigation if this is first waypoint
      if active_waypoint_index == 0 then
        active_waypoint_index = 1
      end
    end
  })
end

function setup_helm_buttons()
  button("left_big", 102, 12, cycle_station_backward, "BR")
  button("right_big", 102, 21, cycle_station_forward, "EN")

  dpad(18, 60, {
    label = "heading",
    left = function()
      sub.heading -= 15
      if sub.heading < 0 then sub.heading += 360 end
    end,
    right = function()
      sub.heading += 15
      if sub.heading >= 360 then sub.heading -= 360 end
    end
  })

  dpad(56, 60, {
    label = "speed",
    up = function()
      sub.speed += 10
      if sub.speed > 160 then sub.speed = 160 end
    end,
    down = function()
      sub.speed -= 10
      if sub.speed < 0 then sub.speed = 0 end
    end
  })

  dpad(94, 60, {
    label = "depth",
    up = function()
      sub.depth -= 50
      if sub.depth < 0 then sub.depth = 0 end
    end,
    down = function()
      sub.depth += 50
      if sub.depth > 1200 then sub.depth = 1200 end
    end
  })
end

function setup_engineering_buttons()
  button("left_big", 102, 12, cycle_station_backward, "HL")
  button("right_big", 102, 21, cycle_station_forward, "SC")
end

function setup_science_buttons()
  button("left_big", 102, 12, cycle_station_backward, "EN")
  button("right_big", 102, 21, cycle_station_forward, "QT")
end

function setup_quarters_buttons()
  button("left_big", 102, 12, cycle_station_backward, "SC")
  button("right_big", 102, 21, cycle_station_forward, "CM")
end

function cycle_station_forward()
  station_index += 1
  if station_index > #stations then
    station_index = 1
  end
  station = stations[station_index]
  setup_station_buttons()
end

function cycle_station_backward()
  station_index -= 1
  if station_index < 1 then
    station_index = #stations
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
  if active_waypoint_index > 0 and active_waypoint_index <= #waypoints then
    local target_wpt = waypoints[active_waypoint_index]
    local dx = target_wpt.x - sub.x
    local dy = target_wpt.y - sub.y

    -- handle longitude wrapping (take shortest path)
    if dx > 10800 then
      dx -= 21600
    elseif dx < -10800 then
      dx += 21600
    end

    local dist = sqrt(dx * dx + dy * dy)

    -- check if arrived (only if moving)
    if dist < 5 and sub.speed > 0 then
      -- advance to next waypoint
      active_waypoint_index += 1
      if active_waypoint_index > #waypoints then
        -- reached final waypoint, stop
        active_waypoint_index = 0
        sub.speed = 0
      end
    else
      -- calculate desired heading to waypoint
      -- use same bearing calculation as display
      -- negate dy because world Y+ = south, add 180 to correct offset
      local desired_heading = calculate_bearing(sub.x, sub.y, target_wpt.x, target_wpt.y)

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
  local dy = sin(angle) * speed_scale  -- positive sin; world Y+ = south

  -- update submarine position
  sub.x += dx
  sub.y += dy

  -- apply world wrapping
  sub.x = wrap_longitude(sub.x)
  sub.y = clamp_latitude(sub.y)
end

function update_sample_collection()
  -- check if near any uncollected sample sites
  for site in all(sample_sites) do
    if not site.collected then
      local dx = site.x - sub.x
      local dy = site.y - sub.y

      -- handle longitude wrapping for distance calculation
      if dx > 10800 then
        dx -= 21600
      elseif dx < -10800 then
        dx += 21600
      end

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
    left_big = {normal=21, selected=21, active=17},
    right_big = {normal=23, selected=23, active=19}
  }

  -- get sprite number from map
  local sprite_num = sprite_map[type][state]

  -- check if this is a big button
  if type == "left_big" or type == "right_big" then
    -- draw two 8x8 sprites side by side for 16x8 button
    spr(sprite_num, x, y)
    spr(sprite_num + 1, x + 8, y)

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

function wrap_longitude(x)
  -- wrap longitude coordinate at world boundaries
  -- longitude wraps continuously: -10800 to +10800 (±180°)
  while x > 10800 do
    x -= 21600
  end
  while x < -10800 do
    x += 21600
  end
  return x
end

function clamp_latitude(y)
  -- clamp latitude to world boundaries
  -- latitude clamps at poles: -5400 to +5400 (±90°)
  if y > 5400 then y = 5400 end
  if y < -5400 then y = -5400 end
  return y
end

function world_to_degrees(world_x, world_y)
  -- convert world coordinates to degrees lat/lon
  -- world: x=-1000 to +1000, y=-1000 to +1000
  -- output: longitude 0-360° (0°=prime meridian, 180°=antimeridian)
  --         latitude 0-180° (0°=south pole, 90°=equator, 180°=north pole)

  -- longitude: map -1000..+1000 to 0..360
  -- -1000 = 180°W (180°), 0 = 0°, +1000 = 180°E (180°)
  local lon_deg = (world_x + 1000) * 360 / 2000

  -- latitude: map -1000..+1000 to 0..180
  -- -1000 = 0° (90°S), 0 = 90° (equator), +1000 = 180° (90°N)
  local lat_deg = (world_y + 1000) * 180 / 2000

  return lon_deg, lat_deg
end

function format_position(world_x, world_y)
  -- format position as "DDDW DDN" or "DDDE DDS"
  -- returns string like "045w 23n" or "120e 67s"
  -- scale: 1 world unit = 1 minute, 60 units = 1 degree

  -- longitude: -10800 to +10800 maps to 180W to 180E
  -- convert minutes to degrees: world_x / 60
  local lon_val = abs(world_x) / 60
  local lon_dir = world_x >= 0 and "e" or "w"

  -- latitude: -5400 to +5400 maps to 90S to 90N
  -- convert minutes to degrees: world_y / 60
  local lat_val = abs(world_y) / 60
  local lat_dir = world_y >= 0 and "n" or "s"

  return pad_zeros(flr(lon_val), 3) .. lon_dir .. " " .. pad_zeros(flr(lat_val), 2) .. lat_dir
end

function world_to_screen(world_x, world_y)
  -- submarine is fixed at screen position (47, 64)
  -- world scrolls around submarine
  -- world: x=longitude (+ east, - west), y=latitude (+ north, - south)
  -- screen: y increases downward, so flip y axis for latitude

  -- calculate offset from submarine in world units
  local dx = world_x - sub.x
  local dy = world_y - sub.y

  -- handle longitude wrapping (shortest distance around the world)
  -- if the distance is > 10800 units, the object is closer going the other way
  if dx > 10800 then
    dx -= 21600
  elseif dx < -10800 then
    dx += 21600
  end

  -- convert to screen pixels using zoom
  -- at zoom=1.0: 1 world unit (1 minute) = 1 pixel
  -- scale = zoom (1.0 = 1 pixel per minute)
  local screen_x = 47 + dx * zoom
  local screen_y = 64 - dy * zoom  -- negative because screen Y is inverted

  return screen_x, screen_y
end

function screen_to_world(screen_x, screen_y)
  -- inverse of world_to_screen
  -- convert screen position to world coordinates using zoom
  -- at zoom=1.0: 1 pixel = 1 world unit (1 minute)
  local world_x = sub.x + (screen_x - 47) / zoom
  local world_y = sub.y - (screen_y - 64) / zoom  -- negative for Y inversion
  return world_x, world_y
end

function calculate_bearing(x1, y1, x2, y2)
  -- calculate bearing from point 1 to point 2
  -- returns 0=north, 90=east, 180=south, 270=west
  local dx = x2 - x1
  local dy = y2 - y1

  -- handle longitude wrapping (take shortest path)
  if dx > 10800 then
    dx -= 21600
  elseif dx < -10800 then
    dx += 21600
  end

  local angle = atan2(-dy, dx)  -- negate dy because world Y+ = south
  local bearing = angle * 360 + 180  -- atan2 returns angle from east, convert to bearing from north

  -- normalize to 0-360
  while bearing < 0 do bearing += 360 end
  while bearing >= 360 do bearing -= 360 end

  return bearing
end

function draw_waypoint_info()
  -- display first 3 waypoints with bearing and distance on right side
  local y = 33
  local prev_x, prev_y = sub.x, sub.y

  for i=1,min(3, #waypoints) do
    local wpt = waypoints[i]
    local dx = wpt.x - prev_x
    local dy = wpt.y - prev_y

    -- handle longitude wrapping for distance calculation
    if dx > 10800 then
      dx -= 21600
    elseif dx < -10800 then
      dx += 21600
    end

    local dist = flr(sqrt(dx * dx + dy * dy))
    local brg = flr(calculate_bearing(prev_x, prev_y, wpt.x, wpt.y))

    print("wpt " .. i, 102, y, 12)
    print(pad_zeros(brg, 3) .. "/" .. dist, 102, y+7, 7)

    prev_x, prev_y = wpt.x, wpt.y
    y += 14
  end
end

function draw_corner_mask()
  -- fill triangular corner mask
  -- covers area above diagonal from (0,32) to (32,0)
  for y=0,31 do
    line(0, y, 32-y, y, 1)
  end
end

function draw_dashed_line(x1, y1, x2, y2, color)
  -- draw a dashed line from (x1,y1) to (x2,y2)
  local dx = x2 - x1
  local dy = y2 - y1
  local dist = sqrt(dx * dx + dy * dy)
  local steps = dist / 2  -- dash every 2 pixels

  for i=0,steps do
    if i % 2 == 0 then  -- draw every other segment
      local t1 = i / steps
      local t2 = min((i + 1) / steps, 1)
      local sx1 = x1 + dx * t1
      local sy1 = y1 + dy * t1
      local sx2 = x1 + dx * t2
      local sy2 = y1 + dy * t2
      line(sx1, sy1, sx2, sy2, color)
    end
  end
end

function draw_rotated_sub(x, y, heading)
  -- draw submarine triangle pointing in direction of heading
  -- heading: 0=north, 90=east, 180=south, 270=west
  -- pico-8 screen: Y increases downward, so north is UP (negative Y)
  -- convert heading to pico-8 angle (0.0-1.0)
  -- subtract 90 to convert from north=0 to east=0, then flip Y by negating sin
  local angle = (heading - 90) / 360

  -- define triangle points relative to center
  -- nose points forward, base is stern
  local nose_dist = 4
  local base_dist = 3
  local base_width = 2

  -- calculate nose point (forward)
  -- negate sin to flip Y axis so north=up on screen
  local nose_x = x + cos(angle) * nose_dist
  local nose_y = y - sin(angle) * nose_dist

  -- calculate base points (stern, perpendicular to heading)
  local perp_angle = angle + 0.25  -- perpendicular angle
  local left_x = x - cos(angle) * base_dist + cos(perp_angle) * base_width
  local left_y = y - (- sin(angle) * base_dist + sin(perp_angle) * base_width)
  local right_x = x - cos(angle) * base_dist - cos(perp_angle) * base_width
  local right_y = y - (- sin(angle) * base_dist - sin(perp_angle) * base_width)

  -- draw triangle: left side, right side, base
  line(nose_x, nose_y, left_x, left_y, 7)   -- left side
  line(nose_x, nose_y, right_x, right_y, 7) -- right side 
  line(left_x, left_y, right_x, right_y, 7)  -- base
end

-- =====================================================================
-->8
-- === draw loop (30fps) ===
-- =====================================================================
function _draw()
  cls()
  draw_dev_grid()

  -- draw current station
  if station == "communications" then
    draw_communications()
  elseif station == "sensors" then
    draw_sensors()
  elseif station == "bridge" then
    draw_bridge()
  elseif station == "helm" then
    draw_helm()
  elseif station == "engineering" then
    draw_engineering()
  elseif station == "science" then
    draw_science()
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
function draw_communications()
  -- placeholder for communications station
  print(station, 101, 2, 7)
  print("communications", 32, 48, 7)
  print("placeholder", 40, 56, 6)
  draw_ui_buttons()
end

function draw_sensors()
  -- placeholder for sensors station
  print(station, 101, 2, 7)
  print("sensors", 40, 48, 7)
  print("placeholder", 40, 56, 6)
  draw_ui_buttons()
end

function draw_bridge()

  -- right side info bar
  print(station, 101, 2, 7) -- station title
  draw_waypoint_info()

  -- bottom info bar
  print("navigation positionlog", 1, 98, 12) -- info bar title
  print("mission time: ", 1, 104, 12)
  print(current_day .. " " .. pad_zeros(current_hour, 2) .. ":" .. pad_zeros(current_minute, 2), 53, 104, 6) -- mission time label
  print("currpos: " .. format_position(sub.x, sub.y), 1, 110, 6) -- current position label
  print("destpos: ", 1, 116, 12)
  if active_waypoint_index > 0 and active_waypoint_index <= #waypoints then
    local dest = waypoints[active_waypoint_index]
    print(format_position(dest.x, dest.y), 37, 116, 6) -- destination position label
  else
    print(" - - - -", 37, 116, 6)
  end

  -- draw grid lines at 1-degree increments
  -- 1 degree = 60 world units (1 world unit = 1 minute)
  -- at zoom=1.0: grid lines are 60 pixels apart
  local grid_spacing = 60  -- 1 degree in world units (60 minutes)

  -- draw vertical lines (longitude)
  for i = -3, 3 do
    local x = 47 + (i * grid_spacing - (sub.x % grid_spacing)) * zoom
    if x >= 0 and x <= map_size then
      line(x, 0, x, map_size, 1)
    end
  end

  -- draw horizontal lines (latitude)
  for i = -3, 3 do
    local y = 64 - (i * grid_spacing - (sub.y % grid_spacing)) * zoom
    if y >= 0 and y <= map_size then
      line(0, y, map_size, y, 1)
    end
  end

  -- draw port at (100,0) - moved right to see ownship better
  local port_x, port_y = world_to_screen(100, 0)
  spr(33, port_x-4, port_y-4) -- subtract 4 to center


  -- draw sample sites
  for site in all(sample_sites) do
    if not site.collected then
      local sx, sy = world_to_screen(site.x, site.y)
      spr(35, sx-4, sy-4) -- subtract 4 to center
    end
  end

  -- draw waypoint route lines and markers
  if #waypoints > 0 then
    -- draw dashed line from ownship to first waypoint
    local wx1, wy1 = world_to_screen(waypoints[1].x, waypoints[1].y)
    draw_dashed_line(47, 64, wx1, wy1, 10)  -- yellow dashed line

    -- draw lines between waypoints
    for i=1,#waypoints-1 do
      local wx1, wy1 = world_to_screen(waypoints[i].x, waypoints[i].y)
      local wx2, wy2 = world_to_screen(waypoints[i+1].x, waypoints[i+1].y)
      draw_dashed_line(wx1, wy1, wx2, wy2, 9)
    end

    -- draw waypoint markers
    for i=1,#waypoints do
      local wx, wy = world_to_screen(waypoints[i].x, waypoints[i].y)
      -- highlight active waypoint
      local color = (i == active_waypoint_index) and 11 or 10
      circ(wx, wy, 2, color)
      print(i, wx-1, wy-2, color)
    end
  end

  -- draw cursor (only when cursor dpad is active)
  if input_mode == "dpad_active" then
    local btn = ui_buttons[selected_button]
    if btn and btn.label == "cursor" then
      local cx, cy = cursor.x, cursor.y
      rect(cx-3, cy-3, cx+3, cy+3, 7)
      line(cx-5, cy, cx-3, cy, 7) -- left
      line(cx+3, cy, cx+5, cy, 7) -- right
      line(cx, cy-5, cx, cy-3, 7) -- up
      line(cx, cy+3, cx, cy+5, 7) -- down

      -- cursor position info (show coordinates in lat/lon format)
      local cursor_world_x, cursor_world_y = screen_to_world(cursor.x, cursor.y)
      print(format_position(cursor_world_x, cursor_world_y), 33, 1, 6)
    end
  end

  -- draw submarine (fixed at screen position)
  draw_rotated_sub(47, 64, sub.heading)

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

  if active_waypoint_index > 0 then
    print("navigating...", 33, 1, 11)
  end
end

function draw_helm()
  print("helm controls", 32, 12, 7)

  local y = 25

  -- display position
  print("position", 10, y, 6)
  print(format_position(sub.x, sub.y), 10, y+6, 7)
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
  print(format_position(sub.x, sub.y), 10, y, 7)
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
00000000000777000007770000777000000770000006660000066600006660000006600000000000000000000000000000000000000000000000000000000000
0000000000770dddddd0077007700dddddd0770000660dddddd0066006600dddddd0660000000000000000000000000000000000000000000000000000000000
000000000770dddddddd00777700dddddddd07700660dddddddd00666600dddddddd066000000000000000000000000000000000000000000000000000000000
00000000770dddddddddd077770dddddddddd077660dddddddddd066660dddddddddd06600000000000000000000000000000000000000000000000000000000
00000000770dddddddddd077770dddddddddd077660dddddddddd066660dddddddddd06600000000000000000000000000000000000000000000000000000000
000000000770dddddddd00777700dddddddd07700660dddddddd00666600dddddddd066000000000000000000000000000000000000000000000000000000000
0000000000770dddddd0077007700dddddd0770000660dddddd0066006600dddddd0660000000000000000000000000000000000000000000000000000000000
00000000000777000007770000777000000770000006660000066600006660000006600000000000000000000000000000000000000000000000000000000000
0000000000066600000000000000dd000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000666666600000000006666600000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000606060000000000666666000b300b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000006000000000006560ddd000b000330eeee00e00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060060060000000066600d00b030b000eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066060660000000006600000b000b0b0e000ee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000666666600000000506ddddd33b030b000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000666000000000005555550003000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
