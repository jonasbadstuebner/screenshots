import 'dart:async';

import 'package:resource_portable/resource_portable.dart';
import 'package:tool_base/tool_base.dart';

import 'utils.dart';

///
/// Copy resource images for a screen from package to files.
///
Future<void> unpackImages(
    Map<String, String> screenResources, String dstDir) async {
  for (final resourcePath in screenResources.values) {
    final resourceImage = await readResourceImage(resourcePath);

    // create resource file
    final dstPath = '$dstDir/$resourcePath';
    await writeImage(resourceImage, dstPath);
  }
}

/// Read scripts from resources and install in staging area.
Future<void> unpackScripts(String dstDir) async {
  await unpackScript(
    'resources/script/android-wait-for-emulator',
    dstDir,
  );
  await unpackScript(
    'resources/script/android-wait-for-emulator-to-stop',
    dstDir,
  );
  await unpackScript(
    'resources/script/simulator-controller',
    dstDir,
  );
  await unpackScript(
    'resources/script/sim_orientation.scpt',
    dstDir,
  );
}

/// Read script from resources and install in staging area.
Future<void> unpackScript(String srcPath, String dstDir) async {
  final resource = Resource('package:screenshots/$srcPath');
  final script = await resource.readAsString();
  final file = await fs.file('$dstDir/$srcPath').create(recursive: true);
  await file.writeAsString(script, flush: true);
  // make executable
  cmd(['chmod', 'u+x', '$dstDir/$srcPath']);
}

/// Read an image from resources.
Future<List<int>> readResourceImage(String uri) async {
  final resource = Resource('package:screenshots/$uri');
  return resource.readAsBytes();
}

/// Write an image to staging area.
Future<void> writeImage(List<int> image, String path) async {
  final file = await fs.file(path).create(recursive: true);
  await file.writeAsBytes(image, flush: true);
}
