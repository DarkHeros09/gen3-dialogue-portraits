-- Speaker resolution -- who is talking, and which picture is theirs
--
-- This suite drives the mod's own exported resolvers over the shapes the real
-- game hands them.  It does NOT need a world: `speakerFor` takes the text a box
-- was opened with, and `artFor` takes the plain descriptor `speakerFor` builds,
-- so both can be asked directly.
--
-- What it pins, in the order the mod asks them:
--   1. the text's own "NAME: " prefix beats everything
--   2. a CustomArt/ file beats every ROM route
--   3. the object's own trainer row, reached from the script the object points
--      at -- the only EXACT route for a trainer, and the one that settles the
--      people a shared graphics id cannot tell apart
--   4. the object's numeric trainer class resolves through TrainerPic.front
--   5. a sprite id whose tail is a species resolves through the dex
--   6. a name the text used that is a class resolves through the class list
-- and, just as important, that a sprite whose tail is NOT a species declines --
-- SPRITE_MONSTER is a doll, not a Pokemon.
--
-- Run:  luajit tests/dp3_speaker_test.lua <engine root>
--   or: MODKIT_LUAJIT=<luajit> python3 tools/modkit.py test <mod dir>

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

local script = normalise(arg and arg[0] or "tests/dp3_speaker_test.lua")
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
if not love.timer then love.timer = { getTime = function() return 0 end } end

-- The stub image must be the shape a REAL LÖVE 11.5 Image is: getDimensions and
-- nothing else.  LÖVE removed Image:getData in 11.0 and this engine targets
-- 11.5, so a source picture cannot hand back its pixels at runtime.  A stub that
-- offered getData is exactly what hid the portrait bug that made every portrait
-- vanish in the game while this suite stayed green: the double was more capable
-- than the real object.  Same shape as dp3_geometry_test's.
local function stubImage(w, h)
  local image = { w = w, h = h }
  image.getDimensions = function() return w, h end
  return image
end
love.graphics = love.graphics or {}
love.graphics.newImage = function() return stubImage(64, 64) end
-- A crop is a quad, so the mod needs this and never a pixel readback.
love.graphics.newQuad = function(x, y, w, h, tex)
  return { x = x, y = y, w = w, h = h, tex = tex }
end
love.image = love.image or {}
love.image.newImageData = function(a, b)
  local w, h = a, b
  if type(a) == "number" then w, h = a, b else w, h = 64, 64 end
  local data = { w = w, h = h, pixels = {} }
  data.getPixel = function(_, x, y)
    local p = data.pixels[y * w + x]
    if p then return p[1], p[2], p[3], p[4] end
    return 0, 0, 0, 0
  end
  data.setPixel = function(_, x, y, r, g, b, a)
    data.pixels[y * w + x] = { r, g, b, a }
  end
  return data
end

-- ------- the engine's own picture sources, stubbed at the seam the mod asks
--
-- The mod resolves a trainer class through src.core.game3.trainer_pic and a
-- species through src.core.game3.pokemon.  Both are replaced here so the suite
-- can say WHICH source answered without needing the ROM.
local asked = { trainer = {}, species = {}, keyName = {}, speciesFromName = {} }
-- The images are keyed by PICTURE ID, so two calls for the same id hand back
-- the same object and two calls for different ids hand back different ones.
-- That is what makes "these two speakers got different pictures" a real
-- question: a stub that minted a fresh image per call would answer yes even if
-- the mod asked for one id for everybody, which is exactly the bug that
-- shipped.  The id has to be observable through the picture for the assertion
-- to mean anything.
local byPic = {}
package.loaded["src.core.game3.trainer_pic"] = {
  front = function(picId)
    asked.trainer[#asked.trainer + 1] = picId
    picId = tonumber(picId)
    if picId == 999 then return nil end
    byPic[picId] = byPic[picId] or stubImage(64, 64)
    return { image = byPic[picId], w = 64, h = 64 }
  end,
}
-- The engine's OWN spelling fold, which is what the crop table's species keys
-- are written in.  `keyName` is the display name with the gender signs spelled
-- _F / _M, the punctuation dropped and the spaces turned into underscores; the
-- crop table's keys are that, lowercased with the separators stripped.
--
-- It is stubbed rather than left out on purpose.  A stub without it would make
-- the mod's fold fall back to lowercasing the display name -- where "NIDORAN(F)"
-- becomes "nidoran" -- and the suite would pass while the per-species entry for
-- Nidoran could never fire, which is exactly the bug this release fixes.
local KEYNAMES = {
  [25] = "PIKACHU", [29] = "NIDORAN_F", [32] = "NIDORAN_M",
  [122] = "MR_MIME", [83] = "FARFETCHD", [250] = "HO_OH",
}
local BY_NAME = {
  PIKACHU = 25,
  ["NIDORAN♀"] = 29, NIDORAN_F = 29,
  ["NIDORAN♂"] = 32, NIDORAN_M = 32,
  ["MR. MIME"] = 122, MR_MIME = 122,
  ["FARFETCH'D"] = 83, FARFETCHD = 83,
}
local byDex = {}
package.loaded["src.core.game3.pokemon"] = {
  frontPic = function(index)
    asked.species[#asked.species + 1] = index
    index = tonumber(index)
    byDex[index] = byDex[index] or stubImage(64, 64)
    return { image = byDex[index], w = 64, h = 64 }
  end,
  keyName = function(index)
    asked.keyName[#asked.keyName + 1] = index
    return KEYNAMES[tonumber(index)]
  end,
  speciesFromName = function(name)
    asked.speciesFromName[#asked.speciesFromName + 1] = name
    if type(name) ~= "string" then return nil end
    return BY_NAME[name:upper()]
  end,
}
-- The class list the mod inverts, and the trainer rows it translates a class
-- through.  The numbers are the shape the real cart has, and they are chosen
-- so the class and the picture DISAGREE wherever it matters -- which is the
-- whole reason the translation exists:
--
--   class 17 -> pic 17    the coincidence that makes the bug easy to miss
--   class 43 -> pic 106   COLLECTOR: class and picture are different numbers
--   class 24 -> pic 26    one class, two pictures (a tie, resolved lowest)
--   class 97 -> pic 132   POKéMON PROF.: again different numbers
--   GRUNT                 one name, two pictures -- must decline
--
-- And the shape 1.9.2 exists for: the cart lists 31 of its class names TWICE,
-- the Hoenn class first and its Kanto counterpart second, and the two are
-- different people with different battle art.  LASS is 49 (picture 65, Hoenn)
-- and again 59 (picture 84, Kanto); RIVAL is 81 (picture 106, the early one)
-- and 89 (picture 124, the late one).  Both pairs are here, in the cart's own
-- order, so that a lookup taking the LOWEST id -- the rule this suite stayed
-- green through until 1.9.2 -- lands on the wrong one and the assertions below
-- fail.  That is the whole point of the duplication: the suite was green
-- because its pack had no duplicate names to be wrong about.
package.loaded["src.core.game3.scripting.trainers"] = {
  pack = function()
    return {
      classNames = { [0] = "POKéMON TRAINER", [2] = "PROFESSOR_OAK",
                     [8] = "AQUA LEADER", [17] = "GUITARIST",
                     [82] = "SCIENTIST", [64] = "SUPER NERD",
                     [24] = "LEADER", [27] = "FISHERMAN", [28] = "POKéFAN",
                     [29] = "YOUNGSTER", [49] = "LASS", [74] = "ELITE FOUR",
                     [84] = "LEADER", [43] = "COLLECTOR", [85] = "TEAM ROCKET",
                     [97] = "POKéMON PROF.",
                     -- The three classes that share the yellow-haired sprite,
                     -- so section 12 can show what the SPRITE route answers for
                     -- it (the Rocker) next to what each of the three really is.
                     [76] = "ROCKER", [77] = "JUGGLER", [79] = "BIRD KEEPER",
                     -- the duplicates: the Hoenn class first, Kanto second
                     [59] = "LASS", [81] = "RIVAL", [89] = "RIVAL",
                     -- GENTLEMAN, which is the class the cart draws the Resort
                     -- Gorgeous butler as (his graphic is
                     -- OBJ_EVENT_GFX_GENTLEMAN), so section 21 can show that
                     -- his label resolves through it.
                     [22] = "GENTLEMAN" },
      trainers = {
        -- Every row carries its OWN `id`, because the cart's do: the real table
        -- is a plain 1-based array whose rows repeat their trainer id, so
        -- `trainers[i].id == i - 1` and the ARRAY KEY is NOT the id.  The script
        -- route reads `row.id` and never the key, and a stub without the field
        -- would have made that route silently unreachable in here while working
        -- in the game -- the same class of gap as a double that offers a method
        -- the real object does not have, and just as good at hiding a bug.
        --
        -- The cart's table OPENS with an empty record -- trainer id 0, class 0,
        -- pic 0, no name -- and it is here on purpose, because a pack without
        -- it cannot reproduce the bug that shipped: `0` is truthy in Lua, so a
        -- guard that asks only `if pic` reads this row as a real mapping and
        -- answers picture 0 for class 0 -- which is what EVERY non-trainer map
        -- object carries (src/core/game3/objects.lua defaults trainerType to
        -- 0).  Every ordinary NPC in the game wore the same face.
        [0] = { id = 0,  class = 0,  pic = 0,   name = "" },
        -- A second one, under a class with no other row, so the rule under test
        -- is "picture 0 is the null picture" rather than "class 0 is special".
        [9] = { id = 9,  class = 8,  pic = 0,   name = "" },
        -- A GENTLEMAN, for section 21: the butler's picture is the cart's own
        -- Gentleman bust (123), reached through his label.
        [900] = { id = 900, class = 22, pic = 123, name = "WILTON" },
        [1] = { id = 1,  class = 17, pic = 17,  name = "BROCK" },
        [2] = { id = 2,  class = 43, pic = 106, name = "TERRY" },
        [3] = { id = 3,  class = 43, pic = 106, name = "TERRY" },
        [4] = { id = 4,  class = 24, pic = 26,  name = "ROXANNE" },
        [5] = { id = 5,  class = 24, pic = 27,  name = "BRAWLY" },
        [6] = { id = 6,  class = 97, pic = 132, name = "PROF. OAK" },
        [7] = { id = 7,  class = 85, pic = 109, name = "GRUNT" },
        [8] = { id = 8,  class = 85, pic = 137, name = "GRUNT" },
        -- The ordinary townsfolk classes: what a non-battle map object's SPRITE_*
        -- id is folded onto, so a Lass standing by the fence has a face.  They
        -- are here because SPRITE_ART is only as good as the class it names.
        [10] = { id = 10, class = 29, pic = 36, name = "" },
        [11] = { id = 11, class = 49, pic = 65, name = "" },
        -- The three-way collapse the graphics-id table exists for: the host
        -- maps the Hiker, the Balding Man and the Man all onto SPRITE_POKEFAN_M,
        -- so the sprite route can only ever answer ONE of the three -- the
        -- PokéFan -- and a Hiker wears his face.
        [15] = { id = 15, class = 28, pic = 66, name = "" },
        -- One class, several characters: class 84 is LEADER and covers all eight
        -- gym leaders, so the class route has to pick one of these two rows and
        -- the graphic is the only fact that says which leader is in the room.
        [12] = { id = 12, class = 84, pic = 26, name = "" },
        [13] = { id = 13, class = 84, pic = 27, name = "" },
        -- An Elite Four member, reachable by NAME -- the graphics-id table's
        -- string entries resolve through the pack exactly the way SPRITE_ART's
        -- values do, so this is the row that makes "LANCE" answer.
        [14] = { id = 14, class = 74, pic = 115, name = "LANCE" },
        -- The Fisherman, so the Fat Man's case can show what the sprite route
        -- would have answered: the host maps graphic 27 onto SPRITE_FISHER, so
        -- 1.6.0 gave a Fat Man the Fisherman's face.
        [16] = { id = 16, class = 27, pic = 67, name = "" },
        -- The Kanto half of the duplicated names -- the rows the cart actually
        -- fields its trainers under, and the reason the name lookup has to
        -- weigh rows rather than take the lowest id.  LASS is class 49 above
        -- (picture 65, the Hoenn lass) and 59 here (picture 84, the Kanto one),
        -- and 49's single row is a stray: the girl on Route 3 is a class-59
        -- Lass, so "lowest id wins" put a Hoenn face on her.
        [17] = { id = 17, class = 59, pic = 84,  name = "" },
        -- The rival pair, which the row count CANNOT separate on its own and
        -- which nothing in the game reported.  Class 81 (RIVAL_EARLY) is
        -- picture 106 and 89 (RIVAL_LATE) is 124; both class names are spelled
        -- "RIVAL", so once the tie-break prefers the class with more rows the
        -- name resolves to 89 and the LATE face.  The rival's picture is
        -- therefore pinned in the mod as RIVAL_ART and never looked up by this
        -- name -- and the assertions in section 5b are what say so.  Three rows
        -- at 89 against one at 81 is the shape that makes the name wrong; the
        -- cart's own split is 12 against 9, which is the same decision.
        [18] = { id = 18, class = 81, pic = 106, name = "" },
        [19] = { id = 19, class = 89, pic = 124, name = "" },
        [20] = { id = 20, class = 89, pic = 124, name = "" },
        [21] = { id = 21, class = 89, pic = 124, name = "" },
        -- ------- the script route's fixture
        --
        -- The four reported families, under the REAL trainer ids the shipped
        -- art/trainer_ids.lua carries -- so section 5c ties the file the mod
        -- ships to the pack it resolves against, instead of to a second copy of
        -- the same guess.  173 is Super Nerd Leslie (the report's first case),
        -- 484 a pair of Twins (the second), 258 a Gamer (the third: the old man
        -- the cart drew, not the old karate instructor), and 221 an Engineer,
        -- who wears a graphic the graphics table DELIBERATELY declines.
        [22] = { id = 173, class = 64, pic = 89,  name = "LESLIE" },
        [23] = { id = 484, class = 92, pic = 127, name = "ELI & ANNE" },
        [24] = { id = 258, class = 72, pic = 97,  name = "HUGO" },
        [25] = { id = 221, class = 68, pic = 93,  name = "BRAXTON" },
        -- ...and the OTHER person who wears graphic 55, so section 6h can show
        -- what the graphics route answers for the shared uniform: a Scientist,
        -- picture 107.  That is the face Super Nerd Leslie was wearing.
        [26] = { id = 26,  class = 82, pic = 107, name = "" },
        -- The ORDERING fixture, and it needs a shared graphic the graphics table
        -- DOES answer for: graphic 56 is worn by seventeen Hikers and seven Ruin
        -- Maniacs, and GFX_ART answers the Hiker.  A Ruin Maniac is the proof
        -- that the script route is consulted before that table -- if it were
        -- consulted after, picture 90 would already have been returned.
        [27] = { id = 620, class = 104, pic = 145, name = "LAYTON" },
        [28] = { id = 216, class = 67,  pic = 92,  name = "ARNIE" },
        -- ------- 1.9.4: ONE SPRITE, SEVERAL PEOPLE
        --
        -- Graphic 26 -- the yellow-haired sprite -- is worn by eighteen Bird
        -- Keepers, nine Jugglers and exactly one Rocker, and the three ids
        -- below are REAL ones whose objects really do stand on graphic 26
        -- (Route 13, Victory Road 2F and Route 12 respectively).  That is the
        -- reported "the yellow-haired trainer sprite sometimes shows the Rocker
        -- portrait and sometimes the Bird Keeper portrait" with the cart's own
        -- numbers attached, and section 12 asserts all three answers at once.
        [29] = { id = 300, class = 79, pic = 104, name = "SEBASTIAN" },
        [30] = { id = 287, class = 77, pic = 102, name = "NELSON" },
        [31] = { id = 285, class = 76, pic = 101, name = "LUCA" },
        -- The Young Couple.  Its two objects share trainer id 486 -- ONE
        -- picture for two people -- and differ only by graphic: the woman wears
        -- 29 (BEAUTY), the man 25 (MAN).  Both script keys are real, and they
        -- are two DIFFERENT keys naming the same id, which is exactly how the
        -- cart hands a couple to the player: one trainer, two bodies.
        [32] = { id = 486, class = 94, pic = 129, name = "GIA & JES" },
        -- The name route's four cases, all real ids.  ERIK and DAISY are the
        -- two the guard CLOSES (a name that matches somebody else entirely);
        -- LORELEI and SELPHY are the two that ARE the trainer they name and
        -- must keep their faces.  Section 12 asserts both halves, because a
        -- guard that closed all four would be as wrong as one that closed none.
        [33] = { id = 177, class = 64,  pic = 89,  name = "ERIK" },
        [34] = { id = 526, class = 106, pic = 147, name = "DAISY" },
        [35] = { id = 410, class = 87,  pic = 112, name = "LORELEI" },
        [36] = { id = 606, class = 105, pic = 146, name = "SELPHY" },
      },
    }
  end,
}

-- ------- the host's own GRAPHICS ID -> SPRITE_* table
--
-- Stubbed at the seam the mod asks (src/core/game3/scripting/gfx_ids.lua), and
-- for one reason only: to tell a sprite the host MAPPED from a sprite the host
-- FELL BACK to.  FRLG's OBJ_EVENT_GFX_* and the host's SPRITE_* vocabulary are
-- not the same space -- several graphics share one sprite, and the real table
-- answers SPRITE_YOUNGSTER for every graphic it does not list -- so "this
-- object's sprite is SPRITE_YOUNGSTER" is evidence about the TABLE's coverage,
-- not about the object.
--
-- The fallback is deliberately NOT reproduced here.  The mod reads TO_SPRITE
-- directly and must treat a missing entry as "the host guessed", so a stub that
-- applied the host's default would be enforcing the very rule under test -- the
-- same trap as the trainer_pic stub answering picture 0.  Only the ids used
-- below are listed.
--
-- Nothing from 92 up is listed, and that is the real table's own limit rather
-- than a convenience: it stops at 92 (SPRITE_POKE_BALL), and FRLG's Pokemon
-- graphics -- 109 SNORLAX through 150 DEOXYS_N -- all sit above it, so every
-- one of them arrives at the mod as the host's SPRITE_YOUNGSTER fallback.  A
-- stub that invented an entry for 110 would be a double more capable than the
-- engine, and the Pokemon route would then look tested while the very thing it
-- works around had been edited out of the test.
package.loaded["src.core.game3.scripting.gfx_ids"] = {
  TO_SPRITE = {
    [17] = "SPRITE_LASS",          -- LITTLE_GIRL
    [22] = "SPRITE_LASS",          -- LASS: the graphic, and it needs no entry
    [27] = "SPRITE_FISHER",        -- FAT_MAN: mapped, onto a Fisherman
    [30] = "SPRITE_POKEFAN_M",     -- BALDING_MAN, and the same sprite as the Man
    [32] = "SPRITE_GRAMPS",        -- OLD_MAN_1
    [55] = "SPRITE_SCIENTIST",     -- SCIENTIST, the graphic Super Nerds also wear
    [56] = "SPRITE_POKEFAN_M",     -- HIKER, and the same sprite as the Man
  },
}

-- ------- the cart's own Fame Checker portraits, stubbed at the seam the mod
-- asks (src/ui/game3/fame_checker.lua `portrait`).
--
-- The real module decodes a 64x64 RGBA out of the generated cache the engine
-- extracted from the player's ROM; the double hands back the same shape a real
-- LÖVE Image has (getDimensions) and records the person index it was asked for,
-- so the suite can prove WHICH person each name asks for rather than only that
-- something came out.  Bill is person 13, Daisy 1, Mr. Fuji 14.
local fameAsked = {}
package.loaded["src.ui.game3.fame_checker"] = {
  portrait = function(person)
    fameAsked[#fameAsked + 1] = person
    return stubImage(64, 64)
  end,
}

-- ------- the engine's session, stubbed at the seam the rival route asks
--
-- The rival's name is the one thing the cart cannot spell out: his dialogue is
-- written with the FD 06 placeholder, which the engine expands to whatever the
-- player typed before a mod ever sees the box.  That name lives in the save,
-- and the mod reaches it through the engine's session.  Stubbed here so the
-- suite never needs a booted game, and so section 7b can say "the player called
-- him GARY" by setting one field.
--
-- The shape is the real one -- one session object with a mutable field, not a
-- function that mints a fresh table per call -- because the mod reads it twice
-- in one resolution (once to flag the speaker, once inside artFor) and a double
-- that changed answer between those two reads would be a different object from
-- the one the engine hands it.  `_game` is the second place the name can come
-- from and is added only in the branch that tests it.
local session = { rivalName = nil }
local sessionStub = { getSession = function() return session end }
package.loaded["src.core.game3.runtime"] = sessionStub

-- ------- the mod facade
local Runtime = require("src.mods.Runtime")
local Hooks = require("src.mods.Hooks")
local Events = require("src.mods.Events")
Runtime.install(Events.new(), Hooks.new(), {})

local SPECIES = {
  PIKACHU   = { index = 25 },
  CHARIZARD = { index = 6 },
  SNORLAX   = { index = 143 },
  -- The reported case.  Spearow stands in the world as OBJ_EVENT_GFX_SPEAROW
  -- (graphics id 110) and the host sprite vocabulary has no name for it, so
  -- before 1.9.2 it got no portrait at all -- see section 6g.
  SPEAROW   = { index = 21 },
  -- Keyed by the CART's spelling, deliberately.  The engine's norm_key folds
  -- NIDORAN♀ to "nidoranf" when the real dex is asked, and the mod must NOT do
  -- that folding itself -- it hands the token on as the text spelled it.  A stub
  -- keyed by the cart's spelling therefore fails the moment the mod starts
  -- normalising, which is the duplication this is here to prevent.
  ["NIDORAN♀"] = { index = 29 },
  ["NIDORAN♂"] = { index = 32 },
  ["MR. MIME"] = { index = 122 },
  ["FARFETCH'D"] = { index = 83 },
}
local customFiles = {}

local mod = { path = MOD_ROOT, exports = {}, generation = 3 }
mod.log = { info = function() end, warn = function() end, error = function() end }
mod.options = {
  define = function() end,
  get = function(_, key) return ({ style = "inset", side = "auto" })[key] end,
}
mod.read = function(_, rel)
  local f = io.open(MOD_ROOT .. "/" .. rel, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  return data
end
mod.content = {
  pokemon = { get = function(_, name) return SPECIES[name] end },
}
mod.assets = {
  image = function(_, path)
    if customFiles[path] then return stubImage(64, 64) end
    return nil
  end,
}
mod.hooks = {
  wrap = function(_, name, fn) Runtime.hooks:wrap(name, fn, 100, "gen3-dialogue-portraits") end,
}
mod.events = {
  on = function(_, name, fn) Runtime.events:on(name, fn, 100, "gen3-dialogue-portraits") end,
}

-- ------- load the mod
--
-- The engine's own invocation (src/mods/Loader.lua): run the entry chunk with
-- the api, and if it RETURNED a function, call that with the api too.  A mod
-- file may do either.
local chunk = assert(loadfile(MOD_ROOT .. "/main.lua"))
local result = chunk(mod)
if type(result) == "function" then result(mod) end
local X = mod.exports

ok(type(X.nameFromText) == "function", "the mod exports nameFromText")
ok(type(X.artFor) == "function", "the mod exports artFor")
ok(type(X.speakerFor) == "function", "the mod exports speakerFor")

-- ------- 1. the text's own name
io.write("-- the text names its speaker\n")
eq(X.nameFromText("OAK: This is my lab!"), "OAK", "OAK: is read off the text")
eq(X.nameFromText("RIVAL: Smell ya later!"), "RIVAL", "RIVAL: is read off the text")
eq(X.nameFromText("NIDORAN_F: Nidoran!"), "NIDORAN_F", "an underscore species key tokenises")
eq(X.nameFromText("PROF.OAK: Hmm."), "PROF.OAK", "a dotted name tokenises")
eq(X.nameFromText("Just some ordinary text."), nil, "plain text names nobody")
eq(X.nameFromText("lowercase: not a name"), nil, "a lowercase prefix is not a name")
eq(X.nameFromText("PIKACHU: Pika!"), "PIKACHU", "a species can name itself")

-- a token list, which is what a scripted box actually carries
local tokens = { { s = "PIKACHU" }, { s = ":" }, { s = " Pika!" } }
eq(X.nameFromText(tokens), "PIKACHU", "a token list is flattened before the name is read")
eq(X.plainText(tokens), "PIKACHU: Pika!", "plainText joins the token strings")

-- ------- 1b. the names the cart spells with a sign, a quote or a space
--
-- FRLG spells four of its 386 species with a character an obvious `[A-Z0-9._-]`
-- token class rejects: NIDORAN♀ and NIDORAN♂ (the gender signs), FARFETCH'D (an
-- apostrophe) and MR. MIME (a space).  That is not a curiosity, because two of
-- those four are among the 19 species that speak ANYWHERE in this game -- the
-- rest being CHANSEY, CLEFAIRY, CUBONE, DODUO, FEAROW, JIGGLYPUFF, MACHOKE,
-- MACHOP, MEOWTH, NIDORINO, PIDGEOT, PIDGEY, PIKACHU, POLIWRATH, PSYDUCK, SEEL
-- and WIGGLYTUFF -- so a class that stopped at the underscore made both Nidoran
-- resolve no speaker at all and draw no portrait.
--
-- The names that already worked are asserted alongside them, because a widening
-- that broke PIKACHU would be no fix at all.
io.write("-- the names the cart spells with a sign, a quote or a space\n")
eq(X.nameFromText("NIDORAN♀: Kya kyaoo!"), "NIDORAN♀", "the female sign tokenises")
eq(X.nameFromText("NIDORAN♂: Bowbow!"), "NIDORAN♂", "and the male sign")
eq(X.nameFromText("FARFETCH'D: Leek!"), "FARFETCH'D", "an apostrophe tokenises")
eq(X.nameFromText("MR. MIME: Mime mime!"), "MR. MIME", "and a space inside a name")
eq(X.nameFromText("PIKACHU: Pika!"), "PIKACHU", "the names that already worked still do")

-- The token is handed on EXACTLY as the cart spells it.  Folding ♀/♂ to _F/_M
-- is the engine's norm_key and belongs there -- it is also what has to answer
-- for a host key like "nidoranf" -- so a normalisation hidden in the mod would
-- be a second implementation of it.  The stub above is keyed by the cart's own
-- spelling, so this fails the moment the mod starts folding.
X.forgetSpeaker()
local nido = X.speakerFor("NIDORAN♀: Kya kyaoo!")
eq(nido and nido.species, "NIDORAN♀", "a Nidoran resolves to the cart's own spelling")
eq(nido and nido.fromText, true, "and is marked as coming from the text")
ok(X.artFor(nido) ~= nil, "so it gets a portrait where it used to get none")
eq(asked.species[#asked.species], 29, "cut from Nidoran F's own front pic")

-- The widening admits multi-word tokens, and the cart really does write those:
-- its signs read "UNION ROOM:" and "ROOFTOP SQUARE:".  A name is only ever a
-- HINT here, so a token that resolves to nothing must leave the object the
-- press found untouched rather than erasing it -- the same property the rival's
-- placeholder name needed.  With no press on record there is nothing to fall
-- back to, so the answer is nothing drawn -- which is right for a sign.
eq(X.nameFromText("UNION ROOM: Trade here!"), "UNION ROOM", "a sign's label tokenises")
eq(X.artFor(X.speakerFor("UNION ROOM: Trade here!")), nil,
  "but a label that names nobody draws nothing")
eq(X.nameFromText("lowercase: still not a name"), nil,
  "and the class is still uppercase-only, so prose is never a name")

-- ------- 2. the text beats the press
io.write("-- a name in the text beats whoever is standing there\n")
local byText = X.speakerFor("PIKACHU: Pika!")
eq(byText and byText.species, "PIKACHU", "a named species resolves to that species")
eq(byText and byText.fromText, true, "and it is marked as coming from the text")
local art = X.artFor(byText)
ok(art ~= nil, "a named species gets art")
eq(asked.species[#asked.species], 25, "and the dex was asked for that species")

-- ------- 3. the press names the object
io.write("-- the press names the object\n")
local PIKACHU_EO = { def = { sprite = "SPRITE_PIKACHU" }, sprite = "SPRITE_PIKACHU" }
Runtime.call("world.talk", function() end, {}, PIKACHU_EO)
local byPress = X.speakerFor("Pika pika!")
eq(byPress and byPress.sprite, "SPRITE_PIKACHU", "the press's object is the speaker")
local pressArt = X.artFor(byPress)
ok(pressArt ~= nil, "a talking Pokemon gets art from the dex")
eq(asked.species[#asked.species], 25, "the dex was asked for Pikachu")

-- a trainer object carries its class as a number
local BROCK_EO = { def = { trainerType = 17 }, trainerType = 17, sprite = "SPRITE_HIKER" }
Runtime.call("world.talk", function() end, {}, BROCK_EO)
local byClass = X.speakerFor("I am Brock!")
eq(byClass and byClass.class, 17, "a trainer object keeps its numeric class")
ok(X.artFor(byClass) ~= nil, "a trainer class gets art")
eq(asked.trainer[#asked.trainer], 17, "TrainerPic.front was asked for that class")

-- ------- 4. a sprite whose tail is not a species declines
io.write("-- a doll is not a Pokemon\n")
eq(X.speciesOfSprite("SPRITE_PIKACHU"), "PIKACHU", "SPRITE_PIKACHU is a Pikachu")
eq(X.speciesOfSprite("SPRITE_MONSTER"), nil, "SPRITE_MONSTER is a doll, not a species")
eq(X.speciesOfSprite("SPRITE_SURF"), nil, "the surf blob is not a species")
eq(X.speciesOfSprite("NOT_A_SPRITE"), nil, "a non-sprite id declines")

-- ------- 5. the class list is inverted, not hardcoded
io.write("-- class names resolve through the engine's own list\n")
eq(X.classIdForName("PROFESSOR_OAK"), 2, "PROFESSOR_OAK resolves to its class id")
eq(X.classIdForName("professor_oak"), 2, "the lookup is case-insensitive")
eq(X.classIdForName("NO_SUCH_CLASS"), nil, "an unknown class resolves to nil")

-- ------- 5b. a class name the cart lists TWICE means the one it USES
--
-- The reported "certain NPCs display an incorrect portrait", reduced to one
-- lookup.  FRLG carries the whole Hoenn class roster first and repeats 31 of
-- those names for its own Kanto classes further down -- LASS is 49 and again
-- 59 -- and the two are different people with different battle art.  Until
-- 1.9.2 the lookup took the LOWEST id with the name, so it answered the Hoenn
-- class for all 31 of them, and the girl on Route 3 (a class-59 Lass) wore the
-- Hoenn Lass's face.
--
-- The evidence for which id a name MEANS is the cart's own trainer table: the
-- class the game fields trainers under is the one with rows, and 49's single
-- row is a stray against 59's six.  So the tie is broken on row count.  The
-- two assertions that matter are the id AND the picture, because a lookup that
-- returned 59 while the pack's picture table still answered 65 would be the
-- same wrong face by a longer route.
io.write("-- a class name the cart lists twice means the one it uses\n")
eq(X.classIdForName("LASS"), 59, "LASS means the Kanto class, 59 -- not the Hoenn 49")
eq(X.picForClass(X.classIdForName("LASS")), 84,
   "and the Lass picture is 84, the Kanto one, not the Hoenn 65")
eq(X.picForClass(49), 65,
   "while the Hoenn class still resolves to its own picture when asked by id")

-- The pair the row count cannot separate, and the reason the rival's picture is
-- a constant.  The stub's class 81 carries one row and 89 carries three, so the
-- name resolves to 89 -- the LATE rival's picture 124 -- where the cart's own
-- numbers are 81 with 9 rows and 89 with 12.  (Class 43 is spelled COLLECTOR
-- here, as the cart spells it; the pre-1.9.2 stub called it RIVAL, which the
-- cart never did, and that fiction made this ambiguity invisible.)
eq(X.classIdForName("RIVAL"), 89, "RIVAL is ambiguous and the row count picks 89")
eq(X.picForClass(89), 124, "which is the LATE rival's picture, 124")
eq(type(X.RIVAL_ART), "number", "so the rival's picture is pinned as a number")
eq(X.RIVAL_ART, 106, "and it is the early one, 106 -- what this mod always answered")
eq(X.NAME_ART.RIVAL, X.RIVAL_ART,
   "the text route's RIVAL entry is that number, not the ambiguous name")
eq(X.SPRITE_ART.SPRITE_BLUE, X.RIVAL_ART,
   "and so is the sprite route's, so neither can reach the name")

-- And the three routes that READ those entries really do answer the pin.  The
-- two assertions above say the constants agree; these say the resolution goes
-- through them, which is a different claim -- a route that looked the name up
-- directly would leave both constants untouched and still draw 124.
local rivalByName = X.artFor({ name = "RIVAL" })
eq(rivalByName and rivalByName.pic, 106,
   "a box that names RIVAL draws 106 even though the NAME means 124")
local rivalBySprite = X.artFor({ sprite = "SPRITE_BLUE" })
eq(rivalBySprite and rivalBySprite.pic, 106,
   "the rival's own object draws 106 through the sprite route")
local rivalByFlag = X.artFor({ rival = true })
eq(rivalByFlag and rivalByFlag.pic, 106,
   "and the player's-own-name route draws 106")

-- ------- 6. the class is EXCHANGED for a picture, not used as one
--
-- This is the Gen 3 trap.  FRLG's class ids and front-pic ids are different
-- number spaces, so handing a class to TrainerPic.front does not fail -- it
-- quietly returns whichever picture sits at that index, which is a different
-- character's face.  It happens to look right for the low-numbered classes
-- (GUITARIST is class 17 and picture 17), which is exactly why it needs a test.
io.write("-- a class is translated to its picture\n")
eq(X.picForClass(17), 17, "a class that pins one picture resolves to it")
eq(X.picForClass(43), 106, "COLLECTOR is class 43 and picture 106 -- not 43")
eq(X.picForClass(97), 132, "POKéMON PROF. is class 97 and picture 132")
eq(X.picForClass(24), 26, "a class with two pictures picks the lowest of the tie")
eq(X.picForClass(9999), nil, "an unknown class has no picture")

-- the picture the class resolved to is the one actually asked for
asked.trainer = {}
local byTranslated = X.artFor({ class = 43 })
ok(byTranslated ~= nil, "a class gets art through the translation")
eq(asked.trainer[#asked.trainer], 106, "TrainerPic.front was asked for 106, not 43")
eq(byTranslated and byTranslated.pic, 106, "and the entry carries the picture's id")

-- ------- 6b. the cart's null records are not mappings
--
-- The bug this section exists for: EVERY interaction in the game showed the
-- SAME portrait.  The cart's trainer table opens with an empty record -- trainer
-- id 0, class 0, pic 0 -- and every map object that is not a trainer carries
-- class 0, so an index that accepted `pic = 0` answered picture 0 (a real 64x64
-- face) for every townsfolk, family member and shopkeeper in FireRed.
--
-- This whole suite was green through that, because the pack stub above had no
-- such row.  A double that carries only the CLEAN shape of the data cannot fail
-- on the dirty shape; rows 0 and 9 of the stub are the dirty shape, and they
-- are there to keep this from ever being green again.
io.write("-- the cart's null records are not mappings\n")
eq(X.picForClass(0), nil, "class 0 means 'not a trainer', so it maps to nothing")
eq(X.picForClass(8), nil, "nor does a class whose only row is picture 0")
eq(X.picArt(0), nil, "picture 0 is the cart's null picture, not a picture")
eq(X.picForName(""), nil, "the empty record names nobody")

-- the shape the player actually meets: an ordinary object, class 0, wearing a
-- sprite the cart never drew a battle face for.  It gets nothing -- and
-- specifically NOT the null picture.
local NPC_EO = { def = { trainerType = 0 }, trainerType = 0,
                 sprite = "SPRITE_NURSE" }
Runtime.call("world.talk", function() end, {}, NPC_EO)
local npc = X.speakerFor("Hello there!")
ok(npc ~= nil, "an ordinary NPC is still a speaker")
eq(npc and npc.class, nil, "but class 0 is not carried as a class")
eq(X.artFor(npc), nil, "and an unmapped sprite gets no portrait -- not the null one")
eq(X.portraitFor(npc), nil, "so nothing is cut for it either")

-- ------ 6d. an ordinary NPC whose sprite names a class DOES get a face
--
-- This is the other half of the same rule, and it is what makes portraits
-- appear for the townsfolk the player actually walks up to: a map object that
-- is NOT a trainer carries no class, so its own SPRITE_* id is the only thing
-- naming it.  SPRITE_LASS is the Lass, so it gets the Lass's battle bust.
io.write("-- a townsfolk sprite that names a class gets that class's picture\n")
eq(X.SPRITE_ART.SPRITE_LASS, "LASS", "SPRITE_LASS names the LASS class")
asked.trainer = {}
local lassArt = X.artFor({ sprite = "SPRITE_LASS" })
ok(lassArt ~= nil, "a Lass NPC gets a portrait")
-- 84, not 65.  The sprite names the class "LASS", the cart spells that name
-- twice, and 1.9.1 answered the Hoenn class's picture 65 -- which is the
-- reported girl on Route 3 wearing the wrong face.  The assertion is on the id
-- actually asked of TrainerPic.front, so a resolver that picked the right class
-- and then asked for the wrong picture still fails here.
eq(asked.trainer[#asked.trainer], 84, "TrainerPic.front was asked for the KANTO Lass picture")
eq(lassArt and lassArt.pic, 84, "and the entry carries it")
ok(X.artFor({ sprite = "SPRITE_NURSE" }) == nil,
   "while a sprite the cart never drew for still gets nothing")
-- a nameless Lass object with class 0 must not be dragged back to the null pic
local LASS_EO = { def = { trainerType = 0 }, trainerType = 0,
                  sprite = "SPRITE_LASS" }
Runtime.call("world.talk", function() end, {}, LASS_EO)
local lass = X.speakerFor("Hi!")
eq(lass and lass.class, nil, "a townsfolk Lass carries no class")
eq(X.artFor(lass) and X.artFor(lass).pic, 84,
   "and still resolves through the sprite, not through picture 0")

-- ------- 6e. the cart's own GRAPHICS ID outranks the sprite, and can decline
--
-- The release.  SPRITE_ART answers from the object's overworld SPRITE_*, and
-- that is not FRLG's OBJ_EVENT_GFX_*: several graphics share one sprite, and
-- every graphic the host table does not list falls back to SPRITE_YOUNGSTER.
-- Both consequences were visible in play, as one complaint -- "some NPCs have
-- the wrong portrait": a Hiker wearing the PokéFan's face, and a Bug Catcher, a
-- Rocket, a Swimmer, the Channeler and every gym leader standing in their own
-- room wearing a Youngster's.
--
-- The object still carries its real graphics id, and it is the more specific
-- fact -- a graphic is one person or one uniform, a class can cover eight gym
-- leaders -- so the mod consults it BEFORE the class route.  The half that is
-- easy to miss is the second one: "the host has no mapping for this graphic"
-- is evidence that the sprite the object carries is the host's FALLBACK rather
-- than a fact about the object, so that closes the sprite route instead of
-- handing back the Youngster.
io.write("-- the cart's graphics id outranks the sprite, and can decline\n")

eq(type(X.GFX_ART), "table", "the cart's graphics-id table is there to consult")

-- A gym leader.  Class 84 is LEADER and covers all eight of them, so the class
-- route has to pick one of its rows; only the graphic says which leader is
-- standing there.  This is the precedence assertion -- the graphic runs BEFORE
-- the class, not after it.
local byClass = X.artFor({ class = 84 })
eq(byClass and byClass.pic, 26, "class 84 alone answers with one of its rows")
asked.trainer = {}
local sabrina = X.artFor({ class = 84, gfx = 85 })
ok(sabrina ~= nil, "the same class WITH a graphic still resolves")
eq(asked.trainer[#asked.trainer], 122, "to Sabrina's picture, asked for by graphics id")
ok(sabrina and sabrina.pic ~= byClass.pic,
   "which is not what the class alone answered, so the graphic really outranked it")

-- A Hiker.  SPRITE_POKEFAN_M is the Man, the Balding Man AND the Hiker, so the
-- sprite route can only ever answer one of the three -- and the one it answered
-- was the PokéFan.
asked.trainer = {}
local hiker = X.artFor({ sprite = "SPRITE_POKEFAN_M", gfx = 56 })
ok(hiker ~= nil, "a Hiker gets a portrait")
eq(asked.trainer[#asked.trainer], 90, "the cart's own HIKER picture, by graphics id")
eq(X.artFor({ sprite = "SPRITE_POKEFAN_M" }).pic, 66,
   "where the sprite alone answers with the PokéFan's")

-- A `false` entry: a graphic the cart never drew a battle bust of.  The female
-- Worker is the shape of it -- the host maps graphic 48 onto SPRITE_SCIENTIST,
-- so the sprite route hands back the Scientist, which is the face she wore.
-- Declining has to close the SPRITE route too, or the host's guess comes
-- straight back.
--
-- This block used graphic 27, the Fat Man, as its example until 1.2.3 gave him
-- the Collector's bust out of rom_sprites (see GFX_ART).  The rule is the same
-- one; only the example moved.
eq(X.GFX_ART[48], false, "graphic 48 is the female Worker, whom the cart never drew")
eq(X.artFor({ sprite = "SPRITE_SCIENTIST" }).pic, 107,
   "the Scientist sprite alone still answers")
eq(X.artFor({ sprite = "SPRITE_SCIENTIST", gfx = 48 }), nil,
   "but her graphic declines it -- no portrait, not a Scientist's")

-- And the same rule for a graphic the host table simply does not list: the
-- sprite the object carries is the host's own fallback, so it says nothing
-- about who is talking and must not be used.
--
-- The example is graphic 91 (the Gym Guy), not 63: 1.2.5 gave the captain's
-- graphic its own entry, so 63 no longer demonstrates an unmapped graphic.
eq(X.artFor({ sprite = "SPRITE_YOUNGSTER", gfx = 91 }), nil,
   "a graphic the host does not map closes the sprite route rather than guessing")
asked.trainer = {}
-- Graphic 22 is the LASS, which GFX_ART does not touch, so this is the sprite
-- route answering and nothing else.  (Graphic 17 was used here until 1.9.4;
-- it now has an entry of its own, so it no longer demonstrates the sprite
-- route -- see "the LITTLE_GIRL graphic is a twin" below.)
local mapped = X.artFor({ sprite = "SPRITE_LASS", gfx = 22 })
ok(mapped ~= nil, "while a graphic the host DOES map keeps it open")
eq(asked.trainer[#asked.trainer], 84, "and it resolves to the Lass, exactly as before")

-- A STRING entry resolves through the pack -- a trainer's own name first, a
-- class name second -- so the Elite Four need no picture id typed into the
-- table at all.
asked.trainer = {}
local lance = X.artFor({ gfx = 74 })
ok(lance ~= nil, "a string entry resolves through the pack")
eq(asked.trainer[#asked.trainer], 115, "to Lance's own picture")

-- ------- 6f. 1.9.1: the graphics ids that were wearing the WRONG PERSON
--
-- 1.9.0 answered two shapes: "the host has no mapping for this graphic" and
-- "this graphic is a person the cart never drew".  It did not answer the two in
-- between, and they are what the second report names:
--
--   * the host DOES map the graphic, but onto a sprite that names a DIFFERENT
--     kind -- a Camper onto SPRITE_YOUNGSTER, a Picnicker onto SPRITE_LASS;
--   * the host maps it onto ONE sprite shared by two people, so the sprite
--     route answered for whichever the class-name lookup reached first -- which
--     for SPRITE_COOLTRAINER_F was the MALE cooltrainer, and for a male TUBER
--     was the FEMALE one.
--
-- Both are the gym leaders' lesson again: a class covers a whole kind, a graphic
-- is one person.  So every assertion here is on the graphics id, and every pair
-- asserts that the two sexes come back as two DIFFERENT pictures -- an
-- assertion on the id alone would be satisfied by a resolver that asked for the
-- right id and then drew the same face for both.
io.write("-- a graphic the host names with the wrong person\n")

-- A Camper.  The host calls him SPRITE_YOUNGSTER, so the sprite route handed
-- back picture 36 -- a boy, but the wrong one, and not a camper.
asked.trainer = {}
local camper = X.artFor({ sprite = "SPRITE_YOUNGSTER", gfx = 39 })
ok(camper ~= nil, "a Camper gets a portrait")
eq(asked.trainer[#asked.trainer], 86, "the cart's own CAMPER picture, by graphics id")

-- A Picnicker.  The host calls her SPRITE_LASS, so she wore the Lass's face.
asked.trainer = {}
local picnicker = X.artFor({ sprite = "SPRITE_LASS", gfx = 40 })
ok(picnicker ~= nil, "a Picnicker gets a portrait")
eq(asked.trainer[#asked.trainer], 87, "the cart's own PICNICKER picture")

-- The cooltrainers.  SPRITE_COOLTRAINER_M and _F both name the class
-- COOLTRAINER, and the two graphics resolve by id -- but the sprite route is
-- what 1.9.0 used, and it answered from the class name alone, whose one row is
-- a MALE.  So a female cooltrainer wore a man's face.  (1.9.2 changed how a
-- duplicated class name is resolved, but this pair never depended on that: the
-- graphics id settles it, and the two assertions below are what keep it settled
-- whatever the name lookup decides.)
asked.trainer = {}
local coolM = X.artFor({ sprite = "SPRITE_COOLTRAINER_M", gfx = 41 })
eq(asked.trainer[#asked.trainer], 110, "a male Cooltrainer resolves to his own picture")
asked.trainer = {}
local coolF = X.artFor({ sprite = "SPRITE_COOLTRAINER_F", gfx = 42 })
eq(asked.trainer[#asked.trainer], 111, "and a female one to hers, not to his")
ok(coolM and coolF and coolM.image ~= coolF.image,
   "so the two sexes do not share a face")

-- The tubers.  1.9.0 sent all three tuber graphics to picture 140 and said the
-- cart "has one tuber picture"; it has two.  140 is the female, 7 the male.
asked.trainer = {}
local tuberM = X.artFor({ gfx = 36 })
eq(asked.trainer[#asked.trainer], 7, "a male Tuber gets the male tuber picture")
asked.trainer = {}
local tuberF = X.artFor({ gfx = 37 })
eq(asked.trainer[#asked.trainer], 140, "and a female one the female picture")
ok(tuberM and tuberF and tuberM.image ~= tuberF.image,
   "which are two pictures, as the cart drew two")

-- The old folks.  The cart DID draw them, and the host vocabulary has no name
-- for them at all: SPRITE_GRAMPS and SPRITE_GRANNY are not in SPRITE_ART, so
-- they had no portrait -- and they are the most common people in the game after
-- the youngsters.
--
-- 1.9.1 answered with "pictures 34 and 35, the EXPERT pair", and that is half
-- right: 35 IS the old woman, and 34 is EXPERT_M -- the old KARATE INSTRUCTOR,
-- white gi, black belt, red headband.  The bald old man in the blue robe that
-- every OBJ_EVENT_GFX_OLD_MAN_* sprite depicts is the GAMER, picture 97.  The
-- difference is not academic, and it is not only about trainers: 35 of the 41
-- objects wearing an old-man graphic are ordinary people, who have no trainer
-- row for the script route to resolve them by, so THIS entry is what they wear.
-- The literal is the requirement; GFX_ART is how it is spelled.
asked.trainer = {}
local oldMan = X.artFor({ sprite = "SPRITE_GRAMPS", gfx = 32 })
ok(oldMan ~= nil, "an old man gets a portrait where he had none")
eq(asked.trainer[#asked.trainer], 97, "the cart's own old-man picture")
eq(X.GFX_ART[34], 97, "and not picture 34, which is the old karate instructor")
-- 33 is NOT the same man.  This line said "the second old man is the same
-- person" until 1.2.3, on the note that the cart carries one old-man bust.
-- rom_sprites says otherwise: ow_032 is a blue-robed old man and ow_033 is a
-- khaki-clad one, and the cart's second old-man bust is 75 -- a bald man with
-- white hair at the sides and a khaki outfit, exactly the graphic's man.
eq(X.GFX_ART[33], 75, "the second old man is a DIFFERENT man -- picture 75")
eq(X.GFX_ART[34], 97, "and so is the one lying down")
asked.trainer = {}
local oldWoman = X.artFor({ sprite = "SPRITE_GRANNY", gfx = 35 })
ok(oldWoman ~= nil, "and an old woman gets one")
eq(asked.trainer[#asked.trainer], 35, "the cart's own old-woman picture")
ok(oldMan and oldWoman and oldMan.image ~= oldWoman.image,
   "which are two people, not one face for both")

-- The Man and the Balding Man.  Both share SPRITE_POKEFAN_M with the Hiker, and
-- the Hiker was fixed by naming his picture; before that the other two wore the
-- PokéFan's face -- picture 66, a boy with a net, so a grown man and a bald one
-- were wearing a child's.
--
-- Both are now answered by the cart's own bust for the CLASS that wears the
-- graphic.  The Balding Man (30) is the ENGINEER: all three Engineers wear it
-- and nothing else does, so picture 93 is the cart's bust of this exact person,
-- and the 28 ordinary balding men are the same person the Engineers are.
--
-- The Man (25) is the TAMER, by the majority rule the map table already uses.
-- Measured by .probe/dp3_classgfx.lua: graphic 25 carries 9 trainer objects --
-- six TAMERs (class 78) and three YOUNG COUPLEs (94) -- and 20 ordinary men, and
-- art/map_art.lua already answers 103 for it on each of the four maps a Tamer
-- stands on.  Declining it made the SAME sprite answer on those four maps and
-- nowhere else, which is the reported "not all Tamer sprites have associated
-- portraits".  Picture 103 is the Tamer -- a man in a man's clothes, whip
-- raised -- so it is a plausible face for the twenty men too, and it is exactly
-- what the map route already gives the nine trainers.
eq(X.GFX_ART[25], 103, "graphic 25 is the Man, and the class the cart put on it is the Tamer")
eq(X.GFX_ART[30], 93, "and graphic 30 the Balding Man is the Engineer")
asked.trainer = {}
local man = X.artFor({ sprite = "SPRITE_POKEFAN_M", gfx = 25 })
eq(man and man.pic, 103, "so a Man gets the Tamer's face, not the PokéFan's")
eq(asked.trainer[#asked.trainer], 103, "and it is the cart's own TAMER picture")
local balding = X.artFor({ sprite = "SPRITE_POKEFAN_M", gfx = 30 })
ok(balding ~= nil, "and a Balding Man gets a face after all")
eq(asked.trainer[#asked.trainer], 93, "the cart's own Engineer, which is him")

-- ...and the sprite route's own answer is still refused, which is what the
-- decline was for in the first place: the graphic's entry outranks it.
eq(X.artFor({ sprite = "SPRITE_POKEFAN_M" }).pic, 66,
   "the PokéFan sprite alone still answers with its own picture")
eq(X.artFor({ sprite = "SPRITE_POKEFAN_M", gfx = 25 }).pic, 103,
   "but on graphic 25 the graphic's own answer wins, so no boy's face")

-- The end of the chain, and the shape the player actually meets: a Swimmer's
-- map object.  He is not a battle object, so he carries class 0 and the host
-- drops his graphic onto SPRITE_YOUNGSTER -- which is why he wore a boy's face.
local SWIMMER_EO = { def = { trainerType = 0 }, trainerType = 0,
                     sprite = "SPRITE_YOUNGSTER", graphicsId = 44 }
Runtime.call("world.talk", function() end, {}, SWIMMER_EO)
local swimmer = X.speakerFor("The water's lovely!")
eq(swimmer and swimmer.gfx, 44, "the press carries the object's own graphics id")
asked.trainer = {}
local swimmerArt = X.artFor(swimmer)
ok(swimmerArt ~= nil, "and a Swimmer gets a portrait")
eq(asked.trainer[#asked.trainer], 99, "his own, not the Youngster's the host fell back to")
ok(swimmerArt and swimmerArt.pic ~= 36,
   "so the wrong-portrait report is answered at the object, not at the sprite")

-- ------- 6g. 1.9.2: a Pokemon standing in the world
--
-- The other half of the report, and the same failing vocabulary one layer
-- further out.  FRLG puts Pokemon in the world as map objects and names each
-- one with its own OBJ_EVENT_GFX_* id -- 109 SNORLAX through 150 DEOXYS_N --
-- and the host's graphics-id table stops at 92.  So a Spearow arrives with no
-- host sprite of its own, and the two facts that could have named it are both
-- destroyed by the fallback the engine substitutes:
--
--   * speciesOfSprite("SPRITE_YOUNGSTER") is nil -- the sprite route has no
--     species to answer with, because a Youngster is not a Pokemon;
--   * hostSpriteFor(110) is nil, so the sprite route in artFor is CLOSED, since
--     a boy's face on a Spearow is the wrong-portrait bug that rule prevents.
--
-- Neither is wrong on its own.  Together they meant NO PORTRAIT AT ALL for
-- every Pokemon standing in the world -- the reported "some Pokemon, such as
-- Spearow, do not display a portrait at all".  The cart's graphics id is the
-- fact left over, and it names the species outright.
io.write("-- a Pokemon standing in the world\n")
ok(type(X.speciesOfGfx) == "function", "the mod exports speciesOfGfx")
ok(type(X.GFX_MON) == "table", "and the graphics-id -> species table it reads")
-- Reached through a local, so a revision that never gained this route reports
-- every assertion below instead of erroring out on the first call.  The point of
-- the section is to fail LOUDLY and in full against the code it replaces.
local speciesOfGfx = X.speciesOfGfx or function() return nil end
eq(speciesOfGfx(110), "SPEAROW", "graphics id 110 is a Spearow")
eq(speciesOfGfx(109), "SNORLAX", "and 109 the Snorlax asleep on Route 12")
eq(speciesOfGfx(92), nil, "while an id inside the host's own range is not a Pokemon")
eq(speciesOfGfx(151), nil, "nor is 151, which is the S.S. Anne -- a boat")
eq(speciesOfGfx(nil), nil, "and nil declines rather than erroring")

-- The host's own fallback, reproduced as the INPUT to the resolver rather than
-- as a mapping inside the stub: the object really does arrive wearing
-- SPRITE_YOUNGSTER, and it really does carry graphics id 110.
asked.trainer = {}
asked.species = {}
local spearow = X.artFor({ sprite = "SPRITE_YOUNGSTER", gfx = 110 })
ok(spearow ~= nil, "a Spearow gets a portrait where it had none")
eq(asked.species[#asked.species], 21, "the dex was asked for Spearow's own front pic")
eq(#asked.trainer, 0, "and no trainer picture was asked for at all")

-- The negative control the section needs: a REAL Youngster is unaffected.  He
-- carries no graphics id in the Pokemon range, so the sprite route is still
-- open for him and still answers the boy.
local boy = X.artFor({ sprite = "SPRITE_YOUNGSTER" })
eq(boy and boy.pic, 36, "while a real Youngster still gets the Youngster's face")
ok(spearow and boy and spearow.image ~= boy.image,
   "so a Spearow does not wear a boy's face")

-- And the end of the chain, the shape the player actually meets: the Spearow in
-- the Viridian house is an ordinary map object, so it carries class 0 and no
-- trainerType, and the press is the only thing that hands the resolver its id.
-- The text names nobody -- "Kyah!" has no colon -- so the graphics id is the
-- ONLY route that can answer, which is exactly what the fix is about.
local SPEAROW_EO = { def = { trainerType = 0 }, trainerType = 0,
                     sprite = "SPRITE_YOUNGSTER", graphicsId = 110 }
Runtime.call("world.talk", function() end, {}, SPEAROW_EO)
local mon = X.speakerFor("Kyah!")
ok(mon ~= nil, "a Pokemon's box is still a speaker")
eq(mon and mon.class, nil, "with no class, like every ordinary object")
eq(mon and mon.species, "SPEAROW", "and the press carries the species off the graphics id")
asked.species = {}
local monArt = X.artFor(mon)
ok(monArt ~= nil, "so the box gets a portrait")
eq(asked.species[#asked.species], 21, "cut from Spearow's own front pic")

-- The box that names the species as well is the same answer by a shorter route,
-- and it must not be a different one -- the two ways of learning "this is a
-- Spearow" have to agree.
local namedMon = X.speakerFor("SPEAROW: Kyah!")
eq(namedMon and namedMon.species, "SPEAROW", "a box that names the species agrees")
asked.species = {}
ok(X.artFor(namedMon) ~= nil, "and draws")
eq(asked.species[#asked.species], 21, "from the same front pic")
X.forgetSpeaker()

-- ------- 6h. 1.9.3: WHICH trainer the object is, from its own script
--
-- A graphics id is a uniform, not a person, and FRLG reuses one uniform for
-- whole families of trainers.  Measured over the whole game by
-- .probe/dp3_gfx_census.lua: 34 graphics ids are worn by trainer objects, and 16
-- of them are shared by two or more classes with DIFFERENT pictures --
-- OBJ_EVENT_GFX_SCIENTIST by eight Super Nerds AND fourteen Scientists,
-- OBJ_EVENT_GFX_ROCKER by eighteen Bird Keepers, nine Jugglers and one Rocker,
-- OBJ_EVENT_GFX_LITTLE_GIRL by every pair of Twins in the game.  For those 16 no
-- value in GFX_ART can be right, and the value that was there is the reported
-- bug: a Super Nerd wearing a Scientist's face, a pair of Twins wearing a
-- Lass's.
--
-- The fact that separates them is the trainer's own row in the cart's table, and
-- the handle for it is the object's script: a trainer's script opens with a
-- `trainerbattle` op naming him, and the engine keys a script by `scriptKey`.
-- art/trainer_ids.lua is that mapping, generated from the ROM.
--
-- The engine cannot supply it.  TrainerSight.getTrainerId digs the same op, but
-- out of the DECODED script bundle -- and .probe/dp3_bundle_vs_rom.lua measures
-- that bundle as able to answer for 15 of the game's 432 trainer objects,
-- because ExtractScripts.extractFromRom seeds only the 18 maps of island1 and
-- 559 of 1584 scripts survive the disassembly.  Every object has a scriptKey; it
-- is the bundle that does not have the script.
io.write("-- which trainer the object is, from its own script\n")

-- The table is the ROM's, so these assertions tie the SHIPPED file to the pack
-- it resolves against rather than to a second copy of the same guess: the ids
-- below are real ones the file carries, and the pack stub carries matching rows.
local TIDS = X.scriptTrainerIds
ok(type(TIDS) == "table", "the script table is loaded")
local nKeys, badKey, badVal = 0, nil, nil
for key, id in pairs(TIDS) do
  nKeys = nKeys + 1
  if type(key) ~= "string" or not key:match("^g3:%x%x%x%x%x%x%x%x$") then
    badKey = badKey or tostring(key)
  end
  if type(id) ~= "number" or id <= 0 then badVal = badVal or tostring(id) end
end
ok(badKey == nil, "every key is the engine's own script-key spelling")
ok(badVal == nil, "and every value is a real trainer id")
-- 432 on the FireRed this was generated from, and the assertion is a FLOOR
-- rather than that number because the table is data: a revision that moves the
-- addresses makes it smaller, and a smaller table is a fallback to the old
-- behaviour rather than a wrong answer.  A handful of entries would be neither.
ok(nKeys > 400, "and it covers the game's trainers, not a handful")

eq(TIDS["g3:081aa28f"], 173, "Super Nerd Leslie's script names trainer 173")
eq(TIDS["g3:081aa349"], 484, "and a pair of Twins' script names 484")
eq(TIDS["g3:081a9c81"], 258, "and a Gamer's script names 258")
eq(TIDS["g3:081a9c05"], 221, "and an Engineer's script names 221")
eq(X.picForId(173), 89, "and the cart files trainer 173 under picture 89")
eq(X.picForId(99999), nil, "an id the pack does not know answers nothing")

-- THE FIRST REPORT, and the shape of all three.  Graphic 55 is worn by Super
-- Nerds and Scientists alike, so the graphics route cannot answer and the sprite
-- route answers a Scientist -- picture 107 -- for everyone who wears it.
asked.trainer = {}
local uniform = X.artFor({ gfx = 55, sprite = "SPRITE_SCIENTIST" })
eq(asked.trainer[#asked.trainer], 107, "graphic 55 alone is a Scientist's face")
asked.trainer = {}
local leslie = X.artFor({ gfx = 55, sprite = "SPRITE_SCIENTIST",
                          scriptKey = "g3:081aa28f" })
eq(asked.trainer[#asked.trainer], 89, "but Super Nerd Leslie gets the Super Nerd")
ok(uniform and leslie and uniform.image ~= leslie.image,
   "which are two different people wearing one uniform")

-- THE SECOND: every Twins object in the game wears the LITTLE_GIRL graphic, and
-- the host calls that graphic SPRITE_LASS -- so the graphic alone answered with
-- a Lass's face, picture 84, and 18 ordinary girls wearing it did too.
-- 1.9.4 files the graphic itself, and the sprite is a twin.
asked.trainer = {}
local lassFace = X.artFor({ gfx = 17, sprite = "SPRITE_LASS" })
eq(asked.trainer[#asked.trainer], 127, "the LITTLE_GIRL graphic is a twin, not a Lass")
asked.trainer = {}
local twins = X.artFor({ gfx = 17, sprite = "SPRITE_LASS",
                         scriptKey = "g3:081aa349" })
eq(asked.trainer[#asked.trainer], 127, "and the Twins get the Twins, by either route")

-- THE THIRD: the old man.  Graphic 32 is the old man's own graphic and GFX_ART
-- now answers picture 97 for him -- but a Gamer wears the same graphic and is
-- pinned by his own row, so both halves of the report agree.
asked.trainer = {}
local gamer = X.artFor({ gfx = 32, scriptKey = "g3:081a9c81" })
eq(asked.trainer[#asked.trainer], 97, "the Gamer gets the old man the cart drew")

-- AND THE DECLINES THE ROUTE RESCUES.  Until 1.9.4 GFX_ART answered `false` for
-- graphic 30 -- a generic balding man has no battle bust, or so the reasoning
-- went -- and three Engineers wear it, so a decline there stopped the sprite
-- route too and those three had NO portrait at all.  The graphic does answer
-- now (it is the Engineer's own sprite), so the route is no longer what saves
-- them; it is still what pins each of them to his own row.
asked.trainer = {}
local baldingPlain = X.artFor({ gfx = 30, sprite = "SPRITE_POKEFAN_M" })
ok(baldingPlain ~= nil, "graphic 30 answers on its own, without the script route")
eq(asked.trainer[#asked.trainer], 93, "with the cart's own Engineer")
asked.trainer = {}
local engineer = X.artFor({ gfx = 30, sprite = "SPRITE_POKEFAN_M",
                            scriptKey = "g3:081a9c05" })
ok(engineer ~= nil, "and an Engineer wearing it gets a portrait")
eq(asked.trainer[#asked.trainer], 93, "the cart's own Engineer")

-- The ordering, and it needs a shared graphic the table DOES answer for.
-- Graphic 56 is worn by seventeen Hikers and seven Ruin Maniacs, and GFX_ART
-- answers the Hiker -- picture 90.  So the Ruin Maniac is the proof that the
-- script route is consulted BEFORE that table: if it were consulted after,
-- picture 90 would already have been returned and he would wear the Hiker's
-- face.  The route also runs AFTER a name the dialogue used and after CustomArt,
-- because those are statements about the BOX rather than about the object.
asked.trainer = {}
local hiker = X.artFor({ gfx = 56, sprite = "SPRITE_POKEFAN_M" })
eq(asked.trainer[#asked.trainer], 90, "graphic 56 alone is a Hiker, as the table says")
asked.trainer = {}
local ruin = X.artFor({ gfx = 56, sprite = "SPRITE_POKEFAN_M",
                        scriptKey = "g3:0816468d" })
eq(asked.trainer[#asked.trainer], 145,
   "but a Ruin Maniac wearing it is the Ruin Maniac, so the row is asked first")
ok(hiker and ruin and hiker.image ~= ruin.image,
   "which is a different face from the Hiker's")
asked.trainer = {}
local byName = X.artFor({ name = "LANCE", gfx = 74, scriptKey = "g3:081aa28f" })
eq(asked.trainer[#asked.trainer], 115, "a name the text used still wins outright")

-- And it must be invisible to everybody else.  An unknown key, a non-trainer
-- graphic, and a descriptor with no key at all all resolve exactly as before.
asked.trainer = {}
local unknown = X.artFor({ gfx = 32, sprite = "SPRITE_GRAMPS",
                           scriptKey = "g3:ffffffff" })
eq(asked.trainer[#asked.trainer], 97, "an unknown script key leaves the graphics route alone")
-- Graphic 25 answers for itself now (see the Man note above), and an unknown key
-- does not change that: the answer is the graphic's own, not the sprite's guess.
eq(X.artFor({ gfx = 25, sprite = "SPRITE_POKEFAN_M",
              scriptKey = "g3:ffffffff" }).pic, 103,
   "and an unknown key still leaves graphic 25 its own answer")

-- The whole chain, in the shape the game hands it over: a map object, pressed,
-- with the script key on the object rather than passed in by hand.
local LESLIE_EO = { def = { graphicsId = 55, scriptKey = "g3:081aa28f" },
                    graphicsId = 55, scriptKey = "g3:081aa28f",
                    sprite = "SPRITE_SCIENTIST" }
Runtime.call("world.talk", function() end, {}, LESLIE_EO)
local leslieSpeaker = X.speakerFor("I'm a Super Nerd!")
ok(leslieSpeaker ~= nil, "a pressed trainer is still a speaker")
eq(leslieSpeaker and leslieSpeaker.scriptKey, "g3:081aa28f",
   "and the press carries the script key off the object")
asked.trainer = {}
local leslieArt = X.artFor(leslieSpeaker)
eq(asked.trainer[#asked.trainer], 89, "so his box is cut from his own row")
X.forgetSpeaker()

-- ------- 6c. two speakers get two DIFFERENT pictures
--
-- The assertion the suite was missing, and the one that names the symptom.  "Was
-- TrainerPic.front asked for the right id?" is satisfied by a resolver that
-- answers one picture for everybody, as long as the id it asks for is right --
-- and the picture that comes back is the thing the player actually sees.
io.write("-- two speakers, two different pictures\n")
local classArt = {}
for _, class in ipairs({ 17, 43, 97 }) do
  classArt[class] = X.artFor({ class = class })
end
ok(classArt[17] and classArt[43] and classArt[97], "each class resolves")
ok(classArt[17].image ~= classArt[43].image,
   "GUITARIST and RIVAL do not share a picture")
ok(classArt[43].image ~= classArt[97].image,
   "nor do RIVAL and the professor")
ok(classArt[17].pic ~= classArt[43].pic and classArt[43].pic ~= classArt[97].pic,
   "because each resolved to its own picture id")

-- and a named speaker resolves through the name, to its own picture
local named = X.artFor(X.speakerFor("TERRY: Smell ya later!"))
ok(named ~= nil, "a named trainer resolves")
eq(named and named.pic, 106, "TERRY resolves to his own picture")
ok(named and named.image ~= classArt[17].image,
   "which is not the class-17 picture")

-- ------- 7. a trainer's own name resolves exactly
io.write("-- a trainer's name resolves to their picture\n")
eq(X.picForName("BROCK"), 17, "BROCK's picture is found by name")
eq(X.picForName("PROF. OAK"), 132, "so is the professor's, under the cart's spelling")
eq(X.picForName("prof. oak"), 132, "and the lookup is case-insensitive")
eq(X.picForName("NOBODY"), nil, "an unknown name resolves to nothing")
-- One name, two pictures: it names nobody in particular, so it must decline --
-- otherwise every Rocket grunt would wear the admin's face.
eq(X.picForName("GRUNT"), nil, "a name worn by two pictures declines")
eq(X.picForName("grunt"), nil, "and declines however it is spelled")

asked.trainer = {}
local byName = X.artFor({ name = "BROCK" })
ok(byName ~= nil, "a named trainer gets art")
eq(asked.trainer[#asked.trainer], 17, "the name route asked for BROCK's picture")

-- ------- 7b. the rival, whose name the cart never spells out
--
-- The one speaker in the game whose name is NOT in the ROM's text.  His
-- dialogue carries the FD 06 placeholder where the name belongs -- 28 sites in
-- the ROM put it immediately before the colon -- and the engine expands that to
-- whatever the player typed, so the box a mod sees reads "GARY: ..." (or
-- "BLUE: ...", or whatever), and the trainer pack has never heard of that name.
--
-- Which is why he had no portrait.  The name route resolved to nothing, and the
-- object the press had resolved -- SPRITE_BLUE, which the sprite route answers
-- perfectly well -- was discarded one line earlier.  The fix lets the object
-- ride along WITH the name, flagged, and only when the name itself cannot
-- answer.
--
-- What this section has to prove, in order: that the name really is unplaceable
-- (or the rest is testing nothing), that the flag resolves him, that a name the
-- pack DOES know still outranks the object it rode in with, that an unknown
-- name which is NOT the rival still gets nothing, and that with no name on the
-- save the whole route goes quiet -- which is what shows the resolution is
-- driven by the save and not by a hardcoded guess at "GARY".
io.write("-- the rival is named by the player, not by the cart\n")

-- Cleared first, and deliberately: most of the rival's boxes are SCRIPTED and
-- arrive with no A press behind them at all, so the press-free case below is the
-- one that matters.  Section 6d leaves a Lass on the press record, and without
-- this line the "nothing pressed" assertions would be running against a real
-- object and could pass through the sprite route instead of the rival's name --
-- which is exactly what an early run of these cases did.
X.forgetSpeaker()

ok(type(X.rivalName) == "function", "the mod exports rivalName")
ok(type(X.isRivalName) == "function", "the mod exports isRivalName")

-- With no name on the save there is no rival, and that is the honest default: a
-- fresh save has none until the player gives one.
eq(X.rivalName(), nil, "a save with no rival name names nobody")
eq(X.isRivalName("GARY"), false, "so no spelling is the rival")

-- The player types it, and it lands on the session.
session.rivalName = "GARY"
eq(X.rivalName(), "GARY", "the rival's name is read off the session")
eq(X.isRivalName("GARY"), true, "the player's own spelling is the rival")
eq(X.isRivalName("gary"), true, "and the match is case-insensitive")
eq(X.isRivalName("BLUE"), false, "a name the player did not choose is not the rival")
eq(X.isRivalName(""), false, "the empty name is nobody")
eq(X.isRivalName(nil), false, "and nil is nobody")

-- The second place the name can live.  Worth its own check because the session
-- path answers first and would hide a broken save fallback entirely.
session.rivalName = nil
sessionStub._game = { save = { rivalName = "BLUE" } }
eq(X.rivalName(), "BLUE", "with no session the name is read off the save")
eq(X.isRivalName("BLUE"), true, "and the save's spelling is recognised")
sessionStub._game = nil
session.rivalName = "GARY"

-- The premise the whole section rests on: the pack cannot place him, because it
-- lists the cart's own names and his is the player's.  If this ever stops being
-- true the fall-through below is dead code and should be deleted, not kept.
eq(X.picForName("GARY"), nil, "the trainer pack has no row for the player's name")
eq(X.artFor({ name = "GARY", fromText = true }), nil,
   "so the name alone, with nothing pressed, resolves to nothing")

-- The fix.  A box that names the rival resolves through him -- press or no
-- press, because his boxes are scripted and most of them arrive with no A press
-- behind them at all.
local rivalBox = X.speakerFor("GARY: Smell ya later!")
ok(rivalBox ~= nil, "the rival's box is still a speaker")
eq(rivalBox and rivalBox.rival, true, "and it is flagged as the rival")
asked.trainer = {}
local rivalArt = X.artFor(rivalBox)
ok(rivalArt ~= nil, "the rival gets a portrait")
eq(rivalArt and rivalArt.pic, 106, "which is RIVAL's picture, 106")
eq(asked.trainer[#asked.trainer], 106, "TrainerPic.front was asked for 106")

-- ...and the same box with the object behind it, which is how a talk begins.
-- The descriptor must still carry the object, not have swapped it for the name.
local RIVAL_EO = { def = { sprite = "SPRITE_BLUE" }, sprite = "SPRITE_BLUE" }
Runtime.call("world.talk", function() end, {}, RIVAL_EO)
local pressed = X.speakerFor("GARY: Smell ya later!")
eq(pressed and pressed.rival, true, "a pressed rival box is flagged too")
eq(pressed and pressed.object, RIVAL_EO, "and still carries the object it rode in with")
eq(X.artFor(pressed) and X.artFor(pressed).pic, 106, "and resolves to 106")

-- The text still outranks the object it rode in with.  The rival's object is
-- SPRITE_BLUE, whose sprite route answers RIVAL and therefore 106, so a box
-- naming somebody the pack knows must answer THAT person -- otherwise every
-- hand-off between two characters would wear the rival's face.
local namedOver = X.speakerFor("BROCK: I am Brock!")
eq(namedOver and namedOver.rival, false, "Brock's box is not the rival's")
eq(X.artFor(namedOver) and X.artFor(namedOver).pic, 17,
   "and the pack's own name wins over the rival's object")

-- The negative control the fix needs.  Without this, "any name I cannot place
-- gets a face" would pass everything above while inventing portraits for every
-- typo in the game -- and for the player's own name, which the ROM also writes
-- as a placeholder (FD 01, 36 sites).
X.forgetSpeaker()
eq(X.artFor(X.speakerFor("SOMEONE: ...")), nil,
   "a name the pack cannot place and that is not the rival gets nothing")
Runtime.call("world.talk", function() end, {}, RIVAL_EO)
local unknownOverRival = X.artFor(X.speakerFor("SOMEONE: ..."))
eq(unknownOverRival and unknownOverRival.pic, 106,
   "while the same unknown name over the rival's object falls through to him")

-- And with the name gone from the save the flag cannot fire: the route is
-- driven by the save, not by a guess at the name the cart happens to use in
-- its own text.  This is the assertion that would fail if someone "fixed" the
-- rival by adding GARY to the mod's name table.
X.forgetSpeaker()
session.rivalName = nil
eq(X.rivalName(), nil, "the name is gone from the save")
local orphan = X.speakerFor("GARY: Smell ya later!")
eq(orphan and orphan.rival, false, "so the box is not flagged as the rival")
eq(X.artFor(orphan), nil, "and it gets nothing -- the flag was the whole answer")
session.rivalName = "GARY"

-- ------- 8. CustomArt wins over every ROM route
io.write("-- the player's own art wins\n")
customFiles["CustomArt/PIKACHU.png"] = true
local own = X.artFor({ name = "PIKACHU", species = "PIKACHU" })
ok(own ~= nil and own.custom == true, "CustomArt/ beats the dex route")
local before = #asked.species
customFiles["CustomArt/OAK.png"] = true
local own2 = X.artFor({ name = "OAK", class = 17 })
ok(own2 ~= nil and own2.custom == true, "CustomArt/ beats the class route")
eq(#asked.species, before, "and the dex was not consulted at all")

-- The class's own name is the third key, so one file faces a whole class.
-- Worth its own check because a nameless speaker leaves a hole at index 1 of
-- the key list, and a hole is exactly what an ipairs-based loop stops on.
io.write("-- one file can face a whole class\n")
customFiles["CustomArt/OAK.png"] = nil
customFiles["CustomArt/TEAM ROCKET.png"] = true
local byClassFile = X.artFor({ class = 85, sprite = "SPRITE_YOUNGSTER" })
ok(byClassFile ~= nil and byClassFile.custom == true,
  "a class-named file is found for a speaker with no name and no sprite key")
customFiles["CustomArt/TEAM ROCKET.png"] = nil

-- ...and the sprite key is still reached when only the NAME is absent
customFiles["CustomArt/SPRITE_NURSE.png"] = true
local bySpriteFile = X.artFor({ class = 85, sprite = "SPRITE_NURSE" })
ok(bySpriteFile ~= nil and bySpriteFile.custom == true,
  "the sprite key is reached past a missing name")
customFiles["CustomArt/SPRITE_NURSE.png"] = nil

-- ------- 9. a trainer class with no art answers nil rather than a wrong picture
io.write("-- no art is better than the wrong art\n")
customFiles["CustomArt/OAK.png"] = nil
eq(X.artFor({ class = 999 }), nil, "a class whose pic is unavailable answers nil")
eq(X.artFor({}), nil, "an empty descriptor answers nil")
eq(X.artFor(nil), nil, "a nil descriptor answers nil")

-- ------- 10. the press record has an end
io.write("-- a conversation ends\n")
X.forgetSpeaker()
eq(X.speakerFor("Pika pika!"), nil, "after teardown a box names nobody")
Runtime.call("world.talk", function() end, {}, PIKACHU_EO)
ok(X.speakerFor("Pika pika!") ~= nil, "and a fresh press names somebody again")
Runtime.emit("world.stepped", {})
eq(X.speakerFor("Pika pika!"), nil, "a player step ends the conversation")
Runtime.call("world.talk", function() end, {}, PIKACHU_EO)
Runtime.emit("map.entered", {})
eq(X.speakerFor("Pika pika!"), nil, "leaving the map ends the conversation")

-- The third way out, and the one a step and a warp both miss: turning on the
-- spot.  A turn never moves the player, so it never reaches Player.finishStep,
-- which is the only place world.stepped is emitted (src/core/game3/player.lua
-- :653, reached only at :799) -- so a player who talked to somebody and then
-- turned to read the sign beside them still had the last speaker on record.
-- The engine's own end-of-conversation seam is script.ended, and the press
-- starts a script run: that run finishing IS the conversation being over.
io.write("-- the script's own end\n")
Runtime.call("world.talk", function() end, {}, PIKACHU_EO)
ok(X.speakerFor("Pika pika!") ~= nil, "a press is on record")

-- A script that hands off to another retires itself first with
-- completed = false (src/core/game3/scripting/vm.lua:95, where Vm:start ends
-- the script it supersedes).  That is the SAME conversation continuing, so
-- clearing here would drop the portrait from every box the second half shows.
Runtime.emit("script.ended", { completed = false })
ok(X.speakerFor("Pika pika!") ~= nil,
   "a hand-off (completed = false) keeps the speaker -- the conversation goes on")

Runtime.emit("script.ended", { completed = true })
eq(X.speakerFor("Pika pika!"), nil, "a finished script ends the conversation")

-- The rule, not the shape: only completed == false keeps the record.  The Gen 3
-- emitter always sends a real boolean (vm.lua:58, `completed and true or false`),
-- so a payload without a verdict is the one case the guard decides -- and it
-- decides "over", which is the direction that cannot leave a portrait on a box
-- nobody is behind.
Runtime.call("world.talk", function() end, {}, PIKACHU_EO)
Runtime.emit("script.ended", {})
eq(X.speakerFor("Pika pika!"), nil, "a payload with no verdict counts as finished")

-- and the record is not burned: the next press resolves again
Runtime.call("world.talk", function() end, {}, PIKACHU_EO)
ok(X.speakerFor("Pika pika!") ~= nil, "a fresh press after a script ends works")
X.forgetSpeaker()
eq(X.speakerFor("Pika pika!"), nil, "and forgetSpeaker still clears it outright")

-- ------- 11. what this release adds
--
-- In a function of its own for the same reason the geometry suite does it: this
-- chunk is compiled as ONE Lua function and LuaJIT caps that at 200 locals.
local function releaseTests()
  -- ------- the crop table's key for a species
  --
  -- The crop table's `pokemon` keys are the engine's own `keyName` lowercased
  -- with the separators stripped, which is NOT the cart's display name for four
  -- of its 386 species: NIDORAN_F is "nidoranf", HO_OH is "hooh" and MR_MIME is
  -- "mrmime".  Until this release the key was the display name lowercased, so an
  -- entry filed for any of those four could never fire -- and two of the four
  -- (the Nidoran) are among the 19 species that speak in FireRed.
  --
  -- The mod asks the ENGINE for the fold rather than carrying a second copy of
  -- norm_key, so the assertions below are as much about WHO answered as about
  -- the answer: `asked.speciesFromName` is the record of the question.
  io.write("-- the crop table's key for a species\n")
  ok(type(X.speciesKey) == "function", "the mod exports speciesKey")
  eq(X.speciesKey("PIKACHU"), "pikachu", "a plain name lowercases")
  eq(X.speciesKey("NIDORAN♀"), "nidoranf",
    "the female sign folds to the engine's key, not to a bare nidoran")
  eq(asked.speciesFromName[#asked.speciesFromName], "NIDORAN♀",
    "the engine's own dex was asked, for the cart's own spelling")
  eq(asked.keyName[#asked.keyName], 29,
    "and answered with a species id the mod then folded")
  eq(X.speciesKey("NIDORAN♂"), "nidoranm", "and the male sign")
  eq(X.speciesKey("MR. MIME"), "mrmime", "a space and a full stop come off")
  eq(X.speciesKey("FARFETCH'D"), "farfetchd", "and an apostrophe")
  eq(X.speciesKey("HO-OH"), "hooh", "and a hyphen")
  eq(X.speciesKey(nil), nil, "a non-string declines")
  eq(X.speciesKey(""), nil, "and an empty string is not a species")
  eq(X.speciesKey("RATTATA"), "rattata",
    "a species the dex cannot place still folds, off its display name")

  -- The fold has to hold up WITHOUT a dex behind it, too.  `speciesFromName`
  -- declines whenever `Pokemon._byName` is empty -- a checkout that never
  -- imported a ROM -- and then a plain lowercase-and-strip loses the one thing
  -- that matters: BOTH gender signs vanish, so the two Nidoran collapse onto a
  -- single key ("nidoran") and a filed nidoranf / nidoranm entry could never
  -- fire.  That is the same unreachable-entry bug reached from the other side,
  -- so the fallback folds the signs itself and this is the assertion that says
  -- it does.  The stubs are put back straight afterwards, because every later
  -- block in this file resolves species through the dex.
  local dex = package.loaded["src.core.game3.pokemon"]
  local hadFromName, hadKeyName = dex.speciesFromName, dex.keyName
  dex.speciesFromName = function() return nil end
  dex.keyName = function() return nil end
  eq(X.speciesKey("NIDORAN♀"), "nidoranf",
    "with no dex to ask, the female sign still folds to the key's letter")
  eq(X.speciesKey("NIDORAN♂"), "nidoranm",
    "and the male sign folds apart from it")
  eq(X.speciesKey("MR. MIME"), "mrmime",
    "and a space and a full stop still come off")
  eq(X.speciesKey("HO-OH"), "hooh", "and a hyphen")
  dex.speciesFromName, dex.keyName = hadFromName, hadKeyName
  eq(X.speciesKey("NIDORAN♀"), "nidoranf",
    "and the dex-backed fold answers the same thing when it is put back")

  -- ------- the trainer who challenges you
  --
  -- A trainer with a line of sight does not wait for an A press: the engine
  -- starts their script from a step (src/core/game3/trainer_sight.lua,
  -- TrainerSight.engage), and that path raises no world.talk -- so
  -- pressSpeaker stayed nil, speakerFor had nothing to answer with, and the
  -- "wants to battle" box came out bare.  That is the reported bug.
  --
  -- The engine names the object for exactly this case: engage() emits
  -- world.trainer_engaged with the trainer's own event object, so recording it
  -- is the same act as recording a press -- and every existing way of ending a
  -- conversation still drops it again.
  io.write("-- the trainer who challenges you\n")
  X.forgetSpeaker()
  eq(X.speakerFor("I like shorts!"), nil,
    "with nothing on record, a sight-challenge box names nobody")
  Runtime.emit("world.trainer_engaged", {
    npc = { trainerType = 27, sprite = "SPRITE_FISHER" },
    trainerClass = 27, trainerId = 12,
  })
  local sight = X.speakerFor("I like shorts!  They're comfy and easy to wear!")
  ok(sight ~= nil, "a trainer who engages the player names somebody")
  eq(sight and sight.class, 27, "and it is the trainer the engine named")
  -- The engine hands over the trainer's ID as well as his class --
  -- trainer_sight.lua:258 emits `trainerId = tid` -- and an id is EXACT where a
  -- class is only a kind, so the id is what answers when both are present.
  -- (This fixture's id 12 is a LEADER, picture 26; its class 27 is the
  -- Fisherman, picture 67, and that is the answer the class route gives when
  -- there is no id -- which the next block checks.)
  asked.trainer = {}
  local sightArt = X.artFor(sight)
  ok(sightArt ~= nil, "so the challenge box gets a portrait at all")
  eq(asked.trainer[#asked.trainer], 26,
    "cut from the id's own picture, because an id outranks a class")

  -- and the record still has an end, like every other way a box gets its speaker
  Runtime.emit("world.stepped", {})
  eq(X.speakerFor("I like shorts!"), nil, "and stepping away still clears it")

  -- The class in the payload is a fallback for an object whose own trainerType
  -- has not been stamped yet, and a mod must not write on the world's object.
  io.write("-- the challenger's object is not scribbled on\n")
  local npc = { sprite = "SPRITE_LASS" }
  Runtime.emit("world.trainer_engaged", { npc = npc, trainerClass = 49 })
  eq(npc.trainerType, nil, "the engine's own object is left exactly as it was")
  local viaPayload = X.speakerFor("Hi! Let's battle!")
  eq(viaPayload and viaPayload.class, 49,
    "and the payload's class is what answered the box")
  ok(X.artFor(viaPayload) ~= nil, "which draws")
  -- 65, because 49 is a class ID handed over directly -- the ambiguity the fix
  -- is about lives in the NAME "LASS", and no name is consulted here.  The
  -- picture a class 49 answers is its own, and always was.
  eq(asked.trainer[#asked.trainer], 65, "cut from that class's own picture")

  -- And the Fisherman's class answers HIS picture when no id rides along, which
  -- is the fallback the block above handed over to: class 27 is picture 67, and
  -- the id 12 that outranked it in the previous block is a different man.
  X.forgetSpeaker()
  Runtime.emit("world.trainer_engaged",
    { npc = { sprite = "SPRITE_FISHER" }, trainerClass = 27 })
  local byClass = X.speakerFor("I like shorts!")
  eq(byClass and byClass.class, 27, "a payload with a class and no id")
  asked.trainer = {}
  ok(X.artFor(byClass) ~= nil, "still draws")
  eq(asked.trainer[#asked.trainer], 67,
    "and lands on the class's picture, which is what an id would have outranked")

  -- A payload that names no object must not invent a speaker -- and must not
  -- erase a live one either: an unrelated event firing mid-conversation is not
  -- a reason to drop the portrait off the box the player is reading.
  X.forgetSpeaker()
  Runtime.emit("world.trainer_engaged", {})
  eq(X.speakerFor("Anything at all!"), nil,
    "an engagement with no object names nobody")
  Runtime.emit("world.trainer_engaged", { npc = { trainerType = 27 } })
  ok(X.speakerFor("Go, Pikachu!") ~= nil, "and a real one names somebody again")
  Runtime.emit("world.trainer_engaged", {})
  ok(X.speakerFor("Go, Pikachu!") ~= nil,
    "which a malformed payload leaves on record rather than clearing")
end
releaseTests()

-- ------- 12. 1.9.4: ONE SPRITE, SEVERAL PEOPLE
--
-- The second report's key finding, measured rather than assumed: an FRLG
-- graphics id is a UNIFORM, and one uniform is worn by several kinds of trainer
-- who each have their own battle art.  Graphic 26 -- the yellow-haired sprite
-- -- is worn by eighteen Bird Keepers, nine Jugglers and exactly one Rocker;
-- graphic 17 by every pair of Twins in the game; graphic 30 by the three
-- Engineers and by nobody else.  For the trainers on a shared uniform no single
-- value in GFX_ART can be right, so they are answered by their own ids (the
-- script route, section 6h) and GFX_ART carries the answer for the NON-trainers
-- on the same uniform -- one consistent picture per sprite, which is what the
-- report asks for and what the four cases below pin.
--
-- The last block is the guard the Fat Man needed, which is the same defect one
-- step along: a name in a box cannot conjure a bust the cart never drew.
local function oneSpriteManyPeople()
  io.write("-- one sprite, several people\n")

  -- (1) THE YELLOW-HAIRED SPRITE.  The report's own example: "sometimes shows
  -- the Rocker portrait and sometimes the Bird Keeper portrait".  Both are
  -- right -- for different people -- and the graphic is what told them apart
  -- wrongly, because it is a uniform and not a person.
  eq(X.GFX_ART[26], 104,
     "graphic 26 -- the yellow-haired sprite -- answers the Bird Keeper")
  eq(X.artFor({ sprite = "SPRITE_ROCKER" }).pic, 101,
     "while the SPRITE route alone still answers the Rocker, which is the report")
  eq(X.artFor({ gfx = 26, sprite = "SPRITE_ROCKER" }).pic, 104,
     "so a non-trainer on that graphic gets the majority wearer's face")
  local bk = X.artFor({ gfx = 26, sprite = "SPRITE_ROCKER", scriptKey = "g3:081aa749" })
  local jg = X.artFor({ gfx = 26, sprite = "SPRITE_ROCKER", scriptKey = "g3:08161065" })
  local rk = X.artFor({ gfx = 26, sprite = "SPRITE_ROCKER", scriptKey = "g3:081aa587" })
  eq(bk and bk.pic, 104, "the Bird Keeper's own script answers the Bird Keeper")
  eq(jg and jg.pic, 102, "a Juggler's answers the Juggler")
  eq(rk and rk.pic, 101, "and the Rocker's answers the Rocker")
  ok(bk and jg and rk and bk.image ~= jg.image and jg.image ~= rk.image
     and bk.image ~= rk.image,
     "three people, three pictures, one uniform")

  -- (2) THE RED-HAIRED LITTLE GIRL.  She is one of the Twins, and the host
  -- calls her graphic SPRITE_LASS -- so every ordinary girl on it wore the
  -- Lass's face.  One value serves the Twins AND the ordinary girls, because
  -- both halves of picture 127 are the same girl (see the pair block below).
  eq(X.GFX_ART[17], 127,
     "graphic 17 -- the red-haired girl -- answers the Twins")
  eq(X.artFor({ gfx = 17, sprite = "SPRITE_LASS" }).pic, 127,
     "so an ordinary girl on it is a Twin, not the Lass the sprite route answered")
  eq(X.artFor({ gfx = 17, sprite = "SPRITE_LASS", scriptKey = "g3:081aa349" }).pic, 127,
     "and the Twins' own row agrees, which is why one value can serve both")

  -- (3) THE BALDING MAN, who used to decline.  1.9.3 filed him with the Man,
  -- on the reasoning that both share SPRITE_POKEFAN_M and so both wore the
  -- PokéFan's boy's face -- but the cart HAS drawn this person: he is the
  -- Engineer, and every Engineer object in the game wears this sprite.
  eq(X.GFX_ART[30], 93,
     "graphic 30 -- the balding man -- answers the Engineer")
  eq(X.artFor({ gfx = 30, sprite = "SPRITE_POKEFAN_M" }).pic, 93,
     "so the 28 ordinary balding men get the face the cart drew for this person")
  eq(X.artFor({ gfx = 30, sprite = "SPRITE_POKEFAN_M",
                scriptKey = "g3:081a9c05" }).pic, 93,
     "and Braxton's own row agrees")

  -- (4) THE YOUNG COUPLE: one picture, two bodies, two windows.  Both objects
  -- carry trainer id 486, so both resolve to picture 129 -- the cart's single
  -- drawing of a Young Couple, two people side by side -- and the only fact
  -- that says which half is standing there is the graphic.  The two keys below
  -- are two REAL scripts naming that one id, which is how the cart hands a
  -- couple to the player: one trainer, two bodies.
  local KEY_WOMAN, KEY_MAN = "g3:081aa603", "g3:081aa649"
  local woman = X.artFor({ gfx = 29, sprite = "SPRITE_BEAUTY", scriptKey = KEY_WOMAN })
  local man = X.artFor({ gfx = 25, sprite = "SPRITE_MAN", scriptKey = KEY_MAN })
  eq(woman and woman.pic, 129,
     "the woman in a Young Couple resolves to the pair's picture")
  eq(man and man.pic, 129, "and so does the man")
  eq(woman and woman.image, man and man.image,
     "which is ONE picture for both of them")
  -- And the CUT differs, which is the thing the player sees: portraitFor is
  -- the whole path from a speaker to a quad, so this is the end-to-end check
  -- rather than a reimplementation of the chooser.
  local womanCut = X.portraitFor({ gfx = 29, sprite = "SPRITE_BEAUTY", scriptKey = KEY_WOMAN })
  local manCut = X.portraitFor({ gfx = 25, sprite = "SPRITE_MAN", scriptKey = KEY_MAN })
  ok(womanCut and manCut and womanCut.quad and manCut.quad,
     "both halves are cut from a real picture")
  ok(womanCut and manCut and womanCut.quad.x ~= manCut.quad.x,
     "cut with two different windows, so each is framed on his or her own half")
  eq(womanCut and womanCut.quad.x, 0, "the woman's window starts at the left edge")
  eq(manCut and manCut.quad.x, 32, "and the man's at the middle")
  ok(womanCut and manCut and womanCut.image == manCut.image,
     "while both are the same picture -- one drawing, two people")
  -- The Twins are the other shape: both bodies are the SAME girl, so one
  -- rectangle answers for both -- and for the LITTLE_GIRL sprite that wears her.
  -- And it starts at 2, not 0: her head runs to column 33 and her sister's
  -- begins at 35, so a window at 0 stops at 31 and cuts two columns off her
  -- face.  The number matters here more than the shape does.
  eq(X.rectFor("trainers", "127", { gfx = 17 }).x, 2,
     "while the Twins share one window, because both halves are one girl")
  eq(X.rectFor("trainers", "127", { gfx = 17 }).size, 32,
     "at the ordinary size, so the twin is not zoomed against the other faces")

  -- A graphic that is NOT half of a pair must be left exactly as it was.  This
  -- is the reason the halves live in their own table and not as `gfx:` entries
  -- in `speakers`: graphic 29 is the woman in a Young Couple AND every ordinary
  -- Beauty, who wears picture 98 and is not half of anything.
  local plainBeauty = X.rectFor("trainers", "98", { gfx = 29 })
  local beautyNoGfx = X.rectFor("trainers", "98", {})
  eq(plainBeauty.x, beautyNoGfx.x,
     "an ordinary Beauty is not cut with half of picture 129")
  eq(plainBeauty.y, beautyNoGfx.y, "on either axis")

  -- (5) A NAME CANNOT CONJURE A BUST THE CART NEVER DREW.
  --
  -- The name route reads a "NAME:" token out of the box and looks it up in the
  -- pack -- right when the speaker IS that trainer, wrong when the name only
  -- belongs to somebody else who happens to share it.  Fuchsia City's fat man
  -- says "ERIK: Where's SARA?" and the pack has a real ERIK, a Super Nerd whose
  -- picture 89 is a man in a white lab coat -- the "Scientist portrait" the
  -- report named.  Daisy Oak is the second instance, found by sweeping rather
  -- than by being reported: she says "DAISY:", and the pack's DAISY is a
  -- Painter on Five Island wearing picture 147.
  --
  -- A `false` entry is the cart's own statement that this graphic's person has
  -- no battle bust, so a token in their dialogue cannot make one exist.
  --
  -- The example is the female Worker, not graphic 27: 1.2.3 gives the Fat Man
  -- the Collector's bust out of rom_sprites, so his graphic no longer declines
  -- and his own boxes resolve through it.
  eq(X.GFX_ART[48], false,
     "graphic 48 -- the female Worker -- is one the cart declined")
  eq(X.picForName("ERIK"), 89, "and the pack really does know an ERIK")
  eq(X.artFor({ gfx = 48, sprite = "SPRITE_SCIENTIST",
                name = "ERIK", fromText = true }), nil,
     "but a declined graphic cannot be overruled by a name in the box")
  eq(X.GFX_ART[76], false,
     "graphic 76 -- Daisy, the rival's sister -- likewise")
  eq(X.picForName("DAISY"), 147, "and the pack really does know a DAISY")
  -- Daisy is the one name in this block that DOES have art, because the cart
  -- drew her -- just not in its battle art.  She rides the Fame Checker route
  -- (section 14), which is asked before this pack-name route precisely so the
  -- Painter 147 above never wins.
  eq(X.artFor({ gfx = 76, sprite = "SPRITE_MOM",
                name = "DAISY", fromText = true }).pic, 301,
     "but Daisy Oak is not the Painter: she gets the cart's Fame Checker art")

  -- The two the guard must NOT close, and the reason it is a guard and not a
  -- ban: here the speaker IS the trainer the text names.  Selphy's is the
  -- stronger case of the two, because her graphic has no entry at all -- the
  -- name route is the ONLY thing that gives her a face.
  eq(X.artFor({ gfx = 77, sprite = "SPRITE_LORELEI",
                name = "LORELEI", fromText = true }).pic, 112,
     "Lorelei IS Lorelei, and keeps her face")
  eq(X.artFor({ gfx = 28, sprite = "SPRITE_WOMAN",
                name = "SELPHY", fromText = true }).pic, 146,
     "and so does Selphy, whose graphic has no entry at all")

  -- The boundary, pinned rather than left implicit: the guard closes a graphic
  -- that DECLINED and nothing else, so a name still beats a graphic that
  -- ANSWERS.  That is deliberate -- a single running script hands ONE object to
  -- its whole run while the dialogue inside can hand off between two characters
  -- box by box, and that hand-off is the name route's reason for existing.
  --
  -- The measurement that makes leaving it open safe is
  -- .probe/dp3_name_hijack.lua: over all 1648 objects and every line of each,
  -- the name route never once disagrees with the graphic it rides on (0 cases)
  -- and never once disagrees with a trainer's own id (0 cases).  So the open
  -- boundary is never crossed in the shipped game.
  eq(X.artFor({ gfx = 32, sprite = "SPRITE_GRAMPS",
                name = "ERIK", fromText = true }).pic, 89,
     "a graphic that ANSWERS still lets the name through -- the guard's boundary")
end
oneSpriteManyPeople()

-- ------- 13. 1.9.5: WHERE the graphic is standing
--
-- The reported rule, and the release's second answer to "one sprite, several
-- people".  A graphic is a uniform: OBJ_EVENT_GFX_ROCKER -- the yellow-haired
-- figure -- is worn by eighteen Bird Keepers, nine Jugglers and exactly one
-- Rocker, and no single value in GFX_ART can be right for all of them.  A
-- trainer is named by his own script and gets his own picture, but the table
-- the id route reads is a GENERATED cache, and when it is not there yet every
-- trainer falls past the id route onto the graphics table.  That is the report:
-- a Super Nerd wearing the Scientist's 107, a Juggler wearing the Bird Keeper's
-- 104, an Aroma Lady wearing nothing at all.
--
-- art/map_art.lua answers it from the map, because the map decides which class
-- is standing here.  It is generated by .probe/dp3_emit_map_art.lua and keyed
-- by the engine's own map id (MapCatalog.pretToEngine, the FR_* spelling that
-- Map.current carries).
local function mapRouteTests()
  io.write("-- where the graphic is standing\n")

  -- The table itself, read from the shipped file: one graphic, one answer PER
  -- MAP.  Asserted by number, because the whole claim is that the answers
  -- DIFFER -- a table whose every map held 104 would satisfy "the route
  -- answers" and be useless.
  local MAP = X.MAP_ART
  ok(type(MAP) == "table", "the location table is loaded from art/map_art.lua")
  eq(MAP["FR_ROUTE_8"] and MAP["FR_ROUTE_8"][55], 89,
     "graphic 55 on Route 8 is the SUPER NERD's picture")
  eq(MAP["FR_SILPH_CO_2F"] and MAP["FR_SILPH_CO_2F"][55], 107,
     "and the same graphic in Silph Co. is the SCIENTIST's")
  eq(MAP["FR_FUCHSIA_CITY_GYM"] and MAP["FR_FUCHSIA_CITY_GYM"][26], 102,
     "graphic 26 in Fuchsia Gym is the JUGGLER")
  eq(MAP["FR_ROUTE_13"] and MAP["FR_ROUTE_13"][26], 104,
     "on Route 13 the Bird Keeper")
  eq(MAP["FR_ROUTE_12"] and MAP["FR_ROUTE_12"][26], 101,
     "and on Route 12 the Rocker, the only one of the three who wears it")
  eq(MAP["FR_THREE_ISLAND_BOND_BRIDGE"]
       and MAP["FR_THREE_ISLAND_BOND_BRIDGE"][28], 144,
     "graphic 28 on Bond Bridge is the AROMA LADY -- the reported 'no portrait'")
  eq(MAP["FR_SIX_ISLAND_PATTERN_BUSH"]
       and MAP["FR_SIX_ISLAND_PATTERN_BUSH"][28], 141,
     "and on Pattern Bush the BREEDER")

  -- Through artFor, which is the route a portrait actually takes.  Each of the
  -- three reported classes, answered from the map alone -- no id, no key.
  local function here(gfx, mapId)
    local a = X.artFor({ gfx = gfx, sprite = "SPRITE_ROCKER", mapId = mapId })
    return a and a.pic
  end
  eq(here(26, "FR_FUCHSIA_CITY_GYM"), 102,
     "a Juggler's sprite resolves to the Juggler when the map says so")
  eq(here(26, "FR_ROUTE_13"), 104, "and to the Bird Keeper on Route 13")
  eq(here(26, "FR_ROUTE_12"), 101, "and to the Rocker on Route 12")
  eq(here(55, "FR_ROUTE_8"), 89, "a Super Nerd's sprite to the Super Nerd")
  eq(here(55, "FR_SILPH_CO_2F"), 107, "and to the Scientist where a Scientist stands")
  eq(here(28, "FR_THREE_ISLAND_BOND_BRIDGE"), 144,
     "and the Aroma Lady's sprite to the Aroma Lady, who had no face at all")

  -- The map is a fact about WHERE, and an unknown map is not a licence to guess
  -- a different one: a graphic on a map the table does not carry falls through
  -- to the graphics table exactly as before.
  eq(here(55, "FR_NOWHERE_AT_ALL"), X.GFX_ART[55],
     "a map the table does not carry changes nothing")

  -- The id still outranks the map, and that ordering is measured rather than
  -- assumed: .probe/dp3_map_route_yield.lua finds 17 of the 432 trainer objects
  -- where the two disagree -- a Route 16 Biker standing among Hikers (id 96
  -- against the map's 91), a Kindle Road Cooltrainer among Black Belts -- and
  -- there the cart named that man himself, so the id is the one to believe.
  -- The numbers here are this fixture's own: id 16 is picture 67, and graphic
  -- 55 on Route 8 is 89, so the two answers really are different.
  asked.trainer = {}
  local byId = X.artFor({ gfx = 55, sprite = "SPRITE_SCIENTIST", trainerId = 16 })
  eq(byId and byId.pic, 67,
     "a trainer the cart named keeps his own face even where the map disagrees")
  eq(here(55, "FR_ROUTE_8"), 89,
     "while the same graphic with no id takes the map's answer")

  -- A species is not a person, so the map is not asked about it.  The guard is
  -- visible because graphic 26 IS one the map answers for: if the location route
  -- ran on this descriptor it would return 102, and 104 -- the graphics table's
  -- value -- is what it actually gets.
  local mon = X.artFor({ gfx = 26, species = "PIKACHU",
                         mapId = "FR_FUCHSIA_CITY_GYM" })
  eq(mon and mon.pic, 104,
     "a Pokemon is not asked about the map -- the location route is guarded off")

  -- and the real shape of a Pokemon object: no species is named in the text, so
  -- the graphics id names it, and the map still says nothing.
  asked.species = {}
  local wild = X.artFor({ gfx = 110, sprite = "SPRITE_YOUNGSTER",
                          mapId = "FR_ROUTE_12" })
  ok(wild ~= nil, "a Pokemon standing in the world still gets its own art")
  eq(asked.species[#asked.species], 21, "from the dex, by its graphics id")

  -- And the map really does reach speakerFor, which is the only place it can
  -- come from: Map.current is read through map.entered, so the box drawn on
  -- Route 8 carries Route 8's answer.
  io.write("-- the map reaches the speaker\n")
  Runtime.emit("map.entered", { mapId = "FR_ROUTE_8" })
  eq(X.mapIdNow(), "FR_ROUTE_8", "the map the player is on is tracked")
  X.forgetSpeaker()
  Runtime.call("world.talk", function() end, {},
    { def = { graphicsId = 55 }, graphicsId = 55, sprite = "SPRITE_SCIENTIST" })
  local sp = X.speakerFor("A box from somebody standing on Route 8.")
  ok(sp ~= nil, "an object with a graphic names a speaker")
  eq(sp and sp.mapId, "FR_ROUTE_8", "and the speaker carries the map it stood on")
  asked.trainer = {}
  local art = X.artFor(sp)
  eq(art and art.pic, 89,
     "so the box gets the Super Nerd, whom the map says is standing there")
  -- The memoisation, which is the other half of the report and the reason the
  -- fallback was ever reached.  `picForId` reads the cart's GENERATED trainer
  -- table, and the old shape cached the EMPTY index BEFORE asking -- so one ask
  -- that arrived before the table existed froze every trainer onto his
  -- graphic's face for the rest of the session, which is precisely the report
  -- (the Super Nerds on 107, the Jugglers on 104, the Aroma Ladies on nothing).
  --
  -- It can only be reproduced the way it happened, so this is a SECOND mod
  -- instance: loaded with the pack absent, then asked again once it appears.
  -- The facade is built with no-op hooks and events on purpose -- this instance
  -- must not register anything on the shared Runtime that the suite's own mod
  -- is already using.
  io.write("-- an empty pack answer is not remembered\n")
  local Trainers = package.loaded["src.core.game3.scripting.trainers"]
  local realPack = Trainers.pack
  local absent = true
  Trainers.pack = function()
    if absent then return nil end
    return realPack()
  end
  local fresh = { path = MOD_ROOT, exports = {}, generation = 3 }
  fresh.log = { info = function() end, warn = function() end, error = function() end }
  fresh.options = mod.options
  fresh.read = mod.read
  fresh.content = mod.content
  fresh.assets = mod.assets
  fresh.hooks = { wrap = function() end }
  fresh.events = { on = function() end }
  -- The install guard, and why this test has to step around it.
  --
  -- The mod installs ONCE, and the sentinel it installs against is on the
  -- ENGINE's Message module -- which the suite's own instance has already set.
  -- So a second instance returns from the install before it reaches its own
  -- exports, and a test that did not know that would read an empty table and
  -- blame the mod.  That is the guard doing its job, not a fault.
  --
  -- A real fresh boot has no sentinel, so this clears it (and the option-row
  -- one) for the duration, then puts back every engine function the instance
  -- replaces.  It must leave no trace: the suite's own mod has to still be the
  -- one installed when the file ends.
  local Message    = require("src.ui.game3.message")
  local FrlgFont   = require("src.ui.game3.frlg_font")
  local OptionRows = require("src.ui.game3.option_rows")
  local saved = {
    wrapped     = Message.dp3_wrapped,
    show        = Message.show,
    draw        = Message.draw,
    fontDraw    = FrlgFont.draw,
    rowsWrapped = OptionRows.dp3_build_wrapped,
    rowsBuild   = OptionRows.build,
  }
  Message.dp3_wrapped = nil
  OptionRows.dp3_build_wrapped = nil

  local boot = assert(loadfile(MOD_ROOT .. "/main.lua"))
  local booted = boot(fresh)
  if type(booted) == "function" then booted(fresh) end
  ok(type(fresh.exports.picForId) == "function",
     "a fresh instance does export its surface -- the sentinel is not hiding it")
  eq(fresh.exports.picForId(11), nil,
     "with the trainer table absent, the id route has nothing to answer with")
  eq(fresh.exports.artFor({ gfx = 55, sprite = "SPRITE_SCIENTIST" }).pic,
     X.GFX_ART[55],
     "so the lab coat falls to the graphics table -- one face for the graphic")
  absent = false
  eq(fresh.exports.picForId(11), 65,
     "and the SAME instance answers once the table appears: the empty index was not cached")
  Trainers.pack = realPack
  -- Put the engine back exactly as it was, sentinels included: this instance
  -- was only ever a way to hold a second `packIndex`, and the suite's own mod
  -- must still be the one that is installed.
  Message.dp3_wrapped, OptionRows.dp3_build_wrapped = saved.wrapped, saved.rowsWrapped
  Message.show, Message.draw, FrlgFont.draw = saved.show, saved.draw, saved.fontDraw
  OptionRows.build = saved.rowsBuild
  -- The suite's own instance is untouched: it was built when the pack was there
  -- and its index was real, so the reported classes still resolve exactly.
  eq(X.picForId(11), 65, "and the suite's own mod still answers from the pack")
  eq(Message.dp3_wrapped, saved.wrapped,
     "and the engine module is back exactly as the test found it")
end
mapRouteTests()

-- ------- 14. THE CART'S OWN FAME CHECKER PORTRAITS
--
-- The reporter asks for three characters by name -- Bill, Daisy and Mr. Fuji --
-- and says each must have a portrait, including when the NPC starts the
-- interaction.  None of the three has a battle class, so the class and sprite
-- routes cannot answer for them; the cart drew them in its FAME CHECKER
-- instead, and that is where their art comes from.  The route must ask the
-- Fame Checker for the right PERSON, and the synthetic picture ids must be the
-- ones art/crops.lua files windows against.
local function fameTests()
  io.write("-- the cart's own Fame Checker portraits\n")

  eq(X.FAME_PERSON.BILL, 13, "Bill is Fame Checker person 13")
  eq(X.FAME_PERSON.DAISY, 1, "Daisy is person 1")
  eq(X.FAME_PERSON.MRFUJI, 14, "Mr. Fuji is person 14")

  fameAsked = {}
  local bill = X.artFor({ name = "BILL", fromText = true })
  ok(bill ~= nil, "Bill gets a portrait")
  eq(bill and bill.pic, 313, "cut from the synthetic Bill picture key")
  eq(fameAsked[#fameAsked], 13, "asked the Fame Checker for person 13")

  -- Daisy is the case that matters most: the pack has a DAISY (a Painter) and
  -- the Fame Checker route is asked FIRST, so the wrong face never wins -- and
  -- it answers even where her graphic used to decline (gfx 76).
  fameAsked = {}
  local daisy = X.artFor({ gfx = 76, sprite = "SPRITE_MOM",
                           name = "DAISY", fromText = true })
  ok(daisy ~= nil, "Daisy gets a portrait even where her graphic once declined")
  eq(daisy and daisy.pic, 301, "from the synthetic Daisy key")
  eq(fameAsked[#fameAsked], 1, "asked for person 1, not the pack's Painter DAISY")

  fameAsked = {}
  local fuji = X.artFor({ name = "MR. FUJI", fromText = true })
  ok(fuji ~= nil, "Mr. Fuji gets a portrait")
  eq(fuji and fuji.pic, 314, "from the synthetic Fuji key")
  eq(fameAsked[#fameAsked], 14, "asked for person 14")

  -- Bill and Daisy also have an EXACT graphics id of their own (73 and 76), so
  -- a box that does not name them still gets their face.  Mr. Fuji has none:
  -- he wears the shared OLD_MAN graphic, and an unnamed old man must keep the
  -- cart's old-man picture rather than wear Mr. Fuji's face.
  fameAsked = {}
  local billGfx = X.artFor({ gfx = 73, sprite = "SPRITE_BILL" })
  ok(billGfx ~= nil and billGfx.pic == 313, "Bill resolves by graphics id 73")
  eq(fameAsked[#fameAsked], 13, "asking for person 13")
  local daisyGfx = X.artFor({ gfx = 76, sprite = "SPRITE_MOM" })
  ok(daisyGfx ~= nil and daisyGfx.pic == 301,
     "Daisy resolves by graphics id 76 -- where she used to decline")
  eq(fameAsked[#fameAsked], 1, "asking for person 1")
  eq(X.artFor({ gfx = 32, sprite = "SPRITE_GRAMPS" }).pic, 97,
     "an unnamed old man keeps the cart's old-man picture, not Fuji's")

  -- The three crop windows are filed, and they sit ON the head (the Fame
  -- Checker art starts at the top of the square, so y is 0, not the trainer
  -- default's 3).
  eq(X.rectFor("trainers", "301", { name = "DAISY" }).y, 0,
     "Daisy's window is filed at the top of the art")
  eq(X.rectFor("trainers", "313", { name = "BILL" }).size, 32,
     "Bill's window is 32px, like every other portrait")
  eq(X.rectFor("trainers", "314", { name = "MR. FUJI" }).size, 32,
     "and so is Mr. Fuji's")

  -- CustomArt/ is still the most specific key there is.
  customFiles["CustomArt/BILL.png"] = true
  fameAsked = {}
  local own = X.artFor({ name = "BILL", fromText = true })
  ok(own ~= nil and own.custom == true, "CustomArt/BILL.png beats the Fame Checker")
  eq(#fameAsked, 0, "and the Fame Checker is not even asked")
  customFiles["CustomArt/BILL.png"] = nil

  -- A name the cart did NOT draw in the Fame Checker still declines: this
  -- route adds three faces, it does not turn every name into one.
  eq(X.artFor({ name = "MOM", fromText = true }), nil,
     "a name the Fame Checker does not hold still declines")
end
fameTests()

-- ------- 15. THE NPC-STARTED SCENE
--
-- The reported shape: a portrait appears when the PLAYER starts the
-- interaction (world.talk names the object) but not when the NPC starts it.  An
-- NPC-started scene -- a coord event, an ON_FRAME map script, a cutscene that
-- walks somebody over -- raises no world.talk and no world.trainer_engaged, so
-- pressSpeaker is nil and the box had nothing to answer with.  The actor is
-- still in the data: the script moves and turns the object it is about, and the
-- engine's decoded script is a table of rows.
local function sceneTests()
  io.write("-- an NPC starts the interaction\n")

  local hadSpace = package.loaded["src.core.game3.scripting.space"]
  local hadObjects = package.loaded["src.core.game3.objects"]

  local npc = { sprite = "SPRITE_FISHER", graphicsId = 57, def = {} }
  local other = { sprite = "SPRITE_LASS", graphicsId = 22, def = {} }
  package.loaded["src.core.game3.objects"] = {
    find = function(id)
      if id == 5 then return npc end
      if id == 6 then return other end
      return nil
    end,
  }
  local space = {
    vm = {
      isRunning = function() return true end,
      ctx = { pc = { listKey = "std:4", index = 1 },
              stack = { { listKey = "scene" } } },
      _scriptKey = "scene",
      scripts = {
        ["std:4"] = { { op = "message", ptr = 0 } },
        scene = {
          { op = "applymovement", localId = 5 },
          { op = "applymovement", localId = 0xFF },  -- the player: not an object
          { op = "callstd", std = 4 },
        },
      },
    },
  }
  package.loaded["src.core.game3.scripting.space"] = space

  X.forgetSpeaker()
  local sp = X.speakerFor("Here, take this!")
  ok(sp ~= nil, "a box the NPC started names its actor with no press behind it")
  eq(sp and sp.sprite, "SPRITE_FISHER", "and it is the object the scene moves")
  eq(sp and sp.gfx, 57, "with its graphics id carried through")

  -- The name the text used still outranks the inferred actor, so a scene that
  -- hands off between two characters box by box keeps both right.
  local named = X.speakerFor("OAK: Watch out!")
  eq(named and named.name, "OAK", "a named line still names itself, not the actor")

  -- A scene that moves two people names the one it moved LAST.  The scene idiom
  -- is "place the speaker, then show their line", and a scene that alternates
  -- between two people -- Three Island's bikers and locals, g3:081679b5, moves a
  -- local, box, the biker, box, five times over -- is exactly this shape.  The
  -- old rule answered "nobody" whenever two objects were moved anywhere in the
  -- script, which left that whole scene bare.
  space.vm.scripts.scene = {
    { op = "applymovement", localId = 5 },
    { op = "turnobject", localId = 6 },
  }
  X.forgetSpeaker()
  local crowd = X.speakerFor("A crowd scene")
  ok(crowd ~= nil, "a scene that moves two people still names one")
  eq(crowd and crowd.sprite, "SPRITE_LASS",
     "and it is the one the script moved last")

  -- ...and the one it moved FIRST is named when that is the last move before
  -- the box -- recency, not "the only actor", is the rule.
  space.vm.scripts.scene = {
    { op = "applymovement", localId = 6 },
    { op = "turnobject", localId = 5 },
  }
  X.forgetSpeaker()
  local first = X.speakerFor("Another crowd scene")
  eq(first and first.sprite, "SPRITE_FISHER",
     "a different last move names a different speaker")

  -- ...and the script's actor outranks the PRESS record, because one pressed
  -- script can hand its boxes to several people.  Three Island's biker/local
  -- dialogue (g3:0816786f) alternates four speakers inside one press, so the
  -- pressed object is right for at most one of its boxes.
  space.vm.scripts.scene = { { op = "applymovement", localId = 5 } }
  space.vm.ctx = { pc = { listKey = "std:4", index = 1 },
                   stack = { { listKey = "scene", index = 1 } } }
  Runtime.call("world.talk", function() end, {}, other)
  local staged = X.speakerFor("A line nobody named")
  ok(staged ~= nil, "a pressed script that stages somebody still names them")
  eq(staged and staged.sprite, "SPRITE_FISHER",
     "and it is the object the script staged, not the pressed one")

  -- With no actor row before the box the press is the speaker, as always -- the
  -- ordinary `lock`/`faceplayer`/box conversation.
  space.vm.scripts.scene = { { op = "callstd", std = 4 } }
  X.forgetSpeaker()
  Runtime.call("world.talk", function() end, {}, other)
  local plain = X.speakerFor("A plain pressed line")
  eq(plain and plain.sprite, "SPRITE_LASS",
     "a press with nothing staged for the box is still the speaker")

  -- Nothing running: no actor, and no stale one either.
  space.vm.isRunning = function() return false end
  X.forgetSpeaker()
  eq(X.speakerFor("Nothing running"), nil,
     "with no script running there is no actor")

  -- Put the engine back.
  package.loaded["src.core.game3.scripting.space"] = hadSpace
  package.loaded["src.core.game3.objects"] = hadObjects
end
sceneTests()

-- ------- 16. a step inside a script is not the player ending the conversation
--
-- The reported "some dialogue boxes lose the portrait partway through".  FRLG
-- walks the PLAYER around inside a script -- `applymovement 0xFF` is how a
-- cutscene turns the player to face the speaker, or walks them into a scene --
-- and that goes through Player.scriptStep -> Player.finishStep, the one place a
-- real step emits world.stepped (src/core/game3/player.lua:653, reached only at
-- :799).  So the event fires MID-conversation, and the old unconditional clear
-- dropped the portrait for every box after it.  Oak's aide is the worked
-- example: his branch scripts at g3:081663da / :081663e6 / :081663fc run
-- `applymovement 0xFF` between his first box and the rest of his speech.
--
-- The guard is the one the Gen 2 port has carried since 1.3.3: while a script
-- is in flight the step is the SCENE's, and the record stands until the script
-- itself ends.  Section 10 above still holds the other half -- with no script
-- running, a step is the player's own and ends the conversation -- so the two
-- together pin the rule rather than either half of it.
local function stepGuardTests()
  io.write("-- a script's own step does not end the conversation\n")

  local hadSpace = package.loaded["src.core.game3.scripting.space"]
  local running = true
  package.loaded["src.core.game3.scripting.space"] = {
    vm = { isRunning = function() return running end, ctx = {}, scripts = {} },
  }

  X.forgetSpeaker()
  Runtime.call("world.talk", function() end, {}, PIKACHU_EO)
  ok(X.speakerFor("Pika pika!") ~= nil, "a press is on record")

  -- The step the scene takes: the player is walked by applymovement 0xFF.
  Runtime.emit("world.stepped", {})
  ok(X.speakerFor("Pika pika!") ~= nil,
    "a step while the script runs keeps the speaker -- the box keeps its face")

  -- The script's own end still ends it, so nothing outlives the conversation.
  Runtime.emit("script.ended", { completed = true })
  eq(X.speakerFor("Pika pika!"), nil, "and the script's end still ends it")

  -- With no script in flight, a step is the player's own and ends it, exactly
  -- as section 10 says -- so the guard is not a blanket "never clear".
  running = false
  Runtime.call("world.talk", function() end, {}, PIKACHU_EO)
  ok(X.speakerFor("Pika pika!") ~= nil, "a fresh press is on record")
  Runtime.emit("world.stepped", {})
  eq(X.speakerFor("Pika pika!"), nil, "with no script running, a step ends it")

  package.loaded["src.core.game3.scripting.space"] = hadSpace
end
stepGuardTests()

-- ------- 17. the female psychic's graphic answers
--
-- OBJ_EVENT_GFX_WOMAN_1 (23) is the female PSYCHIC graphic.  The host names it
-- SPRITE_TEACHER (src/core/game3/scripting/gfx_ids.lua:14) and SPRITE_ART has
-- no SPRITE_TEACHER entry, so the sprite route declined and every one of the
-- fifteen non-trainer women wearing it drew nothing -- the reported "portraits
-- are missing for some psychic sprites".  The three trainers on it (LAURA id
-- 608, JACLYN id 517, RODETTE id 587) already resolved through the trainer
-- route; the graphic ITSELF is what answered nobody.  Picture 138 is the cart's
-- female PSYCHIC bust, and art/map_art.lua's own generated answer is [23] = 138
-- on all three maps that put a psychic on it, so GFX_ART[23] = 138 is that same
-- rule for the maps that put none.
io.write("-- the female psychic's graphic answers\n")
local psychic = X.artFor({ gfx = 23 })
ok(psychic ~= nil, "a bare WOMAN_1 object now draws a portrait")
eq(psychic and psychic.pic, 138, "and it is the female Psychic's own bust")

-- The exact route that used to decline, made to bite: the host's sprite name
-- for this graphic has no art, and the PSYCHIC class (75) has no row in this
-- suite's pack, so NOTHING but the graphic route above can answer.  If the new
-- GFX_ART entry were absent this would be nil, which is the shipped bug.
local byGfx = X.artFor({ gfx = 23, sprite = "SPRITE_TEACHER", class = 75 })
eq(byGfx and byGfx.pic, 138,
  "it answers even though SPRITE_TEACHER has no art and class 75 has no pack row")

-- The map route (step 4b) agrees: on the three maps that field a psychic on
-- this graphic the generated table says the same 138.  This ties the new
-- hand-written entry to art/map_art.lua rather than to a second guess.
eq(X.artFor({ gfx = 23, mapId = "FR_SIX_ISLAND_GREEN_PATH" }).pic, 138,
  "and the map route's own generated answer agrees")
eq(X.MAP_ART["FR_FIVE_ISLAND_LOST_CAVE_ROOM4"][23], 138, "on Lost Cave too")
eq(X.MAP_ART["FR_SEVEN_ISLAND_TRAINER_TOWER"][23], 138, "and on the Trainer Tower")

-- The three trainers who wear it still resolve through their OWN ids (the
-- trainer route, step 4, runs before the graphic route), so the new entry is a
-- floor for the un-named object, not an override of a named person.
eq(X.artFor({ gfx = 23, scriptKey = "g3:08164c11" }).pic, 138,
  "LAURA, the real trainer on this graphic, still resolves by her own id")
eq(X.scriptTrainerIds["g3:081ac517"], 517, "JACLYN's script names trainer 517")
eq(X.scriptTrainerIds["g3:081ac88b"], 587, "and RODETTE's names 587")

-- ------- 18. Celio, the one named character the decline left faceless
--
-- The reported "in the Bill interaction on One Island with Celio, his portrait
-- is missing from some of his dialogue boxes".  OBJ_EVENT_GFX_CELIO (89) is
-- worn by exactly ONE object in the whole game -- Celio, in the Net Center --
-- and the mod DECLINED it (`[89] = false`), on the reasoning that the cart never
-- drew a bust of him.  That left a named story character with no face on any of
-- his boxes, which is the same shape as the Balding Man decline 1.9.4 removed.
-- Measured by .probe/dp3_gfxwho.lua: 1 object, 0 trainers.
--
-- The scene is a coord event -- `lockall`, no world.talk -- and it moves Bill,
-- Celio AND the player, so sceneSpeaker answers nothing (more than one actor)
-- and the text's own "CELIO: " is the only fact in play.  That is why the fix
-- is two entries: the GRAPHIC for the boxes that carry an object, and the NAME
-- for the scene's boxes, which carry none.
io.write("-- Celio, who had no face at all\n")

-- The graphic route: one graphic, one person, one picture (the cart's own bust
-- for graphic 89 -- picture 89, the Super Nerd's).  Every one of these is read
-- through a local so a bite reports the whole family rather than dying on the
-- first nil.
local function picOf(d) local a = X.artFor(d) return a and a.pic or nil end
eq(X.GFX_ART[89], 89, "graphic 89 now names a picture instead of declining")
eq(picOf({ gfx = 89 }), 89, "a bare Celio object draws a portrait")
eq(picOf({ gfx = 89, sprite = "SPRITE_SUPER_NERD" }), 89,
  "and so does one carrying the host's sprite name for the graphic")
eq(picOf({ gfx = 89, scriptKey = "g3:08170ec5" }), 89,
  "and one carrying his own object script's key")

-- The name route: the Net Center scene's boxes carry NO object at all.
eq(X.NAME_ART["CELIO"], "SUPER NERD", "CELIO is filed in the text-name table")
eq(picOf({ name = "CELIO", fromText = true,
           mapId = "OneIsland_PokemonCenter_1F" }), 89,
  "a name-only Celio box -- the coord-event scene -- now draws a portrait")

-- The whole scene, box for box, as the cart spells it: four Bill lines and
-- three Celio lines, alternating.  Bill is the regression guard -- he was
-- already right, and this release must not disturb him.
local SCENE = {
  { "BILL: Oh, hey!!", 313 },
  { "BILL: What kept you so long?Been out having a good time?We got it done.The PCs are up and running!", 313 },
  { "CELIO: The job went incrediblyquick.BILL is one amazing guy…", 89 },
  { "BILL: No, no! There was almostnothing left for me to do.CELIO, I have to hand it to you.You've learned a lot.", 313 },
  { "CELIO: Oh, really?Ehehe…", 89 },
  { "BILL: Well, there you have it.I'm finished with the job.We should head back to KANTO.CELIO, I'll be seeing you again.", 313 },
  { "CELIO: , I'm really sorrythat we sent you off alone today.I promise, I will show you aroundthese islands sometime.", 89 },
}
for i, row in ipairs(SCENE) do
  local d = X.speakerFor(row[1])
  local a = d and X.artFor(d)
  eq(a and a.pic, row[2], ("scene box %d (%s…) gets picture %d")
    :format(i, row[1]:sub(1, 5), row[2]))
end

-- Celio's OWN dialogue has boxes that do NOT spell his name -- his object
-- script hands off to lines with no "CELIO: " prefix -- and those are the
-- "some of his dialogue boxes" of the report.  They carry his object (gfx 89)
-- and nothing else, so the graphic route is what has to answer for them.
-- Celio's own object, as a press hands it over: his graphic and his script key,
-- no class and no trainer id -- he is not a trainer.
local CELIO_EO = { def = { graphicsId = 89, scriptKey = "g3:08170ec5" },
                   graphicsId = 89, scriptKey = "g3:08170ec5" }

local CELIO_UNNAMED = {
  "I'm sorry for taking up so much ofBILL's time.I'm also sorry for being such a poor host on your visit here.",
  "I…I'm not crying.That's enough about me!, you're going to keeplooking for exotic POKéMON, right?I wish you the best of luck!",
  "This is my own ferry PASS.It will let you get to all theSEVII ISLANDS., please, I can'tdo it without your help.",
  "Oh!Th-that's…",
  "I was trying to find the gemeven while I was studying.As a result, I've made no headwayin both my search and studies…If I relied on BILL, I'm sure myresearch would progress.But this time, I want to try to dothings by myself.",
}
for i, txt in ipairs(CELIO_UNNAMED) do
  eq(X.nameFromText(txt), nil, ("unnamed Celio line %d really has no name prefix"):format(i))
  -- Press his object, the way the engine does, so the box carries gfx 89 and
  -- nothing else -- exactly the shape these lines arrive in.
  Runtime.call("world.talk", function() end, {}, CELIO_EO)
  local d = X.speakerFor(txt)
  eq(d and d.gfx, 89, ("and it resolves Celio's object, gfx 89 (line %d)"):format(i))
  local a = d and X.artFor(d)
  eq(a and a.pic, 89, ("so it draws picture 89 (line %d)"):format(i))
end

-- ------- 19. the two lines the report names
--
-- Both are lines whose box carries NO name, so both depend on the object route
-- -- and both were reported as showing no portrait.  The lifecycle half (a
-- short move between boxes must not end the record; a fresh press must start a
-- fresh conversation) is `XF.departureTests` in the geometry suite; this is the
-- resolution half, so the assignment is pinned next to the behaviour.
io.write("-- the lines the report names\n")

-- Oak's aide: "I'm glad I caught up to you." -- his object is gfx 55.
-- Pin the map, because the map route (step 4b) outranks the graphic and Route 8
-- really does put a Super Nerd on gfx 55 ([55] = 89 there).  Pewter City has no
-- such trainer, which is why the aide resolves through GFX_ART[55] = 107.
Runtime.emit("map.entered", { mapId = "FR_PEWTER_CITY" })
local AIDE_EO = { def = { graphicsId = 55, localId = 7 },
                  graphicsId = 55, localId = 7, sprite = "SPRITE_SCIENTIST" }
Runtime.call("world.talk", function() end, {}, AIDE_EO)
local aideLine = X.speakerFor(
  "I'm glad I caught up to you.I'm PROF. OAK's AIDE.I've been asked to deliver this,so here you go.")
eq(aideLine and aideLine.gfx, 55, "the aide's line resolves his own object")
eq(aideLine and aideLine.name, nil, "and names nobody in the text")
eq(X.artFor(aideLine) and X.artFor(aideLine).pic, 107,
  "so it draws the Scientist's picture (gfx 55 -> 107)")

-- Bill: "ASH, this is my buddy CELIO." / "…wait for me just a bit?" is the Net
-- Center box that shows Celio off (g3:08170eb1) -- Bill's object is gfx 73.
local BILL_EO = { def = { graphicsId = 73, localId = 2 },
                  graphicsId = 73, localId = 2, sprite = "SPRITE_BILL" }
Runtime.call("world.talk", function() end, {}, BILL_EO)
local billLine = X.speakerFor(
  "Oh, hey, !Did you see?We got the PC working!I've got a few things to showCELIO here.Can you go out on a stroll orsomething for a while more?")
eq(billLine and billLine.gfx, 73, "Bill's line resolves his own object")
eq(billLine and billLine.name, nil, "and names nobody in the text")
eq(X.artFor(billLine) and X.artFor(billLine).pic, 313,
  "so it draws his Fame Checker portrait (gfx 73 -> person 13)")

-- ------- 20. a name beats the graphic it wears
--
-- Five Island's Resort Gorgeous: Lady Selphy wears OBJ_EVENT_GFX_WOMAN_2 (28),
-- the graphic the LADY, AROMA LADY and POKéMON BREEDER classes all share, and
-- the majority class on it is the AROMA LADY -- so GFX_ART[28] is 144 and her
-- HOUSE map has no MAP_ART entry to outrank it.  The cart's own trainer table
-- names her (id 606, class 105, picture 146) and every one of her boxes says
-- "SELPHY: ", so the name route is what answers; her script has no
-- trainerbattle at its head for the id route to use.  Measured by
-- .probe/dp3_classgfx.lua: graphic 28 carries AROMA LADY x4, BREEDER x3, LADY x2.
io.write("-- Lady Selphy\n")
eq(X.GFX_ART[28], 144, "graphic 28 still answers the Aroma Lady, its majority class")
eq(X.artFor({ gfx = 28 }).pic, 144, "so a bare graphic-28 box draws her picture")
eq(X.picForName("SELPHY"), 146, "but SELPHY resolves through the LADY class")
eq(X.artFor({ name = "SELPHY", fromText = true, gfx = 28,
              mapId = "FR_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE" }).pic, 146,
  "so a Selphy box draws the LADY's picture 146, not 144")
-- The scene's other speaker is the butler (gfx 61).  Section 21 is where his
-- label is tested; here it is only worth pinning that his OWN object still
-- answers through the graphic, and that naming him agrees with it.
eq(X.artFor({ name = "BUTLER", fromText = true, gfx = 61 }).pic, 123,
  "and the Butler's own object answers the same 123")

-- ------- 21. the cart's one capitalised speaker label
--
-- "Butler: " is the ONLY capitalised-word label in the game that is a person.
-- Measured over every dialogue box by .probe/dp3_labels.lua: Butler x5, Diary
-- x4, Hint x1, Name x7 -- and the other three are the Pokemon Mansion's diaries
-- and two sign shapes, which resolve to nothing and are left exactly as they
-- were.
--
-- It matters because a box the name rule does not recognise falls to the OBJECT
-- route, and in a scene that route names the object the script moved most
-- recently -- which is not necessarily the speaker.  The Resort Gorgeous House
-- scene moves SELPHY for her own line and then shows two of the butler's, so
-- those two boxes carried HER object (gfx 28) and wore the Aroma Lady's 144,
-- while his third carried his own (gfx 61) and wore the Gentleman's 123.
io.write("-- the cart's one capitalised speaker label\n")
eq(X.nameFromText("Butler: Yes, my lady."), "Butler",
  "a capitalised label is read as a speaker")
eq(X.nameFromText("Diary: July 5 Guyana, South America"), "Diary",
  "and so is a diary, which resolves to nothing")
eq(X.nameFromText("SELPHY: Oh, hello, there."), "SELPHY",
  "the all-caps rule is untouched")
eq(X.nameFromText("Oh, hello, there."), nil, "and prose is still not a name")
eq(X.NAME_ART["BUTLER"], "GENTLEMAN",
  "BUTLER is filed against the class the cart itself draws him as")
-- The ORDER is half the fix: NAME_ART runs with the pack's name route, before
-- the graphic.  The butler shows it, because his graphic (28) answers the Aroma
-- Lady's 144 and his entry answers the Gentleman's 123.
eq(X.artFor({ name = "Butler", fromText = true, gfx = 28 }).pic, 123,
  "so his boxes draw 123 even when the object they carry is somebody else's")
eq(X.artFor({ name = "Butler", fromText = true, gfx = 61 }).pic, 123,
  "and when the object is his own")
eq(X.artFor({ name = "Diary", fromText = true, gfx = 28 }).pic, 144,
  "while a diary label changes nothing at all")

-- ------- 22. the maps the generated per-map table cannot reach
--
-- art/map_art.lua is built from TRAINER objects, so a map whose only speaker of
-- a graphic is a non-trainer has no entry for it and the graphic's own table
-- answers -- which for a shared graphic is its majority class.  Lady Selphy
-- wears gfx 28, shared by LADY, AROMA LADY and POKéMON BREEDER, so GFX_ART[28]
-- is the Aroma Lady's 144; her House and Lost Cave Room 10 have no trainers at
-- all.  The box that opens "I wish to see a POKéMON." (g3:08171efe) carries no
-- name and moves nobody, so it was resolved from her own object and drew 144,
-- while every box of hers that says "SELPHY: " drew 146 -- one conversation,
-- two faces.  PLACE_ART is that same 146 for the two maps the generated table
-- cannot reach.
io.write("-- the maps the generated table cannot reach\n")
eq(X.GFX_ART[28], 144, "graphic 28 still answers the Aroma Lady, its majority class")
eq(X.PLACE_ART["FR_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE"][28], 146,
  "but Selphy's house is filed as a LADY")
eq(X.PLACE_ART["FR_FIVE_ISLAND_LOST_CAVE_ROOM10"][28], 146,
  "and so is the Lost Cave room she also stands in")
eq(X.artFor({ gfx = 28, mapId = "FR_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE" }).pic, 146,
  "so the wish box (no name, no actor) draws her, not the Aroma Lady")
eq(X.artFor({ gfx = 28, mapId = "FR_FIVE_ISLAND_LOST_CAVE_ROOM10" }).pic, 146,
  "and so does the Lost Cave one")
eq(X.artFor({ gfx = 28, mapId = "FR_VIRIDIAN_CITY_SCHOOL" }).pic, 144,
  "while a map that is not filed keeps the graphic's own answer")
eq(X.artFor({ gfx = 28, mapId = "FR_FIVE_ISLAND_RESORT_GORGEOUS" }).pic, 146,
  "and the outdoor map keeps the generated table's 146")

do
  -- ------- the Mt Moon scientist, and a scene that moves a Pokemon
  --
  -- Two reports, one file.
  --
  -- (1) Mt Moon's fossil-room Super Nerd is MIGUEL, trainer 170, class SUPER
  -- NERD, cart picture 89.  He wears OBJ_EVENT_GFX_SCIENTIST (55) -- the lab
  -- coat the host calls SPRITE_SCIENTIST and that 8 Super Nerds AND 14
  -- Scientists share -- and his object's script wraps its trainerbattle in a
  -- subroutine, so neither generated table carries him.  Without the map entry
  -- he falls through to GFX_ART[55] and wears the SCIENTIST's 107.
  io.write("-- the Mt Moon scientist, and a scene that moves a Pokemon\n")

  eq(X.MAP_ART["FR_MT_MOON_B2F"] and X.MAP_ART["FR_MT_MOON_B2F"][55], 89,
     "graphic 55 on Mt Moon B2F is the SUPER NERD's picture")
  eq(X.artFor({ gfx = 55, sprite = "SPRITE_SCIENTIST",
                mapId = "FR_MT_MOON_B2F" }).pic, 89,
     "so the fossil-room object draws the Super Nerd")
  eq(X.artFor({ gfx = 55, sprite = "SPRITE_SCIENTIST" }).pic, X.GFX_ART[55],
     "while the graphic alone still answers the Scientist -- unchanged")
  eq(X.MAP_ART["FR_SILPH_CO_2F"] and X.MAP_ART["FR_SILPH_CO_2F"][55], 107,
     "and Silph Co. still says the Scientist")

  -- (2) Cerulean City's LASS runs `applymovement localId=5` to walk the SLOWBRO
  -- beside her and only then says her own lines.  The scene route names the
  -- object a script MOVES, so it named the Slowbro for every one of her boxes
  -- and she wore its face.  A species is not a person, so the press wins.
  local SLOWBRO = { localId = 5, graphicsId = 129, sprite = "SPRITE_YOUNGSTER",
                    trainerType = 0, scriptKey = "g3:081667dd",
                    cellX = 32, cellY = 29 }
  local LASS = { localId = 6, graphicsId = 22, sprite = "SPRITE_LASS",
                 trainerType = 0, scriptKey = "g3:0816674f",
                 cellX = 33, cellY = 29 }
  local savedSpace = package.loaded["src.core.game3.scripting.space"]
  local savedObjects = package.loaded["src.core.game3.objects"]
  package.loaded["src.core.game3.objects"] = {
    find = function(lid) return ({ [5] = SLOWBRO, [6] = LASS })[tonumber(lid)] end,
  }
  package.loaded["src.core.game3.scripting.space"] = { vm = {
    isRunning = function() return true end,
    scripts = { ["g3:0816674f"] = {
      { op = "lock" },                        -- 1
      { op = "applymovement", localId = 5 },  -- 2  the Slowbro -- NOT a speaker
      { op = "message", ptr = 0 },            -- 3  her own line
    } },
    ctx = { pc = { listKey = "g3:0816674f", index = 3 }, stack = {} },
    _scriptKey = "g3:0816674f",
  } }

  X.forgetSpeaker()
  Runtime.call("world.talk", function() end, {}, LASS)   -- the player talked to HER
  local sp = X.speakerFor("Where did my SLOWBRO go?")
  eq(sp and sp.gfx, 22, "a script that moves a Pokemon does not name the Pokemon")
  eq(sp and sp.gfx ~= 129, true, "and certainly not the Slowbro's graphic")
  ok(X.artFor(sp) ~= nil, "so her box still draws a portrait")

  package.loaded["src.core.game3.scripting.space"] = savedSpace
  package.loaded["src.core.game3.objects"] = savedObjects
end

io.write(("\n%d checks, %d failures\n"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
