# Polarion Infrastructure as code

[![SCM Compliance](https://scm-compliance-api.radix.equinor.com/repos/Equinor/105ab78a-3463-4ed5-b77b-9105396e7895/badge)](https://developer.equinor.com/governance/scm-policy/)

Polarion installation from procedure
<https://statoilsrm.sharepoint.com/sites/MSTechnicalteam/_layouts/15/Doc.aspx?sourcedoc={81f68d5a-4870-40f8-81c8-00bcc4281075}&action=edit&wd=target%2804%20-%20Polarion%2FInstallation.one%7Cd4ff7f38-29b6-4898-a558-5c9ca52e48aa%2F%29&wdorigin=717>

This deploys 4 Virtual Machines with Windows Server 2019 // Will change this to describe better the 2025 solution once we get started.

Option to deploy 3 environments DEV, QA and PROD

## Infrastructure Diagram Polarion 2022 R2 and to be Polarion 2023

![Polarion](./docs/assets/Polarion.svg)

## After installation of VM, pre applications are installed in order

- .Net 6 Framework
- VC Redistributable-x64
- OpenSSL-3.1.3-x64
- OJDK11 - Default
- OJDK17 - Ready for use when upgrading to Docmap 2023
- Vscode-x64 System Installer
- AzureStorageExplorer System Installer
- AzCopy
- Creating SecurityGroups for Admin (a_key access) Admin_S499PLWSXX-DEV/QA/PROD
- Adding the SecurityGroups to the Virtual Machines for Administrators group for the S499PLWSXX-DEV/QA/PROD vms

- AccessIT groups for Admin is ordered by AccessIT and adding them to the Admin_S499PLWSXX-DEV/QA/PROD ordered manually - not yet coded for automation work in progress.

## Specs are set by recommended requirements for Polarion

- VM 1:
  - Standard_D8s_v5
  - diskSizeGB: 4096
  - OS: Windows Server 2019
  - managedDisk: Premium_LRS
  - AAD
- VM 2:
  - Standard_D8s_v5
  - diskSizeGB: default
  - OS: Windows Server 2019
  - AAD
- VM 3:
  - Standard_D8s_v5
  - diskSizeGB: 1024
  - OS: Windows Server 2019
  - managedDisk: Premium_LRS
  - AAD
- VM 4:
  - Standard_D8s_v5
  - diskSizeGB: 1024
  - OS: Windows Server 2019
  - managedDisk: Premium_LRS
  - AAD
