#!/usr/bin/env python3
"""mxdis: a disassembler for Multics (DPS-8/Honeywell 6180) object code,
aimed at reconstructing PL/I source from compiled object segments.

Input is the text output of Multics commands run on the object segment:

  dump_segment PATH -character   > NAME.dump   (required: the words)
  print_link_info PATH -long     > NAME.plk    (recommended: links, entries)
  print_bind_map PATH -long      > NAME.pbm    (bound segments: components)

Usage:
  python3 mxdis.py NAME.dump [--plk NAME.plk] [--pbm NAME.pbm]
                   [--range START END] [--outdir DIR] [--no-calls]

With --pbm, writes one COMPONENT.dis per bound component into --outdir
(default: current directory).  Without it, disassembles the whole text
section (from the plk Start/Length table) or --range (octal word
addresses, END exclusive) to standard output.

  python3 mxdis.py NAME.dump --symbols
prints every printable string run and every plausible clock-value pair
in the dump (compiler names, source pathnames, user ids and dates live in
the symbol section).

Annotations in the output:
  ; <link name>          pr4|N,* references, from the plk link table
  ; static/linkage+N     pr4|N without indirection (internal static lives
                         in the linkage section; per-process static in a
                         bound segment with perprocess_static)
  ; op <name>            pl1_operators_ entries (pr0|N), from opnames.py
  = "string"             EIS descriptors and ic-relative constants (EIS
                         descriptor offsets are relative to the address of
                         the EIS instruction word, not the descriptor)
  [word 'ascii' desc]    the constant word an ic-relative epp2/lda/... uses,
                         decoded as an argument descriptor where it is one
  ;; CALL target(args)   reconstructed from the arg-list building sequence
  <<< name >>>           entry points from the plk definitions

This is a working tool, not a complete DPS-8 disassembler: unknown opcodes
print as .word, and the instruction set coverage is what PL/I-compiled
code (and a little ALM) uses.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dumpload  # noqa: E402
import mxinfo  # noqa: E402
from opnames import OPNAMES  # noqa: E402

# ---------------------------------------------------------------- opcodes
OPS = {}


def _o(code, name, ext=0):
    OPS[(code, ext)] = name


for _n, _c in [
        ('lda', 0o235), ('ldq', 0o236), ('ldaq', 0o237), ('sta', 0o755), ('stq', 0o756), ('staq', 0o757),
        ('stz', 0o450), ('ada', 0o075), ('adq', 0o076), ('adaq', 0o077), ('sba', 0o175), ('sbq', 0o176),
        ('sbaq', 0o177), ('asa', 0o055), ('asq', 0o056), ('aos', 0o054), ('ssa', 0o155), ('ssq', 0o156),
        ('cmpa', 0o115), ('cmpq', 0o116), ('cmpaq', 0o117), ('ana', 0o375), ('anq', 0o376), ('anaq', 0o377),
        ('ora', 0o275), ('orq', 0o276), ('oraq', 0o277), ('era', 0o675), ('erq', 0o676), ('eraq', 0o677),
        ('ansa', 0o355), ('ansq', 0o356), ('orsa', 0o255), ('orsq', 0o256), ('ersa', 0o655), ('ersq', 0o656),
        ('cana', 0o315), ('canq', 0o316), ('canaq', 0o317),
        ('als', 0o735), ('qls', 0o736), ('lls', 0o737), ('ars', 0o731), ('qrs', 0o732), ('lrs', 0o733),
        ('alr', 0o775), ('qlr', 0o776), ('llr', 0o777), ('arl', 0o771), ('qrl', 0o772), ('lrl', 0o773),
        ('mpy', 0o402), ('mpf', 0o401), ('div', 0o506), ('dvf', 0o507), ('neg', 0o531), ('negl', 0o533),
        ('eaa', 0o635), ('eaq', 0o636), ('lca', 0o335), ('lcq', 0o336), ('lcaq', 0o337),
        ('tra', 0o710), ('tze', 0o600), ('tnz', 0o601), ('tnc', 0o602), ('trc', 0o603), ('tmi', 0o604),
        ('tpl', 0o605), ('ttf', 0o607), ('tov', 0o617), ('rtcd', 0o610), ('call6', 0o713), ('ret', 0o630),
        ('stca', 0o751), ('stcq', 0o752), ('stba', 0o551), ('stbq', 0o552), ('stc1', 0o554), ('stc2', 0o750),
        ('stcd', 0o357), ('ldi', 0o634), ('sti', 0o754), ('nop', 0o011), ('rpt', 0o520), ('rpd', 0o560),
        ('rpl', 0o500), ('sreg', 0o753), ('lreg', 0o073), ('fld', 0o431), ('dfld', 0o433), ('fst', 0o455),
        ('dfst', 0o457), ('fad', 0o475), ('fsb', 0o575), ('fmp', 0o461), ('fdv', 0o565), ('fcmp', 0o515),
        ('fneg', 0o513), ('fno', 0o573), ('ufa', 0o435), ('cmg', 0o405), ('cmk', 0o211), ('xec', 0o716),
        ('xed', 0o717), ('stac', 0o354), ('stacq', 0o654), ('ldac', 0o034), ('ldqc', 0o032), ('szn', 0o234),
        ('sznc', 0o214)]:
    _o(_c, _n)
for _i in range(8):
    _o(0o220 + _i, 'ldx%d' % _i)
    _o(0o720 + _i, 'lxl%d' % _i)
    _o(0o740 + _i, 'stx%d' % _i)
    _o(0o440 + _i, 'sxl%d' % _i)
    _o(0o620 + _i, 'eax%d' % _i)
    _o(0o700 + _i, 'tsx%d' % _i)
    _o(0o100 + _i, 'cmpx%d' % _i)
    _o(0o060 + _i, 'adx%d' % _i)
    _o(0o160 + _i, 'sbx%d' % _i)
    _o(0o320 + _i, 'lcx%d' % _i)
    _o(0o540 + _i, 'sprp%d' % _i)
    _o(0o760 + _i, 'lprp%d' % _i)
# pointer-register instructions: the 10th opcode bit (ext) selects 0-3 / 4-7
for _i, (_c, _e) in enumerate([(0o350, 0), (0o351, 1), (0o352, 0), (0o353, 1),
                               (0o370, 0), (0o371, 1), (0o372, 0), (0o373, 1)]):
    _o(_c, 'epp%d' % _i, _e)
for _i, (_c, _e) in enumerate([(0o250, 0), (0o251, 1), (0o252, 0), (0o253, 1),
                               (0o650, 0), (0o651, 1), (0o652, 0), (0o653, 1)]):
    _o(_c, 'spri%d' % _i, _e)
for _i, _c in enumerate([0o270, 0o271, 0o272, 0o273, 0o670, 0o671, 0o672, 0o673]):
    _o(_c, 'tsp%d' % _i)
_o(0o604, 'tmoz', 1)
_o(0o605, 'tpnz', 1)
_o(0o606, 'ttn', 1)
# EIS multiword instructions (ext=1): name, number of descriptor words
EIS = {0o100: ('mlr', 2), 0o101: ('mrl', 2), 0o020: ('mve', 3), 0o160: ('mvt', 3), 0o106: ('cmpc', 2),
       0o120: ('scd', 3), 0o121: ('scdr', 3), 0o124: ('scm', 3), 0o125: ('scmr', 3), 0o164: ('tct', 3),
       0o165: ('tctr', 3), 0o024: ('mvne', 3), 0o060: ('csl', 2), 0o061: ('csr', 2), 0o064: ('sztl', 2),
       0o065: ('sztr', 2), 0o066: ('cmpb', 2), 0o301: ('btd', 2), 0o305: ('dtb', 2), 0o300: ('mvn', 2),
       0o303: ('cmpn', 2), 0o202: ('ad2d', 2), 0o222: ('ad3d', 3), 0o203: ('sb2d', 2), 0o223: ('sb3d', 3)}
for _k, (_n, _) in EIS.items():
    _o(_k, _n, 1)
for _n, _c in [('a9bd', 0o500), ('a6bd', 0o501), ('a4bd', 0o502), ('abd', 0o503), ('awd', 0o507),
               ('s9bd', 0o520), ('s6bd', 0o521), ('s4bd', 0o522), ('sbd', 0o523), ('swd', 0o527)]:
    _o(_c, _n, 1)

REGN = {0: 'n', 1: 'au', 2: 'qu', 3: 'du', 4: 'ic', 5: 'al', 6: 'ql', 7: 'dl',
        8: 'x0', 9: 'x1', 10: 'x2', 11: 'x3', 12: 'x4', 13: 'x5', 14: 'x6', 15: 'x7'}

# PL/I argument-descriptor type codes (descriptor word: flag, 6-bit type,
# packed bit, 4-bit ndims, 24-bit size)
DTYPES = {1: 'fixed bin', 2: 'fixed bin long', 3: 'float bin', 4: 'float bin long', 9: 'fixed dec',
          10: 'float dec', 13: 'ptr', 14: 'offset', 15: 'label', 16: 'entry', 17: 'structure',
          18: 'area', 19: 'bit', 20: 'bit varying', 21: 'char', 22: 'char varying', 23: 'file'}


def s15(v):
    return v - 0o100000 if v & 0o40000 else v


def s18(v):
    return v - 0o1000000 if v & 0o400000 else v


def descriptor(w):
    """Decode an argument descriptor word, or return None."""
    if not (w >> 35) & 1:
        return None
    t = (w >> 29) & 0o77
    if t not in DTYPES:
        return None
    packed = (w >> 28) & 1
    ndims = (w >> 24) & 0o17
    size = w & 0o77777777
    name = DTYPES[t]
    if t in (1, 2, 9):
        p = size & 0o7777
        q = (size >> 12) & 0o7777
        s = '%s(%d%s)' % (name, p, ',%d' % q if q else '')
    elif t in (3, 4, 10):
        s = '%s(%d)' % (name, size & 0o7777)
    elif t in (19, 20, 21, 22):
        s = '%s(%s)' % (name, '*' if size == 0o77777777 else ('<length filled in at run time>' if size == 0 else str(size)))
        if t in (19, 21) and not packed:
            s += ' aligned'
    else:
        s = name
    if ndims:
        s += ' [%d dims]' % ndims
    return s


def tagstr(t):
    tm, td = t >> 4, t & 0o17
    r = REGN.get(td, '?%o' % td)
    if tm == 0:
        return r
    if tm == 1:
        return '*' if td == 0 else r + '*'
    if tm == 2:
        return '*' + r if td else '*'
    return 'it%o' % td


class Disassembler:
    def __init__(self, mem, links=None, entries=None, static_note='static/linkage'):
        self.m = mem
        self.links = links or {}
        self.entries = entries or {}
        self.static_note = static_note

    def w(self, a):
        return self.m.get(a, 0)

    def operand(self, w, addr):
        """Return (text, ic_target or None, pr, offset, indirect)."""
        y = w >> 18
        a = (w >> 6) & 1
        t = w & 0o77
        ts = tagstr(t)
        if a:
            pr = y >> 15
            off = s15(y & 0o77777)
            s = 'pr%d|%s' % (pr, ('%o' % off) if off >= 0 else '-%o' % -off)
            if ts and ts != 'n':
                s += ',' + ts
            return s, None, pr, off, t == 0o20
        if ts == 'ic':
            off = s18(y)
            tgt = (addr + off) & 0o777777
            return '%+d (=%o)' % (off, tgt), tgt, None, None, False
        s = '%o' % y
        if ts and ts != 'n':
            s += ',' + ts
        return s, None, None, None, False

    def eis_desc(self, inst_addr, d, mf):
        ar = (mf >> 6) & 1
        rl = (mf >> 5) & 1
        idf = (mf >> 4) & 1
        reg = mf & 0o17
        y = d >> 18
        cn = (d >> 15) & 7
        ta = (d >> 13) & 3
        n = d & 0o7777
        if idf:
            return 'indirect descriptor at %o' % y, None
        if ar:
            loc = 'pr%d|%o' % (y >> 15, y & 0o77777)
        else:
            loc = '%o' % y
        if reg:
            loc += ',' + REGN[reg]
        ln = REGN.get(n & 0o17, '?') if rl else str(n)
        text = '%s(cn%d),%s,len=%s' % (loc, cn, ['9bit', '6bit', '4bit', '?'][ta], ln)
        lit = None
        if reg == 4 and not ar and not rl and ta == 0:
            # ic-relative constant: offset from the EIS instruction word
            base = (inst_addr + s18(y)) & 0o777777
            lit = dumpload.string_at(self.m, base, cn // 2 if ta == 0 else cn, n)
        return text, lit

    def disassemble(self, start, end, calls=True):
        out = []
        a = start
        last_src = None      # description of the last epp2 operand
        slots = {}           # pr6 offset -> (text, ic address)
        base = None
        nargs = None
        target = None
        in_range = [x for x in self.entries if start <= x < end]
        data_until = min(in_range) if in_range else start
        while a < end:
            if a in self.entries:
                out.append('')
                out.append('<<< %s >>>' % ', '.join(self.entries[a]))
            w = self.w(a)
            if a < data_until:
                # constants (descriptors, strings, entry info) before the
                # first entry point of this range
                dd = descriptor(w)
                out.append('%06o  %012o  data   "%s"%s' % (a, w, dumpload.ascii(w), ('   desc ' + dd) if dd else ''))
                a += 1
                continue
            op = (w >> 9) & 0o777
            ext = (w >> 8) & 1
            name = OPS.get((op, ext))
            if ext and op in EIS:
                n, nd = EIS[op]
                mfs = [w & 0o177, (w >> 18) & 0o177, (w >> 27) & 0o177]
                out.append('%06o  %012o  %-6s' % (a, w, n))
                for i in range(nd):
                    d = self.w(a + 1 + i)
                    is_arg = ((n in ('tct', 'tctr') and i >= 1) or (n in ('scm', 'scmr', 'scd', 'scdr') and i == 2)
                              or (n == 'mvt' and i == 2))
                    if is_arg:
                        y = d >> 18
                        loc = ('pr%d|%o' % (y >> 15, y & 0o77777)) if (d >> 6) & 1 else '%o' % y
                        out.append('%06o  %012o      arg%d  %s' % (a + 1 + i, d, i + 1, loc))
                    else:
                        txt, lit = self.eis_desc(a, d, mfs[i])
                        line = '%06o  %012o      desc%d %s' % (a + 1 + i, d, i + 1, txt)
                        if lit is not None:
                            line += '   = %r' % lit
                        out.append(line)
                a += 1 + nd
                continue
            if not name:
                out.append('%06o  %012o  %-6s "%s"' % (a, w, '.word', dumpload.ascii(w)))
                a += 1
                continue
            opd, ictgt, pr, off, ind = self.operand(w, a)
            note = ''
            if pr == 4 and ind and off in self.links:
                note = '  ; ' + self.links[off]
            elif pr == 4 and not ind and off is not None and off >= 8:
                note = '  ; %s+%o' % (self.static_note, off)
            elif pr == 0 and off in OPNAMES:
                note = '  ; op ' + OPNAMES[off]
            elif pr == 2 and off in (0o1045, 0o1046, 0o1047):
                note = '  ; op ' + OPNAMES[off] + ' (entry sequence)'
            if ictgt is not None and name not in ('tra', 'tze', 'tnz', 'tmi', 'tpl', 'tmoz', 'tpnz', 'ttn',
                                                  'ttf', 'tnc', 'trc', 'tov') and not name.startswith('tsx') \
                    and not name.startswith('tsp'):
                cw = self.w(ictgt)
                dd = descriptor(cw)
                note += '   [%012o %r%s]' % (cw, dumpload.ascii(cw), (' = ' + dd) if dd else '')
            out.append('%06o  %012o  %-6s %s%s' % (a, w, name, opd, note))
            # ---- call tracking
            if calls:
                if name == 'epp2':
                    if pr == 4 and ind:
                        last_src = (self.links.get(off, 'link|%o' % off), None)
                    elif ictgt is not None:
                        last_src = ('text|%o' % ictgt, ictgt)
                    elif pr is None and (w & 0o77) == 0:
                        # direct text address: a binder-resolved call to
                        # another component of a bound segment
                        y = w >> 18
                        last_src = ('/'.join(self.entries[y]) if y in self.entries else 'text|%o' % y, y)
                    else:
                        last_src = (opd, None)
                    target = last_src[0]
                elif name == 'spri2' and pr == 6:
                    slots[off] = last_src
                elif name == 'eax1' and pr == 6:
                    base = off
                elif name == 'fld' and (w & 0o77) == 7:
                    nargs = (w >> 18) >> 11
                elif name == 'tsx0' and pr == 0 and off in (0o616, 0o617, 0o622, 0o623, 0o624, 0o625, 0o627) \
                        and base is not None and nargs is not None:
                    withdesc = off in (0o616, 0o622, 0o624)
                    args = []
                    for i in range(nargs):
                        s = slots.get(base + 2 + 2 * i)
                        txt = s[0] if s else '?'
                        if withdesc:
                            # calls through an entry variable (and internal
                            # calls) carry an environment pointer after the
                            # argument pointers, before the descriptors
                            gap = 2 if off in (0o616, 0o624) else 0
                            ds = slots.get(base + 2 + 2 * nargs + gap + 2 * i)
                            if ds and ds[1] is not None:
                                dd = descriptor(self.w(ds[1]))
                                if dd:
                                    txt += ' : ' + dd
                        args.append(txt)
                    kind = {0o616: 'entry variable', 0o617: 'entry variable', 0o624: 'internal',
                            0o625: 'internal', 0o627: 'internal (other block)'}.get(off, '')
                    out.append('        ;; CALL %s%s (%s)' % (target, (' [%s]' % kind) if kind else '',
                                                           ', '.join(args)))
                    slots, base, nargs = {}, None, None
            a += 1
        return out


def symbols(mem):
    """Printable runs and plausible clock pairs (for the symbol section)."""
    out = []
    addrs = sorted(mem)
    run, run_start = '', None
    for a in addrs:
        txt = ''.join(chr(c) if 32 <= c < 127 else '\0' for c in dumpload.chars(mem[a]))
        for k, ch in enumerate(txt):
            if ch != '\0':
                if not run:
                    run_start = (a, k)
                run += ch
            else:
                if len(run.strip()) >= 4:
                    out.append('%06o(%d)  str  %r' % (run_start[0], run_start[1], run))
                run = ''
        hi = mem[a]
        if mxinfo.plausible_clock(hi) and (a + 1) in mem:
            try:
                out.append('%06o     clock %s UTC' % (a, mxinfo.clock(hi, mem[a + 1]).strftime('%Y-%m-%d %H:%M:%S')))
            except OverflowError:
                pass
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('dump')
    ap.add_argument('--plk')
    ap.add_argument('--pbm')
    ap.add_argument('--range', nargs=2, metavar=('START', 'END'))
    ap.add_argument('--outdir', default='.')
    ap.add_argument('--no-calls', action='store_true')
    ap.add_argument('--symbols', action='store_true')
    ns = ap.parse_args()

    mem = dumpload.load(ns.dump)
    if ns.symbols:
        print('\n'.join(symbols(mem)))
        return
    links, entries, text_len = {}, {}, None
    if ns.plk:
        info = mxinfo.parse_plk(open(ns.plk).read())
        links = info['links']
        for d in info['defs']:
            if d['section'] == 'text':
                entries.setdefault(d['offset'], []).append(d['name'])
        text_len = info['length'].get('Text')
    dis = Disassembler(mem, links, entries)
    calls = not ns.no_calls
    if ns.range:
        s, e = int(ns.range[0], 8), int(ns.range[1], 8)
        print('\n'.join(dis.disassemble(s, e, calls)))
    elif ns.pbm:
        comps = mxinfo.parse_pbm(open(ns.pbm).read())
        os.makedirs(ns.outdir, exist_ok=True)
        for c in comps:
            s, e = c['text_start'], c['text_start'] + c['text_length']
            path = os.path.join(ns.outdir, c['name'] + '.dis')
            with open(path, 'w') as f:
                f.write('; %s  text %o-%o  compiled %s  %s\n' % (c['name'], s, e, c['compiled'], c['language']))
                f.write('\n'.join(dis.disassemble(s, e, calls)) + '\n')
            print('wrote', path)
    else:
        e = text_len if text_len is not None else max(mem) + 1
        print('\n'.join(dis.disassemble(0, e, calls)))


if __name__ == '__main__':
    main()
