#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

for path in \
  .github/workflows \
  code/zk_libcod \
  code/bin \
  cod2server/main \
  cod2server/testbench \
  tests \
  results \
  scripts; do
  [[ -d "$path" ]] || fail "missing required directory: $path"
done

[[ -f .gitmodules ]] || fail ".gitmodules is missing"
[[ $(git config -f .gitmodules --get submodule.code/zk_libcod.path) == "code/zk_libcod" ]] || fail "invalid zk_libcod submodule path"
[[ $(git config -f .gitmodules --get submodule.code/zk_libcod.url) == "https://github.com/ddrabik-bot/zk_libcod.git" ]] || fail "invalid zk_libcod submodule URL"
[[ $(git config -f .gitmodules --get submodule.code/zk_libcod.branch) == "master" ]] || fail "invalid zk_libcod submodule branch"

git ls-files --error-unmatch code/zk_libcod >/dev/null 2>&1 || fail "zk_libcod is not tracked as a submodule"
grep -Fq 'git submodule update --init --recursive' README.md || fail "README lacks submodule checkout instructions"
grep -Fq 'ddrabik-bot/zk_libcod' README.md || fail "README lacks zk_libcod source declaration"

printf 'PASS: F1.1 repository structure is valid\n'
