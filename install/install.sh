#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    cat "${BASH_SOURCE[0]}" | grep -Eo '^\s*##.*$' | sed -E 's/^.*##//g'

    ## Majormaco installation script.
    ##
    ## Use --setup switch to run installation.
    ##
    ## All necessary content will be copied to /usr/local/opt/majormaco and setted up.
    ## In order to create links just use --link switch.
    ##
    ## Your mac concierge, 2014

    exit 1
fi

command="cp -r"
installation_dir="/usr/local/opt/majormaco"

while [ -n "$1" ]; do
    [ "$1" = "--link" ] && command="ln -fs"
    shift
done

dir="$( cd "$( dirname "$( readlink "${BASH_SOURCE[0]}" )" )/../" && pwd )"

proceed()
{
    [[ "$1" =~ [Nn][Oo]* ]] && echo "$2" && exit 2

    test 0 -eq 0
}

read -p "Specify WiFi network interface (skip to default - en0): " en

en=${en:-en0}

networkinfo=$(networksetup -getairportnetwork $en | head -1; test ${PIPESTATUS[0]} -eq 0)

if [ "$?" != "0" ]; then
    echo "$networkinfo" >&2
    exit 2
fi

wifi=$(echo $networkinfo | awk '{print $4}')

read -p "Is '$wifi' WiFi network covers your safe place? [Yn]: " yn

proceed "$yn" "OK. Try again at safe place."

btlist=$($dir/bin/btutil list)

if [ -n "$btlist" ]; then
    echo -e "\nThere is a list of your paired bluetooth devices\n"
    $dir/bin/btutil list | sed -E 's/^/ - /g'
else
    echo "It seems there is no paired bluetooth devices."
    read -p "Continue? [Yn]: " yn

    proceed $yn
fi

echo -e "\nBluetooth will be used to connect to one of your specified devices in order to confirm unlock."

read -p "Specify one or more address of bluetooth devices (not from list allowed too) separated by space: " bt

echo -e "\nOkay. When this mac wake up, '$wifi' network is connected and one of these '$bt' bluetooth devices are able to connect majormaco will unlock this mac with your system password."

read -s -p "Enter the password: " pass

[ -z "$pass" ] && echo "There is no password. Can't proceed." && exit 2

keyName="majormaco-$(env LC_CTYPE=C tr -dc "a-zA-Z0-9-_" < /dev/urandom | head -c 10)"

echo ""

read -p "Enter label for KeyChain item (skip to default - $keyName) for password store: " key

[ -n "$key" ] && keyName="$key"

user=$(whoami)

security add-generic-password -U -a $user -s $keyName -w $pass

# ensure installation directory
mkdir -p $installation_dir

`$command $dir/unlock.sh $installation_dir/`
`$command $dir/bin $installation_dir/`
`$command $dir/install/majormaco.plist ~/Library/LaunchAgents/`

launchctl load ~/Library/LaunchAgents/majormaco.plist

cat $dir/install/wakeup.sh | sed -E "s/{KEY}/$keyName/g;s/{WIFI}/$wifi/g;s/{BLUETOOTH}/$bt/g" > $installation_dir/wakeup.sh

chmod +x $installation_dir/wakeup.sh

echo -e "\n\033[0;32mDone.\033[0m"
