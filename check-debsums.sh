#/bin/bash
cd "$(dirname "$0")" || exit 1
debsums -a -s 2>&1 |
grep -vFx -f assumeok.debsums.fgrep || echo >&2 "ok"
