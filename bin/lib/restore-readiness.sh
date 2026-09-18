#!/usr/bin/env bash
# Avoid reading dataless files: that could trigger an unbounded cloud download.
_restore_hydrated_regular_file() {
  [[ -f "$1" && -r "$1" ]] || return 1
  local flags
  flags="$(stat -f '%Sf' "$1" 2>/dev/null)" || return 1
  [[ "$flags" != *dataless* && "$flags" != *offline* ]]
}

restore_hydrated_file() {
  [[ -s "$1" ]] && _restore_hydrated_regular_file "$1"
}

restore_hydrated_tree() {
  local file found=0
  [[ -d "$1" && -r "$1" ]] || return 1
  while IFS= read -r file; do
    _restore_hydrated_regular_file "$file" || return 1
    found=1
  done < <(find "$1" -type f -print 2>/dev/null)
  [[ "$found" == 1 ]]
}
