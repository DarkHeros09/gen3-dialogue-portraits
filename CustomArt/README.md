# Custom art

This folder is how you give a portrait to anyone the mod doesn't already cover —
Mom, a nurse, the shop clerk, an old man in the street, any story character with
no battle art of their own. A PNG dropped here beats every route the mod has, in
every `PORTRAIT` layout (INSET / FRAMED / MARGIN), and is drawn exactly as
supplied, uncropped.

One note since 1.0.1: **Bill, Daisy and Mr. Fuji are already covered** — the
cart drew them in its Fame Checker, and the mod now serves those portraits. A
`CustomArt/BILL.png`, `CustomArt/DAISY.png` or `CustomArt/MR. FUJI.png` still
wins over them if you would rather use your own art.

**This folder ships no art.** The mod has no pictures in it at all: every
portrait is cut, at runtime, out of the battle art the engine extracted from
your own ROM. There is nothing here to replace — you are adding.

## How it's named

A PNG is matched by filename against **three** things, most specific first:

1. **The name the dialogue used** — for a character the ROM's own text names
   outright. `BROCK.png` answers `"BROCK: …"`. This is the most specific key
   there is, because it names one character.
2. **The object's own overworld sprite** — `SPRITE_NURSE.png`,
   `SPRITE_CLERK.png`, `SPRITE_OAK.png`. Find the ids in the tables below.
3. **The trainer class's name** — `HIKER.png`, `TEAM ROCKET.png`, `LASS.png`.
   This is the broadest key, and the useful one: a single file here faces every
   member of that class in the game. Class names come straight from the cart, so
   they are spelled the way the game spells them, spaces and all.

The first key that matches wins, so a specific file is never shadowed by a broad
one: `BROCK.png` beats `HIKER.png` for a Hiker-named-Brock.

Note the order is **name, then sprite, then class** — not class first as in the
Gen 2 mod. That is deliberate: on Gen 3 a class covers many characters (all
eight gym leaders share one), so a class-level file is the *least* specific
thing you can write, not the most.

## Size

**30 × 30 pixels** is the size to draw at — it's what the built-in crop produces,
and it is the one size that lands on a clean 1× pixel scale in every layout. Inside
INSET's 32 × 32 slot it keeps a pixel of padding on every side; in FRAMED it
becomes a 32 × 32 panel with a one-pixel outline around it, also at 1×.

FRAMED's panel is the art's own size at a whole number of times it, so a larger
file is **not** scaled down to fit a fixed frame — it gets a panel as big as it is,
and that panel takes more columns out of the dialogue box, leaving the text
narrower. 30 × 30 is the size to aim at; well past it the portrait starts eating
the box.

Other sizes are still accepted: INSET centres the image and auto-scales it to fit,
and any size that divides its slot evenly lands on the pixel grid — 15 × 15 is
exactly 2×. Past 32 × 32 INSET's fit goes fractional, which is the size to actually
avoid there. FRAMED's zoom is a whole number whatever the crop, so its cost for a
large file is a large panel rather than a soft one.

Custom art is drawn as-is: it is **not** cropped through `art/crops.lua` and it
is **not** put through any colour pipeline.

## The catch: several characters share one sprite

Gen 3 reuses Gen 2's host sprite vocabulary
(`src/core/game3/scripting/gfx_ids.lua` maps the cart's `OBJ_EVENT_GFX_*` ids
onto it), and that mapping is many-to-one. Several FRLG graphics collapse onto
one `SPRITE_*` name, so a sprite-keyed file can land on more than you meant:

| File | Also lands on |
| --- | --- |
| `SPRITE_MOM.png` | Daisy, the player's PC, and Mom — three different characters |
| `SPRITE_POKEFAN_M.png` | the Hiker, the Balding Man and the Man |
| `SPRITE_TEACHER.png` | Woman 1 and Woman 3 |
| `SPRITE_YOUNGSTER.png` | the Little Boy, the Boy, the Camper, and the default for any unmapped graphic |
| `SPRITE_FISHER.png` | the Fat Man and the Fisher |
| `SPRITE_SCIENTIST.png` | the Scientist and the lab aide |
| `SPRITE_COOLTRAINER_F.png` | the Cooltrainer and the Crush Girl |
| `SPRITE_LASS.png` | the Little Girl, the Picnicker, and Woman 2 |

Two ways out: use the **name** key if the dialogue names them, or use the
**class** key if they battle you (the class is exact where the sprite is not).

And one sprite is a catch-all: `SPRITE_YOUNGSTER` is what the engine falls back
to for any FRLG graphic it has no mapping for, so a `CustomArt/SPRITE_YOUNGSTER.png`
would also cover every gym leader, the Elite Four and Professor Oak. Don't write
that file unless you mean it.

## Table 1 — Trainers (already covered, nothing to draw)

Every trainer class gets a portrait out of the box: the mod exchanges the class
for a picture through the cart's own trainer table. **Nothing here needs
drawing.** The table is here so you can find the class NAME to use as a
`CustomArt/` filename, and to show the one case that is not exact.

| Class | Name | Notes |
| --- | --- | --- |
| 0 | POKéMON TRAINER | |
| 2 | AQUA LEADER | leftover Hoenn data |
| 3 | TEAM AQUA | leftover Hoenn data |
| 4 | AROMA LADY | |
| 5 | RUIN MANIAC | |
| 6 | INTERVIEWER | |
| 7, 8 | TUBER | two rows, both used |
| 9 | COOLTRAINER | **two pictures** |
| 10 | HEX MANIAC | |
| 11 | LADY | |
| 12 | BEAUTY | |
| 13 | RICH BOY | |
| 14 | POKéMANIAC | |
| 15 | SWIMMER♂ | |
| 16 | BLACK BELT | |
| 17 | GUITARIST | |
| 18 | KINDLER | |
| 19 | CAMPER | |
| 20 | BUG MANIAC | |
| 21 | PSYCHIC | **two pictures** |
| 22 | GENTLEMAN | |
| 23 | ELITE FOUR | **four pictures** — leftover Hoenn data |
| 24 | LEADER | **eight pictures** — leftover Hoenn data |
| 25 | SCHOOL KID | **two pictures** |
| 26 | SR. AND JR. | |
| 27 | POKéFAN | **two pictures** |
| 28 | EXPERT | **two pictures** |
| 29 | YOUNGSTER | |
| 30 | CHAMPION | |
| 31 | FISHERMAN | |
| 32 | TRIATHLETE | **six pictures** |
| 33 | DRAGON TAMER | |
| 34 | BIRD KEEPER | |
| 35 | NINJA BOY | |
| 36 | BATTLE GIRL | |
| 37 | PARASOL LADY | |
| 38 | SWIMMER♀ | |
| 39 | PICNICKER | |
| 40 | TWINS | |
| 41 | SAILOR | |
| 42 | BOARDER | |
| 43 | COLLECTOR | |
| 44 | POKéMON TRAINER | **three pictures** |
| 45 | POKéMON BREEDER | **two pictures** |
| 46 | POKéMON RANGER | **two pictures** |
| 47 | MAGMA LEADER | leftover Hoenn data |
| 48 | TEAM MAGMA | **two pictures** — leftover Hoenn data |
| 49 | LASS | |
| 50 | BUG CATCHER | |
| 51 | HIKER | |
| 52 | YOUNG COUPLE | |
| 53 | OLD COUPLE | |
| 54 | SIS AND BRO | |
| 55 | AQUA ADMIN | **two pictures** — leftover Hoenn data |
| 56 | MAGMA ADMIN | **two pictures** — leftover Hoenn data |
| 57 | YOUNGSTER | the second YOUNGSTER row |
| 58 | BUG CATCHER | |
| 59 | LASS | |
| 60 | SAILOR | |
| 61 | CAMPER | |
| 62 | PICNICKER | |
| 63 | POKéMANIAC | |
| 64 | SUPER NERD | |
| 65 | HIKER | |
| 66 | BIKER | |
| 67 | BURGLAR | |
| 68 | ENGINEER | |
| 69 | FISHERMAN | |
| 70 | SWIMMER♂ | |
| 71 | CUE BALL | |
| 72 | GAMER | |
| 73 | BEAUTY | |
| 74 | SWIMMER♀ | |
| 75 | PSYCHIC | **two pictures** |
| 76 | ROCKER | |
| 77 | JUGGLER | |
| 78 | TAMER | |
| 79 | BIRD KEEPER | |
| 80 | BLACK BELT | |
| 81 | RIVAL | the rival, early |
| 82 | SCIENTIST | |
| 83 | BOSS | Giovanni |
| 84 | LEADER | **eight pictures** — the Kanto gym leaders |
| 85 | TEAM ROCKET | grunts, plus the admin |
| 86 | COOLTRAINER | **two pictures** |
| 87 | ELITE FOUR | **four pictures** — Lorelei, Bruno, Agatha, Lance |
| 88 | GENTLEMAN | |
| 89 | RIVAL | the rival, later |
| 90 | CHAMPION | the rival as Champion |
| 91 | CHANNELER | |
| 92 | TWINS | |
| 93 | COOL COUPLE | |
| 94 | YOUNG COUPLE | |
| 95 | CRUSH KIN | |
| 96 | SIS AND BRO | |
| 97 | POKéMON PROF. | Professor Oak |
| 98 | PLAYER | never a talking NPC |
| 99 | CRUSH GIRL | |
| 100 | TUBER | |
| 101 | POKéMON BREEDER | |
| 102 | POKéMON RANGER | **two pictures** |
| 103 | AROMA LADY | |
| 104 | RUIN MANIAC | |
| 105 | LADY | |
| 106 | PAINTER | |

**"Two pictures" and up is the one soft spot.** A class covers several
characters, so a class-only lookup can only pick one of them — the mod takes the
picture the most trainers of that class use. Where the dialogue names the
speaker, the name key resolves it exactly; where it does not, a `CustomArt/`
file is the fix. This is stated plainly rather than papered over: it is one
picture per class, not a guess dressed up as an answer.

## Table 2 — Everyone else (what needs drawing)

These are the humanoids in the world that do **not** resolve through a trainer
class — the people behind a counter, sitting in a house, or waiting in a script.
None of them has a portrait unless you add one here.

| Sprite | Draw this file | Seen on |
| --- | --- | --- |
| `SPRITE_BILL` | `CustomArt/SPRITE_BILL.png` (or `BILL.png`) — **already covered** by the Fame Checker art | Bill's cottage, Cerulean Cape |
| `SPRITE_CLERK` | `CustomArt/SPRITE_CLERK.png` | every Poké Mart counter |
| `SPRITE_GRAMPS` | `CustomArt/SPRITE_GRAMPS.png` | old men, everywhere |
| `SPRITE_GRANNY` | `CustomArt/SPRITE_GRANNY.png` | old women, everywhere |
| `SPRITE_LINK_RECEPTIONIST` | `CustomArt/SPRITE_LINK_RECEPTIONIST.png` | every Pokémon Center |
| `SPRITE_MOM` | `CustomArt/SPRITE_MOM.png` (or `MOM.png`) | Mom and the player's PC. **Daisy is already covered** by the Fame Checker art, so this file no longer has to land on her too |
| `SPRITE_NURSE` | `CustomArt/SPRITE_NURSE.png` | every Pokémon Center |
| `SPRITE_OAK` | `CustomArt/SPRITE_OAK.png` (or `OAK.png`) — **already covered** by his class pic | Professor Oak, in his lab |
| `SPRITE_OFFICER` | `CustomArt/SPRITE_OFFICER.png` | the Mystery Gift deliveryman |
| `SPRITE_POKE_BALL` | `CustomArt/SPRITE_POKE_BALL.png` | an item ball — a talking ball is a joke, not a character |
| `SPRITE_SUPER_NERD` | `CustomArt/SPRITE_SUPER_NERD.png` | Celio, on One Island |
| `SPRITE_BLUE` | `CustomArt/SPRITE_BLUE.png` (or `RIVAL.png`) — **already covered** by the RIVAL class | the rival, out of battle |
| `SPRITE_ROCKER` | `CustomArt/SPRITE_ROCKER.png` | punks and rockers |
| `SPRITE_BEAUTY` | `CustomArt/SPRITE_BEAUTY.png` | beauties |
| `SPRITE_SAILOR` | `CustomArt/SPRITE_SAILOR.png` | sailors and the S.S. Anne crew |
| `SPRITE_GENTLEMAN` | `CustomArt/SPRITE_GENTLEMAN.png` | gentlemen |
| `SPRITE_BLACK_BELT` | `CustomArt/SPRITE_BLACK_BELT.png` | black belts |
| `SPRITE_SCIENTIST` | `CustomArt/SPRITE_SCIENTIST.png` | scientists and lab aides |
| `SPRITE_FISHER` | `CustomArt/SPRITE_FISHER.png` | fishers, and fat men |
| `SPRITE_COOLTRAINER_M` | `CustomArt/SPRITE_COOLTRAINER_M.png` | male cooltrainers |
| `SPRITE_COOLTRAINER_F` | `CustomArt/SPRITE_COOLTRAINER_F.png` | female cooltrainers, and crush girls |
| `SPRITE_POKEFAN_M` | `CustomArt/SPRITE_POKEFAN_M.png` | hikers, balding men, and men — **three at once** |
| `SPRITE_TEACHER` | `CustomArt/SPRITE_TEACHER.png` | Woman 1 and Woman 3 |
| `SPRITE_LASS` | `CustomArt/SPRITE_LASS.png` | little girls, picnickers, Woman 2 |
| `SPRITE_YOUNGSTER` | `CustomArt/SPRITE_YOUNGSTER.png` | little boys, boys, campers — **and every unmapped graphic**, so use with care |

Two groups are deliberately **not** in this table:

- **The player** (`SPRITE_CHRIS`, `SPRITE_KRIS`) is never a talking NPC, so a
  portrait would have nowhere to appear.
- **Pokémon** are not reachable this way on Gen 3. The host sprite vocabulary is
  humanoids only, so no object in the world arrives as `SPRITE_PIKACHU`. A
  species gets a portrait only when the dialogue names it outright —
  `"PIKACHU: …"` — and that goes through the dex, so `CustomArt/PIKACHU.png`
  still answers it.

## Checking your work

Drop the PNG in, start the game, and talk to the character. There is no build
step and nothing to regenerate — the mod looks the folder up on every load.

If a file doesn't seem to be picked up, the usual cause is a name that doesn't
match any of the three keys. The mod logs nothing per-portrait by default, so
the quick check is to name the file after the sprite (`SPRITE_NURSE.png`), which
is the key you can read straight off the tables above.
