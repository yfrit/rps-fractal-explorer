local Class = require("YfritLib.Class")
local GenkenRules = require("GenkenRules")

-- A single deterministic Genken match between two fixed decks (0 = Rock,
-- 1 = Paper, 2 = Scissors). Each deck is a list of moves a player cycles
-- through, one per turn; when a deck runs out it wraps back to its first card.
--
-- Configure once, then run any number of matchups:
--   local battle = DeckBattle:new({ maxTurns = 50, logs = false })
--   local result = battle:run({0, 0, 0}, {2, 1})
--   -- result.winner == 1 | 2 | nil (draw), result.turns / points1 / points2
--
-- maxTurns may be math.huge for an uncapped match: run short-circuits the only
-- perpetual matchup -- two *equivalent* decks (identical infinite play
-- sequences) -- to a draw before simulating, so every other matchup is decided
-- in finite turns.
local DeckBattle =
    Class.new(
    {
        logs = false
    },
    function(self, params)
        self.maxTurns = params.maxTurns or 50
        self.logs = params.logs
    end
)

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

local function gcd(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end

    return a
end

-- Two cycling decks produce the same infinite play sequence iff they agree over
-- the first lcm(#deck1, #deck2) turns -- both are periodic with period dividing
-- that lcm, so matching one full window means matching forever. Such equivalent
-- decks mirror each other and can only draw; every non-equivalent matchup is
-- decided in finite turns.
local function decksAreEquivalent(deck1, deck2)
    local len1, len2 = #deck1, #deck2
    local turns = len1 / gcd(len1, len2) * len2

    for turn = 1, turns do
        if deck1[((turn - 1) % len1) + 1] ~= deck2[((turn - 1) % len2) + 1] then
            return false
        end
    end

    return true
end

-- Run one match between deck1 and deck2. State is local so a single instance
-- can be reused across many matchups. Returns a result table:
--   { winner = 1 | 2 | nil, turns = number, points1 = number, points2 = number }
-- (winner = nil denotes a draw / turn-limit result).
function DeckBattle:run(deck1, deck2)
    -- Equivalent decks mirror each other forever: the one perpetual draw, which
    -- would loop without end under an uncapped maxTurns. Short-circuit it.
    if decksAreEquivalent(deck1, deck2) then
        if self.logs then
            print("=== Deck Battle (Genken rules) ===")
            print("Deck 1: " .. deckString(deck1))
            print("Deck 2: " .. deckString(deck2))
            print("Equivalent decks -- identical play sequences forever; draw.")
            print()
        end

        return {winner = nil, turns = 0, points1 = 0, points2 = 0}
    end

    local points1, points2, generators1, generators2 = 0, 0, 0, 0

    if self.logs then
        print("=== Deck Battle (Genken rules) ===")
        print("Deck 1: " .. deckString(deck1))
        print("Deck 2: " .. deckString(deck2))
        print(string.format("Win at 10 points, max %s turns.", tostring(self.maxTurns)))
        print()
    end

    for turn = 1, self.maxTurns do
        local play1 = deck1[((turn - 1) % #deck1) + 1]
        local play2 = deck2[((turn - 1) % #deck2) + 1]

        local generated1, generated2
        points1, points2, generators1, generators2, generated1, generated2 =
            GenkenRules.resolveTurn(play1, play2, points1, points2, generators1, generators2)

        if self.logs then
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
        end

        if points1 >= 10 then
            if self.logs then
                print()
                print(string.format("Player 1 wins on turn %d! (P1 %d, P2 %d)", turn, points1, points2))
            end
            return {winner = 1, turns = turn, points1 = points1, points2 = points2}
        end
        if points2 >= 10 then
            if self.logs then
                print()
                print(string.format("Player 2 wins on turn %d! (P1 %d, P2 %d)", turn, points1, points2))
            end
            return {winner = 2, turns = turn, points1 = points1, points2 = points2}
        end

        if self.logs then
            print()
        end
    end

    if self.logs then
        print(
            string.format("Draw -- reached the %s-turn limit (P1 %d, P2 %d).", tostring(self.maxTurns), points1, points2)
        )
    end

    return {winner = nil, turns = self.maxTurns, points1 = points1, points2 = points2}
end

return DeckBattle
