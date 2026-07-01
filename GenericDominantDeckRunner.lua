local DeckBattle = require("DeckBattle")
local Table = require("YfritLib.Table")

-- Generalized dominant-deck hypothesis:
--   "For every X, there exists a deck with Y cards (Y > X) that beats every
--    deck with X or fewer cards."
-- This driver walks the ladder forever: start at X = 1, Y = X + 1; test every
-- Y-card deck against all decks of size <= X; if none beats them all, increment
-- Y and retry; once one is found, log it, increment X, and continue.
--
-- Y carries forward across X instead of resetting to X + 1 (it is only bumped
-- up to the floor X + 1 when it would fall below it). Any candidate size that
-- failed for level X also fails for level X + 1 -- the opponent set only grows,
-- so a deck that couldn't beat all decks <= X cannot beat all decks <= X + 1.
--
-- THIS LOOP NEVER TERMINATES BY DESIGN -- force-stop it when satisfied. Battle
-- logs stay off the whole time (per-turn logs would be far too much).
--
-- GenkenRules.resolveTurn is symmetric between the two players, so testing each
-- candidate only in the player-1 seat is complete. A matchup counts as a win
-- only when result.winner == 1 (a draw does NOT count).
--
-- Matches run with no turn limit: DeckBattle short-circuits the only perpetual
-- draw (equivalent decks) to a draw, so every other matchup is decided.
local maxTurns = math.huge

local function moveName(play)
    if play == 0 then
        return "R"
    elseif play == 1 then
        return "P"
    elseif play == 2 then
        return "S"
    end

    return "?(" .. tostring(play) .. ")"
end

local function deckString(deck)
    local parts = {}
    for index, play in ipairs(deck) do
        parts[index] = moveName(play)
    end

    return "{" .. table.concat(parts, ", ") .. "}"
end

-- Iterator over all 3^size ordered decks (0 = Rock, 1 = Paper, 2 = Scissors),
-- enumerated by a base-3 odometer over a single reused table. The table is
-- mutated in place between yields, so shallowCopy anything you keep.
local function decksOfSize(size)
    local deck = {}
    for i = 1, size do
        deck[i] = 0
    end

    local exhausted = false
    local first = true

    return function()
        if exhausted then
            return nil
        end

        if first then
            first = false
            return deck
        end

        local i = 1
        while i <= size do
            deck[i] = deck[i] + 1
            if deck[i] <= 2 then
                return deck
            end
            deck[i] = 0
            i = i + 1
        end

        exhausted = true
        return nil
    end
end

-- Every deck of size 1..maxSize, as a flat list of independent (copied) decks.
local function buildOpponents(maxSize)
    local opponents = {}
    for size = 1, maxSize do
        for deck in decksOfSize(size) do
            opponents[#opponents + 1] = Table.shallowCopy(deck)
        end
    end

    return opponents
end

-- True iff candidate (as player 1) wins every matchup. Short-circuits on the
-- first non-win, so most candidates are rejected cheaply.
local function beatsAll(battle, candidate, opponents)
    for _, opponent in ipairs(opponents) do
        if battle:run(candidate, opponent).winner ~= 1 then
            return false
        end
    end

    return true
end

local function load()
    local battle = DeckBattle:new({maxTurns = maxTurns, logs = false})

    print("=== Generic dominant-deck search (Genken rules) ===")
    print("Win at 10 points, no turn limit -- draws happen only between equivalent decks.")
    print("(win = decided, not a draw)")
    print("For each X: find a Y-card deck (Y > X) that beats every deck of size <= X.")
    print("This runs forever -- force-stop when satisfied.")
    print()

    local x = 1
    local y = x + 1

    while true do
        if y < x + 1 then
            y = x + 1
        end

        local opponents = buildOpponents(x)
        print(string.format("--- X = %d: beat all %d decks of size <= %d ---", x, #opponents, x))

        local winner
        while not winner do
            local checked = 0
            for candidate in decksOfSize(y) do
                checked = checked + 1
                if beatsAll(battle, candidate, opponents) then
                    winner = Table.shallowCopy(candidate)
                    break
                end
            end

            if not winner then
                print(string.format("  no winning deck of size %d (checked %d); trying size %d", y, checked, y + 1))
                y = y + 1
            end
        end

        print(string.format("  FOUND: %s (size %d) beats all decks of size <= %d", deckString(winner), y, x))
        print()

        x = x + 1
    end
end

return {
    load = load
}
