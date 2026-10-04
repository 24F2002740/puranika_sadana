import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders Kannada text to a PNG image using Flutter's Canvas to ensure correct
/// native shaping, then returns it as a pw.Image for use in PDF documents.
///
/// This requires a Flutter context or to be run within a Flutter app environment
/// where NotoSansKannada font is registered.
Future<pw.Image> buildShapedKannadaWidget(
  String kannadaText, {
  double fontSize = 14,
  PdfColor color = PdfColors.black,
}) async {
  // Handle empty text to avoid toImage() errors with zero dimensions
  if (kannadaText.isEmpty) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.transparent);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return pw.Image(pw.MemoryImage(byteData!.buffer.asUint8List()));
  }

  final TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: kannadaText,
      style: TextStyle(
        fontSize: fontSize,
        color: Color.fromARGB(
          (color.alpha * 255).round(),
          (color.red * 255).round(),
          (color.green * 255).round(),
          (color.blue * 255).round(),
        ),
        fontFamily: 'NotoSansKannada',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  textPainter.paint(canvas, Offset.zero);

  final picture = recorder.endRecording();
  // Ensure we have at least 1x1 dimensions
  final ui.Image image = await picture.toImage(
    textPainter.width.ceil().clamp(1, 10000),
    textPainter.height.ceil().clamp(1, 10000),
  );
  
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception('Failed to convert canvas to PNG bytes');
  }
  final Uint8List pngBytes = byteData.buffer.asUint8List();

  return pw.Image(pw.MemoryImage(pngBytes));
}
