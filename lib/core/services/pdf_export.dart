import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Renders [body] as a simple single-column PDF titled [title] and hands
/// it to the platform's native share/save sheet — works the same way on
/// web (browser download or Web Share API) and mobile (share sheet with a
/// "Save to Files" option), with no platform-specific file-path handling.
Future<void> exportTextAsPdf({required String title, required String body}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 16),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
      ],
    ),
  );
  final bytes = await doc.save();
  final safeName = title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, name: '$safeName.pdf', mimeType: 'application/pdf')],
      fileNameOverrides: ['$safeName.pdf'],
    ),
  );
}
