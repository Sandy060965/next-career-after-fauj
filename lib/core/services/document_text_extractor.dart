import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class DocxExtractionException implements Exception {
  DocxExtractionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Extracts plain text from a .docx file's bytes. A .docx is a zip archive
/// containing word/document.xml, whose paragraphs (`w:p`) hold text runs
/// (`w:t`) — this unzips it and reads those runs out in document order.
Future<String> extractDocxText(Uint8List bytes) async {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (e) {
    throw DocxExtractionException("Couldn't open this file as a .docx: $e");
  }

  final matches = archive.files.where((f) => f.name == 'word/document.xml');
  if (matches.isEmpty) {
    throw DocxExtractionException(
      'This .docx has no word/document.xml — is it a valid Word file?',
    );
  }
  final documentFile = matches.first;

  final XmlDocument document;
  try {
    final xmlString = utf8.decode(documentFile.content as List<int>);
    document = XmlDocument.parse(xmlString);
  } catch (e) {
    throw DocxExtractionException("Couldn't read this .docx's content: $e");
  }

  final buffer = StringBuffer();
  for (final paragraph in document.findAllElements('p', namespace: '*')) {
    final text = paragraph
        .findAllElements('t', namespace: '*')
        .map((e) => e.innerText)
        .join();
    if (text.trim().isNotEmpty) {
      buffer.writeln(text);
    }
  }

  final result = buffer.toString().trim();
  if (result.isEmpty) {
    throw DocxExtractionException('No readable text found in this .docx.');
  }
  return result;
}
