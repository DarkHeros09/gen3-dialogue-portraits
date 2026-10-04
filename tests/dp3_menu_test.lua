-- Reachability -- can the player actually GET to this mod's settings?
--
-- The other three suites all pass with the settings unreachable.  They prove
-- the portraits resolve, the crop geometry is right, and the mod installs its
-- seams -- none of which needs a menu.  So a build where every portrait draws
-- perfectly and the player still cannot change PORTRAIT or SIDE is green
-- everywhere, and that is exactly the state this mod has shipped in.
--
-- The reason is a hole in the engine.  Gen 1 reaches the mod manager from an F10
-- hotkey (src/core/Game.lua) and from its options menu's MODS row
-- (src/ui/OptionsMenu.lua); Gen 2 reaches it from its start menu
-- (src/core/Game2.lua).  A FireRed boot has NONE of the three: src/core/Game3.lua
-- and src/ui/game3/* mention ManagerState exactly zero times, and
-- src/ui/game3/start_menu.lua builds only POKeDEX / POKeMON / BAG / TRAINER /
-- SAVE / OPTION / EXIT.
--
-- An earlier version answered that by wrapping ui.start_menu.items and adding a
-- MODS row that pushed ManagerState.  That works on Gold; on FireRed it opens a
-- menu that cannot draw.  ManagerState is rendered by Gen 1 primitives
-- (src.render.Font, src.ui.OptionRows, src.ui.Theme) and FireRed's extracted
-- latin_normal font has no glyphs for them -- every character logs "font: no
-- glyph for ..." and the screen paints nothing, so the settings were, once
-- again, unreachable.
--
-- So this mod no longer pushes a foreign menu.  It puts its settings into
-- FireRed's own OPTION menu, drawn by FireRed's own chrome and font.  The seam
-- is src/ui/game3/option_rows.lua: option_menu.lua calls Rows.build(ctx) and
-- then Rows.group, which turns any id listed in Rows.GROUPS into a group row
-- whose activate() opens a sub-page of its members, ordered by Rows.ORDER.  The
-- mod wraps Rows.build to append two rows and registers one group; the entry is
-- named DIALOGUE PORTRAITS.
--
-- This suite drives that: the group is absent before the mod loads, appears as
-- exactly one DIALOGUE PORTRAITS row when it does, opens a two-row page holding
-- PORTRAIT and SIDE, and stepping either one is written both where the engine
-- persists options and where the mod reads them live.  The control phases at
-- each end are what make "it is present" evidence rather than a story the
-- harness would tell about any engine.
--
-- Run:  luajit tests/dp3_menu_test.lua <engine root>

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

local script = normalise(arg and arg[0] or "tests/dp3_menu_test.lua")
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

-- ------- the cart-text seam
--
-- src/ui/game3/option_rows.lua builds its labels from the CART's own message
-- table (RomText.at("sOptionMenuItemsNames", i)), and RomText.ir() ASSERTS when
-- the running cart's script bundle has not been mounted.  That is correct at
-- runtime -- the bundle is always up by the time OPTION opens -- but this suite
-- drives Rows.build() with no ROM data at all, so without a seam it dies on the
-- first row.  The engine's own menu tests stub rom_text for exactly this reason
-- (see tests/game3_mods_menu_test.lua), so this does the same: an identity
-- mapper that returns the key, which is all this suite needs to assert on row
-- identity, order and grouping.  Nothing here changes what the ENGINE does; it
-- only lets the headless harness reach the rows.
--
-- Installed BEFORE OptionRows is required below, so the require picks it up.
do
  local function key(n, i, j)
    if i == nil then return n end
    return j and (n .. "[" .. i .. "][" .. j .. "]") or (n .. "[" .. i .. "]")
  end
  local function plain(k) return k end
  package.loaded["src.core.game3.rom_text"] = {
    plain = plain, box = plain, ascii = plain,
    has = function() return true end,
    key = key,
    at = function(n, i, j) return key(n, i, j) end,
    count = function() return 0 end,
    list = function() return {} end,
    lazy = function(map) return setmetatable({},
      { __index = function(_, k) return map[k] end }) end,
  }
end

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

-- Same real-directory filesystem view the load suite uses, for the same two
-- reasons (FsIo cannot stat through a ".." component, and arg[0] does not
-- survive the .bat luajit shim).  Non-mod paths are deliberately NOT mapped:
-- the loader persists cart enable state through this fs, so a fall-through
-- would write options.lua into the mod directory and modkit pack would then
-- sweep it into the release.
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

-- ------- the OPTION menu, driven the way option_menu.lua drives it
local OptionRows = require("src.ui.game3.option_rows")

-- Build the rows and group them exactly as src/ui/game3/option_menu.lua does:
-- Rows.build(ctx) then Rows.group(flat, openPage), where openPage is the
-- sub-page pusher the group's own activate() calls.
local function buildView(opts)
  local pages = {}
  local ctx = opts.ctx
  local flat = OptionRows.build(ctx)
  local view = OptionRows.group(flat, function(title, rows)
    pages[#pages + 1] = { title = title, rows = rows }
  end)
  return flat, view, pages
end

local function findRow(rows, id)
  for _, row in ipairs(rows) do
    if type(row) == "table" and row.id == id then return row end
  end
  return nil
end

local function stockContext(options, game)
  return { options = options or { modOptions = {} }, game = game }
end

-- ================================================== phase 0: the control
io.write("-- with no mod loaded the option menu is stock\n")
do
  local ctx = stockContext()
  local flat, view = buildView({ ctx = ctx })
  eq(findRow(flat, "dp3portrait"), nil,
    "no DIALOGUE PORTRAIT row before the mod loads")
  eq(findRow(flat, "dp3side"), nil,
    "no DIALOGUE SIDE row before the mod loads")
  eq(findRow(view, "group.dialoguePortraits"), nil,
    "and no DIALOGUE PORTRAITS group")
  ok(findRow(flat, "textSpeed") ~= nil,
    "the stock TEXT SPEED row is still there")
  ok(findRow(flat, "frameType") ~= nil,
    "and so is the stock FRAME row, which is the nearest neighbour we add beside")
end

-- ================================================= phase 1: load the mod
io.write("-- the mod brings its own settings into OPTION\n")
local run = Sdk.loadMod(MOD_ID, {
  generation = 3, data = Sdk.gen3Data(), fs = modFs(MOD_ROOT, MOD_ID),
})
ok(#(run.errors or {}) == 0,
  "the real loader reports no errors" ..
  (#(run.errors or {}) > 0 and (": " .. tostring(run.errors[1])) or ""))

local game = { mods = run.loader, save = { options = {} }, generation = 3 }
local ctx = stockContext(nil, game)

local flat, view, pages = buildView({ ctx = ctx })
local portrait = findRow(flat, "dp3portrait")
local side = findRow(flat, "dp3side")
ok(portrait ~= nil, "the PORTRAIT row reaches the option list")
ok(side ~= nil, "and so does the SIDE row")

local group = findRow(view, "group.dialoguePortraits")
ok(group ~= nil, "they are folded into one DIALOGUE PORTRAITS group row")
eq(group and group.label, "DIALOGUE PORTRAITS", "whose label is DIALOGUE PORTRAITS")
eq(group and group.value(), "2 OPTIONS", "and which says it holds two options")

-- the individual rows must NOT also appear beside the group
eq(findRow(view, "dp3portrait"), nil, "PORTRAIT is not also a top-level row")
eq(findRow(view, "dp3side"), nil, "and neither is SIDE")

-- ==================================== phase 2: the group opens its own page
io.write("-- and it opens the two settings\n")
if group then
  group.activate(ctx)
  local page = pages[#pages]
  ok(page ~= nil, "activating the group opens a sub-page")
  eq(page and page.title, "DIALOGUE PORTRAITS", "titled DIALOGUE PORTRAITS")
  eq(page and #page.rows, 2, "holding exactly the two options")

  local pagePortrait = findRow(page and page.rows or {}, "dp3portrait")
  local pageSide = findRow(page and page.rows or {}, "dp3side")
  ok(pagePortrait ~= nil, "PORTRAIT is editable here")
  ok(pageSide ~= nil, "SIDE is editable here")

  if pagePortrait then
    eq(pagePortrait.label, "PORTRAIT", "PORTRAIT is labelled PORTRAIT")
    eq(pagePortrait.value(ctx), "INSET", "and defaults to INSET")
  end
  if pageSide then
    eq(pageSide.label, "SIDE", "SIDE is labelled SIDE")
    eq(pageSide.value(ctx), "AUTO", "and defaults to AUTO")
  end

  -- ============================ phase 3: and changing it sticks
  io.write("-- changing a setting the way the UI does\n")
  if pagePortrait and type(pagePortrait.step) == "function" then
    pagePortrait.step(ctx, 1)
    local stored = ctx.options.modOptions[MOD_ID]
    eq(stored and stored.style, "framed",
      "stepping PORTRAIT right stores FRAMED in the engine options tree")
    local live = run.loader.modOptions and run.loader.modOptions[MOD_ID]
    eq(live and live.style, "framed",
      "and mirrors it to the loader, which is where the mod reads it live")
    eq(pagePortrait.value(ctx), "FRAMED",
      "so the row now prints FRAMED")
  end

  -- a choice row must wrap, not run off the end
  if pageSide and type(pageSide.step) == "function" then
    pageSide.step(ctx, -1)
    local stored = ctx.options.modOptions[MOD_ID]
    eq(stored and stored.side, "right",
      "stepping SIDE left from AUTO wraps to RIGHT")
  end
end

-- ================================== phase 4: the door closes with the mod
-- Release the loader handle and the rows must go.  Without this, "the group is
-- present" is satisfied by a harness that always draws one.
io.write("-- and the way in goes when the mod does\n")
ctx.game = { save = { options = {} }, generation = 3 }
local flatAfter, viewAfter = buildView({ ctx = ctx })
eq(findRow(flatAfter, "dp3portrait"), nil,
  "with the mod released, the PORTRAIT row is gone")
eq(findRow(viewAfter, "group.dialoguePortraits"), nil,
  "and so is the DIALOGUE PORTRAITS group")

run.release()

io.write(("\n%d checks, %d failures\n"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
