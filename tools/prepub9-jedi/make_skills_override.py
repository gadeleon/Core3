# Copy the client's skills.iff and make the pre-Pub9 Jedi boxes visible (GOD_ONLY=0, IS_HIDDEN=0),
# as they were live up to patch_08, but only to Jedi state 2 and up (JEDI_STATE_REQUIRED=2), the way
# the client already hides the Pub9 Force trees. Edits 4-byte values in place, so the IFF layout is unchanged.
# Usage: SWG_TRE=/path/to/client python3 make_skills_override.py <output skills.iff>
import os, sys, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import tre
out = sys.argv[1]
arc, d = tre.get("datatables/skill/skills.iff")
d = bytearray(d)

def find(tag, p=0, end=None):
    end = len(d) if end is None else end
    while p + 8 <= end:
        t = bytes(d[p:p+4]); sz = struct.unpack(">I", d[p+4:p+8])[0]
        if t == b"FORM":
            r = find(tag, p + 12, p + 8 + sz)
            if r: return r
        elif t == tag.encode():
            return p + 8, sz
        p += 8 + sz

cols, _ = find("COLS"); typ, _ = find("TYPE"); rows, _ = find("ROWS")
nc = struct.unpack_from("<I", d, cols)[0]
names = [x.decode() for x in bytes(d[cols+4:]).split(b"\0")[:nc]]
types = [x.decode() for x in bytes(d[typ:]).split(b"\0")[:nc]]
gi, hi, ji = names.index("GOD_ONLY"), names.index("IS_HIDDEN"), names.index("JEDI_STATE_REQUIRED")
nr = struct.unpack_from("<I", d, rows)[0]; p = rows + 4; changed = 0
for _ in range(nr):
    offs = []
    for t in types:
        offs.append(p)
        if t[0].lower() in "ihbef": p += 4
        else: p = d.index(b"\0", p) + 1
    name = bytes(d[offs[0]:d.index(b"\0", offs[0])]).decode()
    if name == "jedi" or name.startswith("jedi_"):
        for c, value in ((gi, 0), (hi, 0), (ji, 2)):
            if struct.unpack_from("<i", d, offs[c])[0] != value:
                struct.pack_into("<i", d, offs[c], value); changed += 1
open(out, "wb").write(d)
print("source", arc, "rows", nr, "values changed", changed)
