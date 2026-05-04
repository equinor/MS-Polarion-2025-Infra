# Polarion Infrastructure as Code

[![SCM Compliance](https://scm-compliance-api.radix.equinor.com/repos/Equinor/105ab78a-3463-4ed5-b77b-9105396e7895/badge)](https://developer.equinor.com/governance/scm-policy/)

Infrastructure repository for the MS Polarion 2025 Azure platform.

## What Is Deployed

The deployment is orchestrated by [Bicep/main.bicep](Bicep/main.bicep) and provisions:

- 1 main resource group: S499-MS-POLARION-2025-<ENV>
- 1 Recovery Services Vault resource group: S499-MS-POLARION-2025-<ENV>-RSV
- 1 Key Vault with private endpoint and RBAC role assignments
- 1 Log Analytics Workspace
- 1 Storage Account
- 1 Network Security Group for workload resources
- 1 Recovery Services Vault with private endpoint, backup policies, and protected item mapping
- 1 empty Network Security Group in the Recovery Services Vault resource group

Note: the VM module exists in [Bicep/modules/main-deployment.bicep](Bicep/modules/main-deployment.bicep), but the module invocation is currently commented out in [Bicep/main.bicep](Bicep/main.bicep).

## Current Runtime Configuration

Based on [Bicep/modules/main-deployment.bicep](Bicep/modules/main-deployment.bicep):

- VM count: 4
- VM size: `Standard_D4s_v5`
- OS image: `MicrosoftWindowsServer/WindowsServer/2025-datacenter-g2/latest`
- OS disk default: 512 GB, `Premium_LRS`
- VM name pattern: <VM_NAME_BASE><NN><EnvSuffix>
- Default VM name base: S499POLWS
- Example DEV VM names:
  - S499POLWS01Dev
  - S499POLWS02Dev
  - S499POLWS03Dev
  - S499POLWS04Dev

## Environment Status

- Supported by template parameter validation: DEV, TEST, QA, PROD, TST, PRD, DEMO (plus lowercase variants)
- Parameter files currently present in repository:
  - [Bicep/Environments/DEV/1.main.json](Bicep/Environments/DEV/1.main.json)
  - [Bicep/Environments/QA/1.main.json](Bicep/Environments/QA/1.main.json)

## Required Input Parameters

See [Bicep/main.bicep](Bicep/main.bicep). Key inputs include:

- `resourceGroupName`
- `rgLocation`
- `solution`
- `environment`
- `keyVaultName`
- `keyVaultAccessObject`
- `networkAccessPolicies`
- `subnetConfig` (`compute`, `privateEndpoints`, `recoveryServicesVault`)
- `storageAccountName`
- `skuName`
- `runner`
- `vmConfigurations` (used for VM IP extraction and backup protected item mapping)
- `vmNameBase` (used for VM naming and backup protected item naming)
- `tags`

## Secret Requirements For VM Deployment

VM local admin passwords are read from Key Vault during deployment.

Secret name format is:

- <vmNameBase><NN><UPPERCASE_ENV>-localadmin-password

For DEV defaults, expected secret names are:

- S499POLWS01DEV-localadmin-password
- S499POLWS02DEV-localadmin-password
- S499POLWS03DEV-localadmin-password
- S499POLWS04DEV-localadmin-password

If these secrets are missing, VM deployment will fail.

## Network Security Groups

The workload NSG is created by [Bicep/modules/dependencies.bicep](Bicep/modules/dependencies.bicep) and includes:

- Allow TCP 88 and 389 from Any to Any (single combined LDAP/Kerberos rule)
- Allow TCP 443, 6516, and 5433 from VirtualNetwork to VirtualNetwork
- Optional RDP controls on TCP 3389 for configured VM private IPs:
  - Allow from VirtualNetwork to configured VM private IPs
  - Deny from Any to configured VM private IPs

An additional empty NSG is deployed in the Recovery Services Vault resource group for future customization.

## Recovery Services Vault Configuration

The Recovery Services Vault in [Bicep/modules/dependencies.bicep](Bicep/modules/dependencies.bicep) includes:

- Backup policies loaded from [Bicep/CommonFiles/backupPolicies.json](Bicep/CommonFiles/backupPolicies.json)
- Private endpoint deployment on subnetConfig.recoveryServicesVault
- Protected item mapping to VMPolicyEnhanced for VM backup items passed from [Bicep/main.bicep](Bicep/main.bicep)

Important: protected item association assumes the referenced virtual machines exist at protection time.

## Deployment

The CI/CD workflow runs a subscription-level deployment with:

- Template: [Bicep/main.bicep](Bicep/main.bicep)
- Parameter file: [Bicep/Environments/DEV/1.main.json](Bicep/Environments/DEV/1.main.json)

Equivalent command pattern used in workflow ([.github/workflows/reusable-Management-Systems-Classic.yml](.github/workflows/reusable-Management-Systems-Classic.yml)):

```powershell
New-AzSubscriptionDeployment \
  -TemplateFile .\Bicep\main.bicep \
  -TemplateParameterFile .\Bicep\Environments\DEV\1.main.json \
  -resourceGroupName "MS-Polarion-2025" \
  -location "NorwayEast" \
  -rgLocation "NorwayEast" \
  -solution "MS-Polarion-2025" \
  -environment "DEV" \
  -runner "<public-runner-ip>"
```

### Bootstrap And Harden Key Vault Access

For first-time deployment where secrets must be seeded from pipeline:

- Bootstrap run: set `includeRunnerAccess=true` and pass `initialKeyVaultSecrets`.
- Harden run: set `includeRunnerAccess=false` after secrets are created.

This keeps temporary runner access only for bootstrap and removes it in the final state.

## Network And Subnets

Subnet planning and examples are documented in [docs/subnet.md](docs/subnet.md).

The environment parameter file must provide subnet resource IDs through `subnetConfig`:

- `compute`
- `privateEndpoints`
- `recoveryServicesVault`

## Repository Structure

- [Bicep/main.bicep](Bicep/main.bicep): Top-level orchestration
- [Bicep/modules/dependencies.bicep](Bicep/modules/dependencies.bicep): Shared dependencies (KV, LAW, Storage, RSV)
- [Bicep/modules/main-deployment.bicep](Bicep/modules/main-deployment.bicep): VM deployment
- [Bicep/Environments/DEV/1.main.json](Bicep/Environments/DEV/1.main.json): DEV parameters
- [Bicep/Environments/QA/1.main.json](Bicep/Environments/QA/1.main.json): QA parameters
- [docs/setup.md](docs/setup.md): Initial setup notes
- [Manual/GeneratePassword.ps1](Manual/GeneratePassword.ps1): Local password generation helper
- [Manual/CreateSubnets.ps1](Manual/CreateSubnets.ps1): Subnet plan helper

## Diagram

![Polarion](./docs/assets/Polarion.svg)

## Security

Please report vulnerabilities as described in [Security.md](Security.md).
