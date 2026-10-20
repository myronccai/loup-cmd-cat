# Design: cat

## Overview

`main()` passes `runtime.args()` to `cli.app.run`, which parses the arguments
into `Options`, handles `--help` and `--version`, and calls
`commands.cat.run_cat`. `run_cat` reads each operand whole and writes it out;
when any line option is set it first passes the text through `render`, a pure
function that returns the output together with the state carried to the next
operand. The tests call `render` and the parser directly.

## Modules

| Module | Contents |
|---|---|
| `source/main.loup` | entry point: `run(runtime.args())` |
| `source/appinfo.loup` | name, version, summary, exit statuses (usage errors are status 1, as in GNU cat) |
| `source/cli/args.loup` | `Options`, `match_long` (getopt_long's exact-or-unique-prefix rule), `parse_args` |
| `source/cli/usage.loup` | `usage()` help text, `version_line()` |
| `source/cli/app.loup` | `run()`: parse, help/version, run the command, map exceptions to status 1 |
| `source/commands/cat.loup` | `State`, `Rendered`, `number_field`, `visible_byte`, `visible_text`, `render`, `finish`, `operand_problem`, `io_reason`, `run_cat` |

## Data

- `Options`: one `bool` per option (`number`, `number_nonblank`,
  `squeeze_blank`, `show_ends`, `show_tabs`, `show_nonprinting`) plus
  `help`, `version` and the operands. `-A`, `-e` and `-t` set several flags.
- `State`: what GNU cat keeps between files. `newlines` counts the newlines
  just seen in a row (-1 inside a line, 0 at the start of one, 1 after one
  empty line, capped at 2); `line_number` is the last number printed;
  `pending_cr` is a `\r` held back at the end of an operand because, under
  `-E`, it prints as `^M` only if a newline follows.
- `Rendered`: the output text and the next `State`.

## Rendering

`render` splits the text on `\n`. For each piece it prints a line number if
the piece starts a line, then the piece with `-T` applied, then, if a
newline followed it, the newline itself with GNU's blank-line rules: the
second and later newlines of a run are empty lines, dropped under `-s`,
numbered under `-n` but not `-b`, and every printed newline gets a `$` under
`-E`.

Loup strings hold the bytes they were read with: iterating one yields a unit
per UTF-8 character, and bytes that are not valid UTF-8 come out as units of
their own, so `\n`, `\t` and `\r` are always separate units and lines can be
split and joined without changing any other byte. Under `-v`, `run_cat`
reads the operand as `bytes` instead and `visible_text` turns every byte
except newline into its `^`/`M-` notation (from a 256-entry table built once,
since a native build never frees strings made per byte). The result is plain
ASCII, which `render` then numbers and squeezes like any other text.

With no line option set, `run_cat` prints the text as read, which is both
exact and fast.

## Differences from GNU cat

- Each operand is read whole before it is written (Loup 1.26.0 has no
  streaming reads, ROADMAP T2), so `cat` on an endless stream, such as
  `cat /dev/zero`, never prints anything and memory grows with the input.
- An operand that exists but cannot be read (no read permission) stops the
  native binary with the runtime's own message
  (`IoError: read_text failed on 'NAME': Permission denied (os error 13)`) and
  status 1, and later operands are not read: the native runtime cannot raise
  a catchable `IoError`, and Loup has no `stat()` to check permissions first
  (T1). Missing files and directories are detected beforehand and reported as
  GNU does.
- Memory grows with the input: about 4 bytes per input byte for `-n`, 17 for
  `-v`.
- `--version` prints one line.
- The "input file is output file" check is not made.

## Error handling

`operand_problem` returns GNU's reason for a missing operand or a directory,
and `run_cat` prints `cat: NAME: REASON`, sets status 1 and moves on. A read
that throws `IoError` (possible under `loup run`) is reported the same way.
Usage errors come back from `parse_args` as `Err(message)`; `run` prints them
with the `Try 'cat --help'` line and returns 1.

## Testing

- `tests/args_test.loup`: short, combined and long options, abbreviations,
  ambiguity, `--`, operand order, errors.
- `tests/cat_test.loup`: `render` for every option and their combinations,
  state carried across operands, `number_field`, `visible_byte`,
  `unit_bytes`, `operand_problem`.
- `tests/app_test.loup`: exit statuses through `run()`.
- `tests/e2e.sh`: runs the native binary on files under `$TMP` and on
  standard input, comparing output byte for byte, including NUL and
  non-UTF-8 bytes, error messages and statuses.
