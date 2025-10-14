local Class = require("YfritLib.Class")

local Genken =
    Class.new(
    {
        logs = false
    },
    function(self, params)
        self.fractal = params.fractal
    end
)

function Genken:simulate(params)
    -- self:simulateRecursive(params.maxTurns, {}, {}, 0, 0, 0, 0)
    self:exploreNextPlays(params.maxTurns - 1, {}, {}, 0, 0, 0, 0)
end

function Genken:simulateRecursive(remainingTurns, plays1, plays2, points1, points2, generators1, generators2)
    -- simulate last plays
    local lastPlayer1Play = plays1[#plays1]
    local lastPlayer2Play = plays2[#plays2]

    -- scissors (create generator)
    if lastPlayer1Play == 2 then
        generators1 = generators1 + 1
    end
    if lastPlayer2Play == 2 then
        generators2 = generators2 + 1
    end

    local generatedPoints1 = generators1
    local generatedPoints2 = generators2

    -- rock (gain 4 points)
    if lastPlayer1Play == 0 then
        generatedPoints1 = generatedPoints1 + 4
    end
    if lastPlayer2Play == 0 then
        generatedPoints2 = generatedPoints2 + 4
    end

    -- paper (gain 1 point, negate 4 points)
    if lastPlayer1Play == 1 then
        generatedPoints1 = generatedPoints1 + 1
        generatedPoints2 = generatedPoints2 - 4
    end
    if lastPlayer2Play == 1 then
        generatedPoints2 = generatedPoints2 + 1
        generatedPoints1 = generatedPoints1 - 4
    end
    generatedPoints2 = math.max(0, generatedPoints2)
    generatedPoints1 = math.max(0, generatedPoints1)

    -- update points
    points1 = points1 + generatedPoints1
    points2 = points2 + generatedPoints2

    -- if neither player scored, both get a point
    if generatedPoints1 == 0 and generatedPoints2 == 0 then
        points1 = points1 + 1
        points2 = points2 + 1
    end

    -- while both players have 10+ points, decrement both by 10
    while points1 >= 10 and points2 >= 10 do
        points1 = points1 - 10
        points2 = points2 - 10
    end

    -- if one player has 10+ points, they win
    if points1 >= 10 then
        self.fractal:setSquare({plays1, plays2}, 1)
        self:printState(1, plays1, plays2, points1, points2, generators1, generators2)
        return
    elseif points2 >= 10 then
        self.fractal:setSquare({plays1, plays2}, 2)
        self:printState(2, plays1, plays2, points1, points2, generators1, generators2)
        return
    end

    if remainingTurns == 0 then
        self.fractal:setSquare({plays1, plays2}, 3)
        self:printState(3, plays1, plays2, points1, points2, generators1, generators2)
        return
    end

    self:exploreNextPlays(remainingTurns - 1, plays1, plays2, points1, points2, generators1, generators2)
end

function Genken:exploreNextPlays(remainingTurns, plays1, plays2, points1, points2, generators1, generators2)
    for nextPlayer1Play = 0, 2 do
        plays1[#plays1 + 1] = nextPlayer1Play

        for nextPlayer2Play = 0, 2 do
            plays2[#plays2 + 1] = nextPlayer2Play

            self:simulateRecursive(remainingTurns, plays1, plays2, points1, points2, generators1, generators2)

            table.remove(plays2, #plays2)
        end

        table.remove(plays1, #plays1)
    end
end

function Genken:printPlays(player, plays)
    io.write("Player " .. player .. " plays: ")
    for _, play in ipairs(plays) do
        if play == 0 then
            io.write("R") -- Rock
        elseif play == 1 then
            io.write("P") -- Paper
        elseif play == 2 then
            io.write("S") -- Scissors
        end
    end
    print()
end

function Genken:printState(winner, plays1, plays2, points1, points2, generators1, generators2)
    if not self.logs then
        return
    end

    self:printPlays(1, plays1)
    self:printPlays(2, plays2)

    print(string.format("Player 1: %d points, %d generators", points1, generators1))
    print(string.format("Player 2: %d points, %d generators", points2, generators2))

    if winner == 1 then
        print("Player 1 wins.")
    elseif winner == 2 then
        print("Player 2 wins.")
    else
        print("Draw.")
    end

    print()
    print("===========================")
    print()
end

return Genken
