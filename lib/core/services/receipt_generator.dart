import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

import '../../features/dashboard/presentation/providers/booking_wizard_provider.dart';
import '../constants/app_constants.dart';
import 'settings_service.dart';
import '../utils/kannada_helper.dart';

class ReceiptGenerator {
  static Future<Uint8List> generate(BookingWizardState state) async {
    final pdf = pw.Document();
    final settings = SettingsService();
    final currencyFormatter = NumberFormat('#,##,###', 'en_IN');

    // Font for English parts and fallback
    pw.Font? englishFont;
    try {
      final eData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      englishFont = pw.Font.ttf(eData);
    } catch (_) {
      englishFont = pw.Font.helvetica();
    }
    final eFont = englishFont;

    Uint8List logoData = Uint8List(0);
    Uint8List deityData = Uint8List(0);
    try {
      if (settings.logoImageUrl != null) {
        if (settings.logoImageUrl!.startsWith('http')) {
          final response = await http.get(Uri.parse(settings.logoImageUrl!));
          if (response.statusCode == 200) {
            logoData = response.bodyBytes;
          }
        } else if (File(settings.logoImageUrl!).existsSync()) {
          logoData = await File(settings.logoImageUrl!).readAsBytes();
        }
      }
      
      if (logoData.isEmpty) {
        logoData = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
      }
      deityData = (await rootBundle.load('assets/images/mookambika.png')).buffer.asUint8List();
    } catch (_) {}

    final maroon = PdfColor.fromInt(0xFF5D1014);
    final gold = PdfColor.fromInt(0xFF965B00); // Darker gold for print
    final ivory = PdfColor.fromInt(0xFFFFF8EF);
    final darkGray = PdfColors.black; // Pure black for better print legibility
    final darkGreen = PdfColors.green900;

    // Helper to shorten the shaping calls - Defaults to BOLD for print
    Future<pw.Widget> sh(String text, double size, PdfColor color, {double? maxWidth, ui.TextAlign align = ui.TextAlign.left, ui.FontWeight fontWeight = ui.FontWeight.bold}) =>
        buildShapedKannadaWidget(text, fontSize: size, color: color, maxWidth: maxWidth, textAlign: align, fontWeight: fontWeight);

    // --- Pre-render Header & Business Info ---
    final headerKImg = await sh('ಶ್ರೀ ಮೂಕಾಂಬಿಕಾ ದೇವಿ ಕೃಪೆ', 10, ivory);
    final bizNameImg = await sh(settings.businessName, 20, gold, fontWeight: ui.FontWeight.bold);
    final bizAddrImg = await sh(settings.businessAddress, 9, ivory, fontWeight: ui.FontWeight.bold);
    final receiptLabelImg = await sh('ಬುಕಿಂಗ್ ರಸೀದಿ · ', 11, maroon, fontWeight: ui.FontWeight.bold);

    // --- Pre-render Booking Details ---
    final vadhuvVaraLabelImg = await sh('ವಧು-ವರ: ', 12, darkGray, fontWeight: ui.FontWeight.bold);
    final groomNameImg = await sh(state.groomName, 14, darkGray, fontWeight: ui.FontWeight.bold);
    final brideNameImg = await sh(state.brideName, 14, darkGray, fontWeight: ui.FontWeight.bold);
    
    final uruLabelImg = await sh('ಊರು: ', 12, darkGray, fontWeight: ui.FontWeight.bold);
    final addressImg = await sh(state.address, 12, darkGray, fontWeight: ui.FontWeight.bold);
    
    final dinankaLabelImg = await sh('ದಿನಾಂಕ: ', 12, darkGray, fontWeight: ui.FontWeight.bold);
    final eventDateStr = state.eventDate != null ? DateFormat('dd MMM yyyy').format(state.eventDate!) : '';
    
    final muhurthaLabelImg = await sh('ಮುಹೂರ್ತ: ', 12, darkGray, fontWeight: ui.FontWeight.bold);
    String eventTimeStr = '';
    if (state.muhurthamTime != null) {
      final hourRaw = state.muhurthamTime!.hour;
      final hour = hourRaw % 12 == 0 ? 12 : hourRaw % 12;
      final minute = state.muhurthamTime!.minute.toString().padLeft(2, '0');
      final period = hourRaw < 12 ? 'AM' : 'PM';
      eventTimeStr = '$hour:$minute $period';
    }
    
    final athithigaluLabelImg = await sh('ಅತಿಥಿಗಳು: ', 12, darkGray, fontWeight: ui.FontWeight.bold);

    // --- Section Preparation ---
    final hallFeaturesTitleImg = await sh('ಹಾಲ್ ಸೌಲಭ್ಯಗಳು — Hall Facilities', 13, maroon, fontWeight: ui.FontWeight.bold);
    final menuTitleImg = await sh('ಮೆನು — Catering Items', 13, maroon, fontWeight: ui.FontWeight.bold);
    
    final hallFeatures = state.selectedHall?.facilities ?? [];
    final hallFeatureWidgets = await Future.wait(hallFeatures.asMap().entries.map((e) => 
        sh('${e.key + 1}. ${e.value}', 10, darkGray, fontWeight: ui.FontWeight.bold)));

    // MENU ITEMS
    final displayCateringItems = [...state.cateringItems];
    for (var extra in state.customExtras) {
      if (!extra.isFlat) {
        if (!displayCateringItems.contains(extra.name)) {
          displayCateringItems.add(extra.name);
        }
      }
    }

    final cateringItemWidgets = await Future.wait(displayCateringItems.map((item) async {
       return await sh(item, 10, darkGray, fontWeight: ui.FontWeight.bold);
    }));

    final totalLabelImg = await sh('ಒಟ್ಟು ', 12, maroon, fontWeight: ui.FontWeight.bold);
    final balanceLabelImg = await sh('ಬಾಕಿ ', 12, maroon, fontWeight: ui.FontWeight.bold);

    // --- Pricing Labels Preparation ---
    final hallRentalLabel = await sh('Hall Rental (${state.selectedHall?.name ?? ""})', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final previousDayHallLabel = await sh('ಹಿಂದಿನ ದಿನದ ಹಾಲ್ (Previous Day Hall)', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final vadyaLabel = await sh('Vadya (Band)', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final extraPurohitaruLabel = await sh('Extra Purohitaru', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final cateringLabel = await sh('Catering ${state.selectedMenuTier != null ? "(Tier ${state.selectedMenuTier})" : "(Manual)"}', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final beligeTindiLabel = await sh('ಬೆಳಗಿನ ತಿಂಡಿ (Belige Tindi)', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final sanjeTindiLabel = await sh('ಸಂಜೆಯ ತಿಂಡಿ (Sanje Tindi)', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final ratriUtaLabel = await sh('ರಾತ್ರಿಯ ಊಟ (Ratri Uta)', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final drinkLabel = await sh(state.drinkName, 11, darkGray, fontWeight: ui.FontWeight.bold);
    final cleaningLabel = await sh('Cleaning Charge', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final addGuestsLabel = await sh('Additional Guests Charge', 11, darkGray, fontWeight: ui.FontWeight.bold);
    final subtotalLabel = await sh('Subtotal (before discounts)', 11, maroon, fontWeight: ui.FontWeight.bold);
    final hallDiscountLabel = await sh('Hall Discount', 11, darkGreen, fontWeight: ui.FontWeight.bold);
    final cateringDiscountLabel = await sh('Catering Discount', 11, darkGreen, fontWeight: ui.FontWeight.bold);
    
    final savedExtraWidgets = await Future.wait(state.savedExtras.map((e) => sh(e.name, 11, darkGray, fontWeight: ui.FontWeight.bold)));

    final paymentHistoryWidgets = await Future.wait<pw.Widget>(
      state.paymentHistory.map(
            (p) => sh(
          '  ${DateFormat("dd/MM/yy").format(p.date)} - ${p.method}',
          9,
          darkGray,
          fontWeight: ui.FontWeight.bold,
        ),
      ),
    );

    final checklistTitleImg = await sh('ತರಬೇಕಾದ ವಸ್ತುಗಳು', 13, maroon, fontWeight: ui.FontWeight.bold);

    // Process checklist items from constants
    final checklistWidgets = await Future.wait(
      AppConstants.bookingChecklist.asMap().entries.map((entry) async {
        final index = entry.key + 1;
        final item = entry.value;
        final kanWidget = await sh('$index. ${item['kan']} ', 11, PdfColors.black, fontWeight: ui.FontWeight.bold);
        return pw.Row(
          children: [
            kanWidget,
            pw.Text('(${item['eng']})', style: pw.TextStyle(font: eFont, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        );
      }),
    );

    final termsTitleImg = await sh('ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು (Terms & Conditions):', 11, maroon, fontWeight: ui.FontWeight.bold);
    final term1Img = await sh('1. ಮುಂಗಡವಾಗಿ ಪಾವತಿಸಿದ ಹಣ ಯಾವುದೇ ಕಾರಣಕ್ಕೂ ಹಿಂತಿರುಗಿಸಲಾಗುವುದಿಲ್ಲ.', 10, darkGray, fontWeight: ui.FontWeight.bold);
    final term2Img = await sh('2. ನಿಗದಿತ ಸಮಯಕ್ಕೆ ಹಾಲ್ ಖಾಲಿ ಮಾಡಬೇಕು.', 10, darkGray, fontWeight: ui.FontWeight.bold);
    final footerImg = await sh(settings.businessName, 10, darkGray, maxWidth: 535, align: ui.TextAlign.center, fontWeight: ui.FontWeight.bold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        theme: pw.ThemeData.withFont(base: eFont, bold: eFont),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: pw.BoxDecoration(color: maroon),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (logoData.isNotEmpty) 
                    pw.Container(
                      width: 55, height: 55,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: gold, width: 1.5),
                        image: pw.DecorationImage(image: pw.MemoryImage(logoData), fit: pw.BoxFit.cover),
                      ),
                    )
                  else pw.SizedBox(width: 55),
                  pw.Column(
                    children: [
                      headerKImg,
                      bizNameImg,
                      bizAddrImg,
                      pw.Text('Ph: ${settings.businessPhone}', style: pw.TextStyle(color: ivory, fontSize: 9, font: eFont, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  if (deityData.isNotEmpty) 
                    pw.Container(
                      width: 55, height: 55,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: gold, width: 1.5),
                        image: pw.DecorationImage(image: pw.MemoryImage(logoData), fit: pw.BoxFit.cover),
                      ),
                    )
                  else pw.SizedBox(width: 55),
                ],
              ),
            ),
            // Sub-header Label
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              color: ivory,
              child: pw.Center(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    receiptLabelImg,
                    pw.Text('BOOKING RECEIPT', style: pw.TextStyle(fontSize: 10, color: maroon, font: eFont, fontWeight: pw.FontWeight.bold)),
                    if (state.editingBookingId?.isNotEmpty ?? false)
                      pw.Text(' · #${state.editingBookingId}', style: pw.TextStyle(fontSize: 10, color: maroon, font: eFont, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            
            // Customer Details
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFFFBF5), 
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: maroon, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        children: [
                          vadhuvVaraLabelImg,
                          pw.SizedBox(width: 4),
                          pw.Text('Chi. ', style: pw.TextStyle(font: eFont, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                          groomNameImg,
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                            child: pw.Text('&', style: pw.TextStyle(font: eFont, fontSize: 16, fontWeight: pw.FontWeight.bold, color: maroon)),
                          ),
                          pw.Text('Chi.Sau. ', style: pw.TextStyle(font: eFont, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                          brideNameImg,
                        ],
                      ),
                      pw.Text('Ph: ${state.contact1}${state.contact2.isNotEmpty ? ", ${state.contact2}" : ""}', 
                          style: pw.TextStyle(font: eFont, fontSize: 10, color: darkGray, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Divider(thickness: 1.0, color: maroon),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(children: [dinankaLabelImg, pw.SizedBox(width: 4), pw.Text(eventDateStr, style: pw.TextStyle(font: eFont, fontSize: 11, fontWeight: pw.FontWeight.bold))]),
                      pw.Row(children: [muhurthaLabelImg, pw.SizedBox(width: 4), pw.Text(eventTimeStr, style: pw.TextStyle(font: eFont, fontSize: 11, fontWeight: pw.FontWeight.bold))]),
                      pw.Row(children: [uruLabelImg, pw.SizedBox(width: 4), addressImg]),
                      pw.Row(children: [athithigaluLabelImg, pw.SizedBox(width: 4), pw.Text('${state.guestCount}', style: pw.TextStyle(font: eFont, fontSize: 11, fontWeight: pw.FontWeight.bold))]),
                    ],
                  ),
                ],
              ),
            ),

            // Hall Features
            if (hallFeatureWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              _buildShapedPillBox(
                titleWidget: hallFeaturesTitleImg,
                itemWidgets: hallFeatureWidgets,
                maroon: maroon,
                borderColor: darkGray,
              ),
            ],

            // Menu Items
            if (cateringItemWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              _buildShapedPillBox(
                titleWidget: menuTitleImg,
                itemWidgets: cateringItemWidgets,
                maroon: maroon,
                borderColor: darkGray,
              ),
            ],

            pw.SizedBox(height: 3),
            
            // Pricing Rows
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Individual Charges (Directly from doc)
                  if (state.hallCharge > 0)
                    _buildShapedPriceRow(hallRentalLabel, state.hallCharge, currencyFormatter, englishFont: eFont),

                  if (state.addPreviousDayHall && state.previousDayHallAmount > 0)
                    _buildShapedPriceRow(previousDayHallLabel, state.previousDayHallAmount, currencyFormatter, englishFont: eFont),

                  if (state.vadyaCharge > 0)
                    _buildShapedPriceRow(vadyaLabel, state.vadyaCharge, currencyFormatter, englishFont: eFont),

                  if (state.extraPurohitaru > 0)
                    _buildShapedPriceRow(extraPurohitaruLabel, state.extraPurohitaru, currencyFormatter, englishFont: eFont),

                  if (state.cateringTotal > 0)
                    _buildShapedPriceRow(cateringLabel, state.cateringTotal, currencyFormatter, englishFont: eFont),

                  if (state.addBeligeTindi && state.beligeTindiAmount > 0)
                    _buildShapedPriceRow(beligeTindiLabel, state.beligeTindiAmount, currencyFormatter, englishFont: eFont),

                  if (state.addSanjeTindi && state.sanjeTindiAmount > 0)
                    _buildShapedPriceRow(sanjeTindiLabel, state.sanjeTindiAmount, currencyFormatter, englishFont: eFont),

                  if (state.addRatriUta && state.ratriUtaAmount > 0)
                    _buildShapedPriceRow(ratriUtaLabel, state.ratriUtaAmount, currencyFormatter, englishFont: eFont),

                  if (state.drinkEnabled && state.drinkTotalAmount > 0)
                    _buildShapedPriceRow(drinkLabel, state.drinkTotalAmount, currencyFormatter, englishFont: eFont),

                  if (state.cleaningCharge > 0)
                    _buildShapedPriceRow(cleaningLabel, state.cleaningCharge, currencyFormatter, englishFont: eFont),

                  // Saved Extras (Every item in the savedExtras list)
                  for (var i = 0; i < state.savedExtras.length; i++)
                    if (state.savedExtras[i].amount != 0)
                      _buildShapedPriceRow(
                        savedExtraWidgets[i],
                        state.savedExtras[i].amount,
                        currencyFormatter,
                        englishFont: eFont,
                      ),

                  pw.Divider(thickness: 1.2, color: maroon),

                  // Subtotal
                  if (state.subtotal > 0)
                    _buildShapedPriceRow(
                      subtotalLabel,
                      state.subtotal,
                      currencyFormatter,
                      englishFont: eFont,
                    ),

                  // Discounts
                  if (state.hallDiscount > 0)
                    _buildShapedPriceRow(hallDiscountLabel, -state.hallDiscount, currencyFormatter, englishFont: eFont, isDiscount: true, discountColor: darkGreen),

                  if (state.cateringDiscount > 0)
                    _buildShapedPriceRow(cateringDiscountLabel, -state.cateringDiscount, currencyFormatter, englishFont: eFont, isDiscount: true, discountColor: darkGreen),

                  if (state.additionalGuestsCharge > 0)
                    _buildShapedPriceRow(addGuestsLabel, state.additionalGuestsCharge, currencyFormatter, englishFont: eFont),

                  pw.Divider(thickness: 1.2, color: maroon),
                  
                  // Total
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(children: [totalLabelImg, pw.Text(' (TOTAL AMOUNT)', style: pw.TextStyle(font: eFont, fontSize: 12, color: maroon, fontWeight: pw.FontWeight.bold))]),
                      pw.Text('₹${currencyFormatter.format(state.totalAmount.toInt())}', style: pw.TextStyle(fontSize: 16, font: eFont, color: maroon, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  
                  // Payment History
                  if (state.paymentHistory.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Row(children: [pw.Text('Payments:', style: pw.TextStyle(font: eFont, fontSize: 10, fontWeight: pw.FontWeight.bold))]),
                    for (var i = 0; i < state.paymentHistory.length; i++)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          paymentHistoryWidgets[i],
                          pw.Text('₹${currencyFormatter.format(state.paymentHistory[i].amount.toInt())}', style: pw.TextStyle(fontSize: 9, font: eFont, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                  ],

                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Advance Paid', style: pw.TextStyle(fontSize: 11, font: eFont, fontWeight: pw.FontWeight.bold)),
                      pw.Text('₹${currencyFormatter.format(state.advanceAmount.toInt())}', style: pw.TextStyle(fontSize: 11, font: eFont, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Balance Due
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(children: [balanceLabelImg, pw.Text(' (BALANCE DUE)', style: pw.TextStyle(font: eFont, fontSize: 12, color: maroon, fontWeight: pw.FontWeight.bold))]),
                      pw.Text('₹${currencyFormatter.format((state.totalAmount - state.advanceAmount).toInt())}', style: pw.TextStyle(fontSize: 16, color: maroon, font: eFont, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 3), 

            // Checklist Section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: maroon, width: 1.0), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  checklistTitleImg,
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 1), child: pw.Divider(thickness: 1.0, color: maroon)),
                  ...checklistWidgets.map((w) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 0.5),
                    child: w,
                  )),
                ],
              ),
            ),

            pw.SizedBox(height: 2), 
            
            // Terms & Conditions Footer
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: maroon, width: 1.0),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  termsTitleImg,
                  pw.SizedBox(height: 0.5),
                  term1Img,
                  pw.SizedBox(height: 0.5),
                  term2Img,
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 1), child: pw.Divider(thickness: 1.0, color: maroon)),
                  pw.Center(child: footerImg),
                ],
              ),
            ),
            
            pw.SizedBox(height: 10), 
            
            // Signatures
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1.5)))),
                      pw.SizedBox(height: 3),
                      pw.Text('Customer Signature', style: pw.TextStyle(fontSize: 10, font: eFont, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1.5)))),
                      pw.SizedBox(height: 3),
                      pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 10, font: eFont, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildShapedPriceRow(pw.Widget labelWidget, double amount, NumberFormat formatter, {required pw.Font englishFont, double fontSize = 11, bool isDiscount = false, PdfColor? discountColor}) {
    if (amount == 0 && !isDiscount) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          labelWidget,
          pw.Text('${amount < 0 ? "-" : ""}₹${formatter.format(amount.abs().toInt())}', 
            style: pw.TextStyle(font: englishFont, fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: isDiscount ? (discountColor ?? PdfColors.green) : null)),
        ],
      ),
    );
  }

  static pw.Widget _buildShapedPillBox({
    required pw.Widget titleWidget, 
    required List<pw.Widget> itemWidgets, 
    required PdfColor maroon, 
    required PdfColor borderColor,
    Set<int> highlightedIndices = const {},
    PdfColor? highlightColor,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: maroon, width: 1.0), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          titleWidget,
          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 1.5), child: pw.Divider(thickness: 1.0, color: maroon)),
          pw.Wrap(
            spacing: 4,
            runSpacing: 3,
            children: List.generate(itemWidgets.length, (i) {
              final isHighlighted = highlightedIndices.contains(i);
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: isHighlighted ? const PdfColor.fromInt(0xFFFFF9E6) : const PdfColor.fromInt(0xFFEEEEEE), 
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(
                    color: isHighlighted ? (highlightColor ?? maroon) : maroon, 
                    width: 1.0,
                  ),
                ),
                child: itemWidgets[i],
              );
            }),
          ),
        ],
      ),
    );
  }
}
