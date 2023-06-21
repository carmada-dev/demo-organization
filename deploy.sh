#!/bin/bash

# WORKAROUND BEGIN: https://github.com/Azure/azure-cli/issues/26272
AZURE_CORE_USE_COMMAND_INDEX=False
rm -f ~/.azure/commandIndex.json
# WORKAROUND END

RESET='false'

usage() { 
	echo "======================================================================================"
	echo "Usage: $0"
	echo "======================================================================================"
	echo " -o [REQUIRED] 	The organization (DevCenter) name"
	echo " -p [REQUIRED] 	The project name"
	echo " -d [FLAG] 		Dump the BICEP template in ARM format"
	echo " -r [FLAG] 		Reset the full demo environment"
	exit 1; 
}

displayHeader() {
	echo -e "\n======================================================================================"
	echo $1
	echo -e "======================================================================================\n"
}

cancelDeployments() {

	local SUBSCRIPTIONID="$1"

	# on subscription level
	# ------------------------------------------------------------------------------

	for DEPLOYMENTNAME  in $(az deployment sub list --subscription $SUBSCRIPTIONID --query '[?properties.provisioningState==`InProgress`].name' -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Canceling deployment '$DEPLOYMENTNAME' ..."
		az deployment sub cancel --subscription $SUBSCRIPTIONID --name $DEPLOYMENTNAME -o none &
	done; wait

	# on resource group level
	# ------------------------------------------------------------------------------

	for RESOURCEGROUP in $(az group list --subscription $SUBSCRIPTIONID --query '[].name' -o tsv | dos2unix); do
		for DEPLOYMENTNAME  in $(az deployment group list --subscription $SUBSCRIPTIONID --resource-group $RESOURCEGROUP --query '[?properties.provisioningState==`InProgress`].name' -o tsv | dos2unix); do
			echo "$SUBSCRIPTIONID - Canceling deployment '$DEPLOYMENTNAME' in resource group '$RESOURCEGROUP' ..."
			az deployment group cancel --subscription $SUBSCRIPTIONID --resource-group $RESOURCEGROUP --name $DEPLOYMENTNAME -o none &
		done
	done; wait
}

purgeResources() {

	local SUBSCRIPTIONID="$1"

	# purge resource scoped resources
	# ------------------------------------------------------------------------------

	for RESOURCEGROUP in $(az group list --subscription $SUBSCRIPTIONID --query '[].name' -o tsv | dos2unix); do
		for WORKSPACE in $(az monitor log-analytics workspace list-deleted-workspaces --subscription $SUBSCRIPTIONID --resource-group $RESOURCEGROUP --query [].name -o tsv | dos2unix); do
			echo "$SUBSCRIPTIONID - Purging log analytics workspace '$WORKSPACE' ..."
			az monitor log-analytics workspace delete --subscription $SUBSCRIPTIONID --resource-group $RESOURCEGROUP --name $WORKSPACE --force --yes -o none &
		done
	done 

	# purge subscription scoped resources
	# ------------------------------------------------------------------------------

	for KEYVAULT in $(az keyvault list-deleted --subscription $SUBSCRIPTIONID --resource-type vault --query "[?!(starts_with(name, 'pkrkv'))].name" -o tsv 2>/dev/null | dos2unix); do
		echo "$SUBSCRIPTIONID - Purging deleted key vault '$KEYVAULT' ..." 
		az keyvault purge --subscription $SUBSCRIPTIONID --name $KEYVAULT -o none & 
	done

	for APPCONFIG in $(az appconfig list-deleted --subscription $SUBSCRIPTIONID --query '[].name' -o tsv 2>/dev/null | dos2unix); do
		echo "$SUBSCRIPTIONID - Purging deleted app configuration '$APPCONFIG' ..." 
		az appconfig purge --subscription $SUBSCRIPTIONID --name $APPCONFIG --yes -o none &
	done

	wait # ... until all purge operations are done
}

cleanupRoleAssignmentsAndDefinitions() {

	local SUBSCRIPTIONID="$1"

	# delete role assignments and definitions
	# ------------------------------------------------------------------------------

	for ASSIGNMENTID in $(az role assignment list --subscription $SUBSCRIPTIONID --query "[?(principalType=='ServicePrincipal' && principalName=='')].id" -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting orphan role assignment $ASSIGNMENTID"
		az role assignment delete --subscription $SUBSCRIPTIONID --ids $ASSIGNMENTID --yes -o none &
	done; wait

	for DEFINITIONNAME in $(az role definition list --custom-role-only --scope /subscriptions/$SUBSCRIPTIONID --query [].name -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting custom role definition $DEFINITIONNAME"
		az role definition delete --name $DEFINITIONNAME --custom-role-only --scope /subscriptions/$SUBSCRIPTIONID -o none &
	done; wait

}

resetSubscription() {

	local SUBSCRIPTIONID="$1"

	cancelDeployments $SUBSCRIPTIONID

	# delete dev projects
	# ------------------------------------------------------------------------------

	for POOLID in $(az resource list --subscription $SUBSCRIPTIONID --resource-type 'Microsoft.DevCenter/projects/pools' --query [].id -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting devbox pool '$POOLID' ..." 
		az devcenter admin pool delete --ids $POOLID --yes --only-show-errors &
	done; wait 

	for PROJECTID in $(az resource list --subscription $SUBSCRIPTIONID --resource-type 'Microsoft.DevCenter/projects' --query [].id -o tsv | dos2unix); do
		PROJECTJSON=$(az devcenter admin project show --ids $PROJECTID)
		PROJECTNAME=$(echo $PROJECTJSON | jq -r .name)
		PROJECTRG=$(echo $PROJECTJSON | jq -r .resourceGroup)
	done; wait

	for PROJECTID in $(az resource list --subscription $SUBSCRIPTIONID --resource-type 'Microsoft.DevCenter/projects' --query [].id -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting dev project '$PROJECTID' ..." 
		az devcenter admin project delete --ids $PROJECTID --yes --only-show-errors &
	done; wait 

	# delete dev centers
	# ------------------------------------------------------------------------------

	for DEVBOXDEFINITIONID in $(az resource list --subscription $SUBSCRIPTIONID --resource-type 'Microsoft.DevCenter/devcenters/devboxdefinitions' --query [].id -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting devbox definition '$DEVBOXDEFINITIONID' ..." 
		az devcenter admin devbox-definition delete --ids $DEVBOXDEFINITIONID --yes --only-show-errors &
	done; wait 

	for DEVCENTERID in $(az resource list --subscription $SUBSCRIPTIONID --resource-type 'Microsoft.DevCenter/devcenters' --query [].id -o tsv | dos2unix); do
		
		DEVCENTERJSON=$(az devcenter admin devcenter show --ids $DEVCENTERID)
		DEVCENTERNAME=$(echo $DEVCENTERJSON | jq -r .name)
		DEVCENTERRG=$(echo $DEVCENTERJSON | jq -r .resourceGroup)
		
		for ATTACHEDNETWORKNAME in $(az devcenter admin attached-network list --subscription $SUBSCRIPTIONID --resource-group $DEVCENTERRG --dev-center-name $DEVCENTERNAME --query [].name -o tsv | dos2unix); do
			echo "$SUBSCRIPTIONID - Detaching network '$ATTACHEDNETWORKNAME' from dev center '$DEVCENTERID' ..." 
			az devcenter admin attached-network delete --subscription $SUBSCRIPTIONID --resource-group $DEVCENTERRG --dev-center-name $DEVCENTERNAME --name $ATTACHEDNETWORKNAME --yes --only-show-errors &
		done

	done; wait

	for DEVCENTERID in $(az resource list --subscription $SUBSCRIPTIONID --resource-type 'Microsoft.DevCenter/devcenters' --query [].id -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting dev center '$DEVCENTERID' ..." 
		az devcenter admin devcenter delete --ids $DEVCENTERID --yes --only-show-errors &
	done; wait 

	# delete resources
	# ------------------------------------------------------------------------------

	for RESOURCEGROUP in $(az group list --subscription $SUBSCRIPTIONID --query '[].name' -o tsv | dos2unix); do
		if [ $(az resource list --subscription $SUBSCRIPTIONID --resource-group $RESOURCEGROUP --query '[] | length(@)' -o tsv) -gt 0 ]; then
			echo "$SUBSCRIPTIONID - Deleting resources in '$RESOURCEGROUP' ..."
			az deployment group create --mode Complete --subscription $SUBSCRIPTIONID --resource-group $RESOURCEGROUP --name $"$(uuidgen)" --template-uri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/100-blank-template/azuredeploy.json -o none &
		fi
	done; wait

	# give the resource graph some time to update before purge
	sleep 60 && purgeResources $SUBSCRIPTIONID

	# delete resource groups and deployments
	# ------------------------------------------------------------------------------

	for RESOURCEGROUP in $(az group list --subscription $SUBSCRIPTIONID --query '[].name' -o tsv | dos2unix); do 
		echo "$SUBSCRIPTIONID - Deleting resource group '$RESOURCEGROUP' ..." 
		az group delete --subscription $SUBSCRIPTIONID --name $RESOURCEGROUP --yes -o none &
	done; wait

	for DEPLOYMENTNAME in $(az deployment sub list --subscription $SUBSCRIPTIONID --query [].name -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting deployment '$DEPLOYMENTNAME' ..." 
		az deployment sub delete --subscription $SUBSCRIPTIONID --name $DEPLOYMENTNAME -o none &
	done; wait
	
	# delete role assignments and definitions
	# ------------------------------------------------------------------------------

	for ASSIGNMENTID in $(az role assignment list --subscription $SUBSCRIPTIONID --query "[?(principalType=='ServicePrincipal' && principalName=='')].id" -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting orphan role assignment $ASSIGNMENTID"
		az role assignment delete --subscription $SUBSCRIPTIONID --ids $ASSIGNMENTID --yes -o none &
	done; wait

	for DEFINITIONNAME in $(az role definition list --custom-role-only --scope /subscriptions/$SUBSCRIPTIONID --query [].name -o tsv | dos2unix); do
		echo "$SUBSCRIPTIONID - Deleting custom role definition $DEFINITIONNAME"
		az role definition delete --name $DEFINITIONNAME --custom-role-only --scope /subscriptions/$SUBSCRIPTIONID -o none &
	done; wait

	echo "Finished reset of subscription $SUBSCRIPTIONID"
}



PROJECTS=()

while getopts 'o:p:r' OPT; do
    case "$OPT" in
		o)
			ORGANIZATION="${OPTARG}" ;;
		p)
			PROJECTS+=( "${OPTARG}" ) ;;
        r) 
			RESET='true' ;;
		*) 
			usage ;;
    esac
done

clear

[ -z "$ORGANIZATION" ] && usage

[ ! -f "$ORGANIZATION" ] \
	&& echo "Could not find organization definition file: $ORGANIZATION" \
	&& exit 1

displayHeader "Initialize context"
SUBSCRIPTION=$(cat $ORGANIZATION | jq -r .subscription)
az account set --subscription $SUBSCRIPTION -o none && echo "Selected subscription '$(az account show --query name -o tsv | dos2unix)' ($SUBSCRIPTION) as organization home!" 

if [ "$RESET" = 'true' ]; then
	displayHeader "Reset subscriptions"
	RESETSUBSCRIPTIONS=( "$SUBSCRIPTION" )
	for PROJECT in "${PROJECTS[@]}"; do
		for RESETSUBSCRIPTION in $(cat $PROJECT | jq -r '.. | .subscription? | select(. != null)'); do
			RESETSUBSCRIPTIONS+=( "$RESETSUBSCRIPTION" )		
		done
		for PROJECTID in $(az resource list --resource-type 'Microsoft.DevCenter/projects' --query '[].id' -o tsv | dos2unix); do
			for DEPLOYMENTTARGETID in $(az rest --method get --uri "https://management.azure.com$PROJECTID/environmentTypes?api-version=2022-09-01-preview" | jq -r '.. | .deploymentTargetId? | select(. != null)' | dos2unix); do
				[[ " ${RESETSUBSCRIPTIONS[@]} " =~ " ${DEPLOYMENTTARGETID##*/} " ]] || RESETSUBSCRIPTIONS+=( "${DEPLOYMENTTARGETID##*/}" )
			done
		done
	done
	for RESETSUBSCRIPTION in "${RESETSUBSCRIPTIONS[@]}"; do
		resetSubscription $RESETSUBSCRIPTION &		
	done; wait
	for RESETSUBSCRIPTION in "${RESETSUBSCRIPTIONS[@]}"; do
		cleanupRoleAssignmentsAndDefinitions $RESETSUBSCRIPTION &
	done; wait

	echo '... done'
fi

displayHeader "Merge projects"
PROJECTSFILE="$(dirname $ORGANIZATION)/projects.json"
echo "Target file: $PROJECTSFILE"
jq -s . "${PROJECTS[@]}" > $PROJECTSFILE

displayHeader "Resolve principals"
UPN=$(grep -Eom1 "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" $PROJECTSFILE)
while [ ! -z "$UPN" ]; do
	echo "Resolving UPN '$UPN' ..."
	OID=$(az ad user show --id $UPN --query id -o tsv | dos2unix)
	[ -z "$OID" ] && exit 1
	echo "Replacing UPN '$UPN' with OID '$OID'..."
	sed -i "s/$UPN/$OID/" $PROJECTSFILE
	UPN=$(grep -Eom1 "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" $PROJECTSFILE)
done
echo '... done'

displayHeader "Transpile template"
az bicep build --file ./resources/main.bicep --stdout > ./deploy.json
echo "Target file: ./deploy.json"

displayHeader "Run deployment"
az deployment sub create \
	--name $(uuidgen) \
	--location $(jq --raw-output .location $ORGANIZATION) \
	--template-file ./deploy.bicep \
	--only-show-errors \
	--parameters \
		OrganizationDefinition=@$ORGANIZATION \
		ProjectDefinitions=@$PROJECTSFILE \
		Windows365PrinicalId=$(az ad sp show --id 0af06dc6-e4b5-4f28-818e-e78e62d137a5 --query id -o tsv | dos2unix)
echo '... done'
