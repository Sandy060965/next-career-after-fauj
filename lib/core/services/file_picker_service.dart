import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A PDF larger than this can take long enough to base64-encode client-side
/// before an analysis request that the "Check match"/upload screen looks
/// permanently stuck rather than just slow. Callers that accept a raw PDF
/// upload (CV, JD) should reject anything past this with a clear reason —
/// see onboarding_screen.dart and jd_match_screen.dart.
const kMaxUploadPdfMb = 8;
const kMaxUploadPdfBytes = kMaxUploadPdfMb * 1024 * 1024;

/// Thrown when the user picks a file whose extension isn't in the caller's
/// [allowedExtensions] list. Kept distinct from a plain `null` return (which
/// means "cancelled") so callers can show a specific message.
class UnsupportedFileTypeException implements Exception {
  const UnsupportedFileTypeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Shown when the file picker returns nothing while the app is running as
/// an installed home-screen icon on iOS — a documented WebKit bug where
/// input[type=file] can complete with no file returned even after a real
/// selection, specifically in standalone display mode (works fine in a
/// plain Safari tab). Genuinely indistinguishable from an ordinary cancel
/// at the code level, so this is only shown in that mode, not on every
/// cancel.
const kInstalledAppFilePickerHint =
    "If you selected a file and it didn't appear, this is a known Safari issue "
    'in the installed app — try opening the site directly in Safari instead of '
    'the home-screen icon.';

String _friendlyExtensionList(List<String> extensions) =>
    extensions.map((e) => e.toUpperCase()).join(' or ');

/// True if [fileName]'s extension (case-insensitive) is in [allowedExtensions].
bool _hasAllowedExtension(String fileName, List<String> allowedExtensions) {
  final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  return allowedExtensions.map((e) => e.toLowerCase()).contains(extension);
}

typedef FileNamePicker = Future<String?> Function();

/// Opens the native file picker and returns the chosen file's name, or
/// `null` if the user cancelled.
///
/// Always opens with no type restriction at the OS level (FileType.any) —
/// restricting via `allowedExtensions` maps to an HTML `accept` attribute on
/// web, which Mobile Safari is known to filter unreliably (the Files/iCloud
/// source can fail to appear at all for an extension-restricted picker).
/// [allowedExtensions], if given, is instead validated after the file comes
/// back, throwing [UnsupportedFileTypeException] with a clear message.
Future<String?> pickFileName({List<String>? allowedExtensions}) async {
  final file = await FilePicker.pickFile(type: FileType.any);
  if (file == null) return null;
  if (allowedExtensions != null && !_hasAllowedExtension(file.name, allowedExtensions)) {
    throw UnsupportedFileTypeException(
      'That file type isn\'t supported here — please choose a '
      '${_friendlyExtensionList(allowedExtensions)} file.',
    );
  }
  return file.name;
}

/// A picked file's name plus its raw bytes, for callers that need the
/// actual content (e.g. CV text extraction) rather than just the name.
class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Like [pickFileName] but also reads the file's bytes. See [pickFileName]
/// for why type filtering happens after picking rather than via the OS
/// picker's own type restriction.
Future<PickedFile?> pickFileWithBytes({List<String>? allowedExtensions}) async {
  final file = await FilePicker.pickFile(type: FileType.any);
  if (file == null) return null;
  if (allowedExtensions != null && !_hasAllowedExtension(file.name, allowedExtensions)) {
    throw UnsupportedFileTypeException(
      'That file type isn\'t supported here — please choose a '
      '${_friendlyExtensionList(allowedExtensions)} file.',
    );
  }
  return PickedFile(name: file.name, bytes: await file.readAsBytes());
}
