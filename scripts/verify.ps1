param([switch]$Build)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot 'vinhcommand_desktop')
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'Flutter dependencies failed' }
  flutter analyze --no-pub --no-fatal-infos
  if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed' }
  flutter test --no-pub
  if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed' }
  if ($Build) {
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'Windows build failed' }
  }
} finally { Pop-Location }
Push-Location (Join-Path $PSScriptRoot 'vinhcommand-android')
try {
  if ($Build) { & .\gradlew.bat :app:testDebugUnitTest :app:assembleDebug --console=plain }
  else { & .\gradlew.bat :app:testDebugUnitTest --console=plain }
  if ($LASTEXITCODE -ne 0) { throw 'Android verification failed' }
} finally { Pop-Location }
