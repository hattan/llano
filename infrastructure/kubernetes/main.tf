
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.22.0"
}

resource "azurerm_resource_group" "llano-rg" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.resource_group_name}acr"
  resource_group_name = "${azurerm_resource_group.llano-rg.name}"
  location            = "${azurerm_resource_group.llano-rg.location}"
  admin_enabled       = true
  sku                 = "Basic"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name       = "${var.resource_group_name}-aks"
  location   = "${var.resource_group_location}"
  dns_prefix = "llano-un"

  resource_group_name = "${azurerm_resource_group.llano-rg.name}"
  kubernetes_version  = "1.12.5"

  linux_profile {
    admin_username = "${var.linux_admin_username}"

    ssh_key {
      key_data = "${var.linux_admin_ssh_publickey}"
    }
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }

  agent_pool_profile {
    name    = "agentpool"
    count   = "2"
    vm_size = "Standard_DS2_v2"
    os_type = "Linux"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }
}

resource "azurerm_storage_account" "site-storage" {
  name                     = "${var.resource_group_name}sitestorage"
  resource_group_name      = "${azurerm_resource_group.llano-rg.name}"
  location                 = "${azurerm_resource_group.llano-rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Does not work
#resource "azurerm_role_assignment" "acr-assignment" {
#  scope                = "${azurerm_container_registry.acr.id}"
#  role_definition_name = "AcrPull"
#  principal_id         = "${var.client_id}"
#}
