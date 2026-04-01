# $organization = "TmJr75"
$organization = "Equinor"
$RepoName = "MS-Polarion-2025-Infra"

git init
git add .
git commit -m "new repo"


# https://cli.github.com/manual/gh_repo_create
gh repo create $organization/$RepoName --public --source=. --remote=upstream
# gh repo create $organization/$RepoName --internal --source=. --remote=upstream

# push changes
git remote -v
git push --set-upstream upstream master
