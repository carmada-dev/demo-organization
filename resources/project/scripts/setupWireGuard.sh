#!/bin/bash

echo '====================================================================================================================='
echo `$(basename "$0") $@`
echo '====================================================================================================================='

ENDPOINT=''
HRANGE=''
VRANGE=''
IRANGES=()

while getopts 'e:h:v:i:' OPT; do
    case "$OPT" in
		e)
			ENDPOINT="${OPTARG}" ;;
		h)
			HRANGE="${OPTARG}" ;;
		v)
			VRANGE="${OPTARG}" ;;
		i)
			IRANGES+=("${OPTARG}") ;;
    esac
done

# install required packages
sudo apt-get install -y coreutils iptables wireguard nmap 

# enable IP forwarding
sudo sed -i -e 's/#net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sed -i -e 's/#net.ipv6.conf.all.forwarding.*/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sudo sysctl -p

# get all available IP addresses in the provided IP range / CIDR block
# CAUTION: leave the outer parenthesis where they are to get the result as array
VRANGEIPS=($(nmap -sL -n $VRANGE | awk '/Nmap scan report/{print $NF}'))

SERVER_PATH='/etc/wireguard'
sudo rm -rf $SERVER_PATH/*

SERVER_HOST=$(echo $ENDPOINT | cut -d ':' -f1)
SERVER_PORT=$(echo $ENDPOINT | cut -d ':' -f2)

if [ "$SERVER_HOST" -eq "$SERVER_PORT" ]; then
	# fallback to default wireguard port
	# if no port number was provided by
	# the script's endpoint argument
	SERVER_PORT='51820'
fi

SERVER_PRIVATEKEY=$(wg genkey)
SERVER_PUBLICKEY=$(echo $SERVER_PRIVATEKEY | wg pubkey)

echo "Creating WireGuard server configuration ..." && sudo tee $SERVER_PATH/wg0.conf <<EOF

[Interface]
Address = ${VRANGEIPS[1]}
PrivateKey = $SERVER_PRIVATEKEY
ListenPort = $SERVER_PORT

PostUp = iptables -I FORWARD 1 -i eth0 -o wg0 -j ACCEPT
PostUp = iptables -I FORWARD 1 -i wg0 -o eth0 -j ACCEPT
PostDown = iptables -D FORWARD -i eth0 -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o eth0 -j ACCEPT

EOF

# ==================================================
# ISLANDS
# ==================================================

IRANGESCOUNT=$((${#IRANGES[@]}))

for (( i=0 ; i<$IRANGESCOUNT ; i++ )); do

	PEER_INDEX=$(printf "%03d" $(($i + 1)))
	PEER_PRIVATEKEY=$(wg genkey)
	PEER_PUBLICKEY=$(echo $PEER_PRIVATEKEY | wg pubkey)
	PEER_PRESHAREDKEY=$(wg genpsk)

echo "Append WireGuard server configuration (ISLAND #$PEER_INDEX) ..." && sudo tee -a $SERVER_PATH/wg0.conf <<EOF

[Peer]
PublicKey = $PEER_PUBLICKEY
PresharedKey = $PEER_PRESHAREDKEY
AllowedIPs = $VRANGE, ${IRANGES[i]}
PersistentKeepalive = 20

EOF

echo "Creating WireGuard peer configuration (ISLAND #$PEER_INDEX) ..." && sudo tee $SERVER_PATH/island-$PEER_INDEX.conf <<EOF

[Interface]
Address = ${VRANGEIPS[(i+2)]}/32
PrivateKey = $PEER_PRIVATEKEY

[Peer]
PublicKey = $SERVER_PUBLICKEY
PresharedKey = $PEER_PRESHAREDKEY
Endpoint = $SERVER_HOST:$SERVER_PORT
AllowedIPs = $HRANGE, $VRANGE
PersistentKeepalive = 20

EOF

done

# ==================================================
# CONFIGURE SERVICE
# ==================================================

# enable and start WireGuard service
sudo systemctl enable wg-quick@wg0.service
sudo systemctl daemon-reload
sudo systemctl start wg-quick@wg0.service