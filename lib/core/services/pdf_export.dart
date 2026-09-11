import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'pdf_download_stub.dart' if (dart.library.html) 'pdf_download_web.dart' as platform_download;

/// Renders [body] as a simple single-column PDF titled [title] and delivers
/// it to the officer. On mobile/desktop native, this hands off to the
/// platform's native share/save sheet ("Save to Files" etc.) via
/// [SharePlus]. On web, this always triggers a direct browser download —
/// deliberately bypassing SharePlus there, since a "Download" button should
/// always just download: some desktop browsers (Chrome included) support
/// the Web Share API for files, which would otherwise open the native OS
/// share sheet instead of saving the file, surprising anyone who tapped a
/// button labelled "Download".
Future<void> exportTextAsPdf({required String title, required String body}) async {
  // The bundled Inter font (already shipped for the app's own UI) covers ₹,
  // en/em dashes, bullets, and check marks that the PDF package's built-in
  // base-14 fonts can't draw — without it those characters silently vanish
  // from the downloaded file.
  final regularFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'));
  final boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf'));

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 16),
        pw.Text(
          body,
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
          overflow: pw.TextOverflow.span,
        ),
      ],
    ),
  );
  final bytes = await doc.save();
  final safeName = title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
  await deliverPdfBytes(bytes, '$safeName.pdf');
}

/// Hands already-built PDF bytes to the officer — a direct browser download
/// on web, the native share/save sheet elsewhere. Shared by every PDF
/// exporter in the app (not just [exportTextAsPdf]) so this platform split
/// lives in exactly one place.
Future<void> deliverPdfBytes(Uint8List bytes, String fileName) async {
  if (kIsWeb) {
    platform_download.downloadBytes(bytes, fileName);
    return;
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
      fileNameOverrides: [fileName],
    ),
  );
}
