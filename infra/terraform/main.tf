resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}-tf-${var.unique_username}"
  location = var.location
}

resource "azurecaf_name" "acr" {
  name          = "accl"
  resource_type = "azurerm_container_registry"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

module "acr" {
  source              = "./modules/acr"
  name                = azurecaf_name.acr.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurecaf_name" "aks" {
  name          = "accl"
  resource_type = "azurerm_kubernetes_cluster"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

module "aks" {
  source                       = "./modules/aks"
  name                         = azurecaf_name.aks.result
  prefix                       = var.prefix
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  acr_id                       = module.acr.acr_id
  aks_aad_auth                 = var.aks_aad_auth
  aks_aad_admin_user_object_id = var.aks_aad_admin_user_object_id
}