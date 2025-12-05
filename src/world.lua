-- World module
-- Handles level data, tilemap, and world logic

local world = {}

function world.init()
    return {
        width = 256,
        height = 256,
        tilemap = {},
        camera_x = 0,
        camera_y = 0
    }
end

function world.update(w)
    -- Update world state
end

function world.draw(w)
    -- Draw tilemap
    map(0, 0, 0, 0, 16, 16)
end

function world.is_solid(w, x, y)
    -- Check if a position is solid/blocked
    return false -- Placeholder
end

return world
