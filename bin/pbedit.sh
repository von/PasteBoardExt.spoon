#!/usr/bin/env bash
# Edit the paste buffer

set -o errexit  # Exit on error

if test -n "${EDITOR}" ; then
  editor="${EDITOR}"
else
  # Default editor is MacVim as installed by Homebrew
  for mvim in \
    /usr/local/bin/mvim \
    /opt/homebrew/bin/mvim \
    /Applications/MacVim.app/Contents/bin/mvim \
    ; do
    if test -x "${mvim}" ; then
      editor="${mvim}"
      break
    fi
  done
fi

if test -z "${editor}" ; then
  echo "Macvim (mvim) not found." 1>&2
  exit 1
fi

# Use --nofork for mvim
if [[ ${editor} == *mvim ]] ; then
  editor="${editor} --nofork"
fi

tmpfile=$(mktemp)".txt"
pbpaste -Prefer txt > ${tmpfile}
${editor} ${tmpfile}
cat ${tmpfile} | pbcopy
exit 0
