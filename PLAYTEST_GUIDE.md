# Playtest Guide — What to Play, What to Watch, How to Report

The repeatable protocol for manual playtests (yours and, later, external
testers'). The sims prove the math; only humans can prove the *feel*.

## Session 0 — the fresh-Seeker run (highest value, do first)

1. **Back up, then delete the save** to become a brand-new player:
   ```
   cp ~/Library/Application\ Support/Godot/app_userdata/Seven\ Springs/save.json ~/ss_save_backup.json
   rm ~/Library/Application\ Support/Godot/app_userdata/Seven\ Springs/save.json
   ```
   (Restore later by copying it back.)
2. Launch (`godot --path .` from `~/sufiGacha`, or the web build) and play
   **45–60 minutes without stopping to take notes** — first impressions
   only happen once. Note-taking comes after.

## What to watch, per system (jot AFTER the session)

**Tutorial & first minutes**
- Did the five tutorial beats teach enough? Too much text anywhere?
- After the tutorial, did you know what to do next without thinking?

**Combat (the deterministic puzzle)**
- Can you follow a battle WITHOUT reading the log?
- When you lose, does it feel like "my plan was short" (good) or "the game
  is rigid" (bad)?
- Does "TRANCE IMMINENT" change your decisions? Is timing Brand's
  Immunity against it discoverable and satisfying?
- Chase a 3-star on a stage you only 1-starred: does it feel like solving?

**The daily loop**
- Deeds → Sanctum → Journey/Minaret: does the day have a shape, or does it
  feel like chores? How long until you ran out of *wants*?
- Is Breath ever a wall at a moment that annoyed you? (Note the moment.)

**Economy & The Calling**
- After Valley 1: did you WANT a specific hero? Could you see the path to
  affording them? Did buying feel like a choice or a spreadsheet?
- Do star/waymark/deed rewards feel connected to what you did?

**The week-2 wall (our known danger zone)**
- Around stage 1-10 to 1-12 you'll hit the level wall. Grind or quit —
  which did you *feel* like doing? What would have kept you?

**The dawah layer**
- Open the Notebook cold: did any entry make you want to tap a link?
  Which one? Did the fantasy voice read as inviting or evasive?

## Reporting

Dump raw impressions (voice-note style is fine) — unsorted, unfiltered,
including "this is probably just me" items. I triage them into PROGRESS.md.
The three killer questions if time is short:
1. When did you last feel *delight*? What caused it?
2. When did you first feel *friction*? What caused it?
3. Would you open the game again tomorrow without being asked? Why/why not?

## For external testers (later)
Same protocol, plus: never coach them during the first session; watch where
they get stuck silently. The web build (`python3 -m http.server 8000 -d
build/web`) is the zero-install way to put it in front of someone.
