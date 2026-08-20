# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A small set of standalone Windows `.bat` scripts (no build system, no
dependencies, no tests) that use `netsh advfirewall` and PowerShell to
block/unblock network traffic for executables under a given directory,
via the native Windows Firewall. There is no Autodesk-specific logic —
`block.bat` works against any directory of `.exe` files.

There is nothing to build, lint, or test — this is not a compiled or
packaged project. The scripts can only be meaningfully run on Windows
(they depend on `netsh`, PowerShell, and `net session`/UAC elevation),
so validate changes by reading them carefully; there's no CI or
interpreter available to execute them from this environment.

## Architecture

Four scripts share one identification scheme: every rule they create is
named exactly `AutodeskBlocker_In` or `AutodeskBlocker_Out` (not a unique
name per program). `unblock.bat` and `status.bat` rely on that fixed name
to find/remove rules — they never need to know which directory a `block.bat`
run used, since matching is by rule name, not by remembered state.

- **`block.bat`** — takes a directory (arg, drag-and-drop, or interactive
  prompt), self-elevates via `Start-Process -Verb RunAs` if not already
  Administrator, then shells out to PowerShell (`Get-ChildItem -Recurse
  -Force -File -Filter *.exe`) to enumerate `.exe` files recursively,
  including hidden files/folders. For each one it adds one inbound and one
  outbound `netsh advfirewall firewall add rule` block, scoped to that
  program's full path, all profiles. Skips its own `pause` when the
  `BLOCKER_NO_PAUSE` env var is set (used by `block-list.bat`).
- **`block-list.bat`** — thin wrapper: elevates once, then reads
  `block-list.txt` (next to it, one directory path per line, `#`-prefixed
  and blank lines skipped via `for /f "eol=# delims="`) and `call`s
  `block.bat` once per line. Sets `BLOCKER_NO_PAUSE=1` before the loop so
  `block.bat` doesn't stop for a keypress after every directory; since the
  wrapper is already elevated, the nested `block.bat` calls inherit that
  token and skip their own UAC prompt too. Errors out with a message to
  run `discover.bat` if `block-list.txt` doesn't exist yet.
- **`discover.bat`** / **`discover.ps1`** — read-only helper, not part of
  the block/unblock/status trio. Self-elevates (needed to read other
  users' `AppData`), then runs `discover.ps1`, which walks
  `Program Files`, `Program Files (x86)`, `ProgramData`, and every
  `C:\Users\*\AppData\{Roaming,Local}` looking for directories matching
  `Autodesk|ADSK`, prints each match with a recursive `.exe` count, and
  writes the plain path list (no exe counts) to `block-list.txt` via
  `Set-Content` at `$PSScriptRoot\block-list.txt` — that's the file
  `block-list.bat` reads, so the two scripts are coupled through that
  filename. Re-running `discover.bat` **overwrites** `block-list.txt`.
  Exists because exact Autodesk folder names are version/year-specific and
  go stale in a hardcoded list. `discover.bat` must keep `discover.ps1`
  alongside it (invoked via `-File "%~dp0discover.ps1"`).
  `block-list.txt` is gitignored — it's machine-specific generated output,
  not source.
- **`unblock.bat`** — self-elevates, then deletes every rule named
  `AutodeskBlocker_In` / `AutodeskBlocker_Out` in one `netsh ... delete rule`
  call each (a single name-matched delete removes all rules sharing that
  name).
- **`status.bat`** — read-only, does not self-elevate. Uses PowerShell
  (`Get-NetFirewallRule -DisplayName 'AutodeskBlocker_*'` plus
  `Get-NetFirewallApplicationFilter`) to print direction/action/enabled
  state/program path for every active rule.

Batch-specific implementation details worth preserving when editing these
scripts:
- `setlocal EnableDelayedExpansion` + `!var!` (not `%var%`) is required
  inside the `for /f` loop in `block.bat` because the loop body sets and
  reads a variable (`EXE`) within the same iteration.
- Elevation is implemented by relaunching the script itself
  (`Start-Process -FilePath '%~f0' ... -Verb RunAs`) rather than requiring
  the user to open an elevated shell manually.
- Rule identification is intentionally name-based (not path-based) so
  `unblock.bat`/`status.bat` work independently of which directory/directories
  were originally blocked.
