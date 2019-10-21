#!/bin/sh

# gencert.sh - Multi-Server SSL Generator
# By Adamm - https://github.com/Adamm00
# 22/10/2019

PID="$$"
SN="$(< /dev/urandom tr -dc 0-9 | head -c16)"

if [ -f /usr/sbin/openssl11 ]
then
	OPENSSL=/usr/sbin/openssl11
else
	OPENSSL=/usr/sbin/openssl
fi

WAITTIMER=0
while [ -f "/var/run/gencert.pid" ] && [ "$WAITTIMER" -lt "14" ]; do
	WAITTIMER=$((WAITTIMER+2))
	sleep $WAITTIMER
done
touch /var/run/gencert.pid

cd /opt/tmp || exit 1
KEYNAME="ca.key"
CERTNAME="ca.crt"

OPENSSLCNF="/etc/openssl.config.$PID"

cp -L /etc/ssl/openssl.cnf $OPENSSLCNF

echo "0.commonName=CN" >> $OPENSSLCNF
echo "0.commonName_value=Skynet" >> $OPENSSLCNF
echo "0.organizationName=O" >> $OPENSSLCNF
echo "0.organizationName_value=Skynet" >> $OPENSSLCNF
echo "0.emailAddress=E" >> $OPENSSLCNF
echo "0.emailAddress_value=root@localhost" >> $OPENSSLCNF


# Required extension
sed -i "/\[ v3_ca \]/aextendedKeyUsage = serverAuth" $OPENSSLCNF

# Start of SAN extensions
sed -i "/\[ CA_default \]/acopy_extensions = copy" $OPENSSLCNF
sed -i "/\[ v3_ca \]/asubjectAltName = @alt_names" $OPENSSLCNF
sed -i "/\[ v3_req \]/asubjectAltName = @alt_names" $OPENSSLCNF
echo "[alt_names]" >> $OPENSSLCNF


LANIP0="192.168.1.1"
LANIP1="192.168.1.2"
LANIP2="192.168.1.69"
LANIP3="192.168.1.70"


# IP
echo "IP.0 = $LANIP0" >> $OPENSSLCNF
echo "DNS.0 = $LANIP0" >> $OPENSSLCNF # For broken clients like IE

echo "IP.1 = $LANIP1" >> $OPENSSLCNF
echo "DNS.1 = $LANIP1" >> $OPENSSLCNF # For broken clients like IE

echo "IP.2 = $LANIP2" >> $OPENSSLCNF
echo "DNS.2 = $LANIP2" >> $OPENSSLCNF # For broken clients like IE

echo "IP.3 = $LANIP3" >> $OPENSSLCNF
echo "DNS.3 = $LANIP3" >> $OPENSSLCNF # For broken clients like IE

# hostnames

COMPUTERNAME4="SkynetNAS"
echo "DNS.4 = $COMPUTERNAME4" >> $OPENSSLCNF

COMPUTERNAME5="RT-AX88U-DC28"
echo "DNS.5 = $COMPUTERNAME5" >> $OPENSSLCNF

COMPUTERNAME6="router.asus.com"
echo "DNS.6 = $COMPUTERNAME6" >> $OPENSSLCNF


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
