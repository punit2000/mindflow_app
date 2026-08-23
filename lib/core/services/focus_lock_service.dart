import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges to the Android [FocusLockService], which blocks selected apps by
/// showing a full-screen overlay whenever one of the chosen apps is opened
/// during a focus session.
class FocusLockService {
  static const MethodChannel _channel = MethodChannel(
    'com.antigravity.flow_notes_reminders/focus_lock',
  );

  /// Whether this platform supports app blocking via overlay.
  bool get isSupported => Platform.isAndroid;

  Future<bool> canDrawOverlay() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlay') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openOverlaySettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('openOverlaySettings');
    } catch (_) {}
  }

  Future<bool> canAccessUsageStats() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('canAccessUsageStats') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openUsageStatsSettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('openUsageStatsSettings');
    } catch (_) {}
  }

  /// Returns installed launchable apps as [package, label] pairs.
  Future<List<({String package, String label})>> listInstalledApps() async {
    if (!isSupported) return [];
    try {
      final raw = await _channel
              .invokeListMethod<Map<Object?, Object?>>('listInstalledApps') ??
          [];
      return [
        for (final map in raw)
          (
            package: (map['package'] ?? '') as String,
            label: (map['label'] ?? '') as String,
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> start(int minutes, List<String> packages) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('start', {
        'minutes': minutes,
        'packages': packages,
      });
    } catch (_) {}
  }

  Future<void> stop() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}