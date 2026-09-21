# VinhCommand Windows Build Guide

## Prerequisites

1. **Flutter SDK** (3.13+)
   - `flutter --version` to verify
   
2. **Visual Studio 2022** with:
   - Desktop development with C++ workload
   - Windows 10/11 SDK

3. **Inno Setup 6+** (for installer) - Optional
   - Download: https://jrsoftware.org/isinfo.php

## Quick Build

```powershell
# Run the complete build script
.\build_windows.ps1 -CreateShortcuts -CreateInstaller
```

Or manually:

```powershell
# 1. Clean & get dependencies
flutter clean
flutter pub get

# 2. Run code generation (required for freezed/json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Build Windows Release
flutter build windows --release
```

## Build Output

The executable will be at:
```
build\windows\x64\runner\Release\vinhcommand_desktop.exe
```

Required files to distribute:
- `vinhcommand_desktop.exe`
- `flutter_windows.dll`
- `data\` folder (contains flutter_assets, icudtl.dat, AOT snapshot)

## Create Shortcuts

```powershell
# Create Desktop & Start Menu shortcuts
.\create_shortcuts.ps1 -ExePath "build\windows\x64\runner\Release\vinhcommand_desktop.exe"
```

Options:
- `-AppName "VinhCommand"` - Application name
- `-IconPath "path\to\icon.ico"` - Custom icon
- Run as Administrator for All Users Start Menu shortcut

## Create Installer (Optional)

```powershell
# Requires Inno Setup 6+
.\create_installer.ps1 -SourceDir "build\windows\x64\runner\Release" -CreateInstaller
```

Options:
- `-InstallDir "C:\Program Files\VinhCommand"` - Installation directory
- `-Version "1.0.0"` - Version number
- `-OutputDir ".\installer"` - Output directory for installer

## Troubleshooting

### Build Fails with "toMap/fromMap not found"
Run code generation:
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build Fails with "Process/Server/AccessCodeId not found"
The codebase has missing type definitions. Check that all entities in `lib/core/entities/` and `lib/core/value_objects/` have proper Freezed/JsonSerializable annotations.

### Visual Studio Build Errors
1. Open `build\windows\runner\vinhcommand_desktop.sln` in Visual Studio
2. Build in Release mode
3. Check for missing Windows SDK or C++ workload

### Missing DLLs at Runtime
Ensure these are in the same folder as the exe:
- `flutter_windows.dll`
- `data\flutter_assets\` (entire folder)
- `data\icudtl.dat`
- `data\app.so` (AOT snapshot)

## Distribution Checklist

- [ ] `vinhcommand_desktop.exe`
- [ ] `flutter_windows.dll`
- [ ] `data\flutter_assets\` (folder)
- [ ] `data\icudtl.dat`
- [ ] `data\app.so` (Release AOT snapshot)
- [ ] Any plugin DLLs from `build\windows\x64\runner\Release\`

## Application Configuration

The app is configured in:
- `windows/runner/CMakeLists.txt` - Binary name, version
- `windows/runner/Runner.rc` - Version info, icon, metadata
- `pubspec.yaml` - App name, version, assets
- `windows/runner/resources/app_icon.ico` - Application icon

## Testing the Release Build

```powershell
# Run the built executable directly
cd build\windows\x64\runner\Release
.\vinhcommand_desktop.exe
```

The app should launch without requiring Flutter, VS Code, or any development tools.

## Known Issues

1. **Database entities need code generation** - Run `flutter pub run build_runner build` after any entity changes
2. **PowerShell scripts in Dart strings** - Use raw strings (r'''...''') to avoid $ interpolation issues
3. **Missing repository implementations** - Some repositories throw UnimplementedError; use WindowsSystemRepository/ProcessMonitorService instead

## Build Command Summary

```powershell
# Complete build with shortcuts and installer
.\build_windows.ps1 -CreateShortcuts -CreateInstaller

# Or step by step:
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build windows --release
.\create_shortcuts.ps1 -ExePath "build\windows\x64\runner\Release\vinhcommand_desktop.exe"
.\create_installer.ps1 -SourceDir "build\windows\x64\runner\Release"
```