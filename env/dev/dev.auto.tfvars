location = "East US"

resource_group_name = "cicd-resource-group"

subnet_prefixes = {
  web      = "10.0.1.0/24",
  app      = "10.0.2.0/24",
  database = "10.0.3.0/24",
}

vnet_address_space = ["10.0.0.0/16"]


admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD6hlLBDd9AUXS9cQr+FfZy+MERLwCi5cn2MLWbyECKggqZtughLx/GZ6p9JpHnGkR8/3hCud1MgthQOYT/xVe6U6N4c/l5RRRM2Pr3EPXPMJ4JvLzXCIkBN91J4DCITkN+16lSKysZ08XqWANjPGEidWQJR8emt6zqJGMB99upanZ0AMmQs0/Tv8s48TEfE8P2Nug4kZKVIxIMbVDIiaprHA/2QT+K3ZYcf/THeS8EvrqQVfo54eKKzWTzY/LtCkB65RppdnLqkKm5JkmNTVL4Nldxv3X0YmjA5r7d71WSkaTeaHYOzD15SLgJeHF3bwss6h7R64heuOjRR2TmpxiEMaiD6sZG2rx68OMeKTdnQlQ2ou7CR1HEWnWftLX31hrX8BEqajZndKtybKPN7muDF17QAtUURmCwikS2kHjRZ98/8ty8pHXdANZBjJVVdFwvi3t8u0PpFrADb/YxvORHGxAD6fiJv432AcXxZi7D9gL8hlLiKKM5bS5y0GRvDaFij3pCYUSejnJouSNQCGgkYSvgZefxfyxxlOOdnlfabcBqDe51LOojskL1BwLZWP9d2u4qIj3zbFiMEJ01rv4aOVt8QO3nwGh6CfM6RXUavMISt6d5C7t3B52KUWmuYsMNNP5GyQNH1Dl3FCNVB721FnwFPTxiTvbNQ+wm03l9eQ== seyiabiodun@Mac.Home"
