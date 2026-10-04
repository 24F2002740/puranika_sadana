import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _settings = SettingsService();
  final _pricing = PricingService();
  final _picker = ImagePicker();

  bool _isPageLoading = true;
  bool _isSaving = false;

  // Controllers for various sections
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _businessEmailController;

  late TextEditingController _tier1Controller;
  late TextEditingController _tier2Controller;
  late TextEditingController _tier3Controller;

  late TextEditingController _upiIdController;
  late TextEditingController _receiptFooterController;
  late TextEditingController _termsController;
  late TextEditingController _ownerPinController;

  late TextEditingController _firstReminderController;
  late TextEditingController _finalReminderController;

  bool _dailyBalanceReminders = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (!_settings.isInitialized) {
      await _settings.init();
    }
    
    if (mounted) {
      setState(() {
        _businessNameController = TextEditingController(text: _settings.businessName);
        _businessAddressController = TextEditingController(text: _settings.businessAddress);
        _businessPhoneController = TextEditingController(text: _settings.businessPhone);
        _businessEmailController = TextEditingController(text: _settings.businessEmail);

        _tier1Controller = TextEditingController(text: _settings.cateringTier1Rate.toStringAsFixed(0));
        _tier2Controller = TextEditingController(text: _settings.cateringTier2Rate.toStringAsFixed(0));
        _tier3Controller = TextEditingController(text: _settings.cateringTier3Rate.toStringAsFixed(0));

        _upiIdController = TextEditingController(text: _settings.upiId);
        _receiptFooterController = TextEditingController(text: _settings.receiptFooter);
        _termsController = TextEditingController(text: _settings.termsAndConditions);
        _ownerPinController = TextEditingController(text: _settings.ownerPin);

        _firstReminderController = TextEditingController(text: _settings.firstReminderDays.toString());
        _finalReminderController = TextEditingController(text: _settings.finalReminderDays.toString());
        
        _dailyBalanceReminders = _settings.dailyBalanceReminders;
        _pushNotifications = _settings.pushNotificationsEnabled;
        _isPageLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _tier1Controller.dispose();
    _tier2Controller.dispose();
    _tier3Controller.dispose();
    _upiIdController.dispose();
    _receiptFooterController.dispose();
    _termsController.dispose();
    _ownerPinController.dispose();
    _firstReminderController.dispose();
    _finalReminderController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    if (_isSaving) return;
    
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _isSaving = true);
      try {
        final String destination = isLogo ? 'settings/logo.png' : 'settings/upi_qr.png';
        final String downloadUrl = await _settings.uploadImage(File(image.path), destination);
        
        if (isLogo) {
          await _settings.saveLogo(downloadUrl);
        } else {
          await _settings.saveUpiInfo(_upiIdController.text, downloadUrl);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isLogo ? "Logo" : "QR Code"} updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Log out of Puranika Sadana?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSection(Future<void> Function() saveFn) async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    try {
      await saveFn();
      _showSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPageLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBF7EE),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3D1608))),
      );
    }

    final currentLocale = ref.watch(localeProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF7EE),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3D1608),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isSaving ? null : () => _goBack(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_settings.businessName,
                   style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
            ],
          ),
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Language Selector
              _buildSectionTitle('App Settings'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7DCC4)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFFB5651D)),
                  title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: DropdownButton<String>(
                    value: currentLocale.languageCode,
                    underline: const SizedBox(),
                    onChanged: _isSaving ? null : (String? newValue) {
                      if (newValue != null) {
                        ref.read(localeProvider.notifier).setLocale(Locale(newValue));
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildExpandableSection(
                icon: Icons.temple_hindu_outlined,
                title: 'Temple / Business Info',
                subtitle: 'Name, address, contact details',
                content: Column(
                  children: [
                    _buildTextField('Temple / Business Name', _businessNameController),
                    const SizedBox(height: 16),
                    _buildTextField('Address', _businessAddressController, maxLines: 2),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Phone', _businessPhoneController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Email', _businessEmailController)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSaveButton('Save Business Info', () => _saveSection(() => _settings.saveBusinessInfo(
                        _businessNameController.text,
                        _businessAddressController.text,
                        _businessPhoneController.text,
                        _businessEmailController.text,
                      ))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildExpandableSection(
                icon: Icons.restaurant_menu_outlined,
                title: 'Pricing Settings',
                subtitle: 'Catering & Hall rental rates',
                content: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Catering Per-Plate Rates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(height: 12),
                    _buildPriceRow('Tier 1', _tier1Controller),
                    const SizedBox(height: 12),
                    _buildPriceRow('Tier 2', _tier2Controller),
                    const SizedBox(height: 12),
                    _buildPriceRow('Tier 3', _tier3Controller),
                    const SizedBox(height: 20),
                    _buildSaveButton('Save Catering Rates', () => _saveSection(() => _pricing.updateCateringPrices(
                        double.tryParse(_tier1Controller.text) ?? 180,
                        double.tryParse(_tier2Controller.text) ?? 210,
                        double.tryParse(_tier3Controller.text) ?? 240,
                      ))),
                    const Divider(height: 40),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Hall Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hall rental rates and cleaning charges are managed in the Hall Management section.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildSaveButton('Go to Hall Management', () {
                      context.push('/halls');
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildExpandableSection(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Reminder alerts & push settings',
                content: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField('First Reminder (Days)', _firstReminderController, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Final Reminder (Days)', _finalReminderController, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildToggleRow('Daily Balance Reminders', _dailyBalanceReminders, (v) => setState(() => _dailyBalanceReminders = v)),
                    _buildToggleRow('Push Notifications', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                    const SizedBox(height: 20),
                    _buildSaveButton('Save Reminder Rules', () => _saveSection(() => _settings.saveReminderSettings(
                        int.tryParse(_firstReminderController.text) ?? 3,
                        int.tryParse(_finalReminderController.text) ?? 1,
                        _dailyBalanceReminders,
                        _pushNotifications,
                      ))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildExpandableSection(
                icon: Icons.phone_android_outlined,
                title: 'UPI & Payment',
                subtitle: 'UPI ID and QR code for receipts',
                content: Column(
                  children: [
                    _buildTextField('UPI ID', _upiIdController),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('QR Code Image', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    _buildImagePickerBox(_settings.upiQrImageUrl, () => _pickImage(false)),
                    const SizedBox(height: 20),
                    _buildSaveButton('Save Payment Info', () => _saveSection(() => _settings.saveUpiInfo(_upiIdController.text, null))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildExpandableSection(
                icon: Icons.receipt_long_outlined,
                title: 'Receipt Footer & Terms',
                subtitle: 'Text shown on printed receipts',
                content: Column(
                  children: [
                    _buildTextField('Receipt Footer Note', _receiptFooterController, maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField('Terms & Conditions', _termsController, maxLines: 4),
                    const SizedBox(height: 20),
                    _buildSaveButton('Save Receipt Settings', () => _saveSection(() => _settings.saveReceiptSettings(_receiptFooterController.text, _termsController.text))),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _buildExpandableSection(
                icon: Icons.branding_watermark_outlined,
                title: 'Branding & Logo',
                subtitle: 'App logo shown on receipts',
                content: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('App Logo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    _buildImagePickerBox(_settings.logoImageUrl, () => _pickImage(true)),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Support & App'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7DCC4)),
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Puranika Sadana',
                          applicationVersion: '1.0.0',
                          applicationIcon: _settings.logoImageUrl != null 
                            ? Image.network(_settings.logoImageUrl!, width: 50, height: 50)
                            : Image.asset('assets/images/logo.png', width: 50, height: 50),
                          children: [
                            const Text('Digitalizing Hall Management for Sri Kshetra Kollur.'),
                            const SizedBox(height: 10),
                            Text('Made for ${_settings.businessName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Divider(color: Color(0xFFE7DCC4)),
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _showLogoutConfirmation,
                icon: const Icon(Icons.logout),
                label: const Text('LOGOUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 40),
              Text('Made for ${_settings.businessName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('App Version 1.0.0', style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 10)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3D1608)),
        ),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFB5651D)),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFB5651D), size: 24),
          ),
          title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3D1608))),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            const Divider(color: Color(0xFFE7DCC4), height: 32),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool isNumber = false, bool isObscured = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          obscureText: isObscured,
          enabled: !_isSaving,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7DCC4))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7DCC4))),
            filled: true,
            fillColor: _isSaving ? Colors.grey.shade100 : const Color(0xFFFBF7EE),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: !_isSaving,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              prefixText: '₹ ',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7DCC4))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7DCC4))),
              filled: true,
              fillColor: _isSaving ? Colors.grey.shade100 : Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Switch(
          value: value,
          onChanged: _isSaving ? null : onChanged,
          activeThumbColor: const Color(0xFFB5651D),
        ),
      ],
    );
  }

  Widget _buildImagePickerBox(String? imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7EE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE7DCC4), style: BorderStyle.solid),
        ),
        child: imageUrl != null
            ? Stack(
                children: [
                  Center(child: Image.network(imageUrl, fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  )),
                  if (!_isSaving)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: const Color(0xFFB5651D), size: 30),
                  const SizedBox(height: 8),
                  const Text('Tap to upload image', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _buildSaveButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D1608),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _isSaving
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
        : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }
}
