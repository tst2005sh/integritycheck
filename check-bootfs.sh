#!/bin/sh

cd "$(dirname "$0")" || exit 1

#safe=/tmp/safe ; installed=/tmp/installed
safe=$(mktemp) ; installed=$(mktemp) ; stats=$(mktemp)
trap "rm -f $safe $installed $stats" EXIT

verbose=false
while [ $# -gt 0 ]; do
	case "$1" in
	(-v) verbose=true;;
	(--) shift; break;;
	(-*) echo >&2 "$0: ERROR: Unknown option $1";exit 1;;
	esac
	shift
done

{
	# get /boot/config-* /boot/System.map-* /boot/vmlinuz-* from linux-image-* packages
	dpkg-query -L $(
		dpkg -l |cut -c5- |grep -E '^(linux-image-|ovhkernel-)'|cut -d\  -f1
	) |
	sort -u |
	grep '^/boot'

	# search all files from grub-* and grub2-*
	dpkg-query -L $(
		dpkg -l |cut -c5- |grep -E '^grub(|2)-'|cut -d\  -f1
	) |
	sort -u
} |
while read -r f; do
	[ -f "$f" ] || continue
	printf %s\\n "$f"
done |
xargs sha1sum -z |
cut -z -d\  -f1 |
sed -z -e 's,^,^,g' |
tr \\0 \\n > $safe

( cd /boot && find ./ -type f -exec sha1sum {} \; ) |
sort -u -t\  -k3 > $installed


grep -f $safe $installed > $stats
stats_ok="$(cat $stats |wc -l |cut -d\  -f1)"

if ${verbose:-false}; then
	cat $stats |
	sed -E -e 's,^([^ ]+  )\./,\1/boot/,g' -e 's,^,OK:,g'
	> $stats
fi

grep -v -f $safe $installed |
tee $stats |
sed -E  -e 's,^([^ ]+  )\./,\1/boot/,g' -e 's,^,unknown:,g'
stats_ko="$(cat $stats |wc -l |cut -d\  -f1)"

echo >&2 "Stats: $stats_ko unknown / $(( $stats_ok + $stats_ko )) total"

