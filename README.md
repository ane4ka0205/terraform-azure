# Azure-Terraform
Install Azure CLI with yum
For Linux distributions with yum such as RHEL, Fedora, or CentOS, there's a package for the Azure CLI. This package has been tested with RHEL 7, Fedora 19 and higher, and CentOS 7.


Note
To install the CLI, you need the following software:
•	Python 2.7x or Python 3.x
•	OpenSSL 1.0.2

Install

1.	Import the Microsoft repository key.

rpm --import https://packages.microsoft.com/keys/microsoft.asc

2.	Create local azure-cli repository information.

sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

3.	Install with the yum install command.

sudo yum install azure-cli

You can then run the Azure CLI with the az command. To sign in, use az login command.
1.	Run the login command.
az login

If the CLI can open your default browser, it will do so and load a sign-in page.
Otherwise, you need to open a browser page and follow the instructions on the command line to enter an authorization code after navigating to https://aka.ms/devicelogin in your browser.


2.	Sign in with your account credentials in the browser.
To learn more about different authentication methods, see Sign in with Azure CLI.

Update
Update the Azure CLI with the yum update command.
bashCopy
sudo yum update azure-cli





The following section creates a resource group named myResourceGroup in the eastus location:

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags {
        environment = "Terraform Demo"
    }
}
In additional sections, you reference the resource group with ${azurerm_resource_group.myterraformgroup.name}.







Create virtual network
The following section creates a virtual network named myVnet in the 10.0.0.0/16 address space:

resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "Terraform Demo"
    }
}
The following section creates a subnet named mySubnet in the myVnet virtual network:

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}





Create public IP address
To access resources across the Internet, create and assign a public IP address to your VM. The following section creates a public IP address named myPublicIP:

resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Terraform Demo"
    }
}


Create Network Security Group
Network Security Groups control the flow of network traffic in and out of your VM. The following section creates a network security group named myNetworkSecurityGroup and defines a rule to allow SSH traffic on TCP port 22:

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}




Create virtual network interface card
A virtual network interface card (NIC) connects your VM to a given virtual network, public IP address, and network security group. The following section in a Terraform template creates a virtual NIC named myNIC connected to the virtual networking resources you have created:

resource "azurerm_network_interface" "myterraformnic" {
    name                = "myNIC"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}



Create storage account for diagnostics
To store boot diagnostics for a VM, you need a storage account. These boot diagnostics can help you troubleshoot problems and monitor the status of your VM. The storage account you create is only to store the boot diagnostics data. As each storage account must have a unique name, the following section generates some random text:

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }

    byte_length = 8
}






Now you can create a storage account. The following section creates a storage account, with the name based on the random text generated in the preceding step:

resource "azurerm_storage_account" "mystorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    location            = "eastus"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags {
        environment = "Terraform Demo"
    }
}



Create virtual machine
The final step is to create a VM and use all the resources created. The following section creates a VM named myVMand attaches the virtual NIC named myNIC. The latest Ubuntu 16.04-LTS image is used, and a user named azureuser is created with password authentication disabled.
SSH key data is provided in the ssh_keys section. Provide a valid public SSH key in the key_data field.

resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3Nz{snip}hwhqT9h"
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Terraform Demo"
    }
}



