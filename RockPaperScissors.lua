local Class = require("YfritLib.Class")
local Table = require("YfritLib.Table")

local RockPaperScissors =
    Class.new(
    {},
    function(self, params)
        self.fractal = params.fractal
    end
)

function RockPaperScissors:simulate(params)
    self:simulateRecursive(params.maxTurns, {}, {})
end

function RockPaperScissors:simulateRecursive(remainingTurns, player1Plays, player2Plays)
    if self:checkCurrentState(player1Plays, player2Plays) then
        return -- if we reached a victory/defeat condition, stop exploring
    end

    if remainingTurns == 0 then
        -- a "draw" (kinda, because we reached max depth)
        self.fractal:setSquare(
            {player1Plays, player2Plays},
            3,
            {
                player1Plays = Table.shallowCopy(player1Plays),
                player2Plays = Table.shallowCopy(player2Plays)
            }
        )
        return
    end

    self:exploreNextPlays(remainingTurns - 1, player1Plays, player2Plays)
end

function RockPaperScissors:checkCurrentState(player1Plays, player2Plays)
    -- check current state, if it's a victory/defeat condition then set fractal square and stop
    local lastPlayer1Play = player1Plays[#player1Plays]
    local lastPlayer2Play = player2Plays[#player2Plays]
    if lastPlayer1Play ~= lastPlayer2Play then
        -- 0: rock, 1: paper, 2: scissors
        local winner
        if lastPlayer1Play == 0 then
            winner = lastPlayer2Play == 1 and 2 or 1
        elseif lastPlayer1Play == 1 then
            winner = lastPlayer2Play == 2 and 2 or 1
        else
            winner = lastPlayer2Play == 0 and 2 or 1
        end

        self.fractal:setSquare(
            {player1Plays, player2Plays},
            winner,
            {
                player1Plays = Table.shallowCopy(player1Plays),
                player2Plays = Table.shallowCopy(player2Plays)
            }
        )

        return true
    end

    return false
end

function RockPaperScissors:exploreNextPlays(remainingTurns, player1Plays, player2Plays)
    for nextPlayer1Play = 0, 2 do
        player1Plays[#player1Plays + 1] = nextPlayer1Play

        for nextPlayer2Play = 0, 2 do
            player2Plays[#player2Plays + 1] = nextPlayer2Play

            self:simulateRecursive(remainingTurns, player1Plays, player2Plays)

            table.remove(player2Plays, #player2Plays)
        end

        table.remove(player1Plays, #player1Plays)
    end
end

return RockPaperScissors
