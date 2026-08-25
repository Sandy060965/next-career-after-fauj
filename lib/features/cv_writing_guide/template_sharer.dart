import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';

import 'cv_template.dart';

const _docxMimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

/// Overridable for testing so the platform share sheet is never actually
/// invoked in a test run.
typedef TemplateSharer = Future<void> Function(CvTemplate template);

/// Hands the bundled template asset to the platform share sheet as an
/// in-memory file — deliberately not path_provider + a temp-file write
/// (the previous approach): path_provider has no web implementation at
/// all (only android/ios/linux/macos/windows are in its own plugin
/// manifest), so that path always threw on web. XFile.fromData works
/// purely in memory on every platform, web included, with no disk I/O.
Future<void> shareTemplateFile(CvTemplate template) async {
  final data = await rootBundle.load(template.assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, name: template.fileName, mimeType: _docxMimeType)],
      subject: template.fileName,
    ),
  );
}
