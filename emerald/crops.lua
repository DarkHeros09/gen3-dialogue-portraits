-- The 32px window to cut each EMERALD trainer picture with.
--
-- GENERATED -- do not hand-edit.  Regenerate with
--   python .probe/dp3_emit_emerald_crops.py \
--     .probe/_em_crop_measure.tsv gen3-dialogue-portraits-repo/emerald/crops.lua
-- from measurements of the cart's own art (dp3_emerald_crop_measure.py).
--
-- WHY THIS EXISTS.  The mod's art/crops.lua is keyed by FireRed trainer
-- FRONT-PIC id and every rectangle in it was measured off FireRed art.
-- Emerald's pictures are their own number space AND their own art set:
-- many are FULL-BODY standing figures whose opaque art starts 15 or more
-- rows below the top, and several hold TWO people.  FireRed's default
-- window {16, 3, 32} -- tuned for a single FireRed bust -- therefore
-- framed the chest, or split two heads in half.  That is the reported
-- "some portraits are badly framed".  Each rectangle here centres the
-- 32px window on the HEAD band measured from the picture itself.
--
-- `trainers` is keyed by Emerald FRONT-PIC id.  `pairs` holds one
-- rectangle per half of a two-person picture, and `pairSide` says which
-- half an overworld graphic stands on -- the same two-table shape the
-- FireRed table uses, for the same reason (one rectangle cannot be right
-- for both people in the picture).
--
-- The default is the safest single window for an Emerald bust: the head
-- band of the measured pictures sits around rows 2-20, so a window at
-- {16, 1, 32} holds a head and shoulders whole for the typical case.
return {
  defaults = {
    trainers = { 16, 1, 32 },
    pokemon  = { 16, 17, 32 },
  },

  -- head-banded window per picture (x, y, 32), from the measurement
  --
  -- Keys are STRINGS, like art/crops.lua and for the same reason:
  -- portraitFor builds the key as tostring(entry.pic), so a numeric key
  -- here would never match and every picture would fall to the default.
  -- (Measured: a numeric-keyed first draft did exactly that -- all 93
  -- pictures read as unfiled.)
  trainers = {
    ["0"] = { 28, 0, 32 },  -- head starts row 1
    ["1"] = { 16, 4, 32 },  -- head starts row 6
    ["2"] = { 23, 1, 32 },  -- head starts row 3
    ["3"] = { 14, 0, 32 },  -- head starts row 2
    ["4"] = { 14, 1, 32 },  -- head starts row 3
    ["5"] = { 14, 2, 32 },  -- head starts row 4
    ["6"] = { 17, 1, 32 },  -- head starts row 3
    ["7"] = { 18, 16, 32 },  -- head starts row 18
    ["8"] = { 14, 5, 32 },  -- head starts row 7
    ["9"] = { 20, 3, 32 },  -- head starts row 5
    ["10"] = { 17, 0, 32 },  -- head starts row 2
    ["11"] = { 18, 0, 32 },  -- head starts row 2
    ["12"] = { 17, 0, 32 },  -- head starts row 0
    ["13"] = { 17, 0, 32 },  -- head starts row 0
    ["14"] = { 21, 0, 32 },  -- head starts row 2
    ["15"] = { 14, 4, 32 },  -- head starts row 6
    ["16"] = { 27, 7, 32 },  -- head starts row 9
    ["18"] = { 22, 12, 32 },  -- head starts row 14
    ["19"] = { 17, 17, 32 },  -- head starts row 19
    ["20"] = { 23, 2, 32 },  -- head starts row 4
    ["21"] = { 18, 0, 32 },  -- head starts row 1
    ["22"] = { 17, 1, 32 },  -- head starts row 3
    ["23"] = { 14, 7, 32 },  -- head starts row 9
    ["24"] = { 16, 19, 32 },  -- head starts row 21
    ["25"] = { 14, 10, 32 },  -- head starts row 12
    ["26"] = { 22, 1, 32 },  -- head starts row 3
    ["27"] = { 12, 1, 32 },  -- head starts row 3
    ["28"] = { 14, 4, 32 },  -- head starts row 6
    ["29"] = { 17, 16, 32 },  -- head starts row 18
    ["30"] = { 16, 4, 32 },  -- CORRECTED by eye (scan read a prop, not the head)
    ["31"] = { 20, 2, 32 },  -- head starts row 4
    ["32"] = { 20, 1, 32 },  -- head starts row 3
    ["33"] = { 22, 6, 32 },  -- head starts row 8
    ["34"] = { 14, 3, 32 },  -- head starts row 5
    ["35"] = { 19, 4, 32 },  -- head starts row 6
    ["36"] = { 19, 7, 32 },  -- head starts row 9
    ["37"] = { 14, 4, 32 },  -- head starts row 6
    ["38"] = { 8, 0, 32 },  -- head starts row 2
    ["39"] = { 10, 0, 32 },  -- head starts row 1
    ["40"] = { 18, 7, 32 },  -- head starts row 9
    ["41"] = { 16, 1, 32 },  -- head starts row 3
    ["42"] = { 22, 2, 32 },  -- head starts row 4
    ["43"] = { 15, 0, 32 },  -- head starts row 2
    ["44"] = { 17, 0, 32 },  -- head starts row 1
    ["45"] = { 13, 1, 32 },  -- head starts row 3
    ["47"] = { 21, 0, 32 },  -- head starts row 0
    ["48"] = { 16, 12, 32 },  -- head starts row 14
    ["49"] = { 17, 12, 32 },  -- head starts row 14
    ["51"] = { 12, 7, 32 },  -- head starts row 9
    ["52"] = { 16, 4, 32 },  -- head starts row 6
    ["53"] = { 17, 13, 32 },  -- head starts row 15
    ["54"] = { 8, 2, 32 },  -- CORRECTED by eye (scan read a prop, not the head)
    ["55"] = { 34, 8, 32 },  -- CORRECTED by eye (scan read a prop, not the head)
    ["56"] = { 13, 1, 32 },  -- head starts row 3
    ["57"] = { 18, 0, 32 },  -- head starts row 2
    ["58"] = { 15, 1, 32 },  -- head starts row 3
    ["59"] = { 16, 3, 32 },  -- head starts row 5
    ["60"] = { 15, 2, 32 },  -- head starts row 4
    ["61"] = { 16, 3, 32 },  -- head starts row 5
    ["62"] = { 13, 1, 32 },  -- head starts row 3
    ["63"] = { 16, 17, 32 },  -- head starts row 19
    ["64"] = { 20, 0, 32 },  -- head starts row 0
    ["65"] = { 9, 1, 32 },  -- head starts row 3
    ["66"] = { 12, 4, 32 },  -- head starts row 6
    ["68"] = { 19, 0, 32 },  -- head starts row 2
    ["69"] = { 18, 0, 32 },  -- head starts row 2
    ["70"] = { 17, 5, 32 },  -- head starts row 7
    ["71"] = { 11, 6, 32 },  -- head starts row 8
    ["72"] = { 11, 6, 32 },  -- head starts row 8
    ["73"] = { 20, 16, 32 },  -- CORRECTED by eye (scan read a prop, not the head)
    ["74"] = { 17, 5, 32 },  -- head starts row 7
    ["75"] = { 18, 1, 32 },  -- head starts row 3
    ["76"] = { 18, 0, 32 },  -- head starts row 1
    ["77"] = { 22, 7, 32 },  -- head starts row 9
    ["81"] = { 15, 0, 32 },  -- head starts row 0
    ["82"] = { 17, 1, 32 },  -- head starts row 3
    ["83"] = { 14, 0, 32 },  -- head starts row 2
    ["84"] = { 16, 2, 32 },  -- head starts row 4
    ["85"] = { 13, 6, 32 },  -- head starts row 8
    ["86"] = { 15, 0, 32 },  -- head starts row 1
    ["87"] = { 18, 0, 32 },  -- head starts row 1
    ["88"] = { 16, 1, 32 },  -- head starts row 3
    ["89"] = { 14, 6, 32 },  -- head starts row 8
    ["90"] = { 16, 6, 32 },  -- head starts row 8
    ["91"] = { 11, 6, 32 },  -- head starts row 8
    ["92"] = { 11, 6, 32 },  -- head starts row 8
  },

  -- two-person pictures: one rectangle per half
  pairs = {
    ["17"] = { left = { 5, 3, 32 }, right = { 30, 4, 32 } },
    ["46"] = { left = { 2, 8, 32 }, right = { 29, 9, 32 } },
    ["50"] = { left = { 8, 6, 32 }, right = { 27, 8, 32 } },
    ["67"] = { left = { 8, 15, 32 }, right = { 30, 15, 32 } },
    ["78"] = { left = { 11, 5, 32 }, right = { 23, 5, 32 } },
    ["79"] = { left = { 2, 0, 32 }, right = { 32, 20, 32 } },
    ["80"] = { left = { 3, 13, 32 }, right = { 26, 5, 32 } },
  },

  -- which half of a pair an overworld graphic stands on (Emerald gfx ids).
  --
  -- Same shape as art/crops.lua's pairSide: the graphic says WHICH half is
  -- standing there, so one two-person bust answers correctly for both
  -- people.  Decided by eye against each graphic's overworld front frame
  -- (.probe/_em_pairside.png) and the cart's own class table
  -- (.probe/drivers/dp3_emerald_classdump.lua).
  pairSide = {
    [6] = "left",      -- TWIN       -- both twins are the same girl; either half will do
    [8] = "left",      -- GIRL_1     -- the cart draws her as one of the Twins; either half will do
    [10] = "left",      -- GIRL_2     -- ditto
    [12] = "left",      -- LITTLE_GIRL -- ditto
    [67] = "right",      -- REPORTER_M -- his overworld frame holds the camera too, so the right half
    [68] = "left",      -- REPORTER_F -- the interviewer holding the microphone
    [110] = "right",      -- CAMERAMAN  -- the one holding the camera
    [131] = "left",      -- LIZA       -- one half of the Psychic twins
    [132] = "right",      -- TATE       -- the other half
    [213] = "left",      -- TUBER_M_SWIMMING -- the boy with the inner tube
  },
}
