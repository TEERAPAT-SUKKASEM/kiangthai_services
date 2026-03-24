import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/shared_booking_fields.dart';

class AirBookingScreen extends StatefulWidget {
  const AirBookingScreen({super.key});

  @override
  State<AirBookingScreen> createState() => _AirBookingScreenState();
}

class _AirBookingScreenState extends State<AirBookingScreen> {
  final List<String> _services = [
    'ล้างแอร์',
    'ซ่อมแอร์',
    'ติดตั้งแอร์',
    'ย้ายแอร์',
  ];
  String _selectedService = 'ล้างแอร์';

  final List<String> _btuOptions = [
    'ไม่ทราบขนาด / ไม่แน่ใจ',
    '9,000 BTU',
    '12,000 BTU',
    '15,000 BTU',
    '18,000 BTU',
    '24,000 BTU',
    '30,000+ BTU',
  ];
  String _selectedBtu = 'ไม่ทราบขนาด / ไม่แน่ใจ';

  final _countController = TextEditingController(text: '1');
  final _symptomsController = TextEditingController();

  // ----- Controller สำหรับ Profile -----
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  List<String> _savedAddresses = [];
  bool _isNewAddress = false; // ตัวเช็กว่าพิมพ์ที่อยู่ใหม่หรือเปล่า

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
    _fetchUserProfile(); // ดึงข้อมูลทันทีที่เปิดหน้านี้

    // ดักจับการพิมพ์กล่องที่อยู่: ถ้าพิมพ์แล้วไม่เหมือนในลิสต์ ให้โชว์ปุ่มเซฟ
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

  // ==========================================
  // ดึงข้อมูลส่วนตัวมาจาก Database (profiles)
  // ==========================================
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

        // ดึงลิสต์ที่อยู่ (ถ้ามี)
        if (profile['saved_addresses'] != null) {
          _savedAddresses = List<String>.from(profile['saved_addresses']);
          if (_savedAddresses.isNotEmpty) {
            _addressController.text =
                _savedAddresses.first; // ออโต้เติมที่อยู่อันแรกให้เลย
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  // ==========================================
  // บันทึกที่อยู่ใหม่กลับไปที่ Database
  // ==========================================
  Future<void> _saveNewAddress() async {
    final text = _addressController.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final updatedAddresses = List<String>.from(_savedAddresses)
      ..add(text); // เพิ่มของใหม่เข้าไปในลิสต์

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'saved_addresses': updatedAddresses,
            'full_name':
                _nameController.text, // อัปเดตชื่อเผื่อลูกค้าแก้ด้วยเลย
            'phone_number': _phoneController.text,
          })
          .eq('id', user.id);

      setState(() {
        _savedAddresses = updatedAddresses; // อัปเดตลิสต์ในหน้าจอ
        _isNewAddress = false; // ซ่อนปุ่มเซฟ
      });

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกที่อยู่ลงรายการสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
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
          .eq('service_type', 'แอร์')
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
      appBar: AppBar(title: const Text('จองบริการแอร์')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'ประเภทบริการ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    service,
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

          if (_selectedService == 'ล้างแอร์') ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายละเอียดแอร์',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'ขนาด BTU',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: _selectedBtu,
                    items: _btuOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) =>
                        setState(() => _selectedBtu = newValue!),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _countController,
                    decoration: const InputDecoration(
                      labelText: 'จำนวนเครื่อง',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],

          if (_selectedService == 'ซ่อมแอร์') ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายละเอียดการซ่อม',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _symptomsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ระบุอาการเสีย (เช่น แอร์ไม่เย็น, มีน้ำหยด)',
                      border: OutlineInputBorder(),
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
                  ? 'แนบรูปภาพสำเร็จ (กดเพื่อเปลี่ยน)'
                  : 'ถ่ายรูป / แนบรูปภาพหน้างาน',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(color: _hasImage ? Colors.green : Colors.blue),
              backgroundColor: _hasImage
                  ? Colors.green.shade50
                  : Colors.transparent,
            ),
          ),

          // ==========================================
          // เรียกใช้ Shared Widget และโยนตัวแปรให้ครบ
          // ==========================================
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
            onSaveAddressTap: _saveNewAddress, // ผูกปุ่มเซฟกับฟังก์ชัน
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
              if (_selectedDate == null ||
                  _selectedTime == null ||
                  _addressController.text.isEmpty ||
                  _nameController.text.isEmpty ||
                  _phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'กรุณากรอกข้อมูลให้ครบถ้วน',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (_selectedService == 'ซ่อมแอร์' &&
                  _symptomsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'กรุณาระบุอาการเสีย',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) return;

              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังบันทึกข้อมูล...')),
                );
                final dateStr =
                    '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
                final timeStr = '$_selectedTime:00';

                final existingBookings = await Supabase.instance.client
                    .from('bookings')
                    .select('id')
                    .eq('booking_date', dateStr)
                    .eq('booking_time', timeStr)
                    .eq('service_type', 'แอร์')
                    .neq('status', 'cancelled');
                if (existingBookings.isNotEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'คิวนี้เพิ่งเต็ม กรุณาเลือกเวลาใหม่',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    _fetchBookedTimes(_selectedDate!);
                  }
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

                // แพ็คชื่อ เบอร์โทร และที่อยู่ ลงใน JSONB เลย ช่างจะได้เห็นข้อมูลเป๊ะๆ
                await Supabase.instance.client.from('bookings').insert({
                  'customer_id': user.id,
                  'service_type': 'แอร์',
                  'service_details': {
                    'sub_type': _selectedService,
                    'btu': _selectedService == 'ล้างแอร์' ? _selectedBtu : null,
                    'count': _selectedService == 'ล้างแอร์'
                        ? _countController.text
                        : null,
                    'symptoms': _selectedService == 'ซ่อมแอร์'
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

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'จองคิวสำเร็จ!',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            child: const Text(
              'ยืนยันการจอง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
