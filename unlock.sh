#!/bin/bash -e

# lockfile -0 -r 1 -l 4 -s 0 '/tmp/unlock.sh.lock' &>/dev/null || exit 3

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

keyChainItemName=$1
homeWiFi=$2
btPassive=$3
btActive=$4

homeLocation=$(echo "$5 $6" | sed -E 's/(^[ ]+|[ ]+$)//g')
locationAccuracy=$7

openSesame()
{
	[ -n "$TEST" ] && echo "Welcome!" && exit 0

	aPass=$(security 2>&1 >/dev/null find-generic-password -gl "$keyChainItemName" | awk '{print $2}' | sed -E 's/(^"|"$)//g')

	osascript -e "tell application \"System Events\" to keystroke \"$aPass\"" 
	sleep .1
	osascript -e "tell application \"System Events\" to keystroke return"
}

getWiFi()
{
    echo `networksetup -getairportnetwork en0 | head -1 | awk '{print $4}'`
}

getBluetooth()
{
	btOne=$(echo $btPassive | sed 's/:/-/g')
	btTwo=$(echo $btActive | sed 's/:/-/g')
	result=$(system_profiler -xml SPBluetoothDataType | xpath "boolean(/plist/array/dict/array/dict/array/dict/dict[string='$btOne' or string='$btTwo']/key[.='device_isconnected']/following-sibling::string[1][.='attrib_Yes']"  2>&1 | sed -E 's/^.+Value: //g;s/1/OK/g;s/0//g')

	syslog -s -l notice "No connected device"

	if [ -z "$result" ]; then
		syslog -s -l notice "Force connect to device"

		result=$(cat << __EOF | sed -E 's/^[	 ]+//g' | python - "$btActive" 1 | grep -E '^OK$'
			import sys
			import lightblue

			address = sys.argv[1]
			channel = int(sys.argv[2])

			s = lightblue.socket()
			s.connect((address, channel))

			print 'OK'

			s.close()
__EOF)
	fi
	
	echo "$result"
}

getLocation()
{
    echo `/usr/local/bin/whereami | head -3 | tr '\n' ' ' | sed -E 's/[A-Za-z:()]//g;s/^[ ]+//g;s/[ ]+$//g;s/[ ]+/ /g'`
}


[ -n "$btPassive" ] && [ -z "$(getBluetooth)" ] && syslog -s -l notice 'No Bluetooth found' && exit 1

[ -n "$btPassive" ] && syslog -s -l notice 'Bluetooth matched'

syslog -s -l notice "Bluetooth matched"

for i in $(jot 10); do
    aWiFi=$(getWiFi)
    [ "$aWiFi" == "$homeWiFi" ] && echo "WiFi SSID matched" && break
    echo "Tested SSID: $aWiFi"
    aWiFi=""

    sleep 1
done

[ -z "$aWiFi" ] && exit 1

syslog -s -l notice "WiFi matched"

[ -z "$homeLocation" ] && echo "No home location check." && openSesame && exit 0

currentLocation=$(getLocation)
read -a params <<< "$homeLocation $currentLocation"

distanceToHome=$(cat << __EOF | python - "${params[@]}" 
	import sys
	import math

	EARTH_RADIUS = 6371.0072

	def toRads(degrees):
	    return (degrees * (math.pi / 180))

	lat1  = toRads(float(sys.argv[1]))
	long1 = toRads(float(sys.argv[2]))
	lat2  = toRads(float(sys.argv[3]))
	long2 = toRads(float(sys.argv[4]))

	dLat  = lat2 - lat1
	dLong = long2 - long1

	a = math.sin(dLat/2) * math.sin(dLat/2) + math.cos(lat1) * math.cos(lat2) * math.sin(dLong/2) * math.sin(dLong/2)
	c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

	print (EARTH_RADIUS * c)
__EOF)


# distanceToHome=$(python $dir/distance.py "${params[@]}")

#: ${locationAccuracy:=$(bc <<< "scale=13; ${params[4]} / 1000")}

echo "Distance to home $distanceToHome m, location accuracy $locationAccuracy m" 

[ $(bc -l <<< "$distanceToHome > $locationAccuracy") == 1] && echo "Too far from home, bye" && exit 2

# get pass only if screen really locked
# userIdle=`/usr/sbin/ioreg -c IOHIDSystem | sed -e '/HIDIdleTime/ !{ d' -e 't' -e '}' -e 's/.* = //g' -e 'q'`
# [ $(bc <<< "scale=0; $userIdle / 100000000") != 0 ] && echo "We're not screen-locked, bye" && exit 0

openSesame
exit 0