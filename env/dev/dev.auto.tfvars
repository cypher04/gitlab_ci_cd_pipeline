location = "East US"

resource_group_name = "cicd-resource-group"

subnet_prefixes = {
  web      = "10.0.1.0/24",
  app      = "10.0.2.0/24",
  database = "10.0.3.0/24",
}

vnet_address_space = ["10.0.0.0/16"]
