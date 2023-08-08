import 'dart:convert';
import 'dart:io';

import 'config.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;

/// Called by integration test to capture images.
Future screenshot(
  dynamic tester, // WidgetTester
  dynamic binding, // IntegrationTestWidgetsFlutterBinding
  dynamic integrationTestChannel, // MethodChannel
  dynamic platformDispatcher, // PlatformDispatcher.instance
  ScreenshotsConfig config,
  String name, {
  Duration? timeout,
  bool silent = false,
}) async {
  if (config.isScreenShotsAvailable) {
    // todo: auto-naming scheme
    print("Takin screenshot '$name'");

    final pixels = await takeScreenshot(
      binding,
      integrationTestChannel,
      platformDispatcher,
      name,
      timeout: timeout,
    );

    if (Platform.isAndroid) {
      await integrationTestChannel.invokeMethod<void>(
        'revertFlutterImage',
        null,
      );
    }

    final testDir = '${config.stagingDir}/$kTestScreenshotsDir';
    final fullFilePath = '$testDir/$name.$kImageExtension';

    var client = http.Client();
    try {
      var response = await client.post(
          Uri.http(
              '${const String.fromEnvironment(kEnvImageReceiverIPAddress)}:${config.imageReceiverPort}',
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

Future<List<int>> takeScreenshot(
    dynamic binding,
    dynamic integrationTestChannel,
    dynamic platformDispatcher,
    String screenshotName,
    {Duration? timeout}) async {
  if (bool.fromEnvironment('dart.library.js_util')) {
    // kIsWeb implementation
    throw 'web not yet implemented';
    // await binding.takeScreenshot(name);
    // return;
  } else if (Platform.isAndroid) {
    try {
      await integrationTestChannel.invokeMethod<void>(
        'convertFlutterSurfaceToImage',
      );
    } catch (e) {
      print(
          'converting surface to image failed; probably it was already an image?: $e');
    }
    final DateTime endTime =
        binding.clock.fromNowBy(timeout ?? const Duration(seconds: 30));
    do {
      if (binding.clock.now().isAfter(endTime)) {
        break;
      }
      await binding.pump(const Duration(milliseconds: 100));
    } while (binding.hasScheduledFrame);
  }
  var reportData = <String, dynamic>{};
  reportData['screenshots'] ??= <dynamic>[];
  final Map<String, dynamic> data = await _takeScreenshot(
      integrationTestChannel, platformDispatcher, screenshotName);
  assert(data.containsKey('bytes'));

  (reportData['screenshots']! as List<dynamic>).add(data);
  return data['bytes']! as List<int>;
}

Future<Map<String, dynamic>> _takeScreenshot(dynamic integrationTestChannel,
    dynamic platformDispatcher, String screenshot) async {
  integrationTestChannel.setMethodCallHandler(
      (call) => _onMethodChannelCall(call, platformDispatcher));
  final List<int>? rawBytes =
      await integrationTestChannel.invokeMethod<List<int>>(
    'captureScreenshot',
    <String, dynamic>{'name': screenshot},
  );
  if (rawBytes == null) {
    throw StateError(
        'Expected a list of bytes, but instead captureScreenshot returned null');
  }
  return <String, dynamic>{
    'screenshotName': screenshot,
    'bytes': rawBytes,
  };
}

Future<dynamic> _onMethodChannelCall(
    dynamic call, dynamic platformDispatcher) async {
  switch (call.method) {
    case 'scheduleFrame':
      platformDispatcher.scheduleFrame();
      break;
  }
  return null;
}
