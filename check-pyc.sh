#!/bin/sh
find /usr/ -mount -type f -name '*.cpython-*.pyc' |
while read -r pyc; do
	py="$(
		printf %s\\n "$pyc" |
		sed -E -e 's,/__pycache__/([^/.]+)\.cpython-[0-9.]+.pyc$,/\1.py,g'
	)"
	[ -f "$py" ] || echo >&2 "MISSING py file $py (but $pyc exists)"
done
