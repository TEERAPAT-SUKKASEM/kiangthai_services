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
  String _selectedService = 'ล้างแอร์';
  final _btuController = TextEditingController();
  final _countController = TextEditingController(text: '1');

  DateTime? _selectedDate;
  String? _selectedTime; // เปลี่่ยนมาเก็บเป็น String เช่น '08:30'
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  bool _hasImage = false;

  XFile? _pickedImage;
  Uint8List? _imageBytes;

  // ตัวแปรใหม่สำหรับจัดการลอจิกปฏิทิน
  List<String> _bookedTimes = [];
  bool _isLoadingTimes = false;

  @override
  void dispose() {
    _btuController.dispose();
    _countController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ==========================================================
  // ฟังก์ชันพระเอก: ดึงคิวที่ถูกจองไปแล้วในวันนั้นๆ
  // ==========================================================
  Future<void> _fetchBookedTimes(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _selectedTime = null; // รีเซ็ตเวลาที่เลือกไว้เมื่อเปลี่ยนวัน
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

      // ดึงเวลาที่ได้มา (เช่น "08:30:00") มาตัดเหลือแค่ "08:30"
      final times = response.map<String>((e) {
        final timeStr = e['booking_time'] as String;
        return timeStr.substring(0, 5);
      }).toList();

      setState(() {
        _bookedTimes = times;
        _isLoadingTimes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTimes = false);
      // โชว์ Error ถ้าดึงไม่ได้
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงคิวว่าง: $e')),
        );
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
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: _selectedService,
            isExpanded: true,
            items: <String>['ล้างแอร์', 'ซ่อมแอร์', 'ติดตั้งแอร์', 'ย้ายแอร์']
                .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                })
                .toList(),
            onChanged: (newValue) =>
                setState(() => _selectedService = newValue!),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _btuController,
            decoration: const InputDecoration(
              labelText: 'ขนาด BTU (ถ้าทราบ)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _countController,
            decoration: const InputDecoration(
              labelText: 'จำนวนเครื่อง',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // ส่งตัวแปรและฟังก์ชันใหม่ให้ SharedBookingFields
          SharedBookingFields(
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            bookedTimes: _bookedTimes,
            isLoadingTimes: _isLoadingTimes,
            addressController: _addressController,
            noteController: _noteController,
            hasImage: _hasImage,
            onDateSelected: (newDate) {
              _fetchBookedTimes(
                newDate,
              ); // กดวันที่ปุ๊บ สั่งยิงข้อมูลถาม Supabase ปั๊บ!
            },
            onTimeSelected: (newTime) {
              setState(() => _selectedTime = newTime);
            },
            onImageTap: _pickImage,
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

              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) return;

              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังบันทึกข้อมูล...')),
                );

                final dateStr =
                    '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
                final timeStr =
                    '$_selectedTime:00'; // ประกอบร่างเวลาให้ฐานข้อมูลเข้าใจ (เติม :00 เข้าไป)

                // ========================================================
                // ระบบเช็กคิวซ้ำตอนกดปุ่ม (เผื่อคนกดพร้อมกันเสี้ยววินาที) ก็ยังคงเก็บไว้เป็น Guard ปราการด่านสุดท้าย
                // ========================================================
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
                          'ขออภัยครับ เวลานี้เพิ่งถูกจองไปเมื่อสักครู่ กรุณาเลือกเวลาใหม่',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    _fetchBookedTimes(
                      _selectedDate!,
                    ); // รีเฟรชปุ่มเวลาใหม่ทันที
                  }
                  return;
                }
                // ========================================================

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

                await Supabase.instance.client.from('bookings').insert({
                  'customer_id': user.id,
                  'service_type': 'แอร์',
                  'service_details': {
                    'sub_type': _selectedService,
                    'btu': _btuController.text,
                    'count': _countController.text,
                    'address': _addressController.text,
                    'note': _noteController.text,
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
