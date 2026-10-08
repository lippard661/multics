"""Parsers for the Multics object-description commands, plus clock decoding.

print_link_info PATH -long   (pli -lg, alias plk in some sites)
    Creation date, translator, source paths and dates, section Start/Length
    table, the definitions (entry points with their text offsets), and the
    links (link|N -> external name).  The link offsets are what the code
    references as pr4|N,* .

print_bind_map PATH -long    (pbm -lg)
    For a bound segment: one row per component with its text start and
    length, internal static and symbol ranges, compile date and language.

Both parsers take the command output as text and are tolerant of the
surrounding header lines.
"""
import datetime
import re


def parse_plk(text):
    info = {'links': {}, 'defs': [], 'sources': [], 'start': {}, 'length': {},
            'created': None, 'translator': None, 'compiler': None}
    seg = None
    hdr = None
    for line in text.splitlines():
        s = line.strip()
        m = re.match(r'Created on (.*)', s)
        if m and info['created'] is None:
            info['created'] = m.group(1)
        m = re.match(r'using (.*)', s)
        if m and info['compiler'] is None:
            info['compiler'] = m.group(1)
        m = re.match(r'Translator:\s+(.*)', s)
        if m:
            info['translator'] = m.group(1)
        m = re.match(r'(\d\d/\d\d/\d\d\s+\d{4}\.\d .*?)\s+(>\S+)$', s)
        if m:
            info['sources'].append((m.group(1).strip(), m.group(2)))
        m = re.match(r'\s*(Object|Start|Length)\s+(.*)', line)
        if m:
            if m.group(1) == 'Object':
                hdr = m.group(2).split()
            elif hdr:
                vals = m.group(2).split()
                info[m.group(1).lower()] = {k: int(v, 8) for k, v in zip(hdr, vals)}
        m = re.match(r'segnames?:\s+(\S+)', s)
        if m:
            seg = m.group(1)
        m = re.match(r'(text|symb|link|stat|defs)\|([0-7]+)\s+(\S+)\s*(\S*)', s)
        if m and m.group(1) != 'link':
            info['defs'].append({'section': m.group(1), 'offset': int(m.group(2), 8),
                                 'name': m.group(3), 'class': m.group(4), 'segname': seg})
        elif m and m.group(1) == 'link':
            info['links'][int(m.group(2), 8)] = m.group(3)
    return info


def parse_pbm(text):
    """Return a list of components: name, text_start, text_length (octal ints),
    stat_start/len, symb_start/len, date, language."""
    comps = []
    in_table = False
    for line in text.splitlines():
        if re.match(r'\s*Component\s+Text', line):
            in_table = True
            continue
        if in_table:
            m = re.match(r'\s*(\S+)\s+([0-7]+)\s+([0-7]+)\s+([0-7]+)\s+([0-7]+)\s+([0-7]+)\s+([0-7]+)\s+'
                         r'(\d\d/\d\d/\d\d\s+\d{4}\.\d)\s+(.*)$', line)
            if m:
                comps.append({'name': m.group(1),
                              'text_start': int(m.group(2), 8), 'text_length': int(m.group(3), 8),
                              'stat_start': int(m.group(4), 8), 'stat_length': int(m.group(5), 8),
                              'symb_start': int(m.group(6), 8), 'symb_length': int(m.group(7), 8),
                              'compiled': m.group(8), 'language': m.group(9).strip()})
            elif line.strip().startswith('Bindfile'):
                in_table = False
    return comps


EPOCH = datetime.datetime(1901, 1, 1)


def clock(hi, lo):
    """A Multics clock value (fixed bin (71), microseconds since
    1901-01-01 0000 GMT) stored in two words, as a UTC datetime."""
    return EPOCH + datetime.timedelta(microseconds=(hi << 36) | lo)


def plausible_clock(hi):
    """True if a word looks like the high half of a 1960s-2030s clock value."""
    return 0o070000 <= hi <= 0o200000
