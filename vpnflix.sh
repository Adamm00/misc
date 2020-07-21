#!/bin/sh
#####################################################################################
#                                                                                   #
#               ██╗   ██╗██████╗ ███╗   ██╗███████╗██╗     ██╗██╗  ██╗              #
#               ██║   ██║██╔══██╗████╗  ██║██╔════╝██║     ██║╚██╗██╔╝              #
#               ██║   ██║██████╔╝██╔██╗ ██║█████╗  ██║     ██║ ╚███╔╝               #
#               ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║██╔══╝  ██║     ██║ ██╔██╗               #
#                ╚████╔╝ ██║     ██║ ╚████║██║     ███████╗██║██╔╝ ██╗              #
#                 ╚═══╝  ╚═╝     ╚═╝  ╚═══╝╚═╝     ╚══════╝╚═╝╚═╝  ╚═╝              #
#                                                                                   #
#                  Route Netflix/Hulu Traffic Thorugh VPN Client1                   #
#                       By Adamm - https://github.com/Adamm00                       #
#                                22/07/2020 - v1.0.2                                #
#####################################################################################


clear
sed -n '2,16p' "$0"
FWMARK_WAN="0x8000/0x8000"
FWMARK_OVPNC1="0x1000/0x1000"

Check_Lock() {
	if [ -f "/tmp/vpnflix.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/vpnflix.lock)" ] && [ "$(sed -n '2p' /tmp/vpnflix.lock)" != "$$" ]; then
		logger -st VPNFlix "[INFO] Lock File Detected ($(sed -n '1p' /tmp/vpnflix.lock)) (pid=$(sed -n '2p' /tmp/vpnflix.lock)) - Exiting (cpid=$$)"
		echo
		exit 1
	else
		echo "$@" > /tmp/vpnflix.lock
		echo "$$" >> /tmp/vpnflix.lock
	fi
}

Populate_Config() {
	if [ ! -f "/jffs/configs/dnsmasq.conf.add" ]; then
		touch /jffs/configs/dnsmasq.conf.add
	fi
	sed -i '\~# VPNFlix~d' /jffs/configs/dnsmasq.conf.add

	domainlist="\
		netflix.com
		nflxvideo.net
		nflxso.net
		nflxext.com
		nflximg.net
		nflximg.com
		netflix.net"

	domainlist2="\
		hulu.com
		hulustream.com"

	domainlist3="\
		whatismyip.host"

	{
		echo "ipset=/$(echo "$domainlist" | tr '\n' '/' | tr -d "\t")VPNFlix-Netflix # VPNFlix"
		echo "server=/$(echo "$domainlist" | tr '\n' '/' | tr -d "\t")127.0.1.1#53 # VPNFlix"
		echo "address=/$(echo "$domainlist" | tr '\n' '/' | tr -d "\t"):: # VPNFlix"
		echo "ipset=/$(echo "$domainlist2" | tr '\n' '/' | tr -d "\t")VPNFlix-Hulu # VPNFlix"
		echo "server=/$(echo "$domainlist2" | tr '\n' '/' | tr -d "\t")127.0.1.1#53 # VPNFlix"
		echo "address=/$(echo "$domainlist2" | tr '\n' '/' | tr -d "\t"):: # VPNFlix"
		echo "ipset=/$(echo "$domainlist3" | tr '\n' '/' | tr -d "\t")VPNFlix-Other # VPNFlix"
		echo "server=/$(echo "$domainlist3" | tr '\n' '/' | tr -d "\t")127.0.1.1#53 # VPNFlix"
		echo "address=/$(echo "$domainlist3" | tr '\n' '/' | tr -d "\t"):: # VPNFlix"
	} >> /jffs/configs/dnsmasq.conf.add
	chmod +x /jffs/configs/dnsmasq.conf.add
	service restart_dnsmasq
}

Filter_Version() {
	grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})'
}

Load_Menu () {
	reloadmenu="1"
	while true; do
		echo "Select Menu Option:"
		echo "[1]  --> Start VPNFlix"
		echo "[2]  --> Save"
		echo "[3]  --> Temporarily Disable VPNFlix"
		echo "[4]  --> Update VPNFlix"
		echo "[5]  --> Uninstall"
		echo
		echo "[e]  --> Exit Menu"
		echo
		printf "[1-5]: "
		read -r "menu"
		echo
		case "$menu" in
			1)
				option1="start"
				break
			;;
			2)
				option1="check"
				break
			;;
			3)
				option1="disable"
				break
			;;
			4)
			option1="update"
			while true; do
				echo "Select Update Option:"
				echo "[1]  --> Check For And Install Any New Updates"
				echo "[2]  --> Check For Updates Only"
				echo "[3]  --> Force Update Even If No Updates Detected"
				echo
				printf "[1-3]: "
				read -r "menu2"
				echo
				case "$menu2" in
					1)
						break
					;;
					2)
						option2="check"
						break
					;;
					3)
						option2="-f"
						break
					;;
					e|exit|back|menu)
						unset "option1" "option2"
						clear
						Load_Menu
						break
					;;
					*)
						echo "[*] $menu2 Isn't An Option!"
						echo
					;;
				esac
			done
			break
			;;
			5)
				option1="uninstall"
				break
			;;
			e|exit)
				echo "[*] Exiting!"
				echo; exit 0
			;;
			*)
				echo "[*] $menu Isn't An Option!"
				echo
			;;
		esac
	done
}

if [ -z "$1" ]; then
	Load_Menu
fi

if [ -n "$option1" ]; then
	set "$option1" "$option2"
fi

case "$1" in
	start)
		Check_Lock "$@"
		mkdir -p /jffs/addons/vpnflix
		if [ ! -f "/jffs/scripts/firewall-start" ]; then
			echo "#!/bin/sh" > /jffs/scripts/firewall-start
		elif [ -f "/jffs/scripts/firewall-start" ] && ! head -1 /jffs/scripts/firewall-start | grep -qE "^#!/bin/sh"; then
			sed -i '1s~^~#!/bin/sh\n~' /jffs/scripts/firewall-start
		fi
		cmdline="sh /jffs/addons/vpnflix/vpnflix.sh start # VPNFlix"
		if grep -E "sh /jffs/addons/vpnflix/vpnflix.sh .* # VPNFlix" /jffs/scripts/firewall-start 2>/dev/null | grep -qvE "^#"; then
			sed -i "s~sh /jffs/addons/vpnflix/vpnflix.sh .* # VPNFlix .*~$cmdline~" /jffs/scripts/firewall-start
		else
			echo "$cmdline" >> /jffs/scripts/firewall-start
		fi
		if [ ! -f "/jffs/configs/dnsmasq.conf.add" ]; then
			touch /jffs/configs/dnsmasq.conf.add
		fi
		if [ -d "/opt/bin" ] && [ ! -f "/opt/bin/vpnflix" ]; then
			ln -s /jffs/addons/vpnflix/vpnflix.sh /opt/bin/vpnflix
		fi
		if ! grep -F "sh /jffs/addons/vpnflix/vpnflix.sh" /jffs/configs/profile.add; then
			echo "alias vpnflix=\"sh /jffs/addons/vpnflix/vpnflix.sh\" # VPNFlix" >> /jffs/configs/profile.add
		fi
		if [ "$(nvram get vpn_client1_state)" != "2" ]; then
			nvram set vpn_client1_state="2"
			restartvpn="1"
		fi
		if [ -z "$(nvram get vpn_client_clientlist)" ]; then
			nvram set vpn_client_clientlist="<DummyVPN>172.16.1.1>0.0.0.0>VPN"
			restartvpn="1"
		fi
		if [ -z "$(nvram get vpn_client1_clientlist)" ]; then
			nvram set vpn_client1_clientlist="<DummyVPN>172.16.1.1>0.0.0.0>VPN"
			restartvpn="1"
		fi
		if [ -f "/jffs/addons/vpnflix/vpnflix.ipset" ]; then ipset restore -! -f "/jffs/addons/vpnflix/vpnflix.ipset"; fi
		if ! ipset -L -n VPNFlix-Netflix >/dev/null 2>&1; then ipset -q create VPNFlix-Netflix hash:net timeout 604800; fi
		if ! ipset -L -n VPNFlix-Hulu >/dev/null 2>&1; then ipset -q create VPNFlix-Hulu hash:net timeout 604800; fi
		if ! ipset -L -n VPNFlix-Other >/dev/null 2>&1; then ipset -q create VPNFlix-Other hash:net timeout 604800; fi
		if ! ipset -L -n VPNFlix-Master >/dev/null 2>&1; then
			ipset -q create VPNFlix-Master list:set
			ipset -q -A VPNFlix-Master VPNFlix-Netflix
			ipset -q -A VPNFlix-Master VPNFlix-Hulu
			ipset -q -A VPNFlix-Master VPNFlix-Other
		fi
		ip rule del fwmark "$FWMARK_WAN" >/dev/null 2>&1
		ip rule add from 0/0 fwmark "$FWMARK_WAN" table 254 prio 9990
		ip rule del fwmark "$FWMARK_OVPNC1" >/dev/null 2>&1
		ip rule add from 0/0 fwmark "$FWMARK_OVPNC1" table 111 prio 9995
		iptables -D PREROUTING -t mangle -m set --match-set VPNFlix-Master dst -j MARK --set-xmark "$FWMARK_OVPNC1" 2>/dev/null
		iptables -A PREROUTING -t mangle -m set --match-set VPNFlix-Master dst -j MARK --set-xmark "$FWMARK_OVPNC1" 2>/dev/null
		iptables -D POSTROUTING -t nat -s "$(nvram get vpn_server1_sn)"/24 -o tun11 -j MASQUERADE 2>/dev/null
		iptables -A POSTROUTING -t nat -s "$(nvram get vpn_server1_sn)"/24 -o tun11 -j MASQUERADE 2>/dev/null
		iptables -D PREROUTING -t mangle -i tun21 -m set --match-set VPNFlix-Master dst -j MARK --set-xmark "$FWMARK_OVPNC1" 2>/dev/null
		iptables -A PREROUTING -t mangle -i tun21 -m set --match-set VPNFlix-Master dst -j MARK --set-xmark "$FWMARK_OVPNC1" 2>/dev/null
		Populate_Config
		cru d VPNFlix_save
		cru a VPNFlix_save "30 * * * * sh /jffs/addons/vpnflix/vpnflix.sh save"
		if [ "$restartvpn" = "1" ]; then
			nvram commit
			service "restart_vpnclient1"
		fi
	;;

	save)
		Check_Lock "$@"
		echo "Saving VPNFlix Server List..."
		if ipset -L -n VPNFlix-Master >/dev/null 2>&1; then {
			ipset save VPNFlix-Netflix
			ipset save VPNFlix-Hulu
			ipset save VPNFlix-Other
			ipset save VPNFlix-Master
		} > "/jffs/addons/vpnflix/vpnflix.ipset" 2>/dev/null; fi
		echo "Complete! - $(wc -l < /jffs/addons/vpnflix/vpnflix.ipset) Entries Total"
	;;

	disable)
		Check_Lock "$@"
		echo "Disabing VPNFlix Policy Routing..."
		ip rule del fwmark "$FWMARK_WAN" >/dev/null 2>&1
		ip rule del fwmark "$FWMARK_OVPNC1" >/dev/null 2>&1
		iptables -D PREROUTING -t mangle -m set --match-set VPNFlix-Master dst -j MARK --set-mark "$FWMARK_OVPNC1" 2>/dev/null
		iptables -D POSTROUTING -t nat -s "$(nvram get vpn_server1_sn)"/24 -o tun11 -j MASQUERADE 2>/dev/null
		iptables -D PREROUTING -t mangle -i tun21 -m set --match-set VPNFlix-Master dst -j MARK --set-xmark "$FWMARK_OVPNC1" 2>/dev/null
		if ipset -L -n VPNFlix-Master >/dev/null 2>&1; then
			{
				ipset save VPNFlix-Netflix
				ipset save VPNFlix-Hulu
				ipset save VPNFlix-Other
				ipset save VPNFlix-Master
			} > "/jffs/addons/vpnflix/vpnflix.ipset" 2>/dev/null
		fi
		ipset destroy VPNFlix-Master
		ipset destroy VPNFlix-Netflix
		ipset destroy VPNFlix-Hulu
		ipset destroy VPNFlix-Other
		echo "Complete!"
	;;

	update)
		Check_Lock "$@"
		remotedir="https://raw.githubusercontent.com/Adamm00/misc/master"
		localver="$(Filter_Version < "$0")"
		remotever="$(curl -fsL --retry 3 --connect-timeout 3 "${remotedir}/vpnflix.sh" | Filter_Version)"
		localmd5="$(md5sum "$0" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 3 --connect-timeout 3 "${remotedir}/vpnflix.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" = "$remotemd5" ] && [ "$2" != "-f" ]; then
			echo "[i] VPNFlix Up To Date - $localver (${localmd5})"
			noupdate="1"
		elif [ "$localmd5" != "$remotemd5" ] && [ "$2" = "check" ]; then
			echo "[i] VPNFlix Update Detected - $remotever (${remotemd5})"
			noupdate="1"
		elif [ "$2" = "-f" ]; then
			echo "[i] Forcing Update"
		fi
		if [ "$localmd5" != "$remotemd5" ] || [ "$2" = "-f" ] && [ "$noupdate" != "1" ]; then
			echo "[i] New Version Detected - Updating To $remotever (${remotemd5})"
			curl -fsL --retry 3 --connect-timeout 3 "${remotedir}/vpnflix.sh" -o "$0"
			echo "[i] Update Complete!"
			echo
			exit 0
		fi
	;;

	uninstall)
		Check_Lock "$@"
		echo "If You Were Experiencing Issues, Try Update Or Visit SNBForums/Github For Support"
		echo "https://github.com/Adamm00/misc"
		echo
		while true; do
			echo "[!] Warning - This Will Delete All VPNFlix Related Files"
			echo "Are You Sure You Want To Uninstall?"
			echo
			echo "[1]  --> Yes"
			echo "[2]  --> No"
			echo
			echo "Please Select Option"
			printf "[1-2]: "
			read -r "continue"
			echo
			case "$continue" in
				1)
					echo "[i] Deleting VPNFlix Files"
					sed -i '\~# VPNFlix~d' /jffs/configs/dnsmasq.conf.add /jffs/scripts/firewall-start /jffs/configs/profile.add
					ip rule del fwmark "$FWMARK_WAN" >/dev/null 2>&1
					ip rule del fwmark "$FWMARK_OVPNC1" >/dev/null 2>&1
					iptables -D PREROUTING -t mangle -m set --match-set VPNFlix-Master dst -j MARK --set-mark "$FWMARK_OVPNC1" 2>/dev/null
					ipset destroy VPNFlix-Master
					ipset destroy VPNFlix-Netflix
					ipset destroy VPNFlix-Hulu
					ipset destroy VPNFlix-Other
					rm -rf /jffs/addons/vpnflix
					echo "[i] Complete!"
					echo
					exit 0
				;;
				2|e|exit)
					echo "[*] Exiting!"
					echo; exit 0
				;;
				*)
					echo "[*] $continue Isn't An Option!"
					echo
				;;
			esac
		done
	;;

	*)
		echo "Command Not Recognized, Please Try Again"
		echo "Accepted Commands Are; (sh $0 [start|save|disable|update|uninstall])"
		echo
		exit 2
	;;
esac

if [ -f "/tmp/vpnflix.lock" ] && [ "$$" = "$(sed -n '2p' /tmp/vpnflix.lock)" ]; then rm -rf "/tmp/vpnflix.lock"; fi
if [ -n "$reloadmenu" ]; then echo; echo; printf "[i] Press Enter To Continue..."; read -r "continue"; exec "$0"; fi