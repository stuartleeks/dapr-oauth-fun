#!/bin/bash
set -e


#
# This script generates the bicep parameters file and then uses that to deploy the infrastructure
# An output.json file is generated in the project root containing the outputs from the deployment
# The output.json format is consistent between Terraform and Bicep deployments
#

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

help()
{
    echo ""
      echo "<This command will deploy the infrastructure for this project using Bicep>"
      echo ""
      echo "Command"
      echo "    deploy-infra.sh : Will deploy all required services services."
      echo ""
      echo "Arguments"
      echo "    --username, -u      : Unique name to assign in all deployed services, your high school hotmail alias is a great idea!"
      echo "    --location, -l      : Azure region to deploy to"
      echo ""
      exit 1
}

SHORT=u:,l:,h
LONG=username:,location:,help
OPTS=$(getopt -a -n files --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

USERNAME=''
LOCATION=''
while :
do
  case "$1" in
    -u | --username )
      USERNAME="$2"
      shift 2
      ;;
    -l | --location )
      LOCATION="$2"
      shift 2
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      ;;
  esac
done

if [[ -f "$script_dir/../.env" ]]; then
	source "$script_dir/../.env"
fi

if [[ ${#USERNAME} -eq 0 ]]; then
  echo 'ERROR: Missing required parameter --username | -u' 1>&2
  exit 6
fi

if [[ ${#LOCATION} -eq 0 ]]; then
  echo 'ERROR: Missing required parameter --location | -l' 1>&2
  exit 6
fi



cat << EOF > "$script_dir/../infra/azuredeploy.parameters.json"
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "value": "${LOCATION}"
    },
    "uniqueUserName": {
      "value": "${USERNAME}"
    }
  }
}
EOF

deployment_name="deployment-${USERNAME}-${LOCATION}"
cd infra/bicep
echo "Starting Bicep deployment ($deployment_name)"
az deployment sub create \
  --location "$LOCATION" \
  --template-file main.bicep \
  --name "$deployment_name" \
  --parameters azuredeploy.parameters.json \
  --output json \
  | jq "[.properties.outputs | to_entries | .[] | {key:.key, value: .value.value}] | from_entries" > "$script_dir/../infra/output.json"


extension_installed=$(az extension list --query "length([?contains(name, 'k8s-extension')])")
if [[ $extension_installed -eq 0 ]]; then
  echo "Installing k8s-extension extension for az CLI"
  az extension add --name k8s-extension
fi

provider_state=$(az provider list --query "[?contains(namespace,'Microsoft.KubernetesConfiguration')] | [0].registrationState" -o tsv)
if [[ $provider_state != "Registered" ]]; then
  echo "Registering Microsoft.KubernetesConfiguration provider"
  az provider register --namespace Microsoft.KubernetesConfiguration
fi

RESOURCE_GROUP=$(jq -r '.rg_name' < "$script_dir/../infra/output.json")
if [[ ${#RESOURCE_GROUP} -eq 0 ]]; then
  echo 'ERROR: Missing output value rg_name' 1>&2
  exit 6
fi

AKS_NAME=$(jq -r '.aks_name' < "$script_dir/../infra/output.json")
if [[ ${#AKS_NAME} -eq 0 ]]; then
  echo 'ERROR: Missing output value aks_name' 1>&2
  exit 6
fi

echo "Getting AKS credentials"
# Get kubeconfig for the AKS cluster
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --overwrite-existing
# Update the kubeconfig to use  https://github.com/azure/kubelogin
kubelogin convert-kubeconfig -l azurecli


## TODO - can this be configured in the bicep template?
echo "Configuring Dapr extension"
az k8s-extension create --cluster-type managedClusters \
--cluster-name "$AKS_NAME" \
--resource-group "$RESOURCE_GROUP" \
--name dapr \
--extension-type Microsoft.Dapr
