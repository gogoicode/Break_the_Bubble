import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'constants.dart'; // Ensure this line is present
import 'settings_modal.dart';
import 'break_prompt_modal.dart';

// ... rest of the file

class BreakTheBubbleHomePage extends StatefulWidget {
  final int breakThreshold;
  const BreakTheBubbleHomePage({super.key, required this.breakThreshold});

  @override
  State<BreakTheBubbleHomePage> createState() => _BreakTheBubbleHomePageState();
}

class _BreakTheBubbleHomePageState extends State<BreakTheBubbleHomePage> {
  int _continuousTime = 0;
  int _breakCount = 0;
  int _lastActiveTime = 0;
  int _streakCount = 0;
  Timer? _timer;
  bool _isBreakTime = false;
  int _breakThreshold = 25;

  @override
  void initState() {
    super.initState();
    _loadState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant BreakTheBubbleHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.breakThreshold != _breakThreshold) {
      _breakThreshold = widget.breakThreshold;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _continuousTime = prefs.getInt('continuousTime') ?? 0;
      _breakCount = prefs.getInt('breakCount') ?? 0;
      _lastActiveTime =
          prefs.getInt('lastActiveTime') ??
          DateTime.now().millisecondsSinceEpoch;
      _streakCount = prefs.getInt('streakCount') ?? 0;
      _breakThreshold = prefs.getInt('breakThreshold') ?? 25;
    });
  }

  void _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('continuousTime', _continuousTime);
    await prefs.setInt('breakCount', _breakCount);
    await prefs.setInt('lastActiveTime', DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('streakCount', _streakCount);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final delta = now - _lastActiveTime;

      if (delta < 10000) {
        setState(() {
          _continuousTime++;
        });
        _saveState();
      } else {
        setState(() {
          _continuousTime = 0;
        });
        _saveState();
      }

      if (_continuousTime >= _breakThreshold * 60) {
        _continuousTime = 0;
        _showBreakPrompt();
      }

      _lastActiveTime = now;
    });
  }

  void _showBreakPrompt() {
    _timer?.cancel();
    setState(() {
      _isBreakTime = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BreakPromptModal(
          onBreakComplete: () {
            Navigator.of(context).pop(); // Dismiss the pop-up
            setState(() {
              _breakCount++;
              _streakCount++;
              _isBreakTime = false;
              _continuousTime = 0;
            });
            _saveState();
            _startTimer(); // Restart the timer
          },
          onBreakSkip: () {
            Navigator.of(context).pop(); // Dismiss the pop-up
            setState(() {
              _isBreakTime = false;
              _continuousTime = 0;
              _streakCount = 0; // The streak is now reset to 0
            });
            _saveState();
            _startTimer(); // Restart the timer
          },
        );
      },
    );
  }

  void _resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _continuousTime = 0;
      _breakCount = 0;
      _streakCount = 0;
      _lastActiveTime = DateTime.now().millisecondsSinceEpoch;
      _breakThreshold = 25;
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All data has been reset.')));
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SettingsModal(
          initialThreshold: _breakThreshold,
          onSave: (newThreshold) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('breakThreshold', newThreshold);
            setState(() {
              _breakThreshold = newThreshold;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved successfully!')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    Color color = Colors.white,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: bubbleBlueSecondary),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Break the Bubble',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bubbleBluePrimary,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bubbleBlueBackground, bubbleBlueLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatsDisplay(),
              const SizedBox(height: 24),
              _buildTimerDisplay(),
              const SizedBox(height: 24),
              _buildControlButtons(),
              const SizedBox(height: 24),
              _buildActionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDisplay() {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Breaks Taken',
            value: '$_breakCount',
            icon: Icons.free_breakfast,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            title: 'Streak',
            value: '$_streakCount',
            icon: Icons.local_fire_department,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Continuous Usage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatTime(_continuousTime),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: bubbleBluePrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _isBreakTime ? null : _showBreakPrompt,
          icon: const Icon(Icons.pause, color: Colors.white),
          label: const Text(
            'Take a Break',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: bubbleBluePrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsList() {
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
            onTap: _resetData,
          ),
          const Divider(),
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info, color: bubbleBluePrimary),
            title: Text('Version'),
            subtitle: Text('1.4.0 - Progress Edition'),
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
          color: Colors.black87,
        ),
      ),
    );
  }
}
