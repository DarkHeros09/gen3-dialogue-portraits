-- The Emerald counterpart of main.lua's hand-authored GFX_ART: the person
-- graphics the MEASURED tables cannot answer, given the cart's own bust.
--
-- ---- why a hand table is needed at all
--
-- emerald/gfx_art.lua and emerald/map_art.lua are MAJORITIES over the cart's
-- trainer rows: they answer for a graphic only when some trainer WEARS it.  Of
-- the person graphics the ROM places, the great majority are worn by a trainer
-- and the two generated tables answer them; a measured 25 kinds are not, and
-- for those the graphic is the only fact about the person.  Without an entry
-- here every one of them got NO portrait -- which is exactly the report this
-- release fixes ("no portraits has been showing during dialogue boxs").
--
-- The 25 were measured, not assumed: .probe/drivers/dp3_emerald_sweep.lua walks
-- every map the engine hydrates, resolves every object, and prints the person
-- graphics the resolver declined.  THAT list is what this table is keyed by.
--
-- ---- how the values were decided
--
-- By eye, against the cart's own art, the way FRLG's GFX_ART was: the overworld
-- sprite (rom_sprites/overworld/ow_NNN.png, id = this table's key) and the
-- trainer bust (rom_sprites/trainers/tr_NNN.png, id = the value) were put side
-- by side (.probe/dp3_em_cmp.py) and the bust that IS that person -- or, for a
-- figure the cart never drew a bust of, the closest bust of the same build and
-- palette -- was written down.  NO value here is inferred from a class name or
-- a graphic name; where a name and the art disagree, the art won.
--
-- Three kinds of entry, in order of how hard the value is:
--
--   * EXACT, for the leaders, the champion, the villains, the Frontier Brain
--     and the rival.  The cart FIELDS these in battle, so its own trainer table
--     carries a row for each and the row names the picture -- NORMAN id 269 pic
--     44, WALLACE id 335 pic 54, ARCHIE id 34 pic 13, BRANDON id 811 pic 88
--     (measured by .probe/dp3_em_named.lua).  The graphic is only needed because
--     the importer's scriptKey table cannot name their battle scripts.  The
--     rival is exact from the other side: his overworld art is PIXEL-IDENTICAL
--     to the player's (gfx 100 == gfx 0, gfx 105 == gfx 89), so he wears the
--     player's own bust.
--   * A CLOSEST-BUILD bust, for the generic townsfolk the cart drew no bust of
--     (the man, the woman, the nurse): the same decision FRLG's table records
--     for its Man (-> the Tamer) and its Balding Man (-> the Engineer).
--   * `false`, for a named character who never battles, so the cart has no front
--     picture of them at all: a wrong face would be worse than none, which is
--     the answer FRLG's table gives its Daisy and its Fat Man.
--
-- ---- the values
--
-- A NUMBER is an exact front-picture id, read the same way art/crops.lua's are.
-- `false` is "this graphic is a person the cart never drew a battle bust of".
-- Keyed by the graphics id, exactly like emerald/gfx_art.lua, so a typo in a key
-- would fall through to the generated majority rather than crash; the tests
-- assert every value is a readable picture or `false`.

return {
  -- ------- the ORDINARY townsfolk: a whole family of graphics the cart's own
  -- class table answers for exactly, but that the measured majority routes to a
  -- Sailor (pic 68) because ONE mis-keyed trainer object wears each of them.
  --
  -- WHY THE MAJORITY IS WRONG HERE.  emerald/gfx_art.lua counts an object only
  -- when its scriptKey maps to a cart trainer id.  gfx 7 BOY_1 is worn by 26
  -- ordinary NPCs and one object whose scriptKey resolves to a trainer row whose
  -- class reads SAILOR, so the whole-ROM majority is "SAILOR x1" -- one vote
  -- against zero, because the 26 townsfolk are not trainers and never got a
  -- vote.  A graphic is a uniform, not a person, and the cart's own NAME for the
  -- graphic (emerald/gfx_names.lua) is the better fact when it names a class.
  --
  -- These entries resolve it by eye, against the cart's own art, the way FRLG's
  -- GFX_ART was: the overworld sprite's front frame beside the candidate busts,
  -- at 10x (.probe/_em_girls_pick.png).  The boy graphics wear the YOUNGSTER
  -- (pic 53), RICH_BOY its own class picture 23, and the GIRL graphics the
  -- cart's own little girl -- the TWINS picture (67), cut to one half, which is
  -- what FRLG's GFX_ART does for its LITTLE_GIRL ("picture 127 is the Twins, and
  -- art/crops.lua cuts it down to one girl").  NO value here is inferred from a
  -- class name alone; where the name and the art disagreed, the art won.
  --
  -- WHY NOT THE SCHOOL KID ANY MORE (reported, this release).  1.3.2 gave every
  -- girl graphic picture 48, on the strength of the graphic's cart name being
  -- read against the pack's "SCHOOL KID" class.  Picture 48 is a BOY -- blue
  -- cap, blue shirt, a green bag over his shoulder (.probe/_em_keypics.png) --
  -- so every girl in Hoenn was drawn as a boy.  The pack's class label is not
  -- the art, which is the mistake this table exists to avoid.
  --
  -- The picture ids are the cart's own, read off the class table the mod builds
  -- (.probe/drivers/dp3_emerald_classdump.lua): YOUNGSTER class 37 pic 53,
  -- RICH BOY class 22 pic 23, TWINS class 46 pic 67.
  [7]  = 53,             -- BOY_1        (x26) small boy,  blue cap   -> YOUNGSTER
  [8]  = 67,             -- GIRL_1             small girl, yellow top -> TWINS left half
  [9]  = 53,             -- BOY_2        (x26) small boy,  blue cap   -> YOUNGSTER
  [10] = 67,             -- GIRL_2             small girl, white top  -> TWINS left half
  [11] = 53,             -- LITTLE_BOY         small boy             -> YOUNGSTER
  [12] = 67,             -- LITTLE_GIRL  (x21) small girl, red top    -> TWINS left half
  [13] = 53,             -- BOY_3              small boy, red cap     -> YOUNGSTER
  [15] = 23,             -- RICH_BOY           boy in a dark suit    -> RICH BOY (pic 23)

  -- ------- graphics whose own cart name IS a class, and the class answers with
  -- a BETTER picture than the majority -- the two route-3 disagreements the
  -- audit found (.probe/drivers/dp3_emerald_route3_check.lua).
  [47] = 77,             -- LASS   (x36) -> LASS class 54 pic 77, not the majority's Psychic 34
  [55] = 0,              -- HIKER  (x29) -> HIKER class 2 pic 0,   not the majority's Ruin Maniac 16

  -- ------- the rest of the SAILOR-contaminated and mis-routed ordinary NPCs
  --
  -- Same one-mis-keyed-trainer artefact as the child family above, on the adult
  -- graphics: WOMAN_1, FAT_MAN and POKEFAN_F all route to the Sailor (pic 68) by
  -- a single spurious vote, and POKEFAN_M/WOMAN_2 to a near-miss.  Each decided
  -- by eye against the overworld front frame (.probe/_em_women_pick.png).
  --
  -- THE FOUR WOMEN all take picture 15, the AROMA LADY -- the one ordinary
  -- adult-woman bust the cart draws, and the same answer FRLG's GFX_ART records
  -- for its own ordinary woman ("WOMAN_2 -> the Aroma Lady, the majority of its
  -- trainers").  1.3.2 had WOMAN_1 and WOMAN_2 on picture 20 (a green-haired
  -- Cooltrainer, a different person) and WOMAN_4 on picture 49, which is the
  -- SCHOOL KID -- a YOUNG GIRL (.probe/_em_keypics.png), so the adult woman was
  -- drawn as a child.  WOMAN_5 had NO entry at all and fell through to the
  -- statistical routes.  All four are reported.
  [16] = 15,             -- WOMAN_1   (x15) woman, apron      -> pic 15 (AROMA LADY)
  [17] = 0,              -- FAT_MAN   (x29) the round man -> pic 0 (HIKER), the cart's
                         --   one stocky rounded build -- reported.  The old value, pic 2,
                         --   is a young woman in red and read as the wrong person.
  [18] = 52,             -- POKEFAN_F (x43) the fan girl -> pic 52 (POKéFAN), not the Sailor
  [25] = 52,             -- POKEFAN_M (x23) the fan boy  -> pic 52 (POKéFAN), not 51
  [20] = 15,             -- WOMAN_2   (x49) woman, green dress -> pic 15 (AROMA LADY)
  [26] = 15,             -- WOMAN_4   (x21) woman -> pic 15 (AROMA LADY); was 49, a young girl
  [34] = 15,             -- WOMAN_5   (x17) woman, red top -> pic 15 (AROMA LADY); NEW entry --
                         --   1.3.2 had none, so she fell through to a statistical route
  [65] = 2,              -- MAN_4     (x26) -> pic 2 (POKéMON BREEDER), not the Young Couple 78

  -- ------- the pair pictures the majority had already routed, now HAND-PINNED
  -- so the framing cannot drift back to the single default.  The half is filed
  -- in emerald/crops.lua's pairSide; these keep the PICTURE right.
  [68]  = 17,            -- REPORTER_F     -> INTERVIEWER pair (left, with the mic)
  [110] = 17,            -- CAMERAMAN      -> INTERVIEWER pair (right, with the camera)
  [67]  = 17,            -- REPORTER_M     -> INTERVIEWER pair (right, with the camera too --
                         --   his overworld front frame holds the camera, .probe/_em_reporters.png)
  [213] = 80,            -- TUBER_M_SWIMMING -> SIS AND BRO pair (left, the boy)

  -- ------- a lone NPC wearing a TWO-PERSON picture
  --
  -- MAN_4 (x26) is one of the most-placed people in Hoenn, and the majority
  -- routes it to picture 78 -- the YOUNG COUPLE, a two-person bust.  A lone NPC
  -- has no pairSide (there is no "which half" for someone standing alone), so
  -- the pair route cannot fire and the whole embrace was cut with one window:
  -- two heads in a 32px box.  It takes a single bust instead, by eye against the
  -- overworld front frame: pic 2 (POKéMON BREEDER), the cart's plainest
  -- lone-adult male.
  --
  -- (WOMAN_4 was here too in 1.3.2; it is now the AROMA LADY, filed with the
  -- other women above.  One key per graphic -- a second [26] entry below would
  -- silently win and undo that.)
  -- MAN_4 (x26) is filed with the adult block below, for the same reason.

  -- ------- EXACT: the leaders, the champion, the villains, the Frontier Brain
  --
  -- Each value is the picture in the cart's own trainer row for that character.
  [129] = 44,            -- NORMAN   (leader, Petalburg; id 269 pic 44)
  [133] = 54,            -- WALLACE  (champion;        id 335 pic 54)
  [195] = 13,            -- ARCHIE   (Team Aqua leader; id 34  pic 13)
  [234] = 88,            -- BRANDON  (Pyramid King;     id 811 pic 88)

  -- ------- EXACT: the rival wears the player's own bust
  --
  -- gfx 100 (RIVAL_BRENDAN_NORMAL) is PIXEL-IDENTICAL to gfx 0 (BRENDAN_NORMAL)
  -- and gfx 105 (RIVAL_MAY_NORMAL) to gfx 89 (MAY_NORMAL) -- the same art, so
  -- the same person.  The cart draws one bust per gender: 71 is Brendan's and
  -- 72 is May's.
  [100] = 71,            -- RIVAL_BRENDAN_NORMAL -> pic 71
  [105] = 72,            -- RIVAL_MAY_NORMAL     -> pic 72

  -- ------- EXACT: the old pair are the EXPERT pair
  --
  -- The cart's EXPERT class (class 10, pic 9) is the white-haired, bearded old
  -- man in the blue robe, and BOTH old-man graphics the ROM places wear him:
  -- OLD_MAN and EXPERT_M.  Measured by .probe/drivers/dp3_emerald_classdump.lua
  -- (EXPERT -> pic 9) and looked at at 8x (.probe/_em_old.png).
  [29] = 9,              -- OLD_MAN   -> pic 9  (EXPERT, the old man)
  [21] = 9,              -- EXPERT_M  (x50) -> pic 9 (EXPERT, the old man)

  -- The old WOMAN has no bust: Emerald's 93 pictures hold ONE elder, the man in
  -- picture 9.  The old woman is the EXPERT class's female half on the cart's
  -- trainer table, but the cart never drew her a front picture -- the picture
  -- the majority reached for, 24, is WINSTRATE (class 35, a young man), which is
  -- why 1.3.2's `[30] = 24` drew a young man for every old woman in Hoenn.  A
  -- wrong face is worse than none, so both decline -- the answer FRLG's table
  -- gives its Daisy and its Fat Man.
  [30]  = false,         -- OLD_WOMAN   (x10) the cart drew no old-woman bust
  [22]  = false,         -- EXPERT_F    (x23) ditto

  -- ------- CLOSEST BUILD: the townsfolk and staff the cart drew no bust of
  --
  -- MAN_1 (x31), MAN_2 (x22), WOMAN_3 (x37) are among the most
  -- common people in Hoenn and had no face at all.  Each takes the bust whose
  -- build and palette its sprite shows, decided by eye against the art
  -- (.probe/_em_townsfolk.png):
  [19] = 16,             -- MAN_1   (the man in the green vest)  -> pic 16 (RUIN MANIAC)
  [23] = 5,              -- MAN_2   (the man in the green apron) -> pic 5  (COLLECTOR)
  [24] = 15,             -- WOMAN_3 (the girl in the red dress)  -> pic 15 (AROMA LADY)
  -- SCIENTIST_2 (a woman in a lab coat) took picture 24 in 1.3.2 on the belief
  -- that 24 was the EXPERT old woman.  It is not: 24 is WINSTRATE (class 35), a
  -- young man, so every female scientist wore a kneeling boy.  The cart has no
  -- lab-coat bust; pic 82 (SALON MAIDEN) is the closest lone adult female in a
  -- pale outfit, and a woman is at least the right person.
  [115] = 82,            -- SCIENTIST_2 (a woman in a lab coat)  -> pic 82 (SALON MAIDEN)

  -- ------- REPORTED: the player's family, and the professor
  --
  -- May's mother and Professor Birch had NO face (both declined in 1.3.2) and
  -- the lab scientist wore a TEAM AQUA GRUNT -- the documented majority artefact
  -- again: gfx_art.lua carried `[46] = 1` with the comment "1 trainers: TEAM
  -- AQUA x1", one mis-keyed Aqua object wearing the scientist graphic, so every
  -- scientist in Hoenn wore the villain's face.  The scientist is now DECLINED
  -- and has moved to the declined block below.  Neither Birch nor his wife has an
  -- exact bust -- Emerald's class table has no Professor and no mother -- so each
  -- takes the closest build by eye (.probe/_r6_decide.png):
  [64] = 24,             -- PROF_BIRCH -> pic 24 (WINSTRATE).  A FALLBACK ONLY:
                         --   route 3b serves the cart's OWN Birch portrait
                         --   (field_effect.o:sNewGameBirch_Gfx, shipped as
                         --   emerald/art/PROF_BIRCH.png), which is exact art and
                         --   therefore answers first -- Emerald's own 93 battle
                         --   pictures hold no Birch at all (his new-game speech
                         --   art in field_effect.o is the only portrait the cart
                         --   draws of him), which is exactly why a pic number
                         --   could never answer him.  This entry survives only
                         --   for a boot where that PNG cannot be loaded -- a
                         --   graphics-context-less run -- where a closest-build
                         --   shape still beats a bare box.  Pic 24 is the
                         --   "EXPERT" (a kneeling old woman), which is NOT Birch;
                         --   it is a last-resort shape, never the answer.
  [215] = 15,            -- MOM        -> pic 15 (AROMA LADY): brown hair, red top,
                         --   the closest female build to Mom's overworld sprite.

  -- ------- CLOSEST BUILD: the nurse the cart drew no bust of
  --
  -- The cart DOES draw a nurse overworld sprite (gfx 58 -- pink hair, a white cap
  -- with a red cross), but it draws NO nurse battle bust: pic 82 is the SALON
  -- MAIDEN, a purple-clad contest host, which 1.3.2 wore for her and which reads
  -- as the wrong person entirely.  Reported as "should not have a portrait"; a
  -- wrong face is worse than none, so she declines -- the answer this table gives
  -- the old woman and the Mart employee.
  [58] = false,          -- NURSE

  -- ------- DECLINED: named people who never battle, so no bust exists
  --
  -- The TV crew, the shop and Devon staff, the contest and link-room staff, the
  -- mystery-gift man and Scott.  The cart never drew a front picture of any of
  -- them, and a wrong face is worse than none -- the answer FRLG's table gives
  -- its Daisy and its Fat Man.  The mother and the nurse USED to be here too;
  -- they are reported and now take a closest-build bust above.
  [219] = false,         -- SCOTT
  [99] = false,          -- ARTIST
  [27] = false,          -- COOK
  [190] = false,         -- CONTEST_JUDGE
  [28] = false,          -- LINK_RECEPTIONIST
  [227] = false,         -- UNION_ROOM_NURSE
  [223] = false,         -- MYSTERY_GIFT_MAN
  [83] = false,          -- MART_EMPLOYEE
  [116] = false,         -- DEVON_EMPLOYEE
  [46] = false,          -- SCIENTIST_1.  Reported: "remove the scientist portrait."
  --   It was given pic 70 (a young man in a white coat) as the nearest thing to a
  --   lab scientist, but Emerald's 93 pictures hold NO scientist of either sex --
  --   gfx 46 SCIENTIST_1 is placed exactly ONCE in the whole cart, at
  --   SlateportCity localId=11 -- so pic 70 is not the person, only a shape that
  --   happens to wear a pale coat, which fails the same test that sent the nurse
  --   and the old women here.  A wrong face is worse than none, so it declines.
  --   NOTE this is the SCIENTIST with a lab coat and glasses; SCIENTIST_2
  --   (gfx 115, the woman) keeps pic 82 above.
}
