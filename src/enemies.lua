-- Enemy module
-- Handles enemy definitions and behaviors

local enemies = {}

function enemies.create(x, y, type)
    return {
        x = x,
        y = y,
        width = 8,
        height = 8,
        health = 30,
        type = type or "basic",
        speed = 1,
        direction = 1
    }
end

function enemies.update(e)
    -- Simple patrol behavior
    e.x += e.speed * e.direction
    
    -- Turn around at edges
    if e.x < 0 or e.x > 128 then
        e.direction *= -1
    end
end

function enemies.draw(e)
    spr(2, e.x, e.y)
end

function enemies.take_damage(e, amount)
    e.health -= amount
    return e.health <= 0
end

return enemies
