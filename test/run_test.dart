//import 'dart:io';

import 'package:fake_process_manager/fake_process_manager.dart';
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:screenshots/src/daemon_client.dart';
import 'package:screenshots/src/run.dart';
import 'package:screenshots/src/screens.dart';
import 'package:test/test.dart';
import 'package:tool_base/tool_base.dart';
import 'package:tool_base_test/tool_base_test.dart';

import 'src/mocks.dart';

main() {
  const stagingDir = '/tmp/screenshots';
  const configAndroidDeviceName = 'Nexus 6P';
  const configIosDeviceName = 'iPhone X';
  const emulatorId = 'NEXUS_6P_API_28';
  final stdinCaptured = <String>[];

  Directory? sdkDir;

  void _captureStdin(String item) {
    stdinCaptured.add(item);
  }

  final unpackScriptsCalls = [
    Call(
        'chmod u+x /tmp/screenshots/resources/script/android-wait-for-emulator',
        null),
    Call(
        'chmod u+x /tmp/screenshots/resources/script/android-wait-for-emulator-to-stop',
        null),
    Call('chmod u+x /tmp/screenshots/resources/script/simulator-controller',
        null),
    Call('chmod u+x /tmp/screenshots/resources/script/sim_orientation.scpt',
        null),
  ];
  final runAndroidTestCall = Call(
      'flutter -d emulator-5554 drive example/test_driver/main.dart',
      ProcessResult(0, 0, 'drive output', ''));

  final installedDaemonEmulator = loadDaemonEmulator({
    'id': emulatorId,
    'name': 'emulator description',
    'category': 'mobile',
    'platformType': 'android'
  });

  late FakeProcessManager fakeProcessManager;
  late MockDaemonClient mockDaemonClient;

  setUp(() async {
    fakeProcessManager = FakeProcessManager(stdinResults: _captureStdin);
    mockDaemonClient = MockDaemonClient();
    when(mockDaemonClient.emulators)
        .thenAnswer((_) => Future.value([installedDaemonEmulator]));
  });

  tearDown(() {
    if (sdkDir != null) {
      tryToDelete(sdkDir!);
      sdkDir = null;
    }
  });

  group('run', () {
    group('with running android emulator', () {
      const deviceId = 'emulator-5554';
      final runningDaemonDevice = loadDaemonDevice({
        'id': deviceId,
        'name': 'Android SDK built for x86',
        'platform': 'android-x86',
        'emulator': true,
        'category': 'mobile',
        'platformType': 'android',
        'ephemeral': true,
        'emulatorId': configAndroidDeviceName,
      });

      setUp(() {
        // running emulator
        when(mockDaemonClient.devices)
            .thenAnswer((_) => Future.value([runningDaemonDevice]));
      });

      testUsingContext('no frames, no locales', () async {
        // screenshots config
        const configStr = '''
          tests:
            - example/test_driver/main.dart
          staging: $stagingDir
          locales:
            - en-US
          devices:
            android:
              $configAndroidDeviceName:
          frame: false
      ''';
        final adbPath = initAdbPath();
        final androidUSLocaleCall = Call(
            '$adbPath -s $deviceId shell getprop persist.sys.locale',
            ProcessResult(0, 0, 'en-US', ''));
        // fake process responses
        final calls = <Call>[
          ...unpackScriptsCalls,
//          Call('$adbPath -s emulator-5554 emu avd name',
//              ProcessResult(0, 0, 'Nexus_6P_API_28', '')),
          androidUSLocaleCall,
          androidUSLocaleCall,
          runAndroidTestCall,
        ];
        fakeProcessManager.calls = calls;
        final result = await screenshots(configStr: configStr);
        expect(result, isTrue);
        final logger = context.get<Logger>() as BufferLogger;
        expect(logger.statusText,
            isNot(contains('Starting $configAndroidDeviceName...')));
        expect(logger.statusText, isNot(contains('Changing locale')));
        expect(logger.statusText, contains('Warning: framing is not enabled'));
        fakeProcessManager.verifyCalls();
        verify(mockDaemonClient.devices).called(1);
        verify(mockDaemonClient.emulators).called(1);
      }, skip: false, overrides: <Type, Generator>{
        DaemonClient: () => mockDaemonClient,
        ProcessManager: () => fakeProcessManager,
//        Platform: () => FakePlatform.fromPlatform(const LocalPlatform())
//          ..environment = {'CI': 'false'},
        Logger: BufferLogger.new,
      });

      testUsingContext('change orientation', () async {
        const emulatorName = 'Nexus 6P';
        // screenshots config
        const configStr = '''
          tests:
            - example/test_driver/main.dart
          staging: $stagingDir
          locales:
            - en-US
          devices:
            android:
              $emulatorName:
                orientation: LandscapeRight
          frame: true
      ''';
        final adbPath = initAdbPath();
        final androidUSLocaleCall = Call(
            '$adbPath -s $deviceId shell getprop persist.sys.locale',
            ProcessResult(0, 0, 'en-US', ''));
        // fake process responses
        final calls = <Call>[
          ...unpackScriptsCalls,
//          Call('$adbPath -s emulator-5554 emu avd name',
//              ProcessResult(0, 0, 'Nexus_6P_API_28', '')),
          androidUSLocaleCall,
          androidUSLocaleCall,
          Call(
              '$adbPath -s emulator-5554 shell settings put system user_rotation 1',
              null),
          runAndroidTestCall,
        ];
        fakeProcessManager.calls = calls;
        final result = await screenshots(configStr: configStr);
        expect(result, isTrue);
        final logger = context.get<Logger>() as BufferLogger;
        expect(logger.statusText,
            contains('Setting orientation to LandscapeRight'));
        expect(logger.statusText, contains('Warning: framing is not enabled'));
        fakeProcessManager.verifyCalls();
        verify(mockDaemonClient.devices).called(2);
        verify(mockDaemonClient.emulators).called(1);
      }, skip: false, overrides: <Type, Generator>{
        DaemonClient: () => mockDaemonClient,
        ProcessManager: () => fakeProcessManager,
//        Platform: () => FakePlatform.fromPlatform(const LocalPlatform())
//          ..environment = {'CI': 'false'},
        Logger: BufferLogger.new,
      });
    });

    group('with no attached devices, no running emulators', () {
      late MemoryFileSystem memoryFileSystem;

      setUp(() async {
        memoryFileSystem = MemoryFileSystem();
      });

      testUsingContext(', android run, no frames, no locales', () async {
        // screenshots config
        const configStr = '''
      tests:
        - example/test_driver/main.dart
      staging: $stagingDir
      locales:
        - en-US
      devices:
        android:
          $configAndroidDeviceName:
      frame: false
      ''';
        final adbPath = initAdbPath();
        const deviceId = 'emulator-5554';
        final androidUSLocaleCall = Call(
            '$adbPath -s $deviceId shell getprop persist.sys.locale',
            ProcessResult(0, 0, 'en-US', ''));
        // fake process responses
        final calls = <Call>[
          ...unpackScriptsCalls,
          androidUSLocaleCall,
          androidUSLocaleCall,
          runAndroidTestCall,
          androidUSLocaleCall,
          Call('$adbPath -s $deviceId emu kill', null),
        ];
        fakeProcessManager.calls = calls;

        when(mockDaemonClient.devices).thenAnswer((_) => Future.value([]));
        when(mockDaemonClient.launchEmulator(emulatorId))
            .thenAnswer((_) => Future.value(deviceId));
        when(mockDaemonClient.waitForEvent(EventType.deviceRemoved))
            .thenAnswer((_) => Future.value({'id': deviceId}));

        final result = await screenshots(configStr: configStr);
        expect(result, isTrue);
        final logger = context.get<Logger>() as BufferLogger;
        expect(logger.statusText,
            contains('Starting $configAndroidDeviceName...'));
        expect(logger.statusText, contains('Warning: framing is not enabled'));
        fakeProcessManager.verifyCalls();
        verify(mockDaemonClient.devices).called(1);
        verify(mockDaemonClient.emulators).called(1);
        verify(mockDaemonClient.launchEmulator(emulatorId)).called(1);
        verify(mockDaemonClient.waitForEvent(EventType.deviceRemoved))
            .called(1);
      }, skip: false, overrides: <Type, Generator>{
        DaemonClient: () => mockDaemonClient,
        ProcessManager: () => fakeProcessManager,
//        Platform: () => FakePlatform.fromPlatform(const LocalPlatform())
//          ..environment = {'CI': 'false'},
        Logger: BufferLogger.new,
      });

      testUsingContext(
          ', android and ios run, no frames, multiple locales, orientation',
          () async {
        const locale1 = 'en-US';
        const locale1Lower = 'en_US';
        const locale2 = 'fr-CA';
        const locale2Lower = 'fr_CA';
        const orientation1 = 'LandscapeRight';
        const orientation2 = 'LandscapeLeft';
        const deviceId = 'emulator-5554';
        const configStr = '''
          tests:
            - example/test_driver/main.dart
          staging: $stagingDir
          locales:
            - $locale1
            - $locale2
          devices:
            android:
              $configAndroidDeviceName:
                orientation: $orientation1
            ios:
              $configIosDeviceName:
                orientation: $orientation2
          frame: false
      ''';
        const simulatorID = '6B3B1AD9-EFD3-49AB-9CE9-D43CE1A47446';

        // fake process responses
        final callListIosDevices = Call(
            'xcrun simctl list devices --json',
            ProcessResult(
                0,
                0,
                '''
                {
                  "devices" : {
                    "iOS 11.2" : [
                      {
                        "state" : "Shutdown",
                        "availability" : "(available)",
                        "name" : "iPhone 7 Plus",
                        "udid" : "1DD6DBF1-846F-4644-8E97-76175788B9A5"
                      }
                    ],
                    "iOS 11.1" : [
                      {
                        "state" : "Shutdown",
                        "availability" : "(available)",
                        "name" : "iPhone X",
                        "udid" : "$simulatorID"
                      }
                    ]
                  }
                }
                ''',
                ''));
        final callPlutilEnUS = Call(
            'plutil -convert json -o - //Library/Developer/CoreSimulator/Devices/$simulatorID/data/Library/Preferences/.GlobalPreferences.plist',
            ProcessResult(0, 0, '{"AppleLocale":"$locale1"}', ''));
        final callPlutilFrCA = Call(
            'plutil -convert json -o - //Library/Developer/CoreSimulator/Devices/$simulatorID/data/Library/Preferences/.GlobalPreferences.plist',
            ProcessResult(0, 0, '{"AppleLocale":"$locale2"}', ''));
        final adbPath = initAdbPath();
        final androidEnUSLocaleCall = Call(
            '$adbPath -s $deviceId shell getprop persist.sys.locale',
            ProcessResult(0, 0, locale1, ''));
        final androidFrCALocaleCall = Call(
            '$adbPath -s $deviceId shell getprop persist.sys.locale',
            ProcessResult(0, 0, locale2, ''));
        final calls = <Call>[
          callListIosDevices,
          ...unpackScriptsCalls,
          androidEnUSLocaleCall,
          androidEnUSLocaleCall,
          Call(
              '$adbPath -s $deviceId shell settings put system user_rotation 1',
              null),
          runAndroidTestCall,
          androidEnUSLocaleCall,
          Call('$adbPath -s $deviceId root', null),
          Call(
              '$adbPath -s $deviceId shell setprop persist.sys.locale $locale2 ; setprop ctl.restart zygote',
              null),
          Call('$adbPath -s $deviceId logcat -c', null),
          Call(
              '$adbPath -s $deviceId logcat -b main *:S ContactsDatabaseHelper:I ContactsProvider:I -e $locale2Lower',
              ProcessResult(
                  0,
                  0,
                  '08-28 14:25:11.994  5294  5417 I ContactsProvider: Locale has changed from [$locale1] to [$locale2]',
                  '')),
          Call(
              '$adbPath -s $deviceId shell settings put system user_rotation 1',
              null),
          runAndroidTestCall,
          androidFrCALocaleCall,
          Call('$adbPath -s $deviceId root', null),
          Call(
              '$adbPath -s $deviceId shell setprop persist.sys.locale $locale1 ; setprop ctl.restart zygote',
              null),
          Call('$adbPath -s $deviceId logcat -c', null),
          Call(
              '$adbPath -s $deviceId logcat -b main *:S ContactsDatabaseHelper:I ContactsProvider:I -e $locale1Lower',
              ProcessResult(
                  0,
                  0,
                  '08-28 14:25:11.994  5294  5417 I ContactsProvider: Locale has changed from [$locale2] to [$locale1]',
                  '')),
          Call('$adbPath -s $deviceId emu kill', null),
          callListIosDevices,
          Call(
              'plutil -convert binary1 //Library/Developer/CoreSimulator/Devices/$simulatorID/data/Library/Preferences/.GlobalPreferences.plist',
              null),
          callPlutilEnUS,
          Call('xcrun simctl boot $simulatorID', null),
          callPlutilEnUS,
          callPlutilEnUS,
          // 29
          Call(
              'osascript /tmp/screenshots/resources/script/sim_orientation.scpt Landscape Left',
              null),
          Call('flutter -d $simulatorID drive example/test_driver/main.dart',
              null),
          callPlutilEnUS,
          Call(
              '/tmp/screenshots/resources/script/simulator-controller $simulatorID locale $locale2',
              null),
          Call('xcrun simctl shutdown $simulatorID', null),
          Call('xcrun simctl boot $simulatorID', null),
          // 35
          Call(
              'osascript /tmp/screenshots/resources/script/sim_orientation.scpt Landscape Left',
              null),
          Call('flutter -d $simulatorID drive example/test_driver/main.dart',
              null),
          callPlutilFrCA,
          Call(
              '/tmp/screenshots/resources/script/simulator-controller $simulatorID locale $locale1',
              null),
          Call('xcrun simctl shutdown $simulatorID', null),
        ];
        fakeProcessManager.calls = calls;

        const runningEmulatorDeviceId = 'emulator-5554';
        final devices = [
          {
            'id': runningEmulatorDeviceId,
            'name': 'Android SDK built for x86',
            'platform': 'android-x86',
            'emulator': true,
            'category': 'mobile',
            'platformType': 'android',
            'ephemeral': true,
            'emulatorId': emulatorId,
          },
          {
            'id': simulatorID,
            'name': 'User’s iPhone X',
            'platform': 'ios',
            'emulator': true,
            'category': 'mobile',
            'platformType': 'ios',
            'ephemeral': true,
            'model': 'iPhone 5c (GSM)',
            'emulatorId': simulatorID,
          }
        ];
        final daemonDevices =
            devices.map(loadDaemonDevice).toList();

        final devicesResponses = <List<DaemonDevice>>[
          [],
          daemonDevices,
          daemonDevices,
          daemonDevices,
          daemonDevices,
          daemonDevices,
          daemonDevices,
        ];

        when(mockDaemonClient.devices)
            .thenAnswer((_) => Future.value(devicesResponses.removeAt(0)));
        when(mockDaemonClient.launchEmulator(emulatorId))
            .thenAnswer((_) => Future.value(runningEmulatorDeviceId));
        when(mockDaemonClient.waitForEvent(EventType.deviceRemoved))
            .thenAnswer((_) => Future.value({'id': runningEmulatorDeviceId}));

        memoryFileSystem
            .file('example/test_driver/main.dart')
            .createSync(recursive: true);
        memoryFileSystem
            .directory(
                '/Library/Developer/CoreSimulator/Devices/$simulatorID/data/Library/Preferences')
            .createSync(recursive: true);

        final screenshots = Screenshots(configStr: configStr);
        final result = await screenshots.run();
        expect(result, isTrue);
        final logger = context.get<Logger>() as BufferLogger;
        expect(logger.errorText, '');
//        print(logger.statusText);
        expect(logger.statusText,
            contains('Starting $configAndroidDeviceName...'));
        expect(logger.statusText, contains('Starting $configIosDeviceName...'));
        expect(logger.statusText,
            contains('Setting orientation to $orientation1'));
        expect(logger.statusText,
            contains('Setting orientation to $orientation2'));
        expect(logger.statusText, contains('Warning: framing is not enabled'));
        expect(
            logger.statusText,
            contains(
                'Changing locale from $locale1 to $locale2 on \'$configAndroidDeviceName\'...'));
        expect(
            logger.statusText,
            contains(
                'Changing locale from $locale2 to $locale1 on \'$configAndroidDeviceName\'...'));
        expect(
            logger.statusText,
            contains(
                'Changing locale from $locale1 to $locale2 on \'$configIosDeviceName\'...'));
        expect(
            logger.statusText,
            contains(
                'Changing locale from $locale2 to $locale1 on \'$configIosDeviceName\'...'));
        expect(
            logger.statusText,
            contains(
                'Restarting \'$configIosDeviceName\' due to locale change...'));
        fakeProcessManager.verifyCalls();
        verify(mockDaemonClient.devices).called(7);
        verify(mockDaemonClient.emulators).called(1);
        verify(mockDaemonClient.launchEmulator(emulatorId)).called(1);
        verify(mockDaemonClient.waitForEvent(EventType.deviceRemoved))
            .called(1);
      }, skip: false, overrides: <Type, Generator>{
        DaemonClient: () => mockDaemonClient,
        ProcessManager: () => fakeProcessManager,
        Platform: () => FakePlatform.fromPlatform(const LocalPlatform())
                .copyWith(environment: {
//            'CI': 'false',
//            'HOME': LocalPlatform().environment['HOME']
              'HOME': memoryFileSystem.currentDirectory.path
            }, operatingSystem: 'macos'),
        Logger: BufferLogger.new,
        FileSystem: () => memoryFileSystem,
      });
    });
  });

  group('hack in CI', () {
    const deviceId = 'emulator-5554';
    final runningEmulatorDaemonDevice = loadDaemonDevice({
      'id': deviceId,
      'name': 'Android SDK built for x86',
      'platform': 'android-x86',
//      'platform': 'android-arm', // expect android-x86
      'emulator': true,
//      'emulator': false, // expect true
      'category': 'mobile',
      'platformType': 'android',
      'ephemeral': true,
      'emulatorId': emulatorId,
//      'emulatorId': null, // expect Nexus_6P_API_28 (or running avd)
    });

    setUp(() {
      when(mockDaemonClient.devices)
          .thenAnswer((_) => Future.value([runningEmulatorDaemonDevice]));
    });

    testUsingContext('on android', () async {
      // screenshots config
      const configStr = '''
          tests:
            - example/test_driver/main.dart
          staging: $stagingDir
          locales:
            - en-US
          devices:
            android:
              $configAndroidDeviceName:
                orientation: 
                 - Portrait
                 - LandscapeRight
          frame: false
      ''';
      final adbPath = initAdbPath();
      final androidUSLocaleCall = Call(
          '$adbPath -s $deviceId shell getprop persist.sys.locale',
          ProcessResult(0, 0, 'en-US', ''));
      final calls = <Call>[
        ...unpackScriptsCalls,
        androidUSLocaleCall,
        androidUSLocaleCall,
//        Call('$adbPath -s emulator-5554 emu avd name',
//            ProcessResult(0, 0, 'Nexus_6P_API_28', '')),
        Call('$adbPath -s $deviceId shell settings put system user_rotation 0',
            null),
        runAndroidTestCall,
        Call('$adbPath -s $deviceId shell settings put system user_rotation 1',
            null),
        runAndroidTestCall,
      ];
      fakeProcessManager.calls = calls;

      final result = await screenshots(configStr: configStr);

      expect(result, isTrue);
      fakeProcessManager.verifyCalls();
      verify(mockDaemonClient.devices).called(3);
      verify(mockDaemonClient.emulators).called(1);
      final logger = context.get<Logger>() as BufferLogger;
      expect(logger.errorText, '');
      expect(
          logger.statusText,
          isNot(contains(
              'Warning: the locale of a real device cannot be changed.')));
      expect(logger.statusText,
          isNot(contains('Starting $configAndroidDeviceName...')));
      expect(logger.statusText, contains('Setting orientation to Portrait'));
      expect(
          logger.statusText, contains('Setting orientation to LandscapeRight'));
    }, skip: false, overrides: <Type, Generator>{
      DaemonClient: () => mockDaemonClient,
      ProcessManager: () => fakeProcessManager,
      Platform: () => FakePlatform.fromPlatform(const LocalPlatform())
          .copyWith(environment: {'CI': 'true'}),
      Logger: BufferLogger.new,
    });
  });

  group('utils', () {
    testUsingContext('change android locale of real device', () {
      final adbPath = initAdbPath();
      const deviceId = 'deviceId';
      const deviceLocale = 'en-US';
      const testLocale = 'fr-CA';

      fakeProcessManager.calls = [
        Call(
            '$adbPath -s $deviceId root',
            ProcessResult(
                0, 0, 'adbd cannot run as root in production builds\n', '')),
        Call(
            '$adbPath -s $deviceId shell setprop persist.sys.locale $testLocale ; setprop ctl.restart zygote',
            null),
      ];
      changeAndroidLocale(deviceId, deviceLocale, testLocale);
      final logger = context.get<Logger>() as BufferLogger;
      expect(
          logger.errorText,
          contains(
              'Warning: locale will not be changed. Running in locale \'$deviceLocale\''));
      fakeProcessManager.verifyCalls();
    }, skip: false, overrides: <Type, Generator>{
      ProcessManager: () => fakeProcessManager,
      Logger: BufferLogger.new,
    });

    test('find running emulator', () async {
      final runningEmulator = loadDaemonDevice({
        'id': emulatorId,
        'name': 'sdk phone armv7',
        'platform': 'android-arm',
        'emulator': true,
        'category': 'mobile',
        'platformType': 'android',
        'ephemeral': true,
        'emulatorId': emulatorId,
      });
      final emulator = loadDaemonEmulator({
        'id': emulatorId,
        'name': 'emulator description',
        'category': 'mobile',
        'platformType': 'android'
      });
      final deviceFound = findRunningDevice(
          [runningEmulator], [emulator], configAndroidDeviceName);
      expect(deviceFound, equals(runningEmulator));
    });

    testUsingContext('multiple tests (on iOS)', () async {
      const deviceName = 'device name';
      const deviceId = 'deviceId';
      const locale = 'locale';
      const test1 = 'test_driver/main.dart';
      const test2 = 'test_driver/main2.dart';
      const configStr = '''
        tests:
          - $test1
          - $test2
        staging: /tmp/screenshots
        locales:
          - en-US
        devices:
          ios:
            $deviceName:
        frame: false
      ''';
      final screenshots = Screenshots(configStr: configStr);
      screenshots.screens = Screens();
      await screenshots.screens.init();
      fakeProcessManager.calls = [
        Call('flutter -d $deviceId drive $test1', null),
        Call('flutter -d $deviceId drive $test2', null),
      ];
      final result = await screenshots.runProcessTests(
        deviceName,
        locale,
        null,
        getDeviceType(screenshots.config, deviceName),
        8020,
        deviceId,
        usePatrol: false,
      );
      expect(result, isNull);
      final logger = context.get<Logger>() as BufferLogger;
      expect(logger.errorText, '');
      expect(logger.statusText,
          contains('Running $test1 on \'$deviceName\' in locale $locale...'));
      expect(logger.statusText,
          contains('Running $test2 on \'$deviceName\' in locale $locale...'));
      expect(logger.statusText,
          contains('Warning: \'$deviceName\' images will not be processed'));
      fakeProcessManager.verifyCalls();
    }, skip: false, overrides: <Type, Generator>{
      ProcessManager: () => fakeProcessManager,
      Logger: BufferLogger.new,
    });
  });
}

String initAdbPath() {
  final sdkDir = MockAndroidSdk.createSdkDirectory();
  Config.instance.setValue('android-sdk', sdkDir.path);
  final adbPath = '${sdkDir.path}/platform-tools/adb';
  return adbPath;
}

class MockDaemonClient extends Mock implements DaemonClient {}
