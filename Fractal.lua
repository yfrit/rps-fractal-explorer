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
        },
        emojis = {
            [0] = "R", -- rock
            [1] = "P", -- paper
            [2] = "S" -- scissors
        }
    },
    function(self, params)
        self.screenWidth = params.screenWidth
        self.screenHeight = params.screenHeight
        self.xSize = params.xSize
        self.ySize = params.ySize
        self.squares = {}
        self.hoveredSquare = nil
    end
)

function Fractal:setSquare(coordinates, value, metadata)
    local x, width = self:calculatePositionAndSize(coordinates[1], self.screenWidth, self.xSize)
    local y, height = self:calculatePositionAndSize(coordinates[2], self.screenHeight, self.ySize)
    table.insert(
        self.squares,
        {
            x = x,
            y = y,
            width = width,
            height = height,
            color = self.colors[value],
            metadata = metadata,
            value = value
        }
    )
end

function Fractal:update(dt)
    -- get mouse position
    local mouseX, mouseY = love.mouse.getPosition()

    -- check if it's inside any square
    self.hoveredSquare = nil
    for square in self:iterateSquares() do
        if mouseX >= square.x and mouseX <= square.x + square.width and mouseY >= square.y and mouseY <= square.y + square.height then
            self.hoveredSquare = square
        end
    end
end

function Fractal:draw()
    for square in self:iterateSquares() do
        if square.width >= 1 and square.height >= 1 then
            love.graphics.setColor(square.color)
            love.graphics.rectangle("fill", square.x, square.y, square.width, square.height)
        end

        if self.outlines then
            if square.width >= self.minOutlineSize and square.height >= self.minOutlineSize then
                love.graphics.setColor(255, 255, 255)
                love.graphics.rectangle("line", square.x, square.y, square.width, square.height)
            end
        end
    end

    if self.hoveredSquare then
        -- show tooltip
        local mouseX, mouseY = love.mouse.getPosition()
        love.graphics.setColor(0, 0, 0, 200)
        love.graphics.rectangle("fill", mouseX, mouseY, 100, 40)

        love.graphics.setColor(255, 255, 255)
        local player1Text = string.format("1: %s", self:formatPlays(self.hoveredSquare.metadata.player1Plays))
        local player2Text = string.format("2: %s", self:formatPlays(self.hoveredSquare.metadata.player2Plays))
        if self.hoveredSquare.value == 1 then
            player1Text = "(W) " .. player1Text
        elseif self.hoveredSquare.value == 2 then
            player2Text = "(W) " .. player2Text
        end

        local text = player1Text .. "\n" .. player2Text
        love.graphics.printf(text, mouseX - 5, mouseY + 5, 100, "right")
    end
end

function Fractal:formatPlays(plays)
    local formattedPlays = {}
    for _, play in ipairs(plays) do
        table.insert(formattedPlays, self.emojis[play])
    end
    return table.concat(formattedPlays, "")
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

function Fractal:iterateSquares()
    local index = 0
    local squares = self.squares
    local length = #squares
    local includeIndirect = love.keyboard.isDown(" ")

    return function()
        repeat
            index = index + 1
        until index > length or includeIndirect or not squares[index].metadata.indirectVictory

        if index <= length then
            return squares[index]
        end
    end
end

return Fractal
