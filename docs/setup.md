# Setup

## Prereq

1. Owner on subscription
2. Application Developer role
3. Git
4. GH Cli
5. Powershell 7
6. Powershell module Az >7

## Setup

```powershell
$projectName = "<YOUR PROJECT>"
$appname = "<YOUR APP REGRSTRATION NAME>"
$subscription = "<YOUR SUBSCRIPTION ID>"

$reponame = "equinor/$projectname"
gh repo create $reponame --private --template "equinor/sysops-templates" --clone 

Connect-AzAccount
$app = New-AzADServicePrincipal -displayname $appname
$appid = $app.appid
$secret = (new-AzADServicePrincipalCredential -ServicePrincipalObject $app).SecretText

gh secret set CLIENT_SECRET -b"${secret}"  --repo="${reponame}"
gh secret set CLIENT_ID -b"${appid}"  --repo="${reponame}"

New-AzRoleAssignment -principalid $app.id -Scope "/subscriptions/$subscription" -RoleDefinitionName "Omnia Contributor"
```
