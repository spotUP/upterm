#!/bin/sh
# Checks for bin/upterm-bootstrap and bin/upterm-doctor. Offline: clones from
# the local checkouts in UPTERM_SRC (default: parent of this repo). Never
# touches the real repos; the dirty case works on a fresh clone.
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
src=${UPTERM_SRC:-$(dirname "$here")}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/upterm-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
fail=0
ok()  { echo "[OK] $1"; }
bad() { echo "[FAIL] $1"; fail=1; }

# 1. bootstrap into an empty root reproduces every pinned commit
export UPTERM_ROOT="$tmp/ws" UPTERM_SRC="$src"
"$here/bin/upterm-bootstrap" --optional > "$tmp/boot1.log" 2>&1 \
  && ok "bootstrap exit 0" || { bad "bootstrap exit status"; tail -5 "$tmp/boot1.log"; }
n=0; m=0
while read -r name url branch commit path; do
  case $name in '#'*|'') continue;; esac
  n=$((n+1))
  got=$(git -C "$UPTERM_ROOT/${path:-$name}" rev-parse HEAD 2>/dev/null)
  if [ "$got" = "$commit" ]; then m=$((m+1)); else bad "$name: HEAD ${got:-none}, pinned $commit"; fi
done < "$here/repos.lock"
[ "$n" -gt 0 ] && [ "$n" = "$m" ] && ok "$m of $n repos at the pinned commit" || bad "$m of $n repos at the pinned commit"

# 2. a second run is idempotent
"$here/bin/upterm-bootstrap" --optional > "$tmp/boot2.log" 2>&1 && ok "second bootstrap exit 0" || bad "second bootstrap"

# 3. doctor exits 0 on this machine against the real workspace
env -u UPTERM_SRC UPTERM_ROOT="$(dirname "$here")" "$here/bin/upterm-doctor" > "$tmp/doctor.log" 2>&1 \
  && ok "doctor exit 0" || { bad "doctor exit status"; grep FAIL "$tmp/doctor.log"; }

# 4. a dirty repo (in the fresh clone) is skipped, named, and the exit status is 1
echo x > "$UPTERM_ROOT/tmux-amiga/dirty-marker"
"$here/bin/upterm-bootstrap" --only tmux-amiga vtcon > "$tmp/boot3.log" 2>&1; rc=$?
[ "$rc" = 1 ] && ok "dirty tree: exit 1" || bad "dirty tree: exit $rc"
grep -q 'tmux-amiga: 1 uncommitted' "$tmp/boot3.log" && ok "dirty repo named with its count" || bad "dirty repo not named"
grep -q 'vtcon at' "$tmp/boot3.log" && ok "clean repo still processed" || bad "clean repo skipped"

exit $fail
