-- The FIRE RED / LEAF GREEN busts an EMERALD graphic may borrow when the
-- Emerald cart never drew that person a battle bust of its own.
--
-- ---- why this table exists, and why it is so short
--
-- The mod's Emerald resolver (emerald/init.lua) answers an Emerald speaker from
-- Emerald data only: the script key, the box's name, the graphic's class name,
-- the (map, graphic) pair and the whole-ROM graphic majority.  Where a graphic
-- is worn by NO trainer -- the townsfolk, the shop clerks, the nurse -- that
-- route ends, and emerald/gfx_art_people.lua decides the graphic BY HAND.  A
-- measured 13 kinds it DECLINES (`false`), because the Emerald cart never drew
-- them a battle bust at all.
--
-- FireRed and LeafGreen, however, DID draw busts for several of those kinds:
-- a Scientist, an Engineer, a Gentleman, an elderly Expert, a Painter.  This
-- table is those borrowings, decided one graphic at a time, and nothing else.
--
-- ---- WHY SHARING IS KEYED BY GRAPHIC AND NOT BY CLASS OR PICTURE ID
--
-- Measured against the two carts' own trainer tables, and this is the whole
-- reason the table is hand-written rather than computed:
--
--   * The two cartoons' CLASS ID SPACES DIVERGE.  Of 67 class names the two
--     carts spell the same, 66 carry a DIFFERENT number in each.  Emerald's
--     HIKER is class 2, FireRed's is class 51; Emerald's BEAUTY is 21, FireRed's
--     12.  So forwarding an Emerald class id into FireRed's table names a
--     different person -- Emerald's HIKER picture is 0, and FireRed's picture 0
--     is the AQUA LEADER.  That is the HIKER-wearing-Archie bug, and it is not
--     a risk here: no id from either cart is ever handed to the other.
--   * The PICTURE spaces diverge for the same reason: Emerald's 0..92 and
--     FireRed's 0..147 are different art sets that happen to share a numbering.
--   * So the only sound key is the GRAPHIC the Emerald object wears, answered
--     with a FireRed PICTURE id that was LOOKED AT and confirmed to be that
--     kind of person.  A graphic is a uniform -- the same reasoning the rest of
--     this mod is built on.
--
-- ---- the values, and how each was decided
--
-- Every value is a FireRed FRONT-PIC id, and every one was chosen by rendering
-- the Emerald overworld graphic beside the candidate FireRed busts and looking
-- (.probe/dp3_frlg_share_cmp.py -> .probe/_share_*.png), the way
-- emerald/gfx_art_people.lua and art/crops.lua were decided.  NO value here was
-- inferred from a class name alone; where a name and the art disagreed, the art
-- won.
--
-- FireRed's class -> picture mapping is read from the ROM itself by
-- tools/dump_class_pics.py (TRAINERS_TABLE 0x23EAC8 stride 0x28,
-- CLASS_BASE 0x23E558 stride 13, PIC_TABLE 0x23957C), so the ids below are the
-- cart's own, not a guess.
--
--   gfx  46  SCIENTIST_1        -> 107  Exact in kind.  FireRed class 82
--                                      SCIENTIST pins picture 107 -- a
--                                      glasses-wearing man in a white lab
--                                      coat, the same person Emerald draws.
--   gfx 116  DEVON_EMPLOYEE     -> 107  The same lab-coat kind: a company
--                                      scientist in a white coat.  (FireRed
--                                      ENGINEER, 93, is the yellow field
--                                      uniform and reads as a different job.)
--   gfx  30  OLD_WOMAN          ->  35  Closest build: FireRed EXPERT pins 34
--                                      (male) and 35 (female); 35 is the
--                                      elderly woman, which is the person.
--   gfx  22  EXPERT_F           ->  35  Literally FireRed's EXPERT_F: the same
--                                      class name, and 35 is its female face.
--   gfx  99  ARTIST            -> 147  Closest kind: FireRed PAINTER, 147, is
--                                      the beret-wearing artist; Emerald draws
--                                      a smaller figure of the same trade.
--   gfx 190  CONTEST_JUDGE      -> 123  Closest build: FireRed GENTLEMAN, 123,
--                                      an elderly man in a suit, is the build
--                                      Emerald's judge is drawn in.
--   gfx 219  SCOTT              -> 101  Closest build: FireRed ROCKER, 101, is
--                                      the young man in a casual jacket.
--   gfx  28  LINK_RECEPTIONIST  ->  51  Closest build: the Emerald graphic
--                                      wears a GREEN CAP and uniform, and
--                                      FireRed PICNICKER 51 is the green-capped
--                                      girl who matches that colour and build
--                                      far better than any cooler.  (FireRed's
--                                      TEAM MAGMA girl, 64, is the red uniform
--                                      and was the wrong read -- re-rendered
--                                      and corrected.)
--   gfx  83  MART_EMPLOYEE      ->  98  Closest build: FireRed BEAUTY, 98, is
--                                      the aproned woman behind a counter.
--   gfx  58  NURSE              -> 126  Closest kind: FireRed CHANNELER, 126,
--                                      is the white-clad woman; the cart has no
--                                      nurse bust to borrow.
--   gfx 227  UNION_ROOM_NURSE   -> 126  The same nurse, in the same white.
--   gfx  27  COOK               ->  23  Closest build: the Emerald cook is a
--                                      hatted, upright working man; FireRed
--                                      GENTLEMAN 23 (bowler hat, standing) is
--                                      nearer that build than the aged 123.
--   gfx 223  MYSTERY_GIFT_MAN   ->  23  Closest build: the Emerald graphic wears
--                                      a CAP and uniform; FireRed GENTLEMAN 23,
--                                      the man in a hat, is the nearest build.
--
-- ---- the compromises, stated rather than hidden
--
--   * Three graphics share one borrowed face, because FireRed drew only one
--     person of that build: gfx 27 COOK and gfx 223 MYSTERY_GIFT_MAN both take
--     FireRed GENTLEMAN 23, and gfx 58 and gfx 227 take CHANNELER 126.  That is
--     a closest-build compromise, not an identity, and it is recorded here
--     rather than dressed up.  Where neither cart drew a bust of the kind at all
--     (FireRed has no nurse, no cook, no receptionist), a nearest neighbour is
--     the honest ceiling -- and is still better than the whole-ROM majority a
--     statistical route would otherwise put on the box.
--   * Every value was re-rendered and re-checked against the FRLG cache before
--     this release, not carried over from a class name.  Two were CORRECTED that
--     way: gfx 28 moved off FireRed 64 (the red TEAM MAGMA girl -- the wrong
--     read) onto 51 (the green-capped PICNICKER that matches the graphic), and
--     gfx 27 / 223 moved off the aged 123 onto 23 (the hatted, upright build).
--   * A graphic absent from this table is simply not borrowed -- the Emerald
--     decline stands.
--   * No graphic that Emerald ALREADY resolves (its own class route, the hand
--     table, a shipped PNG) appears here.  Borrowing is offered only where the
--     hand table DECLINES, so this table can never overrule Emerald's own art
--     for the same person.
--
-- ---- what reading it costs
--
-- A borrowed picture is read from the FIRERED cache by explicit, version-prefixed
-- path (CacheFs.readAt, the engine's own cross-version read -- see dex.lua:40).
-- The path's generated-tree root is DERIVED from the engine
-- (src.core.game3.cache_paths.CACHE_ROOT), not written here, so this file carries
-- no literal into the player's ROM-derived tree (modkit MK301).  That cache
-- exists only if FireRed has been IMPORTED through the launcher at least once;
-- if it has not, every value here simply misses and the Emerald decline stands.
-- Nothing is mounted, nothing is switched, and a FireRed boot is never affected.

return {
  -- exact / same-kind borrowings (a FireRed bust that IS that kind of person)
  [46]  = 107,   -- SCIENTIST_1       -> FireRed SCIENTIST (class 82)
  [116] = 107,   -- DEVON_EMPLOYEE    -> FireRed SCIENTIST, the same lab coat
  [22]  = 35,    -- EXPERT_F          -> FireRed EXPERT_F (class 28)
  [99]  = 147,   -- ARTIST            -> FireRed PAINTER (class 106)
  [58]  = 126,   -- NURSE             -> FireRed CHANNELER, closest white-clad woman
  [227] = 126,   -- UNION_ROOM_NURSE  -> the same

  -- closest-build borrowings (the same trade or the same build, not the person)
  [30]  = 35,    -- OLD_WOMAN         -> FireRed EXPERT_F, the elderly woman
  [190] = 123,   -- CONTEST_JUDGE     -> FireRed GENTLEMAN, the elderly man
  [219] = 101,   -- SCOTT             -> FireRed ROCKER, the casual young man
  [28]  = 51,    -- LINK_RECEPTIONIST -> FireRed PICNICKER, the green-capped build
  [83]  = 98,    -- MART_EMPLOYEE     -> FireRed BEAUTY, the aproned woman
  [27]  = 23,    -- COOK              -> FireRed GENTLEMAN, the hatted working build
  [223] = 23,    -- MYSTERY_GIFT_MAN  -> FireRed GENTLEMAN, the man in a hat
}
