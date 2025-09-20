import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'constants.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    int threshold = prefs.getInt('breakThreshold') ?? 25;
    int continuousTime = prefs.getInt('continuousTime') ?? 0;
    int lastActiveTime =
        prefs.getInt('lastActiveTime') ?? DateTime.now().millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = now - lastActiveTime;

    if (delta > 10000) {
      // Phone inactive for more than 10s, reset
      continuousTime = 0;
    } else {
      continuousTime += delta ~/ 60000;
    }
    lastActiveTime = now;
    await prefs.setInt('continuousTime', continuousTime);
    await prefs.setInt('lastActiveTime', lastActiveTime);

    final bool permissionGranted = prefs.getBool('permissionGranted') ?? false;

    if (permissionGranted && continuousTime >= threshold) {
      continuousTime = 0;
      await prefs.setInt('continuousTime', 0);
      await FlutterOverlayWindow.showOverlay(
        alignment: OverlayAlignment.center,
        enableDrag: false,
        height: 350,
        width: 300,
      );
    }
    return Future.value(true);
  });
}