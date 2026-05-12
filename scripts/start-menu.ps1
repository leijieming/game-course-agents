Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Script:Installer = Join-Path $Script:Root "install.ps1"
$Script:DefaultWorkspace = Join-Path $HOME "GameCourseAI"
$Script:AllModules = @(
  "toolchain",
  "claude-code",
  "cc-switch",
  "game-studios",
  "unreal",
  "unity",
  "godot",
  "blender"
)
$Script:CoreModules = @("toolchain", "claude-code", "cc-switch", "game-studios")
$Script:ModuleCatalog = @(
  [pscustomobject]@{ Id = "toolchain"; Label = "Environment check and workspace"; Default = $true },
  [pscustomobject]@{ Id = "claude-code"; Label = "Claude Code CLI"; Default = $true },
  [pscustomobject]@{ Id = "cc-switch"; Label = "CC Switch"; Default = $true },
  [pscustomobject]@{ Id = "game-studios"; Label = "Claude-Code-Game-Studios workspace"; Default = $true },
  [pscustomobject]@{ Id = "unreal"; Label = "Unreal MCP client entry"; Default = $true },
  [pscustomobject]@{ Id = "unity"; Label = "Unity MCP bridge record"; Default = $false },
  [pscustomobject]@{ Id = "godot"; Label = "Godot MCP bridge record"; Default = $false },
  [pscustomobject]@{ Id = "blender"; Label = "Blender MCP bridge record"; Default = $false }
)
$Script:EnvironmentTools = @(
  [pscustomobject]@{ Name = "Git"; Command = "git"; WingetId = "Git.Git" },
  [pscustomobject]@{ Name = "Node.js LTS"; Command = "node"; WingetId = "OpenJS.NodeJS.LTS" },
  [pscustomobject]@{ Name = "Python 3.12"; Command = "python"; WingetId = "Python.Python.3.12" },
  [pscustomobject]@{ Name = "uv"; Command = "uvx"; WingetId = "astral-sh.uv" }
)

function Resolve-CommandPath {
  param([Parameter(Mandatory)][string]$Name)

  $commands = Get-Command -Name $Name -ErrorAction SilentlyContinue
  foreach ($command in @($commands)) {
    if ($command.Source -and ($command.Source -match "\.(exe|cmd|bat)$")) {
      return $command.Source
    }
  }

  $command = @($commands) | Select-Object -First 1
  if ($command -and $command.Source) {
    return $command.Source
  }

  return $null
}

function Read-TextOrDefault {
  param(
    [Parameter(Mandatory)][string]$Prompt,
    [Parameter(Mandatory)][string]$Default
  )

  $value = Read-Host "$Prompt [$Default]"
  if ([string]::IsNullOrWhiteSpace($value)) {
    return $Default
  }
  return $value.Trim()
}

function Read-YesNo {
  param(
    [Parameter(Mandatory)][string]$Prompt,
    [bool]$Default = $false
  )

  $suffix = if ($Default) { "Y/n" } else { "y/N" }
  while ($true) {
    $answer = Read-Host "$Prompt [$suffix]"
    if ([string]::IsNullOrWhiteSpace($answer)) {
      return $Default
    }
    switch ($answer.Trim().ToLowerInvariant()) {
      "y" { return $true }
      "yes" { return $true }
      "n" { return $false }
      "no" { return $false }
      default { Write-Host "Please enter y or n." -ForegroundColor Yellow }
    }
  }
}

function Pause-Menu {
  Write-Host ""
  Read-Host "Press Enter to continue" | Out-Null
}

function Confirm-Delete {
  Write-Host ""
  Write-Host "This removal action is destructive." -ForegroundColor Yellow
  $answer = Read-Host "Type DELETE to continue"
  return ($answer -ceq "DELETE")
}

function Invoke-Installer {
  param([string[]]$Arguments = @())

  if (-not (Test-Path -LiteralPath $Script:Installer)) {
    throw "install.ps1 was not found at $Script:Installer"
  }

  Write-Host ""
  Write-Host "Running install.ps1 $($Arguments -join ' ')" -ForegroundColor Cyan
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Script:Installer @Arguments 2>&1 | ForEach-Object {
    Write-Host $_
  }
  return $LASTEXITCODE
}

function Build-InstallArguments {
  param(
    [Parameter(Mandatory)][string]$WorkspacePath,
    [Parameter(Mandatory)][string[]]$Modules,
    [string]$OfflineCache = "",
    [string]$GameStudiosMode = "new",
    [switch]$DryRun,
    [switch]$IncludeWsl,
    [switch]$ConfigureApi
  )

  $arguments = @(
    "-WorkspacePath",
    $WorkspacePath,
    "-Modules",
    ($Modules -join ","),
    "-GameStudiosMode",
    $GameStudiosMode
  )

  if (-not [string]::IsNullOrWhiteSpace($OfflineCache)) {
    $arguments += @("-OfflineCache", $OfflineCache)
  }
  if ($DryRun) {
    $arguments += "-DryRun"
  }
  if ($IncludeWsl) {
    $arguments += "-IncludeWsl"
  }
  if ($ConfigureApi) {
    $arguments += "-ConfigureApi"
  }

  return $arguments
}

function Confirm-InstallPlan {
  param(
    [Parameter(Mandatory)][string]$WorkspacePath,
    [Parameter(Mandatory)][string[]]$Modules,
    [string]$OfflineCache = "",
    [string]$GameStudiosMode = "new",
    [bool]$DryRun = $false,
    [bool]$IncludeWsl = $false,
    [bool]$ConfigureApi = $false
  )

  Write-Host ""
  Write-Host "Install plan" -ForegroundColor Cyan
  Write-Host "  Workspace: $WorkspacePath"
  Write-Host "  Modules:   $($Modules -join ', ')"
  Write-Host "  Game Studios mode: $GameStudiosMode"
  Write-Host "  Dry run:   $DryRun"
  Write-Host "  WSL lane:  $IncludeWsl"
  Write-Host "  API setup: $ConfigureApi"
  if (-not [string]::IsNullOrWhiteSpace($OfflineCache)) {
    Write-Host "  Offline cache: $OfflineCache"
  }
  return (Read-YesNo -Prompt "Run this plan now?" -Default $false)
}

function Invoke-PlannedInstall {
  param(
    [Parameter(Mandatory)][string]$WorkspacePath,
    [Parameter(Mandatory)][string[]]$Modules,
    [string]$OfflineCache = "",
    [string]$GameStudiosMode = "new",
    [switch]$DryRun,
    [switch]$IncludeWsl,
    [switch]$ConfigureApi
  )

  if (-not (Confirm-InstallPlan -WorkspacePath $WorkspacePath -Modules $Modules -OfflineCache $OfflineCache -GameStudiosMode $GameStudiosMode -DryRun:[bool]$DryRun -IncludeWsl:[bool]$IncludeWsl -ConfigureApi:[bool]$ConfigureApi)) {
    Write-Host "Cancelled."
    return 0
  }

  $arguments = Build-InstallArguments -WorkspacePath $WorkspacePath -Modules $Modules -OfflineCache $OfflineCache -GameStudiosMode $GameStudiosMode -DryRun:$DryRun -IncludeWsl:$IncludeWsl -ConfigureApi:$ConfigureApi
  return (Invoke-Installer -Arguments $arguments)
}

function Invoke-InstallWizard {
  $workspacePath = Read-TextOrDefault -Prompt "Workspace path" -Default $Script:DefaultWorkspace
  $offlineCache = Read-Host "Offline cache path (blank to skip)"
  $mode = Read-TextOrDefault -Prompt "Game Studios mode: new or merge" -Default "new"
  if ($mode -notin @("new", "merge")) {
    Write-Host "Unknown mode. Falling back to new." -ForegroundColor Yellow
    $mode = "new"
  }

  $selectedModules = @()
  foreach ($module in $Script:ModuleCatalog) {
    if (Read-YesNo -Prompt "Install $($module.Label)?" -Default $module.Default) {
      $selectedModules += $module.Id
    }
  }

  if ($selectedModules.Count -eq 0) {
    Write-Host "No modules selected."
    return 0
  }

  $includeWsl = Read-YesNo -Prompt "Include WSL status check?" -Default $false
  $configureApi = Read-YesNo -Prompt "Configure API provider during install?" -Default $false
  $dryRun = Read-YesNo -Prompt "Preview only with -DryRun?" -Default $false

  return (Invoke-PlannedInstall -WorkspacePath $workspacePath -Modules $selectedModules -OfflineCache $offlineCache -GameStudiosMode $mode -DryRun:$dryRun -IncludeWsl:$includeWsl -ConfigureApi:$configureApi)
}

function Invoke-PresetInstall {
  param(
    [Parameter(Mandatory)][string[]]$Modules,
    [switch]$DryRun,
    [switch]$IncludeWsl,
    [switch]$ConfigureApi
  )

  $workspacePath = Read-TextOrDefault -Prompt "Workspace path" -Default $Script:DefaultWorkspace
  return (Invoke-PlannedInstall -WorkspacePath $workspacePath -Modules $Modules -DryRun:$DryRun -IncludeWsl:$IncludeWsl -ConfigureApi:$ConfigureApi)
}

function Invoke-EnvironmentInstaller {
  $winget = Resolve-CommandPath -Name "winget"
  if (-not $winget) {
    Write-Host "winget was not found. Install App Installer from Microsoft Store, then reopen the terminal." -ForegroundColor Yellow
    return 1
  }

  $missingTools = @()
  foreach ($tool in $Script:EnvironmentTools) {
    if (-not (Resolve-CommandPath -Name $tool.Command)) {
      $missingTools += $tool
    }
  }

  if ($missingTools.Count -eq 0) {
    Write-Host "Git, Node.js, Python, and uv are already available."
    return 0
  }

  Write-Host ""
  Write-Host "Missing environment tools" -ForegroundColor Cyan
  foreach ($tool in $missingTools) {
    Write-Host "  - $($tool.Name) via winget id $($tool.WingetId)"
  }
  Write-Host "A new terminal may be required after installation for PATH changes."

  if (-not (Read-YesNo -Prompt "Install these environment tools now?" -Default $false)) {
    Write-Host "Cancelled."
    return 0
  }

  $exitCode = 0
  foreach ($tool in $missingTools) {
    Write-Host ""
    Write-Host "Installing $($tool.Name)..." -ForegroundColor Cyan
    & $winget install --id $tool.WingetId -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
      Write-Host "winget failed for $($tool.Name) with code $LASTEXITCODE." -ForegroundColor Yellow
      $exitCode = $LASTEXITCODE
    }
  }

  return $exitCode
}

function Invoke-RemoveCourseInstall {
  $workspacePath = Read-TextOrDefault -Prompt "Workspace path to remove" -Default $Script:DefaultWorkspace
  $offlineCache = Read-Host "Offline cache path to remove (blank to skip)"
  $removeClaude = Read-YesNo -Prompt "Also uninstall global Claude Code npm package?" -Default $false
  $removeCcSwitch = Read-YesNo -Prompt "Also remove CC Switch app if found?" -Default $false

  $targets = @()
  if (Test-Path -LiteralPath $workspacePath) {
    $targets += $workspacePath
  }
  if ((-not [string]::IsNullOrWhiteSpace($offlineCache)) -and (Test-Path -LiteralPath $offlineCache)) {
    $targets += $offlineCache
  }

  if ($removeCcSwitch) {
    foreach ($path in @(
      (Join-Path $env:LOCALAPPDATA "Programs\CC Switch"),
      (Join-Path $env:ProgramFiles "CC Switch")
    )) {
      if (Test-Path -LiteralPath $path) {
        $targets += $path
      }
    }
  }

  Write-Host ""
  Write-Host "Removal plan" -ForegroundColor Cyan
  if ($targets.Count -eq 0) {
    Write-Host "  File targets: none found"
  } else {
    foreach ($target in $targets) {
      Write-Host "  Remove folder: $target"
    }
  }
  Write-Host "  Uninstall Claude Code: $removeClaude"
  Write-Host "  Uninstall CC Switch:   $removeCcSwitch"
  Write-Host "  Not removed: Git, Node.js, Python, Unreal, Unity, Godot, Blender"

  if (($targets.Count -eq 0) -and (-not $removeClaude) -and (-not $removeCcSwitch)) {
    Write-Host "Nothing selected for removal."
    return 0
  }

  if (-not (Confirm-Delete)) {
    Write-Host "Cancelled."
    return 0
  }

  $exitCode = 0
  foreach ($target in $targets) {
    Write-Host "Removing $target"
    Remove-Item -LiteralPath $target -Recurse -Force
  }

  if ($removeClaude) {
    $npm = Resolve-CommandPath -Name "npm"
    if ($npm) {
      & $npm uninstall -g @anthropic-ai/claude-code
      if ($LASTEXITCODE -ne 0) {
        $exitCode = $LASTEXITCODE
      }
    } else {
      Write-Host "npm was not found; Claude Code npm uninstall skipped." -ForegroundColor Yellow
    }
  }

  if ($removeCcSwitch) {
    $winget = Resolve-CommandPath -Name "winget"
    if ($winget) {
      & $winget uninstall --name "CC Switch" --accept-source-agreements
      if ($LASTEXITCODE -ne 0) {
        Write-Host "winget could not uninstall CC Switch automatically. Manual uninstall may still be needed." -ForegroundColor Yellow
      }
    } else {
      Write-Host "winget was not found; CC Switch system uninstall skipped." -ForegroundColor Yellow
    }
  }

  return $exitCode
}

function Show-Menu {
  Clear-Host
  Write-Host ""
  Write-Host "Game Course Agents setup menu" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "1. Preview default install"
  Write-Host "2. Install full course workspace"
  Write-Host "3. Select install content"
  Write-Host "4. Install Claude Code + CC Switch + Game Studios"
  Write-Host "5. Configure Unreal MCP only"
  Write-Host "6. Install missing environment tools"
  Write-Host "7. Configure API provider"
  Write-Host "8. Remove course-installed items"
  Write-Host "0. Exit"
  Write-Host ""
}

if ($args.Count -gt 0) {
  exit (Invoke-Installer -Arguments @($args))
}

while ($true) {
  Show-Menu
  $choice = Read-Host "Select an option"
  $exitCode = 0

  switch ($choice) {
    "1" { $exitCode = Invoke-PresetInstall -Modules $Script:AllModules -DryRun }
    "2" { $exitCode = Invoke-PresetInstall -Modules $Script:AllModules }
    "3" { $exitCode = Invoke-InstallWizard }
    "4" { $exitCode = Invoke-PresetInstall -Modules $Script:CoreModules }
    "5" { $exitCode = Invoke-PresetInstall -Modules @("toolchain", "game-studios", "unreal") }
    "6" { $exitCode = Invoke-EnvironmentInstaller }
    "7" { $exitCode = Invoke-PresetInstall -Modules @("cc-switch") -ConfigureApi }
    "8" { $exitCode = Invoke-RemoveCourseInstall }
    "0" { exit 0 }
    default {
      Write-Host "Unknown option." -ForegroundColor Yellow
    }
  }

  if ($exitCode -ne 0) {
    Write-Host "Last action exited with code $exitCode." -ForegroundColor Yellow
  }
  Pause-Menu
}
