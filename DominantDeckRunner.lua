local DeckBattle = require("DeckBattle")

-- Hypothesis: there exists a 2-card deck (a cycling pair of Genken moves) that
-- beats EVERY possible 1-card deck. This driver brute-forces the (tiny) search
-- space: 9 ordered 2-card decks x 3 one-card decks. Moves: 0 = Rock, 1 = Paper,
-- 2 = Scissors.
--
-- GenkenRules.resolveTurn is symmetric between the two players, so testing the
-- 2-card deck only in the player-1 seat is complete. A matchup counts as a win
-- only when result.winner == 1 (a draw / turn-limit result does NOT count).
local maxTurns = 50

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

local function buildTwoCardDecks()
    local decks = {}
    for firstCard = 0, 2 do
        for secondCard = 0, 2 do
            decks[#decks + 1] = {firstCard, secondCard}
        end
    end

    return decks
end

local function load()
    local battle = DeckBattle:new({maxTurns = maxTurns, logs = false})
    local oneCardDecks = {{0}, {1}, {2}}
    local twoCardDecks = buildTwoCardDecks()

    print("=== Searching for a 2-card deck that beats all 1-card decks ===")
    print(string.format("Win at 10 points, max %d turns. (win = decided, not a draw)", maxTurns))
    print()

    local winningDeck

    for _, candidate in ipairs(twoCardDecks) do
        local wonAll = true
        local results = {}

        for index, opponent in ipairs(oneCardDecks) do
            local result = battle:run(candidate, opponent)
            local won = result.winner == 1
            wonAll = wonAll and won

            local verdict
            if won then
                verdict = "WIN"
            elseif result.winner == 2 then
                verdict = "LOSS"
            else
                verdict = "DRAW"
            end
            results[index] = string.format("%s vs %s", verdict, deckString(opponent))
        end

        print(
            string.format(
                "Deck %s: %s -> %s",
                deckString(candidate),
                table.concat(results, ", "),
                wonAll and "DOMINANT!" or "not dominant"
            )
        )

        if wonAll then
            winningDeck = candidate
            break
        end
    end

    print()

    if not winningDeck then
        print(
            string.format(
                "Hypothesis FAILED: no 2-card deck beats all 1-card decks (max %d turns).",
                maxTurns
            )
        )
        return
    end

    print("======================================================")
    print(string.format("FOUND a dominant 2-card deck: %s", deckString(winningDeck)))
    print("Replaying its battles with full logs:")
    print("======================================================")
    print()

    battle.logs = true
    for _, opponent in ipairs(oneCardDecks) do
        battle:run(winningDeck, opponent)
        print()
    end
end

return {
    load = load
}
