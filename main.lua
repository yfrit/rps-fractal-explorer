local Fractal = require("Fractal")
local RockPaperScissors = require("RockPaperScissors")
local ResourceRoyale = require("ResourceRoyale")

local fractal, game

function love.load()
	math.randomseed(os.time())
	love.graphics.setBackgroundColor(127, 127, 127)

	fractal =
		Fractal:new(
		{
			screenWidth = love.graphics.getWidth(),
			screenHeight = love.graphics.getHeight(),
			xSize = 3,
			ySize = 3
		}
	)

	-- game =
	-- 	RockPaperScissors:new(
	-- 	{
	-- 		fractal = fractal
	-- 	}
	-- )
	game =
		ResourceRoyale:new(
		{
			fractal = fractal
		}
	)
	game:simulate(
		{
			maxTurns = 5
		}
	)
end

function love.update(dt)
	fractal:update(dt)
end

function love.draw()
	fractal:draw()
end
