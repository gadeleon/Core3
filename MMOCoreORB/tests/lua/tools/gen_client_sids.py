#!/usr/bin/env python3
"""Generate the client string-id fixtures (tests/lua/fixtures/string/en/<FILE>.sids).

Purpose: the pre-NGE client resolves "@<file>:<id>" from the string tables (.stf) in
the TRE archives the server loads. The Lua tests cannot read TRE (no zlib in Lua 5.3),
so this maintenance tool extracts every id once and the committed .sids files are what
the tests read. run.sh needs neither /tre nor Python.

Read-only guarantee: TRE archives are only ever opened with "rb". The tool writes
nothing but tests/lua/fixtures/string/en/<FILE>.sids (and, with --check, nothing).
Regenerate fixtures with this tool, never edit them by hand.

Usage (run from MMOCoreORB/):
  python3 tests/lua/tools/gen_client_sids.py [--tre-dir DIR] [--fixture-dir DIR] [--check] [FILE ...]

FILE is a string-file path without "string/en/" and ".stf", e.g. conversation/naboo_privateer_tier4,
skl_n or space/space_loot. With no FILE, every file referenced by an "@<file>:<id>" literal in the
space conversation sources is processed, together with every existing .sids fixture.
The first archive in the bin/conf/config.lua TreFiles order that holds the file wins; a
zero-length newest entry (a deleted file) or a file in no archive is an error, and so is any archive of the
TreFiles order that is missing from --tre-dir (in write and --check mode alike: a skipped archive could hide the
newest copy of a file and write a stale fixture).
--check writes nothing, lists differing or missing fixtures and exits 1 if any.
--fixture-dir points at another fixture tree (for example a scratch copy).

--quest-names handles one more fixture instead of the .sids files: fixtures/misc/quest_crc_string_table.names, the
list of quest names (one "spacequest/<type>/<name>" per line, byte-sorted, LF) of the client's misc/quest_crc_string_table.iff
(first archive of the TreFiles order that holds it). The client maps journal CRCs to quests through this table, so a quest
name that is not in it (case matters) has no readable journal entry. With --check it writes nothing and exits 1 on a
difference; --names-file overrides the path (for a scratch copy).
"""
import argparse
import os
import re
import struct
import sys
import zlib

sys.dont_write_bytecode = True  # never leave a __pycache__ in the tests tree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))  # MMOCoreORB/
DEFAULT_FIXTURES = os.path.join(ROOT, "tests", "lua", "fixtures", "string", "en")
SOURCE_DIRS = [
    "bin/scripts/mobile/conversations/space",
    "bin/scripts/screenplays/space/conversations",
]
LITERAL = re.compile(r'"@([\w/]+):([\w]+)"')


QUEST_TABLE = b"misc/quest_crc_string_table.iff"
DEFAULT_NAMES = os.path.join(ROOT, "tests", "lua", "fixtures", "misc", "quest_crc_string_table.names")


class GenError(Exception):
    pass


def tre_order():
    text = open(os.path.join(ROOT, "bin", "conf", "config.lua")).read()
    m = re.search(r"TreFiles\s*=\s*\{(.*?)\}", text, re.S)
    if not m:
        raise GenError("TreFiles list not found in bin/conf/config.lua")
    names = re.findall(r'"([^"]+\.tre)"', re.sub(r"--[^\n]*", "", m.group(1)))
    return names


class Tre:
    def __init__(self, path):
        self.path = path
        self.f = open(path, "rb")
        hdr = self.f.read(36)
        _, _, n, toc_off, toc_c, toc_sz, blk_c, blk_sz, _ = struct.unpack("<4s4s7I", hdr)
        self.f.seek(toc_off)
        toc = self.f.read(toc_sz)
        toc = zlib.decompress(toc) if toc_c else toc
        names = self.f.read(blk_sz)
        names = zlib.decompress(names) if blk_c else names
        self.entries = {}
        for i in range(n):
            _, ln, off, c, cl, no = struct.unpack_from("<6I", toc, i * 24)
            name = names[no:names.index(b"\0", no)]
            self.entries[name] = (ln, off, c, cl)

    def read(self, name):
        ln, off, c, cl = self.entries[name]
        if ln == 0:
            return b""
        self.f.seek(off)
        d = self.f.read(cl if c else ln)
        return zlib.decompress(d) if c else d

    def close(self):
        self.f.close()


def parse_ids(d):
    _, _, _, cnt = struct.unpack_from("<IBII", d, 0)
    p = 13
    for _ in range(cnt):
        _, _, nc = struct.unpack_from("<III", d, p)
        p += 12 + nc * 2
    ids = []
    for _ in range(cnt):
        _, nl = struct.unpack_from("<II", d, p)
        p += 8
        ids.append(d[p:p + nl].decode())
        p += nl
    return ids


def iff_chunks(b, off, end):
    while off < end:
        tag = b[off:off + 4]
        ln = struct.unpack(">I", b[off + 4:off + 8])[0]
        if tag == b"FORM":
            yield from iff_chunks(b, off + 12, off + 8 + ln)
        else:
            yield tag, b[off + 8:off + 8 + ln]
        off += 8 + ln


def parse_quest_names(d):
    c = dict(iff_chunks(d, 0, len(d)))
    n = struct.unpack("<I", c[b"DATA"])[0]
    offs = struct.unpack("<%dI" % n, c[b"STRT"])
    s = c[b"STNG"]
    names = [s[o:s.index(b"\0", o)] for o in offs]
    return sorted(set(names))


class Archives:
    def __init__(self, tre_dir):
        self.tre_dir = tre_dir
        self.cache = {}

    def open(self, name):
        if name not in self.cache:
            path = os.path.join(self.tre_dir, name)
            self.cache[name] = Tre(path) if os.path.exists(path) else None
        return self.cache[name]

    def ids_for(self, file):
        target = ("string/en/%s.stf" % file).encode()
        for name in tre_order():
            t = self.open(name)
            if t is not None and target in t.entries:
                data = t.read(target)
                if not data:
                    raise GenError("%s: zero-length (deleted) entry in %s" % (file, name))
                return sorted(set(parse_ids(data)), key=lambda s: s.encode())
        raise GenError("%s: no archive in the TreFiles order holds %s" % (file, target.decode()))

    def quest_names(self):
        for name in tre_order():
            t = self.open(name)
            if t is not None and QUEST_TABLE in t.entries:
                data = t.read(QUEST_TABLE)
                if not data:
                    raise GenError("quest table: zero-length (deleted) entry in %s" % name)
                return parse_quest_names(data)
        raise GenError("quest table: no archive in the TreFiles order holds %s" % QUEST_TABLE.decode())

    def close(self):
        for t in self.cache.values():
            if t:
                t.close()


def referenced_files():
    files = set()
    for d in SOURCE_DIRS:
        for dp, _, fns in os.walk(os.path.join(ROOT, d)):
            for fn in fns:
                if fn.endswith(".lua"):
                    for line in open(os.path.join(dp, fn), errors="replace"):
                        for m in LITERAL.finditer(line):
                            files.add(m.group(1))
    return files


def existing_fixtures(fixture_dir):
    out = set()
    for dp, _, fns in os.walk(fixture_dir):
        for fn in fns:
            if fn.endswith(".sids"):
                rel = os.path.relpath(os.path.join(dp, fn), fixture_dir)
                out.add(rel[:-5].replace(os.sep, "/"))
    return out


def main():
    ap = argparse.ArgumentParser(description="Generate client string-id fixtures (read-only on /tre).")
    ap.add_argument("--tre-dir", default="/tre")
    ap.add_argument("--fixture-dir", default=DEFAULT_FIXTURES)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--quest-names", action="store_true")
    ap.add_argument("--names-file", default=DEFAULT_NAMES)
    ap.add_argument("files", nargs="*")
    a = ap.parse_args()

    missing = [n for n in tre_order() if not os.path.exists(os.path.join(a.tre_dir, n))]
    if missing:
        print("ERROR archive(s) of the config.lua TreFiles order missing from %s: %s" % (a.tre_dir, ", ".join(missing)), file=sys.stderr)
        return 2

    if a.quest_names:
        arch = Archives(a.tre_dir)
        try:
            body = b"".join(n + b"\n" for n in arch.quest_names())
        except GenError as e:
            print("ERROR " + str(e), file=sys.stderr)
            return 1
        finally:
            arch.close()
        if a.check:
            cur = open(a.names_file, "rb").read() if os.path.exists(a.names_file) else None
            if cur != body:
                print(("MISSING " if cur is None else "DIFFERS ") + a.names_file)
                return 1
            return 0
        os.makedirs(os.path.dirname(a.names_file), exist_ok=True)
        with open(a.names_file, "wb") as out:
            out.write(body)
        print("wrote %s (%d names)" % (a.names_file, body.count(b"\n")))
        return 0

    files = sorted(set(a.files) if a.files else referenced_files() | existing_fixtures(a.fixture_dir))
    arch = Archives(a.tre_dir)
    bad = 0
    try:
        for f in files:
            try:
                ids = arch.ids_for(f)
            except GenError as e:
                print("ERROR " + str(e), file=sys.stderr)
                bad += 1
                continue
            body = "".join(i + "\n" for i in ids).encode()
            path = os.path.join(a.fixture_dir, f + ".sids")
            if a.check:
                cur = open(path, "rb").read() if os.path.exists(path) else None
                if cur != body:
                    print(("MISSING " if cur is None else "DIFFERS ") + f + ".sids")
                    bad += 1
            else:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "wb") as out:
                    out.write(body)
                print("wrote %s (%d ids)" % (f, len(ids)))
    finally:
        arch.close()
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
