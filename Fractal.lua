local Class = require("YfritLib.Class")

local Fractal =
    Class.new(
    {
        outlines = true,
        minOutlineSize = 5,
        colors = {
            [1] = {255, 0, 0},
            [2] = {0, 0, 255},
            [3] = {0, 0, 0}
        }
    },
    function(self, params)
        self.screenWidth = params.screenWidth
        self.screenHeight = params.screenHeight
        self.xSize = params.xSize
        self.ySize = params.ySize
        self.squares = {}
    end
)

function Fractal:setSquare(coordinates, value)
    local x, width = self:calculatePositionAndSize(coordinates[1], self.screenWidth, self.xSize)
    local y, height = self:calculatePositionAndSize(coordinates[2], self.screenHeight, self.ySize)
    table.insert(
        self.squares,
        {
            x = x,
            y = y,
            width = width,
            height = height,
            color = self.colors[value]
        }
    )
end

function Fractal:update(dt)
    -- get mouse position
    local mouseX, mouseY = love.mouse.getPosition()
    print(mouseX, mouseY)
end

function Fractal:draw()
    for _, square in ipairs(self.squares) do
        if square.width >= 1 and square.height >= 1 then
            love.graphics.setColor(square.color)
            love.graphics.rectangle("fill", square.x, square.y, square.width, square.height)
        end
    end

    if self.outlines then
        for _, square in ipairs(self.squares) do
            if square.width >= self.minOutlineSize and square.height >= self.minOutlineSize then
                love.graphics.setColor(255, 255, 255)
                love.graphics.rectangle("line", square.x, square.y, square.width, square.height)
            end
        end
    end
end

function Fractal:calculatePositionAndSize(coordinate, screenSize, internalSize)
    local position = 0

    local size = screenSize

    for _, coordinateValue in ipairs(coordinate) do
        size = size / internalSize
        position = position + coordinateValue * size
    end

    return position, size
end

return Fractal
