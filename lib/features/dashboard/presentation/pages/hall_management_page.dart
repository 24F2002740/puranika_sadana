import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../../data/repositories/hall_repository_provider.dart';
import '../../domain/models/hall.dart';

class HallManagementPage extends ConsumerStatefulWidget {
  final int initialIndex;
  const HallManagementPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HallManagementPage> createState() => _HallManagementPageState();
}

class _HallManagementPageState extends ConsumerState<HallManagementPage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final ImagePicker _picker = ImagePicker();

  List<Hall> _halls = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers and State per Hall
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _locationControllers = [];
  final List<TextEditingController> _capacityControllers = [];
  final List<TextEditingController> _rateControllers = [];
  final List<TextEditingController> _cleaningControllers = [];
  final List<bool> _activeStatus = [];
  final List<List<String>> _hallFacilities = [];
  final List<List<String>> _hallPhotos = [];

  // Validation errors
  final List<Map<String, String?>> _errors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
    _loadHalls();
  }

  Future<void> _loadHalls() async {
    try {
      final halls = await ref.read(hallRepositoryProvider).getHalls();

      if (!mounted) return;

      // Dispose the previous controller before creating a new one.
      _tabController?.dispose();
      _tabController = null;

      // Clear old controllers/data.
      _disposeControllers();

      setState(() {
        _halls = halls;

        if (halls.isNotEmpty) {
          final safeIndex = widget.initialIndex.clamp(0, halls.length - 1);

          _tabController = TabController(
            length: halls.length,
            vsync: this,
            initialIndex: safeIndex,
          );
        }

        for (final hall in halls) {
          _nameControllers.add(
            TextEditingController(text: hall.name),
          );

          _locationControllers.add(
            TextEditingController(text: hall.location),
          );

          _capacityControllers.add(
            TextEditingController(text: hall.capacity.toString()),
          );

          _rateControllers.add(
            TextEditingController(
              text: hall.packageRate.toInt().toString(),
            ),
          );

          _cleaningControllers.add(
            TextEditingController(
              text: hall.cleaningCharge.toInt().toString(),
            ),
          );

          _activeStatus.add(hall.isActive);
          _hallFacilities.add(List<String>.from(hall.facilities));
          _hallPhotos.add(List<String>.from(hall.photoPaths));
          _errors.add({});
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _halls = [];
        _tabController?.dispose();
        _tabController = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading halls: $e'),
        ),
      );
    }
  }

    void _disposeControllers() {
      for (var c in _nameControllers) {
        c.dispose();
      }

      for (var c in _locationControllers) {
        c.dispose();
      }

      for (var c in _capacityControllers) {
        c.dispose();
      }

      for (var c in _rateControllers) {
        c.dispose();
      }

      for (var c in _cleaningControllers) {
        c.dispose();
      }

      _nameControllers.clear();
      _locationControllers.clear();
      _capacityControllers.clear();
      _rateControllers.clear();
      _cleaningControllers.clear();
      _activeStatus.clear();
      _hallFacilities.clear();
      _hallPhotos.clear();
      _errors.clear();
    }

    @override
    void dispose() {
      _tabController?.dispose();
      _disposeControllers();
      super.dispose();
    }

    void _goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    }

    Future<void> _addPhoto() async {
      if (_isSaving) return;
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: const Color(0xFFFBF7EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        builder: (context) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D1608)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPickerOption(Icons.camera_alt_outlined, 'Take Photo', () => Navigator.pop(context, ImageSource.camera)),
                  _buildPickerOption(Icons.photo_library_outlined, 'Choose from Gallery', () => Navigator.pop(context, ImageSource.gallery)),
                ],
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        await _pickImage(source);
      }
    }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera permission denied. Please enable it in settings.',
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();

        final fileName =
            'hall_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';

        final savedImage = await File(image.path).copy(
          '${appDir.path}/$fileName',
        );

        final tabController = _tabController;

        if (tabController == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hall selected.')),
            );
          }
          return;
        }

        final index = tabController.index;

        if (index < 0 || index >= _hallPhotos.length) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid hall selected.')),
            );
          }
          return;
        }

        setState(() {
          _hallPhotos[index].add(savedImage.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

    Widget _buildPickerOption(IconData icon, String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE7DCC4)),
              ),
              child: Icon(icon, color: const Color(0xFFB5651D), size: 30),
            ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _addNewFacility() {
    if (_isSaving) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFBF7EE),
        title: const Text('Add Facility', style: TextStyle(color: Color(0xFF3D1608))),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter facility name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  final tabController = _tabController;

                  if (tabController == null) {
                    return;
                  }

                  final index = tabController.index;

                  if (index >= 0 && index < _hallFacilities.length) {
                    _hallFacilities[index].add(controller.text);
                  }
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D1608), foregroundColor: Colors.white),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFacility(int hallIndex, int facilityIndex) {
    if (_isSaving) return;
    final facility = _hallFacilities[hallIndex][facilityIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFBF7EE),
        title: const Text('Delete Facility', style: TextStyle(color: Color(0xFF3D1608), fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$facility"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hallFacilities[hallIndex].removeAt(facilityIndex);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('YES, DELETE'),
          ),
        ],
      ),
    );
  }

  bool _validate(int index) {
    bool isValid = true;
    setState(() {
      final name = _nameControllers[index].text.trim();
      final location = _locationControllers[index].text.trim();
      final capacityStr = _capacityControllers[index].text.trim();
      final rateStr = _rateControllers[index].text.trim();
      final cleaningStr = _cleaningControllers[index].text.trim();

      _errors[index]['name'] = name.isEmpty ? 'Hall Name cannot be empty' : null;
      _errors[index]['location'] = location.isEmpty ? 'Location cannot be empty' : null;

      final cap = int.tryParse(capacityStr);
      _errors[index]['capacity'] = (cap == null || cap <= 0) ? 'Enter a valid positive number' : null;

      final rate = double.tryParse(rateStr);
      _errors[index]['rate'] = (rate == null || rate <= 0) ? 'Enter a valid positive number' : null;

      final cleaning = double.tryParse(cleaningStr);
      _errors[index]['cleaning'] = (cleaning == null || cleaning < 0) ? 'Enter a valid number' : null;

      isValid = _errors[index].values.every((e) => e == null);
    });
    return isValid;
  }

  Future<void> _saveAllChanges() async {
    // Re-entrancy guard
    if (_isSaving) return;

    final tabController = _tabController;

    if (tabController == null) {
      return;
    }

    final index = tabController.index;
    if (!_validate(index)) return;

    setState(() => _isSaving = true);
    try {
      final hall = _halls[index];
      final updatedHall = hall.copyWith(
        name: _nameControllers[index].text.trim(),
        location: _locationControllers[index].text.trim(),
        capacity: int.parse(_capacityControllers[index].text.trim()),
        packageRate: double.parse(_rateControllers[index].text.trim()),
        cleaningCharge: double.parse(_cleaningControllers[index].text.trim()),
        isActive: _activeStatus[index],
        facilities: _hallFacilities[index],
        photoPaths: _hallPhotos[index],
      );

      await ref.read(hallRepositoryProvider).saveHall(updatedHall);
      
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All changes for this hall saved successfully')),
        );
        _loadHalls(); // Refresh everything
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF7EE),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3D1608),
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isSaving ? null : _goBack,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hall Management', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${_halls.length} halls',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _isSaving ? null : _addNewFacility,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_halls.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No halls found.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else ...[
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController!,
                  labelColor: const Color(0xFF3D1608),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFB5651D),
                  indicatorWeight: 3,
                  isScrollable: true,
                  tabs: _halls
                      .map((hall) => Tab(text: hall.name))
                      .toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController!,
                  children: List.generate(
                    _halls.length,
                        (index) => _buildHallForm(index),
                  ),
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: _buildBottomButton(),

      ),
    );
  }

  Widget _buildHallForm(int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hall Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3D1608)),
              ),
              Switch(
                value: _activeStatus[index],
                onChanged: _isSaving ? null : (v) => setState(() => _activeStatus[index] = v),
                activeThumbColor: const Color(0xFFB5651D),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('Hall Name', _nameControllers[index], errorText: _errors[index]['name']),
          const SizedBox(height: 16),
          _buildTextField('Location', _locationControllers[index], errorText: _errors[index]['location']),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTextField('Capacity', _capacityControllers[index], isNumber: true, errorText: _errors[index]['capacity'])),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Package Rate (₹)', _rateControllers[index], isNumber: true, errorText: _errors[index]['rate'])),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Cleaning Charge (₹)', _cleaningControllers[index], isNumber: true, errorText: _errors[index]['cleaning']),
          const SizedBox(height: 24),
          const Text(
            'Photos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3D1608)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _hallPhotos[index].length + 1,
              itemBuilder: (context, photoIdx) {
                if (photoIdx == _hallPhotos[index].length) {
                  return InkWell(
                    onTap: _isSaving ? null : _addPhoto,
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE7DCC4), style: BorderStyle.solid),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFB5651D)),
                    ),
                  );
                }
                final photoPath = _hallPhotos[index][photoIdx];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                    image: photoPath.startsWith('assets/')
                      ? DecorationImage(image: AssetImage(photoPath), fit: BoxFit.cover)
                      : DecorationImage(image: FileImage(File(photoPath)), fit: BoxFit.cover),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: _isSaving ? null : () => setState(() => _hallPhotos[index].removeAt(photoIdx)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hall Facilities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3D1608)),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hallFacilities[index].length,
            itemBuilder: (context, facilityIdx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE7DCC4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFFB5651D), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_hallFacilities[index][facilityIdx], style: const TextStyle(fontSize: 13))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                      onPressed: _isSaving ? null : () => _confirmDeleteFacility(index, facilityIdx),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _isSaving ? Colors.grey.shade100 : Colors.white,
            errorText: errorText,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE7DCC4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE7DCC4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAllChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D1608),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : const Text('Save All Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
