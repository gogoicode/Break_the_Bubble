import 'dart:math';
import 'package:flutter/material.dart';
import 'constants.dart';

class BreakPromptModal extends StatelessWidget {
  final VoidCallback onBreakComplete;
  final VoidCallback onBreakSkip; // New callback for skipping the break

  const BreakPromptModal({
    super.key,
    required this.onBreakComplete,
    required this.onBreakSkip, // Add the new callback to the constructor
  });

  String _getRandomPrompt() {
    final random = Random();
    return breakPrompts[random.nextInt(breakPrompts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: bubbleBlueLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: bubbleBluePrimary, width: 2),
      ),
      title: const Text(
        'Time for a Break!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Icon(Icons.watch_later_outlined, size: 60, color: bubbleBlueSecondary),
            const SizedBox(height: 16),
            Text(
              _getRandomPrompt(),
              style: const TextStyle(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onBreakComplete, // This button completes the break
              style: ElevatedButton.styleFrom(
                backgroundColor: bubbleBluePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'I\'ve taken my break!',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBreakSkip, // This button skips the break
              child: const Text(
                'Skip Break',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}