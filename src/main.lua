-- Aqua Nova Main Game File
-- Entry point for the Pico-8 game

-- Game state
function _init()
    -- Initialize game variables
    game_state = "playing" -- "playing", "paused", "game_over", "menu"
    
    -- Player
    player = {
        x = 64,
        y = 64,
        width = 8,
        height = 8,
        speed = 2,
        health = 100
    }
    
    -- Enemies
    enemies = {}
    
    -- World
    camera_x = 0
    camera_y = 0
end

-- Update game logic
function _update()
    if game_state == "playing" then
        update_player()
        update_enemies()
        update_camera()
    end
end

-- Render game
function _draw()
    cls() -- Clear screen
    
    -- Draw background
    palt(0, false)
    palt(15, true)
    
    -- Draw world
    draw_world()
    
    -- Draw entities
    draw_player()
    draw_enemies()
    
    -- Draw UI
    draw_ui()
end

-- Player update
function update_player()
    local dx = 0
    local dy = 0
    
    if btn(0) then dx = -player.speed end
    if btn(1) then dx = player.speed end
    if btn(2) then dy = -player.speed end
    if btn(3) then dy = player.speed end
    
    player.x += dx
    player.y += dy
    
    -- Clamp to screen
    player.x = mid(0, player.x, 128 - player.width)
    player.y = mid(0, player.y, 128 - player.height)
end

-- Enemy update
function update_enemies()
    -- Placeholder for enemy logic
end

-- Camera update
function update_camera()
    camera_x = player.x - 64
    camera_y = player.y - 64
end

-- Draw world
function draw_world()
    -- Placeholder for world drawing
    map(0, 0, 0, 0, 16, 16)
end

-- Draw player
function draw_player()
    spr(1, player.x, player.y)
end

-- Draw enemies
function draw_enemies()
    -- Placeholder for enemy drawing
end

-- Draw UI
function draw_ui()
    -- Draw health
    print("hp: " .. player.health, 2, 2, 7)
end
