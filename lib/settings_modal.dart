import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

class SettingsModal extends StatefulWidget {
  final int initialThreshold;
  final Function(int) onSave;
  const SettingsModal({
    super.key,
    required this.initialThreshold,
    required this.onSave,
  });

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final TextEditingController _thresholdController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _thresholdController.text = widget.initialThreshold.toString();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final input = _thresholdController.text;
    final parsedInput = int.tryParse(input);

    if (parsedInput == null || parsedInput <= 0) {
      setState(() {
        _errorText = 'Please enter a valid number greater than 0';
      });
    } else {
      widget.onSave(parsedInput);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: const BoxDecoration(
          color: bubbleBlueBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Set break interval (minutes):',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Minutes',
                hintText: 'e.g., 30',
                errorText: _errorText,
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: bubbleBlueSecondary),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black26),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _saveSettings,
                  child: const Text('Save', style: TextStyle(color: bubbleBlueSecondary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}