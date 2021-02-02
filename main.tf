provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.34.0"

  subscription_id = "77fa3f66-1a1a-4556-a4ef-3696d323e4d2"
  client_id       = "9fad165b-deeb-4d83-96c4-40b5cc572c09"
  client_secret   = "${var.client_secret}"
  tenant_id       = "513294a0-3e20-41b2-a970-6d30bf1546fa"
}

# Create a resource group
resource "azurerm_resource_group" "test" {
  name     = "terraform-rg"
  location = "West US"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "test" {
  name                = "terraform-vnet"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location            = "${azurerm_resource_group.test.location}"
  address_space       = ["10.2.0.0/16"]
}

# Create a subnet within terraform-vnet1
resource "azurerm_subnet" "test" {
  name		       = "terraformsubnet"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "terraform-vnet"
  address_prefix       = "10.2.1.0/24" 
  service_endpoints    = ["Microsoft.Storage"]  
}

# Associate subnet with nsg
resource "azurerm_subnet_network_security_group_association" "test"{
  subnet_id = "${azurerm_subnet.test.id}"
  network_security_group_id = "${azurerm_network_security_group.test.id}" 
}

# Create network interface with dynamic public ip
resource "azurerm_network_interface" "test"{
  name                = "test-nic-terraform"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  network_security_group_id = "${azurerm_network_security_group.test.id}"
 
  ip_configuration{
    name = "test-ip-terraform"
    subnet_id = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.test1.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.test.id}"]
 }

}

# Create network interface with static public ip
resource "azurerm_network_interface" "test1"{
  name                = "test-nic-terraform1"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  network_security_group_id = "${azurerm_network_security_group.test.id}"

  ip_configuration{
    name = "test-ip-terraform1"
    subnet_id = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.test.id}"   
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.test.id}"] 
  }

}

# Create Static public ip
resource "azurerm_public_ip" "test" {
  name                = "terraformpublicip1"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  allocation_method   = "Static"
}

# Create Static public ip
resource "azurerm_public_ip" "test2" {
  name                = "terraformpublicip2"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  allocation_method   = "Static"
}


# Create Dynamic public ip
resource "azurerm_public_ip" "test1" {
  name                = "terraformpublicip"
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  allocation_method   = "Dynamic"
}

# Create VM1
resource "azurerm_virtual_machine" "test"{
  name = "test-vm-terraform"
  location = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size = "Standard_A0"
  availability_set_id = "${azurerm_availability_set.test.id}"

  storage_image_reference{
  publisher = "RedHat"
  offer = "RHEL"
  sku = "7-RAW"
  version = "latest" 
  }
  
  storage_os_disk {
    name              = "disk1-terraform"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "terraform"
    admin_username = "kushal"
    admin_password = "Welcome@123456"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
 
}

# Create VM2
resource "azurerm_virtual_machine" "test1"{
  name = "test-vm-terraform1"
  location = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test1.id}"]
  vm_size = "Standard_A0"
  availability_set_id = "${azurerm_availability_set.test.id}"

  storage_image_reference{
  publisher = "RedHat"
  offer = "RHEL"
  sku = "7-RAW"
  version = "latest"
  }

  storage_os_disk {
    name              = "disk2-terraform"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "terraform"
    admin_username = "kushal"
    admin_password = "Welcome@123456"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

# Create NSG
resource "azurerm_network_security_group" "test"{
  name = "test-nsg-terraform"
  location = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  security_rule{
      name = "Port_22"
      direction = "Inbound"
      priority = "340"
      access = "Allow"
      protocol = "Tcp"
      source_address_prefix = "*"
      source_port_range = "*"
      destination_address_prefix = "*"
      destination_port_range = "22" 
    }
  security_rule{
      name = "Port_80"
      direction = "Inbound"
      priority = "350"
      access = "Allow"
      protocol = "Tcp"
      source_address_prefix = "*"
      source_port_range = "*"
      destination_address_prefix = "*"
      destination_port_range = "80"
    }
}

# Create AV Set
resource "azurerm_availability_set" "test" {
  name = "terraform-av-set"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location = "${azurerm_resource_group.test.location}"
  managed = true
}

# Create LB
resource "azurerm_lb" "test" {
  name = "terraform-lb"
  location = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  
  frontend_ip_configuration {
    name = "terraform-frontend-ip-config"
    public_ip_address_id = "${azurerm_public_ip.test2.id}"
  }
}

# Create LB backend address pool
resource "azurerm_lb_backend_address_pool" "test" {
  name = "terraform-backend-pool"
  resource_group_name = "${azurerm_resource_group.test.name}"
  loadbalancer_id = "${azurerm_lb.test.id}"
}

# Create LB Probe
resource "azurerm_lb_probe" "test" {
  name = "terraform-lb-probe"
  resource_group_name = "${azurerm_resource_group.test.name}"
  loadbalancer_id = "${azurerm_lb.test.id}"
  protocol = "Tcp"
  port = "80"
  interval_in_seconds = "5"
  number_of_probes = "2"
}

# Create LB rule
resource "azurerm_lb_rule" "test" {
  name = "terraform-lb-rule"
  resource_group_name = "${azurerm_resource_group.test.name}"
  loadbalancer_id = "${azurerm_lb.test.id}"
  frontend_ip_configuration_name = "${azurerm_lb.test.frontend_ip_configuration[0].name}"
  protocol = "Tcp"
  frontend_port = "80"
  backend_port = "80"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.test.id}"
  probe_id = "${azurerm_lb_probe.test.id}"
}

# Create Storage account
resource "azurerm_storage_account" "test" {
  name = "terraformsa26"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location = "${azurerm_resource_group.test.location}"
  account_replication_type = "LRS"
  account_tier = "Standard"
  account_kind = "StorageV2"

  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = ["${azurerm_subnet.test.id}"]
  }
}

# Create Storage Container
resource "azurerm_storage_container" "test" {
  name = "vhds"
  resource_group_name = "${azurerm_resource_group.test.name}"
  storage_account_name = "${azurerm_storage_account.test.name}"
  container_access_type = "private"
} 

