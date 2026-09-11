import 'dart:typed_data';

/// Never actually called — pdf_export.dart only reaches this on web, where
/// pdf_download_web.dart is used instead. Exists solely so the conditional
/// import resolves on non-web platform builds.
void downloadBytes(Uint8List bytes, String fileName) {
  throw UnsupportedError('Direct file download is only implemented for web.');
}
