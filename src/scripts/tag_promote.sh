#!/bin/bash -eo pipefail

ParsePromoteVersion() {
  git log -1 --pretty=%B | perl -wne '/[Pp]romote( to)?: ([\w\.\-]+)/i and print $2'
}

Main() {
  git config user.email "team@teak.io"
  git config user.name "Teak CI"

  PVERSION="$(ParsePromoteVersion)"

  if [ -n "$PVERSION" ]; then
    git tag -a "$PVERSION" -m "Promoted by CI"
    git push --tags
    eval "$ON_TAG"
  else
    echo "No tag needed"
    eval "$ON_SKIP"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  Main
fi
