# Dump FRLG trainer records (id, class, pic, name) straight out of the cart.
#
# Trainer record layout (src/import/gba/versions.lua: TRAINERS_TABLE = 0x23EAC8,
# stride 0x28, 743 records):
#
#   off+0  partyFlags      off+1  class        off+2  encGender
#   off+3  pic             off+4  name (12, 0xFF-terminated)
#
# The point of this dump: `pic` is what TrainerPic.front() indexes, `class` is
# what a map object carries as trainerType, and they are different number
# spaces.  `name` is a third thing entirely -- and it is the one that lets a
# "BROCK: " prefix in the dialogue resolve to a picture exactly.
#
# Run with the ROM to hand -- either a Pokemon_FireRed.gba in the current
# directory, or FIRERED_ROM set to one:
#
#   python tools/dump_trainers.py            # summary + per-name ambiguity
#   python tools/dump_trainers.py BROCK      # the rows for one name

import os
import sys

ROM = os.environ.get("FIRERED_ROM", "Pokemon_FireRed.gba")
TRAINERS_BASE, TRAINER_STRIDE, TRAINER_COUNT = 0x23EAC8, 0x28, 743
CLASS_BASE, CLASS_STRIDE, CLASS_COUNT = 0x23E558, 13, 107

CHARMAP = {
    0x00: " ", 0x1B: "\u00e9",
    0xAB: "!", 0xAC: "?", 0xAD: ".", 0xAE: "-", 0xAF: "\u00b7",
    0xB0: "\u2026", 0xB1: '"', 0xB2: '"', 0xB3: "'", 0xB4: "'",
    0xB5: "\u2642", 0xB6: "\u2640", 0xB7: "$", 0xB8: ",", 0xB9: "\u00d7",
    0xBA: "/", 0xEF: "\u25b6", 0xF0: ":",
}


def decode(data, off, length):
    out, i = [], 0
    while i < length:
        b = data[off + i]
        if b == 0xFF:
            break
        if b == 0x53 and i + 1 < length and data[off + i + 1] == 0x54:
            out.append("POK\u00e9MON")
            i += 2
            continue
        if b in CHARMAP:
            out.append(CHARMAP[b])
        elif 0xBB <= b <= 0xD4:
            out.append(chr(ord("A") + (b - 0xBB)))
        elif 0xD5 <= b <= 0xEE:
            out.append(chr(ord("a") + (b - 0xD5)))
        else:
            out.append("{%02X}" % b)
        i += 1
    return "".join(out).rstrip()


def read_rows(data):
    """(trainerId, class, pic, name) for all 743 records."""
    rows = []
    for tid in range(TRAINER_COUNT):
        off = TRAINERS_BASE + tid * TRAINER_STRIDE
        rows.append((tid, data[off + 1], data[off + 3], decode(data, off + 4, 12)))
    return rows


def main():
    needle = sys.argv[1].upper() if len(sys.argv) > 1 else None
    with open(ROM, "rb") as handle:
        data = handle.read()

    class_names = {
        cid: decode(data, CLASS_BASE + cid * CLASS_STRIDE, CLASS_STRIDE)
        for cid in range(CLASS_COUNT)
    }
    rows = read_rows(data)

    if needle:
        shown = [r for r in rows if needle in r[3].upper()]
        print("rows matching %r: %d" % (needle, len(shown)))
        for tid, cls, pic, name in shown:
            print("%3d  class %3d %-18s pic %3d  name %r"
                  % (tid, cls, class_names.get(cls, "?"), pic, name))
        return

    # name -> set of pics it is ever drawn with
    by_name = {}
    for _tid, _cls, pic, name in rows:
        if name:
            by_name.setdefault(name, set()).add(pic)

    print("trainer records: %d" % len(rows))
    print("distinct names:  %d" % len(by_name))
    ambiguous = sorted(n for n, pics in by_name.items() if len(pics) > 1)
    print("names that pin more than one pic: %d" % len(ambiguous))
    for name in ambiguous:
        print("   %-16s %s" % (name, sorted(by_name[name])))

    print()
    print("--- the story names, as the ROM spells them ---")
    for name in ("OAK", "BLUE", "RIVAL", "BROCK", "MISTY", "LANCE", "GIOVANNI",
                 "BILL", "MOM", "DAISY"):
        hits = [(t, c, p) for t, c, p, n in rows if n.upper() == name]
        if hits:
            print("   %-10s %s" % (name, hits[:6]))


if __name__ == "__main__":
    main()
