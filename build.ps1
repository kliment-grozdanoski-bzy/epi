Param
	(
		[switch]
		$Install,
		[switch]
		$Update,
		[switch]
		$Build,
		[switch]
		$Test,
		[switch]
		$Pack,
		[switch]
		$Publish,
		[switch]
		$Release
	) 


Function NuGet-Install {
	Param(
		[string]
		$OutDir=".",
		[string]
		$NugetPath = "C:\ProgramData\chocolatey\lib\NuGet.CommandLine\tools\NuGet.exe"
	)

	$ScriptBlockContent = {
		& $NugetPath install -ExcludeVersion -OutputDir $OutDir
	}

	Invoke-Command -ScriptBlock $ScriptBlockContent -ArgumentList $($NugetPath, $Source, $ApiKey, $Path) -Verbose
}

function Choco-Install {
	choco install OctopusTools -y --version 4.9.1
}

function Add-OctopusDeployRelease {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true)]
        [string]
		$ProjectName, 
		[Parameter(Mandatory=$true)]
		[string]
		$Version, 
		[Parameter(Mandatory=$true)]
		[string]
		$Packageversion, 
		[Parameter(Mandatory=$true)]
		[string]
		$OctopusDeployServer,
		[Parameter(Mandatory=$true)]
		[string]
		$OctopusDeployAPIKey,
		[string]
		$OctoLocation = "C:\ProgramData\chocolatey\lib\OctopusTools\tools\octo.exe",
		[switch]
		$LocalBuild,
		[string]
		$OctopusChannel
	)

	Write-Host @"
			Options:
				ProjectName = $ProjectName
				Version = $Version
				PackageVersion = $Packageversion
				OctopusDeployServer = $OctopusDeployServer
				OctopusChannel = $OctopusChannel
"@

	# Check for octo.exe
	If (Test-Path $OctoLocation) {
		Write-Host "octo.exe found: $OctoLocation"
	} Else {
		Write-Warning "octo.exe not found at $OctoLocation"
		[Environment]::Exit(1)
	}
	
	Create-Release-Notes -Version $Version
		
	If ($LocalBuild) {
		Write-Warning "Local build - octopus release not created"
	} Else {

		$ScriptBlockContent = $null
		if($OctopusChannel) {
			$ScriptBlockContent = {
				& $OctoLocation create-release --project `"$ProjectName`" --version $Version --packageVersion $PackageVersion --server $OctopusDeployServer --apiKey $OctopusDeployAPIKey --releasenotesfile ".\release-notes.md" --channel $OctopusChannel
			}
		} else {
			$ScriptBlockContent = {
				& $OctoLocation create-release --project `"$ProjectName`" --version $Version --packageVersion $PackageVersion --server $OctopusDeployServer --apiKey $OctopusDeployAPIKey --releasenotesfile ".\release-notes.md"
			}
		}

		

		Invoke-Command -ScriptBlock $ScriptBlockContent -ArgumentList $($OctoLocation, $ProjectName, $Version, $PackageVersion, $OctopusDeployServer,  $OctopusDeployAPIKey) -Verbose | Tee-Object -Variable result
		
		If($result) {
			$message =  $result | Out-String

			If (-Not $message.Contains("created successfully!")) {
				Write-Error $message

				# stop build process
				[Environment]::Exit(1)
			}
		}
	}
}
	

#Install dependencies	
$modulePath = ".\BuildTools.DB"
If (-Not (Test-Path $modulePath)) {
	# TODO: find NuGet proper location
	NuGet-Install
}
	
# Import dependencies	
Import-Module "$modulePath\buildtoolsdb-helpers.ps1"

# print all variables
# Get-Childitem -Path Env:* | Sort-Object Name

# set env variables
$nuget_deployments_server = $env:Nuget_Deployments_Server
$nuget_deployments_api_key = $env:Nuget_Deployments_Api_Key
$octopus_server = $env:Octopus_Server
$octopus_api_key = $env:Octopus_API_Key
$version = $env:BUILD_NUMBER
$projectName = $env:db_project_name
$buildAgent = $env:BUILD_AGENT
$branch = $env:Branch_Name
$multipleChannels = $env:Multiple_Channels
$channels = $null

$sonar_url = $env:Sonar_Url

# set variables
$src = ""
If (Test-Path "src") {
	$src = "src"
}

if(!($projectName)) {
	$projectName = (Get-Item .).BaseName
	Write-Verbose "Project name: $projectName"
}

$buildOutputPath = "BuildOutput"
$packagePath = "$src\$projectName.nuspec"
$packagePaths = @()


if($multipleChannels) {
	$channels = $multipleChannels -Split ";"
}

$outDir = "$buildOutputPath\$projectName\"
$config = "Release"
$localBuild = $false
$pullRequestNo = $null
$preview = $true
#$preview = $false
$prereleaseTag = $false

If (-Not $version) {
	$version = "1.0.0"
}
  
# init, build and validate, publish

If(-Not $buildAgent) {
	$localBuild = $true
}

If($branch) {
	If($branch.EndsWith("/merge")) {
		$pullRequestNo = $branch.Split('/')[0]
	} Else {
		$preview = $false
	}
}

# Install dependencies
If ($Install) {
	Choco-Install
}

	
# Build project
If ($Build) {
	# clean build output
	If(Test-Path $buildOutputPath) {
	  Remove-Item -Force -Recurse $buildOutputPath
	}

	# Build project
	Write-Host "##teamcity[blockOpened name='Build-Project' description=' $projectName']"
	
	if ((Test-Path "$src\template-powerbi-reports.nuspec") -and ($projectName -ne "template-powerbi-reports")) {
		Write-Error "template-powerbi-reports.nuspec has not been configured"
	}


	

	Write-Host "##teamcity[blockClosed name='Build-Project']"
}

$packageFiles = Get-ChildItem -Path "$src\" -Include "*.nuspec" -Recurse

	
if($packageFiles) {
	if($packageFiles.Length -eq 0) {
		Write-Error "no *.nuspec files configured for this repository."
	}
} else {
	Write-Error "no files found"
}

foreach ($item in $packageFiles) {
	
	$packagePaths += "$src\$($item.Name)"
	Write-Host "Found nuspec $($item.Name)"
}



foreach ($path in $packagePaths) {
	$projName = $path -replace ".nuspec", "" 
	$projName = $projName -replace "$src\\", ""
	
	if($projectName -eq "template-powerbi-reports") {
		# default octopus deploy project
		$projName = "SolidOps.PBI.Reports"
	}
	
	Write-Host "Nuspec project: $projName"

	# Pack and publish package
	If ($Pack) {
		Write-Host "##teamcity[blockOpened name='Pack-Project' description='Pack project']"
		Pack-Project -Path $path -Version $version -ProjectName $projName -OutDir $outDir	
		
		Write-Host "##teamcity[blockClosed name='Pack-Project']"
	}

	# Publish Nuget
	If ($Publish -And -Not $preview) {
		
		Write-Host "##teamcity[blockOpened name='Publish-Project $projName' description='Publish project $$projName.$version.nupkg']"
		$nupkg = "$outDir$projName.$version.nupkg"
		Write-Host "Nuget pgk path: $nupkg"

		Publish-Package -Path $nupkg -Source $nuget_deployments_server -ApiKey $nuget_deployments_api_key
		Write-Host "##teamcity[blockClosed name='Publish-Project']"
	}

	# Create Octopus Deploy new release
	If ($Release) {
		If ($preview) {
			Create-Release-Notes -Version $version
		} Else {
			# replace alpha if pre-release build
			#$releaseNumber = $version.Replace("-alpha", "")
			
			$packageVersion = $version.Split("-")[0]
			Write-Host "##teamcity[blockOpened name='Octopus-Release' description='Release project']"

			if($version.Split("-")[1])
			{
				$packageVersion = $version
				$prereleaseTag = $true
			}

			$octopusOptions = @{
				ProjectName = $projName
				Version = $version
				PackageVersion = $packageVersion
				OctopusDeployServer = $octopus_server
				OctopusDeployAPIKey = $octopus_api_key
				OctopusChannel = $null
			}

			#Create-Octopus-Release @octopusOptions
			# create default release
			Add-OctopusDeployRelease @octopusOptions

			if(($channels) -and (-not $prereleaseTag)) {
				Write-Host "Create release for multiple channels"
				foreach ($channel in $channels) {
					Write-Host "##teamcity[blockOpened name='Octopus-Release Channel $($channel)']"
					$octopusOptions.OctopusChannel = $channel
					$octopusOptions.Version = $version + "-" + $channel
					Add-OctopusDeployRelease @octopusOptions
					Write-Host "##teamcity[blockClosed name='Octopus-Release Channel $($channel)']"
				}
			}
			
			
			Write-Host "##teamcity[blockClosed name='Octopus-Release']"
		}
	} 

}

