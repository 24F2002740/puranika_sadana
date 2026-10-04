import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:puranika_sadana/features/dashboard/domain/models/booking.dart';
import 'package:puranika_sadana/features/dashboard/presentation/providers/bookings_provider.dart';
import 'package:puranika_sadana/services/certificate_service.dart';
import 'package:puranika_sadana/core/services/settings_service.dart';
import 'package:puranika_sadana/features/dashboard/data/repositories/booking_repository_provider.dart';
import 'package:share_plus/share_plus.dart';

class MarriageCertificateScreen extends ConsumerStatefulWidget {
  final Booking booking;
  const MarriageCertificateScreen({super.key, required this.booking});

  @override
  ConsumerState<MarriageCertificateScreen> createState() => _MarriageCertificateScreenState();
}

class _MarriageCertificateScreenState extends ConsumerState<MarriageCertificateScreen> {
  final _settings = SettingsService();
  final _collectedByController = TextEditingController();

  @override
  void dispose() {
    _collectedByController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _fetchFileFromFirestore(String bookingId, String fieldName) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('certificate_files').doc(bookingId).get();
      if (doc.exists) {
        final base64String = doc.data()?[fieldName] as String?;
        if (base64String != null) {
          return base64Decode(base64String);
        }
      }
    } catch (e) {
      debugPrint("Error fetching file from Firestore: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    
    return bookingsAsync.when(
      data: (bookings) {
        final booking = bookings.firstWhere(
          (b) => b.id == widget.booking.id,
          orElse: () => widget.booking,
        );
        
        final certificateIssued = booking.certificateIssued;
        final certificateReissued = booking.certificateReissued;

        if (certificateIssued && _collectedByController.text.isEmpty) {
          _collectedByController.text = booking.collectedByMobile ?? '';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFBF7EE),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4A1B0C),
            title: Text(certificateIssued ? "View Certificate" : "Preview Certificate", style: const TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AspectRatio(
                    aspectRatio: 1 / 1.414, 
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: _collectedByController,
                        builder: (context, value, _) {
                          return _CertificateLayout(
                            booking: booking, 
                            isDuplicate: certificateReissued,
                            collectedByMobile: _collectedByController.text,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (!certificateIssued)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _collectedByController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Collected by — Mobile Number",
                            hintText: "Enter contact of person collecting certificate",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _issueCertificate(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A1B0C),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("ISSUE & EXPORT PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _printNow(booking),
                                icon: const Icon(Icons.print),
                                label: const Text("Print Now"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A1B0C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _sendWhatsApp(booking),
                                icon: const Icon(Icons.send),
                                label: const Text("WhatsApp"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _sharePdf(booking),
                          icon: const Icon(Icons.share),
                          label: const Text("Share PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!certificateReissued)
                          TextButton.icon(
                            onPressed: () => _showReissueDialog(context, booking),
                            icon: const Icon(Icons.history_edu, color: Color(0xFF4A1B0C)),
                            label: const Text("Request Reissue (Duplicate Copy)", 
                              style: TextStyle(color: Color(0xFF4A1B0C), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              "Certificate reissued on ${DateFormat('dd-MM-yyyy').format(booking.reissueDate!)} — no further reissues permitted",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Done — I'll do this later", style: TextStyle(color: Color(0xFF4A1B0C), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Future<void> _issueCertificate(Booking booking) async {
    final mobile = _collectedByController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Collected by Mobile Number")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFBA7517))),
    );

    try {
      final updatedBookingForPdf = booking.copyWith(collectedByMobile: mobile);
      final service = CertificateService();
      final pdfBytes = await service.generateCertificateBytes(updatedBookingForPdf);
      final pdfBase64 = base64Encode(pdfBytes);

      // Save heavy data to separate collection
      final docRef = FirebaseFirestore.instance.collection('certificate_files').doc(booking.id);
      
      // Size Safety Check
      final docSnap = await docRef.get();
      int existingSize = 0;
      if (docSnap.exists) {
        existingSize = (docSnap.data()!['invitationPhotoBase64'] as String?)?.length ?? 0;
      }

      if (existingSize + pdfBase64.length > 900 * 1024) {
         if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Total certificate data exceeds limit. Try issuing with a smaller invitation photo."))
           );
         }
         return;
      }

      await docRef.set({
        'certificatePdfBase64': pdfBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      final now = DateTime.now();
      final updatedBooking = booking.copyWith(
        certificateIssued: true,
        certificateIssuedAt: now,
        certificatePdfPath: "FIRESTORE_BASE64", // Marker indicating cloud storage
        collectedByMobile: mobile,
        logs: [...booking.logs, "Certificate issued on ${DateFormat('dd-MM-yyyy HH:mm').format(now)}. Collected by: $mobile"],
      );
      
      final repository = ref.read(bookingRepositoryProvider);
      await repository.updateBooking(updatedBooking);

      if (mounted) {
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _printNow(Booking booking) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFBA7517))),
    );

    try {
      final pdfBytes = await _fetchFileFromFirestore(booking.id, 'certificatePdfBase64');
      if (mounted) Navigator.pop(context);

      if (pdfBytes != null) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load certificate from cloud.")));
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _sendWhatsApp(Booking booking) async {
    _sharePdf(booking, text: "Marriage Certificate via WhatsApp");
  }

  Future<void> _sharePdf(Booking booking, {String? text}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFBA7517))),
    );

    try {
      final pdfBytes = await _fetchFileFromFirestore(booking.id, 'certificatePdfBase64');
      if (mounted) Navigator.pop(context);

      if (pdfBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File("${tempDir.path}/Marriage_Certificate_${booking.id}.pdf");
        await file.writeAsBytes(pdfBytes);
        
        await Share.shareXFiles([XFile(file.path)], text: text ?? 'Marriage Certificate for ${booking.brideName} & ${booking.groomName}');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load certificate from cloud.")));
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  void _showReissueDialog(BuildContext context, Booking booking) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Authorize Reissue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("This action requires the OWNER PIN. Only one duplicate copy can be issued per booking."),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Owner PIN (4-6 digits)", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text == _settings.ownerPin) {
                Navigator.pop(context);
                _showReasonDialog(context, booking);
              } else {
                final logMsg = "Failed reissue attempt: Incorrect PIN entered on ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}";
                final repository = ref.read(bookingRepositoryProvider);
                await repository.updateBooking(booking.copyWith(
                  logs: [...booking.logs, logMsg],
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text("Incorrect OWNER PIN. Access Denied."),
                  ));
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A1B0C), foregroundColor: Colors.white),
            child: const Text("AUTHORIZE"),
          ),
        ],
      ),
    );
  }

  void _showReasonDialog(BuildContext context, Booking booking) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reason for Reissue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please specify why a duplicate copy is being requested."),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "e.g. Original lost, Printing error...", 
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a reason")));
                return;
              }
              Navigator.pop(context);
              _processReissue(booking, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A1B0C), foregroundColor: Colors.white),
            child: const Text("CONFIRM REISSUE"),
          ),
        ],
      ),
    );
  }

  Future<void> _processReissue(Booking booking, String reason) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFBA7517))),
    );

    try {
      final service = CertificateService();
      final now = DateTime.now();
      
      final updatedBooking = booking.copyWith(
        certificateReissued: true,
        reissueReason: reason,
        reissueDate: now,
        logs: [
          ...booking.logs, 
          "Duplicate Certificate reissued on ${DateFormat('dd-MM-yyyy HH:mm').format(now)}. Reason: $reason. Authorized by Owner PIN."
        ],
      );
      
      final pdfBytes = await service.generateCertificateBytes(updatedBooking, isDuplicate: true);
      final pdfBase64 = base64Encode(pdfBytes);

      final docRef = FirebaseFirestore.instance.collection('certificate_files').doc(booking.id);
      
      // Size Safety Check
      final docSnap = await docRef.get();
      int existingSize = 0;
      if (docSnap.exists) {
        existingSize = (docSnap.data()!['invitationPhotoBase64'] as String?)?.length ?? 0;
      }

      if (existingSize + pdfBase64.length > 900 * 1024) {
         if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Total certificate data exceeds limit."))
           );
         }
         return;
      }

      await docRef.set({
        'certificatePdfBase64': pdfBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final finalBooking = updatedBooking.copyWith(certificatePdfPath: "FIRESTORE_BASE64");
      
      final repository = ref.read(bookingRepositoryProvider);
      await repository.updateBooking(finalBooking);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Duplicate certificate issued successfully")));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}

class _CertificateLayout extends StatelessWidget {
  final Booking booking;
  final bool isDuplicate;
  final String? collectedByMobile;
  const _CertificateLayout({required this.booking, this.isDuplicate = false, this.collectedByMobile});

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF4A1B0C);
    const gold = Color(0xFFBA7517);
    const cream = Color(0xFFFFFCF6);

    return Container(
      decoration: BoxDecoration(
        color: cream,
        border: Border.all(color: gold, width: 1.5),
      ),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/images/logo.png', width: 280),
            ),
          ),
          // Full Decorative Border
          Positioned(top: 0, left: 0, right: 0, child: _buildHorizontalStripedBorder(maroon, cream)),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildHorizontalStripedBorder(maroon, cream)),
          Positioned(top: 0, bottom: 0, left: 0, child: _buildVerticalStripedBorder(maroon, cream)),
          Positioned(top: 0, bottom: 0, right: 0, child: _buildVerticalStripedBorder(maroon, cream)),

          if (isDuplicate)
            Center(
              child: Transform.rotate(
                angle: -0.5,
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade900, width: 4),
                    ),
                    child: Text(
                      "DUPLICATE COPY",
                      style: TextStyle(
                        color: Colors.red.shade900, 
                        fontSize: 40, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 25),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDuplicate)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: maroon)),
                          child: const Text("DUPLICATE COPY", style: TextStyle(color: maroon, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Image.asset('assets/images/mookambika.png', width: 75, height: 90),
                    const SizedBox(height: 4),
                    const Text("|| Sri Mookambika ||", style: TextStyle(color: maroon, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("SRI PURANIK SADANA", style: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: maroon, fontSize: 30)),
                    const Text("Car Street, Sri Kshetra Kollur - 576220, Udupi Dist.", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("Certificate issued: ${booking.certificateIssuedAt != null ? DateFormat('dd-MM-yyyy').format(booking.certificateIssuedAt!) : DateFormat('dd-MM-yyyy').format(DateTime.now())}", style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(height: 15),
                    const Text("This is to certify that", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 18)),
                    const SizedBox(height: 20),
                    
                    _buildPersonInfo("Chi. ${booking.groomName}", "S/o ${booking.groomFatherName ?? ''}", "DOB: ${booking.groomDob ?? ''}", booking.groomAddress ?? ''),
                    const SizedBox(height: 18),
                    _buildPersonInfo("Chi. Sou. ${booking.brideName}", "D/o ${booking.brideFatherName ?? ''}", "DOB: ${booking.brideDob ?? ''}", booking.brideAddress ?? ''),
                    
                    const SizedBox(height: 25),
                    const Text("are married at Sri Puranik Sadana, Kollur", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
                    Text("on ${DateFormat('dd-MM-yyyy').format(booking.eventDate)} ${booking.startTime?.format(context) ?? ''}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text("according to Hindu Religion Marriage Systems", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
                    
                    const SizedBox(height: 60),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSignatureLine("Party Signature"),
                        _buildSignatureLine("Authorised Signature"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Collected by — Mob: ${collectedByMobile ?? ''}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.5, color: Colors.grey),
                    const SizedBox(height: 6),
                    Text("Certificate ID #WB-${booking.eventDate.year}-${booking.id.split('-').last}", 
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    if (isDuplicate && booking.reissueDate != null)
                       Padding(
                         padding: const EdgeInsets.only(top: 2),
                         child: Text("Duplicate Reissued on: ${DateFormat('dd-MM-yyyy HH:mm').format(booking.reissueDate!)}", 
                          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                       ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStripedBorder(Color maroon, Color cream) {
    return SizedBox(
      height: 10,
      width: double.infinity,
      child: Row(
        children: List.generate(40, (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? maroon : cream,
          ),
        )),
      ),
    );
  }

  Widget _buildVerticalStripedBorder(Color maroon, Color cream) {
    return SizedBox(
      width: 10,
      height: double.infinity,
      child: Column(
        children: List.generate(60, (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? maroon : cream,
          ),
        )),
      ),
    );
  }

  Widget _buildPersonInfo(String name, String parent, String dob, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: DottedLinePainter(),
        ),
        const SizedBox(height: 8),
        Text(parent, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(dob, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              const TextSpan(text: "Address: ", style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: address),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureLine(String label) {
    return Column(
      children: [
        Container(width: 120, height: 1.5, color: Colors.black),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    var max = size.width;
    var dashWidth = 2;
    var dashSpace = 2;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
