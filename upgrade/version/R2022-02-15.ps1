$repository = "https://github.com/beazley/template-powerbi-reports.git"
$folder = "template-powerbi-reports"

Write-Host "---> Init"
if(Test-Path $folder) {
    Remove-Item $folder -Recurse -Force #-ErrorAction Ignore
    Write-Host "deleted existing template-powerbi-reports"
}

git clone $repository

Write-Host "---> Process"
Copy-Item ".\$folder\build.ps1" ".\.."


Write-Host "---> Cleanup"