import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../widgets/shared_booking_fields.dart';

/// Configuration for a bookable service category.
class ServiceConfig {
  final String serviceName;      // e.g. 'Electrical'
  final String serviceTypeKey;   // stored in DB service_type column
  final Color themeColor;
  final List<String> subTypes;
  final List<Map<String, dynamic>> extraFields;

  const ServiceConfig({
    required this.serviceName,
    required this.serviceTypeKey,
    required this.themeColor,
    required this.subTypes,
    this.extraFields = const [],
  });
}

// ---------------------------------------------------------------------------
// Pre-built configs for the five remaining services
// ---------------------------------------------------------------------------

final electricalConfig = ServiceConfig(
  serviceName: 'Electrical',
  serviceTypeKey: 'Electrical',
  themeColor: Colors.orange,
  subTypes: ['Wiring Repair', 'Outlet / Switch Install', 'Circuit Breaker', 'Electrical Inspection'],
  extraFields: [
    {'key': 'issue', 'label': 'Describe the issue', 'type': 'text'},
  ],
);

final solarConfig = ServiceConfig(
  serviceName: 'Solar',
  serviceTypeKey: 'Solar',
  themeColor: Colors.amber,
  subTypes: ['Panel Installation', 'Panel Maintenance', 'Inverter Repair', 'System Consultation'],
  extraFields: [
    {
      'key': 'roof_type',
      'label': 'Roof Type',
      'type': 'dropdown',
      'options': ['Concrete', 'Metal Sheet', 'Tile', 'Other'],
    },
    {'key': 'panel_count', 'label': 'Number of Panels (if applicable)', 'type': 'number'},
    {'key': 'issue', 'label': 'Additional details', 'type': 'text'},
  ],
);

final cctvConfig = ServiceConfig(
  serviceName: 'CCTV',
  serviceTypeKey: 'CCTV',
  themeColor: Colors.red,
  subTypes: ['New Installation', 'Camera Repair', 'Camera Replacement', 'System Upgrade'],
  extraFields: [
    {'key': 'camera_count', 'label': 'Number of Cameras', 'type': 'number'},
    {
      'key': 'location_type',
      'label': 'Location Type',
      'type': 'dropdown',
      'options': ['Indoor', 'Outdoor', 'Both'],
    },
    {'key': 'issue', 'label': 'Additional details', 'type': 'text'},
  ],
);

final waterPumpConfig = ServiceConfig(
  serviceName: 'Water Pump',
  serviceTypeKey: 'Water Pump',
  themeColor: Colors.cyan,
  subTypes: ['Installation', 'Repair', 'Replacement', 'Maintenance'],
  extraFields: [
    {
      'key': 'pump_type',
      'label': 'Pump Type',
      'type': 'dropdown',
      'options': ['Submersible', 'Centrifugal', 'Jet Pump', 'Booster Pump', 'Not Sure'],
    },
    {'key': 'issue', 'label': 'Describe the issue', 'type': 'text'},
  ],
);

final electronicsConfig = ServiceConfig(
  serviceName: 'Electronics',
  serviceTypeKey: 'Electronics',
  themeColor: Colors.purple,
  subTypes: ['TV Repair', 'Washing Machine', 'Refrigerator', 'Other Appliance'],
  extraFields: [
    {'key': 'brand_model', 'label': 'Brand / Model', 'type': 'text'},
    {'key': 'issue', 'label': 'Describe the issue', 'type': 'text'},
  ],
);

// ---------------------------------------------------------------------------
// Generic booking screen driven by ServiceConfig
// ---------------------------------------------------------------------------

class ServiceBookingScreen extends StatefulWidget {
  final ServiceConfig config;
  const ServiceBookingScreen({super.key, required this.config});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  late String _selectedSubType;

  // Controllers for extra fields (keyed by field key)
  final Map<String, TextEditingController> _extraControllers = {};
  // Dropdown values for extra fields (keyed by field key)
  final Map<String, String> _dropdownValues = {};

  // Profile controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  List<String> _savedAddresses = [];
  bool _isNewAddress = false;

  DateTime? _selectedDate;
  String? _selectedTime;

  bool _hasImage = false;
  XFile? _pickedImage;
  Uint8List? _imageBytes;

  List<String> _bookedTimes = [];
  bool _isLoadingTimes = false;
  Timer? _addressDebounce;

  @override
  void initState() {
    super.initState();
    _selectedSubType = widget.config.subTypes.first;

    for (final field in widget.config.extraFields) {
      final key = field['key'] as String;
      if (field['type'] == 'dropdown') {
        _dropdownValues[key] = (field['options'] as List<String>).first;
      } else {
        _extraControllers[key] = TextEditingController();
      }
    }

    _fetchUserProfile();
    _addressController.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final text = _addressController.text.trim();
      final isNew = text.isNotEmpty && !_savedAddresses.contains(text);
      if (isNew == _isNewAddress) return;
      setState(() => _isNewAddress = isNew);
    });
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _addressController.removeListener(_onAddressChanged);
    for (final c in _extraControllers.values) {
      c.dispose();
    }
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ---- Profile helpers (same logic as AirBookingScreen) ----

  Future<void> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      setState(() {
        _nameController.text = profile['full_name'] ?? '';
        _phoneController.text = profile['phone_number'] ?? '';
        if (profile['saved_addresses'] != null) {
          _savedAddresses = List<String>.from(profile['saved_addresses']);
          if (_savedAddresses.isNotEmpty) {
            _addressController.text = _savedAddresses.first;
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _saveNewAddress() async {
    final text = _addressController.text.trim();
    if (text.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final updatedAddresses = List<String>.from(_savedAddresses)..add(text);
    try {
      await Supabase.instance.client.from('profiles').update({
        'saved_addresses': updatedAddresses,
        'full_name': _nameController.text,
        'phone_number': _phoneController.text,
      }).eq('id', user.id);

      setState(() {
        _savedAddresses = updatedAddresses;
        _isNewAddress = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ---- Date / time helpers ----

  Future<void> _fetchBookedTimes(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _selectedTime = null;
      _isLoadingTimes = true;
    });
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select('booking_time')
          .eq('booking_date', dateStr)
          .eq('service_type', widget.config.serviceTypeKey)
          .neq('status', 'cancelled');
      setState(() {
        _bookedTimes =
            response.map<String>((e) => (e['booking_time'] as String).substring(0, 5)).toList();
        _isLoadingTimes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTimes = false);
    }
  }

  // ---- Image picker ----

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = image;
        _imageBytes = bytes;
        _hasImage = true;
      });
    }
  }

  // ---- Submit booking ----

  Future<void> _submitBooking() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _addressController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving booking...')),
      );

      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr = '$_selectedTime:00';

      // Check for double-booking
      final existingBookings = await Supabase.instance.client
          .from('bookings')
          .select('id')
          .eq('booking_date', dateStr)
          .eq('booking_time', timeStr)
          .eq('service_type', widget.config.serviceTypeKey)
          .neq('status', 'cancelled');

      if (existingBookings.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This time slot is now full, please choose another',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.orange,
            ),
          );
          _fetchBookedTimes(_selectedDate!);
        }
        return;
      }

      // Upload image if provided
      String? imageUrl;
      if (_pickedImage != null && _imageBytes != null) {
        final fileExt =
            _pickedImage!.name.split('.').last.isEmpty ? 'png' : _pickedImage!.name.split('.').last;
        final filePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await Supabase.instance.client.storage.from('booking_images').uploadBinary(
              filePath,
              _imageBytes!,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        imageUrl = Supabase.instance.client.storage.from('booking_images').getPublicUrl(filePath);
      }

      // Build service_details JSONB
      final Map<String, dynamic> serviceDetails = {
        'sub_type': _selectedSubType,
        'contact_name': _nameController.text,
        'contact_phone': _phoneController.text,
        'address': _addressController.text,
      };
      // Add extra field values
      for (final field in widget.config.extraFields) {
        final key = field['key'] as String;
        if (field['type'] == 'dropdown') {
          serviceDetails[key] = _dropdownValues[key];
        } else {
          serviceDetails[key] = _extraControllers[key]?.text ?? '';
        }
      }

      await Supabase.instance.client.from('bookings').insert({
        'customer_id': user.id,
        'service_type': widget.config.serviceTypeKey,
        'service_details': serviceDetails,
        'booking_date': dateStr,
        'booking_time': timeStr,
        'status': 'pending',
        'image_url': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed!', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;

    return Scaffold(
      appBar: AppBar(title: Text('Book ${cfg.serviceName} Service')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          // --- Sub-type selector ---
          const Text('Service Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemCount: cfg.subTypes.length,
            itemBuilder: (context, index) {
              final sub = cfg.subTypes[index];
              final isSelected = _selectedSubType == sub;
              return ChoiceChip(
                label: Center(
                  child: Text(
                    sub,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedSubType = sub);
                },
                selectedColor: cfg.themeColor,
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(color: isSelected ? cfg.themeColor : Colors.grey.shade300),
              );
            },
          ),
          const SizedBox(height: 20),

          // --- Extra fields ---
          if (cfg.extraFields.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cfg.themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${cfg.serviceName} Details',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...cfg.extraFields.map((field) {
                    final key = field['key'] as String;
                    final label = field['label'] as String;
                    final type = field['type'] as String;

                    if (type == 'dropdown') {
                      final options = field['options'] as List<String>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: label,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          initialValue: _dropdownValues[key],
                          items: options
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) => setState(() => _dropdownValues[key] = v!),
                        ),
                      );
                    } else if (type == 'number') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _extraControllers[key],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: label,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      );
                    } else {
                      // text
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _extraControllers[key],
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: label,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      );
                    }
                  }),
                ],
              ),
            ),

          const SizedBox(height: 15),

          // --- Image picker ---
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: Icon(
              _hasImage ? Icons.check_circle : Icons.camera_alt,
              color: _hasImage ? Colors.green : cfg.themeColor,
            ),
            label: Text(
              _hasImage ? 'Image attached (tap to change)' : 'Take photo / Attach job site image',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(color: _hasImage ? Colors.green : cfg.themeColor),
              backgroundColor: _hasImage ? Colors.green.shade50 : Colors.transparent,
            ),
          ),

          // --- Shared fields (address, date, time) ---
          SharedBookingFields(
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            bookedTimes: _bookedTimes,
            isLoadingTimes: _isLoadingTimes,
            nameController: _nameController,
            phoneController: _phoneController,
            addressController: _addressController,
            savedAddresses: _savedAddresses,
            showSaveAddressButton: _isNewAddress,
            onAddressSelected: (newAddress) {
              if (newAddress != null) setState(() => _addressController.text = newAddress);
            },
            onSaveAddressTap: _saveNewAddress,
            onDateSelected: (newDate) => _fetchBookedTimes(newDate),
            onTimeSelected: (newTime) => setState(() => _selectedTime = newTime),
          ),

        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
            boxShadow: AppShadows.lifted,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: cfg.themeColor,
              foregroundColor: Colors.white,
              shadowColor: cfg.themeColor.withValues(alpha: 0.45),
              elevation: 4,
            ),
            onPressed: _submitBooking,
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('Confirm Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          ),
        ),
      ),
    );
  }
}
