#!/bin/bash

echo '====================================================================================================================='
echo `$(basename "$0") $@`
echo '====================================================================================================================='

export DEBCONF_NOWARNINGS=yes
export DEBIAN_FRONTEND=noninteractive

# patch needrestart config
[ -f '/etc/needrestart/needrestart.conf' ] \
	&& sed -i 's/#$nrconf{restart}.*/$nrconf{restart} = '"'"'l'"'"';/g' /etc/needrestart/needrestart.conf

# update and upgrade packages
sudo apt-get update -y && sudo apt-get upgrade -y 

# install commonly used packages
sudo apt-get install -y apt-utils apt-transport-https coreutils jq

# install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# dump VM metadata
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq > ./metadata.json

# configure Azure CLI defaults
az config set \
	defaults.location=$(jq -r .compute.location ./metadata.json) \
	defaults.group=$(jq -r .compute.resourceGroupName ./metadata.json)

# login and set subscription context
az login --identity --allow-no-subscriptions