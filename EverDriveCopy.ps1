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
    [string]$Path,
    
    # Determine destination folder
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,
    
    # Exclude platform sub-folder
    [switch]$NoPlatform
)

# ---------------------------------------------------------------------------------------
#   FUNCTIONS
# ---------------------------------------------------------------------------------------
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
        '(\(PC10\))'    { $folderName = "PlayChoice-10"; break }
        '(\(VS\))'      { $folderName = "Nintendo VS System"; break }
        '(\(J\))'       { $folderName = "Famicom"; break }
        '(\(U\))'       { $folderName = "NES (NTSC)"; break }
        '(\(E\))'       { $folderName = "NES (PAL)"; break }
        default         { $folderName = "NES"; break }
    }

    $folderName
}

function New-PCEngineFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\(SGX\))'     { $folderName = "SuperGrafx"; break }
        '(\(U\))'       { $folderName = "TurboGrafx-16"; break }
        default         { $folderName = "PC Engine"; break }
    }

    $folderName
}

function New-MasterSystemFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\([JU]\))'    { $folderName = "Master System (NTSC)"; break }
        '(\(E\))'       { $folderName = "Master System (PAL)"; break }
        default         { $folderName = "Master System"; break }
    }

    $folderName
}

function New-Nintendo64FolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\([JU]\))'    { $folderName = "Nintendo 64 (NTSC)"; break }
        '(\(E\))'       { $folderName = "Nintendo 64 (PAL)"; break }
        default         { $folderName = "Nintendo 64"; break }
    }

    $folderName
}

function New-MegaDriveFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        'BIOS'          { $folderName = "_BIOS"; break }
        '32X'           { $folderName = "32X"; break }
        '(\(U\))'       { $folderName = "Genesis"; break }
        '(\(E\))'       { $folderName = "Mega Drive (PAL)"; break }
        '(\(J\))'       { $folderName = "Mega Drive (NTSC)"; break }
        default         { $folderName = "Mega Drive"; break }
    }

    $folderName
}

function New-SuperFamicomFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\(J\))'       { $folderName = "Super Famicom"; break }
        '(\(U\))'       { $folderName = "SNES (NTSC)"; break }
        '(\(E\))'       { $folderName = "SNES (PAL)"; break }
        default         { $folderName = "SNES"; break }
    }

    $folderName
}

function Get-RomFilePaths {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    process {
        $files = @()
        $filter = @(
            "*.fds", "*.gb", "*.gbc", "*.gba", "*.gen", "*.gg", "*.nes", "*.pce", "*.sfc",
            "*.smd", "*.smc", "*.sms", "*.z64", "*.bin"
        )
        $targetFiles = Get-ChildItem -Path $Path -Recurse -Include $filter        
        
        foreach ($file in $targetFiles) {
            if ($NoPlatform) {
                $targetDir = $Target
            } else {
                $folderName = New-PlatformFolder -Extension $file.Extension -BaseName $file.BaseName
                $targetDir = Join-Path -Path $Target -ChildPath $folderName
            }            
                      
            $targetFile = Join-Path -Path ($file.BaseName | New-SubFolderName) -ChildPath $file.Name
        
            $fileMember = New-Object PSObject -Property @{
                Dest = Join-Path -Path $targetDir -ChildPath $targetFile
                Source = $file.FullName
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
