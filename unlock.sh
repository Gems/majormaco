#!/usr/bin/env bash

set -e

# lockfile -0 -r 1 -l 4 -s 0 '/tmp/unlock.sh.lock' &>/dev/null || exit 3

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $dir

key=  wifi=  en="en0"  bt=

while true; do
  case "$1" in
    --key ) key="$2"; shift 2 ;;
    --wifi ) wifi="$2"; shift 2;;
    --wifi-interface ) en="$2"; shift 2;;
    --bt ) bt=$(echo "$2" | sed 's/:/-/g'); shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

openSesame()
{
	[ -n "$TEST" ] && echo "Welcome!" && exit 0

	aPass=$(security 2>&1 >/dev/null find-generic-password -gl "$key" | sed -E 's/(^password: "([^"]+)"$)/\2/g')

	osascript -e "tell application \"System Events\" to keystroke \"$aPass\""
	sleep .1
	osascript -e "tell application \"System Events\" to keystroke return"
}

getWiFi()
{
    networkinfo=$(networksetup -getairportnetwork $en | head -1; test ${PIPESTATUS[0]} -eq 0)

	if [ "$?" != 0 ]; then
		echo "$networkinfo" >&2
		exit 1
	fi

	echo $networkinfo | awk '{print $4}'
}

getBluetooth()
{
	btlist=$(echo "$bt" | awk '{print toupper($0)}')

	result=$(system_profiler -xml SPBluetoothDataType | xpath "boolean(/plist/array/dict/array/dict/array/dict/dict[contains(string, '$btlist')]/key[.='device_isconnected']/following-sibling::string[1][.='attrib_Yes']"  2>&1 | sed -E 's/^.+Value: //g;s/1/OK/g;s/0//g')

    btlist=$(echo "$bt" | awk '{print tolower($0)}' | sed 's/ /|/g')

    for i in $(jot 2); do
	    if [ -z "$result" ]; then
            result=$(bin/btutil list | grep -Eo "^ON ($btlist)")
        fi

        if [ -z "$result" ]; then
            result=$(bin/btutil list | grep -Eo "($btlist)" | xargs -P 2 -n 1 bin/btutil connect | grep -Eo '^OK.')
        fi

		if [ -n "$result" ]; then
            break
        fi
	done

	echo "$result"
}

[ -z "$(getBluetooth)" ] && syslog -s -l notice 'No Bluetooth found' && exit 1

syslog -s -l notice "Bluetooth matched"

for i in $(jot 10); do
    aWiFi=$(getWiFi)
    [ "$aWiFi" == "$wifi" ] && syslog -s -l notice "WiFi SSID matched" && break
    aWiFi=""

    sleep 1
done

[ -z "$aWiFi" ] && exit 1

syslog -s -l notice "WiFi matched"

openSesame
