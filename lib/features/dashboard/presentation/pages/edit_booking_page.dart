import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puranika_sadana/core/services/pricing_service.dart';
import 'package:puranika_sadana/features/dashboard/domain/models/booking.dart';
import 'package:puranika_sadana/features/dashboard/domain/models/hall.dart';
import '../../data/repositories/booking_repository_provider.dart';
import '../../data/repositories/hall_repository_provider.dart';

class EditBookingPage extends ConsumerStatefulWidget {
  final Booking booking;
  const EditBookingPage({super.key, required this.booking});

  @override
  ConsumerState<EditBookingPage> createState() => _EditBookingPageState();
}

class _EditBookingPageState extends ConsumerState<EditBookingPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _brideNameController;
  late TextEditingController _groomNameController;
  late TextEditingController _guestCountController;
  late TextEditingController _advancePaidController;
  late Hall _selectedHall;
  late DateTime _selectedDate;
  late int _selectedTier;
  
  late bool _addPalav;
  late bool _addPoori;
  late bool _addIceCream;
  late bool _addWater;
  late bool _addCleaning;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _brideNameController = TextEditingController(text: b.brideName);
    _groomNameController = TextEditingController(text: b.groomName);
    _guestCountController = TextEditingController(text: b.guestCount.toString());
    _advancePaidController = TextEditingController(text: b.advancePaid.toStringAsFixed(0));
    _selectedHall = b.hall;
    _selectedDate = b.eventDate;
    _selectedTier = b.cateringTier;
    _addPalav = b.addPalav;
    _addPoori = b.addPoori;
    _addIceCream = b.addIceCream;
    _addWater = b.addWater;
    _addCleaning = b.addCleaning;
  }

  @override
  void dispose() {
    _brideNameController.dispose();
    _groomNameController.dispose();
    _guestCountController.dispose();
    _advancePaidController.dispose();
    super.dispose();
  }

  double get _cateringTotal {
    final pricing = PricingService();
    final guests = int.tryParse(_guestCountController.text) ?? 0;
    double rate = 0;
    if (_selectedTier == 1) rate = pricing.menu1Price;
    if (_selectedTier == 2) rate = pricing.menu2Price;
    if (_selectedTier == 3) rate = pricing.menu3Price;
    return rate * guests;
  }

  double get _extrasTotal {
    final pricing = PricingService();
    final guests = int.tryParse(_guestCountController.text) ?? 0;
    double total = 0;
    if (_addPalav) total += pricing.palavSaladPrice * guests;
    if (_addPoori) total += pricing.pooriSaguPrice * guests;
    if (_addIceCream) total += pricing.iceCreamPrice * guests;
    if (_addWater) total += pricing.waterBottlePrice * guests;
    if (_addCleaning) total += pricing.defaultCleaningCharge;
    return total;
  }

  double get _grandTotal {
    final double hallPrice = _selectedHall.packageRate;
    return hallPrice + _cateringTotal + _extrasTotal;
  }

  double get _balanceDue {
    final paid = double.tryParse(_advancePaidController.text) ?? 0;
    return _grandTotal - paid;
  }

  @override
  Widget build(BuildContext context) {
    final hallsAsync = ref.watch(watchHallsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1608),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Booking', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('#${widget.booking.id}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      ),
      body: hallsAsync.when(
        data: (halls) {
          // Ensure _selectedHall is part of the halls list (matching by ID)
          final matchedHall = halls.cast<Hall?>().firstWhere(
            (h) => h?.id == _selectedHall.id,
            orElse: () => null,
          );
          
          if (matchedHall != null && matchedHall != _selectedHall) {
             _selectedHall = matchedHall;
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionCard('BRIDE & GROOM', [
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Bride\'s Name', _brideNameController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Groom\'s Name', _groomNameController)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard('EVENT DETAILS', [
                    _buildDropdown('Hall', halls),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker('Event Date')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Guest Count', _guestCountController, isNumber: true)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard('CATERING TIER', [
                    Row(
                      children: [
                        _buildTierButton(1, 'Tier 1', '₹180/plate'),
                        const SizedBox(width: 10),
                        _buildTierButton(2, 'Tier 2', '₹210/plate'),
                        const SizedBox(width: 10),
                        _buildTierButton(3, 'Tier 3', '₹240/plate'),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard('OPTIONAL EXTRAS', [
                    _buildCheckbox('Palav + salad', '+₹35/plate', _addPalav, (v) => setState(() => _addPalav = v!)),
                    _buildCheckbox('2 poori + sagu', '+₹45/plate', _addPoori, (v) => setState(() => _addPoori = v!)),
                    _buildCheckbox('Icecream', '+₹15/plate', _addIceCream, (v) => setState(() => _addIceCream = v!)),
                    _buildCheckbox('Water bottle (500ml)', '+₹7/plate', _addWater, (v) => setState(() => _addWater = v!)),
                    _buildCheckbox('Cleaning charge', '+₹2500', _addCleaning, (v) => setState(() => _addCleaning = v!)),
                  ]),
                  const SizedBox(height: 16),
                  _buildSectionCard('PAYMENT', [
                    _buildTextField('Advance Paid (₹)', _advancePaidController, isNumber: true),
                  ]),
                  const SizedBox(height: 16),
                  _buildCalculationSummary(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFE7DCC4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D1608),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB5651D), letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7DCC4))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE7DCC4))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<Hall> halls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7DCC4)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Hall>(
              value: halls.any((h) => h.id == _selectedHall.id) 
                  ? halls.firstWhere((h) => h.id == _selectedHall.id) 
                  : _selectedHall,
              isExpanded: true,
              items: [
                if (!halls.any((h) => h.id == _selectedHall.id))
                   DropdownMenuItem<Hall>(
                    value: _selectedHall,
                    child: Text(_selectedHall.name),
                  ),
                ...halls.map((hall) => DropdownMenuItem<Hall>(
                  value: hall,
                  child: Text(hall.name),
                )),
              ],
              onChanged: _isSaving ? null : (val) => setState(() => _selectedHall = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSaving ? null : () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7DCC4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MM/dd/yyyy').format(_selectedDate)),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierButton(int tier, String label, String sub) {
    final isSelected = _selectedTier == tier;
    return Expanded(
      child: InkWell(
        onTap: _isSaving ? null : () => setState(() => _selectedTier = tier),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFDF7F0) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFB5651D) : const Color(0xFFE7DCC4), width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFB5651D) : Colors.black87)),
              Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, String price, bool value, Function(bool?) onChanged) {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(value: value, onChanged: _isSaving ? null : onChanged, activeColor: const Color(0xFFB5651D)),
            Text(label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text(price, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const Divider(height: 1, color: Color(0xFFE7DCC4)),
      ],
    );
  }

  Widget _buildCalculationSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC4)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Catering total', _cateringTotal),
          _buildSummaryRow('Extras total', _extrasTotal),
          const Divider(height: 24, color: Color(0xFFE7DCC4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('₹${NumberFormat('#,##,###').format(_grandTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Balance due', style: TextStyle(color: Color(0xFFA53D30), fontWeight: FontWeight.w500, fontSize: 15)),
              Text('₹${NumberFormat('#,##,###').format(_balanceDue)}', style: const TextStyle(color: Color(0xFFA53D30), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text('₹${NumberFormat('#,##,###').format(amount)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  void _saveChanges() async {
    if (_isSaving) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final updatedBooking = widget.booking.copyWith(
        brideName: _brideNameController.text,
        groomName: _groomNameController.text,
        hall: _selectedHall,
        eventDate: _selectedDate,
        totalAmount: _grandTotal,
        advancePaid: double.tryParse(_advancePaidController.text) ?? 0,
        guestCount: int.tryParse(_guestCountController.text) ?? 150,
        cateringTier: _selectedTier,
        addPalav: _addPalav,
        addPoori: _addPoori,
        addIceCream: _addIceCream,
        addWater: _addWater,
        addCleaning: _addCleaning,
      );
      
      try {
        final repository = ref.read(bookingRepositoryProvider);
        await repository.updateBooking(updatedBooking);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
           setState(() => _isSaving = false);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
