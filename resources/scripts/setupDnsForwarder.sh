#!/bin/bash

echo '====================================================================================================================='
echo `$(basename "$0") $@`
echo '====================================================================================================================='

FORWARDS=()
FORWARDS_FULL=()
FORWARDS_ZONE=()
CLIENTS=()

while getopts 'n:f:c:' OPT; do
    case "$OPT" in
		f)
			FORWARDS+=("${OPTARG}") ;;
		c)
			CLIENTS+=("${OPTARG}") ;;
    esac
done

for FORWARD in "${FORWARDS[@]}"; do
	if [ -z "$(echo $FORWARD | grep '>')" ]; then
		echo "Identified general forwarder: $FORWARD"
		FORWARDS_FULL+=("$FORWARD") 
	else
		ZONE_NAME=$(echo "$FORWARD" | grep -o '.*>' | cut -d '>' -f1)
		ZONE_FORW=$(echo "$FORWARD" | grep -o '>.*' | cut -d '>' -f2)
		echo "Identified conditional forwarder: $ZONE_FORW ($ZONE_NAME)"
		FORWARDS_ZONE+=("zone \"$ZONE_NAME\" { type forward; forward only; forwarders { $ZONE_FORW; }; };")
	fi 
done

# install required packages
sudo apt-get install -y bind9

# ensure bind cache folder exists
sudo mkdir -p /var/cache/bind

CLIENTS_VALUE="$(if [ ${#CLIENTS[@]} -eq 0 ]; then echo 'any;'; else printf "%s; " "${CLIENTS[@]}"; fi)"
FORWARDS_FULL_VALUE="$(if [ ${#FORWARDS_FULL[@]} -eq 0 ]; then echo ''; else printf "%s; " "${FORWARDS_FULL[@]}"; fi)"
FORWARDS_ZONE_VALUE="$(if [ ${#FORWARDS_ZONE[@]} -eq 0 ]; then echo ''; else printf "%s" "${FORWARDS_ZONE[@]}"; fi)"

# update bind configuration
echo "Updating BIND9 configuration ..." && sudo tee /etc/bind/named.conf.options <<EOF

acl goodclients {
    $CLIENTS_VALUE
    localhost;
    localnets;
};

$FORWARDS_ZONE_VALUE

options {
	directory "/var/cache/bind";
	recursion yes;
	allow-query { goodclients; };
	forwarders {
		$FORWARDS_FULL_VALUE
	};
	forward only;
	dnssec-validation no; 	# needed for private dns zones
	auth-nxdomain no;    	# conform to RFC1035
	listen-on { any; };
};

EOF

# check bind configruation
sudo named-checkconf /etc/bind/named.conf.options

# restart bind with new configuration
sudo service bind9 restart
