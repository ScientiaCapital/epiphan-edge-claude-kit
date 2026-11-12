# One-line installer for the Epiphan Edge x Claude Code kit (Windows PowerShell 5.1+ or PowerShell 7).
#   irm https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.ps1 | iex
# Safe to re-run. Installs Git for Windows and Claude Code if they're missing, downloads this kit
# into ~\epiphan-edge-claude-kit, points it at your Epiphan region, then opens Claude Code.
# Optional: EPIPHAN_KIT_DIR (folder), EPIPHAN_REGION (na, eu or au),
# EPIPHAN_KIT_REF (a tag, branch or commit; default: the latest release, never the tip of main).
# Everything runs inside a script block and uses 'return', never 'exit', so a problem can't close your window.

& {
    # Not 'Stop': in Windows PowerShell 5.1 that turns any stderr from git or claude into a fatal error.
    # Native commands are checked with $LASTEXITCODE; the cmdlets that must not fail use -ErrorAction Stop.
    $ErrorActionPreference = 'Continue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $Repo = 'https://github.com/ScientiaCapital/epiphan-edge-claude-kit'
    $Clone = if ($env:EPIPHAN_KIT_CLONE) { $env:EPIPHAN_KIT_CLONE } else { "$Repo.git" }  # override is only for CI tests
    $Dir = if ($env:EPIPHAN_KIT_DIR) { $env:EPIPHAN_KIT_DIR } else { Join-Path $HOME 'epiphan-edge-claude-kit' }
    $Marker = '.epiphan-kit'  # left in folders that were downloaded without git
    $DefaultUrl = 'https://go.epiphan.cloud/mcp'
    $Ref = $env:EPIPHAN_KIT_REF

    function Say($Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
    function Problem($Message) { Write-Host "`nProblem: $Message" -ForegroundColor Red }
    function Has($Command) { [bool](Get-Command $Command -ErrorAction SilentlyContinue) }
    function Update-Path {
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                    [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
                    (Join-Path $HOME '.local\bin')
    }
    # The tag ends up in a download URL and a git ref, so anything that isn't shaped like v1.2.3 is refused.
    function Test-ReleaseTag($Tag) { [bool]($Tag -and ([string]$Tag) -match '^v?[0-9][A-Za-z0-9._-]*$') }
    # Two ways to learn the latest release tag. GitHub's API allows 60 requests an hour per address, which a school
    # network behind one address can use up, so the second way reads the redirect from the release page, which isn't
    # counted against that limit. -ApiBase exists so a test can point the first way at an address that fails.
    function Get-LatestRelease($ApiBase = 'https://api.github.com') {
        $tag = $null
        try { $tag = (Invoke-RestMethod "$ApiBase/repos/ScientiaCapital/epiphan-edge-claude-kit/releases/latest" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop).tag_name }
        catch { $tag = $null }
        if (Test-ReleaseTag $tag) { return $tag }
        $tag = $null
        try {
            # Don't follow the redirect: its address names the tag. Windows PowerShell 5.1 throws on it, PowerShell 7 may not.
            $location = $null
            try {
                $page = Invoke-WebRequest "$Repo/releases/latest" -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 15 -ErrorAction Stop
                $location = [string]$page.Headers['Location']
            } catch {
                $response = $_.Exception.Response
                if ($response) {
                    $location = if ($response.Headers.Location) { [string]$response.Headers.Location } else { [string]$response.Headers['Location'] }
                }
            }
            if ($location -match '/releases/tag/([^/\s?#]+)') { $tag = $Matches[1] }
        } catch { $tag = $null }
        if (Test-ReleaseTag $tag) { return $tag }
        return $null
    }
    function Set-Ref($Folder) {  # switch an existing clone to $Ref (a tag, branch or commit)
        git -C $Folder fetch --quiet --depth 1 origin $Ref
        if ($LASTEXITCODE -eq 0) { git -C $Folder checkout --quiet --detach FETCH_HEAD }
        return ($LASTEXITCODE -eq 0)
    }
    function Get-Zip {
        $zip = Join-Path ([IO.Path]::GetTempPath()) 'epiphan-edge-claude-kit.zip'
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ('epiphan-kit-' + [guid]::NewGuid())
        $want = if ($Ref) { $Ref } else { 'main' }
        Invoke-WebRequest "$Repo/archive/$want.zip" -OutFile $zip -UseBasicParsing -ErrorAction Stop
        Expand-Archive $zip -DestinationPath $tmp -ErrorAction Stop
        New-Item -ItemType Directory -Force $Dir -ErrorAction Stop | Out-Null
        # Copy over, so your own files (like .claude\settings.local.json) stay.
        $inner = Get-ChildItem $tmp -Directory -Filter 'epiphan-edge-claude-kit-*' -ErrorAction Stop | Select-Object -First 1
        Copy-Item (Join-Path $inner.FullName '*') $Dir -Recurse -Force -ErrorAction Stop
        Remove-Item $zip, $tmp -Recurse -Force
        Set-Content -Path (Join-Path $Dir $Marker) -Value $want -ErrorAction Stop
    }

    Say 'Step 1 of 5: Git for Windows (needed for the kit''s safety checks and for updates)'
    if (Has git) {
        Write-Host "Already installed: $(git --version)"
    } elseif (Has winget) {
        Write-Host 'Installing Git for Windows with winget (Windows may ask for permission)...'
        winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        Update-Path
    }
    if (-not (Has git)) {
        Write-Warning 'Git for Windows is not installed. The kit still works, and every change still asks you first,'
        Write-Warning 'but its extra safety hooks need Git. Install it from https://git-scm.com/downloads/win, then re-run this.'
    }
    # jq lets the kit hide stream keys from Claude (.claude\hooks\epiphan-redact.sh). Optional.
    if (-not (Has jq) -and (Has winget)) {
        Write-Host 'Installing jq with winget (it hides stream keys, the passwords that let a device stream, from Claude)...'
        winget install --id jqlang.jq -e --source winget --accept-package-agreements --accept-source-agreements *> $null
        if ($LASTEXITCODE -ne 0) { Write-Warning "winget couldn't install jq (exit code $LASTEXITCODE). Run  winget install jqlang.jq  to see why." }
        Update-Path
    }
    if (-not (Has jq)) {
        Write-Warning 'jq is not installed. Until it is, results that may contain stream keys are withheld from Claude.'
        Write-Warning 'Install it with: winget install jqlang.jq'
    }

    Say 'Step 2 of 5: Claude Code'
    if (Has claude) {
        Write-Host "Already installed: $(claude --version). Checking for updates..."
        claude update *> $null
        if ($LASTEXITCODE -ne 0) { Write-Host "(Couldn't check for updates. That's OK, carrying on.)" }
    } else {
        Write-Host "Installing Claude Code with Anthropic's official installer..."
        # Separate process, so nothing in the official installer can end this script early.
        powershell -NoProfile -ExecutionPolicy Bypass -Command 'irm https://claude.ai/install.ps1 | iex'
        Update-Path
        if (-not (Has claude)) {
            Problem "Claude Code installed, but this window can't find it yet. Close PowerShell, open a new one, and paste the install line again."
            return
        }
    }

    Say 'Step 3 of 5: The kit'
    # The published kit is installed at its latest release, so a re-run never picks up unreviewed changes on main.
    # If the release can't be looked up, stop: main is installed only when EPIPHAN_KIT_REF=main is set on purpose.
    if (-not $Ref -and -not $env:EPIPHAN_KIT_CLONE) {
        $Ref = Get-LatestRelease
        if (-not $Ref) {
            Problem ("Couldn't look up the latest release of the kit on GitHub (tried its API and its release page), so nothing was installed or changed. " +
                     'Check your internet connection, wait a few minutes (GitHub limits how often it can be asked), then paste the install line again. ' +
                     'To install the newest unreleased files on main instead, run  $env:EPIPHAN_KIT_REF = ''main''  first (EPIPHAN_KIT_REF=main).')
            return
        }
    }
    $origin = ''
    if ((Test-Path (Join-Path $Dir '.git')) -and (Has git)) { $origin = (git -C $Dir remote get-url origin 2>$null) }
    if ($origin -and ($origin -replace '\.git$', '') -eq ($Clone -replace '\.git$', '')) {
        Write-Host "Found it in $Dir. Updating..."
        if ($Ref) {
            if (-not (Set-Ref $Dir)) { Write-Host "Couldn't update to $Ref (did you change files?). Keeping your copy as is." }
        } else {
            git -C $Dir pull --ff-only --quiet
            if ($LASTEXITCODE -ne 0) { Write-Host "Couldn't update (did you change files?). Keeping your copy as is." }
        }
    } elseif (Test-Path (Join-Path $Dir $Marker)) {
        Write-Host "Found it in $Dir. Updating..."
        try { Get-Zip } catch { Write-Host "Couldn't update ($($_.Exception.Message)). Keeping your copy as is." }
    } elseif (Test-Path $Dir) {
        Problem "$Dir already exists but isn't this kit. Rename that folder, then paste the install line again."
        return
    } elseif (Has git) {
        git clone --quiet --depth 1 $Clone $Dir
        if ($LASTEXITCODE -ne 0) {
            Problem 'The download failed. Check your internet connection, then paste the install line again.'
            return
        }
        if ($Ref -and -not (Set-Ref $Dir)) {
            Problem "Couldn't fetch $Ref. Check EPIPHAN_KIT_REF, then paste the install line again."
            return
        }
        Write-Host "Downloaded to $Dir"
    } else {
        try { Get-Zip } catch {
            Problem "The download failed ($($_.Exception.Message)). Check your internet connection, then paste the install line again."
            return
        }
        Write-Host "Downloaded to $Dir"
    }
    $version = $Ref
    if (-not $version -and (Test-Path (Join-Path $Dir '.git')) -and (Has git)) { $version = (git -C $Dir describe --tags --always 2>$null) }
    elseif (-not $version -and (Test-Path (Join-Path $Dir $Marker))) { $version = (Get-Content (Join-Path $Dir $Marker) -ErrorAction SilentlyContinue | Select-Object -First 1) }
    if (-not $version) { $version = 'main' }
    Write-Host "Kit version: $version"

    Say 'Step 4 of 5: Your Epiphan region'
    $region = $env:EPIPHAN_REGION
    if (-not $region -and -not $env:CI) {
        Write-Host "Where is your Epiphan Edge account? Check the web address you sign in at. (Not sure? Press Enter for 1.)"
        Write-Host '  1) North America  (go.epiphan.cloud)'
        Write-Host '  2) Europe         (eu.epiphan.cloud)'
        Write-Host '  3) Australia      (au.epiphan.cloud)'
        $choice = Read-Host 'Type 1, 2 or 3 and press Enter [1]'
        $region = switch ($choice) { '2' { 'eu' } '3' { 'au' } default { 'na' } }
    }
    if (-not $region) {
        # No one to ask (CI) and no EPIPHAN_REGION: leave the region as it was.
        Write-Host 'No region given. Keeping the current one (North America unless you picked another before).'
    } else {
        $url = switch ($region) { 'na' { $DefaultUrl } 'eu' { 'https://eu.epiphan.cloud/mcp' } 'au' { 'https://au.epiphan.cloud/mcp' } default { $null } }
        if (-not $url) { Problem "EPIPHAN_REGION is '$region'. Use na, eu or au."; return }
        # North America is the default in .mcp.json. Other regions get a private override for this
        # folder (stored in ~\.claude.json), so the shared files never change and updates keep working.
        Push-Location $Dir
        try {
            claude mcp remove --scope local epiphan *> $null
            if ($url -ne $DefaultUrl) {
                claude mcp add --scope local --transport http epiphan $url *> $null
                if ($LASTEXITCODE -ne 0) { Problem "Couldn't set the region. Paste the install line again."; return }
            }
        } finally { Pop-Location }
        Write-Host "Using $url"
    }

    Say 'Step 5 of 5: Open Claude Code'
    Write-Host @"
When Claude Code opens:
  1. First time only: sign in to your Claude account in the browser.
  2. "Do you trust the files in this folder?"  ->  Yes
  3. "New MCP server found in this project: epiphan"  ->  press the up arrow to "Use this MCP server", then Enter
     (the highlight starts on "Continue without", so Enter straight away says no)
  4. Type  /connect-epiphan  and press Enter. It signs you in to Epiphan Edge without leaving Claude.

Next time, open PowerShell and type:
  cd "$Dir"; claude
"@

    if (-not $env:CI) {
        Set-Location $Dir
        claude
    }
}
