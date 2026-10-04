import 'dart:io';
import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../features/dashboard/domain/models/booking.dart';

class CertificateService {
  static final CertificateService _instance = CertificateService._internal();
  factory CertificateService() => _instance;
  CertificateService._internal();

  Future<Uint8List> generateCertificateBytes(Booking booking, {bool isDuplicate = false}) async {
    final pdf = pw.Document();
    
    final deityImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/mookambika.png')).buffer.asUint8List(),
    );
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    final kannadaFont = await PdfGoogleFonts.notoSansKannadaRegular();
    final kannadaBoldFont = await PdfGoogleFonts.notoSansKannadaBold();
    final serifBoldFont = await PdfGoogleFonts.notoSerifBold();
    final serifItalicFont = await PdfGoogleFonts.notoSerifItalic();

    // Darkened colors for better print legibility
    final maroon = PdfColor.fromInt(0xFF3A0D02); // Darker maroon
    final gold = PdfColor.fromInt(0xFF965B00);   // Darker gold/brown for print
    final cream = PdfColor.fromInt(0xFFFFFCF6);

    final eventTimeStr = _formatTimeOfDay(booking.startTime);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: cream,
                border: pw.Border.all(color: gold, width: 2.0), // Increased thickness
              ),
              child: pw.Stack(
                children: [
                  // Full Decorative Border (Top, Bottom, Left, Right)
                  pw.Positioned(
                    top: 0, left: 0, right: 0,
                    child: _buildHorizontalStripedBorder(maroon, cream),
                  ),
                  pw.Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: _buildHorizontalStripedBorder(maroon, cream),
                  ),
                  pw.Positioned(
                    top: 0, bottom: 0, left: 0,
                    child: _buildVerticalStripedBorder(maroon, cream),
                  ),
                  pw.Positioned(
                    top: 0, bottom: 0, right: 0,
                    child: _buildVerticalStripedBorder(maroon, cream),
                  ),

                  pw.Center(
                    child: pw.Opacity(
                      opacity: 0.08, // Slightly increased from 0.05 for print
                      child: pw.Image(logoImage, width: 350),
                    ),
                  ),
                  
                  if (isDuplicate)
                    pw.Center(
                      child: pw.Transform.rotate(
                        angle: -0.5,
                        child: pw.Opacity(
                          opacity: 0.15, // Slightly increased from 0.1
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.red900, width: 5),
                            ),
                            child: pw.Text(
                              "DUPLICATE COPY",
                              style: pw.TextStyle(
                                color: PdfColors.red900,
                                fontSize: 65,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 45),
                    child: pw.Column(
                      children: [
                        if (isDuplicate)
                          pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: maroon, width: 1.5),
                              ),
                              child: pw.Text("DUPLICATE COPY", style: pw.TextStyle(color: maroon, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            ),
                          ),
                        pw.Center(
                          child: pw.Image(deityImage, width: 95, height: 115),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Center(
                          child: pw.Text("|| Sri Mookambika ||", 
                            style: pw.TextStyle(color: maroon, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(height: 10),
                        
                        pw.Center(
                          child: pw.Text("SRI PURANIK SADANA", 
                            style: pw.TextStyle(font: serifBoldFont, color: maroon, fontSize: 32)),
                        ),
                        pw.Center(
                          child: pw.Text("Car Street, Sri Kshetra Kollur - 576220, Udupi Dist.", 
                            style: pw.TextStyle(color: PdfColors.black, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ),
                        
                        pw.SizedBox(height: 15),
                        pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text("Certificate issued: ${DateFormat('dd-MM-yyyy').format(booking.certificateIssuedAt ?? DateTime.now())}", 
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ),
                        
                        pw.SizedBox(height: 20),
                        pw.Center(
                          child: pw.Text("This is to certify that", 
                            style: pw.TextStyle(font: serifItalicFont, fontSize: 18, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                        ),
                        
                        pw.SizedBox(height: 20),
                        
                        _buildPersonBlock(
                          "Chi. ${booking.groomName}",
                          "S/o ${booking.groomFatherName ?? ''}",
                          "DOB: ${booking.groomDob ?? ''}",
                          booking.groomAddress ?? '',
                          serifBoldFont,
                          kannadaBoldFont,
                          kannadaFont,
                        ),
                        
                        pw.SizedBox(height: 18),
                        
                        _buildPersonBlock(
                          "Chi. Sou. ${booking.brideName}",
                          "D/o ${booking.brideFatherName ?? ''}",
                          "DOB: ${booking.brideDob ?? ''}",
                          booking.brideAddress ?? '',
                          serifBoldFont,
                          kannadaBoldFont,
                          kannadaFont,
                        ),
                        
                        pw.SizedBox(height: 25),
                        
                        pw.Center(
                          child: pw.Column(
                            children: [
                              pw.Text("are married at Sri Puranik Sadana, Kollur", 
                                style: pw.TextStyle(font: serifItalicFont, fontSize: 16, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                              pw.Text("on ${DateFormat('dd-MM-yyyy').format(booking.eventDate)} $eventTimeStr", 
                                style: pw.TextStyle(font: serifBoldFont, fontSize: 16, color: maroon)),
                              pw.Text("according to Hindu Religion Marriage Systems", 
                                style: pw.TextStyle(font: serifItalicFont, fontSize: 16, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                        
                        pw.Spacer(),
                        
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              children: [
                                pw.Container(width: 140, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1.2, color: PdfColors.black)))),
                                pw.Text("Party Signature", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                            pw.Column(
                              children: [
                                pw.Container(width: 140, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1.2, color: PdfColors.black)))),
                                pw.Text("Authorised Signature", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        
                        pw.SizedBox(height: 15),
                        pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text("Collected by — Mob: ${booking.collectedByMobile ?? ''}", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ),
                        
                        pw.SizedBox(height: 12),
                        pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 1.0, color: PdfColors.black),
                        pw.Center(
                          child: pw.Text("Certificate ID #WB-${booking.eventDate.year}-${booking.id.split('-').last}", 
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                        ),
                        if (isDuplicate && booking.reissueDate != null)
                           pw.Center(
                            child: pw.Text("Duplicate Reissued on: ${DateFormat('dd-MM-yyyy HH:mm').format(booking.reissueDate!)} - Auth by PIN", 
                              style: pw.TextStyle(fontSize: 9, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<String> generateCertificatePdf(Booking booking, {bool isDuplicate = false}) async {
    final bytes = await generateCertificateBytes(booking, isDuplicate: isDuplicate);
    final output = await getApplicationDocumentsDirectory();
    final fileName = isDuplicate ? "Marriage_Certificate_Duplicate_${booking.id}.pdf" : "Marriage_Certificate_${booking.id}.pdf";
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(bytes);
    return file.path;
  }

  pw.Widget _buildHorizontalStripedBorder(PdfColor maroon, PdfColor cream) {
    return pw.Container(
      height: 12,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: List.generate(45, (index) => pw.Expanded(
          child: pw.Container(
            color: index % 2 == 0 ? maroon : cream,
          ),
        )),
      ),
    );
  }

  pw.Widget _buildVerticalStripedBorder(PdfColor maroon, PdfColor cream) {
    return pw.Container(
      width: 12,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: List.generate(65, (index) => pw.Expanded(
          child: pw.Container(
            color: index % 2 == 0 ? maroon : cream,
          ),
        )),
      ),
    );
  }

  pw.Widget _buildPersonBlock(
    String name, 
    String parent, 
    String dob, 
    String address,
    pw.Font serifBold,
    pw.Font kannadaBold,
    pw.Font kannadaFont,
  ) {
    final bool isKannada = name.contains(RegExp(r'[\u0C80-\u0CFF]'));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(style: pw.BorderStyle.dotted, width: 1.2, color: PdfColors.black)),
          ),
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(name, 
            style: pw.TextStyle(
              font: isKannada ? kannadaBold : serifBold,
              fontSize: 18,
              color: PdfColors.black,
            )),
        ),
        pw.SizedBox(height: 6),
        pw.Text(parent, style: pw.TextStyle(font: kannadaBold, fontSize: 13, color: PdfColors.black)), // Changed to kannadaBold
        pw.SizedBox(height: 3),
        pw.Text(dob, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 3),
        pw.RichText(text: pw.TextSpan(
          children: [
            pw.TextSpan(text: "Address: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black)),
            pw.TextSpan(text: address, style: pw.TextStyle(font: kannadaBold, fontSize: 13, color: PdfColors.black)), // Changed to kannadaBold
          ]
        )),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return "";
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }
}
