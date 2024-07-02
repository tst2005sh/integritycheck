#!/bin/sh

tmpdir="$(mktemp -d)"
trap "rm -rf -- '$tmpdir'" EXIT

find /usr/ -mount -type f -name '*.cpython-*.pyc' |
#head -1000 |
while read -r pyc; do
	py="$(
		printf %s\\n "$pyc" |
		sed -E -e 's,/__pycache__/([^/.]+)\.cpython-[0-9.]+.pyc$,/\1.py,g'
	)"
	#echo >&2 "# $pyc"
	#echo >&2 "# $py"

	if [ ! -f "$py" ]; then
		echo >&2 "MISSING py file $py (but $pyc exists)"
		continue
	fi
	d="$(dirname "$py")"
	py2="$tmpdir/$(basename "$py")"
	cp -a "$py" "$py2"
	(
		cd $tmpdir &&
		python3 -m compileall -qq -p "$d" "$(basename "$py")" 2>&- ||
		echo "# ERROR with file $py $pyc"
	)
	pyc2="$tmpdir/__pycache__/$(basename "$pyc")"
	if [ ! -f "$pyc2" ]; then
		echo >&2 "no such $pyc2 ($pyc $py)"
		find "$tmpdir" -type f -name '*.pyc'
		break
	fi
	# craft the sha1sum with the system-side path
	echo "$(sha1sum "$pyc2"|cut -d\  -f1)  $pyc"
	rm -f -- "$pyc2" "$py2"
	#find $tmpdir
	#break
done
