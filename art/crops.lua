-- Portrait crop rectangles -- Pokemon FireRed / LeafGreen (Gen 3)
--
-- This mod ships no art.  Every portrait is cut, at runtime, out of the battle
-- art the ENGINE extracted from the player's own ROM:
--
--   trainers  the 64x64 trainer class front pic
--   pokemon   the 64x64 species front pic
--
-- The mod does not name those files itself -- it asks the engine for the
-- picture (TrainerPic.front for a trainer, Pokemon.frontPic for a species) and
-- uses the picture's own id, or the species key, to look up the rectangle
-- below.  What lives here is the only part that was ever this mod's own work:
-- WHERE to cut.  One rectangle per portrait, as three integers.
--
--   ["38"] = { x, y, size }      -- trainers, keyed by the FRONT-PIC id
--   ["pikachu"] = { x, y, size } -- pokemon, keyed by the species key, lowercased
--
-- x/y are the top-left corner in SOURCE pixels, size is the side of a square
-- window, and that window is scaled into the box's art slot (32px) by
-- nearest-neighbour, so a size of 32 is 1:1 and anything smaller zooms in.
-- The window is clamped into the source, so a rect that runs off its sprite
-- degrades to the nearest legal crop instead of throwing.
--
-- Note the trainer key is the front-pic id, NOT the trainer class.  Gen 3 keeps
-- those in two different number spaces -- class 81 is RIVAL and its picture is
-- 106 -- and the rectangle frames the PICTURE, so the picture's id is the key.
-- Two characters who share a class but are drawn differently (Brock and Misty
-- are both class 84, pictures 116 and 117) therefore do not collide, and two
-- characters who share a picture correctly share a rectangle.
--
-- The pic id is what the mod's own `picForClass` / `picForName` resolve to; to
-- find the one you want, talk to the character with the mod's `debug` log on,
-- or read it straight off the cart's trainer table (record offset +3).
--
-- ------- 1.9.0: 32px, so the portrait fills its frame edge to edge
--
-- 1.8.3's defaults were 30 for a window that is 32: the panel's content rect
-- and INSET's slot are both 32px (four tiles) and the layouts CENTRED the art
-- in them, so every portrait shipped with a one-pixel white margin all the way
-- round -- the "margin between the portrait and its surrounding frame".  Both
-- defaults are 32 now, and the layouts centre them at 1:1, so the art reaches
-- the frame on all four sides with nothing resampled.
--
-- The growth is one pixel on EVERY side, not a new framing: each new default
-- has the same centre as the 30px window it replaces --
--
--   trainers   (17, 4, 30) -> (16, 3, 32)   centre (32, 19) either way
--   pokemon    (17, 18, 30) -> (16, 17, 32) centre (32, 33) either way
--
-- -- so a portrait that was framed correctly in 1.8.3 is framed identically
-- now, one pixel larger on each side.  Nothing else about the default moved.
--
-- The window is a constant size whatever the crop, so a 32px crop still costs
-- the dialogue box exactly the seven columns a 30px one did.
--
-- ------- 1.9.1: three pictures the mod had never routed to before
--
-- 1.9.1 corrects the NPC mappings (main.lua's GFX_ART), and three of the
-- pictures it newly routes to were not framed well enough to ship without an
-- entry: the male Tuber (7, 20% at the default), the old woman (35, 21%) and
-- the Camper (86, 37%).  All three are measured by `.probe/dp3_crop_review.lua`
-- and LOOKED at through the proposed rectangle before being written down, which
-- is the same standard every other entry in this table met.
--
-- It is worth saying plainly, because the two reports sound alike: a mapping
-- that is missing and a WINDOW aimed at empty space look identical on screen --
-- an empty frame.  That is what 1.9.1's Fisherman was.  The NPC resolved to
-- picture 38, whose default window is 17% artwork -- the sparsest of all 148
-- trainer pictures -- so "the fisherman has no portrait" was a crop and not a
-- mapping.
--
-- ------- 1.9.2: the same Fisherman, one layer further down
--
-- 1.9.2 corrects WHICH CLASS a duplicated class name means (main.lua's
-- `classIdForName`), and the Fisherman is the case that shows why both layers
-- had to be fixed.  1.9.1 framed picture 38 correctly -- and 38 is the HOENN
-- fisherman, which is the wrong person.
--
-- The cart spells "FISHERMAN" twice: class 31, the Hoenn fisherman, whose
-- picture is 38, and class 69, the Kanto one, whose picture is 94.  The old
-- tie-break took the LOWER id, so it meant class 31 -- and every ordinary
-- fisherman in Kanto, the ones who carry no class of their own and are named by
-- their sprite, wore a face from Ruby and Sapphire.  With the tie-break
-- corrected they wear picture 94, whose default frames it at 58% with the head
-- inside, and 1.9.1's entry for 38 is gone because nothing reaches it now.
--
-- That is the whole release in one picture, and it was never only the Fisherman:
-- the cart lists 31 of its class names twice, Hoenn first and Kanto second, and
-- the old rule picked the Hoenn half for every one of them.  The girl on Route 3
-- wore the Hoenn Lass, and the Beauty, the Black Belt, the Gentleman and the
-- Sailor each wore their Hoenn counterpart.
--
-- ------- the two rules, and the entries that override them
--
-- FRLG's front pics are 64x64 and framed as a bust: the head sits high in the
-- frame and roughly centred, which is why the trainer default is a window
-- centred a little above the middle rather than on the sprite's geometric
-- centre.  That rule is RIGHT for a centred bust and WRONG for a pose whose
-- content starts unusually high or low, or whose topmost blob is a prop rather
-- than the head -- a held rod, a raised arm, a wing.  The Gen 1 and Gen 2
-- originals of this mod answer that with a hand-tuned rectangle for every class
-- and every species, arrived at by rendering the crops in a grid and LOOKING at
-- them; the rectangles cannot be derived, and a cleverer rule was tried and
-- abandoned there because it broke as many as it fixed.  This port ships the
-- rule plus the entries the measurements name, and every entry below says
-- which measurement put it there.
--
--   TRAINER entries are centred on the HEAD: the topmost blob, taken as the
--   union of the widest opaque run on each of the first 18 rows, with the
--   window's top three rows above the artwork's own first row.
--
--       x = round(head centre) - 16      y = first opaque row - 3   (clamped)
--
--   SPECIES entries are centred on the WHOLE CREATURE: there is no prop to
--   confuse a bounding box, and a creature's silhouette starts at its ears or
--   wings, so the body's own box is the honest reading.
--
--       x = floor(box centre) - 16       y = first opaque row - 4   (clamped)
--
--   The species rule holds for most creatures and fails for the ones whose box
--   is not their head: a sleeping Snorlax is a body with a head tucked into one
--   end, a Slowpoke's topmost blob is its TAIL, and a legendary bird's box is
--   mostly WING.  1.9.2 added four of those, and each is centred on its FACE
--   instead, with the measurement in its own comment.  The box is a rule of
--   thumb, not a fact about where the face is.
--
-- The one-row difference in headroom is deliberate: a bust's head is the
-- tallest thing in its frame, while a creature's top row is usually the tip of
-- something thin.
--
-- And the rule is checked with a CUT COUNT, not only a fill percentage:
-- `.probe/dp3_window_cut.py` reports how many opaque pixels of the sprite fall
-- outside the window on each side, which is "the head sticks out of the frame"
-- as a number.  Two entries this release would have been wrong without it --
-- the Sailor's densest window chops 95 pixels off his cap, and the Black Belt's
-- chopping 369 off his head -- and both look plausible as a percentage.
--
-- ------- why every entry is where it is
--
-- An entry is filed when the DEFAULT window is either mostly empty or plainly
-- mis-aimed.  Measured off the cart's own art, an NPC- or trainer-facing
-- picture qualifies when the default window leaves more than four rows of empty
-- space above the artwork AND holds less than about 42% artwork -- the "large
-- amounts of white space" of the report -- or when the head extends more than
-- two pixels outside the window.  Two probes do the measuring and one does the
-- LOOKING, because a fill percentage says a window is dense, not that it has a
-- face in it:
--
--   * `.probe/dp3_crop_review.lua` -- the bounding box, the head blob, the
--     default's fill and the two rules' own answers, for every picture;
--   * `.probe/dp3_best_crop.lua`   -- the window holding the most artwork;
--   * `.probe/dp3_crop_see.lua`    -- the window rendered at 1:1, for the eye.
--   * `.probe/dp3_crop_audit.lua`  -- where the head is and where the old
--     default cut it.
--
-- Where the head and the densest window disagree the HEAD wins: a portrait is a
-- face, so a window holding 80% of a seated Fisherman and none of his face is a
-- worse portrait than one holding 46% and all of it.
--
-- To add one: render the source sprite with `.probe/dp3_crop_see.lua`, note the
-- window that frames the face, and put it in the matching table.  `pokemon` is
-- keyed by the engine's own species key lowercased -- which is NOT always the
-- same as the display name: NIDORAN_F is "nidoranf", HO_OH is "hooh", MR_MIME
-- is "mrmime".  The mod folds the display name through `Pokemon.keyName` before
-- looking it up (see main.lua's `speciesKey`), so the cart's "NIDORAN(F)" and
-- "MR. MIME" find these keys; `.probe/dp3_species_key.lua` prints the folding
-- for all 23 spellings the cart uses.
--
-- ------- two key spaces, and how to choose between them
--
-- `trainers` and `pokemon` are keyed by the PICTURE.  `speakers` is keyed by
-- the PERSON (or the creature) doing the talking.  Both are consulted, and the
-- speaker wins, because it is the more specific fact.
--
-- Reach for the PICTURE key when the ARTWORK is what is wrong.  That is every
-- trainer entry this release ships, and the reason is that a picture is shared:
-- the same face is worn by an NPC and by fifteen battle trainers, and all
-- sixteen should be framed the same way, because it is the same picture.  The
-- Black Belt above is the worked example -- picture 105, reached by graphics id
-- 54 and by class 80, framed once for both.
--
-- Reach for a SPEAKER key when two speakers share one picture and only ONE of
-- them is framed badly -- the case a picture key cannot express, and the whole
-- reason `speakers` exists.  Its keys are the identities the mod already
-- resolves a speaker by, most specific first:
--
--   ["name:OAK"]             the name the dialogue used, or a trainer's own name
--   ["gfx:57"]               the cart's own FRLG OBJ_EVENT_GFX_* id
--   ["sprite:SPRITE_FISHER"] the host overworld sprite id
--   ["class:31"]             the trainer class
--
-- There is deliberately no `species:` key.  A Pokemon's species key IS its
-- identity, so the `pokemon` table was always keyed by the speaker; it is the
-- NPC side that had no such key, because an ordinary NPC carries no class, no
-- species and often no name -- its sprite and its graphics id are all it has.
-- Nothing needs one yet: every badly-framed picture this release found is worn
-- by one KIND of person, so the picture key says the same thing and catches
-- more routes (the class route AND the graphics-id route AND the sprite route).
-- The table is empty rather than deleted because that is the fact, and the
-- mechanism is covered by the suite with temporary entries.
--
-- ------- 1.9.4: a third key space, for the pictures that hold two people
--
-- There is one case neither of the above can express, and it is not a framing
-- case at all.  Five of the cart's front pics draw TWO people into one 64x64
-- picture -- the Twins, the Cool Couple, the Young Couple, the Crush Kin, Sis
-- and Bro -- and both members of such a pair wear the SAME picture, so:
--
--   * a picture key cannot separate them: `trainers["129"]` is one rectangle
--     and both halves are cut with it;
--   * a speaker key cannot separate them either, because the two halves share
--     every identity the mod can see -- same picture, same class, and (for the
--     Twins) the same graphics id.  The Young Couple is the one pair whose two
--     halves wear DIFFERENT graphics, and even there a `gfx:29` crop would also
--     catch every ordinary Beauty, who wears picture 98 and is half of nothing.
--
-- So a pair picture is described by two tables instead: `pairs` holds one
-- rectangle per half, keyed by the picture id, and `pairSide` says which half a
-- given graphics id stands on.  Both are consulted only when the picture that
-- was resolved IS a pair, which is what keeps gfx 29 -- a Beauty, and also the
-- woman in a Young Couple -- from being cut with the wrong half.
--
-- The resolution order in main.lua is therefore:
--
--   pairs (picture is a pair, and the speaker's graphic names a half)
--   > speakers (name:, gfx:, sprite:, class:)
--   > trainers / pokemon (the picture)
--   > defaults
--
-- and `pairs` is first because it is the only one of the four that is a
-- statement about a PERSON inside a picture rather than about the picture.

return {
  -- The framing rule, applied to every portrait that has no entry of its own.
  -- Both sources are 64x64, so both defaults are 32-wide windows that FILL the
  -- 32px slot/panel content exactly; the trainer window sits higher because a
  -- class pic is a bust and a species pic is a whole creature.
  defaults = {
    trainers = { 16, 3, 32 },
    pokemon  = { 16, 17, 32 },
  },

  -- Per-picture overrides, keyed by the FRLG trainer front-pic id.  Every one
  -- of these is a picture the default window leaves floating above its subject.
  trainers = {
    -- ------- the Fame Checker's own three portraits (main.lua's FAME_PIC)
    --
    -- The cart keeps a 64x64 portrait for Oak, Daisy, Bill and Mr. Fuji in its
    -- Fame Checker, and this mod now draws the three who have no battle art of
    -- their own (Oak keeps his class picture).  They are NOT the trainer busts
    -- the default rule was written for: a Fame Checker portrait is a HEAD
    -- filling the top of the square -- the opaque art starts at row 1 or 2 and
    -- the face occupies roughly rows 2-25 -- so the trainer default {16, 3, 32}
    -- begins below the face and frames the chest.  Each window below sits on
    -- the head, measured from the four .rgba files dumped by
    -- .probe/dp3_fame_dump.lua: the head's x range and centre are in each
    -- comment, and y 0 is the top of the art.
    --
    -- The keys are SYNTHETIC picture ids in no relationship to a front-pic id
    -- (301, 313, 314) because the source is not a front pic at all; main.lua's
    -- FAME_PIC is the only thing that produces them.
    ["301"] = { 16, 0, 32 },  -- DAISY    -- head x 23-42, centre 32
    ["313"] = { 18, 0, 32 },  -- BILL     -- head x 25-44, centre 34
    ["314"] = { 18, 0, 32 },  -- MR. FUJI -- head x 21-47, centre 34

    -- PICTURE 82 -- the YOUNGSTER of class 57, and the SITTING BOY of graphics
    -- id 21.  bbox (16,15)-(49,62), 34% artwork at the default with twelve
    -- empty rows above the head, which starts at row 15.  The head's centre is
    -- 30, which files {14,12,32} at 44%.
    --
    -- 1.9.2 note: this is the picture the class NAME "YOUNGSTER" resolves to
    -- now.  It used to resolve to picture 36, the Hoenn youngster, whose entry
    -- is gone -- see the header.
    ["82"] = { 14, 12, 32 },

    -- PICTURE 83 -- the BUG CATCHER.  Reached by the cart's own graphics id 20
    -- (main.lua's GFX_ART), and by class 58 for the battle rows.  A wide pose
    -- whose head the default cuts on the LEFT: the head blob is x 7-44, so the
    -- window's own left edge at x16 takes nine pixels off its face, and the
    -- window is 36% artwork with eleven empty rows above.  {10,11,32} frames
    -- the whole head with the net still in shot, at 62%.
    ["83"] = { 10, 11, 32 },

    -- PICTURE 85 -- the SAILOR, reached by the cart's graphics id 62 and by
    -- class 60 for the battle rows.  A standing figure saluting, drawn to the
    -- top of its square: the head's cap starts at row 1 and the head spans
    -- x 14-42.  The default window (16,3,32) is 63% artwork but takes nine
    -- pixels off the LEFT of the cap and twenty-seven off its top, so the cap's
    -- top-left corner sits outside the frame.
    --
    -- {12,0,32} is the rule's own answer -- head centre 28, and the first opaque
    -- row (1) minus the three rows of headroom, clamped to 0 -- and it cuts
    -- nothing at all: 61% artwork with the whole cap and the raised arm in shot.
    --
    -- The DENSEST window is {11,7,32} at 65%, and it is the one to beware of: it
    -- buys four points of fill by chopping 95 pixels off the top of the head.
    -- More artwork and less face is a worse portrait.
    ["85"] = { 12, 0, 32 },

    -- PICTURE 95 -- the male SWIMMER, reached by the cart's graphics ids 43
    -- and 45.  bbox (12,15)-(49,62), 39% artwork, head starting at row 15 and
    -- clipped four pixels on the left by the default.  {12,12,32} at 52%.
    ["95"] = { 12, 12, 32 },

    -- PICTURE 105 -- the BLACK BELT, reached by the cart's graphics id 54 and
    -- by class 80 for the battle rows.  THE WORKED EXAMPLE for 1.9.2, and the
    -- one that shows why a fill percentage is not a measurement.
    --
    -- He is drawn in a wide fighting stance with both arms out and the red belt
    -- trailing behind his head.  The default window (16,3,32) is 63% artwork,
    -- which sounds fine, and it takes 255 pixels off the LEFT of the pose --
    -- including half his face, because the head is at x 9-45 while the window
    -- opens at x 16.
    --
    -- The densest window is {13,20,32} at 86%, and it is his LAP: it cuts 369
    -- pixels off the top of the head, which is exactly the mistake the header
    -- warns about.  A portrait of a crotch is not a portrait.
    --
    -- No 32px window holds this picture's head, because the head is 37 pixels
    -- wide (x 9-45), so the window CENTRES it instead: {11,1,32} opens two
    -- pixels left of the head and takes three off its right, as even as a
    -- 32-wide window can make a 37-wide head.  It cuts nothing off the TOP --
    -- the head's topmost row is 3 -- so the face and the headband are whole, at
    -- 64% artwork.  The 65 and 174 pixels it still takes off the left and right
    -- are the outstretched arms, which a bust is entitled to crop.
    ["105"] = { 11, 1, 32 },

    -- PICTURE 140 -- the FEMALE TUBER, reached by the cart's graphics id 37.
    -- bbox (16,23)-(52,62): the figure sits in the BOTTOM of its square because
    -- a tuber is drawn inside a tyre, so the default window is 23% artwork with
    -- twenty empty rows above the head.  The head's centre is 34, which files
    -- {18,20,32} at 66% -- the head, and the tyre it is standing in.
    --
    -- 1.9.1: this entry used to claim "the cart has one tuber picture for all
    -- three" graphics ids 36, 37 and 38, and the cart has two.  Picture 7 is the
    -- MALE tuber, which is why a boy in a swim ring was wearing a girl's face;
    -- 36 and 38 are routed to 7 now (main.lua's GFX_ART) and only the female id
    -- 37 reaches this rectangle.
    ["140"] = { 18, 20, 32 },

    -- PICTURE 7 -- the MALE TUBER, reached by the cart's graphics ids 36 and
    -- 38.  The same seated-in-a-tyre pose as 140, so the default window is 20%
    -- artwork with eighteen empty rows above the figure -- as empty as the
    -- Fisherman's.  The head's centre is 32.5, which files {17,16,32} at 52%.
    ["7"] = { 17, 16, 32 },

    -- PICTURE 35 -- the old WOMAN, reached by the cart's graphics id 35.  The
    -- female half of the EXPERT pair, and the cart's only old-woman bust.  bbox
    -- (11,21)-(51,61): she is drawn SEATED and low in her square, so the default
    -- window is 21% artwork with eighteen empty rows above her.  The head's
    -- centre is 29, which files {13,18,32} at 63%.
    --
    -- Her male counterpart is picture 34, and it deliberately has NO entry: the
    -- old man is a standing bust whose head starts at row 2, so the default
    -- frames him at 58% with his head inside.  A key that just restates the
    -- default is a line that can drift out of date, so the measurement is
    -- recorded here instead of as a rectangle.
    ["35"] = { 13, 18, 32 },

    -- PICTURE 86 -- the CAMPER, reached by the cart's graphics id 39.  bbox
    -- (12,13)-(46,62): the head starts at row 13 and the default clips two
    -- pixels off the left of it, leaving 37% artwork.  {11,10,32} at 48% frames
    -- the whole head with the cap still in shot.
    --
    -- Its female counterpart, picture 87 (the PICNICKER), needs no entry -- the
    -- default frames it correctly, which the same probe measures.
    ["86"] = { 11, 10, 32 },

    -- ------- the pictures 1.9.2 newly routes to, and the ones it retires
    --
    -- 1.9.2 corrects which class a duplicated class NAME means (main.lua's
    -- `classIdForName`), and that moves seven trainer pictures.  Two of them
    -- needed an entry -- 85 and 105, above.  The other five do not, and the
    -- measurement is recorded here rather than as a rectangle that would only
    -- restate the default:
    --
    --   picture 84  the Kanto LASS (class 59; graphics ids 17 and 22) -- the
    --               default frames her at 47% with the head inside.  This is
    --               the girl on Route 3 the report names, and she now wears it.
    --   picture 94  the Kanto FISHERMAN (class 69; graphics id 57) -- 58%, head
    --               inside.  This is the picture the NPC on the pier wears now.
    --   picture 98  the BEAUTY (class 73; graphics id 29) -- 63%, and the
    --               default takes exactly ONE row off the top of her hair,
    --               which is inside this table's two-pixel tolerance.
    --   picture 123 the GENTLEMAN (class 88; graphics id 61) -- 55%, head in.
    --   picture 110 the Kanto COOLTRAINER bust (class 86) -- 49%, head in, and
    --               nothing in the world resolves to it anyway.
    --
    -- Three pictures become UNREACHABLE, and their entries are gone with them:
    -- 36 (the Hoenn youngster), 38 (the Hoenn fisherman) and 65 (the Hoenn
    -- lass).  The header tells that story, because it is worth reading once.

    -- ------- 1.9.3: the same audit, run over the whole table
    --
    -- 1.9.3 re-frames the pictures whose window sat on the wrong part of the
    -- art, and every entry below (and every re-measured rectangle in `pokemon`)
    -- came out of looking at the sprite with `.probe/dp3_frame_compare.py`,
    -- which draws the window over the whole 64x64 and shows the result beside
    -- it.  The species are the ones that report names; the trainer is the one
    -- the sweep found, and it was found by rendering all 147 trainer pictures
    -- (`.probe/dp3_trainer_sheet.py`) rather than by trusting a fill percentage.

    -- PICTURE 66 -- the HOENN BUG CATCHER, class 50.  The cart spells "BUG
    -- CATCHER" twice -- class 50 here and class 58, whose picture 83 is the one
    -- the NAME resolves to and which already has an entry above.  Class 50 is
    -- still reachable: one trainer row in the cart's own table carries it, so
    -- `picForClass(50)` reaches this rectangle.
    --
    -- The pose is a boy lunging with a butterfly net, drawn small in the upper
    -- left with the net sweeping out to the right.  bbox (13,12)-(61,61), and
    -- the default window is 33% artwork -- the emptiest of the trainer pictures
    -- that anything still reaches, because the net, not the head, owns the
    -- right half of the frame.  The default takes the whole of the hat's left
    -- brim off and leaves the face against its left edge.
    --
    -- The head blob is x 13-40 with the face at x 18-34, so the rule's own
    -- answer is the face's centre (26) minus 16, and the artwork's first row
    -- (12) minus the three rows of headroom: {10,9,32}.  That holds the whole
    -- hat and the face, centred, at 44% -- and the net is what it crops, which
    -- a bust is entitled to do.
    ["66"] = { 10, 9, 32 },
  },

  -- Per-species overrides, keyed by the species key, lowercased and stripped of
  -- its separators (see the header; main.lua's `speciesKey` does the folding).
  --
  -- WHY EVERY SPECIES THAT CAN BE REACHED HAS AN ENTRY.  The default window is
  -- rows 17-48 of a 64px sprite, which frames a whole creature's BODY.  A
  -- portrait is a face, and most species have artwork starting ABOVE row 17 --
  -- PIKACHU's at row 6, PIDGEOT's at 2, FEAROW's at 0 -- so the default cut the
  -- top of the head off and showed mostly chest.  Every entry below is the
  -- sprite's own bounding box centre on x with the window's top four rows above
  -- the artwork (clamped), unless its own comment says otherwise.
  --
  -- TWO populations reach this table, and 1.9.2 is the release that made the
  -- second one reachable at all:
  --
  --   * the species that SPEAK -- 19 of them.  The cart writes their names into
  --     its own dialogue ("PIKACHU: Pika!") and the mod resolves a speaker from
  --     the text.  Until 1.9.2 that was the only way a Pokemon got a portrait;
  --   * the Pokemon that STAND IN THE WORLD as map objects -- 32 graphics ids
  --     from 109 (SNORLAX) up, which the host sprite vocabulary cannot name at
  --     all (main.lua's GFX_MON).  They resolved to NO portrait before 1.9.2,
  --     and the reported "some Pokemon, such as Spearow, do not display a
  --     portrait at all" is that omission.
  --
  -- The two sets overlap -- all 19 speakers are also placed somewhere -- so the
  -- reachable total is 32 species and this table carries 31 of them.  Nothing
  -- outside those 32 is listed: a key nothing ever reaches is a line that
  -- silently never fires, and the mod's rule everywhere the data does not decide
  -- is to decline rather than to guess.  A script that named a species the cart
  -- never placed would fall through to the default window, which is the same
  -- answer the 19 speakers got before any of this table existed.
  --
  -- ------- 1.9.3: the species whose BOX is not their FACE
  --
  -- Seven rectangles below were re-measured in 1.9.3, and they are all the same
  -- mistake.  The species rule is "centre the creature's own box", which is
  -- honest for a creature that faces the camera -- its box IS its head and
  -- shoulders -- and wrong for one drawn side-on or with a wing spread, where
  -- the box is mostly something else:
  --
  --   fearow     the box is WING and the head is at the bottom left, so the old
  --              window {32,0,32} held nothing but a wing -- no face at all;
  --   pidgeot    the box is WING and the head is at the top left, so the old
  --              window cut the eye and the beak off the left edge;
  --   zapdos     head and beak are at the LEFT of a wing-dominant box;
  --   moltres    head and beak are at the BOTTOM left of a wing-dominant box;
  --   articuno   head is at the top left, and the old window left the eye on
  --              the left edge;
  --   slowbro    the box includes the SHELLDER clamped to its tail, so centring
  --              the box pushed the muzzle off the left edge;
  --   nidorino   the box centre is between the ears, and the ears are the top
  --              two-thirds of the creature, so the old window framed the ears
  --              and cut the muzzle.
  --
  -- In each case the window is now centred on the FACE -- the eye and the beak
  -- or muzzle -- and the measurement is in the entry's own comment.  `.probe/
  -- dp3_frame_compare.py` is the tool that settled them: it draws the candidate
  -- window over the whole 64x64 sprite and shows the crop beside it, which is
  -- the only way to tell a window that holds a face from one that holds 90% of
  -- a wing.
  --
  -- Every other species was checked the same way and left alone.  A rectangle
  -- that only restates the rule is a line that can drift out of date, so the
  -- ones that were right stay unlisted.
  pokemon = {
    ["chansey"]   = { 15, 5, 32 },    -- bbox (6,9)-(56,54)
    ["clefairy"]  = { 15, 11, 32 },   -- bbox (14,15)-(49,47)
    ["cubone"]    = { 13, 9, 32 },    -- bbox (10,13)-(48,50)
    ["doduo"]     = { 14, 6, 32 },    -- bbox (11,10)-(50,56)
    ["fearow"]    = { 0, 20, 32 },    -- bbox (4,0)-(63,63); head at the BOTTOM left, eye x 12-18 y 36-44
    ["jigglypuff"] = { 16, 11, 32 },  -- bbox (16,15)-(48,47)
    ["machoke"]   = { 14, 4, 32 },    -- bbox (5,8)-(56,57)
    ["machop"]    = { 15, 7, 32 },    -- bbox (17,11)-(46,52)
    ["meowth"]    = { 16, 8, 32 },    -- bbox (13,12)-(51,51)
    ["nidoranf"]  = { 15, 12, 32 },   -- bbox (15,16)-(47,47)
    ["nidoranm"]  = { 13, 13, 32 },   -- bbox (14,17)-(44,51)
    ["nidorino"]  = { 11, 14, 32 },   -- bbox (10,9)-(53,55); head x 10-42 y 8-46, muzzle to y 45
    ["pidgeot"]   = { 0, 3, 32 },     -- bbox (1,2)-(62,62); head x 4-26 y 8-30, at the LEFT
    ["pidgey"]    = { 16, 10, 32 },   -- bbox (16,14)-(49,50)
    ["pikachu"]   = { 17, 2, 32 },    -- bbox (13,6)-(53,54); its ears start at row 6
    ["poliwrath"] = { 14, 5, 32 },    -- bbox (6,9)-(55,56)
    ["psyduck"]   = { 15, 6, 32 },    -- bbox (14,10)-(49,54)
    -- 1.9.5 (corrected): the SEAL is drawn FRONT-ON with its FACE LOW, and the
    -- first cut of this entry was measured against the WRONG PICTURE -- mon-87,
    -- DEWGONG, whose head does sit at the top left.
    --
    -- Which picture is the seal's is not a guess.  The engine shows a species
    -- its own front pic: speciesArt feeds record.index to Pokemon.frontPic, and
    -- SEEL's internal species id is 86 -- Pokemon.national(86) is 86, internal
    -- equals national for every id up to 251, and the pack's own name index
    -- inverts gSpeciesNames, where 86 is SEEL.  Pokemon.frontPic(86) is
    -- BYTE-IDENTICAL to .probe/_art/mon-86.png, proved by
    -- .probe/dp3_seel_engine.lua, which wraps the LÖVE stub's constructors to
    -- keep the engine's own rgba.  So mon-86 is the sprite to measure.
    --
    -- Seel's sprite is not Dewgong's shape.  The whole creature is one mass,
    -- bbox (6,9)-(53,54), but the FACE is at the BOTTOM CENTRE: the muzzle is
    -- the only tan mass, bbox (18,42)-(34,51), the tongue the only red one,
    -- bbox (20,47)-(27,52), and the two eyes the only dark blobs inside the
    -- silhouette, at (20,39)-(25,44) and (29,34)-(35,37).  All three found by
    -- colour in .probe/dp3_seel_face.py.  The face therefore spans x 18-35,
    -- y 34-52 -- the bottom third of the sprite.
    --
    -- The rule's own answer for a species is the box's centre on x, four rows
    -- above the first opaque row on y, at 32.  Here that is x 29.5-16 = 13 and
    -- y 9-4 = 5, i.e. {13,5,32} -- the entry this table carried.  It runs
    -- x 13-44, y 5-36: the two lobes at the top of the sprite and the upper
    -- body, with the ENTIRE face below the window.  That is the reported "the
    -- Seel portrait is not framed correctly", and it is the same shape as the
    -- 1.9.3 birds -- a creature whose BOX is not its FACE.
    --
    -- The sprite is 44 rows tall, from the top lobes at row 9 to the tongue at
    -- row 52, and 32 rows cannot hold it, so the FACE wins: {12,21,32} runs
    -- x 12-43, y 21-52 and holds the eyes, the whole muzzle and the whole
    -- tongue, whose last row stops exactly at the bottom edge.  The top lobes
    -- fall off the top, which is where a portrait wants a raised limb.  The
    -- window is centred on the face's own width -- the face spans x 18-35, so
    -- its centre is 26.5 against the window's 27.5 -- leaving six columns of
    -- margin on the left and eight on the right.
    ["seel"]      = { 12, 21, 32 },   -- face bbox (18,42)-(34,52); tongue to y 52
    ["wigglytuff"] = { 14, 2, 32 },   -- bbox (8,6)-(53,55)

    -- ------- the Pokemon that STAND IN THE WORLD, added by 1.9.2
    --
    -- Every one of these is a species the cart PLACES as a map object, and none
    -- of them could be reached before 1.9.2 -- see the note above.  The
    -- rectangle is the rule: the creature's own box centre on x, four rows above
    -- its first opaque row on y.
    --
    -- Four of them say otherwise in their own comment, and each time for the
    -- same reason: the box is not the head.  A sleeping Snorlax's box is its
    -- whole body with the head tucked into one end, a Slowpoke's topmost blob is
    -- its TAIL, and the legendary birds' boxes are mostly WING.  Those are
    -- centred on the FACE instead, which `.probe/dp3_window_cut.py` locates by
    -- colour -- the beak is the only orange thing in a blue bird.
    --
    -- 1.9.3 is where the birds' entries finally matched that claim.  1.9.2 said
    -- the three birds were face-centred and only Snorlax and Slowpoke were:
    -- zapdos, moltres and articuno were all filed at x 13-17, y 0, which is the
    -- WING on every one of them.  Their own art puts the head at the left --
    -- top-left for articuno and zapdos, bottom-left for moltres -- and the three
    -- are re-measured above and below.  The lesson is in the header: a rule
    -- written down is not a rule applied, and the only check that catches it is
    -- rendering the window over the sprite and looking.
    --
    -- VOLTORB is deliberately absent.  The default frames it at 50% with the
    -- whole ball and both eyes inside it, and a key that only restates the
    -- default is a line that can drift out of date.
    ["spearow"]    = { 16, 12, 32 },  -- bbox (15,15)-(48,51); THE REPORTED CASE
    ["kangaskhan"] = { 19, 2, 32 },   -- bbox (3,5)-(61,63)
    ["slowbro"]    = { 4, 7, 32 },    -- bbox (3,10)-(61,61); the box is the SHELLDER, not the face
    ["lapras"]     = { 9, 1, 32 },    -- bbox (4,4)-(61,59)
    ["zapdos"]     = { 0, 6, 32 },    -- bbox (0,3)-(63,59); head and beak are at the LEFT
    ["moltres"]    = { 0, 30, 32 },   -- bbox (1,0)-(63,57); head and beak are at the BOTTOM left
    ["articuno"]   = { 1, 0, 32 },    -- bbox (2,0)-(63,63); head at the top LEFT, eye x 10-16
    ["mewtwo"]     = { 21, 0, 32 },   -- bbox (3,1)-(59,63); head is x 26-47
    ["snorlax"]    = { 24, 2, 32 },   -- bbox (0,5)-(63,58); head is x 40-53, y 5-16
    ["slowpoke"]   = { 8, 16, 32 },   -- bbox (10,12)-(55,50); box centre is the TAIL
    ["lugia"]      = { 6, 28, 32 },   -- bbox (1,0)-(63,63); face = eye x14-30 + beak
    ["hooh"]       = { 2, 26, 32 },   -- bbox (0,0)-(63,63); face = eye x 8-28 + beak
  },

  -- ------- pictures the cart drew TWO people into
  --
  -- Five of the cart's front pics are a PAIR: one 64x64 picture holding two
  -- people side by side.  A pair picture is not two pictures, so the picture key
  -- cannot express it -- `trainers["129"]` is one rectangle, and both members of
  -- the Young Couple wear picture 129 -- and that is the reported "the couple
  -- (JES and GIA) that shares one portrait".  Both halves are the same artwork,
  -- so no single rectangle for picture 129 can be right for both of them.
  --
  -- The fact that separates them is the object's own GRAPHICS ID, which is the
  -- same fact that separates the Bird Keepers from the Rocker on gfx 26 (see
  -- GFX_ART in main.lua).  FRLG places the two halves of a pair with two
  -- different overworld sprites -- the Young Couple's woman wears
  -- OBJ_EVENT_GFX_BEAUTY and her partner wears OBJ_EVENT_GFX_MAN -- so
  -- `pairSide` below maps a graphic to the half it stands on, and `pairs` holds
  -- one rectangle per half.  Which is which is read off the cart's own
  -- placement, never off the artwork: the half that wears BEAUTY is the woman
  -- whatever she is drawn wearing.
  --
  -- Every rectangle here is measured off the picture, not guessed.  A pair is
  -- drawn as two whole figures side by side, so each face sits in the UPPER
  -- part of its own half -- which is why every y below is small -- and each
  -- window is the 32px square that holds one person's head and shoulders whole
  -- while stopping short of the other's art.  The bboxes each one was measured
  -- against are in the comment.
  --
  -- Only the pairs the cart actually PLACES are listed, and that is a
  -- measurement rather than a tidy-up: 127 Twins, 128 Cool Couple, 129 Young
  -- Couple, 130 Crush Kin and 131 Sis and Bro are worn by objects standing in
  -- the world, and 68 RSYoungCouple / 69 OldCouple are not -- no object in this
  -- game wears either -- so a rectangle for them would be a line nothing can
  -- reach.  Measured by .probe/dp3_full_audit.lua, which prints the trainer row
  -- behind every object's graphics id.
  pairs = {
    -- Twins.  Both halves are the same girl, so ONE rectangle answers for both
    -- of them -- and for the LITTLE_GIRL sprite that wears her (see GFX_ART).
    -- The left twin's head spans x 20-33 and her sister's starts at x 35, with
    -- the two heads meeting at the single column x 34.  So the window is the
    -- one 32px span that holds the whole of the left girl and none of the
    -- right: x 2 to 33.  x 0 (which this table used at first) stops at column
    -- 31 and takes the right two columns of her head off with it.
    -- bbox left (20,16)-(33,62), right (35,17)-(55,61)
    ["127"] = { left = { 2, 10, 32 } },
    -- Cool Couple: the boy is on the LEFT in trousers, the girl on the RIGHT in
    -- a jacket and shorts.  bbox left (8,3)-(31,62), right (32,3)-(60,62)
    ["128"] = { left = { 0, 2, 32 }, right = { 32, 2, 32 } },
    -- Young Couple: the woman is on the LEFT in a skirt, the man on the RIGHT.
    -- bbox left (1,8)-(31,61), right (32,6)-(61,61)
    ["129"] = { left = { 0, 4, 32 }, right = { 32, 2, 32 } },
    -- Crush Kin: the karate half is on the LEFT, the orange half on the RIGHT.
    -- bbox left (1,4)-(31,62), right (32,0)-(62,62) -- and the RIGHT half's art
    -- reaches row 0, because her ponytail's red band sticks up over the karate
    -- half's shoulder.  So her window starts at 0 and not at the 2 the others
    -- use: at 2 the top of the band was cut, which is the one thing a head
    -- window must never do.  Measured rather than eyeballed -- see the note on
    -- the audit below -- and it is the only half of the nine that needed it.
    ["130"] = { left = { 0, 3, 32 }, right = { 32, 0, 32 } },
    -- Sis and Bro: the sister is on the LEFT, the brother is on the RIGHT and
    -- is drawn LOWER than she is -- his art starts at y 19, hers at y 2 -- so
    -- this is the one pair whose two windows do not share a y.
    -- bbox left (5,2)-(31,60), right (32,19)-(58,63)
    ["131"] = { left = { 0, 2, 32 }, right = { 32, 16, 32 } },
  },

  -- Which half of a pair picture an object stands on, by its FRLG graphics id.
  --
  -- This is a table of its own rather than nine `gfx:<id>` crops in `speakers`
  -- below, and that is the whole point: a `gfx:` crop is applied to whatever
  -- picture the speaker resolved to, and gfx 29 is not only the woman in a
  -- Young Couple -- it is also every ordinary Beauty, who wears picture 98 and
  -- would be cut with half of picture 129 if this were filed there.  A graphic
  -- listed here is only ever asked for a half when the picture it resolved to
  -- IS that pair, so an ordinary Beauty keeps her own picture and her own
  -- rectangle untouched.
  --
  -- A graphic that is not listed is not one of a pair's two people, and a
  -- graphic that IS listed is harmless for every other picture it wears: gfx 41
  -- is a Cool Couple's boy AND a plain Cooltrainer (picture 110) AND a Psychic
  -- (picture 100), and neither of those two is in `pairs`.
  pairSide = {
    [17] = "left",   -- LITTLE_GIRL     -- both Twins wear it; either half will do
    [24] = "right",  -- CRUSH_GIRL      -- the orange half of a Crush Kin
    [54] = "left",   -- BLACK_BELT      -- the karate half of a Crush Kin
    [44] = "left",   -- SWIMMER_F       -- the sister in Sis and Bro
    [36] = "right",  -- TUBER_M         -- the brother in Sis and Bro
    [42] = "right",  -- COOLTRAINER_F   -- the girl in a Cool Couple
    [41] = "left",   -- COOLTRAINER_M   -- the boy in a Cool Couple
    [29] = "left",   -- BEAUTY          -- the woman in a Young Couple
    [25] = "right",  -- MAN             -- the man in a Young Couple
  },

  -- Per-speaker overrides, keyed by the identities the mod resolves a speaker
  -- by rather than by the picture that speaker wears.  See the header for when
  -- to reach for this table instead of the two above -- and note that nothing
  -- needs it yet, which is a measurement rather than an omission.
  speakers = {},
}
