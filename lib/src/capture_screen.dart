// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'globals.dart';

/// Called by integration test to capture images.
Future<void> screenshot(
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
    print("Taking screenshot '$name'");

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

    final client = http.Client();
    Exception? sendError;
    try {
      final response = await client.post(
          Uri.http(
              '${const String.fromEnvironment(kEnvImageReceiverIPAddress)}:${config.imageReceiverPort}',
              fullFilePath),
          body: pixels);
      print('screenshot-receiver: ${utf8.decode(response.bodyBytes)}');
    } catch (e) {
      print('screenshot-send-error: $e');
      if (e is Exception) {
        sendError = e;
      } else {
        sendError = Exception(e.toString());
      }
    } finally {
      client.close();
    }
    // You should see that something went wrong, but it should not leave the client open. So I did it like this.
    if (sendError != null) {
      throw sendError;
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
  if (const bool.fromEnvironment('dart.library.js_util')) {
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
    final endTime = binding.clock
        .fromNowBy(timeout ?? const Duration(seconds: 30)) as DateTime;
    do {
      if ((binding.clock.now() as DateTime).isAfter(endTime)) {
        break;
      }
      await binding.pump(const Duration(milliseconds: 100));
    } while (binding.hasScheduledFrame as bool);
  }
  final reportData = <String, dynamic>{};
  reportData['screenshots'] ??= <dynamic>[];
  final data = await _takeScreenshot(
      integrationTestChannel, platformDispatcher, screenshotName);
  assert(data.containsKey('bytes'));

  (reportData['screenshots']! as List<dynamic>).add(data);
  return data['bytes']! as List<int>;
}

Future<Map<String, dynamic>> _takeScreenshot(dynamic integrationTestChannel,
    dynamic platformDispatcher, String screenshot) async {
  integrationTestChannel.setMethodCallHandler(
      (dynamic call) => _onMethodChannelCall(call, platformDispatcher));
  final rawBytes = await integrationTestChannel.invokeMethod<List<int>>(
    'captureScreenshot',
    <String, dynamic>{'name': screenshot},
  ) as List<int>?;
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
