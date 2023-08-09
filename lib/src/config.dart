import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:screenshots/src/orientation.dart';

import 'globals.dart';
import 'screens.dart';
import 'utils.dart' as utils;

const kEnvConfigPath = 'SCREENSHOTS_YAML';
const kEnvImageReceiverIPAddress = 'IMAGE_RECEIVER_ADDRESS';
const kEnvImageReceiverPort = 'IMAGE_RECEIVER_PORT';
const kEnvImageSendHost = 'IMAGE_SEND_HOST';
const kEnvImageSendPort = 'IMAGE_SEND_PORT';
const kEnvSreenshotsStagingDir = 'SCREENSHOTS_STAGING_DIR';

/// Config info used to manage screenshots for android and ios.
// Note: should not have context dependencies as is also used in driver.
// todo: yaml validation
class ScreenshotsConfig {
  ScreenshotsConfig({
    String? configPath,
    String? configStr,
  })  : configPath = configPath ?? kConfigFileName,
        _configStr = configStr {
    if (configStr != null) {
      // used by tests
      _configInfo = utils.parseYamlStr(configStr)!;
    } else {
      if (isScreenShotsAvailable) {
        final envConfigPath = io.Platform.environment[kEnvConfigPath];
        if (envConfigPath == null) {
          // used by command line and by driver if using kConfigFileName
          _configInfo = utils.parseYamlFile(this.configPath)!;
        } else {
          // used by driver
          _configInfo = utils.parseYamlFile(envConfigPath)!;
        }
      } else {
        io.stdout.writeln('Warning: screenshots not available.\n'
            '\tTo enable set $kEnvConfigPath environment variable\n'
            '\tor create ${io.File(this.configPath).absolute}.');
      }
    }
  }

  /// Checks if screenshots is available.
  ///
  /// Created for use in driver.
  // Note: order of boolean tests is important
  bool get isScreenShotsAvailable =>
      _configStr != null ||
      io.Platform.environment[kEnvConfigPath] != null ||
      io.File(configPath).existsSync();

  final String configPath;

  final String? _configStr;
  late Map<String, dynamic> _configInfo;
  Map<dynamic, dynamic>? _screenshotsEnv; // current screenshots env
  List<ConfigDevice>? _devices;

  // Getters
  List<String> get tests => _processList(_configInfo['tests'] as List<dynamic>);

  InternetAddress? get imageReceiverHost =>
      _configInfo.containsKey('imageReceiverHost')
          ? InternetAddress(_configInfo['imageReceiverHost'] as String,
              type: InternetAddressType.IPv4)
          : InternetAddress('127.0.0.1', type: InternetAddressType.IPv4);

  int get imageReceiverPort => _configInfo.containsKey('imageReceiverPort')
      ? _configInfo['imageReceiverPort'] as int
      : 8020;

  InternetAddress? get imageSendHost =>
      _configInfo.containsKey('imageSendTarget')
          ? InternetAddress(_configInfo['imageSendTarget'] as String,
              type: InternetAddressType.IPv4)
          : null;

  int get imageSendPort => _configInfo.containsKey('imageSendPort')
      ? _configInfo['imageSendPort'] as int
      : imageReceiverPort;

  String get stagingDir => _configInfo['staging'] as String;

  bool get rawScreenshots =>
      bool.tryParse(_configInfo['rawScreenshots'].toString()) ?? false;

  List<String> get locales =>
      _processList(_configInfo['locales'] as List<dynamic>);

  List<ConfigDevice> get devices => _devices ??= _processDevices(
      _configInfo['devices'] as Map<String, dynamic>, isFrameEnabled);

  List<ConfigDevice> get iosDevices =>
      devices.where((device) => device.deviceType == DeviceType.ios).toList();

  List<ConfigDevice> get androidDevices => devices
      .where((device) => device.deviceType == DeviceType.android)
      .toList();

  bool get isFrameEnabled => _configInfo['frame'] as bool;

  String? get recordingDir => _configInfo['recording'] as String?;

  String? get archiveDir => _configInfo['archive'] as String?;

  /// Get all android and ios device names.
  List<String> get deviceNames => devices.map((device) => device.name).toList();

  ConfigDevice getDevice(String deviceName) => devices.firstWhere(
      (device) => device.name == deviceName,
      orElse: () => throw 'Error: no device configured for \'$deviceName\'');

  /// Check for active run type.
  /// Run types can only be one of [DeviceType].
  bool isRunTypeActive(DeviceType runType) {
    final deviceType = utils.getStringFromEnum(runType);
    return !(_configInfo['devices'][deviceType] == null ||
        _configInfo['devices'][deviceType].length == 0);
  }

  /// Check if frame is required for [deviceName].
  bool isFrameRequired(String deviceName, Orientation? orientation) {
    final device = devices.firstWhere((device) => device.name == deviceName,
        orElse: () => throw 'Error: device \'$deviceName\' not found');
    // orientation over-rides frame if not in Portait (default)
    if (orientation == null) return device.isFramed;
    return (orientation != Orientation.LandscapeLeft &&
            orientation != Orientation.LandscapeRight) ||
        device.isFramed;
  }

  /// Current screenshots runtime environment
  /// (updated before start of each test)
  Future<Map<dynamic, dynamic>> get screenshotsEnv async {
    if (isScreenShotsAvailable) {
      if (_screenshotsEnv == null) await _retrieveEnv();
      return _screenshotsEnv!;
    } else {
      // output in test (hence no printStatus)
      io.stdout.writeln('Warning: screenshots runtime environment not set.');
      return Future.value({});
    }
  }

  io.File get _envStore {
    return io.File('${_configInfo['staging']}/$kEnvFileName');
  }

  /// Records screenshots environment before start of each test
  /// (called by screenshots)
  @visibleForTesting
  Future<void> storeEnv(Screens screens, String emulatorName, String locale,
      DeviceType deviceType, Orientation orientation) async {
    // store env for later use by tests
    final screenProps = screens.getScreen(emulatorName);
    final screenSize = screenProps == null ? null : screenProps['size'];
    final currentEnv = {
      'screen_size': screenSize,
      'locale': locale,
      'device_name': emulatorName,
      'device_type': utils.getStringFromEnum(deviceType),
      'orientation': utils.getStringFromEnum(orientation)
    };
    await _envStore.writeAsString(json.encode(currentEnv));
  }

  Future<void> _retrieveEnv() async {
    _screenshotsEnv =
        json.decode(await _envStore.readAsString()) as Map<dynamic, dynamic>;
  }

  List<String> _processList(List<dynamic> list) {
    return list.map((item) {
      return item.toString();
    }).toList();
  }

  List<ConfigDevice> _processDevices(
      Map<String, dynamic> devices, bool globalFraming) {
    Orientation getValidOrientation(String orientation, String deviceName) {
      bool isValidOrientation(String orientation) {
        return Orientation.values.map<Orientation?>((e) => e).firstWhere(
                (o) => utils.getStringFromEnum(o) == orientation,
                orElse: () => null) !=
            null;
      }

      if (!isValidOrientation(orientation)) {
        print(
            'Invalid value for \'orientation\' for device \'$deviceName\': $orientation}');
        print('Valid values:');
        for (final _orientation in Orientation.values) {
          print('  ${utils.getStringFromEnum(_orientation)}');
        }
        io.exit(1); // todo: add tool exception and throw
      }
      return utils.getEnumFromString(Orientation.values, orientation)!;
    }

    final configDevices = <ConfigDevice>[];

    devices.forEach((deviceType, dynamic device) {
      (device as Map<String, dynamic>?)
          ?.forEach((deviceName, dynamic deviceProps) {
        final propsMap = deviceProps as Map<String, dynamic>?;
        final orientationVal = propsMap?['orientation'];
        configDevices.add(ConfigDevice(
          deviceName,
          utils.getEnumFromString(DeviceType.values, deviceType)!,
          propsMap == null
              ? null
              : orientationVal == null
                  ? null
                  : orientationVal is String
                      ? [getValidOrientation(orientationVal, deviceName)]
                      : List<Orientation>.from(
                          (orientationVal as List<dynamic>).map((dynamic o) {
                          return getValidOrientation(o.toString(), deviceName);
                        })),
          isBuild: (propsMap?['build'] as bool?) ?? true,
          isFramed: propsMap == null
              ? globalFraming
              : (propsMap['frame'] as bool?) ??
                  globalFraming, // device frame overrides global frame
        ));
      });
    });

    return configDevices;
  }
}

/// Describe a config device
class ConfigDevice {
  ConfigDevice(
    this.name,
    this.deviceType,
    this.orientations, {
    required this.isBuild,
    required this.isFramed,
  });

  final String name;
  final DeviceType deviceType;
  final bool isFramed;
  final List<Orientation>? orientations;
  final bool isBuild;

  @override
  bool operator ==(other) {
    return other is ConfigDevice &&
        other.name == name &&
        other.isFramed == isFramed &&
        const ListEquality<Orientation>()
            .equals(other.orientations, orientations) &&
        other.deviceType == deviceType &&
        other.isBuild == isBuild;
  }

  @override
  String toString() =>
      'name: $name, deviceType: ${utils.getStringFromEnum(deviceType)}, isFramed: $isFramed, orientations: $orientations, isBuild: $isBuild';
}
