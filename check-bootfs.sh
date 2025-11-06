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

#### CURRENT-FILES ####
( cd /boot && find ./ -type f -exec sha1sum {} \; ) |
sort -u -t\  -k3 > $installed
#### /CURRENT-FILES ####

# because dpkg -S <glob-pattern>
glob_quote() {
	sed "$@" -e 's,[[\\?*],\\\0,g'
}

#### SAFE-FILES ####
{
	# get /boot/config-* /boot/System.map-* /boot/vmlinuz-* from linux-image-* packages
	dpkg-query -L $(
		dpkg -l |cut -c5- |grep -E '^(linux-image-|ovhkernel-)'|cut -d\  -f1
	) |
	sort -u |
	grep '^/boot'

	# grub background png
	dpkg 2>&- -L desktop-base |
	grep '/grub.*\.png$'|
	sort -u

	dpkg-query -L $(
		{
			# include all content of grub packages
			dpkg -l |cut -c5- |grep -E '^(grub|grub2)-'|cut -d\  -f1

			# include all content of packages that provide any .efi files
			find /usr/ -type f -print0 |
			grep --null-data -E '\.efi(|\.signed)$' |
			sed --null-data -e 's,^/usr,,g' -e 'p;s,^,/usr,g' |
			glob_quote --null-data |
			xargs -0 dpkg-query -S 2>/dev/null |
			cut -d: -f1
		} |
		sort -u
	) |
	sort -u
} |
sort -u |
while read -r f; do
	[ -f "$f" ] || continue
	printf %s\\0 "$f"
done |
#### /SAFE-FILES ####
#### SAFE-CHECKSUM ####
xargs -0 sha1sum -z |
cut -z -d\  -f1 |
sed -z -e 's,^,^,g' |
tr \\0 \\n > $safe
#### /SAFE-CHECKSUM ####

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
