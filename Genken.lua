local Class = require("YfritLib.Class")
local Table = require("YfritLib.Table")

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
        self.fractal:setSquare({plays1, plays2}, 1, self:getMetadata(plays1, plays2))
        self:printState(1, plays1, plays2, points1, points2, generators1, generators2)
        return true, 1
    elseif points2 >= 10 then
        self.fractal:setSquare({plays1, plays2}, 2, self:getMetadata(plays1, plays2))
        self:printState(2, plays1, plays2, points1, points2, generators1, generators2)
        return true, 2
    end

    if remainingTurns == 0 then
        self.fractal:setSquare({plays1, plays2}, 3, self:getMetadata(plays1, plays2))
        self:printState(3, plays1, plays2, points1, points2, generators1, generators2)
        return false
    end

    return self:exploreNextPlays(remainingTurns - 1, plays1, plays2, points1, points2, generators1, generators2)
end

function Genken:exploreNextPlays(remainingTurns, plays1, plays2, points1, points2, generators1, generators2)
    local results = {}

    -- simulate
    for nextPlayer1Play = 0, 2 do
        plays1[#plays1 + 1] = nextPlayer1Play

        results[nextPlayer1Play] = {}

        for nextPlayer2Play = 0, 2 do
            plays2[#plays2 + 1] = nextPlayer2Play

            local hasWinner, winner = self:simulateRecursive(remainingTurns, plays1, plays2, points1, points2, generators1, generators2)
            results[nextPlayer1Play][nextPlayer2Play] = {
                hasWinner = hasWinner,
                winner = winner
            }

            table.remove(plays2, #plays2)
        end

        table.remove(plays1, #plays1)
    end

    -- if player 1 has a play that wins agains all player 2 possible plays, they win
    for play1 = 0, 2 do
        local hasCounter = false
        for play2 = 0, 2 do
            local result = results[play1][play2]
            if not result.hasWinner or result.winner ~= 1 then
                hasCounter = true
            end
        end

        if not hasCounter then
            self.fractal:setSquare({plays1, plays2}, 1, self:getMetadata(plays1, plays2, true))
            return true, 1
        end
    end

    -- if player 2 has a play that wins agains all player 1 possible plays, they win
    for play2 = 0, 2 do
        local hasCounter = false
        for play1 = 0, 2 do
            local result = results[play1][play2]
            if not result.hasWinner or result.winner ~= 2 then
                hasCounter = true
            end
        end

        if not hasCounter then
            self.fractal:setSquare({plays1, plays2}, 2, self:getMetadata(plays1, plays2, true))
            return true, 2
        end
    end

    return false
end

function Genken:getMetadata(plays1, plays2, indirectVictory)
    return {
        player1Plays = Table.shallowCopy(plays1),
        player2Plays = Table.shallowCopy(plays2),
        indirectVictory = indirectVictory or false
    }
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
