-- Player entity module
-- Handles player movement, collision, and actions

local player = {}

function player.create(x, y)
    return {
        x = x,
        y = y,
        width = 8,
        height = 8,
        speed = 2,
        health = 100,
        max_health = 100,
        velocity_x = 0,
        velocity_y = 0
    }
end

function player.update(p)
    -- Handle input
    local dx = 0
    local dy = 0
    
    if btn(0) then dx = -p.speed end
    if btn(1) then dx = p.speed end
    if btn(2) then dy = -p.speed end
    if btn(3) then dy = p.speed end
    
    p.x += dx
    p.y += dy
    
    -- Clamp to bounds
    p.x = mid(0, p.x, 128 - p.width)
    p.y = mid(0, p.y, 128 - p.height)
end

function player.draw(p)
    spr(1, p.x, p.y)
end

function player.take_damage(p, amount)
    p.health = max(0, p.health - amount)
end

function player.heal(p, amount)
    p.health = min(p.max_health, p.health + amount)
end

return player
