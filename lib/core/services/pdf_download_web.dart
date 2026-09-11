import 'dart:html' as html;
import 'dart:typed_data';

/// Directly triggers a browser file download — no Web Share API, no native
/// OS share sheet, just a save-to-disk anchor click. See pdf_export.dart
/// for why this exists as a separate, web-only path.
///
/// Deliberately uses a data: URI, not a blob: URL — this is the exact
/// pattern share_plus's own web download fallback uses internally. A blob:
/// URL requires createObjectURL/revokeObjectURL lifecycle management, where
/// revoking too early (even after a delay, if generation is slow enough to
/// eat into it) can silently fail the download; a data: URI embeds the
/// bytes directly in the href, so there is no separate object whose
/// lifetime can be gotten wrong.
void downloadBytes(Uint8List bytes, String fileName) {
  final anchor = html.AnchorElement(
    href: Uri.dataFromBytes(bytes, mimeType: 'application/pdf').toString(),
  )
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}
