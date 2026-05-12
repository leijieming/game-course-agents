Set-StrictMode -Version Latest

try {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {
  # Older hosts can ignore console encoding changes.
}

$Script:I18nLanguage = "en-US"
$Script:I18nStrings = @{}
$Script:I18nDefaults = @{
  "installer.started" = "Installer started."
  "report.dryRun" = "Dry-run mode: health report would be written."
  "report.written" = "Health report written."
  "menu.title" = "Game Course Agents setup menu"
}

function Initialize-I18n {
  param(
    [Parameter(Mandatory)][string]$Root,
    [ValidateSet("zh-CN", "en-US")]
    [string]$Language = "en-US"
  )

  $Script:I18nLanguage = $Language
  $Script:I18nStrings = @{}

  if ($Language -eq "en-US") {
    return
  }

  $languagePath = Join-Path $Root ("locales\{0}.json" -f $Language)
  if (-not (Test-Path -LiteralPath $languagePath)) {
    return
  }

  $pack = Get-Content -Raw -Path $languagePath -Encoding UTF8 | ConvertFrom-Json
  foreach ($property in $pack.strings.PSObject.Properties) {
    $Script:I18nStrings[$property.Name] = [string]$property.Value
  }
}

function T {
  param(
    [Parameter(Mandatory)][string]$Key,
    [string]$Default = "",
    [hashtable]$Values = @{}
  )

  $text = $null
  if ($Script:I18nStrings.ContainsKey($Key)) {
    $text = $Script:I18nStrings[$Key]
  } elseif ($Script:I18nDefaults.ContainsKey($Key)) {
    $text = $Script:I18nDefaults[$Key]
  } elseif (-not [string]::IsNullOrWhiteSpace($Default)) {
    $text = $Default
  } else {
    $text = $Key
  }

  foreach ($name in $Values.Keys) {
    $text = $text.Replace(("{{{0}}}" -f $name), [string]$Values[$name])
  }

  return $text
}
