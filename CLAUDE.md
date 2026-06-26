# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A LÖVE (Love2D) Lua application that exhaustively explores the game tree of
Rock-Paper-Scissors variants and renders it as a nested **fractal grid**. Each
turn subdivides every cell into a 3×3 block (player 1's move selects the column,
player 2's move selects the row), so depth-N play sequences appear as squares
nested N levels deep. Cells are colored by outcome: red = player 1 win, blue =
player 2 win, black = draw / max depth reached.

## Running and linting

```sh
run.bat              # launches: start LOVE\love LOVE\..  (runs love.exe with the repo root as the game dir)
luacheck .           # lint (config in .luacheckrc)
```

There is no test suite and no build step — it is interpreted Lua run by the
bundled `LOVE/love.exe`. `conf.lua` sets `t.console = true`, so on Windows a
console window opens alongside the game to show `print()` output (used for the
hover/Space hints and `Genken`'s optional state logs).

### External dependency: YfritLib

`require("YfritLib.Class")` and `require("YfritLib.Table")` come from **YfritLib,
installed via LuaRocks** (not vendored in this repo). It's already set up on this
machine and resolves at runtime — no per-clone copy step needed. `.luacheckrc`
also declares a `yfrit` std with globals `async`, `makeAsync`, `optionalRequire`,
`mockRequire`, `unmockRequire`.

- `Class.new(defaultsTable, function(self, params) ... end)` → a class whose
  shared/default fields come from `defaultsTable` and whose constructor is the
  function. Instantiate with `SomeClass:new(params)`; add methods with
  `function SomeClass:method(...)`.
- `Table.shallowCopy(t)` — used to snapshot the mutable `plays` arrays before
  storing them as immutable square metadata.

## Architecture

The flow is: a **game** simulator walks the play tree and calls
`fractal:setSquare(...)` for each terminal node; the **Fractal** stores those
squares and handles all rendering/interaction. The simulator never touches
LÖVE directly.

- **`main.lua`** — entry point; just `require("FractalExplorer")`. The "Refactor
  to support multiple main files" commit established this indirection so the
  active experience can be swapped by changing what `main.lua` requires.
- **`FractalExplorer.lua`** — owns the LÖVE callbacks (`love.load/update/draw`).
  Constructs one `Fractal` (3×3 subdivision) and one game, then calls
  `game:simulate({maxTurns = N})` once at load. **Swap which game runs by
  commenting/uncommenting the `RockPaperScissors` vs `Genken` block here.**
- **`Fractal.lua`** — the renderer and the only stateful runtime object.
  - `setSquare(coordinates, value, metadata)` where `coordinates =
    {player1Plays, player2Plays}`; the two play-lists are the nested paths along
    X and Y. `calculatePositionAndSize` converts a path into pixel pos/size by
    repeatedly dividing the screen by `xSize`/`ySize` (3) per level — this is
    what produces the fractal nesting.
  - `value` (1/2/3) indexes `colors`; `metadata` carries the play history shown
    in the hover tooltip and the `indirectVictory` flag.
  - Interaction: hovering a cell shows both players' move sequences (R/P/S);
    holding **Space** reveals squares flagged `indirectVictory` (hidden by
    default via the `iterateSquares` filter).
- **`RockPaperScissors.lua`** — classic RPS. Recursively expands all 3×3 move
  pairs to `maxTurns` depth; stops a branch as soon as one player's move beats
  the other (records the winner) or depth runs out (records a draw).
- **`Genken.lua`** — a custom RPS-derived scoring game and the currently active
  one. Per turn: Rock = +4 points, Paper = +1 and −4 to the opponent, Scissors =
  build a "generator" that yields passive points each subsequent turn. First to
  10 points wins; if both reach 10+ the excess cancels (subtract 10 from each).
  Beyond direct wins it also detects **indirect victories** in
  `exploreNextPlays`: if a player has one move that beats *every* opponent
  response in the explored subtree, that node is marked a win with
  `indirectVictory = true`. **See [GENKEN.md](GENKEN.md) for the full rules.**

## Conventions

- Plays are integers everywhere: `0 = Rock`, `1 = Paper`, `2 = Scissors`
  (note: `Fractal.emojis` uses this 0-based map, while `Fractal.colors` is keyed
  by the 1/2/3 *outcome* value — don't conflate the two).
- The recursive explorers mutate shared `plays1`/`plays2` arrays in place
  (push before recursing, `table.remove` after) for speed, so anything stored
  long-term must be `Table.shallowCopy`'d first — see `getMetadata`.
