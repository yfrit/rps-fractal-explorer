local GenkenRules = {}

-- Resolve one Genken turn. Pure function (no LÖVE / Class / fractal dependency).
-- Plays: 0 = Rock, 1 = Paper, 2 = Scissors.
-- Returns the updated state plus each player's generated points this turn
-- (the trailing two returns are handy for logging; callers may ignore them).
function GenkenRules.resolveTurn(play1, play2, points1, points2, generators1, generators2)
    -- scissors: +1 generator BEFORE income is counted
    if play1 == 2 then
        generators1 = generators1 + 1
    end
    if play2 == 2 then
        generators2 = generators2 + 1
    end

    local generated1 = generators1
    local generated2 = generators2

    -- rock: +4
    if play1 == 0 then
        generated1 = generated1 + 4
    end
    if play2 == 0 then
        generated2 = generated2 + 4
    end

    -- paper: +1 self, -4 to opponent's generated points this turn
    if play1 == 1 then
        generated1 = generated1 + 1
        generated2 = generated2 - 4
    end
    if play2 == 1 then
        generated2 = generated2 + 1
        generated1 = generated1 - 4
    end

    generated1 = math.max(0, generated1)
    generated2 = math.max(0, generated2)

    points1 = points1 + generated1
    points2 = points2 + generated2

    -- anti-stalemate: if neither scored, both get +1
    if generated1 == 0 and generated2 == 0 then
        points1 = points1 + 1
        points2 = points2 + 1
    end

    -- simultaneous-overshoot cancellation
    while points1 >= 10 and points2 >= 10 do
        points1 = points1 - 10
        points2 = points2 - 10
    end

    return points1, points2, generators1, generators2, generated1, generated2
end

return GenkenRules
