#!/bin/sh

# Note: actuellement ca scan bien /usr et ca s'y retrouve avec le contenu de  /bin --> /usr/bin
# TODO: scanner /opt

cd "$(dirname "$0")" || exit 1

OPT_VERBOSE=false
OPT_DEBUG=false
OPT_NO_CACHE=false
OPT_IGNORE_AVAILABLE=false
OPT_IGNORE_LOCAL=false
while [ $# -gt 0 ]; do
	case "$1" in
	(-v) OPT_VERBOSE=true ;;
	(-q) OPT_VERBOSE=false ;;
	(--debug|--cache) OPT_DEBUG=true ;;
	(-f|--no-cache) OPT_NO_CACHE=true ;;
	(-I|--ignore-available) OPT_IGNORE_AVAILABLE=true ;;
	(-L|--ignore-local) OPT_IGNORE_LOCAL=true ;;
	(--) shift;break;;
	(-*) echo >&2 "ERROR unknown option $1"; exit 1;;
	esac
	shift
done

ignorelocaldir=integrity.ignores-local
ignoredir=integrity.ignores-enabled
if ${OPT_IGNORE_AVAILABLE:-false}; then
	ignoredir=integrity.ignores-available
fi

tmp_search=$(mktemp)
tmp_exclude=$(mktemp)
tmp_ignore_egrep=$(mktemp)
if ${OPT_DEBUG:-false}; then
	tmp_cache=/tmp/integritycheck.$(date +%Y-%m-%d|md5sum|cut -d\  -f1)
	trap "rm -f $tmp_search $tmp_exclude $tmp_ignore_egrep" EXIT
else
	tmp_cache=$(mktemp)
	trap "rm -f $tmp_search $tmp_exclude $tmp_ignore_egrep $tmp_cache" EXIT
fi


# WIP
#scan_root_symlink() {
#	find / -maxdepth 1 -type l -print0 |
#	xargs --null -- readlink -z -f |
#	sed --null-data -e 's,$,/,g' |
#	xargs --null readlink -f
#}

[ -f $tmp_cache ] && [ -s $tmp_cache ] && cachefound=true || cachefound=false

if ${OPT_NO_CACHE:-false} || ! ${cachefound:-false}; then

	#scan_root_symlink > symlinkdest

	find /usr $(find / -maxdepth 1 -type l) -type f -print0 |
	tee "$tmp_search" |
	sed --null-data -e 's,^/usr,,g' -e 'p;s,^,/usr,g' |
	xargs -0 dpkg-query -S 2>/dev/null | sed -e 's,^.*: ,,g' |
	sed -e 's,^/usr,,g' -e 'p;s,^,/usr,g' > "$tmp_exclude"

# WIP
#	find /boot -type f -print0 |
#	tee -a "$tmp_search" |
#	xargs -0 dpkg-query -S 2>/dev/null | sed -e 's,^.*: ,,g' >> "$tmp_exclude"

	cat "$tmp_search" |
	grep -h -a --null-data -vFx -f "$tmp_exclude" |
	tr \\0 \\n > "$tmp_cache"
fi

grep 2>/dev/null -hv '^$' "${ignoredir}"/*.egrep > "$tmp_ignore_egrep"

if ${OPT_IGNORE_LOCAL:-false} && [ -d "${ignorelocaldir}" ]; then
	grep 2>/dev/null -hv '^$' "${ignorelocaldir}"/*.egrep >> "$tmp_ignore_egrep"
fi

if ${OPT_VERBOSE:-false}; then
	grep -h -E -f "$tmp_ignore_egrep" "$tmp_cache" |
	sed -e 's,^,~ok: ,g'
fi

grep -h -E -v -f "$tmp_ignore_egrep" "$tmp_cache" |
sed -e 's,^,unknown ,g' |
grep '' && r=1 || r=0

if ! ${OPT_NO_CACHE:-fasle} && ${cachefound:-false}; then
	echo >&2 "$0 -f|--no-cache to force a full scan"
fi
exit $r
