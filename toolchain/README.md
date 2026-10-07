# Toolchains

`PINNED` lists bebbo's remote, branch and commit for each tree; `patches/` holds
the local modifications (output of `git diff` in each tree on 2026-10-06):

- `amiga-gcc-zlib-darwin.patch`: Makefile, adds `--with-system-zlib` to the macOS configure line.
- `amiga-gcc15-gcc16-branch.patch`: default-repos, builds gcc branch `amiga16.1` instead of `amiga6`.

Rebuild (from a clone at the pinned commit):

    git apply <patch>        # inside the clone
    make update; make all PREFIX=...

Install prefixes: `~/opt/amiga` (gcc 6.5.0b) and `~/opt/amiga16` (gcc 16.1.1b) are what the
kit's build uses (measured with `--version`). Prefix not confirmed as the build setting: the
trees' Makefiles do not mention a prefix, and bebbo's README says the default is `/opt/amiga`
with `PREFIX=yourprefix` to override; the exact command used for `~/opt/...` is not recorded.
The 2.95.3 compiler is not here: it lives in the `ixemul-gcc295` Docker image.

## Before the first build (macOS)

Bebbo's README (the clone's `README.md`, section "macOS") lists the Homebrew
packages its build needs: `brew install bash wget make lhasa gmp mpfr libmpc
flex gettext gnu-sed texinfo gcc@12 make autoconf bison`. On macOS pass a
modern bash: `make all SHELL=$(brew --prefix)/bin/bash`, and possibly
`CC=gcc-12 CXX=g++-12 gmake ...` (quoted from that README; not re-run here).

The kit's build wants the AmigaOS 3.2 headers in the gcc tree: add `NDK=3.2`
to the make parameters (bebbo's README: "to use NDK3.2 add `NDK=3.2`"). That
`~/opt/amiga/m68k-amigaos/ndk-include` on the build machine is the 3.2 set is
what `ixemul-vtcon/docker/build.sh` assumes; the exact command used to build it
is not recorded (see the prefix note above). Only the 6.5 tree (`amiga-gcc`,
`~/opt/amiga`) is used by the kit and its ports. `amiga-gcc15` / `~/opt/amiga16`
is for ixemul-vtcon's gcc 16 experiments only; skip it for a kit build.

## vbcc, vasm, vlink

The kit's own programs are built with vbcc, not with these trees:
`brew tap tditlu/amiga && brew install vbcc vasm vlink` (the tap and its
formulae; brew may ask you to `brew trust tditlu/amiga`). `VBCC_PREFIX` names
the install when it is not Homebrew's.

## After the compiler: the ixemul SDK

`ixemul-vtcon` builds ixemul.library with gcc 2.95.3 in Docker and needs
`~/opt/amiga/m68k-amigaos/{ndk-include,ixemul,lib}` from the step above; then
`docker/install-sdk-headers.sh` and `make -C compat install` put this tree's
headers and libixcompat into that SDK. See "Build order" in `../README.md`.
