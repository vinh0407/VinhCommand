import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../core/vinhcommand_core.dart';
import '../../core/utils/generate_id.dart';

class ScreenCaptureService implements ScreenRepository {
  bool _hasPermission = false;

  @override
  Future<List<ScreenSourceInfo>> getAvailableSources() async {
    final sources = <ScreenSourceInfo>[];

    try {
      final process = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class Win32 {
          [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
          [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
          [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
          [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
          public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
          [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
        }
"@
        \$windows = @()
        \$rect = New-Object Win32+RECT
        \$callback = [Win32+EnumWindowsProc] {
          param(\$hWnd, \$lParam)
          if ([Win32]::IsWindowVisible(\$hWnd)) {
            \$sb = New-Object System.Text.StringBuilder(256)
            [Win32]::GetWindowText(\$hWnd, \$sb, 256) | Out-Null
            \$title = \$sb.ToString()
            if (\$title.Length -gt 0) {
              [Win32]::GetWindowRect(\$hWnd, [ref]\$rect) | Out-Null
              \$w = \$rect.Right - \$rect.Left
              \$h = \$rect.Bottom - \$rect.Top
              if (\$w -gt 100 -and \$h -gt 100) {
                \$windows += @{Title=\$title; Width=\$w; Height=\$h; Handle=\$hWnd}
              }
            }
          }
          return \$true
        }
        [Win32]::EnumWindows(\$callback, [IntPtr]::Zero)
        \$windows | ConvertTo-Json
        ''',
      ]);

      if (process.exitCode == 0) {
        final output = process.stdout.toString().trim();
        if (output.isNotEmpty) {
          final List<dynamic> windows = jsonDecode(output);
          for (final w in windows) {
            sources.add(ScreenSourceInfo(
              id: w['Handle'].toString(),
              name: w['Title'],
              type: ScreenSource.window,
              width: w['Width'],
              height: w['Height'],
              isPrimary: false,
            ));
          }
        }
      }
    } catch (_) {}

    // Add desktop source
    sources.insert(0, ScreenSourceInfo(
      id: 'desktop',
      name: 'Desktop',
      type: ScreenSource.desktop,
      width: 1920,
      height: 1080,
      isPrimary: true,
    ));

    return sources;
  }

  @override
  Future<ScreenCapture> captureScreen(ScreenConfig config) async {
    if (!await hasPermission()) {
      throw ScreenCaptureException(
        code: 'PERMISSION_DENIED',
        message: 'Screen capture permission not granted',
        suggestedAction: 'Grant screen capture permission in Windows Settings',
      );
    }

    try {
      final data = await _captureWindowsDesktop(config);
      return ScreenCapture(
        id: generateId(),
        source: config.source,
        width: config.source == ScreenSource.desktop ? 1920 : (config.region?.width ?? 1920),
        height: config.source == ScreenSource.desktop ? 1080 : (config.region?.height ?? 1080),
        fps: config.targetFps,
        bitrate: config.targetBitrate,
        windowTitle: config.windowTitle,
        capturedAt: DateTime.now(),
        data: data,
      );
    } catch (e) {
      throw ScreenCaptureException(
        code: 'CAPTURE_FAILED',
        message: 'Failed to capture screen: $e',
      );
    }
  }

  Future<Uint8List> _captureWindowsDesktop(ScreenConfig config) async {
    // This would use Windows Graphics Capture API or BitBlt
    // For now, return placeholder
    return Uint8List(0);
  }

  @override
  Future<Stream<ScreenCapture>> startScreenStream(ScreenConfig config) async {
    if (!await hasPermission()) {
      throw ScreenCaptureException(
        code: 'PERMISSION_DENIED',
        message: 'Screen capture permission not granted',
      );
    }

    final controller = StreamController<ScreenCapture>();
    
    Timer.periodic(Duration(milliseconds: 1000 ~/ config.targetFps), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        final capture = await captureScreen(config);
        controller.add(capture);
      } catch (e) {
        controller.addError(e);
      }
    });

    return controller.stream;
  }

  @override
  Future<void> stopScreenStream(String streamId) async {
    // Implementation would track active streams
  }

  @override
  Future<bool> hasPermission() async {
    if (_hasPermission) return true;

    try {
      final process = await Process.run('powershell', [
        '-Command',
        '''
        try {
          Add-Type @"
          using System;
          using System.Runtime.InteropServices;
          public class Win32 {
            [DllImport("user32.dll")] public static extern IntPtr GetDesktopWindow();
            [DllImport("user32.dll")] public static extern IntPtr GetWindowDC(IntPtr hWnd);
            [DllImport("gdi32.dll")] public static extern bool BitBlt(IntPtr hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hdcSrc, int nXSrc, int nYSrc, int dwRop);
          }
"@
          \$hdc = [Win32]::GetWindowDC([Win32]::GetDesktopWindow())
          \$result = [Win32]::BitBlt(\$hdc, 0, 0, 1, 1, \$hdc, 0, 0, 0x00CC0020)
          \$result
        } catch { \$false }
        ''',
      ]);

      _hasPermission = process.exitCode == 0 && process.stdout.toString().trim().toLowerCase() == 'true';
      return _hasPermission;
    } catch (_) {
      return false;
    }
  }

  void dispose() {}
}

class RemoteControlService {
  bool _active = false;
  bool _permissionGranted = false;

  bool get isActive => _active;

  Future<bool> requestPermission() async {
    // This would show a system dialog
    _permissionGranted = true;
    return _permissionGranted;
  }

  Future<void> enable() async {
    if (!_permissionGranted) {
      await requestPermission();
    }
    _active = true;
  }

  Future<void> disable() async {
    _active = false;
  }

  Future<void> sendMouseEvent(int x, int y, MouseEventType type) async {
    if (!_active) {
      throw RemoteControlException(
      code: 'NOT_ACTIVE',
      message: 'Remote control not active',
    );
    }
    // Implementation would use SendInput API
  }

  Future<void> sendKeyboardEvent(String key, KeyEventType type) async {
    if (!_active) {
      throw RemoteControlException(
      code: 'NOT_ACTIVE',
      message: 'Remote control not active',
    );
    }
    // Implementation would use SendInput API
  }

  void dispose() {
    _active = false;
  }
}

enum MouseEventType {
  move,
  leftDown,
  leftUp,
  rightDown,
  rightUp,
  middleDown,
  middleUp,
  wheel,
}

enum KeyEventType {
  down,
  up,
}


