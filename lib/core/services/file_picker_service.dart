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
