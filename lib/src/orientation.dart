import 'package:tool_base/tool_base.dart';
import 'package:tool_mobile/tool_mobile.dart';

import 'globals.dart';
import 'utils.dart' as utils;
import 'utils.dart';

const kDefaultOrientation = 'Portrait';

enum Orientation { Portrait, LandscapeRight, PortraitUpsideDown, LandscapeLeft }

/// Change orientation of a running emulator or simulator.
/// (No known way of supporting real devices.)
void changeDeviceOrientation(DeviceType deviceType, Orientation orientation,
    {String? deviceId, String? scriptDir}) {
  final androidOrientations = {
    'Portrait': '0',
    'LandscapeRight': '1',
    'PortraitUpsideDown': '2',
    'LandscapeLeft': '3'
  };
  final iosOrientations = {
    'Portrait': 'Portrait',
    'LandscapeRight': 'Landscape Right',
    'PortraitUpsideDown': 'Portrait Upside Down',
    'LandscapeLeft': 'Landscape Left'
  };
  const sim_orientation_script = 'sim_orientation.scpt';
  final orientation0 = utils.getStringFromEnum(orientation);
  printStatus('Setting orientation to $orientation0');
  switch (deviceType) {
    case DeviceType.android:
      cmd([
        getAdbPath(androidSdk)!,
        '-s',
        deviceId!,
        'shell',
        'settings',
        'put',
        'system',
        'user_rotation',
        androidOrientations[orientation0]!
      ]);
      break;
    case DeviceType.ios:
      // requires permission when run for first time
      cmd([
        'osascript',
        '$scriptDir/$sim_orientation_script',
        iosOrientations[orientation0]!
      ]);
      break;
    case DeviceType.web:
      throw 'web not yet implemented';
  }
}

Orientation getOrientationEnum(String orientation) {
  final orientation0 =
      utils.getEnumFromString<Orientation>(Orientation.values, orientation);
  orientation0 == null
      ? throw 'Error: orientation \'$orientation\' not found'
      : null;
  return orientation0;
}
