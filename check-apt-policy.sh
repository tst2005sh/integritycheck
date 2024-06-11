

check_recent() {
	apt search '' 2>&- |grep '^[^ ]' |grep -w 'installed' |grep -w 'local' |cut -d/ -f1
}

check_legacy() {
	for p in $(LANG=C dpkg -l |tail -n +6 |awk '{print $2}'); do apt-cache policy $p |grep '^        ' |grep -v /var/lib/dpkg/status|tr \\n \; |grep -q '' || echo "$p";done
}

OPT_APT_POLICY=false
OPT_LEGACY=false
while [ $# -gt 0 ]; do
	case "$1" in
	(--legacy) OPT_LEGACY=true;;
	(-v|-p|--policy) OPT_APT_POLICY=true ;;
	(*) break ;;
	esac
	shift
done

if ${OPT_APT_POLICY:-false}; then

	if ${OPT_LEGACY:-false}; then
		check_legacy
	else
		check_recent
	fi | xargs apt policy
else
	if ${OPT_LEGACY:-false}; then
		check_legacy
	else
		check_recent
	fi
fi
