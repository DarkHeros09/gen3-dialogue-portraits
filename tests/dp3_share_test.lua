-- Emerald BORROWING a FireRed bust -- route 7, end to end.
--
-- WHY THIS SUITE EXISTS, and why it is separate from the other Emerald suites.
--
-- dp3_emerald_test proves the RESOLVER answers an Emerald speaker from Emerald
-- data.  dp3_birch_test proves the DRAW PATH turns a route-3b ASSET into a quad.
-- Neither touches route 7, which is the one route whose art comes from the OTHER
-- cart: emerald/frlg_share.lua maps 13 Emerald GRAPHICS (the kinds the Emerald
-- cart never drew a bust of) onto FireRed FRONT-PIC ids, and emerald/init.lua's
-- shareArtFor reads that picture out of the FIRERED cache and hands main.lua a
-- texture.
--
-- Route 7 has four independent ways to be wrong, and a bare box on screen hides
-- all four, so each is pinned here:
--
--   1. it must FIRE where it is meant to   -- a gap graphic (46 SCIENTIST_1)
--      borrows FireRed picture 107 when a FireRed cache and factory are present
--   2. it must be keyed by GRAPHIC, not id -- the two carts' id spaces diverge
--      (Emerald's HIKER is pic 0; FireRed's pic 0 is the AQUA LEADER), so a
--      borrowed id must never be read as an Emerald one and vice versa.  The one
--      measurement that matters most: an Emerald graphic in the hand table is
--      NOT borrowed, and a graphic routed to Emerald's HIKER never becomes
--      FireRed's Archie.
--   3. it must CUT by the FIRERED table   -- a borrowed entry carries a FireRed
--      picture id, so its window must come from art/crops.lua, NOT from the
--      Emerald table the boot would otherwise select.  Picture 35 is pinned for
--      exactly this: FireRed files it {13,18,32} and Emerald files it {19,4,32},
--      so a mis-routed table is a visibly different rectangle, not a subtle one.
--   4. it must be the SAFE ANSWER when it cannot run -- no FireRed cache, no
--      image factory, no entry: nil, never a crash and never a wrong Emerald
--      face.  And on a FireRed boot, none of it may run at all.
--
-- Run:  luajit tests/dp3_share_test.lua <engine root>

local function isFile(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function normalise(path)
  return (path:gsub("\\", "/"):gsub("/+$", ""))
end

local script = normalise(arg and arg[0] or "tests/dp3_share_test.lua")
local here = script:match("^(.*)/[^/]+$") or "."

local MOD_ROOT
for _, candidate in ipairs({ here .. "/..", here, "." }) do
  local root = normalise(candidate)
  if isFile(root .. "/main.lua") and isFile(root .. "/emerald/frlg_share.lua") then
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

-- ------- a love that records the quads it is asked to build
--
-- A pass is a QUAD at the right rectangle -- the thing that reaches the screen
-- -- so newQuad is stubbed to record its arguments, exactly as dp3_birch_test
-- does.
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

-- ------- the mod loader harness (the pattern dp3_birch_test uses)
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

-- The engine's GameVersion must report Emerald for the emerald branch to be
-- reachable; the mod reads it, so a stub is the seam.
--
-- IT MUST BE INSTALLED BEFORE THE MOD'S FIRST isEmeraldBoot() CALL.  main.lua
-- caches `Emerald.detectGameId()` in a closure variable on the first call and
-- never asks again ("a mod's own table cannot appear or vanish mid-session" --
-- the same reasoning emerald/init.lua gives for its table cache).  So a suite
-- that swapped GameVersion in *after* the first portraitFor call would have no
-- effect at all, and the assertions would fail for a reason that has nothing to
-- do with route 7.  This suite therefore SETS THE BOOT ONCE, immediately after
-- Sdk.loadMod and before any portraitFor, and leaves it set for every Emerald
-- case -- which is also what a real run looks like: the game does not change
-- mid-session.  (The FRLG guard loads a SECOND instance with the stub in place
-- before it loads, for the same reason.)
local _savedGV = package.loaded["src.core.GameVersion"]
local function setGame(id)
  package.loaded["src.core.GameVersion"] = {
    get = function() return id end,
    VERSIONS = { [id] = { id = id, cachePrefix = id .. "/" } },
    info = function(v) return { cachePrefix = (v or id) .. "/" } end,
  }
end
local function restoreGame() package.loaded["src.core.GameVersion"] = _savedGV end
local function withEmerald(fn)
  setGame("emerald")
  local ok2, err = pcall(fn)
  if not ok2 then error(err, 0) end
end

io.write("-- route 7: an Emerald graphic borrows a FireRed bust\n")

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
ok(type(ex and ex.bindEmeraldShareImage) == "function",
  "exports: bindEmeraldShareImage is exported, so route 7 is controllable in a test")

local function bindShare(fn) return ex.bindEmeraldShareImage(fn) end

-- THE BOOT IS DECLARED HERE, before the mod's first portraitFor: main.lua caches
-- the detected game on first use (see setGame's comment above).  Everything below
-- runs on this Emerald boot except the FRLG-guard block, which re-declares.
setGame("emerald")

-- The mod's own share table, read straight from disk so the test asserts the
-- SHIPPED file rather than a fixture that could drift from it.
local SHARE
do
  local f = io.open(MOD_ROOT .. "/emerald/frlg_share.lua", "rb")
  local src = f and f:read("*a"); if f then f:close() end
  local chunk = src and load(src, "@emerald/frlg_share.lua")
  SHARE = chunk and chunk()
end
ok(type(SHARE) == "table", "share: emerald/frlg_share.lua loads")

-- The mod's own Emerald hand table (gfx_art_people.lua) and the FireRed crop
-- table, read from disk: the KEYED-BY-GRAPHIC property and the crop-origin
-- property are both about these files, so the assertions use the real ones.
local PEOPLE, FRLG_CROPS
do
  local f = io.open(MOD_ROOT .. "/emerald/gfx_art_people.lua", "rb")
  local src = f and f:read("*a"); if f then f:close() end
  local chunk = src and load(src, "@emerald/gfx_art_people.lua")
  PEOPLE = chunk and chunk()

  local c = io.open(MOD_ROOT .. "/art/crops.lua", "rb")
  local csrc = c and c:read("*a"); if c then c:close() end
  local cchunk = csrc and load(csrc, "@art/crops.lua")
  FRLG_CROPS = cchunk and cchunk()
end
ok(type(PEOPLE) == "table", "people: emerald/gfx_art_people.lua loads")
ok(type(FRLG_CROPS) == "table" and type(FRLG_CROPS.trainers) == "table",
  "crops: art/crops.lua loads with a trainers table")

-- The FireRed cache + picture service, stubbed as a seam.
--
-- In a real boot, CacheFs.readAt("firered/data/generated/gba/trainers/front/
-- <pic>.rgba") returns 16384 bytes when FireRed has been imported.  There is no
-- such cache headless, so the suite installs one: a CacheFs whose readAt answers
-- a full 64x64 RGBA for the pictures the share table names, and nil for anything
-- else -- which is exactly the shape of "FireRed imported, and the picture is
-- there / is not".  `opts.imported` defaults to TRUE (an imported FireRed is the
-- common case); pass `{ imported = false }` to simulate a FireRed never imported.
local function withFireRedCache(fn, opts)
  opts = opts or {}
  local imported = (opts.imported ~= false)
  local savedCache = package.loaded["src.import.CacheFs"]
  local asked = {}
  package.loaded["src.import.CacheFs"] = {
    readAt = function(rel)
      asked[#asked + 1] = rel
      if not imported then return nil end               -- never imported
      local pic = rel:match("/front/(%d+)%.rgba$")
      if not pic then return nil end
      pic = tonumber(pic)
      if opts.missing and opts.missing[pic] then return nil end
      return string.rep("\0", 64 * 64 * 4)
    end,
  }
  local ok2, err = pcall(fn, asked)
  package.loaded["src.import.CacheFs"] = savedCache
  if not ok2 then error(err, 0) end
end

-- The engine's trainer-pic service turns a picture id into a texture; a headless
-- build has none.  Stub the same seam the other Emerald suites stub, so the
-- hand-table and statistical routes can resolve and a test of "is this graphic
-- borrowed?" is not confounded by "no engine service".  Every picture "exists".
local function withPicStub(fn)
  local saved = package.loaded["src.core.game3.trainer_pic"]
  package.loaded["src.core.game3.trainer_pic"] = {
    front = function(pic)
      pic = tonumber(pic)
      if not pic then return nil end
      return { image = { __pic = pic }, w = 64, h = 64 }
    end,
  }
  local ok2, err = pcall(fn)
  package.loaded["src.core.game3.trainer_pic"] = saved
  if not ok2 then error(err, 0) end
end

-- Drive the real draw path for a speaker; hand back both the cut and the first
-- quad the frame built.
local function cutFor(speaker)
  quads = {}
  local cut = ex.portraitFor(speaker)
  return cut, quads[1]
end

-- =====================================================================
-- PART A -- the SHIPPED TABLE: keyed by graphic, and honest about its gaps
-- =====================================================================

-- 13 measured entries, one per graphic the Emerald cart declines AND FireRed
-- drew.  Pin the count and the headline value (the Scientist) so a future edit
-- that silently drops or repoints the table fails loudly.
do
  local n = 0
  for _ in pairs(SHARE) do n = n + 1 end
  eq(n, 13, "table: frlg_share.lua holds the 13 measured borrowings")
  eq(SHARE[46], 107, "table: SCIENTIST_1 (gfx 46) borrows FireRed picture 107")
  eq(SHARE[22], 35, "table: EXPERT_F (gfx 22) borrows FireRed 35")
  eq(SHARE[116], 107, "table: DEVON_EMPLOYEE (gfx 116) borrows the same lab coat")
  -- the three values CORRECTED after re-rendering the art against the FRLG
  -- cache: the receptionist off the red TEAM MAGMA girl, the two hatted men off
  -- the aged cane-figure.  Pinned so a future edit cannot silently revert them.
  eq(SHARE[28], 51, "table: LINK_RECEPTIONIST is the green-capped PICNICKER 51, not Magma 64")
  eq(SHARE[27], 23, "table: COOK is the hatted GENTLEMAN 23, not the aged 123")
  eq(SHARE[223], 23, "table: MYSTERY_GIFT_MAN is the hatted GENTLEMAN 23")

  -- Every key is a numeric Emerald graphic id and every value a numeric FireRed
  -- picture id, or the lookups in shareArtFor would silently miss.
  local bad = 0
  for k, v in pairs(SHARE) do
    if type(k) ~= "number" or type(v) ~= "number" or v < 0 then bad = bad + 1 end
  end
  eq(bad, 0, "table: every graphic maps to a numeric FireRed picture id")

  -- THE CENTRAL DESIGN PROPERTY, asserted file-to-file: no graphic in the share
  -- table is one the Emerald hand table ANSWERS with a picture.  A graphic the
  -- hand table resolves is real Emerald art and must outrank a borrowed face; the
  -- share table must therefore name only graphics the cart has NO answer for --
  -- in practice the 13 it DECLINES with `false`.  (`false` is a decline, not an
  -- answer: it says "this cart drew no bust", which is exactly the precondition
  -- a borrow fills.  An ANSWER -- a number -- is the case that must never be
  -- borrowed over.)
  local answered, declined, absent = 0, 0, 0
  for gfx in pairs(SHARE) do
    local v = PEOPLE[gfx]
    if v == false then declined = declined + 1
    elseif v ~= nil then answered = answered + 1
    else absent = absent + 1 end
  end
  eq(answered, 0,
    "table: no borrowed graphic is one the hand table ANSWERS with a picture")
  eq(declined, 13,
    "table: every borrowed graphic is one the hand table DECLINES with false")
  eq(absent, 0,
    "table: (and none is absent from the hand table -- borrowing fills a decline)")
end

-- =====================================================================
-- PART B -- route 7 FIRES, and is keyed by GRAPHIC
-- =====================================================================

withEmerald(function()
  withFireRedCache(function(asked)
    -- A factory that proves it was handed 16384 bytes and a 64x64 shape, and
    -- returns a distinguishable stub image.
    bindShare(function(bytes, w, h)
      ok(#bytes == 64 * 64 * 4, "fire: the factory was handed a full 64x64 RGBA")
      eq(w, 64, "fire: and a width of 64")
      eq(h, 64, "fire: and a height of 64")
      return { __shared = true, getDimensions = function() return 64, 64 end }
    end)

    -- gfx 46 SCIENTIST_1 is declined by the hand table; with a FireRed cache it
    -- must borrow FireRed picture 107.
    local cut, quad = cutFor({ gfx = 46, mapId = "LittlerootTown", localId = 5 })
    ok(cut ~= nil, "fire: gfx 46 (SCIENTIST_1) gets a cut once FireRed is imported")
    eq(cut and cut.pic, 107, "fire: and it is FireRed picture 107")
    eq(cut and cut.share, "firered", "fire: and it is marked as borrowed from FireRed")
    ok(quad ~= nil, "fire: a love quad was actually built, so a face reaches the screen")

    -- The cache was asked for the picture by its PREFIXED path -- the whole
    -- point of reading another version's cache explicitly.  The path is
    -- "<version prefix> <engine cache root> /trainers/front/<pic>.rgba": the
    -- prefix is FireRed's, the root is derived from the engine's own module (not
    -- written in the mod), and the subpath is the mod's constant.  This asserts
    -- the pieces WITHOUT hard-coding the generated-tree root, so the test cannot
    -- drift from the engine's CACHE_ROOT.
    local CachePaths = require("src.core.game3.cache_paths")
    local wanted
    for _, rel in ipairs(asked) do
      if rel:match("%.rgba$") and rel:find("107", 1, true) then wanted = rel end
    end
    ok(wanted ~= nil, "fire: the FireRed cache was read for the borrowed picture")
    if wanted then
      eq(wanted, "firered/" .. CachePaths.CACHE_ROOT .. "/trainers/front/107.rgba",
        "fire: by its version-qualified path, derived from the engine's own root")
      -- the prefix really is FireRed's, not the boot's own game
      ok(wanted:sub(1, 8) == "firered/",
        "fire: and the version prefix is FireRed's, not the Emerald boot's")
    end
  end)
end)

-- KEYED BY GRAPHIC, NOT ID -- the one fact the whole table exists to respect.
withPicStub(function()
withEmerald(function()
  withFireRedCache(function()
    bindShare(function() return { getDimensions = function() return 64, 64 end } end)

    -- gfx 55 HIKER is answered by Emerald's hand table as picture 0 (Emerald's
    -- HIKER).  It must NOT be borrowed: route 7 runs after the hand table, and
    -- FireRed's picture 0 is the AQUA LEADER -- the HIKER-wearing-Archie bug.
    local hiker = cutFor({ gfx = 55 })
    ok(hiker ~= nil, "graphic-key: the HIKER still resolves on Emerald")
    eq(hiker and hiker.share, nil,
      "graphic-key: the HIKER is NOT borrowed, so it cannot become FireRed's Archie")
    eq(PEOPLE[55], 0, "graphic-key: the hand table answers the HIKER as Emerald picture 0")
    eq(hiker and hiker.pic, 0, "graphic-key: and the HIKER keeps Emerald picture 0")

    -- A graphic the hand table DECLINES with `false` is the subtle case, and it
    -- is worth stating because it looks like it should block borrowing but does
    -- not.  gfx 58 (NURSE) is `false` in the hand table -- "the cart drew no
    -- nurse bust" -- but `false` is a DECLINE (no Emerald answer), not a
    -- prohibition on borrowing; frlg_share.lua exists precisely to supply the
    -- 13 kinds the cart declined.  So gfx 58 is present there, and with a
    -- FireRed cache it MUST borrow.
    eq(PEOPLE[58], false, "graphic-key: the hand table declines gfx 58 (NURSE)")
    eq(SHARE[58], 126, "graphic-key: and the share table supplies it from FireRed 126")
    local nurse = cutFor({ gfx = 58 })
    ok(nurse ~= nil, "graphic-key: so gfx 58 borrows once FireRed is imported")
    eq(nurse and nurse.pic, SHARE[58], "graphic-key: and it is the share table's picture")

    -- ...and conversely, a graphic ABSENT from the share table is not borrowed.
    -- gfx 1 is a graphic the cart has no trainer for and FireRed is not asked to
    -- supply -- the decline must stand.
    eq(SHARE[1], nil, "graphic-key: gfx 1 is not in the share table")
    local notBorrowed = cutFor({ gfx = 1 })
    ok(notBorrowed == nil or notBorrowed.share == nil,
      "graphic-key: a graphic absent from the share table is NOT borrowed")
  end)
end)
end)

-- =====================================================================
-- PART C -- the borrowed bust is CUT by the FIRERED table
-- =====================================================================
--
-- THE crop-origin property.  A borrowed entry carries a FireRed picture id, so
-- its window must come from art/crops.lua even though the boot is Emerald.
-- Picture 35 is the sharpest witness: FireRed and Emerald file DIFFERENT
-- rectangles under it, so a mis-routed table is a different (x,y), not a subtle
-- one.  (Measured: FRLG {13,18,32}, Emerald {19,4,32}.)
withEmerald(function()
  withFireRedCache(function()
    bindShare(function() return { getDimensions = function() return 64, 64 end } end)

    -- Sanity: the two tables really do disagree on picture 35, or this test
    -- proves nothing.
    eq(FRLG_CROPS.trainers["35"][1], 13, "crops: FireRed files picture 35 at x=13")
    eq(FRLG_CROPS.trainers["35"][2], 18, "crops: and y=18")

    -- gfx 22 EXPERT_F borrows FireRed picture 35.  Its cut must be the FIRERED
    -- rectangle 13,18 -- not Emerald's 19,4.
    local cut, quad = cutFor({ gfx = 22 })
    ok(cut ~= nil, "crops: gfx 22 (EXPERT_F) gets a cut")
    eq(cut and cut.pic, 35, "crops: via FireRed picture 35")
    ok(quad ~= nil, "crops: and a quad was built")
    eq(quad and quad.x, 13, "crops: the window comes from the FIRERED table (x=13)")
    eq(quad and quad.y, 18, "crops: and y=18 -- NOT Emerald's 19,4")
    eq(quad and quad.w, 32, "crops: the window is the 32px slot")
    eq(quad and quad.h, 32, "crops: on both axes")

    -- A SECOND witness, one the Emerald table does not file at all.  FireRed
    -- files picture 107 at {17,1,32}; Emerald has NO entry for 107, so if the cut
    -- had been taken from the Emerald table it would have landed on Emerald's
    -- default {16,1,32} -- x=16.  A pass at x=17 proves the FireRed table was
    -- consulted even for a picture Emerald does not know.
    eq(FRLG_CROPS.trainers["107"][1], 17, "crops: FireRed files picture 107 at x=17")
    local cut107, quad107 = cutFor({ gfx = 46 })  -- 46 -> FireRed 107
    ok(cut107 ~= nil, "crops: the Scientist (FireRed 107) gets a cut")
    eq(quad107 and quad107.x, 17,
      "crops: at the FireRed table's own x=17, not Emerald's default x=16")
    eq(quad107 and quad107.y, 1, "crops: and the FireRed table's y=1")

    -- A borrowed picture NEITHER table files (FireRed 147, from gfx 99 ARTIST)
    -- falls to the FIRERED default {16,3,32} -- the right shape for a FireRed
    -- bust -- not Emerald's default {16,1,32}.  y is the discriminator (3 vs 1).
    ok(not FRLG_CROPS.trainers["147"], "crops: FireRed files no window for picture 147")
    local def = FRLG_CROPS.defaults.trainers
    eq(def[2], 3, "crops: FireRed's trainer default sits at y=3")
    local cutArtist, quadArtist = cutFor({ gfx = 99 })  -- 99 -> FireRed 147
    ok(cutArtist ~= nil, "crops: a borrowed picture with no entry still gets a cut")
    eq(quadArtist and quadArtist.x, def[1], "crops: at the FireRed default x=16")
    eq(quadArtist and quadArtist.y, 3,
      "crops: at the FireRed default y=3 (NOT Emerald's default y=1)")
  end)
end)

-- =====================================================================
-- PART D -- the SAFE ANSWER when route 7 cannot run
-- =====================================================================

-- D1. FireRed never imported: no cache, so every borrowing misses and the
-- Emerald decline stands -- a bare box, never a crash and never a wrong face.
withEmerald(function()
  withFireRedCache(function()
    bindShare(function() return { getDimensions = function() return 64, 64 end } end)
    local cut = cutFor({ gfx = 46 })
    ok(cut == nil or cut.share == nil,
      "no-cache: an unimported FireRed leaves the Scientist declined, not borrowed")
  end, { imported = false })
end)

-- D2. No graphics context to build a texture (an engine build without
-- love.image / love.graphics): route 7 answers nil rather than raising.
--
-- The live factory main.lua binds is emeraldImageFromBytes, and it returns nil
-- when love.image is absent -- so this removes love.image from the stub for the
-- duration and restores the LIVE factory (bindShare(nil) does that), which is
-- exactly the state a headless boot without an image module is in.
withEmerald(function()
  withFireRedCache(function()
    bindShare(nil)   -- restore the live factory (emeraldImageFromBytes)
    local savedImage = love.image
    love.image = nil
    local okcall, cut = pcall(ex.portraitFor, { gfx = 46 })
    love.image = savedImage
    eq(okcall, true, "no-context: portraitFor does not raise without love.image")
    ok(cut == nil or cut.share == nil,
      "no-context: and the Scientist is not served a borrowed face")
    -- restore the live factory for the checks that follow
    ex.bindEmeraldShareImage(nil)
  end)
end)

-- D3. The cache is present but the picture file is short/truncated: a partial
-- entry must MISS, not half-load.  Simulated by a cache that answers a short
-- string for the borrowed picture.
withEmerald(function()
  local savedCache = package.loaded["src.import.CacheFs"]
  package.loaded["src.import.CacheFs"] = {
    readAt = function(rel)
      if rel:match("/front/%d+%.rgba$") then return "\0\0\0\0" end  -- 4 bytes
      return nil
    end,
  }
  bindShare(function() return { getDimensions = function() return 64, 64 end } end)
  local okcall, cut = pcall(ex.portraitFor, { gfx = 46 })
  eq(okcall, true, "short-read: a truncated cache entry does not raise")
  ok(cut == nil or cut.share == nil,
    "short-read: and a short entry misses rather than half-loading")
  package.loaded["src.import.CacheFs"] = savedCache
end)

-- D4. The share table is present but has no entry for the graphic: the Emerald
-- decline stands.  (Also asserted in Part B; repeated here as the boundary of
-- the safe-answer group.)
withEmerald(function()
  withFireRedCache(function()
    bindShare(function() return { getDimensions = function() return 64, 64 end } end)
    local cut = cutFor({ gfx = 200 })  -- a graphic in neither table
    ok(cut == nil or cut.share == nil,
      "no-entry: a graphic in neither table is not borrowed")
  end)
end)

-- =====================================================================
-- PART E -- the FRLG GUARD: a FireRed boot runs none of this
-- =====================================================================
--
-- On a FireRed boot the Emerald branch of artFor is never entered, so route 7
-- -- which lives inside it -- cannot run, and a borrowed Emerald face can never
-- appear from a FireRed resolution.  The engine's Loader refuses a SECOND load
-- of the same mod in one process (the mod's own "already installed" guard), and
-- main.lua caches the detected game on first use, so the honest way to observe
-- the other boot is a FRESH MODULE INSTANCE driven directly -- the same approach
-- dp3_emerald_test's game-guard block takes.  The module's non-Emerald refusal
-- is what actually stands between a FireRed boot and an Emerald borrow; this
-- asserts it on the module, and asserts that even with `force` the SHARE route
-- is not reached when the tables do not name the graphic.

do
  local f = io.open(MOD_ROOT .. "/emerald/init.lua", "rb")
  local source = f and f:read("*a"); if f then f:close() end
  local chunk = source and load(source, "@" .. MOD_ROOT .. "/emerald/init.lua")
  local fresh = chunk and chunk()
  ok(type(fresh) == "table", "FRLG guard: a fresh module instance loads")
  if type(fresh) == "table" then
    fresh.bind({ read = function(rel)
      local fh = io.open(MOD_ROOT .. "/" .. rel, "rb")
      if not fh then return nil end
      local s = fh:read("*a"); fh:close(); return s
    end })
    local savedGV = package.loaded["src.core.GameVersion"]
    local savedCache = package.loaded["src.import.CacheFs"]

    -- everything route 7 needs is PRESENT...
    package.loaded["src.import.CacheFs"] = {
      readAt = function(rel)
        if rel:match("/front/%d+%.rgba$") then return string.rep("\0", 64 * 64 * 4) end
        return nil
      end,
    }
    fresh.bindShareImage(function() return { __shared = true } end)

    -- ...but the running game is FireRed.
    package.loaded["src.core.GameVersion"] =
      { get = function() return "firered" end, VERSIONS = { emerald = {} },
        info = function() return { cachePrefix = "firered/" } end }
    eq(fresh.canDrawPortraits(), false,
      "FRLG guard: canDrawPortraits() is false on FireRed")
    eq(fresh.artFor({ gfx = 46 }), nil,
      "FRLG guard: a FireRed boot gets NO art from the Emerald resolver")
    -- the resolver refuses BEFORE any route, so the share route is not reached
    -- either -- even though gfx 46 IS in the share table and the cache is up.
    eq(fresh.isRunning(), false, "FRLG guard: isRunning() is false on FireRed")

    -- The two boots the brief names must both be refused.
    for _, other in ipairs({ "firered", "leafgreen" }) do
      package.loaded["src.core.GameVersion"] =
        { get = function() return other end, VERSIONS = { emerald = {} },
          info = function() return { cachePrefix = other .. "/" } end }
      eq(fresh.artFor({ gfx = 46 }), nil,
        ("FRLG guard: %s gets NO art from the Emerald resolver"):format(other))
    end

    -- ...while the SAME instance DOES borrow on Emerald -- so the guard refuses
    -- the wrong game without breaking the right one.
    package.loaded["src.core.GameVersion"] =
      { get = function() return "emerald" end, VERSIONS = { emerald = {} },
        info = function() return { cachePrefix = "firered/" } end }
    local a = fresh.artFor({ gfx = 46 })
    ok(type(a) == "table" and a.pic == 107,
      "FRLG guard: the same instance borrows on Emerald (gfx 46 -> 107)")

    package.loaded["src.core.GameVersion"] = savedGV
    package.loaded["src.import.CacheFs"] = savedCache
  end
end

-- =====================================================================
-- PART F -- the resolver property, at the module level
-- =====================================================================
--
-- The draw-path tests above prove route 7 through portraitFor.  This pins the
-- same property on Emerald.artFor directly, so a change that broke the seam
-- between the two layers fails in one place rather than neither.
do
  local f = io.open(MOD_ROOT .. "/emerald/init.lua", "rb")
  local source = f and f:read("*a"); if f then f:close() end
  local fresh = source and load(source, "@" .. MOD_ROOT .. "/emerald/init.lua")
  fresh = fresh and fresh()
  ok(type(fresh) == "table", "resolver: a fresh module instance loads")
  if type(fresh) == "table" then
    fresh.bind({ read = function(rel)
      local fh = io.open(MOD_ROOT .. "/" .. rel, "rb")
      if not fh then return nil end
      local s = fh:read("*a"); fh:close(); return s
    end })
    local savedGV = package.loaded["src.core.GameVersion"]
    local savedCache = package.loaded["src.import.CacheFs"]
    package.loaded["src.core.GameVersion"] =
      { get = function() return "emerald" end, VERSIONS = { emerald = {} },
        info = function() return { cachePrefix = "firered/" } end }
    package.loaded["src.import.CacheFs"] = {
      readAt = function(rel)
        if rel:match("/front/%d+%.rgba$") then return string.rep("\0", 64 * 64 * 4) end
        return nil
      end,
    }

    eq(fresh.SHARE_VERSION, "firered",
      "resolver: the borrow reads from the FireRed cache, by literal")
    eq(fresh.SHARE_PIC_SUB, "/trainers/front/",
      "resolver: the picture subpath is the mod's own constant")
    eq(fresh.FRLG_SHARE_PATH, "emerald/frlg_share.lua",
      "resolver: the share table's path is one literal")
    -- The ROM-derived root is DERIVED, not stored: the mod must not carry the
    -- generated tree as a literal (modkit MK301), so it takes the engine's own.
    eq(fresh.SHARE_PIC_DIR, nil,
      "resolver: the mod does NOT store the ROM-derived cache root as a literal")

    -- No factory bound: shareArtFor declines (the safe answer).
    fresh.bindShareImage(nil)
    eq(fresh.shareArtFor(46), nil,
      "resolver: with no image factory, shareArtFor declines")

    -- A factory bound, a cache present: route 7 answers, in main.lua's shape.
    fresh.bindShareImage(function(bytes, w, h)
      return { __shared = true }
    end)
    local sad = fresh.shareArtFor(46)
    ok(type(sad) == "table" and sad.image ~= nil,
      "resolver: shareArtFor answers with an image once a factory is bound")
    eq(sad and sad.pic, 107, "resolver: and records the FireRed picture id")
    eq(sad and sad.share, "firered", "resolver: and where it borrowed from")
    eq(sad and sad.w, 64, "resolver: at the cart's 64px width")
    eq(sad and sad.h, 64, "resolver: and 64px height")

    -- A graphic absent from the table is not borrowed even with everything up.
    eq(fresh.shareArtFor(200), nil, "resolver: an unfiled graphic is not borrowed")
    eq(fresh.shareArtFor(nil), nil, "resolver: a nil graphic is not borrowed")

    -- shareBytes validates the id and the length.
    ok(fresh.shareBytes(107) ~= nil, "resolver: a full picture reads back its bytes")
    eq(fresh.shareBytes(-1), nil, "resolver: a negative id (FireRed's sentinel) is refused")

    package.loaded["src.core.GameVersion"] = savedGV
    package.loaded["src.import.CacheFs"] = savedCache
  end
end

run.release()

io.write(("\n%d checks, %d failures\n"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
