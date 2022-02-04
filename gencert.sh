#!/bin/sh

# gencert.sh - Multi-Server SSL Generator
# By Adamm - https://github.com/Adamm00
# 04/02/2022

PID="$$"
SN="$(tr -dc 0-9 < /dev/urandom | head -c16)"

if [ -f "/usr/sbin/openssl11" ]; then
	OPENSSL=/usr/sbin/openssl11
else
	OPENSSL=/usr/sbin/openssl
fi

WAITTIMER=0
while [ -f "/var/run/gencert.pid" ] && [ "$WAITTIMER" -lt "14" ]; do
	WAITTIMER=$((WAITTIMER + 2))
	sleep $WAITTIMER
done
touch /var/run/gencert.pid

cd /opt/tmp || exit 1
KEYNAME="ca.key"
CERTNAME="ca.crt"

OPENSSLCNF="/etc/openssl.config.$PID"

cp -L /etc/ssl/openssl.cnf $OPENSSLCNF

{
	echo "0.commonName=CN"
	echo "0.commonName_value=Skynet"
	echo "0.organizationName=O"
	echo "0.organizationName_value=Skynet"
	echo "0.emailAddress=E"
	echo "0.emailAddress_value=root@localhost"
} >> $OPENSSLCNF

# Required extension
sed -i "/\[ v3_ca \]/aextendedKeyUsage = serverAuth" $OPENSSLCNF

# Start of SAN extensions
sed -i "/\[ CA_default \]/acopy_extensions = copy" $OPENSSLCNF
sed -i "/\[ v3_ca \]/asubjectAltName = @alt_names" $OPENSSLCNF
sed -i "/\[ v3_req \]/asubjectAltName = @alt_names" $OPENSSLCNF
echo "[alt_names]" >> $OPENSSLCNF

# IP

laniplist="\
	192.168.1.1
	192.168.50.1
	192.168.1.69"

i="0"
for ip in $laniplist; do
	echo "IP.$i = $ip"
	echo "DNS.$i = $ip"
	i="$((i + 1))"
done >> $OPENSSLCNF

# hostnames

computernamelist="\
	SkynetNAS
	RT-AX88U-DC28
	RT-AX86U-38B8
	router.asus.com"

for computername in $computernamelist; do
	echo "DNS.$i = $computername"
	i="$((i + 1))"
done >> $OPENSSLCNF

# create the key
$OPENSSL genpkey -out $KEYNAME.$PID -algorithm rsa -pkeyopt rsa_keygen_bits:2048
# create certificate request and sign it
$OPENSSL req -new -x509 -key $KEYNAME.$PID -sha256 -out $CERTNAME.$PID -days 825 -config $OPENSSLCNF -set_serial "$SN"

# server.pem for WebDav SSL
# cat $KEYNAME.$PID $CERTNAME.$PID > server.pem

mv $KEYNAME.$PID $KEYNAME
mv $CERTNAME.$PID $CERTNAME

chmod 640 $KEYNAME
chmod 640 $CERTNAME

rm -f $OPENSSLCNF /var/run/gencert.pid