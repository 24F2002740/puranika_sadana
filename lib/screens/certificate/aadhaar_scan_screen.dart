import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:go_router/go_router.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../features/dashboard/domain/models/booking.dart';
import '../../features/dashboard/data/repositories/booking_repository_provider.dart';
import 'marriage_certificate_screen.dart';
import '../../core/constants/app_colors.dart';

class AadhaarScanScreen extends ConsumerStatefulWidget {
  final Booking booking;
  const AadhaarScanScreen({super.key, required this.booking});

  @override
  ConsumerState<AadhaarScanScreen> createState() => _AadhaarScanScreenState();
}

class _AadhaarScanScreenState extends ConsumerState<AadhaarScanScreen> {
  final _picker = ImagePicker();
  late TextRecognizer _textRecognizer;
  
  bool _isProcessing = false;
  String _rawOcrText = "";
  String? _ocrErrorText;
  bool? _lastScanWasGroom;

  // Encryption setup
  static const _rawKey = String.fromEnvironment('AADHAAR_ENCRYPTION_KEY');
  final _encryptionKey = encrypt.Key.fromUtf8(_rawKey.isEmpty ? 'placeholder_key_32_chars_12345678' : _rawKey);
  final _iv = encrypt.IV.fromLength(16);

  // Form Controllers
  late TextEditingController _gName, _gDob, _gGender, _gFather, _gAddress, _gAadhaar;
  late TextEditingController _bName, _bDob, _bGender, _bFather, _bAddress, _bAadhaar;

  String? _invitationPath;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    _gName = TextEditingController(text: widget.booking.groomName);
    _gDob = TextEditingController(text: widget.booking.groomDob);
    _gGender = TextEditingController(text: widget.booking.groomGender);
    _gFather = TextEditingController(text: widget.booking.groomFatherName);
    _gAddress = TextEditingController(text: widget.booking.groomAddress);
    _gAadhaar = TextEditingController(text: _decryptAadhaar(widget.booking.groomAadhaar));

    _bName = TextEditingController(text: widget.booking.brideName);
    _bDob = TextEditingController(text: widget.booking.brideDob);
    _bGender = TextEditingController(text: widget.booking.brideGender);
    _bFather = TextEditingController(text: widget.booking.brideFatherName);
    _bAddress = TextEditingController(text: widget.booking.brideAddress);
    _bAadhaar = TextEditingController(text: _decryptAadhaar(widget.booking.brideAadhaar));

    _invitationPath = widget.booking.invitationPhotoPath;
  }

  String _decryptAadhaar(String? encrypted) {
    if (encrypted == null || encrypted.isEmpty) return "";
    if (_rawKey.isEmpty) return "[Key Missing]";
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      return encrypter.decrypt64(encrypted, iv: _iv);
    } catch (e) {
      return "";
    }
  }

  String _encryptAadhaar(String plain) {
    if (plain.isEmpty || _rawKey.isEmpty) return "";
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    return encrypter.encrypt(plain, iv: _iv).base64;
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _gName.dispose(); _gDob.dispose(); _gGender.dispose(); _gFather.dispose(); _gAddress.dispose(); _gAadhaar.dispose();
    _bName.dispose(); _bDob.dispose(); _bGender.dispose(); _bFather.dispose(); _bAddress.dispose(); _bAadhaar.dispose();
    super.dispose();
  }

  Future<void> _scanAadhaar(bool isGroom) async {
    if (isGroom) {
      _gName.clear(); _gDob.clear(); _gGender.clear();
      _gFather.clear(); _gAddress.clear(); _gAadhaar.clear();
    } else {
      _bName.clear(); _bDob.clear(); _bGender.clear();
      _bFather.clear(); _bAddress.clear(); _bAadhaar.clear();
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _isProcessing = true;
      _ocrErrorText = null;
      _rawOcrText = "";
      _lastScanWasGroom = isGroom;
    });

    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      setState(() {
        _rawOcrText = recognizedText.text;
      });

      _parseAndFill(recognizedText.text, isGroom);

      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      setState(() {
        _ocrErrorText = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _parseAndFill(String text, bool isGroom) {
    final nameCtrl = isGroom ? _gName : _bName;
    final dobCtrl = isGroom ? _gDob : _bDob;
    final genderCtrl = isGroom ? _gGender : _bGender;
    final fatherCtrl = isGroom ? _gFather : _bFather;
    final addressCtrl = isGroom ? _gAddress : _bAddress;
    final aadhaarCtrl = isGroom ? _gAadhaar : _bAadhaar;

    nameCtrl.clear();
    dobCtrl.clear();
    genderCtrl.clear();
    fatherCtrl.clear();
    addressCtrl.clear();
    aadhaarCtrl.clear();

    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    void setField(TextEditingController ctrl, String label, String value) {
      debugPrint("OCR Auto-fill [$label]: Writing '$value'");
      ctrl.text = value;
    }

    bool containsHeaderKeywords(String line) {
      final l = line.toLowerCase();
      return l.contains('government') || 
             l.contains('india') || 
             l.contains('authority') || 
             l.contains('unique') || 
             l.contains('identification');
    }

    bool isAnchorLine(String line) {
      final l = line.toLowerCase();
      return l == 'to' || l.contains('government of india');
    }

    bool isHeaderLine(String line) {
      final l = line.toLowerCase();
      return l == 'to' || 
             l.contains('government of india') || 
             l.contains('unique identification authority');
    }

    String? foundName;
    int nameLineIdx = -1;

    bool isValidName(String candidate) {
      if (candidate.length <= 3) return false;
      if (!RegExp(r'[aeiouAEIOU]').hasMatch(candidate)) return false;
      if (RegExp(r'\d|[:/]').hasMatch(candidate)) return false;
      if (containsHeaderKeywords(candidate)) return false;
      if (RegExp(r'^Aadhaa+r?$', caseSensitive: false).hasMatch(candidate)) return false;
      if (candidate.contains(RegExp(r'VTC|District|State|PIN Code|Post|Taluk|Address|DOB|Gender', caseSensitive: false))) return false;
      return true;
    }

    for (int i = 0; i < lines.length; i++) {
      if (isAnchorLine(lines[i])) {
        int nextIdx = i + 1;
        while (nextIdx < lines.length && (isHeaderLine(lines[nextIdx]) || containsHeaderKeywords(lines[nextIdx]))) {
          nextIdx++;
        }
        if (nextIdx < lines.length) {
          final candidate = lines[nextIdx];
          if (isValidName(candidate)) {
            foundName = candidate;
            nameLineIdx = nextIdx;
            break;
          }
        }
      }
    }

    if (foundName == null) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!RegExp(r'\d').hasMatch(line) && isValidName(line)) {
          foundName = line;
          nameLineIdx = i;
          break;
        }
      }
    }
    
    if (foundName != null) {
      setField(nameCtrl, "Name", foundName);
    }

    final dobPattern = r'\d{2}\s*[/\-.]\s*\d{2}\s*[/\-.]\s*\d{4}';
    String? selectedDob;

    bool isNearIssued(String val) {
      int pos = text.indexOf(val);
      if (pos == -1) return false;
      int start = pos > 20 ? pos - 20 : 0;
      int end = pos + val.length + 20 < text.length ? pos + val.length + 20 : text.length;
      return text.substring(start, end).toLowerCase().contains('issued');
    }

    final dobRegex = RegExp('(?:DOB|DoB|Date\\s*of\\s*Birth)\\s*[:/]?\\s*($dobPattern)', caseSensitive: false);
    final dobMatch = dobRegex.firstMatch(text);
    if (dobMatch != null) {
      final val = dobMatch.group(1)!;
      if (!isNearIssued(val)) {
        selectedDob = val.replaceAll(RegExp(r'\s'), '');
      }
    }

    if (selectedDob == null) {
      final yobRegex = RegExp(r'(?:Year\s*of\s*Birth|YOB)[:\s]*(\d{4})', caseSensitive: false);
      final yobMatch = yobRegex.firstMatch(text);
      if (yobMatch != null) {
        final val = yobMatch.group(1)!;
        if (!isNearIssued(val)) {
          selectedDob = val;
        }
      }
    }
    
    if (selectedDob != null) {
      setField(dobCtrl, "DOB", selectedDob);
    }

    final genderRegex = RegExp(r'female|male|ಸ್ತ್ರೀ|ಪುರುಷ', caseSensitive: false);
    String? gender;
    if (nameLineIdx != -1) {
      final afterName = lines.sublist(nameLineIdx + 1).join('\n');
      gender = genderRegex.firstMatch(afterName)?.group(0);
    }
    gender ??= genderRegex.firstMatch(text)?.group(0);

    if (gender != null) {
      final gVal = gender.toLowerCase();
      if (gVal.contains('female') || gVal.contains('ಸ್ತ್ರೀ')) {
        setField(genderCtrl, "Gender", "Female");
      } else {
        setField(genderCtrl, "Gender", "Male");
      }
    }

    Match? relMatch;
    final sRegex = RegExp(r'\b([SDWC])[/I1]?[O0]\b[:\s\-]*\s*([^\n,]+)', caseSensitive: false);
    relMatch = sRegex.firstMatch(text);
    if (relMatch != null) {
      setField(fatherCtrl, "Father", relMatch.group(2)!.trim());
    } else {
      final lRegex = RegExp(r'\b(?:Father|Mother|Guardian)\b\s*[:\-]?\s*([^\n,]+)', caseSensitive: false);
      relMatch = lRegex.firstMatch(text);
      if (relMatch != null) {
        setField(fatherCtrl, "Father", relMatch.group(1)!.trim());
      }
    }

    final aadhaarRegex = RegExp(r'\d{4}\s*\d{4}\s*\d{4}');
    final aadhaarMatches = aadhaarRegex.allMatches(text);
    String? finalAadhaar;
    final occurrences = <String, int>{};

    for (final m in aadhaarMatches) {
      final val = m.group(0)!.replaceAll(RegExp(r'\s'), '');
      final prefix = text.substring(m.start > 30 ? m.start - 30 : 0, m.start).toLowerCase();
      if (prefix.contains('enrol') || prefix.contains('enroll') || prefix.contains('vid')) continue;
      
      occurrences[val] = (occurrences[val] ?? 0) + 1;
      if (prefix.contains(RegExp(r'aadhaar\s*no'))) finalAadhaar = val;
    }
    
    if (finalAadhaar == null && occurrences.isNotEmpty) {
      int max = 0;
      String? mostFreq;
      occurrences.forEach((v, c) {
        if (c > max) { max = c; mostFreq = v; }
      });
      finalAadhaar = mostFreq;
    }
    if (finalAadhaar != null) setField(aadhaarCtrl, "Aadhaar", finalAadhaar);

    final pincodeRegex = RegExp(r'(?<!\d)\d{6}(?!\d)');
    String? address;

    final addrLabel = RegExp(r'(Address|ವಿಳಾಸ)', caseSensitive: false).firstMatch(text);
    if (addrLabel != null) {
      final after = text.substring(addrLabel.end);
      final pin = pincodeRegex.firstMatch(after);
      if (pin != null) address = after.substring(0, pin.end).replaceAll('\n', ' ').trim();
    }

    if ((address == null || address.isEmpty) && relMatch != null) {
      final after = text.substring(relMatch.end);
      final pin = pincodeRegex.firstMatch(after);
      if (pin != null) address = after.substring(0, pin.end).replaceAll('\n', ' ').trim();
    }

    if ((address == null || address.isEmpty) && nameLineIdx != -1) {
      List<String> addressParts = [];
      for (int i = nameLineIdx + 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains(RegExp(r'Mobile:|Government of India|Unique Identification', caseSensitive: false))) break;
        final pinMatch = pincodeRegex.firstMatch(line);
        if (pinMatch != null) {
          addressParts.add(line.substring(0, pinMatch.end));
          break;
        }
        addressParts.add(line);
      }
      if (addressParts.isNotEmpty) address = addressParts.join(', ');
    }

    if (address != null) {
      setField(addressCtrl, "Address", address);
    }
    
    setState(() {});
  }

  Future<void> _onGenerate() async {
    setState(() {
      _isProcessing = true;
    });

    String? invitationBase64;
    
    // Step 3: Compress and Encode Invitation Photo to Base64
    if (_invitationPath != null && _invitationPath != "FIRESTORE_BASE64") {
      try {
        if (File(_invitationPath!).existsSync()) {
          final compressedFile = await FlutterImageCompress.compressWithFile(
            _invitationPath!,
            minWidth: 800,
            minHeight: 800,
            quality: 70,
          );

          if (compressedFile != null) {
            // Firestore limit is 1MB. Base64 is ~1.33x overhead. 
            // 900KB string limit means ~675KB of raw bytes.
            if (compressedFile.length > 650 * 1024) {
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Invitation photo too large — please retake or use a smaller image"))
                 );
               }
               setState(() => _isProcessing = false);
               return;
            }
            invitationBase64 = base64Encode(compressedFile);
          }
        }
      } catch (e) {
        debugPrint("Error compressing invitation: $e");
      }
    }

    final updatedBooking = widget.booking.copyWith(
      groomName: _gName.text,
      groomDob: _gDob.text,
      groomGender: _gGender.text,
      groomFatherName: _gFather.text,
      groomAddress: _gAddress.text,
      groomAadhaar: _encryptAadhaar(_gAadhaar.text),
      groomVerified: true,
      brideName: _bName.text,
      brideDob: _bDob.text,
      brideGender: _bGender.text,
      brideFatherName: _bFather.text,
      brideAddress: _bAddress.text,
      brideAadhaar: _encryptAadhaar(_bAadhaar.text),
      brideVerified: true,
      invitationPhotoPath: "FIRESTORE_BASE64", // Marker indicating data is in certificate_files collection
    );

    try {
      final repository = ref.read(bookingRepositoryProvider);
      
      // Save heavy data to separate collection
      if (invitationBase64 != null) {
        final docRef = FirebaseFirestore.instance.collection('certificate_files').doc(widget.booking.id);
        
        // Check current doc size if it exists to ensure total doesn't exceed limit
        final docSnap = await docRef.get();
        int existingSize = 0;
        if (docSnap.exists) {
          final data = docSnap.data()!;
          existingSize = (data['certificatePdfBase64'] as String?)?.length ?? 0;
        }

        if (existingSize + invitationBase64.length > 900 * 1024) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Total certificate data exceeds limit. Try a smaller photo."))
             );
           }
           setState(() => _isProcessing = false);
           return;
        }

        await docRef.set({
          'invitationPhotoBase64': invitationBase64,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await repository.updateBooking(updatedBooking);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) => MarriageCertificateScreen(booking: updatedBooking)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating booking: $e")));
      }
    }
  }

  bool _isGenerateEnabled() {
    if (_rawKey.isEmpty) return false;
    return _gName.text.isNotEmpty && _gDob.text.isNotEmpty && _gAadhaar.text.length == 12 &&
           _bName.text.isNotEmpty && _bDob.text.isNotEmpty && _bAadhaar.text.length == 12 &&
           _invitationPath != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A1B0C),
        elevation: 0,
        title: const Text("Verify Details", style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_rawKey.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Encryption Key Missing. App cannot process Aadhaar data. Please rebuild with AADHAAR_ENCRYPTION_KEY defined.",
                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildSection("Groom's Details", true),
                const SizedBox(height: 16),
                _buildSection("Bride's Details", false),
                const SizedBox(height: 16),
                _buildInvitationSection(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isGenerateEnabled() ? _onGenerate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A1B0C),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("GENERATE CERTIFICATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, bool isGroom) {
    final nameCtrl = isGroom ? _gName : _bName;
    final dobCtrl = isGroom ? _gDob : _bDob;
    final genderCtrl = isGroom ? _gGender : _bGender;
    final fatherCtrl = isGroom ? _gFather : _bFather;
    final addressCtrl = isGroom ? _gAddress : _bAddress;
    final aadhaarCtrl = isGroom ? _gAadhaar : _bAadhaar;

    return Column(
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE7DCC4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4A1B0C)))),
                    ElevatedButton.icon(
                      onPressed: _rawKey.isNotEmpty ? () => _scanAadhaar(isGroom) : null,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text("SCAN CARD"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA7517),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _buildField("Official Name", nameCtrl),
                _buildField("Father/Guardian", fatherCtrl),
                Row(
                  children: [
                    Expanded(child: _buildField("DOB", dobCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField("Gender", genderCtrl)),
                  ],
                ),
                _buildField("Address", addressCtrl, maxLines: 2),
                _buildField("Aadhaar Number (12 digits)", aadhaarCtrl, isAadhaar: true),
              ],
            ),
          ),
        ),
        if (_lastScanWasGroom == isGroom) _buildDebugInfo(),
      ],
    );
  }

  Widget _buildDebugInfo() {
    if (_ocrErrorText != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text("Error: $_ocrErrorText", style: const TextStyle(color: Colors.red, fontSize: 12)),
      );
    }
    
    if (_lastScanWasGroom != null) {
      if (_rawOcrText.isEmpty && !_isProcessing) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text("No text detected in photo — try better lighting or hold camera closer", 
            style: TextStyle(color: Colors.orange, fontSize: 12)),
        );
      }

      if (_rawOcrText.isNotEmpty) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Detected ${_rawOcrText.length} characters", style: const TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 4),
              Text(_rawOcrText, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.black87)),
            ],
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, bool isAadhaar = false}) {
    bool isInvalidAadhaar = isAadhaar && controller.text.length != 12 && controller.text.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isAadhaar ? TextInputType.number : TextInputType.text,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          suffixIcon: const Icon(Icons.edit, size: 16, color: Color(0xFFBA7517)),
          helperText: isInvalidAadhaar ? "Must be 12 digits" : null,
          helperStyle: const TextStyle(color: AppColors.error, fontSize: 10),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE7DCC4))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBA7517))),
        ),
      ),
    );
  }

  Widget _buildInvitationSection() {
    final isCloud = _invitationPath == "FIRESTORE_BASE64";
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE7DCC4))),
      child: ListTile(
        onTap: () async {
          if (isCloud) {
            _showCloudInvitationDialog();
            return;
          }
          final img = await _picker.pickImage(source: ImageSource.gallery);
          if (img != null) setState(() => _invitationPath = img.path);
        },
        leading: Icon(Icons.insert_photo, color: _invitationPath != null ? Colors.green : const Color(0xFFBA7517)),
        title: const Text("Wedding Invitation Photo", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(_invitationPath == null ? "Required" : (isCloud ? "Saved in Cloud" : "Attached")),
        trailing: isCloud ? const Icon(Icons.cloud_done, color: Colors.blue) : const Icon(Icons.chevron_right),
      ),
    );
  }

  void _showCloudInvitationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFBA7517))),
    );
    
    try {
      final doc = await FirebaseFirestore.instance.collection('certificate_files').doc(widget.booking.id).get();
      if (mounted) Navigator.pop(context);
      
      if (doc.exists) {
        final base64String = doc.data()?['invitationPhotoBase64'] as String?;
        if (base64String != null) {
          final bytes = base64Decode(base64String);
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickNewInvitation();
                          },
                          child: const Text("REPLACE"),
                        ),
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading photo: $e")));
      }
    }
  }

  void _pickNewInvitation() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _invitationPath = img.path);
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFBA7517)),
                SizedBox(height: 16),
                Text("Analyzing Aadhaar card...", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Processing data", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
