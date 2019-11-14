#!/bin/sh
# PIA IP Rotator By Adamm - 15/11/19
# Rotate PIA Server IP's To Avoid Geo-Blocking

if [ -d "/opt/bin" ] && [ ! -L "/opt/bin/pia" ]; then
	ln -s /jffs/scripts/pia.sh /opt/bin/pia
fi

Is_IP () {
		grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

if [ ! -f /jffs/scripts/pia.blacklist ]; then
	touch /jffs/scripts/pia.blacklist
fi

echo "PIA Server Selecter"
while true; do
echo
echo "Select VPN Client To Modify:"
echo
printf "[1-5]: "
read -r "client"
echo
serverclient="$client"
	case "$client" in
		1)
			client=""
			break
		;;
		2)
			break
		;;
		3)
			break
		;;
		4)
			break
		;;
		5)
			break
		;;
		list)
			curl -fs https://www.privateinternetaccess.com/pages/network/ | sed -n 's:.*<p data-label=\"Hostname\" class=\"hostname\">\(.*\)</p>.*:\1:p'
		;;
		e|exit|back|menu)
			exit 0
			break
		;;
		*)
			echo "[*] $client Isn't An Option!"
		;;
	esac
done
echo "Input New Server IP/URL:"
echo
printf "[IP/URL]: "
read -r "server"
case "$server" in
	e|exit|back|menu)
		exit 0
	;;
	*)
	if ping -q -w3 -c1 "$server" >/dev/null 2>&1; then
		if echo "$server" | Is_IP; then
			nvram set "vpn_client${serverclient}_addr=$server"
			nvram commit
		fi
	else
		echo "Error Connecting To $server"
		exit 1
	fi
esac
if ! echo "$server" | Is_IP; then
	echo
	echo "Individual Server IP's:"
	echo
	serverlist="$(nslookup "$server" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | awk 'NR>2')"
	for ip in $serverlist; do
		if echo "$ip" | grep -qf /jffs/scripts/pia.blacklist; then
			echo "$ip - [Blacklisted]"
		else
			echo "$ip"
		fi
	done
	echo
	echo "Rotating IP List"
	for serverip in $(echo "$serverlist" | grep -vf /jffs/scripts/pia.blacklist); do
		if ping -q -w3 -c1 "$serverip" >/dev/null 2>&1; then
			nvram set "vpn_client${serverclient}_addr=$serverip"
			nvram commit
			service "restart_vpnclient${serverclient}"
			while true; do
				echo "Keep ${serverip}?:"
				echo "[1]  --> Yes"
				echo "[2]  --> No"
				echo
				printf "[1-2]: "
				read -r "menu"
				echo
				case "$menu" in
					1)
						echo "VPN Server Set To ${serverip}"
						exit 1
						break
					;;
					2)
						echo "Attempting next IP"
						echo "$serverip" >> /jffs/scripts/pia.blacklist
						break
					;;
					e|exit|back|menu)
						exit 0
						break
					;;
					*)
						echo "[*] $menu Isn't An Option!"
						echo
					;;
				esac
			done
		else
			echo "Error Connecting To $serverip"
		fi
	done
fi
