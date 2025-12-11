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
frames = 0 -- frame counter (30fps)
last_second = 0 -- last frame when a second elapsed
m_time = 0 -- mission time in seconds (resets at port)
z_time = 28800 -- zulu time in seconds (starts at 8:00 AM)
m_day = 0 -- mission day counter (0-based)
z_day = 1 -- zulu day counter (1-based)
day = 86400 -- seconds per day constant


-- === submarine ===
sub = {
  lon = 0, -- longitude in minutes (-10800 to +10800)
  lat = 0, -- latitude in minutes (-5400 to +5400)
  heading = 200, -- degrees 1-360 degrees True North
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
-- scale: 1 world unit = 1 decimal degree
world_size = 360.0 -- world is full globe: 360 decimal degrees
map_size = 96 -- map display is 96×96 pixels

-- zoom system: zoom_level index selects from zoom_levels table
-- pixels per degree: higher zoom = closer view
zoom_level = 7 -- default zoom level (1=widest, 9=closest)
zoom_levels = {0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0} -- pixels per degree
zoom = zoom_levels[zoom_level] -- actual zoom multiplier

-- world coordinates (full globe):
-- lon: longitude -180.0 to +180.0 (wraps at boundaries)
-- lat: latitude -90.0 to +90.0 (clamps at poles)
-- zoom effects: level 1 (0.25x) shows 384°, level 7 (16.0x) shows 6°, level 9 (64.0x) shows 1.5°

-- sample sites (decimal degrees)
sample_sites = {
  {lon=8.33, lat=5.0, collected=false},     -- ~8°20'E, 5°N
  {lon=-6.67, lat=3.33, collected=false},   -- ~6°40'W, 3°20'N
  {lon=5.0, lat=-8.33, collected=false}     -- 5°E, ~8°20'S
}

-- sample collection
samples_collected = 0
collection_range = 5  -- units within which to collect

-- waypoint system
-- waypoint 0 = ownship present position (implicit)
-- waypoint 1, 2, 3... = user-defined waypoints
waypoints = {}
active_waypoint_index = 0  -- 0 = no active route, 1+ = navigating to waypoint N
waypoint_display_info = {}  -- pre-calculated bearing/distance for display

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
  setup_station_buttons()
  -- reset game state after game over (keep mission progression, reset everything else)
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
  update_waypoint_info()
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

  -- zoom controls
  button("up", 102, 87, zoom_in, "-")
  button("down", 112, 87, zoom_out, "+")

  dpad(108, 108, {
    label = "cursor",
    left = function()
      move_cursor(-1, 0)  -- move 1 degree west
    end,
    right = function()
      move_cursor(1, 0)  -- move 1 degree east
    end,
    up = function()
      move_cursor(0, 1)  -- move 1 degree north
    end,
    down = function()
      move_cursor(0, -1)  -- move 1 degree south
    end,
    action = function()
      -- convert screen cursor to world waypoint and add to route
      local world_lon, world_lat = screen_to_world(cursor.x, cursor.y)
      add(waypoints, {lon=world_lon, lat=world_lat})

      -- activate navigation if this is first waypoint
      if active_waypoint_index == 0 then
        active_waypoint_index = 1
      end
    end
  })
end

function zoom_in()
  -- increase zoom level (closer view)
  if zoom_level < 9 then
    zoom_level += 1
    zoom = zoom_levels[zoom_level]
  end
end

function zoom_out()
  -- decrease zoom level (wider view)
  if zoom_level > 1 then
    zoom_level -= 1
    zoom = zoom_levels[zoom_level]
  end
end

function move_cursor(dx_degrees, dy_degrees)
  -- move cursor by specified world coordinate offset
  -- automatically handles zoom scaling and screen bounds
  local world_lon, world_lat = screen_to_world(cursor.x, cursor.y)
  world_lon += dx_degrees / zoom
  world_lat += dy_degrees / zoom
  cursor.x, cursor.y = world_to_screen(world_lon, world_lat)
  cursor.x = mid(0, cursor.x, 96)
  cursor.y = mid(0, cursor.y, 96)
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
  frames += 1

  -- check if a full second has elapsed (every 30 frames)
  if frames - last_second >= 30 then
    last_second = frames

    -- increment time by 1 second
    m_time += 1
    z_time += 1

    -- === per-second updates (mission time) ===
    -- add per-second resource changes here
    -- example: resources.battery -= 1

    -- check if mission day rolled over
    if m_time >= day then
      m_time -= day
      m_day += 1

      -- === per-day updates (mission time) ===
      resources.food -= 1
      if resources.food <= 0 then
        resources.food = 0
      end
    end

    -- check if zulu day rolled over
    if z_time >= day * z_day then
      z_day += 1
    end
  end
end

function update_movement()
  -- auto-navigate to waypoint if active
  if active_waypoint_index > 0 and active_waypoint_index <= #waypoints then
    local target_wpt = waypoints[active_waypoint_index]
    local dist = calculate_distance(sub.lon, sub.lat, target_wpt.lon, target_wpt.lat)

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
      local desired_heading = calculate_bearing(sub.lon, sub.lat, target_wpt.lon, target_wpt.lat)

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
        sub.heading = flr(desired_heading)
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
  -- speed in knots, time scale: 1 real second = 1 game minute
  -- 1 knot = 1 nautical mile/hour = 1/60 degree/hour
  -- at 30fps: 1 knot = 1/60/60 degree/frame = 1/1800 degree/frame
  local speed_scale = sub.speed / 1800  -- degrees per frame

  local dx = cos(angle) * speed_scale
  local dy = sin(angle) * speed_scale  -- positive sin; world Y+ = south

  -- update submarine position
  sub.lon += dx
  sub.lat += dy

  -- apply world wrapping
  sub.lon = wrap_longitude(sub.lon)
  sub.lat = clamp_latitude(sub.lat)
end

function update_sample_collection()
  -- check if near any uncollected sample sites
  for site in all(sample_sites) do
    if not site.collected then
      local dist = calculate_distance(sub.lon, sub.lat, site.lon, site.lat)

      if dist < collection_range then
        site.collected = true
        samples_collected += 1
        resources.money += 100  -- reward for sample
      end
    end
  end
end

function update_waypoint_info()
  -- pre-calculate waypoint display info (bearing/distance)
  -- this keeps calculations out of draw loop
  waypoint_display_info = {}
  local prev_lon, prev_lat = sub.lon, sub.lat

  for i=1,min(3, #waypoints) do
    local wpt = waypoints[i]
    local dist = flr(calculate_distance(prev_lon, prev_lat, wpt.lon, wpt.lat))
    local brg = flr(calculate_bearing(prev_lon, prev_lat, wpt.lon, wpt.lat))

    add(waypoint_display_info, {bearing=brg, distance=dist})
    prev_lon, prev_lat = wpt.lon, wpt.lat
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

function wrap_longitude_delta(dx)
  -- wrap longitude difference to shortest path
  -- used for distance/bearing calculations
  if dx > 180.0 then
    dx -= 360.0
  elseif dx < -180.0 then
    dx += 360.0
  end
  return dx
end

function wrap_longitude(lon)
  -- wrap longitude coordinate at world boundaries
  -- longitude wraps continuously: -180.0 to +180.0
  while lon > 180.0 do
    lon -= 360.0
  end
  while lon < -180.0 do
    lon += 360.0
  end
  return lon
end

function clamp_latitude(lat)
  -- clamp latitude to world boundaries
  -- latitude clamps at poles: -90.0 to +90.0
  if lat > 90.0 then lat = 90.0 end
  if lat < -90.0 then lat = -90.0 end
  return lat
end

function calculate_distance(lon1, lat1, lon2, lat2)
  -- calculate distance with longitude wrapping
  local dx = lon2 - lon1
  local dy = lat2 - lat1
  dx = wrap_longitude_delta(dx)
  return sqrt(dx * dx + dy * dy)
end

function degrees_to_minutes(degrees)
  -- convert decimal degrees to whole degrees + minutes
  -- example: 45.5° = 45° 30'
  local deg = flr(abs(degrees))
  local min = flr((abs(degrees) - deg) * 60)
  return deg, min
end

function format_position(world_lon, world_lat)
  -- format position as "DDD°MM'W DD°MM'N" format
  -- returns string like "045°30e 23°15n"
  -- coordinates are already in decimal degrees

  -- convert decimal degrees to degrees + minutes
  local lon_deg, lon_min = degrees_to_minutes(world_lon)
  local lon_dir = world_lon >= 0 and "e" or "w"

  local lat_deg, lat_min = degrees_to_minutes(world_lat)
  local lat_dir = world_lat >= 0 and "n" or "s"

  -- format: "045°30e 23°15n"
  return pad_zeros(lon_deg, 3) .. "\31" .. pad_zeros(lon_min, 2) .. lon_dir .. " " ..
         pad_zeros(lat_deg, 2) .. "\31" .. pad_zeros(lat_min, 2) .. lat_dir
end

function world_to_screen(world_lon, world_lat)
  -- submarine is fixed at screen position (47, 64)
  -- world scrolls around submarine
  -- world: lon=longitude (+ east, - west), lat=latitude (+ north, - south)
  -- screen: y increases downward, so flip y axis for latitude

  -- calculate offset from submarine in world units
  local dx = world_lon - sub.lon
  local dy = world_lat - sub.lat

  -- handle longitude wrapping (shortest distance around the world)
  dx = wrap_longitude_delta(dx)

  -- convert to screen pixels using zoom
  -- at zoom=16.0: 1 world unit (1 degree) = 16 pixels
  -- scale = zoom (pixels per degree)
  local screen_x = 47 + dx * zoom
  local screen_y = 64 - dy * zoom  -- negative because screen Y is inverted

  return screen_x, screen_y
end

function screen_to_world(screen_x, screen_y)
  -- inverse of world_to_screen
  -- convert screen position to world coordinates using zoom
  -- at zoom=16.0: 1 pixel = 0.0625 degrees (1/16 degree)
  local world_lon = sub.lon + (screen_x - 47) / zoom
  local world_lat = sub.lat - (screen_y - 64) / zoom  -- negative for Y inversion
  return world_lon, world_lat
end

function calculate_bearing(lon1, lat1, lon2, lat2)
  -- calculate bearing from point 1 to point 2
  -- returns 0=north, 90=east, 180=south, 270=west
  local dx = lon2 - lon1
  local dy = lat2 - lat1

  -- handle longitude wrapping (take shortest path)
  dx = wrap_longitude_delta(dx)

  local angle = atan2(-dy, dx)  -- negate dy because world Y+ = south
  local bearing = angle * 360 + 180  -- atan2 returns angle from east, convert to bearing from north

  -- normalize to 0-360
  while bearing < 0 do bearing += 360 end
  while bearing >= 360 do bearing -= 360 end

  return bearing
end

function draw_waypoint_info()
  -- display first 3 waypoints with bearing and distance on right side
  -- data pre-calculated in update_waypoint_info()
  local y = 33

  for i=1,#waypoint_display_info do
    local info = waypoint_display_info[i]
    print("wpt " .. i, 102, y, 12)
    print(pad_zeros(info.bearing, 3) .. "/" .. info.distance, 102, y+7, 7)
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

function draw_border_mask()
  -- fill rectangles outside map boundaries to mask overflow
  -- map area is (0,0) to (96,96) with clipped corner

  -- top border (above map, right of clipped corner)
  rectfill(32, -1, 127, -1, 1)

  -- right border (right of map)
  rectfill(97, 0, 127, 127, 1)

  -- bottom border (below map)
  rectfill(0, 97, 127, 127, 1)

  -- left border (left of map)
  rectfill(-1, 0, -1, 127, 1)
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

  -- draw grid lines at 1-degree increments
  -- 1 degree = 1.0 world units (1 world unit = 1 decimal degree)
  -- at zoom=16.0: grid lines are 16 pixels apart
  local grid_spacing = 1.0  -- 1 degree in world units

  -- draw vertical lines (longitude)
  for i = -3, 3 do
    local x = 47 + (i * grid_spacing - (sub.lon % grid_spacing)) * zoom
    line(x, 0, x, map_size, 1)
  end

  -- draw horizontal lines (latitude)
  for i = -3, 3 do
    local y = 64 - (i * grid_spacing - (sub.lat % grid_spacing)) * zoom
    line(0, y, map_size, y, 1)
  end

  -- draw port at (100,0) - moved right to see ownship better
  local port_x, port_y = world_to_screen(100, 0)
  spr(33, port_x-4, port_y-4) -- subtract 4 to center


  -- draw sample sites
  for site in all(sample_sites) do
    if not site.collected then
      local sx, sy = world_to_screen(site.lon, site.lat)
      spr(35, sx-4, sy-4) -- subtract 4 to center
    end
  end

  -- draw waypoint route lines and markers
  if #waypoints > 0 then
    -- draw dashed line from ownship to first waypoint
    local wx1, wy1 = world_to_screen(waypoints[1].lon, waypoints[1].lat)
    draw_dashed_line(47, 64, wx1, wy1, 10)  -- yellow dashed line

    -- draw lines between waypoints
    for i=1,#waypoints-1 do
      local wx1, wy1 = world_to_screen(waypoints[i].lon, waypoints[i].lat)
      local wx2, wy2 = world_to_screen(waypoints[i+1].lon, waypoints[i+1].lat)
      draw_dashed_line(wx1, wy1, wx2, wy2, 9)
    end

    -- draw waypoint markers
    for i=1,#waypoints do
      local wx, wy = world_to_screen(waypoints[i].lon, waypoints[i].lat)
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
      local cursor_world_lon, cursor_world_lat = screen_to_world(cursor.x, cursor.y)
      print(format_position(cursor_world_lon, cursor_world_lat), 33, 1, 6)
    end
  end

  -- draw submarine (fixed at screen position)
  draw_rotated_sub(47, 64, sub.heading)

  -- draw corner mask
  draw_corner_mask()

  -- draw border mask rectangles to hide overflow
  draw_border_mask()

  -- draw map border frame
  line(32, 0, 96, 0, 12) -- top
  line(96, 0, 96, 96, 12) -- right
  line(0, 96, 96, 96, 12) -- bottom
  line(0, 32, 0, 96, 12) -- left
  line(0, 32, 32, 0, 12) -- top left corner

  -- draw submarine status info (top left, on map)
  print("d" .. flr(sub.depth), 1, 1, 7)
  print("h" .. pad_zeros(flr(sub.heading), 3), 1, 7, 7)
  print("s" .. pad_zeros(flr(sub.speed), 3), 1, 13, 7)

  -- navigation status (top center, on map)
  if active_waypoint_index > 0 then
    print("navigating...", 33, 1, 11)
  end

  -- right side info bar (outside map)
  print(station, 101, 2, 7) -- station title
  draw_waypoint_info()

  -- bottom info bar (outside map)
  print("navigation positionlog", 1, 98, 12) -- info bar title
  print("mission time: ", 1, 104, 12)
  local m_hour = flr(m_time / 3600) % 24
  local m_min = flr(m_time / 60) % 60
  print("d" .. m_day .. " " .. pad_zeros(m_hour, 2) .. ":" .. pad_zeros(m_min, 2), 53, 104, 6) -- mission time label
  print("currpos: " .. format_position(sub.lon, sub.lat), 1, 110, 6) -- current position label
  print("destpos: ", 1, 116, 12)
  if active_waypoint_index > 0 and active_waypoint_index <= #waypoints then
    local dest = waypoints[active_waypoint_index]
    print(format_position(dest.lon, dest.lat), 37, 116, 6) -- destination position label
  else
    print(" - - - -", 37, 116, 6)
  end

  -- draw d-pad control on right side (outside map)
  draw_ui_buttons()
end

function draw_helm()
  print("helm controls", 32, 12, 7)

  local y = 25

  -- display position
  print("position", 10, y, 6)
  print(format_position(sub.lon, sub.lat), 10, y+6, 7)
  y += 20

  -- display current values above dpads
  local compass = {"n", "ne", "e", "se", "s", "sw", "w", "nw"}
  local dir_idx = flr((sub.heading + 22.5) / 45) % 8 + 1

  print("heading", 10, y, 6)
  print(flr(sub.heading) .. " " .. compass[dir_idx], 10, y+6, 7)

  print("speed", 60, y, 6)
  print(flr(sub.speed) .. " kts", 60, y+6, 7)

  print("depth", 95, y, 6)
  print(flr(sub.depth) .. " m", 95, y+6, 7)

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

  -- display zulu clock (world time)
  local z_hour = flr(z_time / 3600) % 24
  local z_min = flr(z_time / 60) % 60
  print("zulu clock", 10, y, 6)
  y += 8
  print("day: " .. z_day .. " " .. pad_zeros(z_hour, 2) .. ":" .. pad_zeros(z_min, 2), 10, y, 7)
  y += 15

  -- display position
  print("position", 10, y, 6)
  y += 8
  print(format_position(sub.lon, sub.lat), 10, y, 7)
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
