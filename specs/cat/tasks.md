# Tasks: cat

- [x] 1. Parse GNU cat options (short, combined, long with unique prefixes, `--`, mixed operands, usage errors with status 1)
  - _Requirements: 3.4, 4.1, 4.2, 4.3_
- [x] 2. Copy operands and standard input byte for byte
  - _Requirements: 1.1, 1.2, 1.3_
- [x] 3. Number lines (`-n`, `-b`) and squeeze blank lines (`-s`), carrying state across operands
  - _Requirements: 2.1, 2.2, 2.3, 2.4_
- [x] 4. Show ends, tabs and non-printing bytes (`-E`, `-T`, `-v`, `-A`, `-e`, `-t`)
  - _Requirements: 3.1, 3.2, 3.3, 3.4_
- [x] 5. Report missing operands and directories, continue, exit 1
  - _Requirements: 5.1, 5.2_
- [x] 6. Unit tests and end-to-end tests of the native binary
  - _Requirements: all_
