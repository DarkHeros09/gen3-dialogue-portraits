-- Which PICTURE a shared overworld graphic means on a PARTICULAR map.
--
-- GENERATED -- do not hand-edit.  Regenerate with
--   luajit .probe/dp3_emit_map_art.lua gen1recomp gen3-dialogue-portraits
-- from the same ROM the engine extracts its map events from.
--
-- A graphic is a uniform, not a person.  OBJ_EVENT_GFX_ROCKER is worn by 28
-- trainer objects -- 18 Bird Keepers, 9 Jugglers and 1 Rocker -- and those
-- three classes wear three DIFFERENT pictures (104, 102, 101).  Sixteen of
-- the 34 graphics a trainer can wear are shared that way, so no single value
-- per graphic can be right for all of them, and a table that gives one is
-- wrong for every class but the majority.
--
-- The cart's exact answer for a TRAINER is his own id, and
-- art/trainer_ids.lua carries that; it runs before this table.  This table
-- answers for everyone else, and it answers the way the report asked for:
-- by WHERE the graphic is standing.
--
-- Keys are the ENGINE's map ids (the spelling of `payload.mapId` from the
-- engine's own `map.entered` event), produced by the engine's own
-- MapCatalog.pretToEngine -- not by re-deriving the name mangling here.
--
-- A value is the front-picture id of the class that wears that graphic HERE,
-- chosen by how many of this map's trainers wear it.  A graphic this map
-- does not put a trainer under is ABSENT, and the caller falls through to
-- GFX_ART, which is the answer for a graphic no trainer on this map wears.
--
-- 91 maps, 228 (map, graphic) pairs.  11 of those pairs are AMBIGUOUS -- two
-- or more classes wearing the one graphic on the one map -- and each is
-- decided by the majority; every one is listed below with its split.
--
-- The comment on each line names the class that won and the count, so a
-- wrong answer can be read off the file.
return {
  ["FR_CELADON_CITY_GAME_CORNER"] = {
    [49] = 109,      -- TEAM ROCKET -- 1 of this map's trainers
  },
  ["FR_CELADON_CITY_GYM"] = {
    [22] = 84,       -- LASS -- 2 of this map's trainers
    [29] = 98,       -- BEAUTY -- 3 of this map's trainers
    [40] = 87,       -- PICNICKER -- 1 of this map's trainers
    [42] = 111,      -- COOLTRAINER -- 1 of this map's trainers
  },
  ["FR_CERULEAN_CITY_GYM"] = {
    [40] = 87,       -- PICNICKER -- 1 of this map's trainers
    [43] = 95,       -- SWIMMER♂ -- 1 of this map's trainers
  },
  ["FR_CINNABAR_ISLAND_GYM"] = {
    [52] = 92,       -- BURGLAR -- 3 of this map's trainers
    [55] = 89,       -- SUPER NERD -- 4 of this map's trainers
  },
  ["FR_FIVE_ISLAND_LOST_CAVE_ROOM1"] = {
    [56] = 145,      -- RUIN MANIAC -- 1 of this map's trainers
  },
  ["FR_FIVE_ISLAND_LOST_CAVE_ROOM4"] = {
    [23] = 138,      -- PSYCHIC -- 1 of this map's trainers
  },
  ["FR_FIVE_ISLAND_MEADOW"] = {
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
    [50] = 137,      -- TEAM ROCKET -- 1 of this map's trainers
  },
  ["FR_FIVE_ISLAND_MEMORIAL_PILLAR"] = {
    [26] = 104,      -- BIRD KEEPER -- 3 of this map's trainers
  },
  ["FR_FIVE_ISLAND_RESORT_GORGEOUS"] = {
    [18] = 82,       -- YOUNGSTER -- 1 of this map's trainers
    [22] = 147,      -- PAINTER -- 3 of this map's trainers
    [28] = 146,      -- LADY -- 2 of this map's trainers
    [43] = 95,       -- SWIMMER♂ -- 1 of this map's trainers
  },
  ["FR_FIVE_ISLAND_ROCKET_WAREHOUSE"] = {
    [49] = 109,      -- TEAM ROCKET -- 3 of this map's trainers
    [50] = 137,      -- TEAM ROCKET -- 2 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_FIVE_ISLAND_WATER_LABYRINTH"] = {
    [28] = 141,      -- POKéMON BREEDER -- 1 of this map's trainers
  },
  ["FR_FUCHSIA_CITY_GYM"] = {
    [25] = 103,      -- TAMER -- 2 of this map's trainers
    [26] = 102,      -- JUGGLER -- 4 of this map's trainers
  },
  ["FR_MT_EMBER_EXTERIOR"] = {
    [24] = 139,      -- CRUSH GIRL -- 1 of this map's trainers
    [39] = 142,      -- POKéMON RANGER -- 1 of this map's trainers
    [40] = 143,      -- POKéMON RANGER -- 1 of this map's trainers
  },
  ["FR_MT_MOON_1F"] = {
    [18] = 82,       -- YOUNGSTER -- 1 of this map's trainers
    [20] = 83,       -- BUG CATCHER -- 2 of this map's trainers
    [22] = 84,       -- LASS -- 2 of this map's trainers
    [55] = 89,       -- SUPER NERD -- 1 of this map's trainers
    [56] = 90,       -- HIKER -- 1 of this map's trainers
  },
  ["FR_MT_MOON_B2F"] = {
    [49] = 109,      -- TEAM ROCKET -- 4 of this map's trainers
  },
  ["FR_PEWTER_CITY_GYM"] = {
    [39] = 86,       -- CAMPER -- 1 of this map's trainers
  },
  ["FR_POKEMON_MANSION_1F"] = {
    [18] = 82,       -- YOUNGSTER -- 1 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_POKEMON_MANSION_2F"] = {
    [52] = 92,       -- BURGLAR -- 1 of this map's trainers
  },
  ["FR_POKEMON_MANSION_3F"] = {
    [52] = 92,       -- BURGLAR -- 1 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_POKEMON_MANSION_B1F"] = {
    [52] = 92,       -- BURGLAR -- 1 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_POKEMON_TOWER_3F"] = {
    [58] = 126,      -- CHANNELER -- 3 of this map's trainers
  },
  ["FR_POKEMON_TOWER_4F"] = {
    [58] = 126,      -- CHANNELER -- 3 of this map's trainers
  },
  ["FR_POKEMON_TOWER_5F"] = {
    [58] = 126,      -- CHANNELER -- 4 of this map's trainers
  },
  ["FR_POKEMON_TOWER_6F"] = {
    [58] = 126,      -- CHANNELER -- 3 of this map's trainers
  },
  ["FR_POKEMON_TOWER_7F"] = {
    [49] = 109,      -- TEAM ROCKET -- 3 of this map's trainers
  },
  ["FR_ROCKET_HIDEOUT_B1F"] = {
    [49] = 109,      -- TEAM ROCKET -- 5 of this map's trainers
  },
  ["FR_ROCKET_HIDEOUT_B2F"] = {
    [49] = 109,      -- TEAM ROCKET -- 1 of this map's trainers
  },
  ["FR_ROCKET_HIDEOUT_B3F"] = {
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
  },
  ["FR_ROCKET_HIDEOUT_B4F"] = {
    [49] = 109,      -- TEAM ROCKET -- 3 of this map's trainers
  },
  ["FR_ROCK_TUNNEL_1F"] = {
    [40] = 87,       -- PICNICKER -- 3 of this map's trainers
    [52] = 88,       -- POKéMANIAC -- 1 of this map's trainers
    [56] = 90,       -- HIKER -- 3 of this map's trainers
  },
  ["FR_ROCK_TUNNEL_B1F"] = {
    [40] = 87,       -- PICNICKER -- 2 of this map's trainers
    [52] = 88,       -- POKéMANIAC -- 3 of this map's trainers
    [56] = 90,       -- HIKER -- 3 of this map's trainers
  },
  ["FR_ROUTE_10"] = {
    [40] = 87,       -- PICNICKER -- 2 of this map's trainers
    [52] = 88,       -- POKéMANIAC -- 2 of this map's trainers
    [56] = 90,       -- HIKER -- 2 of this map's trainers
  },
  ["FR_ROUTE_11"] = {
    [18] = 82,       -- YOUNGSTER -- 4 of this map's trainers
    [30] = 93,       -- ENGINEER -- 2 of this map's trainers
    [32] = 97,       -- GAMER -- 4 of this map's trainers
  },
  ["FR_ROUTE_12"] = {
    [25] = 129,      -- YOUNG COUPLE -- 1 of this map's trainers
    [26] = 101,      -- ROCKER -- 1 of this map's trainers
    [29] = 129,      -- YOUNG COUPLE -- 1 of this map's trainers
    [39] = 86,       -- CAMPER -- 1 of this map's trainers
    [57] = 94,       -- FISHERMAN -- 5 of this map's trainers
  },
  ["FR_ROUTE_13"] = {
    [26] = 104,      -- BIRD KEEPER -- 3 of this map's trainers
    [29] = 98,       -- BEAUTY -- 2 of this map's trainers
    [40] = 87,       -- PICNICKER -- 4 of this map's trainers
    [53] = 91,       -- BIKER -- 1 of this map's trainers
  },
  ["FR_ROUTE_14"] = {
    [17] = 127,      -- TWINS -- 2 of this map's trainers
    [26] = 104,      -- BIRD KEEPER -- 6 of this map's trainers
    [53] = 91,       -- BIKER -- 4 of this map's trainers
  },
  ["FR_ROUTE_15"] = {
    [24] = 130,      -- CRUSH KIN -- 1 of this map's trainers
    [26] = 104,      -- BIRD KEEPER -- 2 of this map's trainers
    [29] = 98,       -- BEAUTY -- 2 of this map's trainers
    [40] = 87,       -- PICNICKER -- 4 of this map's trainers
    [53] = 91,       -- BIKER -- 2 of this map's trainers
    [54] = 130,      -- CRUSH KIN -- 1 of this map's trainers
  },
  ["FR_ROUTE_16"] = {
    [25] = 129,      -- YOUNG COUPLE -- 1 of this map's trainers
    [29] = 129,      -- YOUNG COUPLE -- 1 of this map's trainers
    [53] = 91,       -- split, majority wins -- BIKER x3 -> pic 91; CUE BALL x3 -> pic 96
  },
  ["FR_ROUTE_17"] = {
    [53] = 91,       -- split, majority wins -- BIKER x5 -> pic 91; CUE BALL x5 -> pic 96
  },
  ["FR_ROUTE_18"] = {
    [26] = 104,      -- BIRD KEEPER -- 3 of this map's trainers
  },
  ["FR_ROUTE_19"] = {
    [36] = 131,      -- SIS AND BRO -- 1 of this map's trainers
    [43] = 95,       -- SWIMMER♂ -- 5 of this map's trainers
    [44] = 99,       -- split, majority wins -- SWIMMER♀ x3 -> pic 99; SIS AND BRO x1 -> pic 131
    [45] = 95,       -- SWIMMER♂ -- 2 of this map's trainers
  },
  ["FR_ROUTE_20"] = {
    [26] = 104,      -- BIRD KEEPER -- 1 of this map's trainers
    [40] = 87,       -- PICNICKER -- 2 of this map's trainers
    [43] = 95,       -- SWIMMER♂ -- 3 of this map's trainers
    [44] = 99,       -- SWIMMER♀ -- 4 of this map's trainers
  },
  ["FR_ROUTE_21_NORTH"] = {
    [36] = 131,      -- SIS AND BRO -- 1 of this map's trainers
    [43] = 95,       -- SWIMMER♂ -- 1 of this map's trainers
    [44] = 131,      -- SIS AND BRO -- 1 of this map's trainers
    [57] = 94,       -- FISHERMAN -- 2 of this map's trainers
  },
  ["FR_ROUTE_21_SOUTH"] = {
    [43] = 95,       -- SWIMMER♂ -- 3 of this map's trainers
    [57] = 94,       -- FISHERMAN -- 2 of this map's trainers
  },
  ["FR_ROUTE_24"] = {
    [18] = 82,       -- YOUNGSTER -- 1 of this map's trainers
    [20] = 83,       -- BUG CATCHER -- 1 of this map's trainers
    [22] = 84,       -- LASS -- 2 of this map's trainers
    [39] = 86,       -- CAMPER -- 2 of this map's trainers
  },
  ["FR_ROUTE_25"] = {
    [18] = 82,       -- YOUNGSTER -- 3 of this map's trainers
    [22] = 84,       -- LASS -- 1 of this map's trainers
    [39] = 86,       -- CAMPER -- 1 of this map's trainers
    [40] = 87,       -- PICNICKER -- 1 of this map's trainers
    [56] = 90,       -- HIKER -- 3 of this map's trainers
  },
  ["FR_ROUTE_3"] = {
    [18] = 82,       -- YOUNGSTER -- 2 of this map's trainers
    [20] = 83,       -- BUG CATCHER -- 3 of this map's trainers
    [22] = 84,       -- LASS -- 3 of this map's trainers
  },
  ["FR_ROUTE_4"] = {
    [22] = 84,       -- LASS -- 1 of this map's trainers
  },
  ["FR_ROUTE_6"] = {
    [20] = 83,       -- BUG CATCHER -- 2 of this map's trainers
    [39] = 86,       -- CAMPER -- 2 of this map's trainers
    [40] = 87,       -- PICNICKER -- 2 of this map's trainers
  },
  ["FR_ROUTE_8"] = {
    [17] = 127,      -- TWINS -- 2 of this map's trainers
    [22] = 84,       -- LASS -- 4 of this map's trainers
    [32] = 97,       -- GAMER -- 2 of this map's trainers
    [53] = 91,       -- BIKER -- 2 of this map's trainers
    [55] = 89,       -- SUPER NERD -- 3 of this map's trainers
  },
  ["FR_ROUTE_9"] = {
    [20] = 83,       -- BUG CATCHER -- 2 of this map's trainers
    [39] = 86,       -- CAMPER -- 2 of this map's trainers
    [40] = 87,       -- PICNICKER -- 2 of this map's trainers
    [56] = 90,       -- HIKER -- 3 of this map's trainers
  },
  ["FR_SAFFRON_CITY_DOJO"] = {
    [54] = 105,      -- BLACK BELT -- 5 of this map's trainers
  },
  ["FR_SAFFRON_CITY_GYM"] = {
    [41] = 100,      -- PSYCHIC -- 4 of this map's trainers
    [58] = 126,      -- CHANNELER -- 3 of this map's trainers
  },
  ["FR_SEVEN_ISLAND_SEVAULT_CANYON"] = {
    [24] = 139,      -- CRUSH GIRL -- 1 of this map's trainers
    [25] = 103,      -- TAMER -- 1 of this map's trainers
    [39] = 142,      -- POKéMON RANGER -- 1 of this map's trainers
    [40] = 143,      -- POKéMON RANGER -- 1 of this map's trainers
    [41] = 110,      -- split, majority wins -- COOLTRAINER x1 -> pic 110; COOL COUPLE x1 -> pic 128
    [42] = 111,      -- split, majority wins -- COOLTRAINER x1 -> pic 111; COOL COUPLE x1 -> pic 128
  },
  ["FR_SEVEN_ISLAND_SEVAULT_CANYON_ENTRANCE"] = {
    [25] = 129,      -- YOUNG COUPLE -- 1 of this map's trainers
    [26] = 102,      -- JUGGLER -- 1 of this map's trainers
    [28] = 144,      -- AROMA LADY -- 1 of this map's trainers
    [29] = 129,      -- YOUNG COUPLE -- 1 of this map's trainers
    [39] = 142,      -- POKéMON RANGER -- 1 of this map's trainers
    [40] = 143,      -- POKéMON RANGER -- 1 of this map's trainers
  },
  ["FR_SEVEN_ISLAND_TANOBY_RUINS"] = {
    [22] = 147,      -- PAINTER -- 1 of this map's trainers
    [56] = 145,      -- RUIN MANIAC -- 2 of this map's trainers
    [61] = 123,      -- GENTLEMAN -- 1 of this map's trainers
  },
  ["FR_SEVEN_ISLAND_TRAINER_TOWER"] = {
    [19] = 100,      -- PSYCHIC -- 1 of this map's trainers
    [23] = 138,      -- PSYCHIC -- 1 of this map's trainers
  },
  ["FR_SILPH_CO_10F"] = {
    [49] = 109,      -- TEAM ROCKET -- 1 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_SILPH_CO_11F"] = {
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
  },
  ["FR_SILPH_CO_2F"] = {
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 2 of this map's trainers
  },
  ["FR_SILPH_CO_3F"] = {
    [49] = 109,      -- TEAM ROCKET -- 1 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_SILPH_CO_4F"] = {
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_SILPH_CO_5F"] = {
    [26] = 102,      -- JUGGLER -- 1 of this map's trainers
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_SILPH_CO_6F"] = {
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_SILPH_CO_7F"] = {
    [49] = 109,      -- TEAM ROCKET -- 3 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_SILPH_CO_8F"] = {
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_SILPH_CO_9F"] = {
    [49] = 109,      -- TEAM ROCKET -- 2 of this map's trainers
    [55] = 107,      -- SCIENTIST -- 1 of this map's trainers
  },
  ["FR_SIX_ISLAND_GREEN_PATH"] = {
    [23] = 138,      -- PSYCHIC -- 1 of this map's trainers
  },
  ["FR_SIX_ISLAND_OUTCAST_ISLAND"] = {
    [36] = 131,      -- SIS AND BRO -- 1 of this map's trainers
    [43] = 95,       -- SWIMMER♂ -- 1 of this map's trainers
    [44] = 99,       -- split, majority wins -- SWIMMER♀ x1 -> pic 99; SIS AND BRO x1 -> pic 131
    [49] = 109,      -- TEAM ROCKET -- 1 of this map's trainers
    [57] = 94,       -- FISHERMAN -- 1 of this map's trainers
  },
  ["FR_SIX_ISLAND_PATTERN_BUSH"] = {
    [18] = 82,       -- YOUNGSTER -- 2 of this map's trainers
    [20] = 83,       -- BUG CATCHER -- 3 of this map's trainers
    [22] = 84,       -- LASS -- 2 of this map's trainers
    [28] = 141,      -- POKéMON BREEDER -- 2 of this map's trainers
    [39] = 86,       -- CAMPER -- 1 of this map's trainers
    [40] = 87,       -- PICNICKER -- 1 of this map's trainers
    [56] = 145,      -- RUIN MANIAC -- 1 of this map's trainers
  },
  ["FR_SIX_ISLAND_RUIN_VALLEY"] = {
    [52] = 88,       -- POKéMANIAC -- 1 of this map's trainers
    [56] = 145,      -- split, majority wins -- HIKER x1 -> pic 90; RUIN MANIAC x3 -> pic 145
  },
  ["FR_SIX_ISLAND_WATER_PATH"] = {
    [17] = 127,      -- TWINS -- 2 of this map's trainers
    [26] = 102,      -- JUGGLER -- 1 of this map's trainers
    [28] = 144,      -- AROMA LADY -- 1 of this map's trainers
    [43] = 95,       -- SWIMMER♂ -- 1 of this map's trainers
    [44] = 99,       -- SWIMMER♀ -- 1 of this map's trainers
    [56] = 90,       -- HIKER -- 1 of this map's trainers
  },
  ["FR_SSANNE_1F_ROOM2"] = {
    [18] = 82,       -- YOUNGSTER -- 1 of this map's trainers
    [22] = 84,       -- LASS -- 1 of this map's trainers
  },
  ["FR_SSANNE_1F_ROOM5"] = {
    [61] = 123,      -- GENTLEMAN -- 1 of this map's trainers
  },
  ["FR_SSANNE_1F_ROOM7"] = {
    [61] = 123,      -- GENTLEMAN -- 1 of this map's trainers
  },
  ["FR_SSANNE_2F_ROOM2"] = {
    [57] = 94,       -- FISHERMAN -- 1 of this map's trainers
    [61] = 123,      -- GENTLEMAN -- 1 of this map's trainers
  },
  ["FR_SSANNE_2F_ROOM4"] = {
    [22] = 84,       -- LASS -- 1 of this map's trainers
    [61] = 123,      -- GENTLEMAN -- 1 of this map's trainers
  },
  ["FR_SSANNE_B1F_ROOM1"] = {
    [57] = 94,       -- FISHERMAN -- 1 of this map's trainers
    [62] = 85,       -- SAILOR -- 1 of this map's trainers
  },
  ["FR_SSANNE_B1F_ROOM2"] = {
    [62] = 85,       -- SAILOR -- 1 of this map's trainers
  },
  ["FR_SSANNE_B1F_ROOM3"] = {
    [62] = 85,       -- SAILOR -- 1 of this map's trainers
  },
  ["FR_SSANNE_B1F_ROOM4"] = {
    [62] = 85,       -- SAILOR -- 2 of this map's trainers
  },
  ["FR_SSANNE_DECK"] = {
    [62] = 85,       -- SAILOR -- 2 of this map's trainers
  },
  ["FR_THREE_ISLAND_BOND_BRIDGE"] = {
    [17] = 127,      -- TWINS -- 2 of this map's trainers
    [28] = 144,      -- AROMA LADY -- 2 of this map's trainers
    [37] = 140,      -- TUBER -- 2 of this map's trainers
    [44] = 99,       -- SWIMMER♀ -- 1 of this map's trainers
  },
  ["FR_VERMILION_CITY_GYM"] = {
    [30] = 93,       -- ENGINEER -- 1 of this map's trainers
    [61] = 123,      -- GENTLEMAN -- 1 of this map's trainers
    [62] = 85,       -- SAILOR -- 1 of this map's trainers
  },
  ["FR_VICTORY_ROAD_1F"] = {
    [41] = 110,      -- COOLTRAINER -- 1 of this map's trainers
    [42] = 111,      -- COOLTRAINER -- 1 of this map's trainers
  },
  ["FR_VICTORY_ROAD_2F"] = {
    [25] = 103,      -- TAMER -- 1 of this map's trainers
    [26] = 102,      -- JUGGLER -- 2 of this map's trainers
    [52] = 88,       -- POKéMANIAC -- 1 of this map's trainers
    [54] = 105,      -- BLACK BELT -- 1 of this map's trainers
  },
  ["FR_VICTORY_ROAD_3F"] = {
    [41] = 110,      -- split, majority wins -- COOLTRAINER x2 -> pic 110; COOL COUPLE x1 -> pic 128
    [42] = 111,      -- split, majority wins -- COOLTRAINER x2 -> pic 111; COOL COUPLE x1 -> pic 128
  },
  ["FR_VIRIDIAN_CITY_GYM"] = {
    [25] = 103,      -- TAMER -- 2 of this map's trainers
    [41] = 110,      -- COOLTRAINER -- 3 of this map's trainers
    [54] = 105,      -- BLACK BELT -- 3 of this map's trainers
  },
  ["FR_VIRIDIAN_FOREST"] = {
    [20] = 83,       -- BUG CATCHER -- 5 of this map's trainers
  },
  ["SEVII_ONE_ISLAND_KINDLE_ROAD"] = {
    [24] = 139,      -- split, majority wins -- CRUSH KIN x1 -> pic 130; CRUSH GIRL x2 -> pic 139
    [39] = 86,       -- CAMPER -- 1 of this map's trainers
    [40] = 87,       -- PICNICKER -- 1 of this map's trainers
    [43] = 95,       -- SWIMMER♂ -- 1 of this map's trainers
    [44] = 99,       -- SWIMMER♀ -- 1 of this map's trainers
    [45] = 95,       -- SWIMMER♂ -- 1 of this map's trainers
    [46] = 99,       -- SWIMMER♀ -- 1 of this map's trainers
    [54] = 105,      -- split, majority wins -- BLACK BELT x2 -> pic 105; CRUSH KIN x1 -> pic 130
    [57] = 94,       -- FISHERMAN -- 1 of this map's trainers
  },
  ["SEVII_ONE_ISLAND_TREASURE_BEACH"] = {
    [44] = 99,       -- SWIMMER♀ -- 1 of this map's trainers
  },
}
