$repository = "https://github.com/beazley/template-powerbi-reports.git"
$folder = "template-powerbi-reports"

Write-Host "---> Init"
if(Test-Path $folder) {
    Remove-Item $folder -Recurse -Force #-ErrorAction Ignore
    Write-Host "deleted existing template-powerbi-reports"
}

git clone $repository

Write-Host "---> Process"
Copy-Item ".\$folder\src\Dataflows\*.template.json" ".\..\src\Dataflows"


Write-Host "---> Cleanup"

#git clone $repository

#Remove-Item $folder -Recurse #-ErrorAction Ignore
