#!/usr/bin/env bash
# End-to-end tests: run the built binary and compare its standard output
# (byte for byte) and exit status with the expected ones.
#
# usage: tests/e2e.sh BINARY
#
# The cases run in a temporary directory holding the fixture files made
# below, so error messages show short names.

set -u
BIN=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

# check_file NAME STATUS EXPECTED_FILE [ARGS...]
# Runs BINARY ARGS... with standard input from the file named by $IN
# (default: /dev/null) and compares standard output with EXPECTED_FILE.
check_file() {
    local name=$1 want_status=$2 want_file=$3
    shift 3
    "$BIN" "$@" < "${IN:-/dev/null}" > "$TMP/out" 2> "$TMP/err"
    local status=$?
    if [ "$status" -eq "$want_status" ] && cmp -s "$want_file" "$TMP/out"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $name (exit $status, expected $want_status)"
        diff <(od -c "$want_file") <(od -c "$TMP/out") | sed 's/^/    /' | head -20
        sed 's/^/    stderr: /' "$TMP/err" | head -5
    fi
}

# check NAME STATUS EXPECTED_STDOUT [ARGS...]
# As check_file, with the expected output given as a string. Bash strings
# cannot hold NUL bytes; use check_file for output that contains them.
check() {
    local name=$1 want_status=$2
    printf '%s' "$3" > "$TMP/want"
    shift 3
    check_file "$name" "$want_status" "$TMP/want" "$@"
}

# check_err NAME STATUS EXPECTED_STDERR [ARGS...]
# Runs BINARY ARGS... and compares standard error and the exit status.
check_err() {
    local name=$1 want_status=$2 want_err=$3
    shift 3
    "$BIN" "$@" < "${IN:-/dev/null}" > "$TMP/out" 2> "$TMP/err"
    local status=$?
    if [ "$status" -eq "$want_status" ] && [ "$(cat "$TMP/err")" = "$want_err" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $name (exit $status, expected $want_status)"
        echo "    want stderr: $want_err"
        sed 's/^/    got stderr:  /' "$TMP/err" | head -5
    fi
}

cd "$TMP" || exit 1
printf 'one\ntwo\n' > a
printf 'three\n' > b
printf 'x' > partial
printf 'line\n\n\n\nnext\n\n' > blanks
printf 'a\tb\r\nc\rd\n' > ctrl
printf '\001\033\177\200\237\240\303\251\377\n' > high
printf 'end\r' > cr
printf '\nafter\n' > nl
printf 'a\0b\377\n' > binary
printf 'x\342\r\n' > leadcr
mkdir dir

# Concatenation and standard input
check "one file"            0 $'one\ntwo\n'                   a
check "two files"           0 $'one\ntwo\nthree\n'            a b
IN=a check "stdin, no operand"  0 $'one\ntwo\n'
IN=b check "dash for stdin" 0 $'one\ntwo\nthree\none\ntwo\n'  a - a
check "no newline at end"   0 'x'                             partial
check "empty input"         0 ''
check_file "binary bytes"   0 binary                          binary

# Line numbering and squeezing
check "-n"                  0 $'     1\tone\n     2\ttwo\n     3\tthree\n'  -n a b
check "-n partial line"     0 $'     1\txone\n     2\ttwo\n'              -n partial a
check "-b"                  0 $'     1\tline\n\n\n\n     2\tnext\n\n'      -b blanks
check "-b overrides -n"     0 $'     1\tline\n\n\n\n     2\tnext\n\n'      -nb blanks
check "-s"                  0 $'line\n\nnext\n\n'                          -s blanks
check "-s across files"     0 $'line\n\nnext\n\nafter\n'                   -s blanks nl
check "-sn"                 0 $'     1\tline\n     2\t\n     3\tnext\n     4\t\n' -sn blanks
check "--number"            0 $'     1\tthree\n'                           --number b
check "--num abbrev. -b"    0 $'     1\tone\n     2\ttwo\n'               --number-n a

# Visible characters
check "-E"                  0 $'a\tb^M$\nc\rd$\n'               -E ctrl
check "-T"                  0 $'a^Ib\r\nc\rd\n'                 -T ctrl
check "-v"                  0 $'a\tb^M\nc^Md\n'                 -v ctrl
check "-A"                  0 $'a^Ib^M$\nc^Md$\n'               -A ctrl
check "-e"                  0 $'a\tb^M$\nc^Md$\n'               -e ctrl
check "-t"                  0 $'a^Ib^M\nc^Md\n'                 -t ctrl
check "-v high bytes"       0 $'^A^[^?M-^@M-^_M- M-CM-)M-^?\n'  -v high
check "-v NUL"              0 $'a^@bM-^?\n'                     -v binary
check "-E stray byte, CR" 0 $'x\342^M$\n'                   -E leadcr
check "-E held CR + LF"     0 $'end^M$\nafter$\n'               -E cr nl
check "-E held CR at end"   0 $'end\r'                          -E cr
check "--show-all"          0 $'a^Ib^M$\nc^Md$\n'               --show-all ctrl
check "-u ignored"          0 $'three\n'                        -u b
check "options after files" 0 $'     1\tthree\n'                b -n
check "-- ends options"     0 $'three\n'                        -- b

# Errors
check "missing file"        1 $'one\ntwo\n'                     missing a
check_err "missing message" 1 'cat: missing: No such file or directory' missing a
check "directory"           1 $'three\n'                        dir b
check_err "directory message" 1 'cat: dir: Is a directory'      dir
check_err "-n as operand"   1 'cat: -n: No such file or directory' -- -n
check_err "invalid option"  1 $'cat: invalid option -- \'z\'\nTry \'cat --help\' for more information.' -nz a
check_err "unknown long"    1 $'cat: unrecognized option \'--frob\'\nTry \'cat --help\' for more information.' --frob
check_err "ambiguous long"  1 $'cat: option \'--show\' is ambiguous; possibilities: \'--show-nonprinting\' \'--show-ends\' \'--show-tabs\' \'--show-all\'\nTry \'cat --help\' for more information.' --show
check_err "argument to flag" 1 $'cat: option \'--number\' doesn\'t allow an argument\nTry \'cat --help\' for more information.' --number=3

# Help and version
check "version"             0 $'cat (loup-cmd-cat) 0.1.0\n'     --version
check "version abbrev."     0 $'cat (loup-cmd-cat) 0.1.0\n'     --vers
"$BIN" --help > "$TMP/help"
if head -1 "$TMP/help" | grep -q '^Usage: cat \[OPTION\]... \[FILE\]...$'; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "FAIL: help"
fi

echo "e2e: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
