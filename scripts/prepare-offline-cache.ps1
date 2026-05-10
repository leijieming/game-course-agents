<#
.SYNOPSIS
  Prepares an offline cache directory from manifest cacheArtifacts entries.

.DESCRIPTION
  URL artifacts are downloaded. Command-based artifacts are recorded in the
  index so instructors can prepare them with the matching package manager.
#>

[CmdletBinding()]
param(
  [string]$CachePath = (Join-Path (Get-Location) "offline-cache"),
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$manifestRoot = Join-Path $root "manifests"
$index = [ordered]@{
  generatedAt = (Get-Date).ToString("o")
  cachePath = $CachePath
  artifacts = @()
}

function Ensure-Directory {
  param([Parameter(Mandatory)][string]$Path)
  if ($DryRun) {
    Write-Host "[SKIP] Would create $Path"
    return
  }
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

Ensure-Directory -Path $CachePath

Get-ChildItem -Path $manifestRoot -Filter "*.json" | Sort-Object Name | ForEach-Object {
  $manifest = Get-Content -Raw -Path $_.FullName | ConvertFrom-Json
  foreach ($artifact in $manifest.cacheArtifacts) {
    $target = Join-Path $CachePath $artifact.file
    $targetDir = Split-Path -Parent $target
    Ensure-Directory -Path $targetDir

    $record = [ordered]@{
      module = $manifest.id
      id = $artifact.id
      file = $artifact.file
      source = $artifact.source
      downloaded = $false
      sha256 = $null
    }

    if ($artifact.source -match "^https?://") {
      if ($DryRun) {
        Write-Host "[SKIP] Would download $($artifact.source) -> $target"
      } else {
        Invoke-WebRequest -Uri $artifact.source -OutFile $target
        $record.downloaded = $true
        $record.sha256 = (Get-FileHash -Algorithm SHA256 -Path $target).Hash.ToLowerInvariant()
      }
    } else {
      Write-Host "[INFO] Manual cache command for $($manifest.id): $($artifact.source)"
    }

    $index.artifacts += $record
  }
}

$indexPath = Join-Path $CachePath "manifest-cache-index.json"
if ($DryRun) {
  Write-Host "[SKIP] Would write $indexPath"
} else {
  $index | ConvertTo-Json -Depth 8 | Set-Content -Path $indexPath -Encoding UTF8
  Write-Host "[PASS] Offline cache index written: $indexPath"
}
