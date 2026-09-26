# Dump FRLG trainer class names straight out of the cart.
#
# Offsets come from the engine's own extractor (src/import/gba/versions.lua):
#   TRAINER_CLASS_NAMES = 0x23E558, stride 13, count 107
# so the table ends at 0x23E558 + 107*13 = 0x23EAC7, one byte before
# TRAINERS_TABLE (0x23EAC8) -- which is the arithmetic agreeing with itself.
#
#   python tools/dump_class_names.py

import os

ROM = os.environ.get("FIRERED_ROM", "Pokemon_FireRed.gba")
BASE, STRIDE, COUNT = 0x23E558, 13, 107

# Only the slots a class name actually uses.  The letters and digits come from
# the arithmetic ranges below (FRLG's charmap lays A-Z and a-z out contiguously);
# everything here is the punctuation around them.
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
    print("rom bytes =", len(data))
    print("table ends at", hex(BASE + COUNT * STRIDE))
    for cid in range(COUNT):
        name = decode(data, BASE + cid * STRIDE, STRIDE)
        print("%3d  %s" % (cid, name if name else "(blank)"))


if __name__ == "__main__":
    main()
