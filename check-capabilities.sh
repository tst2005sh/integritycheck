#!/bin/sh

QUICK=false
while [ $# -gt 0 ]; do
	case "$1" in
	(--quick|--fast) QUICK=true;;
	(--) shift; break;;
	(-*) echo >&2 "ERROR";exit 1;;
	(*) break ;;
	esac
	shift
done

okdirs() {
	cat assumeok.capabilites.fgrep | rev |cut -d/ -f2- |rev |sort -u
}

if ${QUICK:-false}; then
	set -- $(okdirs)
fi

if ! command -v getcap >/dev/null 2>&1 && [ "$(id -u)" != 0 ]; then
	echo >&2 "$0 is supposed to be run as root"
	exit 1
fi

if [ $# -eq 0 ]; then
	set -- /bin /sbin /usr/bin /usr/sbin /lib* /usr/lib*
fi
getcap -r "$@" |
sed -E -e 's, = ([^+]+)\+([^+]+)$, \1=\2,g' |
grep -vFx -f assumeok.capabilites.fgrep ||
echo >&2 "ok"
