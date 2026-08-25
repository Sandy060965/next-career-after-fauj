import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'cv_template.dart';

/// Overridable for testing so the platform share sheet is never actually
/// invoked in a test run.
typedef TemplateSharer = Future<void> Function(CvTemplate template);

/// Copies the bundled template asset to a temp file and hands it to the
/// platform share sheet — the standard Flutter pattern for letting the
/// officer save or forward a bundled file, since there's no direct
/// "download to device" API.
Future<void> shareTemplateFile(CvTemplate template) async {
  final data = await rootBundle.load(template.assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${template.fileName}');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], subject: template.fileName),
  );
}
