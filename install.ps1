<#
.SYNOPSIS
  Windows course installer for Claude Code, CC Switch, Game Studios, and engine MCP bridges.

.DESCRIPTION
  This script is intentionally conservative: it installs AI tooling and connection
  layers, but it does not install Unreal Engine, Unity, Godot, or Blender.
  Missing desktop apps are reported as SKIP/WARN items instead of hard failures.
#>

[CmdletBinding()]
param(
  [string]$WorkspacePath = (Join-Path $HOME "GameCourseAI"),
  [string]$OfflineCache = "",
  [switch]$DryRun,
  [switch]$IncludeWsl,
  [switch]$ConfigureApi,
  [ValidateSet("new", "merge")]
  [string]$GameStudiosMode = "new",
  [string[]]$Modules = @(
    "toolchain",
    "claude-code",
    "cc-switch",
    "game-studios",
    "unreal",
    "unity",
    "godot",
    "blender"
  ),
  [switch]$SkipMcpConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:ManifestRoot = Join-Path $Script:Root "manifests"
$Script:Report = [ordered]@{
  generatedAt = (Get-Date).ToString("o")
  workspacePath = $WorkspacePath
  dryRun = [bool]$DryRun
  includeWsl = [bool]$IncludeWsl
  gameStudiosMode = $GameStudiosMode
  events = @()
}

function Write-Step {
  param(
    [Parameter(Mandatory)][string]$Status,
    [Parameter(Mandatory)][string]$Module,
    [Parameter(Mandatory)][string]$Message,
    [hashtable]$Data = @{}
  )

  $entry = [ordered]@{
    time = (Get-Date).ToString("o")
    status = $Status
    module = $Module
    message = $Message
    data = $Data
  }
  $Script:Report.events += $entry
  $color = switch ($Status) {
    "PASS" { "Green" }
    "WARN" { "Yellow" }
    "SKIP" { "DarkYellow" }
    "FAIL" { "Red" }
    default { "White" }
  }
  Write-Host ("[{0}] {1}: {2}" -f $Status, $Module, $Message) -ForegroundColor $color
}

function Write-HealthReport {
  param([string]$Path = (Join-Path $WorkspacePath "health-report.json"))

  if ($DryRun) {
    Write-Step -Status "SKIP" -Module "report" -Message "Dry-run mode: health report would be written." -Data @{ path = $Path }
    return
  }

  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  $Script:Report | ConvertTo-Json -Depth 8 | Set-Content -Path $Path -Encoding UTF8
  Write-Step -Status "PASS" -Module "report" -Message "Health report written." -Data @{ path = $Path }
}

function Read-Manifest {
  param([Parameter(Mandatory)][string]$Id)

  $path = Join-Path $Script:ManifestRoot ("{0}.json" -f $Id)
  if (-not (Test-Path $path)) {
    throw "Missing manifest: $path"
  }
  Get-Content -Raw -Path $path | ConvertFrom-Json
}

function Test-CommandAvailable {
  param([Parameter(Mandatory)][string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-LoggedCommand {
  param(
    [Parameter(Mandatory)][string]$Module,
    [Parameter(Mandatory)][string]$Command,
    [string[]]$Arguments = @()
  )

  if ($DryRun) {
    Write-Step -Status "SKIP" -Module $Module -Message "Dry-run command skipped." -Data @{ command = $Command; arguments = $Arguments }
    return
  }

  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Module command failed: $Command $($Arguments -join ' ')"
  }
}

function Test-OfflineArtifact {
  param(
    [Parameter(Mandatory)]$Artifact,
    [Parameter(Mandatory)][string]$Module
  )

  if ([string]::IsNullOrWhiteSpace($OfflineCache)) {
    return $false
  }

  $artifactPath = Join-Path $OfflineCache $Artifact.file
  if (-not (Test-Path $artifactPath)) {
    Write-Step -Status "WARN" -Module $Module -Message "Offline artifact is missing." -Data @{ file = $Artifact.file }
    return $false
  }

  if ($Artifact.sha256) {
    $hash = (Get-FileHash -Algorithm SHA256 -Path $artifactPath).Hash.ToLowerInvariant()
    if ($hash -ne $Artifact.sha256.ToLowerInvariant()) {
      Write-Step -Status "FAIL" -Module $Module -Message "Offline artifact checksum mismatch." -Data @{ file = $Artifact.file }
      return $false
    }
  }

  Write-Step -Status "PASS" -Module $Module -Message "Offline artifact is available." -Data @{ file = $Artifact.file }
  return $true
}

function Ensure-Directory {
  param([Parameter(Mandatory)][string]$Path)

  if ($DryRun) {
    Write-Step -Status "SKIP" -Module "filesystem" -Message "Dry-run directory creation skipped." -Data @{ path = $Path }
    return
  }
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Backup-Path {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Module
  )

  if (-not (Test-Path $Path)) {
    return $null
  }

  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $backupRoot = Join-Path $WorkspacePath ".backups"
  $backupPath = Join-Path $backupRoot ("{0}-{1}" -f (Split-Path -Leaf $Path), $stamp)
  if ($DryRun) {
    Write-Step -Status "SKIP" -Module $Module -Message "Dry-run backup skipped." -Data @{ source = $Path; backup = $backupPath }
    return $backupPath
  }

  Ensure-Directory -Path $backupRoot
  Copy-Item -Recurse -Force -Path $Path -Destination $backupPath
  Write-Step -Status "PASS" -Module $Module -Message "Existing path backed up." -Data @{ source = $Path; backup = $backupPath }
  return $backupPath
}

function Configure-ClaudeMcp {
  param([Parameter(Mandatory)][string]$TargetPath)

  if ($SkipMcpConfig) {
    Write-Step -Status "SKIP" -Module "mcp" -Message "MCP configuration skipped by parameter."
    return
  }

  $source = Join-Path $Script:Root "examples/mcp/claude-code.mcp.json"
  $target = Join-Path $TargetPath ".mcp.json"
  if (-not (Test-Path $source)) {
    throw "Missing MCP example: $source"
  }

  if (Test-Path $target) {
    Backup-Path -Path $target -Module "mcp" | Out-Null
  }

  if ($DryRun) {
    Write-Step -Status "SKIP" -Module "mcp" -Message "Dry-run MCP copy skipped." -Data @{ target = $target }
    return
  }

  Copy-Item -Force -Path $source -Destination $target
  Write-Step -Status "PASS" -Module "mcp" -Message "Claude Code project MCP configuration created." -Data @{ target = $target }
}

function Configure-CcSwitch {
  if (-not $ConfigureApi) {
    Write-Step -Status "SKIP" -Module "cc-switch" -Message "API provider capture skipped. Re-run with -ConfigureApi to enter provider details."
    return
  }

  $providerName = Read-Host "Provider name for CC Switch"
  $baseUrl = Read-Host "Provider base URL"
  $apiKey = Read-Host -AsSecureString "API key"

  if ($DryRun) {
    Write-Step -Status "SKIP" -Module "cc-switch" -Message "Dry-run provider import skipped." -Data @{ provider = $providerName; baseUrl = $baseUrl }
    return
  }

  $providerDir = Join-Path $WorkspacePath ".local"
  Ensure-Directory -Path $providerDir
  $providerFile = Join-Path $providerDir "cc-switch-provider.local.json"
  $payload = [ordered]@{
    provider = $providerName
    baseUrl = $baseUrl
    apiKeyStoredBy = "local-secure-input"
    createdAt = (Get-Date).ToString("o")
  }
  $payload | ConvertTo-Json -Depth 5 | Set-Content -Path $providerFile -Encoding UTF8
  $apiKey.Dispose()
  Write-Step -Status "PASS" -Module "cc-switch" -Message "Provider metadata written without logging secret material." -Data @{ path = $providerFile }
}

function Install-Toolchain {
  $module = "toolchain"
  $required = @("git", "node", "npm")
  foreach ($command in $required) {
    if (Test-CommandAvailable -Name $command) {
      Write-Step -Status "PASS" -Module $module -Message "$command is available."
    } else {
      Write-Step -Status "WARN" -Module $module -Message "$command is missing. Install it before running the full course setup."
    }
  }

  if (Test-CommandAvailable -Name "python") {
    Write-Step -Status "PASS" -Module $module -Message "python is available."
  } elseif (Test-CommandAvailable -Name "py") {
    Write-Step -Status "PASS" -Module $module -Message "py launcher is available."
  } else {
    Write-Step -Status "WARN" -Module $module -Message "Python is missing. Some MCP servers may need Python or uv."
  }

  if (Test-CommandAvailable -Name "uvx") {
    Write-Step -Status "PASS" -Module $module -Message "uvx is available."
  } else {
    Write-Step -Status "WARN" -Module $module -Message "uvx is missing. Blender/Unreal MCP can still be installed later."
  }
}

function Install-ClaudeCode {
  $module = "claude-code"
  if (Test-CommandAvailable -Name "claude") {
    Write-Step -Status "PASS" -Module $module -Message "Claude Code CLI is already available."
    return
  }

  if (-not (Test-CommandAvailable -Name "npm")) {
    Write-Step -Status "WARN" -Module $module -Message "npm is missing; Claude Code install skipped."
    return
  }

  Invoke-LoggedCommand -Module $module -Command "npm" -Arguments @("install", "-g", "@anthropic-ai/claude-code")
  Write-Step -Status "PASS" -Module $module -Message "Claude Code install command completed."
}

function Find-CcSwitchApp {
  $commands = @("ccswitch", "cc-switch")
  foreach ($command in $commands) {
    $match = Get-Command $command -ErrorAction SilentlyContinue
    if ($match) { return $match.Source }
  }

  $paths = @(
    (Join-Path $env:LOCALAPPDATA "Programs\CC Switch\CC Switch.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\cc-switch\CC Switch.exe"),
    (Join-Path $env:ProgramFiles "CC Switch\CC Switch.exe")
  )

  foreach ($path in $paths) {
    if ($path -and (Test-Path $path)) { return $path }
  }

  return $null
}

function Install-CcSwitchRelease {
  $module = "cc-switch"
  $releaseUrl = "https://api.github.com/repos/farion1231/cc-switch/releases/latest"
  $installerPath = $null

  if (-not [string]::IsNullOrWhiteSpace($OfflineCache)) {
    $candidate = Join-Path $OfflineCache "cc-switch/release.msi"
    if (Test-Path $candidate) {
      $installerPath = $candidate
      Write-Step -Status "PASS" -Module $module -Message "Using offline CC Switch installer." -Data @{ path = $installerPath }
    }
  }

  if (-not $installerPath) {
    $downloadDir = Join-Path $WorkspacePath "downloads"
    $installerPath = Join-Path $downloadDir "CC-Switch-Windows.msi"
    if ($DryRun) {
      Write-Step -Status "SKIP" -Module $module -Message "Dry-run CC Switch release download skipped." -Data @{ release = $releaseUrl; pattern = "Windows.msi" }
      return
    }

    Ensure-Directory -Path $downloadDir
    $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ "User-Agent" = "game-course-ai-agent-installer" }
    $asset = $release.assets |
      Where-Object { $_.name -match "Windows\.msi$" } |
      Select-Object -First 1
    if (-not $asset) {
      Write-Step -Status "WARN" -Module $module -Message "No Windows.msi asset found in latest CC Switch release; install manually from Releases." -Data @{ releases = "https://github.com/farion1231/cc-switch/releases" }
      return
    }
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath
    Write-Step -Status "PASS" -Module $module -Message "CC Switch Windows installer downloaded." -Data @{ path = $installerPath }
  }

  if ($DryRun) {
    Write-Step -Status "SKIP" -Module $module -Message "Dry-run CC Switch MSI install skipped." -Data @{ path = $installerPath }
    return
  }

  Start-Process -FilePath "msiexec.exe" -ArgumentList @("/i", $installerPath, "/passive", "/norestart") -Wait
  Write-Step -Status "PASS" -Module $module -Message "CC Switch MSI installer finished."
}

function Install-CcSwitch {
  $module = "cc-switch"
  $app = Find-CcSwitchApp
  if ($app) {
    Write-Step -Status "PASS" -Module $module -Message "CC Switch is already available." -Data @{ path = $app }
    Configure-CcSwitch
    return
  }

  Install-CcSwitchRelease
  Configure-CcSwitch
}

function Install-GameStudiosTemplate {
  param([Parameter(Mandatory)][string]$TargetPath)

  $module = "game-studios"
  Ensure-Directory -Path $TargetPath
  $repo = "https://github.com/leijieming/Claude-Code-Game-Studios.git"
  $templatePath = Join-Path $WorkspacePath "_Claude-Code-Game-Studios"

  if (-not (Test-Path $templatePath)) {
    if (Test-CommandAvailable -Name "git") {
      Invoke-LoggedCommand -Module $module -Command "git" -Arguments @("clone", "--depth", "1", $repo, $templatePath)
      Write-Step -Status "PASS" -Module $module -Message "Game Studios template cloned." -Data @{ path = $templatePath }
    } else {
      Write-Step -Status "WARN" -Module $module -Message "git is missing; Game Studios template clone skipped."
      return
    }
  } else {
    Write-Step -Status "PASS" -Module $module -Message "Game Studios template already exists." -Data @{ path = $templatePath }
  }

  $items = @("CLAUDE.md", ".claude", "design", "docs", "production", "tools")
  foreach ($item in $items) {
    $source = Join-Path $templatePath $item
    $target = Join-Path $TargetPath $item
    if (-not (Test-Path $source)) {
      continue
    }
    if (Test-Path $target) {
      Backup-Path -Path $target -Module $module | Out-Null
    }
    if ($DryRun) {
      Write-Step -Status "SKIP" -Module $module -Message "Dry-run template copy skipped." -Data @{ item = $item }
      continue
    }
    Copy-Item -Recurse -Force -Path $source -Destination $target
  }

  Configure-ClaudeMcp -TargetPath $TargetPath
  Write-Step -Status "PASS" -Module $module -Message "Game Studios template configured." -Data @{ target = $TargetPath; mode = $GameStudiosMode }
}

function Find-Unreal {
  $roots = @(
    "${env:ProgramFiles}\Epic Games",
    "${env:ProgramFiles(x86)}\Epic Games"
  ) | Where-Object { $_ -and (Test-Path $_) }
  foreach ($root in $roots) {
    $match = Get-ChildItem -Directory -Path $root -Filter "UE_5*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($match) { return $match.FullName }
  }
  return $null
}

function Find-Unity {
  $hubRoot = "${env:ProgramFiles}\Unity\Hub\Editor"
  if (Test-Path $hubRoot) {
    $match = Get-ChildItem -Directory -Path $hubRoot -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($match) { return $match.FullName }
  }
  return $null
}

function Find-Godot {
  $command = Get-Command "godot" -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }
  $candidates = @(
    (Join-Path $HOME "Downloads"),
    (Join-Path $HOME "Apps")
  )
  foreach ($dir in $candidates) {
    if (-not (Test-Path $dir)) { continue }
    $match = Get-ChildItem -Recurse -File -Path $dir -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($match) { return $match.FullName }
  }
  return $null
}

function Find-Blender {
  $command = Get-Command "blender" -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }
  $root = "${env:ProgramFiles}\Blender Foundation"
  if (Test-Path $root) {
    $match = Get-ChildItem -Recurse -File -Path $root -Filter "blender.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($match) { return $match.FullName }
  }
  return $null
}

function Configure-EngineBridge {
  param(
    [Parameter(Mandatory)][string]$Module,
    [Parameter(Mandatory)][scriptblock]$Finder,
    [Parameter(Mandatory)][string]$BridgeName,
    [Parameter(Mandatory)][string]$Upstream
  )

  $path = & $Finder
  if (-not $path) {
    Write-Step -Status "SKIP" -Module $Module -Message "$BridgeName host app not found; bridge setup skipped." -Data @{ upstream = $Upstream }
    return
  }

  $bridgeRoot = Join-Path $WorkspacePath "engine-bridges"
  $moduleRoot = Join-Path $bridgeRoot $Module
  Ensure-Directory -Path $moduleRoot

  $readme = Join-Path $moduleRoot "README.local.md"
  $content = @"
# $BridgeName 本地连接记录

- Host path: $path
- Upstream: $Upstream
- Created: $(Get-Date -Format "o")

此目录只记录课程安装器检测到的本机路径和上游适配器。实际插件安装步骤见 docs/getting-started.md。
"@

  if ($DryRun) {
    Write-Step -Status "SKIP" -Module $Module -Message "Dry-run bridge record skipped." -Data @{ hostPath = $path }
    return
  }

  $content | Set-Content -Path $readme -Encoding UTF8
  Write-Step -Status "PASS" -Module $Module -Message "$BridgeName host app detected; bridge record created." -Data @{ hostPath = $path; readme = $readme }
}

function Configure-Wsl {
  if (-not $IncludeWsl) {
    Write-Step -Status "SKIP" -Module "wsl" -Message "WSL setup skipped. Re-run with -IncludeWsl to enable it."
    return
  }

  if (-not (Test-CommandAvailable -Name "wsl")) {
    Write-Step -Status "WARN" -Module "wsl" -Message "wsl.exe is not available. Enable WSL2 before using the Linux lane."
    return
  }

  Invoke-LoggedCommand -Module "wsl" -Command "wsl" -Arguments @("--status")
  Write-Step -Status "PASS" -Module "wsl" -Message "WSL command is available. Run docs/getting-started.md WSL section for Linux-side setup."
}

function Invoke-ModuleLifecycle {
  param([Parameter(Mandatory)][string]$Id)

  $manifest = Read-Manifest -Id $Id
  foreach ($artifact in $manifest.cacheArtifacts) {
    Test-OfflineArtifact -Artifact $artifact -Module $manifest.id | Out-Null
  }

  switch ($Id) {
    "toolchain" { Install-Toolchain }
    "claude-code" { Install-ClaudeCode }
    "cc-switch" { Install-CcSwitch }
    "game-studios" { Install-GameStudiosTemplate -TargetPath $WorkspacePath }
    "unreal" { Configure-EngineBridge -Module "unreal" -Finder ${function:Find-Unreal} -BridgeName "Unreal Engine 5" -Upstream $manifest.upstream.url }
    "unity" { Configure-EngineBridge -Module "unity" -Finder ${function:Find-Unity} -BridgeName "Unity" -Upstream $manifest.upstream.url }
    "godot" { Configure-EngineBridge -Module "godot" -Finder ${function:Find-Godot} -BridgeName "Godot 4" -Upstream $manifest.upstream.url }
    "blender" { Configure-EngineBridge -Module "blender" -Finder ${function:Find-Blender} -BridgeName "Blender" -Upstream $manifest.upstream.url }
    default { Write-Step -Status "WARN" -Module $Id -Message "No lifecycle handler exists for this module." }
  }
}

try {
  Ensure-Directory -Path $WorkspacePath
  Write-Step -Status "PASS" -Module "installer" -Message "Installer started." -Data @{ modules = $Modules }

  foreach ($module in $Modules) {
    Invoke-ModuleLifecycle -Id $module
  }

  Configure-Wsl
  Write-HealthReport
} catch {
  Write-Step -Status "FAIL" -Module "installer" -Message $_.Exception.Message
  Write-HealthReport
  exit 1
}
