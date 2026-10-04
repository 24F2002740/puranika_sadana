import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../features/dashboard/presentation/providers/booking_wizard_provider.dart';
import '../core/services/pricing_service.dart';
import '../core/utils/kannada_helper.dart';
import 'dart:ui' as ui;

class ReceiptGenerator {
  static Future<Uint8List> generate(BookingWizardState state) async {
    final pdf = pw.Document();
    final pricing = PricingService();

    final kannadaFont = await PdfGoogleFonts.notoSansKannadaRegular();
    final boldFont = await PdfGoogleFonts.notoSansKannadaBold();

    Uint8List logoData = Uint8List(0);
    Uint8List deityData = Uint8List(0);
    try {
      logoData = (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
      deityData = (await rootBundle.load('assets/mookambika.png')).buffer.asUint8List();
    } catch (_) {}

    final maroon = PdfColor.fromInt(0xFF5D1014);
    final gold = PdfColor.fromInt(0xFFD4AF37);
    final ivory = PdfColor.fromInt(0xFFFFF8EF);
    final mediumGrey = PdfColors.grey600;

    // Pre-render shaped Kannada widgets for the checklist section
    final checklistTitle = await buildShapedKannadaWidget(
      'ತರಬೇಕಾದ ವಸ್ತುಗಳು',
      fontSize: 10,
      color: gold,
      fontWeight: ui.FontWeight.bold,
    );
    final checklistContent = await buildShapedKannadaWidget(
      'ಬುಕಿಂಗ್ ರಸೀದಿ · ಆಧಾರ್ ಕಾರ್ಡ್ (ಹುಡುಗ & ಹುಡುಗಿ) · ಆಮಂತ್ರಣ ಪತ್ರಿಕೆ · ಸಿಂಗಾರ ಕೊನೆ · ಹಣ್ಣು ಕಾಯಿ (ದೇವಸ್ಥಾನಕ್ಕೆ)',
      fontSize: 8,
      color: PdfColors.white,
      fontWeight: ui.FontWeight.bold,
    );

    final totalAmount = state.totalAmount;

    final String eventDate = state.eventDate != null 
        ? DateFormat('dd MMM yyyy').format(state.eventDate!) 
        : '';
    
    String eventTime = '';
    if (state.muhurthamTime != null) {
      final hour = state.muhurthamTime!.hourOfPeriod == 0 ? 12 : state.muhurthamTime!.hourOfPeriod;
      final minute = state.muhurthamTime!.minute.toString().padLeft(2, '0');
      final period = state.muhurthamTime!.period.index == 0 ? 'AM' : 'PM';
      eventTime = '$hour:$minute $period';
    }

    double menuRate = 0;
    if (state.selectedMenuTier == 1) {
      menuRate = pricing.menu1Price;
    } else if (state.selectedMenuTier == 2) {
      menuRate = pricing.menu2Price;
    } else if (state.selectedMenuTier == 3) {
      menuRate = pricing.menu3Price;
    }
    
    if (state.menuRateOverride != null && state.menuRateOverride! > 0) {
      menuRate = state.menuRateOverride!;
    }

    if (state.addPalav) {
      menuRate += pricing.palavSaladPrice;
    }
    if (state.addPoori) {
      menuRate += pricing.pooriSaguPrice;
    }
    if (state.addIceCream) {
      menuRate += pricing.iceCreamPrice;
    }
    if (state.addWater) {
      menuRate += pricing.waterBottlePrice;
    }
    for (var extra in state.customExtras) {
      if (!extra.isFlat) {
        menuRate += extra.rate;
      }
    }

    final dishes = <String>[];
    if (state.selectedMenuTier == 1) {
      dishes.addAll(pricing.menu1Dishes);
    } else if (state.selectedMenuTier == 2) {
      dishes.addAll(pricing.menu2Dishes);
    } else if (state.selectedMenuTier == 3) {
      dishes.addAll(pricing.menu3Dishes);
    }
    for (var extra in state.customExtras) {
      if (!extra.isFlat) {
        dishes.add(extra.name);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: kannadaFont, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: pw.BoxDecoration(color: maroon),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoData.isNotEmpty) pw.Image(pw.MemoryImage(logoData), width: 50),
                    pw.Column(
                      children: [
                        pw.Text('ಶ್ರೀ ಮೂಕಾಂಬಿಕಾ ದೇವಿ ಕೃಪೆ', style: pw.TextStyle(color: ivory, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Puranika Sadana', style: pw.TextStyle(color: gold, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Sri Kshetra Kollur', style: pw.TextStyle(color: ivory, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    if (deityData.isNotEmpty) pw.Image(pw.MemoryImage(deityData), width: 50),
                  ],
                ),
              ),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                color: ivory,
                child: pw.Center(
                  child: pw.Text('ಬುಕಿಂಗ್ ರಸೀದಿ · BOOKING RECEIPT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: maroon)),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFFBF5),
                  border: pw.Border.all(color: maroon, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(font: kannadaFont, fontSize: 11, color: PdfColors.black),
                              children: [
                                pw.TextSpan(text: 'ವಧು-ವರ: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                pw.TextSpan(text: 'ಚಿ.${state.groomName} & ಚಿ.ಸೌ.${state.brideName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(font: kannadaFont, fontSize: 11, color: PdfColors.black),
                              children: [
                                pw.TextSpan(text: 'ಊರು: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                pw.TextSpan(text: state.address, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text('ದಿನಾಂಕ: $eventDate', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text('ಮುಹೂರ್ತ: $eventTime', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('ಲಗ್ನ: ${state.lagna ?? ''}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              _buildPillBox(
                title: 'ಹಾಲ್ ಸೌಲಭ್ಯಗಳು — Hall Facilities',
                items: pricing.getHallFeatures(state.selectedHall),
                maroon: maroon,
                mediumGrey: mediumGrey,
              ),
              pw.SizedBox(height: 12),
              _buildPillBox(
                title: 'ಮೆನು — ₹${menuRate.toInt()}/ಎಡೆಗೆ',
                items: dishes,
                maroon: maroon,
                mediumGrey: mediumGrey,
              ),
              pw.SizedBox(height: 12),
              
              if (state.addCleaning || 
                  state.additionalGuestsCharge > 0 || 
                  state.hallDiscount > 0 || 
                  state.cateringDiscount > 0 ||
                  state.addPreviousDayHall ||
                  state.addBeligeTindi ||
                  state.addSanjeTindi ||
                  state.addRatriUta ||
                  state.extraPurohitaruEnabled ||
                  state.drinkEnabled)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  child: pw.Column(
                    children: [
                      if (state.addPreviousDayHall)
                        _buildPriceRow('ಹಿಂದಿನ ದಿನದ ಹಾಲ್ (Previous Day Hall)', state.previousDayHallAmount),
                      if (state.addBeligeTindi)
                        _buildPriceRow('ಬೆಳಗಿನ ತಿಂಡಿ (Belige Tindi)', state.beligeTindiAmount),
                      if (state.addSanjeTindi)
                        _buildPriceRow('ಸಂಜೆಯ ತಿಂಡಿ (Sanje Tindi)', state.sanjeTindiAmount),
                      if (state.addRatriUta)
                        _buildPriceRow('ರಾತ್ರಿಯ ಊಟ (Ratri Uta)', state.ratriUtaAmount),
                      if (state.extraPurohitaruEnabled)
                        _buildPriceRow('ಹೆಚ್ಚುವರಿ ಪುರೋಹಿತರು (Extra Purohitaru)', state.extraPurohitaruAmount),
                      if (state.drinkEnabled)
                        _buildPriceRow(state.drinkName, state.drinkTotalAmount),
                      if (state.addCleaning)
                        _buildPriceRow('ಕ್ಲೀನಿಂಗ್ ಚಾರ್ಜ್ (Cleaning Charge)', state.cleaningCharge),
                      if (state.additionalGuestsCharge > 0)
                        _buildPriceRow('Additional Guests (${(state.finalGuestCount ?? state.guestCount) - state.guestCount} extra)', state.additionalGuestsCharge),
                      if (state.hallDiscount > 0)
                        _buildPriceRow('Hall Discount', -state.hallDiscount, color: PdfColor.fromInt(0xFF1B5E20)),
                      if (state.cateringDiscount > 0)
                        _buildPriceRow('Catering Discount', -state.cateringDiscount, color: PdfColor.fromInt(0xFF1B5E20)),
                    ],
                  ),
                ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Divider(thickness: 1.5, color: maroon),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ಒಟ್ಟು (Total)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: maroon)),
                      pw.Text('ಮುಂಗಡ (Advance paid)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ಬಾಕಿ (Balance due)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('₹${totalAmount.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: maroon)),
                      pw.Text('₹${state.advanceAmount.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('₹${(totalAmount - state.advanceAmount).toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildShapedInfoBox(
                      checklistTitle,
                      checklistContent,
                      maroon,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _buildInfoBox(
                      'ಮತ್ತೆ ನಿಮಗೆ ಬೇಕಾದ ವಸ್ತುಗಳು',
                      'ಪೇಟ · ಕಾಲುಂಗುರ · ಕರಿಮಣಿ · ಧಾರೆಸೀರೆ · ಬಾಸಿಂಗ, etc.',
                      maroon,
                      gold,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: 160,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(width: 1.5, color: PdfColors.black)),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Customer Signature', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: 160,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(width: 1.5, color: PdfColors.black)),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPriceRow(String label, double amount, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Text(
            '${amount < 0 ? "-" : ""}₹${amount.abs().toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}', 
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPillBox({
    required String title,
    required List<String> items,
    required PdfColor maroon,
    required PdfColor mediumGrey,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: mediumGrey, width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(color: maroon, fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Divider(thickness: 1, color: mediumGrey),
          ),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFEEEEEE),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: PdfColors.grey500, width: 1),
              ),
              child: pw.Text(item, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoBox(String title, String content, PdfColor maroon, PdfColor gold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: maroon,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(color: gold, fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Text(content, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, height: 1.4, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildShapedInfoBox(pw.Widget title, pw.Widget content, PdfColor maroon) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: maroon,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          title,
          pw.SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}
