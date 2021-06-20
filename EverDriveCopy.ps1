<#
    .SYNOPSIS
        Organize and copy rom files.

    .DESCRIPTION
        This script is used to copy ROM files from a sourced folder onto a destined folder with an
        more orginized folder structure that catered towards easier use of an EverDrive flash cart.

    .EXAMPLE
        EverDriveCopy.ps1 -Path C:\Data\ROMs -TargetPath F:\
        Copies all rom files from C:\Data\ROMs onto drive F

    .EXAMPLE
        EverDriveCopy.ps1 -Path C:\Data\ROMs\Famicom -TargetPath F:\ROMs
        Copies and group ROMs files located in the Famicom folder onto F:\ROMs
#>
param (
    # Determine folder that contains files that are to be copied
    [Parameter(Mandatory = $true)]
    [string[]]$Path,
    
    # Determine destination folder
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,
    
    # Exclude platform sub-folder
    [switch]$NoPlatform
)

enum Broadcast { NTSC; PAL }
enum Region { Japan; USA; Europe; Australia }

# ---------------------------------------------------------------------------------------
#   FUNCTIONS
# ---------------------------------------------------------------------------------------
function Get-BroadcastTypeFromFileName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )
    
    switch -Regex ($FileName) {
        '(\([JKU145]\))'    { $broadcastType = [Broadcast]::NTSC; break }
        '(\([ABCEFGIS8]\))' { $broadcastType = [Broadcast]::PAL; break }
        '(\(UK\))'          { $broadcastType = [Broadcast]::PAL; break }
        '(\(SW\))'          { $broadcastType = [Broadcast]::PAL; break }
        '(\(NL\))'          { $broadcastType = [Broadcast]::PAL; break }
        '(\(FN\))'          { $broadcastType = [Broadcast]::PAL; break }
        '(\(HK\))'          { $broadcastType = [Broadcast]::PAL; break }
        '(\(GR\))'          { $broadcastType = [Broadcast]::PAL; break }
        '(\(PAL\))'         { $broadcastType = [Broadcast]::PAL; break }
        '(\(NTSC\))'        { $broadcastType = [Broadcast]::NTSC; break }
        '(\([JU][JU]\))'    { $broadcastType = [Broadcast]::NTSC; break }
    }

    $broadcastType
}

function Get-RegionFromFileName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\([U4]\))'    { $region = [Region]::USA; break }
        '(\([J1]\))'    { $region = [Region]::Japan; break }
        '(\([EFGS]\))'  { $region = [Region]::Europe; break }
        '(\(A\))'       { $region = [Region]::Australia; break }
    }

    $region
}

function New-RomFileName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$File
    )

    $newExtension = $File.Extension.ToLower()
    $newBaseName = $File.BaseName.Trim() `
        -replace '^The ','' `
        -replace ', The','' `
        -replace '\(Europe\)','(E)' `
        -replace '\(England\)','(UK)' `
        -replace '\(USA\)','(U)' `
        -replace '\(Japan\)','(J)' `
        -replace '\(China\)','(C)' `
        -replace '\(Hong Kong\)','(HK)' `
        -replace '\(Netherlands\)','(NL)' `
        -replace '\(Spain\)','(S)' `
        -replace '\(Sweden\)','(SW)' `
        -replace '\(Greece\)','(GR)' `
        -replace '\(Public Domain\)','(PD)' `
        -replace '\(Unlicensed\)','(Unl)'

    New-Object PSObject -Property @{
        BaseName    = $newBaseName
        Extension   = $newExtension
        Name        = "{0}{1}" -f $newBaseName, $newExtension
    }
}

function New-SubFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Name
    )

    switch -Regex ($Name) {
        '(\(BIOS\))'    { $subFolder = '_BIOS'; break }
        '(\(PD\))'      { $subFolder = '_Public Domain'; break }
        '(\(Unl\))'     { $subFolder = '_Unlicensed'; break }
        '^[a-dA-D]'     { $subFolder = "[A-D]"; break }
        '^[e-hE-H]'     { $subFolder = "[E-H]"; break }
        '^[i-lI-L]'     { $subFolder = "[I-L]"; break }
        '^[m-pM-P]'     { $subFolder = "[M-P]"; break }
        '^[q-tQ-T]'     { $subFolder = "[Q-T]"; break }
        '^[u-zU-Z]'     { $subFolder = "[U-Z]"; break }
        default         { $subFolder = "[#]"; break }
    }

    $subFolder
}

function New-PlatformFolder {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Extension,
        [Parameter(Mandatory = $true)]
        [string]$BaseName
    )

    switch ($Extension) {
        ".fds"      { $folderName = "Famicom Disk System"; break }
        ".gb"       { $folderName = "Game Boy"; break }
        ".gbc"      { $folderName = "Game Boy Color"; break }
        ".gba"      { $folderName = "Game Boy Advance"; break }
        ".gg"       { $folderName = "Game Gear"; break }
        ".smd"      { $folderName = $BaseName | New-MegaDriveFolderName; break }
        ".gen"      { $folderName = $BaseName | New-MegaDriveFolderName; break }
        ".bin"      { $folderName = $BaseName | New-MegaDriveFolderName; break }        
        ".nes"      { $folderName = $BaseName | New-FamicomFolderName; break }
        ".pce"      { $folderName = $BaseName | New-PCEngineFolderName; break }
        ".sms"      { $folderName = $BaseName | New-MasterSystemFolderName; break }
        ".sfc"      { $folderName = "Super Famicom"; break }
        ".smc"      { $folderName = $BaseName | New-SuperFamicomFolderName; break }
        ".z64"      { $folderName = $BaseName | New-Nintendo64FolderName; break }
        default     { $folderName = "Other"; break }
    }

    $folderName
}

function New-FamicomFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\(PC10\))' { 
            $folderName = "PlayChoice-10"
            break
        }

        '(\(VS\))' { 
            $folderName = "Nintendo VS System"
            break
        }

        default {
            switch ($FileName | Get-RegionFromFileName) {
                'Japan' { 
                    $folderName = "Famicom"
                    break
                }

                default {
                    switch ($FileName | Get-BroadcastTypeFromFileName) {
                        'NTSC'  { $folderName = "NES (NTSC)"; break }
                        'PAL'   { $folderName = "NES (PAL)"; break }
                        default { $folderName = "NES"; break }
                    }
                }
            }
        }
    }

    $folderName
}

function New-PCEngineFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\(SGX\))' { 
            $folderName = "SuperGrafx"
            break
        }

        default {
            switch ($FileName | Get-RegionFromFileName) {
                'USA'       { $folderName = "TurboGrafx-16"; break }
                'Europe'    { $folderName = "TurboGrafx"; break }
                default     { $folderName = "PC Engine"; break }
            }
        }
    }

    $folderName
}

function New-MasterSystemFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch ($FileName | Get-RegionFromFileName) {
        'Japan' { 
            $folderName = "Mark III"
            break
        }

        default {
            switch ($FolderName | Get-BroadcastTypeFromFileName) {
                'NTSC'  { $folderName = "Master System (NTSC)"; break }
                'PAL'   { $folderName = "Master System (PAL)"; break }
                default { $folderName = "Master System"; break }
            }
        }
    }

    $folderName
}

function New-Nintendo64FolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch ($FileName | Get-BroadcastTypeFromFileName) {
        'NTSC'      { $folderName = "Nintendo 64 (NTSC)"; break }
        'PAL'       { $folderName = "Nintendo 64 (PAL)"; break }
        default     { $folderName = "Nintendo 64"; break }
    }

    $folderName
}

function New-MegaDriveFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        'BIOS' { 
            $folderName = "_BIOS"
            break 
        }

        '32X' { 
            $folderName = "32X"
            break
        }
        
        default {
            switch ($FileName | Get-RegionFromFileName) {
                'USA' { 
                    $folderName = "Genesis"
                    break 
                }

                default {
                    switch ($FileName | Get-BroadcastTypeFromFileName) {
                        'NTSC'  { $folderName = "Mega Drive (NTSC)"; break }
                        'PAL'   { $folderName = "Mega Drive (PAL)"; break }
                        default { $folderName = "Mega Drive"; break }
                    }
                }
            }

            break
        }
    }

    $folderName
}

function New-SuperFamicomFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch ($FileName | Get-RegionFromFileName) {
        'Japan' { 
            $folderName = "Super Famicom"
            break 
        }

        default {
            switch ($FileName | Get-BroadcastTypeFromFileName) {
                'NTSC'  { $folderName = "SNES (NTSC)"; break }
                'PAL'   { $folderName = "SNES (PAL)"; break }
                default { $folderName = "SNES"; break }
            }
        }
    }

    $folderName
}

function Get-RomFilePaths {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    process {
        $files = @()
        $filter = @(
            "*.fds", "*.gb", "*.gbc", "*.gba", "*.gen", "*.gg", "*.nes", "*.pce", "*.sfc",
            "*.smd", "*.smc", "*.sms", "*.z64", "*.bin"
        )

        Get-ChildItem -Path $Path -Recurse -Include $filter | ForEach-Object {
            $file = $_ | New-RomFileName

            if ($NoPlatform) {
                $targetDir = $Target
            } else {
                $folderName = New-PlatformFolder -Extension $file.Extension -BaseName $file.BaseName
                $targetDir = Join-Path -Path $Target -ChildPath $folderName
            }

            $targetFile = Join-Path -Path ($file.BaseName | New-SubFolderName) -ChildPath $file.Name
        
            $fileMember = New-Object PSObject -Property @{
                Dest    = Join-Path -Path $targetDir -ChildPath $targetFile
                Source  = $_.FullName
            }
        
            $files += $fileMember
        }

        $files | Sort-Object -Property Dest | Select-Object -Property Source, Dest -Unique
    }
}

# ---------------------------------------------------------------------------------------
#   MAIN
# ---------------------------------------------------------------------------------------
try {
    Get-RomFilePaths -Path $Path -Target $TargetPath | ForEach-Object {
        $destDir = Split-Path -Path $_.Dest -Parent
    
        if (!(Test-Path -LiteralPath $destDir)) {
            New-Item $destDir -Type Directory
        }
    
        Write-Verbose "$(Split-Path $_.Source -Leaf)  >>  $destDir"
        Copy-Item -LiteralPath $_.Source -Destination $_.Dest -Force
    }
}
catch {
    Write-Host "The following error has occurred:"
    Write-Host $_
}
