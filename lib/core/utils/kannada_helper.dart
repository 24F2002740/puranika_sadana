import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders Kannada text to a PNG image using Flutter's Canvas to ensure correct
/// native shaping, then returns it as a pw.Image for use in PDF documents.
Future<pw.Image> buildShapedKannadaWidget(
  String kannadaText, {
  double fontSize = 14,
  PdfColor color = PdfColors.black,
  double? maxWidth,
  TextAlign textAlign = TextAlign.left,
  FontWeight fontWeight = FontWeight.normal,
  String fontFamily = 'NotoSansKannada',
}) async {
  // If text is empty, return a tiny transparent image to avoid layout errors
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
        fontWeight: fontWeight,
        color: Color.fromARGB(
          (color.alpha * 255).round(),
          (color.red * 255).round(),
          (color.green * 255).round(),
          (color.blue * 255).round(),
        ),
        fontFamily: fontFamily,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
  )..layout(maxWidth: maxWidth ?? double.infinity);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  textPainter.paint(canvas, Offset.zero);

  final picture = recorder.endRecording();
  
  // Ensure we have valid dimensions
  final int width = textPainter.width.ceil().clamp(1, 10000);
  final int height = textPainter.height.ceil().clamp(1, 10000);
  
  final ui.Image image = await picture.toImage(width, height);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  if (byteData == null) {
    throw Exception('Failed to convert canvas to PNG bytes');
  }

  return pw.Image(pw.MemoryImage(byteData.buffer.asUint8List()), width: width.toDouble() * 0.75, height: height.toDouble() * 0.75);
}
