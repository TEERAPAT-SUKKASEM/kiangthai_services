import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/i18n.dart';
import '../widgets/shared_booking_fields.dart';

class AirBookingScreen extends StatefulWidget {
  const AirBookingScreen({super.key});

  @override
  State<AirBookingScreen> createState() => _AirBookingScreenState();
}

class _AirBookingScreenState extends State<AirBookingScreen> {
  final List<String> _services = [
    'AC Cleaning',
    'AC Repair',
    'AC Installation',
    'AC Relocation',
  ];
  String _selectedService = 'AC Cleaning';

  final List<String> _btuOptions = [
    'Unknown / Not Sure',
    '9,000 BTU',
    '12,000 BTU',
    '15,000 BTU',
    '18,000 BTU',
    '24,000 BTU',
    '30,000+ BTU',
  ];
  String _selectedBtu = 'Unknown / Not Sure';

  final _countController = TextEditingController(text: '1');
  final _symptomsController = TextEditingController();

  // ----- Profile controllers -----
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  List<String> _savedAddresses = [];
  bool _isNewAddress = false; // true when typed address is not in the saved list

  DateTime? _selectedDate;
  String? _selectedTime;

  bool _hasImage = false;
  XFile? _pickedImage;
  Uint8List? _imageBytes;

  List<String> _bookedTimes = [];
  bool _isLoadingTimes = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // load profile data as soon as screen opens

    // Listen for address input: show save button if typed value is not in saved list
    _addressController.addListener(() {
      final text = _addressController.text.trim();
      setState(() {
        _isNewAddress = text.isNotEmpty && !_savedAddresses.contains(text);
      });
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    _symptomsController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Fetch user profile from database (profiles table)
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

        // populate saved addresses if any
        if (profile['saved_addresses'] != null) {
          _savedAddresses = List<String>.from(profile['saved_addresses']);
          if (_savedAddresses.isNotEmpty) {
            _addressController.text =
                _savedAddresses.first; // auto-fill with the first saved address
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  // Save new address back to database
  Future<void> _saveNewAddress() async {
    final text = _addressController.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final updatedAddresses = List<String>.from(_savedAddresses)
      ..add(text); // add new address to the list

    final messenger = ScaffoldMessenger.of(context);

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'saved_addresses': updatedAddresses,
            'full_name':
                _nameController.text, // also update name in case customer changed it
            'phone_number': _phoneController.text,
          })
          .eq('id', user.id);

      if (!mounted) return;
      setState(() {
        _savedAddresses = updatedAddresses; // update displayed list
        _isNewAddress = false; // hide save button
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(t('booking.address_saved')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('${t('common.error')}: $e')));
    }
  }

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
          .eq('service_type', 'AC')
          .neq('status', 'cancelled');
      setState(() {
        _bookedTimes = response
            .map<String>((e) => (e['booking_time'] as String).substring(0, 5))
            .toList();
        _isLoadingTimes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTimes = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('booking.title.ac'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            t('booking.service_type'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
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
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              final isSelected = _selectedService == service;
              return ChoiceChip(
                label: Center(
                  child: Text(
                    tCanonical(service),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedService = service);
                },
                selectedColor: Colors.blueAccent,
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(
                  color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          if (_selectedService == 'AC Cleaning') ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tCanonical('AC')} ${t('booking.details_suffix')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: t('ac.btu_size'),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    initialValue: _selectedBtu,
                    items: _btuOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value == 'Unknown / Not Sure'
                                  ? t('ac.btu_unknown')
                                  : value,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) =>
                        setState(() => _selectedBtu = newValue!),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _countController,
                    decoration: InputDecoration(
                      labelText: t('ac.units'),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],

          if (_selectedService == 'AC Repair') ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('ac.repair_details'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _symptomsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: t('ac.issue_hint'),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 15),

          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: Icon(
              _hasImage ? Icons.check_circle : Icons.camera_alt,
              color: _hasImage ? Colors.green : Colors.blue,
            ),
            label: Text(
              _hasImage
                  ? t('booking.image_attached')
                  : t('booking.take_photo'),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(color: _hasImage ? Colors.green : Colors.blue),
              backgroundColor: _hasImage
                  ? Colors.green.shade50
                  : Colors.transparent,
            ),
          ),

          // Use SharedBookingFields and pass all required variables
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
              if (newAddress != null) {
                setState(() => _addressController.text = newAddress);
              }
            },
            onSaveAddressTap: _saveNewAddress,
            onDateSelected: (newDate) => _fetchBookedTimes(newDate),
            onTimeSelected: (newTime) =>
                setState(() => _selectedTime = newTime),
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              if (_selectedDate == null ||
                  _selectedTime == null ||
                  _addressController.text.isEmpty ||
                  _nameController.text.isEmpty ||
                  _phoneController.text.isEmpty) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      t('booking.fill_required'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (_selectedService == 'AC Repair' &&
                  _symptomsController.text.trim().isEmpty) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      t('ac.describe_issue'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) return;

              try {
                messenger.showSnackBar(
                  SnackBar(content: Text(t('booking.saving'))),
                );
                final dateStr =
                    '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
                final timeStr = '$_selectedTime:00';

                final existingBookings = await Supabase.instance.client
                    .from('bookings')
                    .select('id')
                    .eq('booking_date', dateStr)
                    .eq('booking_time', timeStr)
                    .eq('service_type', 'AC')
                    .neq('status', 'cancelled');
                if (existingBookings.isNotEmpty) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        t('booking.slot_full'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  if (mounted) _fetchBookedTimes(_selectedDate!);
                  return;
                }

                String? imageUrl;
                if (_pickedImage != null && _imageBytes != null) {
                  final fileExt = _pickedImage!.name.split('.').last.isEmpty
                      ? 'png'
                      : _pickedImage!.name.split('.').last;
                  final filePath =
                      '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                  await Supabase.instance.client.storage
                      .from('booking_images')
                      .uploadBinary(
                        filePath,
                        _imageBytes!,
                        fileOptions: FileOptions(contentType: 'image/$fileExt'),
                      );
                  imageUrl = Supabase.instance.client.storage
                      .from('booking_images')
                      .getPublicUrl(filePath);
                }

                // Pack contact info into JSONB so technician sees exact details
                await Supabase.instance.client.from('bookings').insert({
                  'customer_id': user.id,
                  'service_type': 'AC',
                  'service_details': {
                    'sub_type': _selectedService,
                    'btu': _selectedService == 'AC Cleaning' ? _selectedBtu : null,
                    'count': _selectedService == 'AC Cleaning'
                        ? _countController.text
                        : null,
                    'symptoms': _selectedService == 'AC Repair'
                        ? _symptomsController.text
                        : null,
                    'contact_name': _nameController.text,
                    'contact_phone': _phoneController.text,
                    'address': _addressController.text,
                  },
                  'booking_date': dateStr,
                  'booking_time': timeStr,
                  'status': 'pending',
                  'image_url': imageUrl,
                });

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      t('booking.confirmed'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                navigator.pop();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${t('common.error')}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              t('booking.confirm_booking'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
