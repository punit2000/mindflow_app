param(
    [ValidateSet('debug', 'release')]
    [string]$Mode = 'debug'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$versionLine = Select-String -Path $pubspecPath -Pattern '^version:\s*([0-9]+(?:\.[0-9]+){2})\+([0-9]+)' | Select-Object -First 1

if ($null -eq $versionLine -or $versionLine.Line -notmatch '^version:\s*([0-9]+(?:\.[0-9]+){2})\+([0-9]+)') {
    throw 'Could not read a semantic version and build number from pubspec.yaml.'
}

$versionName = $Matches[1]
$buildNumber = $Matches[2]
Push-Location $projectRoot
try {
    & flutter build apk "--$Mode"
    if ($LASTEXITCODE -ne 0) { throw "Flutter APK build failed with exit code $LASTEXITCODE." }

    $source = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-$Mode.apk"
    $outputDirectory = Join-Path $projectRoot 'build\app\outputs\versioned-apk'
    $destination = Join-Path $outputDirectory "MindFlow-v$versionName+$buildNumber-$Mode.apk"
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
    Write-Output "Versioned APK created: $destination"
} finally {
    Pop-Location
}
