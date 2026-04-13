We will split the subnet into 4 blocks
dev, qa, prod and a shared for other resources

Inside each environment’s /26

RSV Private Endpoint subnet: /27 (32 total, 27 usable) → meets Microsoft’s recommended size
App Private Endpoints subnet (Storage, Key Vault, etc.): /28 (16 total, 11 usable)
Compute subnet (3 VMs): /28 (16 total, 11 usable)

vnet-dev: 10.83.157.0/26
vnet-qa: 10.83.157.64/26
vnet-prod: 10.83.157.128/26
reserved/shared: 10.83.157.192/26

Subnets inside each environment

dev (10.83.157.0/26)

snet-pe-rsv-dev: 10.83.157.0/27
snet-pe-app-dev (Storage, Key Vault, etc.): 10.83.157.32/28
snet-compute-dev (3 VMs): 10.83.157.48/28
qa (10.83.157.64/26)

snet-pe-rsv-qa: 10.83.157.64/27
snet-pe-app-qa: 10.83.157.96/28
snet-compute-qa: 10.83.157.112/28
prod (10.83.157.128/26)

snet-pe-rsv-prod: 10.83.157.128/27
snet-pe-app-prod: 10.83.157.160/28
snet-compute-prod: 10.83.157.176/28
reserved/shared (10.83.157.192/26)

Keep for future services or expansion, e.g., Azure Bastion (requires AzureBastionSubnet /26), Azure Firewall (/26+), Application Gateway (/27+), or to upsize an environment’s PEs later.
