#!/bin/bash

echo '====================================================================================================================='
echo `$(basename "$0") $@`
echo '====================================================================================================================='

FORWARDS=()
BLOCKS=()
MASQUERADES=()

while getopts 'f:b:m:' OPT; do
    case "$OPT" in
		f)
			FORWARDS+=("${OPTARG}") ;;
		b)
			BLOCKS+=("${OPTARG}") ;;
		m)
			MASQUERADES+=("${OPTARG}") ;;
    esac
done

# auto confirm iptables-persistent prompts
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

# install required packages
sudo apt-get install -y iptables iptables-persistent

# enable IP forwarding
sudo sed -i -e 's/#net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sed -i -e 's/#net.ipv6.conf.all.forwarding.*/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sudo sysctl -p

# accept forwarding for established and related packages
sudo iptables -A FORWARD -i eth0 -o eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# DENY forwarding
for BLOCK in "${BLOCKS[@]}"; do
	sudo iptables -A FORWARD -i eth0 -s $BLOCK -m state --state NEW -j REJECT
done

if [ ${#FORWARDS[@]} -eq 0 ] && [ ${#MASQUERADES[@]} -eq 0 ]; then 

	sudo iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT

else 

	# ACCEPT simple forwarding
	for FORWARD in "${FORWARDS[@]}"; do
		sudo iptables -A FORWARD -i eth0 -o eth0 -s $FORWARD -j ACCEPT
	done

	# ACCEPT forwarding with masquerade
	for MASQUERADE in "${MASQUERADES[@]}"; do
		sudo iptables -A FORWARD -i eth0 -o eth0 -s $MASQUERADE -j ACCEPT
		sudo iptables -t nat -A POSTROUTING -s $MASQUERADE -o eth0 -j MASQUERADE
	done

fi

sudo iptables-save > /etc/iptables/rules.v4