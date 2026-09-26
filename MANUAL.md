# Dialogue Portraits — FireRed / LeafGreen

A face beside the words. Talk to somebody and their portrait appears next to
the dialogue box.

**This is the full manual.** The front page of this repository is a short
[`README.md`](README.md); everything below is the long version — every option,
every resolution rule, what the mod declines to draw and why, the test suites,
and how to cut a release.

This is the Gen 3 port of **gen2-dialogue-portraits**, which is itself the Gen 2
port of **gen1recomp-dialogue-portraits**. The idea, the three layouts, the
speaker-resolution order and most of the shape of the code are those mods'.
What is this repo's own is everything FireRed and LeafGreen do differently —
and on this generation that list is longer than on either of the others,
because Gen 3 does not share the dialogue box the first two do.

Gen 3 is the engine's **beta** generation. This mod is written against release
0.3.0 and its `src/ui/game3/*` and `src/core/game3/*` modules.

---

## Options

Two options, both inside FireRed's own **`OPTION`** menu. Open the start menu in
the field, choose **`OPTION`**, and the last entry on the page is
**`DIALOGUE PORTRAITS`** — open it for **`PORTRAIT`** and **`SIDE`**. Nothing is
added when the mod is off, and no engine change is needed.

That entry is not part of FireRed. Gen 1 opens the mod manager from an **F10**
hotkey and from a `MODS` row in its options menu; Gen 2 opens it from a `mods`
entry in its start menu; **Gen 3 has no route to it at all** — nothing under
`src/core/Game3.lua` or `src/ui/game3/` mentions `ManagerState`, and FRLG's start
menu is only POKéDEX / POKéMON / BAG / TRAINER / SAVE / OPTION / EXIT. An earlier
version of this mod answered that by adding a `MODS` row to the start menu that
opened the engine's own mod manager — and that is the wrong door on this
generation: `ManagerState` is drawn with Gen 1 primitives (`src.render.Font`,
`src.ui.OptionRows`, `src.ui.Theme`) and FireRed's extracted font has no glyphs
for them, so it painted a blank screen. This mod instead puts its settings into
the menu FireRed already has, through the option menu's own row/group machinery
(`src/ui/game3/option_rows.lua`), drawn by FireRed's own chrome and font.

| Option | Values | Default |
| --- | --- | --- |
| `PORTRAIT` | `INSET` · `FRAMED` · `MARGIN` · `OFF` | `INSET` |
| `SIDE` | `AUTO` · `LEFT` · `RIGHT` | `AUTO` |

`SIDE` chooses which side of the box the face sits on. `AUTO` reads the
player's own facing: you turn LEFT to talk to somebody standing to your left,
so that is the side of the screen they are on and the side their face belongs
on. Facing UP or DOWN says nothing either way — the speaker is straight ahead —
so those keep the traditional LEFT.

The FRLG dialogue box's **content rect** is **26 × 4 tiles — 208 × 32 px — at
column 2, row 15** of a 240 × 160 screen. It is a *wider, shorter* window than
Gen 1/2's 20 × 6 (160 × 48) on a 160 × 144 screen, and that one difference is
why the layouts below are not the Gen 2 mod's numbers.

**The box you actually see is bigger than that**, and every layout below is
measured against the visible one. `Chrome.dialogueFrame()` draws the frame
*around* the content rect — two columns to the left of `DLG_LEFT`, two columns
past its end, a row above and a row below — so FRLG's box occupies **30 × 6
tiles, 240 × 48 px, at (0, 112)**: the entire width of the screen, edge to edge.
`Chrome.DLG_*` is the *text's* window, not the picture's. Sizing a panel to the
freed run of `DLG_*` therefore puts it two columns inside the box's own border,
which is what made FRAMED's panel read as part of the box instead of as a panel
standing beside it.

### INSET

The art goes in five of the box's own columns, and the text moves along to make
room. The box keeps its full width.

```
+--------------------------------------+
| [##]  Somebody is talking to you.    |
| [##]  Their face is right here.      |
+--------------------------------------+
```

Both sides reserve the **same five columns** — a 32 px slot, plus one kept clear
of the words — so `SIDE` does not change how much text there is:

- LEFT: the text starts 40 px further along and loses 40 px — 208 → 168.
- RIGHT: the text stays where it is and loses 40 px — 208 → 168. That clear
  column is the one the blinking arrow owns, so the arrow gets its own room and
  the words get the same width as on the left.

It used to reserve the art's own columns on the left and one more on the right,
which made the same layout a different width on each side.

**The portrait now fills its slot: 32 px in a 32 px slot, edge to edge, with no
padding of its own.** The default crop is exactly **32 px** — the box's own
content rect — so the picture stops where the column it was given stops. The
clearance to the words is the *reserve* rather than padding: the box hands the
slot four columns and one more kept clear (`INSET_GAP_TW`), so the first letter
starts **8 px** past the art however big the crop is. A crop wider than the slot
is still fitted *down* to it rather than crossing into the pen.

That is a change from 1.8.x, which inset the slot by a pixel on each side and
drew a **30 px** portrait inside it — a one-pixel band of box around the picture on
every side. 1.4.0 and 1.5.0 also measured 30 px; 1.6.0 made it 38 px in a 40 px
slot, and that is **taller than the box's own 4-row content rect** (32 px) — so the
only way to place it was to clamp it against the visible box's top border rather
than to centre it in the rect it occupies.

Vertically it is centred against the box the player **sees** — the same rect
FRAMED uses — which at 32 px lands it on rows **120–151**: the content rect, edge
to edge, with nothing left over. The offset is clamped at zero, and that clamp is
now inert rather than load-bearing: a crop can only reach it by being bigger than
the slot it is fitted into, which `fitScale` does not allow.

### FRAMED

A bordered panel of its own, on whichever side the portrait belongs. **The panel
is the game's own menu window** — the same `Chrome.stdFrame` the start menu's box
and the OPTION page's body are drawn with, so the portrait wears the frame the
player already knows from the menus, and a change to that frame moves both.

It is **six tiles (48 px) square**, with a whole tile (8 px) of border on every
side and a 32 px content rect inside it. The art is centred in that content at
the largest whole number of times the crop that fits, so the default 32 px crop
is drawn **1:1** and fills the content exactly.

The window is a **constant size** rather than the art's size, and that is forced
by the border: `Chrome.stdFrame` draws its border from 8 × 8 tiles, so the window
has to be a whole number of tiles on both axes or the frame does not line up. A
crop that varies from 12 px to 32 px cannot be wrapped in a tile-aligned border
of its own width, so the window is one size for everybody and the *art* is what
varies.

It stands **exactly `EDGE_PAD` — 4 game px — clear of both** the play area's own
edge and the box, because the columns the box gives up are bought in whole tiles
and the slack between the run and the window is **split in two**. Before 1.9.0 the
whole slack went outward: the panel sat flush against the box, and on the default
crop the run was exactly the window's own width, so the portrait touched the
screen's edge too. See below.

| crop | zoom | art | window | columns of the box | text | gap to the box | gap to the edge |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 32 px (the default) | 1× | 32 px | 48 px | 7 | 152 px | **4 px** | **4 px** |
| 16 px | 2× | 32 px | 48 px | 7 | 152 px | 4 px | 4 px |
| 12 px | 2× | 24 px | 48 px | 7 | 152 px | 4 px | 4 px |

**The text width is a constant again**, because the run the box gives up is
bought for the window and the window never changes: **152 px** for every speaker
in this layout, whatever their crop. That is the reversal this release makes
against 1.8.0, where the panel was the art's own size and the text width was
therefore a property of the speaker.

What the art does instead is fill the window as far as a whole number of times
its own size allows: a 16 px crop is drawn **2×** (32 px, filling the content
exactly), a 12 px one is also **2×** (24 px, four pixels of content left on each
side). A crop is never resampled to an arbitrary fit, so its pixels stay square
with the source.

The shapes this replaces, in order, because each got part of it right:

- **1.4.0** — six tiles square with the art stretched to fill a 46 px window. A
  30 px face in a 48 px panel is 61 % flat white, and the stretch was 1.53×.
- **1.6.0** — the same fixed 48 px square, kept alive for one more release.
- **1.8.0** — the panel **sized to the art** instead: a 32 px panel for the
  default crop, with a hand-painted one-pixel black outline where a border should
  be. The ring went and the text width became per-speaker, but the outline was a
  hairline scaled up with everything else rather than a border.

**This release takes the fixed size back and keeps the honest border.** The
window is the game's, so the ring around the art is a real 8 px border drawn from
the game's own tiles — and it is the *window* that is fixed, not the art:

```
frame 48 x 48   border 8 px   content 32 x 32   art 32 x 32 at 1x
```

#### The panel is centred in the columns the box gave up

The box gives up a whole number of **columns** (8 px each) and the window is
exactly six of them, so the run it buys is `ceil((EDGE_PAD + 48) / 8)` = **7**
columns — 56 px — for a 48 px window, and the **8 px of slack is split four and
four**. The panel therefore stands **4 px from the play area's own edge** and
**4 px from the box's own *visible* edge**, and because the window is one size
that is the same for *every* crop: 1.8.0's 6 px and 10 px for the 16 px and 12 px
crops are gone with the per-speaker panel.

Those 4 px are `EDGE_PAD`, spelled as a number the bookkeeping can be checked
against — **the gap the player sees is the constant itself**, not the run's
slack. Both halves matter: an outer edge flush with the screen is the edge of a
phone's display, and an inner edge flush with the box made the panel and the box
read as one merged shape, which is what "there is no space between the portrait
and the frame it sits in" looked like.

What stands between the portrait and the first letter is that inner 4 px **plus**
the box's own border: the text pen starts at the content rect, which
`Chrome.dialogueFrame` draws `CHROME_L` (2) columns inside the visible edge, so
the gap to the words is `CHROME_L * 8 + EDGE_PAD` = **20 px**. 1.6.0 and 1.7.0
closes it to 4 px by having the panel stand *over* that border; this release
keeps the border showing and moves the panel clear of both edges instead.

```
FRAMED-LEFT   panel 4..52      box visible edge 56    pen 72       gap 20
FRAMED-RIGHT  panel 188..236   box visible edge 184   pen end 168  gap 20
```

The box is 26 columns wide at x=2, so on screen it is columns 0–29 (0–240 px).
Getting the panel's edges wrong by a couple of tiles is invisible in a screenshot
of one side and obvious in a screenshot of the other, which is why
`tests/dp3_geometry_test.lua` captures the rectangle the panel actually paints
and asserts both its edges against the box's — and why it spies on the
`Chrome.stdFrame` call itself, so "it is the game's window" is measured rather
than claimed.

```
+-----------------------------+  +------+
| Somebody is talking to you. |  | #### |
| Their face has a panel now. |  | #### |
+-----------------------------+  +------+
```

### MARGIN

The art is painted out in the letterbox, over the finished frame, and costs the
text nothing — it is a bordered panel of its own moved clear of the box, on the
side `SIDE` asks for. This uses the `render.hud` hook and window space, so it
only helps when the window is wider than the 240 × 160 game frame — on a
fullscreen 16:9 display there is plenty of room either side. There the panel is
centred in the margin and **bottom-aligned with the play area**, so it sits level
with the box.

Where there is no margin to use — a window at the game's own aspect ratio, which
is every phone in portrait — it stands **above the box** instead, keeping
`MARGIN_BOX_GAP` clear of the box and `MARGIN_PAD` in from the play area's own
edge: **2 game px** above the box's top, and 4 game px in from the edge. Those
are two different margins and 1.9.3 is where they stopped sharing one constant —
the distance the panel keeps from the box is not the distance it keeps from the
screen, and the report was that the first was 4 px when it should be 2. It is
never centred in the frame: the box lives in the bottom fifth of the screen, so a
vertically centred panel floats half a screen away from the dialogue it belongs
to.

#### The window is the game's own, in both layouts

The panel is the game's standard menu window — six tiles (48 px) square, an 8 px
tile border on every side, a 32 px content rect inside — and the art is centred
in that content at the largest whole number of times the crop that fits:

| crop | zoom | art | window |
| --- | --- | --- | --- |
| 32 px (the default) | 1× | 32 px | 48 px |
| 16 px | 2× | 32 px | 48 px |
| 12 px | 2× | 24 px | 48 px |

This is the **same plan FRAMED draws** — there is one shape now, and the two
layouts differ only in where it is put. That matters twice over. The window's
size is the game's rather than the crop's, so the ring around the art is a real
8 px border rather than a hairline, and the border is the *same* border the
player sees on every menu in the game. And the art is a whole multiple of its
source instead of being stretched to fill a window, so a small crop keeps its own
proportions.

What the clearance means is worth spelling out, because it is two numbers doing
two jobs, and 1.9.3 is where they were split apart. The panel's **bottom** edge
is `MARGIN_BOX_GAP` — **2 game px** — above the box, and its **top** is the
window's own height higher than that: 48 px above the box's top, which is the
box's own height. `MARGIN_PAD` — **4 game px** — is the clearance **in from the
play area's edge** on the side the portrait belongs to, so on a phone it no
longer touches the edge of the screen. One number for the box, one for the
screen; before 1.9.3 there was a single constant and the box gap was 4.

**FRAMED is governed by `EDGE_PAD`** — the same 4 game px the edge uses — and it
buys its room out of the box, in whole columns. Both now land on it **exactly**,
because FRAMED's run is 7 tiles against a 6-tile window and the extra tile is
split in two: MARGIN places its panel in window space and keeps `EDGE_PAD` as a
margin, FRAMED splits the run's slack and gets `EDGE_PAD` on each side. Before
1.9.0 the whole slack went outward, so FRAMED's gap to the box was zero and its
gap to the screen was 8 px.

The letterbox branch is the one place the box gap does **not** apply, and that is
deliberate: when there is a letterbox the panel is drawn *beside* the box, out in
the black bar, so there is no box top to stand above — only the screen edge to
stay clear of. It keeps `MARGIN_PAD` on both axes there, and the y axis only
switches to `MARGIN_BOX_GAP` in the branch where the panel really is over the box.

The unit is the point. 2 game px was 8 *device* pixels on a 1080-wide phone but 12
on a 1440-wide one, because the gap scales with the device's `Sp`; stating the
clearance in game px is what makes it the same margin everywhere. The number is
also what decides whether the letterbox is worth using at all: the panel only goes
out into the margin when the margin can hold it **plus** the clearance on both
sides, so a margin that merely *fits* the panel now falls through to standing above
the box rather than sitting 2 px from the screen's edge. FRAMED has nothing above
the box to line up with either — its panel stands beside the box, sharing the
box's vertical centre.

MARGIN mirrors a Pokemon on the LEFT, exactly as INSET and FRAMED do: a species
front pic is drawn facing left, which is the right way round on the right — the
creature looks in towards the words — so art on the left is turned back the
other way. Trainer pics are busts and are never mirrored.

#### The panel is placed in window units, not framebuffer pixels

`render.hud`'s viewport reports `scale` as **integer framebuffer pixels per game
pixel** (`Renderer:fitScale`), while `gameX` and `gameWidth` are LÖVE window
units. So `gameWidth` is *not* `Display.W * scale`: the two differ by exactly the
display's pixel ratio. `conf.lua` sets `t.window.highdpi` on mobile only, so that
ratio is 1 on a desktop and 2 or 3 on a phone — which is why the mistake was
invisible on every desktop run and severe on a phone.

Read as window units, `scale` drew the panel three times too large on a 3× phone
(128 px instead of 42) and put its top edge about a hundred pixels **below the
bottom of the game frame**, down in the touch-controls deck. The scale is taken
from the playfield rectangle instead — `gameWidth / Display.W` — which is the
number that matches the origin it is added to, and which is what the Gen 2 port
has always used (`unit = vp.gameWidth / 160`). That is the **fallback**. On Gen 3
the scale comes from the renderer, which is the next section.

#### The panel is placed against the box the frame was DRAWN at

MARGIN draws in window space, so it has to know where the dialogue box is on the
screen — and the rect `render.hud` hands it **is not always that rect**:

| | where it comes from | how it is fitted |
| --- | --- | --- |
| **reported** | `Game3:_drawHud` → `Display.fit(w, h)` (`src/core/game3/display.lua:50`) | centred in **48 % of the SAFE AREA**, scale from the **width alone** |
| **drawn** | `Renderer:endFrame` → `Renderer:frameRects()` | fitted into `Playfield.cutout` — the **touch skin's** viewport, a **fraction of the WINDOW** — scale from **both axes** |

Two different computations, and they agree only when no touch skin is selected —
which is why this was invisible on a desktop and on every viewport the test suite
had. `.probe/dp3_hudframe_probe.lua` drives both sides headlessly and measures the
distance between the two box tops:

| layout | reported box top vs drawn |
| --- | --- |
| desktop 1280×720, no skin | +0.00 game px |
| portrait 360×780 @3x, skin deck 0.50, notch | +1.50 |
| portrait 360×780 @3x, skin deck 0.50, no notch | −6.00 |
| portrait 360×780 @3x, skin deck 0.62, no notch | **−41.00** |
| portrait 360×780 @3x, skin deck 0.35, no notch | **+38.00** |
| portrait 412×1000 @3x, skin deck 0.50, notch | +0.40 |

A panel placed `MARGIN_PAD` game px above the *reported* box therefore sat
anywhere from **33 game px inside the real box** to **46 game px above it** —
the range measured when the constant was 8; at today's 4 it is 37 inside to 42
above, which is the same fault scaled down — depending on the skin, which is both
halves of the report, "the gap is too big" and "the box is way up". The mod never
moves the box: `DLG_TOP` and `DLG_H` are read-only here,
and the only writes to the dialogue chrome are horizontal, inside FRAMED. It was
measuring the wrong one.

MARGIN is the **only** layout that can be wrong about this, and that is not a
coincidence: INSET and FRAMED draw *inside* the canvas, where the box is wherever
Chrome says it is. MARGIN is the one layout that has to reproduce the renderer's
arithmetic from outside, so it now asks the renderer. `frameRect` calls
`Renderer:frameRects()` and takes the **UI** rect — `uox`/`uoy`/`uvpw`/`uvph`,
where `endFrame` blits `self.canvas`, the surface the dialogue box is drawn into
— and not the world rect `ox`/`oy`, which is the same numbers only while the UI
scale equals `fitScale` (UI LAYOUT = CENTERED, the default). The `render.hud`
payload stays, as the fallback it is: a payload with no renderer behind it — Gen
1/2, or an older engine — still gets the documented rect and the documented
scale.

**The module has to be reached through `require`, and that is not a style
choice.** A mod does not run against `_G`: the loader builds its environment with
`Sandbox.envFor` and `setfenv`s the entry chunk into it, and the `package` in
that environment is `LegacyCompat`'s **`packageShim`**
(`src/mods/LegacyCompat.lua:835`) — a decoy whose `loaded` is a **fresh empty
table**. So `package.loaded["src.render.Renderer"]` is `nil` in the game and the
engine's real table only in a suite compiled against `_G`. 1.8.0 used
`package.loaded`, so its lookup silently returned `nil`, fell through to the
fallback, and the fix did not run — which is exactly the bug 1.8.1 fixes, and why
the suite now builds the mod the way the loader does rather than against `_G`.
`require` is the route the sandbox sanctions (`sandboxedRequire` calls
`pcall(_G.require, name)`) and answers with the same singleton the engine
initialises.

### OFF

Vanilla. The box and the text are byte-identical to an unmodded game.

---

## Which picture you get

This mod ships **no art**. Every portrait is cut, at runtime, out of the battle
art the engine extracted from your own ROM. Both sources are 64 × 64:

| Source | Module | What it is |
| --- | --- | --- |
| Trainer front pic | `src.core.game3.trainer_pic` → `TrainerPic.front(picId)` | the 64×64 bust the game shows in a trainer battle |
| Species front pic | `src.core.game3.pokemon` → `Pokemon.frontPic(index)` | the 64×64 front sprite |

The resolution order, first hit wins:

1. **Your own art**, if you supplied it — `CustomArt/<name>.png` or
   `CustomArt/<sprite>.png`. See *Custom art* below.
2. **A name the dialogue itself used** that is a trainer's own name — exact.
   (The rival is the one speaker this cannot answer for, and he is resolved
   between here and the next step; see *The rival* below.)
   A name in a box is not always the name of the person standing there, so this
   step is **skipped when the speaker's own graphic has already declined** — see
   *A name in a box is not a person* below.
3. **The cart's own trainer id, read out of the object's own script.** This is
   the route 1.9.3 added, and it is the one that answers "which trainer is
   this?" exactly. The map event does not carry the trainer class — the
   extractor keeps the object's `scriptKey` and drops `trainerType` — so the
   mod ships its own table, `art/trainer_ids.lua`, mapping a script's own key to
   the cart's numeric trainer id. See *The script names the trainer* below.
4. **Where that graphic is standing** — the map the player is on, through
   `art/map_art.lua`. This is the step 1.9.5 added, and it exists because step 3
   needs a table the game *generates*: when that table is not there, every
   trainer falls past step 3 and lands on step 5, which holds one value per
   graphic. The map can tell them apart, because it decides which class is
   standing here. See *Where the graphic is standing* below.
5. **The cart's own graphics id** the object carries — `eo.graphicsId`. This is
   the step that tells two people apart when the sprite vocabulary cannot: the
   host maps several FRLG graphics onto one sprite and drops the rest onto a
   Youngster, so the graphic is what says a Hiker is not a PokéFan and which of
   the eight gym leaders sharing a class is standing in the room. It answers
   with an exact front-picture id, a name resolved through the trainer pack, or
   **no portrait** where the cart never drew the person a battle bust. See *The
   graphic is not the sprite* below.
6. **The trainer class** the object carries, translated to its picture through
   the engine's own trainer pack. Only *battle* objects carry a class, so this
   answers for every trainer the player talks to — and it is a fallback for the
   ones step 3 could not name, not the first word on the subject.
7. **The object's own overworld sprite**, for the people who are not battle
   objects. This is what gives the ordinary townsfolk a face: a map object that
   is not a trainer carries no class, so its `SPRITE_*` id is the only thing
   naming it, and a sprite whose id names the same kind of person the cart drew
   IS that picture — `SPRITE_LASS` is the Lass, `SPRITE_SAILOR` is the Sailor,
   `SPRITE_HIKER` the Hiker, and so on. A handful of sprites also name a story
   character outright (`SPRITE_OAK` → the professor, `SPRITE_BLUE` → the rival).
8. **A Pokémon's own front pic**, for a species the text names — `"PIKACHU: "` —
   or one the object's graphics id names. See *Pokémon in the world* below.

Step 5 also closes step 7 rather than only outranking it. If the host's table has
no mapping for the object's graphics id, the sprite the object carries is the
host's own **fallback** — it is not evidence about who is talking — so the sprite
route is skipped and the portrait declines. Without that, declining a Fat Man's
face would just hand back the Fisherman the fallback pointed at.

Step 4 sits *below* step 3 on purpose, and the ordering is measured rather than
assumed: the map and the man's own id disagree for **17 of the game's 432 trainer
objects** — a Route 16 Biker standing among Hikers, a Kindle Road Cooltrainer
among Black Belts — and in every one of those the cart named that man himself, so
the id is the fact to believe. See *Where the graphic is standing* below.

#### A name in a box is not a person

Step 2 takes a name in the dialogue at its word, because that is what makes a
script that hands off between two characters box by box come out right — the
speaker's graphic stays the same while the name in the box changes. But FRLG
writes a name into a box for reasons other than "this is who is talking".

The reported case is the fat man on Fuchsia City's first object. His box opens:

> `ERIK: Where's SARA? I said I'd meet her here.`

**ERIK is a real trainer** — id 177, a SUPER NERD, whose picture 89 is a man in a
white lab coat. That is the "Scientist portrait" that was reported on a fat man.
But the fat man is not Erik, and is not a trainer at all: he wears gfx 27, and
`GFX_ART` says of that graphic, deliberately, that the cart drew no battle bust of
this person. A name in a dialogue box cannot make a picture exist.

So step 2 does not get to overrule a graphic that has already **declined**. A
`false` entry in `GFX_ART` is the cart's own statement that this person has no
bust, and the name route now reads it:

```lua
local gfxDeclines = speaker.gfx ~= nil
  and GFX_ART[speaker.gfx] == false
  and not speaker.species
if speaker.name and not gfxDeclines then
  ...
```

Everything else is untouched. A graphic that **answers** still takes the name
first, which is what keeps the hand-off case working, and a species named in the
text is not a graphic question at all (it is resolved before this runs).

**The guard is narrow on purpose, and that is measured.** A sweep of every line of
every object in the game (`.probe/dp3_name_hijack.lua`) walks **1648 objects**,
finds **52** that name someone, and **4** non-trainers whose name resolves to a
trainer's picture. Two of those four are **Lorelei** and **Selphy**, who really
are the trainers they name and keep their faces. The other two are suppressed. The
same sweep checks the converse and finds **0** trainers whose name route disagrees
with their own id, and **0** objects where the name disagrees with the graphic it
rides on — which is why the name route is still ahead of the graphic route rather
than deleted.

Sweeping rather than waiting for a report found the second suppressed case:
**Daisy Oak**, in the rival's house, whose box opens `DAISY: Hi, PLAYER!`. The
pack has a DAISY — trainer 526, a **Painter** on Five Island, whose overworld
sprite is `OBJ_EVENT_GFX_LASS`. Daisy Oak is the rival's sister in
`OBJ_EVENT_GFX_DAISY`, and the cart drew no bust of her: the front-pic list is 148
class pictures plus Oak, Red, Leaf, Brendan and May, and none of them is her. She
was wearing a Painter's face. `GFX_ART[76] = false`.

#### The sprite is a uniform, not a person

The question "which portrait goes with this sprite?" has no answer, and the
reason is that a sprite is a **uniform**. Uniforms are shared.

`OBJ_EVENT_GFX_ROCKER` (26) is the yellow-haired figure. The game puts it on
**28 trainer objects: 18 Bird Keepers, 9 Jugglers and exactly one Rocker** —
three classes, three different battle pictures (104, 102 and 101), one sprite.
**16 of the 34 graphics a trainer can wear are shared that way**, by two or more
classes whose pictures differ. So a table from sprite to portrait would have to
be wrong for most of the people wearing those sprites, and any build that had one
would be *guessing* rather than reading.

The fact that does decide it is the trainer's own **id**, which the cart keeps in
his script, and the chain is:

```
object's script  ->  trainerbattle (0x5C)  ->  trainer id  ->  class  ->  front pic
```

So this mod applies two rules, not one:

* **A trainer gets his own picture**, by id, through the script route below.
  That is the only route that can tell the eight Super Nerds from the fourteen
  Scientists, or the eighteen Bird Keepers from the one Rocker. Measured across
  the whole game: **432 trainer objects, 0 of them showing a portrait that is not
  their id's own front pic**.
* **A non-trainer has no trainer data at all.** He is not in the pack, so there
  is nothing to read, and his sprite is the only fact about him there is. He gets
  **one consistent picture per graphic**, from `GFX_ART`.

The rest of this section is the script route for trainers; *The graphic is not
the sprite* below is the per-graphic table for everybody else.

#### The script names the trainer

A trainer's class is the one fact the mod needs and the map event does not carry.
The extractor keeps `localId, graphicsId, x, y, elevation, movementType,
movement, range, scriptKey, flag` (`src/import/gba/map_tree_extract.lua`) and
nothing else, so the object's `trainerType` field — where the cart keeps the
class — is dropped on the way in. Until 1.9.3 the mod made do with the one fact
it *did* have, the overworld **sprite**, and read the class off that. A sprite is
shared, so that is a guess, and it is wrong exactly where two classes share one
graphic — which is where all three of the reported cases were:

| what | sprite | who wears it | was drawing | draws now |
| --- | --- | --- | --- | --- |
| Leslie | `SCIENTIST` | 8 Super Nerds (pic **89**) + 14 Scientists (pic 107) | **107** | **89** |
| the twins | `LITTLE_GIRL` | 8 Twins (pic **127**) | **84**, the Lass | **127** |
| the old bald man | `OLD_MAN_1` | 6 Gamers (pic **97**) + 24 ordinary old men | **34**, the karate instructor | **97** |

The engine has its own route to a trainer's id — `TrainerSight.getTrainerId`
looks the object's script up in the extracted script bundle — and this mod does
not use it, because the bundle only covers island 1's eighteen maps and a probe
over all **432** trainer objects in the cart shows it answers for **15** of them.
The other 417 have a `scriptKey` that is simply not in the bundle.

So the mod brings its own answer. A `scriptKey` is `Opcodes.key(scriptPtr)` — the
script's own address — and the trainer's id is the two bytes just past the
`trainerbattle` opcode at the head of that script. `.probe/dp3_emit_trainer_ids.lua`
walks all 425 maps, digs that out of the cart, and writes **`art/trainer_ids.lua`**:
432 script keys, each naming exactly one trainer id, with no conflicts. The mod
loads it through `mod:read`, and the route is `scriptKey` → trainer id → that
trainer's own front picture, through a `byId` index over the engine's own pack.

Two things about it are deliberate:

- **It runs before the graphics table.** That is not just a priority, it is a
  second fix: the graphics table *declines* some ids on purpose — a Man or a
  Balding Man has no battle bust — and a decline there also stops the sprite
  route, so the twelve Tamers, Young Couples and Engineers wearing those sprites
  had no portrait at all. The script route answers first and they get their own
  faces.
- **It only ever reads.** `eo.trainerId` is never written back, so the engine's
  own trainer sight and Vs. Seeker are left exactly as they were. This mod does
  not get to change when a trainer spots you.

A key the table does not carry leaves the object exactly as it was, which is how
the gym leaders still work: their battles are not plain `trainerbattle` stubs at
the head of the object's script, so they are not in the table, and the graphics
route still picks the eight of them out one by one.

Two values in the cart mean "none" rather than a picture, and this mod treats
them that way: **class 0** is what every map object that is not a trainer
carries (`trainerType` defaults to 0), and **picture 0** is the null picture the
cart's empty trainer record points at. Neither is a mapping, so a sprite with no
class behind it resolves to *no portrait* — not to picture 0. That is not a
pedantic distinction. `0` is truthy in Lua, so an index that asks only "is this
a number?" answers picture 0 for every ordinary person in the game, and every
one of them wears the same face.

The sprites the cart never drew a battle face for — the Nurse, the Clerk, Mom,
Bill, the Teacher, the Chef, the Policeman, the three generic women — are
deliberately **not** mapped to the nearest-looking class, because a wrong face is
worse than no face. Give those a portrait with `CustomArt/`
(`CustomArt/SPRITE_NURSE.png` and friends).

**The old folks are not on that list, and 1.9.1 is why.** They were, and it was
wrong: `SPRITE_GRAMPS` and `SPRITE_GRANNY` are in neither table, so an old man
and an old woman resolved *nothing at all* — while the cart had drawn them both,
as the **EXPERT** pair, pictures 34 and 35. 1.9.1 maps all four old-people
graphics to those two pictures, which between them cover **45 objects**: the most
common people in the game after the youngsters. The lesson is worth keeping: "the
cart never drew them" is a claim to check, not to assume, and the check is
`.probe/dp3_pic_names.py`, which names every front picture the cart carries.

**1.9.3 corrected what those four map to, and it was the same lesson twice.**
`SPRITE_GRAMPS` was sent to picture 34 — the old karate instructor — on the
reasoning that "the old man" is the Expert. The cart disagrees: it draws **two**
old men, and they are different people.

| graphics id | the cart's own name | who wears it | picture |
| --- | --- | --- | --- |
| 32 | `OLD_MAN_1` | **6 Gamers** + 24 ordinary old men | **97** |
| 33 | `OLD_MAN_2` | the same split | **97** |
| 34 | `OLD_MAN_3` | the same split | **97** |
| 35 | `OLD_WOMAN` | the EXPERT F's, 21 objects | **35** |

Picture **97 is the bald old man in the blue robe** — the `old_man_1` overworld
sprite, drawn to match it — and picture 34 is a man in a white gi. So the old
bald man the report names was wearing the karate instructor's face because the
table guessed "old man → Expert" instead of asking which picture the cart gives
the old man's own graphic. The Gamer is the trainer family there (6 rows); the
other 24 are ordinary NPCs with no class at all, and for them picture 97 is still
the right answer — it is the cart's own old man.

### The graphic is not the sprite

The mod's `SPRITE_ART` table answers from an object's overworld `SPRITE_*` id,
and on Gen 3 that id is **not** the cart's own `OBJ_EVENT_GFX_*`. The engine
maps one onto the other in `src/core/game3/scripting/gfx_ids.lua`, and that map
is **many-to-one and partial**:

| | |
| --- | --- |
| **Collapse** | `[25] MAN` and `[56] HIKER` are both `SPRITE_POKEFAN_M` — two people, one sprite — and so was `[30] BALDING_MAN` until 1.9.4, when it turned out the cart *had* drawn him (see below) |
| **Drop** | every id the table does not list is answered by the fallback at `gfx_ids.lua:75` — `TO_SPRITE[id] or "SPRITE_YOUNGSTER"` |
| **Wrong kind** | `[39] CAMPER` → `SPRITE_YOUNGSTER` and `[40] PICNICKER` → `SPRITE_LASS` — the sprite names a *different* person, so the route answers confidently and wrongly |
| **One sprite, many people** | `[26] ROCKER` → `SPRITE_ROCKER`, and the graphic is worn by 18 Bird Keepers and 9 Jugglers as well as the one Rocker |

All three showed in play, as one complaint. A Hiker wore the PokéFan's face, and
so did a Man and a Balding Man — picture 32 is a **boy**, so a grown man and a
bald one were wearing a child's. A Camper wore a Youngster's face and a Picnicker
a Lass's. And every graphic with no entry — the Bug Catchers, the Rockets, the
Swimmers, the Tubers, the Channeler, and **every gym leader and Elite Four member
standing in their own room** — wore a Youngster's.

The third row is the one 1.9.0 missed, because it is neither a collapse nor a
drop: the host *does* map the graphic, to a sprite that names somebody else. It
is also the row that hides the **sex** errors, which are the same shape one level
down — `SPRITE_COOLTRAINER_M` and `SPRITE_COOLTRAINER_F` both name the class
COOLTRAINER, so both resolve through the class-name lookup to the **lowest** id
with that name, whose single row is picture **8, a male**. A female Cooltrainer
was wearing a man's face, and a male Tuber a girl's.

The object carries the more specific fact already: `eo.graphicsId`
(`src/core/game3/objects.lua:138`, `:163`). A graphic is one person or one
uniform; a class can cover eight gym leaders **or both sexes of one kind**. So the
graphics id is consulted **before** the class, through the mod's own `GFX_ART`
table:

| value | meaning | example |
| --- | --- | --- |
| a **number** | an exact front-picture id | `[85] = 122` — Sabrina |
| a **string** | a name, resolved through the pack exactly as `SPRITE_ART`'s values are — a trainer's own name first, a class name second | `[74] = "LANCE"` |
| **`false`** | the cart never drew this person a battle bust | `[27] = false` — the Fat Man |

The `false` entries are six graphics that were wearing somebody else's face: the
Fat Man the Fisherman's (`:18` sends him to `SPRITE_FISHER`), a female Worker the
Scientist's (`:29` → `SPRITE_SCIENTIST`), Celio the Super Nerd's
(`:45` → `SPRITE_SUPER_NERD`), the Man the PokéFan's (`:25` → `SPRITE_POKEFAN_M`,
whose picture is a boy), and — added in 1.9.4 — **Daisy Oak** (`:76`, who was
wearing a Five Island Painter's face through the name route; see *A name in a box
is not a person*).

The Balding Man was on that list too, from 1.9.1, on the reasoning that he shares
`SPRITE_POKEFAN_M` with the Man. **That reasoning was wrong**, and 1.9.4 is where
it was measured rather than assumed:

| graphics id | the cart's own name | who wears it | picture |
| --- | --- | --- | --- |
| 30 | `BALDING_MAN` | **all 3 Engineers** + 28 ordinary NPCs | **93** |

Every one of the game's three Engineer objects wears gfx 30 — Braxton on Route 11,
Baily on Route 11, and the Engineer in Vermilion Gym — and **no other trainer
class wears it at all**. It is the cart's own overworld sprite for the Engineer,
and picture 93 is the cart's bust of him: a hard hat, a wrench and a toolbox. So
the 28 non-trainers sharing his sprite were not wearing a wrong face, they were
wearing **no face**, and the fix is one graphic, one person, one picture.

### One sprite, many people

Four graphics were answering with the wrong person, or with nobody. Each now
carries its **majority class** — the kind most of its wearers are — and each answer
is what the cart's own art shows for that class:

| graphics id | the cart's own name | who wears it | was | now |
| --- | --- | --- | --- | --- |
| 26 | `ROCKER` | **18 Bird Keepers**, 9 Jugglers, 1 Rocker, + 8 NPCs | 101 (the Rocker) | **104** (the Bird Keeper) |
| 17 | `LITTLE_GIRL` | **8 Twins** + 18 ordinary girls | 84 (a Lass) | **127** (the Twins) |
| 55 | `SCIENTIST` | **8 Super Nerds**, 14 Scientists, + 31 NPCs | *unset* → 107 by the sprite route | **107** (the Scientist) |
| 28 | `WOMAN_2` | **4 Aroma Ladies**, 3 Breeders, 2 Ladies, 1 Lass, 1 Scientist, + 18 NPCs | *unset* → **nothing at all** | **144** (the Aroma Lady) |

The last two rows are 1.9.5's. Both graphics were answering *somebody else* or
*nobody*: gfx 55 is the **lab coat**, which the host calls `SPRITE_SCIENTIST`, so a
Super Nerd on it wore the Scientist's picture 107 — the reported "Super Nerd
displays the wrong portrait". gfx 28 had no entry at all, so the Aroma Lady's own
NPCs wore nothing. Each now carries its **majority class**, so the fallback is at
worst the most common wearer rather than a different class or a blank — and the
Super Nerds and Aroma Ladies themselves are answered exactly, by id or by map.

`OBJ_EVENT_GFX_ROCKER` (26) is the **yellow-haired** figure, and its art is picture
104's: yellow hair, a red shirt and blue overalls. Picture 101 — the Rocker — is a
blue-haired punk in an orange jacket, and the two share nothing but a jacket
colour. The host calls gfx 26 `SPRITE_ROCKER`, so the sprite route handed the
Rocker to everybody on it, which is the reported "the yellow-haired trainer sprite
sometimes shows the Rocker portrait and sometimes the Bird Keeper portrait". It
shows both because the graphic is worn by both — and now the **28 trainers** on it
get their own ids from the script route while the **8 non-trainers** get the
majority wearer, the Bird Keeper.

`OBJ_EVENT_GFX_LITTLE_GIRL` (17) is the **red-haired little girl**, and she is one
of the **Twins**. The host calls her `SPRITE_LASS`, so every non-trainer girl on
the graphic wore a Lass's face — picture 84, orange hair — which is the reported
"the red-haired little girl sprite, which is actually one of the twins". Picture
127 is the Twins, and the crop table cuts it down to one girl (see *Two people in
one picture*), which is what both halves of that pair want and what the 18
ordinary girls on the graphic want too.

### Where the graphic is standing

A graphic is a uniform, and uniforms are shared — so the same figure can be a
Juggler in one building and a Bird Keeper on the road outside it. The rule that
settles it is **the map**, and 1.9.5 ships it as `art/map_art.lua`: for each map,
the picture each graphic's *own trainers* resolve to.

| map | graphic | the map's answer |
| --- | --- | --- |
| `FR_ROUTE_12` | 26 | **101 Rocker** |
| `FR_ROUTE_13` | 26 | **104 Bird Keeper** |
| `FR_FUCHSIA_CITY_GYM` | 26 | **102 Juggler** |
| `FR_ROUTE_8`, `FR_MT_MOON_1F` | 55 | **89 Super Nerd** |
| `FR_SILPH_CO_2F` | 55 | **107 Scientist** |
| `FR_THREE_ISLAND_BOND_BRIDGE` | 28 | **144 Aroma Lady** |
| `FR_SIX_ISLAND_PATTERN_BUSH` | 28 | **141 Breeder** |

The table is generated by `.probe/dp3_emit_map_art.lua`, which walks every map in
the cart and records the picture each graphic's trainers resolve to: **91 maps, 228
graphic → picture pairs**, of which **11 are splits** — one graphic worn by two
classes *on the same map* — where the majority class wins and the comment names the
whole split so the choice is legible. Keys are engine map ids (`FR_ROUTE_8`),
produced by the engine's own `MapCatalog.pretToEngine`, so they match
`Map.current` exactly; the mod learns the map from the `map.entered` event.

**It runs below the id, not above it.** The map and the man's own id disagree for
**17 of the game's 432 trainer objects** — a Route 16 Biker standing among Hikers, a
Kindle Road Cooltrainer among Black Belts — and in every one of those the cart named
that man himself, so his id is the fact to believe. `.probe/dp3_map_route_yield.lua`
is the measurement.

**What it is actually for.** Measured honestly, the route changes **exactly one
non-trainer in the whole game** — a Lady on Five Island standing among Ladies, 144
→ 146 — and 5 of its 6 answers already agree with what the mod said. Its value is
not correction on a complete boot; it is being the answer **when the cart's trainer
table is missing**. That table is a *generated cache*, and on a boot without it the
id route cannot fire at all, which is the boot this report came from:
`.probe/dp3_loader_read.lua` drives the real engine loader over the real mod
directory and gets **8 of 8** location cases right with **no** trainer table
present.

A species is never asked about the map: a Pokémon standing in the world has its own
art, and the trainers around it say nothing about it.

### Two people in one picture

Five of the cart's front pictures draw **two figures** in the one 64×64 square:

| picture | the pair | left half | right half |
| --- | --- | --- | --- |
| 127 | Twins | one twin (both halves are the same girl) | — |
| 128 | Cool Couple | the boy, in trousers | the girl, in a jacket |
| 129 | Young Couple | the woman, in a skirt | the man, in trousers |
| 130 | Crush Kin | the karate half | the orange half |
| 131 | Sis and Bro | the sister | the brother, drawn lower |

A single window cannot be right for both people, so `art/crops.lua` carries a
**`pairs`** table — a rectangle per half — and a **`pairSide`** table from graphics
id to half. The object's own sprite then picks the half it stands on, so the
Young Couple's woman (gfx 29, BEAUTY) and man (gfx 25, MAN) are cut from opposite
ends of the same drawing and no longer wear the same face. That is the reported
JES and GIA.

`pairSide` is a table of its own rather than nine `gfx:<id>` crop overrides, and
that is the point: a `gfx:` crop is applied to **whatever picture the speaker
resolved to**, and gfx 29 is not only the woman in a Young Couple — it is also
every ordinary Beauty, who wears picture 98 and would be cut with half of picture
129 if this were filed there. A graphic listed in `pairSide` is only ever asked
for a half when the picture it resolved to *is* that pair.

### Pokémon in the world

FRLG puts Pokémon in the world as map objects and names each one with its own
`OBJ_EVENT_GFX_*` id: **109 `SNORLAX`** through **150 `DEOXYS_N`**. Every one of
those ids sits above the **92** the host's `TO_SPRITE` table stops at
(`SPRITE_POKE_BALL`), so all of them arrive as the engine's `SPRITE_YOUNGSTER`
fallback — and that fallback cost the species **twice**:

- the sprite route reads a species off the *sprite* id (`SPRITE_PIKACHU` **is** a
  Pikachu) and a Youngster is not one, so it had nothing to answer with;
- `hostSpriteFor(110)` is `nil`, so the sprite route **declined** — correctly,
  because a boy's face on a Spearow is exactly the wrong-portrait bug step 3
  exists to prevent.

Neither is wrong on its own. Together they meant **no portrait at all** for every
Pokémon standing in the world, which is the reported Spearow. The cart's own
graphics id is the fact left over, and it names the species outright, so
`GFX_MON` reads it: ids 109–150 → host species keys, with the three Deoxys forms
folded onto one species.

**32 of the 42 ids are actually placed** somewhere in the game — measured across
425 maps by `.probe/dp3_nonpeople_sweep.lua`, which found 513 objects carrying a
graphics id of 92 or above — and the whole range is mapped anyway, because the
mapping is exact for every id and `OBJ_EVENT_GFX_VAR_*` can place any of them at
runtime.

### The class is not the picture

This is the one thing Gen 3 does that the other generations do not, and it is
worth knowing even if you never read the code.

**FRLG keeps a trainer's class and their front picture in two different number
spaces.** A map object carries only the class (`trainerType`); `TrainerPic.front`
indexes the *picture* table. So handing a class id to the picture loader does
not fail — it returns whichever picture happens to sit at that index, which is
somebody else's face.

| Class | Name | Picture |
| --- | --- | --- |
| 17 | GUITARIST | 17 |
| 24 | LEADER | 26, 27, 28, 75…79 *(Hoenn, unused in FRLG)* |
| 49 | LASS | 65 *(Hoenn — listed first, and the trap)* |
| 59 | LASS | **84** *(the Kanto lass)* |
| 81 | RIVAL_EARLY | **106** |
| 89 | RIVAL_LATE | 124 |
| 84 | LEADER | 108, 116…122 *(the eight Kanto leaders)* |
| 87 | ELITE FOUR | 112…115 |
| 97 | POKéMON PROF. | **132** |

Class 17 is its own picture and class 81 is not, which is exactly why the
mistake is easy to miss: it looks right for the low-numbered classes and is
silently wrong from about class 22 up.

**And 31 of the cart's class names are spelled twice.** FRLG carries its whole
Hoenn roster first and repeats those names for its own Kanto classes further
down — `LASS` is 49 *and* 59, `FISHERMAN` 31 and 69, `BEAUTY` 12 and 73,
`SAILOR` 41 and 60, `BLACK BELT` 16 and 80, `GENTLEMAN` 22 and 88, `YOUNGSTER`
29 and 57 — and the two are different people with different battle art. 1.9.2
resolves a name to the class the cart actually **fields trainers under** rather
than to the lowest id, because that is the class the game uses: `FISHERMAN` is
69 with **15** rows against 31's 1, `LASS` 59 with **26** against 49's 1,
`YOUNGSTER` 57 with **28** against 29's 1 — and of the cart's **742** rows, only
**53** sit under a name's low-id half. Before that, all 31 names
answered the Hoenn class — which is why the girl on Route 3, a class-59 Lass,
wore the Hoenn Lass's picture 65.

Two pairs the row count cannot separate, and neither moves a face. `LEADER` is
8 rows at 24 and 8 at 84, and the tie goes to the **higher** id — 84, the Kanto
half — so it lands on the right side anyway; nothing resolves through that name
regardless. `POKéMON TRAINER` is 0 rows at 0 and at 1 and 7 at 44, so it moves
from *no answer* to picture 56, and nothing writes it either. **`RIVAL` is the
pair that would have moved a face**: classes 81 (picture 106) and 89 (picture
124) are both spelled `RIVAL`, 89 carries the rows, so the name now resolves to
**124** — a
change nothing reported and 1.9.0 verified as 106. So the rival is never resolved
by that name: his picture is pinned as the constant `RIVAL_ART`, and the three
routes that used to write `"RIVAL"` write the number instead.

So the class is **exchanged** for a picture through the engine's own extracted
trainer pack, which is the only place that knows both halves. Two consequences:

- **83 of the 106 classes the cart uses pin exactly one picture**, so for those
  the exchange is exact.
- **The rest pin several** — one class covers all eight gym leaders, or four
  Elite Four members. A class alone cannot answer those, so the mod takes the
  picture the most trainers *of that class* use, ties to the lowest picture id.
  This is a tie *within one class*, and it is a different rule from the tie
  across two classes that share a name, above. A class covering one character is
  exact; a class covering eight is one of the eight. The eight gym leaders do not
  rely on this: their **graphics id** resolves them exactly (step 3 above), and
  this fallback is what answers only when the object's graphic is not in the
  table.

**Names are far better behaved.** Of the 428 distinct names in the cart, only
three ever pin more than one picture — so a name the dialogue used resolves
exactly. A name that *is* ambiguous (`GRUNT`) declines rather than guessing,
because a generic name that answers would put the admin's face on every Rocket in
the game.

### The crop table has two key spaces

`art/crops.lua` keys its overrides two ways, and which one to reach for depends
on what actually varies.

**By picture** — `trainers[<front-pic id>]`, `pokemon[<species key>]` — is the
general case and the right default. Brock and Misty are both class 84 but
pictures 116 and 117, so a class-keyed table could not give them different
framing; and picture 85 is reached by the cart's graphics id 62 *and* by class 60
for the battle rows, so one rectangle filed against the picture covers the Sailor
on the pier and the Sailor in a battle with the same line.

**By speaker** — `speakers[...]` — is the escape hatch for the case a picture key
cannot express: **two speakers who share a picture and are not framed the same
way.** A picture key would reframe both of them. The four prefixes are tried most
specific first, which is the same order the speaker itself is resolved in, and a
**speaker key always beats a picture key** — a statement about one person
outranks a statement about everyone who shares their face:

| key | matches | example |
| --- | --- | --- |
| `name:<NAME>` | the name the dialogue used | `name:OAK` |
| `gfx:<id>` | the cart's own graphics id | `gfx:57` |
| `sprite:<SPRITE_*>` | the map object's sprite id | `sprite:SPRITE_OAK` |
| `class:<id>` | the numeric trainer class | `class:69` |

There is deliberately **no `species:` prefix**: for a Pokémon the species *is* the
speaker, so the `pokemon` table was always an interaction table and a species key
is already a speaker key.

A malformed entry is **ignored rather than obeyed** — a table with a missing or
non-numeric coordinate falls through to the next key instead of becoming a
one-pixel window that draws a portrait nobody can see.

To find a picture's id: read it off the cart's trainer table (each record is
0x28 bytes, the class at offset +1 and the picture at offset +3), or note what
the mod's own `picForClass` / `picForName` resolve to. That same table is how you
tell **which speakers share a picture** before reaching for a speaker key — and
the cart's sprite/graphics ids are the wrong tool for that, because several
people can share both.

---

## Portrait art status

`art/crops.lua` holds **one framing rule for everybody** plus the
per-character overrides. The overrides are sparse — the defaults answer for
almost everyone, and only a character whose face is off-centre needs an entry:

| Kind | Keyed by | Rectangle `{ x, y, size }` |
| --- | --- | --- |
| `trainers` (default) | — | `{ 16, 3, 32 }` |
| `pokemon` (default) | — | `{ 16, 17, 32 }` |
| `trainers[<pic>]` | front-pic id | e.g. `["85"] = { 12, 0, 32 }` — the Sailor |
| `pokemon[<species>]` | species key, lowercased | e.g. `["pikachu"] = { 17, 2, 32 }` |
| `pairs[<pic>]` | front-pic id, `left` / `right` | e.g. `["129"] = { left = {0,4,32}, right = {32,2,32} }` — the Young Couple |
| `pairSide[<gfx>]` | graphics id | `[29] = "left"` — the woman in a Young Couple |
| `speakers[<key>]` | the person, four prefixes | — |

The defaults are 32 px squares taken out of a 64 × 64 source, so they fill the
32 px slot — and FRAMED's content rect — **1:1, edge to edge**, which is 1.9.0's
change: 1.8.x's windows were 30 px and were centred in a 32 px rect, so every
portrait shipped with a one-pixel margin all the way round. The growth is one
pixel on *every* side rather than a new framing, and each new default has the same
centre as the 30 px window it replaces — `(17, 4, 30) → (16, 3, 32)` and
`(17, 18, 30) → (16, 17, 32)` — so a portrait framed correctly in 1.8.3 is framed
identically now. The trainer window is centred a little above the middle, which is
where a Pokémon trainer's face sits in a battle bust; the species window sits
lower, which is where a species front sprite's face is.

`pokemon` is keyed by the engine's own species key — the display name folded
through `Pokemon.keyName` and lowercased — which is **not** the display name for
four of the cart's species: `NIDORAN♀` is `nidoranf`, `NIDORAN♂` is `nidoranm`,
`MR. MIME` is `mrmime` and `FARFETCH'D` is `farfetchd`. 1.9.0 is what folded them:
until then the key was the display name lowercased, so an entry filed for any of
those four could never fire. Two of the four — the Nidoran — are among the species
that speak.

The table is still written from measurement rather than invented. 1.9.5 ships **10
trainer pictures** — 7, 35, 66, 82, 83, 85, 86, 95, 105 and 140 — **31 species**,
and **nine pair halves** (127, 128, 129, 130, 131).
The species half grew from the 19 that *speak* to the 32 the *world places* in
1.9.2, because that release gave every Pokémon map object a portrait (see *Pokémon
in the world*): the default window (rows 17–48) frames a whole creature's body and
most of those 32 have artwork starting above row 17. Voltorb is the one placed
species with no entry — the default frames a whole ball with both eyes in.

**1.9.3 re-measured seven species and one trainer picture, and every one of them
was the same mistake: the rule centres the creature's own box, and the box was not
the face.**

| species | old window | new | what the old one framed |
| --- | --- | --- | --- |
| **Fearow** | `{32,0}` | `{0,20}` | **a wing. No face at all.** Its head is at the bottom left |
| **Pidgeot** | `{15,0}` | `{0,3}` | a wing; the eye and beak were cut off the left edge |
| **Zapdos** | `{16,0}` | `{0,6}` | a wing; the head and beak are at the left |
| **Moltres** | `{13,0}` | `{0,30}` | a wing; the head and beak are at the **bottom** left |
| **Articuno** | `{17,0}` | `{1,0}` | a wing; the eye sat on the left edge |
| **Slowbro** | `{15,7}` | `{4,7}` | the Shellder clamped to its tail — the muzzle was cut off the left |
| **Nidorino** | `{15,5}` | `{11,14}` | the ears; the muzzle was cut off the bottom |
| **Bug Catcher** (pic 66) | default | `{10,9}` | the hat's left brim, with the face against the edge |

The four birds are the interesting ones, because 1.9.2's own comment said the
legendary birds were "centred on the FACE instead" of on their wings — and only
Snorlax and Slowpoke actually were. All three birds were filed at `x 13–17, y 0`,
which is the wing on every one of them. A rule written down is not a rule applied,
and the only check that catches it is rendering the window over the whole sprite
and **looking** at the result, which is what **`.probe/dp3_frame_compare.py`** now
does: it draws the candidate window over the 64 × 64 source and shows the crop
beside it.

**1.9.5 found one more of the same shape — Seel, the reported "not framed
correctly" — and then found that its own first fix had been measured on the wrong
picture.**

| species | rule's own answer | first 1.9.5 cut | shipped |
| --- | --- | --- | --- |
| **Seel** | `{13,5}` | `{4,4}` | `{12,21}` |

A species portrait is the engine's own front pic: `speciesArt` hands
`record.index` to `Pokemon.frontPic`, and SEEL's internal species id is **86**, not
87. `frontPic(86)` is byte-identical to `.probe/_art/mon-86.png` — proved by
`.probe/dp3_seel_engine.lua`, which wraps the LÖVE stub's constructors and keeps
the engine's own rgba. `mon-87` is **Dewgong**, whose head does sit at the top
left, and that is the sprite the first cut was measured on.

Seel's own sprite is drawn **front-on with the face low**: the whole creature is
one mass, bbox `(6,9)-(53,54)`, the muzzle is the only tan mass, bbox
`(18,42)-(34,51)`, the tongue the only red one, bbox `(20,47)-(27,52)`, and the
two eyes the only dark blobs inside the silhouette — all three located by colour in
`.probe/dp3_seel_face.py`. So the rule's own answer — the box centre on x, four
rows above the first opaque row — is `{13,5,32}`, which frames the two lobes at the
top and the upper body with the **whole face below the window**; and `{4,4,32}`,
measured on Dewgong, framed a top lobe. The sprite is 44 rows tall and 32 cannot
hold it, so the face wins: `{12,21,32}` holds the eyes, the whole muzzle and the
whole tongue, whose last row stops exactly at the bottom edge.

The trainer picture was found by the same sweep run over **all 147** trainer front
pics at once (`.probe/dp3_trainer_sheet.py`) rather than by trusting a density
number. It is the only one that needed a rectangle; the other 146 frame their
subject correctly with the default. Every species was checked the same way and the
24 that were right were left alone — a rectangle that only restates the rule is a
line that can drift out of date.

**1.9.4 re-measured every window in the table — 50 of them, across the two
defaults, ten trainer pictures, 31 species and nine pair halves — on all four
edges**, with `.probe/dp3_crop_framing.py`, which reads the numbers out of
`art/crops.lua` rather than copying them. The 147 trainer pictures and 31 species
that 1.9.3 had already looked at were **not** re-checked by eye: this is the
mechanical pass that says which ones need an eye at all, and it flagged none. Two
windows were still wrong, and both were found by **looking** rather than by the
sweep:

| window | was | now | why |
| --- | --- | --- | --- |
| picture **127** left | `{0, 10, 32}` | **`{2, 10, 32}`** | The left Twin's head runs to column **33** and her sister's begins at **35**, so a window at 0 stops at 31 and cuts **two columns off her face**. 2 is the only 32 px span that holds all of her and none of her sister. |
| picture **130** right | `{32, 2, 32}` | **`{32, 0, 32}`** | Her ponytail's red band reaches row **0**, so a window starting at 2 cut the top of it. |

**The sweep missed the first one, and that is worth writing down.** The first
version of `.probe/dp3_pair_framing.py` tested the **top** edge only, and its
docstring said so in prose that read as if it tested them all; the left Twin's two
cut columns were on her **side**. It was caught by eye, in
`.probe/_fc194b/127L.png`. The rewrite reports all four edges and the seam column,
and its docstring now states plainly what it **cannot** decide: *"cut at the seam"
and "cut the subject's own side" are identical to a pixel test* — both are an
opaque edge column with art continuing past it, and no opacity check knows whether
that art is a sister's hair or your own. So the probe measures and the eye judges,
and the nine pair windows are **pinned by number** in `dp3_geometry_test.lua`,
because a property test ("it fits inside the source") passes just as happily for
the window that cuts her face.

The rule that comes out of it, for anyone adding an entry: **a window that fits
inside the source can still be cutting the face inside it.** Check the number, not
just the bounds.

This rule is a **starting point, not a finished table**. It gets most of them
right and some of them wrong, and which are which is a matter of taste. If a
particular character's face is off-centre, that is what the override tables are
for — see `art/crops.lua`'s own header, which documents both key spaces and when
to reach for each.

---

## Custom art

Drop a PNG in `CustomArt/` and it wins over every ROM route. Two names are
tried, in this order:

```
CustomArt/<name>.png      the name the dialogue used, or the speaker's name
CustomArt/<sprite>.png    the object's own sprite id, e.g. SPRITE_OAK.png
```

So `CustomArt/OAK.png` and `CustomArt/SPRITE_OAK.png` both work for Oak, and
either beats his class pic. See `CustomArt/README.md` for the details,
including how to get a portrait onto a character the ROM has no art for at all.

---

## How the speaker is identified

Three answers, and the text's own is asked first.

**Some of the ROM's own dialogue literally names its speaker** — `"OAK: "` is
extracted verbatim from the cart, not added by a mod. A name found in the text
beats the press lookup below it, because a single running script hands ONE
object to its whole run while the dialogue inside that run can hand off between
two characters box by box.

#### What counts as a name

The prefix is matched with `^([A-Z][A-Z0-9%._%-'♀♂ ]*):` — an uppercase letter
followed by uppercase letters, digits, `.` `_` `-` `'`, the two gender signs, and
spaces, up to the colon. That set is not a guess about English: it is **exactly
what FireRed uses**, and it is wider than it looks because the cart spells four of
its 386 species in a way a tidier class would reject — **`NIDORAN♀` (U+2640),
`NIDORAN♂` (U+2642), `FARFETCH'D` (an apostrophe) and `MR. MIME` (a space)**.
Two of those four speak, so before 1.8.2 both Nidoran resolved no speaker and
drew no portrait. A trailing space is trimmed, so `MR. MIME :` cannot keep it.

**The mod does not normalise the name; the engine does.** `♀` and `♂` are handed
on as they are and folded by the engine's own `norm_key`, because that is the
function that already knows `NIDORAN♀` is `_F`. Folding here would be a second,
disagreeing copy of a rule the engine owns — which is also why the suite's
species stub is keyed by the cart's own spelling, so a future tidy-up in the mod
fails the test rather than passing it.

**The rival is the one speaker the cart never spells out**, and getting him wrong
is what 1.1.0 shipped. His dialogue is *not* written `"RIVAL: "` anywhere in the
ROM: it is written with the placeholder `FD 06` where the name belongs — 28 sites
in the cart put `FD 06` immediately before the colon — and the engine expands
that to whatever **the player typed** before a mod ever sees the string
(`src/core/game3/scripting/ops_a.lua`). So the box arrives reading `"GARY: "`, or
`"BLUE: "`, or whatever the player chose, and no trainer pack can place that
name, because the pack lists the cart's own names. He is recognised instead by
the name on the save — the only place it exists — and resolved through his own
picture. See *The rival* below.

That is also why a name the mod cannot place no longer throws away the object the
press resolved: the object now rides *alongside* the name rather than being
discarded in favour of it, and a name the pack **does** know still wins outright,
so a script that hands off between two characters is unaffected.

**When the text names nobody, the object the A press resolved is asked.** Gen 3
raises the `world.talk` hook for exactly the presses that reach an object with a
script (`src/core/game3/field.lua`), and for nothing else — a sign, a hidden
item and a field move are different branches of the same function and never
raise it. So the hook firing *is* the engine saying "this is a conversation with
somebody". That makes it the precise analogue of Gen 2's `World.talkNpc`, and it
is a real field rather than an inference from the call stack.

**A trainer who challenges you never pressed anything.** FRLG's line-of-sight
trainers see the player and start their script from a *step*
(`src/core/game3/trainer_sight.lua`, `TrainerSight.engage`), and that path raises
no `world.talk` at all — so the press record stayed empty, the resolver had
nothing to answer with, and the *"wants to battle"* box came out bare. This is
why 1.9.0 also listens on `world.trainer_engaged`: the engine emits it from that
same function, with the trainer's own event object, so it names the speaker for
the one box an A press cannot. Recording it is the same act as recording a press,
and every existing way of ending a conversation drops it again. The payload's
`trainerClass` rides along as the fallback for an object whose own `trainerType`
has not been stamped yet, and it is put into a shallow **copy** rather than
written onto the engine's object, because a mod must not scribble on the world.

**The record has an end, and there are three ways it ends.** Walking a step
(`world.stepped`) or entering a map (`map.entered`) drops it — and so does the
conversation's own script finishing (`script.ended`). That third one is not
redundant, because **a turn on the spot is not a step**: turning to read the sign
beside somebody sets the facing and returns without ever reaching
`Player.finishStep`, which is the only place `world.stepped` is emitted
(`src/core/game3/player.lua`). Without it, a player who talked to the rival and
then turned away still had him on record for the next box. A script that *hands
off* to another retires itself first with `completed = false`, and that is the
same conversation continuing, so the record deliberately survives it.

**And a portrait is drawn only for the dialogue frame**, not for every box that
happens to be open. `world.talk` says a conversation started; it does not say
the box on screen is part of one. Every box the engine opens carries its own
frame kind — `setFrame("battle")` for an evolution
(`src/ui/game3/evolution_scene.lua`), `setFrame("sign")` for a sign — and the
portrait is resolved only when that kind is `dialogue`, so those boxes are bare
even with a conversation still on record.

The **egg hatch** is worth naming separately, because it is *not* an example of
that guard. `src/ui/game3/egg_hatch.lua` sets `setFrame("dialogue")`, so the
guard passes and the box is the field box at the field box's own coordinates. It
comes out bare for a different reason: hatching is driven by steps, and a step
has already dropped the press record (`world.stepped`). Earlier versions of this
file and of `mod.card` claimed the egg hatch used the battle frame; it does not.

### The rival

The one speaker in the game whose name is not in the ROM's text, and the reason
1.1.0 gave him no face.

His dialogue carries the placeholder `FD 06` where the name belongs — 28 sites in
the cart put it immediately before the colon — and the engine expands that to
whatever the player typed before `Message.show` ever sees the string. So the box
arrives reading `"GARY: "`, and the name route cannot answer it: the trainer pack
lists the cart's own names, and the player's choice is not among them.

Two things had to change for him:

1. **The name route no longer discards the object.** A box that named somebody
   the pack could not place used to return that name and stop, throwing away the
   object the press had resolved — which for the rival is `SPRITE_BLUE`, a sprite
   the sprite route answers perfectly well. The object now rides *alongside* the
   name. A name the pack **does** know is still tried first and still wins
   outright, so a script handing off between two characters is unaffected; only a
   name that resolves to nothing falls through to the object.
2. **The name on the save is checked.** Both the live session
   (`Runtime.getSession().rivalName`) and the save table
   (`Runtime._game.save.rivalName`) carry it, and a box whose text matches it is
   flagged as the rival and resolved through his own picture. The save is the
   only place that name exists — the cart never writes it, and the pack cannot
   guess it.

Both reads are `pcall`ed like every other engine reach here, because a headless
or half-initialised boot must not turn a portrait lookup into an error. With no
rival name on the save there is no rival and the flag simply does not fire — the
resolution is driven by the save, not by a guess at the name the cart happens to
use in its own text.

`tests/dp3_speaker_test.lua` covers all of it, including the two negative
controls that matter: an unknown name which is *not* the rival still gets
nothing, and a name the pack **does** know still beats the rival's own object.

---

## Compatibility with other mods

- **Load order.** Priority 100, the same as the Gen 1/2 mods. Every hook is
  wrapped, not replaced, and `next` is always called, so this mod composes with
  anything else that wraps `world.talk`, `render.hud`, `Message.show`,
  `Message.draw` or `FrlgFont.draw`.
- **Other portrait mods.** Don't run two portrait mods at once — they will both
  paint, and you will get two faces.
- **Anything that redirects a class's picture.** The class front pic is asked
  for through the engine's own `TrainerPic.front`, so a mod that swaps what that
  returns is followed rather than second-guessed.
- **Re-install safety.** The install is guarded by a sentinel on the `Message`
  module table, so a mod reload leaves the existing wraps in place rather than
  stacking a second copy on top.

---

## What Gen 3 does differently

Worth knowing if you are reading the code after the Gen 1 or Gen 2 version.

**The dialogue box is not `TextBox`.** Gen 1 and Gen 2 share
`src/render/TextBox.lua`, and that is why the Gen 2 port is mostly a rename —
both seams it needs (re-geometry one box; paint over it) exist on both
generations. Gen 3 has its own field text printer, `src/ui/game3/message.lua`,
driven by `src/ui/game3/chrome.lua`'s dialogue frame and
`src/ui/game3/frlg_font.lua`'s variable-width renderer. So the seams are:

| Seam | Why |
| --- | --- |
| `Message.show` | the one funnel every field box goes through — where "who is talking" is decided, once per box |
| `Message.draw` | where the box is painted, once per frame while open |
| `Chrome.DLG_*` | the box's own geometry, read fresh on every draw |
| `FrlgFont.draw` | where the text actually lands |
| `world.talk` hook | the A press that reached an object with a script |

**The geometry arithmetic is redone from scratch**, because the box is a
different box — see the numbers under *Options*.

**The `render.hud` viewport is not a reliable description of the frame.** On Gen 1
and Gen 2 the payload's `gameWidth` *is* `Display.W * scale`, so the two are
interchangeable and both older ports use `scale`. On Gen 3 there are two traps,
and both are invisible on every desktop.

**The units.** `Renderer:endFrame` reports `scale` as `Renderer:fitScale()` —
**integer framebuffer pixels per game pixel** — while `gameX`, `gameY` and
`gameWidth` are LÖVE window units, so `gameWidth` is `Display.W * scale / dpiX`.
The two differ by the display's pixel ratio, which is 1 on a desktop and 2 or 3 on
a phone (`conf.lua` sets `t.window.highdpi` on mobile only). Read as window units,
`scale` puts the panel below the bottom of the game frame on a phone.

**The rect.** The payload is `Display.fit` — centred in 48 % of the **safe area**,
scale from the **width alone** — while the frame is actually drawn by
`Renderer:frameRects()`, fitted into the **touch skin's** cutout (a fraction of the
window) with its scale from **both axes**. The two agree only when no touch skin is
selected, so a desktop never shows it; on a phone the two box positions can be 41
game px apart, and anything positioned *relative to the dialogue box* lands in the
wrong place. Ask the renderer, and take the **UI** rect (`uox`/`uoy`) — where
`endFrame` blits the canvas the box is drawn into — rather than the world rect.

A layout in window space should fall back to `gameWidth / Display.W` — which is
what the Gen 2 port does anyway — only when there is no renderer to ask.

**The trainer class is not the picture.** On Gen 1 and Gen 2 a class resolves
straight to its frontpic; on Gen 3 the class and the picture are different
number spaces and the class has to be exchanged for one. This is the single
biggest difference in the mod and it is covered in *The class is not the
picture* above.

**`engine_internals` is required.** The Gen 3 dialogue printer is not part of
the Gen 1 API facade (`src/mods/Gen3Compat.lua` serves 15 Gen 1 modules and this
is not one of them), so it is required directly. That is what the manifest's
`engine_internals` permission is for, and it is the only engine-internal reach
this mod makes.

**`gen3` is a real target token.** The manifest says `"games": ["gen3"]`, which
the engine expands to `{ firered, leafgreen }`. So this mod loads on both
FireRed and LeafGreen, and on nothing else.

**The per-box geometry swap.** FRAMED changes `Chrome.DLG_W` (and
`Chrome.DLG_LEFT`) for the length of one draw and puts them straight back —
the Gen 2 port's "swap the geometry for one call" trick applied to Chrome's own
constants, which `dialogueFrame()` and `drawText()` both read fresh. The restore
happens on the error path too, so a throw mid-draw cannot leave the box short.

**The text shift is scoped.** INSET's shift lives in the `FrlgFont.draw`
wrapper, guarded by a flag the draw wrapper raises around its own call — so no
menu string, party label or battle line is ever moved, only the dialogue box's
own text.

**The text is wrapped once and clipped somewhere else.** `Message.show`
word-wraps the box's text against `ctx.maxWidth`, defaulting to a hardcoded 208
— the vanilla box's own 26 columns (`src/ui/game3/message.lua`).
`Message.drawText` then *clips* each line at `Chrome.DLG_W * Display.TILE`,
which follows the geometry. Vanilla the two agree, because 208 *is* 26 columns.
Every layout here breaks that agreement, so the mod hands the wrap the layout's
own width as well: `Message.show` supplies `opts.ctx.maxWidth` before calling
the vanilla implementation, which makes it the one place in the mod that reads
the frame from `opts` rather than from `Message.frameKind()`. The two agree by
construction — `Message.show` derives its frame from exactly those opts and
always overwrites it, so there is no sticky frame to miss. The caller's own
`opts` and `ctx` are **copied** rather than mutated, because a script hands the
same table to several boxes and `ctx` also carries the `playerName`/`rivalName`
the text placeholders expand through.

Gen 3 pages the overflow for free: a narrower wrap that pushes a page past the
two lines the box holds becomes a new page on an A press
(`src/core/game3/scripting/text_ir.lua`), rather than scrolling the first line
away. The Gen 2 port needed a whole `keepPageWaits` pass for the same problem;
this one does not.

**But a narrower wrap can leave a page holding one word.** The engine's wrap is
greedy — it fills each line as far as it will go and lets the remainder fall
where it may, with no short-line balancing at all (`wrap_subline`). At vanilla's
208 that never shows, because the ROM's text is authored to two lines of 26
columns. At the **152** a FRAMED box costs, it does — this line ends its second
page with a single word:

```
"Your very own POKeMON legend is about to unfold! A dream of yours is coming true!"
```

Measured by `.probe/dp3_wrap_probe.lua`, and confirmed across a dozen real FRLG
lines at 208/176/168/160/152/144 by `.probe/dp3_orphan_probe.lua`. That corpus is
why this is not the line 1.8.2 used: at 152 the old one wraps to two balanced
lines and only orphans at 176 and 168, so the guard would have had nothing to fix
and the test would have been a tautology dressed as coverage. The replacement
orphans across 144, 152 **and** 160, so it survives a column of drift either way.

And on Gen 3 a page break is an A press, so that is a button to advance past a
page the player has already read. The mod therefore wraps `TextIR.toTextBox` and
**reflows** its answer: when a page ends on one word, the last word of the line
above moves down to join it. It is a reflow, not a re-wrap, and that is what
makes it safe to do to text the mod did not write — **no word is added, dropped
or reordered, and the number of lines and page breaks is unchanged**, so nothing
repaginates. The engine counts *lines* to decide pages, so a reflow that kept
every word but changed a line count would move every page boundary in the box.
The line it takes from has to keep two words of its own, or the orphan would only
move up a line and leave a new one behind.

The guard is armed on the **width**, not installed unconditionally: it fires only
for a box this mod narrowed. MARGIN costs the text nothing, so a MARGIN box keeps
the engine's own wrap byte for byte — and so does an OFF one. This mod narrows
the wrap; where it does not, it has no business rewriting the game's text.

Installing the wrapper after load is safe here, and that is worth knowing before
touching it: `message.lua` reads `TextIR.toTextBox` as a **field** at call time,
so replacing it later still takes effect. `FrlgFont.draw` is the opposite case —
`vanillaShow` captures it as an upvalue, so it has to be wrapped *before* the mod
loads.

---

## Known limits

- **A class that covers several characters resolves to one of them.** All eight
  gym leaders share class 84 and all four Elite Four members share class 87, so
  a *class-only* lookup can only pick one picture for the whole class. The name
  route rescues this wherever the dialogue names the speaker; where it does not,
  `CustomArt/` is the answer. The mod never pretends otherwise — it is one
  picture per class, not a guess dressed up as an answer.
- **The default crop rule is not tuned per character.** See *Portrait art
  status*. Some faces will sit off-centre until an override is added. The extreme
  case *was* the Fisherman NPC, picture 38 — only **17 % ink**, the sparsest of
  all 148 trainer pictures, so the default square landed almost entirely on empty
  water. 1.9.2 retired his entry, because nothing wears him any more: the name
  `FISHERMAN` now resolves to the Kanto class 69, and picture 94 — the fifteen
  battle Fishermen — is framed correctly by the default at 58 %. It is worth
  reading once as an example of what a wrong class name costs: a measured,
  hand-tuned window filed against a picture that turns out to be unreachable.
- **Most named characters have no portrait**, by design — the ROM has no battle
  art to cut. `CustomArt/` is the answer.
- **The rival is recognised by the name on your save**, so a player who names him
  something the trainer pack already knows — `BROCK`, say — gets the pack's
  answer rather than his own face. The name the pack knows is tried first and
  wins outright, deliberately, because that is what keeps a script handing off
  between two characters correct. It is a narrow case: the pack's 429 names are
  mostly not things a player types for their rival.
- **MARGIN needs a letterbox.** On a window that exactly fits the 240 × 160
  frame there is no margin to paint into, and it falls back to sitting above the
  box.
- **A Pokémon in the world is named by its graphics id, not by its sprite.** Gen
  3's host sprite vocabulary is humanoids only, so no object in the world ever
  arrives as `SPRITE_PIKACHU`. Before 1.9.2 that meant every Pokémon map object
  resolved **nothing at all**; the cart's own `OBJ_EVENT_GFX_*` id is what names
  the species (109 `SNORLAX` … 150 `DEOXYS_N`), and the text route still answers
  for a species the dialogue names outright.
- **Gen 3 is a beta generation in the engine.** This mod is written against
  release 0.3.0's `src/ui/game3/*` and `src/core/game3/*`.
- **`AUTO` needs the player to have turned.** If a box opens from a script that
  the player did not start by pressing A on somebody, `AUTO` keeps LEFT.

---

## Roadmap

- More per-character crop overrides, filled in from looking at the real output.
  The mechanism is in place and 1.9.4 ships 10 trainer pictures, 31 species and
  nine pair halves — but a hand-tuned rectangle for everybody is the Gen 1 and Gen 2
  mods' work and needs the grid-of-crops tooling below. In between, the default
  is right for most of the cast and a wrong override is worse than none.
- More of the story cast in `SPRITE_ART` — only unambiguous sprites are listed
  today, because a key the game never places is a line that silently never
  fires.
- A `tools/` script to render the crop table in bulk and look at it, like the
  Gen 2 mod's. `.probe/dp3_crop_framing.py` now does the mechanical half of this
  — it says which windows cut their art — and `.probe/dp3_frame_compare.py` the
  visual half.

---

## Assets and licensing

**This mod ships no ROM-derived art.** There is no picture in this repository
taken from, or cut out of, a Pokémon ROM. Every portrait is cut at runtime from
data the engine extracted from the player's own ROM on the player's own machine,
and none of it is redistributed here.

`art/crops.lua` is a table of **rectangles** — four numbers per character — not
pixels. It is not a derivative work of Nintendo's art.

`modkit lint` enforces the no-ROM-content rule; see *Verifying it*.

---

## Verifying it

### The headless tests

Five suites, run from a gen1recomp checkout with the mod beside it:

```sh
cd gen1recomp
luajit ../gen3-dialogue-portraits/tests/dp3_speaker_test.lua
luajit ../gen3-dialogue-portraits/tests/dp3_geometry_test.lua
luajit ../gen3-dialogue-portraits/tests/dp3_load_test.lua
luajit ../gen3-dialogue-portraits/tests/dp3_menu_test.lua
luajit ../gen3-dialogue-portraits/tests/launcher_update_test.lua
```

They find the engine on their own if the mod is a sibling of the checkout, or
take it as the first argument.

**`dp3_load_test.lua` — 23 checks.** That the mod **loads at all**, through the
engine's real `Loader` and its real hook bus rather than a double. The other two
suites drive the mod's exported resolvers, so a manifest the loader rejects, a
permission it refuses, or an install that throws inside `onLoad` would leave both
of them green while the game showed nothing — which is precisely the failure this
suite exists to catch. It asserts the loader reports no errors, the mod is
discovered under its own id, its body ran, `Message.show` / `Message.draw` /
`FrlgFont.draw` were replaced on the **real** engine modules, and `world.talk` and
`render.hud` each carry a link.

Then it runs the same assertions again on a **Gen 2 boot**, where the expectation
is inverted: the mod must install nothing. Without that half, "`Message.show` was
replaced" is one-directional — a harness that never ran the mod satisfies it just
as well. The two phases producing opposite results is what makes the suite
evidence rather than decoration.

Two traps are worth knowing if you adapt this. `arg[0]` does not survive the
`.bat` luajit shim (it arrives as `luajit`), so the mod root is discovered as
`tests/..`; and the engine's `FsIo` cannot stat a directory through a `..`
component (`isDir("tests/..")` is false while `tests/../manifest.json` reads
fine), while its `FsIo.new` joins `root .. "/" .. path` so an absolute root
becomes `./C:/...`. Either one makes `Loader:_discover` skip the mod and report
**"0 mods loaded, 0 errors"** — no error to grep for. The suite therefore hands
the loader a small `mods/<key>` view of the real directory, with the mod id as the
key, which sidesteps every one of those joins.

**`dp3_menu_test.lua` — 29 checks.** That the player can **reach the settings**.
Every other suite passes with them unreachable — which is exactly how the mod
first shipped, with perfect portraits and no menu entry to change them.

FireRed has no route to the mod manager: Gen 1 has an F10 hotkey and a MODS row
in its options menu, Gen 2 has a `mods` entry in its start menu, and Gen 3 has
neither — nothing under `src/core/Game3.lua` or `src/ui/game3/` mentions
`ManagerState` at all. The first fix added a `MODS` row to the start menu that
pushed `ManagerState`, and that opened a menu FireRed's font cannot draw. So the
mod now puts its settings into FireRed's own `OPTION` menu instead: it wraps
`Rows.build` (`src/ui/game3/option_rows.lua`) to append two rows and registers
one `Rows.GROUPS` entry, which the option menu's own `Rows.group` turns into the
`DIALOGUE PORTRAITS` group row.

The suite drives that path end to end: the two rows reach `Rows.build`, they are
folded into exactly one `DIALOGUE PORTRAITS` group (and do *not* also appear
beside it), opening it gives a two-row page holding `PORTRAIT` and `SIDE` with
the declared defaults, and stepping each one is written both into the engine's
own options tree (`options.modOptions`) and into the loader's live copy — which
is where the mod reads it while playing — and is printed back by the row.

Its first phase runs *before* the mod is loaded and asserts no group and no rows;
its last phase asserts they are gone again once the mod is not the loaded one.
Without those two, "the group is present" would be satisfied by an engine that
always had one. Verified to bite: making `modLoaded` always answer false turns it
into 10 failures, every one of them a row or group assertion.

**`dp3_speaker_test.lua` — 327 checks.** Who is talking and which picture is
theirs: the text's own name, the press's object, a class being **exchanged** for
its picture rather than used as one, a name resolving to a picture exactly, an
ambiguous name declining, an ordinary townsfolk sprite resolving through its
class (`SPRITE_LASS` gets the Lass's bust), a sprite whose tail is *not* a
species declining (`SPRITE_MONSTER` is a doll), the class list being inverted
rather than hardcoded, `CustomArt/` beating every ROM route, a class with no
picture answering nil rather than a wrong picture, and the press record having an
end — three of them.

**The names the cart spells with a sign, a quote or a space get a block of their
own**, because they are the two portraits that never drew and they would fail
against any stub that spells them the tidy way. The suite's species table is
keyed by the cart's own spelling — `NIDORAN♀`, `NIDORAN♂`, `MR. MIME`,
`FARFETCH'D` — so it fails if the mod ever starts normalising those names
itself instead of handing them to the engine. It asserts each tokenises, that
`NIDORAN♀` survives into the speaker *unfolded* and resolves art, and that a
`NAME:` prefix which is not a speaker at all (`UNION ROOM:`) tokenises but draws
nothing.

**The graphics id gets a block of its own**, because it is the one route that has
to be tested at four different strengths at once. It pins the *precedence* (a
class-84 object with graphic 85 answers with Sabrina's picture 122, where the
class alone answers 26), the *collapse* (a Hiker carrying `SPRITE_POKEFAN_M` and
graphic 56 gets picture 90, where the sprite alone gets the PokéFan's 66), the
*decline* (a `false` entry resolves to nil **and** closes the sprite route, so
the Fisherman the host's fallback pointed at does not come back), the *host
fallback* (a graphic `gfx_ids.lua` does not list closes the sprite route rather
than trusting the `SPRITE_YOUNGSTER` the engine derived), the *string* form
(`[74] = "LANCE"` resolving through the pack to picture 115), and the end of the
chain — a Swimmer's map object, class 0, `graphicsId = 44`, whose portrait is
picture 99 rather than the boy's face the host mapped him to. The `gfx_ids` stub
deliberately does **not** reproduce the engine's `or "SPRITE_YOUNGSTER"` fallback:
a double that applied the host's default would be enforcing the rule under test.

**1.9.1 adds a second block to that section**, because 1.9.0's four strengths all
test the *route* — that it is consulted, that it outranks the class, that it can
decline and close the sprite route — and not one of them says anything about which
id it answers *with*. The new block pins the two shapes in between: the wrong
*kind* (a Camper carrying `SPRITE_YOUNGSTER` and graphic 39 gets picture 86, and a
Picnicker carrying `SPRITE_LASS` and graphic 40 gets 87) and the wrong *sex*
(graphic 41 → 110 and 42 → 111 for the cooltrainers, 36 → 7 and 37 → 140 for the
tubers), plus the old folks, who resolve nothing at all without an entry because
`SPRITE_GRAMPS` and `SPRITE_GRANNY` are in neither table.

The sex pairs assert the two pictures are **different objects**, not merely two
different ids — the same distinction the stub's `byPic` cache exists for one
paragraph up. An assertion on the id alone is satisfied by a resolver that asks
for the right id and then draws one face for both, which is precisely the bug
being fixed.

**1.9.2 adds two blocks, and the more important of the two is the change to the
stub.** The pack this suite builds used to list **one class id per name**, so it
could not be wrong about a name the cart spells twice — and that is exactly why
the suite stayed green through both of this release's bugs. It now carries the
cart's own duplication (`LASS` at 49 *and* 59, `RIVAL` at 43, 81 *and* 89) with
row counts, and its `TO_SPRITE` stub deliberately lists nothing above id 92.
Run against the pre-fix `main.lua`, the updated suite reports **21 named
failures** where the old one reported none.

On top of that, two new blocks. The **class-name** block pins the tie-break both
ways: that `LASS` means 59 and picture 84 rather than the Hoenn 49 and 65, that
the class-49 lookup still answers 65 when asked *by id*, that `RIVAL` resolves to
89 and picture 124 — the *late* face, which is the trap — and then that all three
rival routes answer 106 anyway, because the picture is pinned rather than looked
up. The **Pokémon** block pins the reported Spearow end to end: `speciesOfGfx`
reads ids 110 and 109, declines 92 (inside the host's own range) and 151 (the
S.S. Anne, a boat), an object wearing the host's `SPRITE_YOUNGSTER` fallback and
carrying graphic 110 resolves to the dex's Spearow — with **no** trainer picture
asked for at all — a real Youngster still gets picture 36, and the same box
driven through `world.talk` with a text that names nobody (`"Kyah!"`) carries the
species off the graphics id alone.

The three ends are pinned separately, because they are three different seams: a
step, a map change, and the conversation's script finishing. `script.ended` gets
the closest reading, because its `completed` flag is the whole point: a hand-off
(`completed = false`) must **keep** the record or every box in the second half of
a chained conversation loses its portrait, and a finished script must drop it.
The suite was shown to bite on both halves — removing the subscription fails the
two "finished" cases, and removing only the `completed == false` guard fails the
hand-off case.

**The rival has his own block**, and it opens by clearing the press record. That
line is not tidiness: the block's first case is a box arriving with **no press
behind it**, which is what the rival's scripted boxes actually look like, and
without the clear it would be running against a Lass left on the record by the
section above — passing through the sprite route while appearing to test the
rival's name. An early run of these cases did exactly that, and the bite-proof
for the rival route is what caught it (`got 65` — the Lass — where `nil` was
expected). The block then pins the name on the save being read from the session
*and* from the save table, the pack's inability to place the player's choice, the
two negative controls above, and the flag going quiet when the save has no name —
which is the assertion that fails if anyone ever "fixes" the rival by adding
`GARY` to the mod's own name table.

It also pins the cart's **null records**: class 0 ("not a trainer") and picture 0
(the null picture) resolve to nothing, an ordinary NPC gets no portrait rather
than the null one, and two speakers get two **different** pictures. The pack stub
carries the cart's empty record and its images are keyed by picture id, because
a stub that mints a fresh image per call cannot tell one picture from another —
which is how the "every NPC wore one face" bug stayed invisible here.

**1.9.5 adds a block for the location route, and it is the first block here that
has to drive a second mod instance.** The map route is only *visible* on a boot
where the id route cannot answer, and the id route cannot answer when the cart's
trainer table is absent — so the block builds a fresh mod over an engine whose
`Trainers.pack` returns nothing, asserts the reported symptoms appear (a Super
Nerd's graphic falling to 107, a Juggler's to 104), and then asserts the **same
instance** answers correctly once the table appears. That last assertion is the
one that pins the memoization fix: it fails if the empty index is stored, which is
exactly what the old code did. The fresh instance needs the install sentinel
cleared first — the mod guards its engine wrapping on a flag that lives on the
*shared* engine module, so a second instance otherwise returns before exporting
anything — and the engine functions it replaced are put back afterwards.

The rest of the block pins the route's own behaviour: the graphic with a map
answer resolves to that map's picture, the id still outranks it where the two
disagree, a species is never asked about the map, and the reported three classes
resolve to 89 / 102 / 144 on their own maps.

**`dp3_geometry_test.lua` — 496 checks.** The layouts, measured against the
**real** engine modules. The trick that makes it measurable: the `FrlgFont.draw`
spy is installed *before* the mod loads, so the mod captures the spy as *its*
vanilla and the spy therefore sees the arguments the mod has already rewritten.
A spy installed after would see the unmodified ones and prove nothing. (The
`TextIR.toTextBox` spy below is the exception — `message.lua` reads that field at
call time rather than capturing it as an upvalue, so it can be installed at any
point.)

It pins, per layout, the numbers this manual quotes above — including that `OFF`
leaves the text exactly where vanilla puts it, that `AUTO` follows the player's
facing (LEFT and RIGHT) and falls back to LEFT for UP/DOWN, that the box's
geometry is put straight back afterwards, and that it is put back even when the
draw throws.

**The visible box is derived, not typed.** The suite reads the mod's own
`CHROME_*` numbers and asserts the box they imply is 240 × 48 at (0, 112) — the
whole screen width. That number was established by measurement rather than by
reading the code: `.probe/dp3_chrome_probe.lua` drives `Chrome.dialogueFrame()`
headlessly and captures the rectangles it actually draws.

**INSET's art is checked at its slot.** The suite captures where the art was
drawn and asserts it **starts on the slot's first pixel and ends on its far
edge** — 32 px in a 32 px slot, edge to edge, which is the margin the report
asked to have removed — and that a crop as wide as the slot is fitted *down* to
it rather than crossing into the text. It also asserts the art is centred against
the *visible* box vertically — the rect the layout occupies and the one FRAMED
measures — landing on the content rect's own rows, and that the offset is
clamped, so a portrait taller than its rect cannot begin above the box's top
border. That clamp is inert at 32 px rather than load-bearing, which is the point
of the revert: at 1.6.0's 38 px the offset was negative and the clamp was the only
thing placing the art at all. (The mutation that restored the pinned placement and
the unpadded window, and the one that restored the 38 px measurement, are among
the retired letters listed at the end of this section.)

**And INSET's two sides are checked against each other.** The point of the
padding fix is that `SIDE` must not change the layout, so the assertions are
pairs: the text pen and the wrap width are the *same expression* on the left as
on the right, and `INSET_RESERVE_TW` is asserted to be the slot's columns plus the
wider of the arrow's column and the clearance — so a change to either constant
has to be a deliberate one. Verified to bite: making the shift side-dependent
again fails six, and making the wrap width side-dependent fails four.

**FRAMED is checked at the engine's own call, not only at the rectangle.** The
panel is the game's window, so the strongest thing the suite can say is that the
mod *asks* for it: a spy on `Chrome.stdFrame` — the same function the start menu
and the OPTION page are drawn with — captures the call and asserts it is a
`PANEL_CONTENT_TW`-tile window at the origin. That assertion holds whether the
extracted tiles are present or not, because the tiles and the engine's flat
fallback come out of the same call, and it fails the moment the mod goes back to
painting its own panel. The suite also spies `love.graphics.rectangle` to check
*where* the window landed: its **outer** edge stops `EDGE_PAD` — 4 px — short of
the play area's own edge and its **inner** edge `EDGE_PAD` short of the box's own
visible edge, because this release splits the run's slack either side of the
panel rather than pushing all of it outward. So the panel touches neither the box
nor the screen, and the gap the player sees is the constant itself rather than a
rounding of it. Both edges, because a panel that starts in the right place and is
the wrong width passes an assertion on its left edge alone.

The three nested fills are checked too, and by colour rather than by width: the
outer rect has to be the engine's own frame colour (`98/255`), not the black the
mod used to paint, and the rect inside it the engine's white content. A
width-only match would have accepted 1.8.0's black panel and reported it as the
window, so `panelOf` requires both. Verified to bite: **C5**, putting the mod
back on its own hand-painted panel, fails **91** assertions.

**And the gap is asserted from both ends.** The distance from the panel's edge to
the text pen is asserted to be `CHROME_L * T + EDGE_PAD` — **20 px**, the box's own
border plus the clearance the panel keeps from the box — on each side
independently, the left measured forward from the panel to where the pen starts
and the right measured back from where the line ends, because `SIDE` producing two
different gaps is exactly the class of bug an earlier release had to fix in INSET.
The **outer** edge is asserted against `EDGE_PAD` directly, and the run's own slack
— `FRAMED_GIVE * T - FRAMED_PLAN.w`, pinned to the literal **8** — is asserted too,
because that is what makes the split the only reading: 8 px of slack, EDGE_PAD each
side of the panel. Verified to bite: **C4**, setting `EDGE_PAD` back to 8, fails
**13** — the slack does not move, because `ceil((8 + 48) / 8)` is still 7 columns,
but the split can no longer give 8 away and the floor no longer matches, and both
are asserted rather than inferred.

**And the window is asserted to be the engine's shape, not the art's.** The
window's outer rect is asserted to be six tiles square with one tile of border on
each side and a 32 px content rect inside, and the art is asserted to be centred
in that content at the plan's own zoom. This is the assertion a per-speaker panel
could not make, and the one that separates this release from 1.8.0: there the
panel's width *was* the art's, so "the art is centred in the window" was true
while the window's size was a property of the speaker. Verified to bite: **C7**,
sizing the window to the art again, fails **11** — not more, and the reason is
worth stating: the DEFAULT crop is 32 px, so its window comes out 48 px either
way, and C7 is caught by the narrow crops, whose windows would shrink to 40 px.

**The window is asserted to be ONE size, and the zoom to be the only thing that
varies.** `panelPlan` is asked for the default crop, a 16 px crop and a 12 px
crop: all three windows come back 48 px, and the arts come back 32 px at 1×, 32 px
at 2× and 24 px at 2× — the first two are the same 32 px reaching the content by
two different routes, which is why the zoom section asserts the *scale* doubles
rather than that the art gets bigger. `framedGive` is the same seven columns for all three, so
the **text width is a constant** — 152 px — and the suite asserts that out loud
rather than leaving it to be discovered, because it is the reversal this release
makes against 1.8.0, where two speakers in the same layout got two different text
widths. Verified to bite: **C6**, removing the whole-number zoom, fails **12**.

**And the panel's slack is SPLIT between the box and the screen.** The run is
`give` whole tiles and the window is exactly six of them, so 8 px are left over,
and this release gives four to each side: the panel's outer edge is `EDGE_PAD`
from the play area and its inner edge `EDGE_PAD` from the box's visible edge. The
suite asserts both distances, on both sides and for the hand-tuned crops as well,
so the margin is pinned to the constant rather than to the run's slack — which is
the statement that neither the margin nor the gap depends on the speaker. Verified
to bite: **C12**, putting the whole slack back on the outer side — 1.8.3's
placement — fails **17**.

**And MARGIN draws the same window, checked at a whole number of times the crop.**
`panelPlan` is asked directly for a 16 px crop and asserted to give zoom 2 and a
48 px window, and then a MARGIN draw is driven with a 16 px crop filed against a
picture nothing else in the file touches — and against a rectangle no earlier cut
used — because the mod's crop cache is keyed on the **rectangle**, so a cut is
only reused by a speaker whose rectangle matches it exactly. The window that
reaches the draw call is asserted to be that one, the art to be drawn at the same
whole-number zoom, and the window less its two borders to be exactly the zoomed
art — and, because the 32 px default now fills the window at 1× just as the 16 px
crop does at 2×, the assertion that it is **bigger** than the default's is gone:
what is asserted instead is `16 * zoom * 3`, and against the default's own
`DEFAULT_ART * 3`, so the difference is the *zoom* and not the size. The windows
themselves are asserted to be the *same* size, because they are. The suite also
asserts that
MARGIN's plan and FRAMED's agree, because they are one function now. Verified to
bite: **C6**, removing the zoom rule, fails the MARGIN half of the same ten.

**Three mutations were retired with the branches they mutated.** **W** un-clamped
the centring offset in the fill branch that scaled the art into a fixed window;
that branch is **deleted** now — the art is fitted *into* the content rather than
stretched across it, so there is no non-integer fill left to clamp. **E** snapped
`fitScale` to a whole number; `fitScale` is INSET's caller only now, and INSET's
32 px crop in a 32 px slot is already 1×, so the snap changes nothing any
assertion can see. **Y** restored the 1.7.0 split where MARGIN borrowed FRAMED's
fixed panel; with one plan again, Y *is* a permutation of the same shape. A
mutation nothing fails on is a mutation that means nothing, so all three are kept
on the record and no longer run.

**The text is checked at the wrap, not at the clip.** Everything above measures
where the text is *drawn*; a line is wrapped once, inside `Message.show`, against
`ctx.maxWidth`. The suite spies `TextIR.toTextBox` and asserts the width the real
wrap was handed — 168 for both INSET sides, 152 for FRAMED, 208 for MARGIN and
OFF, 212 for a battle frame — and then asserts that the wrap and the clip are
**the same number on the same box**, which is the property the fix is actually
about. FRAMED's number is a constant now, which is the same trade as the window
itself. It also asserts the caller's own `ctx` survives the copy with its
`playerName` intact and no `maxWidth` added, because a fix that narrowed the wrap
by mutating the caller's table would trade clipped text for `PLAYER`. Verified to
bite: dropping the width fails nine of these.

**The one-word page is checked at the text the box will print.** The wrap spy
records what `TextIR.toTextBox` returned, so the assertions read the string the
player sees rather than the mod's arithmetic. A real FireRed line that orphans a
word at FRAMED's 152 is shown orphaned with the mod left out of it and not
orphaned with it in; then the reflow is held to the two properties that make it
safe — the **word sequence** is unchanged and the **line and page counts** are
unchanged — by counting all three on both strings. A mutation that drops a word
fails four of these and one that downgrades a page break to a line break fails
four more.

The box this runs on has to be one that **actually orphans the line**, which is
not a detail: it has now bitten four times. It first ran on INSET-LEFT, and when
INSET-LEFT gained a column of clearance the same line stopped orphaning at the new
width; then FRAMED's own width moved and the line it had moved to stopped
orphaning there too; 1.8.1 narrowed FRAMED by a column for the clearance, which
moved it a third time; and this release narrowed it again, 168 → 152, where the
line 1.8.2 used no longer orphans at all — it wraps to two balanced lines at 152
and only drops a word at 176 and 168. Every time the assertions still passed,
because "no page ends on one word" is trivially true of a box that never
orphaned. A positive test has to run at a width where the thing it guards happens
— which is why the suite derives the width from `FRAMED_TEXT_W` rather than typing
it, and why the line itself was re-picked by measurement: the one now used orphans
across **144, 152 and 160**, so it survives a column of drift in either direction
instead of sitting one column away from being a tautology.

The negative controls are the interesting half, and the first version of them was
**blind**. It compared the mod's output against `TextIR.toTextBox` — which, by
then, was the mod's own wrapper — so both sides were guarded and the assertion
passed under a mutation that removed the gate entirely. The suite now captures
the engine's own wrap **before the mod loads** and asserts the property directly:
a MARGIN box and an OFF box each still end on one word, because the guard stayed
out of them, and each is byte-for-byte the engine's own output. Verified to bite:
removing the gate fails four, and never applying the guard fails one.

**And MARGIN measures the box the frame was DRAWN at, not the one reported.** This
is the second half of the release, and it is the half the suite could not see
before: every other viewport in the file is a payload with no renderer behind it,
which is the one case where the two rects agree. The new section installs a stub
`Renderer` whose `frameRects` answers with **both** the UI rect and the world rect
— deliberately different numbers, and a UI scale deliberately not equal to
`fitScale` — and then drives a real MARGIN draw through it. It asserts that the
panel is placed against the *drawn* box, that the gap measured that way is
`MARGIN_PAD`, and that measuring against the reported box instead would put the
panel somewhere else by exactly the distance between the two rects. The payload
path is still exercised: with no renderer installed, `frameRect` must fall back to
the payload and to the payload's own scale. Verified to bite: restoring the
reported rect fails eight, and taking the world rect instead of the UI rect fails
ten.

**And the mod is compiled into the sandbox's own environment.** This is what
1.8.0's suite could not do, and it is why the fix above passed every test and ran
in no game. The suite now builds the mod's chunk with `setfenv` into an
environment whose `package` is the decoy shape `LegacyCompat` supplies — an empty
`loaded` — and pins that environment with three assertions before anything else
runs, so a return to `package.loaded` cannot pass again. Verified to bite:
restoring the `package.loaded` lookup 1.8.0 shipped fails nine.

**And the frame guard is checked by frame kind.** The suite opens a box with
`frame = "sign"` and one with `frame = "battle"` and asserts neither paints a
portrait *and* that each keeps its own geometry — `x = 16`, `maxWidth = 208` for
the sign, `x = 10`, `maxWidth = 224` for the battle box — because a guard that
suppressed the portrait but left the text shifted would satisfy "paints nothing"
while still moving the engine's own text. A negative control follows: the field
dialogue still paints, at `16 + 32`. Verified to bite: removing the guard fails
six of these.

**MARGIN is driven through `render.hud`**, with the viewport the engine's own
`Game3:_drawHud` builds, so the coordinates asserted are window units. Five
behaviours are pinned: it draws the engine's own 48 px window — the panel is the
same one FRAMED draws, so it is asserted to be `PANEL_MAX_TW` square rather than
the art's own size — in window units; it honours `SIDE` instead of always going
right; it stands above the
box when there is no letterbox, keeping `MARGIN_BOX_GAP` — **2 game px** — clear
of the box's top and `MARGIN_PAD` — **4 game px** — in from the play area's own
edge, asserted as the distance rather than as the coordinate so the invariant
reads as one thing rather than as two restatements of the same arithmetic, and
clamped to the frame's top edge if that would put it off-screen; it uses and
centres in the letterbox when
there is one, bottom-aligned with the play area so it sits level with the box; and
it mirrors a Pokemon on the left while leaving a trainer bust alone. It is also
checked for painting a **window** — the engine's own slate ring and white content,
matched on the frame colour as well as the width — because "a panel was painted"
and "a portrait was drawn bare on the map" are the same rectangle call and only
the colour tells them apart, and for the art sitting in that window's content at
the plan's own centring: the border plus the plan's offset to its left, the same
above it, and the art no wider than the content it is centred in.

**Both clearances are asserted against their literal** as well as against
`MARGIN_PAD` / `MARGIN_BOX_GAP`. Those literal assertions are the ones that
matter: a suite that only ever compares the code against its own constant stays
green if someone sets the constant back to 8 — the value 1.8.2 lowered — or puts
the box gap back to 4, so the literals are the requirement and the constants are
how they are spelled. 1.9.3 is the proof: the box gap moved 4 → 2 with the edge
clearance left alone, and the two literals are asserted separately and
independently, along with `MARGIN_BOX_GAP < MARGIN_PAD` so a future edit cannot
quietly re-merge them into one number.

**And the letterbox *condition* is asserted at its boundary.** The panel goes out
into the margin only when the margin can hold it *plus* the clearance on both
sides, so the 48 px window needs `48 * 3 + 2 * 4 * 3` = **168** window units at 3×.
The suite checks a margin of 116 px (too narrow — the panel stands above the box,
inset from the play area's edge) and one of exactly 168 px, **derived from the
window and the clearance rather than typed** (wide enough — the panel goes into the
margin, and is exactly `MARGIN_PAD` from the screen's own edge once centred there).
Testing only comfortable distances from that boundary would pass with the condition
weakened.

Verified to bite: ignoring `SIDE` fails ten, centring vertically fails seven, never
mirroring fails one, not painting the window fails ninety (mutation **C5**, across
both layouts, `drawFramed` being shared), dropping the horizontal inset fails
five, and weakening the letterbox condition fails three. The box gap is pinned
twice over: putting `MARGIN_BOX_GAP` back to 4 — the value it had before 1.9.3 —
fails three, and re-merging the two constants (`boxGap = MARGIN_PAD * s`) fails
five, across the desktop, phone and touch-skin viewports.

**And the panel is checked on a viewport built the way the engine builds one.**
Every other viewport in the suite has `scale == gameWidth / Display.W`, which is
the desktop relationship — so none of them can see the unit mismatch at all, and
the suite was green while every phone drew the panel in the wrong place. The new
section builds a 360 × 720 phone at 3× (`scale` 4, playfield 320 window units,
the two disagreeing) and asserts the panel is sized in window units, placed
**`MARGIN_PAD` in from** the playfield origin rather than on it, and **inside the
game frame** — the last being the assertion the original bug actually failed. It
also pins `unitFor` on all four shapes: playfield-only, `scale`+`dpiX`, both
agreeing, and neither. Verified to bite: reading `scale` as window units fails
eleven, preferring it over the playfield width fails thirteen, and dropping the
`dpiX` division from the fallback fails one.

It also checks that the crop table is keyed by the **picture** and not the
class, by filing two rectangles of different sizes under the two candidate keys
and watching which rectangle the crop is built from.

**And the exception table is checked end to end, including at the cut.** A block
of its own covers the two key spaces: the shipped pic-38 entry against pic 94 (the
NPC is reframed, the fifteen battle Fishermen are not), each of the four speaker
prefixes beating the picture key, the four-way precedence order, an unfiled key
falling through to the default, a malformed override being ignored rather than
becoming a one-pixel window, and a species key needing no speaker key at all. The
one that matters most is the last: the exception is driven all the way to the
**quad** the portrait is actually built from, by drawing picture 17 through
`SPRITE_HIKER`, then filing a `sprite:SPRITE_HIKER` override, then removing it —
asserting the quad's `x` at each step. A resolver can pick the right rectangle and
still hand the draw a cut made from the wrong one, which is exactly the bug the
rectangle-keyed cache fixed, and only reading the quad can tell.

Verified to bite: mutation **C1**, narrowing the name token class back to
`[A-Z0-9._-]`, fails nine; **C2**, no longer consulting the speaker table, fails
nine; **C3**, keying the crop cache on the picture again, fails one; **C4**,
putting `EDGE_PAD` back to 8, fails thirteen; **C5**, putting the mod back on its
own hand-painted panel, fails ninety-one; **C6**, removing the whole-number zoom,
fails twelve; **C7**, sizing the window to the art again, fails eleven.

**1.9.0's six new mutations are C8 to C13**, and each one restores a shape the
reports describe:

| | what it restores | failures |
| --- | --- | --- |
| **C8** | INSET back to a 30 px portrait inside a slot inset by a pixel each side — the margin between the art and its frame | **4** |
| **C9** | `art/crops.lua`'s default windows back to 1.8.3's 30 px | **12** |
| **C10** | the species crop key back to the display name lowercased | **2** |
| **C11** | the `world.trainer_engaged` subscription neutered — the sight-challenge with no press behind it | **9** |
| **C12** | FRAMED's whole slack back on the outer side, flush against the box | **17** |
| **C13** | the no-dex fallback no longer folding the two gender signs apart | **2** |

**C9 is the one that needs the harness to have grown.** The crop table's default
window is *data* in `art/crops.lua`, not code in `main.lua`, so `dp3_bite.py` now
snapshots and restores every file a mutation touches — each with its own backup
beside the harness — and proves the shipped default by moving it back to 30. A
mutation that cannot reach the file that holds the answer would have left the one
change the report is most about unproofed.

**1.9.1's eight new mutations are I to M and C14 to C16**, and each restores one
group of the mappings the second report is about. They are filed against the
suite that owns the question rather than all against one, because the two halves
fail differently: `I`–`M` change WHO resolves, so the speaker suite has to notice
them, and `C14`–`C16` delete a crop rectangle, which only the geometry suite can
see.

| | what it restores | failures |
| --- | --- | --- |
| **I** | the Camper and the Picnicker left on the kind the host's sprite names them | **4** |
| **J** | both cooltrainers back on the class-name route — and its lowest id with that name, picture 8, a male | **3** |
| **K** | every tuber graphic back on picture 140, the female | **2** |
| **L** | the old man and the old woman left unmapped, so they resolve nothing at all | **5** |
| **M** | the Man and the Balding Man back on the PokéFan's face — picture 32, a boy | **2** |
| **C14** | the male Tuber's crop rectangle deleted, back to the default window | **2** |
| **C15** | the old woman's crop rectangle deleted | **2** |
| **C16** | the Camper's crop rectangle deleted | **2** |

**`C14`–`C16` are filed because of what the report says, not for tidiness.** The
symptom the release opens with — *"the fisherman has no portrait at all"* — is a
crop and not a mapping: a window aimed at empty water reads on screen as an empty
frame, so the two are indistinguishable to a player. Routing three new pictures
without framing them would therefore have reproduced the report three times over,
and a rectangle nothing asserts is a rectangle that can stop being read without
anyone noticing.

**1.9.2's five new mutations are N to R**, each restoring one half of one of this
release's two fixes, plus `C17`–`C19` for the crop rectangles it adds.

| | what it restores | failures |
| --- | --- | --- |
| **N** | the class-name tie-break back to *lowest id wins* | **7** |
| **O** | the graphics id no longer naming a species | **8** |
| **P** | the player's-own-name route back on the name `"RIVAL"` | **4** |
| **Q** | `SPRITE_ART.SPRITE_BLUE` back on the name `"RIVAL"` | **3** |
| **R** | `NAME_ART.RIVAL` back on the name `"RIVAL"` | **2** |
| **C17** | the Sailor's crop rectangle deleted, back to the default window | **2** |
| **C18** | the Black Belt's crop rectangle deleted | **3** |
| **C19** | Spearow's crop rectangle deleted — the reported case | **2** |

**`N` and `O` are the reported bugs; `P`–`R` are what fixing `N` would have
broken in silence.** The class name `RIVAL` is spelled by three classes, the row
count picks the *late* one (picture 124), and nothing in the game reports it — so
without the pin, fixing the girl on Route 3 would have moved the rival's face
from 106 to 124 and no test, no probe and no player would have said a word. The
pin has three mutations rather than one because each of the three routes reads a
**different** table — `SPRITE_ART`, `NAME_ART`, and the constant inside `artFor`
— so each can be reverted on its own and each has to be proved on its own.

**And the speaker suite's stub now carries the duplication.** It used to hold one
class id per name, so it could not be wrong about a name the cart spells twice —
which is precisely why it was green through both of this release's bugs. A double
that carries only the clean shape of the data cannot fail on the dirty shape.
It now mirrors the cart's own shape (`LASS` at 49 *and* 59, `RIVAL` at 43, 81
*and* 89, with row counts), and its `TO_SPRITE` stub deliberately lists nothing
above 92, because an entry for 110 would edit the Pokémon fallback out of the
test. Run against the pre-fix `main.lua` the updated suite reports **21 named
failures** where it used to report none — the assertion that the test change is
itself real.

The letters **A**–**R** are the resolution mutations — **A**–**H** the speaker
ones, **I**–**M** the 1.9.1 mappings, **N**–**R** the 1.9.2 ones — and
**C1**–**C19** the crop and layout ones. Where an earlier revision of this file
names a letter outside those sets — `AC`, `AD`, `AE`, `AF`, `AG`, `T`, `U`, `Z`,
`AH` — that letter no longer resolves: `dp3_bite.py` was rewritten when the
layout moved onto the engine's own window, and the mutations behind those names
were either folded into the ones above or retired with the branches they mutated.
The behaviour each one was recorded for is still asserted; what is missing is a
runnable mutation that proves the assertion bites, and that gap is worth closing
the next time the file is touched.

The suite asks one question before any of that: *does a portrait actually
resolve?* If it does not, the mod's draw wrapper falls through to vanilla and
every layout assertion silently measures untouched engine numbers — reporting
failures and naming the wrong cause. That check exists because it happened.

It ends at the other end of the same chain: it spies `love.graphics.draw`, drives
a press through `world.talk`, opens a box, draws it, and asserts the speaker's own
picture really was painted through its quad. A portrait that resolves but is never
drawn would satisfy every measurement above and still show the player nothing.

Then it does that for **two** speakers and asserts they paint two **different**
pictures — taken at the draw, because a resolver can ask for the right picture id
and still be handed one picture back for everybody. That check is only meaningful
because this suite's art stub is now keyed by picture id; it used to mint a fresh
image per call, which made "same picture for everyone" invisible to it, and that
is exactly how every ordinary NPC in the game came to wear one face while the
suite reported green.

#### The double must not be more capable than the real thing

The crop is a **quad**, and the suites' stub image is shaped like a real LÖVE
11.5 `Image`: `getDimensions` and nothing else. That pairing is deliberate and it
is the one thing in these suites worth copying. LÖVE removed `Image:getData` in
11.0 and this engine targets 11.5, so a real picture **cannot** hand back its
pixels — which means an earlier version of this mod, which built each portrait by
copying pixels into a fresh `ImageData`, could not build a portrait at all in the
game. Every character was silent and faceless.

The suite stayed green, because its stub image offered `getData()`. The double
was *more capable* than the object it stood in for, and that is the failure mode
to watch for in a headless suite: a thin double makes the code fail loudly, but
an over-equipped one makes a broken feature look tested. Both suites now assert
`rawget(image, "getData") == nil` and then that a portrait still comes out, so
the readback route cannot come back without a test going red.

Those four are about the mod at runtime — what portrait a speaker gets. The
fifth is about the other half of shipping a mod.

**`launcher_update_test.lua` — 41 checks.** Whether the launcher will offer an
update for this mod, and whether the archive it would download is the one this
repo publishes. It builds a synthetic GitHub release shaped exactly like this
repo's — same semver tag, same asset names, the same `.modpkg` beside the `.zip`,
and a decoy `another-mod-1.0.0.zip` that sorts first — and drives it through the
engine's own `ModUpdate.parseReleases` / `pickZipAsset` / `statusFor` /
`pickBest`. Nothing touches the network; those four are pure, and they are where
every silent failure lives.

The failure it exists to catch is a quiet one. The launcher asks for the release
*list*, and `parseReleases` takes the array branch there and **drops** an entry it
cannot use — no error, no reason, just a list without it. So a release whose tag
is not semver, or whose asset is named slightly differently, or which carries
only a `.modpkg`, makes the mod look perfectly up to date forever. The suite
asserts each of those shapes is dropped, that a usable release survives beside a
bad one, and that the single-object branch (`/releases/latest`, the one that does
answer with a reason) refuses them with the reason it should.

It also checks the parts of the contract that live in this tree rather than in
the release: that the workflow and the vendored builder are present, that the
workflow takes the asset name from the manifest instead of hard-coding it, and
that the `.modkitignore` guard entries still match the manifest's id and version.

One thing it does differently from the copy it was taken from, and the reason is
worth keeping. That copy typed `"1.0.0"` as its "an older install gets the
update" probe, which is a fine older version for a repo at 1.4.8 — and this
repo's first release **is** 1.0.0, where `statusFor` correctly answers `current`
for a version equal to the release, so the assertion failed on the first build.
The probe is now `"0.0.1"` with an assertion that it is not the manifest's own
version, so the check cannot quietly become a tautology again.

### The distribution gates

From the engine checkout:

```sh
export MODKIT_LUAJIT=<path to luajit>
python3 tools/modkit.py validate ../gen3-dialogue-portraits --strict
python3 tools/modkit.py lint     ../gen3-dialogue-portraits
python3 tools/modkit.py gen3check ../gen3-dialogue-portraits --strict --notes
```

`validate --strict` drives the real mod loader headlessly and promotes every
warning to fatal. `lint` is the no-ROM-content gate: ROM images, ROM-hack
patches, raw chip-audio banks and bulk dumps of imported data tables all fail
it. `gen3check` is the generation gate — "will this run on a Gen 3 game, and how
far" — which is the one that matters most here, since the whole point of the
port is the generation split. All three pass.

### Checking the cart's own numbers

Three scripts in `tools/` read the ROM directly and print what the mod
otherwise only sees at runtime. They are how *The class is not the picture*
above was established — the fact that mattered most about this port came out of
the cart, not out of the mod's own comments.

```sh
# the 107 class names, as the cart spells them
python tools/dump_class_names.py

# class -> front-pic id, and which classes pin more than one
python tools/dump_class_pics.py

# every trainer record: id, class, picture, name
python tools/dump_trainers.py
python tools/dump_trainers.py BROCK     # just the rows for one name
```

Run them from a directory holding `Pokemon_FireRed.gba`, or point `FIRERED_ROM`
at one. The offsets they use are the engine's own
(`src/import/gba/versions.lua`), and they are worth re-running if the engine
ever moves them: the class table ends exactly one byte before the trainer table,
which is the arithmetic agreeing with itself.

---

## Releasing it, and the launcher's auto-update

The launcher can update an installed mod from this repo's GitHub releases. It
reads `ModUpdate`'s contract (`src/mods/ModUpdate.lua` in the engine), and the
whole of it is four requirements:

1. **`manifest.json` carries `"github": "owner/repo"`.** Absent or empty means
   the launcher never checks this mod. `modkit set-github <mod> <owner>/<repo>`
   sets it. Note the field lives in the *installed* copy, so it only starts
   working from the first release that carries it — a copy installed before that
   has to be replaced by hand once.
2. **A Release, not just a tag.** The check hits
   `api.github.com/repos/<repo>/releases`. A pushed tag with no Release attached
   is invisible to it.
3. **A semver-like tag** — `v1.0.0` or `1.0.0`; a leading `v` is stripped.
4. **A `.zip` asset named `<mod-id>-<version>.zip`** — here,
   `gen3-dialogue-portraits-1.0.0.zip`. The lookup is exact-name first, then
   `<mod-id>*.zip`, then any `.zip`, so the exact name is the one to use. **Only
   the `.zip` is consumed**; the `.modpkg` is for manual install and is not
   looked at. An update shows only when the release version is strictly newer
   than the installed one, so the version has to actually move.

**Cutting a release.** Nothing is built into the repo. The `.zip` is a build
product: `.github/workflows/release.yml` builds it from the tagged tree and
attaches it to the GitHub Release. So the whole procedure is bump the version,
tag, push:

```sh
# 1. bump "version" in manifest.json
git tag v1.0.1
git push origin v1.0.1
```

The workflow reads the mod id and version out of the manifest, **refuses to run
if the tag disagrees with them**, builds `gen3-dialogue-portraits-<version>.zip`
and attaches it with `gh release create`. The tag and the asset name therefore
cannot drift from the manifest they ship inside — which is the failure this whole
section exists to prevent.

**Building one by hand** (to look at it before tagging) uses the same script the
workflow uses, and the same rules:

```sh
python3 tools/build_release.py . -o /tmp/gen3-dialogue-portraits-1.0.0.zip
```

Two things to get right if you do. The zip's wrapper folder name comes from the
*directory* `build_release.py` is pointed at, so run it from a checkout named
`gen3-dialogue-portraits` — the name this repo clones to. **This is easy to get
wrong from a working copy named anything else**, and a wrapper named
`gen3-dialogue-portraits-repo/` is what it produces if you do: it still installs
(`LauncherMods.locateRoot` accepts any single top-level folder holding the
manifest) but lands as a *second* copy of the same mod id beside the first, which
is worse than failing. Point the builder at a directory carrying the id, or let
CI do it — the workflow checks out into exactly that name. And write the output
outside the tree: both builders walk everything they find, so an artifact left in
the repo root gets folded into the next build. `.modkitignore` names those two
paths as a guard against exactly that, but it is a guard, not a licence — and the
entries are exact paths, so a version bump has to rename them.

**A `.modpkg` is optional.** The launcher's updater only ever reads the `.zip`,
and the launcher installs a `.zip` perfectly well, so the release does not need
one. If you want one for manual `modkit` installs, build it locally — `modkit
pack` runs the full gate set and needs `luajit`, which is why CI does not do it:

```sh
MODKIT_LUAJIT=<path/to/luajit> python3 <engine>/tools/modkit.py pack . \
    -o /tmp/gen3-dialogue-portraits-1.0.0.modpkg
gh release upload v1.0.0 /tmp/gen3-dialogue-portraits-1.0.0.modpkg
```

The two archives must carry the same payload — the `.zip` under a
`gen3-dialogue-portraits/` wrapper, the `.modpkg` flat plus its own
`.modkit/pack.json`. Both are 10 files: everything except the two ignore files,
`.github/`, the five suites and the four `tools/` scripts, all of which
`.modkitignore` lists.

`tests/launcher_update_test.lua` checks the contract without touching the
network: that the workflow and the vendored builder are present, that the
workflow takes the asset name from the manifest rather than hard-coding it, and
that the `.modkitignore` guard entries still match the manifest's id and version.
A version bump that forgets them fails the suite rather than shipping a release
the launcher cannot see.

---

## Credits

- The Gen 1 and Gen 2 mods this is a port of, for the idea, the three layouts
  and the speaker-resolution order.
- [pret/pokefirered](https://github.com/pret/pokefirered), for the dialogue box
  geometry, the text printer semantics and the trainer class list this mod
  reads.
- The gen1recomp engine, for the Gen 3 field, UI and mod-loader stack.
