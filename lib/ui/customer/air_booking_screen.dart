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
  // ตัวแปรสำหรับบริการแอร์
  final List<String> _services = [
    'ล้างแอร์',
    'ซ่อมแอร์',
    'ติดตั้งแอร์',
    'ย้ายแอร์',
  ];
  String _selectedService = 'ล้างแอร์';

  // ตัวแปร Dropdown BTU
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

  final _countController = TextEditingController(text: '1'); // จำนวนเครื่อง
  final _symptomsController =
      TextEditingController(); // อาการเสีย (แทน note เดิม)

  DateTime? _selectedDate;
  String? _selectedTime;
  final _addressController = TextEditingController();

  bool _hasImage = false;
  XFile? _pickedImage;
  Uint8List? _imageBytes;

  List<String> _bookedTimes = [];
  bool _isLoadingTimes = false;

  @override
  void dispose() {
    _countController.dispose();
    _symptomsController.dispose();
    _addressController.dispose();
    super.dispose();
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

      final times = response
          .map<String>((e) => (e['booking_time'] as String).substring(0, 5))
          .toList();
      setState(() {
        _bookedTimes = times;
        _isLoadingTimes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTimes = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
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

          // 1. ปุ่มเลือกบริการแบบ Grid (2x2)
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

          // ==========================================
          // 2. ส่วน Dynamic: เปลี่ยนตามประเภทบริการ
          // ==========================================

          // --- ถ้าเลือกล้างแอร์ ---
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
                          (String value) => DropdownMenuItem<String>(
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

          // --- ถ้าเลือกซ่อมแอร์ ---
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
                      labelText:
                          'ระบุอาการเสีย (เช่น แอร์ไม่เย็น, มีน้ำหยด, เปิดไม่ติด)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // (ติดตั้งแอร์ และ ย้ายแอร์ จะไม่มีช่องกรอกอะไรเพิ่มตามที่คุณระบุครับ)
          const SizedBox(height: 15),

          // 3. ปุ่มแนบรูปภาพ (ย้ายขึ้นมาอยู่ในกลุ่มเดียวกับบริการ)
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

          // 4. เรียกใช้ Shared Widget (เหลือแค่สถานที่และเวลา)
          SharedBookingFields(
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            bookedTimes: _bookedTimes,
            isLoadingTimes: _isLoadingTimes,
            addressController: _addressController,
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
                  _addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'กรุณากรอกวันที่ เวลา และที่อยู่ให้ครบถ้วน',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // บังคับกรอกอาการเสีย ถ้าเลือกซ่อมแอร์
              if (_selectedService == 'ซ่อมแอร์' &&
                  _symptomsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'กรุณาระบุอาการเสียให้ช่างทราบด้วยครับ',
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
                          'ขออภัยครับ เวลานี้เพิ่งถูกจองไปเมื่อสักครู่',
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
                  final fileName =
                      '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                  final filePath = '${user.id}/$fileName';

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

                // การแพ็คข้อมูลลง Database แบบฉลาด (แพ็คเฉพาะข้อมูลที่เกี่ยวกับบริการนั้นๆ)
                await Supabase.instance.client.from('bookings').insert({
                  'customer_id': user.id,
                  'service_type': 'แอร์',
                  'service_details': {
                    'sub_type': _selectedService,
                    // ถ้าเลือกล้างแอร์ ค่อยส่งค่า BTU กับ จำนวนเครื่องไป
                    'btu': _selectedService == 'ล้างแอร์' ? _selectedBtu : null,
                    'count': _selectedService == 'ล้างแอร์'
                        ? _countController.text
                        : null,
                    // ถ้าเลือกซ่อมแอร์ ค่อยส่งค่า อาการเสียไป
                    'symptoms': _selectedService == 'ซ่อมแอร์'
                        ? _symptomsController.text
                        : null,
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
