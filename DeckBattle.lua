local GenkenRules = require("GenkenRules")

-- ==== Edit your decks here (0 = Rock, 1 = Paper, 2 = Scissors) ====
-- Each deck is a list of moves a player cycles through, one per turn. When a
-- deck runs out it wraps back to its first card.
local deck1 = {0, 0, 0}
local deck2 = {2, 1}
local maxTurns = 50

local function moveName(play)
    if play == 0 then
        return "R (Rock)"
    elseif play == 1 then
        return "P (Paper)"
    elseif play == 2 then
        return "S (Scissors)"
    end

    return "? (" .. tostring(play) .. ")"
end

local function deckString(deck)
    local parts = {}
    for index, play in ipairs(deck) do
        parts[index] = moveName(play)
    end

    return table.concat(parts, ", ")
end

local function simulate(d1, d2, turnCap)
    local points1, points2, generators1, generators2 = 0, 0, 0, 0

    print("=== Deck Battle (Genken rules) ===")
    print("Deck 1: " .. deckString(d1))
    print("Deck 2: " .. deckString(d2))
    print(string.format("Win at 10 points, max %d turns.", turnCap))
    print()

    for turn = 1, turnCap do
        local play1 = d1[((turn - 1) % #d1) + 1]
        local play2 = d2[((turn - 1) % #d2) + 1]

        local generated1, generated2
        points1, points2, generators1, generators2, generated1, generated2 =
            GenkenRules.resolveTurn(play1, play2, points1, points2, generators1, generators2)

        print(string.format("Turn %d:", turn))
        print(string.format("  P1 plays %s", moveName(play1)))
        print(string.format("  P2 plays %s", moveName(play2)))
        print(
            string.format(
                "  P1 generated %d -> total %d points (%d generators)",
                generated1,
                points1,
                generators1
            )
        )
        print(
            string.format(
                "  P2 generated %d -> total %d points (%d generators)",
                generated2,
                points2,
                generators2
            )
        )

        if points1 >= 10 then
            print()
            print(string.format("Player 1 wins on turn %d! (P1 %d, P2 %d)", turn, points1, points2))
            return
        end
        if points2 >= 10 then
            print()
            print(string.format("Player 2 wins on turn %d! (P1 %d, P2 %d)", turn, points1, points2))
            return
        end

        print()
    end

    print(string.format("Draw -- reached the %d-turn limit (P1 %d, P2 %d).", turnCap, points1, points2))
end

function love.load()
    simulate(deck1, deck2, maxTurns)
end
