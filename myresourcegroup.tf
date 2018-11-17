resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "westus"

    tags {
        environment = "Terraform Demo"
    }
}
