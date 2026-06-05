# Patch SolLib.Tests.Mobile.dproj Deployment section with library resource deploy entries.
# Sources: SolLib/src/Resources/WordLists.rc and Normalization.rc (RC symbol + file path).
# Covers Android64, iOSDevice64, iOSSimARM64 for Debug and Release.
#
# Usage:
#   .\sync-mobile-library-resources.ps1
#
# Re-run when library .rc files change or after regenerating the mobile .dproj from template.
# Then rebuild/deploy so SolLib.Tests.Mobile.deployproj is refreshed by the IDE.

param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$DprojName = "SolLib.Tests.Mobile.dproj"
)

$DelphiTestsDir = Join-Path $RepoRoot "SolLib.Tests\Delphi.Tests"
$LibResourcesDir = Join-Path $RepoRoot "SolLib\src\Resources"
$DprojPath = Join-Path $DelphiTestsDir $DprojName

$RcFiles = @(
    (Join-Path $LibResourcesDir "WordLists.rc"),
    (Join-Path $LibResourcesDir "Normalization.rc")
)

if (-not (Test-Path $DprojPath)) {
    Write-Error "Mobile dproj not found: $DprojPath"
    exit 1
}

function Parse-RcEntries([string]$RcPath) {
    if (-not (Test-Path $RcPath)) {
        Write-Error "RC file not found: $RcPath"
        exit 1
    }
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($line in Get-Content $RcPath) {
        if ($line -match '^\s*([A-Z0-9_]+)\s+RCDATA\s+"(.+)"\s*$') {
            $symbol = $Matches[1]
            $rel = $Matches[2] -replace '/', '\'
            $localName = "..\..\SolLib\src\Resources\$rel"
            $entries.Add([PSCustomObject]@{
                Symbol = $symbol
                LocalName = $localName
            })
        }
    }
    return $entries
}

# One DeployFile per platform (Delphi Deployment manager expects independent rows per remote path).
$PlatformDeploy = @(
    @{ Name = 'Android64';     RemoteDir = 'assets\internal\SolLib' },
    @{ Name = 'iOSDevice64';   RemoteDir = 'StartUpDocuments\SolLib' },
    @{ Name = 'iOSSimARM64';   RemoteDir = 'StartUpDocuments\SolLib' }
)

function New-DprojDeployFileBlock {
    param(
        [string]$LocalName,
        [string]$Configuration,
        [string]$PlatformName,
        [string]$RemoteDir,
        [string]$RemoteName
    )
    $ln = $LocalName.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
    $rd = $RemoteDir.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
    $rn = $RemoteName.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
    return @"
                <DeployFile LocalName="$ln" Configuration="$Configuration" Class="File">
                    <Platform Name="$PlatformName">
                        <RemoteDir>$rd</RemoteDir>
                        <RemoteName>$rn</RemoteName>
                        <Overwrite>true</Overwrite>
                    </Platform>
                </DeployFile>
"@
}

$allEntries = New-Object System.Collections.Generic.List[object]
foreach ($rc in $RcFiles) {
    foreach ($e in (Parse-RcEntries $rc)) {
        $allEntries.Add($e)
    }
}

if ($allEntries.Count -eq 0) {
    Write-Error "No RCDATA entries found in library .rc files."
    exit 1
}

$sorted = $allEntries | Sort-Object Symbol
$blocks = New-Object System.Collections.Generic.List[string]
foreach ($entry in $sorted) {
    foreach ($config in @('Debug', 'Release')) {
        foreach ($plat in $PlatformDeploy) {
            [void]$blocks.Add((New-DprojDeployFileBlock `
                -LocalName $entry.LocalName `
                -Configuration $config `
                -PlatformName $plat.Name `
                -RemoteDir $plat.RemoteDir `
                -RemoteName $entry.Symbol))
        }
    }
}
$generatedBlock = ($blocks -join "`r`n") + "`r`n"
$deployFileCount = $blocks.Count

$dprojText = [System.IO.File]::ReadAllText($DprojPath)

# Remove existing library resource DeployFile blocks (re-run safe).
$dprojText = $dprojText -replace '(?s)\s*<!-- BEGIN sync-mobile-library-resources\.ps1 -->.*?<!-- END sync-mobile-library-resources\.ps1 -->\s*', "`r`n"
$dprojText = $dprojText -replace '(?s)<DeployFile LocalName="\.\.\\\.\.\\SolLib\\src\\Resources\\[^"]*"[^>]*>.*?</DeployFile>\s*', ''
# Collapse runs of blank lines introduced by removals.
$dprojText = $dprojText -replace '(\r?\n){3,}', "`r`n`r`n"

# Insert before the first DeployClass in the Deployment section.
$insertPattern = '(?s)(<Deployment Version="5">.*?)(\s*<DeployClass Name=")'
if ($dprojText -notmatch $insertPattern) {
    Write-Error "Could not find Deployment/DeployClass anchor in $DprojPath"
    exit 1
}

$dprojText = [regex]::Replace(
    $dprojText,
    $insertPattern,
    { param($m) $m.Groups[1].Value + "`r`n" + $generatedBlock + $m.Groups[2].Value },
    1
)

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($DprojPath, $dprojText, $utf8NoBom)

Write-Host "Patched $DprojPath with $($sorted.Count) library resources x 2 configs x 3 platforms ($deployFileCount DeployFile blocks)."
Write-Host "One DeployFile per platform (Android64 / iOSDevice64 / iOSSimARM64). Rebuild/deploy to refresh SolLib.Tests.Mobile.deployproj."
