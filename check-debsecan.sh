#!/bin/sh

s_to_dhms() {
	local s=$(( $1 % 60 ))
	local m=$(( $1 / 60 % 60 ))
	local h=$(( $1 / 3600 % 24 ))
	local d=$(( $1 / 86400 ))
	if [ ${d:-0} -gt 0 ]; then
		printf '%dd %02dh %02dm %02ds\n' "$d" "$h" "$m" "$s"
	else
		printf '%2dh %02dm %02ds\n' "$h" "$m" "$s"
	fi
}
show_cvedb_age() {
	local age=$(( $(date +%s) -$(head -2 /var/lib/debsecan/history |tail -1) )) 
	#local age=$(( $(date +%s) -$(date +%s -d '-1day-7hour-0minute-34second') ))

	local age_txt="$(s_to_dhms "$age")"
	if [ ${d:-0} -gt 0 ]; then
		echo >&2 "WARN: debsecan CVE database seems too old : $age_txt > 1 day"
	else
		echo >&2 "INFO: debsecan CVE database last update : $age_txt < 1 day"
	fi
}

show_fixable_packages() {
	debsecan --suite "$SUITE" --format packages --only-fixed > "$tmp"

	# Workaround pour ignorer les vieux kernel
	splitpattern='^(linux-headers-|linux-image-)'

	# 1) lister tout ce qui n'est PAS linux-image-* ou linux-headers-*
	grep -vE "$splitpattern" "$tmp"

	# 2) lister tout ce qui est linux-image-* ou linux-headers-* avec grep $(uname -r)
	grep -E "$splitpattern" "$tmp" | grep "$(uname -r)"'$'
}
show_unfixed_stats() {
	# format simple = CVE space PACKAGE
	debsecan --suite $SUITE --format simple > "$tmp"
	# CVE
	count1="$({
		splitpattern='^CVE[^ ]* (linux-headers-|linux-image-)'
		grep -vE "$splitpattern" "$tmp" | cut -d\  -f1
		grep -E "$splitpattern" "$tmp" | grep "$(uname -r)"'$' | cut -d\  -f1
	} |sort -u | wc -l)"

	# packages
	count2="$({
		splitpattern='^CVE[^ ]* (linux-headers-|linux-image-)'
		grep -vE "$splitpattern" "$tmp" | cut -d\  -f2
		grep -E "$splitpattern" "$tmp" | grep "$(uname -r)"'$' | cut -d\  -f2
	} |sort -u | wc -l)"

	#echo "$count1 $count2"
	#echo "$(debsecan --suite $SUITE --format bugs |sort -u |wc -l) $(debsecan --suite $SUITE --format packages |sort -u |wc -l)"

	echo >&2 "INFO: $count2 installed packages provide $count1 unfixed CVE"
}

tmp=$(mktemp); trap "rm -f $tmp" EXIT;

SUITE="$(if test -f /etc/os-release; then grep ^VERSION_CODENAME= /etc/os-release|cut -d= -f2; else echo GENERIC;fi)"
show_fixable_packages
show_unfixed_stats
show_cvedb_age
