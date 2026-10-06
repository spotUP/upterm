# upterm

Meta-repo for the UP-Term source tree: it pins the repositories that build the
UP-Term kit (`build/UP-Term.lha`, made in vtcon) to the commits that were known
to work together. It holds no source of the parts.

Requires: python3 >= 3.14 (measured: 3.14.7), git, lha, vbcc (`vc`, `vlink`,
`vasmm68k_mot`), Docker (image `ixemul-gcc295`), NDK 3.2R4 headers.

## Quick start

    git clone <this repo> ~/Code/upterm        # workspace root = its parent: ~/Code
    ~/Code/upterm/bin/upterm-bootstrap         # clone every repo at its pinned commit
    ~/Code/upterm/bin/upterm-doctor            # what is missing on this machine
    # build the toolchains per toolchain/README.md, unpack the NDK, then:
    make -C ~/Code/vtcon dist                  # build/UP-Term.lha

`UPTERM_ROOT` overrides the workspace directory. `UPTERM_SRC=<dir>` makes the
bootstrap clone from existing local checkouts (`<dir>/<path>`) instead of the
network. `upterm-bootstrap --only name...` limits it, `--optional` adds the
optional repos, `--update` rewrites `repos.lock` to the repos' current heads
(commit that in this repo: it records "these versions work together").
A repo with uncommitted changes is skipped, named, and the exit status is 1.

## Build order

1. `amiga-gcc` (gcc 6.5 to `~/opt/amiga`) and `amiga-gcc15` (gcc 16 to `~/opt/amiga16`): `toolchain/`
2. `ixemul-vtcon` (ixemul.library, ixnet.library; Docker image `ixemul-gcc295`)
3. `upterm-ports`, `tmux-amiga`, `screen-amiga`, `cpython-amiga`, `neovim-amiga`
4. `vtcon`: `make dist`

## Which repo for which part

| Repo | Gives you | Needs |
|---|---|---|
| vtcon | the console, shell, tools, the kit | the rest, for `make dist` |
| ixemul-vtcon | ixemul.library, ixnet.library | Docker, `~/opt/amiga` (NDK headers, libamiga) |
| upterm-ports | recipes for GNU tools (grep, ncurses, ...) | `~/opt/amiga` |
| tmux-amiga | tmux 3.6a | `~/opt/amiga`, ixemul-vtcon |
| screen-amiga | GNU screen 4.9.1 | `~/opt/amiga`, ixemul-vtcon, GG ncurses |
| cpython-amiga | Python 3.14 | `~/opt/amiga`, ixemul-vtcon |
| neovim-amiga | Neovim 0.12 | `~/opt/amiga`, ixemul-vtcon |
| amiga-gcc, amiga-gcc15 | bebbo's compilers (pinned, with local patches) | a host C toolchain |
| dctelnet-vtcon (optional) | DCTelnet using vtcon's engine | vtcon |

Tests: `tests/test_bootstrap.sh`.
