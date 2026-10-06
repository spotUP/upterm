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
