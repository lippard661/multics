"""Load the output of the Multics dump_segment command into a word map.

Expected input: `dump_segment PATH -character` (ds -ch) output, e.g.

    000000 404000000021 404000000025 526000000000 404000000043 ...............#
    000004 464000000000 000002000004 000003000000 000005000000 ................
    ======
    001400 040040040040 ...

* Each data line is a 6-digit octal word address followed by 1-4 twelve-digit
  octal words (36-bit words) and, with -character, an ASCII rendering.
* A line of "======" means dump_segment suppressed one or more lines that were
  identical to the line before it.  They are filled in by repeating that line's
  words up to the next printed address.
* Header lines (pathname, date) and blank lines are ignored.

Returns a dict {word_address: 36-bit int}.
"""
import re

_LINE = re.compile(r'^\s*([0-7]{6})((?:\s+[0-7]{12}){1,4})')


def load(path):
    mem = {}
    last_addr = None
    last_words = None
    pending_repeat = False
    with open(path, errors='replace') as f:
        for line in f:
            m = _LINE.match(line)
            if m:
                addr = int(m.group(1), 8)
                words = [int(w, 8) for w in m.group(2).split()]
                if pending_repeat and last_addr is not None:
                    step = len(last_words)
                    for base in range(last_addr + step, addr, step):
                        for i, w in enumerate(last_words):
                            mem[base + i] = w
                pending_repeat = False
                for i, w in enumerate(words):
                    mem[addr + i] = w
                last_addr, last_words = addr, words
            elif line.strip().startswith('======'):
                pending_repeat = True
    return mem


def chars(w):
    """The four 9-bit characters of a word, as integers."""
    return [(w >> (27 - 9 * i)) & 0o777 for i in range(4)]


def ascii(w):
    return ''.join(chr(c) if 32 <= c < 127 else '.' for c in chars(w))


def string_at(mem, word_addr, char_offset, length):
    """Characters starting char_offset 9-bit characters into word_addr."""
    out = []
    for k in range(length):
        n = char_offset + k
        c = chars(mem.get(word_addr + n // 4, 0))[n % 4]
        out.append(chr(c) if c < 128 else '?')
    return ''.join(out)
