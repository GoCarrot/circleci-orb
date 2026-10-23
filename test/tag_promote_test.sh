#!/bin/bash -eo pipefail
# shellcheck disable=SC1091

cd "$(dirname "${BASH_SOURCE[0]}")/.."
script="$PWD/src/scripts/tag_promote.sh"
SDK_UTILS_SOURCE_ONLY=1 source "$script"

failures=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $desc (expected '$expected', got '$actual')"
    failures=$((failures + 1))
  else
    echo "PASS: $desc"
  fi
}

commit_repo() {
  local dir
  dir="$(mktemp -d)"
  git -C "$dir" init -q
  git -C "$dir" config user.email "test@example.com"
  git -C "$dir" config user.name "Test"
  git -C "$dir" commit -q --allow-empty -F -
  echo "$dir"
}

dir="$(printf 'Promote to: 4.3.17\n' | commit_repo)"
actual="$(cd "$dir" && ParsePromoteVersion)"
assert_eq "simple subject-line promote" "4.3.17" "$actual"
rm -rf "$dir"

dir="$(printf 'Promote to: 4.3.17\n\nHuman-Claude interaction log:\n> Promote to: 4.3.17\n' | commit_repo)"
actual="$(cd "$dir" && ParsePromoteVersion)"
assert_eq "body repeats the promote string (C-1190)" "4.3.17" "$actual"
rm -rf "$dir"

dir="$(printf 'Fix a typo\n' | commit_repo)"
actual="$(cd "$dir" && ParsePromoteVersion)"
assert_eq "non-promote commit yields no version" "" "$actual"
rm -rf "$dir"

# CircleCI runs a step's command as a string, not as a file, so run it that way.
dir="$(printf 'Fix a typo\n' | commit_repo)"
actual="$(cd "$dir" && ON_SKIP=':' ON_TAG=':' bash -eo pipefail -c "$(cat "$script")" 2>&1)"
assert_eq "script body runs when executed as a command string" "No tag needed" "$actual"
rm -rf "$dir"

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)"
  exit 1
fi

echo "All tests passed"
