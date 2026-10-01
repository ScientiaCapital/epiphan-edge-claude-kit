# One-line installer for the Epiphan Edge x Claude Code kit (Windows PowerShell 5.1+ or PowerShell 7).
#   irm https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.ps1 | iex
# Safe to re-run. Installs Git for Windows and Claude Code if they're missing, downloads this kit
# into ~\epiphan-edge-claude-kit, then opens Claude Code there. Set EPIPHAN_KIT_DIR for another folder.
# Everything runs inside a script block and uses 'return', never 'exit', so a problem can't close your window.

& {
    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $Repo = 'https://github.com/ScientiaCapital/epiphan-edge-claude-kit'
    $Dir = if ($env:EPIPHAN_KIT_DIR) { $env:EPIPHAN_KIT_DIR } else { Join-Path $HOME 'epiphan-edge-claude-kit' }

    function Say($Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
    function Problem($Message) { Write-Host "`nProblem: $Message" -ForegroundColor Red }
    function Has($Command) { [bool](Get-Command $Command -ErrorAction SilentlyContinue) }
    function Update-Path {
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                    [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
                    (Join-Path $HOME '.local\bin')
    }

    Say 'Step 1 of 4: Git for Windows (Claude Code and this kit use its bash)'
    if (Has git) {
        Write-Host "Already installed: $(git --version)"
    } elseif (Has winget) {
        Write-Host 'Installing Git for Windows with winget (Windows may ask for permission)...'
        winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        Update-Path
    }
    if (-not (Has git)) {
        Write-Warning 'Git for Windows is not installed. The kit still works, but its safety hook needs it.'
        Write-Warning 'Install it from https://git-scm.com/downloads/win when you can, then re-run this installer.'
    }

    Say 'Step 2 of 4: Claude Code'
    if (Has claude) {
        Write-Host "Already installed: $(claude --version)"
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

    Say 'Step 3 of 4: The kit'
    if (Test-Path (Join-Path $Dir '.git')) {
        Write-Host "Found it in $Dir. Updating..."
        git -C $Dir pull --ff-only --quiet
        if ($LASTEXITCODE -ne 0) { Write-Host "Couldn't update (did you change files?). Keeping your copy as is." }
    } elseif (Test-Path $Dir) {
        Problem "$Dir already exists but isn't this kit. Rename that folder, then paste the install line again."
        return
    } elseif (Has git) {
        git clone --quiet --depth 1 "$Repo.git" $Dir
        Write-Host "Downloaded to $Dir"
    } else {
        $zip = Join-Path ([IO.Path]::GetTempPath()) 'epiphan-edge-claude-kit.zip'
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ('epiphan-kit-' + [guid]::NewGuid())
        Invoke-WebRequest "$Repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
        Expand-Archive $zip -DestinationPath $tmp
        Move-Item (Join-Path $tmp 'epiphan-edge-claude-kit-main') $Dir
        Remove-Item $zip, $tmp -Recurse -Force
        Write-Host "Downloaded to $Dir (no git found, so updates mean re-running this installer)"
    }

    Say 'Step 4 of 4: Open Claude Code'
    Write-Host @"
When Claude Code opens:
  1. First time only: sign in to your Claude account in the browser.
  2. "Do you trust the files in this folder?"  ->  Yes
  3. "New MCP server found: epiphan"           ->  choose to use it
  4. Type  /start  and press Enter. It walks you through signing in to Epiphan Edge.

Next time, open PowerShell and type:
  cd "$Dir"; claude
"@

    if (-not $env:CI) {
        Set-Location $Dir
        claude
    }
}
