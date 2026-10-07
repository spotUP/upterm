# upterm

Meta-repo for the UP-Term source tree: it pins the repositories that build the
UP-Term kit (`build/UP-Term.lha`, made in vtcon) to the commits that were known
to work together. It holds no source of the parts.

Requires: python3 >= 3.14 (measured: 3.14.7), git, lha, vbcc (`vc`, `vlink`,
`vasmm68k_mot`), Docker (image `ixemul-gcc295`), NDK 3.2R4 headers. The whole
path from an empty Mac to a kit, a test rig, a real Amiga and Claude is below
in "Set up the whole thing".

## Set up the whole thing

Each step names the document that has the details. A step marked (not run) was
written from the scripts and Makefiles on a machine that already had the
piece, not replayed on a clean one. Paths use `~/Code` as the workspace root;
`UPTERM_ROOT=<dir>` moves it.

1. **The Mac.** macOS with Xcode command line tools and Homebrew. This README,
   "Host prerequisites" below.
2. **Toolchains.** bebbo's amiga-gcc (gcc 6.5), vbcc, the 2.95.3 Docker image.
   `toolchain/README.md`.
3. **Clone everything and check.** `bin/upterm-bootstrap`, then
   `bin/upterm-doctor` ("Quick start" below).
4. **The gitignored inputs** (NDK headers, Roadshow netinclude, AmiSSL SDK,
   Unifont, Twemoji, the library and port artifacts). "Inputs that are not in
   git" below.
5. **Build the parts and the kit** (`make dist` in vtcon gives
   `build/UP-Term.lha`). "Build order" and "Build the kit" below.
6. **The test rig** (FS-UAE, Kickstart ROM, system disk, amiagent; `rig.py
   setup`, `start --max`; what each rig script proves). `vtcon/tools/rig/README.md`.
7. **A real Amiga** (Replay, A1200, anything 68020 or better): TCP/IP stack,
   AmiSSL 5, the Installer, first run, the `C:Claude` setup wizard.
   `vtcon/dist/README.txt` (end users: WHAT YOU NEED, INSTALL, NETWORK,
   CLAUDE).
8. **Claude Code on a NAS** (Synology container, tmux, password, login).
   `vtcon/tools/nas/README.md`.
9. **Claude controls the Amiga** (amimcp + amiagent, token, MCP config, the
   skill). `vtcon/tools/nas/README.md`, "Give Claude control of the Amiga".

Where the other documents live:

| Question | Document |
|---|---|
| What does a part do, which repos need which | the table at the end of this file |
| Rules, every command of a repo | `RULES.md`, section `## Commands`, in vtcon, upterm-ports, neovim-amiga, cpython-amiga |
| How the kit builds, what versions it holds | vtcon `Makefile` rule `dist`, `Files/VERSIONS` in the kit |
| Why the meta-repo is built this way | `vtcon/thoughts/shared/plans/2026-10-06-meta-repo.md` |
| What the console does per sequence | `vtcon/thoughts/shared/research/2026-09-28_console-conformance-matrix.md` |
| Each part's own build | `README.md` of tmux-amiga, screen-amiga (`src/Makefile.amiga` head), cpython-amiga, neovim-amiga, upterm-ports, ixemul-vtcon (`docker/`) |
| DCTelnet with vtcon's engine (optional) | `dctelnet-vtcon/README.md` (its own build environment section) |
| amiga-pi | not part of the UP-Term kit and not in `repos.lock`; not covered here |

## Host prerequisites (macOS)

    brew install python@3.14 git lha cmake ninja
    brew tap tditlu/amiga                  # vbcc, vasm, vlink for AmigaOS (brew may ask: brew trust tditlu/amiga)
    brew install vbcc vasm vlink
    # Docker Desktop (the ixemul library is built by gcc 2.95.3 in an amd64 image)
    # bebbo's amiga-gcc needs its own packages: toolchain/README.md

- `VBCC_PREFIX` defaults to `$(brew --prefix vbcc)`; set it (`make dist VBCC_PREFIX=<dir>`)
  when vbcc is not a Homebrew install. The directory must hold
  `targets/m68k-amigaos/include` and `targets/m68k-amigaos/lib` (with `startup.o`
  and `libvc.a`); vtcon writes `build/vbcc-aos68k.cfg` from it.
- Docker: `docker images -q ixemul-gcc295` must print an id; the image is built by
  `sh docker/build.sh` in ixemul-vtcon (needs network: the Dockerfile clones the
  binutils 2.14 and gcc 2.95.3 sources from GitHub and downloads GG's
  fd2inline-1.11 from codewiz.org (that URL is not checked here)).
- Free disk: several GB (each toolchain tree, the cpython and neovim builds,
  `build/rig/` 1.5 GB for the system disk). Check `df -h /` before a build that
  fails strangely.
- `upterm-doctor` checks python, lha, vbcc tools, Docker image, the two gcc
  prefixes and the NDK; it does not check cmake, ninja, FS-UAE or the inputs below.

## Inputs that are not in git

All of these are gitignored or outside the repos. The vtcon Makefile variable
that names each is in the right column; every default hangs off `UPTERM_ROOT`.

| Input | Where it goes | How to get it |
|---|---|---|
| AmigaOS NDK 3.2R4 headers (Include_H) | `vtcon/vendor/ndk-3.2r4-Include_H` (`VTCON_NDK=`; `upterm-doctor` also reads `VTCON_NDK`) | The AmigaOS 3.2 NDK ("NDK3.2R4") from Hyperion Entertainment's AmigaOS 3.2 developer download (licensed; the exact URL is not recorded here). Unpack the `Include_H` drawer. |
| Roadshow netinclude | `vtcon/vendor/ndk-3.2r4-netinclude` (`VTCON_NETINCLUDE=`), used for `C:Claude` | From the same NDK: `NDK3.2R4/SANA+RoadshowTCP-IP/netinclude`, copied. `uptelnet` instead takes `VTCON_NETINC=` (default: `vendor/roadshow-netinclude`, else dctelnet-v2's `src/third_party/netinclude`, so check out `dctelnet-v2`). |
| AmiSSL 5 SDK | `vtcon/vendor/amissl-5.27/` (found by itself; `AMISSL_SDK=` otherwise) | `gh release download 5.27 -R jens-maus/amissl -p AmiSSL-5.27-SDK.lha` and `lha x` it there. Without it `C:Claude` refuses https. |
| Unifont 17.0.05 | `vtcon/build/unifont/unifont_all-17.0.05.hex.gz` | Fetched by `make dist` itself (curl from ftp.gnu.org/gnu/unifont/, checked against a SHA-256 in the Makefile). Offline: place the file there yourself. `UNIFONT_VER=` and `UNIFONT_SHA256=` change it. |
| Twemoji 17.0.3 | `vtcon/build/twemoji/twemoji-17.0.3.tar.gz` | Fetched by `make dist` itself (github.com/jdecked/twemoji tag v17.0.3, SHA-256 checked). Offline: place the file there. `TWEMOJI_VER=`, `TWEMOJI_SHA256=`. |
| GNU ncurses 5.5 (m68k, Geek Gadgets) | `vtcon/build/rig/vtc/pkgs/ncurses-5.5-1-p-bin-m68k` (`NCURSES=` in tmux-amiga and screen-amiga) | Aminet `dev/gg/ncurses-5.5-1-bin-m68k`, unpacked there. The `-p-` in the directory name is the owner's; whether it marks a modification is not verified. Needed before tmux and screen build. |
| `IXEMUL_LIB`, `IXNET_LIB` | default `ixemul-vtcon/build295/library/68020/68881/amigaos/ixemul.library` and `.../build295/ixnet/68020/amigaos/ixnet.library` | `sh docker/build.sh` in ixemul-vtcon (builds the Docker image once, then the libraries). |
| `PYTHON_DIST` | default `cpython-amiga/build/m68k/dist/Python3` | the cpython-amiga build below |
| `NVIM_DIST` | default `neovim-amiga/build/v012/dist/nvim` | the neovim-amiga build below (the 0.12 target: `Makefile.v012`; the plain `Makefile` is the 0.4.4 baseline and writes `build/m68k/dist/`) |
| `SCREEN_BIN` | default `screen-amiga/src/screen` | `make -f Makefile.amiga` in `screen-amiga/src` |
| `TMUX_BIN` | default `tmux-amiga/build/tmux-bin` | `make -f Makefile.amiga` in tmux-amiga |

Access: `repos.lock` lists `dctelnet-v2`, `amiexpress-doorserver` and
`dctelnet-vtcon` with ssh URLs (`git@github.com:spotUP/...`); the first is not
marked optional, so `upterm-bootstrap` fails without access to it, and
`amiexpress-doorserver` is private. What the kit build takes from `dctelnet-v2`
is only a Roadshow netinclude for `uptelnet`; without access, bootstrap with
`--only` for the other repos and give `uptelnet` a `vendor/roadshow-netinclude`
drawer in vtcon (copy of the NDK's `SANA+RoadshowTCP-IP/netinclude`; that it is
byte-equal to dctelnet's copy is not verified).

Not needed to build the kit: gcc 16 (`amiga-gcc15`, `~/opt/amiga16`). No Makefile
of vtcon, upterm-ports, tmux-amiga, screen-amiga, cpython-amiga or neovim-amiga
names it (searched by grep for `amiga16`); only ixemul-vtcon's
`tools/selfcall_check.py` and `tools/mixlink.sh` and vtcon's `stackext_rig.py`
A/B use it. `upterm-doctor` still reports it as a failure when missing: ignore
that line for a kit build.

Also not in the kit build: `upterm-ports` (`make dist` does not read it; it
feeds the userland rig, `vtcon/tools/rig/userland_rig.py`), `dctelnet-vtcon`
(optional), `amiexpress-doorserver` (only vtcon's `make te-diff`).

## Build the kit

After the Build order below (steps 1 to 3 give the artifacts):

    make -C ~/Code/vtcon test                  # optional: host suites
    make -C ~/Code/vtcon dist                  # build/UP-Term.lha

`make dist` runs `make amiga` itself (vbcc, from the vtcon directory: the vbcc
config names `vendor/ndk-3.2r4-Include_H` relative to it, so run make there).
To use an artifact from another place: `make dist IXEMUL_LIB=... IXNET_LIB=...
PYTHON_DIST=... NVIM_DIST=... SCREEN_BIN=... TMUX_BIN=...`. A dirty or
moved repo is listed in the kit's `Files/VERSIONS`.

## Quick start

    git clone <this repo> ~/Code/upterm        # workspace root = its parent: ~/Code
    ~/Code/upterm/bin/upterm-bootstrap         # clone every repo at its pinned commit
    ~/Code/upterm/bin/upterm-doctor            # what is missing on this machine
    # toolchains, inputs and parts as in "Set up the whole thing" above, then:
    make -C ~/Code/vtcon dist                  # build/UP-Term.lha

`UPTERM_ROOT` overrides the workspace directory. `UPTERM_SRC=<dir>` makes the
bootstrap clone from existing local checkouts (`<dir>/<path>`) instead of the
network. `upterm-bootstrap --only name...` limits it, `--optional` adds the
optional repos, `--update` rewrites `repos.lock` to the repos' current heads
(commit that in this repo: it records "these versions work together").
A repo with uncommitted changes is skipped, named, and the exit status is 1.

## Build order

Each part builds in its own repo; the commands are in that repo's `RULES.md`
`## Commands` (vtcon, upterm-ports, neovim-amiga, cpython-amiga) or the head of
its Makefile. The order below is from what each Makefile reads from the others
(not run end to end on a clean machine). Use at most 4 parallel jobs.

1. `amiga-gcc` to `~/opt/amiga` (gcc 6.5, with `NDK=3.2`; `toolchain/README.md`).
   `amiga-gcc15` (gcc 16 to `~/opt/amiga16`) is not needed for the kit.
2. `ixemul-vtcon` (branch `feature/ixemul-80`):

       cd ~/Code/ixemul-vtcon
       sh docker/build.sh                     # image ixemul-gcc295 once, then ixemul.library and ixnet.library into build295/
       sh docker/install-sdk-headers.sh       # this repo's header changes into ~/opt/amiga/m68k-amigaos/ixemul/include
       make -C compat && make -C compat install    # libixcompat.a into the SDK lib (tmux, screen, python, neovim link it)

3. The ncurses input (table above), then the userland of the kit:

       make -f Makefile.amiga -C ~/Code/tmux-amiga          # build/tmux-bin
       make -f Makefile.amiga -C ~/Code/screen-amiga/src    # screen
       cd ~/Code/cpython-amiga && tools/fetch-cpython.sh && make cc1 compat && tools/configure-m68k.sh && make m68k zip dist   # build/m68k/dist/Python3
       cd ~/Code/neovim-amiga                               # build/v012/dist/nvim, from Makefile.v012 (order from the script guards, not run):
       #   make -f Makefile.v012 libs host-deps && tools/configure-nvim012.sh --host   (host nvim first: it makes nlua0)
       #   make -f Makefile.v012 sysroot && tools/configure-nvim012.sh && make -f Makefile.v012 dist

   `cpython-amiga/vendor/cpython` is fetched by `tools/fetch-cpython.sh` (git
   clone of the v3.14.x tag plus the patches); `make cc1` clones bebbo's gcc 6
   sources into `build/gcc` (a patched cc1 the port needs). `neovim-amiga/vendor012`
   is committed; its tarballs in `dl/` are gitignored and not needed to build.
   The neovim step order above is the least certain line of this file:
   run `make -f Makefile.v012 -n dist` to see what it would do and check the
   owner's handoff `neovim-amiga/thoughts/shared/handoffs/2026-10-03_neovim-0.12.5-links-awaiting-rig.md`.
4. `upterm-ports` (optional: `make sysroot`, `make <pkg>`; feeds the userland rig).
5. `vtcon`: `make dist` ("Build the kit").

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
