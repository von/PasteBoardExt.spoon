#!/usr/bin/env bash
# Edit the paste buffer

set -o errexit  # Exit on error

# Default editor is MacVim as installed by Homebrew
editor=${EDITOR:-/usr/local/bin/mvim}

# Use --nofork for mvim
if [[ ${editor} == *mvim ]] ; then
  editor="${editor} --nofork"
fi

tmpfile=$(mktemp)".txt"
pbpaste -Prefer txt > ${tmpfile}
${editor} ${tmpfile}
cat ${tmpfile} | pbcopy
exit 0
