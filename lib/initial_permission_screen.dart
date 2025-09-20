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
  // A variable to store the break threshold from SharedPreferences.
  // This is used to register the workmanager task.
  int _breakThreshold = 25;

  @override
  void initState() {
    super.initState();
    _loadBreakThreshold();
  }

  // A helper function to load the threshold from storage.
  Future<void> _loadBreakThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _breakThreshold = prefs.getInt('breakThreshold') ?? 25;
    });
  }

  // This function registers the workmanager task with the saved threshold.
  Future<void> _registerWorkmanagerTask() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('breakThreshold', _breakThreshold);

    await Workmanager().registerPeriodicTask(
      continuousUsageTask,
      continuousUsageTask,
      frequency: const Duration(minutes: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.perm_device_information,
                size: 80,
                color: bubbleBluePrimary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Permission Required',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'To receive break reminders while using other apps, please grant the "Display over other apps" permission.',
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
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('permissionGranted', true);
                    await _registerWorkmanagerTask(); // Call the newly added function
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BreakTheBubbleHomePage(),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Overlay permission denied. Cannot run break reminders.',
                          ),
                        ),
                      );
                    }
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
