# Dump the FRLG trainer class -> front-pic mapping straight out of the cart.
#
# The trainer record (src/import/gba/versions.lua: TRAINERS_TABLE = 0x23EAC8,
# stride 0x28, 743 records) carries BOTH a class and a pic:
#
#   off+0  partyFlags      off+1  class        off+2  encGender
#   off+3  pic             off+4  name (12)
#
# and TrainerPic.front(picId) indexes TRAINER_FRONT_PIC_TABLE (0x23957C) --
# the PIC table, not the class table.  So class and pic are different number
# spaces and this script exists to say what the mapping between them is.
#
#   python tools/dump_class_pics.py

import os

ROM = os.environ.get("FIRERED_ROM", "Pokemon_FireRed.gba")
TRAINERS_BASE, TRAINER_STRIDE, TRAINER_COUNT = 0x23EAC8, 0x28, 743
CLASS_BASE, CLASS_STRIDE, CLASS_COUNT = 0x23E558, 13, 107
PIC_TABLE, PIC_COUNT = 0x23957C, 148

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


def main():
    with open(ROM, "rb") as handle:
        data = handle.read()

    class_names = {
        cid: decode(data, CLASS_BASE + cid * CLASS_STRIDE, CLASS_STRIDE)
        for cid in range(CLASS_COUNT)
    }

    # class -> { pic: [trainer ids] }
    by_class = {}
    for tid in range(TRAINER_COUNT):
        off = TRAINERS_BASE + tid * TRAINER_STRIDE
        cls = data[off + 1]
        pic = data[off + 3]
        by_class.setdefault(cls, {}).setdefault(pic, []).append(tid)

    print("distinct classes used by a trainer:", len(by_class))
    multi = 0
    for cls in sorted(by_class):
        pics = by_class[cls]
        flag = ""
        if len(pics) > 1:
            multi += 1
            flag = "  <-- MORE THAN ONE PIC"
        detail = ", ".join(
            "%d(x%d)" % (p, len(ids)) for p, ids in sorted(pics.items()))
        print("class %3d  %-18s -> pic %s%s"
              % (cls, class_names.get(cls, "?"), detail, flag))

    print()
    print("classes with more than one pic:", multi)
    print("pic table holds %d entries, so a class id can land inside it by "
          "accident up to %d." % (PIC_COUNT, PIC_COUNT - 1))
    print()
    print("pic id range actually referenced:",
          min(p for pics in by_class.values() for p in pics),
          "..", max(p for pics in by_class.values() for p in pics))


if __name__ == "__main__":
    main()
