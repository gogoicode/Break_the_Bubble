import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'constants.dart';
import 'settings_modal.dart';
import 'break_prompt_modal.dart';

class BreakTheBubbleHomePage extends StatefulWidget {
  const BreakTheBubbleHomePage({super.key});

  @override
  State<BreakTheBubbleHomePage> createState() => _BreakTheBubbleHomePageState();
}

class _BreakTheBubbleHomePageState extends State<BreakTheBubbleHomePage> {
  int _continuousTime = 0;
  int _breakCount = 0;
  int _streakCount = 0;
  int _breakThreshold = 25;
  late StreamSubscription _overlayListener;

  @override
  void initState() {
    super.initState();
    _loadState();
    _initOverlayListener();
  }

  @override
  void dispose() {
    _overlayListener.cancel();
    super.dispose();
  }

  void _initOverlayListener() {
    _overlayListener = FlutterOverlayWindow.overlayListener.listen((message) {
      if (message == 'breakComplete') {
        _incrementBreakCount();
      }
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _breakCount = prefs.getInt('breakCount') ?? 0;
      _streakCount = prefs.getInt('streakCount') ?? 0;
      _continuousTime = prefs.getInt('continuousTime') ?? 0;
      _breakThreshold = prefs.getInt('breakThreshold') ?? 25;
    });
  }

  Future<void> _incrementBreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    int newBreakCount = (prefs.getInt('breakCount') ?? 0) + 1;
    await prefs.setInt('breakCount', newBreakCount);
    setState(() {
      _breakCount = newBreakCount;
    });
  }

  Future<void> _resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('continuousTime', 0);
    await prefs.setInt('breakCount', 0);
    await prefs.setInt('streakCount', 0);
    setState(() {
      _continuousTime = 0;
      _breakCount = 0;
      _streakCount = 0;
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SettingsModal(
            initialThreshold: _breakThreshold,
            onSave: (newThreshold) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('breakThreshold', newThreshold);
              setState(() {
                _breakThreshold = newThreshold;
              });
              await Workmanager().cancelByUniqueName(continuousUsageTask);
              await Workmanager().registerPeriodicTask(
                continuousUsageTask,
                'ContinuousUsageTask',
                frequency: const Duration(minutes: 15),
                constraints: Constraints(
                  networkType: NetworkType.notRequired,
                  requiresBatteryNotLow: true,
                ),
                inputData: {'breakThreshold': newThreshold},
              );
            },
          ),
        );
      },
    );
  }

  void _showBreakPrompt() {
    showDialog(
      context: context,
      builder: (context) => BreakPromptModal(
        onBreakComplete: () {
          _incrementBreakCount();
          Navigator.of(context).pop();
        },
        onBreakSkip: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bubbleBlueBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgressCard(),
              const SizedBox(height: 20),
              _buildActionCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bubbleBluePrimary,
                  ),
            ),
            const SizedBox(height: 20),
            _buildMetric('Breaks Taken', _breakCount, Icons.star_border),
            const Divider(),
            _buildMetric('Current Streak', _streakCount, Icons.local_fire_department),
            const Divider(),
            _buildMetric('Threshold', _breakThreshold, Icons.timer),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String title, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: bubbleBlueSecondary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: bubbleBluePrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: Column(
        children: [
          _buildSectionHeader('Actions'),
          ListTile(
            leading: const Icon(Icons.settings, color: bubbleBluePrimary),
            title: const Text('Settings'),
            subtitle: const Text('Adjust break time intervals'),
            onTap: _showSettings,
          ),
          const Divider(),
          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Data'),
            subtitle: const Text('Clear all progress and start fresh'),
            onTap: () {
              // Add a confirmation dialog before resetting
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Data?'),
                  content: const Text(
                      'Are you sure you want to reset all your progress? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _resetData();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Reset', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}