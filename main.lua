-- Each experience module returns a table of LÖVE callbacks { load, update, draw }.
-- Swap the active experience by changing which one is required here. Modules
-- without graphics (e.g. the deck runners) simply omit update/draw.
-- local experience = require("FractalExplorer")
-- local experience = require("DeckBattleRunner")
local experience = require("DominantDeckRunner")

function love.load()
    experience.load()
end

function love.update(dt)
    if experience.update then
        experience.update(dt)
    end
end

function love.draw()
    if experience.draw then
        experience.draw()
    end
end
