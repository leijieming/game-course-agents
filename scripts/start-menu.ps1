param(
  [ValidateSet("zh-CN", "en-US")]
  [string]$Language = "zh-CN"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Script:Installer = Join-Path $Script:Root "install.ps1"
$Script:DefaultWorkspace = Join-Path $HOME "GameCourseAI"
$Script:Language = $Language
. (Join-Path $Script:Root "scripts\i18n.ps1")
Initialize-I18n -Root $Script:Root -Language $Script:Language
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
  [pscustomobject]@{ Id = "toolchain"; Label = (T -Key "module.toolchain" -Default "Environment check and workspace"); Default = $true },
  [pscustomobject]@{ Id = "claude-code"; Label = (T -Key "module.claude-code" -Default "Claude Code CLI"); Default = $true },
  [pscustomobject]@{ Id = "cc-switch"; Label = (T -Key "module.cc-switch" -Default "CC Switch"); Default = $true },
  [pscustomobject]@{ Id = "game-studios"; Label = (T -Key "module.game-studios" -Default "Claude-Code-Game-Studios workspace"); Default = $true },
  [pscustomobject]@{ Id = "unreal"; Label = (T -Key "module.unreal" -Default "Unreal MCP client entry"); Default = $true },
  [pscustomobject]@{ Id = "unity"; Label = (T -Key "module.unity" -Default "Unity MCP bridge record"); Default = $false },
  [pscustomobject]@{ Id = "godot"; Label = (T -Key "module.godot" -Default "Godot MCP bridge record"); Default = $false },
  [pscustomobject]@{ Id = "blender"; Label = (T -Key "module.blender" -Default "Blender MCP bridge record"); Default = $false }
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
      default { Write-Host (T -Key "common.yesNo" -Default "Please enter y or n.") -ForegroundColor Yellow }
    }
  }
}

function Pause-Menu {
  Write-Host ""
  Read-Host (T -Key "menu.pressEnter" -Default "Press Enter to continue") | Out-Null
}

function Confirm-Delete {
  Write-Host ""
  Write-Host (T -Key "remove.destructive" -Default "This removal action is destructive.") -ForegroundColor Yellow
  $answer = Read-Host (T -Key "remove.typeDelete" -Default "Type DELETE to continue")
  return ($answer -ceq "DELETE")
}

function Invoke-Installer {
  param([string[]]$Arguments = @())

  if (-not (Test-Path -LiteralPath $Script:Installer)) {
    throw "install.ps1 was not found at $Script:Installer"
  }

  Write-Host ""
  Write-Host (T -Key "run.installer" -Default "Running install.ps1 {arguments}" -Values @{ arguments = ($Arguments -join " ") }) -ForegroundColor Cyan
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
    [bool]$DryRun = $false,
    [bool]$IncludeWsl = $false,
    [bool]$ConfigureApi = $false
  )

  $arguments = @(
    "-WorkspacePath",
    $WorkspacePath,
    "-Language",
    $Script:Language,
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
  Write-Host (T -Key "plan.title" -Default "Install plan") -ForegroundColor Cyan
  Write-Host (T -Key "plan.workspace" -Default "  Workspace: {path}" -Values @{ path = $WorkspacePath })
  Write-Host (T -Key "plan.modules" -Default "  Modules:   {modules}" -Values @{ modules = ($Modules -join ", ") })
  Write-Host (T -Key "plan.mode" -Default "  Game Studios mode: {mode}" -Values @{ mode = $GameStudiosMode })
  Write-Host (T -Key "plan.dryRun" -Default "  Dry run:   {value}" -Values @{ value = $DryRun })
  Write-Host (T -Key "plan.wsl" -Default "  WSL lane:  {value}" -Values @{ value = $IncludeWsl })
  Write-Host (T -Key "plan.api" -Default "  API setup: {value}" -Values @{ value = $ConfigureApi })
  if (-not [string]::IsNullOrWhiteSpace($OfflineCache)) {
    Write-Host (T -Key "plan.offlineCache" -Default "  Offline cache: {path}" -Values @{ path = $OfflineCache })
  }
  return (Read-YesNo -Prompt (T -Key "plan.confirm" -Default "Run this plan now?") -Default $false)
}

function Invoke-PlannedInstall {
  param(
    [Parameter(Mandatory)][string]$WorkspacePath,
    [Parameter(Mandatory)][string[]]$Modules,
    [string]$OfflineCache = "",
    [string]$GameStudiosMode = "new",
    [bool]$DryRun = $false,
    [bool]$IncludeWsl = $false,
    [bool]$ConfigureApi = $false
  )

  $plan = @{
    WorkspacePath = $WorkspacePath
    Modules = @($Modules)
    OfflineCache = $OfflineCache
    GameStudiosMode = $GameStudiosMode
    DryRun = $DryRun
    IncludeWsl = $IncludeWsl
    ConfigureApi = $ConfigureApi
  }

  if (-not (Confirm-InstallPlan @plan)) {
    Write-Host (T -Key "common.cancelled" -Default "Cancelled.")
    return 0
  }

  $arguments = Build-InstallArguments @plan
  return (Invoke-Installer -Arguments $arguments)
}

function Invoke-InstallWizard {
  $workspacePath = Read-TextOrDefault -Prompt (T -Key "prompt.workspace" -Default "Workspace path") -Default $Script:DefaultWorkspace
  $offlineCache = Read-Host (T -Key "prompt.offlineCache" -Default "Offline cache path (blank to skip)")
  $mode = Read-TextOrDefault -Prompt (T -Key "prompt.gameStudiosMode" -Default "Game Studios mode: new or merge") -Default "new"
  if ($mode -notin @("new", "merge")) {
    Write-Host (T -Key "prompt.unknownMode" -Default "Unknown mode. Falling back to new.") -ForegroundColor Yellow
    $mode = "new"
  }

  $selectedModules = @()
  foreach ($module in $Script:ModuleCatalog) {
    if (Read-YesNo -Prompt (T -Key "prompt.installModule" -Default "Install {label}?" -Values @{ label = $module.Label }) -Default $module.Default) {
      $selectedModules += $module.Id
    }
  }

  if ($selectedModules.Count -eq 0) {
    Write-Host (T -Key "prompt.noModules" -Default "No modules selected.")
    return 0
  }

  $includeWsl = Read-YesNo -Prompt (T -Key "prompt.includeWsl" -Default "Include WSL status check?") -Default $false
  $configureApi = Read-YesNo -Prompt (T -Key "prompt.configureApi" -Default "Configure API provider during install?") -Default $false
  $dryRun = Read-YesNo -Prompt (T -Key "prompt.previewOnly" -Default "Preview only with -DryRun?") -Default $false

  $plan = @{
    WorkspacePath = $workspacePath
    Modules = @($selectedModules)
    OfflineCache = $offlineCache
    GameStudiosMode = $mode
    DryRun = $dryRun
    IncludeWsl = $includeWsl
    ConfigureApi = $configureApi
  }

  return (Invoke-PlannedInstall @plan)
}

function Invoke-PresetInstall {
  param(
    [Parameter(Mandatory)][string[]]$Modules,
    [switch]$DryRun,
    [switch]$IncludeWsl,
    [switch]$ConfigureApi
  )

  $workspacePath = Read-TextOrDefault -Prompt (T -Key "prompt.workspace" -Default "Workspace path") -Default $Script:DefaultWorkspace
  $plan = @{
    WorkspacePath = $workspacePath
    Modules = @($Modules)
    DryRun = [bool]$DryRun
    IncludeWsl = [bool]$IncludeWsl
    ConfigureApi = [bool]$ConfigureApi
  }

  return (Invoke-PlannedInstall @plan)
}

function Invoke-EnvironmentInstaller {
  $winget = Resolve-CommandPath -Name "winget"
  if (-not $winget) {
    Write-Host (T -Key "environment.wingetMissing" -Default "winget was not found. Install App Installer from Microsoft Store, then reopen the terminal.") -ForegroundColor Yellow
    return 1
  }

  $missingTools = @()
  foreach ($tool in $Script:EnvironmentTools) {
    if (-not (Resolve-CommandPath -Name $tool.Command)) {
      $missingTools += $tool
    }
  }

  if ($missingTools.Count -eq 0) {
    Write-Host (T -Key "environment.allAvailable" -Default "Git, Node.js, Python, and uv are already available.")
    return 0
  }

  Write-Host ""
  Write-Host (T -Key "environment.missingTitle" -Default "Missing environment tools") -ForegroundColor Cyan
  foreach ($tool in $missingTools) {
    Write-Host (T -Key "environment.installLine" -Default "  - {name} via winget id {id}" -Values @{ name = $tool.Name; id = $tool.WingetId })
  }
  Write-Host (T -Key "environment.pathNotice" -Default "A new terminal may be required after installation for PATH changes.")

  if (-not (Read-YesNo -Prompt (T -Key "environment.confirm" -Default "Install these environment tools now?") -Default $false)) {
    Write-Host (T -Key "common.cancelled" -Default "Cancelled.")
    return 0
  }

  $exitCode = 0
  foreach ($tool in $missingTools) {
    Write-Host ""
    Write-Host (T -Key "environment.installing" -Default "Installing {name}..." -Values @{ name = $tool.Name }) -ForegroundColor Cyan
    & $winget install --id $tool.WingetId -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
      Write-Host (T -Key "environment.wingetFailed" -Default "winget failed for {name} with code {code}." -Values @{ name = $tool.Name; code = $LASTEXITCODE }) -ForegroundColor Yellow
      $exitCode = $LASTEXITCODE
    }
  }

  return $exitCode
}

function Invoke-RemoveCourseInstall {
  $workspacePath = Read-TextOrDefault -Prompt (T -Key "prompt.removeWorkspace" -Default "Workspace path to remove") -Default $Script:DefaultWorkspace
  $offlineCache = Read-Host (T -Key "prompt.removeCache" -Default "Offline cache path to remove (blank to skip)")
  $removeClaude = Read-YesNo -Prompt (T -Key "prompt.removeClaude" -Default "Also uninstall global Claude Code npm package?") -Default $false
  $removeCcSwitch = Read-YesNo -Prompt (T -Key "prompt.removeCcSwitch" -Default "Also remove CC Switch app if found?") -Default $false

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
  Write-Host (T -Key "remove.title" -Default "Removal plan") -ForegroundColor Cyan
  if ($targets.Count -eq 0) {
    Write-Host (T -Key "remove.none" -Default "  File targets: none found")
  } else {
    foreach ($target in $targets) {
      Write-Host (T -Key "remove.folder" -Default "  Remove folder: {path}" -Values @{ path = $target })
    }
  }
  Write-Host (T -Key "remove.claude" -Default "  Uninstall Claude Code: {value}" -Values @{ value = $removeClaude })
  Write-Host (T -Key "remove.ccSwitch" -Default "  Uninstall CC Switch:   {value}" -Values @{ value = $removeCcSwitch })
  Write-Host (T -Key "remove.notRemoved" -Default "  Not removed: Git, Node.js, Python, Unreal, Unity, Godot, Blender")

  if (($targets.Count -eq 0) -and (-not $removeClaude) -and (-not $removeCcSwitch)) {
    Write-Host (T -Key "remove.nothing" -Default "Nothing selected for removal.")
    return 0
  }

  if (-not (Confirm-Delete)) {
    Write-Host (T -Key "common.cancelled" -Default "Cancelled.")
    return 0
  }

  $exitCode = 0
  foreach ($target in $targets) {
    Write-Host (T -Key "remove.removing" -Default "Removing {path}" -Values @{ path = $target })
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
      Write-Host (T -Key "remove.npmMissing" -Default "npm was not found; Claude Code npm uninstall skipped.") -ForegroundColor Yellow
    }
  }

  if ($removeCcSwitch) {
    $winget = Resolve-CommandPath -Name "winget"
    if ($winget) {
      & $winget uninstall --name "CC Switch" --accept-source-agreements
      if ($LASTEXITCODE -ne 0) {
        Write-Host (T -Key "remove.ccSwitchManual" -Default "winget could not uninstall CC Switch automatically. Manual uninstall may still be needed.") -ForegroundColor Yellow
      }
    } else {
      Write-Host (T -Key "remove.wingetMissing" -Default "winget was not found; CC Switch system uninstall skipped.") -ForegroundColor Yellow
    }
  }

  return $exitCode
}

function Show-Menu {
  Clear-Host
  Write-Host ""
  Write-Host (T -Key "menu.title" -Default "Game Course Agents setup menu") -ForegroundColor Cyan
  Write-Host ""
  Write-Host (T -Key "menu.option.preview" -Default "1. Preview default install")
  Write-Host (T -Key "menu.option.full" -Default "2. Install full course workspace")
  Write-Host (T -Key "menu.option.select" -Default "3. Select install content")
  Write-Host (T -Key "menu.option.core" -Default "4. Install Claude Code + CC Switch + Game Studios")
  Write-Host (T -Key "menu.option.unreal" -Default "5. Configure Unreal MCP only")
  Write-Host (T -Key "menu.option.environment" -Default "6. Install missing environment tools")
  Write-Host (T -Key "menu.option.api" -Default "7. Configure API provider")
  Write-Host (T -Key "menu.option.remove" -Default "8. Remove course-installed items")
  Write-Host (T -Key "menu.option.exit" -Default "0. Exit")
  Write-Host ""
}

if ($args.Count -gt 0) {
  $forwardedArguments = @("-Language", $Script:Language) + @($args)
  exit (Invoke-Installer -Arguments $forwardedArguments)
}

while ($true) {
  Show-Menu
  $choice = Read-Host (T -Key "menu.prompt.choice" -Default "Select an option")
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
      Write-Host (T -Key "menu.unknown" -Default "Unknown option.") -ForegroundColor Yellow
    }
  }

  if ($exitCode -ne 0) {
    Write-Host (T -Key "common.lastExit" -Default "Last action exited with code {code}." -Values @{ code = $exitCode }) -ForegroundColor Yellow
  }
  Pause-Menu
}
