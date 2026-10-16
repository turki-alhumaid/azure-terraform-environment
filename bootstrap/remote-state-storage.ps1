$RG  = "rg-az-infra-tfstate"
$SA  = "stazinfratfstate2424"
$LOC = "indiasouthcentral"
$TAG_ENV        = "shared"
$TAG_MANAGED_BY = "bootstrap-script"

az group create --name $RG --location $LOC --tags environment=$TAG_ENV managed_by=$TAG_MANAGED_BY

az storage account create --name $SA --resource-group $RG --location $LOC `
  --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false

az storage account blob-service-properties update --account-name $SA `
  --resource-group $RG --enable-versioning true

az storage container create --name tfstate --account-name $SA

