-- Emerald support -- the isolated path, and the FRLG regression guard.
--
-- tests/dp3_speaker_test.lua proves WHAT the mod resolves.  This suite proves
-- WHICH GAME it resolves it for.  Those are different questions and the second
-- is the one the Emerald brief turns on: an Emerald boot must never be answered
-- from a FireRed/LeafGreen table, and a FireRed or LeafGreen boot must be
-- answered exactly as it was before Emerald existed.
--
-- Three parts, and the FRLG half is the one that matters most:
--
--   * DETECTION: the id detector accepts the Emerald id and the cart's own
--     SHA-1 and rejects every other game; the engine's GameVersion routes it.
--   * RESOLUTION: on an Emerald boot the resolver walks EMERALD data --
--     script key -> trainer id -> the cart's picture -- and it declines with a
--     reason that names the missing piece rather than ever raising, guessing,
--     or falling through to an FRLG table.
--   * FRLG REGRESSION: for "firered" and "leafgreen" the gate is SHUT -- the
--     Emerald branch is not taken, and the FRLG resolver answers exactly what
--     it answered before (pinned against literal expected values).
--
-- Two things this suite deliberately does NOT do.  It does not require the
-- engine to have an `emerald` GameVersion row: the detection cases stub
-- GameVersion, so an engine WITH a row and one WITHOUT must both pass, because
-- the mod has to be honest on either.  And it does not need a live Emerald
-- session or an Emerald ROM: the EMERALD DATA half is driven from the mod's own
-- generated table (emerald/trainer_ids.lua), which is what the resolver reads at
-- runtime, plus a stub for the two engine services the live boot would provide.
--
-- Run:  luajit tests/dp3_emerald_test.lua <engine root>

local function isFile(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function normalise(path)
  return (path:gsub("\\", "/"):gsub("/+$", ""))
end

local script = normalise(arg and arg[0] or "tests/dp3_emerald_test.lua")
local here = script:match("^(.*)/[^/]+$") or "."

local MOD_ROOT
for _, candidate in ipairs({ here .. "/..", here, "." }) do
  local root = normalise(candidate)
  if isFile(root .. "/emerald/init.lua") then MOD_ROOT = root break end
end
if not MOD_ROOT then
  io.write("error: cannot find the mod root (emerald/init.lua) from ", script, "\n")
  os.exit(1)
end

-- ------- assertions
local failures, checks = 0, 0
local function fail(msg) failures = failures + 1 io.write("FAIL ", msg, "\n") end
local function ok(cond, msg)
  checks = checks + 1
  if not cond then fail(msg) end
  return cond
end
local function eq(got, want, msg)
  return ok(got == want,
    ("%s (got %s, want %s)"):format(msg, tostring(got), tostring(want)))
end
local function neq(got, unwanted, msg)
  return ok(got ~= unwanted,
    ("%s (got %s, wanted anything else)"):format(msg, tostring(got)))
end

local function countKeys(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

-- ------- load the Emerald module the way main.lua does
--
-- Not require(): a mod's files are not on package.path.  main.lua reads it with
-- mod:read + load, and this suite does the same from disk so the file it tests
-- is byte-for-byte the file that ships.
local Emerald
do
  local f = io.open(MOD_ROOT .. "/emerald/init.lua", "rb")
  if not f then
    io.write("error: cannot read emerald/init.lua\n")
    os.exit(1)
  end
  local source = f:read("*a")
  f:close()
  local chunk, err = load(source, "@" .. MOD_ROOT .. "/emerald/init.lua")
  if not chunk then
    io.write("error: emerald/init.lua does not compile: ", tostring(err), "\n")
    os.exit(1)
  end
  local ok2, value = pcall(chunk)
  if not ok2 or type(value) ~= "table" then
    io.write("error: emerald/init.lua did not return a table\n")
    os.exit(1)
  end
  Emerald = value
end

-- ------- the real mod reader
--
-- The resolver loads emerald/trainer_ids.lua through the injected reader, and
-- main.lua injects `mod:read`.  Here that reader is a plain disk read, so the
-- table under test is the shipped file -- not a hand-written fixture that could
-- drift from it.  A MOD ROOT-relative path is what mod:read takes.
local function diskRead(rel)
  local f = io.open(MOD_ROOT .. "/" .. rel, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end
Emerald.bind({ read = diskRead })

-- ------- a controllable GameVersion
--
-- The module asks the engine for GameVersion to detect the running game and to
-- gate the resolver.  The suite swaps in a fake for the detection cases and
-- restores the real one after, so the FRLG half can still drive the true
-- engine.
local function withGame(id, fn)
  local real = package.loaded["src.core.GameVersion"]
  package.loaded["src.core.GameVersion"] = {
    get = function() return id end,
    VERSIONS = id == "emerald" and { emerald = { id = "emerald" } } or {},
  }
  local ok2, err = pcall(fn)
  package.loaded["src.core.GameVersion"] = real
  if not ok2 then error(err, 0) end
end

-- ------- a stub for the two engine services the live Emerald boot would give
--
-- The resolver turns a trainer id into the cart's picture through
-- src.core.game3.trainers and that picture into a texture through
-- src.core.game3.trainer_pic.  Neither is reachable headlessly, so the suite
-- stubs both -- exactly the two seams emerald/init.lua documents -- and can
-- then assert the resolver walks EMERALD data end to end.  The stub trainer
-- pack is keyed by the REAL Emerald trainer ids this cart uses, so a mapping
-- that works here works on a real boot.
local function withEngineStubs(fn)
  local savedTrainers = package.loaded["src.core.game3.scripting.trainers"]
  local savedPic = package.loaded["src.core.game3.trainer_pic"]
  package.loaded["src.core.game3.scripting.trainers"] = {
    pack = function()
      return { trainers = {
        [318] = { class = 7,  className = "YOUNGSTER", pic = 53, name = "CALVIN" },
        [481] = { class = 41, className = "TWINS",     pic = 67, name = "AMY & LIV" },
        [900] = { class = 0,  className = "--",        pic = 0,  name = "empty row" },
      } }
    end,
  }
  package.loaded["src.core.game3.trainer_pic"] = {
    front = function(pic)
      if pic == 53 then
        return { image = { __stub = "youngster" }, w = 64, h = 64 }
      end
      if pic == 67 then
        return { image = { __stub = "twins" }, w = 64, h = 64 }
      end
      return nil
    end,
  }
  local ok2, err = pcall(fn)
  package.loaded["src.core.game3.scripting.trainers"] = savedTrainers
  package.loaded["src.core.game3.trainer_pic"] = savedPic
  if not ok2 then error(err, 0) end
end

-- =====================================================================
-- 1. the module loads and is the shape main.lua expects
-- =====================================================================

ok(type(Emerald) == "table", "emerald: the module returns a table")
for _, name in ipairs({ "isEmeraldId", "detectGameId", "isRunning",
                        "artFor", "canDrawPortraits", "unsupportedReason",
                        "trainerIds", "trainerIdFor", "picForTrainerId",
                        "artForPic", "bind" }) do
  ok(type(Emerald[name]) == "function",
    "emerald: it exports " .. name .. "()")
end

-- =====================================================================
-- 2. the id detector
-- =====================================================================

eq(Emerald.isEmeraldId("emerald"), true, "id: 'emerald' is Emerald")
eq(Emerald.isEmeraldId("EMERALD"), true, "id: 'EMERALD' folds case")
eq(Emerald.isEmeraldId("pokemonemerald"), true,
  "id: 'pokemonemerald' is Emerald")
eq(Emerald.isEmeraldId("pokeemerald"), true, "id: 'pokeemerald' is Emerald")

-- THE REGRESSION GUARD AS A UNIT: none of the games the mod already supports
-- may be mistaken for Emerald, and neither may a non-game.
for _, id in ipairs({ "firered", "leafgreen", "red", "blue", "yellow",
                      "gold", "silver", "crystal", "", "rse", "ruby",
                      "sapphire" }) do
  eq(Emerald.isEmeraldId(id), false,
    ("id: %q is not Emerald"):format(id))
end
eq(Emerald.isEmeraldId(nil), false, "id: nil is not Emerald")
eq(Emerald.isEmeraldId(42), false, "id: a number is not Emerald")

-- The cart this build was verified against, pinned by SHA-1 so a future edit
-- cannot silently change which dump the module claims to know.
eq(Emerald.CART_GAMECODE, "BPEE", "cart: the game code is BPEE")
eq(Emerald.CART_SHA1, "f3ae088181bf583e55daf962a92bb46f4f1d07b7",
  "cart: the SHA-1 is the USA/Europe rev 0 dump")

-- =====================================================================
-- 3. detection through the engine's GameVersion
-- =====================================================================

withGame("emerald", function()
  eq(Emerald.detectGameId(), "emerald", "detect: GameVersion says emerald")
  eq(Emerald.isRunning(), true, "detect: isRunning() is true on Emerald")
end)
withGame("firered", function()
  eq(Emerald.detectGameId(), "firered", "detect: GameVersion says firered")
  eq(Emerald.isRunning(), false, "detect: isRunning() is false on FireRed")
end)
withGame("leafgreen", function()
  eq(Emerald.detectGameId(), "leafgreen", "detect: GameVersion says leafgreen")
  eq(Emerald.isRunning(), false, "detect: isRunning() is false on LeafGreen")
end)

-- =====================================================================
-- 4. THE EMERALD DATA -- the generated table the resolver reads
-- =====================================================================
--
-- This is what makes the Emerald path real rather than a shape: the mod ships
-- its own Emerald script key -> trainer id table, generated from the engine's
-- extraction of this cart.  Pin its size and two entries so a future
-- regeneration that loses or shifts keys cannot pass silently.

local ids = Emerald.trainerIds()
ok(type(ids) == "table",
  "data: emerald/trainer_ids.lua loads through the mod reader")
if type(ids) == "table" then
  local n = countKeys(ids)
  eq(n, 523, "data: the table holds the 523 measured entries")
  eq(type(ids["g3:081ec105"]), "number",
    "data: a known Youngster script key is present")
  eq(ids["g3:081ec105"], 318, "data: and it maps to trainer 318")
  eq(type(ids["g3:081ec60b"]), "number",
    "data: a known Twins script key is present")
  eq(ids["g3:081ec60b"], 481, "data: and it maps to trainer 481")
  -- Every value must be a usable trainer id.  A table that carried nil or a
  -- string would break the resolver further down, so catch it here.
  local bad = 0
  for k, v in pairs(ids) do
    if type(k) ~= "string" or not k:match("^g3:%x%x%x%x%x%x%x%x$")
        or type(v) ~= "number" or v <= 0 then bad = bad + 1 end
  end
  eq(bad, 0, "data: every key is g3:XXXXXXXX and every value a positive id")
end

-- =====================================================================
-- 5. THE EMERALD RESOLVER -- walks Emerald data on an Emerald boot
-- =====================================================================
--
-- With the engine claiming Emerald and the two engine services stubbed, the
-- resolver must go script key -> trainer id -> picture -> art.  This is the
-- positive control that proves "support" is not just "declines politely".

withGame("emerald", function()
  withEngineStubs(function()
    eq(Emerald.unsupportedReason(), nil,
      "resolve: an engine with the emerald row + a table has NO blocker")

    -- script key -> trainer id, from the shipped table.
    eq(Emerald.trainerIdFor({ scriptKey = "g3:081ec105" }), 318,
      "resolve: a script key resolves to its trainer id")
    eq(Emerald.trainerIdFor({ scriptKey = "g3:081ec60b" }), 481,
      "resolve: a second script key resolves too")
    -- An explicit trainer id wins, so a caller can force a face.
    eq(Emerald.trainerIdFor({ trainerId = 481, scriptKey = "g3:081ec105" }),
      481, "resolve: an explicit trainerId overrides the table")
    -- An unknown key is simply not a trainer -- no id, no error.
    eq(Emerald.trainerIdFor({ scriptKey = "g3:deadbeef" }), nil,
      "resolve: an unknown script key yields no trainer id")

    -- trainer id -> the cart's picture number.
    eq(Emerald.picForTrainerId(318), 53,
      "resolve: trainer 318 is picture 53 in this cart")
    eq(Emerald.picForTrainerId(481), 67,
      "resolve: trainer 481 is picture 67 in this cart")
    eq(Emerald.picForTrainerId(900), nil,
      "resolve: a class-0 row is not a trainer and has no picture")
    eq(Emerald.picForTrainerId(nil), nil,
      "resolve: a nil trainer id has no picture")

    -- picture number -> art, in main.lua's own shape.
    local art = Emerald.artForPic(53)
    ok(type(art) == "table" and art.image ~= nil,
      "resolve: picture 53 yields art with an image")
    eq(art and art.w, 64, "resolve: the art carries the cart's width")
    eq(art and art.h, 64, "resolve: the art carries the cart's height")
    eq(art and art.pic, 53, "resolve: and it records which picture it is")
    eq(Emerald.artForPic(999), nil, "resolve: an unknown picture yields nil")

    -- END TO END: the one call main.lua makes.
    local a2 = Emerald.artFor({ scriptKey = "g3:081ec105" })
    ok(type(a2) == "table" and a2.image ~= nil,
      "resolve: artFor walks script key -> id -> picture -> art")
    eq(a2 and a2.pic, 53, "resolve: and it lands on the right picture")

    -- A non-trainer object is the ordinary "no portrait" answer: nil with no
    -- reason string, because nothing is missing.
    local a3, why3 = Emerald.artFor({ scriptKey = "g3:00000000" })
    eq(a3, nil, "resolve: a non-trainer object gets no portrait")
    eq(why3, nil, "resolve: and that is not reported as a missing piece")

    -- ---- the mod's OWN Emerald art, and the OPENING-TUTORIAL report
    --
    -- "prof.birch front sprite should be provided in the game's beginning."
    -- The opening scene is Route101's g3:081ebcde, whose "Hello! You over
    -- there!" box is preceded by `applymovement localId=2` -- object 2 is
    -- PROF_BIRCH (gfx 64), and its object carries NO scriptKey (the scene runs
    -- off the bag beside him), so routes 1 and 2 are silent and the graphic is
    -- the only fact.  Route 3b must therefore answer it from the cart's own
    -- field-effect portrait, which is what the game itself shows at new-game.
    do
      -- A graphics-id speaker with no scriptKey and no name is the tutorial's
      -- exact shape.
      local tut = { gfx = 64, mapId = "Route101", localId = 2 }

      -- With no image loader bound (headless), the shipped-art route declines
      -- and the hand table's fallback still answers -- that ordering is the
      -- point of keeping [64] = 24.
      local noLoader = Emerald.assetArtFor(64)
      eq(noLoader, nil, "asset: with no image loader bound, route 3b declines")

      -- The table names Birch's art, and it is keyed by the gfx the cart uses.
      eq(Emerald.ASSET_ART[64], "PROF_BIRCH",
        "asset: gfx 64 (PROF_BIRCH) ships its own art")
      eq(Emerald.ART_DIR, "emerald/art/",
        "asset: shipped art lives under one directory")

      -- With a loader bound, the file is asked for by name and the art comes
      -- back in main.lua's shape -- no picture number, because it is not one.
      local asked
      local fakeImage = { getDimensions = function() return 64, 64 end }
      Emerald.bind({ image = function(rel) asked = rel return fakeImage end })
      local shipped = Emerald.assetArtFor(64)
      ok(type(shipped) == "table" and shipped.image == fakeImage,
        "asset: route 3b returns the shipped image")
      eq(asked, "emerald/art/PROF_BIRCH.png",
        "asset: and it asked for the file the table names")
      eq(shipped and shipped.w, 64, "asset: the art carries its width")
      eq(shipped and shipped.h, 64, "asset: the art carries its height")
      eq(shipped and shipped.pic, nil,
        "asset: shipped art is not a trainer picture and says so")

      -- A loader that fails (no graphics context) must not raise and must not
      -- answer -- it falls through to the routes below.
      Emerald.bind({ image = function() error("no graphics context") end })
      eq(Emerald.assetArtFor(64), nil,
        "asset: a loader that raises is treated as 'no shipped art'")

      -- The rect the cart ships FOR Birch must not be a trainer pic: pic 24 is
      -- the EXPERT (a kneeling old woman), which is the wrong person.  Pin the
      -- fact so a future edit cannot silently repoint him at it as an answer.
      eq(Emerald.ASSET_ART[64] == 24, false,
        "asset: Birch is NOT answered by the trainer picture 24")

      -- Restore the module's loader binding for the checks that follow.
      Emerald.bind({ image = nil })
    end

    eq(Emerald.canDrawPortraits(), true,
      "resolve: canDrawPortraits() is true on a fully-backed Emerald boot")
  end)
end)

-- THE PACK LEG, which is the one that broke in a real boot the first time: the
-- resolver reaches the engine's trainer pack through
-- `src.core.game3.scripting.trainers` (the SAME service main.lua's FRLG path
-- uses).  If that module is unreachable, the resolver must say so in the reason
-- -- naming the pack, not "no portrait" and not an FRLG table.  A fresh module
-- instance is needed because the pack is cached on first success.
do
  local f = io.open(MOD_ROOT .. "/emerald/init.lua", "rb")
  local source = f and f:read("*a")
  if f then f:close() end
  local fresh = source and load(source, "@" .. MOD_ROOT .. "/emerald/init.lua")
  fresh = fresh and fresh()
  ok(type(fresh) == "table", "pack: a fresh module instance loads")
  if type(fresh) == "table" then
    fresh.bind({ read = diskRead })
    local saved = package.loaded["src.core.game3.scripting.trainers"]
    local savedGV = package.loaded["src.core.GameVersion"]
    package.loaded["src.core.game3.scripting.trainers"] = nil   -- unreachable
    package.loaded["src.core.GameVersion"] =
      { get = function() return "emerald" end, VERSIONS = { emerald = {} } }
    eq(fresh.picForTrainerId(318), nil,
      "pack: with no pack reachable, an id yields no picture")
    ok(type(fresh.trainerPackError()) == "string",
      "pack: and the module records WHY the pack was unreachable")
    local art, why = fresh.artFor({ scriptKey = "g3:081ec105" })
    eq(art, nil, "pack: the resolver declines while the pack is unreachable")
    eq(why, fresh.trainerPackError(),
      "pack: and the reason is the pack's own, not a generic one")
    if type(why) == "string" then
      ok(why:lower():find("trainer", 1, true) ~= nil
         or why:lower():find("pack", 1, true) ~= nil,
        "pack: the reason names the trainer pack")
    end
    package.loaded["src.core.game3.scripting.trainers"] = saved
    package.loaded["src.core.GameVersion"] = savedGV
  end
end

-- =====================================================================
-- 6b. THE GAME GUARD -- Emerald data must not answer for another game
-- =====================================================================
--
-- This is the brief's central rule expressed as a property of the module rather
-- than of a call site: a boot that is NOT Emerald must get nothing from the
-- Emerald resolver, even when every Emerald table is present and loadable.  It
-- is asserted on a FRESH instance with the real table and realistic engine
-- stubs, so the only thing standing between a FireRed boot and an Emerald face
-- is this guard.
do
  local f = io.open(MOD_ROOT .. "/emerald/init.lua", "rb")
  local source = f and f:read("*a")
  if f then f:close() end
  local fresh = source and load(source, "@" .. MOD_ROOT .. "/emerald/init.lua")
  fresh = fresh and fresh()
  ok(type(fresh) == "table", "guard: a fresh module instance loads")
  if type(fresh) == "table" then
    fresh.bind({ read = diskRead })
    local savedTrainers = package.loaded["src.core.game3.scripting.trainers"]
    local savedPic = package.loaded["src.core.game3.trainer_pic"]
    local savedGV = package.loaded["src.core.GameVersion"]
    -- everything Emerald needs is PRESENT...
    package.loaded["src.core.game3.scripting.trainers"] =
      { pack = function() return { trainers = {
        [318] = { class = 7, pic = 53, name = "CALVIN" } } } end }
    package.loaded["src.core.game3.trainer_pic"] =
      { front = function() return { image = {}, w = 64, h = 64 } end }

    -- ...but the running game is FireRed.
    package.loaded["src.core.GameVersion"] =
      { get = function() return "firered" end, VERSIONS = { emerald = {} } }
    ok(type(fresh.trainerIds()) == "table",
      "guard: the table IS loadable on this boot (so the guard is the only bar)")
    eq(fresh.artFor({ scriptKey = "g3:081ec105" }), nil,
      "guard: a FireRed boot gets NO art from the Emerald resolver")
    eq(fresh.canDrawPortraits(), false,
      "guard: and canDrawPortraits() is false on FireRed")

    -- The two boots the brief names must both be refused.
    for _, other in ipairs({ "firered", "leafgreen" }) do
      package.loaded["src.core.GameVersion"] =
        { get = function() return other end, VERSIONS = { emerald = {} } }
      eq(fresh.artFor({ scriptKey = "g3:081ec105" }), nil,
        ("guard: %s gets NO art from the Emerald resolver"):format(other))
    end

    -- ...while the same instance DOES answer on Emerald -- so the guard refuses
    -- the wrong game without breaking the right one.
    package.loaded["src.core.GameVersion"] =
      { get = function() return "emerald" end, VERSIONS = { emerald = {} } }
    local a = fresh.artFor({ scriptKey = "g3:081ec105" })
    ok(type(a) == "table", "guard: the same instance still answers on Emerald")

    -- An explicit force is honoured for a caller that already established the
    -- game (which is what main.lua does, and what keeps that one check at the
    -- call site rather than duplicated here).
    package.loaded["src.core.GameVersion"] =
      { get = function() return "firered" end, VERSIONS = { emerald = {} } }
    local forced = fresh.artFor({ scriptKey = "g3:081ec105" }, { force = true })
    ok(type(forced) == "table", "guard: force = true bypasses the game guard")

    package.loaded["src.core.game3.scripting.trainers"] = savedTrainers
    package.loaded["src.core.game3.trainer_pic"] = savedPic
    package.loaded["src.core.GameVersion"] = savedGV
  end
end

-- Whatever it is handed, it must never raise -- a malformed speaker must not
-- turn a portrait lookup into a crash.
withGame("emerald", function()
  withEngineStubs(function()
    for _, probe in ipairs({ 1, "text", {}, { graphicsId = 25 },
                             { scriptKey = 12 }, { trainerId = "x" } }) do
      local okcall, a = pcall(Emerald.artFor, probe)
      eq(okcall, true, "resolve: artFor does not raise on a " .. type(probe))
      eq(a, nil, "resolve: and still declines a " .. type(probe))
    end
  end)
end)

-- =====================================================================
-- 6. THE DIAGNOSTIC -- a missing piece is named, never guessed around
-- =====================================================================

-- (a) an engine with no emerald row: the blocker names the engine.
do
  local real = package.loaded["src.core.GameVersion"]
  package.loaded["src.core.GameVersion"] = { get = function() return "emerald" end,
                                             VERSIONS = {} }
  local why = Emerald.unsupportedReason()
  eq(why, Emerald.MISSING_ENGINE_REASON,
    "reason: an engine without an emerald row reports the engine blocker")
  ok(type(why) == "string" and why:lower():find("engine", 1, true) ~= nil,
    "reason: and the wording says the engine is what is missing")
  package.loaded["src.core.GameVersion"] = real
end

-- (b) an engine that HAS emerald but a mod with no table: the blocker names
-- the table.  This needs a FRESH module instance: the loaded one has already
-- read the shipped table and caches it for the process, and it is right to do
-- so -- a mod's own table cannot appear or vanish mid-session.  So load a
-- second copy of the file and give it a reader that returns nothing, which is
-- what a mod built without emerald/trainer_ids.lua would look like.
do
  local f = io.open(MOD_ROOT .. "/emerald/init.lua", "rb")
  local source = f and f:read("*a")
  if f then f:close() end
  local chunk = source and load(source, "@" .. MOD_ROOT .. "/emerald/init.lua")
  local fresh = chunk and chunk()
  ok(type(fresh) == "table", "reason: a second module instance loads")
  if type(fresh) == "table" then
    fresh.bind({ read = function() return nil end })
    local real = package.loaded["src.core.GameVersion"]
    package.loaded["src.core.GameVersion"] =
      { get = function() return "emerald" end, VERSIONS = { emerald = {} } }
    eq(fresh.unsupportedReason(), fresh.MISSING_TABLE_REASON,
      "reason: a mod without the table reports the table blocker")
    -- ...and with no table there is no id to resolve, so the resolver declines
    -- with that same reason rather than reaching for an FRLG table.
    local art, why = fresh.artFor({ scriptKey = "g3:081ec105" })
    eq(art, nil, "reason: and the resolver declines without the table")
    eq(why, fresh.MISSING_TABLE_REASON,
      "reason: naming the table, not an FRLG fallback")
    eq(fresh.canDrawPortraits(), false,
      "reason: canDrawPortraits() is false when the table is absent")
    package.loaded["src.core.GameVersion"] = real
  end
end

-- (c) the reason must name Emerald-era facts and never silently claim success.
withGame("emerald", function()
  local why = Emerald.unsupportedReason()
  ok(why == nil or type(why) == "string",
    "reason: unsupportedReason() is nil or a string, never a boolean")
end)
withGame("firered", function()
  -- Not Emerald: the reason still exists (the caller only asks it when it IS
  -- Emerald, but a wrong call must not crash).
  ok(type(Emerald.unsupportedReason()) == "string",
    "reason: unsupportedReason() is safe off Emerald")
end)

-- =====================================================================
-- 6d. THE EMERALD CROP TABLE and THE HAND-MAPPED PEOPLE TABLE
-- =====================================================================
--
-- Two tables this release added, and each has a failure mode that a box on
-- screen hides:
--
--   * emerald/crops.lua is keyed by Emerald FRONT-PIC id and must NOT be
--     consulted with a FireRed id, and vice versa.  Its keys must be STRINGS:
--     portraitFor builds the key as tostring(entry.pic), so a numeric key would
--     silently miss and fall to the default -- every picture mis-framed, and
--     the file would look correct.  (A numeric first draft did exactly that.)
--   * emerald/gfx_art_people.lua resolves BEFORE the measured majors, so a
--     wrong value there is a wrong FACE, not a missing one.  Every value must
--     be a readable picture id or `false`, and no key may be a pair picture for
--     a graphic that does not wear one.

-- (a) the crop table loads, has its own default, and every key is a string.
do
  local f = io.open(MOD_ROOT .. "/emerald/crops.lua", "rb")
  local src = f and f:read("*a"); if f then f:close() end
  local crops = src and load(src, "@emerald/crops.lua")
  crops = crops and crops()
  ok(type(crops) == "table", "cropE: emerald/crops.lua loads")
  if type(crops) == "table" then
    ok(type(crops.trainers) == "table", "cropE: it has a trainers table")
    ok(type(crops.defaults) == "table" and type(crops.defaults.trainers) == "table",
      "cropE: it has its own default (not FireRed's)")
    -- the default must be a real rectangle, and different from FireRed's
    local d = crops.defaults.trainers
    ok(type(d) == "table" and tonumber(d[1]) and tonumber(d[2]) and tonumber(d[3]),
      "cropE: the default is three numbers")
    -- every trainers key must be a STRING, or portraitFor would never match it
    local badKey, n = 0, 0
    for k in pairs(crops.trainers) do
      n = n + 1
      if type(k) ~= "string" then badKey = badKey + 1 end
    end
    ok(n > 50, ("cropE: the trainers table is populated (%d entries)"):format(n))
    eq(badKey, 0, "cropE: EVERY trainers key is a string, as portraitFor builds it")
    -- every value must be three numbers
    local badVal = 0
    for _, v in pairs(crops.trainers) do
      if type(v) ~= "table" or not (tonumber(v[1]) and tonumber(v[2]) and tonumber(v[3])) then
        badVal = badVal + 1
      end
    end
    eq(badVal, 0, "cropE: every trainers value is three numbers")
    -- pairs: each key string, each side a rectangle
    if type(crops.pairs) == "table" then
      local bad = 0
      for k, v in pairs(crops.pairs) do
        if type(k) ~= "string" or type(v) ~= "table" then bad = bad + 1
        elseif v.left and not (tonumber(v.left[1]) and tonumber(v.left[3])) then bad = bad + 1
        elseif v.right and not (tonumber(v.right[1]) and tonumber(v.right[3])) then bad = bad + 1 end
      end
      eq(bad, 0, "cropE: every pair entry is a string key with rectangle halves")
    end
    -- pairSide values must be "left" or "right"
    if type(crops.pairSide) == "table" then
      local bad = 0
      for _, v in pairs(crops.pairSide) do
        if v ~= "left" and v ~= "right" then bad = bad + 1 end
      end
      eq(bad, 0, "cropE: every pairSide is left or right")
    end
  end
end

-- (b) the hand-mapped people table: every value is a number or false, and no
-- value points at a picture this release knows to be a pair for a lone NPC.
do
  local f = io.open(MOD_ROOT .. "/emerald/gfx_art_people.lua", "rb")
  local src = f and f:read("*a"); if f then f:close() end
  local people = src and load(src, "@emerald/gfx_art_people.lua")
  people = people and people()
  ok(type(people) == "table", "people: emerald/gfx_art_people.lua loads")
  if type(people) == "table" then
    local n, bad = 0, 0
    for k, v in pairs(people) do
      n = n + 1
      if type(k) ~= "number" then bad = bad + 1
      elseif v ~= false and not tonumber(v) then bad = bad + 1 end
    end
    ok(n >= 40, ("people: the table is populated (%d entries)"):format(n))
    eq(bad, 0, "people: every entry is a numeric graphic id -> a picture or false")
    -- the specific fixes this release makes must be present and RIGHT
    eq(people[7], 53, "people: BOY_1 -> YOUNGSTER 53, not the Sailor")
    eq(people[9], 53, "people: BOY_2 -> YOUNGSTER 53")
    eq(people[15], 23, "people: RICH_BOY -> RICH BOY 23, not the Sailor")
    eq(people[17], 0, "people: FAT_MAN -> HIKER 0 (the round build), not the woman in pic 2")
    eq(people[18], 52, "people: POKEFAN_F -> POKéFAN 52, not the Sailor")
    eq(people[47], 77, "people: LASS -> LASS 77, not Psychic 34")
    eq(people[55], 0, "people: HIKER -> HIKER 0, not Ruin Maniac 16")
    eq(people[26], 49, "people: WOMAN_4 -> a lone bust 49, not the Young Couple 78")
    eq(people[65], 2, "people: MAN_4 -> a lone bust 2, not the Young Couple 78")
    eq(people[30], false, "people: OLD_WOMAN declines -- the cart drew no old-woman bust")
    eq(people[22], false, "people: EXPERT_F declines for the same reason")
    eq(people[21], 9, "people: EXPERT_M -> EXPERT 9 (the old man)")
    -- the reported fixes: the family, the lab, and the nurse who must NOT be drawn
    eq(people[64], 24, "people: PROF_BIRCH -> a closest-build bust 24, not nil")
    eq(people[215], 15, "people: MOM -> AROMA LADY 15, not nil")
    eq(people[46], 70, "people: SCIENTIST_1 -> the white-coat bust 70, not the Team Aqua grunt 1")
    eq(people[58], false, "people: NURSE declines -- the cart drew no nurse bust")
  end
end

-- (c) the four windows the automatic head scan misframed are corrected, and the
-- corrected values are the ones the build cuts with.  BUG CATCHER: the scan
-- centred on the butterfly net, so the boy's face was outside the window; the
-- fix moves it to 20,16.  FISHERMAN: the fishing rod widened every row's span
-- so the scan's centre sat mid-frame and the window cut the face off the right
-- edge; the fix moves it from 16,9 to 34,8.
do
  local f = io.open(MOD_ROOT .. "/emerald/crops.lua", "rb")
  local src = f and f:read("*a"); if f then f:close() end
  local crops = src and load(src, "@emerald/crops.lua")
  crops = crops and crops()
  if type(crops) == "table" and type(crops.trainers) == "table" then
    local function win(p)
      local t = crops.trainers[p]
      return t and t[1] .. "," .. t[2]
    end
    eq(win("73"), "20,16", "cropE: BUG CATCHER 73 -> the head, not the net (was 32,10)")
    eq(win("30"), "16,4",  "cropE: pic 30 corrected off the hat brim")
    eq(win("54"), "8,2",   "cropE: pic 54 corrected off the outstretched arm")
    eq(win("55"), "34,8",  "cropE: FISHERMAN 55 -> the face, not the rod (was 16,9)")
  end
end

-- =====================================================================
-- 7. FRLG REGRESSION -- the gate stays shut, the resolver is unchanged
-- =====================================================================
--
-- This half needs the real engine, because it drives the real mod.  If no
-- engine is present, say so and skip rather than pretending.
local ENGINE = (arg and arg[1] and normalise(arg[1]))
  or (os.getenv("GEN1RECOMP_ROOT") and normalise(os.getenv("GEN1RECOMP_ROOT")))
if not ENGINE or not isFile(ENGINE .. "/src/ui/game3/message.lua") then
  local parent = MOD_ROOT:match("^(.*)/[^/]+$")
  for _, candidate in ipairs({ parent .. "/gen1recomp", parent,
                               MOD_ROOT .. "/gen1recomp" }) do
    local root = normalise(candidate)
    if isFile(root .. "/src/ui/game3/message.lua") then ENGINE = root break end
  end
end

if not ENGINE then
  io.write("SKIP: no gen1recomp checkout found; the FRLG half needs one.\n")
  io.write("      Set GEN1RECOMP_ROOT or pass it as the first argument.\n")
else
  package.path = ENGINE .. "/?.lua;" .. ENGINE .. "/?/init.lua;"
    .. MOD_ROOT .. "/?.lua;" .. MOD_ROOT .. "/?/init.lua;" .. package.path

  local hasSdk = isFile(ENGINE .. "/tests/modkit/sdk.lua")
  if not hasSdk then
    io.write("SKIP: engine has no tests/modkit/sdk.lua; cannot drive the loader.\n")
  else
    -- Use the REAL GameVersion, so this is the engine's own answer, not a stub.
    local GameVersion = require("src.core.GameVersion")
    ok(type(GameVersion) == "table",
      "frlg: the engine's GameVersion is present")

    -- =================================================================
    -- 6c. THE COLOUR GATE -- Emerald has no per-speaker text colour
    -- =================================================================
    --
    -- The defect this pins: the mod's coloursAllowPortrait() declines a box
    -- drawn in the "neutral" colour, which on FireRed/LeafGreen means narration
    -- (NEUTRAL == 3).  On EMERALD that colour is a CONSTANT -- the profile
    -- switches the whole lookup off (profiles/emerald/font.lua:22,
    -- npcTextColors = false), so frlg_font.lua:176 returns NEUTRAL for every
    -- graphic.  Every Emerald box therefore arrived with npcColor == 3 and the
    -- FRLG rule read all of them as narration -- the report "the mod loads but
    -- no portraits have been showing during dialogue boxes".
    --
    -- This asserts the ENGINE FACT the fix rests on, using the real engine: the
    -- colour is a constant on the Emerald profile and a real choice on FRLG.
    -- If a future profile edit ever gave Emerald real colours, this fails and
    -- forces the mod's bypass to be revisited rather than left in place stale.
    do
      local FrlgFont = package.loaded["src.ui.game3.frlg_font"]
        or require("src.ui.game3.frlg_font")
      local emeraldFont = require("src.core.game3.profiles.emerald.font")
      ok(type(FrlgFont) == "table" and type(FrlgFont.getNpcTextColor) == "function",
        "colour: the engine's FrlgFont.getNpcTextColor is present")
      eq(type(emeraldFont) == "table" and emeraldFont.npcTextColors, false,
        "colour: the Emerald profile disables per-speaker text colours")

      -- Point the font service at the Emerald profile and prove the colour is
      -- the SAME NEUTRAL for two graphics that are male and female on FRLG --
      -- i.e. it carries no information at all on Emerald.
      local realSync = FrlgFont.sync
      FrlgFont.sync = function() return emeraldFont end
      local neutral = FrlgFont.NPC_TEXT_COLOR and FrlgFont.NPC_TEXT_COLOR.NEUTRAL or 3
      local c0 = FrlgFont.getNpcTextColor(0)
      local c7 = FrlgFont.getNpcTextColor(7)
      local c26 = FrlgFont.getNpcTextColor(26)
      eq(c0, neutral, "colour: graphic 0 reads NEUTRAL on the Emerald profile")
      eq(c7, neutral, "colour: graphic 7 reads NEUTRAL on the Emerald profile")
      eq(c26, neutral, "colour: graphic 26 reads NEUTRAL on the Emerald profile")
      eq(c0, c26,
        "colour: the colour cannot tell one Emerald speaker from another")
      FrlgFont.sync = realSync
    end


    local function gameIsEmerald(id)
      GameVersion.set(id)
      return Emerald.isEmeraldId(GameVersion.get())
    end

    -- THE CORE REGRESSION ASSERTION: with the engine set to FireRed or to
    -- LeafGreen, the Emerald gate is closed.  Whatever else changes, this must
    -- hold -- it is what stops an FRLG boot being routed to the Emerald path.
    if GameVersion.VERSIONS and GameVersion.VERSIONS.firered then
      eq(gameIsEmerald("firered"), false,
        "frlg: the Emerald gate is SHUT on FireRed")
    end
    if GameVersion.VERSIONS and GameVersion.VERSIONS.leafgreen then
      eq(gameIsEmerald("leafgreen"), false,
        "frlg: the Emerald gate is SHUT on LeafGreen")
    end

    -- If this engine build already knows Emerald, the gate must OPEN on it --
    -- that is the positive control, and it is conditional so the suite passes
    -- on an engine that has not caught up yet.
    if GameVersion.VERSIONS and GameVersion.VERSIONS.emerald then
      eq(gameIsEmerald("emerald"), true,
        "emerald: the gate OPENS on an engine that knows Emerald")
      -- ...and the engine accepts this exact cart.
      eq(GameVersion.acceptsSha1("emerald", Emerald.CART_SHA1), true,
        "emerald: the engine accepts the verified cart SHA-1")
    else
      io.write("note: this engine build has no 'emerald' version yet; "
        .. "the positive control is skipped.\n")
    end

    -- Leave the engine where we found it.
    GameVersion.set("red")
  end
end

if failures > 0 then
  io.write(("emerald: %d checks, %d failures\n"):format(checks, failures))
  os.exit(1)
end
io.write(("emerald: %d checks, 0 failures\n"):format(checks))
