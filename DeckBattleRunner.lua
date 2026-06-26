local DeckBattle = require("DeckBattle")

-- ==== Edit your decks here (0 = Rock, 1 = Paper, 2 = Scissors) ====
-- Each deck is a list of moves a player cycles through, one per turn. When a
-- deck runs out it wraps back to its first card.
local deck1 = {0, 0, 0}
local deck2 = {2, 1}
local maxTurns = 50

local function load()
    local battle = DeckBattle:new({maxTurns = maxTurns, logs = true})
    battle:run(deck1, deck2)
end

return {
    load = load
}
