# 1. Grupo de Recursos
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# 2. VNet HUB
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.hub_cidr
}

resource "azurerm_subnet" "hub_subnet" {
  name                 = "subnet-core"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [cidrsubnet(var.hub_cidr[0], 8, 1)] # Usa funciones de Terraform para calcular la subred (10.0.1.0/24)
}

# 3. VNet SPOKE
resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "vnet-spoke-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.spoke_cidr
}

resource "azurerm_subnet" "spoke_subnet" {
  name                 = "subnet-prod-apps"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = [cidrsubnet(var.spoke_cidr[0], 8, 1)] # Calcula automáticamente (192.168.1.0/24)
}

# 4. Peerings (Conexiones bilaterales)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peering-hub-to-spoke"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name  # <- Corregido aquí
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peering-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}
# 5. Crear el Network Security Group (NSG) para Producción
resource "azurerm_network_security_group" "spoke_nsg" {
  name                = "nsg-spoke-prod"
  location            = var.location
  resource_group_name = var.rg_name

  # Regla 1: Permitir tráfico HTTP (Puerto 80)
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Regla 2: Permitir tráfico HTTPS (Puerto 443)
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 6. Asociar el NSG a la subred del SPOKE
resource "azurerm_subnet_network_security_group_association" "spoke_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke_nsg.id
}
