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
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDu4sUTo3TA2caMB3TVuM90f04/LKObgD7ml/hnMfxQbZQrvyA+uRw6oJlEphJazIw+obqqkC7oAvyjCrzlAlfsfmH/HxjQ51gB07spaYdohFSol3o8YTjrQdTwDSuf14OraCKdu+3ZQCVOXZfSsJ5RxQ8QUuDpeLGLu5m94qZ/V9DzGUoWRQdMByjVYGeMAVQ7Bt+QG6x/2kfS+3UAbfvZBm3SbvAhcWG1XvuKyFlW19DhOc3ldSM9a+IbSRo+h3ihbYNY0xOchw4xw8BUkyuS8Cf7t6mJWqEqB/RtUJRKHx53kWVP5ZfiwvYtg/hM8IpUOl4xr0AWSlf8DK6FzTO9 centos@centos-jenkins-1538605948565-s-1vcpu-2gb-nyc1-01"
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
