# Genken — the rules

Genken is a two-player, Rock-Paper-Scissors-derived **economic** game. It keeps
the three moves (Rock / Paper / Scissors) but throws away the classic "rock beats
scissors" relationship entirely. There is no per-turn winner of a clash; instead
each move feeds a running **point economy**, and the first player to pull ahead to
the score threshold wins.

This document describes the game implemented in
[`Genken.lua`](Genken.lua) — just the rules of one playthrough.

## Setup

- Two players, playing **simultaneously** each turn.
- Every turn each player independently chooses one move:
  - `0` = **Rock**
  - `1` = **Paper**
  - `2` = **Scissors**
- Each player tracks two running quantities, both starting at `0`:
  - **points** — the score; the win condition is based on this.
  - **generators** — a passive income engine built by playing Scissors.

## What each move does

Scoring happens once per turn, after both players have revealed their move. Each
player first computes the points they **generate this turn**, then those points
are added to their total.

A player's generated points for the turn start at *their current generator count*
(passive income — see below), then the move played adjusts them:

| Move | Effect on generated points |
|------|----------------------------|
| **Rock** (`0`) | `+4` to yourself. A flat burst of points. |
| **Paper** (`1`) | `+1` to yourself **and** `−4` to your opponent's generated points this turn. |
| **Scissors** (`2`) | Build a **generator**: your generator count goes up by 1 *before* income is counted, so the new generator already pays out this turn (`+1` now and `+1` every future turn). |

### Generators (passive income)

Every generator you own adds `+1` to your generated points **every turn**, for the
rest of the game, no matter what move you play that turn. Generators are permanent
and stack: with 3 generators you collect `+3` each turn on top of whatever your
current move does.

Because Scissors increments the generator count *before* income is tallied,
playing Scissors yields at least `+1` on the turn you play it (more if you already
had generators), plus the recurring `+1`/turn afterwards. Scissors is the
long-term investment move.

### Important: the `−4` from Paper can't drain your total

Paper's `−4` is applied to the opponent's **generated points for that turn only**,
and a turn's generated points are clamped to a minimum of `0` before being added
to the total:

```
generatedPoints = max(0, generatedPoints)
total += generatedPoints
```

So Paper can *deny* an opponent up to 4 points of income on a turn (fully
cancelling a Rock, or eating into generator income), but it can **never reduce
their accumulated total**. Totals only ever go up. Paper also does nothing to the
opponent's generators — it attacks income, not the engine.

## Special rules

- **Anti-stalemate.** If *both* players generate `0` points on a turn (for
  example, both play Paper with too few generators to survive the mutual `−4`),
  then both players are awarded `+1` point so the game can't deadlock.
- **Win threshold: 10 points.** As soon as a player's total reaches `10` or more,
  they win.
- **Simultaneous-overshoot cancellation.** If *both* players are at `10`+ at the
  same time, `10` is subtracted from each (repeatedly, while both are still at
  `10`+). The win only triggers when a single player is at `10`+ alone — you can't
  win by crossing the line on the exact same turn as your opponent.
- **Turn limit → draw.** Exploration runs to a maximum number of turns
  (`maxTurns`). If the turn limit is reached with no winner, the line is a draw.

## Move summary / strategy shape

- **Rock** — immediate burst (`+4` now), no lasting effect. Good for closing out.
- **Paper** — disruption (`+1` self, deny up to `4` of the opponent's income this
  turn). Tempo / defense, not raw scoring.
- **Scissors** — investment. Costs you the bigger immediate gains of Rock but
  builds permanent `+1`/turn income that compounds over a long game.

## Worked examples

Assume both players start at `0` points / `0` generators.

- **P1 plays Scissors, turn 1.** Generators go `0 → 1`, so P1 generates `1` this
  turn → P1 total `1`. P1 now earns `+1` every following turn passively.
- **P1 has 2 generators and plays Rock.** Generated this turn = `2` (generators)
  `+ 4` (Rock) = `6`.
- **Both play Paper with 0 generators.** Each generates `0 + 1 − 4 = −3`, clamped
  to `0`. Both generated `0` → anti-stalemate awards both `+1`.
- **P1 plays Rock (`+4`), P2 plays Paper attacking P1.** P1's `4` is reduced by
  `4` to `0` for the turn; P2 generates `1`. P1 gains nothing this turn, P2 gains
  `1` — but P1's existing total is untouched.
