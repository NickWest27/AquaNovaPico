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


-- === player submarine ===
sub = {
  lon = -70.67, -- longitude in decimal degrees (-180 to +180)
  lat = 41.52, -- latitude in decimal degrees (-90 to +90)
  heading = 200, -- degrees 1-360 degrees True North
  desired_heading = 200, -- target heading for manual helm control
  speed = 0, -- knots 0-160
  acc = 5,
  max_speed = 160,
  depth = 0, -- meters 0-12000
  dive_acc = 100, -- m/s
  max_depth = 12000,
  docked = {
    status = true, -- docked at port or not
    name = "woods hole", -- name of current port
    can_dock = false -- can only dock after leaving port (>1 minute away)
  }
}

-- speed boost multiplier (1x = realistic, 10x = faster gameplay)
speed_boost = 10

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

-- port locations (decimal degrees)
ports = {
  {name="woods hole", lon=-70.67, lat=41.52}  -- Woods Hole
}

-- vessels
vessels = {
  {lon=-70.0, lat=40.1, type="cargo", ident="neutral", hdg=180, spd=10, depth=0, health=100}  -- sample cargo ship
}

-- marine life
marine_life = {
  {lon=-70.1, lat=40.1, type="whale", ident="friendly", hdg=90, spd=5, depth=0, health=100}  -- sample whale
}

--list of task types
task={
	{type="area", prfx = {"procede to ", "patrol at ", "conduct a scan at ", "search area at "}},
	{type="point",prfx = {"proceed to ", "take a sample at ", "rescue survivors at "}},
	{type="target"}
}

-- locations that missions can reference
locations = {
  {name = "area of opperations", lon="71.80w", lat="40.00n", type="area"},
  {name = "fishing grounds", lon="69.50w", lat="41.00n", type="area"},
  {name = "sub sea colonie", lon="72.00w", lat="39.55n", type="point"},
  {name = "deep sea mining colonie", lon="68.52w", lat="40.54n", type="point"},
  {name = "random", lon=flr(rnd(10)-60), lat=flr(rnd(10)-10), type="area"}
}

-- mission system. Maybe in future I will write a briefing and have a function scan it for key words
  -- to generate a task list. eg, if area is mentioned, the player has to get within 80nm of the next
  -- lon/lat mentioned, if point is mentioned, the player must get within 6nm of the next lon/lat.
  -- if speed/depth/heading is mentioned, the player must set those values accordingly.
  -- if "then" the tasks are sequential, if "and" they can be done in any order, etc.
  -- change lon/lat from readable format to decimal degrees for calculations.
missions ={
  {msg="proceed to the "..locations[1].name.." at "..locations[1].lon ..", "..locations[1].lat,
    tasks = {{}},
    completed = false,
    transmitted = false
  }
}


-- sample sites (decimal degrees)
sample_sites = {
  {name="???",
    type="???", -- Biological/Mineral/Energy/Artifact
    properties = {},  -- Thermal/Chemical/Radiation/Magnetic (revealed by analysis)
    lon=-69.9, 
    lat=40.7, 
    rarity = 2,  -- 1-4 (affects research value)
    collected=false,
    anyalysed=false
  },
  {lon=-6.67, lat=3.33, collected=false},  
  {lon=5.0, lat=-8.33, collected=false}
}

-- sample collection
samples_collected = 0
collection_range = 5  -- units within which to collect
sel_smp=0 col_smp={} -- selected sample, collected samples list
ana_st="idle" ana_md="manual" tune=50 apr=0 atm=0 -- analysis state/mode, tuning, progress, timer

-- waypoint system
-- waypoint 0 = ownship present position (implicit)
-- waypoint 1, 2, 3... = user-defined waypoints
waypoints = {}
active_waypoint_index = 0  -- 0 = no active route, 1+ = navigating to waypoint N
waypoint_display_info = {}  -- pre-calculated bearing/distance for display
autopilot = false  -- autopilot heading control (can be toggled on/off)

-- notification system
notification_msg = ""
notification_timer = 0

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
  -- start at port (sub always starts docked at woods hole)
  setup_port_buttons()
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
  update_docking()
  update_sample_collection()
  update_waypoint_info()
  update_notifications()
  if station=="science" and ana_st=="auto" then atm+=1 if atm>=150 then fin_ana() else apr=(atm/150)*100 end end
end

function update_notifications()
  -- decrease notification timer
  if notification_timer > 0 then
    notification_timer -= 1
  end
end

function show_notification(msg)
  notification_msg = msg
  notification_timer = 90  -- show for 3 seconds (90 frames at 30fps)
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
        autopilot = true
        -- sync desired_heading with waypoint bearing to prevent jump when autopilot disables
        sub.desired_heading = calculate_bearing(sub.lon, sub.lat, world_lon, world_lat)
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

  -- autopilot toggle button (aligned with autopilot label)
  button("action", 10, 38, function()
    -- toggle autopilot on/off
    autopilot = not autopilot
    -- if enabling autopilot, check if valid waypoint exists
    if autopilot then
      if #waypoints == 0 or active_waypoint_index == 0 then
        -- no waypoints or route completed, can't enable autopilot
        autopilot = false
      else
        -- sync desired_heading with current waypoint bearing
        local target_wpt = waypoints[active_waypoint_index]
        sub.desired_heading = calculate_bearing(sub.lon, sub.lat, target_wpt.lon, target_wpt.lat)
      end
    else
      -- sync desired_heading to current heading when disabling autopilot
      -- this prevents sudden turns when switching to manual control
      sub.desired_heading = sub.heading
    end
  end)

  -- heading/depth dpad (left/right to adjust heading, up/down adjust depth)
  dpad(23, 67, {
    label = "heading",
    left = function()
      sub.desired_heading -= 15
      if sub.desired_heading < 0 then sub.desired_heading += 360 end
      autopilot = false  -- manual heading change disables autopilot
    end,
    right = function()
      sub.desired_heading += 15
      if sub.desired_heading >= 360 then sub.desired_heading -= 360 end
      autopilot = false  -- manual heading change disables autopilot
    end,
    up = function()
      sub.depth -= 50
      if sub.depth < 0 then sub.depth = 0 end
    end,
    down = function()
      sub.depth += 50
      if sub.depth > 12000 then sub.depth = 12000 end
    end
  })

  -- speed up/down buttons (aligned with speed label)
  -- NOTE: Speed changes should NOT disable autopilot
  button("up", 96, 58, function()
    sub.speed += 10
    if sub.speed > 160 then sub.speed = 160 end
    -- autopilot remains active when changing speed
  end)
  button("down", 96, 68, function()
    sub.speed -= 10
    if sub.speed < 0 then sub.speed = 0 end
    -- autopilot remains active when changing speed
  end)
end

function setup_engineering_buttons()
  button("left_big", 102, 12, cycle_station_backward, "HL")
  button("right_big", 102, 21, cycle_station_forward, "SC")
end

function setup_science_buttons()
  button("left_big", 102, 12, cycle_station_backward, "EN")
  button("right_big", 102, 21, cycle_station_forward, "QT")
  button("action", 2, 75, do_col)
  button("up", 2, 88, do_prv)
  button("down", 12, 88, do_nxt)
  button("action", 2, 102, do_tog)
  dpad(68, 85, {label="tune",left=function() do_tun(-2) end,right=function() do_tun(2) end,up=function() do_tun(10) end,down=function() do_tun(-10) end,action=do_ana})
end

function setup_quarters_buttons()
  button("left_big", 102, 12, cycle_station_backward, "SC")
  button("right_big", 102, 21, cycle_station_forward, "CM")
end

function setup_port_buttons()
  -- port buttons use simple_action type (rect-based, not sprite-based)
  -- coordinates offset by menu position (x=10, y=10)
  button("simple_action", 20, 70, buy_supplies, "buy supplies")  -- x+10, y+60
  button("simple_action", 62, 70, buy_food, "buy food")  -- x+52, y+60
  button("simple_action", 43, 98, leave_port, "leave port")  -- x+33, y+88
end

function buy_supplies()
  local cost = 50
  if resources.money >= cost then
    resources.money -= cost
    resources.supplies += 10
  end
end

function buy_food()
  local cost = 30
  if resources.money >= cost then
    resources.money -= cost
    resources.food += 10
  end
end

function leave_port()
  sub.docked.status = false
  sub.docked.can_dock = false
  station = "bridge"
  setup_station_buttons()
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
  -- determine target heading based on autopilot or manual control
  local target_heading = sub.desired_heading  -- default to manual helm heading

  -- auto-navigate to waypoint if active and autopilot enabled
  if active_waypoint_index > 0 and active_waypoint_index <= #waypoints and autopilot then
    local target_wpt = waypoints[active_waypoint_index]
    local dist = calculate_distance(sub.lon, sub.lat, target_wpt.lon, target_wpt.lat)

    -- check if arrived (only if moving)
    if dist < 5 and sub.speed > 0 then
      -- advance to next waypoint
      active_waypoint_index += 1
      if active_waypoint_index > #waypoints then
        -- reached final waypoint, stop and clear waypoints
        show_notification("destination reached")
        active_waypoint_index = 0
        autopilot = false
        sub.speed = 0
        waypoints = {}  -- clear waypoint list
        waypoint_display_info = {}  -- clear display info
      else
        -- reached intermediate waypoint
        show_notification("waypoint " .. (active_waypoint_index - 1) .. " reached")
      end
    else
      -- calculate desired heading to waypoint
      target_heading = calculate_bearing(sub.lon, sub.lat, target_wpt.lon, target_wpt.lat)
    end
  end

  -- gradually adjust heading toward target (autopilot or manual)
  -- apply turn rate limiting (5 degrees per second max)
  local heading_diff = target_heading - sub.heading
  -- normalize to -180 to 180
  if heading_diff > 180 then heading_diff -= 360 end
  if heading_diff < -180 then heading_diff += 360 end

  -- adjust heading (5 degrees per second max turn rate)
  -- at 30fps: 5/30 = 0.167 degrees per frame
  local turn_rate = 5 / 30
  if abs(heading_diff) > turn_rate then
    if heading_diff > 0 then
      sub.heading += turn_rate
    else
      sub.heading -= turn_rate
    end
  else
    sub.heading = target_heading
  end

  -- wrap heading
  if sub.heading >= 360 then sub.heading -= 360 end
  if sub.heading < 0 then sub.heading += 360 end

  -- convert heading (0-360 degrees) to pico-8 angle (0.0-1.0)
  -- heading: 0=north, 90=east, 180=south, 270=west
  -- pico-8: 0=east, 0.25=south, 0.5=west, 0.75=north
  local angle = (sub.heading - 90) / 360

  -- calculate velocity based on heading and speed
  -- speed in knots with boost multiplier
  -- realistic: 1 knot = 1 nautical mile/hour
  -- 1 nautical mile = 1/60 degree of latitude
  -- 1 knot = (1/60 degree)/hour = (1/60)/3600 degrees/second
  -- at 30fps: 1 knot = (1/60)/3600/30 degree/frame = 1/6480000 degree/frame
  -- apply speed_boost multiplier for playable gameplay
  local speed_scale = (sub.speed * speed_boost) / 6480000  -- degrees per frame

  -- IMPORTANT: Both cos and sin must be negated to match world coordinate system
  -- World coords: +lon=east, +lat=north (standard geographic)
  -- PICO-8 angle 0=east, but cos(0)=+1 points right on screen, which is WEST in world
  -- PICO-8 angle 0.75=north, but -sin(0.75)=-1 points up on screen, which is NORTH in world
  -- Therefore: negate both to convert from PICO-8 screen space to world coordinates
  local dx = -cos(angle) * speed_scale  -- negate: PICO-8 +x (right) = world -lon (west)
  local dy = -sin(angle) * speed_scale  -- negate: PICO-8 -y (up) = world +lat (north)

  -- update submarine position
  sub.lon += dx
  sub.lat += dy

  -- apply world wrapping
  sub.lon = wrap_longitude(sub.lon)
  sub.lat = clamp_latitude(sub.lat)
end

function update_docking()
  -- check if near any port for docking/undocking
  for port in all(ports) do
    local dist = calculate_distance(sub.lon, sub.lat, port.lon, port.lat)

    -- check if far enough to enable docking (must leave docking range first)
    if dist > 0.1 then  -- 0.1 degrees = ~6 nautical miles
      sub.docked.can_dock = true
    end

    -- auto-dock if within range, can dock, and not already docked
    if dist < 0.05 and sub.docked.can_dock and not sub.docked.status then  -- 0.05 degrees = ~3 nautical miles
      sub.docked.status = true
      sub.docked.name = port.name
      sub.speed = 0
      sub.depth = 0
      sub.docked.can_dock = false  -- reset can_dock flag when docking
      setup_port_buttons()

      -- reset mission time on docking
      m_time = 0
      m_day = 0
    end
  end
end


function update_sample_collection()
  -- manual collection only, no auto-collect
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
    left_big = {normal=21, selected=17, active=17},
    right_big = {normal=23, selected=19, active=19}
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

-- science functions
function gen_spec(s) s.sp={} s.tf=20+rnd(60) for i=1,40 do s.sp[i]=20+rnd(20)+(i==flr(s.tf/2.5)+1 and 60 or 0) end end
function do_col() for i,s in pairs(sample_sites) do if not s.collected and calculate_distance(sub.lon,sub.lat,s.lon,s.lat)<collection_range then s.collected=true samples_collected+=1 add(col_smp,i) gen_spec(s) sel_smp=i resources.money+=50 return end end end
function do_prv() if #col_smp==0 then return end for i,v in pairs(col_smp) do if v==sel_smp then sel_smp=col_smp[i==1 and #col_smp or i-1] ana_st="idle" atm=0 apr=0 tune=50 return end end end
function do_nxt() if #col_smp==0 then return end for i,v in pairs(col_smp) do if v==sel_smp then sel_smp=col_smp[i==#col_smp and 1 or i+1] ana_st="idle" atm=0 apr=0 tune=50 return end end end
function do_tog() if ana_md=="manual" then ana_md="auto" ana_st="auto" atm=0 else ana_md="manual" ana_st="idle" atm=0 apr=0 end end
function do_tun(d) if ana_st=="auto" then return end tune=mid(0,tune+d,100) if ana_st=="idle" then ana_st="tune" end end
function do_ana() if sel_smp==0 or ana_st=="auto" then return end local s=sample_sites[sel_smp] if s.anyalysed then return end if abs(tune-s.tf)<=5 then fin_ana() end end
function fin_ana() if sel_smp==0 then return end local s=sample_sites[sel_smp] s.anyalysed=true ana_st="done" s.type=({"bio","min","nrg","art"})[flr(rnd(4))+1] s.name=s.type.." #"..sel_smp resources.money+=200 resources.reputation+=1 end
function chk_col() for i,s in pairs(sample_sites) do if not s.collected and calculate_distance(sub.lon,sub.lat,s.lon,s.lat)<collection_range then return true end end return false end

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

  -- draw port screen if docked, otherwise normal station
  if sub.docked.status then
    draw_port()
  else
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

function draw_port()
  -- draw basic port background
  rectfill(0, 0, 127, 127, 12) -- sky
  rectfill(0, 64, 127, 95, 3) -- land
  rectfill(0, 96, 127, 127, 1) -- water

  -- draw port menu
  local x = 10
  local y = 10
  rect(x, y, x+97, y+97, 12) -- draw menu border
  rectfill(x+1, y+1, x+96, y+96, 1) -- draw menu background

  -- port header
  print("port operations", x+10, y+2, 7)
  print("docked at ".. sub.docked.name, x+10, y+8, 11)

  -- list resources
  print("current supplies:", x+10, y+20, 6)
  print("money: $" .. resources.money, x+10, y+28, 10)
  print("food: " .. resources.food, x+10, y+34, 8)
  print("supplies: " .. resources.supplies, x+10, y+40, 12)
  print("reputation: " .. resources.reputation, x+10, y+46, 14)

  -- draw ui buttons (handled by ui_buttons system)
  draw_ui_buttons()
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

  -- draw port at Woods Hole Woods Hole (-70.666, 41.516)
  local port_x, port_y = world_to_screen(-70.666, 41.516)
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

  -- draw notification if active
  if notification_timer > 0 then
    local msg_width = #notification_msg * 4
    local msg_x = 48 - msg_width / 2
    rectfill(msg_x - 2, 62, msg_x + msg_width + 2, 70, 1)
    rect(msg_x - 2, 62, msg_x + msg_width + 2, 70, 11)
    print(notification_msg, msg_x, 64, 10)
  end
end

function draw_helm()
  print("helm controls", 32, 12, 7)

  local y = 20

  -- display position
  print("position", 10, y, 6)
  print(format_position(sub.lon, sub.lat), 10, y+6, 7)
  y += 14

  -- autopilot status indicator (button at y=38)
  local ap_status = autopilot and "on" or "off"
  local ap_color = autopilot and 11 or 6
  print("autopilot", 10, y, 6)
  print(ap_status, 24, y+6, ap_color)
  y += 15

  -- display current values above controls
  local compass = {"n", "ne", "e", "se", "s", "sw", "w", "nw"}
  local dir_idx = flr((sub.heading + 22.5) / 45) % 8 + 1

  -- heading label (dpad center at x=23, y=67)
  print("heading", 5, y, 6)
  print(flr(sub.heading) .. " " .. compass[dir_idx], 5, y+6, 7)

  -- depth label (dpad center at x=23, y=67, up/down controls depth)
  print("depth", 43, y, 6)
  print(flr(sub.depth) .. " m", 43, y+6, 7)

  -- speed label (buttons at x=96, y=58/68)
  print("speed", 90, y, 6)
  print(flr(sub.speed) .. " kts", 87, y+6, 7)

  -- draw buttons
  draw_ui_buttons()

  -- draw notification if active
  if notification_timer > 0 then
    print(notification_msg, 2, 120, 10)
  end
end

function draw_ui_buttons()
  -- draw all buttons for current screen
  for i, btn in pairs(ui_buttons) do
    local is_selected = (i == selected_button)
    draw_button(btn, is_selected)
  end
end

function draw_science()
  print("science",101,2,7)
  print("material analysis",2,2,7)
  local y,s,sp=14,sel_smp>0 and sample_sites[sel_smp] or nil,nil
  if s then sp=s.sp print("smpld #"..sel_smp,50,2,11) print("mode:"..ana_md,2,8,6) if s.anyalysed then print("type:"..s.type,50,8,10) end end
  y=16 rect(2,y,62,y+54,7)
  if sp then for i=1,#sp do local h=sp[i]/2 rectfill(3+i*1.5,y+54-h,4+i*1.5,y+54,11) end local tx=3+tune*0.6 line(tx,y+1,tx,y+53,10) if s.anyalysed or ana_st=="auto" then local tf=3+s.tf*0.6 line(tf,y+1,tf,y+53,8) end end
  y=18 if s then print("sample "..#col_smp,66,y,6) y+=8 if s.anyalysed then print("analyzed",66,y,10) else print("ready",66,y,7) end end
  y+=8 print(chk_col() and "in range" or "out range",66,y,chk_col() and 11 or 8)
  if ana_st=="auto" then print("auto:"..flr(apr).."%",66,y+8,11) end
  print("collect",10,76,6) print("select",10,89,6) print("mode",10,103,6) print("tune",68,76,6) print("freq:"..flr(tune),68,113,7)
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
