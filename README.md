# Dialogue Portraits — FireRed / LeafGreen

A face beside the words. Talk to somebody in the overworld and their portrait
appears next to the dialogue box.

This is the Gen 3 port of
[`gen2-dialogue-portraits`](https://github.com/DarkHeros09/gen2-dialogue-portraits),
which is itself the Gen 2 port of
[`gen1recomp-dialogue-portraits`](https://github.com/Nezara/gen1recomp-dialogue-portraits).
The idea, the three layouts and the speaker-resolution order are those mods'.
What is this one's own is everything FireRed and LeafGreen do differently.

> **Gen 3 only.** The manifest declares `"games": ["gen3"]`, so it loads on
> FireRed and LeafGreen and nowhere else. Use `gen1recomp-dialogue-portraits` on
> Red, Blue and Yellow, and `gen2-dialogue-portraits` on Gold, Silver and Crystal.

## What it does

Every line of overworld dialogue that belongs to somebody gets that somebody's
face — a trainer before and after a battle, an ordinary NPC, a story character, a
talking Pokémon. Signs, hidden items, field moves, warps and every menu box come
out bare, and so does anything drawn during a battle itself.

**The mod ships no art.** There is no picture in this repository. Every portrait
is cut, on your machine, at runtime, out of the battle sprite the engine has
already extracted from the ROM you supplied — a trainer class frontpic or a
species frontpic — using a table of rectangles that says where on each sprite the
face is. A rectangle is not a picture of anybody, so nothing Nintendo drew is
redistributed here, and nothing needs to be: the game you are already running has
the art.

A PNG you drop in `CustomArt/` beats everything else and is drawn exactly as
supplied. See [`CustomArt/README.md`](CustomArt/README.md).

## Options

Two, both inside FireRed's own **`OPTION`** menu — the last entry on the page is
**`DIALOGUE PORTRAITS`**.

| Option | Values | What it does |
|---|---|---|
| `PORTRAIT` | **INSET** / FRAMED / MARGIN / OFF | Where the portrait goes |
| `SIDE` | **AUTO** / LEFT / RIGHT | Which side of the box the face sits on |

`INSET` puts the art inside the dialogue box in four columns of its own, and the
text moves along. `FRAMED` gives it the game's own menu window beside the box,
drawn in the `OPTION → FRAME` choice you have already made. `MARGIN` paints a
panel of its own out in the letterbox and leaves the box alone. `SIDE = AUTO`
follows the way you turned to talk to somebody.

## Installing

Put the `gen3-dialogue-portraits/` folder in the engine's `mods/` directory,
beside `main.lua`, or install the release `.zip` through the launcher. The
launcher can also update it from this repository's releases — that is what the
`github` field in `manifest.json` is for.

## Documentation

This file is the summary. **[`MANUAL.md`](MANUAL.md) is the full documentation** —
every layout measured, every rule that decides which picture a speaker gets, what
the mod deliberately declines to draw and why, the headless test suites, and how
to cut a release. [`CHANGELOG.md`](CHANGELOG.md) is the history.

## Verifying and releasing

From an engine checkout with the mod beside it:

```sh
# the five headless suites -- 1023 checks, 0 failures
luajit ../gen3-dialogue-portraits/tests/dp3_load_test.lua
luajit ../gen3-dialogue-portraits/tests/dp3_menu_test.lua
luajit ../gen3-dialogue-portraits/tests/dp3_speaker_test.lua
luajit ../gen3-dialogue-portraits/tests/dp3_geometry_test.lua
luajit ../gen3-dialogue-portraits/tests/launcher_update_test.lua

# the distribution gates
export MODKIT_LUAJIT=<path to luajit>
python3 tools/modkit.py validate ../gen3-dialogue-portraits --strict
python3 tools/modkit.py lint     ../gen3-dialogue-portraits
python3 tools/modkit.py gen3check ../gen3-dialogue-portraits --strict --notes
```

**Cutting a release.** Nothing is built into this repo: the `.zip` is a build
product. `.github/workflows/release.yml` builds
`gen3-dialogue-portraits-<version>.zip` from the tagged tree and attaches it to
the GitHub Release, refusing to run if the tag and the manifest disagree. So the
whole procedure is bump the version, tag, push:

```sh
# 1. bump "version" in manifest.json
git tag v1.0.1 && git push origin v1.0.1
```

The asset name matters: the launcher looks for exactly
`<mod-id>-<version>.zip`, and an update is only offered when the release is
strictly newer than the installed copy.

## Credits

- The Gen 1 and Gen 2 mods this is a port of, for the idea, the three layouts and
  the speaker-resolution order.
- [pret/pokefirered](https://github.com/pret/pokefirered), for the dialogue box
  geometry, the text printer semantics and the trainer class list this mod reads.
- The gen1recomp engine, for the Gen 3 field, UI and mod-loader stack.

Pokémon, its characters and its sprites are Nintendo / Game Freak / Creatures
Inc. property. This project claims no rights to them and has no affiliation with
them.
