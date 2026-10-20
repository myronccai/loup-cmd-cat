# loup-cmd-cat

GNU `cat` recreated in [Loup](https://code-craft.ai/references/loup):
concatenate files (or standard input) to standard output, with line numbers,
blank-line squeezing and visible control characters.

Part of the **loup-cmd** series of example applications: classic Linux and
Windows commands, and projects for each Loup execution mode, each in its own
repository under [myronccai](https://github.com/myronccai?tab=repositories&q=loup-cmd).
This one is `host.dual` Loup built as a native binary.

## Requirements

- Loup 1.26.0 or later:

  ```sh
  curl -fsSL https://github.com/code-craft-ai-company/loup-releases/releases/latest/download/loup-install.sh | sh
  ```

- `make`, and `clang` 17 or later for the native build.

## Usage

```sh
make build                     # native binary: build/cat
make ci                        # check, unit tests, build, end-to-end tests
make run ARGS="-n README.md"   # run from source with loup run
```

```text
$ build/cat -n notes.txt
     1	alpha
     2	
     3	
     4	
     5	beta
$ build/cat -sb notes.txt
     1	alpha

     2	beta
$ build/cat -A dos.txt
name^Isize^M$
file^I42^M$
$ printf 'caf\303\251 \001\n' | build/cat -v
cafM-CM-) ^A
$ build/cat notes.txt missing.txt; echo "exit $?"
alpha



beta
cat: missing.txt: No such file or directory
exit 1
$ build/cat --show
cat: option '--show' is ambiguous; possibilities: '--show-nonprinting' '--show-ends' '--show-tabs' '--show-all'
Try 'cat --help' for more information.
$ build/cat --version
cat (loup-cmd-cat) 0.1.0
```

With no FILE, or when FILE is `-`, cat reads standard input. Files are copied
byte for byte, including NUL bytes and bytes that are not UTF-8.

| Option | Meaning |
|---|---|
| `-n`, `--number` | number all output lines |
| `-b`, `--number-nonblank` | number non-empty lines only; overrides `-n` |
| `-s`, `--squeeze-blank` | print one empty line in place of a run of them |
| `-E`, `--show-ends` | print `$` at the end of each line (`^M$` after a CR) |
| `-T`, `--show-tabs` | print TAB as `^I` |
| `-v`, `--show-nonprinting` | `^` and `M-` notation for control and high bytes, except newline and TAB |
| `-A`, `--show-all` | same as `-vET` |
| `-e` / `-t` | same as `-vE` / `-vT` |
| `-u` | ignored |

Short options combine (`-sn`), options may follow file names, `--` ends the
options, and long options may be shortened to any unique prefix
(`--squeeze`). Line numbers, blank-line runs and an unfinished last line
carry over from one file to the next, as in GNU cat.

Exit status: `0` on success; `1` if any operand could not be read or the
command line was invalid (GNU cat uses `1` for both).

## Differences from GNU cat

- Each file is read whole before it is written (Loup 1.26.0 has no streaming
  reads), so an endless input such as `cat /dev/zero` prints nothing, and
  memory grows with the input; `-v` needs about 17 bytes per input byte.
- A file that exists but cannot be read (no read permission) stops the native
  binary with the runtime's own message, e.g.
  `IoError: read_text failed on 'secret': Permission denied (os error 13)`,
  and status 1; later operands are not read. The native runtime cannot raise
  a catchable `IoError`, and Loup has no `stat()` to check permissions first.
  Missing files and directories are checked beforehand and reported as GNU
  does.
- The "input file is output file" check is not made.
- `--version` prints a single line.

## Layout

```text
source/main.loup            # entry point
source/appinfo.loup         # name, version, exit statuses
source/cli/args.loup        # GNU getopt-style option parsing
source/cli/usage.loup       # --help and --version text
source/cli/app.loup         # run(): parse, dispatch, exit status
source/commands/cat.loup    # reading operands, numbering, visible characters
tests/*_test.loup           # unit tests (make test)
tests/fixtures/             # files read by the unit tests
tests/e2e.sh                # end-to-end tests of build/cat (make e2e)
specs/cat/                  # requirements, design, tasks
```

[AGENTS.md](AGENTS.md) has every build and test command and the conventions
for changing the code.
