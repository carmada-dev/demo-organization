# SUBNET='10.0.0.0/24'
# REQUIRED_SUBNETS=3

NETWORK=`echo $SUBNET | cut -d / -f1`;
MASK_BITS=`echo $SUBNET | cut -d / -f 2`;

MAX_SUBNETS=$((32-MASK_BITS));
TOTAL_HOSTS=$((2**MAX_SUBNETS));

if [ $TOTAL_HOSTS -lt 12 ]; then
  echo "Required subnets should be at least 12"
  exit
fi 

if [ $REQUIRED_SUBNETS -gt $TOTAL_HOSTS ]; then
  echo "Required subnets should be less than the available hosts"
  exit
fi  

round() {
  printf "%.${2}f" "${1}"
}

HOSTS_ARRAY=();
HOSTS_ARRAY+=("$((TOTAL_HOSTS))");
COUNT=${#HOSTS_ARRAY[@]};


while [ $COUNT -le $REQUIRED_SUBNETS ]; do
	temp=${HOSTS_ARRAY[0]}; 
	HOSTS_ARRAY=("${HOSTS_ARRAY[@]:1}")  
	HOSTS_ARRAY+=("$((temp/2))");
	HOSTS_ARRAY+=("$((temp/2))");  
	COUNT=$((${#HOSTS_ARRAY[@]}+1));
done

SUBNETS=()

for hosts in "${HOSTS_ARRAY[@]}"; do

	AVL_HOSTS=$((hosts-3));

	#SUBNET
	SUBNET_MASK_BITS=$(round $(echo "scale=10; l($hosts)/l(2)" | bc -l) 0);
	SUBNET_MASK_BITS=$((32-SUBNET_MASK_BITS));
	SUBNETS+=( $NETWORK/$SUBNET_MASK_BITS );

	#NETWORK
	NETWORK_LAST_OCTET=`echo $NETWORK | cut -d . -f 4`
	NETWORK=`echo $NETWORK | cut -d"." -f1-3`;
	NETWORK="$NETWORK.$(($NETWORK_LAST_OCTET+$hosts))";

done

SUBNETSJSON=$(printf '%s\n' "${SUBNETS[@]}" | jq -R . | jq -s .)

jq -c --null-input \
	--argjson subnets "$SUBNETSJSON" \
	'{ subnets: $subnets }' > $AZ_SCRIPTS_OUTPUT_PATH