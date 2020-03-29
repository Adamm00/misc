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
#                      Route Netflix Traffic Thorugh VPN Client1                    #
#                        By Adamm - https://github.com/Adamm00                      #
#                                   26/02/2020                                      #
#####################################################################################

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
		netflix.net"

	domainlist2="\
		whatismyip.host"

	{
		echo "ipset=/$(echo "$domainlist" | tr '\n' '/' | tr -d "\t")VPNFlix-Netflix # VPNFlix"
		echo "server=/$(echo "$domainlist" | tr '\n' '/' | tr -d "\t")127.0.1.1#53 # VPNFlix"
		echo "address=/$(echo "$domainlist" | tr '\n' '/' | tr -d "\t"):: # VPNFlix"
		echo "ipset=/$(echo "$domainlist2" | tr '\n' '/' | tr -d "\t")VPNFlix-Other # VPNFlix"
		echo "server=/$(echo "$domainlist2" | tr '\n' '/' | tr -d "\t")127.0.1.1#53 # VPNFlix"
		echo "address=/$(echo "$domainlist2" | tr '\n' '/' | tr -d "\t"):: # VPNFlix"
	} >> /jffs/configs/dnsmasq.conf.add
	chmod +x /jffs/configs/dnsmasq.conf.add
	service restart_dnsmasq
}

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
		if ! ipset -L -n VPNFlix-Other >/dev/null 2>&1; then ipset -q create VPNFlix-Other hash:net timeout 604800; fi
		if ! ipset -L -n VPNFlix-Master >/dev/null 2>&1; then
			ipset -q create VPNFlix-Master list:set
			ipset -q -A VPNFlix-Master VPNFlix-Netflix
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
		if ipset -L -n VPNFlix-Master >/dev/null 2>&1; then {
			ipset save VPNFlix-Netflix
			ipset save VPNFlix-Other
			ipset save VPNFlix-Master
		} > "/jffs/addons/vpnflix/vpnflix.ipset" 2>/dev/null; fi
		ipset destroy VPNFlix-Master
		ipset destroy VPNFlix-Netflix
		ipset destroy VPNFlix-Other
                cru d VPNFlix_save
		echo "Complete!"
	;;
	uninstall)
		Check_Lock "$@"
		echo "Uninstalling VPNFlix..."
                sh ./vpnflix.sh disable #disable it first
		sed -i '\~# VPNFlix~d' /jffs/configs/dnsmasq.conf.add /jffs/scripts/firewall-start
		rm -rf /jffs/addons/vpnflix
		echo "Complete!"
	;;
	*)
		echo "Command Not Recognized, Please Try Again"
		echo "Accepted Commands Are; (sh $0 [start|save|disable|uninstall])"
		echo
		exit 2
	;;
esac

if [ -f "/tmp/vpnflix.lock" ] && [ "$$" = "$(sed -n '2p' /tmp/vpnflix.lock)" ]; then rm -rf "/tmp/vpnflix.lock"; fi
