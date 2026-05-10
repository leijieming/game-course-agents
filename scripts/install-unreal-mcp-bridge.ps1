<#
.SYNOPSIS
  Installs ChiR24/Unreal_mcp's MCP Automation Bridge into an Unreal project.

.DESCRIPTION
  This helper targets the Native MCP flow: a UE project loads the
  McpAutomationBridge plugin and exposes http://localhost:3000/mcp directly to
  Claude Code. It can detect the currently running UnrealEditor project, build
  the plugin for the detected UE version, install it into the project, enable
  Native MCP, and write project/workspace .mcp.json files.
#>

[CmdletBinding()]
param(
  [string]$UnrealProjectPath = "",
  [string]$EnginePath = "",
  [string]$WorkspacePath = (Join-Path $HOME "GameCourseAI"),
  [string]$SourcePath = "",
  [switch]$SkipBuild,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
  param(
    [Parameter(Mandatory)][string]$Status,
    [Parameter(Mandatory)][string]$Message
  )
  Write-Host ("[{0}] {1}" -f $Status, $Message)
}

function Get-RunningUnrealProject {
  $process = Get-CimInstance Win32_Process |
    Where-Object { $_.Name -like "UnrealEditor*" -and $_.CommandLine -match "\.uproject" } |
    Select-Object -First 1

  if (-not $process) {
    return $null
  }

  $projectMatch = [regex]::Match($process.CommandLine, '"(?<path>[^"]+\.uproject)"')
  if (-not $projectMatch.Success) {
    return $null
  }

  $editorMatch = [regex]::Match($process.CommandLine, '"(?<path>[^"]+UnrealEditor\.exe)"')
  $detectedEngine = ""
  if ($editorMatch.Success) {
    $detectedEngine = $editorMatch.Groups["path"].Value -replace "\\Engine\\Binaries\\Win64\\UnrealEditor\.exe$", ""
  }

  [pscustomobject]@{
    ProjectPath = $projectMatch.Groups["path"].Value
    EnginePath = $detectedEngine
  }
}

function Get-EpicEnginePath {
  param([string]$EngineAssociation)

  $manifestRoot = "C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
  if (-not (Test-Path $manifestRoot)) {
    return ""
  }

  $expectedAppName = "UE_$EngineAssociation"
  $matches = Get-ChildItem -Path $manifestRoot -Filter "*.item" -ErrorAction SilentlyContinue |
    ForEach-Object {
      try {
        $item = Get-Content -Raw -Path $_.FullName | ConvertFrom-Json
        if ($item.DisplayName -eq "Unreal Engine" -and $item.AppName -eq $expectedAppName -and (Test-Path $item.InstallLocation)) {
          $item.InstallLocation
        }
      } catch {
        $null
      }
    }

  @($matches | Select-Object -First 1)[0]
}

function Resolve-UnrealContext {
  $running = Get-RunningUnrealProject

  if ([string]::IsNullOrWhiteSpace($UnrealProjectPath) -and $running) {
    $script:UnrealProjectPath = $running.ProjectPath
  }
  if ([string]::IsNullOrWhiteSpace($EnginePath) -and $running -and -not [string]::IsNullOrWhiteSpace($running.EnginePath)) {
    $script:EnginePath = $running.EnginePath
  }

  if ([string]::IsNullOrWhiteSpace($UnrealProjectPath)) {
    throw "No Unreal project path was provided and no running UnrealEditor .uproject was detected."
  }
  if (-not (Test-Path $UnrealProjectPath)) {
    throw "Unreal project does not exist: $UnrealProjectPath"
  }

  if ([string]::IsNullOrWhiteSpace($EnginePath)) {
    $project = Get-Content -Raw -Path $UnrealProjectPath | ConvertFrom-Json
    if ($project.EngineAssociation) {
      $script:EnginePath = Get-EpicEnginePath -EngineAssociation $project.EngineAssociation
    }
  }
  if ([string]::IsNullOrWhiteSpace($EnginePath) -or -not (Test-Path $EnginePath)) {
    throw "Unable to resolve Unreal Engine path. Pass -EnginePath explicitly."
  }

  $runUat = Join-Path $EnginePath "Engine\Build\BatchFiles\RunUAT.bat"
  if (-not (Test-Path $runUat)) {
    throw "RunUAT.bat not found under engine path: $EnginePath"
  }
}

function Ensure-UnrealMcpSource {
  if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $script:SourcePath = Join-Path $WorkspacePath "_Unreal_mcp"
  }

  if (Test-Path $SourcePath) {
    Write-Step -Status "PASS" -Message "Unreal_mcp source already exists: $SourcePath"
    return
  }

  if ($DryRun) {
    Write-Step -Status "SKIP" -Message "Dry-run clone skipped: $SourcePath"
    return
  }

  New-Item -ItemType Directory -Force -Path $WorkspacePath | Out-Null
  git clone https://github.com/ChiR24/Unreal_mcp.git $SourcePath
  Write-Step -Status "PASS" -Message "Unreal_mcp source cloned: $SourcePath"
}

function Build-McpAutomationBridge {
  if ($SkipBuild) {
    Write-Step -Status "SKIP" -Message "Plugin build skipped by parameter."
    return
  }

  $pluginFile = Join-Path $SourcePath "plugins\McpAutomationBridge\McpAutomationBridge.uplugin"
  if (-not (Test-Path $pluginFile)) {
    throw "McpAutomationBridge.uplugin not found: $pluginFile"
  }

  $packageRoot = Join-Path $env:TEMP "UnrealMcpPackage"
  $script:PackagePath = Join-Path $packageRoot "McpAutomationBridge"
  $runUat = Join-Path $EnginePath "Engine\Build\BatchFiles\RunUAT.bat"

  if ($DryRun) {
    Write-Step -Status "SKIP" -Message "Dry-run BuildPlugin skipped: $PackagePath"
    return
  }

  if (Test-Path $PackagePath) {
    Remove-Item -LiteralPath $PackagePath -Recurse -Force
  }
  & $runUat BuildPlugin "-Plugin=$pluginFile" "-Package=$PackagePath" -TargetPlatforms=Win64 -Rocket
  if ($LASTEXITCODE -ne 0) {
    throw "BuildPlugin failed."
  }
  Write-Step -Status "PASS" -Message "Plugin built for Win64: $PackagePath"
}

function Install-ProjectPlugin {
  $projectRoot = Split-Path -Parent $UnrealProjectPath
  $pluginsRoot = Join-Path $projectRoot "Plugins"
  $target = Join-Path $pluginsRoot "McpAutomationBridge"

  if ($SkipBuild) {
    $script:PackagePath = Join-Path $SourcePath "plugins\McpAutomationBridge"
  }

  if ($DryRun) {
    Write-Step -Status "SKIP" -Message "Dry-run plugin copy skipped: $target"
    return
  }

  if (-not (Test-Path $PackagePath)) {
    throw "Plugin package path not found: $PackagePath"
  }

  New-Item -ItemType Directory -Force -Path $pluginsRoot | Out-Null
  if (Test-Path $target) {
    $backup = Join-Path $pluginsRoot ("McpAutomationBridge.backup-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    Move-Item -LiteralPath $target -Destination $backup
    Write-Step -Status "PASS" -Message "Existing plugin backed up: $backup"
  }
  Copy-Item -Recurse -Force -LiteralPath $PackagePath -Destination $target
  Write-Step -Status "PASS" -Message "Plugin installed: $target"
}

function Enable-ProjectPlugin {
  $project = Get-Content -Raw -Path $UnrealProjectPath | ConvertFrom-Json
  if (-not $project.Plugins) {
    $project | Add-Member -NotePropertyName "Plugins" -NotePropertyValue @() -Force
  }

  $required = @(
    @{ Name = "McpAutomationBridge"; TargetAllowList = @("Editor") },
    @{ Name = "EditorScriptingUtilities"; TargetAllowList = @("Editor") },
    @{ Name = "Niagara" }
  )

  $plugins = @($project.Plugins)
  foreach ($entry in $required) {
    $existing = $plugins | Where-Object { $_.Name -eq $entry.Name } | Select-Object -First 1
    if (-not $existing) {
      $newEntry = [pscustomobject]@{ Name = $entry.Name; Enabled = $true }
      if ($entry.TargetAllowList) {
        $newEntry | Add-Member -NotePropertyName "TargetAllowList" -NotePropertyValue $entry.TargetAllowList
      }
      $plugins += $newEntry
    } else {
      $existing.Enabled = $true
    }
  }
  $project.Plugins = $plugins

  if ($DryRun) {
    Write-Step -Status "SKIP" -Message "Dry-run .uproject update skipped."
    return
  }

  $project | ConvertTo-Json -Depth 10 | Set-Content -Path $UnrealProjectPath -Encoding UTF8
  Write-Step -Status "PASS" -Message "Project plugins enabled: $UnrealProjectPath"
}

function Enable-NativeMcpConfig {
  $projectRoot = Split-Path -Parent $UnrealProjectPath
  $configPath = Join-Path $projectRoot "Config\DefaultGame.ini"
  $section = @"
[/Script/McpAutomationBridge.McpAutomationBridgeSettings]
bAlwaysListen=True
ListenHost=127.0.0.1
ListenPorts=8090,8091
bMultiListen=True
bEnableNativeMCP=True
NativeMCPPort=3000
bLoadAllToolsOnStart=True
"@

  $content = ""
  if (Test-Path $configPath) {
    $content = Get-Content -Raw -Path $configPath
  }
  $content = [regex]::Replace($content, "(?ms)^\[/Script/McpAutomationBridge\.McpAutomationBridgeSettings\]\r?\n.*?(?=^\[|\z)", "")
  $content = $content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $section + [Environment]::NewLine

  if ($DryRun) {
    Write-Step -Status "SKIP" -Message "Dry-run Native MCP config update skipped."
    return
  }

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $configPath) | Out-Null
  Set-Content -Path $configPath -Value $content -Encoding UTF8
  Write-Step -Status "PASS" -Message "Native MCP enabled in config: $configPath"
}

function Write-McpJson {
  param([Parameter(Mandatory)][string]$Path)

  $json = [pscustomobject]@{ mcpServers = [pscustomobject]@{} }
  if (Test-Path $Path) {
    $json = Get-Content -Raw -Path $Path | ConvertFrom-Json
    if (-not $json.mcpServers) {
      $json | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([pscustomobject]@{}) -Force
    }
  }

  $json.mcpServers | Add-Member -NotePropertyName "unreal-engine" -NotePropertyValue ([pscustomobject]@{
    type = "url"
    url = "http://localhost:3000/mcp"
  }) -Force

  if ($DryRun) {
    Write-Step -Status "SKIP" -Message "Dry-run .mcp.json update skipped: $Path"
    return
  }

  $text = $json | ConvertTo-Json -Depth 10
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $text, $encoding)
  Write-Step -Status "PASS" -Message "MCP client config written: $Path"
}

Resolve-UnrealContext
Ensure-UnrealMcpSource
Build-McpAutomationBridge
Install-ProjectPlugin
Enable-ProjectPlugin
Enable-NativeMcpConfig

$projectRoot = Split-Path -Parent $UnrealProjectPath
Write-McpJson -Path (Join-Path $projectRoot ".mcp.json")
New-Item -ItemType Directory -Force -Path $WorkspacePath | Out-Null
Write-McpJson -Path (Join-Path $WorkspacePath ".mcp.json")

Write-Step -Status "NEXT" -Message "Restart Unreal Editor, then verify http://localhost:3000/mcp is listening."
