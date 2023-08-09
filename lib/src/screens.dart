import 'dart:async';
import 'dart:convert';
import 'package:resource_portable/resource_portable.dart';
import 'globals.dart';
import 'utils.dart' as utils;

/// Manage screens file.
class Screens {
  static const _screensPath = 'resources/screens.yaml';
  late Map<String, dynamic> _screens;

  /// Get screens yaml file from resources and parse.
  Future<void> init() async {
    const resource = Resource('package:screenshots/$_screensPath');
    final screens = await resource.readAsString(encoding: utf8);
    _screens = utils.parseYamlStr(screens)!;
  }

  /// Get screen information
  Map<String, dynamic> get screens => _screens;

  /// Get screen properties for [deviceName].
  Map<String, dynamic>? getScreen(String deviceName) {
    Map<String, dynamic>? screenProps;
    for (final osScreens in screens.values) {
      for (var screenProps in (osScreens as Map<String, dynamic>).values) {
        if ((screenProps['devices'] as List<dynamic>).contains(deviceName)) {
          screenProps = screenProps;
        }
      }
    }
    return screenProps;
  }

  /// Get [DeviceType] for [deviceName].
  DeviceType? getDeviceType(String deviceName) {
    DeviceType? deviceType;
    screens.forEach((_deviceType, osScreens) {
      for (final osScreen
          in (osScreens as Map<String, Map<String, List<String>>>).values) {
        if (osScreen['devices']!.contains(deviceName)) {
          deviceType = utils.getEnumFromString(DeviceType.values, _deviceType);
        }
      }
    });
    return deviceType;
  }

  /// Test if screen is used for identifying android model type.
  static bool isAndroidModelTypeScreen(Map screenProps) =>
      screenProps['size'] == null;

  /// Get supported device names by [os]
  List<String> getSupportedDeviceNamesByOs(String os) {
    final deviceNames = <String>[];
    screens.forEach((osType, osScreens) {
      if (osType == os) {
        (osScreens as Map<String, Map<String, List<String>>>)
            .forEach((screenId, screenProps) {
          // omit devices that have screens that are
          // only used to identify android model type
          if (!Screens.isAndroidModelTypeScreen(screenProps)) {
            screenProps['devices']!.forEach(deviceNames.add);
          }
        });
      }
    });
    // sort iPhone devices first
    deviceNames.sort((v1, v2) {
      if ('$v1'.contains('iPhone') && '$v2'.contains('iPad')) return -1;
      if ('$v1'.contains('iPad') && '$v2'.contains('iPhone')) return 1;
      return v1.compareTo(v2);
    });

    return deviceNames;
  }
}
