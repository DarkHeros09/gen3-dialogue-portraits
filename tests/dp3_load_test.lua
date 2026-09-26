-- Load integration -- does the mod actually load, and does it wire its seams?
--
-- The other two suites drive the mod's exported resolvers over hand-built
-- doubles.  Neither one proves the mod LOADS: a manifest the loader rejects, a
-- permission it refuses, a generation it does not claim, or an install that
-- throws inside onLoad would leave both of them green while the game shows no
-- portrait at all.  That is exactly the failure mode this suite exists to catch.
--
-- It goes through the engine's own headless Loader seam (tests/modkit/sdk.lua,
-- the helper the modkit cases use), so what is asserted is the real Loader, the
-- real ModRuntime hook bus, and the real src/ui/game3 modules.
--
-- Phase 1 is a Gen 3 boot: the mod must install everything it claims.
-- Phase 2 is the negative control: a Gen 2 boot must install NOTHING.
-- Without phase 2 every "was replaced" assertion is one-directional -- a harness
-- that never ran the mod satisfies it just as well.
--
-- Run:  luajit tests/dp3_load_test.lua <engine root>

local function isFile(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function isMod(root)
  return isFile(root .. "/main.lua") and isFile(root .. "/art/crops.lua")
end

local function isEngine(root)
  return isFile(root .. "/src/ui/game3/message.lua")
end

local function normalise(path)
  path = path:gsub("\\", "/")
  return (path:gsub("/+$", ""))
end

local script = normalise(arg and arg[0] or "tests/dp3_load_test.lua")
local here = script:match("^(.*)/[^/]+$") or "."

local MOD_ROOT
for _, candidate in ipairs({ here .. "/..", here, "." }) do
  local root = normalise(candidate)
  if isMod(root) then MOD_ROOT = root break end
end
if not MOD_ROOT then
  io.write("error: cannot find the mod root from ", script, "\n")
  os.exit(1)
end

local ENGINE = (arg and arg[1] and normalise(arg[1]))
  or (os.getenv("GEN1RECOMP_ROOT") and normalise(os.getenv("GEN1RECOMP_ROOT")))
if not ENGINE or not isEngine(ENGINE) then
  local parent = MOD_ROOT:match("^(.*)/[^/]+$")
  for _, candidate in ipairs({ parent .. "/gen1recomp", parent, MOD_ROOT .. "/gen1recomp" }) do
    local root = normalise(candidate)
    if isEngine(root) then ENGINE = root break end
  end
end
if not ENGINE or not isEngine(ENGINE) then
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

-- ------- the stub love
local love = require("tests.love_stub")
_G.love = love
love.graphics = love.graphics or {}
if not love.graphics.newImage then
  love.graphics.newImage = function()
    return { getDimensions = function() return 64, 64 end }
  end
end

-- The SDK is an engine test helper, not part of the runtime.  Say so plainly
-- rather than letting a missing require look like a mod failure.
local hasSdk = isFile(ENGINE .. "/tests/modkit/sdk.lua")
if not hasSdk then
  io.write("SKIP: ", ENGINE, "/tests/modkit/sdk.lua is absent, so the engine has no\n")
  io.write("      headless Loader seam to drive.  This suite needs engine 0.3.0+.\n")
  os.exit(0)
end
local Sdk = require("tests.modkit.sdk")

-- ------- what we are loading
local MOD_ID
do
  local f = io.open(MOD_ROOT .. "/manifest.json", "rb")
  local body = f and f:read("*a") or ""
  if f then f:close() end
  MOD_ID = body:match('"id"%s*:%s*"([^"]+)"')
end
ok(type(MOD_ID) == "string" and #MOD_ID > 0, "the manifest declares an id")

-- A real-directory filesystem, written out here rather than borrowed from the
-- engine's FsIo.  Two reasons, both discovered the hard way:
--
--   * FsIo.new joins `base .. "/" .. path`, so a root that is itself absolute
--     produces "./C:/..." and every read returns nil;
--   * FsIo.isDir cannot see a directory through a ".." component --
--     isDir("tests/..") is false while "tests/../manifest.json" reads fine.
--
-- And arg[0] does not survive the .bat luajit shim (it arrives as "luajit"), so
-- the mod root is discovered as "tests/.." and both traps fire at once.  The
-- symptom is "0 mods loaded, 0 errors" -- no error to grep for, because
-- Loader:_discover simply skips a root it cannot stat.
--
-- Presenting the loader a plain "mods/<key>" view sidesteps every one of those
-- joins.  The key is opaque to the loader -- it only ever concatenates it -- so
-- it can just be the mod id.
local function modFs(root, key)
  local prefix = "mods/" .. key
  local fs = { root = root }

  -- Anything outside "mods/<key>" is NOT mapped.  That matters: the loader
  -- persists cart enable state through this fs, so a map that fell through to
  -- the path itself would write options.lua into whatever directory the suite
  -- was launched from.  Refusing is also the shape the engine's own memfs has --
  -- only the provided files exist -- so the loader takes its normal
  -- no-save-yet path.
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
    f:write(body)
    f:close()
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

local function Runtime()
  return package.loaded["src.mods.Runtime"] or require("src.mods.Runtime")
end

local function chains()
  local R = Runtime()
  return R.hooks and R.hooks.chains
end

local function linkCount(name)
  local c = chains()
  local list = c and c[name]
  if type(list) ~= "table" then return -1 end
  return #list
end

local function chainNames()
  local out = {}
  for k in pairs(chains() or {}) do out[#out + 1] = k end
  table.sort(out)
  return out
end

-- A FRESH module table, so a sentinel set by an earlier phase cannot leak into
-- the next one.  `require` hands back the cached table and the mod's install is
-- idempotent through `Message.dp3_wrapped`, so re-requiring is what makes the
-- negative control a real question instead of a tautology.
local function freshDrawModules()
  package.loaded["src.ui.game3.message"] = nil
  package.loaded["src.ui.game3.frlg_font"] = nil
  return require("src.ui.game3.message"), require("src.ui.game3.frlg_font")
end

io.write("-- the mod loads through the engine's real Loader\n")

-- ============================================================ phase 1: Gen 3
local Message, FrlgFont = freshDrawModules()
local vanillaShow, vanillaDraw = Message.show, Message.draw
local vanillaFontDraw = FrlgFont.draw
eq(Message.dp3_wrapped, nil, "the sentinel starts unset")

local run = Sdk.loadMod(MOD_ID, {
  generation = 3, data = Sdk.gen3Data(), fs = modFs(MOD_ROOT, MOD_ID),
})

ok(#(run.errors or {}) == 0,
  "the real loader reports no errors" ..
  (#(run.errors or {}) > 0 and (": " .. tostring(run.errors[1])) or ""))

local ids = {}
for id in pairs(run.mods or {}) do ids[#ids + 1] = id end
table.sort(ids)
eq(#ids, 1, "exactly one mod loaded")
eq(ids[1], MOD_ID, "and it is this mod")
eq(run.mod and run.mod.manifest and run.mod.manifest.id, MOD_ID,
  "the loader's own record agrees on the id")

-- The mod's body ran.  Exports live on the LOADER (`loader.exports[id]`), which
-- is the handle other mods resolve through; `mod.exports` is the mod's own table.
local ex = run.loader and run.loader.exports and run.loader.exports[MOD_ID]
ok(type(ex) == "table", "the loader recorded the mod's exports")
ok(type(ex and ex.speakerFor) == "function", "exports.speakerFor is a function")
ok(type(ex and ex.artFor) == "function", "exports.artFor is a function")

-- The seams, checked on the REAL engine modules.
ok(Message.dp3_wrapped == true, "the sentinel is set on the real Message module")
ok(Message.show ~= vanillaShow, "Message.show was replaced")
ok(Message.draw ~= vanillaDraw, "Message.draw was replaced")
ok(FrlgFont.draw ~= vanillaFontDraw, "FrlgFont.draw was replaced")

ok(linkCount("world.talk") > 0, "world.talk carries a link")
ok(linkCount("render.hud") > 0, "render.hud carries a link")

-- ================================================ phase 2: the negative control
io.write("-- and declines to load on a Gen 2 boot\n")
run.release()

local Message2, FrlgFont2 = freshDrawModules()
local freshShow, freshDraw, freshFont = Message2.show, Message2.draw, FrlgFont2.draw
eq(Message2.dp3_wrapped, nil, "the fresh Message module carries no sentinel")

local run2 = Sdk.loadMod(MOD_ID, {
  generation = 2, data = nil, fs = modFs(MOD_ROOT, MOD_ID),
})

ok(#(run2.errors or {}) == 0, "a Gen 2 boot is not an error, just a skip")
eq(Message2.dp3_wrapped, nil, "a Gen 2 boot leaves the sentinel unset")
ok(Message2.show == freshShow, "a Gen 2 boot does not replace Message.show")
ok(Message2.draw == freshDraw, "a Gen 2 boot does not replace Message.draw")
ok(FrlgFont2.draw == freshFont, "a Gen 2 boot does not replace FrlgFont.draw")
ok(linkCount("world.talk") <= 0, "a Gen 2 boot installs no world.talk link")
ok(linkCount("render.hud") <= 0, "a Gen 2 boot installs no render.hud link")
run2.release()

io.write(("\n%d checks, %d failures\n"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
