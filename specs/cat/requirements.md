# Requirements: cat

## Introduction

`cat` copies files, or standard input, to standard output, one after the
other. This repository recreates GNU coreutils `cat` in Loup, including line
numbering, blank-line squeezing and the options that make line ends, tabs and
other control characters visible. It is the second command in the loup-cmd
series, after `echo`, and the first that reads files.

## Requirements

### Requirement 1: Concatenation

**User Story:** As a shell user, I want files written to standard output in
order so that I can view or join them.

#### Acceptance Criteria

1. WHEN cat is run with file operands, THE program SHALL write the contents of
   each file in operand order, byte for byte, and exit with status 0.
2. WHEN cat is run with no operands, or an operand is `-`, THE program SHALL
   read standard input in its place.
3. THE program SHALL copy bytes that are not valid UTF-8, and NUL bytes,
   unchanged.

### Requirement 2: Line options

**User Story:** As a shell user, I want numbered and tidied lines so that I
can refer to lines and skip runs of blank ones.

#### Acceptance Criteria

1. WHEN `-n` is given, THE program SHALL prefix every output line with its
   number, right-aligned in six columns and followed by a TAB.
2. WHEN `-b` is given, THE program SHALL number only non-empty lines; `-b`
   SHALL override `-n`.
3. WHEN `-s` is given, THE program SHALL print one empty line in place of a
   run of empty lines.
4. THE program SHALL carry the line number, the blank-line run and a partial
   last line from one operand to the next, as GNU cat does.

### Requirement 3: Visible characters

**User Story:** As a shell user, I want control characters shown so that I can
see what a file really contains.

#### Acceptance Criteria

1. WHEN `-E` is given, THE program SHALL print `$` before each newline, and
   show a carriage return that directly precedes a newline as `^M`.
2. WHEN `-T` is given, THE program SHALL print each TAB as `^I`.
3. WHEN `-v` is given, THE program SHALL print control bytes as `^X`, DEL as
   `^?`, and bytes from 128 up as `M-` followed by the notation of the byte
   minus 128, leaving newline and TAB unchanged.
4. THE program SHALL accept `-A` as `-vET`, `-e` as `-vE`, `-t` as `-vT`, and
   ignore `-u`.

### Requirement 4: Command line

**User Story:** As a shell user, I want GNU's option syntax so that existing
commands work unchanged.

#### Acceptance Criteria

1. THE program SHALL accept combined short options (`-nE`), options after
   operands, `--` to end the options, and the long options `--number`,
   `--number-nonblank`, `--squeeze-blank`, `--show-ends`, `--show-tabs`,
   `--show-nonprinting` and `--show-all`, each abbreviable to a unique prefix.
2. WHEN `--help` or `--version` is given, THE program SHALL print the help
   text or the version line and exit with status 0.
3. WHEN an option is unknown, ambiguous, or given an argument it does not
   take, THE program SHALL print GNU's message and
   `Try 'cat --help' for more information.` on standard error and exit with
   status 1.

### Requirement 5: Errors

**User Story:** As a script author, I want a missing file reported without
losing the others so that one bad operand does not hide the rest.

#### Acceptance Criteria

1. WHEN an operand does not exist, THE program SHALL print
   `cat: NAME: No such file or directory` on standard error, continue with the
   next operand, and exit with status 1.
2. WHEN an operand is a directory, THE program SHALL print
   `cat: NAME: Is a directory`, continue, and exit with status 1.
