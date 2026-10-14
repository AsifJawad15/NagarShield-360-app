param([string]$Flutter = 'C:\flutter\bin\flutter.bat')

$project = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $project
New-Item -ItemType Directory -Path 'dist' -Force | Out-Null
New-Item -ItemType Directory -Path 'build' -Force | Out-Null
$env:CI = 'true'
if (-not (Test-Path -LiteralPath 'config/showcase.local.json')) {
  throw 'Missing config/showcase.local.json; run node scripts/prepare_public_demo.mjs'
}
$log = 'build/android-showcase.log'
& $Flutter build apk --split-per-abi --no-pub '--dart-define-from-file=config/showcase.local.json' *> $log
if ($LASTEXITCODE -ne 0) {
  throw "Android build failed. See $log (may contain encoded build config)."
}
foreach ($abi in @('armeabi-v7a', 'arm64-v8a', 'x86_64')) {
  $apk = "build/app/outputs/flutter-apk/app-$abi-release.apk"
  if (-not (Test-Path -LiteralPath $apk)) { throw "APK missing after build: $apk" }
  $destination = "dist/nagarshield-showcase-$abi.apk"
  Copy-Item -LiteralPath $apk -Destination $destination -Force
  Write-Output "Built $destination"
}
$universalLog = 'build/android-showcase-universal.log'
& $Flutter build apk --no-pub '--dart-define-from-file=config/showcase.local.json' *> $universalLog
if ($LASTEXITCODE -ne 0) {
  throw "Universal Android build failed. See $universalLog (may contain encoded build config)."
}
Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' -Destination 'dist/nagarshield-showcase-universal.apk' -Force
Write-Output 'Built dist/nagarshield-showcase-universal.apk'
foreach ($slot in @('a', 'b', 'c')) {
  foreach ($abi in @('armeabi-v7a', 'arm64-v8a', 'x86_64')) {
    $oldApk = "dist/nagarshield-public-$slot-$abi.apk"
    if (Test-Path -LiteralPath $oldApk) { Remove-Item -LiteralPath $oldApk }
  }
  $oldApk = "dist/nagarshield-public-$slot.apk"
  if (Test-Path -LiteralPath $oldApk) { Remove-Item -LiteralPath $oldApk }
}
