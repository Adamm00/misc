#!/bin/sh
# VPNFlix By Adamm - 01/04/18
# Route Netflix Traffic Thorugh VPN Client1

Check_Lock () {
		if [ -f "/tmp/vpnflix.lock" ] && [ -d "/proc/$(sed -n '2p' /tmp/vpnflix.lock)" ] && [ "$(sed -n '2p' /tmp/vpnflix.lock)" != "$$" ] ; then
			logger -st VPNFlix "[INFO] Lock File Detected ($(sed -n '1p' /tmp/vpnflix.lock)) (pid=$(sed -n '2p' /tmp/vpnflix.lock)) - Exiting (cpid=$$)"
			echo
			exit 1
		else
			echo "$@" > /tmp/vpnflix.lock
			echo "$$" >> /tmp/vpnflix.lock
		fi
}

case "$1" in

	start)
		Check_Lock "$@"
		if [ -d "/opt/bin" ] && [ ! -f "/opt/bin/vpnflix" ]; then
			ln -s /jffs/scripts/vpnflix.sh /opt/bin/vpnflix
		fi
		if [ "$(nvram get vpn_client1_state)" != "2" ]; then nvram set vpn_client1_state="2"; fi
		if [ -f "/jffs/scripts/vpnflix.ipset" ]; then ipset restore -! -f "/jffs/scripts/vpnflix.ipset"; fi
		if ! ipset -L -n VPNFlix-Netflix >/dev/null 2>&1; then ipset -q create VPNFlix-Netflix hash:net timeout 604800; fi
		if ! ipset -L -n VPNFlix-Other >/dev/null 2>&1; then ipset -q create VPNFlix-Other hash:net timeout 604800; fi
		if ! ipset -L -n VPNFlix-Master >/dev/null 2>&1; then ipset -q create VPNFlix-Master list:set; ipset -q -A VPNFlix-Master VPNFlix-Netflix; ipset -q -A VPNFlix-Master VPNFlix-Other; fi
		FWMARK_WAN="0x8000/0x8000"
		FWMARK_OVPNC1="0x1000/0x1000"
		ip rule del fwmark "$FWMARK_WAN" > /dev/null 2>&1
		ip rule add from 0/0 fwmark "$FWMARK_WAN" table 254 prio 9990
		ip rule del fwmark "$FWMARK_OVPNC1" > /dev/null 2>&1
		ip rule add from 0/0 fwmark "$FWMARK_OVPNC1" table 111 prio 9995
		iptables -D PREROUTING -t mangle -m set --match-set VPNFlix-Master dst -j MARK --set-mark "$FWMARK_OVPNC1" 2>/dev/null
		iptables -A PREROUTING -t mangle -m set --match-set VPNFlix-Master dst -j MARK --set-mark "$FWMARK_OVPNC1" 2>/dev/null
		sed -i '\~#VPNFlix~d' /jffs/configs/dnsmasq.conf.add
		echo "ipset=/netflix.com/nflxvideo.net/nflxso.net/nflxext.com/nflximg.net/VPNFlix-Netflix #VPNFlix" >> /jffs/configs/dnsmasq.conf.add
		chmod +x /jffs/configs/dnsmasq.conf.add
		cru d VPNFlix_save
		cru a VPNFlix_save "30 * * * * sh /jffs/scripts/vpnflix.sh save"
	;;
	save)
		Check_Lock "$@"
		echo "Saving VPNFlix Server List..."
		if ipset -L -n VPNFlix-Master >/dev/null 2>&1; then { ipset save VPNFlix-Netflix; ipset save VPNFlix-Other; ipset save VPNFlix-Master; } > "/jffs/scripts/vpnflix.ipset" 2>/dev/null; fi
		echo "Complete! - $(wc -l < /jffs/scripts/vpnflix.ipset) Entries Total"
	;;
	disable)
		Check_Lock "$@"
		echo "Disabing VPNFlix Policy Routing..."
		ip rule del fwmark "$FWMARK_WAN" > /dev/null 2>&1
		ip rule del fwmark "$FWMARK_OVPNC1" > /dev/null 2>&1
		iptables -D PREROUTING -t mangle -m set --match-set VPNFlix-Master dst -j MARK --set-mark "$FWMARK_OVPNC1" 2>/dev/null
		if ipset -L -n VPNFlix-Master >/dev/null 2>&1; then { ipset save VPNFlix-Netflix; ipset save VPNFlix-Other; ipset save VPNFlix-Master; } > "/jffs/scripts/vpnflix.ipset" 2>/dev/null; fi
		ipset destroy VPNFlix-Master
		ipset destroy VPNFlix-Netflix
		ipset destroy VPNFlix-Other
		echo "Complete!"
	;;
	install)
		Check_Lock "$@"
		echo "Installing VPNFlix..."
		if [ ! -f "/jffs/scripts/firewall-start" ]; then
			echo "#!/bin/sh" > /jffs/scripts/firewall-start
		elif [ -f "/jffs/scripts/firewall-start" ] && ! head -1 /jffs/scripts/firewall-start | grep -qE "^#!/bin/sh"; then
			sed -i '1s~^~#!/bin/sh\n~' /jffs/scripts/firewall-start
		fi
		cmdline="sh /jffs/scripts/vpnflix.sh start # VPNFlix"
		if grep -E "sh /jffs/scripts/vpnflix.sh .* # VPNFlix" /jffs/scripts/firewall-start 2>/dev/null | grep -qvE "^#"; then
			sed -i "s~sh /jffs/scripts/vpnflix.sh .* # VPNFlix .*~$cmdline~" /jffs/scripts/firewall-start
		else
			echo "$cmdline" >> /jffs/scripts/firewall-start
		fi
		echo "Complete!"
	;;
	*)
		echo "Command Not Recognized, Please Try Again"
		echo "Accepted Commands Are; (sh $0 [start|save|disable])"
		echo; exit 2
	;;

esac

if [ -f "/tmp/vpnflix.lock" ] && [ "$$" = "$(sed -n '2p' /tmp/vpnflix.lock)" ]; then rm -rf "/tmp/vpnflix.lock"; fi