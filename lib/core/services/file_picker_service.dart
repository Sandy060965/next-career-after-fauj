import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A PDF larger than this can take long enough to base64-encode client-side
/// before an analysis request that the "Check match"/upload screen looks
/// permanently stuck rather than just slow. Callers that accept a raw PDF
/// upload (CV, JD) should reject anything past this with a clear reason —
/// see onboarding_screen.dart and jd_match_screen.dart.
const kMaxUploadPdfMb = 8;
const kMaxUploadPdfBytes = kMaxUploadPdfMb * 1024 * 1024;

typedef FileNamePicker = Future<String?> Function();

/// Opens the native file picker restricted to [allowedExtensions] and
/// returns the chosen file's name, or `null` if the user cancelled.
Future<String?> pickFileName({List<String>? allowedExtensions}) async {
  final file = await FilePicker.pickFile(
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
  );
  return file?.name;
}

/// A picked file's name plus its raw bytes, for callers that need the
/// actual content (e.g. CV text extraction) rather than just the name.
class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Like [pickFileName] but also reads the file's bytes.
Future<PickedFile?> pickFileWithBytes({List<String>? allowedExtensions}) async {
  final file = await FilePicker.pickFile(
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
  );
  if (file == null) return null;
  return PickedFile(name: file.name, bytes: await file.readAsBytes());
}
