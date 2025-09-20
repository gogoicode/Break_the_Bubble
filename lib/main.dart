import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'overlay_popup.dart';
import 'initial_permission_screen.dart';
import 'constants.dart';
import 'package:btb/overlay_popup.dart';

/// The entry point for Workmanager's background tasks.
/// This function runs periodically to check for continuous usage.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    int threshold = prefs.getInt('breakThreshold') ?? 25;
    int continuousTime = prefs.getInt('continuousTime') ?? 0;
    int lastActiveTime =
        prefs.getInt('lastActiveTime') ?? DateTime.now().millisecondsSinceEpoch;

    // Check if enough time has passed to trigger a break.
    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = now - lastActiveTime;

    if (delta > 10000) {
      continuousTime = 0;
    } else {
      continuousTime += delta ~/ 60000;
    }
    lastActiveTime = now;
    await prefs.setInt('continuousTime', continuousTime);
    await prefs.setInt('lastActiveTime', lastActiveTime);

    if (continuousTime >= threshold) {
      final bool permissionGranted =
          prefs.getBool('permissionGranted') ?? false;

      if (permissionGranted) {
        await FlutterOverlayWindow.showOverlay(
          alignment: OverlayAlignment.center,
          height: 300,
          width: 300,
        );
      }
      // Reset the time after showing the pop-up, regardless of whether it shows.
      await prefs.setInt('continuousTime', 0);
    }

    return Future.value(true);
  });
}

/// The entry point for the overlay window.
/// This function is called by the `flutter_overlay_window` package to build the UI that appears over other apps.
@pragma('vm:entry-point')
void overlayEntrypoint() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OverlayScreen()),
  );
}

// Main entry point for the application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(const BreakTheBubbleApp());
}

class BreakTheBubbleApp extends StatelessWidget {
  const BreakTheBubbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Break the Bubble',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: bubbleBluePrimary),
        useMaterial3: true,
      ),
      home: const InitialPermissionScreen(),
    );
  }
}
