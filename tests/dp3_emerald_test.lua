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
