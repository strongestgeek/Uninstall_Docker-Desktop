# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Script was not ran as admin" | Out-File -Append -FilePath $logFilePath
    Exit
}

#Info
$logFilePath = 'C:\Temp\Logs\Intunelogs.txt'

# Check if the directory exists, create it if not
$logDirectory = 'C:\Temp\Logs'
if (-not (Test-Path $logDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $logDirectory | Out-Null
}

Stop-Process -Name "Docker*" -Force

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Uninstall Docker Desktop - Started" | Out-File -Append -FilePath $logFilePath

# Define paths
$installerPath = "C:\Program Files\Docker\Docker\Docker Desktop Installer.exe"
$baseResidualPaths = @(
    "C:\ProgramData\Docker",
    "C:\ProgramData\DockerDesktop",
    "C:\Program Files\Docker",
    "C:\Windows\Temp\DockerDesktop"
)

# Define user-specific subpaths
$residualUserSubpaths = @(
    "\AppData\Local\Docker",
    "\AppData\Roaming\Docker",
    "\AppData\Roaming\Docker Desktop",
    "\.docker"
)

# Uninstall Docker Desktop
if (Test-Path $installerPath) {
    Start-Process $installerPath -Wait -ArgumentList "uninstall" -NoNewWindow
    #Write-Host "Docker Desktop has been uninstalled."
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Docker Desktop has been uninstalled." | Out-File -Append -FilePath $logFilePath
} else {
    #Write-Host "Docker Desktop Installer not found at $installerPath. Please check the path and try again."
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Docker Desktop not installed." | Out-File -Append -FilePath $logFilePath
}

## Remove residual files for all user profiles
foreach ($baseResidualPath in $baseResidualPaths) {
    if ((Test-Path $baseResidualPath) -or (Test-Path $baseResidualPath -ea 0)) {
        Write-Host "Removing $baseResidualPath..."
        Remove-Item -Path $baseResidualPath -Recurse -Force
        #Write-Host "$baseResidualPath has been removed."
		$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		"[$timestamp] $baseResidualPath has been removed." | Out-File -Append -FilePath $logFilePath
    } else {
        #Write-Host "$baseResidualPath not found."
    }
}

foreach ($userProfile in (Get-ChildItem -Path "C:\Users" -Directory)) {
    foreach ($subpath in $residualUserSubpaths) {
        $path = Join-Path $userProfile.FullName $subpath
        if ((Test-Path $path) -or (Test-Path $path -ea 0)) {
            Write-Host "Removing $path..."
            Remove-Item -Path $path -Recurse -Force
            #Write-Host "$path has been removed."
			$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			"[$timestamp] $path has been removed." | Out-File -Append -FilePath $logFilePath
        } else {
            #Write-Host "$path not found."
        }
    }
}

# Remove "docker-users" group
$groupToRemove = "docker-users"
$group = Get-LocalGroup -Name $groupToRemove -ErrorAction SilentlyContinue

if ($group -ne $null) {
    #Write-Host "Removing $groupToRemove group..."
    Get-LocalGroupMember -Group $groupToRemove | ForEach-Object {
        Remove-LocalGroupMember -Group $groupToRemove -Member $_ -Confirm:$false
    }
    Remove-LocalGroup -Name $groupToRemove
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $groupToRemove group has been removed." | Out-File -Append -FilePath $logFilePath
} else {
    #Write-Host "$groupToRemove group not found."
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $groupToRemove group not found." | Out-File -Append -FilePath $logFilePath
}

#Find and delte the installation file.
# Define the file name to search for
$fileName = "Docker Desktop Installer.exe"

# Define the root directory to start the search
$rootDirectory = "C:\"  # You may need to adjust this based on your system

# Recursively search for the file
$files = Get-ChildItem -Path $rootDirectory -Filter $fileName -Recurse -ErrorAction SilentlyContinue

# Check if any matching files were found
if ($files.Count -gt 0) {
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Found $($files.Count) instances of $fileName." | Out-File -Append -FilePath $logFilePath

    # Loop through each matching file and delete it
    foreach ($file in $files) {
        Remove-Item -Path $file.FullName -Force
		$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Deleted: $($file.FullName)." | Out-File -Append -FilePath $logFilePath
    }

	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Instalation files found and deleted." | Out-File -Append -FilePath $logFilePath
} else {
	#Write-Host "No instances of $fileName found."
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] No instances of $fileName found." | Out-File -Append -FilePath $logFilePath
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Uninstallation completed and all files cleared out." | Out-File -Append -FilePath $logFilePath