#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if command -v kpackagetool6 >/dev/null 2>&1; then
  kpackagetool6 --type Plasma/Applet --install package || kpackagetool6 --type Plasma/Applet --upgrade package
elif command -v kpackagetool5 >/dev/null 2>&1; then
  kpackagetool5 --type Plasma/Applet --install package || kpackagetool5 --type Plasma/Applet --upgrade package
else
  echo "kpackagetool6 or kpackagetool5 is required to install the widget." >&2
  exit 1
fi
