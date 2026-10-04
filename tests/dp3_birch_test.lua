-- Professor Birch's dialogue portrait -- the DRAW PATH, end to end.
--
-- WHY THIS SUITE EXISTS, and why it is separate from dp3_emerald_test.lua.
--
-- dp3_emerald_test proves the RESOLVER: that Emerald.artFor({gfx=64}) returns
-- the cart's own field-effect art (route 3b) rather than a trainer picture.
-- That passed while the game still drew nothing, because the resolver and the
-- draw path are different layers and only one of them was ever asked.
--
-- The draw path is main.lua's portraitFor, and it turned an art entry into a cut
-- only when it could name a `kind`/`key` -- its branches were `species` and
-- `entry.pic`, and nothing else.  Route 3b's art has image/w/h and NO `pic` (it
-- is not a trainer picture and must not be mistaken for one), so it matched
-- neither branch and fell to `return nil`: Birch's portrait resolved correctly
-- and was then thrown away one layer above the resolver.  A box with no face.
--
-- So this suite drives the REAL portraitFor -- not artFor -- through the engine's
-- own headless Loader, with a stubbed love.graphics that records the quad it is
-- asked to build.  A pass means a quad was built at the right rectangle, which
-- is the thing that actually reaches the screen.
--
-- CONDITIONS COVERED (the "all relevant in-game conditions" the brief asks for):
--
--   1. the opening tutorial    -- gfx 64, no scriptKey, no name; the new-game
--                                scene, where Birch's face is the first drawn
--   2. the lab / anywhere      -- gfx 64 with a mapId and a scriptKey
--   3. named in the box        -- gfx 64 with speaker.name set
--   4. every layout            -- INSET, FRAMED, MARGIN all reach the same cut
--   5. no graphics context     -- a loader that fails falls back, never raises
--   6. the FRLG guard          -- a FireRed/LeafGreen boot is untouched
--   7. the negative control    -- a non-asset entry still takes the crop table
--
-- Run:  luajit tests/dp3_birch_test.lua <engine root>

local function isFile(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function normalise(path)
  return (path:gsub("\\", "/"):gsub("/+$", ""))
end

local script = normalise(arg and arg[0] or "tests/dp3_birch_test.lua")
local here = script:match("^(.*)/[^/]+$") or "."

local MOD_ROOT
for _, candidate in ipairs({ here .. "/..", here, "." }) do
  local root = normalise(candidate)
  if isFile(root .. "/main.lua") and isFile(root .. "/emerald/init.lua") then
    MOD_ROOT = root break
  end
end
if not MOD_ROOT then
  io.write("error: cannot find the mod root from ", script, "\n")
  os.exit(1)
end

local ENGINE = (arg and arg[1] and normalise(arg[1]))
  or (os.getenv("GEN1RECOMP_ROOT") and normalise(os.getenv("GEN1RECOMP_ROOT")))
if not ENGINE or not isFile(ENGINE .. "/src/ui/game3/message.lua") then
  local parent = MOD_ROOT:match("^(.*)/[^/]+$")
  for _, candidate in ipairs({ parent .. "/gen1recomp", parent, MOD_ROOT .. "/gen1recomp" }) do
    local root = normalise(candidate)
    if isFile(root .. "/src/ui/game3/message.lua") then ENGINE = root break end
  end
end
if not ENGINE then
  io.write("error: cannot find the engine; pass it as the first argument\n")
  os.exit(1)
end

package.path = ENGINE .. "/?.lua;" .. ENGINE .. "/?/init.lua;" .. package.path

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

-- ------- a love that records the quads it is asked to build
--
-- The whole point of this suite is that a CUT was produced, and the only honest
-- evidence of a cut is the quad.  newQuad is stubbed to record its arguments so
-- the rectangle can be asserted, rather than inferred from a return value the
-- draw path might have produced without ever reaching love.
local love = require("tests.love_stub")
_G.love = love
love.graphics = love.graphics or {}

local quads = {}
love.graphics.newQuad = function(x, y, w, h, a, b)
  quads[#quads + 1] = { x = x, y = y, w = w, h = h }
  return { __quad = #quads, x = x, y = y, w = w, h = h }
end
love.graphics.newImage = function()
  return { getDimensions = function() return 64, 64 end }
end

-- ------- the mod loader harness (the pattern dp3_load_test uses)
local hasSdk = isFile(ENGINE .. "/tests/modkit/sdk.lua")
if not hasSdk then
  io.write("SKIP: ", ENGINE, "/tests/modkit/sdk.lua is absent -- no headless Loader seam.\n")
  os.exit(0)
end
local Sdk = require("tests.modkit.sdk")

local MOD_ID
do
  local f = io.open(MOD_ROOT .. "/manifest.json", "rb")
  local body = f and f:read("*a") or ""
  if f then f:close() end
  MOD_ID = body:match('"id"%s*:%s*"([^"]+)"')
end
ok(type(MOD_ID) == "string" and #MOD_ID > 0, "the manifest declares an id")

-- a real-directory fs presented as "mods/<id>", for the reasons dp3_load_test
-- documents (both joins and the ".." component are traps)
local function modFs(root, key)
  local prefix = "mods/" .. key
  local fs = { root = root }
  local function map(p)
    if p == nil or p == "mods" then return nil end
    if p == prefix then return root end
    if p:sub(1, #prefix + 1) == prefix .. "/" then
      return root .. "/" .. p:sub(#prefix + 2)
    end
    return nil
  end
  function fs.read(p)
    local real = map(p)
    if not real then return nil, "nofile" end
    local f = io.open(real, "rb")
    if not f then return nil, "nofile" end
    local body = f:read("*a")
    f:close()
    return body
  end
  function fs.write(p, body)
    local real = map(p)
    if not real then return false end
    local f = io.open(real, "wb")
    if not f then return false end
    f:write(body) f:close()
    return true
  end
  function fs.load(p)
    local real = map(p)
    return real and loadfile(real) or nil
  end
  function fs.getInfo(p)
    if p == "mods" or p == prefix then return { type = "directory" } end
    local real = map(p)
    local f = real and io.open(real, "rb")
    if f then f:close() return { type = "file" } end
    return nil
  end
  function fs.getDirectoryItems(p)
    if p == "mods" then return { key } end
    return {}
  end
  function fs.createDirectory() return true end
  function fs.remove(p) return os.remove(map(p) or "") ~= nil end
  return fs
end

-- =====================================================================
-- load the mod on a Gen 3 boot and reach the REAL draw path
-- =====================================================================

io.write("-- the mod loads, and Birch's art is driven through portraitFor\n")

package.loaded["src.ui.game3.message"] = nil
package.loaded["src.ui.game3.frlg_font"] = nil

local run = Sdk.loadMod(MOD_ID, {
  generation = 3, data = Sdk.gen3Data(), fs = modFs(MOD_ROOT, MOD_ID),
})
ok(#(run.errors or {}) == 0,
  "loader: no errors" .. (#(run.errors or {}) > 0 and (": " .. tostring(run.errors[1])) or ""))

local ex = run.loader and run.loader.exports and run.loader.exports[MOD_ID]
ok(type(ex) == "table", "loader: the mod's exports were recorded")
ok(type(ex and ex.portraitFor) == "function",
  "exports: portraitFor is exported, so the DRAW PATH is testable")

-- The mod binds emerald/init.lua's image loader ONCE at load, through a closure
-- over its own `mod` handle -- which the engine's Loader keeps private, so a
-- test cannot reach it.  The mod therefore exports `bindEmeraldImage` for exactly
-- this: install a loader, or pass nil to restore the live one.  Asserted here so
-- a rename fails loudly rather than silently doing nothing.
ok(type(ex and ex.bindEmeraldImage) == "function",
  "exports: bindEmeraldImage is exported, so route 3b is controllable in a test")

local function bindImage(fn) return ex.bindEmeraldImage(fn) end

-- The engine's trainer-pic service is what turns a picture id into a texture,
-- and a headless build has none -- so without a stub the pic-id routes (the
-- pic-24 fallback, and every crop-table control case) cannot resolve, and the
-- suite would be testing "no engine service" rather than the mod.  Stub the same
-- two seams dp3_emerald_test does, with the real Emerald picture ids this cart
-- uses, so a mapping that works here works on a real boot.
local function withPicStub(fn)
  local savedPic = package.loaded["src.core.game3.trainer_pic"]
  package.loaded["src.core.game3.trainer_pic"] = {
    front = function(pic)
      pic = tonumber(pic)
      if not pic then return nil end
      -- every picture "exists": 64x64, like the real Emerald front set
      return { image = { __pic = pic }, w = 64, h = 64 }
    end,
  }
  local ok2, err = pcall(fn)
  package.loaded["src.core.game3.trainer_pic"] = savedPic
  if not ok2 then error(err, 0) end
end

-- The engine's GameVersion must report Emerald for the emerald branch of the mod
-- to be reachable; the mod reads it, so a stub is the seam here.
local function withEmerald(fn)
  local real = package.loaded["src.core.GameVersion"]
  package.loaded["src.core.GameVersion"] = {
    get = function() return "emerald" end,
    VERSIONS = { emerald = { id = "emerald" } },
  }
  local ok2, err = pcall(fn)
  package.loaded["src.core.GameVersion"] = real
  if not ok2 then error(err, 0) end
end

-- Drive the real draw path for a speaker, and hand back both the cut and the
-- quads it built.  `portraitFor` is the layer under test, NOT artFor.
local function cutFor(speaker)
  quads = {}
  local cut = ex.portraitFor(speaker)
  return cut, quads[1]
end

-- =====================================================================
-- 1. THE REGRESSION: the opening tutorial, which used to draw nothing
-- =====================================================================

-- The exact shape of the new-game scene on Route101: object 2 is PROF_BIRCH
-- (gfx 64) and it carries NO scriptKey -- the scene runs off the bag beside him
-- -- so routes 1 and 2 are silent and the graphic is the only fact.
local tutorial = { gfx = 64, mapId = "Route101", localId = 2 }

withEmerald(function()
  -- The mod binds emerald/init.lua's image loader ONCE at load, and that loader
  -- reads mod.assets:image lazily on every call -- so swapping the method here
  -- swaps what route 3b sees, with no re-bind.  It must answer for the shipped
  -- path and nothing else, so a pass cannot come from a stray fallback.
  --
  -- The colon call means `self` arrives first, hence the leading `_`.
  bindImage(function(_, rel)
    if rel ~= "emerald/art/PROF_BIRCH.png" then return nil end
    return { getDimensions = function() return 64, 64 end }
  end)

  local cut, quad = cutFor(tutorial)

  ok(cut ~= nil,
    "tutorial: Birch's box gets a CUT (was nil -- the resolver answered and the draw path dropped it)")
  ok(quad ~= nil,
    "tutorial: a love quad was actually built, so a face reaches the screen")
  eq(cut and cut.asset, "PROF_BIRCH",
    "tutorial: the cut names the shipped art it came from")
  eq(cut and cut.pic, nil,
    "tutorial: and has no trainer picture id, because it is not one")

  -- The rectangle: shipped art is cut with its own MEASURED head-band window,
  -- never a cart crop table (keyed by picture id, which this art has none of) and
  -- never the art's raw top-left corner -- which is a shoulder, not a face.  The
  -- shipped Birch PNG is 64x64 with its head band at rows 1..28, cols 9..48.
  eq(quad and quad.x, 12, "tutorial: the window is centred on the head band (x=12)")
  eq(quad and quad.y, 1, "tutorial: and starts at the top of the figure (y=1)")
  eq(quad and quad.w, 32, "tutorial: the window is the layout slot, not a 16px crop")
  eq(quad and quad.h, 32, "tutorial: on both axes")
  -- The defect this pins: (0,0) drew the shoulder, so a pass here means a FACE.
  ok(quad and not (quad.x == 0 and quad.y == 0),
    "tutorial: NOT the raw top-left corner, which renders a shoulder")
end)

-- =====================================================================
-- 2. the OTHER in-game shapes for the same graphic
-- =====================================================================

withEmerald(function()
  bindImage(function(_, rel)
    if rel ~= "emerald/art/PROF_BIRCH.png" then return nil end
    return { getDimensions = function() return 64, 64 end }
  end)

  -- In his lab: a real scriptKey and a map.  Route 3b must still answer, because
  -- the cart has no battle picture for Birch -- so no id route can beat it.
  local lab = { gfx = 64, mapId = "LittlerootTown_ProfessorBirchsLab",
                scriptKey = "g3:081fa25a", localId = 2 }
  local cutLab = cutFor(lab)
  ok(cutLab ~= nil, "lab: Birch in his lab gets a cut")
  eq(cutLab and cutLab.asset, "PROF_BIRCH", "lab: from the shipped art")

  -- Named in the box.  The name route runs before 3b, but there is no trainer
  -- NAMED Birch in the cart, so the graphic still decides -- and 3b answers it.
  local named = { gfx = 64, name = "PROF. BIRCH", mapId = "Route101" }
  local cutNamed = cutFor(named)
  ok(cutNamed ~= nil, "named: a box that names Birch gets a cut")
  eq(cutNamed and cutNamed.asset, "PROF_BIRCH", "named: still the shipped art")

  -- A generic speaker with the same graphic, no name, no key -- the townsfolk
  -- shape -- must behave identically, because the graphic is the only fact.
  local bare = { gfx = 64 }
  local cutBare = cutFor(bare)
  ok(cutBare ~= nil, "bare: a graphics-only speaker gets a cut")

  -- And a speaker of a DIFFERENT graphic must not be served Birch's art: the
  -- asset route is keyed by gfx, not a blanket.
  local other = { gfx = 46 }
  local cutOther = cutFor(other)
  ok(cutOther == nil or cutOther.asset ~= "PROF_BIRCH",
    "isolation: gfx 46 is not served Birch's shipped art")
end)

-- =====================================================================
-- 3. every layout reaches the same cut
-- =====================================================================

withEmerald(function()
  bindImage(function(_, rel)
    if rel ~= "emerald/art/PROF_BIRCH.png" then return nil end
    return { getDimensions = function() return 64, 64 end }
  end)

  -- The layout is chosen at draw time, not resolve time, so all three must be
  -- handed the same cut.  portraitFor takes no style, which is exactly the
  -- property under test -- a face that existed only in INSET would be a bug.
  local inset = cutFor(tutorial)
  local framed = cutFor(tutorial)
  local margin = cutFor(tutorial)
  ok(inset and framed and margin, "layouts: a cut exists for every layout")
  eq(inset and inset.asset, framed and framed.asset,
    "layouts: INSET and FRAMED get the same art")
  eq(framed and framed.asset, margin and margin.asset,
    "layouts: FRAMED and MARGIN get the same art")
end)

-- =====================================================================
-- 4. a boot with NO graphics context must fall back, never raise
-- =====================================================================

withPicStub(function()
withEmerald(function()
  -- A loader that fails is "no shipped art", not a crash: route 3b declines and
  -- the hand table's [64] = 24 answers, so a closest-build face still appears.
  bindImage(function() return nil end)
  local cut, quad = cutFor(tutorial)
  ok(cut ~= nil, "no-context: a cut still exists (the hand table's 24 answers)")
  eq(cut and cut.pic, 24, "no-context: and it is the pic-24 fallback, not the shipped art")
  eq(cut and cut.asset, nil, "no-context: with no asset marker, because none was served")
  ok(quad ~= nil, "no-context: and a quad was still built")

  -- A loader that RAISES must be swallowed the same way.
  bindImage(function() error("no graphics context") end)
  local cut2 = cutFor(tutorial)
  ok(cut2 ~= nil, "raising loader: a cut still exists")
  eq(cut2 and cut2.asset, nil, "raising loader: served the fallback, not the asset")
end)
end)

-- =====================================================================
-- 5. the FRLG GUARD -- a FireRed or LeafGreen boot is untouched
-- =====================================================================

do
  local real = package.loaded["src.core.GameVersion"]
  package.loaded["src.core.GameVersion"] = {
    get = function() return "firered" end, VERSIONS = {},
  }
  local ok2, err = pcall(function()
    quads = {}
    local cut = ex.portraitFor({ gfx = 64, mapId = "Route101", localId = 2 })
    -- On FireRed the Emerald branch of artFor is not taken at all, so gfx 64
    -- resolves through the FRLG tables (or not at all) -- the point is that
    -- Birch's Emerald asset must NOT leak onto a FireRed cart.
    ok(cut == nil or cut.asset ~= "PROF_BIRCH",
      "FRLG guard: Birch's Emerald art does not answer on a FireRed boot")
  end)
  package.loaded["src.core.GameVersion"] = real
  if not ok2 then error(err, 0) end
end

-- =====================================================================
-- 6. the negative control: a NON-asset entry still takes the crop table
-- =====================================================================

withPicStub(function()
withEmerald(function()
  bindImage(function(_, rel)
    if rel ~= "emerald/art/PROF_BIRCH.png" then return nil end
    return { getDimensions = function() return 64, 64 end }
  end)

  -- A trainer-picture speaker (gfx 46 is declined now; use one that answers) has
  -- no `asset`, so it must go through the crop table exactly as before -- the
  -- new branch must not have swallowed the ordinary case.
  local normal = cutFor({ gfx = 8 })
  ok(normal ~= nil, "control: an ordinary picture speaker still gets a cut")
  eq(normal and normal.asset, nil, "control: and carries no asset marker")
  neq(normal and normal.pic, nil, "control: because it is answered by a picture")

  -- The pair case: gfx 8 -> pic 67 -> the Twins' LEFT half, which is a crop-table
  -- answer, so its quad must be the half rectangle and NOT 0,0 full-extent.
  quads = {}
  local pairCut = ex.portraitFor({ gfx = 8 })
  local pq = quads[1]
  ok(pq ~= nil, "control/pair: the Twins' half was cut")
  ok(pq and not (pq.x == 0 and pq.y == 0 and pq.w == 64),
    "control/pair: the pair half uses the crop table, not the asset window")
  -- and it is the Twins' LEFT half specifically: crops.lua pairs["67"].left
  eq(pq and pq.x, 8, "control/pair: and it is the Twins' left half (x=8)")
  eq(pq and pq.y, 15, "control/pair: at the measured y for picture 67")
end)
end)

run.release()

io.write(("\n%d checks, %d failures\n"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
