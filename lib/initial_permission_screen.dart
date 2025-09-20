import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'break_the_bubble_home_page.dart';
import 'constants.dart';

class InitialPermissionScreen extends StatefulWidget {
  const InitialPermissionScreen({super.key});

  @override
  State<InitialPermissionScreen> createState() =>
      _InitialPermissionScreenState();
}

class _InitialPermissionScreenState extends State<InitialPermissionScreen> {
  bool _permissionGranted = false;
  int _breakThreshold = 25;

  @override
  void initState() {
    super.initState();
    _loadStateAndThreshold();
  }

  Future<void> _loadStateAndThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final bool permissionGranted = prefs.getBool('permissionGranted') ?? false;
    final int breakThreshold = prefs.getInt('breakThreshold') ?? 25;

    setState(() {
      _permissionGranted = permissionGranted;
      _breakThreshold = breakThreshold;
    });
  }

  Future<void> _registerWorkmanagerTask() async {
    // Store the break threshold
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('breakThreshold', _breakThreshold);

    // Register periodic task
    await Workmanager().registerPeriodicTask(
      continuousUsageTask, // unique name
      continuousUsageTask, // task identifier (handled in callbackDispatcher)
      frequency: const Duration(minutes: 15),
      // Updated to the correct enum for the new workmanager version
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Mark permission granted and go to home page
    await _setPermissionGranted(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              BreakTheBubbleHomePage(breakThreshold: _breakThreshold),
        ),
      );
    }
  }

  Future<void> _setPermissionGranted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissionGranted', value);
    setState(() {
      _permissionGranted = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionGranted) {
      return BreakTheBubbleHomePage(breakThreshold: _breakThreshold);
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                size: 80,
                color: bubbleBluePrimary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Permission Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'This app needs permission to run in the background to monitor your phone usage and remind you to take breaks. Please grant this permission to allow a pop-up to show above other apps.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final isPermissionGranted =
                      await FlutterOverlayWindow.isPermissionGranted();
                  if (!isPermissionGranted) {
                    await FlutterOverlayWindow.requestPermission();
                  }

                  if (await FlutterOverlayWindow.isPermissionGranted()) {
                    await _registerWorkmanagerTask();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Overlay permission denied. Cannot run break reminders.',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bubbleBluePrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Grant Permission',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
