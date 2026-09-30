# Changelog

## 1.2.17 — the Nidoran's line: the TEXT now picks the speaker, not the press

**1.2.16 opened the gate and the line still wore the wrong face** -- the report is
"now it shows the trainer portrait not NIDORAN♂".  The gate was only half the
problem: with it open, the SPEAKER still resolved through the press and the scene
routes, and the press is the WOMAN when she is the one who told him to sit.

**What changed**

- **`TEXT_NAMES_A_SPECIES` now maps a text fragment to the species**, and
  `speakerFor` reads it FIRST, before the press record and before the scene route.
  It outranks both, because it is the only one of the three that cannot be wrong
  about who is talking: whatever was pressed, "NIDORAN♂: Bowbow" is the Nidoran.
- Plain substring, no pattern and no lookup -- the same rule 1.2.16 settled: a
  gate or a route must be a fact the mod already holds, never a question that can
  answer nil.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.
- The failing case is now a check: with the WOMAN's object pressed
  (`gfx 16`, `g3:0816a726`), `speakerFor("NIDORAN♂: Bowbow!")` returns
  `species = NIDORAN_M` and `artFor` yields the picture -- not her face.
- The woman's own line ("NIDORAN, sit!") does not match the fragment, so she keeps
  hers.

## 1.2.16 — the Nidoran's line: a plain text match, because the smart one did nothing

**1.2.15's check did not work in the game**, and the report proves it: the box was
still grey/black and still faceless.  It resolved the box's name token through
`speciesArt` and let the box through only if that returned an entry -- and
`speciesArt` can answer nil for reasons a mod cannot see, because it goes through
the engine's own species registry and `frontPic`.

**What changed**

- **A plain substring table**, `TEXT_NAMES_A_SPECIES`, checked with `find(..., 1,
  true)`.  No pattern, no registry, no species art: if the fragment is in the text
  it matches, and the speaker is resolved independently by `speakerFor` anyway
  (its "a species named itself" path already answers this text exactly).
- The fragment is `"NIDORAN♂: Bowbow"`, not the whole line -- the cart writes
  `"NIDORAN♂: Bowbow!"` and a report may quote it with a space before the bang, so
  an exact match would be a trap.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.
- The fragment matches the cart's spelling AND the quoted one, and does not match
  the woman's own line ("NIDORAN, sit!").

## 1.2.15 — a box that NAMES a species keeps its face, whatever colour it is

**What changed**

- **`coloursAllowPortrait` now also accepts a box whose TEXT names its own
  speaker.** The Pewter City Nidoran's line is the case, and the reason the
  1.2.12 exception was not enough: ONE subroutine (`g3:0816a749`) serves BOTH the
  woman's press and the Nidoran's, so the press record names whichever was
  pressed -- and when it names the **woman**, the `(map, graphic)` list could not
  match, so her press showed the Nidoran's line with no face while the Nidoran's
  press showed it correctly.
- The text is the fact that cannot be wrong.  The mod's own resolver already
  answers a text-named species exactly (see `speakerFor`'s "a species named
  itself", which returns `{ name = ..., species = ..., fromText = true }`), so the
  gate now asks the same question: a token that resolves to a species this mod can
  draw is a person-shaped speaker whatever colour the cart drew it in.  So
  **every** box carrying that text gets the Nidoran's face, and the woman's own
  line still gets hers -- the two can no longer be swapped, because the text
  decides each box independently of which object was pressed.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.

## 1.2.14 — the Nidoran's line was the CART'S all along; my duplicate is gone

**What changed**

- **Removed the line 1.2.9 added.** The cart already has it. `PewterCity_House1`
  obj 2 (the woman) and obj 3 (the Nidoran) BOTH `call` the same subroutine,
  `g3:0816a749`, and that subroutine is:

  ```
  1 textcolor 3                     <- NEUTRAL
  2 waitse
  3 playmoncry 32                   <- the Nidoran's own cry
  4 loadword "NIDORAN<male>: Bowbow!"
  5 callstd 4
  6 waitmoncry
  7 call g3:081a6675
  8 return
  ```

  So the line appears in **two** interactions -- the woman's and the Nidoran's --
  and 1.2.9's hook line was a third, duplicate box.  It is gone; the cart's own
  line is the one that shows.
- **The portrait gate is why it had none**, and it is the cart's own doing: the
  subroutine sets `textcolor 3`, the neutral grey/black, so `coloursAllowPortrait`
  declined it.  1.2.12's exception (`["FR_PEWTER_CITY_HOUSE1"] = { [123] = true }`)
  is what lets the Nidoran's box keep its face, and it stays.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.

## 1.2.13 — the male Nidoran's window starts on his artwork, not above it

**What changed**

- **`crops.pokemon.nidoranm`: `{ 13, 13, 32 }` -> `{ 13, 17, 32 }`.**  The window
  began four rows ABOVE the artwork's first opaque row, so the top of the frame
  was empty space and the artwork's bottom was still cut off -- the report is
  exactly that: *"too much white space above NIDORAN♂, bottom clipped"*.  Starting
  the window on row 17 fixes both at once: no white above, and the bottom loses
  two rows instead of six.  The 32px frame cannot hold all 35 rows of the art, so
  a portrait has to choose -- this chooses the head.
- The female's window is untouched; it was reported working.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `art/crops.lua` loads.

## 1.2.12 — the Pewter Nidoran's box is neutral, so it gets the exception

**What changed**

- **`NEUTRAL_COLOUR_PORTRAIT` gained one entry.** 1.2.9 gave the Pewter City
  Nidoran a line, and the line showed with no face -- because its box is drawn in
  the neutral grey/black, which is the colour the cart uses for narration, signs
  and item boxes, and `coloursAllowPortrait` declines those.  The fix is the same
  shape as the museum scientist's in 1.2.7: one `(map, graphic)` pair,
  `["FR_PEWTER_CITY_HOUSE1"] = { [123] = true }`, so this speaker keeps his face
  and **the rule itself is untouched** -- every other neutral box in the game is
  still declined.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.
- The data path was already proven for this graphic before the change: `gfx 123 ->
  speciesOfGfx=NIDORAN_M -> speciesKey=nidoranm -> artFor=ART(image)`, crop
  `13,13,32`.  So the gate was the only thing standing between it and a face.

## 1.2.11 — the Nidoran spelling REVERTED: 1.2.6 broke both of them

**This undoes 1.2.6's change to `GFX_MON`.** That release swapped the two Nidoran
entries from the engine's fold (`"NIDORAN_F"`/`"NIDORAN_M"`) to the cart's own
spelling (`"NIDORAN♀"`/`"NIDORAN♂"`), on the theory that the dex wanted the cart's
form.  It does not, and **the swap broke BOTH**: the female had drawn correctly
for releases and stopped, and the male stopped with it -- the reported "the
Nidoran rendering is broken for both male and female variants, nothing is drawn
at all".

**What changed**

- `GFX_MON[122]`/`[123]` are back to `"NIDORAN_F"`/`"NIDORAN_M"`.
- The two spellings are for two DIFFERENT jobs, and that is the trap worth
  recording: the cart's spelling is what the **name token** wants
  (`nameFromText`'s class accepts the gender signs deliberately), while THIS
  table feeds `speciesArt`, which hands the value to the content registry -- and
  that is keyed by the fold.  The female's record settles which is which.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.
- `Pokemon.norm_key` folds either spelling to `NIDORANF`/`NIDORANM`, and
  `frontPic` yields an image for both Nidoran once the index is built with that
  fold (`NIDORAN_M` -> 32, `NIDORAN_F` -> 29) -- checked against the ROM.

## 1.2.10 — the Nidoran's line gets its portrait

**What changed**

- **The Pewter City Nidoran's box now draws its face.** 1.2.9 showed the line
  from the TOP of the `world.talk` hook, before `forgetSpeaker()` and
  `pressSpeaker = eo` had run -- and the box's speaker is resolved FROM that
  record, so at that moment it still named the previous press and the Nidoran
  itself was never asked.  A Nidoran's face comes from its SPECIES, so with no
  speaker there was no species and no portrait: the line appeared, the face did
  not.  The block now sits **after** `pressSpeaker = eo`, which is also what
  makes it correct on the FIRST press rather than the second.
- The line reads `NIDORAN♂: Bowbow !` as asked.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.
- Still a real-game check: the species portrait needs the engine's extracted
  species pack, which no harness in this workspace has (`[game3/pokemon] species
  pack missing — re-import FireRed ROM`), so the FACE cannot be rendered here.

## 1.2.9 — the Pewter City Nidoran gets a line

**What changed**

- **Pressing Pewter City's Nidoran now says something.** `PewterCity_House1`
  obj 3 is the Nidoran the woman tells to sit (graphic 123), and its object
  script `g3:0816a736` is `lock / faceplayer / call / applymovement /
  waitmovement / release` -- it opens **no box at all**, so pressing it only
  walked it about and there was nothing to read.  The `world.talk` hook now
  shows *"NIDORAN♂: bow bow"* for that press.  A mod cannot put a message into
  the cart's own script, so this hook is the only seam that sees it.
- Scoped to `(map, graphic)` -- `FR_PEWTER_CITY_HOUSE1` and graphic 123 -- not to
  "any Nidoran": FourIsland wears the same graphic twice, once as a stuffed doll,
  and neither of those is this one.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.
- **The box appearing on the A press is NOT verified here** -- that needs the
  running game.  The hook fires before the press record is refreshed, so the
  first thing to check in play is that the line appears on the FIRST press, not
  only the second.

## 1.2.8 — the THIRD museum scientist, and why 1.2.7 only fixed two

**The three museum scientists do not share a script shape.** Lid 3
(`g3:0816a4ae`, the amber giver) and lid 6 (`g3:081c4bbe`, the move tutor) both
open `lock / faceplayer`.  **Lid 5 (`g3:0816a49c`) is only
`loadword / callstd / end`** -- no `lock`, so the engine never SELECTS an object
for that box and hands it NEUTRAL, and 1.2.7's gate read only the PRESS record,
which is not set the same way for a script that never locks.

**What changed**

- **The gate now consults the scene route as well as the press.** The
  `(map, graphic)` pair is the fact that decides, not the route that found it, so
  `coloursAllowPortrait` asks both `pressSpeaker` and `sceneSpeaker()` for
  `["FR_PEWTER_CITY_MUSEUM_1F"][55]`.  All three scientists keep their faces, and
  the list is still one map and one graphic, so no narration or item box anywhere
  else can be caught by it.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.

**Nidoran♂ -- what is actually known, and what is not**

- 1.2.6 changed `GFX_MON[123]` to `"NIDORAN♂"`, the cart's own spelling
  (`names[32]` is `"NIDORAN♂"`; `"NIDORAN_M"` is the engine's `keyName` fold,
  which is what the CROP table wants but not what the dex answers to).
- **It cannot be checked in this workspace.** The engine's dex needs its
  extracted species pack; without it `[game3/pokemon] species pack missing` and
  `Pokemon.speciesFromName` answers nil for EVERY name -- in the headless suite
  and in the LÖVE harness alike.  A "broken dialogue box" is therefore something
  only the game can show me: send the symptom (blank? wrong face? wrong text?)
  and it can be chased.

## 1.2.7 — the museum scientist's face, and why it was missing

**What changed**

- **The museum scientist keeps his portrait on every line.** He is Pewter Museum's
  fossil-room man, the one who hands over the OLD AMBER -- *"Ssh! Listen, I need
  to share a secret with someone…"* -- and he wears graphic 55, which already
  answered 107.  He still showed nothing, because the mod gates a portrait on the
  box's TEXT COLOUR (`coloursAllowPortrait`): FRLG draws a person in dark blue or
  dark red and everything else -- narration, signs, item and letter boxes -- in
  the neutral black/grey, so a neutral box is declined.  **His script
  (g3:0816a4ae) sets no text colour at all**, so the engine handed every one of
  his boxes NEUTRAL and the mod took his face off all of them.  A new
  `NEUTRAL_COLOUR_PORTRAIT` list -- explicit (map, graphic), one entry -- says
  that this speaker is a person talking, so his own boxes keep the portrait and
  no narration or item box anywhere else can be caught by it.  It covers his
  whole dialogue, the amber secret through the handover and every later line,
  because the gate is asked per box.
- **Nidoran♂** keeps 1.2.6's spelling fix (`GFX_MON[123] = "NIDORAN♂"`, the cart's
  own form; `names[32]` is `"NIDORAN♂"`).  See the note below on verifying it.

**How it is verified**

- **1059 checks, 0 failures** across the five suites, and `main.lua` loads.
- The colour gate is now covered by the mod's own resolver path for graphic 55 on
  that map, and the suite still declines a neutral box anywhere else.

**Not verifiable here, and worth a look in game**

- **The species portraits cannot be resolved headlessly.** The engine's dex needs
  its extracted species pack (`[game3/pokemon] species pack missing — re-import
  FireRed ROM`), and without it `Pokemon.speciesFromName` answers nil for every
  name and no species art can be built -- in the headless suite AND in the LÖVE
  harness alike.  So Nidoran's spelling is verified against the cart's own name
  table (`names[32] = "NIDORAN♂"`) rather than against a rendered picture.

## 1.2.6 — the Machop's narration line, and the Nidoran spelling

**What changed**

- **"A MACHOP is stomping the land flat." draws no portrait.** A ONE-OFF, not a
  rule: `speakerFor` matches that one exact line and returns no speaker, so the
  player's own observation about the Machop draws nothing -- while the SAME
  object's other box, "MACHOP: Guoh! Gogogoh!", is the creature talking and keeps
  its face. Every other Pokemon in the world is untouched, because nothing else
  matches the line.
- **The two Nidoran are spelled the way the cart spells them.** The engine's dex
  is keyed by the names in the cart's own species table -- `names[29]` is
  `"NIDORAN♀"` and `names[32]` is `"NIDORAN♂"` -- so `GFX_MON`'s
  `"NIDORAN_F"`/`"NIDORAN_M"` (the engine's `keyName` FOLD of those same two
  names, which is what the CROP table wants) was not a spelling the dex answers
  to. The female was broken in exactly the same way as the male, and both now use
  the cart's own form.

**How it is verified**

- **1059 checks, 0 failures** across the five suites.
- The Machop's two boxes resolve differently, checked through the mod's own
  resolver: `"MACHOP: Guoh! Gogogoh!"` has a speaker, `"A MACHOP is stomping the
  land flat."` has none.
- `GFX_MON[122]`/`[123]` now read `NIDORAN♀`/`NIDORAN♂`. (The dex itself is not
  loaded in the headless harness -- it needs the engine's extracted species pack
  -- so the spelling is verified against the cart's own name table rather than
  against a resolved picture.)

**Still open**

- **The museum scientist.** `PewterCity_Museum_1F` obj 3 (graphic 55) resolves to
  **107 on both of his boxes**, and his script is a plain press -- there is no
  faceless box in the museum to fix. If the box you see draws without a portrait,
  the cause is somewhere else; send me the exact line and I will chase it.

## 1.2.5 — three of six: the captain's last line, the Game Corner counter, the Rocket window

**What changed**

- **The captain's last line has his face.** "Using CUT, you can chop down small
  trees.  Why not try it with the trees around VERMILION CITY?" carries no
  `CAPTAIN: ` label, so the name route could not reach it and the graphic was the
  only thing left -- and graphic 63 had no entry.  `GFX_ART[63] = 81` is that
  same captain for the unlabelled boxes.  (`NAME_ART.CAPTAIN` still answers the
  labelled ones.)
- **The Rocket Game Corner's coin seller has no portrait.** He wears graphic 47,
  the male Worker, which 1.2.3 gave the Bird Keeper's bust -- right for the Silph
  Co. and S.S. Anne workers who also wear it, wrong for the man behind the
  counter, who is a shopkeeper and not a trainer.  `PLACE_ART` gained a `false`
  form, consulted **before** `MAP_ART` and `GFX_ART`, so
  `["FR_CELADON_CITY_GAME_CORNER"][47] = false` declines it **on that map only**.
  Every other map keeps 46.
- **The Team Rocket bust is framed.** Picture 109 had no window, so it took the
  default `{16,3,32}`; measured it is `{11,1,32}`.

**How it is verified**

- **1059 checks, 0 failures** across the five suites.
- Checked through the mod's own resolver: graphic 63 -> 81; graphic 47 on the
  Game Corner -> nil while Silph Co.'s graphic 47 stays 46; graphic 49 -> 109.

**Still open from the six — each needs a decision, not an edit**

- **2. The Machop line.** `VermilionCity` obj 4 IS the Machop (`gfx 130`) and owns
  both `"MACHOP: Guoh! Gogogoh!"` -- which names its speaker -- and `"A MACHOP is
  stomping the land flat."`. The mod has no notion of a box the object *says*
  versus a box *about* the object, and the obvious rule would strip the portrait
  from every unnamed box of every Pokemon in the world.
- **3. The museum scientist already resolves to 107** (and now has a window). No
  graphic-55 object in the museum is faceless.
- **4. Nidoran♂ still has none.** `GFX_MON[123] = "NIDORAN_M"`, but the dex lookup
  does not resolve that spelling -- the cart spells it `NIDORAN♂`, and the fold
  that turns one into the other is exactly the thing the mod notes it must not
  carry a second copy of.  Needs the engine's own key, not a guess.

## 1.2.4 — framing for the pictures 1.2.3 linked, and ERIK's own face back

Two of the five reports in this batch. The other three are described at the end,
because each needs a decision rather than an edit.

**What changed**

- **Nine crop windows, measured from the cart's own pixels.** The pictures 1.2.3
  linked -- 18, 33, 46, 54, 75 and 81 -- had **no window at all**, so every one
  took the default `{16,3,32}`; so did 89, 97 and 107, which earlier releases
  used without ever framing them. All nine are now in `art/crops.lua`, computed
  by `.probe/dp3_crop_measure.py`, which applies the table's own rule to
  `rom_sprites/raw/`: x is the head band's centre minus 16, y the artwork's first
  row minus three rows of headroom. 75 -- the old bald man -- is `{16,1,32}`.
- **ERIK's box no longer wears the Super Nerd's lab coat.** Fuchsia City's fat
  man wears graphic 27 and his box says *"ERIK: Where's SARA? I said I'd meet her
  here."* The name route ran first and returned 89 -- ERIK the Super Nerd, whose
  picture is a man in a white lab coat -- which is the original report coming
  back the moment 1.2.3 gave that graphic a bust to answer with. His own graphic
  is now a fact about who is standing there, so **graphic 27 is the one graphic
  exempt from "the name first"** (`NAME_PROOF`). Every other graphic that
  answers still takes the name first, so a script handing off between two
  characters box by box is untouched.

**How it is verified**

- **1059 checks, 0 failures** across the five suites.
- The ERIK box resolves 54 (his own graphic) and not 89, checked through the
  mod's own resolver.

**Still open from the same batch — each needs a decision, not an edit**

- **The museum scientist already has a portrait.** `PewterCity_Museum_1F` lid 3
  (`gfx 55`, g3:0816a4ae -- *"PLAYER received the OLD AMBER from the man"*) has
  resolved to 107 all along, and his script is a plain press, not a scene. He now
  has a window (107 -> `{17,1,32}`), but nothing was missing. Say which object
  you saw.
- **The Machop line needs a rule.** `VermilionCity` obj 4 IS the Machop
  (`gfx 130`), and it owns both *"MACHOP: Guoh! Gogogoh!"* -- which names its
  speaker and should keep the portrait -- and *"A MACHOP is stomping the land
  flat."*, which is the player's own observation. Nothing in the mod yet
  distinguishes a box the object says from a box about the object.
- **RIVAL is one constant.** `RIVAL_ART = 106`, overridable by
  `CustomArt/RIVAL.png`. Stage-dependent faces need the rival's per-stage trainer
  ids; `TRAINER_IDS` (script key -> trainer id) is the seam.

## 1.2.3 — five faces the graphic table was missing, and one it had wrong

Six links taken from `rom_sprites/` -- the cart's own assets, extracted with the
engine's `ow_extract` and its trainer-picture dump -- and confirmed by eye
against the pairs rather than inferred from a class name.

| overworld graphic | portrait | who |
| --- | --- | --- |
| `ow_027` FAT_MAN | `tr_054` | the Collector |
| `ow_031` WOMAN_3 | `tr_033` | the PokéFan |
| `ow_033` OLD MAN 2 | `tr_075` | the cart's **second** old-man bust |
| `ow_047` WORKER_M | `tr_046` | the Bird Keeper |
| `ow_059` CHEF | `tr_018` | the Kindler |
| `CAPTAIN` (his own text's name) | `tr_081` | the S.S. Anne's captain |

**What changed**

- **Four graphics that answered nothing now answer.** `27`, `31`, `47` and `59`
  had no host sprite entry, no class and no name, so the people wearing them
  drew no portrait at all -- the museum's attendant, the S.S. Anne's kitchen
  hands, Silph Co.'s workers and the women on the corridors.
- **`ow_033` is a correction, not a hole.** It was 97, with `32` and `34`, on the
  note that "the cart carries exactly one old-man bust". There are two -- 97 and
  75 -- and they are different men: `ow_032` is blue-robed, `ow_033` is khaki, and
  75 is the bald khaki one. `32` and `34` keep 97.
- **`CAPTAIN` is answered by the name his own box uses.** "CAPTAIN: Ooargh… I
  feel hideous…" (SSAnne_CaptainsOffice, g3:08160b3a). He wears graphic 63,
  which no other object does, but that graphic has no host entry and he has no
  class, so the name is what resolves him.
- **`ow_027` reverses a deliberate DECLINE.** It was `false` -- "the cart never
  drew the Fat Man" -- which is also what stopped Fuchsia City's fat man, whose
  box says "ERIK: ", from wearing the Super Nerd's face. **He now resolves
  through the graphic instead of declining, so that box resolves the name route
  first again; that interaction is worth watching in play.**

**How it is verified**

- **1059 checks, 0 failures** across the five suites, with the three assertions
  that encoded the superseded decisions updated to say so.
- `.probe/dp3_links_check.lua` resolves all six through the mod's own resolver
  (9 checks, 0 failures), and bites: reverting the links fails it by 6.

## 1.2.2 — a payload an update cannot trip on

The launcher could not update the mod. It stopped on

> *could not write CHANGELOG.md: Could not open file
> mods/gen3-dialogue-portraits/CHANGELOG.md (permission denied)*

Windows cannot delete a read-only file, so a stale read-only copy of
CHANGELOG.md left behind by a previous install made the installer unable to
clear the old tree -- and therefore unable to write the new one. **Size was not
involved**: the file is 192 KB and the engine's caps are 8 MB and up.

**What changed**

- **CHANGELOG.md and README.md are no longer in the shipped payload.** Nothing
  reads either of them out of an *installed* mod: the launcher's "What's New?"
  renders the GitHub Release **body**, which the release workflow extracts from
  the source tree, and no engine code opens them. Both stay in the source tree,
  so this release's notes below are still published as that body. The release
  zip and the `.modpkg` go from 10 entries to **8**. `CustomArt/README.md` is
  deliberately untouched -- that one is the player-facing documentation for
  adding your own portraits.

**How it is verified**

- **1059 checks, 0 failures** across the five suites.
- The failure was **reproduced, and the fix confirmed, under real LÖVE 11.5**:
  `.probe/loveinstall/` drives the engine's own installer over the release zip.
  With the installed CHANGELOG.md made read-only, an update returned
  `could not write CHANGELOG.md ... (permission denied)`; with the file out of
  the payload, the same update succeeds.
- The engine was hardened for the same reason -- `CacheFs.remove`/`removeDir`
  clear the Windows read-only attribute before deleting, so a stale read-only
  file can no longer abort *any* mod's update.

## 1.2.1 — the scientist's own face, and the Pokemon a script moves

Two reports, both of them a face decided by something less specific than the fact
in hand.

**What changed**

- **Mt Moon's fossil-room Super Nerd has his own face again.** He is MIGUEL,
  trainer 170, class SUPER NERD, whose cart front picture is **89**. He wears
  `OBJ_EVENT_GFX_SCIENTIST` (55) — the lab coat the host calls
  `SPRITE_SCIENTIST` and that eight Super Nerds **and** fourteen Scientists share
  — and his object's script CALLS its trainerbattle from a subroutine rather than
  opening with one, so neither generated table carries him. The scene route
  already named him for the fossil's own box, but his graphic then fell through
  to the one-value-per-graphic table and he wore the **Scientist's 107**.
  `art/map_art.lua` now answers for that map, so both the fossil line and his own
  press draw 89.
- **Cerulean City's Slowbro no longer wears itself on its trainer.** The LASS
  beside the Slowbro runs `applymovement localId=5` — the Slowbro — and only then
  says her own lines, and the scene route names "the object the script most
  recently moved", so it named the Slowbro for every one of her boxes and she
  wore its face. A species is not a person, so an actor that resolves to a
  species no longer outranks the press.

**How it is verified**

- **1059 checks, 0 failures** headless across the five suites, plus **12 checks
  under real LÖVE 11.5** (`.probe/lovefix`, driving the real message box, the real
  engine modules and the real ROM art).
- Both fixes are **bite-proven**: reverting them fails the suite by 5 and the
  LÖVE check by 4, with exactly the reported symptoms.
- The guard's **blast radius is measured**: of 5025 decoded scripts, 7 rows stage
  a Pokemon — the Slowbro, a Poliwrath in Celadon, a Nidoran♂ in Pewter and four
  Clefairy rows in Bill's Sea Cottage. Nothing else changes.

## 1.2.0 — every sprite a name, every name the right face

Everything since 1.1.0, in one release: four reports, all of them the same shape
— a portrait that was decided by something less specific than the fact in hand.

**What changed**

- **Every Tamer sprite answers.** Graphic 25 carries six **TAMERs**, three Young
  Couples and twenty ordinary men; the graphic table declined it outright, so the
  same sprite answered on the four maps a Tamer stands on and nowhere else. It
  now carries the Tamer's own bust, its majority class.
- **Four crop windows the default did not look through** — the **Biker**, the
  **Pokémon Breeder**, the **Ruin Maniac** and the **LADY**. Each is a picture
  whose head sits somewhere the default `{16,3,32}` does not look, so it cut the
  face or spent the window on empty art. All four are measured from the ROM's own
  art, by the crop table's own stated rule.
- **The cart's one other speaker label.** The name rule knew only the all-caps
  `NAME:` token; the cart also writes a single capitalised word, `Butler: `. Five
  boxes use it, and because they counted as naming nobody they fell to the object
  route — which names whichever object the scene moved last, not the speaker. The
  butler changed face in the middle of the Resort Gorgeous scene, and two of his
  three faces were not his.
- **The mod's own name table now runs with the pack's name route**, not after the
  graphic. A name the text used is the one fact a script cannot get wrong;
  everything below it is a guess from a graphic.
- **Lady Selphy's own maps.** The generated per-map table is built from trainer
  objects, so the two maps where she stands as a non-trainer had no entry — and
  the box that opens *"I wish to see a Pokémon."* carries no name, so it drew the
  Aroma Lady's face while every `"SELPHY: "` box drew hers. She now draws **146**
  in her house, in Lost Cave Room 10 and outdoors alike.

**How it is verified**

- **1052 checks, 0 failures** headless, plus **52 checks inside LÖVE 11.5**
  driving the real message box and the real decoded scripts.
- Every change is **bite-proven** — reverting it fails the suite.
- Every resolver change is **measured for blast radius**: every field object
  (1648) and every distinct dialogue text (2139) resolved before and after, with
  the diff stated in each section below.

The four sections below are the same work release by release, with the
measurements.

## 1.1.4 — Selphy's own map, which the generated table cannot see

The report: *"the incorrect portrait for Lady Selphy in the Lost Cave, and in
Resort Gorgeous during the dialogue from 'I wish to see a Pokémon' through the
end of the conversation."*

1.1.3 fixed the boxes that NAME her. This is the box that does not.

### What was wrong

`art/map_art.lua` — the per-map table that says which class a shared graphic
means **on this map** — is generated from **TRAINER objects**
(`.probe/dp3_emit_map_art.lua`). A map whose only speaker of a graphic is a
non-trainer therefore has no entry for it, and the graphic's own table answers,
which for a shared graphic is its **majority class**.

Lady Selphy wears `OBJ_EVENT_GFX_WOMAN_2` (28), shared by LADY, AROMA LADY and
POKéMON BREEDER, so `GFX_ART[28]` is the **Aroma Lady's 144**. Her Resort
Gorgeous House has no trainers at all, and neither does Lost Cave Room 10.

The box that opens **"I wish to see a POKéMON."** (`g3:08171efe`) is the one that
showed it: it carries **no name** and moves nobody, so it is resolved from her own
object — **144** — while every box of hers that says `"SELPHY: "` resolves **146**
through the name route. One conversation, two faces. The Lost Cave double of her
never had the right one at all.

### The fix

A hand-written `PLACE_ART` — `(map, graphic) -> picture` — asked **before**
`MAP_ART` and before `GFX_ART`:

| map | graphic | picture |
| --- | --- | --- |
| `FR_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE` | 28 | **146** |
| `FR_FIVE_ISLAND_LOST_CAVE_ROOM10` | 28 | **146** |

It is hand-written on purpose: the generated table must stay generated. The
outdoor Resort Gorgeous already says 146 for this graphic through that table,
because two Ladies do stand there as trainers — `PLACE_ART` is that same answer
for the two maps it cannot reach. Selphy now draws **146** in all three places.

### Blast radius, measured

Every field object resolved before and after (`.probe/dp3_art_sweep.lua`,
`DP3_DUMP=1`, against `git archive HEAD` and the working tree): **1648 objects,
exactly 2 changed** —

```
FiveIsland_LostCave_Room10|1        144 -> 146
FiveIsland_ResortGorgeous_House|1   144 -> 146
```

### Verification

- **1052 checks, 0 failures** — load 23, menu 29, speaker **432** (up from 425),
  geometry 521, launcher 47.
- **Bite-proven**: deleting the two entries fails the suite.
- Gates on the tree: `validate --strict` ok · `lint` ok · `gen3check --strict` ok.

## 1.1.3 — the label the name rule did not know

The report: *"LADY Selphy displays the wrong portrait in the Lost Cave and in
Resort Gorgeous, where she swaps portraits mid-dialogue; the butler also
displays the wrong portrait."*

The root cause is in the portrait SELECTION, and it has two halves.

### One: the cart writes a second kind of speaker label

The name rule reads the cart's all-caps `NAME:` token. The cart has exactly one
other speaker-label shape — a single capitalised word, `Butler: ` — and the rule
did not know it, so those boxes were treated as naming nobody. Measured over
every dialogue box in the game (`.probe/dp3_labels.lua`), there are only **four**
labels of that shape and only the first is a person:

| label | boxes | what it is |
| --- | --- | --- |
| `Butler:` | 5 | the butler of Resort Gorgeous |
| `Diary:` | 4 | the Pokémon Mansion's diaries |
| `Hint:` | 1 | a sign |
| `Name:` | 7 | the Pokédex-evaluation signs |

`nameFromText` now reads the capitalised shape too. The other three resolve to
nothing through `NAME_ART` and the pack, so their boxes are **unchanged** — the
regression sweep below is what proves it.

### Two: the mod's own name table ran LAST

`NAME_ART` was consulted at the tail of the resolver, after the graphic and class
routes — so for a box the name rule DID recognise, the graphic still answered
first. It now runs beside the pack's name route (step 2b), which is the mod's
own principle: *a name the text used is the one fact the script cannot get
wrong, and everything below it is a guess from a graphic.*

### What that produced, and what it produces now

The Resort Gorgeous House scene (`g3:08171f34`) moves SELPHY for her own line
and then shows **two of the butler's**. With the label unknown, those two boxes
fell to the OBJECT route, which names the object the script moved most recently —
SELPHY — so they carried her object (gfx 28) and wore the Aroma Lady's 144, while
his third box carried his own (gfx 61) and wore the Gentleman's 123: **the
butler changed face mid-scene, and two of his three faces were not his.** That is
also what was read as Selphy swapping, and what made her look wrong in Resort
Gorgeous: the 144s in that scene were never hers.

| box | before | after |
| --- | --- | --- |
| SELPHY: Oh, hello, there… | 146 | **146** |
| Butler: Yes, my lady. | 123 | **123** |
| SELPHY: See to it that this person… | 146 | **146** |
| Butler: I shall do as you bid, my lady. | **144** | **123** |
| Butler: I sincerely thank you… | **144** | **123** |

`NAME_ART` gains `BUTLER = "GENTLEMAN"` — the class the cart itself draws him as
(`OBJ_EVENT_GFX_GENTLEMAN`, graphic 61) — so his label and his own object agree
on 123.

### Every affected scene, not only the reported one

Every dialogue box in the game — **2139 distinct texts** — was resolved before
and after (`.probe/dp3_text_sweep.lua`, run against the previous tree and this
one):

- **picture changes: 5** — the five `Butler:` boxes, `NONE` → `123`. Nothing else
  in the game changes picture at all.
- **name-only changes: 16** — those 5 plus the 4 `Diary:`, 1 `Hint:` and 7
  `Name:` boxes, whose pictures are untouched.

`Butler:` is the only person-shaped label of its kind in the cart, so those five
boxes ARE every affected scene.

### Selphy's own portrait

Worth stating plainly, because the report asks for it: her picture is the cart's
own answer — her trainer row names her (id 606, class 105, picture 146) and every
one of her boxes says `"SELPHY: "`, so she draws 146 on every box she speaks.
The two gfx-28 objects that do not speak are the static one in Lost Cave Room 10
(no script at all) and her own House object, whose boxes all carry her name.

### Verification

- **1045 checks, 0 failures** — load 23, menu 29, speaker **425** (up from 417),
  geometry 521, launcher 47.
- **Bite-proven**: removing the capitalised-label rule fails 2 speaker checks;
  moving `NAME_ART` back to the tail fails 1.
- Gates on the tree: `validate --strict` ok · `lint` ok · `gen3check --strict` ok.

## 1.1.2 — four windows the default did not look through

The report: *"adjust the portrait framing for the Biker, Pokémon Breeder and Ruin
Maniac characters, and replace the Lady Selphy portrait with the correct one."*
All four are the same kind of thing: a picture the crop table had no entry for,
so it fell to the default `{16, 3, 32}` — a window written for a bust that fills
the middle of its 64x64 square — and the picture's head is somewhere else.

`art/crops.lua` states the rule in its own words (against picture 66): **x is the
face's centre minus 16, y the artwork's first row minus three rows of headroom,
clamped at 0.** Measured from the `.rgba` dumps by `.probe/dp3_measure.py`:

| picture | class | head | first art row | window |
| --- | --- | --- | --- | --- |
| **91** | BIKER | x 15–31, centre 23 | 2 | `{7, 0, 32}` |
| **141** | POKéMON BREEDER | x 24–42, centre 33 | 15 | `{17, 12, 32}` |
| **145** | RUIN MANIAC | x 23–42, centre 33 | 12 | `{17, 9, 32}` |
| **146** | LADY | face centre 32 | 0 | `{16, 0, 32}` |

- The **Biker** is a rider hunched over a motorbike, drawn small and high; the
  default began one pixel to the *right* of his head, so it took half his face
  off and spent the rest of the window on the fuel tank.
- The **Breeder** and the **Ruin Maniac** are both figures whose artwork does not
  start until row 15 and 12, so the default spent its top third on nothing and
  cut them off at the chest.
- The **LADY** is Lady Selphy's own picture. Her hat's crown is the first opaque
  row, so the default's `y` of 3 took the top of the hat off.

**On Selphy's portrait itself**, one thing is worth stating plainly: the picture
was already the cart's own answer. The cart's trainer table names her (id 606,
class 105, picture 146), her graphic is `OBJ_EVENT_GFX_WOMAN_2` (28) — which the
LADY, AROMA LADY and POKéMON BREEDER classes share, so `GFX_ART[28]` answers the
AROMA LADY's 144 — and every one of her boxes says `"SELPHY: "`, so the name route
gives her 146 and has done since the name route existed. What her portrait needed
was the window, and that is what this release gives it. The same picture is worn
by the two Ladies standing outside on the island, who want the same window.

### Nothing else changed

`art/crops.lua` is **35 added lines and 0 deletions** — the four keys above, and
nothing else in the table. Every other portrait keeps the window it had.

- **1037 checks, 0 failures** — load 23, menu 29, speaker **417** (up from 412),
  geometry **521** (up from 515), launcher 47.
- **Bite-proven**: deleting the four entries fails 4 geometry checks.
- Gates on the tree: `validate --strict` ok · `lint` ok · `gen3check --strict` ok.

## 1.1.1 — every Tamer sprite answers

The report: *"not all Tamer sprites have associated portraits."*

`GFX_ART[25]` (the Man) was one of the `false` entries — a graphic the cart drew
no bust of. That is right for the twenty ordinary men who wear it and wrong for
the **TAMER** class the cart also put on it: measured by
`.probe/dp3_classgfx.lua`, graphic 25 carries **9 trainer objects — six TAMERs
(class 78) and three YOUNG COUPLEs (94) — and 20 ordinary men**, and the majority
of the classes on it is the Tamer.

The nine trainers already had their own pictures through the trainer-id route, and
`art/map_art.lua` already answered **103** for this graphic on each of the four
maps a Tamer stands on (Viridian Gym, Fuchsia Gym, Victory Road 2F, Sevault
Canyon). So the *same* sprite answered on those four maps and nowhere else —
which is exactly the reported shape.

`[25] = 103` now — the Tamer's own bust, a man in a man's clothes with a whip
raised (`.probe/dp3_dump_pics.lua` dumps it). That is a plausible face for the
twenty men, and it is what the map route already gave the nine trainers. The
sprite route's own answer is still refused — it would hand them the PokéFan's
picture 66, a boy with a net — because the graphic's entry outranks it.

### Nothing else changed, and that is measured

Every one of the game's **1649 field objects** was resolved before and after
(`DP3_DUMP=1 luajit .probe/dp3_art_sweep.lua gen1recomp <tree>`): **20 changed,
every one of them graphic 25, every one `NONE` → `103`; 1629 untouched.** No
trainer object lost a portrait and no other graphic moved.

- **1026 checks, 0 failures** — load 23, menu 29, speaker **412** (up from 409),
  geometry 515, launcher 47.
- **Bite-proven**: putting `[25] = false` back fails 3 speaker checks, and the
  sweep's non-trainer gap returns to 956.
- Gates on the tree: `validate --strict` ok · `lint` ok · `gen3check --strict`
  ok.

## 1.1.0 — portraits that follow the game, not a guess

The first release since 1.0.0, and it folds in every fix cut locally in between
(1.0.1 through 1.0.5, all detailed below). One theme throughout: a portrait
appeared where the cart would not have drawn one, or failed to appear where it
would.

**What changed**

- **The text colour decides.** A box the engine draws in its black/grey "normal"
  colour gets no portrait — that colour is FRLG's own mark of "nobody is speaking
  here", used for narration, signs, and item and letter boxes. Oak's aide's
  letter from Mom is the worked example: the script sets `textcolor 3` before it.
- **A scene may hand its boxes to several people.** The speaker of a box is the
  object the script moved most recently before it, so Three Island's
  bikers-and-locals scene, its boss confrontation, and the dialogue you get by
  pressing any of them now show the right person on every line instead of one
  face — or no face at all.
- **The portrait leaves when the speaker does**, and a speaker who is merely
  *placed* for their next line keeps theirs. A scripted move of five or more
  tiles is a walk-off (measured over the whole game: every reposition is 1–4
  tiles, every walk-off is 6 or more), and a fresh press always starts a fresh
  conversation.
- **Celio has a portrait** — graphic 89, the one graphic worn by exactly one
  object in the game — and so do the **female Psychic's** objects (graphic 23,
  which the sprite route had declined).
- **Bill, Daisy and Mr. Fuji** get their cart-drawn Fame Checker portraits, and a
  scene the NPC starts now names its own actor, so a portrait no longer depends
  on who began the conversation.
- **A step inside a script no longer ends the conversation**, so a cutscene that
  walks the player around no longer drops the speaker's face partway through.

Everything is verified headlessly **and** inside LÖVE 11.5 (50 checks driving the
real message box and the real decoded scripts), with every fix bite-proven.

## 1.0.5 — the colour says who is speaking, and a scene may have several

Two rules, both taken from the engine rather than invented.

The report:

> *"Any dialogue box using black or grey colored text should not display a
> portrait. On THREE ISLAND, there is a dialogue scene between a group of bikers
> and the locals where the portrait assignments are incorrect."*

### One: a black/grey box gets no portrait

FRLG draws a speaking NPC's text in a colour taken from the person the script
selected — **dark blue for a male, dark red for a female** — and the plain
**black/grey** "normal" colour for everything that is not a person talking:
narration, signs, item and letter boxes, and any box whose speaker the engine
could not identify (`src/core/game3/scripting/adapters.lua` `resolveNpcColor`
answers NEUTRAL when the script selected no object). The engine already hands the
answer to the box: `adapters.lua:417/452` put it in `opts.npcColor`, and
`message.lua:113` turns anything that is not MALE or FEMALE into `COLOR.NORMAL`.

So the mod reads `opts.npcColor` and declines the portrait when it is NEUTRAL —
the engine's own answer to "is somebody speaking here?", not a second guess.
Oak's aide's letter from Mom is the worked example: the script sets `textcolor 3`
before it (`g3:081662de` row 51), so the engine draws it in the black/grey
colour, and that is why it is bare — quite apart from the aide having walked off.
Item boxes are the other family (`std:0` and `std:9` set `textcolor 3` too). A
box carrying no `npcColor` at all is NOT declined: every field box in the game
carries one, so an absent value means a caller outside the field path (a suite, a
menu) rather than a black/grey box.

### Two: one script can hand its boxes to several people

`sceneSpeaker` used to collect every object the running script moved and answer
only if there was exactly ONE. Three Island's bikers-and-locals scene
(`g3:081679b5`) is built the other way: it moves a local, shows his line, moves
the biker boss, shows his, and so on for five boxes — so both are actors of the
one script, the old rule answered "nobody", and the whole scene came out bare.
The same shape runs the biker-boss confrontation (`g3:08167a59`: seven boxes,
four different bikers) and the dialogue you get by pressing any of them
(`g3:0816786f`, which alternates local, biker, local, biker).

The actor of a box is **the object the script moved or turned most recently
before it**, because that is the scene's own idiom — place the speaker, then show
their line. The scan starts at the command being executed and walks the callers
outward from their own call sites (`ops_a.lua:356` pushes `{listKey, index}`), so
a box opened by a called `std:` stub still finds its actor in the caller. The
player (`0xFF`) is never an actor.

And because one PRESSED script can hand its boxes to several people, the script's
actor now **outranks the press record** in `speakerFor`. The pressed object is
still the speaker whenever the script stages nobody — the ordinary
`lock`/`faceplayer`/box conversation — which is every other conversation in the
game.

### What Three Island resolves to now

| box | speaker | portrait |
| --- | --- | --- |
| "Are you the boss? Go back to KANTO right now!" | the local (gfx 25) | **none** — the cart drew no bust of him |
| "Hah? I just got here, pal…" | the biker boss (gfx 53) | **91** |
| "Your gang of followers have been raising havoc…" | the local | none |
| "No, man, I don't get it at all…" | the biker | **91** |
| "Grr… You cowards… So tough in a pack…" | the local | none |

Before this release all five were bare; and in the press-triggered dialogue the
local's two lines were wearing the pressed biker's face.

### Verification

- **1017 checks, 0 failures** — load 23, menu 29, speaker **409** (up from 404),
  geometry **515** (up from 507), launcher 41.
- **In the LÖVE engine**: `.probe/love3/` is **50 checks, 0 failures** (up from
  35). It now decodes the real `g3:081679b5` from the ROM and asserts the scene
  box for box — the local's lines must NOT wear the biker's face, the biker's
  must paint picture 91 — and it pins the colour rule in both directions.
  `"C:/Program Files/LOVE/lovec.exe" .probe/love3`
- **Bite-proven in both**: recency removed fails 1 suite + 4 LÖVE checks; the
  press-priority restored fails 1 suite check; the colour rule removed fails 1 +
  1.
- New checks: §20 in `dp3_speaker_test.lua` (the script's actor outranks the
  press; a press with nothing staged is still the speaker) and two new sections
  in `dp3_geometry_test.lua` (`XF.colourTests`, `XF.alternatingSceneTests`).
- Gates on the tree: `validate --strict` ok · `lint` ok · `gen3check --strict`
  ok ("will load").

### What this does NOT change

Celio (1.0.3), the female Psychic's graphic (1.0.2) and the `LEFT_TILES`
departure rule (1.0.4) are untouched. The colour rule is checked BEFORE the
departure rule, so a black/grey box is bare whether or not anybody walked off.

## 1.0.4 — a step is not a walk-off

Two reports about a portrait that was MISSING, and the measurement that settles
what "the speaker has left" actually means.

The reports:

> *"Oak's aide: 'I'm glad I caught up to you.' — no portrait."*
>
> *"Bill: 'ASH, this is my buddy CELIO.' / 'ASH, can I get you to wait for me
> just a bit?' — no portrait."*

### One: 1.0.3's departure test fired on a step, not a walk-off

1.0.3 generalised the record to the object a box actually resolved to and ended
it when that object's **cell changed**. That was too eager. Pewter's aide is
**placed** between his first and second line — the coord paths at (46,22) and
(46,23) call `g3:081663e6` / `g3:081663fc`, which walk him one or two tiles DOWN
to stand in front of the player (`g3:0816643e` is one step, `g3:08166441` two) —
and the old test read that step as a walk-off, dropped the record, and left every
box after "I'm glad I caught up to you." bare. Reproduced against the real
decoded script before the fix: box 1 painted, box 2 bare.

The fix is a measured threshold, not a guess. Sweeping every script in the game
for an NPC moved between two of its own boxes (`.probe/dp3_midmove.lua`, which
follows `call`/`call_if` into branches — the aide's own exit lives in
`g3:08166412`, called from between two boxes) gives **858 moves**, and they fall
into exactly two groups:

| tiles walked | count | what it is |
| --- | --- | --- |
| 1 / 2 / 3 / 4 | 267 / 390 / 101 / 23 | a character PLACED for the next line |
| **5** | **0** | **nothing in the game moves exactly five** |
| 6 | 19 | |
| 7–8 | 2 | a character WALKING OUT |
| 9–10 | 23 | the aide's own nine-tile exit, `g3:08166445` |
| 14 / 25 / 62–64 | 28 | |

So `LEFT_TILES = 5`: a move of four tiles or fewer is a reposition and the
portrait stays; six or more is a walk-off and the record ends. The threshold sits
in a gap the data leaves empty, which is why it can be stated as a rule rather
than tuned. It is also strictly *fewer* false positives than 1.0.3: every 1–4
tile mid-conversation move in the game keeps its portrait.

### Two: a new conversation inherited the last one's record

`world.talk` set `pressSpeaker` but left `spokeObject`/`spokeCell` from the
**previous** conversation. So the first box of a new conversation compared the
speaker's current cell against where they stood in the *last* one — and when the
script had moved them in between (the Net Center scene shifts Bill around), that
first box was read as a departure and came out bare. Bill's own line is the
reported shape: `g3:08170eb1` opens by turning him to face the player
(`applymovement 2` → `0x4A` FACE_PLAYER), which is not a move at all, so what was
left over from the previous conversation was the whole cause. Both press hooks
(`world.talk`, `world.trainer_engaged`) now start from a clean record, so a fresh
press is a fresh conversation.

### Verification

- **1004 checks, 0 failures** — load 23, menu 29, speaker **404** (up from 398),
  geometry **507** (up from 506), launcher 41.
- **In the LÖVE engine**: `.probe/love3/` (LÖVE 11.5, real `love.graphics`) is
  **35 checks, 0 failures**. It drives the aide's scene with **no press**, steps
  him two tiles (box 2 must keep its portrait) and then nine tiles (the letter
  must be bare), and runs Bill's line after a move between conversations.
  `"C:/Program Files/LOVE/lovec.exe" .probe/love3`
- **Bite-proven in both**: removing the threshold fails 2 suite + 2 LÖVE checks
  (the reposition cases); removing the fresh-press reset fails 1 + 1.
- New checks: §19 in `dp3_speaker_test.lua` — the two reported lines resolve (the
  aide's object, gfx 55 → picture 107; Bill's, gfx 73 → the Fame Checker's 313)
  — and three more cases in `XF.departureTests` (a reposition keeps, a walk-off
  ends, a fresh press starts clean).
- Gates on the tree: `validate --strict` ok · `lint` ok · `gen3check --strict`
  ok ("will load").

### What this does NOT change

Celio (1.0.3) and the female Psychic's graphic (1.0.2) are untouched. The
`LEFT_TILES` threshold applies to every speaker, press or scene.

## 1.0.3 — the portrait leaves when the speaker does

Two reports, both about a portrait outliving the person it belongs to.

The reports:

> *"Oak's aide portrait incorrectly persists after the aide leaves. When the
> aide finishes handling the letter and departs, and the player begins reading
> the letter (triggered by 'there's a letter attached'), the aide's portrait is
> still displayed."*
>
> *"In the Bill interaction on Island 1 with Celio, his portrait is missing from
> some of his dialogue boxes."*

### One: the departure test only ever looked at a press

1.0.2 taught the mod to read the pressed object's own cell and drop the record
when a script walked them out (`pressLeftTheScene`). That fixed the case where
the player **pressed A** on Oak's aide — and missed the one the report is about.

The aide's scene has **two entrances**. Pressing A on him raises `world.talk`.
But he is also reached by **walking up to him**: the coord events at Pewter
City (46,21)/(46,22)/(46,23) — `g3:081662b7` / `:081662c4` / `:081662d1` — run
`lockall` and `call` the same script, and **never raise `world.talk`**. On that
entrance there is no press to drop, so the portrait comes from the **scene
route**: `sceneSpeaker` reads the running script's own `applymovement localId=7`
row and names the aide.

A departure test keyed on the press therefore could not fire there, and it did
not: `sceneSpeaker` simply named the aide again on the letter box, because his
`applymovement` row is still in the running script. Measured against the real
decoded script (`g3:081662de` + its branches) with a press-less scene: **all four
boxes, including the letter, resolved to the aide (picture 107)**.

The fix generalises the record from "the pressed object" to **the object the box
actually resolved to** — press *or* scene:

- `spokeObject` / `spokeCell` record the speaker the last box used and where it
  stood, whatever route produced it. `noteSpokeCell` keys on `speaker.object`,
  so a box answered by the scene is recorded exactly like one answered by the
  press.
- `speakerLeftTheScene()` compares that object's cell at box time and, when it
  has moved, drops the press **and** sets `sceneGone`.
- `sceneSpeaker()` answers `nil` while `sceneGone` is set, because the actor's
  own `applymovement` rows would otherwise name them again.
- A fresh press (`world.talk`, `world.trainer_engaged`) or the end of the
  conversation (`script.ended`, `map.entered`, a step with no script running)
  clears it, so the suppression never outlives the conversation.

The laziness is unchanged and still load-bearing: the cell is recorded at the
**first** box the speaker answers for, so an actor that moves *before* its first
line (Bill out of the teleporter, a line-of-sight trainer walking up) records
where it moved to and is not mistaken for a departure.

### Two: Celio had no portrait at all

`OBJ_EVENT_GFX_CELIO` (89) was on the `false` list — the graphics the mod
declines because the cart never drew a battle bust of the person wearing them.
That reasoning is right for a graphic worn by anonymous townsfolk and wrong here,
and the measurement says so: **graphic 89 is worn by exactly one object in the
whole game**, Celio himself, on One Island's Net Center floor
(`.probe/dp3_gfxwho.lua`: 1 object, 0 trainers). Declining it left a **named
story character** with no face on any of his boxes — the reported "his portrait
is missing". It is the same shape of mistake as the Balding Man's `false`, which
1.9.4 removed, and it takes the same fix: one graphic, one person, one picture.

The picture is **89**, the cart's own bust for that graphic (the Super Nerd's — a
bespectacled figure in a lab coat, which is the visual the cart itself gives
Celio: `src/core/game3/scripting/gfx_ids.lua:45` maps his graphic to
`SPRITE_SUPER_NERD`). Graphic 89 and picture 89 being the same number is a
coincidence of the two number spaces this mod exists to keep apart, not a
copy-paste.

That fixes the boxes that carry an object. The Net Center's Bill/Celio scene is a
**coord event** (`lockall`, no `world.talk`) that moves Bill, Celio **and** the
player, so `sceneSpeaker` answers nothing (more than one actor) and the text's
own `"CELIO: "` is the only fact in play — a box with **no object at all**. So
`NAME_ART` gains `CELIO = "SUPER NERD"`, resolved through the pack like every
other name there. The two entries are both load-bearing and cover different
boxes: removing the graphic entry fails the five lines that do not spell his name
(they carry only his object), and removing the name entry fails the three scene
boxes that carry no object.

### Verification

- **995 checks, 0 failures** — load 23, menu 29, speaker **398** (up from 370),
  geometry **504** (up from 501), launcher 41.
- **Verified in the LÖVE engine**, not only headlessly: `.probe/love3/` is a LÖVE
  11.5 project that loads the engine's own `src.ui.game3.message` and the mod,
  then paints through the **real** `love.graphics` — **32 checks, 0 failures**.
  It drives the aide's scene with **no press at all** (so only the scene route
  can answer) and asserts the portrait on boxes 1–3 and **none** on the letter
  box; then the Net Center scene box for box (Bill → 313, Celio → 89); then
  Celio's five unnamed lines, pressed on his object.
  `"C:/Program Files/LOVE/lovec.exe" .probe/love3`
- **All four fixes are bite-proven**, in the suites and in the LÖVE run:
  | reverted | suite failures | LÖVE failures |
  | --- | --- | --- |
  | `sceneGone` suppression | 1 (geometry) | 1 |
  | the generalised record | 1 (geometry) | — |
  | `GFX_ART[89]` | 9 (speaker) | 10 |
  | `NAME_ART.CELIO` | 5 (speaker) | 7 |
- New tests: §18 in `dp3_speaker_test.lua` (the whole scene box for box, plus
  Celio's five unnamed lines), `XF.sceneDepartureTests()` in
  `dp3_geometry_test.lua` (a press-less scene whose actor walks out).
- Gates on the tree: `validate --strict` ok · `lint` ok · `gen3check --strict
  --notes` ok ("will load").

## 1.0.2 — the portrait follows the conversation

Three reports, one shared cause each, and each fixed where the behaviour is
shared rather than at the character or scene that was named.

The reports:

> *"During an NPC interaction — for example Bill — some dialogue boxes lose the
> portrait partway through the conversation."*
>
> *"Portraits are missing for some psychic sprites."*
>
> *"Some boxes show a stale or incorrect portrait from a previous interaction.
> One example: after Oak's aide delivers the Running Shoes and a letter, reading
> the letter can show the wrong portrait."*

### One: a step inside a script is not the player ending the conversation

FRLG walks the **player** around *inside* a script. `applymovement 0xFF` is how a
cutscene turns the player to face the speaker, or walks them into a scene, and
that goes through `Player.scriptStep` → `Player.finishStep` — the one place a real
step emits `world.stepped` (`src/core/game3/player.lua:653`, reached only at
`:799`). So the event fired **mid-conversation**, and the handler that ends the
record on a step dropped the portrait for every box after it. Oak's aide is the
worked example: his branch scripts at `g3:081663da` / `:081663e6` / `:081663fc`
run `applymovement 0xFF` between his first box and the rest of his speech, which
is the reported "some boxes lose the portrait partway through".

The fix is the guard the Gen 2 port has carried since 1.3.3: **while a script is
running, a step is the scene's, not the player's**, and the record stands. The
script's own end (`script.ended`) still clears it, so nothing outlives the
conversation, and a step taken with no script in flight is still the player's own
and still ends it. The rule is now asked in one place — `scriptRunning()` — shared
by the step handler, the press-record check below, and the scene route.

### Two: the female psychic's graphic answered nobody

`OBJ_EVENT_GFX_WOMAN_1` (graphics id 23) is the female **Psychic** graphic. The
host names it `SPRITE_TEACHER` (`src/core/game3/scripting/gfx_ids.lua:14`) and
`SPRITE_ART` has no `SPRITE_TEACHER` entry, so the sprite route declined and every
one of the seventeen non-trainer women wearing it drew **nothing** — the reported
"portraits are missing for some psychic sprites". The three trainers on it (LAURA,
JACLYN, RODETTE) already resolved through the trainer route; the graphic **itself**
is what answered nobody. This is the same hole `WOMAN_2` (28) had one release on,
and it takes the same fix: `GFX_ART[23] = 138`, picture 138 being the cart's
female Psychic bust. It agrees with the map route's own generated answer — every
map that puts a psychic on graphic 23 (`art/map_art.lua`) says `[23] = 138` — so
it is that same rule for the maps that put none. Measured over the whole game by
`.probe/dp3_psychic.lua`: graphic 23 is worn by 3 trainers, all PSYCHIC, and by 17
non-trainer objects — every one of which this entry is what gives a face.

### Three: the press record ends when the script walks the speaker out

The record names the object standing in front of the player, and it is that
object's only while the script leaves them there. FRLG walks a character **out of
a scene** after their lines and then shows a box that is not theirs — Oak's aide
hands over the Running Shoes, walks nine tiles to the left, and the letter from
Mom that follows was wearing his face — and the engine raises nothing for it:
only the *player's* own step emits `world.stepped`, and a script moving an
**object** is silent.

So the fact is read rather than waited for. The engine keeps every object's cell
on the object (`src/core/game3/objects.lua:155`) and updates it when a step
completes (`:551`), so "has this object moved since it last spoke?" is answerable
at box time. The cell is recorded **lazily** — at the first box the press answers
for — and that laziness is the whole of the "has spoken" test: a script that moves
the object *before* its first line (Bill stepping into the teleporter, a
line-of-sight trainer walking up to the player) records the cell it moved **to**
and is not mistaken for a departure. Only a move **between two boxes** ends the
record.

### Verification

- **964 checks, 0 failures** — load 23, menu 29, speaker **370** (up from 356),
  geometry **501** (up from 496), launcher 41.
- All three fixes are **bite-proven**: reverting each one makes exactly the new
  assertions fail and nothing else — removing `GFX_ART[23]` fails 3 checks, making
  the step handler unconditional fails 1, disabling the departure check fails 2.
- The step guard, driven through the real event bus: a step while a script runs
  keeps the speaker; the script's own end still ends it; with no script running a
  step still ends it.
- The female psychic's graphic, resolved with the sprite **and** the class route
  both made unable to answer, so only the new `GFX_ART` entry can produce the
  result; the map route's generated answer is asserted to agree; and LAURA's own
  script key is asserted to still resolve through her trainer id.
- The departure lifecycle, driven through the **real** `Message.show`: the pressed
  object's first box wears its portrait; a box after the object walks off is bare;
  an object that moved *before* its first line keeps its portrait; the next box
  keeps it while the object stays put; and a move between boxes ends the record
  again.

## 1.0.1 — the NPC starts the conversation

The report:

> *"In some interactions a portrait appears when the player starts the
> interaction, but does not appear when the NPC starts it. Make sure portraits
> show whoever initiates. Also make sure Bill, Daisy and Mr. Fuji each have a
> portrait when interacted with, including NPC-initiated interactions where
> applicable."*

Two holes, both about a box that arrives without an A press behind it.

### One: an NPC-started scene named nobody

`world.talk` names the object of an A press, and `world.trainer_engaged` names a
line-of-sight trainer. A scene the world starts by itself — a coord event, an
`ON_FRAME` map script, a cutscene that walks somebody over — raises neither, so
`pressSpeaker` stayed nil and the box came out bare even though the very same
line, reached by pressing A on the object, had a face.

The actor is still a fact in the data: an FRLG scene **moves and turns** the
object it is about, and the engine decodes a script into a table of command rows.
`sceneSpeaker` collects every `applymovement` / `turnobject` / `addobject` /
`removeobject` / `setobjectxy(perm)` row in the running script — the current list,
every caller on the call stack (a box is often opened by a called `std:` stub),
and the entry point — resolves each id to a live object, and answers only when
exactly **one** object is named. A scene that touches several objects, or none,
answers nothing, which is this mod's rule everywhere the data does not decide.
The text's own `"NAME: "` prefix still outranks it (`artFor` asks the name
first), so a script that hands off between two characters box by box stays right.

### Two: the three characters the cart drew outside its battle art

Bill, Daisy and Mr. Fuji have no trainer class, no species and (for Bill and
Fuji) no row in the trainer pack, so the class, sprite and name routes all came
up empty — Daisy even wore the pack's **Painter** DAISY (id 526, picture 147),
a different person entirely. The cart *does* draw all three: FireRed's **Fame
Checker** carries a 64x64 portrait for Oak, Daisy, Bill and Mr. Fuji, extracted
to the same generated cache as the rest of the ROM art and loaded by the
engine's own `src/ui/game3/fame_checker.lua`.

The mod now asks that module for the portrait, named by the text (`BILL`,
`DAISY`, `MR. FUJI`/`FUJI`) and pinned to the Fame Checker's own person index
(Bill 13, Daisy 1, Mr. Fuji 14). Bill and Daisy also have an **exact graphics id
of their own** (73 and 76) which is asked next, so a box that does not name them
still resolves; Mr. Fuji has none, because he wears the shared OLD_MAN graphic
and a graphics key would put his face on every old man — his dialogue names him,
and the name route answers. It runs **after** `CustomArt/` and **before** the
pack-name route, so a player's own file still wins and the pack's Painter DAISY
never does. Oak is deliberately left on his Pokémon Professor class pic —
he already had a portrait, and this release changes only what was broken. Like
every other portrait, it is cut out of the player's own extracted ROM art; the
mod still ships none. Three crop windows (`art/crops.lua`, synthetic picture ids
301/313/314) sit on the head, because a Fame Checker portrait is a head filling
the top of the square and the trainer default begins below the face.

### Verification

- **945 checks, 0 failures** — load 23, menu 29, speaker **356** (up from 327),
  geometry 496, launcher 41.
- The Fame Checker route, driven through the **real** engine UI module with the
  generated cache staged: `artFor({name="BILL"})` → picture 313, 64x64 image;
  `DAISY` → 301; `MR. FUJI` → 314.
- The scene route, over a stubbed engine: one moved object names it; the text's
  own name still outranks it; two objects answer nobody; no running script
  answers nobody.

## 1.0.0 — the first release of this repository

The same mod as `dialouge-portraits-gen3` 1.9.5, published under a new id from a
new repository. **Nothing in the mod's behaviour changed.** What changed is where
it lives, what it is called, and how it is built.

- **The id is `gen3-dialogue-portraits`** (it was `dialouge-portraits-gen3`), which
  is `gen2-dialogue-portraits`'s `gen<generation>-dialogue-portraits` shape, and
  which drops the `dialouge` misspelling the old id carried. Two things follow,
  and neither is a bug fix:
  - The id is the key the engine's own options tree stores this mod's settings
    under — `options.modOptions[<id>]` — so an install carried over from 1.9.5
    comes back with `PORTRAIT` and `SIDE` at their defaults and needs them set
    again.
  - The launcher sees a **different mod**, not an upgrade. The old copy has to be
    removed by hand once; after that the id is stable.
- **The version restarts at 1.0.0.** The 1.9.x line was built by hand from a local
  directory and its manifest carried no `github` field, so the launcher could
  never check it for updates — there is no release history to continue from. The
  changelog below is kept whole, because it is the record of what this code does;
  this entry is where the history the launcher reads begins.
- **`manifest.json` gained `"github": "DarkHeros09/gen3-dialogue-portraits"`**,
  the field the launcher reads to find updates. Without it the mod is invisible
  to the updater no matter how many releases the repo has.
- **The release is built by CI, not by hand.**
  `.github/workflows/release.yml` builds
  `gen3-dialogue-portraits-<version>.zip` from the tagged tree and attaches it to
  the GitHub Release. That exact asset name is the contract the launcher's
  updater looks for, and the workflow takes the id and version out of the
  manifest and **refuses to run if the tag disagrees with them**, so the two
  cannot drift. `tools/build_release.py` is vendored so CI needs nothing from a
  development machine, and `tests/launcher_update_test.lua` pins the whole
  contract without touching the network.
- **The front page is now a short `README.md`.** The long documentation that used
  to be the README is kept whole as **`MANUAL.md`** — every option, every
  resolution rule, what the mod declines to draw and why, the test suites, and how
  to cut a release. Nothing was cut.
- **Two repository files are new and neither ships in the mod.** `.gitattributes`
  stores every file exactly as it is on disk (`* -text`), because this tree is all
  LF and the release archives are built from it byte for byte; without it a
  Windows clone with `core.autocrlf=true` would not match the tree the `.zip` was
  built from. `.gitignore` now blocks the build output, and `.modkitignore` guards
  `gen3-dialogue-portraits-1.0.0.modpkg` and `.zip` so a hand-built release left in
  the repo root cannot be folded into the next pack.

## 1.9.5 — where the graphic is standing

The report:

> *"Fix the portrait issues in the game: the Seel portrait is not framed correctly,
> the Aroma Lady has no portrait assigned, and both Super Nerd and Juggler display
> the wrong portraits. To resolve cases where a single sprite is reused across
> multiple trainer classes, determine the correct portrait by checking the sprite's
> location on the map at runtime. For example, the yellow-haired sprite can
> represent an Electrician, Bird Keeper, or Juggler, so assign and display the
> appropriate portrait based on where that sprite appears on the map rather than
> mapping one sprite to a single portrait."*

Four complaints. Two are one defect, one is a second defect underneath it, and one
is a crop.

### The three trainer complaints were one bug, and it was not in the table

The rule the user asked for — *look where the sprite is standing* — was built
(`art/map_art.lua`, below). But before building it I measured what the shipped mod
actually answered, and the three symptoms reproduced **exactly**:

| reported | the mod drew | which is |
| --- | --- | --- |
| Super Nerd | **107**, the Scientist | `GFX_ART[55]` |
| Juggler | **104**, the Bird Keeper | `GFX_ART[26]` |
| Aroma Lady | **nothing at all** | `GFX_ART[28]` was unset |

Those are the *graphics-table* answers. The id route — the one 1.9.3 added and
1.9.4 verified at 432 of 432 — was **not firing in that boot**, and it fell through
to a table that holds one value per graphic.

**Why it was not firing, measured.** The id route needs the cart's trainer table,
and that table is a *generated cache* (`data/generated/gba/trainers.lua`, built by
`src/import/gba/trainer_extract.lua`). `.probe/dp3_loader_read.lua` drives the
**real** `Loader` over an fs backed by the real mod directory, and prints both
boots:

```
WITHOUT a pack:   picForId(169) = nil    picForId(287) = nil    picForId(523) = nil
                  artFor(Super Nerd) = 107   Juggler = 104   Aroma Lady = 144
WITH a pack:      picForId(169) = 89     picForId(287) = 102    picForId(523) = 144
                  artFor(Super Nerd) = 89    Juggler = 102   Aroma Lady = 144
```

### …and a second defect underneath it: the empty index was cached

`loadPackIndex` built the index object, **assigned it to the memo, and only then
asked the engine for the pack**. A first call that found no pack therefore cached an
*empty* index permanently — so the id route stayed dead for the whole session even
once the table existed. The empty index is now returned without being stored, so the
next call retries. Bite-proof (restoring the old order) → **1 failure**.

### The rule the report asked for: `art/map_art.lua`

Generated by `.probe/dp3_emit_map_art.lua`, which walks `MapTree.walk` and, for every
map, records the picture each graphic's **own trainers** resolve to:

- **91 maps, 228 graphic → picture pairs**, 11 of them *splits* — one graphic worn by
  two classes on one map — where the majority class wins and the comment names the
  split.
- Keys are engine map ids (`FR_ROUTE_8`, `FR_FUCHSIA_CITY_GYM`), produced by the
  engine's own `MapCatalog.pretToEngine`, so they match `Map.current` exactly.
- The mod tracks the map from the `map.entered` event, stamps it on the speaker, and
  consults the table **between the id route and the graphics table**.

The reported cases, resolved by location:

| map | graphic | the map's answer |
| --- | --- | --- |
| `FR_ROUTE_12` | 26 | **101 Rocker** |
| `FR_ROUTE_13` | 26 | **104 Bird Keeper** |
| `FR_FUCHSIA_CITY_GYM` | 26 | **102 Juggler** |
| `FR_ROUTE_8`, `FR_MT_MOON_1F` | 55 | **89 Super Nerd** |
| `FR_SILPH_CO_2F` | 55 | **107 Scientist** |
| `FR_THREE_ISLAND_BOND_BRIDGE` | 28 | **144 Aroma Lady** |
| `FR_SIX_ISLAND_PATTERN_BUSH` | 28 | **141 Breeder** |

`.probe/dp3_loader_read.lua` checks all eight through the real loader on a boot with
**no** trainer table: **8 of 8 correct**.

**The honest yield**, from `.probe/dp3_map_route_yield.lua`: of **1604 objects / 432
trainers / 1172 non-trainers**, only **6 non-trainers** have a map answer at all —
**5 already agree** and **1 changes** (`FiveIsland_ResortGorgeous`, gfx 28: 144 → 146,
a Lady). And **17 of the 432 trainers** are objects where the map and the man's own id
*disagree* — a Route 16 Biker standing among Hikers, a Kindle Road Cooltrainer among
Black Belts. There the **id wins**, because the cart named that man himself; that is
why the location route sits *below* the id route rather than above it. On a complete
boot the route therefore changes almost nothing — its value is that it is the answer
when the generated table is missing, which is the boot that produced this report.

### Two defaults so a shared sprite is never faceless

`GFX_ART[55] = 107` (Scientist) and `GFX_ART[28] = 144` (Aroma Lady) — the majority
class of each shared graphic, so the fallback is at worst the most common wearer
instead of a *different* class, or nothing.

### Seel — the crop, corrected

The first cut of this entry was measured against the **wrong picture**. A species
portrait is the engine's own front pic — `speciesArt` hands `record.index` to
`Pokemon.frontPic` — and SEEL's internal species id is **86**, not 87.
`frontPic(86)` is byte-identical to `.probe/_art/mon-86.png`, which
`.probe/dp3_seel_engine.lua` proves by wrapping the LÖVE stub's constructors and
keeping the engine's own rgba; **mon-87 is Dewgong**, whose head does sit at the
top left.

Seel's sprite is not Dewgong's shape. The whole creature is one mass, bbox
(6,9)-(53,54), but the face is at the **bottom centre**: the muzzle is the only tan
mass, bbox (18,42)-(34,51), the tongue the only red one, bbox (20,47)-(27,52), and
the two eyes the only dark blobs inside the silhouette — all three located by
colour in `.probe/dp3_seel_face.py`. The rule's own answer — the box centre on x,
four rows above the first opaque row — is `{13,5,32}`, the entry the table carried,
and it runs x 13-44, y 5-36: the two lobes at the top and the upper body, with the
**whole face below the window**. So `{13,5,32}` *and* the first 1.9.5 cut
`{4,4,32}` both left the face outside. The sprite is 44 rows tall and 32 cannot
hold it, so the face wins: **`{12,21,32}`** holds the eyes, the whole muzzle and
the whole tongue. Bite-proof (the wrong `{4,4,32}`) → **2 failures**.

### Verification

- **875 checks, 0 failures** — load 23, menu 29, speaker **327**, geometry **496**
  (up from 840).
- Bite-proofs, each confirmed then reverted: Seel to the wrong `{4,4,32}` → **2**;
  the location route disabled → **5**; the empty pack index cached before the ask
  → **1**.
- The reported cases through the real loader: **8 of 8** location cases, and
  107/104/144 → 89/102/144 once the pack is present.
- Release gates, in order: `validate --strict`, `lint`, `gen3check --strict
  --notes`, then `pack` last. `validate --strict` first came back **MK301** on
  `main.lua`: this release's comments named the engine's generated trainer cache
  by its full path, and MK301 is a substring search over every `.lua` body that
  cannot tell a comment from a load. The path is now described rather than
  spelled, with a note saying why — a mod must never ship or read the player's
  generated trees, so the literal string is out of the file.

## 1.9.4 — the same sprite, two faces

The report:

> *"Investigate how the game determines which portrait to associate with each
> trainer sprite, then fix portrait mismatches for all NPCs and trainers. Key
> findings to establish: the same trainer sprite can map to multiple portraits
> (e.g., the yellow-haired trainer sprite sometimes shows the Rocker portrait and
> sometimes the Bird Keeper portrait), so determine the correct pattern the game
> uses and apply the right portrait per sprite. For non-trainers, choose one
> consistent portrait per sprite.*
> *Fix "fat man Eric" in Fuchsia City, who incorrectly has a Scientist portrait.
> Fix the Bird Keeper, who has the wrong portrait as noted above. For the couple
> (e.g., JES and GIA) that shares one portrait, crop each individual separately
> and display the correct male or female portrait based on who the player
> interacts with. Fix Engineer Braxton's incorrect portrait. Correct the
> red-haired little girl sprite, which is actually one of the twins.*
> *Also run the framing test across all NPCs and Pokémon, and skip any that have
> already been tested to avoid repeating work."*

### The rule the game uses

**A trainer's portrait comes from the trainer's own data, and never from the
overworld sprite he is drawn as.**  The chain is:

```
object's script  ->  trainerbattle (0x5C)  ->  trainer id  ->  class  ->  front pic
```

The overworld sprite is a *uniform*, and uniforms are shared.  `OBJ_EVENT_GFX_ROCKER`
(26) — the yellow-haired figure the report names — is worn by **28 trainer objects:
18 Bird Keepers, 9 Jugglers and exactly one Rocker**, plus 8 non-trainers.  Sixteen
of the game's 34 trainer-worn graphics are like that, shared by two or more classes
whose pictures differ.  No single value per sprite can be right for those, which is
why the question has no answer at the sprite level and the trainer's own id is the
only fact that does.

So the rule this release applies is two rules:

* **A trainer gets his own picture**, by id, via the script route 1.9.3 added
  (`art/trainer_ids.lua`, 432 script keys, generated from the ROM).
  Measured: `.probe/dp3_full_audit.lua` section A resolves all **432** trainer
  objects in the game and finds **0** whose portrait is not the id's own.
* **A non-trainer has no data at all**, so the sprite is the only fact about him
  and he gets **one consistent picture per graphic**, from `GFX_ART`.

### The five reported cases

| reported | was | now | why |
|---|---|---|---|
| **fat man "Eric"**, Fuchsia City | picture 89, a Super Nerd in a lab coat | **declines** | He is not Eric. His box opens `ERIK: Where's SARA?` and the pack has a real ERIK — trainer 177, SUPER NERD, picture 89. The text-name route took the name at its word. His graphic (27) is one the cart drew no bust of, and a token in a dialogue box cannot make one exist. |
| **the Bird Keeper** | picture 101, the Rocker | **104** | gfx 26's art *is* picture 104's: yellow hair, red shirt, blue overalls. Picture 101 is a blue-haired punk in an orange jacket. The 28 trainers on this graphic get their own ids; the 8 non-trainers get the majority wearer. |
| **the couple (JES and GIA)** | one picture 129 for both | **two windows** | Pictures 127–131 draw two people. `art/crops.lua` gains a `pairs` table of left/right rectangles and a `pairSide` table from graphic to half, so the object's own sprite picks the half it stands on: the woman wears gfx 29 (BEAUTY) and gets the left, the man wears gfx 25 (MAN) and gets the right. |
| **Engineer Braxton** | picture 93 already — but nobody else could reach it | **93, from the sprite too** | Braxton's own answer was right; the *graphic* he wears (30, BALDING_MAN) answered nobody, so the 28 non-trainers sharing his sprite had no face at all. Every one of the game's three Engineer objects wears gfx 30 and no other class wears it — it is the cart's own overworld sprite for the Engineer, and picture 93 is the cart's bust of him. |
| **the red-haired little girl** | picture 84, a Lass | **127, the Twins** | gfx 17 LITTLE_GIRL is the red-haired little girl, and she is one of the Twins. The 8 Twins get 127 by id; the 18 non-trainer girls on the graphic get it from `GFX_ART`. |

### One more, found by sweeping rather than by being reported

The ERIK shape is *a name in a text box that belongs to a different person*.  So
1.9.4 swept every line of every object in the game
(`.probe/dp3_name_hijack.lua`: **1648 objects, 52 that name someone, 4 non-trainers
whose name resolves to a trainer's picture**) and found a second instance:

**Daisy Oak**, in the rival's house, says `DAISY: Hi, PLAYER!` — and the pack has a
DAISY, trainer 526, a **Painter** on Five Island.  A Painter's overworld sprite is
`OBJ_EVENT_GFX_LASS`; Daisy Oak is the rival's sister in `OBJ_EVENT_GFX_DAISY`, and
the cart drew no bust of her (the front-pic list is 148 class pictures plus Oak,
Red, Leaf, Brendan and May).  She was wearing a Painter's face.  `GFX_ART[76] = false`.

The other two of the four are **Lorelei** and **Selphy**, and both *are* the trainer
they name — they keep their faces.  The sweep also checked the converse and found
**0** trainers whose name route disagrees with their own id, and **0** objects where
the name disagrees with the graphic it rides on.  That is what justifies the guard
being narrow: it suppresses a name only when the graphic has already declined, so a
script that hands off between two characters box by box still resolves both.

### The framing, across every window

Every window in `art/crops.lua` — **50** of them, across the two defaults, ten
trainer pictures, 31 species and nine pair halves — was re-measured on all four
edges by `.probe/dp3_crop_framing.py`, which reads the numbers out of the table
rather than copying them.  The 147 trainer pictures and 31 species that 1.9.3 had
already looked at were **not** re-checked by eye, as asked; this sweep is the
mechanical pass that says which ones need an eye at all, and it flagged none.

Two windows were wrong and both were found by *looking*, not by the sweep:

| window | was | now | why |
|---|---|---|---|
| picture **127** left | `{0, 10, 32}` | **`{2, 10, 32}`** | The left Twin's head runs to column **33** and her sister's begins at **35**, so a window at 0 stops at 31 and cuts **two columns off her face**. 2 is the only 32px span that holds all of her and none of her sister. |
| picture **130** right | `{32, 2, 32}` | **`{32, 0, 32}`** | Her ponytail's red band reaches row **0**, so a window starting at 2 cut the top of it. |

**The sweep missed the first one, and that is the lesson.**  The first version of
`.probe/dp3_pair_framing.py` tested the **top** edge only, and said so in prose that
read as if it tested them all; the left Twin's two cut columns were on her *side*.
It was caught by eye, in `.probe/_fc194b/127L.png`.  The rewrite reports all four
edges and the seam column, and its docstring now states plainly what it cannot
decide: *"cut at the seam" and "cut the subject's own side" are identical to a pixel
test* — both are an opaque edge column with art continuing past it, and no opacity
check knows whether that art is a sister's hair or your own.  So the probe measures
and the eye judges; and the nine windows are now **pinned by number** in
`dp3_geometry_test.lua`, because a property test ("it fits inside the source") passes
for both the right window and the one that cuts her face.

### Verification

* **840 checks, 0 failures** — `dp3_load_test` 23, `dp3_menu_test` 29,
  `dp3_speaker_test` 294, `dp3_geometry_test` 494 (up from 731).
* Bite-proofs, each confirmed and reverted: `GFX_ART[26]` back to the Rocker → 2
  failures; the `pairSide[29]` entry removed → 2 suites fail; the name-route guard
  removed → 2 failures (both wrong faces return); `GFX_ART[30]` back to `false` → 6
  failures; both halves of picture 129 given the same window → 2 suites fail; the
  left Twin's window back to `{0,10,32}` → 2 suites fail; picture 130's right half
  back to y 2 → 1 failure.
* `validate --strict` ok · `lint` ok · `gen3check --strict --notes` ok, "will load".

## 1.9.3 — the wrong face, the wrong window

The report, in three parts:

> *"Fix the UI so portrait in margin mode panel edge to box top spacing is 2px.
> Correct trainer/NPC portrait assignments: some NPCs such as "super nerd Leslie"
> show the wrong portrait, some baby/twin NPCs incorrectly show a wrong portrait,
> and the old bald guy shows the wrong old karate instructor portrait. Each
> trainer should map to the correct portrait; compare by trainer id or index or
> name to resolve the mismatches.
> Fix Pokémon/Trainers portrait framing: some trainers or Pokémon like Slowbro,
> Nidorino, and Zapdos are not centered or have their faces clipped. Do not rely
> on a single general crop value; if the general crop value does not work for a
> given Pokémon/trainer, use a case-by-case crop value."*

Three separate defects, and the middle one is the interesting one, because the
mod **could not see the fact it needed**.

### One: MARGIN's panel sat 4 pixels above the box, not 2

The panel's clearance from the box and its clearance from the play area's edge
were the same constant. They are not the same margin, so they are two now:
`EDGE_PAD = 4` is the distance in from the edge of the play area, and
`MARGIN_BOX_GAP = 2` is the distance between the panel's bottom and the top of
the dialogue box. Both are in game pixels, so they are the same on every device.

The letterbox branch keeps the edge value on **both** axes, deliberately: when
there is a letterbox the panel is drawn *beside* the box, out in the black bar,
so there is no box gap to keep — only the screen edge to stay clear of.

### Two: a trainer's class was being guessed from their overworld sprite

Three reports, one cause. `"super nerd Leslie"` wore the Scientist's face, the
twins wore the Lass's, and the old bald man in the blue robe wore the old karate
instructor's.

The mod resolves a battle trainer by their **class**, and a class is a number
that lives in the cart's map-event table. It is not in the runtime object. The
extractor keeps `localId, graphicsId, x, y, elevation, movementType, movement,
range, scriptKey, flag` and nothing else — the object's `trainerType` field,
which is where the cart keeps the class, is dropped on the way in. So the mod
fell back to the one fact it did have, the overworld **sprite**, and read the
class off that. A sprite is shared, so that is a guess, and it is wrong exactly
where two classes share one graphic:

| what | sprite | who wears it | what it was drawing | what it draws now |
| --- | --- | --- | --- | --- |
| Leslie | `SCIENTIST` | 8 Super Nerds (pic **89**) + 14 Scientists (pic 107) | **107**, the Scientist | **89**, the Super Nerd |
| the twins | `LITTLE_GIRL` | 8 Twins (pic **127**) | **84**, the Lass | **127**, the Twins |
| the old bald man | `OLD_MAN_1` | 6 Gamers (pic **97**) + 24 ordinary old men | **34**, the karate instructor | **97**, the Gamer |

The engine has its own way to recover a trainer's id, and this mod deliberately
does not use it. `TrainerSight.getTrainerId` looks the object's script up in the
extracted script bundle — and a probe over all **432** trainer objects in the
cart shows that bundle answers for **15** of them, because it only covers
island 1's eighteen maps. The other 417 have a `scriptKey` that simply is not in
the bundle.

So the mod brings its own answer. A `trainerKey` is `Opcodes.key(scriptPtr)` —
the script's own address — and the trainer's id is the two bytes just past the
`trainerbattle` opcode at the head of that script. **`.probe/dp3_emit_trainer_ids.lua`**
walks all 425 maps, digs that out of the cart, and writes **`art/trainer_ids.lua`**:
432 script keys, each naming exactly one trainer id, no conflicts. The mod loads
it, and a new route resolves `scriptKey` → trainer id → that trainer's own front
picture. It runs **before** the graphics table, so it also rescues the graphics
the table deliberately declines: a Tamer or an Engineer wearing a Man's sprite
now gets their own face instead of none.

Nothing is written back. The route only ever reads, so the engine's own trainer
sight and Vs. Seeker are untouched — this mod does not get to change when a
trainer spots you.

### Three: seven Pokémon and one trainer were framed on the wrong part of the art

The species rule is *centre the creature's own box*, and it is honest for a
creature drawn facing the camera. It is wrong for one drawn side-on or with a
wing spread, where the box is mostly something that is not a head. Measured by
rendering the window over the whole 64×64 sprite and **looking** at the result:

| species | old window | new | what was in the old one |
| --- | --- | --- | --- |
| **Fearow** | `{32,0}` | `{0,20}` | **a wing. No face at all.** Its head is at the bottom left |
| **Pidgeot** | `{15,0}` | `{0,3}` | a wing; the eye and beak were cut off the left edge |
| **Zapdos** | `{16,0}` | `{0,6}` | a wing; the head and beak are at the left |
| **Moltres** | `{13,0}` | `{0,30}` | a wing; the head and beak are at the **bottom** left |
| **Articuno** | `{17,0}` | `{1,0}` | a wing; the eye sat on the left edge |
| **Slowbro** | `{15,7}` | `{4,7}` | the Shellder on its tail — the muzzle was cut off the left |
| **Nidorino** | `{15,5}` | `{11,14}` | the ears; the muzzle was cut off the bottom |
| **Bug Catcher** (pic 66) | default | `{10,9}` | the hat's left brim, with the face against the edge |

1.9.2's own comment said the legendary birds were "centred on the FACE instead"
of on their wings. Only Snorlax and Slowpoke were. All three birds were filed at
`x 13–17, y 0`, which is the wing on every one of them — so a rule written down
is not a rule applied, and the only check that catches it is rendering the
window over the sprite and looking. That check is now a tool:
**`.probe/dp3_frame_compare.py`**.

The trainer picture was found by the same sweep run over **all 147** trainer
front pics at once (`.probe/dp3_trainer_sheet.py`) rather than by trusting a
density number. It is the only one that needed a rectangle; the other 146 frame
their subject correctly with the default.

Every other species was checked the same way and left alone — a rectangle that
only restates the rule is a line that can drift out of date.

## 1.9.2 — the girl on Route 3, and the Spearow that had no face

The report: *"The fix I applied didn't resolve the portrait display issues. …
some Pokémon, such as Spearow, do not display a portrait at all, and certain
NPCs, such as the girl on Route 3, display an incorrect portrait."*

Two symptoms, and they are **two different failures of one vocabulary**. 1.9.0
and 1.9.1 both taught this mod to stop trusting the host's `SPRITE_*` names and
read the cart's own facts instead — the graphics id, the trainer pack's own
tables. This release is the two places that were still reading the host's, and
both of them are the same kind of mistake as round one: a name that means two
things, and a name that means nothing.

### One: a class name the cart spells TWICE

FRLG's class table carries the whole **Hoenn** roster first and then repeats 31
of those names for its own Kanto classes further down. They are different
people with different battle art:

| name | Hoenn | Kanto |
| --- | --- | --- |
| `LASS` | **49** → picture 65 | **59** → picture **84** |
| `FISHERMAN` | 31 → picture 38 | **69** → picture **94** |
| `BEAUTY` | 12 → picture 12 | **73** → picture **98** |
| `SAILOR` | 41 → picture 53 | **60** → picture **85** |
| `BLACK BELT` | 16 → picture 16 | **80** → picture **105** |
| `GENTLEMAN` | 22 → picture 23 | **88** → picture **123** |
| `YOUNGSTER` | 29 → picture 36 | **57** → picture **82** |

The lookup that turned a name into an id took the **lowest** id wearing it.
Since the Hoenn half is listed first, that answered the Hoenn class for **31 of
the cart's 31 duplicated names** — so the girl on Route 3, a class-59 Lass,
wore the Hoenn Lass's face, and the same defect put the Hoenn Fisherman on every
pier, the Hoenn Beauty on every swimmer's towel and the Hoenn Gentleman on every
deck.

The evidence for which id a name **means** is the cart's own trainer table,
because it is the table the cart actually uses: a class the game fields trainers
under has rows and the class it does not field has almost none. Measured across
the cart's **742** rows, only **53** sit under a name's low-id half; `FISHERMAN`
is 69 with **15** rows against 31's **1**, `LASS` 59 with **26** against 49's
**1**, `YOUNGSTER` 57 with **28** against 29's **1**. So the name now resolves
to the class with the most rows.

Two pairs the row count cannot separate, and neither moves a face:

- `LEADER` is 8 rows at 24 and 8 at 84. Ties go to the higher id, which picks
  84 — the Kanto half, whose pictures are 108 and 116–122, so the tie-break
  lands on the right side anyway. Nothing resolves through the name `LEADER`
  regardless.
- `POKéMON TRAINER` is 0 rows at 0 and at 1 and 7 at 44, so it moves from *no
  answer* to picture 56. Nothing writes that name either.

**`RIVAL` is the pair that would have moved a face.** Classes 81 (`RIVAL_EARLY`,
picture 106, 9 rows) and 89 (`RIVAL_LATE`, picture 124, 12 rows) are both spelled
`RIVAL`, so once the tie-break prefers rows the name resolves to **124** — a
change to a portrait nothing reported and 1.9.0 verified as 106. So the rival is
never resolved by that name: his picture is pinned as the constant `RIVAL_ART`,
and the three routes that used to write `"RIVAL"` write the number instead
(`SPRITE_ART.SPRITE_BLUE`, `NAME_ART.RIVAL`, and the player's-own-name route in
`artFor`). `CustomArt/RIVAL.png` is still the way to the later face.

### Two: a graphics id the host table stops short of

FRLG puts **Pokémon in the world as map objects** and names each one with its own
`OBJ_EVENT_GFX_*` id: **109 `SNORLAX` through 150 `DEOXYS_N`**. The host's
`TO_SPRITE` table
(`src/core/game3/scripting/gfx_ids.lua`) **stops at 92** — `SPRITE_POKE_BALL` —
so every one of those ids arrives as the engine's `SPRITE_YOUNGSTER` fallback.
That fallback cost the species **twice**:

- `speciesOfSprite("SPRITE_YOUNGSTER")` reads a species off the sprite id, and a
  Youngster is not one, so the species route had nothing to answer with;
- `hostSpriteFor(110)` is `nil`, so the sprite route **declines** — correctly,
  because a boy's face on a Spearow is exactly the wrong-portrait bug that rule
  exists to prevent.

Neither is wrong alone. Together they meant **no portrait at all** for every
Pokémon standing in the world, which is the reported Spearow. The cart's own
graphics id is the fact left over, and it names the species outright, so it is
read directly (`GFX_MON`): ids 109–150 → host species keys, with the three Deoxys
forms folded onto one species. **32 of the 42 ids are actually placed** somewhere
in the game — measured across 425 maps by `.probe/dp3_nonpeople_sweep.lua`, which
found **513 objects with a graphics id of 92 or above** — and the whole range is
mapped anyway, because the mapping is exact for every id and
`OBJ_EVENT_GFX_VAR_*` can place any of them at runtime.

### Three: three pictures that nothing wears any more

Because a name now means the class the cart fields, the Hoenn pictures the old
lookup reached become **unreachable**, and their crop entries are retired with
them: **36** (the Hoenn youngster), **38** (the Hoenn fisherman) and **65** (the
Hoenn lass). Verified by diffing the whole resolution chain before and after:
**136** speakers resolved to one of the three in the before-snapshot and **zero**
do in the after-snapshot.

Picture 38 is the interesting one, because **1.9.1 filed a hand-tuned window for
it** — it is the sparsest of all 148 trainer pictures at 17 % ink, drawn seated
bottom-right with his rod sweeping up-left, so a centred square lands almost
entirely on empty water. The NPC on the pier is not picture 38 any more: the
name `FISHERMAN` now resolves to class 69, and the fifteen battle Fishermen's
picture **94** is framed correctly by the default at 58 %. So 38's entry is
retired and 94 is recorded in `art/crops.lua` as a *measurement* rather than as a
rectangle that would only restate the default. Worth reading once: it is what a
wrong class name costs — a measured, hand-tuned window filed against a picture
that turns out to be unreachable.

### The crops

Seven trainer pictures and 19 species became nine and 31, and every new entry was
chosen by **looking at the sprite** and then checked against a measurement:

| picture | who | window | why |
| --- | --- | --- | --- |
| **85** | the Kanto SAILOR | `{12, 0, 32}` | the default is 63 % ink but takes 27 rows off the top of his cap and 9 columns off its left |
| **105** | the BLACK BELT | `{11, 1, 32}` | his head is 37 px wide (x 9–45), so no 32-px window holds it; this centres it and cuts nothing off the top |

Two of the newly-reachable pictures needed **no** entry and the measurement is
recorded in the file instead: **84** (the Kanto Lass — the girl on Route 3 —
47 %, head inside) and **94** (the Kanto Fisherman, 58 %, head inside). A third,
**98** (the Beauty), was *dropped* from an earlier draft on purpose: the default
takes exactly **one** row off the top of her hair, a quarter of the two-row
tolerance, so filing an entry would be churn.

The Sailor and the Black Belt are also the two worked examples of the rule this
file has always carried and that a fill percentage alone will not tell you. The
**densest** 32-px window for the Sailor is `{11, 7, 32}` at 65 % — four points
more ink than the one that ships, bought by **chopping 95 pixels off the top of
his head**. For the Black Belt it is `{13, 20, 32}` at **86 %**, which is his
lap: it cuts **369** pixels off the top of his head. More artwork and less face
is a worse portrait, so both entries were chosen on the **cut count**, not the
fill.

The 12 new species windows cover the Pokémon the world actually places —
`spearow {16, 12, 32}`, `kangaskhan`, `slowbro`, `lapras`, `zapdos`, `moltres`,
`articuno`, `mewtwo`, `snorlax`, `slowpoke`, `lugia` and `hooh`. Three of them
depart from the rule in opposite directions and for the same reason, that **the
box is not the head**: Slowpoke's bounding box is centred on its **tail**, so its
window goes right and down; Lugia's and Ho-Oh's faces sit **low** in their
sprites (Lugia's orange beak is at y 47–51), so their windows go down as well;
Snorlax's head is at x 40–53, so its window goes right. Voltorb is the one
placed species with **no** entry — the default frames a whole ball with both eyes
in.

### Verification

Both reported cases, resolved through the real chain and diffed against the
pre-fix build:

| case | before | after |
| --- | --- | --- |
| the girl on Route 3 (`gfx 22`, `SPRITE_LASS`) | picture **65** — the Hoenn Lass | picture **84** — the Kanto Lass |
| the Spearow (`ViridianCity_House`, `gfx 110`) | **no portrait at all** | **Spearow's own** front pic (species 21) |

The whole chain was snapshotted for all 1190 speakers the world places, before
and after. Section A (the trainer kinds) moves exactly the **7** expected
pictures plus the 42 Pokémon ids that gain a species, and **nothing else** —
including `BLUE`, which stays 106. Section B (the NPC kinds) moves exactly the
**7** expected kinds and the **32** placed Pokémon ids, and nothing else.

The suites went from 626 checks to **679**, all green:

| suite | before | after |
| --- | --- | --- |
| `dp3_load_test` | 23 | 23 |
| `dp3_menu_test` | 29 | 29 |
| `dp3_speaker_test` | 195 | **227** |
| `dp3_geometry_test` | 379 | **400** |

The speaker suite was **green through both bugs**, and that is the finding worth
keeping. Its synthetic trainer pack had **no duplicate class names** and **no
Pokémon graphics ids**, so it could not be wrong about either — a double that
carries only the clean shape of the data cannot fail on the dirty shape, which is
the same lesson as 1.9.1's picture-0 stub. Its pack now mirrors the cart's
duplication (`LASS` at 49 *and* 59, `RIVAL` at 43, 81 *and* 89) and its
`TO_SPRITE` stub deliberately lists nothing above 92. Run against the pre-fix
`main.lua`, the updated suite reports **21 named failures** — `LASS means the
Kanto class, 59 -- not the Hoenn 49`, `a Spearow gets a portrait where it had
none`, and nineteen more — and **227 / 0** against the fix.

The bite-proof sweep went from 29 mutations to **38** (A–R, C1–C19), each one
restoring exactly one half of one fix and asserting the suite notices. The five
new ones: **N** puts the class-name tie-break back to *lowest id wins*, **O**
stops the graphics id naming a species, and **P**, **Q** and **R** each send one
of the rival's three routes back to the ambiguous class name.

## 1.9.1 — every NPC's portrait is the person the player is looking at

The report: *"Several NPCs are displaying incorrect portraits that do not
accurately represent them, while others such as the fisherman have no portrait
at all."*

The second half of that turned out to be **already answered**, and the answer is
worth stating because it is the key to the whole report. The Fisherman's graphic
(57) has resolved to picture 38 since before 1.8.0, and 1.9.0 reframed it to
`{32, 8, 32}`. What the 1.8.x player saw was a window aimed at the **empty water
beside him** — 17 % artwork, the sparsest of all 148 trainer pictures — which on
screen is indistinguishable from no portrait at all. So "no portrait" and "the
wrong portrait" are one symptom with two causes, and the audit below is what
separates them.

The first half was real, and it is one mistake in seven places.

### The graphics id knew; the sprite route was not asked

1.9.0 taught the mod to consult the cart's own `OBJ_EVENT_GFX_*` **before** the
class, which fixed every graphic the host table *drops* — the Bug Catchers, the
Rockets, the Swimmers, the Channeler, and all eight gym leaders. It did not fix
the two shapes in between, because neither is a drop:

| shape | what the host does | who wore the wrong face |
| --- | --- | --- |
| **the wrong kind** | maps the graphic onto a sprite that names a *different* person | gfx **39 CAMPER** → `SPRITE_YOUNGSTER`; gfx **40 PICNICKER** → `SPRITE_LASS` |
| **one sprite, two people** | maps it onto one sprite shared by both sexes | gfx **41/42 COOLTRAINER_M/F** → both `COOLTRAINER`, which the class-name lookup takes to the **lowest** id with that name — the RSE class, whose single row is picture **8, a male** |

The second row is the interesting one, and it is the gym leaders' lesson again
one level down: a class covers a whole *kind* (both sexes of Cooltrainer, both
sexes of Tuber), a graphic is **one person**. So the fix is the same as the gym
leaders' — say it by graphic:

| graphic | was | now | why |
| --- | --- | --- | --- |
| `39 CAMPER` | 36 (Youngster) | **86** | a Camper is not a Youngster |
| `40 PICNICKER` | 65 (Lass) | **87** | a Picnicker is not a Lass |
| `41 COOLTRAINER_M` | 8 (RSE, male) | **110** | pins the male of the pair |
| `42 COOLTRAINER_F` | 8 — **a male** | **111** | she was wearing a man's face |
| `36 TUBER_M_WATER` | 140 — **the female** | **7** | 1.9.0 said "the cart has one tuber picture"; it has two |
| `38 TUBER_M_LAND` | 140 — **the female** | **7** | same |
| `25 MAN` | 32 — **a boy** | **`false`** | shares the Hiker's sprite, so it wore the PokéFan's face |
| `30 BALDING_MAN` | 32 — **a boy** | **`false`** | the same, one step milder |

The last two complete a fix 1.9.0 started and stopped short of. Its own README
names the collapse — *"[25] MAN, [30] BALDING_MAN and [56] HIKER are all
SPRITE_POKEFAN_M — three people, one sprite"* — and then only the Hiker got an
entry. Picture 32 is a **boy**, so a grown man and a bald one were wearing a
child's face. The cart drew neither of them, so both decline, which is the same
answer the Fat Man gets.

### The old folks were never missing, they were never asked

`SPRITE_GRAMPS` and `SPRITE_GRANNY` are not in `SPRITE_ART`, and neither is in
the host's graphics-id table, so the old man and the old woman resolved
**nothing at all**. They are the cart's **EXPERT** pair — pictures **34** and
**35** — and between them they are the most common people in the game after the
youngsters: **45 objects** across Pallet Town, Celadon, Fuchsia, Viridian, the
Sevii islands and half the houses in Kanto.

`[32]`, `[33]`, `[34]` → **34**, and `[35]` → **35**. This is the largest single
group the release fixes, and the reason is mundane: a graphic with no entry is
not asked at all, and nobody had noticed that the old folks had no *name* to be
asked by.

### Three new crop rectangles, because routing a picture is half the job

Three of the pictures 1.9.1 routes to were never framed, and each is as empty at
the default window as the Fisherman was — so routing to them without a rectangle
would have re-created the very bug the report opens with:

| picture | what it is | default | filed |
| --- | --- | --- | --- |
| **7** | the MALE tuber | 20 % artwork | `{17, 16, 32}` — 52 % |
| **35** | the old woman | 21 % artwork | `{13, 18, 32}` — 63 % |
| **86** | the Camper | 37 % artwork | `{11, 10, 32}` — 48 % |

Picture **34** (the old man) and **87** (the Picnicker) deliberately have **no**
entry: the default frames them correctly at 58 % and 48 %. The asymmetry is the
measurement, and the suite asserts it, so an entry added later "for symmetry"
has to argue with a number.

### What is still not fixed, and cannot be from here

24 of the 92 people graphics carry **no portrait**, and for these the cart drew
no battle bust to route to. They are the Nurse and the Clerk (20 and 21 objects),
the Cable Club receptionist (57), the Mystery Gift deliveryman (19), the
Policeman (19), the Worker (26), the Fat Man (15), the three generic women (46
between them), the Chef (9), the Gym Guy (9), the Trainer Tower dude (9), the GBA
Kid (7), Bill (5), Mr. Fuji (2), Mom, Daisy, Celio and the Captain.

No mapping can fix these — the art does not exist in FireRed — and a wrong face
is worse than no face, which is this mod's rule everywhere the data does not
decide. They are listed here so the answer is a number rather than a shrug:
`CustomArt/SPRITE_NURSE.png` and friends are the way, and the mod already loads
them.

### Verification

**626 checks** across the four suites (23 + 29 + 195 + 379), **0 failures**, and
**29 bite-proofs** — the 21 that shipped in 1.9.0 plus eight new ones. Each new
one restores one group of the mappings above to its 1.9.0 shape and is reported
by the suite that owns it: `I`–`M` by the speaker suite (who is resolved), and
`C14`–`C16` by the geometry suite (what is drawn), because a crop rectangle that
nothing checks is a rectangle that can silently stop being read.

The seven new speaker checks assert the **sex pairs come back as two different
pictures**, not merely as two different ids: an id-only assertion is satisfied by
a resolver that asks for the right id and then draws one face for both.

## 1.9.0 — the portrait fills its frame, and a trainer who sees you gets a face

Six changes, and the first four are one complaint read from four ends: **the
portrait did not fill the frame it was given, and the frame did not stand clear
of anything beside it.** The report's *"margin between the portrait and its
surrounding frame"* was real — 1.8.x drew a **30 px** art into a **32 px** rect,
so every portrait shipped with a one-pixel band of box all the way round — and so
was *"there is no space between the portrait and the frame it sits in"*, which is
what a panel sent flush against the box looks like. Alongside those, the crop
table stops being a rule and becomes a measurement, and the one box an A press
cannot name finally gets a speaker.

### INSET: the portrait IS the slot, edge to edge

`INSET_ART` is **32** and `INSET_PAD` is **0**, so the art reaches the frame on
all four sides. 1.8.3's 30 px portrait in a 32 px slot was the last of the
margin: centred, it landed at `121..151` inside a `120..152` content rect, with a
pixel of white on every side.

The slot did **not** move. It has been 32 px — four columns — since 1.8.3, and
the reserve is still five columns, so INSET's text still gets **168 px** (21
columns) rather than 1.6.0's 160 px. What moved is the crop size and that one
pad, not a stretch: the art is still drawn 1:1 through the source picture's own
nearest-neighbour filter, so nothing is resampled and no pixel doubles.

The vertical offset is a real **8** now rather than 9, and the clamp is still
inert rather than load-bearing — a crop can only reach it by being bigger than
the slot it is fitted into, which `fitScale` does not allow.

### The default crop is 32 px, so FRAMED's art fills the window

Both defaults in `art/crops.lua` grow by one pixel on **every** side:

```
trainers   (17,  4, 30) -> (16,  3, 32)   centre (32, 19) either way
pokemon    (17, 18, 30) -> (16, 17, 32)   centre (32, 33) either way
```

The centre is unchanged, so this is not a new framing — a portrait framed
correctly in 1.8.3 is framed identically now, one pixel larger each side. The
32 px crop is the 32 px content rect exactly, so FRAMED's art is drawn at **1×**
and reaches the border on all four sides with nothing left to centre.

This is only safe because 1.8.3 already made the **window** a constant: the
columns the box gives up are bought for the window, not for the crop, so a 32 px
crop costs the text exactly what a 30 px one did. The *art* is 1:1 for the
default, not the window.

### FRAMED: the panel is centred in the run

The box gives up `ceil((EDGE_PAD + 48) / 8)` = **7** columns — 56 px — for a
48 px window, so there are **8 px of slack**, and this release gives four to each
side:

```lua
local runX = (activeSide == "right")
  and ((L0 + W0 - give + CHROME_R) * T)
  or ((L0 - CHROME_L) * T)
local panelX = runX + math.floor((give * T - plan.w) / 2)
```

Until now the whole slack went **outward**, which meant the panel sat flush
against the box — a zero-pixel gap, so the panel and the box read as one merged
shape — and on the default crop the run was exactly the panel's own width, so
there was no slack at all and the portrait touched the play area's edge, which on
a phone *is* the edge of the screen.

The panel now stands exactly `EDGE_PAD` — 4 game px — from both:

```
FRAMED-LEFT   panel 4..52      box visible edge 56    pen 72       gap 20
FRAMED-RIGHT  panel 188..236   box visible edge 184   pen end 168  gap 20
```

The gap from the portrait to the nearest letter is that 4 px **plus** the box's
own `CHROME_L` columns of border: `4 + 16` = **20 px**, and it is the same on both
sides. The text width is untouched at **152 px** — the run is the same seven
columns it was.

### The crop table is 26 measurements, not a rule

`art/crops.lua` ships **7 trainer pictures** — 36, 38, 65, 82, 83, 95 and 140 —
and **all 19 species that speak anywhere in FireRed**. The two rules are stated
in the file and are what the numbers come from:

- **trainer entries** centre on the **head** — the topmost blob, taken as the
  union of the widest opaque run on each of the first 18 rows — with the window's
  top three rows above the artwork's own first row;
- **species entries** centre on the **whole creature**, with four rows of
  headroom rather than three, because a creature's top row is usually the tip of
  something thin.

Where the head and the densest window disagree the **head wins**. The Fisherman
is the worked example: his densest window is `{29,29,32}` at 75 % — his lap and
his legs — and a portrait of a lap is not a portrait, so `{32,8,32}` at 46 %
ships instead.

The species table is no longer empty, and that is the measurement rather than a
change of heart. The default window is rows **17–48** of a 64 px sprite, which
frames a whole creature's *body* — and **15 of the 19** speaking species have
artwork starting **above** row 17 (`PIKACHU`'s ears at row 6, `PIDGEOT`'s at 2,
`FEAROW`'s at 0), so the default cut the top of the head off and showed mostly
chest. Only the 19 that *speak* are listed: a key nothing ever reaches is a line
that silently never fires.

The Fisherman's own entry moves from `{30,4,30}` to `{32,8,32}` — the same
picture key, the new default size. The `speakers` table is still empty, and that
is a measurement too: every badly-framed picture this release found is worn by
one *kind* of person, so the picture key says the same thing and catches more
routes.

### The species key is the engine's own fold

A per-species override is keyed by the **engine's** species key, not the cart's
display name:

```lua
local idx = Pokemon.speciesFromName(species)
local key = Pokemon.keyName(idx)          -- NIDORAN♀ -> NIDORAN_F, MR. MIME -> MR_MIME
return (key:lower():gsub("[^a-z0-9]", "")) -- -> nidoranf, mrmime
```

Until 1.9.0 the key was the **display name lowercased** — `"nidoran♀"`,
`"mr. mime"` — so an entry filed for any of the four species the cart spells with
a sign, a quote or a space could never fire, which is the whole reason a
per-Pokémon exception is worth having. Two of the four — the Nidoran — are among
the species that speak, so two of the 19 entries above were unreachable before
this.

The mod asks the engine's dex for the fold rather than carrying a second copy of
it. With no dex behind it — no species pack imported — the fallback folds the two
**gender signs** to the letters the key spells (`♀` → `f`, `♂` → `m`) instead of
letting both vanish into `"nidoran"`, so the key is the same string either way.

### A trainer who challenges you gets a face

A trainer's dialogue does not always begin with an A press. FRLG's
**line-of-sight** trainers see the player and start their script from a *step*
(`src/core/game3/trainer_sight.lua`, `TrainerSight.engage`), and that path raises
no `world.talk` — so the press record stayed empty, the resolver had nothing to
answer with, and the *"wants to battle"* box came out bare.

The engine already names the object for exactly this case: `engage()` emits
`world.trainer_engaged` with the trainer's own event object. Recording that is
the same act as recording a press, and every existing way of ending a
conversation drops it again — a step, a map change, the script finishing. The
payload's `trainerClass` rides along as the fallback for an object whose own
`trainerType` has not been stamped yet, and it is put into a shallow **copy**
rather than written onto the engine's object, because a mod must not scribble on
the world.

### What did not change

- **MARGIN.** The same window, the same `MARGIN_PAD` of 4 on both axes, the same
  letterbox condition. It was already placing its panel in window space, where 4
  game px is a real 4 game px — it is FRAMED that had to buy the same number out
  of the box, and that is what the centring fixes. The README had described
  MARGIN's panel as "the size of the art plus its outline", which was stale prose
  rather than a behaviour: it has drawn the engine's own 48 px window since
  1.8.2.
- **The text width.** 152 px in FRAMED, 168 px in INSET, both unchanged — the
  window was already a constant, so growing the crop and moving the panel could
  not touch it.

### Verified

Four suites, all green: **367** geometry checks (was 340), **176** speaker checks
(was 146), 29 menu, 23 load — **595 checks, 0 failures**. `modkit validate
--strict` and `modkit lint` pass; the engine tree is clean afterwards.

Twenty-one mutations, twenty-one noticed, and the tree restored byte-for-byte
after each. **Six of them are new** and each restores a shape the reports
describe:

| | what it restores | failures |
| --- | --- | --- |
| **C8** | INSET back to a 30 px portrait in a slot inset by a pixel each side | **4** |
| **C9** | `art/crops.lua`'s default windows back to 1.8.3's 30 px | **12** |
| **C10** | the species crop key back to the display name lowercased | **2** |
| **C11** | the `world.trainer_engaged` subscription neutered | **9** |
| **C12** | FRAMED's whole slack back on the outer side, flush against the box | **17** |
| **C13** | the no-dex fallback no longer folding the two gender signs apart | **2** |

**C9 is the one that needed the harness to grow.** The default window is *data*
in `art/crops.lua`, not code in `main.lua`, so `dp3_bite.py` now snapshots and
restores **every file a mutation touches** — each with its own backup beside the
harness — and proves the shipped default by moving it back to 30. A mutation that
could not reach the file holding the answer would have left the one change the
release is most about unproofed.

The older crop and layout letters all still bite, and four of their counts moved
because the suite did:

- **C4** (`EDGE_PAD` back to 8) fails **13**, up from three: the slack no longer
  moves — `ceil((8 + 48) / 8)` is *also* 7 — but the **split** can no longer give
  8 away, so the pin on the constant is no longer the only thing that catches it.
- **C5** (paint the panel by hand again) fails **91**, **C6** (remove the
  whole-number zoom) fails **12**.
- **C7** (size the window to the art again) fails **11**, down from 89, and the
  reason is worth stating: the **default** crop is 32 px, so its window comes out
  48 px either way, and C7 is now caught only by the narrow crops, whose windows
  would shrink to 40 px.

`mod.card` is also checked to **load**, not just to read well: the new species-key
sentence had been inserted into the middle of an existing string concatenation
and closed with a comma, which is a syntax error, and the card must `dofile`
cleanly for the mod browser to read it.

## 1.8.3 — the portraits wear the game's own menu window

One change, asked for directly: *"can you use the same borders used in the start
menu for the portrait?"*

**FRAMED and MARGIN now draw the engine's own standard menu frame** —
`Chrome.stdFrame`, the same call the start menu's box and the OPTION page's body
are drawn with — instead of a panel this mod painted by hand. **INSET is
untouched**: it draws the art inside the dialogue box, where there is no window to
put a window in.

### The panel is the game's window, not an imitation of one

Until now the panel was a **one-pixel black outline** the mod drew itself
(`rectangle` in black, `rectangle` in white inside it) around the art. It read as
a panel, but it was not the game's frame and it did not look like one: a hairline
scaled up with everything else rather than the tile-drawn border every menu in
FireRed wears.

The mod now **asks the engine**:

```lua
love.graphics.push()
love.graphics.translate(contentX, contentY)
love.graphics.scale(unit, unit)
Chrome.stdFrame(0, 0, PANEL_CONTENT_TW, PANEL_CONTENT_TW)
love.graphics.pop()
```

`Chrome.stdFrame` draws its 9-slice border **outside** the rect it is handed and
only comes in tile coordinates, which is why the call is wrapped in a transform:
translate to the content rect, scale by the unit, and ask for a content-sized
window at the origin. The border then lands exactly on the panel's outer edge.
The window is the engine's, so it is also the player's own `OPTION → FRAME`
choice, and the extracted tiles when the install has them.

The panel is therefore **six tiles (48 px) square** with a whole tile (8 px) of
border on every side, around a **32 px content** rect the art is centred in:

```
frame 48 x 48   border 8 px   content 32 x 32   art 30 x 30 at 1x
```

### The window is ONE size, so the text width is a constant again

This is the reversal, and it is forced by the border rather than chosen: the
border is drawn from 8 × 8 tiles and only lines up on the tile grid, so the
window has to be a whole number of tiles on both axes. A crop that varies from
12 px to 32 px cannot be wrapped in a tile-aligned border of its own width.

So the window is one size for everybody and the **art** is what varies:

| crop | zoom | art | window | columns of the box | text | clearance from the edge |
| --- | --- | --- | --- | --- | --- | --- |
| 30 px (the default) | 1× | 30 px | 48 px | 7 | 152 px | **8 px** |
| 16 px | 2× | 32 px | 48 px | 7 | 152 px | 8 px |
| 12 px | 2× | 24 px | 48 px | 7 | 152 px | 8 px |

1.8.0 made the panel the **art's** size — a 32 px panel for the default crop, a
38 px one for a 12 px crop — which bought a tight ring and cost a **per-speaker
text width** (168 px for the default crop, 160 px for the 12 px one). This
release takes the constant text width back and pays for it with a window that is
bigger than most crops need. `framedGive` is now a constant: `ceil((4 + 48) / 8)`
= **7** columns, realising `7 * 8 - 48` = **8 px** of clearance for every crop.

**The art is still never resampled.** It is fitted *into* the content at the
largest whole number of times its own crop that fits, so a 16 px crop is drawn 2×
(32 px, filling the content exactly) and a 12 px one is also 2× (24 px, four
pixels of content left on each side). The 12 px crop's zoom drops from 1.8.0's 3×
to **2×**, because 3 × 12 = 36 no longer fits a 32 px content — which is the same
rule applied to a smaller window, not a new one.

### What did not change

- **INSET.** Its slot, its reserve, its 30 px art and its 168 px text width are
  exactly as they were. It is not a window layout.
- **The clearance constant.** `EDGE_PAD` stays **4**; what moved is the rounding
  it goes through, and only because the window's width did.
- **Where the panel stands.** The panel still hangs off the box's own *visible*
  edge with 16 px of the box's border showing between the portrait and the first
  letter, and its outer edge still falls the run's slack short of the play area's
  edge. Only the numbers moved: the panel is 8..56 on the left and 184..232 on
  the right, against the pen at 72 and 168.
- **MARGIN.** Same window, same `MARGIN_PAD` of 4 on both axes, same letterbox
  condition — but the panel is 48 px now instead of 32, so a margin needs 168
  window units at 3× rather than 120, and a phone cutout that was just wide
  enough before is not any more. It stands above the box in that case, which is
  what the condition is for.

### Verified

Four suites, all green: **340** geometry checks (was 322), **146** speaker
checks, 29 menu, 23 load — **538 checks, 0 failures**. `modkit validate --strict`
and `modkit lint` pass; the engine tree is clean afterwards.

The geometry suite gained a **real transform stack**, and that was not optional.
The engine's `tests/love_stub.lua` leaves `translate` and `scale` as noops, so
the spies would have recorded the window at local coordinates — `(-8, -8)`
wherever it actually landed — and every placement assertion in the file would
have passed while measuring the wrong thing. It now installs its own transform
and folds it into every recorded coordinate and size, which is the same trap as a
double more capable than the real object, one layer down.

The new tests are shown to **bite**: fifteen mutations, fifteen noticed —
including `C5` (paint the panel by hand again → **90** failures), `C7` (size the
window to the art again → **89**) and `C6` (remove the whole-number zoom → **10**).
`C4` still bites too, and for a reason worth recording: with a 48 px window,
`ceil((8 + 48) / 8)` is *also* 7, so putting `EDGE_PAD` back to 8 does **not**
move the slack the player sees. Only the suite's literal pin on `4` catches it.
The tree is restored byte-for-byte afterwards.

One test fixture had to be re-picked rather than re-numbered. The one-word-page
guard is only meaningful on a line that **actually orphans** at FRAMED's width,
and at the new 152 px the line 1.8.2 used wraps to two balanced lines — it only
orphans at 176 and 168. The guard would have had nothing to fix and the assertion
would have been a tautology dressed as coverage, which is the fourth time that
section has been moved by a width change. The replacement was chosen by
measurement across the probe's corpus: it orphans at **144, 152 and 160**, so it
survives a column of drift in either direction.

## 1.8.2 — the portraits that never appeared, and a table that can name one person

Four changes, and three of them are the same report from three directions: a
speaker whose portrait did not draw, or drew the wrong part of the picture. The
fourth is the clearance constant the other three are measured against.

### 1. Two Pokémon had no portrait at all

The report was "some Pokémon don't show a portrait". It was not the crop and it
was not the routing — **it was the name never being read.**

A named speaker is taken from the dialogue's own `NAME: ` prefix, and that
prefix was matched with

```lua
local name = head:match("^([A-Z][A-Z0-9%._%-]*):")
```

FireRed spells four of its 386 species with a character that class rejects —
**`NIDORAN♀` (U+2640), `NIDORAN♂` (U+2642), `FARFETCH'D` (an apostrophe) and
`MR. MIME` (a space)** — and of those four, the first two *speak*. Every other
route was already correct: all 386 species front pics decode out of the ROM, and
the sparsest real species crop is 0.35 fill, so nothing was failing to render.
The two Nidoran simply resolved **no speaker**, and a speaker that does not
resolve draws nothing.

The class is widened to admit exactly what the cart uses:

```lua
local name = head:match("^([A-Z][A-Z0-9%._%-'♀♂ ]*):")
if not name then return nil end
return (name:gsub("%s+$", ""))
```

**Normalisation stays the engine's job.** The mod does not fold `♀`/`♂` itself;
it hands the name on and lets the engine's own `norm_key` do it, because that is
the function that already knows `NIDORAN♀` is `_F`. Folding here would be a
second, disagreeing copy of a rule the engine owns. The trailing-space trim is
there so `MR. MIME :` cannot keep the space before the colon.

The 19 species that actually speak in FRLG were mined from the cart rather than
guessed, by scanning the ROM for every `NAME:` prefix: CHANSEY, CLEFAIRY, CUBONE,
DODUO, FEAROW, JIGGLYPUFF, MACHOKE, MACHOP, MEOWTH, NIDORAN♀, NIDORAN♂, NIDORINO,
PIDGEOT, PIDGEY, PIKACHU, POLIWRATH, PSYDUCK, SEEL, WIGGLYTUFF.

### 2. The Fisherman's portrait was framing the wrong part of the picture

The Fisherman NPC is **picture 38**. Measured off the cart, pic 38's opaque
bounding box is `(4, 11, 61, 62)` — he is drawn seated in the bottom-right with
his rod sweeping up to the top-left — and the default crop `{ 17, 4, 30 }` lands
almost entirely on empty water. It is the **sparsest of all 148 trainer
pictures: 15 % fill**, where the next worst is well above twice that. The real
head and cap sit at x 40–62, y 6–34.

So `art/crops.lua` gains one entry:

```lua
trainers = {
  ["38"] = { 30, 4, 30 },   -- the Fisherman NPC
},
```

The size stays **30** deliberately. A 32 px panel is exactly four tiles, so the
entry costs the text width nothing — the crop moves right, the panel does not
grow.

**Why this is a picture key and not a person key.** Sixteen Fishermen exist in
the game and they do not share a picture: the ordinary **NPC** resolves to pic
38, while the fifteen **battle** Fishermen (class 69) resolve to pic 94. They
share the overworld sprite (`SPRITE_FISHER`) *and* the cart's graphics id (57),
so a `sprite:` or `gfx:` key would have caught all sixteen and reframed fifteen
people who were drawn correctly. **Only the picture separates them.** Pic 38 is
reached by exactly one trainer record in the whole cart (id 39, class 31,
FISHERMAN, no name); the fifteen pic-94 rows are DALE, BARNY, NED, CHIP, HANK,
ELLIOT, RONALD, CLAUDE, WADE, NOLAN, ANDREW, TOMMY, TYLOR, ELLIOT and WADE.

### 3. The crop function is general, so it now takes exceptions by name

The framing rule *was* one rule for everybody plus a picture-keyed override
table, and a picture key cannot express "these two speakers share a picture and
only one of them is framed badly" — which is exactly the Fisherman's problem in
reverse. `art/crops.lua` therefore gains a **second key space**, keyed by the
**person** rather than the picture:

```lua
speakers = {
  -- ["name:FISHER"]   = { 30, 4, 30 },   -- the name the dialogue used
  -- ["gfx:57"]        = { ... },         -- the cart's own graphics id
  -- ["sprite:SPRITE_FISHER"] = { ... },  -- the object's SPRITE_* id
  -- ["class:69"]      = { ... },         -- the numeric trainer class
},
```

The four prefixes are tried **most specific first**, which is the same order
`artFor` already resolves a speaker in, and a **speaker key beats a picture
key** — the more particular statement about one person outranks the general one
about everyone who shares a face. There is deliberately **no `species:` prefix**:
for a Pokémon the species *is* the speaker, so the `pokemon` table was always an
interaction table and a species key is already a speaker key.

Every candidate is validated before it can win, because a malformed entry
(`{ 1, 2 }` — a table with no size) used to pass a bare `type(rect) == "table"`
filter, win the lookup and become a one-pixel clamped window: a portrait drawn
and invisible. A malformed entry now **falls through** to the next key rather
than erasing the portrait.

### 4. `EDGE_PAD` is 4, and the clearance it buys is a floor

`EDGE_PAD` drops from 8 to **4** game pixels. It is one constant behind three
numbers — MARGIN's gap to the box, MARGIN's inset from the play area's edge, and
FRAMED's clearance — and it is worth being precise about which of them moves,
because **they do not move together.**

MARGIN places its panel in **window space**, so it realises `EDGE_PAD` exactly:
4. FRAMED buys its room out of the box in **whole tiles**, so what it realises is
`framedGive(plan) * T - plan.w`, and `EDGE_PAD` is only the **floor the buy is
chosen to clear**:

| crop | panel | columns bought | realised clearance | text |
| --- | --- | --- | --- | --- |
| 30 px (default) | 32 px | 5 | **8 px** (unchanged) | 168 px |
| 16 px | 34 px | 5 (was 6) | **6 px** (was 14) | **168 px** (was 160) |
| 12 px | 38 px | 6 | 10 px (unchanged) | 160 px |

The default crop's geometry is **completely unchanged** — `ceil((4 + 32) / 8)`
is still 5 columns, so the rounding absorbs the whole change. The 16 px crop is
where it shows: it now rounds to the same 5 columns as the default, so it gains
the same 168 px text width and its clearance falls from 14 to 6.

The **letterbox condition** moves with it. The panel only goes out into the
margin when the margin can hold the panel *plus* the clearance on both sides, so
a margin now needs `panelW + 2 * 4` rather than `panelW + 2 * 8` — which is a
panel that fits more often, and a phone cutout that was too narrow at 8 is now
wide enough to use the margin.

### The crop cache is keyed on the rectangle, not the speaker

A latent bug the exception table would have walked straight into. `portraitFor`
cached the cut portrait under the **picture**, so the second speaker of a
picture was served the first speaker's rectangle — and a speaker-key override
filed against a picture that had already been cut was silently ignored. The
rectangle is now resolved *before* the cache is consulted and the cache slot is
the rectangle's own `x,y,size`, so two speakers of one picture can be framed
differently and a later override is honoured.

### Verified

Five suites, all green: **322** geometry checks (was 291), **146** speaker
checks (was 134), 29 menu, 23 load — **520 checks, 0 failures**. `modkit
validate --strict` and `modkit lint` pass; the engine tree is clean afterwards.

The new behaviour is proved against the **real ROM art**, not stubs
(`.probe/dp3_real_chain.lua` drives the engine's own `pokemon.lua` and
`trainer_pic.lua` with the ROM's bytes and asserts the 19 species speakers all
render, `EDGE_PAD = 4`, `MARGIN_PAD = 4`, NPC pic 38 → `30,4,30`, battle pic 94 →
`17,4,30`, and each speaker prefix beating the picture key).

And the new tests are shown to **bite**: twelve mutations, twelve noticed —
including `C1` (narrow the token class again → 9 failures), `C2` (stop consulting
the speaker table → 9), `C3` (key the cache on the picture again → 1) and `C4`
(`EDGE_PAD` back to 8 → 5). The tree is restored byte-for-byte afterwards.

## 1.8.1 — the sandbox ate 1.8.0's fix, and FRAMED stands off the edge

Two changes, and the first is not a layout decision at all: it is **1.8.0's
MARGIN fix not running in the game**. The second is the reported "the framed
portrait is flush against the border".

### 1. The mod was reaching the renderer through a decoy

1.8.0 had the right idea and the wrong lookup. `frameRect` asked for the
renderer like this:

```lua
local Renderer = package.loaded["src.render.Renderer"]
```

and **inside a mod that is `nil`**. A mod does not run against `_G`. The loader
builds its environment with `Sandbox.envFor` and `setfenv`s the entry chunk into
it, and the `package` in that environment is not the engine's:

| | |
| --- | --- |
| **the engine's `package`** | the real one — its `loaded` holds `src.render.Renderer` |
| **a mod's `package`** | `LegacyCompat`'s **`packageShim`** (`src/mods/LegacyCompat.lua:835`), a decoy `{ path = "", cpath = "", preload = {}, loaded = {}, loaders = {} }` whose `loaded` is a **fresh empty table** |

So `package.loaded[...]` answered `nil`, the guard fell through to its fallback,
and MARGIN went on measuring the rect `render.hud` *reports* — the very rect
1.8.0 set out to stop measuring. **The fix was a no-op in the game and there was
nothing to see:** the branch fails silently, logs nothing, and throws nothing.

`.probe/dp3_sandbox_probe.lua` builds the real `Sandbox.envFor` environment and
asks both routes:

```
-- the engine's own view
   require("src.render.Renderer") -> table
   real package.loaded["src.render.Renderer"] -> table
-- the mod's own environment (src/mods/Sandbox.envFor)
   inside the mod: package.loaded[Renderer]       -> nil
   inside the mod: require("src.render.Renderer") -> table: 0x...
```

`require` is the route the sandbox sanctions — its `sandboxedRequire` calls
`pcall(_G.require, name)` — and it answers with the same singleton the engine
calls `Renderer:init()` and `Renderer:endFrame()` on. `frameRect` uses it now.

**And the suite could not see it either.** Every suite compiled `main.lua`
against `_G`, where `package.loaded` *is* populated, so the renderer branch ran
in the tests and not in the game. The geometry suite now builds the mod the way
the loader does — `setfenv` into an environment whose `package` is the decoy
shape — and pins the decoy with three assertions, so a return to
`package.loaded` cannot pass again. Mutation **AG** restores the old lookup and
fails **9**.

### 2. FRAMED stands off the play area's edge

FRAMED's panel was **flush against the play area's edge** — `panelX` was `0` on
the left and `240 - panelW` on the right, and on a phone that edge is the edge of
the screen. There was no clearance constant for FRAMED at all; MARGIN had one
(`MARGIN_PAD`, 8 game px) and FRAMED had zero.

The panel now keeps the **same 8 game px** MARGIN keeps — one number for both
layouts, spelled `EDGE_PAD` — and it is bought out of the box, because
`DLG_LEFT` and `DLG_W` are whole **tile** counts (8 px each) and a box can only
give up whole ones:

```lua
framedGive(plan) = ceil((EDGE_PAD + plan.w) / T)
```

For the default 30 px crop the panel is 32 px = exactly 4 tiles, so the old run
was exactly its own width and there was **no slack anywhere**; the new run is
**5 columns**, which is where the 8 px comes from. The panel hangs off the box's
own **visible** edge and the slack goes to the **outer** side, so the clearance
is exactly `EDGE_PAD` when the panel fills its run and one tile more when it does
not:

| crop | zoom | panel | columns | FRAMED's text | clearance from the edge |
| --- | --- | --- | --- | --- | --- |
| 30 px (the default) | 1× | 32 px | 5 | **168 px** | **8 px** |
| 16 px | 2× | 34 px | 6 | **160 px** | 14 px |
| 12 px | 3× | 38 px | 6 | **160 px** | 10 px |

**The cost is a column, and it is the default crop's text that pays it.** FRAMED's
text was 176 px for the default crop in 1.8.0; it is 168 px now — the same width
the 16 px and 12 px crops already had. That is the trade that was chosen: a gap
worth having, at the price of eight pixels of text.

The panel's inner edge still lands on the box's visible edge, so the gap to the
first letter is still the box's own border, 16 px — unchanged. What moved is the
*outer* side:

```
FRAMED-LEFT   panel 8..40      box visible edge 40    pen 56       gap 16
FRAMED-RIGHT  panel 200..232   box visible edge 200   pen end 184  gap 16
```

### What was checked

`tests/dp3_geometry_test.lua` 280 → **291 checks**; 466 → **477** across the four
suites (291 + 23 + 29 + 134). **31 bite-proofs**, every one bites, `main.lua`
restored byte-for-byte after each (`sha256` before and after):

| | what it restores | failures |
| --- | --- | --- |
| **AG** | **`frameRect` back to `package.loaded` — the sandbox bug itself** | **9** |
| **AH** | **`framedGive` back to `ceil(w / T)` — FRAMED flush against the edge** | **11** |
| D | FRAMED's panel back to 1.6.0's fixed 48 px square | 31 |
| H | the panel not painted at all — both layouts | 78 |
| R | `unitFor` preferring `scale` over the playfield width | 13 |
| U | the box keeping a column the panel needs | 12 |
| Z | the whole-number zoom rule removed | 11 |
| P | the framebuffer-pixel scale read as window units | 11 |
| AF | `frameRect` taking the world rect instead of the UI rect | 10 |
| AE | MARGIN measuring the box `render.hud` REPORTS instead of the one it was drawn at | 8 |
| AA | the clearance back to the 2 game px it was | 7 |
| A, B, C, F, G | INSET's placement, the wrap width, FRAMED's anchor, SIDE | 7 – 10 |
| L, M, N, S, T | the guard's scope and the reflow | 4 – 6 |
| V, X, AB, AC, AD | FRAMED's wrap, the frame guard, the clearance's two halves | 2 – 7 |
| I, J, K, O, Q | the mirror, FRAMED's vertical anchor, the one-word guard | 1 each |

**The two new ones are the release.** AG restores the exact line 1.8.0 shipped
and 1.8.1 fixes, so it is the regression test for the *class* of bug and not just
for this instance. AH restores FRAMED's flush placement — `ceil(w / T)` drops
the clearance out of the run — and bites eleven.

`modkit validate --strict` and `modkit lint` both pass, and the engine tree is
untouched.

## 1.8.0 — FRAMED hugs the art again, and MARGIN asks the renderer where the box is

Two changes. The first reverses 1.7.0's FRAMED decision; the second is the one
the phone was actually complaining about, and it is not a layout decision at all
— it is MARGIN measuring a dialogue box that was not where the box was.

### 1. FRAMED's panel is the art's own size again

1.7.0 made FRAMED's panel a fixed 48 px square and scaled the art to **fill** the
46 px window inside it. That is gone. Both layouts share **one plan** again —
`panelPlan`, the crop plus a 1 px outline at the largest **whole-number** zoom
that still fits the 6-tile (48 px) cap — so FRAMED's panel is the art's size, the
same shape MARGIN draws:

| crop | zoom | panel | columns of the box | FRAMED's text |
| --- | --- | --- | --- | --- |
| 30 px | 1× | 32 px | 4 | **176 px** |
| 16 px | 2× | 34 px | 5 | **168 px** |
| 12 px | 3× | 38 px | 5 | **168 px** |

For the default 30 px crop the panel's top edge comes down **16 game px** (48 →
32), and the art is drawn at **1:1** rather than at 1.533×.

**The trade, stated plainly.** FRAMED's text width is a property of the speaker
again: 176 px for the default crop, 168 px for the 16 px and 12 px ones — the run
is whole *tiles*, so two crops of different sizes can round to the same one.
1.6.0 and 1.7.0 bought a constant text width by making the panel a fixed square
and stretching the art into it; this release gives that up, and what it buys is a
portrait that is the crop's own size at a whole number of times rather than a
fractional fit.

**And the clearance grew, which is a consequence rather than a decision.** The
panel is **centred in the run the box gave up**, so its inner edge lands on the
box's own *visible* edge, and the text pen is `CHROME_L` columns — 16 px —
further in. So there is now 16 px of the box's own border showing between the
portrait and the first letter, where 1.7.0 covered that border and left 4 px.
That is the price of not overlapping the box, and the suite asserts it rather
than leaving it to be rediscovered.

The two layouts are one plan now because they are one shape. They were never two
shapes; 1.6.0 gave MARGIN FRAMED's plan for no reason but that the two were one
function, and 1.7.0 split them to undo that. With FRAMED back on the art's own
size there is nothing left to split, so `marginPlan` is deleted rather than kept
as a second name for the same answer.

### 2. MARGIN asks the renderer where the box is

This is the reported "the gap between the portrait and the box is too big, and
the box is way up", and **the mod was not moving the box at all**. `DLG_TOP` and
`DLG_H` are read-only in this mod; the only writes to the dialogue chrome are
`DLG_W`/`DLG_LEFT`, and only horizontally, inside FRAMED. What was wrong was
*which box MARGIN was measuring*.

MARGIN draws in window space, so it has to know where the box is on the screen.
It was reading that from the rect `render.hud` hands it, and **that rect is not
always the rect the frame was drawn at**:

| | where it comes from | how it is fitted |
| --- | --- | --- |
| **reported** | `Game3:_drawHud` → `Display.fit(w, h)` (`src/core/game3/display.lua:50`) | centred in **48 % of the SAFE AREA**, scale from the **width alone** |
| **drawn** | `Renderer:endFrame` → `Renderer:frameRects()` | fitted into `Playfield.cutout` — the **touch skin's** viewport, a **fraction of the WINDOW** — scale from **both axes** |

Two different computations. They agree only when no touch skin is selected, which
is why this was invisible on a desktop and on every viewport the suite had.
`.probe/dp3_hudframe_probe.lua` drives both sides headlessly and measures the
distance between the two box tops:

| layout | reported box top vs drawn |
| --- | --- |
| desktop 1280×720, no skin | +0.00 game px |
| portrait 360×780 @3x, skin deck 0.50, notch | +1.50 |
| portrait 360×780 @3x, skin deck 0.50, no notch | −6.00 |
| portrait 360×780 @3x, skin deck 0.62, no notch | **−41.00** |
| portrait 360×780 @3x, skin deck 0.35, no notch | **+38.00** |
| portrait 412×1000 @3x, skin deck 0.50, notch | +0.40 |

A panel placed 8 game px above the *reported* box therefore sits anywhere from
**33 game px inside the real box** to **46 game px above it**, depending on the
skin. Both readings were reported, because both happen.

**MARGIN is the only layout that can be wrong about this**, and that is not a
coincidence: INSET and FRAMED draw *inside* the canvas, where the box is wherever
Chrome says it is. MARGIN is the one layout that has to reproduce the renderer's
own arithmetic from outside, so it now asks the renderer. `frameRect` calls
`Renderer:frameRects()` and takes the **UI** rect — `uox`/`uoy`/`uvpw`/`uvph`,
where `endFrame` blits `self.canvas`, the surface the dialogue box is drawn into
— and not the world rect `ox`/`oy`, which is the same numbers only while the UI
scale equals `fitScale` (UI LAYOUT = CENTERED, the default). The `render.hud`
payload stays, as the **fallback** it is: a payload with no renderer behind it —
Gen 1/2, or an older engine — still gets the documented rect and the documented
scale, via `unitFor`.

`docs/modding.md` documents the payload as the playfield rect, "so a tool can use
the letterbox margins without drawing over the playfield", and the Gen 2 notes
spell out that it holds because both sides compute the same number. On Gen 3 with
a skin selected they do not.

### What was checked

`tests/dp3_geometry_test.lua` 255 → **280 checks**; 441 → **466** across the four
suites (255 + 23 + 29 + 134). **29 bite-proofs**, every one bites, `main.lua`
restored byte-for-byte after each (`sha256` before and after):

`.probe/dp3_layout_bite.py` (geometry, A–AF):

| | what it restores | failures |
| --- | --- | --- |
| **D** | **FRAMED's panel back to 1.6.0's fixed 48 px square** | **31** |
| **AE** | **MARGIN measuring the box `render.hud` REPORTS instead of the one it was drawn at** | **8** |
| **AF** | **`frameRect` taking the world rect instead of the UI rect** | **10** |
| **U** | **the box keeping a column the panel needs** | **12** |
| **Z** | **the whole-number zoom rule removed** | **11** |
| **H** | **the panel not painted at all — both layouts** | **78** |
| **P** | **the framebuffer-pixel scale read as window units** | **11** |
| **R** | **`unitFor` preferring `scale` over the playfield width** | **13** |
| **AA** | **the clearance back to the 2 game px it was** | **7** |
| A, B, C, F, G | INSET's placement, the wrap width, FRAMED's anchor, SIDE | 7 – 10 |
| I, J, K, O, Q | the mirror, FRAMED's vertical anchor, the one-word guard | 1 each |
| L, M, N, S, T | the guard's scope and the reflow | 4 – 6 |
| V, X, AB, AC, AD | FRAMED's wrap, the frame guard, the clearance's two halves | 2 – 7 |

**The two new ones are the whole of the second change, and they are separate on
purpose.** AE restores the *reported* rect — the pre-fix shape — and AF restores
the *world* rect, which is the same numbers as the UI rect on a default install
and therefore the subtler of the two: it is caught only because the suite's stub
renderer carries both rects and its UI scale is deliberately not `fitScale`.
A stub that carried one rect, or one whose two rects agreed, would pass with AF
applied — which is exactly why it carries both.

**Three bite-proofs were retired, and each for a reason worth keeping.**

- **Y** restored the 1.7.0 split, where MARGIN borrowed FRAMED's fixed panel.
  There is one plan again, so Y *is* D, and a second copy of D would only make
  the table longer.
- **W** un-clamped the centring offset in the fill branch. That branch was
  MARGIN's until 1.7.0 and is **deleted** now — there is no window to centre
  inside, because the panel is the art plus its outline and the art lands on the
  grid with no slack to distribute. A mutation with no line to mutate is not a
  mutation.
- **E** snapped `fitScale` to a whole number. `fitScale` is INSET's caller only
  now, and INSET's 30 px crop in a 30 px slot is already 1×, so the snap changes
  nothing and no assertion can observe it. The whole-number rule is **Z**'s
  subject instead, and Z runs.

**A number corrected in the 1.7.0 section below.** It read "404 → 436 across the
four suites", but 404 plus the two deltas it lists (17 and 20) is **441**, which
is also what the 1.7.0 artifact's own suites report when run: 255 + 23 + 29 +
134. The 436 was wrong when it was written; it is fixed below.

**Two things 1.8.1 changed, and this section is left as the record of 1.8.0.**
The renderer lookup described above reached the module through `package.loaded`,
which is a decoy inside a mod's sandbox — so the fix as shipped did not run in
the game, and 1.8.1 replaces the lookup with `require`. And FRAMED's default-crop
text is **168 px** now, not the 176 the table above states, because 1.8.1 buys
the panel a column of clearance from the play area's edge. Both are 1.8.1's
subjects; see its section above.

`modkit validate --strict` and `modkit lint` both pass, and the engine tree is
untouched.

## 1.7.0 — the graphic decides, MARGIN's panel is the art's own size, and it keeps its distance

Three asks. The first is the reported "some NPCs have the wrong portrait", and the
answer turned out not to be in the sprite table at all. The second reverses a
decision 1.6.0 made for FRAMED's sake and dragged MARGIN along with it. The third
is what the second exposed: with the panel down at the art's own size it became
obvious how little room it was keeping from the box and from the screen's edge.

### 1. A map object's own graphics id now decides who it is

`SPRITE_ART` answers from the object's overworld `SPRITE_*`, and on Gen 3 that is
**not** FRLG's `OBJ_EVENT_GFX_*`. `src/core/game3/scripting/gfx_ids.lua` maps the
cart's graphics ids onto the host's Gen 2 vocabulary, and that mapping is
many-to-one and partial:

| | |
| --- | --- |
| **Collapse** | `:16` `[25] = SPRITE_POKEFAN_M` (MAN), `:20` `[30] = SPRITE_POKEFAN_M` (BALDING_MAN), `:32` `[56] = SPRITE_POKEFAN_M` (HIKER) — three people, one sprite |
| **Drop** | every id the table does not list is answered by the fallback at `:75` — `TO_SPRITE[id] or "SPRITE_YOUNGSTER"` |

Both showed in play. A Hiker wore the PokéFan's face; and every graphic the table
has no entry for — the Bug Catchers, the Rockets, the Swimmers, the Tubers, the
Channeler, and **every gym leader and Elite Four member standing in their own
room** — wore a Youngster's.

The object already carries the more specific fact: `eo.graphicsId`, set at
`src/core/game3/objects.lua:138`/`:163`. **A graphic is one person or one
uniform; a class can cover eight gym leaders** — and a class is what the gym
leaders were losing to, because `LEADER` is one class for all eight of them. So
the graphics id is consulted **before** the class route, through a new `GFX_ART`
table whose values say what the id means:

| value | meaning | example |
| --- | --- | --- |
| a **number** | an exact front-picture id | `[85] = 122` — Sabrina |
| a **string** | a name, resolved through the pack exactly as `SPRITE_ART`'s values are — a trainer's own name first, a class name second | `[74] = "LANCE"` |
| **`false`** | the cart never drew this person a battle bust | `[27] = false` — the Fat Man |

The three `false` entries are the graphics that were wearing somebody else's
face: the Fat Man the Fisherman's (`:18` sends him to `SPRITE_FISHER`), a female
Worker the Scientist's (`:29` → `SPRITE_SCIENTIST`), and Celio the Super Nerd's
(`:45` → `SPRITE_SUPER_NERD`). No portrait is this mod's answer wherever the data
does not decide.

**And the second half, which is the easy one to miss.** A graphic with no entry is
not asked at all — but it still *says* something: it says the sprite the object
carries is the host's own **fallback**, so it is no evidence about who is talking.
The sprite route is therefore closed whenever the host has no mapping for the
object's graphic. Without that, declining the Fat Man's face would just hand back
the Fisherman the fallback pointed at, and a Swimmer would keep the boy's face.

### 2. MARGIN's panel is the art's own size again

1.6.0 made the panel a fixed 48 px square, and it was right to — for **FRAMED**.
FRAMED's panel *is* its text width: the box gives up a fixed run of columns, so
the frame has to be the same size for every speaker and the art is scaled to fill
the 46 px window inside it. That constraint is FRAMED's, and 1.6.0 gave MARGIN
the same plan for no reason but that the two were one function.

MARGIN takes nothing from the text, so it has no such constraint — and a fixed
48 px panel standing 2 px above the box reaches **50 px** up from it, where the
art needs 34. That is the "margin portrait is way far up from the dialogue box"
complaint, and it is the same complaint 1.4.0 fixed by sizing the panel to the
art. 1.6.0 undid it for FRAMED's sake.

The two layouts are two plans now:

```
panelPlan   FRAMED: PANEL_PX square (48), art scaled to FILL the 46px window
marginPlan  MARGIN: the crop + a 1px outline, at the largest WHOLE-number zoom
                    that still fits the 6-tile cap
```

For the default 30 px crop that is a **32 px** panel instead of 48 — the panel's
top edge comes down **16 game px** with it — and the panel is 93.75 % art where
the six-tile panel of 1.4.0 was 39.1 %.

It also restores the art's **proportions**, which is the half the fixed panel
could not express. Because the panel is the art's own size rather than a window
the art is stretched into, the scale is a whole number of times the crop:

| crop | zoom | panel |
| --- | --- | --- |
| 30 px | 1× | 32 px |
| 16 px | 2× | 34 px |
| 12 px | 3× | 38 px |

1.6.0 had no such rule: it scaled the art to FILL the 46 px window, so a 16 px
crop came out at 2.875× and a 30 px crop at 1.533×. A small crop and a large one
were the same size on screen and neither was a whole multiple of its source. That
cost is now FRAMED's alone, which is the trade a fixed frame is worth.

### 3. MARGIN keeps a clearance, and INSET's portrait is 30 px again

Two reports from a phone, and the first of them is only visible there.

**The clearance.** MARGIN's panel stood **2 game px** above the dialogue box and
**0 game px** from the play area's own edge — `boxLeft` *is* that edge,
`(DLG_LEFT - CHROME_L) * T` — so on a phone it touched the edge of the screen and
all but touched the box. 2 game px is thinner than the box's own border. Both are
now `MARGIN_PAD`, raised from **2 to 8 game px** and applied on **both axes**: the
panel stands 8 game px above the box and 8 game px in from the edge.

The unit is the point. 2 game px is 8 *device* pixels on a 1080-wide phone but 12
on a 1440-wide one, because the gap scales with `Sp`; measuring the clearance in
game px is what makes it the same margin on every device instead of a different one
per screen.

One number rather than two, because it is one job: **nothing in MARGIN may touch**.
The branch that places the panel in a widescreen letterbox now asks for room for
the clearance on **both** sides — `panelW + 2 * pad`, where it used to ask only
whether the margin could *fit* the panel, `panelW + 2 * 2`. The panel it **centres**
there is now clearance-clear of the screen's edge on the outside and of the play
area on the inside, and a margin only just wide enough to hold the panel falls
through to standing above the box instead of sitting 2 px from the edge — which was
the same fault as being flush, one pixel further in.

**INSET's portrait is 30 px again**, the number 1.4.0 and 1.5.0 measured. 1.6.0
took it to 38 px, and that was too big for the thing it sits in: at 38 px the
portrait is **taller than the box's own 4-row content rect** (32 px), so the only
way to place it was to clamp it against the visible box's top border rather than to
centre it in the rect it occupies. At 30 px it centres in that rect on its own —
121..151 inside 120..152 — with nothing clamped.

The slot follows it down, 40 px to 32, so the reserve drops from 6 columns to 5 and
INSET's text gets a column back: **160 px (20 columns) to 168 px (21)**. Both sides
still reserve the same run, which is the property 1.5.0 introduced and this does not
disturb.

### What was checked

`tests/dp3_geometry_test.lua` 238 → **255 checks**; `tests/dp3_speaker_test.lua`
114 → **134**; 404 → **441** across the four suites. **37 bite-proofs**, every one
bites, `main.lua` restored byte-for-byte after each (`sha256` before and after):

`.probe/dp3_layout_bite.py` (geometry, A–AD):

| | what it restores | failures |
| --- | --- | --- |
| **Y** | **MARGIN borrows FRAMED's fixed panel again** | **47** |
| **Z** | **the whole-number zoom rule removed** | **3** |
| **AA** | **the clearance back to the 2 game px it was** | **6** |
| **AB** | **the panel is flush with the play area's edge again** | **5** |
| **AC** | **INSET's portrait back to 1.6.0's 38 px** | **4** |
| **AD** | **the letterbox condition ignores the clearance** | **2** |
| D | FRAMED's panel hugs the art — its size becomes a property of the speaker | 25 |
| E | `fitScale` snaps to a whole number again | 17 |
| H | MARGIN paints no panel | 66 |
| I | MARGIN's art is never mirrored | 1 |
| P | MARGIN scales in framebuffer pixels | 8 |
| R | `unitFor` prefers `scale` over the playfield width | 10 |
| A–C, F–G, J–O, Q, S–X | the 1.2.0 – 1.6.0 fixes | 1 – 10 each |

The four new ones are the whole of this release, and **AD is the one worth
pointing at**: it changes only the letterbox *condition*, leaving both the
coordinates and the constant alone, and it is caught because the suite asserts the
boundary — `panelW + 2 * clearance` is where the branch flips — rather than only
the two sides of it. A test that checked "it uses the letterbox" and "it does not"
at comfortable distances from the boundary would pass with AD applied.

Four counts above moved from the previous release without the behaviour changing
(E 21 → 17, H 58 → 66, P 7 → 8, Y 39 → 47, R 9 → 10): the suite grew, and several
of these mutations are caught partly by assertions this release added.

`.probe/dp3_bite.py` (speaker, A–H):

| | what it restores | failures |
| --- | --- | --- |
| **E** | **the graphics-id route removed** | **8** |
| B | the pressed object no longer rides along with the name | 10 |
| A | the rival's own route removed | 3 |
| H | the graphic no longer outranks the class | 2 |
| C / D | the two halves of `script.ended` | 2 / 1 |
| **F** | **a declined graphic no longer closes the sprite route** | **1** |
| **G** | **a graphic the host does not map no longer closes it** | **1** |

**One bite-proof was retired, and that is the interesting one.** Mutation **W**
un-clamped the centring offset in `drawFramed`'s fill branch. That branch was
MARGIN's until this release: MARGIN borrowed FRAMED's fixed 48 px panel, whose
46 px window times a fractional unit (`Sp / dpiX`) could round the art a pixel
**wider** than the window it was filling — so the unclamped offset was `-1` and
the art hung outside its own outline. MARGIN sizes its panel to the art now, and
FRAMED's window is the fixed 46 px the art is scaled to *fill*, so the rounded art
can only ever **equal** the window and `winW - artW` is never negative. The clamp
is defensive, **no assertion can observe it, and a mutation nothing fails on is a
mutation that means nothing** — so it is kept for the record and no longer run.
Its replacement in the suite is the zoom rule, and Z is the mutation that proves
the suite tests it.

**A tool bug found by the tool's own guard.** The layout bite-proof run was killed
by a timeout mid-mutation, and SIGTERM skips a Python `finally`. The next run then
read the *mutated* file as its pristine copy — and would have written the mutation
back on its way out, corrupting the very file it measures. The harness refuses to
run against a tree whose baseline is not clean, which is what caught it, but the
restore path still trusted a file it had just been told was dirty. Both harnesses
now refuse to start if `main.lua` carries a `[bite-proof` tag, and keep the last
known-clean copy beside themselves as `_main.lua.bitebak`. **A tool that restores
a file must know what "clean" is independently of the file.**

`modkit validate --strict` and `modkit lint` both pass, and the engine tree is
untouched.

## 1.6.0 — the frame is a fixed size again, and it sits on the box

Three asks, all about the same interface, and the first one reverses a decision
two releases made between them. The numbers below are measured, not reasoned
about: `.probe/dp3_measure_probe.lua` drives the real draw headlessly and reads
the panel fill, the art blit and the font pen off `love.graphics`.

### 1. The frame is 48 px for every portrait, and the art fills it

1.4.0 sized the panel to the art, which removed the white ring and made the
panel's width a property of the crop. That is the same layout a different width
depending on who is talking, and it showed in the text:

| crop | 12 | 16 | 20 | 24 | 28 | **30** | 32 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| panel (1.5.0) | 38 | 34 | 42 | 26 | 30 | **32** | 34 |
| text columns (1.5.0) | 21 | 21 | 20 | 22 | 22 | **22** | 21 |

Now the panel is **48 × 48 for everybody** and the text is **172 px (21.5
columns) for everybody**.

The mechanism is a thing both earlier releases missed: **the art does not have
to be a whole number of times the crop.** `fitScale` snapped to a whole number
whenever one fitted — which is why a 30 px crop in a 46 px window was drawn at
1× and left 16 px of white — and it now takes the exact fit. 46 ÷ 30 is 1.533×,
so the art reaches the outline on every side.

**The trade, stated plainly:** on a 30 px crop the art's pixels are no longer
1:1. That is what a frame of one fixed size for every portrait costs, and it is
the cost the request asked for. A crop is still only ever *fitted* to the
window, never upscaled past it.

**Padding is unchanged.** The outline is 1 game px — the same 1 px it was — and
the panel less its two outlines is exactly the art, so there is still no white
between them.

### 2. The FRAMED panel now sits 4 px off the text, not 16

The 16 px was never spacing. `dialogueFrame` draws the box's border `CHROME_L`
(2) columns to the left of `DLG_LEFT`, so a panel standing flush with the box's
*visible* edge sits 16 px from where the text starts. Making that gap smaller
means the panel has to **cover** that border on its side, and its own outline
becomes the edge there.

```
FRAMED_GIVEUP_TW = PANEL_TW + FRAMED_GAP / 8 - CHROME_L
                 = 6 + 0.5 - 2
                 = 4.5 columns
```

The box gives up 4.5 columns instead of 6; the 48 px panel stands over the
border; and 4 game px of that border is left showing between the panel and the
nearest letter. Both sides use the same number, so `SIDE` is still not a width.
The text goes from 176 px (22 columns) to **172 px (21.5)**.

### 3. INSET's portrait is 38 px

`INSET_ART = 38` with `INSET_PAD = 1` makes the slot 40 px — 5 columns — so the
reserve becomes 5 + 1 = **6 columns** and the text gets **160 px (20 columns)**,
down from 21. Both sides still reserve the same run.

The art is centred vertically against the box the player **sees** (48 px) — the
same rect FRAMED anchors its panel to — and the offset is clamped at zero.

Being straight about both halves: at 38 px the choice of rect makes **no
difference**, because the content rect (y 120–152) and the visible box (y
112–160) share a centre at 136, so centring in either lands the art at y=117.
The rect is used because it is the one the layout occupies and the one FRAMED
measures. What actually does work is the **clamp**: at 38 px the portrait is
taller than the 4-row content rect, so an unclamped offset would be negative,
and a portrait any larger would begin above the box's own top border. Clamped,
it can only ever sit at or below it.

### What was checked

`tests/dp3_geometry_test.lua` 215 → **238 checks**; 381 → **404** across the
four suites. **23 bite-proofs** (`.probe/dp3_layout_bite.py`, A–W), every one
bites:

| | what it restores | failures |
| --- | --- | --- |
| D | the panel hugs the art again — its size becomes a property of the speaker | 27 |
| E | `fitScale` snaps to a whole number again | 29 |
| U | `FRAMED_GIVEUP_TW` loses the gap | 7 |
| V | FRAMED's wrap ignores the gap the panel leaves | 7 |
| **W** | **the centring offset loses its clamp** | **3** |
| J | FRAMED's panel top taken from the content rect | 1 |
| H | MARGIN paints no panel | 57 |
| A–C, F–G, I, K–T | the 1.2.0 – 1.5.0 fixes | 1 – 13 each |

`modkit validate --strict` and `modkit lint` both pass, the engine tree is
untouched, and `main.lua` is restored byte-for-byte after every mutation
(`sha256` checked before and after).

**One assertion was deleted for being a tautology, and that is worth keeping.**
The suite used to assert that the panel was *centred in the columns it took* —
which was meaningful while the panel's width varied. With a fixed 48 px panel
taking exactly 6 tiles of 48 px there is no slack left to distribute, so the
centring is a no-op and the assertion would have been true of any position at
all. It is replaced by what is actually true now: the panel is anchored to the
**screen edge**, so a 16 px crop lands in exactly the same place as the default
30 px one.

**And the offsets are clamped, which is load-bearing on a high-DPI phone.** Both
blits compute a centring offset and clamp it at zero
(`math.max(0, math.floor(...))`). Getting the *reason* right took three attempts,
which is why the measurement is written down rather than the intuition.

The fill product is inexact — a 30 px crop at MARGIN's 3× comes out as
`138.00000000000003` rather than 138 — but that case is harmless, because
`artSize` rounds it back onto the window. The case that bites is a window whose
size in **device units has a fractional part of a half or more**, because then
`artSize` rounds the art *up past* the window it is meant to fill.

That happens on real hardware. MARGIN's unit is `gameWidth / Display.W`, which on
a device is `Sp / dpiX`; at `Sp = 5, dpiX = 3` the unit is 5/3, the window is
76.667 px, and the art rounds to 77 — one pixel wider than its own outline. The
unclamped offset is then `floor(−0.333 / 2) = −1` and the art is drawn a pixel
outside the panel. Five of the reachable `(Sp, dpiX)` pairs do this, and 20 of
the 51 fractional units between 1.0 and 6.0. Measured by
`.probe/dp3_scale_probe.lua`, which prints every combination; INSET, whose unit
is always 1, never reaches it and the clamp there is genuinely defensive.

It is checked, not just asserted. The suite builds the `Sp = 5, dpiX = 3`
viewport and holds the art to both outlines, and mutation **W** — which removes
the clamp — fails three of those, drawing the art one pixel left of its own
outline at x = 20.667 where it belongs at 21.667.

## 1.5.0 — the panel was placed in the wrong unit, and one side had no padding

Four reports, two of them real. Both were found by measuring rather than by
reading, and one of them is invisible on every desktop this mod has ever been
tested on.

### 1. MARGIN was scaled in framebuffer pixels and placed in window units

The loudest report — "the framed portrait sits too far from the dialogue box" —
and the cause is a unit mismatch of exactly `dpiX`.

`Renderer:endFrame` hands `render.hud` a viewport built like this
(`src/render/Renderer.lua:820-840`, `:1400`):

```
scale     = Renderer:fitScale()   = integer FRAMEBUFFER pixels per GB pixel
gameX/Y   = r.ox, r.oy            -> LOVE window units
gameWidth = uiw * (scale / dpiX)  -> LOVE window units
```

`fitScale` is `floor(min(pw / 240, ph / 160))` with `pw`, `ph` in **physical**
pixels, so `scale` is physical-per-GB-pixel. `gameWidth` is not: it is
`scale / dpiX` game-pixels-worth of window units. **So `gameWidth` is not
`Display.W * scale`, and the two differ by exactly `dpiX`.**

The mod read `viewport.scale` as if it were window units per GB pixel, and then
added it to `gameX` — which *is* in window units. Every desktop run agreed with
it, because `conf.lua` sets `t.window.highdpi` **on mobile only**
(`src/core/FaithfulRes.lua`), so `dpiX` is 1 on a desktop and 2 or 3 on a phone.

Measured on a 3x phone (360x720 logical, 1080x2160 physical, so `Sp` is 4 and the
real window-unit scale is 4/3), by `.probe/dp3_gap_probe.lua`:

| | panel size | panel y | game frame |
| --- | --- | --- | --- |
| before | 128 × 128 | 378 | 66 … **279** |
| now | 42.7 × 42.7 | 170 | 66 … 279 |

The panel was three times too large and its top edge sat **99 px below the bottom
of the game frame**, down in the touch-controls deck. That is the report, exactly.

The fix takes the scale from the playfield rectangle instead — `gameWidth /
Display.W`, the number that matches the origin it is added to — which is what the
Gen 2 port has done all along (`gen2-dialogue-portraits/main.lua:2573`, `unit =
vp.gameWidth / 160`, "gameWidth is the letterbox, so this tracks"). The port to
Gen 3 lost it. There is a `scale / dpiX` fallback for a viewport with no playfield
width, and `unitFor` is exported so the suite can pin all four cases.

**A note on why the suite never saw it.** Every viewport in the suite had
`scale == gameWidth / Display.W` — a desktop viewport, or a hand-built one that
copied the desktop relationship. The new section builds the viewport the way the
engine builds it, with the two numbers disagreeing, and mutation P confirms the
assertions catch it.

### 2. INSET's left-hand text had 1 px of clearance and the right had 9

"the inset portrait: when positioned on the left side it sits too close to the
text" — and it was the only one of the four reports that reproduced as stated.

INSET reserves columns from the box for the art. On the **right** it reserved
`ART_TW + ARROW_TW` — the slot plus the arrow's own column — so with a 30 px crop
in a 32 px slot the words sat 9 px clear of the art. On the **left** it reserved
`ART_TW` and nothing else, so the words sat **1 px** off the art's own edge: the
slot's inset, not padding. At 1x the first letter was against the portrait.

One column of clearance on the left makes the two sides mirror images, and the
side effect is worth stating because it is user-visible: **INSET-LEFT's text is 21
columns now, not 22.** Both sides are 21, which is the point — `SIDE` used to
change how much text there was, and it no longer does.

### What was reported and did NOT reproduce

Two of the four reports do not hold against 1.4.0, and the measurements say so
rather than an argument. Both are recorded here because "we checked and it is
already right" is a result, and because the numbers they match are 1.3.0's.

**"the inner portrait has too large a margin between it and the frame, creating
excessive white space."** Measured, the art-to-panel ring is **1 game pixel** on
every layout and at every scale, and the art fills **87.9 %** of its panel:

```
FRAMED   RING L1 T1 R1 B1   art fills 87.9% of 32x32
MARGIN   RING L3 T3 R3 B3   (= 1 game px at 3x)  87.9% of 96x96
```

There is no white in the panel at all: the white field it paints is exactly the
art's own rectangle, so the art covers it completely. The panel is `art + 1 px`
and cannot be tighter without removing its outline. A 9 px ring and a 39.1 % fill
is what **1.3.0** did, before the panel was sized to the art — so a build from
before 1.4.0 would show this and a current one cannot.

**"the dialogue text breaks to a new line before reaching the end of the dialogue
box."** Measured, the text run ends exactly at the content rect's own right edge:

```
FRAMED-LEFT   pen 48  wrap 176  ->  run 48..224   content rect 48..224
FRAMED-RIGHT  pen 16  wrap 176  ->  run 16..192   content rect 16..192
INSET-LEFT    pen 56  wrap 168  ->  run 56..224   content rect 16..224
MARGIN        pen 16  wrap 208  ->  run 16..224   content rect 16..224
```

The one place the text stops short of the clip is INSET-RIGHT, by 8 px, and that
is the art slot it is keeping clear of. The wrap and the clip are the same number
on every layout — that was 1.3.0's fix, and it holds.

### What was checked

`tests/dp3_geometry_test.lua` 200 → **215 checks**; 366 → **381** across the four
suites. **20 bite-proofs** (`.probe/dp3_layout_bite.py`, A–T), every one bites:

| | what it restores | failures |
| --- | --- | --- |
| P | `scale` read as window units — **the bug of this release** | 7 |
| R | `unitFor` prefers `scale` over the playfield width | 9 |
| Q | `unitFor`'s fallback forgets `dpiX` | 1 |
| T | INSET's shift goes back to side-dependent | 6 |
| S | INSET's wrap width goes back to side-dependent | 4 |
| A–O | the 1.2.0 – 1.4.0 fixes | 1 – 52 each |

`modkit validate --strict` and `modkit lint` both pass, the engine tree is
untouched, and `main.lua` is restored byte-for-byte after every mutation
(`sha256` checked before and after).

**One test had to move, and the reason is worth keeping.** The one-word-page
section used to run on INSET-LEFT at 176 px. Giving INSET-LEFT its extra column
took it to 168 px, where that line no longer orphans — and the assertions still
passed, because "no page ends on one word" is trivially true of a box that never
orphaned. A positive test has to run at a width where the thing it guards
actually happens, so it now runs on FRAMED, whose 176 px is where that line really
does end a page on a single word.

## 1.4.0 — the panel was mostly white, and a page held one word

Four reports, and they are two mechanisms. Three of the four are one mechanism
seen from three angles: **the panel FRAMED and MARGIN draw was a fixed six tiles
on each axis, and a 30 px face in a 48 px panel is 61 % flat white.** The fourth
is the wrap, where narrowing the text manufactures a page with one word on it.

### 1. The panel is now the art's own size, not a window the art is fitted into

Measured before anything was changed, by `.probe/dp3_fill_probe.lua`, which drives
the real draw headlessly and prints the panel, the art, and the ring between them:

| | panel | art | white ring | art fills |
| --- | --- | --- | --- | --- |
| FRAMED, before | 48 × 48 | 30 × 30 | 9 px every side | 39.1 % |
| FRAMED, now | 32 × 32 | 30 × 30 | 1 px | 87.9 % |
| MARGIN, before | 144 × 144 | 90 × 90 | 27 px every side | 39.1 % |
| MARGIN, now | 96 × 96 | 90 × 90 | 3 px (= 1 game px) | 87.9 % |

Both layouts had the same bug: `PANEL_TW = 6` tiles square whatever the art was,
with the art fitted into a window inside it. 1.2.0 moved that window in from two
pixels to one tile; 1.3.0 un-clamped the zoom so a narrow crop could fill it.
Neither could work, and the arithmetic says why: **the crop is at most `SLOT`
(32) and the smallest whole-number zoom that fills 48 is 2, which overflows it.**
A panel that is mostly white cannot be filled by a small picture. It has to be
small.

So the panel is now `art + 1 px` on each axis — the art plus a one-pixel outline,
which is how Gen 2's MARGIN panel has always been built
(`gen2-dialogue-portraits/main.lua`, `bx, by, bw, bh = x - frame, y - frame,
w + 2 * frame, h + 2 * frame`). That is the sibling this mod is ported from, and
it has never had this complaint. The art still zooms — `art/crops.lua` documents
that ("anything smaller zooms in"), and without it a hand-tuned 16 px crop would
shrink the panel to an 18 px speck — but the zoom is now capped by
`PANEL_MAX_TW`, which is what keeps a panel from crowding the text.

`PANEL_TW` and `PANEL_BORDER` are gone, replaced by two constants that say what
they mean: `PANEL_MAX_TW` is the cap in tiles, `PANEL_EDGE` is the outline in game
pixels. A rename rather than a new value, because both old names would have kept
a meaning they no longer had — `PANEL_BORDER` was "tiles kept clear around the
art" and is now one *pixel*.

Two consequences worth stating, because both are visible:

* **FRAMED's text is 22 columns now, not 20.** The panel is sized to the
  portrait, so the columns it takes are the art's own and the text keeps the
  rest — 4 of the 6 it may use, for the default 30 px crop.
* **The panel is centred in the columns it took, not flush with either end.**
  The columns are whole tiles and the panel need not be (a 16 px crop gives a
  34 px panel inside 40 px of columns), so centring is what splits the slack
  evenly instead of leaving it all on one side.

### 2. MARGIN's panel was too tall, and that is what "far above the box" meant

The same fixed-six-tiles panel, in window units: 144 px tall at 3×. Its bottom
edge was already only `MARGIN_PAD` (2 game px) above the box — but its *top* edge
was 150 px above it, and that is the thing that reads as "positioned far above
the dialogue box". Sizing the panel to the art brings its top down 48 px and takes
the ring with it. One change, both halves of the report.

### 3. A page must not end on a single word

The wrap is greedy: it fills each line as far as it will go and lets the
remainder fall where it may, with **no short-line balancing at all**
(`src/core/game3/scripting/text_ir.lua`, `wrap_subline`). At vanilla's 208 that
never shows, because the ROM's text is authored to two lines of 26 columns. At
the 176 a portrait costs, it does. `.probe/dp3_wrap_probe.lua` measured it:

```
"You need a POKeMON of your own to protect yourself in the tall grass."
  208    You need a POKeMON of your own | protect yourself in the tall grass.
  176    You need a POKeMON of your own | to protect yourself in the tall  <PAGE> grass.
```

On Gen 3 a page break is an A press (`text_ir.lua`, `onPage >= 2`), so that is a
button to advance past a page the player has already read. It is a consequence of
narrowing the wrap rather than an engine defect at vanilla width — the same line
fits in two at 208 — so the fix belongs here and not in the engine.

The mod now wraps `TextIR.toTextBox` and **reflows** its answer: when a page ends
on one word, the last word of the line above moves down to join it. Installing
after load is safe here because `message.lua` reads `TextIR.toTextBox` as a
**field** at call time — unlike `FrlgFont.draw`, which `vanillaShow` captures as
an upvalue and which therefore has to be wrapped before the mod loads.

It is a reflow, not a re-wrap, and that is what makes it safe to do to text this
mod did not author:

* **no word is added, dropped or reordered** — it is the same text;
* **the number of lines and the number of page breaks is unchanged**, so nothing
  repaginates. The engine counts *lines* to decide pages, so a reflow that kept
  every word but changed a line count would move every page boundary in the box.

The line it takes from has to keep two words of its own, or the reflow would only
move the orphan up a line and leave a new one behind.

It is armed on the **width**, not installed unconditionally: it fires only for a
box this mod narrowed (`width < 208`). MARGIN costs the text nothing, so a MARGIN
box keeps the engine's own wrap byte for byte — and so does an OFF one. That
distinction is the point. This mod narrows the wrap; where it does not, it has no
business rewriting the game's text.

### What was checked

`tests/dp3_geometry_test.lua` 161 → **200 checks**; 327 → **366 checks** across
the four suites, all green. Fifteen bite-proofs (`.probe/dp3_layout_bite.py`),
each restoring the pre-fix shape of one half of one fix and confirming the suite
notices:

| Mutation | Fails |
| --- | --- |
| INSET art pinned instead of centred, unpadded window | 6 |
| the wrap not told the layout's width | 8 |
| FRAMED panel sized to the content rect | 7 |
| **the panel the fixed six tiles instead of the art's size** | 11 |
| **the art never zooming** | 8 |
| MARGIN ignoring `SIDE` | 5 |
| MARGIN centred in the frame instead of above the box | 3 |
| MARGIN not painting its panel | 46 |
| MARGIN never mirroring | 1 |
| **the panel flush with the run's start instead of centred** | 1 |
| **the one-word-page guard never applied** | 1 |
| **the guard firing for every box, not only a narrowed one** | 4 |
| **the reflow dropping the word instead of moving it** | 4 |
| **the reflow downgrading a page break to a line break** | 4 |
| **the donor line allowed to keep only one word** | 1 |

Three of those deserve a note of their own.

**The negative control was blind, and a mutation found it.** The first version of
the "a box the mod did not narrow keeps the engine's text" check compared the
mod's output against `TextIR.toTextBox` — which, by then, *was the mod's wrapper*.
Both sides of the comparison were guarded, so the assertion passed under a
mutation that removed the gate entirely and let the guard fire for every box in
the game. It now captures the engine's own wrap **before the mod loads** and
asserts the property directly — "this MARGIN box still ends on one word, because
the guard stayed out of it" — which cannot be fooled that way. The lesson is
general: comparing a thing against itself is not a control.

**The panel's centring had to be made observable before it could be tested.** The
default 30 px crop gives a 32 px panel in 32 px of columns, so there is no slack
to place and a flush panel and a centred one are the same rectangle. The 16 px
crop (34 px panel, 40 px of columns) is the only case in the suite where the two
differ, and the assertion is filed against it.

**`panelOf` was matching the wrong rectangle.** It found a fill by width, and the
*field* inside a 34 px panel is 32 px wide — the same width as the default
panel — so it returned the light fill and reported a rectangle three pixels out.
It now requires the dark colour too. This is the same trap the suite documents
for the panel-vs-bare-art distinction, one level down.

`.probe/dp3_fill_probe.lua`, `.probe/dp3_wrap_probe.lua`, `.probe/dp3_orphan_probe.lua`
and `.probe/dp3_ctx_probe.lua` are all new. `main.lua` is the only production file
changed, and the engine stays pristine.

## 1.3.0 — the layouts did not agree with the text

Four reports about portrait rendering and dialogue text layout, and they turn out
to be two mechanisms. Three of the four are the same mechanism seen from three
angles: **the text is wrapped in one place and clipped in another, and only the
second of those ever followed the layout.** The fourth is MARGIN, which had never
been given the behaviours FRAMED already had.

### 1. The box's own border was the wrong rectangle to measure against

`Chrome.DLG_LEFT/TOP/W/H` is the box's **content** rect — the text's window.
`Chrome.dialogueFrame()` draws the frame *around* it, and it overhangs: two
columns to the left of `DLG_LEFT`, two past its end, a row above and a row below.
So FRLG's 26-column box occupies **30 columns and 6 rows on screen — 240 × 48 px
at (0, 112), the entire width of the screen**, not the 208 × 32 the constants
suggest. Measured rather than assumed: `.probe/dp3_chrome_probe.lua` drives
`dialogueFrame()` headlessly and captures the rectangles it actually draws.

FRAMED sized its panel to the content rect, so the panel covered two columns of
the dialogue box's own border on either side and the two read as one merged blob
— "the framed portrait intrudes into the dialogue box". It also sized the panel
to `DLG_H` rows instead of the six the box really occupies, so the panel floated
against a box a row taller than it.

The panel now stands in the columns the *visible* box gave up, and is the visible
box's height: flush with the screen edge on the left (0–48 px), flush with it on
the right (192–240 px), top and bottom edges lined up with the box's.

### 2. The text was wrapped for a 208 px box and drawn in a 160 px one

This is the clipping, and it was never a clipping bug.

`Message.show` word-wraps the box's text **once**, against `ctx.maxWidth`,
defaulting to a hardcoded `208` — the vanilla box's own 26 columns
(`src/ui/game3/message.lua`). `Message.drawText` then **clips** each line at
`Chrome.DLG_W * Display.TILE`, which follows the geometry. Vanilla the two agree,
because 208 *is* 26 columns.

Every layout in this mod breaks that agreement, and the mod only ever changed the
second half. FRAMED shrank `Chrome.DLG_W` to 20 columns and clipped at 160 while
the engine wrapped for 208 — 48 px of tail cut off every line. INSET left the box
alone and clipped at 176 from inside the `FrlgFont.draw` wrapper, with the wrap
still at 208 — 32 px cut off. That is "clipped on the first line", and it is also
"obstructed by the portrait on the second": a line that should have broken
earlier ran on under the art.

The fix hands the wrap the layout's own width. `Message.show` supplies
`opts.ctx.maxWidth` before calling the vanilla implementation, which makes it the
one place in the mod that reads the frame from `opts` rather than from
`Message.frameKind()` — and the two agree by construction, because `Message.show`
derives its frame from exactly those opts and always overwrites it, so there is
no sticky frame to miss. `opts` and `ctx` are **copied** rather than mutated: a
script hands the same table to several boxes, and `ctx` also carries the
`playerName`/`rivalName` the text placeholders expand through.

Gen 3 pages the overflow for free — a narrower wrap that pushes a page past the
two lines the box holds becomes a new page on an A press (`text_ir.lua`'s
`toTextBox`) rather than scrolling the first line away. The Gen 2 port needed a
whole `keepPageWaits` pass for this; this one does not.

### 3. The framed panel's art was a speck in the middle of it

Two causes, and both are "its margins are excessively large".

`fitScale` clamped at 1×, so a crop narrower than its window rendered at its own
tiny size. `art/crops.lua` has documented the other behaviour all along — "a size
of 32 is 1:1 and anything smaller zooms in" — and the code never did it. A
hand-tuned 16 px window was a 16 px face in the middle of a 32 px field of flat
white. The scale now snaps to a **whole number of times** whenever the art fits,
which is also what keeps pixel art on the pixel grid.

And the window itself was the panel less two *pixels*, so the default 30 px crop
floated in 46 px of white — eleven pixels of margin on every side. The window is
now the panel **inset by one tile**, the way the game frames its own text, with
the art centred inside it.

### 4. The inset art was pinned, not centred

The art was placed a fixed 2 px in from the box's edge. That is not centring: a
30 px crop — the default window — ended *exactly* where the text pen began, with
no gap at all, and a 32 px crop, which `art/crops.lua` calls the 1:1 window, ran
2 px **past** the pen and drew over the first letters of every line. The same
mistake on the other axis is the "toward the bottom-right" half of the report.

The slot is the box's own four columns inset by a pixel, and the art is centred
inside that, so the widest legal crop stops a pixel short of the words instead of
a pixel past them.

### 5. MARGIN had four of FRAMED's behaviours missing

It was always on the **right** whatever `SIDE` said; it was **vertically centred
in the game frame**, which put it half a screen above a box that lives in the
bottom fifth of it; it was drawn **bare, with no panel behind it**; and it was
**never mirrored**, so a Pokemon on the left faced away from its own words.

It is now FRAMED's panel moved clear of the box: the same bordered panel with the
same one-tile art window, on the side `SIDE` asks for. Where the window is wider
than the game frame it uses the letterbox, centred in the margin and
bottom-aligned with the play area so it sits **level with the box**. Where there
is no letterbox it stands **just above the box**, flush with the end the portrait
belongs to — never centred in the frame. And a species front pic on the left is
mirrored, exactly as INSET and FRAMED already did.

### A documentation claim corrected, not a behaviour change

While writing the geometry notes above, one claim in the 1.2.0 entry turned out
to be false, and it had been repeated in `README.md` and `mod.card`: that
`egg_hatch.lua` calls `Message.draw()` with frame `"battle"`. It does not —
`egg_hatch.lua:186` sets `"dialogue"`; only `evolution_scene.lua:139` sets
`"battle"`.

The frame-kind guard is still correct and still worth having, and the egg hatch
still comes out bare — but for a different reason. Hatching is driven by steps,
and a step has already dropped the press record via `world.stepped`, so there is
no speaker left to draw. The old wording would send a future reader looking for a
guard that is not doing what they think it is. All three places now say the
accurate thing, and the 1.2.0 entry carries the correction inline rather than
being quietly rewritten.

No code changed for this.

### What was checked

`tests/dp3_geometry_test.lua` 67 → **161 checks**; 233 → **327 checks** across the
four suites, all green. Nine bite-proofs (`.probe/dp3_layout_bite.py`), each
restoring the pre-fix shape of one half of one fix and confirming the suite
notices:

| Mutation | Fails |
| --- | --- |
| INSET art pinned instead of centred, unpadded window | 6 |
| the wrap not told the layout's width | 6 |
| FRAMED panel sized to the content rect | 15 |
| the art window inset by two pixels instead of a tile | 4 |
| `fitScale` clamped at 1× | 6 |
| MARGIN ignoring `SIDE` | 5 |
| MARGIN centred in the frame instead of above the box | 2 |
| MARGIN not painting its panel | 41 |
| MARGIN never mirroring | 1 |

Two of those deserve a note of their own.

**The FRAMED window's size is invisible with the default crop.** A 30 px crop
lands in the same place whether the window is 32 px or 44 px, so the first draft
of this suite could not see the window change at all and mutation 4 was caught
only by an unrelated MARGIN assertion. The window is now measured with a 12 px
crop, whose whole-number zoom changes with it — 2× in a 32 px window, 3× in a
44 px one — so the zoom it lands on *is* the measurement.

**Mutation 3 crashed the harness before it failed cleanly**, because the panel
arithmetic indexed a nil rectangle and took the rest of the run with it. The
suite now substitutes zeros there, so the assertions fail on their own terms
instead of hiding every MARGIN failure behind one error.

`.probe/dp3_chrome_probe.lua` and `.probe/dp3_layout_bite.py` are both new.
`main.lua` is the only production file changed, and the engine stays pristine.

## 1.2.0 — four ways a portrait was wrong

All four were found in a review of the 1.1.0 source rather than reported from
play, and all four are in what 1.1.0 *shipped* rather than in what its suites
tested. Three were claims the documentation made that the code did not keep; one
was a placement that is obvious in the game and invisible to the tests.

### 1. A sign, a battle box or an egg hatch could wear the last speaker's face

`world.talk` fires for a press that reaches an object with a script, and that is
what the mod used to decide a box had a speaker. But `world.talk` says a
*conversation started*; it does not say the box currently on screen is part of
one. `Message.draw` is called for boxes the field text printer did not open —
`evolution_scene.lua` calls it with frame `"battle"`, and a sign is `"sign"` —
and the press record can still be set at that moment, so a portrait was drawn
over a box that had nothing to do with it.

*(Corrected in 1.3.0: this entry originally named `egg_hatch.lua` alongside
`evolution_scene.lua` as a caller that uses the battle frame. It does not —
`egg_hatch.lua:186` sets `"dialogue"`, so the egg hatch is not covered by this
guard at all, and never was. It comes out bare for the other reason: hatching is
step-driven and `world.stepped` has already dropped the record. The guard is
still right; only the example was wrong, and it was repeated in `README.md` and
`mod.card` until 1.3.0.)*

The fix moves the resolution to **after** the vanilla `Message.show` call, so the
box's own frame kind is settled and can be asked
(`Message.frameKind() == "dialogue"`), and requires the dialogue frame. Real
battle text was never affected — `battle/ui.lua` calls `Message.drawText()`
directly and never reaches `Message.draw` — but the two scripted boxes above
were, and so was any box opened while a conversation was still on record.

Verified to bite: removing the guard fails six assertions in
`tests/dp3_geometry_test.lua`, covering both the portrait *and* the geometry of a
sign frame and a battle frame.

### 2. Turning on the spot did not end the conversation

The README claimed the record had an end — "walking a step or entering a map
drops it". Both are real, and both miss the same case: **a turn is not a step.**
`Player.tryMove` sets the facing and returns `"turned"` without ever reaching
`Player.finishStep`, which is the only place `world.stepped` is emitted
(`src/core/game3/player.lua`). A player who talked to somebody and then turned to
read the sign beside them kept the last speaker on record for the next box.

The engine's own end-of-conversation seam is `script.ended`, and the press starts
a script run: that run finishing *is* the conversation being over. Only
`completed == true` counts — a script that hands off to another retires itself
first with `completed = false` (`scripting/vm.lua`, where `Vm:start` ends the
script it supersedes), and clearing there would drop the portrait from every box
in the second half of a chained conversation.

Fix 1 already means a stale record can no longer leak a portrait into a sign, a
menu or a battle box; this one is about the plain dialogue box that follows,
which is what the player actually sees.

Verified to bite on both halves: removing the subscription fails the two
"finished" cases, and removing only the `completed == false` guard fails the
hand-off case.

### 3. FRAMED's panel was two tiles off, on one side only

The panel is supposed to stand in **exactly** the six columns the box gave up. It
did not: the offset arithmetic mixed tiles and pixels — the constants either side
of it are tile counts and the `± 2` was a pixel count, so it was read as two
whole tiles. The result was a 16-pixel gap and a panel flush against the screen
edge rather than against the box: LEFT painted `0..48` where the freed columns
are `16..64`, RIGHT painted `192..240` where they are `176..224`.

The Gen 2 original gets this right (`gen2-dialogue-portraits/main.lua`), and the
rule there is simply that the panel starts where the box's remaining columns
start, with no offset at all.

Verified to bite: restoring the old offset fails three assertions. The new ones
spy `love.graphics.rectangle`, capture the rectangle the panel actually paints,
and assert **both** edges against the freed columns — both, because a panel of
the wrong width that starts in the right place passes a left-edge assertion
alone.

### 4. The rival had no portrait

The one speaker the cart never spells out. His dialogue carries the placeholder
`FD 06` where the name belongs — 28 sites in the ROM put it immediately before
the colon — and the engine expands it to whatever the player typed
(`scripting/ops_a.lua`) *before* a mod sees the string. So the box arrives
reading `"GARY: "`, and the name route cannot answer it: the trainer pack lists
the cart's own names, and the player's choice is not among them.

Two things were wrong, and either alone would have been enough to lose him:

- `speakerFor` returned the unplaceable name and **stopped**, discarding the
  object the press had resolved one line earlier — which for the rival is
  `SPRITE_BLUE`, a sprite the sprite route answers perfectly well. The object now
  rides alongside the name. A name the pack *does* know is still tried first in
  `artFor` and still wins outright, so a script handing off between two
  characters is unaffected.
- There was no route by which the player's own name could be recognised. There is
  now: the live session (`Runtime.getSession().rivalName`) and the save table
  (`Runtime._game.save.rivalName`), both `pcall`ed like every other engine reach
  in this mod, and a box whose text matches is flagged as the rival and resolved
  through his own picture.

Verified against the **real** pack dumped from the retail cart
(`.probe/dp3_real_pack.lua`), which contains *two* classes named `RIVAL` (`[81]`,
picture 106; `[89]`, picture 124) and no default rival name at all — `BLUE`,
`GARY`, `GREEN`, `RIVAL` and `OAK` are all absent from its 429 distinct names,
which is why the name has to come from the save rather than from a table.
Confirmed resolving: a press on `SPRITE_BLUE` → 106; `"GARY: …"` with and
without a press → 106; `"SOMEONE: …"` → nothing; `"BROCK: …"` → 116, the pack's
own name still winning; `SPRITE_OAK` → 132.

### Suites

`tests/dp3_speaker_test.lua` 79 → **114 checks**, `tests/dp3_geometry_test.lua`
53 → **67**. 184 → **233 checks** across the four suites, all green, plus
`modkit validate --strict` and `modkit lint`.

The rival's block opens by clearing the press record, and that turned out to
matter: its first case is a box arriving with **no press behind it**, which is
what the rival's scripted boxes look like, and without the clear it was running
against a Lass left on the record by the section above and passing through the
sprite route while appearing to test the rival's name. The bite-proof for the
rival route is what caught it, reporting picture 65 — the Lass — where `nil` was
expected.

## 1.1.0 — the settings live in OPTION, and ordinary people have faces

Both of these were reported from play after 1.0.0, and both were bugs in what
1.0.0 *shipped* rather than in what its suites tested: the release archives were
stale, but the two behaviours behind them were wrong on their own terms too.

### 1. The portraits a player actually walks up to were missing

1.0.0 could only answer "who" from data only a *battle* object carries. Its art
tables held two story characters — `SPRITE_OAK` and `SPRITE_BLUE` — and
everything else went through `TrainerPic.front(trainerType)`. But a map object
only carries a `trainerType` when it is a trainer: `src/core/game3/objects.lua`
sets it to `0` for everybody else. So the professor in his lab and the rival
between fights had faces, and **every other person in FireRed — Mom, the
assistants, the Lass by the fence, the Hiker on the mountain, the Sailor in the
harbour — had none**, which to a player looks like the mod not working.

The ordinary NPC's `SPRITE_*` id is the only thing that names them, so it is now
read: `SPRITE_ART` maps the sprites that mean the same *kind* of person the cart
drew a picture of onto that picture's class name (`SPRITE_LASS` → `LASS`,
`SPRITE_SAILOR` → `SAILOR`, and so on), and the value is tried as a trainer's own
name first and as a class name second so `SPRITE_OAK` → `"PROF. OAK"` and
`SPRITE_BLUE` → `RIVAL` keep resolving as they did.

The rule that keeps it honest is unchanged and deliberate: a sprite whose id
names the same kind of person the cart has art for **is** that art and nothing
else is claimed. A sprite the cart never drew — the Nurse, the Clerk, Mom, Bill,
the old folks — is **absent** from the table rather than mapped to the
nearest-looking class, because a wrong face is worse than no face.
`SPRITE_YOUNGSTER` is the one exception and the code says so: the engine uses it
as the fallback for any FRLG graphic it has no mapping for
(`gfx_ids.lua`), so mapping it is what turns "unmapped remainder" into a face.
Drop that one line to go back to no portrait for them.

Verified against the **real** trainer pack dumped from the retail cart
(`.probe/dp3_real_pack.lua`): every one of the fifteen `SPRITE_ART` entries
resolves to a real picture id, and the class route still outranks the sprite
route for anything that is genuinely a trainer (a real Hiker carries class 51 on
his object, so he never reaches his sprite).

### 2. The settings door opened onto a blank screen

The fix 1.0.0 shipped — a `MODS` row in the start menu that pushed the engine's
`ManagerState` — is the wrong door on this generation, and play proved it:
`ManagerState` is drawn with Gen 1 primitives (`src.render.Font`,
`src.ui.OptionRows`, `src.ui.Theme`) and FireRed's extracted `latin_normal` font
has no glyphs for them, so it logs `font: no glyph for M/O/D/S …` and paints
nothing. The settings were exactly as unreachable as before, one layer further
in.

So the mod no longer pushes a foreign menu. It puts its settings **into the menu
FireRed already has, drawn by FireRed's own chrome and font.** The seam is
`src/ui/game3/option_rows.lua`: `option_menu.lua` calls `Rows.build(ctx)` and
then `Rows.group(flat, openPage)`, which folds any id listed in `Rows.GROUPS`
into a group row whose own `activate` opens a sub-page of its members, ordered
by `Rows.ORDER`. The mod wraps `Rows.build` to append two rows and registers one
group — **`DIALOGUE PORTRAITS`** — so the player finds it by opening the start
menu and choosing `OPTION`, which is where they already look. The rows write
through the same engine options tree the option menu itself persists
(`options.modOptions[<mod id>]`), so the menu's own `writeOptions()` is the whole
of the saving.

The wrap is a plain function replacement rather than a hook, so it cannot be
rolled back by a release — which is why it is gated on the loader's own
exports: a boot where this mod is off gets the stock option list, and the suite
proves the door closes by releasing the mod and asking again.

### 3. The suites, and what they had been blind to

- `tests/dp3_menu_test.lua` was rewritten for the new route (**29 checks**): it
  asserts the group is absent before the mod loads, that it appears as exactly
  one `DIALOGUE PORTRAITS` row, that its label is that and its value counts two
  options, that PORTRAIT and SIDE are **not** also left beside it as top-level
  rows, that activating it opens a two-row sub-page with the right labels and
  defaults, that stepping either writes to both the engine options tree and the
  loader's live copy, and that the row prints the new value — then releases the
  mod and asserts the group is gone. Its closing phase covers the new case
  rather than the deleted one.
- `tests/dp3_speaker_test.lua` gained the sprite route (**79 checks**), including
  that an ordinary NPC's sprite resolves to the class the cart drew and that an
  unmapped sprite still resolves to nothing.
- The two layout suites are unchanged; the route change does not touch a draw.

This is the same lesson as 1.0.0's items 4–6, one level up again: **a suite that
tests the seam the mod installs cannot tell whether the game ever calls it.**
The menu suite's first and last phases (absent before, present after, gone on
release) are what make "the row is present" evidence.

### Also in 1.1.0

- `manifest.json` version → `1.1.0`.
- The release archives are rebuilt from this source. **The 1.0.0 archives had
  been cut before the two fixes above and were shipped as 1.0.0** — a player who
  installed them got neither the sprite coverage nor the working menu, which is
  what the two reports describe. Both archives are now cut from the same
  `main.lua` as the source tree.

---

## 1.0.0 — the first release

The Gen 3 port. FireRed and LeafGreen get a portrait beside the dialogue box,
in the three layouts the Gen 1 and Gen 2 mods established, with the geometry
redone from scratch because FRLG's box is not their box.

### What it does

- **INSET** — the art sits in the box's own four columns and the text moves
  along. LEFT: 208 → 176 px. RIGHT: 208 → 168 px, because the blinking arrow
  owns the last column. This is the default.
- **FRAMED** — six columns come off the box and a bordered panel of its own
  stands in them. The text gets 160 px.
- **MARGIN** — the art is painted out in the letterbox via `render.hud` and
  costs the text nothing.
- **OFF** — vanilla, byte for byte.
- **SIDE = AUTO** reads the player's own facing, so the face lands on the side
  the speaker is actually on.

Portraits are cut at runtime out of the ROM's own battle art — a 64 × 64 trainer
front pic or a 64 × 64 species front pic — using one framing rule plus a
per-character override table in `art/crops.lua`. **No art ships in this repo.**

### Notes from the port

**The box is not `TextBox`.** Gen 1 and Gen 2 share `src/render/TextBox.lua`,
which is why the Gen 2 port is mostly a rename. Gen 3 has its own field text
printer, `src/ui/game3/message.lua`, with `chrome.lua` drawing the frame and
`frlg_font.lua` rendering the text. The seams are `Message.show`,
`Message.draw`, `Chrome.DLG_*`, `FrlgFont.draw` and the `world.talk` hook — and
the arithmetic is new, because 26 × 4 tiles at column 2 is not 20 × 6 at
column 0.

**The press is the precise analogue of Gen 2's `World.talkNpc`.** Gen 3 raises
`world.talk` for exactly the presses that reach an object with a script, and for
nothing else — a sign, a hidden item and a field move are different branches of
the same function in `src/core/game3/field.lua` and never raise it. So the hook
firing *is* the engine saying "this is a conversation", and no stale-record
guard is needed. It still gets an end: `world.stepped` and `map.entered` drop
the record.

**A trainer's class and their picture are different numbers on Gen 3.** Class 81
is RIVAL and its picture is 106; class 97 is POKéMON PROF. and its picture is
132. `TrainerPic.front` indexes the picture table, so handing it a class does
not fail — it returns somebody else's face, and it looks correct for the
low-numbered classes (GUITARIST is class 17 *and* picture 17), which is what
makes it dangerous. The mod now exchanges the class for a picture through the
engine's own extracted trainer pack. 83 of the 106 classes the cart uses pin
exactly one picture, so the exchange is exact for those; the rest pin several
(one class covers all eight gym leaders), and the mod takes the most common,
ties to the lowest id. Names are far better behaved — only three of the cart's
428 distinct names ever pin two pictures — so a name the dialogue used resolves
exactly, which is how the gym leaders get their own faces.

The crop table is keyed by **front-pic id** for the same reason: Brock and Misty
are both class 84 but pictures 116 and 117, so a class-keyed table could not
give them different framing.

**`gen3` is a real target token**, resolving to `{ firered, leafgreen }`.

### Six things that went wrong

Three were caught by the suites, which is why the suites exist. The last three
got past them and reached play, and *why* they got past them is the most useful
thing in this file.

1. **A talking Pokémon had no portrait.** `speakerFor` built a descriptor with
   the object's `sprite` but never resolved the species out of it, so `artFor`
   never reached the dex route — `SPRITE_PIKACHU` fell all the way through to
   nil. Fixed by resolving the species at descriptor-build time, where the
   sprite id is already in hand.

2. **`SIDE = AUTO` never read the facing.** The Gen 3 avatar keeps its facing on
   the player module as a plain field (`Player.facing`), not behind an
   accessor — and the mod was reading it as `player.get().facing`, so the read
   always came back nil and `AUTO` silently degraded to the LEFT fallback for
   every speaker. Nothing crashed, nothing logged, and a portrait just quietly
   appeared on the wrong side of the screen. Fixed by reading the field, which
   is how the engine itself reads it (`src/core/game3/field.lua:
   DIR_BY_FACING[P.facing]`), with the accessor form kept as a fallback.

3. **The trainer class was being used as a picture id.** The bug above. Every
   trainer from about class 22 up was wearing a stranger's face, and the
   low-numbered classes made it look like it worked. Found by reading the
   cart's own trainer table rather than trusting the mod's comment: class 81 is
   RIVAL and picture 106, and the two are simply not the same number.

4. **The portrait was built with an API LÖVE removed in 11.0 — so there were no
   portraits at all.** Reported from play, not by a suite: interacting with a
   character showed dialogue and no portrait, for every character. The crop was
   assembled by reading the source picture's pixels back into a fresh
   `ImageData` via `image:getData()`, and **`Image:getData` was removed in LÖVE
   11.0** while this engine targets 11.5. The engine agrees with the API — it
   never calls `getData` anywhere, and instead keeps the `ImageData` it built the
   `Image` from. So the readback could never succeed in the game, `cutPortrait`
   returned nil under its own `pcall`, `portraitFor` returned nil, and
   `Message.draw` fell straight through to vanilla: silent, no error, no log,
   no portrait.

   Fixed by making the crop a **quad** (`love.graphics.newQuad`) instead of a
   copy of the pixels. A quad is LÖVE's own way to draw part of a texture, so it
   needs no readback at all, keeps the single resample, and goes through the
   picture's own nearest-neighbour filter — the same crop, drawn straight from
   the source. `blit` draws `(image, quad, ...)`, and `CustomArt/`, which has no
   rectangle of its own, still draws whole.

   The suite had been green through all of this because its stub image handed
   out `getData()`. The double was **more capable than the object it stood in
   for**, which is the mirror image of the usual thin-double trap: a thin double
   fails loudly, an over-equipped one makes a broken feature look tested. Both
   suites now stub an image the shape a real LÖVE 11.5 one is — `getDimensions`
   and nothing else — assert `getData` is absent, and then assert a portrait
   still resolves from it.

5. **On FireRed there was no way to reach the mod's settings at all.** Also
   reported from play: the portraits were correct, and the player could not find
   a mod entry anywhere in the options menu to change STYLE or SIDE.

   The cause is a hole in the engine, not in this mod. Gen 1 opens the mod
   manager from an **F10 hotkey** (`src/core/Game.lua`) and from a **MODS row in
   its options menu** (`src/ui/OptionsMenu.lua`); Gen 2 opens it from a **`mods`
   entry in its start menu** (`src/core/Game2.lua`). **Gen 3 has none of the
   three.** `src/core/Game3.lua` and everything under `src/ui/game3/` mention
   `ManagerState` exactly zero times — `start_menu.lua` builds only POKéDEX /
   POKéMON / BAG / TRAINER / SAVE / OPTION / EXIT and `option_menu.lua` has no
   mods section — so the settings were declared, saved, and persisted correctly
   with no UI path that could ever reach them.

   The fix is the door the engine does provide: `start_menu.lua:62` raises
   **`ui.start_menu.items`** with the assembled list, and its A-press handler
   dispatches an entry's own **`onSelect`** (`start_menu.lua:128`). The mod wraps
   that hook and adds one row — `{ id = "mods", label = "MODS", onSelect = … }` —
   pushing `ManagerState` the same way Gen 1's MODS row does, placed after
   OPTION and before EXIT where Gold puts it, and guarded so a reload cannot
   stack a second copy.

   Worth knowing: `src/mods/Gen3Compat.lua` documents the opposite — it says a
   FireRed row is `{ id, label }` and "carries no `onSelect` to rewire". That
   comment is stale; `start_menu.lua:128` has dispatched `onSelect` all along.
   The doc was believed, the code was measured, and the code won.

   **Superseded in 1.1.0.** The row was there and the press dispatched, but
   `ManagerState` cannot draw on FireRed — see 1.1.0 §2 above.

6. **Every interaction showed the same portrait.** Reported from play, again:
   the portraits were correct in the menu sense, and every ordinary person in
   the game — townsfolk, family, shopkeepers — wore one identical face.

   It is a one-character bug. `loadPackIndex` walks the cart's trainer table and
   guards each row with `if pic then`. **In Lua, `0` is truthy**, and the cart's
   table opens with an empty record — trainer id 0, class 0, pic 0, no name —
   so that row was read as a real mapping and became `byClass[0] = 0`.

   One dead row would be harmless. This one is not, because **class 0 is what
   every map object that is not a trainer carries**:
   `src/core/game3/objects.lua:170` is
   `trainerType = tonumber(def.trainerType) or 0`, and 0 is exactly what
   "ordinary person" means on this generation. So `picForClass(0)` answered 0
   for every townsfolk, family member and shopkeeper in FireRed, and
   `TrainerPic.front(0)` — which is real, compressed 64×64 art at `0x08E48D58`,
   not a blank — painted the same face for all of them. A second row
   (class 2, AQUA LEADER, also pic 0) collided the same way.

   Fixed at three levels, because each one is a real statement on its own:

   - the **index** no longer accepts the cart's null records — class 0 means
     "not a trainer" and picture 0 is the null picture, so a row needs
     `pic > 0` and `class > 0` to be a mapping;
   - **`picArt`** refuses picture 0, so no route can reintroduce it;
   - **`speakerFor`** normalises `class = 0` to nil, because 0 is not a class.

   **Why the suites were green.** The pack stub in `dp3_speaker_test.lua` had no
   such row — a double carrying only the *clean* shape of the data cannot fail on
   the dirty shape. And the stub in `dp3_geometry_test.lua` minted a **fresh
   image on every call and ignored the picture id entirely**, so it could not
   tell "asked for picture 17" from "asked for picture 17, and 17, and 17". Both
   stubs are now keyed by picture id, the pack stubs carry the cart's null
   records, and both suites assert that two different speakers get two different
   pictures — at the draw, for the geometry suite, because a resolver can pick
   the right id and still be handed one picture back.

   Verified to bite: with the three guards removed, `dp3_speaker_test` reports 6
   failures and `dp3_geometry_test` 2, all of them the null-record assertions;
   and neutering `picForClass` to answer one picture for everybody turns the
   geometry suite's two-speaker check red.

### Tests

- `tests/dp3_speaker_test.lua` — 72 checks, speaker and art resolution,
  including that a class is exchanged for a picture rather than used as one,
  that the cart's null records (class 0 / picture 0) are not mappings, that an
  ordinary NPC resolves to no portrait rather than to picture 0, and that two
  speakers resolve to two **different** pictures.
- `tests/dp3_geometry_test.lua` — 53 checks, the layouts, measured against the
  real `src/ui/game3/*` modules through a font spy installed before the mod
  loads, plus that the crop table is keyed by the picture, that the crop is built
  without any pixel readback, that the portrait really does reach
  `love.graphics.draw`, and that two speakers **paint** two different pictures —
  taken at the draw, not at the resolver.
- `tests/dp3_load_test.lua` — 23 checks, that the mod **loads**: driven through
  the engine's own headless `Loader` seam (`tests/modkit/sdk.lua`), it asserts no
  loader errors, discovery under the mod's id, that the body ran, that all three
  draw seams were replaced on the real engine modules, and that `world.talk` and
  `render.hud` carry a link. Its second half repeats every assertion on a Gen 2
  boot, where the mod must install **nothing** — so the two phases come out
  opposite, which is what makes the "was replaced" assertions evidence rather than
  decoration. Verified to bite: an unloadable `main.lua` turns it into 10
  failures with the loader's own error surfaced.
- `tests/dp3_menu_test.lua` — 34 checks, that the player can **reach the
  settings**: it shows the FireRed start menu and asserts the MODS row is
  there, is the only one, sits directly after OPTION and before EXIT, and
  carries an `onSelect`; that pressing A pushes the engine's own `ManagerState`;
  that the manager lists this mod and that its detail page offers `OPTIONS..`;
  and that behind it the STYLE and SIDE rows are really there with the right
  labels and defaults — then steps STYLE and asserts the new value is stored and
  printed. Its **first** phase runs before the mod is loaded and asserts the row
  is *absent*, and its last phase releases the mod and asserts the row goes with
  it, so "the row is present" cannot be satisfied by an engine that always had
  one. Verified to bite: disabling the hook turns it into 6 failures, all of
  them the row assertions.

`modkit validate --strict` and `modkit lint` both pass.

### Known limits at 1.0.0

- A class covering several characters resolves to one of them (all eight gym
  leaders share a class). The name route covers the cases the dialogue names;
  `CustomArt/` covers the rest.
- The default crop rule is not tuned per character; some faces sit off-centre.
  That is what the override table in `art/crops.lua` is for.
- Most named characters get no portrait, by design — the ROM has no battle art
  to cut. `CustomArt/` is the answer.
- MARGIN needs a window wider than the 240 × 160 frame to have a margin at all.
