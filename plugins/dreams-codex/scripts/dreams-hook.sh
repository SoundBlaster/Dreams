#!/bin/sh
# Runs the Dreams hook when the app is installed; stays silent (exit 0) when it is not,
# so an agent session never sees an error because Dreams is missing.
for dir in ${DREAMS_APP_DIRS:-/Applications "$HOME/Applications"}; do
  app="$dir/Dreams.app/Contents/MacOS/Dreams"
  if [ -x "$app" ]; then exec "$app" --hook "$1"; fi
done
exit 0
