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
--
-- CURSED PLAY-SEQUENCES (pruning). When a candidate loses to some opponent O at
-- turn K, the sequence of plays it emitted over turns 1..K is "cursed": any deck
-- whose *generated play sequence* opens with that same sequence reproduces those
-- turns against O and loses identically. Since O stays in every future opponent
-- set (they only grow) and Y only carries upward, such a deck can never be
-- dominant -- so we cut it from all future enumeration. The curse is on the play
-- sequence (deck[((t-1) % #deck) + 1]), NOT the raw card list: the two differ
-- under looping, and that is exactly what lets us prune looped losers too.
--
-- To harvest curses we do NOT stop at the first winner of a size -- we sweep the
-- whole size, recording every loss, so the curse set is complete before moving on.
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

-- Deck counts (pruned subtrees) grow as 3^depth and quickly exceed what "%d"
-- can print exactly (and overflow to garbage/inf). Show exact integers while
-- they fit, then fall back to scientific / "inf".
local function countString(n)
    if n < 1e15 then
        return string.format("%d", n)
    end

    return string.format("%.3g", n)
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

-- Cursed play-sequences, stored as a trie keyed by play (0/1/2). A node marked
-- terminal ends a cursed sequence; any play sequence reaching a terminal is
-- doomed. root = {children = {...}, terminal = bool}.
local function newCurseTrie()
    return {children = {}}
end

-- Add a cursed play sequence. Stops early if a prefix of seq is already cursed
-- (the shorter curse already covers everything seq would), keeping the trie
-- minimal.
local function addCurse(trie, seq)
    local node = trie
    for i = 1, #seq do
        if node.terminal then
            return
        end

        local play = seq[i]
        local child = node.children[play]
        if not child then
            child = {children = {}}
            node.children[play] = child
        end

        node = child
    end

    node.terminal = true
end

-- True iff the candidate's generated (looping) play sequence begins with some
-- cursed sequence. Walks one play per turn, descending the trie; stops at the
-- first terminal (cursed) or when the trie branch runs out (finite depth, so
-- this always terminates even though the play sequence is infinite).
local function isCursed(trie, deck)
    local size = #deck
    local node = trie
    local turn = 1
    while true do
        local play = deck[((turn - 1) % size) + 1]
        node = node.children[play]
        if not node then
            return false
        end
        if node.terminal then
            return true
        end

        turn = turn + 1
    end
end

-- The plays a deck emits over turns 1..turns (its looping play sequence), as an
-- independent table safe to keep after the reused candidate buffer moves on.
local function playSequence(deck, turns)
    local size = #deck
    local seq = {}
    for turn = 1, turns do
        seq[turn] = deck[((turn - 1) % size) + 1]
    end

    return seq
end

-- Runs candidate (as player 1) against every opponent. Returns won, lossResult:
-- won is true iff it wins them all; otherwise lossResult is the DeckBattle result
-- of the first opponent it failed to beat (a loss or an equivalent-deck draw).
-- Short-circuits on that first non-win, so most candidates are rejected cheaply.
local function beatsAll(battle, candidate, opponents)
    for _, opponent in ipairs(opponents) do
        local result = battle:run(candidate, opponent)
        if result.winner ~= 1 then
            return false, result
        end
    end

    return true, nil
end

local function load()
    local battle = DeckBattle:new({maxTurns = maxTurns, logs = false})
    -- Curses accumulate across every X and Y and are never reset: a play sequence
    -- that loses to an opponent keeps losing to it forever.
    local curseTrie = newCurseTrie()

    print("=== Generic dominant-deck search (Genken rules) ===")
    print("Win at 10 points, no turn limit -- draws happen only between equivalent decks.")
    print("(win = decided, not a draw)")
    print("For each X: find a Y-card deck (Y > X) that beats every deck of size <= X.")
    print("Cursed play-sequences prune doomed decks; each size is swept in full.")
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
        local progressShown = false
        while not winner do
            local battled, pruned, completed = 0, 0, 0

            -- Build decks prefix-first, descending the curse trie in lockstep.
            -- For the first pass a deck's plays equal its cards, so a curse of
            -- length <= depth is a card prefix: on a terminal we cut the whole
            -- subtree (all 3^(y-depth) completions) at once instead of visiting
            -- them. `node` tracks the trie node matching the current prefix, or
            -- nil once the prefix leaves the trie (no card-prefix curse below).
            -- Sweep everything (no break) so every loss feeds the curse set.
            local candidate = {}
            local function sweep(pos, node)
                if pos > y then
                    -- A full deck reached the end without a card-prefix cut.
                    completed = completed + 1
                    -- Survived card-prefix cutting; still catch looping curses
                    -- (length > y), which only manifest past the first pass.
                    if isCursed(curseTrie, candidate) then
                        pruned = pruned + 1
                        return
                    end

                    battled = battled + 1
                    local won, lossResult = beatsAll(battle, candidate, opponents)
                    if won then
                        if not winner then
                            winner = Table.shallowCopy(candidate)
                        end
                    elseif lossResult.winner == 2 then
                        addCurse(curseTrie, playSequence(candidate, lossResult.turns))
                    end

                    return
                end

                for card = 0, 2 do
                    candidate[pos] = card
                    local child = node and node.children[card]
                    if child and child.terminal then
                        pruned = pruned + 3 ^ (y - pos)
                    else
                        sweep(pos + 1, child)
                    end
                end

                candidate[pos] = nil
            end

            sweep(1, curseTrie)

            if winner then
                -- Finish the in-place progress line (if any) before the result.
                if progressShown then
                    io.write("\n")
                end
                print(string.format("  size %d: battled %d, pruned %s", y, battled, countString(pruned)))
            elseif completed == 0 then
                -- No deck of this size reached the end uncut: every play sequence
                -- hits a cursed prefix. Prefix coverage is monotonic, so this holds
                -- for every larger size too -- no deck can ever beat all decks of
                -- size <= x, and the hypothesis is false at this rung.
                if progressShown then
                    io.write("\n")
                end
                print(string.format("  every deck of size %d is cursed -- prefix coverage is total.", y))
                print()
                print(string.format("HYPOTHESIS FALSE at X = %d: no deck beats every deck of size <= %d.", x, x))
                return
            else
                -- Overwrite the previous attempt in place with \r (trailing spaces
                -- clear any leftovers when a shorter line replaces a longer one).
                io.write(
                    string.format(
                        "\r  no winning deck of size %d (battled %d, pruned %s); trying size %d   ",
                        y,
                        battled,
                        countString(pruned),
                        y + 1
                    )
                )
                io.flush()
                progressShown = true
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
