local Fractal = require("Fractal")
local RockPaperScissors = require("RockPaperScissors")
local Genken = require("Genken")

local fractal, game

function love.load()
	print("Hover with mouse to see the plays from each player.")
	print("Hold Space to show indirect victories/defeats.")

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
		Genken:new(
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
