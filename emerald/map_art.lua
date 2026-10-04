-- Which PICTURE a shared Emerald overworld graphic means on a PARTICULAR map.
--
-- GENERATED -- do not hand-edit.  Regenerate with
--   luajit .probe/dp3_emit_emerald_map_art.lua \
--     pokemon-emerald-assets/emerald-cache gen3-dialogue-portraits-repo
-- from the engine's own Emerald extraction of the player's own ROM.
--
-- This is the EMERALD table.  It is NOT art/map_art.lua and the two are never
-- interchangeable: an Emerald graphics id, an Emerald map id and an Emerald
-- picture-number space are all their own.  The resolver picks one table or the
-- other by the running game id, never by falling back -- see emerald/init.lua.
--
-- A graphic is a uniform, not a person.  Emerald's OBJ_EVENT_GFX_* space is
-- worn by several trainer classes whose front pictures differ, so no single
-- value per graphic can be right for all of them.  The cart's EXACT answer for
-- a trainer is his own id, and emerald/trainer_ids.lua carries that; this table
-- answers for everyone else, and it answers by WHERE the graphic is standing.
--
-- Keys are the ENGINE's Emerald map ids (the spelling of `payload.mapId` from
-- the engine's own `map.entered` event), produced the same way the engine
-- builds them: the map's own `MAP_*` const, prefixed.  A value is the front-
-- picture id of the class that wears that graphic HERE, chosen by how many of
-- this map's trainers wear it; a graphic this map puts no trainer under is
-- ABSENT, and the caller falls through to emerald/gfx_art.lua.
--
-- 107 maps, 360 (map, graphic) pairs.  20 of those pairs are AMBIGUOUS -- two
-- or more classes wearing the one graphic on the one map -- and each is
-- decided by the majority; every one is listed below with its split.
--
-- The comment on each line names the class that won and the count, so a wrong
-- answer can be read off the file.
return {
  ["EM_ABANDONED_SHIP_CORRIDORS_1F"] = {
    [54] = 19,       -- TUBER -- 1 of this map's trainers
  },
  ["EM_ABANDONED_SHIP_CORRIDORS_B1F"] = {
    [49] = 68,       -- SAILOR -- 1 of this map's trainers
  },
  ["EM_ABANDONED_SHIP_ROOMS2_1F"] = {
    [26] = 78,       -- YOUNG COUPLE -- 1 of this map's trainers
    [53] = 18,       -- TUBER -- 1 of this map's trainers
    [55] = 16,       -- RUIN MANIAC -- 1 of this map's trainers
    [65] = 78,       -- YOUNG COUPLE -- 1 of this map's trainers
  },
  ["EM_ABANDONED_SHIP_ROOMS_1F"] = {
    [35] = 53,       -- YOUNGSTER -- 1 of this map's trainers
    [45] = 22,       -- BEAUTY -- 1 of this map's trainers
  },
  ["EM_AQUA_HIDEOUT_1F"] = {
    [117] = 1,        -- TEAM AQUA -- 1 of this map's trainers
  },
  ["EM_AQUA_HIDEOUT_B1F"] = {
    [117] = 1,        -- TEAM AQUA -- 2 of this map's trainers
    [118] = 6,        -- TEAM AQUA -- 2 of this map's trainers
  },
  ["EM_AQUA_HIDEOUT_B2F"] = {
    [117] = 1,        -- split, majority wins -- TEAM AQUA x2 -> pic 1; AQUA ADMIN x1 -> pic 10
    [118] = 6,        -- TEAM AQUA -- 1 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE01"] = {
    [5] = 68,       -- SAILOR -- 1 of this map's trainers
    [9] = 68,       -- SAILOR -- 1 of this map's trainers
    [14] = 68,       -- SAILOR -- 1 of this map's trainers
    [15] = 68,       -- SAILOR -- 1 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE02"] = {
    [6] = 68,       -- SAILOR -- 1 of this map's trainers
    [13] = 68,       -- SAILOR -- 1 of this map's trainers
    [17] = 68,       -- SAILOR -- 1 of this map's trainers
    [18] = 68,       -- SAILOR -- 1 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE03"] = {
    [7] = 68,       -- SAILOR -- 1 of this map's trainers
    [11] = 68,       -- SAILOR -- 1 of this map's trainers
    [33] = 68,       -- SAILOR -- 1 of this map's trainers
    [50] = 68,       -- SAILOR -- 1 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE04"] = {
    [8] = 68,       -- SAILOR -- 1 of this map's trainers
    [14] = 68,       -- SAILOR -- 1 of this map's trainers
    [15] = 68,       -- SAILOR -- 1 of this map's trainers
    [20] = 68,       -- SAILOR -- 1 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE05"] = {
    [9] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE06"] = {
    [10] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE07"] = {
    [11] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE08"] = {
    [12] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE09"] = {
    [12] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE10"] = {
    [14] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE11"] = {
    [15] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE12"] = {
    [16] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE13"] = {
    [17] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE14"] = {
    [18] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE15"] = {
    [18] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_BATTLE_PYRAMID_SQUARE16"] = {
    [18] = 68,       -- SAILOR -- 4 of this map's trainers
  },
  ["EM_DEWFORD_TOWN_GYM"] = {
    [14] = 64,       -- BATTLE GIRL -- 3 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 2 of this map's trainers
    [49] = 68,       -- SAILOR -- 1 of this map's trainers
    [126] = 41,       -- LEADER -- 1 of this map's trainers
  },
  ["EM_EVER_GRANDE_CITY_DRAKES_ROOM"] = {
    [124] = 39,       -- ELITE FOUR -- 1 of this map's trainers
  },
  ["EM_EVER_GRANDE_CITY_GLACIAS_ROOM"] = {
    [123] = 38,       -- ELITE FOUR -- 1 of this map's trainers
  },
  ["EM_EVER_GRANDE_CITY_PHOEBES_ROOM"] = {
    [122] = 37,       -- ELITE FOUR -- 1 of this map's trainers
  },
  ["EM_EVER_GRANDE_CITY_SIDNEYS_ROOM"] = {
    [121] = 36,       -- ELITE FOUR -- 1 of this map's trainers
  },
  ["EM_FORTREE_CITY_GYM"] = {
    [31] = 29,       -- CAMPER -- 1 of this map's trainers
    [32] = 30,       -- PICNICKER -- 1 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 4 of this map's trainers
    [130] = 45,       -- LEADER -- 1 of this map's trainers
  },
  ["EM_JAGGED_PASS"] = {
    [31] = 29,       -- CAMPER -- 1 of this map's trainers
    [32] = 30,       -- PICNICKER -- 2 of this map's trainers
    [56] = 56,       -- TRIATHLETE -- 1 of this map's trainers
    [119] = 8,        -- TEAM MAGMA -- 1 of this map's trainers
  },
  ["EM_LAVARIDGE_TOWN_GYM_1F"] = {
    [14] = 64,       -- BATTLE GIRL -- 1 of this map's trainers
    [33] = 3,        -- COOLTRAINER -- 1 of this map's trainers
    [66] = 28,       -- KINDLER -- 2 of this map's trainers
    [128] = 43,       -- LEADER -- 1 of this map's trainers
  },
  ["EM_LAVARIDGE_TOWN_GYM_B1F"] = {
    [66] = 28,       -- KINDLER -- 3 of this map's trainers
  },
  ["EM_MAGMA_HIDEOUT_1F"] = {
    [119] = 8,        -- TEAM MAGMA -- 2 of this map's trainers
  },
  ["EM_MAGMA_HIDEOUT_2F_1R"] = {
    [119] = 8,        -- TEAM MAGMA -- 3 of this map's trainers
    [120] = 26,       -- TEAM MAGMA -- 1 of this map's trainers
  },
  ["EM_MAGMA_HIDEOUT_2F_2R"] = {
    [119] = 8,        -- TEAM MAGMA -- 3 of this map's trainers
    [120] = 26,       -- TEAM MAGMA -- 1 of this map's trainers
  },
  ["EM_MAGMA_HIDEOUT_3F_1R"] = {
    [119] = 8,        -- TEAM MAGMA -- 1 of this map's trainers
    [120] = 26,       -- TEAM MAGMA -- 1 of this map's trainers
  },
  ["EM_MAGMA_HIDEOUT_3F_2R"] = {
    [119] = 8,        -- TEAM MAGMA -- 1 of this map's trainers
  },
  ["EM_MAGMA_HIDEOUT_4F"] = {
    [119] = 8,        -- split, majority wins -- TEAM MAGMA x3 -> pic 8; MAGMA ADMIN x1 -> pic 69
    [196] = 76,       -- MAGMA LEADER -- 1 of this map's trainers
  },
  ["EM_MAUVILLE_CITY_GYM"] = {
    [14] = 64,       -- BATTLE GIRL -- 1 of this map's trainers
    [35] = 53,       -- YOUNGSTER -- 1 of this map's trainers
    [39] = 31,       -- BUG MANIAC -- 1 of this map's trainers
    [66] = 27,       -- GUITARIST -- 2 of this map's trainers
    [127] = 42,       -- LEADER -- 1 of this map's trainers
  },
  ["EM_METEOR_FALLS_1F_2R"] = {
    [21] = 79,       -- OLD COUPLE -- 1 of this map's trainers
    [22] = 79,       -- OLD COUPLE -- 1 of this map's trainers
    [33] = 62,       -- DRAGON TAMER -- 1 of this map's trainers
  },
  ["EM_METEOR_FALLS_STEVENS_CAVE"] = {
    [134] = 81,       -- POKéMON TRAINER -- 1 of this map's trainers
  },
  ["EM_MOSSDEEP_CITY_GYM"] = {
    [37] = 33,       -- PSYCHIC -- 4 of this map's trainers
    [40] = 14,       -- HEX MANIAC -- 2 of this map's trainers
    [47] = 34,       -- PSYCHIC -- 4 of this map's trainers
    [48] = 35,       -- GENTLEMAN -- 2 of this map's trainers
    [131] = 46,       -- LEADER -- 1 of this map's trainers
    [132] = 46,       -- LEADER -- 1 of this map's trainers
  },
  ["EM_MOSSDEEP_CITY_SPACE_CENTER_1F"] = {
    [119] = 8,        -- TEAM MAGMA -- 3 of this map's trainers
    [120] = 26,       -- TEAM MAGMA -- 1 of this map's trainers
  },
  ["EM_MT_CHIMNEY"] = {
    [22] = 24,       -- EXPERT -- 1 of this map's trainers
    [45] = 22,       -- BEAUTY -- 3 of this map's trainers
    [119] = 8,        -- split, majority wins -- TEAM MAGMA x1 -> pic 8; MAGMA ADMIN x1 -> pic 69
    [120] = 26,       -- TEAM MAGMA -- 1 of this map's trainers
    [196] = 76,       -- MAGMA LEADER -- 1 of this map's trainers
  },
  ["EM_MT_PYRE_2F"] = {
    [26] = 78,       -- YOUNG COUPLE -- 1 of this map's trainers
    [39] = 25,       -- POKéMANIAC -- 1 of this map's trainers
    [40] = 14,       -- HEX MANIAC -- 1 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 1 of this map's trainers
    [65] = 78,       -- YOUNG COUPLE -- 1 of this map's trainers
  },
  ["EM_MT_PYRE_3F"] = {
    [20] = 2,        -- POKéMON BREEDER -- 1 of this map's trainers
    [37] = 33,       -- PSYCHIC -- 1 of this map's trainers
    [47] = 34,       -- PSYCHIC -- 1 of this map's trainers
  },
  ["EM_MT_PYRE_4F"] = {
    [40] = 14,       -- HEX MANIAC -- 1 of this map's trainers
  },
  ["EM_MT_PYRE_5F"] = {
    [44] = 11,       -- BLACK BELT -- 1 of this map's trainers
  },
  ["EM_MT_PYRE_6F"] = {
    [37] = 33,       -- PSYCHIC -- 1 of this map's trainers
    [40] = 14,       -- HEX MANIAC -- 1 of this map's trainers
  },
  ["EM_MT_PYRE_SUMMIT"] = {
    [117] = 1,        -- TEAM AQUA -- 3 of this map's trainers
    [118] = 6,        -- TEAM AQUA -- 1 of this map's trainers
  },
  ["EM_PETALBURG_CITY_GYM"] = {
    [33] = 3,        -- COOLTRAINER -- 4 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 3 of this map's trainers
  },
  ["EM_PETALBURG_WOODS"] = {
    [36] = 73,       -- BUG CATCHER -- 2 of this map's trainers
  },
  ["EM_ROUTE_102"] = {
    [35] = 53,       -- YOUNGSTER -- 2 of this map's trainers
    [36] = 73,       -- BUG CATCHER -- 1 of this map's trainers
    [47] = 77,       -- LASS -- 1 of this map's trainers
  },
  ["EM_ROUTE_103"] = {
    [6] = 67,       -- TWINS -- 2 of this map's trainers
    [20] = 15,       -- AROMA LADY -- 1 of this map's trainers
    [25] = 51,       -- POKéFAN -- 1 of this map's trainers
    [42] = 7,        -- SWIMMER♂ -- 1 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 1 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 1 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 1 of this map's trainers
    [66] = 27,       -- GUITARIST -- 1 of this map's trainers
  },
  ["EM_ROUTE_104"] = {
    [6] = 67,       -- TWINS -- 2 of this map's trainers
    [15] = 23,       -- RICH BOY -- 1 of this map's trainers
    [20] = 21,       -- LADY -- 1 of this map's trainers
    [35] = 53,       -- YOUNGSTER -- 1 of this map's trainers
    [47] = 77,       -- LASS -- 1 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 2 of this map's trainers
  },
  ["EM_ROUTE_105"] = {
    [42] = 7,        -- SWIMMER♂ -- 2 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 2 of this map's trainers
    [55] = 16,       -- RUIN MANIAC -- 2 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 1 of this map's trainers
  },
  ["EM_ROUTE_106"] = {
    [42] = 7,        -- SWIMMER♂ -- 1 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 1 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 2 of this map's trainers
  },
  ["EM_ROUTE_107"] = {
    [42] = 7,        -- split, majority wins -- SWIMMER♂ x2 -> pic 7; TRIATHLETE x1 -> pic 60
    [43] = 66,       -- split, majority wins -- SWIMMER♀ x2 -> pic 66; SIS AND BRO x1 -> pic 80
    [213] = 80,       -- SIS AND BRO -- 1 of this map's trainers
  },
  ["EM_ROUTE_108"] = {
    [34] = 20,       -- COOLTRAINER -- 1 of this map's trainers
    [42] = 7,        -- SWIMMER♂ -- 2 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 2 of this map's trainers
    [49] = 68,       -- SAILOR -- 1 of this map's trainers
  },
  ["EM_ROUTE_109"] = {
    [26] = 78,       -- YOUNG COUPLE -- 1 of this map's trainers
    [42] = 7,        -- SWIMMER♂ -- 1 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 1 of this map's trainers
    [49] = 68,       -- SAILOR -- 2 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 1 of this map's trainers
    [53] = 18,       -- TUBER -- 4 of this map's trainers
    [54] = 19,       -- TUBER -- 2 of this map's trainers
    [65] = 78,       -- YOUNG COUPLE -- 1 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 1 of this map's trainers
  },
  ["EM_ROUTE_109_SEASHORE_HOUSE"] = {
    [45] = 22,       -- BEAUTY -- 1 of this map's trainers
    [49] = 68,       -- SAILOR -- 1 of this map's trainers
    [54] = 19,       -- TUBER -- 1 of this map's trainers
  },
  ["EM_ROUTE_110"] = {
    [18] = 52,       -- POKéFAN -- 1 of this map's trainers
    [25] = 51,       -- POKéFAN -- 1 of this map's trainers
    [35] = 53,       -- YOUNGSTER -- 1 of this map's trainers
    [37] = 33,       -- PSYCHIC -- 1 of this map's trainers
    [39] = 5,        -- COLLECTOR -- 1 of this map's trainers
    [47] = 34,       -- PSYCHIC -- 1 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 1 of this map's trainers
    [56] = 56,       -- TRIATHLETE -- 3 of this map's trainers
    [57] = 57,       -- TRIATHLETE -- 3 of this map's trainers
    [66] = 27,       -- GUITARIST -- 1 of this map's trainers
  },
  ["EM_ROUTE_110_TRICK_HOUSE_PUZZLE1"] = {
    [35] = 53,       -- YOUNGSTER -- 1 of this map's trainers
    [47] = 77,       -- LASS -- 2 of this map's trainers
  },
  ["EM_ROUTE_110_TRICK_HOUSE_PUZZLE2"] = {
    [14] = 49,       -- SCHOOL KID -- 1 of this map's trainers
    [38] = 48,       -- SCHOOL KID -- 2 of this map's trainers
  },
  ["EM_ROUTE_110_TRICK_HOUSE_PUZZLE3"] = {
    [31] = 29,       -- CAMPER -- 1 of this map's trainers
    [32] = 30,       -- PICNICKER -- 1 of this map's trainers
  },
  ["EM_ROUTE_110_TRICK_HOUSE_PUZZLE4"] = {
    [14] = 64,       -- BATTLE GIRL -- 2 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 1 of this map's trainers
  },
  ["EM_ROUTE_110_TRICK_HOUSE_PUZZLE6"] = {
    [31] = 74,       -- POKéMON RANGER -- 1 of this map's trainers
    [32] = 75,       -- POKéMON RANGER -- 1 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 1 of this map's trainers
  },
  ["EM_ROUTE_110_TRICK_HOUSE_PUZZLE7"] = {
    [37] = 33,       -- PSYCHIC -- 2 of this map's trainers
    [40] = 14,       -- HEX MANIAC -- 1 of this map's trainers
    [47] = 34,       -- PSYCHIC -- 2 of this map's trainers
    [48] = 35,       -- GENTLEMAN -- 1 of this map's trainers
  },
  ["EM_ROUTE_110_TRICK_HOUSE_PUZZLE8"] = {
    [33] = 3,        -- COOLTRAINER -- 2 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 1 of this map's trainers
  },
  ["EM_ROUTE_111"] = {
    [20] = 15,       -- AROMA LADY -- 1 of this map's trainers
    [31] = 29,       -- CAMPER -- 5 of this map's trainers
    [32] = 30,       -- PICNICKER -- 5 of this map's trainers
    [33] = 3,        -- COOLTRAINER -- 1 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 1 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 1 of this map's trainers
    [55] = 16,       -- RUIN MANIAC -- 2 of this map's trainers
    [66] = 28,       -- KINDLER -- 1 of this map's trainers
    [68] = 17,       -- INTERVIEWER -- 3 of this map's trainers
    [110] = 17,       -- INTERVIEWER -- 3 of this map's trainers
  },
  ["EM_ROUTE_112"] = {
    [20] = 15,       -- AROMA LADY -- 1 of this map's trainers
    [31] = 29,       -- CAMPER -- 1 of this map's trainers
    [32] = 30,       -- PICNICKER -- 1 of this map's trainers
    [66] = 28,       -- KINDLER -- 1 of this map's trainers
  },
  ["EM_ROUTE_113"] = {
    [5] = 63,       -- NINJA BOY -- 2 of this map's trainers
    [6] = 67,       -- TWINS -- 2 of this map's trainers
    [31] = 29,       -- CAMPER -- 1 of this map's trainers
    [32] = 30,       -- PICNICKER -- 1 of this map's trainers
    [34] = 65,       -- PARASOL LADY -- 1 of this map's trainers
    [35] = 53,       -- YOUNGSTER -- 2 of this map's trainers
    [39] = 25,       -- POKéMANIAC -- 1 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 1 of this map's trainers
  },
  ["EM_ROUTE_114"] = {
    [31] = 29,       -- CAMPER -- 1 of this map's trainers
    [32] = 30,       -- PICNICKER -- 3 of this map's trainers
    [39] = 25,       -- POKéMANIAC -- 1 of this map's trainers
    [47] = 50,       -- SR. AND JR. -- 2 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 3 of this map's trainers
    [66] = 28,       -- KINDLER -- 1 of this map's trainers
  },
  ["EM_ROUTE_115"] = {
    [5] = 63,       -- NINJA BOY -- 1 of this map's trainers
    [14] = 64,       -- BATTLE GIRL -- 2 of this map's trainers
    [21] = 9,        -- EXPERT -- 1 of this map's trainers
    [39] = 5,        -- COLLECTOR -- 1 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 2 of this map's trainers
    [47] = 34,       -- PSYCHIC -- 2 of this map's trainers
    [52] = 59,       -- TRIATHLETE -- 1 of this map's trainers
  },
  ["EM_ROUTE_116"] = {
    [9] = 23,       -- RICH BOY -- 1 of this map's trainers
    [14] = 49,       -- SCHOOL KID -- 1 of this map's trainers
    [20] = 21,       -- LADY -- 1 of this map's trainers
    [35] = 53,       -- YOUNGSTER -- 2 of this map's trainers
    [36] = 73,       -- BUG CATCHER -- 1 of this map's trainers
    [38] = 48,       -- SCHOOL KID -- 1 of this map's trainers
    [47] = 77,       -- LASS -- 1 of this map's trainers
  },
  ["EM_ROUTE_117"] = {
    [14] = 64,       -- BATTLE GIRL -- 1 of this map's trainers
    [20] = 2,        -- POKéMON BREEDER -- 1 of this map's trainers
    [39] = 31,       -- BUG MANIAC -- 1 of this map's trainers
    [47] = 50,       -- split, majority wins -- PSYCHIC x1 -> pic 34; SR. AND JR. x2 -> pic 50
    [51] = 58,       -- TRIATHLETE -- 1 of this map's trainers
    [52] = 59,       -- TRIATHLETE -- 2 of this map's trainers
    [65] = 32,       -- POKéMON BREEDER -- 1 of this map's trainers
  },
  ["EM_ROUTE_118"] = {
    [20] = 15,       -- AROMA LADY -- 1 of this map's trainers
    [35] = 53,       -- YOUNGSTER -- 1 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 2 of this map's trainers
    [66] = 4,        -- split, majority wins -- BIRD KEEPER x2 -> pic 4; GUITARIST x1 -> pic 27
    [68] = 17,       -- INTERVIEWER -- 3 of this map's trainers
    [110] = 17,       -- INTERVIEWER -- 3 of this map's trainers
  },
  ["EM_ROUTE_119"] = {
    [5] = 63,       -- NINJA BOY -- 3 of this map's trainers
    [20] = 65,       -- PARASOL LADY -- 1 of this map's trainers
    [31] = 74,       -- POKéMON RANGER -- 1 of this map's trainers
    [32] = 75,       -- POKéMON RANGER -- 1 of this map's trainers
    [36] = 73,       -- BUG CATCHER -- 3 of this map's trainers
    [39] = 31,       -- BUG MANIAC -- 3 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 1 of this map's trainers
    [66] = 4,        -- split, majority wins -- BIRD KEEPER x2 -> pic 4; GUITARIST x1 -> pic 27; KINDLER x1 -> pic 28
  },
  ["EM_ROUTE_119_WEATHER_INSTITUTE_1F"] = {
    [117] = 1,        -- TEAM AQUA -- 1 of this map's trainers
    [118] = 6,        -- TEAM AQUA -- 1 of this map's trainers
  },
  ["EM_ROUTE_119_WEATHER_INSTITUTE_2F"] = {
    [117] = 1,        -- TEAM AQUA -- 2 of this map's trainers
    [118] = 6,        -- split, majority wins -- TEAM AQUA x1 -> pic 6; AQUA ADMIN x1 -> pic 12
  },
  ["EM_ROUTE_120"] = {
    [5] = 63,       -- NINJA BOY -- 2 of this map's trainers
    [14] = 64,       -- BATTLE GIRL -- 1 of this map's trainers
    [31] = 74,       -- POKéMON RANGER -- 1 of this map's trainers
    [32] = 75,       -- POKéMON RANGER -- 1 of this map's trainers
    [33] = 3,        -- COOLTRAINER -- 1 of this map's trainers
    [34] = 65,       -- split, majority wins -- COOLTRAINER x1 -> pic 20; PARASOL LADY x2 -> pic 65
    [39] = 31,       -- BUG MANIAC -- 1 of this map's trainers
    [55] = 16,       -- RUIN MANIAC -- 1 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 2 of this map's trainers
    [68] = 17,       -- INTERVIEWER -- 2 of this map's trainers
    [110] = 17,       -- INTERVIEWER -- 2 of this map's trainers
  },
  ["EM_ROUTE_121"] = {
    [18] = 52,       -- POKéFAN -- 1 of this map's trainers
    [20] = 2,        -- POKéMON BREEDER -- 1 of this map's trainers
    [33] = 3,        -- COOLTRAINER -- 1 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 1 of this map's trainers
    [39] = 31,       -- BUG MANIAC -- 1 of this map's trainers
    [40] = 14,       -- HEX MANIAC -- 1 of this map's trainers
    [45] = 22,       -- BEAUTY -- 1 of this map's trainers
    [47] = 50,       -- SR. AND JR. -- 2 of this map's trainers
    [48] = 35,       -- GENTLEMAN -- 1 of this map's trainers
    [65] = 32,       -- POKéMON BREEDER -- 1 of this map's trainers
  },
  ["EM_ROUTE_123"] = {
    [5] = 63,       -- NINJA BOY -- 1 of this map's trainers
    [6] = 67,       -- TWINS -- 2 of this map's trainers
    [20] = 15,       -- split, majority wins -- AROMA LADY x1 -> pic 15; PARASOL LADY x1 -> pic 65
    [21] = 9,        -- EXPERT -- 1 of this map's trainers
    [33] = 3,        -- COOLTRAINER -- 1 of this map's trainers
    [34] = 20,       -- split, majority wins -- COOLTRAINER x1 -> pic 20; COOLTRAINER x1 -> pic 20
    [35] = 73,       -- BUG CATCHER -- 1 of this map's trainers
    [37] = 33,       -- PSYCHIC -- 1 of this map's trainers
    [39] = 5,        -- COLLECTOR -- 1 of this map's trainers
    [40] = 14,       -- HEX MANIAC -- 1 of this map's trainers
    [47] = 34,       -- PSYCHIC -- 1 of this map's trainers
    [66] = 4,        -- split, majority wins -- BIRD KEEPER x1 -> pic 4; GUITARIST x1 -> pic 27
  },
  ["EM_ROUTE_124"] = {
    [42] = 7,        -- SWIMMER♂ -- 4 of this map's trainers
    [43] = 66,       -- split, majority wins -- TRIATHLETE x1 -> pic 61; SWIMMER♀ x2 -> pic 66; SIS AND BRO x1 -> pic 80
    [213] = 80,       -- SIS AND BRO -- 1 of this map's trainers
  },
  ["EM_ROUTE_125"] = {
    [21] = 9,        -- EXPERT -- 1 of this map's trainers
    [42] = 7,        -- SWIMMER♂ -- 2 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 2 of this map's trainers
    [47] = 50,       -- SR. AND JR. -- 2 of this map's trainers
    [49] = 68,       -- SAILOR -- 1 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 1 of this map's trainers
  },
  ["EM_ROUTE_126"] = {
    [42] = 7,        -- split, majority wins -- SWIMMER♂ x3 -> pic 7; TRIATHLETE x1 -> pic 60
    [43] = 66,       -- split, majority wins -- TRIATHLETE x1 -> pic 61; SWIMMER♀ x3 -> pic 66
  },
  ["EM_ROUTE_127"] = {
    [34] = 20,       -- COOLTRAINER -- 1 of this map's trainers
    [42] = 60,       -- TRIATHLETE -- 1 of this map's trainers
    [43] = 61,       -- TRIATHLETE -- 1 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 1 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 3 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 1 of this map's trainers
  },
  ["EM_ROUTE_128"] = {
    [33] = 3,        -- COOLTRAINER -- 1 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 1 of this map's trainers
    [42] = 7,        -- split, majority wins -- SWIMMER♂ x1 -> pic 7; TRIATHLETE x1 -> pic 60
    [43] = 61,       -- split, majority wins -- TRIATHLETE x1 -> pic 61; SWIMMER♀ x1 -> pic 66
    [50] = 55,       -- FISHERMAN -- 1 of this map's trainers
  },
  ["EM_ROUTE_129"] = {
    [42] = 7,        -- split, majority wins -- SWIMMER♂ x2 -> pic 7; TRIATHLETE x1 -> pic 60
    [43] = 61,       -- split, majority wins -- TRIATHLETE x1 -> pic 61; SWIMMER♀ x1 -> pic 66
  },
  ["EM_ROUTE_130"] = {
    [42] = 7,        -- SWIMMER♂ -- 2 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 1 of this map's trainers
  },
  ["EM_ROUTE_131"] = {
    [42] = 7,        -- SWIMMER♂ -- 3 of this map's trainers
    [43] = 66,       -- split, majority wins -- TRIATHLETE x1 -> pic 61; SWIMMER♀ x2 -> pic 66; SIS AND BRO x1 -> pic 80
    [213] = 80,       -- SIS AND BRO -- 1 of this map's trainers
  },
  ["EM_ROUTE_132"] = {
    [21] = 9,        -- EXPERT -- 1 of this map's trainers
    [22] = 24,       -- EXPERT -- 1 of this map's trainers
    [33] = 3,        -- COOLTRAINER -- 1 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 1 of this map's trainers
    [42] = 7,        -- SWIMMER♂ -- 1 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 1 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 1 of this map's trainers
    [50] = 55,       -- FISHERMAN -- 1 of this map's trainers
  },
  ["EM_ROUTE_133"] = {
    [21] = 9,        -- EXPERT -- 1 of this map's trainers
    [22] = 24,       -- EXPERT -- 1 of this map's trainers
    [33] = 3,        -- COOLTRAINER -- 1 of this map's trainers
    [42] = 7,        -- SWIMMER♂ -- 1 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 2 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 1 of this map's trainers
  },
  ["EM_ROUTE_134"] = {
    [14] = 64,       -- BATTLE GIRL -- 1 of this map's trainers
    [33] = 62,       -- DRAGON TAMER -- 1 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 1 of this map's trainers
    [42] = 7,        -- SWIMMER♂ -- 1 of this map's trainers
    [43] = 66,       -- SWIMMER♀ -- 1 of this map's trainers
    [44] = 11,       -- BLACK BELT -- 1 of this map's trainers
    [49] = 68,       -- SAILOR -- 2 of this map's trainers
    [66] = 4,        -- BIRD KEEPER -- 1 of this map's trainers
  },
  ["EM_RUSTBORO_CITY_GYM"] = {
    [35] = 53,       -- YOUNGSTER -- 2 of this map's trainers
    [125] = 40,       -- LEADER -- 1 of this map's trainers
  },
  ["EM_RUSTURF_TUNNEL"] = {
    [117] = 1,        -- TEAM AQUA -- 1 of this map's trainers
  },
  ["EM_SEAFLOOR_CAVERN_ROOM1"] = {
    [117] = 1,        -- TEAM AQUA -- 2 of this map's trainers
  },
  ["EM_SEAFLOOR_CAVERN_ROOM3"] = {
    [117] = 1,        -- TEAM AQUA -- 1 of this map's trainers
    [118] = 12,       -- AQUA ADMIN -- 1 of this map's trainers
  },
  ["EM_SEAFLOOR_CAVERN_ROOM4"] = {
    [117] = 1,        -- TEAM AQUA -- 1 of this map's trainers
    [118] = 6,        -- TEAM AQUA -- 1 of this map's trainers
  },
  ["EM_SLATEPORT_CITY_OCEANIC_MUSEUM_2F"] = {
    [46] = 1,        -- TEAM AQUA -- 1 of this map's trainers
  },
  ["EM_SOOTOPOLIS_CITY_GYM_1F"] = {
    [218] = 47,       -- LEADER -- 1 of this map's trainers
  },
  ["EM_SOOTOPOLIS_CITY_GYM_B1F"] = {
    [18] = 52,       -- POKéFAN -- 2 of this map's trainers
    [20] = 21,       -- LADY -- 2 of this map's trainers
    [45] = 22,       -- BEAUTY -- 4 of this map's trainers
    [47] = 77,       -- LASS -- 2 of this map's trainers
  },
  ["EM_SSTIDAL_LOWER_DECK"] = {
    [49] = 68,       -- SAILOR -- 2 of this map's trainers
  },
  ["EM_SSTIDAL_ROOMS"] = {
    [15] = 23,       -- RICH BOY -- 1 of this map's trainers
    [20] = 21,       -- LADY -- 1 of this map's trainers
    [25] = 51,       -- POKéFAN -- 1 of this map's trainers
    [26] = 78,       -- YOUNG COUPLE -- 1 of this map's trainers
    [48] = 35,       -- GENTLEMAN -- 2 of this map's trainers
    [65] = 78,       -- YOUNG COUPLE -- 1 of this map's trainers
  },
  ["EM_VICTORY_ROAD_1F"] = {
    [33] = 3,        -- COOLTRAINER -- 3 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 2 of this map's trainers
    [135] = 70,       -- POKéMON TRAINER -- 1 of this map's trainers
  },
  ["EM_VICTORY_ROAD_B1F"] = {
    [33] = 3,        -- COOLTRAINER -- 2 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 3 of this map's trainers
  },
  ["EM_VICTORY_ROAD_B2F"] = {
    [33] = 3,        -- COOLTRAINER -- 3 of this map's trainers
    [34] = 20,       -- COOLTRAINER -- 3 of this map's trainers
  },
}
