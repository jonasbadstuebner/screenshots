import 'dart:io' as io;

import 'package:screenshots/screenshots.dart';
import 'package:screenshots/src/orientation.dart';
import 'package:screenshots/src/screens.dart';
import 'package:screenshots/src/utils.dart';
import 'package:test/test.dart';

import 'src/common.dart';

main() {
  group('config', () {
    test('getters', () {
      const expectedTest = 'test_driver/main.dart';
      const expectedStaging = '/tmp/screenshots';
      const expectedLocale = 'en-US';
      const expectedIosName = 'iPhone XS Max';
      const expectedIosFrame = false;
      const expectedOrientation = 'LandscapeRight';
      final orientation =
          getEnumFromString(Orientation.values, expectedOrientation);
      final expectedIosDevice = ConfigDevice(
        expectedIosName,
        DeviceType.ios,
        expectedIosFrame,
        [orientation!],
        true,
      );
      const expectedAndroidName = 'Nexus 6P';
      const expectedGlobalFrame = true;
      final expectedAndroidDevice = ConfigDevice(
        expectedAndroidName,
        DeviceType.android,
        expectedGlobalFrame,
        [orientation],
        true,
      );
      const expectedRecording = '/tmp/screenshots_record';
      const expectedArchive = '/tmp/screenshots_archive';
      const configStr = '''
      tests:
        - $expectedTest
      staging: $expectedStaging
      locales:
        - $expectedLocale
      devices:
        ios:
          $expectedIosName:
            frame: $expectedIosFrame
            orientation: 
              - $expectedOrientation
        android:
          $expectedAndroidName:
            orientation: $expectedOrientation
      frame: $expectedGlobalFrame
      recording: $expectedRecording
      archive: $expectedArchive
      ''';
      final config = ScreenshotsConfig(configStr: configStr);

      expect(config.tests, [expectedTest]);
      expect(config.stagingDir, expectedStaging);
      expect(config.locales, [expectedLocale]);
      expect(config.androidDevices, equals([expectedAndroidDevice]));
      expect(config.iosDevices, equals([expectedIosDevice]));
      expect(config.iosDevices, isNot(equals([expectedAndroidDevice])));
      expect(config.isFrameEnabled, expectedGlobalFrame);
      expect(config.recordingDir, expectedRecording);
      expect(config.archiveDir, expectedArchive);
      expect(config.getDevice(expectedAndroidName), expectedAndroidDevice);
      expect(config.getDevice(expectedAndroidName), isNot(expectedIosDevice));
      expect(config.deviceNames..sort(),
          equals([expectedAndroidName, expectedIosName]..sort()));
    });

    test('backward compatible orientation', () {
      var configStr = '''
        devices:
          android:
            device name:
              orientation: 
                - Portrait
        frame: true
        ''';
      var config = ScreenshotsConfig(configStr: configStr);
      expect(config.devices[0].orientations![0], Orientation.Portrait);
      configStr = '''
        devices:
          android:
            device name:
              orientation: Portrait
        frame: true
        ''';
      config = ScreenshotsConfig(configStr: configStr);
      expect(config.devices[0].orientations![0], Orientation.Portrait);
    });

    test('active run type', () {
      const configIosOnly = '''
        devices:
          ios:
            iPhone X:
      ''';
      const configAndroidOnly = '''
        devices:
          ios: # check for empty devices
          android:
            Nexus 6P:
      ''';
      const configBoth = '''
        devices:
          ios:
            iPhone X:
          android:
            Nexus 6P:
      ''';
      const configNeither = '''
        devices:
          ios:
          android:
      ''';
//      Map config = utils.parseYamlStr(configIosOnly);
      var config = ScreenshotsConfig(configStr: configIosOnly);
      expect(config.isRunTypeActive(DeviceType.ios), isTrue);
      expect(config.isRunTypeActive(DeviceType.android), isFalse);

      config = ScreenshotsConfig(configStr: configAndroidOnly);
      expect(config.isRunTypeActive(DeviceType.ios), isFalse);
      expect(config.isRunTypeActive(DeviceType.android), isTrue);

      config = ScreenshotsConfig(configStr: configBoth);
      expect(config.isRunTypeActive(DeviceType.ios), isTrue);
      expect(config.isRunTypeActive(DeviceType.android), isTrue);

      config = ScreenshotsConfig(configStr: configNeither);
      expect(config.isRunTypeActive(DeviceType.ios), isFalse);
      expect(config.isRunTypeActive(DeviceType.android), isFalse);
    });

    test('isFrameRequired', () {
      const deviceName = 'Nexus 6P';
      var configStr = '''
        devices:
          android:
            $deviceName:
        frame: true
        ''';
      var config = ScreenshotsConfig(configStr: configStr);
      expect(config.isFrameRequired(deviceName, null), isTrue);
      configStr = '''
        devices:
          android:
            $deviceName:
              frame: false
        frame: true
        ''';
      config = ScreenshotsConfig(configStr: configStr);
      expect(config.isFrameRequired(deviceName, null), isFalse);
      configStr = '''
        devices:
          android:
            $deviceName:
              orientation: 
                - Portrait
                - LandscapeRight
        frame: true
        ''';
      config = ScreenshotsConfig(configStr: configStr);
      final device = config.getDevice(deviceName);
      expect(
          config.isFrameRequired(deviceName, device.orientations![0]), isTrue);
      expect(
          config.isFrameRequired(deviceName, device.orientations![1]), isFalse);
    });

    test('store and retrieve environment', () async {
      const tmpDir = '/tmp/screenshots_test_env';
      clearDirectory(tmpDir);
      const configStr = '''
        staging: $tmpDir
      ''';
      final config = ScreenshotsConfig(configStr: configStr);
      final screens = Screens();
      await screens.init();
      const orientation = 'Portrait';

      final env = {
        'screen_size': '1440x2560',
        'locale': 'en_US',
        'device_name': 'Nexus 6P',
        'device_type': 'android',
        'orientation': orientation
      };

      // called by screenshots before test
      await config.storeEnv(
          screens,
          env['device_name']!,
          env['locale']!,
          getEnumFromString(DeviceType.values, env['device_type']!)!,
          getEnumFromString(Orientation.values, orientation)!);

      // called by test
      // simulate no screenshots available
      var testConfig = ScreenshotsConfig(configStr: configStr);
      expect(await testConfig.screenshotsEnv, {});

      // simulate screenshots available
      const configPath = '$tmpDir/screenshots.yaml';
      await io.File(configPath).writeAsString(configStr);
      testConfig = ScreenshotsConfig(configPath: configPath);
      expect(await testConfig.screenshotsEnv, env);
    });
  });
}
