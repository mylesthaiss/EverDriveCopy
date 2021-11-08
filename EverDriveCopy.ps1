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

$excludedGroupDirs = @(
    "4 Betas", "4 Demos", "5 BIOS", "4 Betas & Prototypes", "4 Bootlegs", "3 Satellaview",
    "3 SuFami Turbo", "3 NSS", "3 SuperGrafx", "3 Sega 32X", "3 PlayChoice-10", "3 Nintendo VS System",
    "5 Tools & Tests", "3 SARA Super Chip", "2 Other Regions", "2 Korea", "3 AES", "3 MVS"
)

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
        '(\[T[\-\+]Cat.*\])'    { $folderName = 'Catalan'; break }
        '(\[T[\-\+]Chi.*\])'    { $folderName = 'Chinese'; break }
        '(\[T[\-\+]Eng.*\])'    { $folderName = 'English'; break }
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
        ".a26"      { $folderName = $BaseName | New-BroadcastFormatFolder; break }
        ".col"      { $folderName = $BaseName | New-BroadcastFormatFolder; break }
        ".fds"      { $folderName = "3 Famicom Disk System"; break }
        ".32x"      { $folderName = "3 Sega 32X"; break }
        ".neo"      { $folderName = $BaseName | New-NeoGeoFolderName; break }
        ".nes"      { $folderName = $BaseName | New-FamicomFolderName; break }
        ".pce"      { $folderName = $BaseName | New-PCEngineFolderName; break }
        ".sc"       { $folderName = "3 SARA Super Chip"; break }
        ".sgx"      { $folderName = "3 SuperGrafx"; break }
        ".sfc"      { $folderName = $BaseName | New-SuperFamicomFolderName; break }
        ".smc"      { $folderName = $BaseName | New-SuperFamicomFolderName; break }
        default     { $folderName = $BaseName | New-RegionFolder; break }
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
            $folderName = "3 PlayChoice-10"
            break
        }

        '(\(VS\))' { 
            $folderName = "3 Nintendo VS System"
            break
        }

        default {
            $folderName = $FileName | New-RegionFolder
            break
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
            $folderName = "3 SuperGrafx"
            break
        }

        default {
            $folderName = $FileName | New-RegionFolder
            break
        }
    }

    $folderName
}

function New-NeoGeoFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -Regex ($FileName) {
        '(\(U\))'   { $folderName = '2 USA'; break }
        '(\(J\))'   { $folderName = '2 Japan'; break }
        '(\(E\))'   { $folderName = '2 Europe'; break }
        '(\(K\))'   { $folderName = '2 Korea'; break }
        '(\(MVS\))' { $folderName = '3 MVS'; break }
        '(\(AES\))' { $folderName = '3 AES'; break }
        default     { $folderName = '1 World'; break }
    }

    $folderName
}

function New-SuperFamicomFolderName {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FileName
    )

    switch -regex ($FileName) {
        '(\(NSS\))'     { $folderName = "3 NSS"; break }
        '(\(BS\))'      { $folderName = "3 Satellaview"; break }
        '^BS '          { $folderName = "3 Satellaview"; break }
        '(\(ST\))'      { $folderName = "3 SuFami Turbo"; break }

        default {
            $folderName = $FileName | New-RegionFolder
            break
        }
    }

    $folderName
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
        'USA'               { $folderName = "1 USA"; break }
        'USEurope'          { $folderName = "1 USA"; break }
        'JapanUS'           { $folderName = "1 USA"; break }
        'World'             { $folderName = "1 USA"; break }
        'USEuropeKorea'     { $folderName = "1 USA"; break }
        'USAus'             { $folderName = "1 USA"; break }
        'USBrazil'          { $folderName = "1 USA"; break }
        'USKorea'           { $folderName = "1 USA"; break }
        'USEuropeBrazil'    { $folderName = "1 USA"; break }
        'Europe'            { $folderName = "2 Europe"; break }
        'EuropeBrazil'      { $folderName = "2 Europe"; break }
        'EuropeKorea'       { $folderName = "2 Europe"; break }
        'Japan'             { $folderName = "2 Japan"; break }
        'JapanBrazil'       { $folderName = "2 Japan"; break }
        'JapanEurope'       { $folderName = "2 Japan"; break }
        'JapanKorea'        { $folderName = "2 Japan"; break }
        'JapanEuropeKorea'  { $folderName = "2 Japan"; break }
        'JapanEuropeBrazil' { $folderName = "2 Japan"; break }
        'JapanUSBrazil'     { $folderName = "2 Japan"; break }
        default             { $folderName = "2 Other Regions"; break }
    }

    $folderName
}

function New-BroadcastFormatFolder {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $FileName
    )

    switch ($FileName | Get-BroadcastTypeFromFileName) {
        'NTSC'  { $folderName = "1 NTSC"; break }
        'PAL'   { $folderName = "2 PAL"; break }
        default { $folderName = "3 Unknown"; break }
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
            "*.sgx", "*.sc"
        )

        Get-ChildItem -Path $Path -Recurse -Include $filter | ForEach-Object {
            $file = $_ | New-RomFileName

            switch -Regex ($file.BaseName) {
                'BIOS'                  { $folderName = "5 BIOS"; break }
                '^ Test'                { $folderName = "5 Tools & Tests"; break }
                '(\(PD\))'              { $folderName = "4 Public Domain"; break }
                '(\(Bootleg\))'         { $folderName = "4 Bootlegs"; break }
                '(\(Bootleg .*\))'      { $folderName = "4 Bootlegs"; break }
                '(\[p[0-9].*\])'        { $folderName = "4 Bootlegs"; break }
                '(\(Unl\))'             { $folderName = "4 Unlicensed"; break }
                '(\(Sachen\))'          { $folderName = "4 Unlicensed"; break }
                '(\(Beta\))'            { $folderName = "4 Prototypes & Betas"; break }
                '(\(Beta .*\))'         { $folderName = "4 Prototypes & Betas"; break }
                '(\(Beta\-.*\))'        { $folderName = "4 Prototypes & Betas"; break }
                '(\(Pre-release\))'     { $folderName = "4 Prototypes & Betas"; break }
                '(\(Proto\))'           { $folderName = "4 Prototypes & Betas"; break }
                '(\(Prototype\))'       { $folderName = "4 Prototypes & Betas"; break }
                '(\(Prototype [0-9]\))' { $folderName = "4 Prototypes & Betas"; break }
                '(\[T[\-\+].*\])'       { $folderName = "4 Translations"; break }
                '(\(Demo\))'            { $folderName = "4 Demos"; break }
                ' Demo$'                { $folderName = "4 Demos"; break }
                '(\[t[0-9].*\])'        { $folderName = "4 Hacks & Trainers"; break }
                '(\[h[0-9].*\])'        { $folderName = "4 Hacks & Trainers"; break }
                '(\(Hack\))'            { $folderName = "4 Hacks & Trainers"; break }
                '(\(Hack .*\))'         { $folderName = "4 Hacks & Trainers"; break }
                '(\(.* Hack\))'         { $folderName = "4 Hacks & Trainers"; break }
                ' Patched$'             { $folderName = "4 Hacks & Trainers"; break }

                default {
                    if ($NoPlatform) {
                        $folderName = $file.BaseName | New-RegionFolder
                    } else {
                        $folderName = New-PlatformFolder -Extension $file.Extension -BaseName $file.BaseName
                    }
                    
                    break
                }
            }

            if ($excludedGroupDirs -notcontains $folderName) {
                if ($folderName -eq '4 Translations') {
                    $subFolder = $file.BaseName | New-LanguageSubFolderName
                } else {
                    $subFolder = $file.BaseName | New-SubFolderName
                }

                $targetFile = Join-Path -Path $subFolder -ChildPath $file.Name
            } else {
                $targetFile = $file.Name
            }

            $targetDir = Join-Path -Path $Target -ChildPath $folderName

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
