Write-Host "R2023-03-13: Migrate from TeamCity to GitHub"
$repository = "https://github.com/beazley/template-powerbi-reports.git"
$folder = "template-powerbi-reports"

Write-Host "---> Init"
if(Test-Path $folder) {
    Remove-Item $folder -Recurse -Force #-ErrorAction Ignore
    Write-Host "deleted existing template-powerbi-reports"
}

git clone $repository

Write-Host "---> Process"
Write-Host "Copy GHAs"
Copy-Item ".\$folder\.github\workflows\pbi-build-release.yml" ".\..\.github\workflows"
Copy-Item ".\$folder\.github\workflows\pbi-init.yml" ".\..\.github\workflows"
Copy-Item ".\$folder\GitVersion.yml" ".\.."
Copy-Item ".\$folder\.gitignore" ".\.."

Write-Host "---> Cleanup"

Write-Host "Disable TeamCity project by following the step-by-step tutorial:"
Write-Host "https://beazley.atlassian.net/wiki/spaces/PDG/pages/3807969463/R2023-03-13+Migrate+from+TC+to+GHA"
