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
enum Region {
    Japan; USA; Europe; Australia; World; USEurope; JapanEurope; Korea; JapanUS; Brazil;
    USEuropeKorea; USKorea; USAus; JapanKorea; EuropeBrazil; EuropeKorea; JapanUSKorea;
    JapanBrazil; JapanEuropeKorea; JapanEuropeBrazil; JapanUSBrazil; USEuropeBrazil; USBrazil
}

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
        '(\(A\))'           { $broadcastType = [Broadcast]::PAL; break }
        '(\(I\))'           { $broadcastType = [Broadcast]::PAL; break }
        '(\(G\))'           { $broadcastType = [Broadcast]::PAL; break }
        '(\(PAL\))'         { $broadcastType = [Broadcast]::PAL; break }
        '(\(PAL60\))'       { $broadcastType = [Broadcast]::PAL; break }
        '(\(NTSC\))'        { $broadcastType = [Broadcast]::NTSC; break }
        '(\([JU][JU]\))'    { $broadcastType = [Broadcast]::NTSC; break }
        '(\(K\))'           { $broadcastType = [Broadcast]::NTSC; break }
        '(\(CN\))'          { $broadcastType = [Broadcast]::NTSC; break }
        '(\(FC\))'          { $broadcastType = [Broadcast]::NTSC; break }
        '(\(R\))'           { $broadcastType = [Broadcast]::PAL; break }
        '(\(W\))'           { $broadcastType = [Broadcast]::NTSC; break }
        '(\([UE][UE]\))'    { $broadcastType = [Broadcast]::NTSC; break }
        ' PAL60$'           { $broadcastType = [Broadcast]::PAL; break }
        ' NTSC$'            { $broadcastType = [Broadcast]::NTSC; break }
    }

    $broadcastType
}

function Get-RegionFromFileName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\([U4]\))'            { $region = [Region]::USA; break }
        '(\([J1]\))'            { $region = [Region]::Japan; break }
        '(\([EFGSI]\))'         { $region = [Region]::Europe; break }
        '(\(SW\))'              { $region = [Region]::Europe; break }
        '(\(GR\))'              { $region = [Region]::Europe; break }
        '(\(A\))'               { $region = [Region]::Australia; break }
        '(\([JUE][JUE][JUE]\))' { $region = [Region]::World; break }
        '(\(W\))'               { $region = [Region]::World; break }
        '(\([UE][UE]\))'        { $region = [Region]::USEurope; break }
        '(\([JE][JE]\))'        { $region = [Region]::JapanEurope; break }
        '(\(K\))'               { $region = [Region]::Korea; break }
        '(\([JU][JU]\))'        { $region = [Region]::JapanUS; break }
        '(\(B\))'               { $region = [Region]::Brazil; break }
        '(\([UEK][UEK][UEK]\))' { $region = [Region]::USEuropeKorea; break }
        '(\([UK][UK]\))'        { $region = [Region]::USKorea; break }
        '(\([UA][UA]\))'        { $region = [Region]::USAus; break }
        '(\([UB][UB]\))'        { $region = [Region]::USBrazil; break }
        '(\([JK][JK]\))'        { $region = [Region]::JapanKorea; break }
        '(\([JB][JB]\))'        { $region = [Region]::JapanBrail; break }
        '(\([EB][EB]\))'        { $region = [Region]::EuropeBrazil; break }
        '(\([EK][EK]\))'        { $region = [Region]::EuropeKorea; break }
        '(\([UEB][UEB][UEB]\))' { $region = [Region]::USEuropeBrazil; break }
        '(\([JEK][JEK][JEK]\))' { $region = [Region]::JapanEuropeKorea; break }
        '(\([JEB][JEB][JEB]\))' { $region = [Region]::JapanEuropeBrazil; break }
        '(\([JUB][JUB][JUB]\))' { $region = [Region]::JapanUSBrazil; break }
    }

    $region
}

function Join-PlatformPaths {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Platform,
        [Parameter(Mandatory = $true)]
        [string]$SubFolder
    )

    if ($NoPlatform) {
        $SubFolder
    } else {
        Join-Path -Path $Platform -ChildPath $SubFolder
    }
}

function New-FolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Name,
        [int16]$Index = 1
    )

    $folderName = "{0} {1}" -f ([string]$Index).PadLeft(2,'0'), $Name
    $folderName
}

function New-RomFileName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$File
    )

    $newBaseName = $File.BaseName.Trim() `
        -replace "`'",'' `
        -replace '^The ','' `
        -replace ', The','' `
        -replace ' \[[CM]\]','' `
        -replace '\(Unenc\)','(Unencrypted)' `
        -replace '\(bootleg\)','(Bootleg)' `
        -replace '\(Proto\)','(Prototype)' `
        -replace '\(Australia\)','(A)' `
        -replace '\(Canada\)','(CN)' `
        -replace '\(Europe\)','(E)' `
        -replace '\(England\)','(UK)' `
        -replace '\(Italy\)','(I)' `
        -replace '\(USA\)','(U)' `
        -replace '\(Japan\)','(J)' `
        -replace '\(Ch\)','(C)' `
        -replace '\(China\)','(C)' `
        -replace '\(Hong Kong\)','(HK)' `
        -replace '\(Netherlands\)','(NL)' `
        -replace '\(Spain\)','(S)' `
        -replace '\(Sweden\)','(SW)' `
        -replace '\(Sw\)','(SW)' `
        -replace '\(Germany\)','(G)' `
        -replace '\(Greece\)','(GR)' `
        -replace '\(Public Domain\)','(PD)' `
        -replace '\(Unlicensed\)','(Unl)' `
        -replace '\(World\)','(W)' `
        -replace '\(USA, Brazil\)','(UB)' `
        -replace '\(USA, Europe\)','(UE)' `
        -replace '\(Europe, USA\)','(UE)' `
        -replace '\(EU\)','(UE)' `
        -replace '\(Brazil\)','(B)' `
        -replace '\(Japan, Brazil\)','(JB)' `
        -replace '\(Japan, Europe\)','(JE)' `
        -replace '\(Japan, Europe, Brazil\)','(JEB)' `
        -replace '\(Japan, USA, Brazil\)','(JUB)' `
        -replace '\(Europe, Japan\)','(JE)' `
        -replace '\(Korea\)','(K)' `
        -replace '\(Japan, USA\)','(JU)' `
        -replace '\(USA, Japan\)','(JU)' `
        -replace '\(France\)','(F)' `
        -replace '\(US\)','(U)' `
        -replace '\(USA, Europe, Korea\)','(UEK)' `
        -replace '\(USA, Europe, Brazil\)','(UEB)' `
        -replace '\(Japan, Korea\)','(JK)' `
        -replace '\(USA, Korea\)','(UK)' `
        -replace '\(USA, Australia\)','(UA)' `
        -replace '\(Europe, Brazil\)','(EB)' `
        -replace '\(Brazil, Europe\)','(EB)' `
        -replace '\(Europe, Korea\)','(EK)' `
        -replace '\(Japan, Europe, Korea\)','(JEK)' `
        -replace '\(Mexico\)','(M)' `
        -replace '\]\[','] [' `
        -replace '\)\(',') (' `
        -replace '\)\[',') [' `
        -replace '\]\(','] ('

    $newExtension = $File.Extension | New-FileExtension -BaseFile $newBaseName

    New-Object PSObject -Property @{
        BaseName    = $newBaseName
        Extension   = $newExtension
        Name        = "{0}{1}" -f $newBaseName, $newExtension
    }
}

function New-FileExtension {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileExtension,
        [Parameter(Mandatory = $true)]
        [string]$BaseFile
    )

    switch -Regex ($BaseFile) {
        '32X' {
            $newFileExtension = ".32x"
            break
        }

        '(\(SGX\))' {
            $newFileExtension = ".sgx"
            break
        }

        default {
            switch ($FileExtension.ToLower()) {
                ".bin"  { $newFileExtension = $BaseFile | New-MegaDriveFileExt -FileExt $FileExtension; break }
                ".md"   { $newFileExtension = $BaseFile | New-MegaDriveFileExt -FileExt $FileExtension; break }
                ".gen"  { $newFileExtension = $BaseFile | New-MegaDriveFileExt -FileExt $FileExtension; break }
                ".smc"  { $newFileExtension = $BaseFile | New-SuperFamicomFileExt -FileExt $FileExtension; break }
                ".sfc"  { $newFileExtension = $BaseFile | New-SuperFamicomFileExt -FileExt $FileExtension; break }
                default { $newFileExtension = $FileExtension.ToLower(); break }
            }
        }
    }

    $newFileExtension
}

function New-SubFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Name
    )

    switch -Regex ($Name -replace "'",'' -replace '([\(\)\[\]])','') {
        '^[0-9a-bA-B]'  { $subFolder = "[#-B]"; break }
        '^[c-eC-E]'     { $subFolder = "[C-E]"; break }
        '^[f-hF-H]'     { $subFolder = "[F-H]"; break }
        '^[i-kI-K]'     { $subFolder = "[I-K]"; break }
        '^[l-nL-N]'     { $subFolder = "[L-N]"; break }
        '^[o-pO-P]'     { $subFolder = "[O-P]"; break }
        '^[q-sQ-S]'     { $subFolder = "[Q-S]"; break }
        '^[t-vT-V]'     { $subFolder = "[T-V]"; break }
        '^[w-zW-Z]'     { $subFolder = "[W-Z]"; break }
    }

    $subFolder
}

function New-LanguageSubFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Name
    )

    switch -Regex ($Name) {
        '([\[ ]T[\-\+]Cat.*\])' { $folderName = 'Catalan'; break }
        '(\[T[\-\+]Chi.*\])'    { $folderName = 'Chinese'; break }
        '([\[ ]T[\-\+]Eng.*\])' { $folderName = 'English'; break }
        '(\[T[\-\+]Bra.*\])'    { $folderName = 'Brazilian Portuguese'; break }
        '(\[T[\-\+]Dan.*\])'    { $folderName = 'Danish'; break }
        '(\[T[\-\+]Dut.*\])'    { $folderName = 'Dutch'; break }
        '(\[T[\-\+]Fin.*\])'    { $folderName = 'Finnish'; break }
        '(\[T[\-\+]Fre.*\])'    { $folderName = 'French'; break }
        '(\[T[\-\+]Ger.*\])'    { $folderName = 'German'; break }
        '(\[T[\-\+]Gre.*\])'    { $folderName = 'Greek'; break }
        '(\[T[\-\+]Hun.*\])'    { $folderName = 'Hungarian'; break }
        '(\[T[\-\+]Ita.*\])'    { $folderName = 'Italian'; break }
        '(\[T[\-\+]Kor.*\])'    { $folderName = 'Korean'; break }
        '(\[T[\-\+]Nor.*\])'    { $folderName = 'Norwegian'; break }
        '(\[T[\-\+]Pol.*\])'    { $folderName = 'Polish'; break }
        '(\[T[\-\+]Por.*\])'    { $folderName = 'Portuguese'; break }
        '(\[T[\-\+]Rus.*\])'    { $folderName = 'Russian'; break }
        '(\[T[\-\+]Spa.*\])'    { $folderName = 'Spanish'; break }
        '(\[T[\-\+]Swe.*\])'    { $folderName = 'Swedish'; break }
        '(\[T[\-\+]Thai.*\])'   { $folderName = 'Thai'; break }
        default                 { $folderName = 'Other'; break }
    }

    $folderName
}

function New-PlatformFolder {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Extension,
        [Parameter(Mandatory = $true)]
        [string]$BaseName
    )

    switch ($Extension) {
        ".sfc"  { $_ = ".smc" }
        ".md"   { $_ = ".gen" }
        ".bin"  { $_ = ".gen" }
        ".gbc"  { $_ = ".gb" }
        ".ngc"  { $_ = ".ngp" }

        ".a26" {
            $folderName = $BaseName | New-PlatformColourFormatFolderStrut -Platform "Atari 2600" -SubIndex 4
            break
        }

        ".sc" {
            $folderName = "Atari 2600" | Join-PlatformPaths -SubFolder ("SARA Super Chip" | New-FolderName -Index 3)
            break
        }

        ".a52" {
            $platform = "Atari 5200"

            if ($BaseName -like "*(XL Conversion)*") {
                $folderName = $platform | Join-PlatformPaths -SubFolder ("Atari XL Conversions" | New-FolderName -Index 3)
            } else {
                $folderName = $BaseName | New-PlatformColourFormatFolderStrut -Platform $platform -SubIndex 4
            }
        }

        ".a78" {
            $folderName = $BaseName | New-PlatformColourFormatFolderStrut -Platform "Atari 7800" -SubIndex 3
            break
        }

        ".j64" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "Atari Jaguar" -SubIndex 4
            break
        }

        ".col" {
            $folderName = $BaseName | New-PlatformColourFormatFolderStrut -Platform "ColecoVision"
            break
        }

        ".nes" {
            $folderName = $BaseName | New-FamicomFolderName
            break
        }

        ".fds" {
            $subFolder = Join-Path -Path ("Famicom Disk System" | New-FolderName -Index 4) -ChildPath ($BaseName | New-SubFolderName)
            $folderName = "NES" | Join-PlatformPaths -SubFolder $subFolder
            break
        }

        ".sms" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "Master System" -SubIndex 4
            break
        }

        ".gg" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "Game Gear" -SubIndex 4
            break
        }

        ".gen" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "Mega Drive" -SubIndex 5
            break
        }

        ".32x" {
            $folderName = "Mega Drive" | Join-PlatformPaths -SubFolder ("Sega 32X" | New-FolderName -Index 4)
            break
        }

        ".neo" {
            $folderName = $BaseName | New-NeoGeoFolderName
            break
        }

        ".smc" {
            $folderName = $BaseName | New-SuperFamicomFolderName
            break
        }

        ".crt" {
            $platform = "Commodore 64" | Join-PlatformPaths -SubFolder ("Cartridge" | New-FolderName -Index 1)
            $folderName = Join-Path -Path $platform -ChildPath ($BaseName | New-SubFolderName)
            break
        }

        ".d64" {
            $platform = "Commodore 64" | Join-PlatformPaths -SubFolder ("Disk" | New-FolderName -Index 2)
            $folderName = Join-Path -Path $platform -ChildPath ($BaseName | New-SubFolderName)
            break
        }

        ".crt" {
            $platform = "Commodore 64" | Join-PlatformPaths -SubFolder ("Tape" | New-FolderName -Index 3)
            $folderName = Join-Path -Path $platform -ChildPath ($BaseName | New-SubFolderName)
            break
        }

        ".ssd" {
            $folderName = Join-Path -Path "BBC Micro" -ChildPath ($BaseName | New-SubFolderName)
            break
        }

        ".adf" {
            $folderName = "Acorn Archimedes"
            break
        }

        ".gb" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "Game Boy"
            break
        }

        ".gba" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "Game Boy Advance"
            break
        }

        ".pce" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "PC Engine" -SubIndex 4
            break
        }

        ".sgx" {
            $folderName = "PC Engine" | Join-PlatformPaths -SubFolder ("SuperGrafx" | New-FolderName -Index 3)
            break
        }

        ".z64" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "Nintendo 64" -SubIndex 4
            break
        }

        ".ngp" {
            $folderName = $BaseName | New-PlatformRegionFolderStrut -Platform "Neo Geo Pocket" -SubIndex 4 -NoGroup
            break;
        }

        default {
            $folderName = $BaseName | New-RegionFolder
            break
        }
    }

    $folderName
}

function New-PlatformRegionFolderStrut {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName,
        [Parameter(Mandatory = $true)]
        [string]$Platform,
        [int]$SubIndex = 3,
        [switch]$NoGroup
    )

    $subFolder = $FileName | New-CategorySubFolder -Index $SubIndex

    if ($null -eq $subFolder) {
        if ($NoGroup) {
            $subFolder = ($FileName | New-RegionFolder)
        } else {
            $subFolder = Join-Path ($FileName | New-RegionFolder) -ChildPath ($FileName | New-SubFolderName)
        }
    }

    if ($NoPlatform) {
        $subFolder
    } else {
        Join-Path -Path $Platform -ChildPath $subFolder
    }
}

function New-PlatformColourFormatFolderStrut {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName,
        [Parameter(Mandatory = $true)]
        [string]$Platform,
        [int16]$SubIndex = 3
    )

    $subFolder = $FileName | New-CategorySubFolder -Index $SubIndex

    if ($null -eq $subFolder) {
        $subFolder = Join-Path ($FileName | New-BroadcastFormatFolder) -ChildPath ($FileName | New-SubFolderName)
    }

    if ($NoPlatform) {
        $subFolder
    } else {
        Join-Path -Path $Platform -ChildPath $subFolder
    }
}

function New-FamicomFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    $subFolder = $FileName | New-CategorySubFolder -Index 7

    if ($null -eq $subFolder) {
        switch -Regex ($FileName) {
            '(\(VS\))' {
                $subFolder = "Nintendo VS System" | New-FolderName -Index 5
                break
            }

            '(\(PC10\))' {
                $subFolder = "PlayChoice-10" | New-FolderName -Index 6
                break
            }

            default {
                $subFolder = Join-Path -Path ($FileName | New-RegionFolder) -ChildPath ($FileName | New-SubFolderName)
                break
            }
        }
    }

    if ($NoPlatform) {
        $subFolder
    } else {
        Join-Path -Path "NES" -ChildPath $subFolder
    }
}

function New-NeoGeoFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\(U\))'   { $folderName = 'USA' | New-FolderName -Index 2; break }
        '(\(J\))'   { $folderName = 'Japan' | New-FolderName -Index 2; break }
        '(\(E\))'   { $folderName = 'Europe' | New-FolderName -Index 2; break }
        '(\(K\))'   { $folderName = 'Korea' | New-FolderName -Index 2; break }
        '(\(MVS\))' { $folderName = 'MVS' | New-FolderName -Index 3; break }
        '(\(AES\))' { $folderName = 'AES' | New-FolderName -Index 3; break }
        default     { $folderName = 'World' | New-FolderName -Index 1; break }
    }

    $folderName
}

function New-SuperFamicomFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    $subFolder = $FileName | New-CategorySubFolder

    if ($null -ne $subFolder) {
        switch -regex ($FileName) {
            '(\(NSS\))' { $subFolder = "NSS" | New-FolderName -Index 4; break }
            '(\(BS\))'  { $subFolder = "Satellaview" | New-FolderName -Index 5; break }
            '^BS '      { $subFolder = "Satellaview" | New-FolderName -Index 5; break }
            '(\(ST\))'  { $subFolder = "SuFami Turbo" | New-FolderName -Index 6; break }
            default     { $subFolder = $FileName | New-RegionFolder; break }
        }
    }

    if ($NoPlatform) {
        $subFolder
    } else {
        Join-Path "SNES" -ChildPath $subFolder
    }
}

function New-MegaDriveFileExt {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $FileName,
        [Parameter(Mandatory = $true)]
        $FileExt
    )

    switch ($FileName | Get-RegionFromFileName) {
        'Japan'             { $fileExt = ".bin"; break }
        'JapanEurope'       { $fileExt = ".bin"; break }
        'JapanUS'           { $fileExt = ".bin"; break }
        'JapanKorea'        { $fileExt = ".bin"; break }
        'JapanEuropeKorea'  { $fileExt = ".bin"; break }
        'USA'               { $fileExt = ".gen"; break }
        'USEurope'          { $fileExt = ".gen"; break }
        'USEuropeKorea'     { $fileExt = ".gen"; break }
        'USKorea'           { $fileExt = ".gen"; break }
        'USAus'             { $fileExt = ".gen"; break }
        'World'             { $fileExt = ".bin"; break }
        'Europe'            { $fileExt = ".md"; break }
        'EuropeBrazil'      { $fileExt = ".md"; break }
        'EuropeKorea'       { $fileExt = ".md"; break }
        default             { $fileExt = $FileExt.ToLower(); break }
    }

    $fileExt
}

function New-SuperFamicomFileExt {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $FileName,
        [Parameter(Mandatory = $true)]
        $FileExt
    )

    switch ($FileName | Get-RegionFromFileName) {
        'Japan'         { $fileExt = ".sfc"; break }
        'JapanKorea'    { $fileExt = ".sfc"; break }
        'USA'           { $fileExt = ".smc"; break }
        'World'         { $fileExt = ".smc"; break }
        'Europe'        { $fileExt = ".smc"; break }
        default         { $fileExt = $FileExt.ToLower(); break }
    }

    $fileExt
}

function New-RegionFolder {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $FileName
    )

    switch ($file.BaseName | Get-RegionFromFileName) {
        'USEurope'          { $_ = "USA" }
        'JapanUS'           { $_ = "USA" }
        'World'             { $_ = "USA" }
        'USEuropeKorea'     { $_ = "USA" }
        'USAus'             { $_ = "USA" }
        'USBrazil'          { $_ = "USA" }
        'USKorea'           { $_ = "USA" }
        'USEuropeBrazil'    { $_ = "USA" }
        'JapanBrazil'       { $_ = "Japan" }
        'JapanEurope'       { $_ = "Japan" }
        'JapanKorea'        { $_ = "Japan" }
        'JapanEuropeKorea'  { $_ = "Japan" }
        'JapanEuropeBrazil' { $_ = "Japan" }
        'JapanUSBrazil'     { $_ = "Japan" }
        'EuropeBrazil'      { $_ = "Europe" }
        'EuropeKorea'       { $_ = "Europe" }
        'USA'               { $folderName = "USA" | New-FolderName -Index 1; break }
        'Japan'             { $folderName = "Japan" | New-FolderName -Index 2; break }
        'Europe'            { $folderName = "Europe" | New-FolderName -Index 3; break }
        default             { $folderName = "Other Regions" | New-FolderName -Index 3; break }
    }

    $folderName
}

function New-CategorySubFolder {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $FileName,
        [int]$Index = 3
    )

    $folderName = $null
    
    switch -regex ($FileName) {
        '(\(Beta\))'            { $_ = "#Prototype" }
        '(\(Beta .*\))'         { $_ = "#Prototype" }
        '(\(Beta\-.*\))'        { $_ = "#Prototype" }
        '(\(Pre-release\))'     { $_ = "#Prototype" }
        '(\(Proto\))'           { $_ = "#Prototype" }
        '(\(Prototype\))'       { $_ = "#Prototype" }
        '(\(Prototype [0-9]\))' { $_ = "#Prototype" }

        '#Prototype' {
            $folderName = "Prototypes & Betas" | New-FolderName -Index $Index
            $folderName = Join-Path -Path $folderName -ChildPath ($FileName | New-SubFolderName)
            break
        }

        '(\[T[\-\+].*\])' {
            $folderName = "Translations" | New-FolderName -Index ($Index + 1)
            $folderName = Join-Path -Path $folderName -ChildPath ($FileName | New-LanguageSubFolderName)
            break
        }

        '(\[t[0-9].*\])'    { $_ = "#Hack" }
        '(\[h[0-9].*\])'    { $_ = "#Hack" }
        '(\(Hack\))'        { $_ = "#Hack" }
        '(\(Hack .*\))'     { $_ = "#Hack" }
        '(\(.* Hack\))'     { $_ = "#Hack" }
        ' Patched$'         { $_ = "#Hack" }

        '#Hack' {
            $folderName = "Hacks & Trainers" | New-FolderName -Index ($Index + 2)
            $folderName = Join-Path -Path $folderName -ChildPath ($FileName | New-SubFolderName)
            break
        }

        '(\(Bootleg\))'     { $_ = "#Bootleg" }
        '(\(Bootleg .*\))'  { $_ = "#Bootleg" }
        '(\[p[0-9].*\])'    { $_ = "#Bootleg" }

        '#Bootleg' {
            $folderName = "Bootlegs" | New-FolderName -Index ($Index + 3)
            break
        }

        '(\(Unl\))'     { $_ = "#Unlicensed" }
        '(\(Sachen\))'  { $_ = "#Unlicensed" }

        '#Unlicensed' {
            $folderName = "Unlicensed" | New-FolderName -Index ($Index + 4)
            $folderName = Join-Path -Path $folderName -ChildPath ($FileName | New-SubFolderName)
            break
        }

        '(\(PD\))' {
            $folderName = "Public Domain" | New-FolderName -Index ($Index + 5)
            $folderName = Join-Path -Path $folderName -ChildPath ($FileName | New-SubFolderName)
            break
        }

        '(\(Demo\))'    { $_ = "#Demo" }
        ' Demo$'        { $_ = "#Demo" }
        '(\(Sample\))'  { $_ = "#Demo" }

        '#Demo' {
            $folderName = "Demos & Samples" | New-FolderName -Index ($Index + 6)
            break
        }

        '^ Test'    { $folderName = "Tools & Tests" | New-FolderName -Index ($Index + 7); break }
        'BIOS'      { $folderName = "BIOS" | New-FolderName -Index ($Index + 8); break }
    }

    $folderName
}

function New-BroadcastFormatFolder {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $FileName
    )

    switch ($FileName | Get-BroadcastTypeFromFileName) {
        'NTSC'  { $folderName = "NTSC" | New-FolderName -Index 1; break }
        'PAL'   { $folderName = "PAL" | New-FolderName -Index 2; break }
        default { $folderName = "Unknown" | New-FolderName -Index 3; break }
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
            "*.a26", "*.col", "*.fds", "*.gb", "*.gbc", "*.gba", "*.gen", "*.gg", "*.nes",
            "*.pce", "*.sfc", "*.smc", "*.sms", "*.z64", "*.bin", "*.md", "*.32x", "*.neo",
            "*.sgx", "*.sc", "*.lnx", "*.j64", "*.jag", "*.crt", "*.d64", "*.tap", "*.adf",
            "*.ssd", "*.a52", "*.a78", "*.ngp", "*.ngc"
        )

        Get-ChildItem -Path $Path -Recurse -Include $filter | ForEach-Object {
            $file = $_ | New-RomFileName

            $folderName = New-PlatformFolder -Extension $file.Extension -BaseName $file.BaseName

            $targetDir = Join-Path -Path $TargetPath -ChildPath $folderName

            $fileMember = New-Object PSObject -Property @{
                Dest    = Join-Path -Path $targetDir -ChildPath $file.Name
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
