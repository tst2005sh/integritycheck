#!/bin/sh
if ! command -v fwupdtool >/dev/null 2>&1; then
	echo >&2 "$0:No such fwupdtool command (you may install fwupd)"
	exit 1
fi
fwupdtool update
