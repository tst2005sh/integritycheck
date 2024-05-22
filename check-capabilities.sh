#!/bin/sh

cd "$(dirname "$0")" || exit 1

tmp_ignore_fgrep="$(mktemp)"
trap "rm -f -- '$tmp_ignore_fgrep'" EXIT

if [ -f ./assumeok.capabilites.fgrep ]; then
	cat ./assumeok.capabilites.fgrep > "$tmp_ignore_fgrep"
else
	echo '#' > "$tmp_ignore_fgrep"
fi

okdirs() {
	grep -h '^[^#]\+' "$tmp_ignore_fgrep" | rev |cut -d/ -f2- |rev |sort -u
}

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

if ${QUICK:-false}; then
	set -- $(okdirs)
fi

if [ $# -eq 0 ]; then
	set -- /bin /sbin /usr/bin /usr/sbin /lib* /usr/lib*
fi

#echo "args: $#: $*"

if ! command -v getcap >/dev/null 2>&1 && [ "$(id -u)" != 0 ]; then
	echo >&2 "$0 is supposed to be run as root"
	exit 1
fi

# try to ouput debian 9 getcap like the one of debian 10-12
debian9_forwardcompatility() {
	sed -E -e 's, = ([^+]+)\+([^+]+)$, \1=\2,g'
}

getcap -r "$@" |
debian9_forwardcompatility |
grep -vFx -f "$tmp_ignore_fgrep" ||
echo >&2 "ok"
