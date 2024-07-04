#/bin/bash
cd "$(dirname "$0")" || exit 1

if ! command -v debsums >/dev/null 2>&1; then
	echo >&2 'debsums command not found (consider to apt-get install debsums)'
	exit 1
fi
debsums -a -s 2>&1 |
if [ -f assumeok.debsums.fgrep ]; then
	grep -vFx -f assumeok.debsums.fgrep || echo >&2 "ok"
else
	cat
fi
