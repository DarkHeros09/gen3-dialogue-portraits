-- Dialogue Portraits (Gen 3) -- FireRed / LeafGreen
--
-- A face beside the words.  Talk to someone and their portrait appears next to
-- the dialogue box.
--
-- This is the Gen 3 port of gen2-dialogue-portraits, which is itself the Gen 2
-- port of gen1recomp-dialogue-portraits.  The idea, the three layouts, the
-- speaker-resolution order and most of the shape of the code are those mods'.
-- What is this repo's own is everything FireRed and LeafGreen do differently --
-- and on this generation that list is longer than on either of the others,
-- because Gen 3 does not share the dialogue box the first two do.
--
-- ------- the one structural difference that shapes everything below
--
-- Gen 1 and Gen 2 share src/render/TextBox.lua, and that is why the Gen 2 port
-- is mostly a rename: both seams it needs -- wrapping TextBox.new to re-geometry
-- one box, and TextBox.draw to paint over it -- exist on both generations.
--
-- Gen 3 does NOT use TextBox.  It has its own field text printer,
-- src/ui/game3/message.lua, driven by src/ui/game3/chrome.lua's dialogue frame
-- and src/ui/game3/frlg_font.lua's variable-width renderer.  So the seams this
-- mod uses are the Gen 3 equivalents:
--
--   Message.show        the one funnel every field box goes through
--   Message.draw        where the box is painted, once per frame while open
--   Chrome.DLG_*        the box's own geometry, read fresh on every draw
--   FrlgFont.draw       where the text actually lands
--   the world.talk hook the A press that reached an object with a script
--
-- and the geometry arithmetic is redone from scratch, because the FRLG box is a
-- different box: 26x4 tiles (208x32 px) on a 240x160 screen, against Gen 1/2's
-- 20x6 (160x48) on a 160x144 one.  That is a WIDER, SHORTER window, which is
-- why the portrait stands BESIDE the box rather than above it: there is no room
-- above or below the box for a panel of any size to stand in.
--
-- ------- who
--
-- Two independent answers, and the text's own is asked first.
--
-- Some of the ROM's own dialogue literally names its speaker -- "OAK: ",
-- "RIVAL: " -- and that text is extracted verbatim from the cart, not added by
-- a mod.  A name found in the text beats the press lookup below it, because a
-- single running script hands ONE object to its whole run while the dialogue
-- inside that run can hand off between two characters box by box.
--
-- When the text names nobody, the object the A press resolved is asked.  Gen 3
-- raises the world.talk hook for exactly the presses that reach an object with
-- a script (src/core/game3/field.lua), and for nothing else -- a sign, a hidden
-- item and a field move are different branches of the same function and never
-- raise it -- so the hook firing IS the engine saying "this is a conversation
-- with somebody".  That makes it the precise analogue of Gen 2's World.talkNpc,
-- and it is a real field rather than an inference from the call stack.
--
-- ------- which picture
--
-- 1. Your own art, if you supply it (see CustomArt/README.md) -- for anyone.
-- 2. A name the dialogue itself used that is a trainer's own name -- exact.
-- 3. The trainer class the object carries, translated to its picture through
--    the engine's own trainer pack.  Gen 3 needs that translation and the other
--    generations do not: FRLG keeps a trainer's CLASS and their front PIC in
--    two different number spaces (class 81 is RIVAL and its picture is 106),
--    so the class has to be exchanged for a picture rather than used as one.
--    Most classes pin exactly one picture, which makes it exact; the ones that
--    cover eight gym leaders are resolved to one of the eight, and the code
--    says so out loud.
-- 4. A talking Pokemon's own front pic, cut the same way, for a species the
--    text names -- "PIKACHU: " -- resolved through the dex, which is a lookup
--    rather than a guess.
-- 5. A named character's picture, for the short hand-checked list of story
--    characters the ROM's own text or overworld sprite identifies.
--
-- Nobody else gets a portrait, on purpose.  Everyone outside that set --
-- townsfolk, family, most named side characters -- has no battle art in FRLG to
-- cut a face out of, and cropping their own overworld sprite would be a worse
-- picture of them rather than a better fallback.
--
-- ------- where
--
-- INSET and FRAMED draw inside the 240x160 game frame, so their art sits in the
-- frame like part of it.  Both work the way the Gen 2 port's do: the box's
-- geometry is read fresh on every draw, so changing it for the length of one
-- draw and putting it straight back gives a per-box geometry change with
-- nothing left behind.
--
-- INSET puts the art in the box's own columns -- left or right, per the SIDE
-- option -- and moves the text along, so the box keeps its full width and the
-- text drops from 26 columns to 21.  Both sides reserve the SAME run: the
-- 4-column slot plus the one column kept clear of the words.  That symmetry is
-- deliberate -- it is what stops the same layout being a column wider on one
-- side than the other, which it was until 1.5.0.
--
-- FRAMED takes the panel's own columns off the box and stands a bordered panel
-- of its own in them, on whichever side the portrait belongs.  The panel is the
-- game's own menu WINDOW -- one size for everybody -- so the run it costs the
-- box, and therefore the text width, is a constant: 7 columns (152px of text).
-- The run is the window's six columns plus the clearance the window keeps from
-- the play area's edge, bought in whole tiles, and the slack is split either
-- side of the panel so it stands EDGE_PAD from both the screen and the box.
--
-- MARGIN uses the render.hud hook instead: window space, over the finished
-- composite, so the portrait can live in the letterbox and cost the text
-- nothing.  Gen 3 raises render.hud with the same payload KEYS Gen 1 and Gen 2
-- do (gameX/gameY/gameWidth/gameHeight/scale), but on this generation the values
-- are not the same numbers the frame is drawn at -- see frameRect -- so MARGIN
-- asks the renderer for the rect it actually used and keeps the payload as its
-- fallback.
--
-- ------- the crop table
--
-- This mod ships no art.  Every portrait is cut, at runtime, out of the battle
-- art the engine extracted from the player's own ROM -- a 64x64 trainer class
-- front pic or a 64x64 species front pic -- using a rectangle from
-- art/crops.lua.  That file holds one framing rule for everybody plus the
-- per-character overrides; see its own header for which is which and why.

-- INSET's portrait is 32px, which is the slot itself -- edge to edge.
--
-- 1.6.0 took it to 38px -- a 40px slot, five columns -- and that was too big for
-- the thing it sits in: at 38px the portrait is TALLER than the box's own 4-row
-- content rect (32px), so the only way to place it was to clamp it against the
-- visible box's top border rather than to centre it in the rect it occupies.
-- 1.8.3 reverted to 30px in a 32px slot, which centred on its own -- 121..151
-- inside 120..152 -- but with a pixel of WHITE on every side.  The slot was 32
-- from that release on, so the only thing left was the crop: the portrait is the
-- slot's own 32px now, and it reaches the frame on all four sides.
--
-- The slot did not move -- still 32px, four columns, and the reserve is still 5,
-- so INSET's text still gets 168px (21 columns) rather than 1.6.0's 160px (20).
-- What moved is INSET_PAD, from 1 to 0: no padding between the art and its
-- frame.  The fix is the crop size and that pad, not a stretch -- the art is
-- still drawn 1:1 through the source picture's own nearest-neighbour filter, so
-- nothing is resampled and no pixel doubles.
local INSET_ART = 32    -- INSET: the side of the portrait itself, in game px
local INSET_PAD = 0     -- INSET: game px kept clear around it (none -- edge to edge)
local ARROW_TW = 1      -- INSET right: the blinking arrow's own column
-- INSET left: the column the text keeps clear between the art and the words.
--
-- Both sides have to reserve the same run, or the same layout is a different
-- width on the left and on the right -- and it was.  RIGHT reserved the slot
-- plus the arrow's column, so the text was 9px clear of the art; LEFT reserved
-- the slot and nothing else, leaving the words 1px off the art's own edge.  1px
-- is the slot's inset, not padding -- at 1x the first letter sat against the
-- portrait, which is what "sits too close to the text" describes.  One column on
-- the left makes the two mirror images, so the text gets the same width
-- whichever side the portrait is on.
local INSET_GAP_TW = 1
local PORTRAIT = 32     -- the crop table's default window, in source px
local SLOT = INSET_ART + 2 * INSET_PAD  -- the slot the art is fitted into: 32
local SLOT_TW = SLOT / 8                -- ...which is 4 columns
local INSET_RESERVE_TW = SLOT_TW + math.max(ARROW_TW, INSET_GAP_TW)

-- The panel FRAMED and MARGIN draw around a portrait.
--
-- The panel is a WINDOW, not a frame that hugs the art: the same one-tile border
-- the game's own menu boxes wear -- the start menu's window and the OPTION
-- page's body both come out of Chrome.stdFrame -- around a content rect the art
-- is centred in.  drawFramed asks the engine for it, so the portrait is drawn
-- with the game's own chrome, tiles and all, rather than an imitation of it.
--
-- The border is what fixes the panel's size.  It is drawn from 8x8 tiles and
-- only lines up on the tile grid, so the panel has to be a whole number of tiles
-- on both axes -- which means the panel is ONE size for everybody again rather
-- than the art's own.  That reverses 1.8.0's "the panel is the art's own size",
-- and it is the honest price of the window: a tile border cannot hug a
-- hand-tuned crop.  The art is still drawn at a whole-number zoom and is still
-- 1:1 for the default crop; what changed is the frame around it.
--
-- PANEL_MAX_TW is the window's OUTER size and PANEL_BORDER_TW the border spent
-- on each side, so the content -- and with it the art's ceiling -- is what is
-- left: 6 - 2 * 1 = 4 tiles, 32px.  1.9.0 makes the default crop 32px to match,
-- so the art fills that content EDGE-TO-EDGE instead of sitting in it with a
-- one-pixel margin; see the note by INSET_ART above.
local PANEL_MAX_TW = 6    -- tiles: the window's outer size, 48px, for everybody
local PANEL_BORDER_TW = 1 -- tiles: the menu window's border, 8px, on every side
local PANEL_CONTENT_TW = PANEL_MAX_TW - 2 * PANEL_BORDER_TW -- tiles: 4, 32px

-- The clearance a panel keeps, in GAME px, from the play area's own edge.
--
-- ONE number for BOTH layouts, because it is one job: nothing the mod draws may
-- touch the edge of the screen.  It was 2 for MARGIN and 0 -- no clearance at
-- all -- for FRAMED, and on a phone the play area's edge IS the edge of the
-- screen, so MARGIN's portrait all but touched it and FRAMED's ran straight off
-- the side of the device.  Two layouts, one complaint.
--
-- 4 game px is half a tile, and the number has to be read against what the two
-- layouts can actually do with it.  MARGIN places its panel in WINDOW space, so
-- 4 game px is a real 4 game px of gap at every device scale.  FRAMED does not
-- place a panel at all -- it BUYS room out of the box, and a box can only give
-- up whole TILES -- so it buys ceil((4 + 48) / 8) = 7 columns for the 48px
-- window and the 8px left over is SPLIT, EDGE_PAD each side.  See framedGive,
-- which is where that arithmetic lives.  So both layouts realise the constant
-- itself, which is up from "at least": 1.8.3 sent the whole slack outward, which
-- left the panel flush against the box.
--
-- MARGIN used to spend it TWICE -- the same 4 px in from the edge and 4 px
-- between the panel and the box it stands over.  The two are NOT one number
-- after all, and 1.9.3 is the release that says so: the edge is about the
-- device (nothing may touch the screen) and the box is about the composition
-- (the panel should read as sitting ON the box, not floating above it).  They
-- were briefly equal at 4 and the second one is MARGIN_BOX_GAP now, below.
--
-- FRAMED still spends EDGE_PAD twice, now that the slack is split: once against
-- the box's visible edge and once against the play area's, and it has to BUY
-- the room for both out of the box.
local EDGE_PAD = 4      -- game px a panel keeps clear of the play area's edge

-- The gap between the panel's own bottom edge and the dialogue box's top, in
-- GAME px, and MARGIN's alone.
--
-- It is not EDGE_PAD and it is not FRAMED's slack, because it is a different
-- job: EDGE_PAD keeps the art off the EDGE OF THE SCREEN, and this keeps the
-- panel off the BOX.  The box is 112 px down a 160 px frame and its own border
-- is eight pixels thick, so the panel's lower border and the box's upper border
-- are two dark bands of the same weight stacked one above the other -- and at
-- 4 px of white between them they read as two separate objects.  At 2 they read
-- as one piece of furniture: the panel's edge and the box's top are one line
-- apart, which is what "the panel sits on the box" looks like.
--
-- It is also the number an earlier release was about, in the other direction.
-- 1.9.0's MARGIN_PAD was 2 for both jobs and the report was "too close to the
-- edge, and too close to the dialogue box"; the edge half of that was right and
-- the box half was over-corrected.  Splitting the constant is what lets the
-- edge keep its 4 while the box gets its 2 back.
--
-- MARGIN places its panel in WINDOW space, where there is no tile grid, so this
-- is a real 2 game px of gap at every device scale -- the property FRAMED
-- cannot have, because a box can only give up whole tiles.  See drawMargin.
local MARGIN_BOX_GAP = 2  -- game px between the panel's edge and the box's top

-- ------- the box the player actually sees
--
-- Chrome.DLG_LEFT/TOP/W/H are the box's CONTENT rect, not the box.  The frame
-- is drawn around it, and it overhangs: dialogueFrame puts its left border two
-- columns to the left of DLG_LEFT, its right border two columns past
-- DLG_LEFT + DLG_W, and a row above and below the content
-- (src/ui/game3/chrome.lua, `cell(0, L - 2, Top - 1)` and friends).
--
-- So FRLG's 26-column box occupies THIRTY columns on screen -- the whole 240px
-- frame, edge to edge -- and is 6 rows tall, not 4.  Any layout that stands
-- something BESIDE the box has to measure against that visible rectangle, not
-- against DLG_*, or it lands on top of the box's own border.  FRAMED did
-- exactly that: sized to the content rect, its panel covered two columns of the
-- dialogue box's frame on either side, so the two read as one merged blob
-- instead of a panel standing beside a box.
local CHROME_L = 2      -- columns of border left of DLG_LEFT
local CHROME_R = 2      -- columns of border past DLG_LEFT + DLG_W
local CHROME_UP = 1     -- rows of border above DLG_TOP
local CHROME_DOWN = 1   -- rows of border below DLG_TOP + DLG_H

-- How much of the box FRAMED gives up is a constant again, but it is still a SUM
-- rather than a number: the window's own six tiles, plus EDGE_PAD rounded up to
-- the next whole tile so the window can stand clear of the play area's edge.
-- Both halves live in framedGive, because the draw and the wrap have to agree
-- about the total and one function is how they do.

-- A sprite id whose tail is not already the species key.
--
-- FRLG gives the Pokemon that stand around their own overworld sprites --
-- SPRITE_PIKACHU IS a Pikachu -- so the species is the sprite id with the
-- prefix taken off, which is a lookup rather than a guess.  The three big-object
-- rows and the surf blob are the exceptions: BIG_* are the 2x2 doll sprites
-- (which depict a Pokemon without being one) and SPRITE_SURF is the surfing
-- blob, not a Pokemon.  Everything else needs no entry.
local MON_SPRITE_FIX = {
  BIG_SNORLAX     = "SNORLAX",
  BIG_LAPRAS      = "LAPRAS",
  BIG_ONIX        = "ONIX",
  SURFING_PIKACHU = "PIKACHU",
}

-- The rival's own front picture, stated outright rather than looked up.
--
-- FRLG splits the rival across TWO trainer classes -- RIVAL_EARLY (81, picture
-- 106) and RIVAL_LATE (89, picture 124) -- and the engine's extracted class
-- list spells both names "RIVAL", so the name cannot say which one is meant.
-- The tie-break every other name now uses -- the class the cart files the most
-- rows under, see `classIdForName` -- would answer RIVAL_LATE, and that is a
-- change to a face nothing reported and 1.9.0 verified.  So the name is not
-- consulted for the rival at all.  The picture is pinned here, and the three
-- places that used to write "RIVAL" write this number instead: the sprite
-- route (SPRITE_ART.SPRITE_BLUE), the text route (NAME_ART.RIVAL) and the
-- player's-own-name route in artFor.  `viaMapping` reads a number as the
-- picture id it already is.
--
-- 106 is the early one, and it is what this mod has always resolved the rival
-- to.  A player who would rather see the later face can still override it,
-- because CustomArt is checked before every route here (CustomArt/RIVAL.png).
local RIVAL_ART = 106

-- Sprite ids that mean "a person" but whose object carries no trainer class,
-- mapped to the name that person is known by in the trainer pack.
--
-- This is the second of the two independent ways to answer "who" for a
-- townsfolk, and it is what makes a portrait appear for the great majority of
-- the people the player actually walks up to.  A map object only carries a
-- trainer CLASS when it is a battle object; an ordinary NPC -- the Boy on the
-- route, the Lass by the fence, the Hiker on the mountain, the Sailor in the
-- harbour -- carries none, so the class route above cannot answer for them and
-- their object's own SPRITE_* id is the only thing that names them.  The value
-- is tried as a trainer's own NAME first and as a CLASS name second, so
-- "PROF. OAK" is the pack's spelling of him while "LASS" is the class.
--
-- The one rule that keeps this honest: a sprite whose id names the same KIND of
-- person the cart has a picture of IS that picture, and nothing else is
-- asserted.  SPRITE_LASS is the Lass, so it gets the Lass's battle bust;
-- SPRITE_SAILOR is the Sailor.  A sprite the cart never drew -- the Nurse, the
-- Clerk, Mom, Bill, the old folks -- is deliberately absent rather than mapped
-- to the nearest-looking class, because a wrong face is worse than no face and
-- CustomArt/<sprite>.png is the route for those (see CustomArt/README.md).
--
-- Note the ids are the HOST vocabulary, not FRLG's: Gen 3 reuses Gen 2's
-- SPRITE_* names (src/core/game3/scripting/gfx_ids.lua maps the cart's
-- OBJ_EVENT_GFX_* ids onto them), and that table has no SPRITE_RIVAL -- the
-- rival stands on SPRITE_BLUE, which in FRLG is exactly who he is.  Several of
-- FRLG's graphics collapse onto one sprite (SPRITE_POKEFAN_M is the Man, the
-- Balding Man AND the Hiker), which is why one sprite can only ever resolve to
-- one class -- and why the class on a trainer's own object still wins: a real
-- Hiker carries class 51 on the object, so the class route answers for him
-- before this table is ever consulted.
--
-- SPRITE_YOUNGSTER is the engine's fallback for any FRLG graphic it has no
-- mapping for, so mapping it is the one entry that reaches wider than its name.
-- Every such object gets a Youngster's face rather than none; the class route
-- still outranks it for anything that is actually a trainer.  Drop the line to
-- turn that back into "no portrait" for the unmapped remainder.
local SPRITE_ART = {
  -- Story characters with no battle class of their own, by the pack's own name.
  SPRITE_OAK          = "PROF. OAK",
  SPRITE_BLUE         = RIVAL_ART,   -- the number, not the name -- see RIVAL_ART

  -- Ordinary townsfolk, by the class whose battle art is the same person.
  SPRITE_YOUNGSTER    = "YOUNGSTER",
  SPRITE_LASS         = "LASS",
  SPRITE_COOLTRAINER_M = "COOLTRAINER",
  SPRITE_COOLTRAINER_F = "COOLTRAINER",
  SPRITE_POKEFAN_M    = "POKéFAN",
  SPRITE_ROCKER       = "ROCKER",
  SPRITE_FISHER       = "FISHERMAN",
  SPRITE_BEAUTY       = "BEAUTY",
  SPRITE_SCIENTIST    = "SCIENTIST",
  SPRITE_BLACK_BELT   = "BLACK BELT",
  SPRITE_GENTLEMAN    = "GENTLEMAN",
  SPRITE_SAILOR       = "SAILOR",
  SPRITE_SUPER_NERD   = "SUPER NERD",
}

-- The cart's OWN graphics id, for the people the host sprite vocabulary
-- COLLAPSES onto somebody else, DROPS altogether, or names with the wrong
-- person entirely.
--
-- SPRITE_ART above answers from the object's overworld SPRITE_*, and that is
-- not the same thing as FRLG's OBJ_EVENT_GFX_*: several graphics share one
-- sprite, and every graphic the host table does not list falls back to
-- SPRITE_YOUNGSTER (src/core/game3/scripting/gfx_ids.lua:75).
--
-- Three consequences, all visible in play.  A Hiker, a Balding Man and a Man are
-- all SPRITE_POKEFAN_M, so all three wore the PokéFan's face.  Two kinds are
-- mapped onto a sprite that names a DIFFERENT kind -- a Camper onto
-- SPRITE_YOUNGSTER, a Picnicker onto SPRITE_LASS -- so they wore that kind's
-- face.  And because the fallback is a YOUNGSTER, every graphic the host has no
-- entry for -- the Bug Catchers, the Rockets, the Swimmers, the Tubers, the
-- Channeler, and every gym leader and Elite Four member standing in their own
-- room -- wore a Youngster's face.  That is the reported "some NPCs have the
-- wrong portrait".
--
-- The object still carries its real graphics id (`eo.graphicsId`, set by
-- src/core/game3/objects.lua), and it is the more specific fact: a graphic is
-- one person or one uniform, a class can cover eight gym leaders.  So it is
-- consulted BEFORE the class route, and a graphic with no entry is not asked at
-- all rather than being answered by the fallback.
--
-- A graphic is not as specific as it looks, though, and that is this release's
-- other half.  FRLG reuses one overworld sprite for whole families of trainers:
-- OBJ_EVENT_GFX_SCIENTIST is worn by eight Super Nerds AND fourteen Scientists,
-- OBJ_EVENT_GFX_ROCKER by eighteen Bird Keepers, nine Jugglers and one Rocker,
-- OBJ_EVENT_GFX_LITTLE_GIRL by every pair of Twins.  Measured over the whole
-- game, 34 graphics ids are worn by trainers and 16 of them are shared by two
-- or more classes -- and for those no value in this table can be right.  The
-- route that can is the trainer's own row, reached from the object's script;
-- see art/trainer_ids.lua and step 4 of artFor.  It runs BEFORE this table, so
-- every entry below is now the answer for the people who are NOT trainers, plus
-- the trainers whose script the table cannot name (the gym leaders, whose
-- battles are not plain trainerbattle stubs).
--
-- A NUMBER is an exact front-picture id.  A STRING resolves through the pack the
-- same way SPRITE_ART's values do -- a trainer's own name first, a class name
-- second.  `false` means "this graphic is a person the cart never drew a battle
-- bust of", and it is how the five graphics that were wearing somebody else's
-- face are turned back into no portrait, which is this mod's rule everywhere
-- the data does not decide.  A decline is about the GRAPHIC, so it stops the
-- sprite route as well; the trainer route above is what keeps a Tamer and an
-- Engineer, who wear two of these declined graphics, from losing their face.
--
-- Every number below is read off pret's own front-pic table -- the order the
-- gTrainerFrontPic_* arrays are declared in src/data/graphics/trainers.h, which
-- is the order the cart's front-pic table indexes them in, and which
-- .probe/dp3_pic_names.py asserts against the pack's singleton classes so the
-- assumption cannot drift.  The gym leaders' are the eight rows of class 84 that
-- the class alone cannot tell apart (LEADER pins pics 108 and 116-122; the Hoenn
-- half of that name, class 24, pins 26-28 and 75-79 and is not used in FRLG; only
-- the graphics id says which leader is standing there).
local GFX_ART = {
  -- Gym leaders and the Elite Four: one shared battle class each, so the class
  -- route picked whichever leader it saw most; the graphic is exact.
  [74] = "LANCE",        -- Elite Four (pic 115)
  [75] = "AGATHA",       -- Elite Four (114)
  [77] = "LORELEI",      -- Elite Four (112)
  [79] = "BRUNO",        -- Elite Four (113)
  [80] = 116,            -- Brock
  [81] = 117,            -- Misty
  [82] = 118,            -- Lt. Surge (the pack has no name spelling this resolves)
  [83] = 119,            -- Erika
  [84] = 120,            -- Koga
  [85] = 122,            -- Sabrina
  [86] = 121,            -- Blaine
  [87] = 108,            -- Giovanni

  -- Ordinary kinds the host DROPS to its Youngster fallback, given the cart's
  -- own FRLG picture for the kind rather than a Youngster's face.
  [20] = 83,             -- BUG CATCHER
  [21] = 82,             -- SITTING BOY -- a boy, so the Youngster was right by luck
  [52] = 88,             -- POKéMANIAC
  [53] = 91,             -- BIKER
  [58] = 126,            -- CHANNELER
  [49] = 109,            -- TEAM ROCKET (M)
  [50] = 137,            -- TEAM ROCKET (F)
  [43] = 95, [45] = 95,  -- SWIMMER (M)
  [44] = 99, [46] = 99,  -- SWIMMER (F)
  [37] = 140,            -- TUBER (F)

  -- Kinds the host maps onto ONE sprite for two people, so the sprite route
  -- could only ever answer for one of them -- and answered for the wrong one.
  -- The graphic is the only fact that separates them: a class covers both sexes
  -- of a kind, a graphic is one person.
  [36] = 7, [38] = 7,    -- TUBER (M): picture 7 is the MALE tuber, 140 the female,
                         -- so a boy in a swim ring wore a girl's face
  [41] = 110,            -- COOLTRAINER (M)
  [42] = 111,            -- COOLTRAINER (F): SPRITE_COOLTRAINER_F resolved through
                         -- class name COOLTRAINER to picture 8, a MALE one

  -- Kinds the host names with the WRONG sprite, so the sprite route answered
  -- with a different person rather than with nobody.  The host calls a Camper
  -- SPRITE_YOUNGSTER and a Picnicker SPRITE_LASS (gfx_ids.lua:39, :40).
  [39] = 86,             -- CAMPER: wore a Youngster's face
  [40] = 87,             -- PICNICKER: wore a Lass's face

  -- Ordinary kinds the host COLLAPSES onto somebody else.
  [24] = 139,            -- CRUSH GIRL: the host called it a Cooltrainer, and a male one
  [56] = 90,             -- HIKER: shares SPRITE_POKEFAN_M with the PokéFan

  -- Two graphics the cart draws as ONE person, which the host then names after
  -- somebody ELSE -- so the sprite route answered with the wrong face rather
  -- than with nobody.  Neither is a guess: each is what the cart's own art
  -- shows, and each is the majority wearer of its graphic.
  --
  -- OBJ_EVENT_GFX_ROCKER (26) is the yellow-haired figure, and it is the BIRD
  -- KEEPER, not the Rocker.  Its art is picture 104's: yellow hair, a red shirt
  -- and blue overalls.  Picture 101 -- the Rocker -- is a blue-haired punk in
  -- an orange jacket, and the two share nothing but a jacket colour.  The host
  -- calls gfx 26 SPRITE_ROCKER (gfx_ids.lua:26) and SPRITE_ART below turns that
  -- into the Rocker, which is the reported "the yellow-haired trainer sprite
  -- sometimes shows the Rocker portrait and sometimes the Bird Keeper
  -- portrait".  Eighteen of the twenty-eight trainer objects wearing gfx 26 are
  -- BIRD KEEPERs, nine are JUGGLERs and exactly one is a ROCKER, so the graphic
  -- is a uniform shared by three kinds and no single value could be right for
  -- all of them -- the trainer route above answers for the twenty-eight, and
  -- this entry is what the eight NON-trainer objects wearing it now get.
  [26] = 104,            -- ROCKER (the yellow-haired sprite) -> the Bird Keeper
  --
  -- OBJ_EVENT_GFX_LITTLE_GIRL (17) is the red-haired little girl, and she is
  -- one of the TWINS.  The host calls her SPRITE_LASS (gfx_ids.lua:17), so
  -- every non-trainer girl wore a Lass's face (picture 84, orange hair) --
  -- the reported "the red-haired little girl sprite, which is actually one of
  -- the twins".  Picture 127 is the Twins, and art/crops.lua cuts it down to
  -- one girl, which is what both halves of that pair want and what the
  -- eighteen ordinary girls on this graphic want too.
  [17] = 127,            -- LITTLE_GIRL -> the Twins
  --
  -- OBJ_EVENT_GFX_SCIENTIST (55) is the lab coat, and it is shared the same
  -- way: 8 Super Nerds and 14 Scientists wear it, and the two pictures are
  -- 89 (a boy in a grey sweater holding a ball) and 107 (a man in a white
  -- coat holding a flask).  The reported "Super Nerd ... displays the wrong
  -- portrait" is this graphic: a Super Nerd standing where the route could not
  -- name him wore 107.  The map route above answers for the maps that put a
  -- Super Nerd on this graphic -- Route 8 and Mt Moon 1F both say 89 -- and
  -- this entry is what the thirty-one non-trainers wearing it get, plus every
  -- trainer on a map that puts no trainer under it.  107 is the honest default:
  -- it is what fourteen of the twenty-two trainers on this graphic wear, and
  -- the overworld sprite IS a lab coat and glasses.  It was already the answer
  -- by accident, through SPRITE_ART below; pinning it here says so outright
  -- rather than leaving it to the host's sprite vocabulary.
  [55] = 107,            -- SCIENTIST (the lab coat) -> the Scientist
  --
  -- OBJ_EVENT_GFX_WOMAN_2 (28) had NO entry at all, which is the reported "the
  -- Aroma Lady has no portrait assigned" -- and it is the only one of the three
  -- reported graphics that was answered with nothing rather than with the wrong
  -- face.  Eleven trainers wear it (4 Aroma Ladies, 3 Breeders, 2 Ladies, and
  -- one each of Lass and Scientist) and eighteen ordinary women do, and the
  -- cart drew a separate bust of every one of those classes.  Picture 144 is
  -- the Aroma Lady, which is what the majority of this graphic's trainers are
  -- and what the report calls it.  The map route above does the finer work --
  -- Bond Bridge's women are Aroma Ladies (144), Pattern Bush's are Breeders
  -- (141) and Resort Gorgeous's are Ladies (146) -- and this entry is what a
  -- woman on a map with no trainer under this graphic now gets, instead of
  -- nothing.
  [28] = 144,            -- WOMAN_2 -> the Aroma Lady, the majority of its trainers
  --
  -- OBJ_EVENT_GFX_WOMAN_1 (23) had NO entry either, and it is the same shape as
  -- the WOMAN_2 hole one release on: the host names it SPRITE_TEACHER
  -- (src/core/game3/scripting/gfx_ids.lua:14), SPRITE_ART has no SPRITE_TEACHER
  -- entry, and the sprite route is therefore declined by hostSpriteFor -- so
  -- every one of the seventeen non-trainer women wearing it was answered with
  -- nothing.  That is the reported "portraits are missing for some psychic
  -- sprites": the graphic IS the female psychic's.  Three trainers wear it --
  -- LAURA in Five Island's Lost Cave, JACLYN on Six Island's Green Path and
  -- RODETTE in the Seven Island Trainer Tower, all PSYCHIC -- and all three
  -- resolve through the trainer route already; the graphic itself answered
  -- nobody, which is what the report saw.  Picture 138 is the cart's female
  -- PSYCHIC bust, and it is what art/map_art.lua's own generated answer says
  -- for all three of those maps ([23] = 138), so this entry is that same rule
  -- for the maps that put no psychic on the graphic.  Measured over the whole
  -- game by .probe/dp3_psychic.lua: graphic 23 is worn by 3 trainers, all
  -- PSYCHIC, and by 17 non-trainer objects -- every one of which this entry is
  -- what gives a face.
  [23] = 138,            -- WOMAN_1 -> the female Psychic, the only class wearing it

  -- People the cart never drew a battle bust of.  Each of these was wearing
  -- somebody else's face: a Fat Man the Fisherman's and a female Worker the
  -- Scientist's.  No portrait is this mod's answer.
  [27] = false,          -- FAT MAN
  [48] = false,          -- WORKER (F)
  [76] = false,          -- DAISY, the rival's sister -- see the note below

  -- MAN (25) was on that list and is not any more, for the same reason the
  -- Balding Man's decline was dropped and CELIO's after it: a decline is right
  -- for a graphic's anonymous wearers and wrong for the one CLASS the cart put
  -- on it.
  --
  -- Measured over the whole game by .probe/dp3_classgfx.lua: graphic 25 is worn
  -- by 9 trainer objects -- six TAMERs (class 78) and three YOUNG COUPLEs
  -- (class 94) -- and by 20 ordinary men.  All nine trainers already had their
  -- own picture through the trainer-id route, and art/map_art.lua already says
  -- 103 for this graphic on each of the four maps a Tamer stands on (Viridian
  -- Gym, Fuchsia Gym, Victory Road 2F, Sevault Canyon).  So the sprite answered
  -- on those maps and nowhere else -- the reported "not all Tamer sprites have
  -- associated portraits" -- and the majority of the classes that wear it is
  -- the TAMER.
  --
  -- 103 is the Tamer's bust: a man in a man's clothes, whip raised
  -- (.probe/dp3_dump_pics.lua dumps it).  That is a plausible face for the
  -- twenty men, and it is exactly what the map route already gives the nine
  -- trainers on the four maps above.  The SPRITE route's own answer is still
  -- refused -- it would hand them the PokéFan's picture 66, a BOY with a net -- because
  -- this entry outranks it.
  [25] = 103,            -- MAN -> the TAMER, the majority class wearing it

  -- CELIO (89) used to be in that list, and keeping it there was the same
  -- mistake the Balding Man's was (see the note below): a decline that is right
  -- for a graphic worn by anonymous townsfolk and wrong for one worn by a NAMED
  -- person the cart drew.
  --
  -- OBJ_EVENT_GFX_CELIO (89) is worn by exactly ONE object in the whole game --
  -- Celio himself, on One Island's Net Center floor.  Measured by
  -- .probe/dp3_gfxwho.lua: 1 object, 0 trainers.  The cart's own overworld
  -- sprite for him IS this graphic (src/core/game3/scripting/gfx_ids.lua:45,
  -- sourced from the cart's event_objects.h), and the cart's bust for that
  -- graphic is picture 89 -- the Super Nerd's, a bespectacled figure in a lab
  -- coat, which is the visual the cart itself gives him.  Declining it left a
  -- named story character with no face on ANY of his boxes, which is the
  -- reported "Celio's portrait is missing from some of his dialogue boxes"; the
  -- fix is one graphic, one person, one picture, exactly as 1.9.4 did for the
  -- Engineer.
  --
  -- Graphic 89 and picture 89 being the same number is a coincidence of the two
  -- number spaces this mod exists to keep apart (see the header on why a class
  -- is not a picture), not a copy-paste.  The NAME route is what answers for him
  -- in the Net Center's coord-event scene, where the box carries no object at
  -- all; see NAME_ART.
  [89] = 89,             -- CELIO -> the cart's own bust for his graphic

  -- DAISY is the one entry here that the SPRITE route had never answered for.
  -- She was wearing a face anyway, and it came from the name route: her box
  -- opens "DAISY: Hi, PLAYER!", the pack HAS a trainer called DAISY (id 526,
  -- class 106, picture 147) -- and she is not that person.  Trainer 526 is a
  -- PAINTER, one of four on Five Island's Resort Gorgeous, and a Painter's
  -- overworld sprite is OBJ_EVENT_GFX_LASS.  Daisy Oak is the rival's sister,
  -- she wears OBJ_EVENT_GFX_DAISY (76), and the cart drew no bust of her: the
  -- front-pic list is 148 pictures of trainer CLASSES plus Oak, Red, Leaf,
  -- Brendan and May, and not one of them is her.  So a Painter's face on
  -- Pallet Town's Daisy is the reported bug's second instance -- the same
  -- shape as the Fat Man and ERIK, found by sweeping every line of every
  -- object in the game rather than by being reported: exactly four
  -- non-trainers in FRLG say a name the pack knows, two of them (LORELEI,
  -- SELPHY) ARE the trainer they name and keep their faces, and this is one of
  -- the other two.  Measured by .probe/dp3_name_hijack.lua.
  --
  -- The BALDING MAN is NOT one of those, and 1.9.4 is where that was measured
  -- rather than assumed.  It was declined alongside the Man, on the reasoning
  -- that the two share SPRITE_POKEFAN_M and so both wore the PokéFan's boy's
  -- face -- but the conclusion drawn from it was wrong: the cart HAS drawn this
  -- person, and the proof is the Engineer.
  --
  -- OBJ_EVENT_GFX_BALDING_MAN is the cart's own overworld sprite for the
  -- ENGINEER class.  Every one of the three Engineer objects in the game wears
  -- it -- Braxton on Route 11, Baily on Route 11, and the Engineer in
  -- Vermilion Gym -- and no other trainer class wears it at all, measured by
  -- .probe/dp3_gfx_census.lua.  Bulbapedia's Engineer article carries the same
  -- fact from the other side: its FireRed/LeafGreen overworld image is the
  -- balding man.  So picture 93, the Engineer in a hard hat with a wrench and a
  -- toolbox, is the cart's bust of this exact person, and the twenty-eight
  -- ordinary balding men in the world are the same person the Engineers are.
  --
  -- This is the reported "Engineer Braxton's incorrect portrait".  Braxton's
  -- own answer was already right -- the trainer route above reads his id and
  -- returns picture 93 -- but the GRAPHIC he wears answered nobody, so the
  -- twenty-eight non-trainers sharing his sprite had no face at all, and a
  -- build without the trainer route had none for him either.  One graphic, one
  -- person, one picture.
  [30] = 93,             -- BALDING MAN -> the Engineer, which is the same person

  -- People the cart DID draw, whom the host sprite vocabulary cannot name at
  -- all.  SPRITE_GRAMPS and SPRITE_GRANNY are not in SPRITE_ART, so the old
  -- folks had no portrait -- and they are the most common people in the game
  -- after the youngsters.  Picture 35 is EXPERT_F, the old woman, and every
  -- old-woman object the cart places is her.
  --
  -- The old MAN is picture 97, not 34, and that is this release.  1.9.1 read
  -- "pictures 34 and 35 are the EXPERT pair" off the class list, where EXPERT
  -- really does hold both -- but 34 is EXPERT_M, the old KARATE INSTRUCTOR in a
  -- white gi with a black belt and a red headband, and the bald old man in the
  -- blue robe that every OBJ_EVENT_GFX_OLD_MAN_* sprite depicts is the GAMER,
  -- picture 97.  The two are the same age and nothing else.  It matters because
  -- the old man is mostly NOT a trainer: of the 41 objects wearing an old-man
  -- graphic, six are GAMERs and 35 are ordinary people who have no trainer row
  -- to be resolved by -- so this entry, and not the script route, is what they
  -- wear.  Measured by .probe/dp3_gfx_census.lua, which also reports that the
  -- cart carries exactly one old-man bust.
  [32] = 97,             -- OLD MAN 1
  [33] = 75,             -- OLD MAN 2 -- the cart's OTHER old-man bust; see below
  [34] = 97,             -- OLD MAN LYING DOWN
  [35] = 35,             -- OLD WOMAN

  -- ------- five links the graphic table was missing
  --
  -- Taken from rom_sprites/ -- the cart's own assets, extracted with the
  -- engine's ow_extract and its trainer-picture dump -- and confirmed by eye
  -- against the pairs rather than inferred from a class name: each graphic here
  -- is the same person as the bust it now answers with.  Four of them answered
  -- NOTHING before this (no host entry, no class, no name), which is the
  -- reported "portraits are missing" for the people wearing them; the fifth is
  -- the correction below.
  --
  -- [33] is the one that CHANGES an answer rather than filling a hole.  It was
  -- 97, on the note further up that "the cart carries exactly one old-man bust".
  -- There are two: 97 and 75, and they are different men (75 is bald with white
  -- hair at the sides and a khaki outfit).  Graphic 33 is the one the SECOND
  -- wears, so it moves to 75 while 32 and 34 keep 97.
  [27] = 54,             -- FAT_MAN -> the COLLECTOR
  [31] = 33,             -- WOMAN_3 -> the POKéFAN
  [47] = 46,             -- WORKER_M -> the BIRD KEEPER
  [59] = 18,             -- CHEF -> the KINDLER
  -- The S.S. Anne captain.  NAME_ART answers the boxes that say "CAPTAIN: ",
  -- but his LAST line -- "Using CUT, you can chop down small trees.  Why not try
  -- it with the trees around VERMILION CITY?" -- carries no label, so the name
  -- route cannot reach it and the graphic is the only thing left.  Graphic 63 is
  -- his alone, so this is that same 81 for the unlabelled boxes.
  [63] = 81,             -- CAPTAIN -> the cart's captain bust
}

-- The cart's own Pokemon overworld graphics, which the host sprite vocabulary
-- has no entry for AT ALL.
--
-- FRLG puts Pokemon in the world as map objects -- the Spearow in the Viridian
-- house, the Snorlax asleep on Route 12, the Pikachu in the Copycat's room --
-- and names each one with its own OBJ_EVENT_GFX_* id: 109 SNORLAX through 150
-- DEOXYS_N.  NONE of those ids is in the host's TO_SPRITE table
-- (src/core/game3/scripting/gfx_ids.lua, which stops at 92), so every one of
-- them arrives as the SPRITE_YOUNGSTER fallback.
--
-- That fallback costs the species twice over, and the second cost is the one
-- that hid the first:
--
--   * speciesOfSprite reads the species off the SPRITE id -- SPRITE_PIKACHU IS
--     a Pikachu -- and a fallback SPRITE_YOUNGSTER names nothing, so the
--     species route has nothing to answer with;
--   * hostSpriteFor(110) is nil, so artFor declines the SPRITE route as well
--     (see step 7) -- correctly, because a Youngster's face on a Spearow is
--     the wrong-portrait bug that rule exists to prevent.
--
-- The result is no portrait at all for every Pokemon standing in the world,
-- which is the reported "some Pokemon, such as Spearow, do not display a
-- portrait at all".  The cart's graphics id is the fact being thrown away, and
-- it names the species outright, so it is read here.
--
-- 109-150 is the whole of the range, taken from pret's own
-- include/constants/event_objects.h: every id from OBJ_EVENT_GFX_SNORLAX up is
-- a Pokemon and the last is DEOXYS_N at 150 (151 is the S.S. Anne, a boat).
-- The three Deoxys forms are one species.  The values are the host species
-- keys -- the spelling `mod.content.pokemon` is keyed by, and the same one
-- `speciesOfSprite` produces from a sprite id.
--
-- 32 of these 42 ids are actually placed somewhere in the game, measured by
-- .probe/dp3_nonpeople_sweep.lua rather than assumed.  The list is the whole
-- range and not those 32 because the mapping is exact for every id, and
-- OBJ_EVENT_GFX_VAR_* (240-255) can place any of them at runtime.
local GFX_MON = {
  [109] = "SNORLAX",    [110] = "SPEAROW",    [111] = "CUBONE",
  [112] = "POLIWRATH",  [113] = "CLEFAIRY",   [114] = "PIDGEOT",
  [115] = "JIGGLYPUFF", [116] = "PIDGEY",     [117] = "CHANSEY",
  [118] = "OMANYTE",    [119] = "KANGASKHAN", [120] = "PIKACHU",
  -- The two Nidoran are spelled the way the CART spells them.  The engine's own
  -- dex is keyed by the name in the cart's species table -- names[29] is
  -- "NIDORAN♀" and names[32] is "NIDORAN♂" -- so "NIDORAN_F"/"NIDORAN_M" (the
  -- engine's keyName FOLD of the same two names, which is what the crop table
  -- wants) is not a spelling the dex answers to.  The female was already broken
  -- this way and so was the male; both now use the cart's own form.
  [121] = "PSYDUCK",    [122] = "NIDORAN♀",   [123] = "NIDORAN♂",
  [124] = "NIDORINO",   [125] = "MEOWTH",     [126] = "SEEL",
  [127] = "VOLTORB",    [128] = "SLOWPOKE",   [129] = "SLOWBRO",
  [130] = "MACHOP",     [131] = "WIGGLYTUFF", [132] = "DODUO",
  [133] = "FEAROW",     [134] = "MACHOKE",    [135] = "LAPRAS",
  [136] = "ZAPDOS",     [137] = "MOLTRES",    [138] = "ARTICUNO",
  [139] = "MEWTWO",     [140] = "MEW",        [141] = "ENTEI",
  [142] = "SUICUNE",    [143] = "RAIKOU",     [144] = "LUGIA",
  [145] = "HO_OH",      [146] = "CELEBI",     [147] = "KABUTO",
  [148] = "DEOXYS",     [149] = "DEOXYS",     [150] = "DEOXYS",
}

-- A second, independent way to answer "who": some of the ROM's own text
-- literally names its speaker, and the name is neither a trainer class nor a
-- species.  The value is looked up as a trainer's own name first and as a
-- class name second, so "PROF. OAK" is the pack's spelling of him.  The rival
-- is the exception: his pack name is whatever the player typed, and the class
-- name "RIVAL" is worn by two different people, so his entry is the picture
-- itself (see RIVAL_ART).
local NAME_ART = {
  OAK           = "PROF. OAK",
  ["PROF.OAK"]  = "PROF. OAK",
  ["PROF. OAK"] = "PROF. OAK",
  RIVAL         = RIVAL_ART,
  -- CELIO is the one name here whose box carries NO object to fall back on.  The
  -- Net Center's Bill/Celio scene is a coord event -- `lockall`, no world.talk --
  -- and it moves Bill, Celio AND the player, so sceneSpeaker answers nothing
  -- (more than one actor) and the text's own "CELIO: " is the only fact left.
  -- The value is the pack name for the bust his graphic maps to, so the picture
  -- is resolved the same way every other name is (see GFX_ART's note on 89).
  CELIO         = "SUPER NERD",
  -- BUTLER is the cart's one capitalised speaker label (see nameFromText), and
  -- it is the only one of the four that is a person.  The butler of Resort
  -- Gorgeous has no class of his own -- his script is a plain loadword/callstd,
  -- with no trainerbattle for the id route -- so his own object already answers
  -- through the graphic, and the graphic is OBJ_EVENT_GFX_GENTLEMAN (61).  The
  -- value names the class the cart itself draws him as, so the label and the
  -- object agree: 123 either way, instead of the label-less boxes falling to
  -- whichever object the scene moved last.
  BUTLER        = "GENTLEMAN",
  -- CAPTAIN is the S.S. Anne's, and his own text names him: "CAPTAIN: Ooargh…
  -- I feel hideous… Urrp! Seasick…" (SSAnne_CaptainsOffice, g3:08160b3a).  He
  -- wears OBJ_EVENT_GFX_CAPTAIN (63), which no other object in the game does,
  -- so the name route and the graphic agree -- but that graphic has no host
  -- sprite entry and he has no class of his own, so before this the name was
  -- the only thing that could answer and nothing was there to answer with.
  -- Picture 81 is the cart's captain bust.
  CAPTAIN       = 81,
}

-- A (map, graphic) override for a named character the GENERATED per-map table
-- cannot see.
--
-- art/map_art.lua is built from TRAINER objects (see the emitter,
-- .probe/dp3_emit_map_art.lua), so a map whose only speaker of a graphic is a
-- NON-trainer gets no entry for it -- and the graphic's own table then answers,
-- which for a shared graphic is its majority class.  Lady Selphy is the case
-- that matters: she wears OBJ_EVENT_GFX_WOMAN_2 (28), the graphic the LADY,
-- AROMA LADY and POKéMON BREEDER classes all share, so GFX_ART[28] is the AROMA
-- LADY's 144.  Her Resort Gorgeous House has no trainers at all, and neither
-- does Lost Cave Room 10, so both maps fell through to that.
--
-- What it looked like: the box that opens "I wish to see a POKéMON."
-- (g3:08171efe) carries no name and moves nobody, so it is resolved from her own
-- object -- 144, the Aroma Lady -- while every box of hers that DOES say
-- "SELPHY: " resolves 146 through the name route.  She changed face in the
-- middle of one conversation, and the Lost Cave double of her never had the
-- right one at all.  The outdoor Resort Gorgeous already says 146 for this
-- graphic, through the generated table, because two LADIES do stand there as
-- trainers; this table is that same answer for the two maps it cannot reach.
--
-- It is asked BEFORE MAP_ART and before GFX_ART, and it is deliberately
-- hand-written: the generated table must stay generated.
local PLACE_ART = {
  -- Lady Selphy's house on Five Island, and the Lost Cave room she also appears
  -- in.  Graphic 28 there is her, and she is a LADY (classes 11 and 105), whose
  -- own picture is 146.
  ["FR_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE"] = { [28] = 146 },
  ["FR_FIVE_ISLAND_LOST_CAVE_ROOM10"]      = { [28] = 146 },

  -- A `false` here DECLINES that graphic ON THAT MAP ONLY, and it is asked
  -- before MAP_ART and GFX_ART, so it is the way to take a face off one person
  -- without touching the same graphic everywhere else it stands.
  --
  -- The ROCKET GAME CORNER's coin seller is the case: he wears graphic 47, the
  -- male Worker, which 1.2.3 gave the Bird Keeper's bust -- right for the
  -- Silph Co. and S.S. Anne workers who also wear it, wrong for the man behind
  -- the counter, who is a shopkeeper and not a trainer at all.  Only this map's
  -- graphic 47 declines; every other map keeps 46.
  ["FR_CELADON_CITY_GAME_CORNER"] = { [47] = false },
}

-- People the CART draws in the neutral text colour, so `coloursAllowPortrait`'s
-- inference -- a neutral box is narration, a sign or an item box -- is wrong for
-- them.  Explicit (map, graphic), and it exists for exactly one NPC.
--
-- Pewter Museum's fossil-room scientist: he is the man who hands over the OLD
-- AMBER ("Ssh! Listen, I need to share a secret…"), he wears graphic 55, and his
-- script g3:0816a4ae sets no text colour, so every one of his boxes arrived
-- NEUTRAL and the mod took his face off all of them -- the "no portrait"
-- report.  He is a person talking, so he keeps his portrait, and nothing else in
-- the game is touched: the list is a (map, graphic) pair, not a rule.
local NEUTRAL_COLOUR_PORTRAIT = {
  ["FR_PEWTER_CITY_MUSEUM_1F"] = { [55] = true },
}

-- Three people the cart DREW but never gave a battle class -- so the class and
-- sprite routes above cannot answer for them, and the reporter asks for each by
-- name: Bill, Daisy and Mr. Fuji.
--
-- The cart keeps their art somewhere else.  FireRed's FAME CHECKER carries a
-- 64x64 portrait for four non-trainers -- Oak, Daisy, Bill and Mr. Fuji -- and
-- the engine extracts them to the same generated cache the rest of its ROM art
-- lives in, then loads them through its own Fame Checker UI (src/ui/game3/
-- fame_checker.lua, `portrait(person)`).  Asking that module for the portrait is
-- the same act as asking TrainerPic.front for a class picture: it reads the
-- PLAYER'S OWN extracted ROM art, so this mod still ships none.
--
-- The key is the text's own name, because that is the one fact a box carries for
-- a person who has no class, no species and often no trainer row.  The value is
-- the Fame Checker's person index (`FameChecker.PERSON`), and the picture id
-- below is the mod's own synthetic key into art/crops.lua -- it is deliberately
-- far above the cart's 148 front-pic ids so it can never collide with one.
--
-- Oak is left out on purpose: he already resolves to his POKéMON PROF. class
-- picture through NAME_ART, and moving him to the Fame Checker art would change
-- a portrait nothing asked to change.
local FAME_NAME = {
  BILL         = "BILL",
  DAISY        = "DAISY",
  ["MR. FUJI"] = "MRFUJI",
  ["MR.FUJI"]  = "MRFUJI",
  FUJI         = "MRFUJI",
}
local FAME_PERSON = { BILL = 13, DAISY = 1, MRFUJI = 14 }
local FAME_PIC = { BILL = 313, DAISY = 301, MRFUJI = 314 }

-- Two of the three also have an EXACT graphics id of their own, so a box that
-- does not name them still resolves: OBJ_EVENT_GFX_BILL (73) is worn only by
-- Bill and OBJ_EVENT_GFX_DAISY (76) only by Daisy (src/core/game3/scripting/
-- gfx_ids.lua, and GFX_ART's own note on 76).  Mr. Fuji gets no entry: he wears
-- a shared OLD_MAN graphic that every old man in the game wears, so a graphic
-- key would put his face on all of them -- the exact wrong-face bug this mod
-- exists to avoid.  His dialogue names him, and the name route answers.
local FAME_GFX = { [73] = "BILL", [76] = "DAISY" }
local FAME_SPRITE = { SPRITE_BILL = "BILL" }

return function(mod)
  -- ------- engine modules
  --
  -- The Gen 3 dialogue printer is not part of the Gen 1 API facade
  -- (src/mods/Gen3Compat.lua serves 15 Gen 1 modules and this is not one of
  -- them), so it is required directly.  That is what the manifest's
  -- engine_internals permission is for, and it is the only engine-internal
  -- reach this mod makes.
  local Message  = require("src.ui.game3.message")
  local Chrome   = require("src.ui.game3.chrome")
  local FrlgFont = require("src.ui.game3.frlg_font")
  local Display  = require("src.core.game3.display")

  -- Optional: the FRLG graphics-id table.  It is what says whether a host
  -- SPRITE_* was the engine's own mapping or its fallback (see GFX_ART above);
  -- without it, the sprite route behaves as it always did rather than
  -- declining, which is the safe direction to fail.
  local GfxIds
  do
    local ok, v = pcall(require, "src.core.game3.scripting.gfx_ids")
    GfxIds = ok and v or nil
  end

  -- The sprite the engine mapped this graphics id to, or nil when the id has
  -- no entry and the host fallback is what supplied the object's sprite.
  local function hostSpriteFor(gfx)
    if gfx == nil or not (GfxIds and GfxIds.TO_SPRITE) then return nil end
    return GfxIds.TO_SPRITE[tonumber(gfx)]
  end

  -- One call, always: mod.options:define REPLACES the option set rather than
  -- adding to it, so a second call would silently wipe the first.
  mod.options:define({
    { key = "style", label = "PORTRAIT", type = "choice", default = "inset",
      choices = { { "INSET", "inset" }, { "FRAMED", "framed" },
                  { "MARGIN", "margin" }, { "OFF", "off" } } },
    -- AUTO reads the player's own facing: you turn LEFT to talk to somebody
    -- standing to your left, so that is the side of the screen they are on and
    -- the side their face belongs on.  Facing UP or DOWN says nothing either
    -- way -- the speaker is straight ahead -- so that case keeps the
    -- traditional left.
    { key = "side", label = "SIDE", type = "choice", default = "auto",
      choices = { { "AUTO", "auto" }, { "LEFT", "left" }, { "RIGHT", "right" } } },
  })

  local function opt(key, fallback)
    local ok, value = pcall(function() return mod.options:get(key) end)
    if ok and value ~= nil then return value end
    return fallback
  end

  -- ------- the crop table
  --
  -- Read through the mod's own reader rather than require(), because a mod's
  -- files are not on package.path.
  local CROPS = {}
  do
    local ok, source = pcall(function() return mod:read("art/crops.lua") end)
    if ok and type(source) == "string" then
      local chunk = load(source, "@" .. tostring(mod.path) .. "/art/crops.lua")
      if chunk then
        local ok2, value = pcall(chunk)
        if ok2 and type(value) == "table" then CROPS = value end
      end
    end
  end

  -- ------- the cart's own trainer id for a script
  --
  -- The one fact that says WHICH trainer an object is, and the one the engine
  -- cannot supply at runtime.  Read through the mod's own reader for the same
  -- reason the crop table is: a mod's files are not on package.path.
  --
  -- The table is generated from the ROM by .probe/dp3_emit_trainer_ids.lua and
  -- the header there carries the whole argument.  The short version:
  --
  --   * the map event's `trainerType` is a TRAINER_TYPE_* flag, not the class,
  --     so the map data cannot name an object's trainer;
  --   * the object a mod is handed keeps only localId, graphicsId, x, y,
  --     elevation, movementType, movement, range, scriptKey and flag
  --     (src/import/gba/map_tree_extract.lua:49 slim_obj), so even the flag is
  --     gone by then;
  --   * the engine's own dig, TrainerSight.getTrainerId, reads the decoded
  --     script bundle -- and .probe/dp3_bundle_vs_rom.lua measures that bundle
  --     as able to answer for 15 of the game's 432 trainer objects, because
  --     ExtractScripts.extractFromRom seeds only the 18 maps of island1 and 559
  --     of 1584 scripts survive the disassembly.
  --
  -- `scriptKey` survives all three: it is what the engine itself keys a script
  -- by (Opcodes.key), it is on the runtime object, and the trainer id is two
  -- bytes past the script it names, because `trainerbattle` is
  -- op 0x5c, type u8, trainer u16, localId u16
  -- (src/core/game3/scripting/disasm.lua:31).
  --
  -- A key that is not in the table is an object this ROM does not make a
  -- trainer -- or a revision whose addresses moved -- and the caller falls
  -- through to the graphics route, which is what the mod did before this table
  -- existed.  The table only ever ADDS an answer.
  local TRAINER_IDS = {}
  do
    local ok, source = pcall(function() return mod:read("art/trainer_ids.lua") end)
    if ok and type(source) == "string" then
      local chunk = load(source, "@" .. tostring(mod.path) .. "/art/trainer_ids.lua")
      if chunk then
        local ok2, value = pcall(chunk)
        if ok2 and type(value) == "table" then TRAINER_IDS = value end
      end
    end
  end

  -- ------- WHERE the graphic is standing
  --
  -- art/trainer_ids.lua answers for a trainer exactly, and it is the first
  -- thing artFor asks.  But it can only answer when the engine has the cart's
  -- trainer table loaded -- `Trainers.pack()` reads a GENERATED cache,
  -- `gba/trainers.lua` under the engine's generated data tree -- and on a boot
  -- where that cache is not there yet every trainer falls past it and lands on
  -- the graphics table.
  --
  -- (That cache's full path is deliberately not spelled out anywhere in this
  -- file: modkit's MK301 rejects the literal string in ANY .lua body, comments
  -- included, because a mod must never ship or read the player's generated
  -- trees.  Naming it in a comment is harmless, but the checker is a substring
  -- search and cannot tell a comment from a load, so the path stays unwritten.)
  -- That fallback is one value per graphic, and it is the wrong shape for the
  -- shared ones, which is the whole of this release's report:
  --
  --   gfx 55 OBJ_EVENT_GFX_SCIENTIST -- 8 Super Nerds AND 14 Scientists
  --   gfx 26 OBJ_EVENT_GFX_ROCKER    -- 18 Bird Keepers, 9 Jugglers, 1 Rocker
  --   gfx 28 OBJ_EVENT_GFX_WOMAN_2   -- 4 Aroma Ladies, 3 Breeders, 2 Ladies
  --
  -- No single value can be right for any of those.  art/map_art.lua answers
  -- the question the graphics table cannot: WHICH of them is standing here.
  -- It is keyed by the engine's map id and by the graphic, and its value is
  -- the picture of the class that wears that graphic ON THAT MAP -- so the
  -- yellow-haired figure is the Juggler in Fuchsia Gym (pic 102), the Bird
  -- Keeper on Route 13 (104) and the Rocker on Route 12 (101), and the lab
  -- coat is the Super Nerd on Route 8 (89) and the Scientist in Silph Co.
  -- (107).  Measured over the whole game: 91 maps, 228 (map, graphic) pairs.
  --
  -- It runs AFTER the id route and BEFORE the graphics table.  That order is
  -- measured, not preferred: the map and the id disagree for 17 of the 432
  -- trainer objects -- a Route 16 Biker stands on a map whose graphic is a
  -- Hiker's -- and the id is the one that is right there.  A trainer keeps his
  -- own face; the map answers for everyone the cart gave no trainer data to.
  --
  -- A graphic this map puts no trainer under is ABSENT from the table, and the
  -- caller falls through to GFX_ART, which is the right answer for a graphic
  -- no trainer here wears at all.
  local MAP_ART = {}
  do
    local ok, source = pcall(function() return mod:read("art/map_art.lua") end)
    if ok and type(source) == "string" then
      local chunk = load(source, "@" .. tostring(mod.path) .. "/art/map_art.lua")
      if chunk then
        local ok2, value = pcall(chunk)
        if ok2 and type(value) == "table" then MAP_ART = value end
      end
    end
  end

  -- The map id, in the engine's own spelling (payload.mapId of `map.entered`,
  -- which MapCatalog.pretToEngine produced).  Tracked from the event so the
  -- read is free at draw time, and read back off the Map module when the
  -- event has not fired yet -- a portrait can be asked for on the very first
  -- map, before any warp has happened.
  local currentMapId = nil
  local function mapIdNow()
    if currentMapId then return currentMapId end
    local ok, Map = pcall(require, "src.core.game3.map")
    if ok and type(Map) == "table" then return Map.current end
    return nil
  end

  mod.events:on("map.entered", function(payload)
    if type(payload) == "table" and payload.mapId then
      currentMapId = payload.mapId
    end
  end)

  -- ------- speaker state
  --
  -- One record: the object the press in flight resolved.  It is set by the
  -- world.talk hook, which only fires for a press that reached an object with a
  -- script, so unlike Gen 2's World.talkNpc there is no stale reading of it to
  -- guard against.  What it does need is an end: walking away or leaving the
  -- map must drop it, or a box that arrives with no press behind it would wear
  -- the last person you spoke to.
  local pressSpeaker = nil

  -- Is a script running?  One implementation, asked from three places below:
  -- the scene route reads the running script's own actor rows, and the press
  -- record outlives a step and a move only while a script is in flight.
  local function scriptRunning()
    local ok, Space = pcall(require, "src.core.game3.scripting.space")
    if not ok or type(Space) ~= "table" then return false end
    local vm = Space.vm
    if type(vm) ~= "table" or type(vm.isRunning) ~= "function" then return false end
    local okR, running = pcall(vm.isRunning, vm)
    return okR and running == true
  end

  -- Where the SPEAKER of the last box stood, and which object that was.  It is
  -- deliberately not the press alone: a box finds its speaker two ways -- the
  -- press record (world.talk) and the scene route (sceneSpeaker, for a scene
  -- the NPC started) -- and a scripted departure is invisible to the engine in
  -- BOTH, because only the player's own step emits world.stepped.  See
  -- speakerLeftTheScene.
  local spokeObject = nil
  local spokeCell = nil

  -- Set when the speaker of the last box walks off mid-conversation.  A press
  -- is dropped outright (pressSpeaker = nil), but the SCENE route would simply
  -- name the same object again on the next box -- the actor's applymovement
  -- rows are still in the running script -- so the scene route has to be told
  -- as well, or the portrait it draws would survive the departure.
  local sceneGone = false

  -- How far a speaker must be moved between two of their own boxes to count as
  -- having LEFT the scene.  It is measured, not chosen: sweeping every script
  -- in the game for an NPC moved between two boxes (.probe/dp3_midmove.lua)
  -- gives 858 moves, and they fall into exactly two groups --
  --
  --     1 tile x267   2 tiles x390   3 tiles x101   4 tiles x 23   <- reposition
  --     6 tiles x 19  7 x1  8 x1  9 x13  10 x10  14 x8  25 x4  62..64 x16
  --
  -- -- and **there is no 5**.  A one-to-four tile move is a character being
  -- placed for the next line (Pewter's aide steps down to stand in front of the
  -- player before his second line, g3:081663e6 / :081663fc); six or more is a
  -- character walking out (the same aide's nine-tile exit to the left,
  -- g3:08166445).  Treating the first as a departure is the reported "Oak's
  -- aide's portrait is missing from 'I'm glad I caught up to you.'": the step
  -- down fired the test and every box after it came out bare.
  local LEFT_TILES = 5

  local function forgetSpeaker()
    pressSpeaker = nil
    spokeObject = nil
    spokeCell = nil
    sceneGone = false
  end

  -- ------- the record ends when the script walks the speaker out
  --
  -- The record names the object the last box was about, and it is that object's
  -- only while the script leaves them there.  FRLG walks a character OUT of a
  -- scene after their lines and then shows a box that is not theirs -- Oak's
  -- aide hands over the Running Shoes, walks nine tiles to the left, and the
  -- letter from Mom that follows was wearing his face -- and the engine raises
  -- nothing for it: only the PLAYER's own step emits world.stepped
  -- (src/core/game3/player.lua:653), and a script moving an OBJECT is silent.
  --
  -- So the fact is read rather than waited for.  The engine keeps every
  -- object's cell on the object (src/core/game3/objects.lua:155) and updates it
  -- when a step completes (:551), so the question "has this object moved since
  -- it last spoke?" is answerable at box time.
  --
  -- It covers BOTH ways a box finds its speaker.  The press record is the
  -- obvious one, but the aide's scene is reached by WALKING UP to him -- a coord
  -- event (g3:081662b7) that runs `lockall` and never raises world.talk -- so
  -- the portrait there comes from the scene route, and a departure test keyed on
  -- the press alone could never fire: sceneSpeaker simply named the aide again
  -- on the letter box and the portrait stayed.  Recording the object the box
  -- ACTUALLY resolved to (press or scene) is what closes that.
  --
  -- The cell is recorded LAZILY -- at the first box the speaker answers for --
  -- and that laziness is the whole of the "has spoken" test.  A script that
  -- moves the object BEFORE its first line (Bill's sprite stepping into the
  -- teleporter, a line-of-sight trainer walking up to the player) therefore
  -- records the cell it moved TO and is not mistaken for a departure; only a
  -- move between two boxes ends the record.
  --
  -- An object the map no longer has counts as gone, which is the same answer.
  local function speakerLeftTheScene()
    if type(spokeObject) ~= "table" or type(spokeCell) ~= "table" then
      return false
    end
    if not scriptRunning() then return false end
    local lid = tonumber(spokeObject.localId)
    if not lid or lid ~= spokeCell.lid then return false end
    local ok, Objects = pcall(require, "src.core.game3.objects")
    if not ok or type(Objects) ~= "table" or type(Objects.find) ~= "function" then
      return false
    end
    local okF, eo = pcall(Objects.find, lid)
    if not okF then return false end
    -- An object the map no longer has has certainly left.
    if type(eo) ~= "table" then
      pressSpeaker = nil
      spokeObject, spokeCell = nil, nil
      sceneGone = true
      return true
    end
    -- Moved -- but only a WALK-OFF counts.  A speaker who is placed for the
    -- next line (Pewter's aide stepping down to face the player) is still in
    -- the scene and still talking; see LEFT_TILES for the measurement that
    -- separates the two.
    local dx = math.abs((tonumber(eo.cellX) or 0) - spokeCell.x)
    local dy = math.abs((tonumber(eo.cellY) or 0) - spokeCell.y)
    if math.max(dx, dy) < LEFT_TILES then return false end
    -- The speaker has walked out.  Drop the press outright, and tell the SCENE
    -- route to stop naming them -- the actor's own applymovement rows are still
    -- in the running script, so sceneSpeaker would otherwise answer again.
    pressSpeaker = nil
    spokeObject, spokeCell = nil, nil
    sceneGone = true
    return true
  end

  -- Re-baseline the record on the cell the speaker is standing on now, for the
  -- box that just resolved to it.  Keyed on the object the box ACTUALLY used
  -- (`speaker.object`), so a box answered by the press and a box answered by the
  -- scene both refresh it, while a box answered only by the text -- which names
  -- somebody and is not tied to an object -- does not.
  local function noteSpokeCell(speaker)
    if type(speaker) ~= "table" then return end
    local eo = speaker.object
    if type(eo) ~= "table" then return end
    local lid = tonumber(eo.localId)
    if not lid then return end
    local ok, Objects = pcall(require, "src.core.game3.objects")
    if not ok or type(Objects) ~= "table" or type(Objects.find) ~= "function" then
      return
    end
    local okF, found = pcall(Objects.find, lid)
    if not okF or type(found) ~= "table" then return end
    spokeObject = eo
    spokeCell = { lid = lid, x = tonumber(found.cellX), y = tonumber(found.cellY) }
  end

  -- ------- resolving art
  --
  -- Every portrait is one of two engine-loaded pictures.  Both are cached by
  -- the engine, so asking twice is free, and both are 64x64.
  local function picArt(picId)
    picId = tonumber(picId)
    -- Picture 0 is the cart's NULL picture, not a picture.  It is what the
    -- empty trainer record points at, and `0` is truthy in Lua, so a guard
    -- that only asks "is there a number?" waves it through -- and then every
    -- speaker with no class of their own wears the same face.  See the trainer
    -- loop below, which is where that actually happens.
    if not picId or picId <= 0 then return nil end
    local ok, TrainerPic = pcall(require, "src.core.game3.trainer_pic")
    if not ok or not TrainerPic or not TrainerPic.front then return nil end
    local ok2, entry = pcall(TrainerPic.front, picId)
    if ok2 and type(entry) == "table" and entry.image then
      -- A copy, so stamping the picture's own id on it cannot leak back into
      -- the engine's cache, which hands out the same table for the same id.
      return { image = entry.image, w = entry.w, h = entry.h, pic = picId }
    end
    return nil
  end

  local function speciesArt(species)
    if type(species) ~= "string" or species == "" then return nil end
    local ok, Pokemon = pcall(require, "src.core.game3.pokemon")
    if not ok or not Pokemon or not Pokemon.frontPic then return nil end
    local record = mod.content.pokemon:get(species)
    local index = record and tonumber(record.index)
    if not index then return nil end
    local ok2, entry = pcall(Pokemon.frontPic, index)
    if ok2 and type(entry) == "table" and entry.image then return entry end
    return nil
  end

  -- The crop table's species KEY, which is not always the cart's display name.
  --
  -- `Pokemon.keyName` is the engine's own folding: NIDORAN♀ -> NIDORAN_F,
  -- NIDORAN♂ -> NIDORAN_M, MR. MIME -> MR_MIME, FARFETCH'D -> FARFETCHD,
  -- HO-OH -> HO_OH.  Lowercased and stripped of its separators that is the
  -- spelling art/crops.lua documents its pokemon keys in.  Until 1.9.0 the crop
  -- key was the DISPLAY name lowercased -- "nidoran♀", "mr. mime" -- so a
  -- per-species override filed for any of those four could never fire, which is
  -- the whole reason a per-Pokemon exception is worth having.
  local function speciesKey(species)
    if type(species) ~= "string" or species == "" then return nil end
    local ok, Pokemon = pcall(require, "src.core.game3.pokemon")
    if ok and Pokemon and Pokemon.speciesFromName and Pokemon.keyName then
      local idx = Pokemon.speciesFromName(species)
      if idx then
        local key = Pokemon.keyName(idx)
        if type(key) == "string" and key ~= "" then
          return (key:lower():gsub("[^a-z0-9]", ""))
        end
      end
    end
    -- No dex to fold the name with -- `speciesFromName` declined and `keyName`
    -- had no table to read.  The punctuation and the spaces come off a plain
    -- lowercase-and-strip on their own, but the two GENDER SIGNS do not: both
    -- would vanish and leave NIDORAN<female> and NIDORAN<male> sharing one key
    -- ("nidoran"), so a filed nidoranf / nidoranm entry could never fire.  They
    -- are folded here the way the engine folds them -- to the letter the key
    -- spells -- so the crop table's key is the same string with or without a
    -- dex behind it.
    local folded = species:lower():gsub("♀", "f"):gsub("♂", "m")
    return (folded:gsub("[^a-z0-9]", ""))
  end

  -- ------- the trainer pack: class -> picture, and name -> picture
  --
  -- THIS IS THE THING THAT IS DIFFERENT ABOUT GEN 3, and it is not obvious.
  --
  -- FRLG keeps a trainer's CLASS and their front PIC in two different number
  -- spaces, and they are not the same number.  A map object carries only the
  -- class (trainerType); TrainerPic.front() indexes the PIC table.  So asking
  -- it for a class id does not fail -- it returns whichever picture happens to
  -- sit at that index, which is somebody else's face.  Class 81 is RIVAL and
  -- its picture is 106; class 97 is POKéMON PROF. and its picture is 132.
  -- Class 17 is GUITARIST and its picture is 17, which is exactly why the
  -- mistake is easy to miss: it looks right for the low-numbered classes and
  -- is silently wrong from about class 22 up.
  --
  -- So the class is translated through the engine's own extracted trainer
  -- pack, which is the only place that knows both halves.  Three things can be
  -- asked of that pack, and all three are used below, most specific first:
  --
  --   * a trainer ID -- the row the cart files under that id.  This is the only
  --     EXACT one of the three, because an id names one trainer where a class
  --     names a kind and a name can be shared.  art/trainer_ids.lua turns an
  --     object's script key into the id and the row turns the id into the
  --     picture; it is the script route in artFor, and it is what settles the
  --     people a graphics id cannot tell apart.
  --   * a trainer's NAME -- the pack carries it, and names are far better
  --     behaved than classes: of the 428 distinct names in the cart, only three
  --     ever pin more than one picture.  So a name the dialogue itself used --
  --     "BROCK: " -- resolves exactly, and that is how the gym leaders get their
  --     own faces despite all eight sharing a class.
  --   * a CLASS -- most pin exactly ONE picture -- 83 of the 106 classes the
  --     cart actually uses -- so for those the translation is exact.  The rest
  --     pin several, because one class covers eight gym leaders or four Elite
  --     Four members.  Those are the ones a class alone cannot answer, and the
  --     choice made here is stated rather than hidden: the picture the most
  --     trainers of that class use, ties to the lowest id.  A class covering
  --     one character is exact; a class covering eight is one of the eight.
  local packIndex
  local function loadPackIndex()
    if packIndex then return packIndex end
    -- An EMPTY answer is not an answer, and it must not be remembered as one.
    --
    -- The cart's trainer table is a GENERATED cache -- Trainers.pack reads
    -- `gba/trainers.lua` under the engine's generated data tree -- so the first
    -- portrait this mod draws can precede it.  The old shape built the empty index and cached it
    -- BEFORE asking, which made one early ask permanent for the whole session:
    -- every trainer froze onto his graphic's face, which is precisely the
    -- 1.9.5 report -- the Super Nerds on a Scientist's picture, the Jugglers on
    -- a Bird Keeper's, the Aroma Ladies on nothing at all.  So the empty table
    -- is returned WITHOUT being cached, and the ask is repeated until it
    -- answers; the pack never goes away once it is there, so this settles after
    -- the first real one.  The cache is set at the foot of this function, on
    -- the one path where there is a trainer table to index.
    local ok, Trainers = pcall(require, "src.core.game3.scripting.trainers")
    local pack = ok and Trainers and Trainers.pack and Trainers.pack()
    if type(pack) ~= "table" then
      return { byClass = {}, byName = {}, byId = {}, classNameToId = {},
               classNameById = {}, classIdsByName = {}, classRows = {} }
    end
    local index = { byClass = {}, byName = {}, byId = {}, classNameToId = {},
                    classNameById = {}, classIdsByName = {}, classRows = {} }

    local names = pack.classNames
    if type(names) == "table" then
      for id, className in pairs(names) do
        if type(className) == "string" and className ~= "" then
          local key, num = className:upper(), tonumber(id)
          if num then
            -- Every id keeps its OWN name, for the reverse lookup...
            index.classNameById[num] = className
            -- ...and every id wearing a name is remembered as a candidate for
            -- it.  Which candidate wins is decided after the trainer rows have
            -- been counted -- see the tie-break at the foot of this function.
            local list = index.classIdsByName[key]
            if not list then list = {}; index.classIdsByName[key] = list end
            list[#list + 1] = num
          end
        end
      end
    end

    local trainers = pack.trainers
    if type(trainers) ~= "table" then return index end
    -- Cached HERE and nowhere earlier.  This is the one path with a real trainer
    -- table behind it; everything above this line is a pack that has not been
    -- generated yet, and a table that is not cached is a table that gets asked
    -- for again -- which is the whole fix.
    packIndex = index
    for _, row in pairs(trainers) do
      if type(row) == "table" then
        -- 0 is a NUMBER, and `if pic` asks only "is this not nil/false?", so a
        -- bare `if pic` reads the cart's empty record as a real mapping.
        --
        -- The cart's trainer table opens with one: trainer id 0 is class 0,
        -- pic 0, no name.  That single dead row is not a cosmetic problem,
        -- because EVERY map object that is not a trainer carries trainerType 0
        -- -- src/core/game3/objects.lua:170 is `trainerType = tonumber(
        -- def.trainerType) or 0`, and 0 is exactly what "ordinary person"
        -- means on this generation.  A byClass[0] entry therefore hands
        -- picture 0 to every townsfolk, family member and shopkeeper in the
        -- game: one identical face for every interaction that is not a battle.
        --
        -- Class 0 means "not a trainer" and picture 0 is the null picture, so
        -- neither is a mapping.  The same rule drops class 2 (AQUA LEADER),
        -- whose only row is the table's other pic-0 record.
        -- How many trainer rows the cart files under each class.  Every row
        -- counts, picture or not, because this is the evidence the name
        -- tie-break below weighs -- and it is the cart's own table that says
        -- which of two same-named classes it actually USES.
        local class = tonumber(row.class)
        if class and class > 0 then
          index.classRows[class] = (index.classRows[class] or 0) + 1
        end

        local pic = tonumber(row.pic)
        if pic and pic > 0 then
          -- The trainer's OWN row.  One id, one trainer, one picture -- no
          -- counting and no tie-break, which is why the script route below
          -- prefers it to the class whenever the id is known.
          local rowId = tonumber(row.id)
          if rowId and rowId > 0 then index.byId[rowId] = pic end
          if class and class > 0 then
            local slot = index.byClass[class]
            if not slot then
              slot = { counts = {}, best = pic, bestCount = 0 }
              index.byClass[class] = slot
            end
            local n = (slot.counts[pic] or 0) + 1
            slot.counts[pic] = n
            -- Deterministic: most common, ties to the lowest picture id.
            if n > slot.bestCount
                or (n == slot.bestCount and pic < slot.best) then
              slot.best, slot.bestCount = pic, n
            end
          end
          local name = row.name
          if type(name) == "string" and name ~= "" then
            local key = name:upper()
            local known = index.byName[key]
            if known == nil then
              index.byName[key] = pic
            elseif known ~= pic then
              -- Two pictures under one name: it names nobody in particular,
              -- so it must not answer.  false marks "ambiguous" as against
              -- nil's "unknown".
              index.byName[key] = false
            end
          end
        end
      end
    end

    -- ------- which class a duplicated NAME means
    --
    -- FRLG's class table opens with the HOENN classes -- it carries the whole
    -- Ruby/Sapphire roster first and repeats every one of those names for its
    -- own Kanto class further down: LASS is 49 and again 59, YOUNGSTER 29 and
    -- 57, FISHERMAN 31 and 69, BEAUTY 12 and 73, SAILOR 41 and 60, GENTLEMAN 22
    -- and 88, BLACK BELT 16 and 80.  The two are different people with
    -- different battle art, and "lowest id wins" -- the rule this table used
    -- until 1.9.2 -- therefore handed out the HOENN picture for 31 of the
    -- cart's class names.  That is the reported "certain NPCs display an
    -- incorrect portrait": the girl on Route 3 wore the Hoenn Lass's face, and
    -- the same defect put the Hoenn Fisherman on every pier, the Hoenn Beauty
    -- on every swimmer's towel and the Hoenn Gentleman on every deck.
    --
    -- The cart's own trainer table is the evidence for which id a name MEANS,
    -- because it is the table the cart actually uses: a class the game fields
    -- trainers under has rows, and the class it does not field has almost none.
    -- Measured across the cart's 742 rows, only 53 sit under a name's LOW-id
    -- half and 689 under the high-id half or under a class whose name is not
    -- duplicated at all.  Every pair tells the same story -- FISHERMAN is 69
    -- with 15 rows against 31's 1, LASS 59 with 26 against 49's 1, YOUNGSTER 57
    -- with 28 against 29's 1 -- so the tie is broken on row count.
    --
    -- The two pairs the row count cannot separate are handled without a special
    -- case, and neither moves a face:
    --
    --   * LEADER is 8 rows at 24 and 8 at 84.  Ties go to the HIGHER id, which
    --     picks 84 -- the Kanto half, whose pictures are 108 and 116-122, so
    --     the tie-break lands on the right side anyway.  Nothing resolves
    --     through the NAME "LEADER" regardless (the gym leaders answer by their
    --     own names, and GFX_ART by their graphics id), so the choice only
    --     decides which picture a CustomArt file named LEADER.png would beat.
    --   * POKéMON TRAINER is 0 rows at 0 and at 1, and 7 at 44, so it moves from
    --     no answer at all to picture 56.  Nothing writes that name either.
    --
    -- RIVAL is the pair that WOULD have moved a face: 81 (RIVAL_EARLY, picture
    -- 106) and 89 (RIVAL_LATE, picture 124) are both spelled "RIVAL", and 89
    -- has the rows.  The rival is therefore never resolved by name -- his
    -- picture is pinned in RIVAL_ART, and the three routes that used to write
    -- "RIVAL" write that number instead.  See there.
    for key, list in pairs(index.classIdsByName) do
      local best
      for _, id in ipairs(list) do
        if best == nil then
          best = id
        else
          local rowsBest = index.classRows[best] or 0
          local rowsId   = index.classRows[id] or 0
          if rowsId > rowsBest or (rowsId == rowsBest and id > best) then
            best = id
          end
        end
      end
      index.classNameToId[key] = best
    end
    return index
  end

  -- Class NAME -> class id, by inverting the engine's own extracted class list.
  --
  -- When the cart lists a name twice -- and it lists 31 of them twice, the Hoenn
  -- class first and its Kanto counterpart second -- the id is the one the cart
  -- files the most trainer rows under, ties to the higher id.  See the foot of
  -- loadPackIndex for why, and for the two pairs that rule cannot separate.
  local function classIdForName(name)
    if type(name) ~= "string" or name == "" then return nil end
    return loadPackIndex().classNameToId[name:upper()]
  end

  -- The reverse, so a class can be named in the log and in CustomArt/ filenames.
  local function classNameFor(classId)
    classId = tonumber(classId)
    if not classId then return nil end
    return loadPackIndex().classNameById[classId]
  end

  -- Class id -> front-pic id, through the pack.  Exact when the class pins one
  -- picture; the most common of them when it pins several.
  local function picForClass(classId)
    classId = tonumber(classId)
    if not classId then return nil end
    local slot = loadPackIndex().byClass[classId]
    return slot and slot.best or nil
  end

  -- Trainer ID -> front-pic id, through the pack.  Always exact: the cart files
  -- one row per trainer and the row carries one picture.  nil for an id the pack
  -- does not know, or one whose row has no picture -- which is a real case, and
  -- the reason this returns nil rather than 0.  See the script route in artFor.
  local function picForId(trainerId)
    trainerId = tonumber(trainerId)
    if not trainerId then return nil end
    return loadPackIndex().byId[trainerId]
  end

  -- A trainer's own name -> front-pic id.  nil when the name is unknown OR
  -- when it is worn by two different pictures -- a name that does not name
  -- anybody in particular must not answer, or a generic "GRUNT" would hand
  -- every Rocket in the game the admin's face.
  local function picForName(name)
    if type(name) ~= "string" or name == "" then return nil end
    local pic = loadPackIndex().byName[name:upper()]
    if pic == false then return nil end
    return pic
  end

  -- The player's own art, if they supplied it.  Checked first, so it beats
  -- every route below it.
  local function customArt(name)
    if type(name) ~= "string" or name == "" then return nil end
    local ok, image = pcall(function()
      return mod.assets:image("CustomArt/" .. name .. ".png")
    end)
    if ok and image then
      local ok2, w, h = pcall(function() return image:getDimensions() end)
      if ok2 and w and h then return { image = image, w = w, h = h, custom = true } end
    end
    return nil
  end

  -- The cart's own Fame Checker portrait, for the three people it drew there
  -- but nowhere in its battle art.  See FAME_NAME above for why this exists.
  --
  -- The image is asked of the engine's own Fame Checker UI rather than read
  -- from a path here, so this file never spells the generated-tree path the
  -- modkit lint rejects, and so the cache key, the palette and the 64x64 size
  -- are the engine's business and not this mod's.  Every reach is pcall'd: a
  -- boot whose cache has not been built yet simply declines, which is this
  -- mod's answer everywhere the art is not there.
  local function fameForKey(key)
    if type(key) ~= "string" then return nil end
    local person, pic = FAME_PERSON[key], FAME_PIC[key]
    if not (person and pic) then return nil end
    local ok, FC = pcall(require, "src.ui.game3.fame_checker")
    if not ok or type(FC) ~= "table" or type(FC.portrait) ~= "function" then return nil end
    local ok2, image = pcall(FC.portrait, person)
    if not ok2 or not image then return nil end
    local ok3, w, h = pcall(function() return image:getDimensions() end)
    if not ok3 or not (w and h) then return nil end
    return { image = image, w = w, h = h, pic = pic }
  end

  -- The name route's spelling of the same question, kept because a name is the
  -- most specific fact a box can carry.
  local function fameArt(name)
    if type(name) ~= "string" or name == "" then return nil end
    return fameForKey(FAME_NAME[name:upper()])
  end

  -- The key a speaker's own facts resolve to: the name the text used first,
  -- then an exact graphics id, then an exact sprite.  Ambiguous graphics (Mr.
  -- Fuji's OLD_MAN) are deliberately absent, so this never guesses.
  local function fameSpeakerKey(speaker)
    if type(speaker) ~= "table" then return nil end
    if type(speaker.name) == "string" then
      local byName = FAME_NAME[speaker.name:upper()]
      if byName then return byName end
    end
    if speaker.gfx ~= nil then
      local byGfx = FAME_GFX[tonumber(speaker.gfx)]
      if byGfx then return byGfx end
    end
    if type(speaker.sprite) == "string" then
      local bySprite = FAME_SPRITE[speaker.sprite]
      if bySprite then return bySprite end
    end
    return nil
  end

  -- The species a sprite id depicts, or nil.  SPRITE_PIKACHU's tail IS
  -- "PIKACHU"; the generic SPRITE_MONSTER / _FAIRY / _BIRD / _DRAGON tails are
  -- not species keys, so they decline by themselves -- which is exactly what
  -- the dolls and decorations want.
  --
  -- Worth knowing: on Gen 3 nothing in the world wears one of these as a
  -- HOST sprite.  The host sprite vocabulary the engine maps FRLG's graphics
  -- ids onto is humanoids only (src/core/game3/scripting/gfx_ids.lua), so no
  -- object ever arrives here as SPRITE_PIKACHU -- which is the whole reason
  -- `speciesOfGfx` below exists.  The route still earns its place, because the
  -- TEXT can name a species outright -- "PIKACHU: Pika!" -- and that goes
  -- through the same dex lookup.
  local function speciesOfSprite(sprite)
    if type(sprite) ~= "string" then return nil end
    local tail = sprite:match("^SPRITE_(.+)$")
    if not tail then return nil end
    tail = MON_SPRITE_FIX[tail] or tail
    if mod.content.pokemon:get(tail) then return tail end
    return nil
  end

  -- The species a GRAPHICS ID stands for, or nil.  The same question as above,
  -- asked of the other number.
  --
  -- It is needed because the host sprite vocabulary cannot answer for a Pokemon
  -- at all: every OBJ_EVENT_GFX_* id from 109 (SNORLAX) up is a Pokemon, not
  -- one of them is in the host's TO_SPRITE table, and the fallback the engine
  -- substitutes -- SPRITE_YOUNGSTER -- names no species.  So the sprite route
  -- above declines, and the sprite route in `artFor` declines with it (a
  -- Youngster's face on a Spearow is the wrong-portrait bug that rule exists to
  -- prevent).  The cart's own id is the fact left over, and GFX_MON reads the
  -- species straight off it.
  local function speciesOfGfx(gfx)
    if gfx == nil then return nil end
    return GFX_MON[tonumber(gfx)]
  end

  -- ------- the rival's name
  --
  -- The cart never spells the rival's name out.  His dialogue is written with
  -- the text placeholder FD 06 where the name belongs -- 28 sites in the ROM put
  -- FD 06 immediately before the colon -- and the engine expands that to whatever
  -- the player typed before a mod ever sees the string
  -- (src/core/game3/scripting/ops_a.lua:167 calls TextIR.toTextBox with the
  -- rival's name in the ctx).  So "RIVAL: " is a string the game does not
  -- actually produce, and the name that DOES arrive is one the trainer pack
  -- cannot know, because the pack lists the cart's own names, not the player's.
  --
  -- The save is the only place that name can be recognised, and both the live
  -- session and the save table carry it.  pcall'd like every other engine reach
  -- here: a headless or half-initialised boot must not turn a portrait lookup
  -- into an error.
  local function rivalName()
    local ok, name = pcall(function()
      local Runtime = require("src.core.game3.runtime")
      if type(Runtime) ~= "table" then return nil end
      local session = Runtime.getSession and Runtime.getSession()
      local fromSession = session and session.rivalName
      if type(fromSession) == "string" and fromSession ~= "" then
        return fromSession
      end
      local game = Runtime._game
      local save = game and game.save
      local fromSave = save and save.rivalName
      if type(fromSave) == "string" and fromSave ~= "" then return fromSave end
      return nil
    end)
    if ok and type(name) == "string" and name ~= "" then return name end
    return nil
  end

  local function isRivalName(name)
    if type(name) ~= "string" or name == "" then return false end
    local rival = rivalName()
    return rival ~= nil and rival:upper() == name:upper()
  end

  -- ------- which picture, in order
  --
  -- `speaker` is a plain descriptor the resolver below builds, so this function
  -- is testable without a world:
  -- { name =, class =, species =, sprite =, rival = }.
  local function artFor(speaker)
    if type(speaker) ~= "table" then return nil end

    -- A mapped value is a picture id, a sprite id that means a person, or a
    -- class name.  A NUMBER is already the first of those -- it is how the
    -- rival is pinned, because his class name is ambiguous (see RIVAL_ART) --
    -- and anything else is tried as a trainer's own name first and as a class
    -- name second, so "PROF. OAK" can be written the way it reads.
    local function viaMapping(mapped)
      if mapped == nil or mapped == false then return nil end
      if type(mapped) == "number" then return picArt(mapped) end
      return picArt(picForName(mapped))
        or picArt(picForClass(classIdForName(mapped)))
    end

    -- 1. the player's own art.  Three names are tried, most specific first:
    --    the name the dialogue used, the object's own sprite id, and finally
    --    the class's name -- so one CustomArt/HIKER.png can face every Hiker
    --    in the game without touching anybody else.
    --
    --    A numeric loop rather than ipairs: a nameless speaker leaves a hole
    --    at index 1, and ipairs stops at the first hole, which would silently
    --    skip both of the other two keys.
    local keys = { speaker.name, speaker.sprite, classNameFor(speaker.class) }
    for i = 1, 3 do
      local own = customArt(keys[i])
      if own then return own end
    end

    -- 1b. the cart's own Fame Checker portrait, for the three characters the
    --     reporter asks for by name.  It is asked BEFORE the pack's own name
    --     route because the pack knows one of those names and means a
    --     DIFFERENT person: FRLG's trainer table has a PAINTER called DAISY
    --     (id 526, picture 147), and Pallet Town's Daisy Oak is not her.  This
    --     route is also what gives the three of them a face in an NPC-started
    --     scene, where there is no press and no class and the text's own name
    --     is the only fact in play.
    --
    --     CustomArt/ still outranks it -- step 1 runs first -- so a player who
    --     drops CustomArt/BILL.png in gets their own art.  The name is the
    --     first key tried, then an exact graphics id (Bill 73, Daisy 76), so a
    --     box that does not name them still resolves.
    do
      local fame = fameForKey(fameSpeakerKey(speaker))
      if fame then return fame end
    end

    -- 2. a name the text used that is a trainer's own name -- exact.  A name the
    --    pack knows outranks everything below it, so a script that hands off
    --    between two characters box by box still gets both of them right.
    --
    --    With one exception, and it is the reported "fat man Eric in Fuchsia
    --    City, who incorrectly has a Scientist portrait".  The cart writes a
    --    speaker's name into the text and this route takes it at its word --
    --    but a name in a box is not always the name of the person standing
    --    there.  The fat man on Fuchsia City's first object says "ERIK: Where's
    --    SARA? I said I'd meet her here.", and ERIK IS a real trainer: id 177,
    --    a SUPER NERD whose picture 89 is a man in a white lab coat, which is
    --    the "Scientist portrait" that was reported.  He is not this fat man,
    --    and this fat man is not a trainer at all -- he wears gfx 27, and
    --    GFX_ART says of that graphic, deliberately, that the cart never drew a
    --    bust of this person.
    --
    --    So the name route does not get to overrule a graphic that has already
    --    DECLINED.  A `false` entry is the cart's own statement that this
    --    person has no battle bust, and a token in their dialogue cannot make
    --    one exist.  Everything else is untouched: a graphic that ANSWERS (the
    --    old man, the Hiker, the rival's SPRITE_BLUE) still takes the name
    --    first, which is what keeps a script handing off between two characters
    --    box by box correct, and a species named in the text is not a graphic
    --    question at all (see speakerFor, which resolves it before this runs).
    --
    --    ONE GRAPHIC IS EXEMPT from "the name first", and it is the fat man's.
    --    1.2.3 gave graphic 27 the Collector's bust out of rom_sprites, so it
    --    no longer declines -- and with it answering, Fuchsia City's fat man
    --    went straight back to wearing ERIK's lab coat, which is the same
    --    report this block was written for.  His own graphic is now a fact
    --    about who is standing there, so his box does not get to hand off to a
    --    name it mentions.  It is one graphic, not a rule: every other graphic
    --    that answers still takes the name first.
    local NAME_PROOF = { [27] = true }   -- FAT MAN: "ERIK: Where's SARA?"
    local gfxDeclines = speaker.gfx ~= nil
      and (GFX_ART[speaker.gfx] == false or NAME_PROOF[speaker.gfx] == true)
      and not speaker.species
    if speaker.name and not gfxDeclines then
      local byName = picArt(picForName(speaker.name))
      if byName then return byName end
    end

    -- 2b. a name the mod itself files, for a person the pack does not know.
    --     This runs HERE, with the pack's name route, and not at the end where
    --     it used to: a name the TEXT used is the one fact about who is
    --     speaking that the script cannot get wrong, and everything below is a
    --     guess from a graphic, which is a uniform and not a person.  Leaving it
    --     at the tail let the graphic route answer first, and that is the
    --     butler's bug -- see NAME_ART's BUTLER note.
    --
    --     It is deliberately NOT gated on gfxDeclines: that guard exists for a
    --     name the PACK knows, which can mean a different person (see the ERIK
    --     note above).  An entry here is this mod's own statement about a named
    --     character, which is exactly what a decline must not be able to
    --     overrule.
    do
      local byTextName = viaMapping(speaker.name and NAME_ART[speaker.name:upper()])
      if byTextName then return byTextName end
    end

    -- 3. the rival, recognised by the name the player gave him.  Only reached
    --    when the name route above could not answer -- which for the rival is
    --    every time, since the pack has no row called what the player typed.
    --    The value is RIVAL_ART, not the class name "RIVAL", because the pack
    --    spells two different rivals with that one name (see RIVAL_ART).
    if speaker.rival then
      local rival = viaMapping(RIVAL_ART)
      if rival then return rival end
    end

    -- 4. WHO the object is, where the cart itself says so.  A trainer's map
    --    script opens with a `trainerbattle` op that names him, and
    --    art/trainer_ids.lua turns that script's own key into the id; the cart's
    --    row for the id then names the picture.  It is the only EXACT route
    --    there is for a trainer, and it has to run BEFORE the graphics id,
    --    because a graphic is a uniform and not a person: OBJ_EVENT_GFX_SCIENTIST
    --    is worn by eight Super Nerds AND fourteen Scientists,
    --    OBJ_EVENT_GFX_ROCKER by eighteen Bird Keepers, nine Jugglers and one
    --    Rocker, and OBJ_EVENT_GFX_LITTLE_GIRL by every pair of Twins in the
    --    game.  No single value in GFX_ART can be right for all of them, and the
    --    value that was there handed the Super Nerds a Scientist's face, the
    --    Bird Keepers a Rocker's and the Twins a Lass's -- which is the reported
    --    "Super Nerd Leslie", "the baby/twin NPCs" and half of the old-man
    --    report.  Measured over the whole game: 34 graphics ids are worn by
    --    trainers and 16 of them are shared by two or more classes.
    --
    --    It also rescues the graphics the table deliberately DECLINES, and that
    --    is a second family of bugs rather than a nicety: GFX_ART answers
    --    `false` for OBJ_EVENT_GFX_MAN and OBJ_EVENT_GFX_BALDING_MAN because a
    --    generic man has no battle bust, which is right for the twenty ordinary
    --    men and twenty-eight ordinary balding men who wear them and wrong for
    --    the six Tamers, three Young Couples and three Engineers who also do --
    --    and a decline there stops the sprite route too, so those twelve had no
    --    portrait at all.
    --
    --    Nothing here touches a non-trainer.  A key the table does not carry
    --    leaves the descriptor exactly as it was, and the gym leaders are the
    --    worked example: their battles are not plain trainerbattle stubs at the
    --    head of the object's script, so they are not in the table, and GFX_ART
    --    still picks the eight of them out one by one.
    --
    --    And it only ever READS.  `eo.trainerId` is not written back, so the
    --    engine's own trainer sight and Vs. Seeker are left exactly as they
    --    were -- this mod does not get to change when a trainer spots you.
    local scriptTrainerId = tonumber(speaker.trainerId)
    if not scriptTrainerId and speaker.scriptKey then
      scriptTrainerId = TRAINER_IDS[speaker.scriptKey]
    end
    if scriptTrainerId then
      local art = picArt(picForId(scriptTrainerId))
      if art then return art end
    end

    -- 4b. WHERE the graphic is standing -- the reported rule, and the answer
    --     for every object the id route above could not name.
    --
    --     The id route needs the cart's trainer table, and that table is a
    --     GENERATED cache (Trainers.pack reads `gba/trainers.lua` under the
    --     engine's generated data tree).
    --     When it is not there yet, every trainer falls past step 4 and lands
    --     on the graphics table at step 5, which holds ONE value per graphic --
    --     and that is exactly the reported shape: a Super Nerd wearing the
    --     Scientist's picture 107, a Juggler wearing the Bird Keeper's 104, and
    --     an Aroma Lady, whose graphic 28 has no value at all, wearing nothing.
    --
    --     art/map_art.lua is the table that can tell them apart, because the
    --     map decides which class is standing here: gfx 26 is the Juggler in
    --     Fuchsia Gym (102), the Bird Keeper on Route 13 (104) and the Rocker
    --     on Route 12 (101); gfx 55 is the Super Nerd on Route 8 (89) and the
    --     Scientist in Silph Co. (107).  One graphic, one answer PER MAP.
    --
    --     It sits below the id on purpose.  The two disagree for 17 of the 432
    --     trainer objects -- a Route 16 Biker stands among Hikers, a Kindle
    --     Road Cooltrainer among Black Belts -- and there the id is the right
    --     one, because the cart named that man himself.  So a trainer keeps his
    --     own face and this route answers for the people the cart named nobody:
    --     the ordinary townsfolk, and every trainer on a boot whose generated
    --     trainer table has not been built.
    --
    --     A species is not a person, so it is not asked: a Pokémon standing in
    --     the world has its own art and the trainers around it say nothing
    --     about it.
    if speaker.mapId and speaker.gfx and not speaker.species then
      -- The hand-written override first: it exists for exactly the maps the
      -- generated table cannot reach (see PLACE_ART).
      local place = PLACE_ART[speaker.mapId]
      -- A `false` entry is this map's own decline, and it has to be read off the
      -- table before the `or nil` below swallows it.
      if type(place) == "table" and place[speaker.gfx] == false then return nil end
      local pic = type(place) == "table" and place[speaker.gfx] or nil
      if type(pic) ~= "number" then
        local here = MAP_ART[speaker.mapId]
        pic = type(here) == "table" and here[speaker.gfx] or nil
      end
      if type(pic) == "number" then
        local art = picArt(pic)
        if art then return art end
      end
    end

    -- 5. the cart's own GRAPHICS ID, where the host sprite vocabulary distorts
    --    or drops the person.  It has to run BEFORE the class route, because a
    --    class can cover eight gym leaders and the graphic is the one fact that
    --    says which of them is standing there.  A `false` entry declines the
    --    face rather than returning early, so an object that DOES carry a class
    --    still answers with its class picture below.
    local gfxEntry
    if speaker.gfx ~= nil then gfxEntry = GFX_ART[speaker.gfx] end
    if type(gfxEntry) == "number" then
      local art = picArt(gfxEntry)
      if art then return art end
    elseif type(gfxEntry) == "string" then
      local art = viaMapping(gfxEntry)
      if art then return art end
    end

    -- 6. the class the object carries, translated through the trainer pack
    local byClass = picArt(picForClass(speaker.class))
    if byClass then return byClass end

    -- 7. a sprite that means a person.  The route is skipped when the engine's
    --    own FALLBACK supplied the sprite, or when the graphics id above was
    --    declined: every FRLG graphic the host table does not list arrives as a
    --    SPRITE_YOUNGSTER, and a boy's face on a Swimmer is the wrong-portrait
    --    report this release is about.  Declining leaves no portrait, which is
    --    this mod's answer wherever the data does not decide.
    local spriteUsable = true
    if speaker.gfx ~= nil then
      if gfxEntry == false or not hostSpriteFor(speaker.gfx) then
        spriteUsable = false
      end
    end
    if spriteUsable then
      local entry = viaMapping(speaker.sprite and SPRITE_ART[speaker.sprite])
      if entry then return entry end
    end

    -- 8. a talking Pokemon.  `speaker.species` is already set for a creature
    --    the text named and for one whose graphics id says so; the fallback
    --    here reads the id for a descriptor built without `speakerFor`, which
    --    is what the suite hands in.
    return speciesArt(speaker.species or speciesOfGfx(speaker.gfx))
  end

  -- ------- who, from the text
  --
  -- The ROM's own dialogue names some of its speakers.  `text` is whatever
  -- Message.show was handed: a string, or a token list from the text IR.
  local function plainText(text)
    if type(text) == "string" then return text end
    if type(text) ~= "table" then return "" end
    local out = {}
    for _, token in ipairs(text) do
      if type(token) == "table" and type(token.s) == "string" then
        out[#out + 1] = token.s
      elseif type(token) == "string" then
        out[#out + 1] = token
      end
    end
    return table.concat(out)
  end

  local function nameFromText(text)
    local head = plainText(text):match("^%s*([^\n]+)")
    if not head then return nil end
    -- "NAME: ..." -- the cart's own spelling of a name, then a colon.
    --
    -- The token has to be as wide as the cart's names actually ARE, and that is
    -- wider than it looks.  FRLG spells four of its 386 species with a character
    -- an obvious `[A-Z0-9._-]` class rejects -- NIDORAN♀ and NIDORAN♂ (the
    -- gender signs), FARFETCH'D (an apostrophe) and MR. MIME (a space) -- and
    -- the two Nidoran are not a corner case: they are 2 of the 19 species that
    -- speak ANYWHERE in this game, so a class that stopped at the underscore
    -- made both of them resolve no speaker at all and draw no portrait.  The
    -- other 17 are CHANSEY, CLEFAIRY, CUBONE, DODUO, FEAROW, JIGGLYPUFF,
    -- MACHOKE, MACHOP, MEOWTH, NIDORINO, PIDGEOT, PIDGEY, PIKACHU, POLIWRATH,
    -- PSYDUCK, SEEL and WIGGLYTUFF -- all of which the old class already read.
    --
    -- Widening it costs nothing, because a name is only ever a HINT here.  A
    -- token that does not resolve leaves the object the press found untouched,
    -- and the class / sprite / graphics-id routes still answer for it -- the
    -- same property the rival's placeholder name needed (see speakerFor).  The
    -- cart's signs read "UNION ROOM:" and "ROOFTOP SQUARE:", which now match
    -- this pattern too; they resolve to nothing and draw nothing, which is the
    -- correct answer for a sign.
    --
    -- The normalisation is deliberately NOT done here.  The token is handed on
    -- as the cart spells it, and the engine's own norm_key is what folds ♀/♂ to
    -- _F/_M and strips the punctuation -- one implementation, in the place that
    -- also has to answer for a host key like "nidoranf".
    local name = head:match("^([A-Z][A-Z0-9%._%-'♀♂ ]*):")
    if not name then
      -- The cart has exactly ONE other speaker-label shape: a single
      -- capitalised word, "Butler: ".  Measured over every dialogue box in the
      -- game (.probe/dp3_labels.lua), there are only four labels of that shape
      -- -- Butler x5, Diary x4, Hint x1, Name x7 -- and only the first is a
      -- person.  The other three are the Pokemon Mansion's diaries and two sign
      -- shapes; they resolve to nothing through NAME_ART and the pack, so they
      -- are left exactly as they were.
      --
      -- It matters because a box that names nobody falls to the OBJECT route,
      -- and in a scene that route names the object the script moved most
      -- recently -- which is not necessarily the speaker.  The Resort Gorgeous
      -- House scene (g3:08171f34) moves SELPHY for her own line and then shows
      -- two of the butler's; those two boxes carried HER object (gfx 28) and
      -- wore whatever its graphic resolves to, while his third box carried his
      -- own (gfx 61) and wore the Gentleman's -- so the butler changed face
      -- mid-scene, and the face he wore on the other two was not his.
      name = head:match("^([A-Z][a-z][%a]*):")
    end
    if not name then return nil end
    -- The class admits a space, so a name can be caught with space before the
    -- colon; trim it, or the token stops matching the pack it is looked up in.
    return (name:gsub("%s+$", ""))
  end

  -- ------- who, when the NPC started it
  --
  -- A press names its speaker through world.talk, and a line-of-sight trainer
  -- through world.trainer_engaged.  A scene the NPC itself starts -- a coord
  -- event, an ON_FRAME map script, a cutscene that walks somebody over -- has
  -- neither: the engine begins the script and the box arrives with
  -- pressSpeaker nil.  That is the reported "a portrait appears when the player
  -- starts it but not when the NPC does".
  --
  -- When the text names the speaker, the name route still answers.  When it does
  -- not, the actor is read out of the running script, the way the Gen 2 port
  -- reads it: an FRLG scene MOVES and TURNS the object it is about, and the
  -- engine's decoded script is a table of command rows, so the object a scene
  -- touches is a fact in the data rather than a guess about the map.
  --
  -- Ambiguity answers nothing.  A scene that touches several objects -- a
  -- grunt AND the rival, a walk-on with a crowd -- has no single actor, and
  -- showing nobody is this mod's answer wherever the data does not decide.  A
  -- row whose id is not a live object (the player, a variable alias such as
  -- VAR_LAST_TALKED) resolves to nothing and is not counted.
  local ACTOR_OPS = {
    applymovement = true, applymovementat = true, turnobject = true,
    addobject = true, addobjectat = true, removeobject = true,
    removeobjectat = true, setobjectxy = true, setobjectxyperm = true,
  }

  local function sceneSpeaker()
    -- The same question the press record asks, so it is asked once (see
    -- scriptRunning).  A scene only exists while its script is running.
    if not scriptRunning() then return nil end
    -- ...and it stops existing for this conversation the moment its actor walks
    -- out of it.  The actor's applymovement rows are still in the running
    -- script, so without this the scene route would name a speaker who has left
    -- the scene -- Oak's aide's portrait on the letter from Mom, drawn from the
    -- coord-event path where there is no press to drop.  See
    -- speakerLeftTheScene.
    if sceneGone then return nil end
    local ok, Space = pcall(require, "src.core.game3.scripting.space")
    if not ok or type(Space) ~= "table" then return nil end
    local vm = Space.vm
    if type(vm) ~= "table" then return nil end

    local ctx = vm.ctx or {}

    local okO, Objects = pcall(require, "src.core.game3.objects")
    if not okO or type(Objects) ~= "table" or type(Objects.find) ~= "function" then
      return nil
    end

    -- Is this row one that moves or turns a live object the scene is about?
    local function actorAt(key, index)
      local rows = vm.scripts and vm.scripts[key]
      if type(rows) ~= "table" then return nil end
      local row = rows[index]
      if type(row) ~= "table" or not ACTOR_OPS[row.op] then return nil end
      local lid = tonumber(row.localId or row[1])
      -- 0xFF is the PLAYER, who is not an object and never a portrait.
      if not lid or lid == 0xFF then return nil end
      local okF, eo = pcall(Objects.find, lid)
      if not okF or type(eo) ~= "table" then return nil end
      return eo
    end

    -- The actor of THIS box is the object the script most recently moved or
    -- turned BEFORE the box, because that is the scene's own idiom: place the
    -- speaker, then show their line.
    --
    -- Scanning the whole script for "the one actor" cannot answer when a scene
    -- alternates between two people.  Three Island's bikers-and-locals scene
    -- (g3:081679b5) moves localId 1 (a local), shows his line, moves localId 3
    -- (the biker boss), shows his line, and so on for five boxes -- both are
    -- actors of the one script, so the old rule answered "nobody" and the whole
    -- scene came out bare.  Recency is what tells them apart, and it is also
    -- what the engine itself keys on: it derives the text colour from the
    -- object the script selected for the box (see the colour rule below).
    local function nearest(key, from)
      local rows = vm.scripts and vm.scripts[key]
      if type(rows) ~= "table" then return nil end
      local start = tonumber(from) or #rows
      if start > #rows then start = #rows end
      for i = start, 1, -1 do
        local eo = actorAt(key, i)
        if eo then return eo end
      end
      return nil
    end

    -- The command being executed comes first (a box is often opened by a called
    -- std stub, which has no actor rows of its own), then each caller outward
    -- from its own call site (ops_a.lua:356 pushes {listKey, index}).
    if ctx.pc and ctx.pc.listKey then
      local eo = nearest(ctx.pc.listKey, ctx.pc.index)
      if eo then return eo end
    end
    local stack = ctx.stack or {}
    for i = #stack, 1, -1 do
      local frame = stack[i]
      if type(frame) == "table" then
        local eo = nearest(frame.listKey, frame.index)
        if eo then return eo end
      end
    end
    -- Last resort: the entry point, in case the scene is reached by a `goto`
    -- that left no frame behind.
    if type(vm._scriptKey) == "string" then
      local eo = nearest(vm._scriptKey)
      if eo then return eo end
    end
    return nil
  end

  -- ------- the resolver
  local function speakerFor(text)
    -- ONE-OFF, and deliberately not a rule.  "A MACHOP is stomping the land
    -- flat." is the player's own observation about the Machop standing in front
    -- of them, not the Machop speaking, so it must draw no portrait -- while the
    -- SAME object's other box, "MACHOP: Guoh! Gogogoh!", is the creature talking
    -- and keeps its face.  Every other Pokemon in the world is untouched: this
    -- matches one exact line, not a class of lines, and there is no rule here to
    -- catch anything else.
    if type(text) == "string"
        and text:find("A MACHOP is stomping the land flat", 1, true) then
      return nil
    end

    -- The object the running script stages for THIS box is read FIRST, and the
    -- press record is the fallback.  A script that moves or turns somebody
    -- immediately before a line is saying "this line is theirs" -- that is the
    -- scene route's own rule (see sceneSpeaker) -- and it has to outrank the
    -- press, because a single pressed script can hand the box to somebody else.
    -- Three Island's biker/local dialogue (g3:0816786f, reached by pressing any
    -- one of them) alternates four speakers inside one press: the pressed
    -- object is right for at most one of its boxes, and the other three wore its
    -- face.  When the script stages nobody -- the ordinary `lock`/`faceplayer`/
    -- box press -- sceneSpeaker answers nil and the press is used, which is
    -- every other conversation in the game.
    -- A script that MOVES a Pokemon is not staging a speaker -- it is moving a
    -- Pokemon.  Cerulean City's LASS runs `applymovement localId=5` to walk the
    -- SLOWBRO beside her and only then says her own lines, so the scene route
    -- named the Slowbro for every one of her boxes and she wore its face.  A
    -- species is not a person -- the same rule the map route and the name route
    -- already keep -- so an actor that resolves to a species does not outrank
    -- the press.  With no press behind the box (a coord event, an ON_FRAME
    -- scene) the actor still stands, which is what keeps a talking Pokemon in a
    -- scene of its own.
    local eo = sceneSpeaker()
    if type(eo) == "table" and type(pressSpeaker) == "table"
        and speciesOfGfx(eo.graphicsId) then
      eo = pressSpeaker
    end
    if type(eo) ~= "table" then eo = pressSpeaker end
    local class, sprite, species, gfx, scriptKey, trainerId, mapId
    if type(eo) == "table" then
      local def = eo.def or {}
      class = tonumber(eo.trainerType) or tonumber(def.trainerType)
      sprite = eo.sprite or def.sprite
      -- The FRLG graphics id, which is more specific than the sprite the host
      -- derived from it: several graphics share one sprite, and an id with no
      -- host entry is answered by the fallback SPRITE_YOUNGSTER.  See GFX_ART.
      gfx = tonumber(eo.graphicsId) or tonumber(def.graphicsId)
        or tonumber(def.graphics)
      -- WHO the object is, as against what it looks like.  The script key is
      -- the handle the engine itself uses for an object's script, and the
      -- trainer id is the one fact that names a trainer exactly; both are read
      -- here so the script route in artFor can reach them, and both are nil for
      -- an ordinary person, which is what keeps that route out of their way.
      -- See art/trainer_ids.lua for why the key is the only route left.
      scriptKey = eo.scriptKey or def.scriptKey
      trainerId = tonumber(eo.trainerId) or tonumber(def.trainerId)
      -- WHERE the object stands.  A graphic is a uniform and several classes
      -- wear it, so the graphic alone cannot say which picture belongs to the
      -- person in front of the player -- the map can, because it is the map
      -- that decides which of those classes is standing here.  See MAP_ART.
      mapId = mapIdNow()
      -- 0 is the cart's "not a trainer", and it is what every ordinary object
      -- carries, so it is not a class and must not be treated as one.  The
      -- sprite route still gets its turn for a story character who has no battle
      -- class but does have art.
      if class and class <= 0 then class = nil end
      -- A sprite id whose tail is a species IS that species, so resolve it here
      -- rather than leaving the descriptor to guess later.  A Pokemon standing
      -- in the world has no such sprite -- the host vocabulary has no Pokemon
      -- in it -- so the cart's graphics id answers instead.  See GFX_MON.
      species = speciesOfSprite(sprite) or speciesOfGfx(gfx)
    end

    local name = nameFromText(text)
    if name then
      local record = mod.content.pokemon:get(name)
      if record then
        -- A species named itself.  Answer it, and answer it exactly: a token
        -- the dex knows must not fall through to whoever is standing there.
        return { name = name, species = name, fromText = true }
      end
      -- A name the mod cannot place must NOT throw away an object it can.
      --
      -- The cart does not always spell a speaker's name out -- the rival's is
      -- written as the FD 06 placeholder and expanded to whatever the player
      -- typed -- so a box can arrive naming somebody the trainer pack has never
      -- heard of.  The old shape returned here and stopped, which is why the
      -- rival had no portrait: the name resolved to nothing, and the pressed
      -- object (SPRITE_BLUE, which the sprite route answers perfectly well) had
      -- already been thrown away one line earlier.
      --
      -- So the object rides along.  This is not a demotion of the text: a name
      -- the pack DOES know is still tried first in artFor and still wins
      -- outright, so a script that hands off between two characters box by box
      -- is unaffected.  Only a name that resolves to nothing falls through to
      -- the object -- and a face for the person the player actually walked up to
      -- beats no face at all.
      return { name = name, fromText = true, rival = isRivalName(name),
               class = class, sprite = sprite, species = species, gfx = gfx,
               scriptKey = scriptKey, trainerId = trainerId, mapId = mapId,
               object = eo }
    end

    if not class and not sprite and not gfx then return nil end
    return { class = class, sprite = sprite, species = species, gfx = gfx,
             scriptKey = scriptKey, trainerId = trainerId, mapId = mapId,
             object = eo }
  end

  -- ------- cutting the portrait
  --
  -- The source is 64x64.  The window is a square taken from art/crops.lua and
  -- scaled into the art slot, so a smaller window is a closer crop.
  --
  -- The crop is a QUAD, not a copy of the pixels, and that is not a shortcut --
  -- it is the only thing that works.  LÖVE removed Image:getData in 11.0, and
  -- this engine targets 11.5, so a source picture cannot be read back to an
  -- ImageData at runtime at all.  (The engine agrees: it never calls getData
  -- anywhere and instead keeps the ImageData it built the Image from.)  A quad
  -- is the engine's own way to draw part of a texture: it needs no readback, it
  -- keeps the one resample, and it goes through the picture's own
  -- nearest-neighbour filter, which is what keeps the art on the pixel grid.
  local cropCache = {}
  local cacheKey = nil

  -- ------- which rectangle, from the most specific key that has one
  --
  -- There are TWO key spaces and they answer different questions:
  --
  --   `speakers`   WHO is talking -- name:<NAME>, gfx:<id>, sprite:<SPRITE_*>,
  --                class:<id>
  --   the picture  WHICH 64x64 front pic the portrait was cut from --
  --                `trainers[<front-pic id>]` / `pokemon[<species key>]`
  --
  -- The picture tables came first and they are still the right place for most
  -- of it, because a rectangle frames a PICTURE and two characters who share
  -- one should share the rectangle.  What they cannot express is the case where
  -- two speakers share a picture and only one of them is framed badly -- and
  -- that is not hypothetical, it is the reason `speakers` exists.  A sprite key
  -- is a statement about a PERSON; a picture key is a statement about ARTWORK
  -- several people may wear.
  --
  -- Which one to reach for, in one line: file against the PICTURE when the
  -- artwork is what is wrong, and against the SPEAKER when a person is.  The
  -- Fisherman in art/crops.lua is the worked example of the first, and its
  -- comment says why the second could not have been used there.
  --
  -- The speaker keys are tried first, most specific to least: the name the text
  -- used, then the cart's own graphics id, then the host sprite id, then the
  -- class.  That is the same order artFor resolves a speaker in, so "the most
  -- specific fact wins" is one rule in both places rather than two.
  --
  -- Note there is no `species:` key.  A Pokemon's species key IS its identity,
  -- so `pokemon[<key>]` was always an interaction table; it is the NPC side
  -- that had no such key, because an ordinary NPC carries no class, no species
  -- and often no name -- its sprite and its graphics id are all it has.
  --
  -- Everything here is optional and everything falls back to `defaults`, so a
  -- crop table with no overrides in it behaves exactly as it did before these
  -- keys existed.
  -- A candidate becomes a rectangle only if it is three NUMBERS.  Anything else
  -- -- a string, a table with two entries in it, a key that was never filed --
  -- is not an override at all, and falls through to the next key rather than
  -- becoming a crop with a nil side.  The direction matters: a malformed entry
  -- that WON would be cut with size nil, which cutPortrait clamps to a
  -- one-pixel window -- a portrait that is drawn and invisible, and one of the
  -- hardest failures in this mod to diagnose.  Degrading to the rule instead is
  -- the same choice the clamp itself makes for a rectangle that runs off its
  -- sprite (see art/crops.lua: "degrades to the nearest legal crop").
  local function asRect(rect)
    if type(rect) ~= "table" then return nil end
    local x, y, size = tonumber(rect[1]), tonumber(rect[2]), tonumber(rect[3])
    if not (x and y and size) then return nil end
    return { x = x, y = y, size = size }
  end

  local function speakerRect(speaker)
    local table_ = CROPS.speakers
    if type(table_) ~= "table" or type(speaker) ~= "table" then return nil end
    local keys = {
      speaker.name and ("name:" .. speaker.name:upper()),
      speaker.gfx ~= nil and ("gfx:" .. tostring(speaker.gfx)),
      speaker.sprite and ("sprite:" .. speaker.sprite),
      speaker.class ~= nil and ("class:" .. tostring(speaker.class)),
    }
    for i = 1, 4 do
      local rect = asRect(keys[i] and table_[keys[i]])
      if rect then return rect end
    end
    return nil
  end

  local function rectFor(kind, key, speaker)
    -- A picture the cart drew TWO people into.  `key` is the picture, the
    -- speaker's own graphics id says which half is standing there, and that
    -- half is the whole answer -- so it is asked FIRST, before the picture
    -- table, because one rectangle for picture 129 cannot be right for both
    -- members of a Young Couple.  It is asked before `speakers` as well, since
    -- a `gfx:29` entry there would also catch every ordinary Beauty, who wears
    -- picture 98 and is not half of anything.  See art/crops.lua: "a third key
    -- space, for the pictures that hold two people".
    local pairSide = speaker and speaker.gfx ~= nil and CROPS.pairSide
      and CROPS.pairSide[tonumber(speaker.gfx)]
    local pair = pairSide and CROPS.pairs
    local pairRect = type(pair) == "table" and asRect(pair[key] and pair[key][pairSide])
    if pairRect then return pairRect end

    local rect = speakerRect(speaker)
    if not rect then
      local table_ = CROPS[kind]
      rect = asRect((type(table_) == "table" and key) and table_[key] or nil)
    end
    if not rect then rect = asRect(CROPS.defaults and CROPS.defaults[kind]) end
    return rect
  end

  local function cutPortrait(entry, rect)
    if not (entry and entry.image and rect) then return nil end
    local sw, sh = tonumber(entry.w), tonumber(entry.h)
    if not (sw and sh) then return nil end
    local size = math.max(1, math.min(rect.size, SLOT))
    local x = math.max(0, math.min(rect.x, sw - size))
    local y = math.max(0, math.min(rect.y, sh - size))

    local g = love and love.graphics
    if not (g and g.newQuad) then return nil end
    -- The texture form is the documented one; the two-number form is the same
    -- rectangle spelled without the picture, so it covers a build whose newQuad
    -- will not take the Image directly.
    local ok, quad = pcall(g.newQuad, x, y, size, size, entry.image)
    if not ok or not quad then
      ok, quad = pcall(g.newQuad, x, y, size, size, sw, sh)
    end
    if not ok or not quad then return nil end
    return { image = entry.image, quad = quad, w = size, h = size }
  end

  -- A cache must never remember a MISS: a miss costs one failed lookup to
  -- retry, which is nothing next to a portrait that never comes back.  It is
  -- keyed on the SOURCE, and inside that on the RECTANGLE -- see the slot below
  -- -- so a mod that swaps a class's picture is followed rather than served a
  -- stale cut, and so is one that files a per-speaker rectangle against a
  -- picture some other speaker already cut.
  local function portraitFor(speaker)
    if type(speaker) ~= "table" then return nil end
    local entry = artFor(speaker)
    if not entry then return nil end
    if entry.custom then return entry end

    -- `kind`/`key` name the PICTURE: a rectangle frames a 64x64 front pic, so
    -- two characters sharing one picture share one rectangle, and two
    -- characters sharing one CLASS but drawn differently (Brock and Misty are
    -- both class 84) do not collide.  It is a fallback now rather than the only
    -- key -- the speaker is handed on as well, so a rectangle filed against a
    -- PERSON outranks one filed against the artwork they wear.  See speakerRect.
    local kind, key
    if speaker.species then
      kind, key = "pokemon", speciesKey(speaker.species) or speaker.species:lower()
    elseif entry.pic then
      kind, key = "trainers", tostring(entry.pic)
    else
      return nil
    end

    -- The rectangle is resolved BEFORE the cache is consulted, because the
    -- cache slot is the RECTANGLE and not the speaker: two speakers who share a
    -- picture and a window share a cut, and two who share a picture but not a
    -- window do not -- which is precisely what a speaker-key override creates.
    -- Keying the slot on the speaker would serve the second of them the first's
    -- cut; keying it on the picture alone would do that for ANY override, since
    -- the picture is the same either way.  See rectFor.
    local rect = rectFor(kind, key, speaker)

    local cacheId = tostring(entry.image) .. "|" .. kind .. "|" .. key
    if cacheKey ~= cacheId then
      cropCache, cacheKey = {}, cacheId
    end
    local slot = (rect and (rect.x .. "," .. rect.y .. "," .. rect.size)) or "-"
    local hit = cropCache[slot]
    if hit then return hit end

    local cut = cutPortrait(entry, rect)
    if cut then
      -- Pokemon front pics are drawn facing left and a trainer pic is a bust
      -- with no facing at all, so only the former is worth turning round.  The
      -- blit flips `directional` art when it lands on the LEFT, which is what
      -- keeps a creature looking in towards its own dialogue.
      cut.directional = (kind == "pokemon")
      cropCache[slot] = cut
    end
    return cut
  end

  -- ------- side
  local function sideFor()
    local side = opt("side", "auto")
    if side == "left" or side == "right" then return side end
    -- AUTO: the player turned to face whoever they are talking to.  Gen 3's
    -- avatar keeps its facing on the module itself -- a plain field, not an
    -- accessor -- and it is still that direction when the box opens, because
    -- the engine reads it the same way to pick the cell it interacts with
    -- (src/core/game3/field.lua: `DIR_BY_FACING[P.facing]`).  So read the
    -- field, and keep the accessor form as a fallback in case a revision grows
    -- one.
    local facing = nil
    local ok, player = pcall(require, "src.core.game3.player")
    if ok and type(player) == "table" then
      facing = player.facing
      if facing == nil and player.get then
        local ok2, p = pcall(player.get)
        if ok2 and type(p) == "table" then facing = p.facing or p.facingDir end
      end
    end
    if facing == "left" then return "left" end
    if facing == "right" then return "right" end
    return "left"
  end

  -- ------- drawing
  local function boxTiles()
    return Chrome.DLG_LEFT, Chrome.DLG_TOP, Chrome.DLG_W, Chrome.DLG_H
  end

  -- `flip` mirrors the art horizontally.  Pokemon front pics are drawn facing
  -- LEFT, which is the right way round for the default right-hand placement --
  -- the creature looks in towards the words -- so art on the LEFT has to be
  -- turned back the other way.  Trainer pics are busts and are never flipped.
  -- Negative sx mirrors around the draw origin, so the origin is walked to the
  -- mirrored art's own right edge first.
  -- The size a cut is drawn at, in whole pixels.
  --
  -- The scale is a RATIO, so the product is not exact: a crop that does not
  -- divide the content -- the suite's 12px one, at 32/12 -- multiplied by
  -- MARGIN's window scale of 3 comes out as 95.99999999999999 rather than 96.
  -- Rounding HERE is what makes the art meet the window's own
  -- edge -- and the offsets in `drawFramed` and `drawInset` are computed from
  -- this rounded number rather than from the raw product, so the centring and
  -- the draw cannot disagree.  `blit` uses it too, so a flipped draw's origin is
  -- the same width the centring was computed against.
  --
  -- Measured rather than assumed (.probe/dp3_scale_probe.lua).  Rounding here is
  -- also what the call sites' `math.max(0, ...)` clamps are a guard against: when
  -- a window's size in device units has a fractional part of a half or more,
  -- this rounds the art UP past the window it is filling, and the unclamped
  -- centring offset is then floor(-0.333 / 2) = -1, which would draw the art a
  -- pixel outside its own outline.
  --
  -- That case is now REACHED BY NEITHER layout, and the clamps are defensive.
  -- It belonged to MARGIN's fixed panel, whose 46px window was multiplied by
  -- MARGIN's unit -- gameWidth / Display.W, which on a device is Sp / dpiX, so
  -- at Sp=5, dpiX=3 the window was 76.667px and the art rounded to 77.  Both
  -- layouts size their panel to the art now, so the window is the crop's own
  -- size times a whole-number zoom, which a 30px crop keeps on the pixel grid at
  -- every (Sp, dpiX).  The clamps stay because the offset is a real number for a
  -- crop that is not square -- it is the slack on the axis the zoom does not
  -- use -- and because a window's size in device units can still be fractional.
  local function artSize(portrait, scale)
    return math.floor((portrait.w or 1) * scale + 0.5),
           math.floor((portrait.h or 1) * scale + 0.5)
  end

  local function blit(portrait, x, y, scale, flip)
    if not portrait then return end
    love.graphics.setColor(1, 1, 1, 1)
    local w = artSize(portrait, scale)
    local dx = flip and (x + w) or x
    local sx = flip and -scale or scale
    if portrait.quad then
      love.graphics.draw(portrait.image, portrait.quad, dx, y, 0, sx, scale)
    else
      -- CustomArt has no rectangle of its own; the whole picture is the crop.
      love.graphics.draw(portrait.image, dx, y, 0, sx, scale)
    end
  end

  -- Fit a cut into a window: the largest scale that keeps it inside, on both
  -- axes at once, so the aspect ratio is preserved.
  --
  -- INSET's caller only, now.  It is a FILL rather than a snap to a whole number,
  -- which is what lets a crop of any size sit in the box's own 32px slot: the art
  -- is centred in the slot afterwards, so a fractional scale is a slightly soft
  -- pixel rather than a ring of white, and the alternative -- snapping to 1x --
  -- would leave a smaller crop marooned in the middle of the slot.
  --
  -- The framed panel used to come through here too, to fill a fixed 46px window,
  -- and that is the behaviour this release reverted: 1.53x for the default 30px
  -- crop, so the framed portrait was half again as large as the inset one.  The
  -- framed window takes a whole-number zoom instead (see panelPlan), so nothing
  -- but INSET asks for a fill.
  --
  -- This used to clamp at 1x, so a crop narrower than its slot rendered at its
  -- own tiny size -- a face the size of a full stop in the middle of the box,
  -- with flat white all round it.  art/crops.lua has documented the other
  -- behaviour all along ("anything smaller zooms in"); the code never did it.
  local function fitScale(portrait, slotW, slotH)
    local w, h = portrait.w or 1, portrait.h or 1
    if not (slotW > 0 and slotH > 0) then return 0 end
    return math.min(slotW / w, slotH / h)
  end

  -- INSET: the art sits in the box's own columns and the text is moved along by
  -- the font wrapper below.
  --
  -- The art is CENTRED in those columns, and it fills them: the slot is 32px and
  -- the art is drawn at the largest fit inside it with no padding of its own
  -- (INSET_PAD 0), so the default 32px crop lands on the slot's first pixel and
  -- on its far edge -- edge to edge, with no margin between the picture and the
  -- column it was given.  The gap to the words is the reserve, not padding: the
  -- box hands the slot four columns and one more kept clear (INSET_GAP_TW), so
  -- the pen is 8px past the slot's own edge whatever the crop is.  It used to
  -- inset the slot by a pixel on each side and draw a 30px crop inside it, which
  -- left a one-pixel band of box around the picture on every side.
  local function drawInset(portrait, side)
    local L, Top, W = boxTiles()
    local T = Display.TILE
    local bx = L * T
    local slotX = (side == "right") and (bx + W * T - SLOT) or bx
    -- Vertically the art is centred against the box the player SEES -- the same
    -- rect FRAMED anchors its panel to -- which at 32px lands it at 120..151,
    -- covering the content rect (120..152) edge to edge with nothing left over.
    -- Centring in the content rect instead would put it at 120 too: the two rects
    -- share a centre at 136, so the choice makes no difference to the answer.  It
    -- is the visible rect because that is the one the layout occupies and the one
    -- FRAMED measures.
    --
    -- The clamp is kept, and it is inert rather than load-bearing now.  At 1.6.0's
    -- 38px it was the whole mechanism: a 38px portrait is taller than the 32px
    -- content rect, so the honest offset was negative and only the clamp stopped
    -- it from starting above the box's own top border.  At 32px the offset is a
    -- real 8, and a crop can only reach the clamp again by being bigger than the
    -- slot it is fitted into -- which fitScale does not allow.
    local boxTop = (Chrome.DLG_TOP - CHROME_UP) * T
    local boxH = (Chrome.DLG_H + CHROME_UP + CHROME_DOWN) * T
    local scale = fitScale(portrait, SLOT - 2 * INSET_PAD, boxH - 2 * INSET_PAD)
    local artW, artH = artSize(portrait, scale)
    blit(portrait,
      slotX + math.max(0, math.floor((SLOT - artW) / 2)),
      boxTop + math.max(0, math.floor((boxH - artH) / 2)), scale,
      portrait.directional and side == "left")
  end

  -- The window a portrait gets, and the whole-number zoom its art is drawn at.
  --
  -- The window is ONE size for everybody -- PANEL_MAX_TW tiles square, with
  -- PANEL_BORDER_TW of that spent on the menu border each side -- because the
  -- border is drawn from tiles and only lines up on the tile grid.  What varies
  -- per portrait is the ART: the largest whole number of times the crop that
  -- still fits the content, centred in it, so a narrow hand-tuned crop is
  -- enlarged rather than left as a speck (art/crops.lua, "anything smaller zooms
  -- in") and the default 32px crop is still drawn 1:1 -- the ART is 1:1 for the
  -- default, not the window, which is what keeps a hand-tuned crop from looking
  -- like a different release from the one beside it.
  --
  -- Everything here is in GAME pixels.  MARGIN multiplies the answer by the
  -- window scale; that is the only difference between the two layouts' windows.
  --
  -- `tiles` is the column budget FRAMED has to reserve, and it is a constant now
  -- rather than a per-portrait sum -- one more consequence of the window being
  -- one size.  MARGIN ignores it, because MARGIN takes nothing from the text.
  local function panelPlan(portrait)
    local T = Display.TILE
    local w = math.max(1, portrait and portrait.w or 1)
    local h = math.max(1, portrait and portrait.h or 1)
    local content = PANEL_CONTENT_TW * T
    local zoom = 1
    while (w * (zoom + 1) <= content) and (h * (zoom + 1) <= content) do
      zoom = zoom + 1
    end
    local aw, ah = w * zoom, h * zoom
    return {
      zoom = zoom,
      w = PANEL_MAX_TW * T, h = PANEL_MAX_TW * T,
      tiles = PANEL_MAX_TW,
      border = PANEL_BORDER_TW * T,
      content = content,
      artW = aw, artH = ah,
      ox = math.floor((content - aw) / 2),
      oy = math.floor((content - ah) / 2),
    }
  end

  -- The columns FRAMED asks the box for: the panel's own run PLUS the clearance
  -- it keeps from the play area's edge, rounded up to whole tiles because
  -- DLG_LEFT and DLG_W are tile counts and a box can only give up whole ones.
  --
  -- ONE function, because TWO places need the same answer: Message.draw, which
  -- hands the columns over, and Message.show, which has to break the words at
  -- the width that leaves.  A wrap told one number and a clip given another is a
  -- box whose last word is cut off -- the bug an earlier release fixed by
  -- passing the count between them, and this keeps that promise while the count
  -- itself became a sum.
  --
  -- The rounding is the reason the clearance is stated as "at least", and the
  -- reason EDGE_PAD is not simply the gap the player sees: the window does not
  -- fill its run, so what a portrait actually gets is `give * T - plan.w`.  At
  -- EDGE_PAD 4 the 48px window buys ceil(52 / 8) = 7 whole tiles and realises 8
  -- -- and it is 8 for every crop now, because the window is one size.  The
  -- number at the top of the file is the FLOOR the buy is chosen to clear, and
  -- the tile is what turns it into the distance on screen.
  local function framedGive(plan)
    local T = Display.TILE
    local w = (plan and plan.w) or (PANEL_MAX_TW * T)
    return math.ceil((EDGE_PAD + w) / T)
  end

  -- FRAMED: the box is drawn short and a window of its own stands in the columns
  -- it gave up.  MARGIN draws the same window out in window space, so `unit` is
  -- the size of one game pixel where it is going: 1 for the in-canvas layouts,
  -- the window scale for MARGIN.
  --
  -- The window is the ENGINE's, not an imitation of it: Chrome.stdFrame is the
  -- same call the start menu's own box and the OPTION page's body are drawn
  -- with, so the portrait wears the game's standard menu frame -- the real
  -- extracted tiles when the install has them, the engine's own flat fallback
  -- when it does not, and the player's own OPTION -> FRAME choice either way.
  --
  -- It is asked in TILE coordinates, which is the only shape it comes in, so the
  -- call is wrapped in a transform: translate to the content rect, scale by the
  -- unit, and ask for a content-sized window at the origin.  stdFrame draws the
  -- border OUTSIDE the rect it is given, so the ring lands exactly on the
  -- panel's outer edge -- which is why the panel's size and the border's width
  -- are the same number read from two ends.
  local function drawFramed(portrait, side, panelX, panelY, panelW, panelH, unit, plan)
    unit = unit or 1
    local border = (plan and plan.border) or (PANEL_BORDER_TW * Display.TILE)
    local contentX = panelX + border * unit
    local contentY = panelY + border * unit
    love.graphics.push()
    love.graphics.translate(contentX, contentY)
    love.graphics.scale(unit, unit)
    Chrome.stdFrame(0, 0, PANEL_CONTENT_TW, PANEL_CONTENT_TW)
    love.graphics.pop()
    -- The art is centred in the content at the plan's whole-number zoom.  The
    -- default 32px crop IS the 32px content, so it leaves nothing to centre and
    -- reaches the border on all four sides; a narrower crop is enlarged and then
    -- centred in what is left.  Either way the border is the separation, not an
    -- outline drawn around the art.
    local zoom = (plan and plan.zoom) or 1
    blit(portrait, contentX + ((plan and plan.ox) or 0) * unit,
      contentY + ((plan and plan.oy) or 0) * unit, zoom * unit,
      portrait.directional and side == "left")
  end

  -- MARGIN draws over the finished frame, in window space, through render.hud.
  -- It is FRAMED's panel moved clear of the box: the same art, the same outline
  -- and the same zoom, sized by panelPlan, on the side the player asked for,
  -- standing MARGIN_BOX_GAP above the dialogue box and MARGIN_PAD in from the
  -- play area's edge -- or out in the letterbox when the window is wider than
  -- the 240x160 frame, in which case it costs the text nothing.
  --
  -- What it used to do, all four of which are one complaint: always the RIGHT
  -- whatever SIDE said; vertically CENTRED in the game frame, which put it half
  -- a screen above a box that lives in the bottom fifth of it; drawn bare, with
  -- no panel behind it; and never mirrored, so a Pokemon on the left faced away
  -- from its own words.
  --
  -- And the fifth, which was the previous release: it was six tiles square
  -- whatever the art was, so a 30px face sat in a 144px panel with 27 window
  -- pixels of FLAT WHITE on every side -- the ring was not a border at all, just
  -- a one-pixel outline scaled up with everything else.  1.8.2 brings the six
  -- tiles back, but as a real window: the ring is the game's own menu border
  -- now, eight pixels of it, so what is left inside is the art and the pixel or
  -- two it does not fill.  A panel that big is also a panel that REACHES: its
  -- top edge landed 150px above the box, which is what "positioned far above the
  -- dialogue box" describes; at 48px it reaches 48, which is the box's own
  -- height.
  --
  -- This release is the clearance, which the sizing exposed rather than caused.
  -- With the panel down at the art's own size it became obvious how LITTLE room
  -- it was keeping: 2 game px above the box and 0 px from the play area's edge,
  -- so on a phone it touched the screen edge and all but touched the box.
  -- 1.9.0 answered with MARGIN_PAD = 2 on both axes and 1.9.1 took it to 4 on
  -- both -- and the 4 was only ever right for the EDGE.  They are two numbers
  -- again now: MARGIN_PAD (the edge, 4) on x and MARGIN_BOX_GAP (the box, 2) on
  -- y, in the branch below.  See the constants at the top of the file for why.
  --
  -- GB pixels -> WINDOW units.
  --
  -- NOT viewport.scale.  That is Renderer:fitScale(): integer FRAMEBUFFER pixels
  -- per GB pixel, while gameX/gameY/gameWidth are LOVE window units -- the two
  -- differ by exactly dpiX, and conf.lua sets t.window.highdpi on mobile only,
  -- so dpiX is 1 on the desktop and 2 or 3 on a phone.  Read as if it were the
  -- window-unit scale it drew the panel dpiX times too large AND dpiX times too
  -- far from the playfield origin: on a 3x phone a 42px panel became 128px and
  -- landed about a hundred pixels below the bottom of the game frame, which is
  -- "the framed portrait sits too far from the dialogue box" exactly.
  --
  -- gameWidth is the playfield in window units, so gameWidth / Display.W is the
  -- scale that matches the origin it is added to, and it tracks the window size
  -- and the integer scale with no renderer access.  This is what the Gen 2 port
  -- has always done (`unit = vp.gameWidth / 160`); the port to Gen 3 lost it.
  local function unitFor(viewport)
    local gw = tonumber(viewport.gameWidth)
    if gw and gw > 0 then return gw / Display.W end
    -- A viewport with no playfield width (an older engine, or a stub): fall back
    -- to the documented scale, divided by the pixel ratio it is expressed in.
    local s = tonumber(viewport.scale) or 0
    if s <= 0 then return 0 end
    return s / (tonumber(viewport.dpiX) or 1)
  end

  -- ------- the rect the frame was ACTUALLY drawn at
  --
  -- MARGIN draws in WINDOW space, so it has to know where the dialogue box is on
  -- the screen -- and the rect render.hud hands it is not always that rect.
  --
  -- The payload is Game3:_drawHud's Display.fit(w, h) (src/core/game3/
  -- display.lua:50).  The frame is drawn by Renderer:endFrame from
  -- Renderer:frameRects(), which fits the picture into Playfield.cutout -- the
  -- TOUCH SKIN's viewport, a FRACTION OF THE WINDOW -- and takes its scale from
  -- BOTH axes of that cutout.  Display.fit instead centres the picture in 48% of
  -- the SAFE AREA and takes its scale from the WIDTH alone.  Those are two
  -- different computations, and .probe/dp3_hudframe_probe.lua measures the gap
  -- between the two box positions at 1.5 to 41 GAME px across realistic phone
  -- layouts -- 0 px on a desktop, where no skin is selected and the cutout is
  -- nil, which is why this never showed up before.
  --
  -- MARGIN is the only layout that can be wrong about this, and that is not a
  -- coincidence: INSET and FRAMED draw inside the canvas, where the box is
  -- wherever Chrome says it is.  MARGIN is the one that has to reproduce the
  -- renderer's own arithmetic from outside, so it asks the renderer.  What it
  -- wants is the UI rect -- uox/uoy/uvpw/uvph, where Renderer:endFrame blits
  -- self.canvas, the surface the dialogue box is drawn into -- and not the world
  -- rect ox/oy, which is the same numbers only while the UI scale equals
  -- fitScale (UI LAYOUT = CENTERED, the default).
  --
  -- docs/modding.md documents the payload as the playfield rect -- "gameX /
  -- gameY ... so a tool can use the letterbox margins without drawing over the
  -- playfield" -- and the Gen 2 notes spell out that it holds because both sides
  -- compute the same number.  On Gen 3 with a skin selected they do not, so this
  -- reads the number the frame was drawn at and treats the payload as the
  -- fallback it is.
  local function frameRect(viewport)
    -- THROUGH require, and that is the whole of this release's first fix.
    --
    -- A mod's environment is src/mods/Sandbox.envFor, and the `package` in it
    -- is LegacyCompat's packageShim -- a decoy table whose `loaded` is a FRESH
    -- EMPTY one (src/mods/LegacyCompat.lua:836).  package.loaded[...] is
    -- therefore nil in the game, while being the engine's real table in the
    -- suite, which compiles main.lua in the ordinary global environment.  So
    -- the lookup below never failed loudly: the guard simply saw nil, took the
    -- silent fallback, and the renderer was never consulted at all -- which is
    -- why 1.8.0's fix changed nothing on screen and why every test still
    -- passed.  .probe/dp3_sandbox_probe.lua measures the two environments side
    -- by side; require is the route the sandbox sanctions, and it answers with
    -- the same singleton the engine calls Renderer:init() and
    -- Renderer:endFrame() on.
    local okR, Renderer = pcall(require, "src.render.Renderer")
    if okR and type(Renderer) == "table"
      and type(Renderer.frameRects) == "function" then
      local ok, r = pcall(Renderer.frameRects, Renderer)
      if ok and type(r) == "table" and (tonumber(r.uvpw) or 0) > 0 then
        return { x = r.uox, y = r.uoy, width = r.uvpw, height = r.uvph,
                 unit = r.uvpw / Display.W }
      end
    end
    local s = unitFor(viewport)
    if s <= 0 then return nil end
    return { x = viewport.gameX, y = viewport.gameY,
             width = viewport.gameWidth, height = viewport.gameHeight, unit = s }
  end


  -- MARGIN's name for the EDGE clearance EDGE_PAD states at the top of the file,
  -- where both layouts can see it.  MARGIN measures it against the PLAY AREA's
  -- own edge and against nothing else: the letterbox branch's
  -- `marginW >= panelW + 2 * pad` spends it on both sides of the margin it
  -- centres in, and the no-letterbox branch's x spends it on the side the
  -- portrait belongs to.  The gap to the BOX is MARGIN_BOX_GAP, a different
  -- number for a different job, and it is spent on the y axis alone.
  --
  -- MARGIN's two axes are built so each invariant holds with no second clamp.
  -- The letterbox branch only takes the letterbox when the margin is at least
  -- panelW + 2 * pad, so the panel it CENTRES there is already pad clear of the
  -- screen edge on the outside and of the play area on the inside -- and it
  -- keeps pad off the BOTTOM of the play area as well, because a panel standing
  -- BESIDE the box has no gap to the box to keep.  The no-letterbox branch is
  -- the one the 2 px requirement is about: it stands the panel directly over
  -- the box, and adds pad explicitly on x and boxGap explicitly on y.
  local MARGIN_PAD = EDGE_PAD          -- game px, from the play area's edge
  local function drawMargin(portrait, side, viewport)
    -- The rect the frame was drawn at, NOT the one render.hud reports -- see
    -- frameRect.  Every number below is measured against this, which is what
    -- makes the clearance below a real distance rather than a nominal one.
    local frame = frameRect(viewport)
    if not frame then return end
    local s = frame.unit
    if s <= 0 then return end
    side = side or "left"
    local T = Display.TILE
    -- THE DEFAULT MEASUREMENT: the panel hugs the art, so its top edge comes
    -- down with the size of the picture instead of standing a fixed 48px above
    -- the box whatever the crop is.  See panelPlan.
    local plan = panelPlan(portrait)
    local panelW = plan.w * s
    local panelH = plan.h * s
    local pad = MARGIN_PAD * s          -- edge clearance: the x axis, both branches
    local boxGap = MARGIN_BOX_GAP * s   -- box clearance: the y axis, over the box

    -- The box's own VISIBLE edges, in window space.  Measured the same way the
    -- panel is, so the two stay aligned however the window is scaled.
    local boxLeft  = frame.x + (Chrome.DLG_LEFT - CHROME_L) * T * s
    local boxRight = frame.x + (Chrome.DLG_LEFT + Chrome.DLG_W + CHROME_R) * T * s
    local boxTop   = frame.y + (Chrome.DLG_TOP - CHROME_UP) * T * s

    -- How much room actually exists outside the play area on that side.
    local marginW = (side == "right")
      and (viewport.width - (frame.x + frame.width))
      or frame.x

    local x, y
    if marginW >= panelW + 2 * pad then
      -- A widescreen letterbox: use it, centred in the margin and BOTTOM-
      -- aligned with the play area, so the panel sits level with the box
      -- instead of floating at the frame's vertical centre.  The clearance
      -- spent here is pad, not boxGap: the panel is BESIDE the box in this
      -- branch, not over it, so there is no panel-to-box gap to keep and what
      -- pad is holding it off is the bottom of the play area itself.
      x = (side == "right")
        and (frame.x + frame.width + (marginW - panelW) / 2)
        or ((marginW - panelW) / 2)
      y = frame.y + frame.height - panelH - pad
    else
      -- No letterbox to use.  Stand directly above the box, MARGIN_PAD in from
      -- the play area's own edge on the side the portrait belongs to, and
      -- MARGIN_BOX_GAP above the box's top.  It used to be flush with that edge,
      -- which on a phone IS the edge of the screen.  The two numbers are not the
      -- same one: the edge clearance is about the device and the box clearance
      -- is about the composition, and 1.9.3 is the release that split them --
      -- hence pad on x and boxGap on y rather than one pad for both.  Never off
      -- the top of the frame -- though with the panel capped at 48px and the box
      -- 112px down, the clamp below cannot fire.
      x = (side == "right") and (boxRight - panelW - pad) or (boxLeft + pad)
      y = boxTop - panelH - boxGap
      if y < frame.y then y = frame.y end
    end

    -- Whole pixels, so the art lands on the device grid.
    x, y = math.floor(x + 0.5), math.floor(y + 0.5)
    drawFramed(portrait, side, x, y, panelW, panelH, s, plan)
  end

  -- ------- install
  --
  -- Sentinel on the module table, not on the function: a Lua function cannot
  -- carry a field, and a table survives a mod reload.
  if Message.dp3_wrapped then
    mod.log:info("already installed; leaving the existing wraps in place")
    return
  end
  Message.dp3_wrapped = true

  local vanillaShow     = Message.show
  local vanillaDraw     = Message.draw
  local vanillaFontDraw = FrlgFont.draw

  -- The box the CURRENT draw belongs to, so the text shift is scoped to the one
  -- box being painted rather than to every string the font renders.  `activePlan`
  -- is panelPlan's answer for that same box: the panel size and the column
  -- budget that go with the portrait, kept rather than recomputed so the draw
  -- cannot disagree with the wrap about how much room the text has.
  local activePortrait, activeSide, activeStyle = nil, "left", "off"
  local activePlan = nil

  -- The width vanilla lays text out in when nothing narrows it: FRLG's own 26
  -- columns.  The wrap guard below is armed against this, so it fires for the
  -- layouts that take columns away and never for a box that keeps them all.
  local VANILLA_TEXT_W = 26 * Display.TILE

  -- Set for the length of one narrowed vanillaShow, so the wrap guard can tell
  -- "the mod narrowed this box" from "this is somebody else's text".
  local pendingWrap = nil

  -- ------- a page must not end on a single word
  --
  -- Narrowing the wrap manufactures a page with one word on it, and the wrap is
  -- greedy: it fills each line as far as it will go and lets the remainder fall
  -- where it may, with no short-line balancing at all
  -- (src/core/game3/scripting/text_ir.lua:276, `wrap_subline`).  At vanilla's
  -- 208 that never shows, because the ROM's own text is authored to two lines of
  -- 26 columns.  At the 176 a portrait costs, it does.  Measured by
  -- .probe/dp3_wrap_probe.lua:
  --
  --   "You need a POKeMON of your own to protect yourself in the tall grass."
  --
  -- at 176 becomes
  --
  --   You need a POKeMON of your own | to protect yourself in the tall  PAGE
  --   grass.
  --
  -- and the whole second page is one word.  On Gen 3 a page break is an A press
  -- (text_ir.lua:382, `onPage >= 2`), so that is a button to advance past a page
  -- the player has already read.  This is a consequence of the narrowing, not an
  -- engine defect at vanilla width -- the same line fits in two at 208 -- which
  -- is why the fix belongs here rather than in the engine.
  --
  -- It is a REFLOW, not a re-wrap: the engine's own line breaks are kept, and
  -- when a page ends on one word the last word of the line before it moves down,
  -- if the two still fit together.  Two properties make that safe to do to text
  -- this mod did not author:
  --
  --   * no word is added, dropped or reordered -- it is the same text;
  --   * the number of lines and the number of page breaks is UNCHANGED, so
  --     nothing about pagination moves.  The engine counts LINES to decide pages,
  --     so a reflow that preserved every word but changed a line count would
  --     repaginate the box; this cannot.
  --
  -- The line it takes from has to keep two words of its own, or the reflow would
  -- only move the orphan up a line and leave a new one behind.
  local function wordsOf(line)
    local out = {}
    for w in line:gmatch("%S+") do out[#out + 1] = w end
    return out
  end

  local function reflowOrphan(text, maxW)
    if type(text) ~= "string" or text == "" then return text end
    if type(maxW) ~= "number" or maxW <= 0 then return text end
    local measure = FrlgFont and FrlgFont.measure
    if type(measure) ~= "function" then return text end

    -- Split into lines, keeping each line's own terminator: "\n" ends a line
    -- inside a page, "\f" ends a page, and the last line has neither.
    local lines, cur = {}, ""
    for i = 1, #text do
      local c = text:sub(i, i)
      if c == "\n" or c == "\f" then
        lines[#lines + 1] = { s = cur, sep = c }
        cur = ""
      else
        cur = cur .. c
      end
    end
    lines[#lines + 1] = { s = cur, sep = "" }

    for i = 1, #lines do
      local endsPage = (lines[i].sep == "\f") or (lines[i].sep == "")
      local orphan = wordsOf(lines[i].s)
      if endsPage and #orphan == 1 and i > 1 then
        local j = i - 1
        while j >= 1 and #wordsOf(lines[j].s) == 0 do j = j - 1 end
        if j >= 1 then
          local donor = wordsOf(lines[j].s)
          if #donor >= 3 then
            local merged = donor[#donor] .. " " .. orphan[1]
            local ok, w = pcall(measure, merged)
            if ok and type(w) == "number" and w <= maxW then
              donor[#donor] = nil
              lines[j].s = table.concat(donor, " ")
              lines[i].s = merged
            end
          end
        end
      end
    end

    local out = {}
    for _, l in ipairs(lines) do out[#out + 1] = l.s .. l.sep end
    return table.concat(out)
  end

  -- The wrap is read as a FIELD at call time -- message.lua holds the module
  -- table and calls TextIR.toTextBox once per box -- so this takes effect even
  -- though it is installed after the mod has loaded.  Contrast FrlgFont.draw,
  -- which vanillaShow captures as an upvalue and which therefore has to be
  -- wrapped before the mod loads (it is, at the top of the install block).
  do
    local ok, TextIR = pcall(require, "src.core.game3.scripting.text_ir")
    if ok and type(TextIR) == "table" and type(TextIR.toTextBox) == "function" then
      local vanillaToTextBox = TextIR.toTextBox
      TextIR.toTextBox = function(ir, ctx)
        local out = vanillaToTextBox(ir, ctx)
        local w = type(ctx) == "table" and tonumber(ctx.maxWidth) or nil
        if pendingWrap and w and w == pendingWrap then
          local fixedOk, fixed = pcall(reflowOrphan, out, w)
          if fixedOk and type(fixed) == "string" then return fixed end
        end
        return out
      end
    else
      mod.log:warn("text_ir not found; a narrowed box may end on a single word")
    end
  end

  -- Message.show is the single funnel every field box goes through (the field
  -- HUD calls it, and so does every script path), so this is where "who is
  -- talking" is decided -- once per box, not once per frame.
  --
  -- The decision is taken AFTER vanillaShow, not before it, because the frame a
  -- box belongs to is only settled once vanillaShow has run: vanillaShow is what
  -- reads opts.frame and writes Message._frame, so Message.frameKind() is the
  -- engine's own answer to "what kind of box is this?" and asking earlier would
  -- read the PREVIOUS box's frame.
  --
  -- A portrait belongs on the field dialogue and nowhere else.  INSET and FRAMED
  -- both draw at the field box's own coordinates (Chrome.DLG_*), so on any other
  -- frame they paint in the wrong place: an evolution and an egg hatch both call
  -- Message.draw() with frame "battle" and neither panel is at Chrome.DLG_*.  The
  -- MARGIN wrapper below has always made this check; the two in-frame layouts now
  -- make it too, so the three agree on what a portrait is for.
  --
  -- Battle text is unaffected either way, and worth saying out loud: the battle
  -- UI draws its own chrome and calls Message.drawText directly
  -- (src/core/game3/battle/ui.lua), so this wrapper never runs for it.
  -- ------- the width the text is laid out in
  --
  -- The one number that has to be right twice, and was only ever right once.
  --
  -- Message.show WRAPS the box's text against `ctx.maxWidth`, defaulting to a
  -- hardcoded 208 -- the vanilla box's own 26 columns
  -- (src/ui/game3/message.lua:148, handed to TextIR.toTextBox at
  -- src/core/game3/scripting/text_ir.lua:335, which word-wraps against it).
  -- Message.drawText then CLIPS each line at `Chrome.DLG_W * Display.TILE`
  -- (src/ui/game3/message.lua:317), which follows the geometry.
  --
  -- Vanilla those two agree, because 208 IS 26 columns.  Every layout here
  -- makes them disagree, and the mod only ever changed the second one: FRAMED
  -- shrank Chrome.DLG_W to 20 columns and drew clipped at 160, while INSET left
  -- the box alone and clipped at 176 from inside the font wrapper.  Either way
  -- the engine wrapped the line for a 208px box and the draw cut its tail off.
  --
  -- That is the "dialogue text is clipped" this release fixes, and it was never
  -- a clipping bug -- it was a wrap that had not been told about the layout.  So
  -- the wrap is now given the layout's own width.  It has to be supplied BEFORE
  -- vanillaShow, because that call is where the wrap happens, which makes this
  -- the one place the frame is read from `opts` rather than from
  -- Message.frameKind().  The two agree by construction: Message.show derives
  -- its frame from exactly these opts and always overwrites it
  -- (src/ui/game3/message.lua:92-106 -- there is no sticky frame to miss).
  --
  -- A narrower wrap can push a page past the two lines the box holds.  On Gen 3
  -- that is the engine's own business and it handles it: TextIR.toTextBox breaks
  -- the overflow onto a new page (text_ir.lua:382, `onPage >= 2`), so the extra
  -- line waits for an A press instead of scrolling the first one away.  The Gen 2
  -- port needed a whole keepPageWaits pass for the same problem, because Gold's
  -- TextBox scrolls a third line rather than paging it; Gen 3 does not.
  local function frameFromOpts(opts)
    if type(opts) ~= "table" then return "dialogue" end
    if opts.frame == "sign" or opts.sign then return "sign" end
    if opts.frame == "braille" then return "braille" end
    if opts.frame == "voiceover" then return "voiceover" end
    if opts.frame == "battle" or opts.battle then return "battle" end
    return "dialogue"
  end

  -- ------- the text colour says whether anybody is speaking
  --
  -- FRLG draws a speaking NPC's text in a colour taken from the person the
  -- script selected: dark blue for a male, dark red for a female, and the plain
  -- BLACK/GREY "normal" colour for everything that is not a person talking --
  -- narration, signs, item and letter boxes, and any box whose speaker the
  -- engine could not identify (src/core/game3/scripting/adapters.lua
  -- resolveNpcColor returns NEUTRAL when the script selected no object).
  --
  -- So the colour is the engine's own answer to "is somebody speaking here?",
  -- and the mod's rule is the reported one: **a box drawn in the black/grey
  -- colour gets no portrait**.  Oak's aide's letter from Mom is the worked
  -- example -- the script sets `textcolor 3` before it (g3:081662de row 51), so
  -- the engine draws it in NORMAL, and that is why it must be bare, quite apart
  -- from the aide having walked off.
  --
  -- The engine hands the answer over in `opts.npcColor` (adapters.lua:417/452
  -- pass it to Hud.openMessage; message.lua:113 turns it into the colour table,
  -- and anything that is not MALE or FEMALE becomes NORMAL).  A box carrying no
  -- npcColor at all is NOT declined: every field box in the game carries one, so
  -- an absent value means a caller outside the field path (a suite, a menu)
  -- rather than a black/grey box.
  local function coloursAllowPortrait(opts)
    if type(opts) ~= "table" then return true end
    local c = opts.npcColor
    if c == nil then return true end
    local ok, FrlgFont = pcall(require, "src.ui.game3.frlg_font")
    if not ok or type(FrlgFont) ~= "table" then return true end
    local neutral = FrlgFont.NPC_TEXT_COLOR and FrlgFont.NPC_TEXT_COLOR.NEUTRAL
    if neutral == nil then neutral = 3 end
    if tonumber(c) ~= neutral then return true end
    -- A person whose box the CART draws in the neutral colour.  The rule above
    -- is right -- a neutral box is narration, a sign or an item box -- but it is
    -- an inference from the colour, and Pewter Museum's scientists are the case
    -- where the inference is wrong.
    --
    -- TWO of the museum's three scientists open with `lock`/`faceplayer` and one
    -- does not: lid 5's script is only `loadword / callstd / end` (g3:0816a49c),
    -- so the engine never SELECTS an object for that box and hands it NEUTRAL,
    -- which is why that one scientist of the three kept no face.  The press is
    -- therefore not enough on its own -- the scene route is consulted too, and
    -- the (map, graphic) pair is the fact that decides, not the route that found
    -- it.  Explicit (map, graphic), not a rule: one map, one graphic, so no
    -- narration or item box anywhere else can be caught by it.
    local function neutralButAPerson()
      local here = NEUTRAL_COLOUR_PORTRAIT[mapIdNow()]
      if not here then return false end
      for _, eo in ipairs({ pressSpeaker, sceneSpeaker() }) do
        if type(eo) == "table" and here[tonumber(eo.graphicsId)] then return true end
      end
      return false
    end
    return neutralButAPerson()
  end

  -- How wide the text is laid out, in pixels, for a given layout.
  --
  -- FRAMED's answer depends on the PORTRAIT, not on a constant: the panel is
  -- sized to the art (see panelPlan) and the box also gives up the clearance
  -- (see framedGive), so the columns it takes are a per-speaker SUM and the text
  -- gets whatever is left.  `give` is that count; it is passed in rather than
  -- looked up so Message.show and Message.draw cannot disagree about it -- they
  -- are two halves of one decision, and a layout where the wrap is told one
  -- width and the clip another is exactly the bug an earlier release fixed.
  --
  -- INSET's is still a constant, and `side` is kept in the signature because it
  -- is the one thing a caller might reasonably expect to matter -- the suite
  -- pins that it does not: SIDE must not change how much text there is.
  local function textWidthFor(style, side, give)
    local T = Display.TILE
    local cols = Chrome.DLG_W
    if style == "framed" then
      cols = cols - (give or PANEL_MAX_TW)
    elseif style == "inset" then
      -- One number for both sides: the art slot plus the column kept clear of
      -- it.  On the right that clear column is where the arrow goes; on the
      -- left it is clearance.
      cols = cols - INSET_RESERVE_TW
    end
    return math.max(1, cols) * T
  end

  Message.show = function(text, opts)
    local style = opt("style", "inset")
    activeStyle, activePortrait, activePlan = style, nil, nil

    -- The speaker of the last box is the speaker only while the script leaves
    -- them where they were.  A script that has walked them away ends the record
    -- HERE, before this box is resolved, so a box that follows a departure --
    -- Oak's aide's letter from Mom -- is bare.  It ends the SCENE route too, not
    -- just the press, because the aide's scene is a coord event with no press.
    -- See speakerLeftTheScene for why the engine raises nothing for this.
    speakerLeftTheScene()

    -- The speaker is resolved before the call as well as after it, and the two
    -- answers do different jobs.  Before: only to size the wrap, because the
    -- wrap happens inside vanillaShow and a layout that narrows the text has to
    -- narrow the wrap in the same breath.  After: the draw, once frameKind() is
    -- the engine's own verdict rather than a reading of opts.
    --
    -- Three gates, and each is the engine's own answer rather than a guess: the
    -- layout is not OFF, the frame is field dialogue, and the text is not drawn
    -- in the black/grey colour (see coloursAllowPortrait).
    local pending, side, width, plan = nil, nil, nil, nil
    local speaker = nil
    if style ~= "off" and frameFromOpts(opts) == "dialogue"
        and coloursAllowPortrait(opts) then
      speaker = speakerFor(text)
      local portrait = speaker and portraitFor(speaker)
      if portrait then
        pending = portrait
        side = sideFor()
        -- The panel is sized to the ART, so FRAMED's column budget is a
        -- property of this portrait and has to be computed before the wrap.
        -- Both halves read the same answer: framedGive(plan) is what the wrap is
        -- told here and what the clip takes the box's columns away by in
        -- Message.draw below, so the two cannot drift apart.
        plan = panelPlan(portrait)
        width = textWidthFor(style, side, framedGive(plan))
      end
    end

    local result
    if width then
      -- Copies, so the caller's own opts and ctx survive untouched -- a script
      -- hands the same table to several boxes, and ctx also carries the
      -- playerName/rivalName the text placeholders expand through.
      local copy = {}
      if type(opts) == "table" then
        for k, v in pairs(opts) do copy[k] = v end
      elseif type(opts) == "function" then
        -- the `done` shorthand vanillaShow accepts
        copy.done = opts
      end
      local ctx = {}
      if type(copy.ctx) == "table" then
        for k, v in pairs(copy.ctx) do ctx[k] = v end
      end
      ctx.maxWidth = width
      copy.ctx = ctx
      -- The wrap runs INSIDE vanillaShow, so the guard below has to be armed
      -- around it rather than after it -- and only for a box this mod actually
      -- narrowed, which is the only place a one-word line comes from.
      local outer = pendingWrap
      pendingWrap = (width < VANILLA_TEXT_W) and width or nil
      local ok, res = pcall(vanillaShow, text, copy)
      pendingWrap = outer
      if not ok then error(res) end
      result = res
    else
      result = vanillaShow(text, opts)
    end

    if pending and Message.frameKind() == "dialogue" then
      activePortrait, activeSide, activePlan = pending, side, plan
      -- This box resolved to an object, so remember where it is standing: the
      -- next box compares against it, and only a move BETWEEN boxes counts as
      -- the speaker leaving (see speakerLeftTheScene).  The object may have come
      -- from the press OR from the scene route -- both are recorded.
      noteSpokeCell(speaker)
    end
    return result
  end

  -- INSET's text shift.  Scoped by the flag the draw wrapper raises around its
  -- own call, so no menu string is ever moved.
  local insetting, insetPx = false, 0
  FrlgFont.draw = function(text, x, y, opts)
    if insetting and insetPx > 0 then
      local copy = {}
      if type(opts) == "table" then
        for k, v in pairs(opts) do copy[k] = v end
      end
      copy.maxWidth = math.max(8, (tonumber(copy.maxWidth) or 0) - insetPx)
      -- LEFT moves the text along; RIGHT leaves it where it is and only takes
      -- the columns away, so the arrow keeps its own column at the end.
      if activeSide == "right" then return vanillaFontDraw(text, x, y, copy) end
      return vanillaFontDraw(text, x + insetPx, y, copy)
    end
    return vanillaFontDraw(text, x, y, opts)
  end

  -- One wrapper, one decision.  FRAMED changes the box's geometry for the
  -- length of the draw and puts it straight back -- the Gen 2 port's "swap the
  -- geometry for one call" trick applied to Chrome's own constants, which
  -- dialogueFrame() and drawText() both read fresh.
  Message.draw = function()
    if not activePortrait then return vanillaDraw() end
    local T = Display.TILE

    if activeStyle == "inset" then
      -- The same run on both sides, so the text is the same width either way and
      -- the art keeps the same clearance from the words (see INSET_GAP_TW).
      insetPx = INSET_RESERVE_TW * T
      insetting = true
      local ok, err = pcall(vanillaDraw)
      insetting, insetPx = false, 0
      if not ok then error(err) end
      drawInset(activePortrait, activeSide)
      return
    end

    if activeStyle == "framed" then
      local plan = activePlan or panelPlan(activePortrait)
      -- The columns the box gives up: the panel's own run PLUS the clearance it
      -- keeps from the play area's edge, rounded to whole tiles.  Asking for
      -- that extra column is what stops the window sitting flush against the
      -- edge of the play area -- which on a phone IS the edge of the screen.
      -- See framedGive, which Message.show's wrap reads too, so the draw and the
      -- wrap cannot disagree about how much text there is.
      local give = framedGive(plan)
      local L0, W0 = Chrome.DLG_LEFT, Chrome.DLG_W
      if activeSide == "right" then
        Chrome.DLG_W = math.max(4, W0 - give)
      else
        Chrome.DLG_LEFT = L0 + give
        Chrome.DLG_W = math.max(4, W0 - give)
      end
      local ok, err = pcall(vanillaDraw)
      Chrome.DLG_LEFT, Chrome.DLG_W = L0, W0
      if not ok then error(err) end
      -- The panel stands in the columns the box gave up -- and "the columns the
      -- box gave up" means the columns the box is VISIBLE in, not the content
      -- rect it declares.  dialogueFrame draws the border CHROME_L columns left
      -- of DLG_LEFT and CHROME_R columns past DLG_LEFT + DLG_W, so the box the
      -- player sees runs from L0 - CHROME_L to L0 + W0 + CHROME_R.
      --
      -- That run is `give` columns now, not `tiles`, and the difference is the
      -- clearance: the box gives up the panel's own run PLUS EDGE_PAD, so the
      -- panel can stand off the play area's edge.  The run is bought in whole
      -- tiles -- a box can only sell columns -- so it is 7 of them for the 48px
      -- window, i.e. 56px, and what the panel does not fill is the slack
      -- `give * T - plan.w` = 8px.
      --
      -- Vertically the panel is centred against the visible box.  It is the SAME
      -- height as that box -- 48px, six tiles, the window's own size -- so the
      -- centring puts it level with the box rather than a little inside it.
      --
      -- 1.9.0: the slack is SPLIT, EDGE_PAD each side, so the panel is centred in
      -- the run the box gave up.  That puts its outer edge exactly EDGE_PAD (4
      -- game px) in from the play area's own edge -- the same number MARGIN keeps
      -- -- and its inner edge exactly EDGE_PAD from the box's VISIBLE edge.  The
      -- gap from the portrait to the nearest letter is then that EDGE_PAD plus
      -- the box's own CHROME_L columns of border, 20px, and it is the same on
      -- both sides.
      --
      -- Until 1.9.0 the whole slack went OUTWARD instead, which left the panel
      -- FLUSH against the box -- a zero-pixel gap, so the panel and the box read
      -- as one merged blob -- and, on the default crop, the run was exactly the
      -- panel's own width, so there was no slack at all and the portrait sat
      -- flush against the play area's edge, which on a phone is the edge of the
      -- screen.  Splitting it is what makes EDGE_PAD -- the floor the header
      -- states -- the gap the player actually sees, on both sides.
      --
      local runX = (activeSide == "right")
        and ((L0 + W0 - give + CHROME_R) * T)
        or ((L0 - CHROME_L) * T)
      local panelX = runX + math.floor((give * T - plan.w) / 2)
      local boxTop = (Chrome.DLG_TOP - CHROME_UP) * T
      local boxH = (Chrome.DLG_H + CHROME_UP + CHROME_DOWN) * T
      drawFramed(activePortrait, activeSide, panelX,
        boxTop + math.floor((boxH - plan.h) / 2), plan.w, plan.h, 1, plan)
      return
    end

    vanillaDraw()
  end

  -- ------- the press
  mod.hooks:wrap("world.talk", function(next, game, eo)
    -- The hook fires only for a press that reached an object with a script, so
    -- recording here is recording a conversation -- not a sign, not a hidden
    -- item, not a menu.
    -- A fresh press starts a FRESH conversation, so the previous record is
    -- dropped outright.  Keeping its cell would compare it against this
    -- object's and read the first box of the new conversation as a departure:
    -- Bill's own script moves him (applymovement 2, g3:08170eb1) before his
    -- "this is my buddy CELIO" line, so a record left on Bill from the last
    -- conversation made that move look like a walk-off and the line came out
    -- bare -- the reported "Bill: 'ASH, this is my buddy CELIO' has no
    -- portrait".
    forgetSpeaker()
    pressSpeaker = eo

    -- ------- the Pewter City Nidoran's own line
    --
    -- PewterCity_House1 obj 3 is the Nidoran the woman tells to sit (graphic
    -- 123).  Its object script g3:0816a736 is
    -- `lock / faceplayer / call / applymovement / waitmovement / release` and it
    -- opens NO box at all, so pressing it only walked it about -- there was
    -- nothing to read.  A mod cannot put a message into the cart's own script,
    -- so this hook is the only seam that sees the press, and it is the line the
    -- report asked for.
    --
    -- AFTER `pressSpeaker = eo`, not before, and that is the whole point: the
    -- box's speaker is resolved from that record, and a Nidoran's face comes
    -- from its SPECIES, so showing the box before the record was set gave a line
    -- with no portrait -- the first report of this line.  It is (map, graphic),
    -- not "any Nidoran": FourIsland wears the same graphic twice, once as a
    -- stuffed doll, and neither of those is this one.
    if type(eo) == "table" and tonumber(eo.graphicsId) == 123
        and mapIdNow() == "FR_PEWTER_CITY_HOUSE1" then
      Message.show("NIDORAN\u{2642}: Bowbow !")
    end

    return next(game, eo)
  end)

  -- ------- the trainer who challenges you
  --
  -- A trainer's own dialogue does not always begin with an A press.  FRLG's
  -- line-of-sight trainers SEE the player and start their script from a step
  -- (src/core/game3/trainer_sight.lua: TrainerSight.engage), and that path
  -- raises no world.talk: no press is in flight, pressSpeaker is nil, speakerFor
  -- has nothing to answer with, and the "wants to battle" box -- the very box
  -- the report names -- came out bare.
  --
  -- The engine already names the object for exactly this case.  engage() emits
  -- world.trainer_engaged with the trainer's own event object, so recording here
  -- is the same act as recording the press, and every existing way of ending a
  -- conversation drops it again (a step, a map change, the script finishing).
  --
  -- The class rides along as a fallback for an object whose own trainerType has
  -- not been stamped yet, and it is put in a shallow COPY rather than written
  -- onto the engine's object -- a mod must not scribble on the world.
  mod.events:on("world.trainer_engaged", function(payload)
    if type(payload) ~= "table" then return end
    local npc = payload.npc
    if type(npc) ~= "table" then return end
    -- The engine hands the id over directly -- trainer_sight.lua:258 emits
    -- `trainerId = tid` -- and it is the one fact that names this man, so it is
    -- taken rather than re-derived.  The shallow copy exists for the class the
    -- payload carries as a fallback for an object whose own trainerType has not
    -- been stamped, and it has to carry EVERY field speakerFor reads: an earlier
    -- shape dropped scriptKey here, which silently turned a line-of-sight
    -- trainer into whoever his graphic happened to look like.
    if payload.trainerId ~= nil or npc.trainerType == nil then
      npc = { sprite = npc.sprite, def = npc.def, graphicsId = npc.graphicsId,
              scriptKey = npc.scriptKey,
              trainerId = payload.trainerId or npc.trainerId,
              trainerType = npc.trainerType or payload.trainerClass }
    end
    forgetSpeaker()
    pressSpeaker = npc
  end)

  -- Every way a conversation ends.  A step and a warp both leave the object
  -- behind, and a box arriving afterwards must be bare.
  --
  -- A step is not the only way out.  Turning on the spot does not move the
  -- player, so it raises no world.stepped: Player.tryMove sets the facing and
  -- returns "turned" without ever reaching finishStep, which is the one place
  -- world.stepped is emitted (src/core/game3/player.lua:653, called only at
  -- :799).  A player who talked to somebody and then turned to read the sign
  -- beside them would therefore still have the last speaker on record.  Reading
  -- a sign is frame "sign" and now draws nothing whatever the record says (see
  -- Message.show above) -- but the record has to end on its own terms too, or
  -- the next plain box wears it.
  --
  -- The engine's own end-of-conversation seam is script.ended.  The press starts
  -- a script run, and that run finishing IS the conversation being over.  Only
  -- completed == true counts: a script that hands off to another script retires
  -- itself first with completed = false (src/core/game3/scripting/vm.lua:95,
  -- where Vm:start ends the script it supersedes), and that is the same
  -- conversation continuing -- clearing there would drop the portrait from the
  -- boxes the second half shows.
  -- A step ends the conversation only when it is the PLAYER'S OWN.  FRLG walks
  -- the player around inside a script -- `applymovement 0xFF` is how a cutscene
  -- turns the player to face the speaker, or walks them into a scene -- and
  -- that goes through Player.scriptStep -> Player.finishStep, which is the same
  -- place a real step emits world.stepped (src/core/game3/player.lua:653).  So
  -- the event fires mid-conversation, and dropping the record there cost the
  -- portrait on every box after it: the reported "some dialogue boxes lose the
  -- portrait partway through".  Oak's aide is the worked example -- the
  -- `applymovement 255` branches at g3:081663da / :081663e6 / :081663fc run
  -- between the first box and the rest of his speech.
  --
  -- While a script is running, the step is the scene's, not the player's, and
  -- the record stands.  The script's own end still clears it (script.ended
  -- below), so nothing outlives the conversation.  This is the guard the Gen 2
  -- port has carried since 1.3.3 (`if not scriptRunning(gameRef) then
  -- forgetSpeaker() end`).
  mod.events:on("world.stepped", function()
    if not scriptRunning() then forgetSpeaker() end
  end)
  mod.events:on("map.entered", forgetSpeaker)
  mod.events:on("script.ended", function(payload)
    if type(payload) == "table" and payload.completed == false then return end
    forgetSpeaker()
  end)

  -- ------- MARGIN
  mod.hooks:wrap("render.hud", function(next, game, viewport)
    next(game, viewport)
    if activeStyle ~= "margin" then return end
    if not activePortrait or not Message.isOpen() then return end
    if Message.frameKind() ~= "dialogue" then return end
    -- The side rides with the portrait rather than being re-read here: it was
    -- resolved once, against the facing the player had when the box opened, and
    -- this hook runs every frame afterwards.
    local ok, err = pcall(drawMargin, activePortrait, activeSide or "left", viewport)
    if not ok then mod.log:warn("margin draw failed: %s", tostring(err)) end
  end)

  -- ------- the way in: a DIALOGUE PORTRAITS group in FireRed's own OPTION menu
  --
  -- Gen 1 reaches the mod manager from a MODS row in its options menu
  -- (src/ui/OptionsMenu.lua) and Gen 2 from a mods entry in its start menu
  -- (src/core/Game2.lua).  A FireRed boot has neither, and it also has no route
  -- to ManagerState at all: src/core/Game3.lua and everything under
  -- src/ui/game3/ mention ManagerState zero times.  Two earlier attempts used
  -- the start menu's ui.start_menu.items hook to add a MODS row -- and that is
  -- exactly the wrong door on this generation, because ManagerState renders
  -- with Gen 1 primitives (src.render.Font, src.ui.OptionRows, src.ui.Theme)
  -- and FireRed's extracted latin_normal font has no glyphs for them: opening
  -- it paints a blank screen ("font: no glyph for M/O/D/S ...") and the mod's
  -- settings are visible to nobody.
  --
  -- So this mod does not push a second, foreign menu.  It puts its settings into
  -- the menu FireRed already has, drawn by FireRed's own chrome and font.  The
  -- seam is src/ui/game3/option_rows.lua: option_menu.lua calls
  -- `Rows.build(ctx)` and then groups the rows through `Rows.group`, which turns
  -- any id listed in `Rows.GROUPS` into a group row whose own `activate` opens a
  -- sub-page of its members, in the order `Rows.ORDER` names them.  Wrapping
  -- `Rows.build` to append two rows and registering one group is the whole fix;
  -- the entry is named DIALOGUE PORTRAITS and lives in OPTION, where the player
  -- already looks.
  local OptionRows = require("src.ui.game3.option_rows")

  local MOD_BLOCK = "dialoguePortraits"
  local PORTRAIT_LABEL = { inset = "INSET", framed = "FRAMED",
                           margin = "MARGIN", off = "OFF" }
  local SIDE_LABEL = { auto = "AUTO", left = "LEFT", right = "RIGHT" }
  local PORTRAIT_VALUES = { "inset", "framed", "margin", "off" }
  local SIDE_VALUES = { "auto", "left", "right" }

  local function modId()
    return mod.id or (mod.manifest and mod.manifest.id) or "gen3-dialogue-portraits"
  end

  local function gameOf(ctx)
    local g = ctx and ctx.game
    if g then return g end
    local ok, Runtime = pcall(require, "src.core.game3.runtime")
    return ok and Runtime and Runtime._game or nil
  end

  -- The values are stored in the engine's own options tree, under
  -- options.modOptions[<mod id>] -- the exact place Loader:_loadState reads a
  -- mod's persisted options back from, and SaveData.saveOptions writes on a
  -- whole-file rewrite.  The engine option menu already calls g:writeOptions()
  -- after a step, so persisting is the menu's own job and nothing extra is
  -- needed.  The loader's live copy is mirrored too, so mod.options:get --
  -- which is what opt() reads at draw time -- sees the change at once rather
  -- than after the next boot.
  local function optionsBucket(ctx)
    local o = ctx and ctx.options
    if type(o) ~= "table" then return nil end
    if type(o.modOptions) ~= "table" then o.modOptions = {} end
    local id = modId()
    local b = o.modOptions[id]
    if type(b) ~= "table" then
      b = {}
      o.modOptions[id] = b
    end
    return b
  end

  local function readChoice(ctx, key, values, fallback)
    local b = optionsBucket(ctx)
    local v = b and b[key]
    if type(v) == "string" then
      for _, candidate in ipairs(values) do
        if candidate == v then return v end
      end
    end
    -- No stored value yet: answer the schema default, which is exactly what the
    -- mod itself would draw with, so the row never lies about the live setting.
    local ok, got = pcall(function() return mod.options:get(key) end)
    if ok and type(got) == "string" then return got end
    return fallback
  end

  local function writeChoice(ctx, key, value)
    local b = optionsBucket(ctx)
    if b then b[key] = value end
    local loader = gameOf(ctx) and gameOf(ctx).mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      local id = modId()
      loader.modOptions[id] = loader.modOptions[id] or {}
      loader.modOptions[id][key] = value
    end
  end

  local function cycleChoice(values, value, dir)
    local at = 1
    for i, v in ipairs(values) do
      if v == value then at = i break end
    end
    at = at + ((dir and dir < 0) and -1 or 1)
    if at < 1 then at = #values end
    if at > #values then at = 1 end
    return values[at]
  end

  local function optionRow(id, label, key, values, labels, default)
    return {
      id = id,
      label = label,
      value = function(ctx)
        local v = readChoice(ctx, key, values, default)
        return labels[v] or labels[default]
      end,
      step = function(ctx, dir)
        writeChoice(ctx, key,
          cycleChoice(values, readChoice(ctx, key, values, default), dir))
        return true
      end,
    }
  end

  local function portraitRow()
    return optionRow("dp3portrait", "PORTRAIT", "style", PORTRAIT_VALUES,
      PORTRAIT_LABEL, "inset")
  end

  local function sideRow()
    return optionRow("dp3side", "SIDE", "side", SIDE_VALUES,
      SIDE_LABEL, "auto")
  end

  -- Register the group once.  A mod reload re-runs this file, so both the group
  -- list and the order list are guarded against a second copy.
  local GROUP_ID = "group.dialoguePortraits"
  local function registerGroup()
    local found = false
    for _, g in ipairs(OptionRows.GROUPS) do
      if g.id == GROUP_ID then found = true break end
    end
    if not found then
      OptionRows.GROUPS[#OptionRows.GROUPS + 1] = {
        id = GROUP_ID,
        label = "DIALOGUE PORTRAITS",
        members = { "dp3portrait", "dp3side" },
      }
    end
    local inOrder = false
    for _, id in ipairs(OptionRows.ORDER) do
      if id == GROUP_ID then inOrder = true break end
    end
    if not inOrder then
      OptionRows.ORDER[#OptionRows.ORDER + 1] = GROUP_ID
    end
  end

  -- Is this mod's body actually loaded in the game being played?  A mod that is
  -- disabled never runs its entry chunk, so its exports are absent and the
  -- option menu must stay exactly stock.  The wrap below is a plain function
  -- replacement (the option menu raises no hook for its rows), so it cannot be
  -- rolled back the way a hook can -- asking the loader instead is what keeps
  -- the rows out of a boot where this mod is off, and what lets the suite prove
  -- the door closes when the mod is released.
  local function modLoaded(ctx)
    local loader = gameOf(ctx) and gameOf(ctx).mods
    return type(loader) == "table" and type(loader.exports) == "table"
      and loader.exports[modId()] ~= nil
  end

  local vanillaBuild = OptionRows.build
  local function installOptionRows()
    registerGroup()
    if OptionRows.dp3_build_wrapped then return end
    OptionRows.dp3_build_wrapped = true
    OptionRows.build = function(ctx)
      local rows = vanillaBuild(ctx)
      if type(rows) ~= "table" then rows = {} end
      if not modLoaded(ctx) then return rows end
      -- Keep the vanilla list intact and append ours.  The two ids are owned by
      -- the group above, so Rows.group folds them into the DIALOGUE PORTRAITS
      -- row instead of listing them beside it.
      local function already(id)
        for _, row in ipairs(rows) do
          if type(row) == "table" and row.id == id then return true end
        end
        return false
      end
      if not already("dp3portrait") then rows[#rows + 1] = portraitRow() end
      if not already("dp3side") then rows[#rows + 1] = sideRow() end
      return rows
    end
  end

  installOptionRows()

  -- ------- what the tests drive
  mod.exports.artFor = artFor
  mod.exports.speakerFor = speakerFor
  mod.exports.rectFor = rectFor
  mod.exports.speciesOfSprite = speciesOfSprite
  -- The same question asked of the cart's own graphics id, which is the only
  -- fact that names a Pokemon standing in the world.  Exported so the suite and
  -- the chain snapshot can pin every id 109-150 to its species.
  mod.exports.speciesOfGfx = speciesOfGfx
  mod.exports.GFX_MON = GFX_MON
  mod.exports.RIVAL_ART = RIVAL_ART
  -- The crop table's own key for a species -- the engine's keyName, not the
  -- cart's display name.  Exported because it is the one thing that makes a
  -- per-Pokemon override reachable for the four species the cart spells with a
  -- sign, a quote or a space.
  mod.exports.speciesKey = speciesKey
  mod.exports.rivalName = rivalName
  mod.exports.isRivalName = isRivalName
  mod.exports.classIdForName = classIdForName
  mod.exports.classNameFor = classNameFor
  mod.exports.picForClass = picForClass
  mod.exports.picForName = picForName
  mod.exports.picArt = picArt
  mod.exports.plainText = plainText
  mod.exports.nameFromText = nameFromText
  mod.exports.forgetSpeaker = forgetSpeaker
  mod.exports.crops = CROPS
  -- The script route's two halves, so the suite can assert the table against the
  -- pack rather than against itself: `scriptTrainerIds` is key -> trainer id and
  -- `picForId` is trainer id -> picture, and a test that only checked
  -- artFor would pass on a table whose every entry was wrong.
  mod.exports.scriptTrainerIds = TRAINER_IDS
  mod.exports.picForId = picForId
  -- The location route's table and the accessor that feeds it, so the suite can
  -- assert both halves of it: that a graphic resolves PER MAP (which is the
  -- whole point, and a test that only read artFor would pass on a table whose
  -- every map held the same value), and that `speakerFor` really stamps the map
  -- it was standing on when the box was drawn.
  mod.exports.MAP_ART = MAP_ART
  mod.exports.PLACE_ART = PLACE_ART
  mod.exports.mapIdNow = mapIdNow
  -- The cart's Fame Checker portraits, exported so the suite can assert the
  -- three names the reporter asks for map to the engine's own person indices
  -- (Bill 13, Daisy 1, Mr. Fuji 14) and to no picture a class could collide
  -- with, rather than only that artFor happens to return something.
  mod.exports.FAME_NAME = FAME_NAME
  mod.exports.FAME_PERSON = FAME_PERSON
  mod.exports.FAME_PIC = FAME_PIC
  mod.exports.FAME_GFX = FAME_GFX
  mod.exports.FAME_SPRITE = FAME_SPRITE
  mod.exports.fameArt = fameArt
  mod.exports.fameSpeakerKey = fameSpeakerKey
  -- The NPC-started scene route, so the suite can prove it reads the actor out
  -- of the running script rather than that it merely did not crash.
  mod.exports.sceneSpeaker = sceneSpeaker
  mod.exports.portraitFor = portraitFor
  mod.exports.INSET_ART = INSET_ART
  mod.exports.SLOT = SLOT
  mod.exports.SLOT_TW = SLOT_TW
  -- The window is one size for everybody, so these three ARE the answer the
  -- suite asserts against: the outer size, the border spent on each side, and
  -- the content the art has to fit -- which is also the ceiling the zoom loop
  -- fits under.
  mod.exports.PANEL_MAX_TW = PANEL_MAX_TW
  mod.exports.PANEL_BORDER_TW = PANEL_BORDER_TW
  mod.exports.PANEL_CONTENT_TW = PANEL_CONTENT_TW
  -- The geometry the layouts are anchored to, exported so the suite can assert
  -- the panel is centred in the run the box gave up -- and that the run is
  -- measured against the box's VISIBLE rectangle, not the content rect DLG_*
  -- describes.
  mod.exports.ARROW_TW = ARROW_TW
  mod.exports.INSET_GAP_TW = INSET_GAP_TW
  mod.exports.INSET_RESERVE_TW = INSET_RESERVE_TW
  -- Exported because it is the one number MARGIN gets from the ENGINE rather
  -- than from its own constants, and getting it wrong is invisible on a desktop
  -- (dpiX is 1 there) while it puts the panel outside the game frame on a phone.
  -- frameRect is the same job done against the rect the frame was DRAWN at; both
  -- are exported so the suite can pin the difference between the two.
  mod.exports.unitFor = unitFor
  mod.exports.frameRect = frameRect
  mod.exports.CHROME_L = CHROME_L
  mod.exports.CHROME_R = CHROME_R
  mod.exports.CHROME_UP = CHROME_UP
  mod.exports.CHROME_DOWN = CHROME_DOWN
  mod.exports.panelPlan = panelPlan
  -- Exported because it is now the SUM the box gives up -- the panel's run plus
  -- the clearance -- and both halves of FRAMED read it, so the suite has to be
  -- able to derive the column cost rather than read `plan.tiles` and be wrong
  -- about the text width by exactly one column.
  mod.exports.framedGive = framedGive
  mod.exports.reflowOrphan = reflowOrphan
  mod.exports.INSET_PAD = INSET_PAD
  mod.exports.EDGE_PAD = EDGE_PAD
  mod.exports.MARGIN_PAD = MARGIN_PAD
  -- MARGIN's other half, and the one the suite has to compare against a literal:
  -- the panel-to-box gap is the whole of the first requirement and it is 2, not
  -- MARGIN_PAD, so a test that only ever checks the code against its own
  -- constant would stay green through exactly the regression this release is
  -- fixing.  See the MARGIN block of dp3_geometry_test.
  mod.exports.MARGIN_BOX_GAP = MARGIN_BOX_GAP
  mod.exports.textWidthFor = textWidthFor
  mod.exports.frameFromOpts = frameFromOpts
  mod.exports.SPRITE_ART = SPRITE_ART
  mod.exports.NAME_ART = NAME_ART
  -- The cart's own graphics-id table, exported for the same reason the two
  -- above are: the suite asserts what the data SAYS (a gym leader is pinned by
  -- his graphic, a graphic the cart never drew is a deliberate `false`) rather
  -- than only what the resolver does with it.
  mod.exports.GFX_ART = GFX_ART
  mod.exports.GROUP_ID = GROUP_ID
  mod.exports.optionRows = OptionRows
  mod.exports.portraitRow = portraitRow
  mod.exports.sideRow = sideRow
  mod.exports.readChoice = readChoice
  mod.exports.writeChoice = writeChoice
  mod.exports.cycleChoice = cycleChoice

  mod.log:info("dialogue portraits (gen 3) installed")
end
