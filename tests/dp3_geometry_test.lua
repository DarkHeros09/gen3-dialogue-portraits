-- Layout geometry -- where the portrait goes, and what it costs the text
--
-- This suite drives the REAL engine modules the mod wraps (src/ui/game3/message,
-- src/ui/game3/chrome, src/ui/game3/frlg_font) and asserts on the numbers they
-- are actually called with.  It is the check that the four layouts cost the
-- text what the README says they cost:
--
--   INSET   the box keeps its 26 columns; the text is moved along by 5 (40px)
--   INSET-R the box keeps its 26 columns; the text loses 5, so the arrow keeps
--           its own column at the end
--   FRAMED  the box is drawn short by the window's own run PLUS its clearance
--           and the text follows it -- 7 columns, 19 left, for EVERY crop,
--           because the window is one size and only the art inside it varies
--   MARGIN  the box and the text are untouched; the panel is drawn over the
--           finished frame, out in the window's margin
--   OFF     the box and the text are byte-identical to vanilla
--
-- Two facts about the box run underneath all of it.
--
-- FIRST, Chrome.DLG_LEFT/TOP/W/H is the box's CONTENT rect, not the box.
-- dialogueFrame draws the frame around it -- two columns to the left of
-- DLG_LEFT, two past DLG_LEFT + DLG_W, a row above and a row below -- so the
-- box the player sees is 30 columns by 6 rows, the whole 240px screen edge to
-- edge.  Anything that stands BESIDE the box has to measure against that
-- visible rectangle; measured, not assumed, by .probe/dp3_chrome_probe.lua,
-- which captures dialogueFrame's own rectangles and finds 240x48 at (0,112).
--
-- SECOND, the text is laid out exactly once and clipped somewhere else.
-- Message.show word-wraps against ctx.maxWidth, defaulting to a hardcoded 208
-- (src/ui/game3/message.lua:148, handed on to TextIR.toTextBox).  The draw then
-- CLIPS each line at Chrome.DLG_W * Display.TILE (message.lua:317).  Vanilla
-- the two agree, because 208 IS 26 columns.  Every layout here breaks that
-- agreement, so the wrap has to be told the layout's own width as well -- which
-- is what the wrap section below measures, through a spy on the real
-- TextIR.toTextBox.
--
-- The trick that makes the font side measurable: that spy is installed BEFORE
-- the mod loads, so the mod captures it as ITS vanilla and the spy therefore
-- sees the arguments the mod has already rewritten.  A spy installed after
-- would see the unmodified ones and prove nothing.  The TextIR spy is the
-- exception and can be installed at any point, because message.lua reads that
-- field at call time rather than capturing it as an upvalue.
--
-- Run:  luajit tests/dp3_geometry_test.lua <engine root>

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

local script = normalise(arg and arg[0] or "tests/dp3_geometry_test.lua")
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
-- Exact comparison is the right default here -- almost every number below is a
-- whole number of game pixels -- but MARGIN multiplies by the window scale, and
-- a fractional scale makes the arithmetic inexact: 30 * (46/30) * (4/3) is not
-- bit-identical to 46 * (4/3) even though the two are the same number, and an
-- exact `eq` would report a one-ulp difference as a bug.  `near` is for those,
-- and only those; a tolerance wide enough to hide a real error would defeat the
-- point of measuring at all.
local function near(got, want, msg, tol)
  tol = tol or 1e-9
  return ok(type(got) == "number" and math.abs(got - want) <= tol,
    ("%s (got %s, want %s)"):format(msg, tostring(got), tostring(want)))
end

-- ------- stub love
local love = require("tests.love_stub")
_G.love = love
if not love.timer then love.timer = { getTime = function() return 0 end } end
love.graphics = love.graphics or {}
local noop = function() end
love.graphics.rectangle = noop
love.graphics.setColor = noop
love.graphics.draw = noop

-- A REAL transform stack, because the portrait's window is drawn through one:
-- the menu frame only comes in tile coordinates, so the mod translates to the
-- content rect and scales by the unit before asking the engine for it.  The
-- engine's love_stub leaves translate/scale as noops, so without this the spies
-- below would record LOCAL coordinates -- the window would read as sitting at
-- (-8,-8) wherever it actually landed -- and every placement assertion in this
-- file would pass while measuring the wrong thing.  That is the same trap as a
-- double more capable than the real object, one layer down.
--
-- push/pop are overridden here rather than left to the stub for the same reason:
-- the stub's own push/pop save colour and blend state, which this file's spies
-- already own, and they know nothing about the transform.
--
-- One table rather than five locals, because this file is close to LuaJIT's
-- 200-local ceiling and the helpers are only ever reached through the spies.
local XF = { stack = { { x = 0, y = 0, s = 1 } } }
function XF.cur() return XF.stack[#XF.stack] end
function XF.push()
  local c = XF.cur()
  XF.stack[#XF.stack + 1] = { x = c.x, y = c.y, s = c.s }
end
function XF.pop() if #XF.stack > 1 then XF.stack[#XF.stack] = nil end end
function XF.translate(dx, dy)
  local c = XF.cur()
  c.x, c.y = c.x + (dx or 0) * c.s, c.y + (dy or 0) * c.s
end
function XF.scale(sx) local c = XF.cur(); c.s = c.s * (sx or 1) end
-- Fold the live transform into a coordinate or a size, so everything the spies
-- record is where it lands on screen rather than where it was asked for.
function XF.fx(v) return XF.cur().x + (v or 0) * XF.cur().s end
function XF.fy(v) return XF.cur().y + (v or 0) * XF.cur().s end
-- nil-preserving, because love.graphics.draw's scale arguments are optional and
-- the art assertions below read them as "nil means 1x".
function XF.fs(v) return v and (v * XF.cur().s) or nil end
love.graphics.push = XF.push
love.graphics.pop = XF.pop
love.graphics.translate = XF.translate
love.graphics.scale = XF.scale

-- The stub image must match a REAL LÖVE 11.5 Image, and that is the whole point
-- of this block.  LÖVE removed Image:getData in 11.0 and this engine targets
-- 11.5, so a real source picture offers getDimensions and nothing else -- no
-- pixel readback of any kind.  An earlier version of this stub handed out
-- getData() and a fresh ImageData, which made the mod's pixel-copy crop look
-- like it worked here while it could not possibly work in the game: the suite
-- stayed green and every portrait was silently missing on screen.  A double
-- that is MORE capable than the real object is at least as dangerous as one
-- that is thinner, so the stub now offers exactly what the engine offers.
local function stubImage(w, h)
  w, h = w or 64, h or 64
  local image = { w = w, h = h }
  image.getDimensions = function() return w, h end
  image.getWidth = function() return w end
  image.getHeight = function() return h end
  return image
end
love.graphics.newImage = function() return stubImage(64, 64) end

-- Every draw call, so the closing section can look at what the portrait was
-- actually drawn through rather than only at the numbers around it -- and at
-- WHERE it was drawn and at what scale, which is what the placement sections
-- need.  The art is the only thing in this suite drawn through a quad (the
-- dialogue chrome falls back to plain rectangles here, its atlas being
-- ROM-extracted), so a table second argument identifies it.
local draws = {}
love.graphics.draw = function(a, b, ...)
  local arg = { ... }
  draws[#draws + 1] = { a = a, b = b, x = XF.fx(arg[1]), y = XF.fy(arg[2]),
                        r = arg[3], sx = XF.fs(arg[4]), sy = XF.fs(arg[5]) }
end

local function artDraw()
  for i = #draws, 1, -1 do
    if type(draws[i].b) == "table" then return draws[i] end
  end
  return nil
end

-- Every filled rectangle, WITH the colour it was filled in.  The colour is the
-- load-bearing half: "a panel was painted" and "a portrait was drawn bare on the
-- map" are the same rectangle call, and only the colour tells them apart.
-- Installed here and left installed, because the panel assertions are spread
-- across the FRAMED and MARGIN sections; the helpers that read it reset it.
local rects, currentColor = {}, nil
love.graphics.setColor = function(r, g, b, a)
  currentColor = { r, g, b, a }
end
love.graphics.rectangle = function(mode, x, y, w, h)
  rects[#rects + 1] = { mode = mode, x = XF.fx(x), y = XF.fy(y),
                        w = XF.fs(w), h = XF.fs(h), color = currentColor }
end

-- Every quad the mod builds, in order, so the crop-key assertions below can
-- read the rectangle the mod really asked for.
local quads = {}
love.graphics.newQuad = function(x, y, w, h, tex)
  local quad = { x = x, y = y, w = w, h = h, tex = tex }
  quads[#quads + 1] = quad
  return quad
end
local function lastQuad() return quads[#quads] end

-- The engine's own art loader does build ImageData, so this stays real; the mod
-- is the thing under test and has no business calling it.
love.image = love.image or {}
love.image.newImageData = function(w, h)
  local d = { w = w, h = h, getPixel = function() return 0, 0, 0, 0 end,
              setPixel = noop }
  d.getDimensions = function() return w, h end
  return d
end

-- ------- the engine modules under test
local Message  = require("src.ui.game3.message")
local Chrome   = require("src.ui.game3.chrome")
local FrlgFont = require("src.ui.game3.frlg_font")
local Display  = require("src.core.game3.display")

local T = Display.TILE
ok(T == 8, "the FRLG tile is 8px")
eq(Chrome.DLG_LEFT, 2, "the dialogue box starts at column 2")
eq(Chrome.DLG_W, 26, "the dialogue box is 26 columns wide")
eq(Chrome.DLG_H, 4, "the dialogue box is 4 rows tall")

-- The vanilla text geometry, read off the engine's own constants, so the
-- expectations below are derived rather than typed.
local VANILLA_X  = Chrome.DLG_LEFT * T
local VANILLA_W  = Chrome.DLG_W * T

-- ------- the frame spy
--
-- The portrait's panel IS the game's own menu window, and the strongest way to
-- say so is to watch the call rather than the pixels: Chrome.stdFrame is the
-- same function the start menu's box is drawn with, so if the mod asks for it
-- the portrait cannot drift from the menu's frame without both drifting.  It is
-- also the assertion that survives the atlas being present or absent -- the
-- tiles and the flat fallback come out of the same call.
--
-- One table, because this file is near LuaJIT's local ceiling.
local STD = { calls = {} }
STD.real = Chrome.stdFrame
Chrome.stdFrame = function(tx, ty, tw, th)
  STD.calls[#STD.calls + 1] = { tx = tx, ty = ty, tw = tw, th = th }
  return STD.real(tx, ty, tw, th)
end

-- ------- the font spy, installed BEFORE the mod loads
local fontCalls = {}
local realFontDraw = FrlgFont.draw
FrlgFont.draw = function(text, x, y, opts)
  fontCalls[#fontCalls + 1] = { x = x, maxWidth = opts and opts.maxWidth }
  return realFontDraw(text, x, y, opts)
end

-- ------- the mod facade
local Runtime = require("src.mods.Runtime")
local Hooks = require("src.mods.Hooks")
local Events = require("src.mods.Events")
Runtime.install(Events.new(), Hooks.new(), {})

local style, side = "inset", "left"
local mod = { path = MOD_ROOT, exports = {}, generation = 3 }
mod.log = { info = function() end, warn = function() end, error = function() end }
mod.options = {
  define = function() end,
  get = function(_, key)
    if key == "style" then return style end
    if key == "side" then return side end
    return nil
  end,
}
mod.read = function(_, rel)
  local f = io.open(MOD_ROOT .. "/" .. rel, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  return data
end
-- One species the suite can name, so the Pokemon route -- and the mirroring
-- that goes with it -- is reachable at all.  Nothing else in this file names a
-- species, so this cannot make a portrait resolve where one should not.
local SPECIES = { PIKACHU = { index = 25 } }
mod.content = { pokemon = { get = function(_, name) return SPECIES[name] end } }
mod.assets = { image = function() return nil end }
mod.hooks = {
  wrap = function(_, name, fn) Runtime.hooks:wrap(name, fn, 100, "gen3-dialogue-portraits") end,
}
mod.events = {
  on = function(_, name, fn) Runtime.events:on(name, fn, 100, "gen3-dialogue-portraits") end,
}

-- A trainer class with a picture, so a portrait is always resolved.
--
-- The `trainers` rows matter: a class is not a picture on Gen 3, so the mod
-- exchanges one for the other through this table.  With no rows here the
-- exchange finds nothing, no portrait resolves, and the suite below measures
-- vanilla numbers while blaming the layout code -- the same failure mode the
-- probe assertion further down exists to catch.
--
-- The images are keyed by PICTURE ID rather than minted per call, and that is
-- load-bearing.  This stub used to return a fresh image for every request,
-- which meant the suite could not tell "asked for picture 17" from "asked for
-- picture 17, and picture 17, and picture 17" -- so it was green while every
-- interaction in the game drew the same face.  Keying by id makes the id
-- observable through the picture, which is what the two-speaker check at the
-- end of this file needs.
local frontByPic = {}
local lastFront = nil
package.loaded["src.core.game3.trainer_pic"] = {
  front = function(picId)
    picId = tonumber(picId)
    -- The engine's own guard is `picId < 0`, and it answers picture 0 happily:
    -- TRAINER_FRONT_PIC_TABLE's entry 0 is real, compressed art.  Refusing 0
    -- here would make this stub enforce the rule under test, and the bug it is
    -- meant to catch would be invisible to the suite -- a double must not be
    -- smarter than the object it stands in for.
    if not picId or picId < 0 then return nil end
    frontByPic[picId] = frontByPic[picId] or love.graphics.newImage()
    lastFront = frontByPic[picId]
    return { image = lastFront, w = 64, h = 64 }
  end,
}
-- Species art, keyed by index for the same reason the trainer art is keyed by
-- picture id: the id has to be observable through the picture, or "asked for
-- the right one" and "asked for the same one every time" look identical.
local pokemonByIndex = {}
package.loaded["src.core.game3.pokemon"] = {
  frontPic = function(index)
    index = tonumber(index)
    if not index then return nil end
    pokemonByIndex[index] = pokemonByIndex[index] or love.graphics.newImage()
    return { image = pokemonByIndex[index], w = 64, h = 64 }
  end,
}
package.loaded["src.core.game3.scripting.trainers"] = {
  pack = function()
    return {
      classNames = { [0] = "POKéMON TRAINER", [17] = "GUITARIST", [29] = "LASS",
                     [30] = "COOLTRAINER", [31] = "BUG CATCHER",
                     [43] = "RIVAL" },
      trainers = {
        -- the cart's empty record, and the reason every NPC wore one face
        [0] = { class = 0,  pic = 0,   name = "" },
        [1] = { class = 17, pic = 17,  name = "GUITARIST" },
        [2] = { class = 43, pic = 106, name = "TERRY" },
        -- Three pictures nothing else in this file touches, so a crop override
        -- can be filed against each without the mod's own crop cache answering
        -- from an earlier cut of the same picture.  The cache is keyed on the
        -- PICTURE, so one key can only ever hold one rectangle per run: the
        -- 32px overrun test, the zoom test and the window-size test therefore
        -- need a key each.
        [3] = { class = 29, pic = 55,  name = "LASS" },
        [4] = { class = 30, pic = 56,  name = "COOLTRAINER" },
        [5] = { class = 31, pic = 57,  name = "BUG CATCHER" },
        -- A fourth for the MARGIN zoom test, which is the one place the crop is
        -- read back off a MARGIN draw rather than a FRAMED one -- so it cannot
        -- share a picture with any of the three above.
        [6] = { class = 32, pic = 58,  name = "SWIMMER" },
      },
    }
  end,
}

-- The ENGINE's own wrap, captured BEFORE the mod installs its own on top of it.
--
-- This exists so the "what does the engine do without the guard" comparisons
-- below are against the real thing.  Reaching the engine's wrap through the
-- mod's wrapper instead is a trap this suite has already fallen into once: both
-- sides of the comparison get guarded, so the assertion goes blind to a guard
-- that fires for every box.  Mutation L in .probe/dp3_layout_bite.py removes the
-- gate entirely and is what caught it.
local TextIR = require("src.core.game3.scripting.text_ir")
local ENGINE_TO_TEXTBOX = TextIR.toTextBox

-- ------- the mod's own environment, in the one respect that changes an ANSWER
--
-- A mod does NOT run against _G.  src/mods/Sandbox.envFor hands it a private
-- table, and the `package` in that table is LegacyCompat's packageShim -- a
-- decoy whose `loaded` is a FRESH EMPTY one (src/mods/LegacyCompat.lua:836).
--
-- So a mod that reaches for the engine through package.loaded finds the real
-- table HERE and nil IN THE GAME, and that is how 1.8.0 shipped a fix that never
-- ran: frameRect's guard saw nil, took its documented fallback to the render.hud
-- payload, and every assertion in this file still passed -- because the suite
-- was compiling main.lua in the ordinary global environment, where the lookup
-- works.  A double that is more capable than the real object is worse than one
-- that is thinner; this one was capable of the exact thing the game forbids.
--
-- The env below is _G with `package` replaced rather than the full sandbox,
-- because this suite is about layout arithmetic and `package` is the only global
-- whose value decides an answer here (main.lua uses no io, os, dofile, loadfile,
-- print or debug at all).  .probe/dp3_sandbox_probe.lua measures the real
-- Sandbox.envFor for comparison, and agrees with this shape.
local MOD_PACKAGE_DECOY = { path = "", cpath = "", preload = {},
                            loaded = {}, loaders = {} }
local MOD_ENV = setmetatable({ package = MOD_PACKAGE_DECOY }, { __index = _G })

local chunk = assert(loadfile(MOD_ROOT .. "/main.lua"))
setfenv(chunk, MOD_ENV)
local result = chunk(mod)
if type(result) == "function" then result(mod) end
local X = mod.exports

-- The decoy is load-bearing, so assert it is really in force: without this, a
-- future edit that dropped the setfenv would quietly restore the blind spot.
ok(rawget(MOD_ENV, "package") == MOD_PACKAGE_DECOY,
  "the mod's chunk runs against the sandbox's package, not the engine's")
ok(MOD_PACKAGE_DECOY.loaded["src.render.Renderer"] == nil,
  "whose loaded table is empty, exactly as LegacyCompat's packageShim is")
ok(type(X.frameRect) == "function", "and the mod still exports frameRect")

-- ------- the box the player actually SEES
--
-- Derived from the mod's own CHROME_* numbers rather than typed, so a change to
-- either side of the pair shows up as a failure here instead of as a portrait
-- that has drifted onto the box's border.  See the header.
local BOX_LEFT  = (Chrome.DLG_LEFT - X.CHROME_L) * T
local BOX_RIGHT = (Chrome.DLG_LEFT + Chrome.DLG_W + X.CHROME_R) * T
local BOX_TOP   = (Chrome.DLG_TOP - X.CHROME_UP) * T
local BOX_H     = (Chrome.DLG_H + X.CHROME_UP + X.CHROME_DOWN) * T

eq(X.CHROME_L, 2, "the frame overhangs the content rect by two columns on the left")
eq(X.CHROME_R, 2, "and by two on the right")
eq(X.CHROME_UP, 1, "and by a row above")
eq(X.CHROME_DOWN, 1, "and by a row below")
eq(BOX_LEFT, 0, "so the visible box starts at the screen's own left edge")
eq(BOX_RIGHT, Display.W, "and runs the whole width of the screen")
eq(BOX_TOP, 112, "and its top is a row above the content rect")
eq(BOX_H, 6 * T, "and it is six rows tall, not the four DLG_H admits")

-- ------- the wrap spy
--
-- Installed here, after the mod has loaded, and that is fine: message.lua reads
-- TextIR.toTextBox as a FIELD at call time, so replacing it is enough.  What
-- this records is the ctx the REAL wrap was handed -- the width every line is
-- broken to, and the names the placeholders expand through, both of which the
-- mod's own copy of opts has to carry.
local TextIR = require("src.core.game3.scripting.text_ir")
local wrapCalls = {}
local realToTextBox = TextIR.toTextBox
TextIR.toTextBox = function(ir, ctx)
  local out = realToTextBox(ir, ctx)
  wrapCalls[#wrapCalls + 1] = {
    maxWidth = type(ctx) == "table" and ctx.maxWidth or nil,
    playerName = type(ctx) == "table" and ctx.playerName or nil,
    ctx = ctx,
    -- The text the box will actually print, AFTER the mod's own guard has had
    -- its say.  Without this the orphan assertions below could only read the
    -- mod's arithmetic back instead of the string the player reads.
    out = out,
  }
  return out
end
local function lastWrap() return wrapCalls[#wrapCalls] end

-- The same wrap with the mod left out of it entirely, for the assertions that
-- have to say "this is what the engine does" rather than "this is what the mod
-- does".  Reading it off realToTextBox would be circular: that IS the mod.
local function engineWrap(text, maxW)
  return ENGINE_TO_TEXTBOX(TextIR.fromAscii(text), { maxWidth = maxW })
end

-- The rectangle a portrait was really drawn in.  blit() walks the draw origin
-- to the mirrored art's own right edge before negating sx, so the left edge is
-- d.x whether or not the art was flipped -- which is what lets the centring
-- assertions below read the same expression for a trainer and a Pokemon.
local function artExtent(d)
  if not d then return nil end
  local w = (d.b and d.b.w or 0) * math.abs(d.sx or 1)
  local h = (d.b and d.b.h or 0) * math.abs(d.sy or 1)
  return { x = d.x, y = d.y, w = w, h = h, scale = d.sx, flip = (d.sx or 1) < 0 }
end

-- The whole suite rests on a portrait actually resolving.  If it does not, the
-- mod's draw wrapper falls through to vanilla and every layout assertion below
-- silently measures UNTOUCHED engine numbers -- it reports five failures and
-- names the wrong cause.  So ask the question out loud, first, and let a broken
-- harness fail here instead of masquerading as broken layout code.
ok(X.portraitFor({ class = 17, sprite = "SPRITE_HIKER" }) ~= nil,
  "a trainer class resolves to a cut portrait (the harness can feed the cutter)")

-- ------- helpers
local function openBox(descriptor, opts, text)
  -- Cleared BEFORE the show, not after: the wrap spy is populated BY the show
  -- (that is where the text is laid out), while the font spy is populated by
  -- the draw.  Clearing afterwards would throw the wrap away and every width
  -- assertion below would read nil.
  fontCalls, wrapCalls = {}, {}
  -- Put a speaker in front of the mod the way the engine does: through the
  -- world.talk hook, which is the only thing that names a press.
  Runtime.call("world.talk", function() end, {}, descriptor)
  Message.show(text or "Some plain dialogue with no name in it.", opts)
end

local function lastCall()
  return fontCalls[#fontCalls]
end

-- ------- OFF changes nothing
io.write("-- OFF is vanilla\n")
style, side = "off", "left"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
Message.draw()
eq(lastCall() and lastCall().x, VANILLA_X, "OFF leaves the text where vanilla puts it")
eq(lastCall() and lastCall().maxWidth, VANILLA_W, "OFF leaves the text its full width")

-- ------- INSET, left and right
--
-- Both sides reserve the SAME run -- the art slot plus one column kept clear of
-- it -- and that agreement is the assertion, not a coincidence of the two
-- numbers.  It used to be the slot on the left and the slot + ARROW_TW on the
-- right, so one layout was 22 columns wide on one side and 21 on the other, and
-- the words sat 9px clear of the art on the right against 1px on the left.  1px
-- is the slot's own inset, not padding: at 1x the first letter was against the
-- portrait, which is "sits too close to the text".  On the right that clear
-- column is where the blinking arrow goes, so both sides need it and neither
-- should be a different width because of it.
--
-- The slot grew from 4 columns to 5 in this release, so INSET's portrait is 38px
-- rather than 30, and the reserve went from 5 columns to 6.  The 38 is not a
-- constant the art is set to: it is the slot less its padding, and the crop is
-- scaled to fill that.
io.write("-- INSET\n")

local INSET_RESERVE_PX = X.INSET_RESERVE_TW * T

style, side = "inset", "left"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
Message.draw()
eq(lastCall() and lastCall().x, VANILLA_X + INSET_RESERVE_PX,
  "INSET-LEFT moves the text along by the reserved run")
eq(lastCall() and lastCall().maxWidth, VANILLA_W - INSET_RESERVE_PX,
  "and costs the text exactly that much")
-- The 1.4.0/1.5.0 measurement, restored.  1.6.0 made the portrait 38px in a 40px
-- slot, which is five columns and a reserve of six -- a portrait taller than the
-- 32px content rect it is supposed to sit in, placed by clamping rather than by
-- centring.  At 32px in a 32px slot the reserve is five and the text keeps the
-- column it lost in 1.6.0.
--
-- The slot is still 32 and the reserve still 5: what changed in this release is
-- that the crop now FILLS the slot instead of sitting in it with a pixel of
-- padding all the way round -- the "margin between the portrait and its
-- surrounding frame".  `INSET_PAD` is the number that used to be that margin,
-- and it is asserted as ZERO rather than left implicit, because a pad of one is
-- exactly what the report describes.
eq(X.SLOT_TW, 4, "INSET gives the art 4 columns")
eq(X.SLOT, 32, "which is a 32px slot")
eq(X.INSET_ART, 32, "and the portrait is the whole slot -- edge to edge")
eq(X.INSET_PAD, 0, "so there is no padding between the art and its frame")
eq(X.SLOT, X.INSET_ART + 2 * X.INSET_PAD, "the slot being the portrait plus its padding")
eq(X.INSET_RESERVE_TW, 5, "and the reserve is 5: the slot plus the column kept clear")
eq(X.INSET_RESERVE_TW, X.SLOT_TW + math.max(X.ARROW_TW, X.INSET_GAP_TW),
  "which is the slot plus the wider of the arrow's column and the clearance")

-- ------- INSET, right
io.write("-- INSET on the right\n")
style, side = "inset", "right"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
Message.draw()
eq(lastCall() and lastCall().x, VANILLA_X, "INSET-RIGHT leaves the text where it was")
eq(lastCall() and lastCall().maxWidth, VANILLA_W - INSET_RESERVE_PX,
  "and costs the text the same run as LEFT, so SIDE is not a width")

-- ------- INSET's art is centred in its slot, against the box the player SEES
--
-- The art used to be pinned a fixed 2px in from the box's edge, and that is not
-- the same thing as centring it: a crop as wide as the slot ended exactly where
-- the text pen began, and anything wider drew over the first letters of every
-- line.  Both halves of "sits too close to the surrounding text" are that one
-- placement, and the "toward the bottom-right" half is the same mistake on the
-- other axis.
--
-- Vertically the art is now centred against the VISIBLE box rather than the
-- 4-row content rect.  At 38px the portrait is taller than that rect, so
-- centring it in 32px would push three pixels of it under the frame's own
-- border -- and the horizontal assertions alone would not have shown that,
-- because height is the axis the content rect runs out of first.
io.write("-- INSET centres the art in its slot\n")

local function insetArt(sideWanted, descriptor)
  style, side = "inset", sideWanted
  draws = {}
  openBox(descriptor or { trainerType = 17, sprite = "SPRITE_HIKER" })
  Message.draw()
  return artExtent(artDraw())
end

local SLOT_X = Chrome.DLG_LEFT * T
local SLOT_W = X.SLOT

local insLeft = insetArt("left")
ok(insLeft ~= nil, "INSET draws the art")
eq(insLeft and insLeft.x, SLOT_X + X.INSET_PAD,
  "INSET-LEFT starts the art on its slot's own first pixel")
eq(insLeft and insLeft.w, X.INSET_ART,
  "and the default crop fills it -- a 32px crop drawn 1:1")
eq(insLeft and (insLeft.x + insLeft.w), SLOT_X + SLOT_W,
  "so it ends on the slot's own far edge, which is the frame edge to edge")
ok(insLeft and math.abs((insLeft.x - SLOT_X) - ((SLOT_X + SLOT_W) - (insLeft.x + insLeft.w))) <= 1,
  "with the space on its two sides differing by at most a pixel")
ok(insLeft and (insLeft.x + insLeft.w) <= VANILLA_X + INSET_RESERVE_PX,
  "and the only clearance to the pen is the column INSET_GAP_TW reserves")
eq(insLeft and insLeft.y, BOX_TOP + math.floor((BOX_H - X.INSET_ART) / 2),
  "and it is centred vertically in the VISIBLE box, not the content rect")

-- A crop as wide as the slot is the case that used to overrun, and it is what
-- the padding exists for: at 1:1 it would reach the pen, so it is fitted to the
-- padded slot instead and still stops short of the words.
X.crops.trainers["55"] = { 8, 8, 38 }
local wide = insetArt("left", { trainerType = 29, sprite = "SPRITE_HIKER" })
ok(wide ~= nil, "a crop as wide as the slot still draws")
eq(wide and wide.w, X.INSET_ART, "and is still fitted to the padded slot")
ok(wide and (wide.x + wide.w) <= VANILLA_X + SLOT_W,
  "so it does not cross into the text")
X.crops.trainers["55"] = nil

local insRight = insetArt("right")
ok(insRight and (insRight.x + insRight.w) <= (Chrome.DLG_LEFT + Chrome.DLG_W) * T,
  "INSET-RIGHT keeps the art inside the box's right-hand columns")
eq(insRight and insRight.x, SLOT_X + VANILLA_W - SLOT_W + X.INSET_PAD,
  "and puts it at the far end of the box, not the near one")

-- ------- AUTO reads the player's own facing
--
-- The engine turns the avatar before the A press and leaves it that way when
-- the box opens (field.lua reads `P.facing` to pick the cell it interacts
-- with), so the facing at box-open time is the answer.  It lives on the player
-- MODULE as a plain field, not behind an accessor -- a distinction worth a
-- check, because an accessor-only read silently degrades to the LEFT fallback
-- and nobody notices until a portrait is on the wrong side of the screen.
io.write("-- AUTO follows the player's facing\n")
local prevPlayer = package.loaded["src.core.game3.player"]
package.loaded["src.core.game3.player"] = { facing = "right" }
style, side = "inset", "auto"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
Message.draw()
eq(lastCall() and lastCall().x, VANILLA_X, "AUTO facing right leaves the text where it was")
eq(lastCall() and lastCall().maxWidth, VANILLA_W - INSET_RESERVE_PX,
  "and costs the text the same run as LEFT")

package.loaded["src.core.game3.player"] = { facing = "left" }
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
Message.draw()
eq(lastCall() and lastCall().x, VANILLA_X + INSET_RESERVE_PX, "AUTO facing left moves the text along")

-- up/down say nothing about which side the speaker is on, so they keep LEFT
package.loaded["src.core.game3.player"] = { facing = "up" }
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
Message.draw()
eq(lastCall() and lastCall().x, VANILLA_X + INSET_RESERVE_PX, "AUTO facing up falls back to the left")
package.loaded["src.core.game3.player"] = prevPlayer

-- ------- FRAMED
io.write("-- FRAMED\n")
style, side = "framed", "right"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
local seenW
local realDialogueFrame = Chrome.dialogueFrame
Chrome.dialogueFrame = function()
  seenW = Chrome.DLG_W
  return realDialogueFrame()
end
Message.draw()
Chrome.dialogueFrame = realDialogueFrame

-- ------- the window is the engine's own, at a whole-number zoom
--
-- The panel's size has been wrong in several directions, and the suite has to be
-- able to tell the current shape apart from all of them:
--
--   * 1.4.0's six-tile panel with the art stretched to fill it -- a 30px face
--     drawn at 46px, 1.53x, half again as tall as the portrait INSET draws
--     beside it.
--   * 1.6.0's fixed 48px square with the art stretched to fill a 46px window,
--     which is that same fault kept alive for one more release.
--   * 1.8.0's panel sized to the art -- a 32px panel for the default crop -- with
--     a hand-painted one-pixel black outline where a border should be, so the
--     only thing around the art was a hairline scaled up with everything else.
--
-- The shape now is a WINDOW: the game's own standard menu frame -- the same
-- Chrome.stdFrame the start menu's box and the OPTION page's body are drawn with
-- -- around a content rect the art is centred in.  The border is drawn from 8x8
-- tiles and only lines up on the tile grid, so the window is a whole number of
-- tiles on both axes and is therefore ONE size for everybody; what varies per
-- portrait is the art, at the largest whole number of times the crop that fits
-- the content.
--
-- So there is still no non-integer scale, the text width is a constant again,
-- and the ring around the art is the game's own border rather than a hairline.
-- All three are pinned below rather than hidden.
--
-- Everything below is derived from panelPlan's own answer rather than typed, so
-- a change to any half shows up as a failure here.
local DEFAULT_ART = X.crops.defaults.trainers[3]
local FRAMED_PLAN = X.panelPlan({ w = DEFAULT_ART, h = DEFAULT_ART })
local FRAMED_TW = FRAMED_PLAN.tiles
-- The columns the box gives up is the window's own run PLUS the clearance it
-- keeps from the play area's edge, bought out of the box.  Asked of the mod
-- rather than typed, so the two places that need the number -- the draw and the
-- wrap -- cannot be tested against a third copy of it.
local FRAMED_GIVE = X.framedGive(FRAMED_PLAN)
local FRAMED_TEXT_W = (26 - FRAMED_GIVE) * T

eq(X.PANEL_MAX_TW, 6, "the window is 6 tiles across")
eq(X.PANEL_BORDER_TW, 1, "and spends one of them on the menu border, each side")
eq(X.PANEL_CONTENT_TW, X.PANEL_MAX_TW - 2 * X.PANEL_BORDER_TW,
  "which leaves the content the art has to fit")
eq(DEFAULT_ART, 32, "the default crop is 32px -- the content rect itself")
eq(FRAMED_PLAN.zoom, 1, "which fits the content at 1x")
eq(FRAMED_PLAN.w, X.PANEL_MAX_TW * T, "so the window is a fixed 48px")
eq(FRAMED_PLAN.h, X.PANEL_MAX_TW * T, "on both axes")
eq(FRAMED_PLAN.border, X.PANEL_BORDER_TW * T, "with an 8px border")
eq(FRAMED_PLAN.content, X.PANEL_CONTENT_TW * T, "around a 32px content")
eq(DEFAULT_ART, FRAMED_PLAN.content,
  "the crop and the content are the same size, so the art fills the window")
eq(FRAMED_PLAN.ox, 0, "and the centring has nothing left to centre on x")
eq(FRAMED_PLAN.oy, 0, "nor on y, which is the one-pixel margin gone")
eq(FRAMED_TW, 6, "which is 6 columns of the box on its own")

-- The box gives up the window's run PLUS the clearance the window keeps from the
-- play area's edge, ROUNDED UP TO WHOLE TILES -- because DLG_LEFT and DLG_W are
-- tile counts and a box can only give up whole ones.  That extra column is what
-- stops the window touching the edge of the screen.
--
-- The rounding is also why the gap the player sees is not EDGE_PAD itself.
-- EDGE_PAD is the FLOOR the buy is chosen to clear; what a portrait actually
-- gets is `give * T - plan.w`, which is that floor rounded up to the next tile
-- boundary.  The window is one size now, so that is 8 game px for every crop --
-- which is why the clearance is documented as "at least" everywhere it is
-- stated, and why EDGE_PAD alone does not decide it: the tile does.
eq(FRAMED_GIVE, math.ceil((X.EDGE_PAD + FRAMED_PLAN.w) / T),
  "the box gives up the window's columns AND the clearance, in whole tiles")
eq(FRAMED_GIVE, 7, "which is 7 columns for the 48px window")
eq(X.EDGE_PAD, 4, "the clearance being 4 game px, half a tile")
eq(FRAMED_GIVE * T - FRAMED_PLAN.w, 8,
  "so the window realises 8 game px -- the floor rounded UP to the tile")
ok(FRAMED_GIVE * T - FRAMED_PLAN.w >= X.EDGE_PAD,
  "which is never less than the clearance, because that is what the buy is for")
eq(FRAMED_TEXT_W, 152, "so the text gets 152px")

eq(seenW, 26 - FRAMED_GIVE, "FRAMED draws the box 7 columns short")
eq(Chrome.DLG_W, 26, "and puts the box's width straight back afterwards")
eq(lastCall() and lastCall().maxWidth, FRAMED_TEXT_W, "FRAMED leaves the text 152px")
eq(lastCall() and lastCall().x, VANILLA_X, "FRAMED-RIGHT does not move the text")

-- ------- where FRAMED's panel stands, and how far it is from the words
--
-- The box is drawn short for the length of the draw, so the columns it gives up
-- are free for the panel.  Gen 2's framedLayout says the same thing
-- (panelTx = tx + boxTw on the right, tx on the left).
--
-- "The columns the box gave up" means the columns it is VISIBLE in, not the
-- content rect it declares.  dialogueFrame draws the border CHROME_L columns
-- left of DLG_LEFT and CHROME_R past DLG_LEFT + DLG_W, so the box the player
-- sees runs from L0 - CHROME_L to L0 + W0 + CHROME_R -- 240x48 at (0,112), the
-- whole screen width.  Measured by .probe/dp3_chrome_probe.lua rather than read
-- off the constants.
--
-- The panel hangs off the box's own visible edge and its OUTER edge lands
-- EDGE_PAD in from the play area's, so it touches neither the box nor the screen.
-- It used to be flush with the play area's edge on the outer side and flush with
-- the box on the inner one, which on a phone meant the portrait ran off the side
-- of the device; the run the box gives up is a whole tile wider than the panel
-- for exactly that reason (see FRAMED_GIVE above).
--
-- The run is whole tiles and the window is six of them, so the slack is the
-- rounding of `give` itself: EDGE_PAD 4 asks for 4px of gap and a box can only
-- sell whole tiles, so it sells 8 and the spare 4 lands on the OUTER side.  The
-- window is one size now, so that slack is 8px for EVERY crop -- a narrow
-- hand-tuned crop changes only the art inside the window, not the margin, which
-- is why the 12px crop below is asserted to have the same one.
--
-- What the panel does NOT do is overlap the box's border.  The panel's inner
-- edge lands on the box's visible edge and the text pen is CHROME_L columns
-- further in, so there is CHROME_L columns -- 16px -- of the box's own border
-- showing between the portrait and the first letter.  That clearance is a
-- consequence of the revert, not an oversight, so it is asserted rather than
-- left for the next reader to rediscover.
io.write("-- where FRAMED's panel stands\n")

-- The window's OUTERMOST fill.  It is the ENGINE's standard-frame border colour
-- now rather than the black this mod used to paint: the panel is Chrome.stdFrame's
-- own 9-slice, so the outer rect is the engine's slate ring, the pale bevel sits
-- inside it and the white content inside that.  Matched on the colour as well as
-- the size, because three nested fills share this rect's origin and its width is
-- the one that says where the window ends.
--
-- The colour is load-bearing rather than decoration, and it is the reason this
-- helper matches on it: 1.8.0's panel was black with a white field, so a helper
-- that matched on width alone would happily report that old rectangle as the
-- window and every assertion built on it would be measuring the wrong release.
local PANEL_BORDER_COLOR = 98 / 255
local function panelOf(wantW)
  wantW = wantW or FRAMED_PLAN.w
  for i = #rects, 1, -1 do
    local r = rects[i]
    if r.mode == "fill" and r.w == wantW and r.color
      and math.abs(r.color[1] - PANEL_BORDER_COLOR) < 1e-9 then
      return r
    end
  end
  return nil
end

-- The white content rect inside the border -- the box the art is centred in.
local function contentOf(wantW)
  for i = #rects, 1, -1 do
    local r = rects[i]
    if r.mode == "fill" and r.color and r.color[1] == 1 and r.color[2] == 1
      and r.color[3] == 1 and (not wantW or r.w == wantW) then
      return r
    end
  end
  return nil
end

local function framedDraw(sideWanted, descriptor, wantW)
  style, side = "framed", sideWanted
  rects, draws, STD.calls = {}, {}, {}
  openBox(descriptor or { trainerType = 17, sprite = "SPRITE_HIKER" })
  Message.draw()
  return panelOf(wantW), artExtent(artDraw())
end

-- Where the box's VISIBLE edge lands after the swap, and where the text pen
-- lands with it.  The box gives up FRAMED_GIVE columns of its CONTENT rect, so
-- its own frame edge moves in by the same amount and its pen moves along with
-- it -- on the left the pen goes right, on the right the clip comes left.
local FRAMED_LEFT_BOX  = (Chrome.DLG_LEFT + FRAMED_GIVE - X.CHROME_L) * T
local FRAMED_RIGHT_BOX = (Chrome.DLG_LEFT + Chrome.DLG_W - FRAMED_GIVE + X.CHROME_R) * T
local FRAMED_PEN_L = (Chrome.DLG_LEFT + FRAMED_GIVE) * T
local FRAMED_PEN_R = (Chrome.DLG_LEFT + Chrome.DLG_W - FRAMED_GIVE) * T

-- The run the box gave up minus the panel that stands in it: the slack the tile
-- rounding leaves.  This release CENTRES the panel in that run, so the slack is
-- split in two -- one half against the play area's own edge, the other between
-- the panel and the box -- and each half is asserted as a distance rather than
-- as a coordinate, so the check names the invariant instead of restating the
-- arithmetic that produced it.
--
-- The gap that matters is the inner one: "the spacing from the panel edge to the
-- top of the box is exactly 4px" is MARGIN's reading of it (a panel standing
-- over the box) and this is FRAMED's (a panel standing beside it).  Filing the
-- panel flush against the box, which is what 1.8.3 did, is that number being
-- zero; splitting the slack is what makes it EDGE_PAD.
-- The slack is computed rather than held in a local of its own, because this
-- suite is compiled as ONE Lua function and LuaJIT caps that at 200 locals.
local FRAMED_INSET = math.floor((FRAMED_GIVE * T - FRAMED_PLAN.w) / 2)

eq(FRAMED_INSET, X.EDGE_PAD,
  "the run's slack is exactly two EDGE_PADs, so each side gets one")
eq(FRAMED_GIVE * T - FRAMED_PLAN.w, 2 * X.EDGE_PAD,
  "the slack being EDGE_PAD twice over")

local leftPanel, leftArt = framedDraw("left")
ok(leftPanel ~= nil, "FRAMED-LEFT draws a panel")
-- THE CLEARANCE, which is this release.  BOX_LEFT IS the play area's own left
-- edge: (DLG_LEFT - CHROME_L) * T, which is 0.
eq(leftPanel and leftPanel.x, BOX_LEFT + FRAMED_INSET,
  "FRAMED-LEFT stands half the run's slack in from the screen's own left edge")
eq(leftPanel and (leftPanel.x - BOX_LEFT), X.EDGE_PAD,
  "which is exactly the clearance EDGE_PAD states, not merely the floor")
ok(leftPanel and leftPanel.x > BOX_LEFT,
  "so on a phone it no longer runs off the side of the device")
eq(leftPanel and leftPanel.w, FRAMED_PLAN.w, "and it is the panel's own width")
eq(leftPanel and leftPanel.h, FRAMED_PLAN.h, "and its height")
eq(leftPanel and leftPanel.y, BOX_TOP + math.floor((BOX_H - FRAMED_PLAN.h) / 2),
  "and it is centred against the visible box")

-- The panel's inner edge stops EDGE_PAD short of the box's visible edge.  The
-- text pen is CHROME_L columns further in than the box, so what stands between
-- the portrait and the first letter is the clearance AND that border -- which is
-- why the same portrait is no longer crowding the words.
eq(leftPanel and (leftPanel.x + leftPanel.w), FRAMED_LEFT_BOX - FRAMED_INSET,
  "FRAMED-LEFT ends it on the box's side of the run")
eq(FRAMED_LEFT_BOX - (leftPanel and leftPanel.x + leftPanel.w or 0), X.EDGE_PAD,
  "and the gap from the panel's edge to the box is exactly EDGE_PAD")
eq(FRAMED_PEN_L - (leftPanel and leftPanel.x + leftPanel.w or 0),
  X.CHROME_L * T + X.EDGE_PAD,
  "so the pen is CHROME_L columns and the clearance past it")
ok(leftPanel and (leftPanel.x + leftPanel.w) < FRAMED_PEN_L,
  "and the panel never reaches the words")
eq(lastCall() and lastCall().x, FRAMED_PEN_L, "which is where the pen really is")

local rightPanel, rightArt = framedDraw("right")
eq(rightPanel and (rightPanel.x + rightPanel.w), BOX_RIGHT - FRAMED_INSET,
  "FRAMED-RIGHT ends it the same half-slack in from the screen's own right edge")
eq(BOX_RIGHT - (rightPanel and (rightPanel.x + rightPanel.w) or 0), X.EDGE_PAD,
  "which is the same clearance the left-hand panel keeps")
ok(rightPanel and (rightPanel.x + rightPanel.w) < BOX_RIGHT,
  "so the right-hand panel keeps the same clearance the left one does")
eq(rightPanel and rightPanel.w, FRAMED_PLAN.w, "at the panel's own width")
eq(rightPanel and rightPanel.h, FRAMED_PLAN.h, "and its height too")
eq(rightPanel and rightPanel.y, leftPanel and leftPanel.y,
  "at the same height as the left one")
eq(rightPanel and rightPanel.x, FRAMED_RIGHT_BOX + FRAMED_INSET,
  "and it starts the same clearance clear of the box's own visible edge")
eq(rightPanel and rightPanel.x - FRAMED_PEN_R, X.CHROME_R * T + X.EDGE_PAD,
  "so the gap from the text to its edge is CHROME_R columns and the clearance")
eq(lastCall() and lastCall().x, VANILLA_X, "and on the right the pen does not move")

-- ------- the panel IS the engine's menu window
--
-- This is the assertion that separates the current shape from every earlier one,
-- and it is the one the mod's own hand-painted panel could not make.  1.8.0 drew
-- a one-pixel black outline around the art and called the result a panel; 1.6.0
-- drew a fixed 48px square and stretched the art into it.  Neither was the
-- game's own window.  What has to hold now is that the portrait wears the SAME
-- frame the start menu and the OPTION page wear -- Chrome.stdFrame, asked for by
-- the mod rather than imitated by it -- so a change to the game's own window
-- moves the portrait with it and the mod cannot drift away from the menu.
--
-- The spy above is what makes that a measurement rather than a claim.  It is
-- also the assertion that survives the extracted tiles being present or absent,
-- because the tiles and the engine's flat fallback come out of the same call --
-- which is why the fill assertions below name the FALLBACK's colours: this
-- checkout has no data/generated, so that is the branch in play.
io.write("-- the panel is the engine's menu window\n")

-- A nil panel would throw on the arithmetic below and take the rest of the suite
-- with it, which hides the MARGIN failures behind one error.  The assertions are
-- what should fail, not the harness, so the zeros stand in and every derived
-- expectation fails on its own terms.
local rp = rightPanel or { x = 0, y = 0, w = 0, h = 0 }
local rc = contentOf(X.PANEL_CONTENT_TW * T) or { x = 0, y = 0, w = 0, h = 0 }
local lastStd = STD.calls[#STD.calls]

-- The call itself: the mod asks the engine for a window, in the only shape the
-- engine offers -- tile coordinates -- having translated to the content rect
-- first, so the ask lands at the origin and its size is the content.
ok(lastStd ~= nil, "the mod asks the engine for a standard menu frame")
eq(lastStd and lastStd.tx, 0, "at the origin, because the mod has already translated")
eq(lastStd and lastStd.ty, 0, "on both axes")
eq(lastStd and lastStd.tw, X.PANEL_CONTENT_TW, "for a content-sized window")
eq(lastStd and lastStd.th, X.PANEL_CONTENT_TW, "on both axes too")

-- The window's OUTER edge, which is what the mod calls the panel.  stdFrame
-- draws its border one tile OUTSIDE the rect it is handed, so the panel is the
-- content plus two tiles -- six, whatever the crop.
eq(rp.w, X.PANEL_MAX_TW * T, "so the panel is the window's own six tiles, 48px")
eq(rp.h, X.PANEL_MAX_TW * T, "on both axes, because a tile border is square")
ok(rp.color and math.abs(rp.color[1] - PANEL_BORDER_COLOR) < 1e-9,
  "painted in the engine's own frame colour, not the black this mod used to use")

-- The white content rect inside it, which is the box the art is centred in.
eq(rc.w, X.PANEL_CONTENT_TW * T, "and its content rect is the window's own 32px")
eq(rc.x - rp.x, X.PANEL_BORDER_TW * T, "one border in from the panel's left edge")
eq(rc.y - rp.y, X.PANEL_BORDER_TW * T, "and one border down from its top")
eq(rp.w - rc.w, 2 * X.PANEL_BORDER_TW * T,
  "the border being what separates the two, one tile on each side")

-- And the art, centred in that content at the plan's whole-number zoom.  This is
-- the half that still varies per portrait: the window is one size, the art is the
-- crop's own at 1x, 2x or 3x.
ok(rightArt ~= nil, "and the art is drawn inside the content")
eq(rightArt and (rightArt.x - rc.x), FRAMED_PLAN.ox, "centred in it horizontally")
eq(rightArt and (rightArt.y - rc.y), FRAMED_PLAN.oy, "and vertically")
eq(rightArt and rightArt.w, DEFAULT_ART, "at the crop's own 32px")
eq(rightArt and rightArt.scale, FRAMED_PLAN.zoom, "which is the plan's own 1x")

-- ------- a narrower crop gets a BIGGER ZOOM, not a narrower panel
--
-- This is the cost of the window, stated as a property rather than a complaint.
-- The border is drawn from 8x8 tiles and only lines up on the tile grid, so the
-- window is a whole number of tiles on both axes and is therefore ONE size for
-- everybody -- six tiles, 48px.  What a narrow crop changes is the ART inside it:
-- a 12px hand-tuned crop is 2x where the 30px default is 1x, so it still fills
-- its content rather than sitting as a speck in the corner of it.
--
-- The consequence, and the thing that has to be said out loud because it is a
-- reversal of 1.8.0: the text width no longer depends on the speaker.  A 12px
-- crop asks the box for the same seven columns a 30px one does, because
-- framedGive reads the WINDOW's size and the window is a constant.  1.8.0 gave
-- the panel the art's own size -- a 38px panel for a 12px crop against a 32px one
-- for the default -- which made the cost of a portrait a property of the speaker;
-- 1.8.2 buys a constant text width back with a fixed window and pays for it with
-- the panel, which is now bigger than most crops need.
--
-- The zoom has to be observable, or "a whole number" is only a constant this file
-- holds rather than a thing the code does.  A 12px crop is 2x -- 24px of art in
-- the 32px content, four pixels of white on each side -- which is art/crops.lua's
-- "anything smaller zooms in" done properly: the ART grows with the crop's
-- smallness, but only as far as the content allows.  Picture 57 is the BUG
-- CATCHER and is used once, here, for that.
io.write("-- a narrower crop gets a bigger zoom, not a narrower panel\n")

X.crops.trainers["57"] = { 8, 8, 12 }
local NARROW_PLAN = X.panelPlan({ w = 12, h = 12 })
local narrowPanel, narrowArt = framedDraw("right",
  { trainerType = 31, sprite = "SPRITE_HIKER" }, NARROW_PLAN.w)
X.crops.trainers["57"] = nil
ok(narrowArt ~= nil, "a 12px crop draws")
eq(NARROW_PLAN.zoom, 2, "and it is zoomed 2x, the largest whole number that fits the content")
eq(NARROW_PLAN.w, X.PANEL_MAX_TW * T, "so its window is the same 48px the default crop gets")
eq(NARROW_PLAN.h, NARROW_PLAN.w, "on both axes")
eq(NARROW_PLAN.tiles, FRAMED_TW, "which takes the window's own six columns of the box")
ok(NARROW_PLAN.tiles == FRAMED_TW, "so the text width no longer depends on the speaker")
eq(narrowArt and narrowArt.w, 12 * NARROW_PLAN.zoom, "and the art is 24px -- the crop at 2x")
eq(narrowArt and narrowArt.h, 12 * NARROW_PLAN.zoom, "on both axes")
eq(narrowArt and (narrowArt.x - (narrowPanel and narrowPanel.x or 0)),
  X.PANEL_BORDER_TW * T + NARROW_PLAN.ox,
  "with the border and the plan's own centring clear of the panel's edge")
eq(narrowArt and (narrowArt.y - (narrowPanel and narrowPanel.y or 0)),
  X.PANEL_BORDER_TW * T + NARROW_PLAN.oy,
  "on the vertical too")
eq(narrowArt and (narrowArt.w + 2 * NARROW_PLAN.ox), NARROW_PLAN.content,
  "so the art plus the centring on both sides is exactly the content it fills")

-- The panel stands half the run's slack clear of the box AND of the play
-- area's edge, whatever the crop.  The run is 7 tiles -- 56px -- and the window
-- is 48px, so 8px of slack is split four and four.  The run is bought for the
-- WINDOW rather than the crop, so the split is the same for a hand-tuned 12px
-- crop as for the default -- only the art inside the window changes.
local narrowGive = X.framedGive(NARROW_PLAN)
eq(narrowGive, 7, "the 12px crop's run is 7 columns, the same as the default's")
eq(narrowGive, FRAMED_GIVE, "because the run is bought for the window, not the crop")
eq(narrowPanel and narrowPanel.x,
  (Chrome.DLG_LEFT + Chrome.DLG_W - narrowGive + X.CHROME_R) * T + FRAMED_INSET,
  "and the panel starts EDGE_PAD clear of the box's own visible edge")
eq(BOX_RIGHT - (narrowPanel and (narrowPanel.x + narrowPanel.w) or 0), X.EDGE_PAD,
  "so its margin is EDGE_PAD -- the same as the default crop's")
ok(narrowPanel and (narrowPanel.x + narrowPanel.w) < BOX_RIGHT,
  "which still keeps it clear of the screen's own edge")

-- The text width is a property of the WINDOW now, and the suite says so out loud
-- rather than leaving it to be discovered: this is the trade the release makes,
-- and `framedGive` is what the wrap and the clip are both handed.
eq(X.textWidthFor("framed", "left", narrowGive), (26 - narrowGive) * T,
  "and it leaves that speaker's text 152px, the same as the default crop's")
eq(X.textWidthFor("framed", "left", narrowGive), FRAMED_TEXT_W,
  "so two speakers in the same layout get the SAME text width")
eq(X.textWidthFor("framed", "left", narrowGive),
  X.textWidthFor("framed", "right", narrowGive),
  "and SIDE still must not change it")

-- ------- a 16px crop is drawn at 2x, and fills its content exactly
--
-- art/crops.lua documents the whole-number behaviour ("a size of 32 is 1:1 and
-- anything smaller zooms in") and this release honours it: a 16px crop is drawn
-- at 2x -- 32px, which is the content's own width, so the centring has nothing
-- left to centre.  1.6.0 scaled it to fill a fixed 46px window instead -- 2.875x
-- -- which is the difference between a portrait the size of its crop and one the
-- size of its frame.
--
-- Picture 56 is the COOLTRAINER and nothing else in this file touches it, so the
-- override filed against it cannot be answered from an earlier cut of the same
-- picture -- the crop cache is keyed on the picture, not on the rectangle.
io.write("-- a 16px crop is drawn at 2x, and fills its content exactly\n")

local ZOOM_PLAN = X.panelPlan({ w = 16, h = 16 })
X.crops.trainers["56"] = { 8, 8, 16 }
local zoomPanel, zoomArt = framedDraw("right",
  { trainerType = 30, sprite = "SPRITE_HIKER" }, ZOOM_PLAN.w)
X.crops.trainers["56"] = nil
ok(zoomArt ~= nil, "a 16px crop draws")
eq(ZOOM_PLAN.zoom, 2, "at exactly 2x, the largest whole number that fits the content")
ok(ZOOM_PLAN.zoom == math.floor(ZOOM_PLAN.zoom),
  "which is a whole number of times, deliberately")
eq(zoomArt and zoomArt.w, 32, "so the art is 32px, not the 30 a 1x snap would give")
eq(ZOOM_PLAN.ox, 0, "and it is exactly the content's width, so nothing is left over")
eq(zoomPanel and zoomPanel.w, X.PANEL_MAX_TW * T,
  "and the window is the window's own 48px, the same as the default crop's")
eq(zoomArt and zoomArt.x, (zoomPanel and zoomPanel.x or 0) + X.PANEL_BORDER_TW * T,
  "with nothing but the border to its left")
eq(zoomArt and zoomArt.y, (zoomPanel and zoomPanel.y or 0) + X.PANEL_BORDER_TW * T,
  "and nothing but the border above it")

-- Two different crops, the SAME window, each flush against its own box's visible
-- edge.  What matters is that the window follows the ENGINE's frame rather than
-- the art: it is one size for everybody now, and the art inside it is what
-- varies.  1.8.0 made the two panels different widths, and that is exactly the
-- shape this release replaced.
--
-- The 16px and 30px crops therefore share an x AND a width, and the clearance
-- they keep is the same 8px -- while the art inside them is 32px against 30px.
-- That pair is the whole reversal in two lines: same window, different art.
eq(zoomPanel and zoomPanel.w, rightPanel and rightPanel.w,
  "a 16px crop and a 30px crop make the SAME window, because the window is one size")
eq(zoomArt and rightArt and zoomArt.w, rightArt.w,
  "and the same art inside it, because both crops fill the same window")
eq(zoomArt and zoomArt.scale, 2 * (rightArt and rightArt.scale or 0),
  "the 16px crop drawn at twice the zoom of the 32px one")
eq(zoomPanel and zoomPanel.x, (Chrome.DLG_LEFT + Chrome.DLG_W - X.framedGive(ZOOM_PLAN)
    + X.CHROME_R) * T + FRAMED_INSET,
  "and each starts EDGE_PAD clear of the box's own visible edge")
eq(BOX_RIGHT - (zoomPanel and (zoomPanel.x + zoomPanel.w) or 0), X.EDGE_PAD,
  "with the same clearance the default crop gets")
ok((BOX_RIGHT - (zoomPanel and (zoomPanel.x + zoomPanel.w) or 0)) >= X.EDGE_PAD,
  "which is still the floor, because that is what the buy was chosen to clear")

-- ------- the text is WRAPPED to the width it is DRAWN in
--
-- This is the other half of the release, and it is the half that made the
-- clipping go away.  Message.show word-wraps the box's text ONCE, against
-- ctx.maxWidth, defaulting to a hardcoded 208 -- the vanilla box's own 26
-- columns.  Message.drawText then CLIPS each line at Chrome.DLG_W * T, which
-- follows the geometry.  Vanilla the two agree because 208 IS 26 columns; every
-- layout here breaks that agreement, and the mod only ever changed the second.
-- FRAMED shrank the box and clipped at the narrower width it shrank to; INSET
-- left the box alone and took its own reserve off the font's width from inside
-- the font wrapper.  Either way the engine had wrapped the line for a 208px box
-- and the draw cut its tail off -- "the text is clipped", and on INSET
-- "obstructed by the portrait", because a line that should have broken earlier
-- ran on under the art.
--
-- So the wrap is now handed the layout's own width.  It has to be supplied
-- BEFORE vanillaShow, because that call is where the wrap happens, which makes
-- Message.show the one place the frame is read from `opts` rather than from
-- Message.frameKind().  The two agree by construction -- Message.show derives
-- its frame from exactly those opts and always overwrites it.
--
-- The wrap spy above is what makes this measurable.  Without it every assertion
-- in this section would be reading the mod's own arithmetic back.
io.write("-- the text is wrapped to the width it is drawn in\n")

local function wrapWidth(styleWanted, sideWanted, descriptor, opts)
  style, side = styleWanted, sideWanted
  openBox(descriptor or { trainerType = 17, sprite = "SPRITE_HIKER" }, opts)
  return lastWrap() and lastWrap().maxWidth
end

-- the rule itself, read off the mod's own arithmetic.  FRAMED's answer is a
-- constant now -- the window is one size and the box also gives up the clearance
-- -- so its calls pass framedGive's answer, which is the same number Message.show
-- passes for the same speaker.
eq(X.textWidthFor("off", "left"), VANILLA_W, "OFF wraps to vanilla's 208px")
eq(X.textWidthFor("inset", "left"), VANILLA_W - INSET_RESERVE_PX,
  "INSET-LEFT wraps to 21 columns")
eq(X.textWidthFor("inset", "right"), VANILLA_W - INSET_RESERVE_PX,
  "and INSET-RIGHT wraps to the same 21 -- SIDE is not a width")
eq(X.textWidthFor("framed", "left", FRAMED_GIVE), FRAMED_TEXT_W,
  "FRAMED wraps to the columns its own window and clearance leave it")
eq(X.textWidthFor("framed", "right", FRAMED_GIVE), FRAMED_TEXT_W,
  "and the same on the right -- SIDE is not a width here either")
eq(X.textWidthFor("margin", "left"), VANILLA_W,
  "MARGIN costs the text nothing -- it draws outside the box")

-- and the same numbers, read off the REAL wrap the engine performed
eq(wrapWidth("off", "left"), 208, "an OFF box is wrapped the vanilla way")
eq(wrapWidth("inset", "left"), VANILLA_W - INSET_RESERVE_PX,
  "an INSET-LEFT box is wrapped the reserved run narrower")
eq(wrapWidth("inset", "right"), VANILLA_W - INSET_RESERVE_PX,
  "and INSET-RIGHT is wrapped the same, because SIDE must not change the width")
eq(wrapWidth("framed", "left"), FRAMED_TEXT_W,
  "a FRAMED box is wrapped the columns its panel leaves")
eq(wrapWidth("margin", "left"), 208, "and a MARGIN box keeps the full 26")

-- The pair that matters.  A wrap narrower than the clip is only cosmetic if the
-- clip did not follow it -- so measure both numbers on the SAME box: the wrap
-- the engine performed, and the width the font was finally handed.
local function wrapVersusDraw(styleWanted, sideWanted)
  style, side = styleWanted, sideWanted
  openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
  Message.draw()
  return lastWrap() and lastWrap().maxWidth, lastCall() and lastCall().maxWidth
end

local wWrap, wDraw = wrapVersusDraw("framed", "left")
eq(wWrap, FRAMED_TEXT_W, "FRAMED wraps to the columns its panel leaves")
eq(wDraw, FRAMED_TEXT_W, "and draws in the same -- the wrap and the clip agree")

local iWrap, iDraw = wrapVersusDraw("inset", "left")
eq(iWrap, VANILLA_W - INSET_RESERVE_PX, "INSET-LEFT wraps to 21 columns")
eq(iDraw, VANILLA_W - INSET_RESERVE_PX, "and draws in 21 -- likewise")

local oWrap, oDraw = wrapVersusDraw("off", "left")
eq(oWrap, 208, "OFF wraps to 26 columns")
eq(oDraw, 208, "and draws in 26 -- vanilla's own agreement, untouched")

-- The caller's own tables have to survive the copy.  A script hands the same
-- opts to several boxes, and ctx is also where the names the text expands
-- through live (text_ir.lua reads ctx.playerName) -- so a fix that narrowed the
-- wrap by mutating the caller's ctx would trade clipped text for "PLAYER".
io.write("-- the caller's ctx survives the wrap fix\n")
local mine = { playerName = "ALMDAR", rivalName = "TERRY" }
style, side = "inset", "left"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" }, { ctx = mine })
eq(lastWrap() and lastWrap().maxWidth, VANILLA_W - INSET_RESERVE_PX,
  "the wrap is narrowed for the layout")
eq(lastWrap() and lastWrap().playerName, "ALMDAR",
  "and the player's name rides along into the wrap")
eq(mine.maxWidth, nil, "and the caller's own ctx is left untouched")
eq(mine.playerName, "ALMDAR", "with its own fields intact")

-- the other frames keep vanilla's own widths, which is the negative control:
-- a mod that narrowed every box would pass everything above.
eq(wrapWidth("inset", "left", { trainerType = 17, sprite = "SPRITE_HIKER" },
  { frame = "sign" }), 208, "a sign frame is wrapped the vanilla way")
eq(wrapWidth("inset", "left", { trainerType = 17, sprite = "SPRITE_HIKER" },
  { frame = "battle", battle = true }), 212, "and so is a battle frame")

-- ------- a page must not end on a single word
--
-- The other half of narrowing the wrap, and the one that only shows up in the
-- game.  The engine's wrap is greedy -- it fills each line as far as it goes and
-- lets the remainder fall where it may, with no short-line balancing at all
-- (text_ir.lua:276, `wrap_subline`) -- and on Gen 3 a third line becomes a new
-- PAGE, which is an A press (text_ir.lua:382, `onPage >= 2`).  So a line that
-- falls to one word is a button to advance past a page the player has already
-- read.
--
-- It does not happen at vanilla's 208, because the ROM's text is authored to two
-- lines of 26 columns.  At the width a portrait costs it does -- the line below
-- is one of the real FRLG lines that ends its second page on a single word:
--
--   "The tall grass is full of wild POKeMON that will jump out at you."
--
-- (.probe/dp3_wrap_probe.lua found the shape, and .probe/dp3_orphan_probe.lua
-- measured the fix across a dozen real FRLG lines at 208/176/168/160.  The line
-- has moved once per width change; see ORPHAN_TEXT below for why it is derived
-- rather than typed.)
--
-- The fix is a REFLOW, not a re-wrap: the engine's own breaks are kept and the
-- last word of the preceding line moves down when the two still fit.  That is
-- safe to do to text this mod did not author for two reasons, and both are
-- asserted below rather than asserted-in-a-comment:
--
--   * the word sequence is unchanged -- it is the same text;
--   * the LINE count and the PAGE count are unchanged, so nothing repaginates.
--
-- The second is the one that matters.  The engine decides pages by counting
-- lines, so a reflow that preserved every word but changed a line count would
-- move every page boundary in the box.
io.write("-- a page must not end on a single word\n")

local function wordsOf(s)
  local o = {}
  for w in s:gmatch("%S+") do o[#o + 1] = w end
  return o
end
local function linesOf(s)
  local o = {}
  for line in (s .. "\n"):gmatch("(.-)\n") do o[#o + 1] = line end
  return o
end
local function pagesOf(s)
  local o = {}
  for p in (s .. "\f"):gmatch("(.-)\f") do o[#o + 1] = p end
  return o
end
-- A page ends on a single word if its last line holds exactly one.
local function endsOnOneWord(s)
  local pages = pagesOf(s)
  local last = linesOf(pages[#pages])
  return #wordsOf(last[#last]) == 1
end
local function countOf(s, sep)
  local n = 1
  for _ in s:gmatch(sep) do n = n + 1 end
  return n
end

-- The line the probe found, and the reason it was found: it is real FireRed
-- text, and at FRAMED's width it really does orphan a word.
--
-- That width is FRAMED_TEXT_W -- the box's 26 columns less the run the window
-- takes -- so the box measured below is the box that actually orphans it, and
-- it is derived rather than typed for a reason.  This matters, and it has now
-- bitten four times: the section used to run on INSET-LEFT, and when INSET-LEFT
-- got a column of clearance the line stopped orphaning at the new width; then
-- FRAMED's own width moved and the line it had been using stopped orphaning
-- there too; 1.8.1 narrowed FRAMED by a column for the clearance, which moved it
-- a third time; and 1.8.2 narrowed it again, from 168 to 152, where the old line
-- no longer orphans at all -- .probe/dp3_orphan_probe.lua measures it as two
-- balanced lines at 152 and only at 176 and 168 does it drop a word.  Every time
-- the assertions still passed, because "no page ends on one word" is trivially
-- true of a box that never orphaned.  A positive test has to run at a width where
-- the thing it guards actually happens, or it is a tautology dressed as coverage
-- -- which is why ORPHAN_W is read off FRAMED_TEXT_W and not typed.
--
-- The replacement was chosen the same way, by measurement rather than by eye:
-- this line orphans across 144, 152 AND 160, a three-width plateau centred on the
-- width FRAMED now asks for, so it survives a column of drift in either
-- direction.  The line it replaces orphaned at exactly one width and was one
-- column away from being a tautology.
local ORPHAN_TEXT =
  "Your very own POKeMON legend is about to unfold! A dream of yours is coming true!"
local ORPHAN_W = FRAMED_TEXT_W

ok(type(X.reflowOrphan) == "function", "the guard is exported")

-- The engine's own answer for this line at that width, with the mod left out of
-- it: that is the thing being fixed, so it has to be shown broken before the fix
-- is believed.
local bypassed = engineWrap(ORPHAN_TEXT, ORPHAN_W)
ok(endsOnOneWord(bypassed),
  "the engine's own wrap at FRAMED's width leaves a page holding one word")

style, side = "framed", "left"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" }, nil, ORPHAN_TEXT)
local guarded = lastWrap() and lastWrap().out
eq(lastWrap() and lastWrap().maxWidth, ORPHAN_W,
  "and FRAMED is the box that gets that width")
ok(type(guarded) == "string", "and the mod's own wrap answers for the same box")
ok(not endsOnOneWord(guarded), "but no page it prints ends on a single word")

-- Safe, and safe in the two specific ways that matter.
eq(#wordsOf(guarded), #wordsOf(bypassed),
  "the reflow neither adds nor drops a word")
local sameOrder = true
do
  local a, b = wordsOf(guarded), wordsOf(bypassed)
  for i = 1, #a do if a[i] ~= b[i] then sameOrder = false break end end
end
ok(sameOrder, "and keeps them in the order they were written")
eq(countOf(guarded, "\n"), countOf(bypassed, "\n"),
  "the number of LINES is unchanged, so nothing repaginates")
eq(countOf(guarded, "\f"), countOf(bypassed, "\f"),
  "and the number of PAGE BREAKS is unchanged")
eq(lastWrap() and lastWrap().maxWidth, ORPHAN_W,
  "and the guard runs at the layout's own width, not vanilla's")

-- The negative controls.  A guard that fired for every box would pass everything
-- above, so a box the mod did NOT narrow has to keep the engine's own text.
--
-- The line for this has to be one that orphans at VANILLA width, and that is not
-- a detail.  The first version of this control reused the 176 line above and
-- compared the mod's output against the engine's wrap -- reached THROUGH the
-- mod's wrapper, so both sides were guarded and the assertion was blind to a
-- guard that fired everywhere.  It passed under mutation L, which removes the
-- gate entirely.  Asserting the PROPERTY instead -- "this box still ends on one
-- word" -- cannot be fooled that way, because that is the thing the gate is for.
local WIDE_ORPHAN =
  "PROF. OAK: This is my grandson. He has been your rival since you were a baby."
ok(endsOnOneWord(engineWrap(WIDE_ORPHAN, 208)),
  "the engine orphans a word at vanilla's 208 on this line too")

style, side = "margin", "left"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" }, nil, WIDE_ORPHAN)
eq(lastWrap() and lastWrap().maxWidth, 208, "a MARGIN box wraps at vanilla's 208")
ok(lastWrap() and endsOnOneWord(lastWrap().out),
  "and the guard stays out of it, so its text is the engine's own")
ok(lastWrap() and lastWrap().out == engineWrap(WIDE_ORPHAN, 208),
  "byte for byte")

style, side = "off", "left"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" }, nil, WIDE_ORPHAN)
ok(lastWrap() and endsOnOneWord(lastWrap().out),
  "and an OFF box is untouched too")
ok(lastWrap() and lastWrap().out == engineWrap(WIDE_ORPHAN, 208),
  "byte for byte")

-- And the guard's own edges, called directly.  A one-word line with nothing
-- before it cannot be fixed and must not be mangled; a donor line that would be
-- left holding one word itself must be refused, or the orphan just moves up.
eq(X.reflowOrphan("grass.", 176), "grass.", "a lone word with no line before it is left alone")
eq(X.reflowOrphan("a b\fgrass.", 176), "a b\fgrass.",
  "and a donor that would be left with one word is refused")
eq(X.reflowOrphan("a b c\fgrass.", 176), "a b\fc grass.",
  "while a donor with room to spare gives its last word up")
eq(X.reflowOrphan("", 176), "", "an empty box is left alone")
eq(X.reflowOrphan("one two three four", 176), "one two three four",
  "and a single line with no page break is never touched")

-- ------- the box geometry is restored even if the draw throws
io.write("-- a throwing draw still restores the box\n")
style, side = "framed", "right"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
Chrome.dialogueFrame = function() error("boom") end
pcall(Message.draw)
Chrome.dialogueFrame = realDialogueFrame
eq(Chrome.DLG_W, 26, "the box's width survives a failing draw")
eq(Chrome.DLG_LEFT, 2, "and so does its column")

-- ------- a portrait belongs on the field dialogue and nowhere else
--
-- INSET and FRAMED both draw at the field box's own coordinates (Chrome.DLG_*),
-- so on any other frame they paint in the wrong place.  EvolutionScene calls
-- Message.draw() with frame "battle" (evolution_scene.lua:139) and its panel is
-- not at Chrome.DLG_*; a sign is frame "sign".
--
-- EggHatch is deliberately NOT one of these, though an earlier version of this
-- comment said it was.  egg_hatch.lua:186 sets frame "dialogue", so the guard
-- passes and the box IS the field box at the field box's own coordinates; it
-- comes out bare because hatching is step-driven and a step has already dropped
-- the press record.  Testing it here would assert the guard does something it
-- does not do.  The MARGIN wrapper has always checked
-- Message.frameKind() before painting -- the two in-frame layouts did not, so a
-- speaker still on record put a portrait AND a 32px text shift on an evolution
-- panel, at coordinates that belong to a box that is not on screen.
--
-- Battle text proper is unaffected either way, and that is worth knowing before
-- reading the battle case below as a regression guard: the battle UI draws its
-- own chrome and calls Message.drawText directly (src/core/game3/battle/ui.lua),
-- so this draw wrapper never runs for a real battle box.
io.write("-- only the field dialogue gets a portrait\n")

local wouldBe = X.portraitFor({ class = 17, sprite = "SPRITE_HIKER" })
ok(wouldBe ~= nil and wouldBe.image ~= nil,
  "the harness can name the picture that must NOT be painted here")

local function painted(image)
  for _, d in ipairs(draws) do
    if d.a == image then return true end
  end
  return false
end

local function openBoxWith(descriptor, opts)
  -- the same helper the rest of the file uses, so the wrap spy is reset the
  -- same way and a frame assertion can never read the previous box's width.
  return openBox(descriptor, opts)
end

style, side = "inset", "left"
draws = {}
openBoxWith({ trainerType = 17, sprite = "SPRITE_HIKER" }, { frame = "sign" })
Message.draw()
ok(not painted(wouldBe.image), "a sign frame paints no portrait")
eq(lastCall() and lastCall().x, VANILLA_X, "and a sign frame's text is not moved")
eq(lastCall() and lastCall().maxWidth, VANILLA_W, "and keeps its full width")

style, side = "inset", "left"
draws = {}
openBoxWith({ trainerType = 17, sprite = "SPRITE_HIKER" },
  { frame = "battle", battle = true })
Message.draw()
ok(not painted(wouldBe.image), "a battle frame paints no portrait")
eq(lastCall() and lastCall().x, 10, "and the battle frame keeps its own baseX")
eq(lastCall() and lastCall().maxWidth, 224, "and its own text width")

-- the negative control, so "paints nothing" cannot be satisfied by a harness
-- that never resolves a portrait in the first place
style, side = "inset", "left"
draws = {}
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
Message.draw()
ok(painted(wouldBe.image), "while the field dialogue still paints the portrait")
eq(lastCall() and lastCall().x, VANILLA_X + INSET_RESERVE_PX, "and still moves the text along")

-- ------- the crop is keyed by the PICTURE, not the class
--
-- Class 43 is RIVAL and its picture is 106, so both numbers are legal keys and
-- the only way to tell which one the mod really used is to make the two
-- rectangles different sizes and watch which size gets cut.  This matters
-- beyond bookkeeping: Brock and Misty are both class 84 but pictures 116 and
-- 117, so a class-keyed table could not give them different framing.
io.write("-- the crop follows the picture, not the class\n")
local cropTable = X.crops
cropTable.trainers["43"]  = { 8, 8, 8 }   -- the class's key: must NOT be used
cropTable.trainers["106"] = { 9, 9, 9 }   -- the picture's key: must be

local cutSize
openBox({ trainerType = 43, sprite = "SPRITE_HIKER" })
local q = lastQuad()
ok(q ~= nil, "the crop is built as a quad, not by copying pixels")
cutSize = q and q.w
eq(cutSize, 9, "the rectangle filed under the picture's id is the one used")
eq(q and q.h, 9, "and the window is square")
eq(q and q.x, 9, "the window's own x is the quad's x")
eq(q and q.y, 9, "and its own y is the quad's y")
cropTable.trainers["43"]  = nil
cropTable.trainers["106"] = nil

-- ------- the crop must not need a pixel readback
--
-- This is the assertion that would have caught the bug that shipped.  LÖVE
-- removed Image:getData in 11.0 and the engine targets 11.5, so a portrait
-- assembled by copying pixels cannot be assembled at all in the game -- and the
-- failure is silent, because the mod builds portraits under a pcall and simply
-- declines.  So: prove the source picture is the shape a real one is (no
-- getData), and then prove a portrait comes out of it anyway.
io.write("-- the crop needs no pixel readback\n")
local real = stubImage(64, 64)
ok(rawget(real, "getData") == nil, "a real LÖVE 11.5 Image has no getData")
local fromBare = X.portraitFor({ class = 17, sprite = "SPRITE_HIKER" })
ok(fromBare ~= nil, "a portrait is still built from a picture with no getData")
ok(fromBare and fromBare.quad ~= nil, "and it carries the quad it will be drawn through")
local tex = fromBare and fromBare.quad and fromBare.quad.tex
ok(tex ~= nil and rawget(tex, "getData") == nil,
   "the quad is bound to the source picture itself, which has no getData")

-- ------- the portrait reaches the draw call
--
-- Everything above measures the layout, and a layout is only worth measuring if
-- a portrait is really painted.  A portrait that resolves but is never handed to
-- love.graphics.draw would satisfy every assertion so far and still show the
-- player nothing -- which is precisely the bug this suite failed to catch, so
-- this is the end of the chain, driven the way the engine drives it: through the
-- world.talk hook, then Message.show, then Message.draw.
io.write("-- the portrait reaches the draw call\n")
style, side = "inset", "left"
openBox({ trainerType = 17, sprite = "SPRITE_HIKER" })
draws = {}
Message.draw()
local painted = nil
for _, d in ipairs(draws) do
  if d.a == lastFront then painted = d break end
end
ok(painted ~= nil, "drawing the box draws the speaker's own picture")
ok(painted and painted.b ~= nil and painted.b.w ~= nil,
   "and it draws it through a quad, not the whole 64x64 sheet")
eq(painted and painted.b and painted.b.w, X.crops.defaults.trainers[3],
   "the quad is the crop rectangle, so a closer window is a closer face")
ok(painted and rawget(painted.a, "getData") == nil,
   "and the picture is drawn as-is, with no pixel readback anywhere")

-- ------- two speakers, two different pictures
--
-- The block above proves A portrait is painted.  It cannot prove it is the
-- RIGHT one: one speaker is enough for "something was drawn".  This is the
-- check that would have caught the bug where every interaction in the game
-- showed the same face, and it has to be taken at the DRAW rather than at the
-- resolver, because a resolver can ask for the right picture id and still be
-- handed one picture back for everybody.
--
-- Note the shape of the failure it guards.  The old stub here minted a fresh
-- image per call, so it could not tell "asked for picture 17" from "asked for
-- picture 17, and 17, and 17".  Keying the stub by id is what gives this
-- section anything to say.
io.write("-- two speakers paint two different pictures\n")

local function paintedImages(descriptor)
  openBox(descriptor)
  draws = {}
  Message.draw()
  local out = {}
  for _, d in ipairs(draws) do out[#out + 1] = d.a end
  return out
end

local function paints(images, image)
  if not image then return false end
  for _, a in ipairs(images) do if a == image then return true end end
  return false
end

-- any picture this suite's own art loader handed out
local function paintsAnyFront(images)
  for _, a in ipairs(images) do
    for _, img in pairs(frontByPic) do
      if a == img then return true end
    end
  end
  return false
end

local guitaristArt = frontByPic[17]
local rivalArt = frontByPic[106]
ok(guitaristArt ~= nil and rivalArt ~= nil and guitaristArt ~= rivalArt,
   "the harness has two different pictures to tell apart")

local guitarDraws = paintedImages({ trainerType = 17, sprite = "SPRITE_HIKER" })
ok(paints(guitarDraws, guitaristArt), "the GUITARIST box paints picture 17")

local rivalDraws = paintedImages({ trainerType = 43, sprite = "SPRITE_HIKER" })
ok(paints(rivalDraws, rivalArt), "the RIVAL box paints picture 106")
ok(not paints(rivalDraws, guitaristArt),
   "and it does NOT paint the GUITARIST's picture")

-- an ordinary object is class 0, which is what every non-trainer in FireRed
-- carries.  It has no art of its own, and the cart's null picture is not art.
local npcDraws = paintedImages({ trainerType = 0, sprite = "SPRITE_YOUNGSTER" })
ok(not paintsAnyFront(npcDraws),
   "an ordinary NPC paints no portrait at all -- not the null one")

local npcArt = X.artFor({ class = 0, sprite = "SPRITE_YOUNGSTER" })
eq(npcArt, nil, "because class 0 resolves to nothing")

-- ------- MARGIN draws over the finished frame, out in the window
--
-- Four things were wrong with it, and they read as one complaint.  It was always
-- on the RIGHT whatever SIDE said.  It was vertically CENTRED in the game frame,
-- which put it half a screen above a box that lives in the bottom fifth of it --
-- "positioned too high on the screen, far from the dialogue box".  It was drawn
-- bare, with no panel behind it -- "no background".  And it was never mirrored,
-- so a Pokemon on the left faced away from its own words -- "facing the wrong
-- direction".
--
-- What it does now is FRAMED's window moved clear of the box: the same art, the
-- same engine-drawn menu border and the same whole-number zoom, on the side the
-- player asked for, standing just above the box -- or out in the letterbox when
-- the window is wider than the 240x160 frame, in which case it costs the text
-- nothing at all.
--
-- It is the SAME window, and that is what makes this layout worth asserting
-- separately.  1.7.0 gave MARGIN the art's own size and kept FRAMED on 1.6.0's
-- fixed 48px square -- the art stretched to fill the 46px window -- on the
-- argument that FRAMED's panel IS its text width.  That argument is about the
-- COLUMNS, not the panel.  1.8.0 put FRAMED back on the art's own size and 1.8.2
-- puts BOTH layouts on the engine's window: one plan, panelPlan, whose size is a
-- constant -- six tiles, 48px -- and whose only per-portrait answer is the zoom.
-- MARGIN spends that window in WINDOW space where there is no tile grid, so the
-- same 48px reaches the screen as 48 * unit device units.  The suite asserts that
-- the two plans agree, because they are one function now.
--
-- It is driven through render.hud, the engine's own screen-space seam
-- (src/core/Game3.lua:_drawHud builds the viewport this is handed), so every
-- coordinate below is in WINDOW units, not game units.
io.write("-- MARGIN draws over the finished frame\n")

-- MARGIN's own plan.  It is the same window FRAMED draws -- one function, one
-- size -- so this is an ALIAS for FRAMED_PLAN in all but name; it is asked for
-- separately rather than copied so that a change which gave the two layouts
-- different windows would show up here instead of being masked by a shared local.
-- The DEFAULT crop is what every viewport below draws.
local MARGIN_PLAN = X.panelPlan({ w = DEFAULT_ART, h = DEFAULT_ART })

-- ------- the renderer double, and the shape of "there is none"
--
-- The mod asks the renderer where the frame was DRAWN (frameRect), and reaches
-- it through require -- so what the answer is depends on what is at
-- package.loaded["src.render.Renderer"] when the hook runs.  Seeding that key is
-- how this suite decides; it is ALSO the only way to say "there is no renderer to
-- ask", because the engine always ships the module and clearing the key just
-- makes require load the real one, uninitialised, answering for Gen 1's 160x144
-- surface.
--
-- So an EMPTY table is the "no renderer" shape: no frameRects to call, so
-- frameRect takes its documented fallback to the payload.  It is the default
-- here, which is what makes every viewport below a test of the FALLBACK -- and
-- the fallback is the branch a Gen 1/2 payload needs, where the reported rect
-- and the drawn one really are the same number.
local NO_RENDERER = {}
local function useRenderer(rect)
  package.loaded["src.render.Renderer"] =
    rect and { frameRects = function() return rect end } or NO_RENDERER
end
local function withRenderer(rect, fn)
  local previous = package.loaded["src.render.Renderer"]
  useRenderer(rect)
  local ok2, a, b = pcall(fn)
  package.loaded["src.render.Renderer"] = previous
  if not ok2 then error(a) end
  return a, b
end

local function marginDraw(sideWanted, viewport, descriptor, plan, drawn)
  style, side = "margin", sideWanted
  rects, draws = {}, {}
  openBox(descriptor or { trainerType = 17, sprite = "SPRITE_HIKER" })
  -- `drawn` is the rect the renderer should answer with, or nil for none.
  local previous = package.loaded["src.render.Renderer"]
  useRenderer(drawn)
  local ok2, err = pcall(Runtime.call, "render.hud", function() end, {}, viewport)
  package.loaded["src.render.Renderer"] = previous
  if not ok2 then error(err) end
  -- The panel's width in window units, derived from the PLAYFIELD rather than
  -- from viewport.scale.  The two differ by dpiX, and deriving this one from
  -- scale would make this helper find no panel at all on a high-DPI viewport --
  -- turning "the panel is in the wrong place" into "the panel was not drawn",
  -- which is a different bug and a much less useful failure.  When a renderer is
  -- in play the mod takes its unit from THERE, so the expected width has to come
  -- from the same place.
  --
  -- `plan` is the answer panelPlan is expected to give for the crop in play.
  -- It defaults to the DEFAULT crop's, which is what every viewport below but
  -- the zoom one draws.
  local unit = drawn and (drawn.uvpw / Display.W)
    or (viewport.gameWidth / Display.W)
  local wantW = (plan or MARGIN_PLAN).w * unit
  return panelOf(wantW), artExtent(artDraw())
end

-- A plain 3x window: 720x480, no letterbox at all, so the panel has to stand
-- above the box.  Display.W/H are the engine's own frame, so this is the real
-- geometry rather than a guess at it.
local plain = {
  width = 720, height = 480, gameX = 0, gameY = 0,
  gameWidth = Display.W * 3, gameHeight = Display.H * 3, scale = 3,
}
-- MARGIN's panel in window units: the window at MARGIN_PLAN's own size, times
-- the window scale.  It IS FRAMED's 48px -- one plan, one size -- and that is
-- asserted rather than assumed, because the two layouts arrived at the same
-- number by different routes in every earlier release.
local MP_W = MARGIN_PLAN.w * 3
local MP_H = MARGIN_PLAN.h * 3

-- The window, stated as one number: a 30px crop gets the engine's 48px menu
-- window, where 1.8.0 gave it a 32px panel that was the art plus an outline and
-- 1.6.0 a 48px square with the art stretched into it.  MARGIN and FRAMED share
-- one plan -- the shape is the shape -- so the two layouts agree about how big
-- the portrait is, and the number they agree on is the window's rather than the
-- crop's.
eq(MARGIN_PLAN.w, X.PANEL_MAX_TW * T,
  "MARGIN's panel is the engine's own six-tile menu window")
eq(MARGIN_PLAN.w, FRAMED_PLAN.w,
  "and it is the same panel FRAMED draws, because it is the same plan")
eq(MP_W, X.PANEL_MAX_TW * 8 * 3,
  "which is the 48px 1.6.0 used -- the same size, drawn as the game's own frame")
eq(MARGIN_PLAN.h, BOX_H,
  "and it is the visible box's own height, so it sits level with the box")

local mLeft, mLeftArt = marginDraw("left", plain)
ok(mLeft ~= nil, "MARGIN draws a panel")
eq(mLeft and mLeft.w, MP_W, "the window wide, in window units")
eq(mLeft and mLeft.h, MP_H, "and the window tall, likewise")
-- THE EDGE CLEARANCE, on the x axis.  The panel used to be flush with the play
-- area's own edge -- boxLeft IS that edge, (DLG_LEFT - CHROME_L) * T, which is
-- 0 -- so on a phone it touched the edge of the screen.  Asserted as the
-- DISTANCE rather than as the coordinate, so the assertion states the invariant
-- ("it keeps MARGIN_PAD") instead of restating the arithmetic that produced it.
--
-- The BOX clearance is the other number on the other axis, and it is the one
-- the request is about: 2 game px between the panel's own bottom edge and the
-- top of the dialogue box.  It is MARGIN_BOX_GAP and NOT MARGIN_PAD, and that
-- split IS this release -- 1.9.1 spent the edge's 4 on both axes, so the panel
-- floated a visible 4 px of white above the box instead of reading as sitting
-- on it.  A test that only ever compared the code against MARGIN_PAD would have
-- stayed green through exactly that, so both numbers are asserted against
-- LITERALS as well as against the constants.  The literal is the requirement;
-- the constant is how it is spelled.
eq(mLeft and (mLeft.x - BOX_LEFT * 3), X.MARGIN_PAD * 3,
  "MARGIN-LEFT stands it MARGIN_PAD in from the play area's own left edge")
eq(mLeft and mLeft.y, BOX_TOP * 3 - MP_H - X.MARGIN_BOX_GAP * 3,
  "and MARGIN_BOX_GAP above the box, not at the frame's vertical centre")
ok(mLeft and (mLeft.y + mLeft.h) < BOX_TOP * 3, "so it clears the box entirely")
ok(mLeft and mLeft.y >= 0, "and it is on screen")

-- The panel must not REACH, and that is what "positioned far above the dialogue
-- box" was about.  At 48px the window is exactly the box's own height, so its
-- top edge lands 48px above the box rather than the 150px 1.4.0's six-tile panel
-- managed -- and the assertion that it is the box's own height is above, because
-- that is the fact the reach follows from.
--
-- MARGIN realises the gap EXACTLY, and that is the difference from FRAMED: it
-- places its panel in WINDOW space, where there is no tile to round to, so 2
-- game px of gap is 2 game px of gap on every device.  The two layouts share the
-- EDGE constant and not the arithmetic, which is why they are asserted apart.
eq(mLeft and (BOX_TOP * 3 - (mLeft.y + mLeft.h)), X.MARGIN_BOX_GAP * 3,
  "and it clears the box by exactly the box gap, no more and no less")
ok(X.MARGIN_BOX_GAP > 0, "which is a real gap rather than a flush edge")
eq(X.MARGIN_BOX_GAP, 2,
  "and it is the 2 game px the request names, not the edge's larger number")
-- The two constants are the two jobs, and this release is the fact that they
-- are no longer one number.  The edge half did not move; the box half came back
-- down to the 2 that 1.9.0 had for both.  Both stated as literals, for the
-- reason in the prose above.
eq(X.MARGIN_PAD, 4, "while the edge clearance keeps its own 4 game px")
ok(X.MARGIN_BOX_GAP < X.MARGIN_PAD,
  "so the panel sits closer to the box than to the edge, which is the composition")

-- A window, not a bare portrait.  Three nested fills make it: the engine's slate
-- ring, its pale bevel and the white content the art sits in.  Without the
-- content the art sat straight on the map, which is exactly what "no background"
-- meant -- and without the ring it was a one-pixel outline scaled up with
-- everything else, which is what 1.8.0 shipped.
--
-- The ring is a whole TILE thick now -- eight game pixels, twenty-four window
-- pixels here -- where the mod's own panel used a single pixel.  That is the
-- point of asking the engine for its frame: the border is the game's, and the
-- game's borders are drawn from tiles.  The cost is that a 30px crop now fills
-- 62.5% of its window (30 of 48 game px) where the 32px panel of 1.8.0 filled
-- 93.75% (.probe/dp3_fill_probe.lua measures the old one) -- the window is the
-- game's own shape rather than the crop's, and that is the trade.
local borderFill = panelOf(MP_W)
local fieldFill = contentOf(MARGIN_PLAN.content * 3)
ok(borderFill ~= nil, "and it is painted as the engine's menu window")
eq(borderFill and borderFill.color and borderFill.color[1], PANEL_BORDER_COLOR,
  "in the engine's own frame colour, not the black this mod used to use")
ok(fieldFill ~= nil, "with a white content rect inside it, so the art is not drawn bare")
eq(fieldFill and fieldFill.color and fieldFill.color[1], 1, "and that content is white")
eq(borderFill and fieldFill and (borderFill.w - fieldFill.w),
  2 * X.PANEL_BORDER_TW * T * 3, "the border being a whole tile thick, not one pixel")

ok(mLeftArt ~= nil, "and the art is drawn in the content")
-- MARGIN draws at a WHOLE-NUMBER zoom, and that is the other half of the
-- release: because the window is a fixed size and the art is fitted INTO it
-- rather than stretched across it, the scale is panelPlan's zoom and the art
-- keeps its own proportions.  1.6.0's fixed frame paid a non-whole fill (46 into
-- 30 is 1.533x) that this shape does not have to.
eq(mLeftArt and mLeftArt.scale, MARGIN_PLAN.zoom * 3,
  "at MARGIN_PLAN's own zoom times the window scale")
eq(mLeftArt and mLeftArt.scale, math.floor(mLeftArt.scale),
  "which is a whole number, because the zoom is a count of whole crops")
-- Where the art lands: the border, then the plan's own centring inside the
-- content.  The ring is no longer the only thing between the panel's edge and
-- the art, and saying so is the point -- the art is centred in a window, not
-- wedged against an outline.
eq(mLeftArt and (mLeftArt.x - (mLeft and mLeft.x or 0)),
  (X.PANEL_BORDER_TW * T + MARGIN_PLAN.ox) * 3,
  "with the border and the plan's own centring to its left")
eq(mLeftArt and (mLeftArt.y - (mLeft and mLeft.y or 0)),
  (X.PANEL_BORDER_TW * T + MARGIN_PLAN.oy) * 3,
  "and the same above it")
ok(mLeftArt and mLeftArt.w <= MARGIN_PLAN.content * 3,
  "and the art fits inside the content it is centred in")

local mRight = marginDraw("right", plain)
eq(mRight and (BOX_RIGHT * 3 - (mRight.x + mRight.w)), X.MARGIN_PAD * 3,
  "MARGIN-RIGHT stands it MARGIN_PAD in from the play area's own right edge")
eq(mRight and mRight.y, mLeft and mLeft.y, "at the same height as the left one")
ok(mRight and mLeft and (mRight.x > mLeft.x),
  "so SIDE really does pick the side, instead of always the right")

-- ------- the panel is placed in WINDOW units, not in framebuffer pixels
--
-- The one number MARGIN takes from the engine rather than from its own
-- constants, and the one it got wrong.  Renderer:endFrame returns
--
--   scale     = Renderer:fitScale() = integer FRAMEBUFFER pixels per GB pixel
--   gameX/Y   = window units
--   gameWidth = uiw * (scale / dpiX)  ->  window units
--
-- so gameWidth is NOT Display.W * scale -- the two differ by exactly dpiX.
-- conf.lua sets t.window.highdpi on mobile only, so dpiX is 1 on the desktop,
-- which is why every viewport above passed; it is 2 or 3 on a phone.  Read as
-- the window-unit scale it drew the panel dpiX times too large AND dpiX times
-- too far from the playfield origin: on a 3x phone the panel came out 128px
-- instead of 42 and landed below the bottom edge of the game frame, which is
-- "the framed portrait sits too far from the dialogue box".
--
-- Every viewport above has scale == gameWidth / Display.W, so not one of them
-- can see this.  This section is built the way the ENGINE builds it.
io.write("-- the panel is placed in window units, not framebuffer pixels\n")

eq(X.unitFor({ gameWidth = 320 }), 320 / Display.W,
  "unitFor takes the scale from the playfield's own width")
eq(X.unitFor({ scale = 4, dpiX = 3 }), 4 / 3,
  "and falls back to scale/dpiX when there is no playfield width")
eq(X.unitFor({ gameWidth = 720, scale = 3, dpiX = 1 }), 3,
  "which is the same number on a desktop, where dpiX is 1")
eq(X.unitFor({}), 0, "and a viewport with neither draws nothing rather than throwing")

-- 360x720 logical at dpiX 3 -- a 1080x2160 phone.  Sp = floor(1080/240) = 4, so
-- the engine's payload is scale = 4 with a playfield of 240 * (4/3) = 320.
local phoneDpi = 3
local phone = {
  width = 360, height = 720,
  gameX = 20, gameY = 66,
  gameWidth = Display.W * 4 / phoneDpi, gameHeight = Display.H * 4 / phoneDpi,
  scale = 4, dpiX = phoneDpi, dpiY = phoneDpi,
}
local PHONE_S = 4 / phoneDpi
local phPanel, phArt = marginDraw("left", phone)
ok(phPanel ~= nil, "a high-DPI viewport still gets a panel")
eq(phPanel and phPanel.w, MARGIN_PLAN.w * PHONE_S,
  "sized in window units, not in framebuffer pixels")
ok(phPanel and phPanel.w < MARGIN_PLAN.w * phone.scale,
  "so it is smaller than reading scale as window units would have made it")
-- The clearance on the phone, which is where the request came from.  It used to
-- be flush with the play area's own origin -- phone.gameX IS that origin, so on
-- this viewport the panel's left edge sat exactly on the frame's edge -- and the
-- rounding to whole device pixels is why this is a `near` and not an `eq`.
near(phPanel and phPanel.x, phone.gameX + X.MARGIN_PAD * PHONE_S,
  "and stands MARGIN_PAD in from the playfield's own origin, not on it", 1)
ok(phPanel and phPanel.x > phone.gameX,
  "so on a phone it no longer touches the edge of the screen")

-- The whole point: it has to be INSIDE the game frame.  Read as framebuffer
-- pixels it was not -- on this viewport it landed about a hundred pixels below
-- the frame's bottom edge, down in the touch-controls deck.
local frameBottom = phone.gameY + phone.gameHeight
ok(phPanel and (phPanel.y + phPanel.h) <= frameBottom,
  "and it is inside the game frame, not below it")
-- The placement rounds to whole device pixels (`math.floor(y + 0.5)`), so the
-- bottom lands within a pixel of the un-rounded arithmetic rather than exactly on
-- it -- 212.67 rounds to a 213px bottom edge.  Asserting equality here would be
-- asserting that a fractional panel lands on a fractional pixel, which is the
-- opposite of what the rounding is there for.
local wantBottom = phone.gameY + BOX_TOP * PHONE_S - X.MARGIN_BOX_GAP * PHONE_S
ok(phPanel and math.abs((phPanel.y + phPanel.h) - wantBottom) <= 1,
  "sitting above the box by the box gap, as on the desktop")
-- The number the request names, in the unit the request names it in: the gap
-- between the box's top and the portrait's bottom is MARGIN_BOX_GAP GAME pixels,
-- and that is 2 -- NOT the edge's 4.  Stated on the phone viewport because that
-- is the one the report came from, and it is the same on every viewport, which
-- is the point of measuring the gap in game px rather than in window px.
eq(X.MARGIN_BOX_GAP, 2, "the box-to-portrait gap is 2 game px")
ok(X.MARGIN_BOX_GAP * PHONE_S >= 2 / phone.dpiX,
  "which on a 3x phone is at least 2 device pixels of real screen, not 2 units")
ok(phArt ~= nil, "and the art is drawn with it")
near(phArt and phArt.w, DEFAULT_ART * MARGIN_PLAN.zoom * PHONE_S,
  "the crop at MARGIN_PLAN's zoom, in window units")

-- ------- the panel is measured against the frame the engine DREW
--
-- The second half of the report, and the one the 8px clearance could not fix
-- because it is not about the clearance at all.
--
-- MARGIN draws in WINDOW space, so it has to know where the dialogue box is on
-- the screen -- and the rect render.hud hands it is not always that rect.  The
-- payload is Game3:_drawHud's Display.fit(w, h), which centres the picture in
-- 48% of the SAFE AREA and takes its scale from the WIDTH alone.  The frame
-- itself is drawn by Renderer:endFrame from Renderer:frameRects(), which fits the
-- picture into Playfield.cutout -- the TOUCH SKIN's viewport, a fraction of the
-- WINDOW -- and takes its scale from BOTH axes of that cutout.
--
-- With no skin selected the cutout is nil and the two agree to the pixel, which
-- is why a desktop never shows this and why every viewport above passes: not one
-- of them has a skin.  With a skin selected they are two different numbers, and
-- .probe/dp3_hudframe_probe.lua measures the distance between the two box
-- positions at 1.5 to 41 GAME px across realistic phone layouts -- so a panel
-- placed 8 game px above the REPORTED box lands up to 49 px above the real one.
--
-- MARGIN is the only layout that can be wrong about this, which is why the
-- report named it: INSET and FRAMED draw inside the canvas, where the box is
-- wherever Chrome says it is.
--
-- Every viewport in this file is a payload with no renderer behind it, so the
-- fallback below is what they all exercise.  This section is the other branch.
io.write("-- the panel is measured against the frame the engine drew\n")

-- The renderer double is defined up beside marginDraw, because marginDraw is
-- what has to seed it.  `frameRects` is the method Renderer:endFrame itself
-- calls, so a table carrying one IS the answer the frame was blitted with -- and
-- it lets the suite put a rect in it that the payload disagrees with, which is
-- the point of this section.

-- The two rects the engine really produces on a portrait phone, taken from
-- .probe/dp3_hudframe_probe.lua: a 360x780 phone at dpi 3 with the default skin
-- (a screen cutout of the top 50% of the window, no notch).
local deckPayload = {
  width = 360, height = 780,
  gameX = 20, gameY = 80.333333333333,
  gameWidth = Display.W * 4 / 3, gameHeight = Display.H * 4 / 3,
  scale = 4, dpiX = 3, dpiY = 3,
}
-- The stub carries BOTH rects Renderer:frameRects answers with, and they are
-- deliberately different: ox/oy is where the WORLD is blitted and uox/uoy is
-- where the UI canvas -- the surface the dialogue box is drawn into -- is.  They
-- coincide while the UI scale equals fitScale, so a stub that carried only one
-- could not tell the two apart.
local deckDrawn = { ox = 20, oy = 66.133333333333,
                    uox = 20, uoy = 88.333333333333,
                    uvpw = Display.W * 4 / 3, uvph = Display.H * 4 / 3 }
local DECK_S = deckDrawn.uvpw / Display.W

-- frameRect prefers the renderer, and takes BOTH halves of the answer from it:
-- the origin it was blitted at and the scale it was blitted with.
local fr = withRenderer(deckDrawn, function() return X.frameRect(deckPayload) end)
eq(fr and fr.y, deckDrawn.uoy, "frameRect takes the origin from the renderer")
eq(fr and fr.unit, DECK_S, "and the unit from the renderer's own playfield width")
eq(fr and fr.x, deckDrawn.uox, "and the horizontal origin too")
ok(fr and fr.y ~= deckDrawn.oy,
  "and it is the UI rect, not the world rect -- they are only equal by accident")
eq(fr and fr.height, deckDrawn.uvph, "and its height is the UI surface's own")

-- And falls back to the payload when there is no renderer to ask, which is the
-- branch every other viewport in this file goes down -- and the branch a Gen 1/2
-- payload needs, where the two really are the same number.
local fb = withRenderer(nil, function() return X.frameRect(deckPayload) end)
eq(fb and fb.y, deckPayload.gameY, "with no renderer it falls back to the payload")
eq(fb and fb.unit, deckPayload.gameWidth / Display.W, "and to the payload's own scale")

-- The two box positions really are different numbers, so the assertions below
-- cannot both pass by accident.
local function boxTopOf(frameY, unit)
  return frameY + (Chrome.DLG_TOP - X.CHROME_UP) * T * unit
end
local drawnTop = boxTopOf(deckDrawn.uoy, DECK_S)
local reportedTop = boxTopOf(deckPayload.gameY, deckPayload.gameWidth / Display.W)
ok(drawnTop ~= reportedTop, "the drawn box and the reported box are not the same place")
near(drawnTop - reportedTop, 8, "on this viewport they are 8 window px apart", 0.001)
near((drawnTop - reportedTop) / DECK_S, 6, "which is 6 game px", 0.001)

-- The same box, drawn twice: once with the renderer's rect available and once
-- without.  The gap is measured against the box that was really DRAWN in both
-- cases, because that is the only box the player can see.
local drawnPanel = marginDraw("left", deckPayload, nil, nil, deckDrawn)
local payloadPanel = marginDraw("left", deckPayload)

ok(drawnPanel ~= nil, "a panel is drawn when the renderer answers")
ok(payloadPanel ~= nil, "and when it does not")

local drawnGap = drawnTop - (drawnPanel and (drawnPanel.y + drawnPanel.h) or 0)
local payloadGap = drawnTop - (payloadPanel and (payloadPanel.y + payloadPanel.h) or 0)

-- THE ASSERTION THE REPORT IS ABOUT.  With the renderer's rect the panel clears
-- the real box by the BOX GAP -- MARGIN_BOX_GAP game px, which is what the
-- previous release's fix was for and what it could not deliver on a phone.
near(drawnGap, X.MARGIN_BOX_GAP * DECK_S,
  "with the drawn rect the panel clears the REAL box by the box gap", 1)
near(drawnGap / DECK_S, X.MARGIN_BOX_GAP,
  "which is MARGIN_BOX_GAP game px, measured on the box the player sees", 0.5)

-- And the regression, stated as a number rather than as a shape: measured
-- against the box it was TOLD about, the same panel sits 6 game px further from
-- the box that is actually on screen.  That is the "vertical gap is too big"
-- report, and it is why raising the gap could never have fixed it.
ok(payloadGap > drawnGap,
  "measured against the reported box instead, the panel sits further away")
near(payloadGap - drawnGap, 8, "by exactly the distance between the two rects", 1)

-- The unit comes from the drawn rect too, not only the origin.  A skin whose
-- cutout is short enough makes the HEIGHT the binding axis, so the renderer's
-- scale is smaller than the payload's -- and then the panel is the wrong SIZE as
-- well as in the wrong place.  Both are fixed by asking the renderer.
local tightDrawn = { uox = 46.666666666667, uoy = 16.333333333333,
                     uvpw = Display.W * 10 / 9, uvph = Display.H * 10 / 9 }
local TIGHT_S = tightDrawn.uvpw / Display.W
ok(TIGHT_S ~= DECK_S, "a shorter cutout gives the renderer a different scale")
ok(TIGHT_S ~= deckPayload.gameWidth / Display.W,
  "which the payload does not know about")

local tightPanel = marginDraw("left", deckPayload, nil, nil, tightDrawn)
ok(tightPanel ~= nil, "so the panel is drawn at the renderer's scale, not the payload's")
eq(tightPanel and tightPanel.w, MARGIN_PLAN.w * TIGHT_S,
  "which is the engine's window in the renderer's window units")
ok(tightPanel and tightPanel.w ~= MARGIN_PLAN.w * DECK_S,
  "and NOT the width the payload's scale would have given it")
-- The clearance is asserted as the invariant BOTH branches keep, rather than
-- against the branch this viewport happened to take.  The window is 48px now, so
-- panelW + 2 * pad is 62.2 units against a 46.7-unit margin -- too wide to use,
-- where the 32px panel of 1.8.0 made it 44.4 and this cutout was just wide
-- enough.  So this viewport falls through to standing ABOVE the box, and the
-- invariant it keeps is the horizontal one: MARGIN_PAD in from the play area's
-- own edge.  Pinning the letterbox branch here would be asserting a number
-- rather than the rule, and the rule is what the clearance is for.
local tightLeftEdge = tightPanel and tightPanel.x or 0
near(tightLeftEdge, tightDrawn.uox + X.MARGIN_PAD * TIGHT_S,
  "and it stands MARGIN_PAD in from the play area's own edge", 1)
ok(tightLeftEdge > tightDrawn.uox,
  "so it clears the play area rather than touching it")
ok(tightPanel and (tightPanel.y + tightPanel.h) < tightDrawn.uoy + BOX_TOP * TIGHT_S,
  "and it stands above the box, the margin being too narrow to use")

-- ------- a crop with room to spare is zoomed by a WHOLE number
--
-- The other half of the release, and the half the 1.6.0 frame could not express
-- at all.  Because the window is a FIXED size and the art is fitted INTO it, a
-- small crop is not stretched across the window: it is zoomed by the largest
-- whole number that still fits the content, so it keeps its own proportions and
-- only the art inside the window grows.
--
-- 1.6.0's panelPlan had no such rule.  It scaled the art to FILL the 46px
-- window, so a 16px crop came out at 2.875x and a 30px crop at 1.533x -- a small
-- crop and a large one were the same size on screen, and neither was a whole
-- multiple of its source.
--
-- The crop is reachable: art/crops.lua keys its overrides by FRONT-PIC id, so a
-- 16px window on picture 17 is a supported thing to ask for.
io.write("-- a crop with room to spare is zoomed by a whole number\n")

-- 16 * 2 = 32 fills the 32px content exactly; 16 * 3 = 48 does not.  So the zoom
-- is 2, the art is 32 game px -- 96 in this 3x window -- and the window around it
-- is still the engine's 48, where 1.6.0 would have stretched the art 2.875x to
-- fill a 46px one.
local ZOOM_PLAN = X.panelPlan({ w = 16, h = 16 })
eq(ZOOM_PLAN.zoom, 2, "a 16px crop is zoomed 2x, because 3x would overrun the content")
eq(ZOOM_PLAN.w, X.PANEL_MAX_TW * T,
  "so its window is the engine's own 48px, whatever the crop")
eq(ZOOM_PLAN.h, ZOOM_PLAN.w, "square, because the window is")
eq(ZOOM_PLAN.ox, 0, "and the crop at 2x fills the content, so nothing is centred")

-- Picture 58 belongs to nothing else in this file, and its rectangle { 8, 8, 16 }
-- is filed under no earlier cut, so the mod's crop cache cannot answer this from
-- an earlier one.  The cache slot is the RECTANGLE, not the picture: a cut is
-- only ever reused by a speaker whose rectangle matches it exactly, which is what
-- lets two speakers of one picture be framed differently.
X.crops.trainers["58"] = { 8, 8, 16 }
local zoomPanel, zoomArt = marginDraw("left", plain,
  { trainerType = 32, sprite = "SPRITE_COOLTRAINER" }, ZOOM_PLAN)
X.crops.trainers["58"] = nil
ok(zoomPanel ~= nil, "and that is the panel the draw call really gets")
eq(zoomPanel and zoomPanel.w, ZOOM_PLAN.w * 3, "at the window scale")
eq(zoomArt and zoomArt.scale, ZOOM_PLAN.zoom * 3,
  "with the art at the same whole-number zoom, so it keeps its proportions")
eq(zoomArt and (zoomArt.x - (zoomPanel and zoomPanel.x or 0)),
  (X.PANEL_BORDER_TW * T + ZOOM_PLAN.ox) * 3,
  "and the border, with the centring adding nothing, clear of the panel's corner")
eq(zoomPanel and (zoomPanel.w - 2 * X.PANEL_BORDER_TW * T * 3), zoomArt and zoomArt.w,
  "the window less its two borders being exactly the zoomed art, which fills it")
-- The ART must be the zoomed crop, or this section is measuring a 1x snap and
-- would pass with the zoom rule deleted.  The windows do not differ -- they
-- never do now -- so the art is the only thing left to check.
--
-- It can no longer be "bigger than the default crop's": the default crop IS the
-- content rect now, so the 16px crop at 2x fills it to the same 32px and the two
-- arts are the same size on screen.  What says the zoom ran is the SIZE OF THE
-- SOURCE it came from: 16px twice over, not 16px once.
ok(zoomArt and (zoomArt.w == 16 * ZOOM_PLAN.zoom * 3),
  "which is the 16px crop at its own whole-number zoom, so the zoom really ran")
eq(zoomArt and zoomArt.w, DEFAULT_ART * 3,
  "and it fills the window exactly as the default crop does")
eq(zoomPanel and zoomPanel.w, MP_W,
  "even though the window around it is the same size as the default crop's")

-- A crop with no room for a second multiple stays at 1x rather than shrinking.
eq(MARGIN_PLAN.zoom, 1, "the default 30px crop has no room for a second multiple")
eq(MARGIN_PLAN.artW, DEFAULT_ART,
  "so its art is the crop's own 30px, not stretched to fill the window")

-- ------- a widescreen window puts the panel in the letterbox
--
-- 1280x480: the play area is 720 wide and centred, so there are 280px of margin
-- on each side -- more than the 96px the panel needs.  The panel uses it, and
-- is bottom-aligned with the play area so it sits LEVEL WITH THE BOX rather than
-- floating at the frame's vertical centre.
io.write("-- a widescreen window puts the panel in the letterbox\n")

local wide = {
  width = 1280, height = 480, gameX = 280, gameY = 0,
  gameWidth = 720, gameHeight = 480, scale = 3,
}
local wLeft = marginDraw("left", wide)
ok(wLeft ~= nil, "the letterbox gets the panel")
ok(wLeft and wLeft.x < 280, "on the left it is out in the margin")
eq(wLeft and (wLeft.x + wLeft.w / 2), 140, "centred in it")
eq(wLeft and (wLeft.y + wLeft.h), 480 - X.MARGIN_PAD * 3,
  "and bottom-aligned with the play area, so it sits level with the box")

local wRight = marginDraw("right", wide)
ok(wRight and wRight.x >= 1000, "on the right it is clear of the play area")
eq(wRight and (wRight.x + wRight.w / 2), 1000 + 140, "and centred in the right margin")

-- ------- the clearance is what decides whether the letterbox is worth using
--
-- The half of this release that is easy to miss, because it is a change to the
-- CONDITION rather than to a coordinate.  The branch used to ask only whether the
-- margin could FIT the panel -- panelW + 2 * 2 -- which allowed a panel sitting
-- 2 game px from the edge of the screen.  That is the same fault as being flush,
-- one pixel further in.  It now asks for room for the clearance on BOTH sides,
-- so a margin that is only just wide enough falls through to standing above the
-- box, where the no-letterbox inset applies instead.
io.write("-- the clearance decides whether the letterbox is worth using\n")

-- A 96px panel plus 2 * 12px of clearance wants 120px of margin; this has 116.
local tight = {
  width = 1280, height = 480, gameX = 116, gameY = 0,
  gameWidth = 720, gameHeight = 480, scale = 3,
}
local tLeft = marginDraw("left", tight)
ok(tLeft ~= nil, "a margin too narrow for the clearance still gets a panel")
eq(tLeft and (tLeft.x - tight.gameX), X.MARGIN_PAD * 3,
  "and it stands MARGIN_PAD in from the play area's own edge, above the box")
ok(tLeft and (tLeft.y + tLeft.h) < 336,
  "rather than out in the margin it is not wide enough to use")

-- Exactly wide enough, and the letterbox is worth using again -- because the
-- CENTRED panel it draws is now clearance-clear of the screen's edge on the
-- outside and of the play area on the inside.  Asserting the boundary itself,
-- not just the two sides of it, is what makes this a test of the condition.
--
-- The fixture is DERIVED from the panel and the clearance rather than typed, so
-- it stays the exact boundary when either moves: a typed 144 was the boundary
-- for a 24px clearance and would silently have stopped being one.
local roomyGameX = MARGIN_PLAN.w * 3 + 2 * X.MARGIN_PAD * 3
local roomy = { width = 1280, height = 480, gameX = roomyGameX, gameY = 0,
  gameWidth = 720, gameHeight = 480, scale = 3 }
local rLeft = marginDraw("left", roomy)
ok(rLeft and rLeft.x < roomy.gameX, "at panelW + 2 * clearance it uses the margin")
eq(rLeft and rLeft.x, X.MARGIN_PAD * 3,
  "and even then the panel is exactly clearance-clear of the screen's own edge")

-- ------- and it never goes off the top of the frame
--
-- A guard the cart's own geometry never reaches: the box lives in the bottom
-- fifth, so the run above it is always more than the four rows the panel needs.
-- Moving the box up is the only way to reach the branch, and reaching it is the
-- point -- a portrait drawn off the top of the frame is worse than one that
-- overlaps a border.
io.write("-- MARGIN never goes off the top of the frame\n")
local realTop = Chrome.DLG_TOP
Chrome.DLG_TOP = 2
local clamped = marginDraw("left", plain)
Chrome.DLG_TOP = realTop
ok(clamped ~= nil, "with the box at the top of the frame the panel still draws")
eq(clamped and clamped.y, 0, "and it is pushed down to the frame's own top edge")
eq(Chrome.DLG_TOP, 15, "and the box's row is put back")

-- ------- a Pokemon on the left faces its own dialogue
--
-- A species front pic is drawn facing LEFT, which is the right way round on the
-- right -- the creature looks in towards the words -- so art on the LEFT has to
-- be turned back the other way.  Trainer pics are busts and are never flipped.
io.write("-- a Pokemon on the left faces its own dialogue\n")
local mon = { sprite = "SPRITE_PIKACHU" }
local _, monLeft = marginDraw("left", plain, mon)
ok(monLeft ~= nil, "a talking Pokemon gets a portrait")
ok(monLeft and monLeft.flip, "and on the LEFT it is mirrored, so it faces the words")
local _, monRight = marginDraw("right", plain, mon)
ok(monRight and not monRight.flip, "while on the RIGHT it is left alone")
local _, trainerLeft = marginDraw("left", plain)
ok(trainerLeft and not trainerLeft.flip, "and a trainer bust is never mirrored")

-- ------- the crop table
io.write("-- the crop table\n")
local CROPS = X.crops
ok(type(CROPS) == "table", "art/crops.lua loaded")
ok(type(CROPS.defaults) == "table", "it carries a default framing rule")
ok(type(CROPS.defaults.trainers) == "table", "there is a trainer default")
ok(type(CROPS.defaults.pokemon) == "table", "there is a species default")

local dflt = X.rectFor("trainers", "17")
ok(dflt ~= nil, "a picture with no entry of its own gets the default")
eq(dflt.size, CROPS.defaults.trainers[3], "and the default's size is what it uses")

-- an override wins over the default
CROPS.trainers["17"] = { 1, 2, 3 }
local over = X.rectFor("trainers", "17")
eq(over.x, 1, "an explicit rectangle wins over the default")
eq(over.y, 2, "and carries its own y")
eq(over.size, 3, "and its own size")
CROPS.trainers["17"] = nil
eq(X.rectFor("trainers", "17").size, CROPS.defaults.trainers[3], "and removing it falls back")

eq(X.rectFor("nonsense", "x"), nil, "an unknown kind has no rectangle")

-- ------- the exceptions, and the two key spaces they can be filed under
--
-- This has to be asserted from the mod's side, because the failure it guards
-- against is silent: a crop table that loads, is read by nothing and leaves
-- every portrait on the default rule looks EXACTLY like one with the right
-- numbers in it.  The picture tables were reachable before this release and
-- `speakers` is new, so "it loaded" is not the question -- "the mod obeys it"
-- is.
--
-- The SHIPPED entry is asserted as shipped, because it is the one a player
-- sees.  The mechanism is asserted with temporary entries, because the shipped
-- table is deliberately nearly empty and a test that needed an entry to exist
-- in order to exercise the code would stop testing it the moment the table
-- changed.
--
-- In a function of its own for the same reason the rest of the file's helpers
-- are: this chunk is compiled as ONE Lua function and LuaJIT caps that at 200
-- locals, which the suite is already close to.  A block would not help -- the
-- count is every local the function ever declares, not the ones live at once.
local function cropExceptionTests()
  io.write("-- the crop table's exceptions\n")

  ok(type(CROPS.speakers) == "table",
    "art/crops.lua carries the per-speaker override table")

  -- THE RESIZE, as arithmetic -- bug 2, pinned.
  --
  -- Growing the window one pixel on EVERY side is what removes the margin
  -- between the portrait and its frame.  Growing it any other way would have
  -- re-framed every portrait in the mod, which this release must not do, so the
  -- CENTRE is what says which of the two happened: 1.8.3 shipped (17,4,30) and
  -- (17,18,30), and both are still the centre of a 32px window that fills the
  -- slot exactly.  A default that had been re-aimed instead would fail this and
  -- nothing else in the file.
  eq(CROPS.defaults.trainers[1] * 2 + CROPS.defaults.trainers[3], 64,
    "the trainer default is centred on x -- as 1.8.3's 30px window was")
  eq(CROPS.defaults.trainers[2] * 2 + CROPS.defaults.trainers[3], 38,
    "and sits on 1.8.3's own centre line of 19, not a re-aimed one")
  eq(CROPS.defaults.pokemon[1] * 2 + CROPS.defaults.pokemon[3], 64,
    "the species default grew around its centre on x the same way")
  eq(CROPS.defaults.pokemon[2] * 2 + CROPS.defaults.pokemon[3], 66,
    "and around 33 on y, which is where 1.8.3 had it too")
  eq(CROPS.defaults.trainers[3], X.INSET_ART,
    "and the crop is the slot's own size, which is what edge to edge means")
  eq(CROPS.defaults.pokemon[3], X.PANEL_CONTENT_TW * T,
    "of the FRAMED/MARGIN window as well -- the content rect, minus its border")

  -- 1.9.2 retires three pictures and adds two, and the Fisherman is the picture
  -- that explains why.
  --
  -- 1.9.1 filed picture 38 for the Fisherman NPC, because that is the picture the
  -- NPC resolved to.  It is also the HOENN fisherman: the cart spells
  -- "FISHERMAN" twice, class 31 (Hoenn, picture 38) and class 69 (Kanto, picture
  -- 94), and the old class-name tie-break took the LOWER id.  With that
  -- corrected the NPC wears 94, whose default frames it at 58% with the head
  -- inside, so 38 has no entry any more -- and nothing reaches it to need one.
  eq(CROPS.trainers["38"], nil,
    "picture 38 -- the HOENN fisherman -- is retired, and nothing reaches it")
  eq(CROPS.trainers["36"], nil,
    "as is picture 36, the Hoenn youngster the name YOUNGSTER used to mean")
  eq(CROPS.trainers["65"], nil,
    "and picture 65, the Hoenn Lass the girl on Route 3 used to wear")
  local kantoFish = X.rectFor("trainers", "94")
  eq(kantoFish.x, CROPS.defaults.trainers[1],
    "while picture 94 -- what every fisherman wears now -- sits on the default")
  eq(kantoFish.y, CROPS.defaults.trainers[2], "on both axes")
  eq(kantoFish.size, CROPS.defaults.trainers[3], "and at the default size")

  -- the two pictures 1.9.2 newly routes to that the default framed badly.  Both
  -- are the same shape of bug as the Fisherman was -- a window off the head --
  -- and both are asserted as shipped, because these are numbers a player sees.
  local sailor = X.rectFor("trainers", "85")
  ok(sailor ~= nil, "picture 85 -- the Sailor -- has an entry of its own")
  eq(sailor.x, 12, "centred on a head the default clipped nine pixels off the left of")
  eq(sailor.y, 0, "and raised to the top, because his cap starts at row 1")
  eq(sailor.size, CROPS.defaults.trainers[3], "at the default size")

  local belt = X.rectFor("trainers", "105")
  ok(belt ~= nil, "picture 105 -- the Black Belt -- has an entry of its own")
  eq(belt.x, 11, "centring a head 37 pixels wide that no 32px window can hold")
  eq(belt.y, 1, "and taking nothing off the top of it")
  eq(belt.size, CROPS.defaults.trainers[3], "at the default size")

  -- and the six pictures 1.9.2 newly routes to that the default frames correctly
  -- need NO entry.  Asserted rather than left implicit, for the same reason the
  -- old man's is: an entry added later "for symmetry" would be a window with no
  -- evidence behind it.
  eq(CROPS.trainers["84"], nil,
    "picture 84 -- the Kanto Lass, and the girl on Route 3 -- needs no entry")
  eq(CROPS.trainers["94"], nil, "nor does picture 94, the Kanto Fisherman")
  eq(CROPS.trainers["98"], nil, "nor picture 98, the Beauty")
  eq(CROPS.trainers["123"], nil, "nor picture 123, the Gentleman")
  eq(CROPS.trainers["110"], nil, "nor picture 110, the Kanto Cooltrainer")

  -- 1.9.1's three new entries.  Each is a picture the mod had never routed to
  -- before -- the mappings that put them there are asserted in the speaker
  -- suite -- and each measured as empty at the default as the Fisherman was:
  -- the male Tuber 20%, the old woman 21%, the Camper 37%.  Asserted as shipped,
  -- for the same reason the Fisherman is: these are numbers a player sees.
  --
  -- The report these come from is the same one the Fisherman's entry answers,
  -- and the two are worth keeping side by side, because a mapping that is
  -- missing and a WINDOW aimed at empty space look identical on screen.  Routing
  -- three new pictures without these rectangles would have re-created the bug
  -- this release is about, three times over.
  local e = X.rectFor("trainers", "7")
  ok(e ~= nil, "picture 7 -- the MALE tuber -- has an entry of its own")
  eq(e.x, 17, "centred on the head the default left floating in an empty window")
  eq(e.y, 16, "eighteen rows below the default's own top edge")
  eq(e.size, CROPS.defaults.trainers[3], "at the default size")

  e = X.rectFor("trainers", "35")
  ok(e ~= nil, "picture 35 -- the old woman -- has an entry of its own")
  eq(e.x, 13, "because she is drawn SEATED, low in her square")
  eq(e.y, 18, "so the default window sat almost entirely above her")

  e = X.rectFor("trainers", "86")
  ok(e ~= nil, "picture 86 -- the Camper -- has an entry of its own")
  eq(e.x, 11, "because the default clips the left of his head")
  eq(e.y, 10, "and leaves him below its top edge")

  -- The old MAN deliberately has none, and so does the Picnicker: their
  -- defaults frame them correctly (58% and 48%).  Asserted rather than left
  -- implicit, because the pair is asymmetric ON PURPOSE and the asymmetry is
  -- the measurement -- an entry added later "for symmetry" would be a window
  -- with no evidence behind it.
  eq(CROPS.trainers["34"], nil, "picture 34 -- the old man -- needs no entry")
  eq(CROPS.trainers["87"], nil, "nor does picture 87, the Picnicker")

  -- The rest of the shipped table, checked for SHAPE rather than restated: every
  -- entry is a legal window inside the 64x64 source, and every entry is the
  -- default SIZE, which is the invariant that keeps a hand-tuned crop from
  -- costing some speakers more of the box than others.
  local FILED_TRAINERS = { "7", "35", "82", "83", "85", "86", "95", "105",
                           "140" }
  local trainersLegal, trainersSized = true, true
  for _, id in ipairs(FILED_TRAINERS) do
    local r = X.rectFor("trainers", id)
    if not r or r.x < 0 or r.y < 0 or r.x + r.size > 64 or r.y + r.size > 64 then
      trainersLegal = false
    end
    if not r or r.size ~= CROPS.defaults.trainers[3] then trainersSized = false end
  end
  ok(trainersLegal,
    "every filed trainer picture is a window that fits inside its 64x64 source")
  ok(trainersSized, "and every one of them is the default size")

  -- A Pokemon portrait is the one the report says is NOT displayed, and it has
  -- TWO causes, one per release:
  --
  --   * 1.9.0/1.9.1: the default window frames a creature's CHEST (rows 17-48 of
  --     a 64px sprite), while 15 of the 19 species that SPEAK have artwork
  --     starting ABOVE row 17 -- PIKACHU's ears at row 6, PIDGEOT's beak at 2,
  --     FEAROW's at 0 -- so the top of the head was cut off;
  --   * 1.9.2: the Pokemon that STAND IN THE WORLD resolved to NO portrait at
  --     all (main.lua's GFX_MON), so there was nothing to frame in the first
  --     place.  "Some Pokemon, such as Spearow, do not display a portrait at
  --     all" is this one.
  --
  -- All 19 speakers are filed, and 18 of them ABOVE the default row.  The
  -- exception is FEAROW, and it is the rule working rather than failing: its
  -- head is at the BOTTOM LEFT of a wing-dominant sprite, so its window has to
  -- go DOWN to reach the face.  1.9.3 measured that; before it, Fearow's entry
  -- sat above the default like the rest and framed nothing but a wing.
  --
  -- The species the world places are filed too -- 31 of the 32, VOLTORB taking
  -- the default -- but NOT all above the default row: a Lugia's face is two thirds of
  -- the way down its sprite, and its entry is BELOW the default.  So those are
  -- checked for the invariant that does hold everywhere: a filed entry moves the
  -- window off the default on at least one axis.
  local SPEAKS = { "chansey", "clefairy", "cubone", "doduo", "fearow",
    "jigglypuff", "machoke", "machop", "meowth", "nidoranf", "nidoranm",
    "nidorino", "pidgeot", "pidgey", "pikachu", "poliwrath", "psyduck",
    "seel", "wigglytuff" }
  local filed, speciesLegal, speciesSized = 0, true, true
  for _, key in ipairs(SPEAKS) do
    local r = X.rectFor("pokemon", key)
    if r and (r.x ~= CROPS.defaults.pokemon[1]
              or r.y ~= CROPS.defaults.pokemon[2]) then filed = filed + 1 end
    if not r or r.x < 0 or r.y < 0 or r.x + r.size > 64 or r.y + r.size > 64 then
      speciesLegal = false
    end
    if not r or r.size ~= CROPS.defaults.pokemon[3] then speciesSized = false end
  end
  eq(filed, #SPEAKS,
    "all 19 species that speak are filed, each moving the window off the default")
  ok(speciesLegal, "and every one is a window inside its 64x64 source")
  ok(speciesSized, "at the default size, so none of them costs the text more")

  local fearow = X.rectFor("pokemon", "fearow")
  ok(fearow.y > CROPS.defaults.pokemon[2],
    "FEAROW is filed BELOW the default row, because its head is at its bottom left")
  eq(fearow.x, 0, "and pushed to the left edge, where the head and beak are")

  -- the Pokemon the WORLD places, which 1.9.2 made reachable.  Spearow is the
  -- reported case and is asserted by number; the rest by the invariant.
  local PLACED = { "snorlax", "spearow", "cubone", "poliwrath", "clefairy",
    "pidgeot", "jigglypuff", "pidgey", "chansey", "kangaskhan", "pikachu",
    "psyduck", "nidoranf", "nidoranm", "nidorino", "meowth", "seel",
    "voltorb", "slowpoke", "slowbro", "machop", "wigglytuff", "doduo",
    "fearow", "machoke", "lapras", "zapdos", "moltres", "articuno", "mewtwo",
    "lugia", "hooh" }
  local moved, placedLegal, placedSized = 0, true, true
  for _, key in ipairs(PLACED) do
    local r = X.rectFor("pokemon", key)
    if r and (r.x ~= CROPS.defaults.pokemon[1]
              or r.y ~= CROPS.defaults.pokemon[2]) then
      moved = moved + 1
    end
    if not r or r.x < 0 or r.y < 0 or r.x + r.size > 64 or r.y + r.size > 64 then
      placedLegal = false
    end
    if not r or r.size ~= CROPS.defaults.pokemon[3] then placedSized = false end
  end
  eq(moved, #PLACED - 1,
    "all but one of the 32 species the world places move the window off the default")
  eq(CROPS.pokemon["voltorb"], nil,
    "and VOLTORB is the one that does not -- the default already frames it")
  ok(placedLegal, "every one of the 31 is a window inside its 64x64 source")
  ok(placedSized, "at the default size")

  local spearow = X.rectFor("pokemon", "spearow")
  eq(spearow.x, 16, "SPEAROW -- the reported case -- is centred on its own box")
  eq(spearow.y, 12, "three rows above a beak that starts at row 15")
  eq(spearow.size, CROPS.defaults.pokemon[3], "at the default size")

  -- the four whose box is not their head.  Each is asserted, because each is a
  -- deliberate departure from the rule the comment above states.
  local lugia = X.rectFor("pokemon", "lugia")
  ok(lugia.y > CROPS.defaults.pokemon[2],
    "LUGIA is filed BELOW the default row, because its face is low in its sprite")
  local hooh = X.rectFor("pokemon", "hooh")
  ok(hooh.y > CROPS.defaults.pokemon[2], "and so is HO-OH, for the same reason")
  local slowpoke = X.rectFor("pokemon", "slowpoke")
  eq(slowpoke.x, 8, "SLOWPOKE is centred on its head, not on a box whose top is its TAIL")
  local snorlax = X.rectFor("pokemon", "snorlax")
  ok(snorlax.x > CROPS.defaults.pokemon[1],
    "and SNORLAX is pushed right, because its head is tucked into its right end")

  -- ------- 1.9.3: the seven whose BOX is not their FACE
  --
  -- Each is asserted by number, because each is a departure from "centre the
  -- creature's own box" and the departure is the whole point.  The four birds
  -- and the two side-on quadrupeds put their head at an EDGE of the sprite --
  -- left, bottom-left or top-left -- so a window centred on the box lands on a
  -- wing or on the far side of the creature.  Before 1.9.3 every one of these
  -- either cut the face or, in Fearow's case, held no face at all.
  local REFRAMED = {
    -- key,        x,  y,  why
    { "fearow",    0, 20, "head at the BOTTOM left; the old {32,0} was a wing" },
    { "pidgeot",   0,  3, "head at the LEFT; the old {15,0} cut the eye off" },
    { "nidorino", 11, 14, "the box centre is between the ears, above the muzzle" },
    { "slowbro",   4,  7, "the box includes the Shellder on its tail" },
    { "zapdos",    0,  6, "head and beak at the LEFT of a wing-dominant box" },
    { "moltres",   0, 30, "head and beak at the BOTTOM left" },
    { "articuno",  1,  0, "head at the top LEFT; the old {17,0} left the eye at the edge" },
    -- 1.9.5 (corrected): SEEL, the reported "not framed correctly".  The engine
    -- shows a species its own front pic -- Pokemon.frontPic(record.index) -- and
    -- SEEL's internal species id is 86, so the picture is mon-86.  That sprite is
    -- drawn FRONT-ON with the face LOW: whole creature bbox (6,9)-(53,54), muzzle
    -- (18,42)-(34,51), tongue (20,47)-(27,52).  The rule's own answer is
    -- {13,5,32}, and the first cut of this entry was measured on mon-87 --
    -- DEWGONG, head at the top left -- so {4,4,32} framed a top lobe.  Both left
    -- the whole face outside the window.  The sprite is 44 rows tall and 32
    -- cannot hold it, so the FACE wins: {12,21,32} holds the eyes, the whole
    -- muzzle and the whole tongue.
    { "seel",     12, 21, "the face is LOW; the old {4,4} framed a top lobe" },
  }
  for _, case in ipairs(REFRAMED) do
    local r = X.rectFor("pokemon", case[1])
    eq(r.x, case[2], case[1]:upper() .. " -- " .. case[4])
    eq(r.y, case[3], "  and the row the face is actually on")
  end
  -- the trainer the same sweep turned up: the Hoenn Bug Catcher, picture 66,
  -- which only the CLASS route reaches because the NAME "BUG CATCHER" means
  -- class 58 and picture 83.  It is asserted through `rectFor` so the picture
  -- key is what is being pinned, not the table's own shape.
  local bug66 = X.rectFor("trainers", "66")
  eq(bug66.x, 10, "the HOENN BUG CATCHER -- picture 66 -- is centred on his face")
  eq(bug66.y, 9, "three rows above a hat that starts at row 12")
  eq(bug66.size, CROPS.defaults.trainers[3], "at the trainer default size")

  -- the speaker keys: each one is consulted, and each beats the picture key.
  -- Filed against picture 105, which is a picture that HAS an entry.
  local cases = {
    { "name:",   { name = "BLACK BELT" },          "name:BLACK BELT" },
    { "gfx:",    { gfx = 54 },                     "gfx:54" },
    { "sprite:", { sprite = "SPRITE_BLACK_BELT" }, "sprite:SPRITE_BLACK_BELT" },
    { "class:",  { class = 80 },                   "class:80" },
  }
  for _, case in ipairs(cases) do
    CROPS.speakers[case[3]] = { 9, 9, 9 }
    local got = X.rectFor("trainers", "105", case[2])
    ok(got and got.x == 9 and got.y == 9 and got.size == 9,
      case[1] .. " a rectangle filed against the SPEAKER beats the picture's")
    CROPS.speakers[case[3]] = nil
  end

  -- and the order between them, most specific first -- the same order artFor
  -- resolves a speaker in, so "the most specific fact wins" is one rule, not two
  CROPS.speakers["class:80"] = { 1, 1, 1 }
  CROPS.speakers["sprite:SPRITE_BLACK_BELT"] = { 2, 2, 2 }
  CROPS.speakers["gfx:54"] = { 3, 3, 3 }
  CROPS.speakers["name:BLACK BELT"] = { 4, 4, 4 }
  local allKeys = { name = "BLACK BELT", gfx = 54,
                    sprite = "SPRITE_BLACK_BELT", class = 80 }
  eq(X.rectFor("trainers", "105", allKeys).x, 4, "the name the text used outranks the rest")
  CROPS.speakers["name:BLACK BELT"] = nil
  eq(X.rectFor("trainers", "105", allKeys).x, 3, "then the cart's own graphics id")
  CROPS.speakers["gfx:54"] = nil
  eq(X.rectFor("trainers", "105", allKeys).x, 2, "then the host sprite id")
  CROPS.speakers["sprite:SPRITE_BLACK_BELT"] = nil
  eq(X.rectFor("trainers", "105", allKeys).x, 1, "then the class")
  CROPS.speakers["class:80"] = nil
  eq(X.rectFor("trainers", "105", allKeys).x, X.crops.trainers["105"][1],
    "and with none of them filed, the picture key answers")

  -- a speaker key that is not filed falls through rather than failing
  local unfiled = X.rectFor("trainers", "17", { sprite = "SPRITE_LASS" })
  eq(unfiled.x, CROPS.defaults.trainers[1], "an unfiled speaker key falls through to the rule")
  eq(unfiled.size, CROPS.defaults.trainers[3], "at the rule's own size")

  -- a malformed entry is ignored rather than trusted: a table with two numbers
  -- in it would otherwise become a crop with a nil size, which cutPortrait
  -- clamps to a one-pixel window -- a portrait that is drawn and invisible
  CROPS.speakers["sprite:SPRITE_LASS"] = "not a rectangle"
  eq(X.rectFor("trainers", "17", { sprite = "SPRITE_LASS" }).size,
    CROPS.defaults.trainers[3], "a non-table override is ignored, not obeyed")
  CROPS.speakers["sprite:SPRITE_LASS"] = { 1, 2 }
  eq(X.rectFor("trainers", "17", { sprite = "SPRITE_LASS" }).size,
    CROPS.defaults.trainers[3], "and so is one without three numbers")
  CROPS.speakers["sprite:SPRITE_LASS"] = nil

  -- a Pokemon needs no speaker key: its species key IS its identity, which is
  -- why `pokemon` was always an interaction table and only the NPC side needed
  -- a new one
  local asSpecies = X.rectFor("pokemon", "pikachu", { species = "PIKACHU" })
  eq(asSpecies.y, 2, "a filed species key names the speaker itself")
  ok(asSpecies.y < CROPS.defaults.pokemon[2],
    "and sits ABOVE the default window, where a Pikachu's face is")
  eq(asSpecies.size, CROPS.defaults.pokemon[3],
    "at the default size, so the entry costs the text nothing")
  local noEntry = X.rectFor("pokemon", "rattata", { species = "RATTATA" })
  eq(noEntry.y, CROPS.defaults.pokemon[2],
    "and a species with nothing filed falls back to the rule on both axes")
  eq(noEntry.x, CROPS.defaults.pokemon[1], "on x too")

  -- and the exception reaches the CUT, not just the lookup.  The rectangle is
  -- one thing and the quad the blit draws is another, and the cache sits
  -- between them: a cache keyed on the PICTURE alone would hand the second
  -- speaker of a picture the first speaker's cut, so a speaker override filed
  -- against a picture already cut would be silently ignored -- and the
  -- assertions above would pass while the portrait stayed wrong.  That is the
  -- exact shape of bug this release exists to fix, so it gets its own check.
  io.write("-- the exception reaches the cut\n")
  local sharedA = X.portraitFor({ class = 17, sprite = "SPRITE_HIKER" })
  eq(sharedA and sharedA.quad and sharedA.quad.x, CROPS.defaults.trainers[1],
    "a picture with nothing filed against it is cut at the default window")
  CROPS.speakers["sprite:SPRITE_HIKER"] = { 5, 6, 7 }
  local sharedB = X.portraitFor({ class = 17, sprite = "SPRITE_HIKER" })
  eq(sharedB and sharedB.quad and sharedB.quad.x, 5,
    "and the SAME picture, filed against by its speaker, is cut at the override")
  CROPS.speakers["sprite:SPRITE_HIKER"] = nil
  local sharedC = X.portraitFor({ class = 17, sprite = "SPRITE_HIKER" })
  eq(sharedC and sharedC.quad and sharedC.quad.x, CROPS.defaults.trainers[1],
    "and removing it goes back to the default rather than the stale override")
end
cropExceptionTests()

-- ------- the pictures the cart drew TWO people into
--
-- Five of the cart's front pics hold a pair: a Young Couple, a Cool Couple, a
-- Crush Kin, a Sis and Bro, and the Twins.  A rectangle frames the PICTURE, so
-- one rectangle for picture 129 cannot be right for both members of a couple --
-- it frames the seam between them.  So a pair is described by two tables
-- instead: `pairs` holds a rectangle per half keyed by the picture, and
-- `pairSide` says which half a graphic stands on.  rectFor asks them FIRST.
--
-- Two things make this safe, and both are asserted below rather than assumed:
-- the halves are keyed by picture AND graphic together (so an ordinary Beauty
-- wearing graphic 29 is not cut with half of a Young Couple), and a pair
-- rectangle has to be inside the 64x64 source, because a window that ran off
-- the edge would be clamped by the cut and would frame the wrong part.
--
-- Hung on XF rather than declared `local`, for the reason XF's own cur/push/pop
-- are: this file sits exactly on LuaJIT's 200-local ceiling for the main chunk,
-- so one more top-level `local` is one too many.  XF is the table that exists
-- for precisely this.
function XF.pairCropTests()
  io.write("-- the pictures the cart drew two people into\n")

  ok(type(CROPS.pairs) == "table", "art/crops.lua carries the pair rectangles")
  ok(type(CROPS.pairSide) == "table", "and the graphic -> half table")

  -- Every pair picture the cart actually places is described, and every
  -- rectangle is a 32px window that fits inside the 64x64 source.  The size is
  -- asserted as the source's own half rather than a literal, because a pair is
  -- by definition two people in one square picture.
  local PAIR_PICS = { "127", "128", "129", "130", "131" }
  local nHalves = 0
  for _, pic in ipairs(PAIR_PICS) do
    local halves = CROPS.pairs[pic]
    ok(type(halves) == "table", "picture " .. pic .. " is a pair")
    for side, rect in pairs(halves) do
      nHalves = nHalves + 1
      ok(side == "left" or side == "right",
        "picture " .. pic .. "'s halves are named left and right, not " .. tostring(side))
      ok(rect[1] + rect[3] <= 64 and rect[2] + rect[3] <= 64,
        "and picture " .. pic .. "'s " .. side .. " window stays inside the source")
    end
  end
  ok(nHalves >= 9, "nine halves across the five pairs the cart places")

  -- The nine windows by NUMBER.  A property test ("it fits in the source") does
  -- not catch a window that fits and still clips: picture 130's right half had
  -- its ponytail's red band cut by a y of 2 that was well inside the source.
  -- The numbers are re-measurable with .probe/dp3_pair_framing.py, which walks
  -- every window in this table and asks whether the artwork continues past its
  -- top edge -- the one edge a head window must never cross.
  local PINNED = {
    -- 127's left half is the OTHER exception, and the reason this table pins
    -- numbers at all: her head runs to column 33 and her sister's begins at 35,
    -- so the only 32px span holding all of her and none of her sister starts at
    -- 2.  At 0 -- which is where it started -- the window stopped at column 31
    -- and took two columns of her face with it.  A "does it fit in the source"
    -- test passes either way; only the number catches it.
    ["127"] = { left  = {  2, 10, 32 } },
    ["128"] = { left  = {  0,  2, 32 }, right = { 32,  2, 32 } },
    ["129"] = { left  = {  0,  4, 32 }, right = { 32,  2, 32 } },
    -- 130's right half is the other exception the probe found: her art reaches
    -- row 0, so her window does too.  Every other half has three or more rows
    -- of headroom and uses 2 or 3.
    ["130"] = { left  = {  0,  3, 32 }, right = { 32,  0, 32 } },
    -- 131 is the one pair whose halves do not share a y: the brother is drawn
    -- lower than his sister (art at y 19 against her y 2).
    ["131"] = { left  = {  0,  2, 32 }, right = { 32, 16, 32 } },
  }
  for _, pic in ipairs(PAIR_PICS) do
    for side, want in pairs(PINNED[pic]) do
      local got = CROPS.pairs[pic][side]
      ok(got ~= nil, "picture " .. pic .. " has a " .. side .. " half")
      eq(got[1], want[1], "picture " .. pic .. " " .. side .. " x")
      eq(got[2], want[2], "picture " .. pic .. " " .. side .. " y")
      eq(got[3], want[3], "picture " .. pic .. " " .. side .. " size")
    end
  end

  -- THE COUPLE, which is the reported case: two people, one picture, and the
  -- graphic is the only fact that says which one is standing there.
  local woman = X.rectFor("trainers", "129", { gfx = 29 })
  local man = X.rectFor("trainers", "129", { gfx = 25 })
  ok(woman and man, "both halves of picture 129 resolve")
  ok(woman.x ~= man.x, "to two DIFFERENT windows")
  eq(woman.x, CROPS.pairs["129"].left[1], "the woman's is the left one")
  eq(man.x, CROPS.pairs["129"].right[1], "and the man's the right one")
  eq(woman.size, man.size, "at one size, because the picture is one square")

  -- A graphic with no half recorded is not one of a pair's two people, so the
  -- picture is framed the ordinary way.  This is what keeps the halves out of
  -- `speakers`: graphic 29 is the woman in a Young Couple AND every ordinary
  -- Beauty, who wears picture 98 and is not half of anything.
  local plainBeauty = X.rectFor("trainers", "98", { gfx = 29 })
  local beautyNoGfx = X.rectFor("trainers", "98", {})
  eq(plainBeauty.x, beautyNoGfx.x,
    "an ordinary Beauty is not cut with half of picture 129")
  eq(plainBeauty.y, beautyNoGfx.y, "on either axis")

  -- And the converse: a graphic that IS recorded as a half, on a picture that
  -- is NOT a pair.  Graphic 41 is a Cool Couple's boy AND a plain Cooltrainer
  -- (picture 110) AND a Psychic (picture 100); neither of those two is in
  -- `pairs`, so neither is cut as a half.
  local plainTrainer = X.rectFor("trainers", "110", { gfx = 41 })
  local trainerNoGfx = X.rectFor("trainers", "110", {})
  eq(plainTrainer.x, trainerNoGfx.x,
    "and a plain Cooltrainer is not cut as half of picture 128")
  eq(plainTrainer.y, trainerNoGfx.y, "on either axis")

  -- A pair picture reached with no graphic at all -- a speaker the press never
  -- resolved -- falls back to the ordinary framing rather than guessing a half.
  -- The wrong half is a wrong portrait, which is the whole defect.
  local noGfx = X.rectFor("trainers", "129", {})
  eq(noGfx.x, CROPS.defaults.trainers[1],
    "a pair picture with no graphic falls back to the default window")
  eq(noGfx.y, CROPS.defaults.trainers[2], "on both axes")
end
XF.pairCropTests()

io.write(("\n%d checks, %d failures\n"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
