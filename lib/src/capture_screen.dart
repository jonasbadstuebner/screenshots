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
  String name, {
  Duration? timeout,
  bool silent = false,
}) async {
  // todo: auto-naming scheme
  print("Taking screenshot '$name'");

  final pixels = await takeScreenshot(
    binding,
    integrationTestChannel,
    platformDispatcher,
    name,
    timeout: timeout,
  );

  final fullFilePath = '$name.$kImageExtension';

  final client = http.Client();
  Exception? sendError;
  try {
    final response = await client.post(
      Uri.http(
        '${const String.fromEnvironment(kEnvImageSendHost)}:${const String.fromEnvironment(kEnvImageSendPort)}',
        fullFilePath,
      ),
      body: pixels,
    );
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
}

Future<List<int>> takeScreenshot(
  dynamic binding,
  dynamic integrationTestChannel,
  dynamic platformDispatcher,
  String screenshotName, {
  Duration? timeout,
}) async {
  if (const bool.fromEnvironment('dart.library.js_util')) {
    throw Exception('web not yet implemented');
  } else if (Platform.isAndroid) {
    await integrationTestChannel.invokeMethod<void>(
      'convertFlutterSurfaceToImage',
    );
  }

  var isPatrolRun = false;
  try {
    final _ = binding.reportData;
    // ignore: avoid_catching_errors
  } on NoSuchMethodError {
    isPatrolRun = true;
  }

  await binding.pump();
  if (!isPatrolRun) {
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['screenshots'] ??= <dynamic>[];
  }
  integrationTestChannel.setMethodCallHandler((dynamic call) async {
    switch (call.method) {
      case 'scheduleFrame':
        platformDispatcher.scheduleFrame();
        break;
    }
    return null;
  });
  final rawBytes = await integrationTestChannel.invokeMethod<List<int>>(
    'captureScreenshot',
    <String, dynamic>{'name': screenshotName},
  );
  if (rawBytes == null) {
    throw StateError(
      'Expected a list of bytes, but instead captureScreenshot returned null',
    );
  }
  final data = <String, dynamic>{
    'screenshotName': screenshotName,
    'bytes': rawBytes,
  };
  assert(data.containsKey('bytes'), 'Missing bytes key');

  if (!isPatrolRun) {
    (binding.reportData!['screenshots'] as List<dynamic>).add(data);
  }

  if (Platform.isAndroid) {
    await integrationTestChannel.invokeMethod<void>(
      'revertFlutterImage',
    );
  }
  return data['bytes']! as List<int>;
}
