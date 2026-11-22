<#
.SYNOPSIS
    Microsoft 'Windows UEFI CA 2023' Media Update Script

.DESCRIPTION
    This script updates Windows media to use boot binaries signed with the 'Windows UEFI CA 2023' certificate.

.NOTES
    File Name  : Make2023BootableMedia.ps1
    Author     : Microsoft Corporation
    Version    : 1.6
    Date       : 2026-10-27

.LICENSE
    Licensed under the BSD License. See License.txt in the project root for full license information.

.COPYRIGHT
    Copyright (c) Microsoft Corporation. All rights reserved.
#>

param (

    [Parameter(Position=0,mandatory=$true)]
	[string] $MediaPath,

	[ValidateSet("ISO", "USB", "LOCAL", IgnoreCase=$true)]
	[Parameter(Position = 1, Mandatory=$false)]
	[string] $TargetType,

	[Parameter(Position = 2,mandatory=$false)]
	[string] $ISOPath,

	[Parameter(Position = 3,mandatory=$false)]
    [string] $USBDrive,

    [Parameter(Position = 4,mandatory=$false)]
    [string] $FileSystem,

    [Parameter(Position = 5, Mandatory=$false)]
    [string] $NewMediaPath,

    [Parameter(Position = 6, Mandatory=$false)]
    [string] $StagingDir,

    [Parameter(Position = 7, Mandatory=$false)]
    [bool] $DebugOn = $false
)

function Get-TS { return "{0:HH:mm:ss}" -f [DateTime]::Now }

function Show-Usage {
    $scriptName = $global:ScriptName
    Write-Host "Usage:`r`n$scriptName -MediaPath <path> -TargetType <type> -ISOPath <path> -USBDrive <drive:> -FileSystem <type> -NewMediaPath <path> -StagingDir <path>" -ForegroundColor Blue
    Write-Host "  -MediaPath <path> The path to the media folder or ISO file to be used as baseline."
    Write-Host "  -TargetType <type> The type of media to be created (ISO, USB, or LOCAL)."
    Write-Host "        ISO: Convert media specified in -MediaPath to 2023 bootable ISO file. Targets -ISOPath."
    Write-Host "        USB: Convert media specified in -MediaPath to 2023 bootable image and writes it to -USBDrive."
    Write-Host "        LOCAL: Convert media specified in -MediaPath to 2023 bootable image copied to -NewMediaPath."
    Write-Host "  -ISOPath <path> The path to the new ISO file to be created from -MediaPath."
    Write-Host "  -USBDrive <drive:> The drive letter to a target USB drive (example E:)."
    Write-Host "  -FileSystem <type> Optional. The file system to format the USB drive with (FAT32 or ExFAT). Default is FAT32."
    Write-Host "  -NewMediaPath <path> Required for LOCAL TargetType. -MediaPath content is duplicated here and then updated."
    Write-Host "  -StagingDir (optional) <path> Overrides default temp staging path used by this script. System %TEMP% used by default with random subfolder."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "$scriptName -MediaPath C:\Media\Win10Media -TargetType ISO -ISOPath C:\Media\Win10_Updated.iso"
    Write-Host "$scriptName -MediaPath C:\Media\Win11.iso -TargetType ISO -ISOPath C:\Media\Win11_Updated.iso"
    Write-Host "$scriptName -MediaPath \\server\share\Win11_Media -TargetType ISO -ISOPath C:\Media\Win11_Updated.iso"
    Write-Host "$scriptName -MediaPath \\server\share\Win11.iso -TargetType ISO -ISOPath C:\Media\Win11_Updated.iso"
    Write-Host "$scriptName -MediaPath C:\Media\Win1124H2 -TargetType USB -USBDrive H:"
    Write-Host "$scriptName -MediaPath C:\Media\Win11.iso -TargetType USB -USBDrive E:"
    Write-Host "$scriptName -MediaPath C:\Media\Win1124H2 -TargetType LOCAL -NewMediaPath C:\Media\Win1124H2_Updated"
    Write-Host "$scriptName -MediaPath H:\Media\Win11.iso -TargetType LOCAL -NewMediaPath R:\Win11_Updated"
    Write-Host "$scriptName -MediaPath C:\Media\Win1124H2 -TargetType ISO -ISOPath C:\Media\Win1124H2_Updated.iso -StagingDir C:\Temp\Win1124H2"
    Write-Host "`r`nIMPORTANT! You must provide this script with a media source (-MediaPath) which has the latest 2024-4B (or later) updates included!`r`n" -ForegroundColor Red
}

function Show-ADK-Req {
    Write-Host "The Windows ADK must be installed on the system if trying to create ISO media. Available at https://aka.ms/adk" -ForegroundColor Red
    Write-Host "After install, open an admin-elevated 'Deploy and Imaging Tools Environment' command prompt provided with the ADK." -ForegroundColor Red
    Write-Host "Then run PowerShell from this command prompt and you should be good to go.`r`n" -ForegroundColor Red
}

function Download-Oscdimg {
    <#
    .SYNOPSIS
        Downloads oscdimg.exe from the Microsoft public symbol server for the current architecture. These are not signed so 
        they are validated against known SHA256 hashes before being used. 
    .OUTPUTS
        The file path to the downloaded oscdimg.exe, or $null on failure.
    #>

    $archUrls = @{
        "AMD64" = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/9F01AFB765000/oscdimg.exe"
        "ARM64" = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/2267BF2C66000/oscdimg.exe"
        "x86"   = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/CFBCC93A60000/oscdimg.exe"
    }

    $arch = $env:PROCESSOR_ARCHITECTURE
    if (-not $archUrls.ContainsKey($arch)) {
        Write-Host "Unsupported architecture [$arch] for oscdimg download." -ForegroundColor Red
        return $null
    }

    $url = $archUrls[$arch]
    $expectedHash = $global:oscdimg_known_hashes[$arch]
    $destPath = Join-Path -Path $env:TEMP -ChildPath "oscdimg.exe"

    Write-Host "Downloading oscdimg.exe for [$arch] from Microsoft symbol server..." -ForegroundColor Blue
    Write-Dbg-Host "Download URL: $url"
    Write-Dbg-Host "Destination: $destPath"

    $tmpDownloadPath = "$destPath.download"
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmpDownloadPath -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "Failed to download oscdimg.exe: $($_.Exception.Message)" -ForegroundColor Red
        Remove-Item -Path $tmpDownloadPath -Force -ErrorAction SilentlyContinue
        return $null
    }

    if (-not (Test-Path $tmpDownloadPath)) {
        Write-Host "Download appeared to succeed but file not found at [$tmpDownloadPath]." -ForegroundColor Red
        return $null
    }

    # Validate downloaded file against known SHA256 hash
    $actualHash = (Get-FileHash -Path $tmpDownloadPath -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) {
        Write-Host "Downloaded oscdimg.exe failed integrity check." -ForegroundColor Red
        Write-Host "Expected SHA256: $expectedHash" -ForegroundColor Red
        Write-Host "Actual SHA256:   $actualHash" -ForegroundColor Red
        Remove-Item -Path $tmpDownloadPath -Force -ErrorAction SilentlyContinue
        return $null
    }
    Write-Dbg-Host "SHA256 hash verified: $actualHash"

    # Move validated file into place
    Move-Item -Path $tmpDownloadPath -Destination $destPath -Force

    $fileSize = (Get-Item $destPath).Length
    Write-Host "Successfully downloaded oscdimg.exe ($fileSize bytes) to [$destPath]" -ForegroundColor Green
    return $destPath
}

function Debug-Pause {

    if ($global:Dbg_Pause) {
        Write-Host "Press any key to continue"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    return
}

# Routine to help with script debugging
function Write-Dbg-Host {
    if ($global:Dbg_Output) {
        Write-Host "$(Get-TS): [DBG] $args" -ForegroundColor DarkMagenta
    }
}

function Execute-Cleanup {

    # Pause here to allow the user to see the mounted WIM
    Debug-Pause

    Write-Dbg-Host "Cleaning up"

    if ($global:WIM_Mount_Path) {
        Write-Dbg-Host "Dismounting [$global:WIM_Mount_Path]"
        try {
            Dismount-WindowsImage -Path $global:WIM_Mount_Path -Discard -ErrorAction stop | Out-Null
            try {
                Write-Dbg-Host "Removing WIM mount path [$global:WIM_Mount_Path]"
                Remove-Item -Path $global:WIM_Mount_Path -Recurse -Force -ErrorAction stop | Out-Null
            } catch {
                Write-Host "Failed to remove WIM mount path [$global:WIM_Mount_Path]" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        } catch {
            Write-Host "Failed to dismount WIM [$global:WIM_Mount_Path]" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }

    if ($global:ISO_Mount_Path) {
        Write-Dbg-Host "Dismounting [$global:ISO_Mount_Path]"

        try {
            Dismount-DiskImage -ImagePath $global:ISO_Mount_Path -ErrorAction stop | Out-Null
        } catch {
            Write-Host "Failed to dismount ISO [$global:ISO_Mount_Path]" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }

    if ($global:StagingDir_Created -eq $true) {
        Write-Dbg-Host "Removing staging directory [$global:Staging_Directory_Path]"
        try {
            Remove-Item -Path $global:Staging_Directory_Path -Recurse -Force -ErrorAction stop | Out-Null
        } catch {
            Write-Host "Failed to remove [$global:Staging_Directory_Path]" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}

function Validate-Requirements {
    param (
        [string] $TargetType
    )

    # If the target type is ISO, check for the required support tools from the ADK
    if ($TargetType -eq "ISO") {

        Write-Host "Checking for required support tools" -ForegroundColor Blue
        # Check if the script is running with administrative privileges
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Host "You do not have Administrator rights to run this script.`nPlease re-run this script as an Administrator." -ForegroundColor Red
            exit
        }
        # Look for the oscdimg.exe tool in the commonly used install path for the ADK.
        $adkOsCdImgPath = "\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        $progFilesPath = Get-ChildItem "Env:ProgramFiles(x86)"
        if ($progFilesPath -ne $null) {
            $executablePath = Join-Path -Path $progFilesPath.Value -ChildPath $adkOsCdImgPath
            if (Test-Path -Path $executablePath) {
                Write-Dbg-Host "Found [oscdimg.exe] in [$executablePath]"
                $global:oscdimg_exe = $executablePath
                return $true
            }
            Write-Dbg-Host "[oscdimg.exe] not found in [$executablePath]"
        }
        # Final attempt to find oscdimg.exe in the system PATH
        $executablePath = (where.exe oscdimg.exe 2>$null)
        if ($null -eq $executablePath) {
            # See if oscdimg.exe exists in the current working directory
            $executablePath = Join-Path -Path $PWD.Path -ChildPath "oscdimg.exe"
            if (-not (Test-Path -Path $executablePath)) {
                Write-Dbg-Host "[oscdimg.exe] not found in [$PWD] or in the system PATH!"

                # Check if oscdimg.exe was previously downloaded to the temp directory
                $tempOscdimg = Join-Path -Path $env:TEMP -ChildPath "oscdimg.exe"
                if (Test-Path -Path $tempOscdimg) {
                    # Validate hash before trusting a cached copy from user-writable temp dir
                    $expectedHash = $global:oscdimg_known_hashes[$env:PROCESSOR_ARCHITECTURE]
                    $actualHash = (Get-FileHash -Path $tempOscdimg -Algorithm SHA256).Hash
                    if ($expectedHash -and $actualHash -eq $expectedHash) {
                        Write-Dbg-Host "Found previously downloaded [oscdimg.exe] in [$tempOscdimg] with valid hash"
                        Write-Host "Using previously downloaded oscdimg.exe from [$tempOscdimg]" -ForegroundColor Green
                        $global:oscdimg_exe = $tempOscdimg
                        return $true
                    } else {
                        Write-Dbg-Host "Cached [oscdimg.exe] at [$tempOscdimg] failed integrity check. Removing."
                        Remove-Item -Path $tempOscdimg -Force -ErrorAction SilentlyContinue
                    }
                }

                # Offer to download oscdimg.exe from the Microsoft public symbol server
                Write-Host "`r`noscdimg.exe is required for ISO media creation and was not found on this system." -ForegroundColor Yellow
                Write-Host "It can be downloaded directly from the Microsoft public symbol server (~450 KB)." -ForegroundColor Yellow
                Write-Host "Alternatively, it is included with an install of the full Windows ADK (https://aka.ms/adk).`r`n" -ForegroundColor Yellow
                $response = Read-Host "Download oscdimg.exe from Microsoft? (Y/N)"
                if ($response -match '^[Yy]') {
                    $downloadedPath = Download-Oscdimg
                    if ($null -ne $downloadedPath) {
                        $global:oscdimg_exe = $downloadedPath
                        return $true
                    }
                    Write-Host "Download failed. Please install the Windows ADK instead." -ForegroundColor Red
                }

                Show-ADK-Req
                return $false
            }
        }

        Write-Dbg-Host "[oscdimg.exe] found in [$executablePath]"
        $global:oscdimg_exe = $executablePath
    }
    return $true
}

function Initialize-MediaPaths {
    param (
         [string] $MediaPath,
         [string] $NewMediaPath,
         [string] $StagingDir
     )

    $isUNCPath = $false
    $localMediaPath = $MediaPath
    $mountResult = $null

    # If NewMediaPath is provided, use it as the staging directory
    if ($NewMediaPath) {
        try {
            $tmpPath = ConvertTo-AbsolutePath -Path $NewMediaPath
        }
        catch {
            Write-Host "Error processing [$NewMediaPath] -> Error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }

        if ($NewMediaPath -match "^[a-zA-Z]:$") {
            $tmpPath = "$NewMediaPath\"
        }

        $global:Temp_Media_To_Update_Path = $tmpPath
        $global:Staging_Directory_Path = $tmpPath

    } else {

        # If NewMediaPath is not provided, use the StagingDir as the staging directory
        $result = Initialize-StagingDirectory $StagingDir
        if ($result -eq $false) {
            return $false
        }
        $global:Temp_Media_To_Update_Path = $global:Staging_Directory_Path + "\MediaToUpdate"
    }

    if (-not (Test-Path -Path $global:Temp_Media_To_Update_Path)) {
        try {
            New-Item -ItemType Directory -Path $global:Temp_Media_To_Update_Path  -Force | Out-Null
            Write-Dbg-Host "[$global:Temp_Media_To_Update_Path] created"
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
            return $false
        }
    }

    Write-Host "Staging media" -ForegroundColor Blue
    $global:Src_Media_Path = $MediaPath
    # See if MediaPath is a UNC path
    if ($MediaPath -match "^\\\\") {
        Write-Dbg-Host "[$MediaPath] is a UNC path"
        $isUNCPath = $true
    }

    # Now determine if this is an ISO
    if ($MediaPath -match "\.iso$") {

        Write-Dbg-Host "[$MediaPath] is an ISO file"
        if ($isUNCPath) {

            $localIsoPath = $global:Staging_Directory_Path + "\$((Get-Item -Path $global:Src_Media_Path).Name)"
            Write-Host "Copying [$global:Src_Media_Path] to staging directory"
            Write-Dbg-Host "Copying [$global:Src_Media_Path] --> [$localIsoPath]"
            try {
                Copy-LargeFileWithProgres -SourcePath $global:Src_Media_Path -Destination $localIsoPath -Force -ErrorAction stop | Out-Null
            } catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
                return $false
            }
        } else{
            # Get full path for the ISO
            $global:Src_Media_Path = (Get-Item -Path $MediaPath).FullName
            if ($global:Src_Media_Path -eq $null) {
                Write-Host "Failed to get full path for [$MediaPath]" -ForegroundColor Red
                return $false
            }
            $localIsoPath = $global:Src_Media_Path
        }

        Write-Host "Mounting ISO from staged media" -ForegroundColor Blue
        Write-Dbg-Host "Mounting ISO [$localIsoPath]"
        $mountResult = Mount-DiskImage -ImagePath $localIsoPath -PassThru -ErrorAction stop
        if ($mountResult -eq $null) {
            Write-Host "Failed to mount $localIsoPath" -ForegroundColor Red
            return $false
        }

        $global:ISO_Mount_Path = $localIsoPath
        $localMediaPath = ($mountResult | Get-Volume).DriveLetter + ":"

        # Retrieve the volume label from the mounted ISO to be used later if a new ISO is created
        $global:ISO_Label = (Get-Volume -DriveLetter ($mountResult | Get-Volume).DriveLetter).FileSystemLabel

    } else {

        Write-Dbg-Host "[$MediaPath] is a directory"
        try {
            $tmpPath = ConvertTo-AbsolutePath -Path $MediaPath -AllowUNC $true
        }
        catch {
            Write-Host "Error processing [$MediaPath] -> Error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }

        $global:Src_Media_Path = $tmpPath
        $localMediaPath = $tmpPath
    }

    $bootWimPath = $localMediaPath + "\sources\boot.wim"
    Write-Dbg-Host "Making sure [$bootWimPath] exists"
    if (-not (Test-Path -Path $bootWimPath)) {
        Write-Host "[$localMediaPath\] does not appear to point to valid Windows media!" -ForegroundColor Red
        return $false
    }

    # Get the current working directory and add "WimMount" to it
    $global:WIM_Mount_Path = $global:Staging_Directory_Path + "\WimMount"

    # If the WIM MOUNT directory does not exist, create it
    if (-not (Test-Path -Path $global:WIM_Mount_Path)) {
        New-Item -ItemType Directory -Path $global:WIM_Mount_Path -Force | Out-Null
        Write-Dbg-Host "Creating mount path [$global:WIM_Mount_Path]"
    }else{
        Write-Dbg-Host "Mount path [$global:WIM_Mount_Path] already exists"
    }

    Write-Dbg-Host "Copying [$localMediaPath] --> [$global:Temp_Media_To_Update_Path]"
    try {
        Copy-FilesWithProgress -SourcePath $localMediaPath -DestinationPath $global:Temp_Media_To_Update_Path
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }

    if ($mountResult -ne $null) {
        Write-Dbg-Host "Unmounting [$global:ISO_Mount_Path]"
        try {
            Dismount-DiskImage -ImagePath $global:ISO_Mount_Path -ErrorAction stop | Out-Null
        } catch {
            Write-Host "Failed to dismount ISO [$global:ISO_Mount_Path]" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            return $false
        }
    }

    Write-Dbg-Host "Media [$global:Temp_Media_To_Update_Path] ready for update!"

    return $true
}

function Initialize-StagingDirectory {
     param (
         [string] $StagingDir
     )

    # If $StagingDir does not exist, set it to the system %TEMP%\%randomdir% directory
    Write-Host "Initializing staging directory" -ForegroundColor Blue

    if (-not $StagingDir) {
        $global:Staging_Directory_Path = [System.IO.Path]::GetTempPath() + ([System.IO.Path]::GetRandomFileName()).Replace(".", "")
        Write-Dbg-Host "Using default staging directory [$global:Staging_Directory_Path]"
        New-Item -ItemType Directory -Path $global:Staging_Directory_Path -Force | Out-Null
        $global:StagingDir_Created = $true
    } else {
        Write-Dbg-Host "Using provided staging directory [$StagingDir]"

        try {
            $tmpPath = ConvertTo-AbsolutePath -Path $StagingDir
            Write-Dbg-Host "StagingDir [$StagingDir] -> [$tmpPath]"
        }
        catch {
            Write-Host "Staging failure -> Error: $($_.Exception.Message) [$StagingDir]" -ForegroundColor Red
            return $false
        }

        $global:Staging_Directory_Path = $tmpPath

        $driveLetter = (Split-Path -Qualifier $global:Staging_Directory_Path).TrimEnd(':')
        try {
            $fs = (Get-Volume -DriveLetter $driveLetter -ErrorAction Stop).FileSystem
        } catch {
            Write-Host "Drive [$driveLetter`:] does not exist or is not accessible." -ForegroundColor Red
            return $false
        }

        # Make sure the staging directory is on an NTFS formatted file system. This is required for WIM mounting
        # which uses reparse points not fully supported on ReFS or other file systems.
        if ($fs -ne "NTFS") {
            Write-Host "`r`nStagingDir [$global:Staging_Directory_Path] must target an NTFS formatted file system (required for WIM mounting).`r`n" -ForegroundColor Red

            if ($global:StagingDir_Created -eq $true) {
                Write-Dbg-Host "Removing staging directory [$global:Staging_Directory_Path]"
                Remove-Item -Path $global:Staging_Directory_Path -Recurse -Force | Out-Null
                $global:StagingDir_Created = $false
            }
            return $false
        }

        $drive = Get-PSDrive -Name $driveLetter -PSProvider FileSystem
        if ($drive.Free -lt 10GB) {
            Write-Host "Drive [$drive] used for temp file staging does not not have enough free disk space! (10GB required)" -ForegroundColor Red
            Write-Dbg-Host "Drive [$drive] free disk space: $($drive.Free / 1GB)GB"

            if ($global:StagingDir_Created -eq $true) {
                Write-Dbg-Host "Removing staging directory [$global:Staging_Directory_Path]"
                Remove-Item -Path $global:Staging_Directory_Path -Recurse -Force | Out-Null
            }
            return $false
        }

        if (Test-Path -Path "$global:Staging_Directory_Path\") {
            # Provided staging directory already exists, ask the user if they want to overwrite it
            Write-Dbg-Host "Staging directory [$global:Staging_Directory_Path] already exists."
            Write-Dbg-Host "Appending random subfolder to staging directory [$global:Staging_Directory_Path]"
            $global:Staging_Directory_Path = "$global:Staging_Directory_Path\" + ([System.IO.Path]::GetRandomFileName()).Replace(".", "")

            try {
                New-Item -ItemType Directory -Path $global:Staging_Directory_Path -Force | Out-Null
                $global:StagingDir_Created = $true
            } catch {
                Write-Host "Failed to create staging directory [$global:Staging_Directory_Path]" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                return $false
            }
        } else {
            # Provided staging directory does not exist, create it
            try {
                New-Item -ItemType Directory -Path $global:Staging_Directory_Path -Force | Out-Null
                $global:StagingDir_Created = $true
                Write-Dbg-Host "[$global:Staging_Directory_Path] created"
            }
            catch {
                Write-Host "Failed to create staging directory [$global:Staging_Directory_Path]" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                return $false
            }
        }
    }

    return $true
}
function Validate-Parameters {
    param (
        [string] $TargetType,
        [string] $ISOPath,
        [string] $USBDrive,
        [string] $NewMediaPath,
        [string] $FileSystem,
        [string] $StagingDir
     )

    if (-not $TargetType) {
        Write-Host "`r`n-TargetType parameter required`r`n" -ForegroundColor Red
        return $false
    }

    switch ($TargetType) {
        "ISO" {

            if ($NewMediaPath){
                Write-Host "`r`n-NewMediaPath parameter invalid for TargetType ISO.`r`n" -ForegroundColor Red
                return $false
            }

            if ($USBDrive) {
                Write-Host "`r`n-USBDrive parameter invalid for TargetType ISO.`r`n" -ForegroundColor Red
                return $false
            }

            if ($FileSystem) {
                Write-Host "`r`n-FileSystem parameter invalid for TargetType ISO.`r`n" -ForegroundColor Red
                return $false
            }

            if (-not $ISOPath) {
                Write-Host "`r`n-ISOPath parameter required for TargetType ISO.`r`n" -ForegroundColor Red
                return $false
            }

            if (-not ($ISOPath -match "\.iso$")) {
                Write-Host "`r`n-ISOPath must specify a *.ISO file.`r`n" -ForegroundColor Red
                Write-Dbg-Host "Invalid ISOPath [$ISOPath]"
                return $false
            }

            # Normalize ISOPath to an absolute path
            try {
                $script:ISOPath = ConvertTo-AbsolutePath -Path $ISOPath
                Write-Dbg-Host "ISOPath: [$ISOPath] -> [$script:ISOPath]"
                $ISOPath = $script:ISOPath
            } catch {
                Write-Host "Invalid -ISOPath '$ISOPath': $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }

            # if $ISOPath exists, ask the user if they want to overwrite it, otherwise abort
            if (Test-Path -Path $ISOPath) {
                Write-Host "ISO [$ISOPath] already exists. Do you want to overwrite it? (Y/N)" -ForegroundColor Yellow
                $response = Read-Host
                if ($response -ne "Y") {
                    Write-Host "Aborting execution`r`n" -ForegroundColor Red
                    exit
                } else {
                    Write-Dbg-Host "Deleting [$ISOPath]"
                    Remove-Item -Path $ISOPath -Force
                }
            }

            Write-Dbg-Host "ISOPath [$ISOPath]"
        }
        "USB" {

            if ($NewMediaPath){
                Write-Host "`r`n-NewMediaPath parameter invalid for TargetType USB.`r`n" -ForegroundColor Red
                return $false
            }

            if ($ISOPath) {
                Write-Host "`r`n-ISOPath parameter invalid for TargetType USB.`r`n" -ForegroundColor Red
                return $false
            }

            if ($FileSystem -and
                ($FileSystem -ne "FAT32" -and $FileSystem -ne "ExFAT")) {
                Write-Host "`r`n-FileSystem must be FAT32 to boot on most UEFI systems." -ForegroundColor Red
                return $false
            }

            if (-not $USBDrive) {
                Write-Host "`r`n-USBDrive parameter required for TargetType USB.`r`n" -ForegroundColor Red
                return $false
            }

            if (-not ($USBDrive -match "^[a-zA-Z]:$")) {
                Write-Host "`r`n-USBDrive must specify a valid drive letter. ($USBDrive invalid!)`r`n" -ForegroundColor Red
                return $false
            } else {
                if ($FileSystem -eq "ExFAT") {
                    Write-Host "`r`nWARNING: Most UEFI systems cannot boot from ExFAT. Use FAT32 unless the target firmware supports booting from ExFAT." -ForegroundColor Yellow
                }
                Write-Host "`r`nWARNING: Contents on drive [$USBDrive] will be erased! Continue? (Y/N) " -ForegroundColor Yellow
                $response = Read-Host
                if ($response -ne "Y") {
                    Write-Host "Aborting execution`r`n" -ForegroundColor Red
                    exit
                }
                # Make sure the drive can support FAT32 if that is the target/default file system.
                Write-Dbg-Host "Checking drive [$USBDrive] file system"
                if (-not $FileSystem -or $FileSystem -ne "ExFAT") {
                    $partition = Get-Partition -DriveLetter $USBDrive.TrimEnd(':')
                    Write-Dbg-Host "Partition: $partition"
                    Write-Dbg-Host "Partition size: $($partition.Size / 1GB)GB"
                    if ($partition.Size -gt 32GB) {
                        Write-Host "Target drive partition is larger than 32GB and cannot be formatted as FAT32. " -ForegroundColor Red
                        Write-Host "Create a partition of 32GB or smaller and try again." -ForegroundColor Red
                        return $false
                    }
                }
            }
        }
        "LOCAL" {

            if ($USBDrive) {
                Write-Host "`r`n-USBDrive parameter invalid for TargetType LOCAL.`r`n" -ForegroundColor Red
                return $false
            }

            if ($ISOPath) {
                Write-Host "`r`n-ISOPath parameter invalid for TargetType LOCAL.`r`n" -ForegroundColor Red
                return $false
            }

            if ($FileSystem) {
                Write-Host "`r`n-FileSystem parameter invalid for TargetType LOCAL.`r`n" -ForegroundColor Red
                return $false
            }

            if (-not $NewMediaPath) {
                Write-Host "`r`n-NewMediaPath parameter required for TargetType LOCAL.`r`n" -ForegroundColor Red
                return $false
            }

            if ($StagingDir) {
                Write-Host "`r`n-StagingDir parameter ignored for TargetType LOCAL.`r`n" -ForegroundColor Yellow
            }

            try {
                $tmpPath = ConvertTo-AbsolutePath -Path $NewMediaPath
                Write-Dbg-Host "NewMediaPath: [$NewMediaPath] -> [$tmpPath]"
            }
            catch {
                Write-Host "-$NewMediaPath' -> Error: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }

            $driveLetter = (Split-Path -Qualifier $tmpPath).TrimEnd(':')
            try {
                $fs = (Get-Volume -DriveLetter $driveLetter -ErrorAction Stop).FileSystem
            } catch {
                Write-Host "Drive [$driveLetter`:] does not exist or is not accessible." -ForegroundColor Red
                return $false
            }

            # Make sure the target drive is NTFS. This is required for WIM mounting which uses
            # reparse points not fully supported on ReFS or other file systems.
            if ($fs -ne "NTFS") {
                Write-Host "`r`n-NewMediaPath [$tmpPath] must target an NTFS formatted file system (required for WIM mounting).`r`n" -ForegroundColor Red
                return $false
            }

            $drive = Get-PSDrive -Name $driveLetter -PSProvider FileSystem
            if ($drive.Free -lt 10GB) {
                Write-Host "[$tmpPath] does not have enough free space! (10GB required)" -ForegroundColor Red
                Write-Dbg-Host "Drive [$drive] free disk space: $($drive.Free / 1GB)GB"
                return $false
            }
        }
        default {
            Write-Host "Invalid TargetType: $TargetType" -ForegroundColor Red
            return $false
        }
    }

    return $true
}

function ConvertTo-AbsolutePath {
    param(
        [string]$Path,
        [bool] $AllowUNC = $false
        )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path cannot be null or empty"
    }

    # Reject UNC paths
    if (-not $AllowUNC) {
        if ($Path -match "^\\\\") {
            throw "Network (UNC) path not allowed"
        }
    }

    $tmpPath = $Path.TrimEnd('\')

    # If a root drive path (C:\), return as-is
    if ($tmpPath -match "^[a-zA-Z]:") {
        return $tmpPath
    }

    # Handle rooted but not fully qualified paths (\rootdir)
    if ($tmpPath -match "^\\[^\\]") {
        # Combine with current drive
        $currentDrive = (Get-Location).Drive.Name + ":"
        return [System.IO.Path]::GetFullPath($currentDrive + $tmpPath)
    }

    # Handle relative paths (.\subdir, ..\parent, subdir)
    if (-not [System.IO.Path]::IsPathRooted($tmpPath)) {
        return [System.IO.Path]::GetFullPath((Join-Path -Path $PWD.Path -ChildPath $tmpPath))
    }

    # For any other case, try to get full path
    return [System.IO.Path]::GetFullPath($tmpPath)
}

function Copy-FilesWithProgress {
    param (
        [string] $SourcePath,
        [string] $DestinationPath
    )

    $files = Get-ChildItem -Path $SourcePath -Recurse -File
    $totalFiles = $files.Count
    $currentFile = 0

    foreach ($file in $files) {
        $currentFile++
        $percentComplete = [math]::Round(($currentFile / $totalFiles) * 100, 2)
        $destinationFile = $file.FullName -replace [regex]::Escape($SourcePath), $DestinationPath

        $destinationDir = [System.IO.Path]::GetDirectoryName($destinationFile)
        if (-not (Test-Path -Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }

        # if the file is larger than 5MB, use the Copy-LargeFileWithProgres function
        if ($file.Length -gt 5MB) {
            Copy-LargeFileWithProgres -SourcePath $file.FullName -DestinationPath $destinationFile
            continue
        } else{
            Copy-Item -Path $file.FullName -Destination $destinationFile -Force
        }

        Write-Progress -Activity "Copying files" -Status "copying [$file]" -PercentComplete $percentComplete
    }
    Write-Progress -Activity "Copying files" -Completed
}

function Copy-LargeFileWithProgres {
    param (
        [string] $SourcePath,
        [string] $DestinationPath
    )

    # Define source and destination files
    $sourceFile = $SourcePath
    $destinationFile = $DestinationPath
    $fileName = [System.IO.Path]::GetFileName($sourceFile)

    # Get the total size of the source file
    $totalSize = (Get-Item $sourceFile).Length

    # Open file streams
    $sourceStream = [System.IO.File]::OpenRead($sourceFile)
    $destinationStream = [System.IO.File]::Create($destinationFile)

    # Define buffer size (e.g., 1 MB)
    $bufferSize = 10MB
    $buffer = New-Object byte[] $bufferSize
    $totalRead = 0

    # Copy in chunks
    try {
        while (($bytesRead = $sourceStream.Read($buffer, 0, $bufferSize)) -gt 0) {
            # Write to destination
            $destinationStream.Write($buffer, 0, $bytesRead)

            # Update total read
            $totalRead += $bytesRead

            # Calculate progress
            $percentComplete = [math]::Round(($totalRead / $totalSize) * 100, 2)

            # Display progress
            Write-Progress -Activity "Copying files" -Status "copying [$fileName] $percentComplete% complete" -PercentComplete $percentComplete
        }
        Write-Progress -Activity "Copying file" -Completed
    }
    finally {
        # Close streams
        $sourceStream.Close()
        $destinationStream.Close()
    }
}

function Copy-2023BootBins {

    $bootWimPath = $global:Temp_Media_To_Update_Path + "\sources\boot.wim"
    # Make sure we have a boot.wim file
    if (-not (Test-Path -Path $bootWimPath)) {
        Write-Host "[$global:Src_Media_Path] does not appear to point to valid Windows media!" -ForegroundColor Red
        return $false
    }
    $bootWimMount = $global:WIM_Mount_Path
    Write-Dbg-Host "Mounting [$bootWimPath]"
    Write-Host "Mounting boot.wim from staged media" -ForegroundColor Blue
    try {
        $mountedImage = Mount-WindowsImage -ImagePath $bootWimPath -Index 1 -Path $bootWimMount -ReadOnly -ErrorAction stop | Out-Null
        Write-Dbg-Host "Mounted [$bootWimPath] --> [$bootWimMount]"
    } catch {
        Write-Host "Failed to mount boot.wim of the source media!`r`nMake sure -StagingDir is targeting an NTFS formatted file system (ReFS is not supported for WIM mounting)." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }

    $ex_bins_path = $bootWimMount + "\Windows\Boot\EFI_EX"
    $ex_fonts_path = $bootWimMount + "\Windows\Boot\FONTS_EX"
    $ex_dvd_path = $bootWimMount + "\Windows\Boot\DVD_EX"

    # Make sure the directories exist
    if (-not (Test-Path -Path $ex_dvd_path) -or
        -not (Test-Path -Path $ex_fonts_path) -or
        -not (Test-Path -Path $ex_bins_path)) {
        Write-Host "-MediaPath [$((Get-Item -Path $global:Src_Media_Path).Name)] does not have required binaries." -ForegroundColor Red
        Write-Host "Make sure all required updates (2024-4B or later) have been applied." -ForegroundColor Red
        Write-Host "[$global:Temp_Media_To_Update_Path] staged but was not updated!" -ForegroundColor Red
        return $false
    }

    Write-Host "Updating staged media to use boot binaries signed with 'Windows UEFI CA 2023' certificate" -ForegroundColor Blue

    try {
        # Special case the architecture specific binary name
        $bootmgr_archver = "bootx64.efi"
        if (Test-Path -Path $global:Temp_Media_To_Update_Path\efi\boot\bootaa64.efi) {
            $bootmgr_archver = "bootaa64.efi" # ARM64
        }

        # Copy $ex_bins_path\bootmgrfw_EX.efi to $global:Temp_Media_To_Update_Path\efi\boot\bootx64.efi
        Write-Dbg-Host "Copying [$ex_bins_path\bootmgfw_EX.efi] to [$global:Temp_Media_To_Update_Path\efi\boot\$bootmgr_archver]"
        Copy-Item -Path $ex_bins_path"\bootmgfw_EX.efi" -Destination $global:Temp_Media_To_Update_Path"\efi\boot\"$bootmgr_archver -Force -ErrorAction stop | Out-Null

        # Copy $ex_bins_path\bootmgr_EX.efi to $global:Temp_Media_To_Update_Path\bootmgr.efi (but only if it exists)
        # Note that this file technically is not signed with the 'Windows UEFI CA 2023' certificate, but if present in the update, it should be copied.
        if ((Test-Path -Path $ex_bins_path"\bootmgr_EX.efi")) {
             # Copy  $ex_bins_path\bootmgr_EX.efi to $global:Temp_Media_To_Update_Path\bootmgr.efi
            Write-Dbg-Host "Copying [$ex_bins_path\bootmgr_EX.efi] to [$global:Temp_Media_To_Update_Path\bootmgr.efi]"
            Copy-Item -Path $ex_bins_path"\bootmgr_EX.efi" -Destination $global:Temp_Media_To_Update_Path"\bootmgr.efi" -Force -ErrorAction stop | Out-Null
        } else {
            Write-Dbg-Host "[$ex_bins_path\bootmgr_EX.efi] does not exist. Skipping."
        }

        # Copy $ex_dvd_path\EFI\en-US\efisys_EX.bin to $global:Temp_Media_To_Update_Path\efi\microsoft\boot\
        Write-Dbg-Host "Copying [$ex_dvd_path\EFI\en-US\efisys_EX.bin] to [$global:Temp_Media_To_Update_Path\efi\microsoft\boot\efisys_ex.bin]"
        Copy-Item -Path $ex_dvd_path"\EFI\en-US\efisys_EX.bin" -Destination $global:Temp_Media_To_Update_Path"\efi\microsoft\boot\efisys_ex.bin" -Force -ErrorAction stop | Out-Null

        # Copy $ex_fonts_path\* to $global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts_ex
        Write-Dbg-Host "Copying [$ex_fonts_path\*] to [$global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts_ex]"
        New-Item -ItemType Directory -Path $global:Temp_Media_To_Update_Path"\efi\microsoft\boot\fonts_ex" -Force | Out-Null
        Copy-Item -Path $ex_fonts_path"\*" -Destination $global:Temp_Media_To_Update_Path"\efi\microsoft\boot\fonts_ex\" -Force -ErrorAction stop | Out-Null

        # Rename $global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts_ex\*_EX.ttf to *.ttf
        Write-Dbg-Host "Renaming [$global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts_ex\*_EX.ttf] to [*.ttf]"
        Get-ChildItem -Path $global:Temp_Media_To_Update_Path"\efi\microsoft\boot\fonts_ex" -Filter "*_EX.ttf" | Rename-Item -NewName { $_.Name -replace '_EX', '' } -Force -ErrorAction stop

        # Copy $global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts_ex\* to $global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts
        Write-Dbg-Host "Copying [$global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts_ex\*] to [$global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts]"
        Copy-Item -Path $global:Temp_Media_To_Update_Path"\efi\microsoft\boot\fonts_ex\*" -Destination $global:Temp_Media_To_Update_Path"\efi\microsoft\boot\fonts" -Force -ErrorAction stop | Out-Null

        # Remove $global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts_ex
        Write-Dbg-Host "Removing [$global:Temp_Media_To_Update_Path\efi\microsoft\boot\fonts_ex]"
        Remove-Item -Path $global:Temp_Media_To_Update_Path"\efi\microsoft\boot\fonts_ex" -Recurse -Force -ErrorAction stop | Out-Null

        # Copy boot.stl from the mounted boot.wim to the staged media if not already present
        $bootStlSource = $bootWimMount + "\Windows\Boot\EFI\boot.stl"
        $bootStlDest = $global:Temp_Media_To_Update_Path + "\EFI\Microsoft\Boot\boot.stl"
        if (-not (Test-Path -Path $bootStlSource)) {
            Write-Dbg-Host "[boot.stl] not found in mounted boot.wim at [$bootStlSource]. Skipping."
        } else {
            Write-Dbg-Host "Copying [$bootStlSource] to [$bootStlDest]"
            Copy-Item -Path $bootStlSource -Destination $bootStlDest -Force -ErrorAction stop | Out-Null
        }

    } catch {
        Write-Host "$_" -ForegroundColor Red
        return $false
    }

    if ($global:WIM_Mount_Path) {
        Write-Dbg-Host "Dismounting [$global:WIM_Mount_Path]"
        try {
            Dismount-WindowsImage -Path $global:WIM_Mount_Path -Discard -ErrorAction stop | Out-Null
            try {
                Write-Dbg-Host "Removing WIM mount path [$global:WIM_Mount_Path]"
                Remove-Item -Path $global:WIM_Mount_Path -Recurse -Force -ErrorAction stop | Out-Null
                $global:WIM_Mount_Path = $null
            } catch {
                Write-Host "Failed to remove WIM mount path [$global:WIM_Mount_Path]" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        } catch {
            Write-Host "Failed to dismount WIM [$global:WIM_Mount_Path]" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    return $true
}

function Create-ISOMedia {
    param (
         [string] $ISOPath
     )

     Write-Host "Writing 'Windows UEFI CA 2023' bootable ISO media at location [$ISOPath]" -ForegroundColor Blue

     # If $ISOLabel is not set, then default to "WINDOWS2023PCAISO"
    if (-not $global:ISO_Label) {
        $global:ISO_Label = "WIN2023PCAISO"
    }

    # Generate a timestamp string in the following format: mm/dd/yyyy,hh:mm:ss
    $timestamp = Get-Date -Format "MM/dd/yyyy,HH:mm:ss"

    $runCommand = "-l$global:ISO_Label -t$timestamp -bootdata:2#p0,e,b$global:Temp_Media_To_Update_Path\boot\etfsboot.com#pEF,e,b$global:Temp_Media_To_Update_Path\efi\microsoft\boot\efisys_ex.bin -u2 -udfver102 -o $global:Temp_Media_To_Update_Path `"$($ISOPath)`""

    Write-Dbg-Host "Running [$global:oscdimg_exe $runCommand]"
    try {

        # Extract the directory portion of $ISOPath
        $isoDirPath = Split-Path -Parent $ISOPath

        # Make sure ISO path is valid or the call to oscdimg.exe will fail
        if (-not (Test-Path $isoDirPath)) {
            Write-Dbg-Host "ISOPath [$isoDirPath] not valid. Creating it."
            New-Item -ItemType Directory -Path $isoDirPath -Force | Out-Null
        }

        Write-Dbg-Host "Writing [$ISOPath]"
        Start-Process -FilePath $global:oscdimg_exe -ArgumentList $runCommand -Wait -NoNewWindow -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "Failed to create ISO [$ISOPath]" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }
    return $true
}

function Create-USBMedia {
    param (
         [string] $USBDrive,
         [string] $FileSystem
     )

    Write-Host "Creating 'Windows UEFI CA 2023' bootable USB media on drive [$USBDrive]" -ForegroundColor Blue

    $volume = Get-Volume -DriveLetter $USBDrive.TrimEnd(':')
    $currentLabel = $volume.FileSystemLabel

    if (-not $currentLabel) {
        $currentLabel = "BOOT2023PCA"
    }

    $fileSystem = $FileSystem
    if (-not $FileSystem) {
        $fileSystem = "FAT32"
    }

    # Format the drive using the existing label
    try {
        Write-Dbg-Host "Formatting drive [$USBDrive] as $fileSystem"
        Format-Volume -DriveLetter $USBDrive.TrimEnd(':') -FileSystem $fileSystem -NewFileSystemLabel $currentLabel -Force -ErrorAction stop | Out-Null
    } catch {
        Write-Host "Failed to format drive [$USBDrive] as $fileSystem" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }

    try {
        # If FAT32 and install.wim is larger than 4GB then split it
        if ($fileSystem -eq "FAT32") {
            $installWimPath = $global:Temp_Media_To_Update_Path + "\sources\install.wim"
            if ((Test-Path -Path $installWimPath) -and ((Get-Item -Path $installWimPath).Length -gt 4GB)) {

                Write-Dbg-Host "[$installWimPath] is larger than 4GB, splitting it"
                $installSwmPath = $global:Temp_Media_To_Update_Path + "\sources\install.swm"
                $installSwmSize = 4000
                Write-Host "Updating Media to be FAT32 compatible" -ForegroundColor Blue
                Split-WindowsImage -ImagePath $installWimPath -SplitImagePath $installSwmPath -FileSize $installSwmSize -ErrorAction stop | Out-Null

                # Remove the original install.wim
                Remove-Item -Path $installWimPath -Force -ErrorAction stop | Out-Null
            }
        }

        Write-Dbg-Host "Copying media to USB drive [$USBDrive\]"
        Copy-FilesWithProgress -SourcePath "$global:Temp_Media_To_Update_Path" -DestinationPath "$USBDrive\"
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }

    return $true
}
function Update-LocalMedia {

    # Work here was already done during staging and CopyBins
    Write-Host "Creating 'Windows UEFI CA 2023' bootable local media at location [$global:Temp_Media_To_Update_Path]" -ForegroundColor Blue
    return $true
}

Set-StrictMode -Version Latest

# Global variables
$global:ScriptName = Split-Path -Leaf $PSCommandPath
$global:Src_Media_Path = $null
$global:Staging_Directory_Path = $null
$global:StagingDir_Created = $false
$global:Temp_Media_To_Update_Path = $null
$global:WIM_Mount_Path = $null
$global:ISO_Mount_Path = $null
$global:ISO_Label = $null
$global:oscdimg_exe = $null
$global:oscdimg_known_hashes = @{
    "AMD64" = "ABCD07318EBD8CDBE274B46C9DE78820DCA9709D558CDBC1F5D1730924264D07"
    "ARM64" = "CDAE3649F6A6DE45F50A0B5FB5E2BBC098503B9EEFB1AE6A398FC955B434F579"
    "x86"   = "85AC2DDD96239D037560E5336727F9A8BE2B902734B9DD88264DD7DB5612EFB9"
}
$global:Dbg_Pause = $false
$global:Dbg_Output = $DebugOn

try {
    Write-Host "`r`n`r`nMicrosoft 'Windows UEFI CA 2023' Media Update Script - Version 1.6`r`n" -ForegroundColor DarkYellow

    # First validate that the required tools/environment exist
    $result = Validate-Parameters -TargetType $TargetType -ISOPath $ISOPath -USBDrive $USBDrive -NewMediaPath $NewMediaPath -FileSystem $FileSystem -StagingDir $StagingDir
    if (-not $result) {
        Write-Dbg-Host "Validate-Parameters failed"
        Show-Usage
        exit
    }

    # validate params
    $result = Validate-Requirements -TargetType $TargetType
    if (-not $result) {
        Write-Dbg-Host "Validate-Requirements failed"
        exit
    }

    # Now initialize media path requirements
    $result = Initialize-MediaPaths -MediaPath $MediaPath -NewMediaPath $NewMediaPath -StagingDir $StagingDir
    if (-not $result) {
        Write-Dbg-Host "Initialize-MediaPath failed"
        Execute-Cleanup
        exit
    }

    $result = Copy-2023BootBins
    if (-not $result) {
        Write-Dbg-Host "Copy-2023BootBins failed"
        Execute-Cleanup
        exit
    }

    switch ($TargetType) {
        "ISO" {
            $result = Create-ISOMedia -ISOPath $ISOPath
            if (-not $result) {
                Write-Host "ISO media creation failed" -ForegroundColor Red
            } else {
                if (Test-Path -Path $ISOPath){
                    Write-Host "Successfully created ISO [$ISOPath]" -ForegroundColor Green
                }
            }
        }
        "USB" {
            $result = Create-USBMedia -USBDrive $USBDrive -FileSystem $FileSystem
            if (-not $result) {
                Write-Host "USB media creation failed!" -ForegroundColor Red
                break
            }
            Write-Host "Successfully created media on drive [$USBDrive]" -ForegroundColor Green
            break
        }
        "LOCAL" {

            $result = Update-LocalMedia
            if (-not $result) {
                Write-Host "Local media update failed!" -ForegroundColor Red
                break
            }
            Write-Host "Local media updated successfully at location [$global:Temp_Media_To_Update_Path]" -ForegroundColor Green
            break
        }
        default {
            Write-Host "Invalid TargetType: $TargetType" -ForegroundColor Red
            Show-Usage
            break
        }
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Execute-Cleanup
exit

# SIG # Begin signature block
# MIInFwYJKoZIhvcNAQcCoIInCDCCJwQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCDALKMGx89IOXv
# 01sW02KbJLeJCW/SL4PEkYT8tH3lM6CCDIowggXRMIIDuaADAgECAhMzAAABRE5C
# TIrLAn4rAAAAAAFEMA0GCSqGSIb3DQEBCwUAMFMxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJDAiBgNVBAMTG1dpbmRvd3MgUHJv
# ZHVjdGlvbiBQQ0EgMjAyMzAeFw0yNjA2MTgxODQwMTJaFw0yNzA2MTcxODQwMTJa
# MHAxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xGjAYBgNVBAMT
# EU1pY3Jvc29mdCBXaW5kb3dzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAi8dn4Tf9InhvFYXUVyktdGTydnXMc7vHl7BPHiKTqy3SnephyFxxt04F42Dq
# Sf6+Rpqhnpv8jimLjFdBw6i7gjVSghX9V9ocmtiplNMw517RikeHAsvFk/2lJY+L
# vMLuQ/3+nsKOGJi7HX5r2vJDBpj30lhQnoizYnwqLt1g3aRvupdkS9MgjjMKKtpd
# 6qr5pnACWG9r0CAgFR+sEmNQsqLCf3otnQb+TpRModUnQcH31dZnac5j1bILyNAw
# fq7IR9Xj5Sh5ppBxhag99skmRyAC/iSA2w/U/O/+jks+xcVmHsbqUB8ahyA9mJ4Q
# n7sT+eB3W3/egqCzcVcqBTNyvQIDAQABo4IBfzCCAXswHwYDVR0lBBgwFgYKKwYB
# BAGCNwoDBgYIKwYBBQUHAwMwHQYDVR0OBBYEFA7Md8bVeJ5cHbG+hbJvNhp4n6F+
# MEUGA1UdEQQ+MDykOjA4MR4wHAYDVQQLExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# FjAUBgNVBAUTDTIyOTg3OSs1MDg2NTEwHwYDVR0jBBgwFoAUhu0Lrj9aCdI9HiEZ
# VX+fMVMi+AAwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jcmwvV2luZG93cyUyMFByb2R1Y3Rpb24lMjBQQ0ElMjAyMDIz
# LmNybDBnBggrBgEFBQcBAQRbMFkwVwYIKwYBBQUHMAKGS2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvV2luZG93cyUyMFByb2R1Y3Rpb24lMjBQ
# Q0ElMjAyMDIzLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQAA
# OAZASvjXMaPwMptQOgvOjHoRuhLPj8NaWc6De8z8E9Ky2KlF/cOTbx9Bseqe41Hu
# hA00TSMw+2EsMErAr6rzJeryVjPhKA/9ZeH+oTPbIcg54Ei3feCDpTz5Jjyser8X
# EJvN2vskwVj/aDDnDOq49fFF3z+AzrrltpIqsjhQtRjuPtMF6R+BFIMT+LVt1ZpB
# ZmQuxHl52tAWtgOoBKuLGNwnCiIicshsvp4iUuojgxBV9qjSOWpzwAxm+hSydp1g
# M4C1F8P51ChiZ2/rDFyb5xB5ZsPY3+js5HZRJHD6DKebbawA51ivDlO5P5os8FY+
# 62RmEzv+D34j4V6jQLY85hBSecfIpNeZb3h/DtSadza4JXCp9Vi0gdtPBE9zUJdx
# k6XILlqTcZZFPpUn1TR8kG2M8uByqkddPELnsRm31AKTWLoMsga7IW+n19MTUNdN
# APExiXrsLNm+fV8zvQYMsAfGLFRoFbXw20mboxTX6qoPNZjr+XkzDTAd/EuVugb4
# qktNVGBgeOFRaafYumzvkhiK0fim4b0vo7dS7bpWjuUUBCs0FbN4qfTA6NYzaItq
# HwYpvD/CozKhT0wp5zGHUkhAS7fBWUst9ynevjsrRUmVdezL/gBJ9hcn1+xfGUCH
# K0QcGo/iCoQA7VWx8+KOK9DXYTgMI8gov30GDnhrjDCCBrEwggSZoAMCAQICEzMA
# AAAXhb1WCUv4yCEAAAAAABcwDQYJKoZIhvcNAQEMBQAwgYgxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTIzMDYxMzE4MzQxNVoXDTM1
# MDYxMzE4NDQxNVowUzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEkMCIGA1UEAxMbV2luZG93cyBQcm9kdWN0aW9uIFBDQSAyMDIz
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1S7lCl1ucUvb2kjr3vJi
# IR+MTkab4S1pqVmgM4rAqSd4+4K7dn2GrAzHCC9n2x3AVwbCGobztxrsQORTcKmD
# vNfXknJL0rM+kgId0WUcEOop/FbRxoOqb6+CGAauW4SfeekfvDKfleHx4Zf+jA+S
# 5oJp811VYJfLsM20jqaq4qECmI9nhqK3txUXeEz0bQElNbaEmIN1RzymPiPNFhIS
# hdKlX3gKQsoVZi6Lod6VRm/T4CkQmPvn3bncPC2pfYOIoM6t+tvdPXAy6J2BDhF5
# pYFRobr0vqhVQW8ElewS5EP4HcS1pICNj1qsVRl+Fb5mKj6Z7VCJSSEj6JV4KExp
# aRIGmm5qa6FJvp9zV0zqkN8zdW/S+MS/wKoOzViwLSplK8ZIJI8NF4S9eX+Aolzl
# mA3Oz24FJRX6OJn3gCGwsbxfPpkA1LYKUkitMMalPma7CJZ+NAPcUWKub7MaPaaE
# kAeqNT9RSV6pfdbSEe7m2lD4denZT9lsenAwSH1xgMC3UlEjuOhPwDMLq0ovrXh3
# X+wJV5KfO1EVNXg/lEWKgnBkhO37vaciSKzkaZcGJ8awIPyUPJmcTqK/m2QCIvTO
# rBxrpebzy6GvH6UXPCTO7HG6rsfoc73RhVsqOs40DUeqoOxnw2OYJSzwwUNYdJ38
# ReXxkZDscIqC5B+f7vaL9LsCAwEAAaOCAUYwggFCMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUhu0Lrj9aCdI9HiEZVX+fMVMi+AAw
# GQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNV
# HSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVo
# dHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29D
# ZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAC
# hj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1
# dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG9w0BAQwFAAOCAgEAkTBCaN+E3TyYb8j/
# s05y+5xVmOUQ6nxxuOfjNdHacjWYsrjzFHd5BF6cSHeclTS96EHXFasf8mCSDDbe
# KNeZzwJW5G8H4EJSbftNdrjGA3MlnLehzetEwdkY3SCd0JSQKLfDOBgtbvbB9EUi
# fajAGUuAk3yn/B/DbELmo3P7eRyLr73oigZb97X4HFH55+6FYB1yaUFq0RfwLzfN
# WAwsFiHqpk52d6RambkbyvkAhioSDgtZ27rTVJO2Cun8SnHuBMa+t2HZ3ICJcs0/
# VINBR7WNx96W6clC0+lzUb2SxxsUVwZbNBuhn1m2ZcmD0Q5gmQm8esArgcH9dKyb
# jNQ4pitbZ2WRxwE8CYBXSQHxpyAyaYJLAh0gixfgDU3xj0t5voNXyHsc1JxHSJOQ
# souwhhokr/NyOfYHGuoY1HuoLslZErRrrrjzqYXRwyHQ3EJ0wo+2NefPvN+znS7P
# 9PI6v92SYfq8Ncqh3xe4zq565S3rewdddqpa5c7gw1xhTPhsdMLN928adrUMcw0G
# ubB8HGpsbDiouRPMVdf/oXBrSp8Vu3v+FYzXRHHbi2BRxdX6Snp6+VGJRLI9zOMc
# Re9fYw1FlhNvTTB22+HdgZRVzsqDnoNVRpyEl9kNmJcEXZL9qmslWGENognP2/1K
# YupeZ3wYWFyQqSPNyW9rUHkv13AxghnjMIIZ3wIBATBqMFMxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJDAiBgNVBAMTG1dpbmRv
# d3MgUHJvZHVjdGlvbiBQQ0EgMjAyMwITMwAAAUROQkyKywJ+KwAAAAABRDANBglg
# hkgBZQMEAgEFAKCBsDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEE
# AYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQglMMy7IN1KCM7
# CnnAk2VPIvtUvouoJE2HFGFakr7eZiowRAYKKwYBBAGCNwIBDDE2MDSgFIASAE0A
# aQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20gMA0G
# CSqGSIb3DQEBAQUABIIBAFuTm/u5kFQX14KJBqnSxaP31k0KRsteiuOKrgd5WhX9
# XgQu5YWqVCZ4RfY8pyO9Vi0qBGeQpwoFBujH4m1VRiNr8oBGdgBFI0id59WfbJje
# 2NSNcATYufDMRPLaTvgyaBaAII1JefOQ28ECkB+RnteJk9HyDnLN/d+zDP66jbBW
# d7mkwUK+j2vqRwJk5rYuh2T1HEalKJkuTAwc8JzHKob9a4sEXAhc2iCKCa7dO1aX
# mKqUyEe8GQyhuMssMu3L6WtSaL8fP9CfY4FTm+VJ6RbLGmddBlpiXR50fnaeUgqK
# YE3VtP/jP3rvWNm3TSAvK3xOB5BMRo5h+MnbeCxddg2hgheXMIIXkwYKKwYBBAGC
# NwMDATGCF4Mwghd/BgkqhkiG9w0BBwKgghdwMIIXbAIBAzEPMA0GCWCGSAFlAwQC
# AQUAMIIBUgYLKoZIhvcNAQkQAQSgggFBBIIBPTCCATkCAQEGCisGAQQBhFkKAwEw
# MTANBglghkgBZQMEAgEFAAQgsx98LXLqFEVDm2ybBCH9kEAYbxgfFVw1BM0D1Elv
# HRACBmq39IbbCxgTMjAyNjEwMjcyMzU1MDcuODIxWjAEgAIB9KCB0aSBzjCByzEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWlj
# cm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOjMzMDMtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloIIR7TCCByAwggUIoAMCAQICEzMAAAIhM8A1+9IPIaQAAQAAAiEw
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcN
# MjYwMjE5MTkzOTU0WhcNMjcwNTE3MTkzOTU0WjCByzELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
# T3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjMzMDMtMDVFMC1E
# OTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA23EwAqlNWL0aHMli9jy/X8n//lC7
# Nqiu1NWmbEZw2Up5Qq+yu44AN3hQhCS+QWe3VEwtA3mXqX/mQvuxxGweCHc5iX0A
# FAxRXq6mOVUx5kLz9lwN5VkhY++NInXBlB4JT+R/z2wiVOxgB1j9h3XAo3cdZWAK
# NAPsyyO8cJ00HjMjl19tdhIOFJgzzyYMXUzMOlhVVrAT1kQYuYA4sctrPu0fAA5O
# ZWwQRQweYdAo6zViDe7ggMxeYO7a6y/J1yCqddJo/UcYXBkPrZYbelSL3coEVU1B
# ncxQdv5wbyakPZMcRZbUEk+9HxHceE8miqMP3+fgUoeM+P/X+zVyFVUy5//JHCQH
# 0ahZka6xbdyCm8u1a85mLqEFg9JZjRbRkOewayZD6zxQD3pNQC7XG2+xR950Kb4v
# J4M/zBV//nJ5jRVhVNvVVS5swfV7y2cW2L5HnrbdJoeZX7XnjdqxMFMq3ayrn8/Y
# dkuqW2rXvgtodNgq18EpGtMens6U5hpCCSxbdubm/1GFzS3R3bMRg+hH3JDiKCWL
# JuDEvRf70qizRyvPSNL0ywZ4EBKeiyBZCDWp0U9z7Tcd6TSkSiUQC3Oi+poVuIS+
# Ghy++Paj30O9reagDJucYimDICdlmp4nUSzbiNudSSDe62mngP9r29FxZGXCG00d
# aX0BrHKOFNIObY8CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBTmIyLOamuqX7qrj8si
# tRU6+UAwpzAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8E
# WDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9N
# aWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmwwbAYIKwYB
# BQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
# cGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEw
# KDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4G
# A1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAOCP925HZ08Q9qxbptzBf
# MVSnRJKIQDm23j60PtH6+W0Ypo8/bFZCk/+4HI+DjHApUmBviHV+jKdxGLCx1n47
# 8H8xaHmRPsk23QY/9VR2UEbgpsOkKnlQk28Np50u5wcZ1nfaGV2z1KahGsB+Q6l0
# GlhYEfQOCllSvyL11QzI9T5TwhEtT9yaJzW3YZJJM+PaybijpuW+3vwR/JaKgJlz
# l0XNtssVlUzFqxKeKbJZr/Hk+1aGPF/43SmEz1RF7H5i21RXKszLgfLxRn1MlrFk
# TkvMIKu5UGH1nGKoezcpqAE1/sFmCt81hu2kXIjxlAM8513X/mh7SFp0CzWuRxZk
# l5ImpN30rqa1mGYh4bmIxNeoa6AKXAR6ZvvEv5DaoZvVo0F/tgcZ2L/iXo8upak4
# vHywS0tOvVl1cP6bX+SFfhbWJd+Br1aHoN9VKFJlVWXtUg1CZJvXQ13PJf6gQ2Ig
# CE9ggrD08rfVwPSVbh8XT+t5+wob1gDv+O0Ebgg7FJRSaFsMgcJe43mKWkVTLULd
# IriTBho4BGiV9UP9o/LF1Eb03Hixww/YqVrdPdmQ1jEHIg0ZoRzRTl9XZ4wb5P5N
# VDHIPfe4+aGM5wJ0qSb5YP+AT92lRNIf2B9ioLCm1ODV2RwIyV49kpaqNQtdeQhu
# qgWWhZDPFurz2Qpuap0nszowggdxMIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAA
# AAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBB
# dXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMyMjVaMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1V/YB
# f2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9alKD
# RLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus
# 9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN7928jaTj
# kY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56
# KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74kpEeHT39
# IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHo
# vwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5TI4CvEJo
# LhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMh
# XV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9QBXpsxREd
# cu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3PmriLq0CAwEA
# AaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFCqn
# Uv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJlpxtTNRnp
# cjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0w
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEw
# CwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/o
# olxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNy
# b3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYt
# MjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5j
# cnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+
# TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpTTd2Y
# urYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM9W0jVOR4
# U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJ
# w7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4FOmRsqlb
# 30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ
# /gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPXfx5bRAGO
# WhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFE
# fnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGConsXHRWJ
# jXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rR
# nj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUz
# WLOhcGbyoYIDUDCCAjgCAQEwgfmhgdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
# ZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjozMzAzLTA1RTAtRDk0
# NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcG
# BSsOAwIaAxUAC2xIGWZ8mB1ydQxm+Xxo6ZV6bbmggYMwgYCkfjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAO6LS6MwIhgPMjAy
# NjEwMjcxNjExMTVaGA8yMDI2MTAyODE2MTExNVowdzA9BgorBgEEAYRZCgQBMS8w
# LTAKAgUA7otLowIBADAKAgEAAgIJvQIB/zAHAgEAAgIRmzAKAgUA7oydIwIBADA2
# BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIB
# AAIDAYagMA0GCSqGSIb3DQEBCwUAA4IBAQAWkBq6EP6orWLb6YwDn3oujjI5+bdF
# HYwsS/iGcKXSg4FV55fmvtKp/C/llFv3t1FXlTgqMZe8cXpD4NO5LOx+S+HJi0Vk
# +v6suggVkWdG9/a51tCuf50tIEGxkUnSRsPtGVRfV/XjyjVDuJImMZoUcWT2PARj
# rj42TEUugcxvgH9rrb55ExhBIqYnqHBtEia5BD0jUlRfuIO8YdB3IJZcEEClGvnf
# 0uoQ7NFv7CoJcSuesGzZI4pYy/WRciDHbyrr0ymT6lI5q6LqAvFrC4VNDGyH2ft4
# IsuqdKcJBMnMnvHYACdUDd4AeFW3sDjpee4xF2s+jEzVnSDK9g27sa7AMYIEDTCC
# BAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
# MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAIhM8A1
# +9IPIaQAAQAAAiEwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsq
# hkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgHsuhQzBH+DU2IVhKa30bhVrnQr2/
# 6ydlbmeoRG6fwmEwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAA7yEHnxVV
# GuAScvCGcsDAL5hkinVFahJsvQPvjwo9RDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwAhMzAAACITPANfvSDyGkAAEAAAIhMCIEIMhp7X1NP2Dw
# RvrXjUQFwQPPqIXShQJSVXjvrArDObeQMA0GCSqGSIb3DQEBCwUABIICAI7ZkhQR
# FpidEBLjJ0uYBLfYZpMKWQ1pHabfeuOEDOw4ameYz4hahhzimjChGqHmGk/ACjHG
# NlOEhJYIvBSoT9LUTTaWJ4mlRuESXq6IAjtGfdC0V4bMwUEs7kWThEbiwZLmZkhS
# Cx25hwY613kodDY9TZGgBaNmDzrBQsGxUw97Yc8jesVNYGXRyXkJxP74cYQH1px6
# SAygnlaDiAVf/3FZPKEmPmkUOTv8aLQ3oEZKM36m1m0kTgZNw06pSJBsHFFKmrUA
# Ez2AIYCctB3UyQcv8d4FW9FMipMMTx28B0N0ZLknlCWHV5jRuV58FAhGffArG5AI
# 8oXL3GHuNUZIJYbaIhqIFmceEATYtYGvuxtmEKOhR61ulkIMI0/xqjYgjtSfMv5v
# 3QOfNheeRw49romM2LOsQ4wJkDiVDUla2bqf64F53MReHlaOGgEAPiecqZcPWJzE
# oaf3iKT5BKphvouGWIIU2BFIsvRhkkMu5Z46kjjIv99dYP46ESXmKIUb7rJvlgED
# /PPLsqddG7hk9V2P9beepiLZvIeTV0Xk0Vsww7RbFxf/KtfJFa99FCjDK8oWcCcx
# RgWgWnTGtCN9phMjaHsm07sKBts5KU3ZCJ4QgiZEVBYLOG3oWwJFyO2NsnM/fbqn
# oY5ARvZKC+WSqSgt9S+NcRnJ4L5deSsD9uIn
# SIG # End signature block
