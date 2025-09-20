import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'initial_permission_screen.dart';
import 'break_the_bubble_home_page.dart';
import 'overlay_popup.dart';
import 'callback_dispatcher.dart';
import 'constants.dart';

/// The entry point for the overlay window.
@pragma('vm:entry-point')
void overlayEntrypoint() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayScreen(),
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  runApp(const BreakTheBubbleApp());
}

class BreakTheBubbleApp extends StatelessWidget {
  const BreakTheBubbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPermissionStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final bool permissionGranted = snapshot.data ?? false;
        return MaterialApp(
          title: 'Break the Bubble',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: bubbleBluePrimary),
            useMaterial3: true,
          ),
          home: permissionGranted
              ? const BreakTheBubbleHomePage()
              : const InitialPermissionScreen(),
        );
      },
    );
  }

  Future<bool> _checkPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('permissionGranted') ?? false;
  }
}