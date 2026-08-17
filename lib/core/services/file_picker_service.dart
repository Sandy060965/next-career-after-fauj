import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

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
