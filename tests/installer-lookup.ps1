# Pull Test-ReleaseTag and Get-LatestRelease out of install.ps1 and run them for real.
# Usage: pwsh -File lookup-test.ps1 <path to install.ps1>
param([Parameter(Mandatory)][string]$Script)
$ErrorActionPreference = 'Stop'
$Repo = 'https://github.com/ScientiaCapital/epiphan-edge-claude-kit'
$text = Get-Content -Raw $Script
$start = $text.IndexOf('function Test-ReleaseTag')
$end = $text.IndexOf('function Set-Ref')
if ($start -lt 0 -or $end -lt 0) { throw 'could not find the lookup functions in install.ps1' }
Invoke-Expression $text.Substring($start, $end - $start)

$failures = 0
function Check($Name, $Ok, $Detail) {
    if ($Ok) { Write-Host "ok   $Name  ($Detail)" } else { Write-Host "FAIL $Name  ($Detail)"; $script:failures++ }
}

# 1. Tag shape check.
Check 'accepts v1.1.5' (Test-ReleaseTag 'v1.1.5') ''
foreach ($bad in '../../evil', 'v1;calc', 'main/../x', '', $null, 'main') {
    Check "refuses '$bad'" (-not (Test-ReleaseTag $bad)) ''
}

# 2. Normal path: the API answers.
$tag = Get-LatestRelease
Check 'API path returns a release tag' (Test-ReleaseTag $tag) "$tag"

# 3. Rate-limited path: the API base is dead, so only the release page can answer.
$tag2 = Get-LatestRelease 'http://127.0.0.1:9'
Check 'release page answers when the API is down' (Test-ReleaseTag $tag2) "$tag2"
Check 'both ways agree on the latest release' ($tag -eq $tag2) "$tag vs $tag2"

if ($failures) { exit 1 }
