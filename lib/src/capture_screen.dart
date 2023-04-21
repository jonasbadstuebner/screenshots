import 'dart:convert';
import 'dart:io';

import 'config.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;

/// Called by integration test to capture images.
Future screenshot(
  dynamic tester, // WidgetTester
  dynamic binding, // IntegrationTestWidgetsFlutterBinding
  ScreenshotsConfig config,
  String name, {
  Duration timeout = const Duration(seconds: 30),
  bool silent = false,
}) async {
  if (config.isScreenShotsAvailable) {
    // todo: auto-naming scheme
    print("Takin screenshot '$name'");
    final pixels = await _getPixelBytes(tester, binding, name);
    final testDir = '${config.stagingDir}/$kTestScreenshotsDir';
    final fullFilePath = '$testDir/$name.$kImageExtension';

    var client = http.Client();
    try {
      var response = await client.post(
          Uri.http(
              '${const String.fromEnvironment(kEnvImageReceiverIPAddress)}:8020',
              fullFilePath),
          body: pixels);
      print('screenshot-receiver: ${utf8.decode(response.bodyBytes)}');
    } catch (e) {
      print("screenshot-send-error: $e");
    } finally {
      client.close();
    }

    if (!silent) print('Screenshot $name created at $fullFilePath');
  } else {
    if (!silent) print('Warning: screenshot $name not created');
  }
}

Future<List<int>> _getPixelBytes(
  dynamic tester, // WidgetTester
  dynamic binding, // IntegrationTestWidgetsFlutterBinding
  String name,
) async {
  if (bool.fromEnvironment('dart.library.js_util')) {
    // kIsWeb implementation
    throw 'web not yet implemented';
    // await binding.takeScreenshot(name);
    // return;
  } else if (Platform.isAndroid) {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
  }
  return await binding.takeScreenshot(name);
}
