Param
	(
		[string]
		$Release
	) 

$releaseFolder = "version"

if(-not (Test-Path "upgrade")) {
    Write-Host "Create upgrade folder"
    New-Item -Name "upgrade" -ItemType "directory"
}

Set-Location "upgrade"

if($Release) {
    Write-Host "Running upgrade for $Release"
    $path = "$($releaseFolder)\$($Release).ps1"
    & $path
    return
} else {
    Write-Host "Running upgrade to latest version"
    $repository = "https://github.com/beazley/template-powerbi-reports.git"
    $folder = "template-powerbi-reports"

    Write-Host "---> Init"
    if(Test-Path $folder) {
        Remove-Item $folder -Recurse -Force #-ErrorAction Ignore
        Write-Host "deleted existing template-powerbi-reports"
    }

    git clone $repository

    if(Test-Path "$($folder)\upgrade") {
        $allFiles = Get-ChildItem "$($folder)\upgrade\$($releaseFolder)\*.ps1"
        foreach ($releaseFile in $allFiles) {
            $newRelease = "$($releaseFolder)\$($releaseFile.Name)"
            Write-Host "Checking for release $newRelease"
            if(Test-Path $newRelease) {
                Write-Host "Found release $newRelease"
            } else {
                Copy-Item $releaseFile.FullName $releaseFolder
                & $newRelease
            }

        }
    } else {
        Write-Host "Missing $($folder)\upgrade"
    }
}