-- Utility functions
-- Common helper functions for the game

local utils = {}

-- Distance calculation
function utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return sqrt(dx * dx + dy * dy)
end

-- Check collision between two rectangles
function utils.check_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

-- Clamp value between min and max
function utils.clamp(val, min_val, max_val)
    return max(min_val, min(max_val, val))
end

-- Linear interpolation
function utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Get random integer
function utils.random_int(min_val, max_val)
    return flr(rnd(max_val - min_val + 1)) + min_val
end

return utils
