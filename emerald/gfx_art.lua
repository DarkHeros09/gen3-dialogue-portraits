-- The majority front-picture for each Emerald overworld graphic, over the
-- whole ROM -- the answer for a graphic no map's trainer set names.
--
-- GENERATED -- do not hand-edit.  Regenerate with
--   luajit .probe/dp3_emit_emerald_map_art.lua \
--     pokemon-emerald-assets/emerald-cache gen3-dialogue-portraits-repo
--
-- This is the EMERALD counterpart of main.lua's GFX_ART, and it is a LAST
-- resort: emerald/map_art.lua runs before it (a map is more specific than the
-- whole ROM), and emerald/trainer_ids.lua runs before both (an id is a
-- person, a graphic is a uniform).
--
-- A graphic is worn by several trainer classes whose pictures differ, so this
-- value is a MAJORITY and is wrong for the minority by construction.  It beats
-- a bare box for an ordinary NPC, which is what the report asked for, and it
-- is the exact same trade-off FRLG's GFX_ART makes.
--
-- 69 graphics carry a trainer; 24 of them are shared by two or more classes
-- with different pictures.
--
-- The comment names the winning class, the count and the split.
return {
  [5] = 63,       -- 9 trainers: NINJA BOY x9 -> pic ; SAILOR x1 -> pic 
  [6] = 67,       -- 8 trainers: TWINS x8 -> pic ; SAILOR x1 -> pic 
  [7] = 68,       -- 1 trainers: SAILOR x1 -> pic 
  [8] = 68,       -- 1 trainers: SAILOR x1 -> pic 
  [9] = 68,       -- 5 trainers: RICH BOY x1 -> pic ; SAILOR x5 -> pic 
  [10] = 68,       -- 4 trainers: SAILOR x4 -> pic 
  [11] = 68,       -- 5 trainers: SAILOR x5 -> pic 
  [12] = 68,       -- 8 trainers: SAILOR x8 -> pic 
  [13] = 68,       -- 1 trainers: SAILOR x1 -> pic 
  [14] = 64,       -- 12 trainers: SCHOOL KID x2 -> pic ; BATTLE GIRL x12 -> pic ; SAILOR x6 -> pic 
  [15] = 68,       -- 6 trainers: RICH BOY x2 -> pic ; SAILOR x6 -> pic 
  [16] = 68,       -- 4 trainers: SAILOR x4 -> pic 
  [17] = 68,       -- 5 trainers: SAILOR x5 -> pic 
  [18] = 68,       -- 13 trainers: POKéFAN x4 -> pic ; SAILOR x13 -> pic 
  [20] = 15,       -- 5 trainers: POKéMON BREEDER x3 -> pic ; AROMA LADY x5 -> pic ; LADY x5 -> pic ; PARASOL LADY x2 -> pic ; SAILOR x1 -> pic 
  [21] = 9,        -- 5 trainers: EXPERT x5 -> pic ; OLD COUPLE x1 -> pic 
  [22] = 24,       -- 3 trainers: EXPERT x3 -> pic ; OLD COUPLE x1 -> pic 
  [25] = 51,       -- 3 trainers: POKéFAN x3 -> pic 
  [26] = 78,       -- 4 trainers: YOUNG COUPLE x4 -> pic 
  [31] = 29,       -- 11 trainers: CAMPER x11 -> pic ; POKéMON RANGER x3 -> pic 
  [32] = 30,       -- 14 trainers: PICNICKER x14 -> pic ; POKéMON RANGER x3 -> pic 
  [33] = 3,        -- 22 trainers: COOLTRAINER x22 -> pic ; DRAGON TAMER x2 -> pic ; SAILOR x1 -> pic 
  [34] = 20,       -- 22 trainers: COOLTRAINER x21 -> pic ; PARASOL LADY x3 -> pic ; COOLTRAINER x1 -> pic 
  [35] = 53,       -- 14 trainers: YOUNGSTER x14 -> pic ; BUG CATCHER x1 -> pic 
  [36] = 73,       -- 7 trainers: BUG CATCHER x7 -> pic 
  [37] = 33,       -- 10 trainers: PSYCHIC x10 -> pic 
  [38] = 48,       -- 3 trainers: SCHOOL KID x3 -> pic 
  [39] = 31,       -- 7 trainers: COLLECTOR x3 -> pic ; POKéMANIAC x3 -> pic ; BUG MANIAC x7 -> pic 
  [40] = 14,       -- 8 trainers: HEX MANIAC x8 -> pic 
  [42] = 7,        -- 29 trainers: SWIMMER♂ x29 -> pic ; TRIATHLETE x5 -> pic 
  [43] = 66,       -- 25 trainers: TRIATHLETE x6 -> pic ; SWIMMER♀ x25 -> pic ; SIS AND BRO x3 -> pic 
  [44] = 11,       -- 12 trainers: BLACK BELT x12 -> pic 
  [45] = 22,       -- 10 trainers: BEAUTY x10 -> pic 
  [46] = 1,        -- 1 trainers: TEAM AQUA x1 -> pic 
  [47] = 34,       -- 12 trainers: PSYCHIC x12 -> pic ; SR. AND JR. x8 -> pic ; LASS x7 -> pic 
  [48] = 35,       -- 6 trainers: GENTLEMAN x6 -> pic 
  [49] = 68,       -- 11 trainers: SAILOR x11 -> pic 
  [50] = 55,       -- 18 trainers: FISHERMAN x18 -> pic ; SAILOR x1 -> pic 
  [51] = 58,       -- 1 trainers: TRIATHLETE x1 -> pic 
  [52] = 59,       -- 3 trainers: TRIATHLETE x3 -> pic 
  [53] = 18,       -- 5 trainers: TUBER x5 -> pic 
  [54] = 19,       -- 4 trainers: TUBER x4 -> pic 
  [55] = 16,       -- 6 trainers: RUIN MANIAC x6 -> pic 
  [56] = 56,       -- 4 trainers: TRIATHLETE x4 -> pic 
  [57] = 57,       -- 3 trainers: TRIATHLETE x3 -> pic 
  [65] = 78,       -- 4 trainers: POKéMON BREEDER x2 -> pic ; YOUNG COUPLE x4 -> pic 
  [66] = 4,        -- 19 trainers: BIRD KEEPER x19 -> pic ; GUITARIST x7 -> pic ; KINDLER x9 -> pic 
  [68] = 17,       -- 8 trainers: INTERVIEWER x8 -> pic 
  [110] = 17,       -- 8 trainers: INTERVIEWER x8 -> pic 
  [117] = 1,        -- 16 trainers: TEAM AQUA x16 -> pic ; AQUA ADMIN x1 -> pic 
  [118] = 6,        -- 7 trainers: TEAM AQUA x7 -> pic ; AQUA ADMIN x2 -> pic 
  [119] = 8,        -- 18 trainers: TEAM MAGMA x18 -> pic ; MAGMA ADMIN x2 -> pic 
  [120] = 26,       -- 5 trainers: TEAM MAGMA x5 -> pic 
  [121] = 36,       -- 1 trainers: ELITE FOUR x1 -> pic 
  [122] = 37,       -- 1 trainers: ELITE FOUR x1 -> pic 
  [123] = 38,       -- 1 trainers: ELITE FOUR x1 -> pic 
  [124] = 39,       -- 1 trainers: ELITE FOUR x1 -> pic 
  [125] = 40,       -- 1 trainers: LEADER x1 -> pic 
  [126] = 41,       -- 1 trainers: LEADER x1 -> pic 
  [127] = 42,       -- 1 trainers: LEADER x1 -> pic 
  [128] = 43,       -- 1 trainers: LEADER x1 -> pic 
  [130] = 45,       -- 1 trainers: LEADER x1 -> pic 
  [131] = 46,       -- 1 trainers: LEADER x1 -> pic 
  [132] = 46,       -- 1 trainers: LEADER x1 -> pic 
  [134] = 81,       -- 1 trainers: POKéMON TRAINER x1 -> pic 
  [135] = 70,       -- 1 trainers: POKéMON TRAINER x1 -> pic 
  [196] = 76,       -- 2 trainers: MAGMA LEADER x2 -> pic 
  [213] = 80,       -- 3 trainers: SIS AND BRO x3 -> pic 
  [218] = 47,       -- 1 trainers: LEADER x1 -> pic 
}
