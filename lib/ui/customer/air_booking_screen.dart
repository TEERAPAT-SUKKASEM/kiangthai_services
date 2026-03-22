import 'dart:typed_data'; // เพิ่มตัวนี้สำหรับจัดการไฟล์บนเว็บ
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // แพ็กเกจกล้องที่เราเพิ่งลงไป
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
  TimeOfDay? _selectedTime;
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  bool _hasImage = false;

  // ตัวแปรสำหรับเก็บไฟล์รูปภาพ
  XFile? _pickedImage;
  Uint8List? _imageBytes; // จำเป็นสำหรับการอัปโหลดบนเว็บ

  @override
  void dispose() {
    _btuController.dispose();
    _countController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับเปิดแกลลอรี่/กล้อง
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // เลือกรูปจากแกลลอรี่
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // อ่านไฟล์เป็น Byte เพื่อให้รองรับการทำงานบน Web
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = image;
        _imageBytes = bytes;
        _hasImage = true; // เปลี่ยนสถานะปุ่มให้เป็นสีเขียว
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

          SharedBookingFields(
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            addressController: _addressController,
            noteController: _noteController,
            hasImage: _hasImage,
            onDateTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            onTimeTap: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => _selectedTime = picked);
              }
            },
            onImageTap: _pickImage, // เรียกใช้ฟังก์ชันเลือกรูปที่เราสร้างไว้!
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
                  const SnackBar(
                    content: Text(
                      'กำลังส่งข้อมูลและอัปโหลดรูปภาพ... (อาจใช้เวลาสักครู่)',
                    ),
                  ),
                );

                String? imageUrl; // ตัวแปรเก็บลิงก์รูป

                // ถ้ามีการแนบรูปภาพ ให้เอาไปอัปโหลดขึ้น Storage ก่อน!
                if (_pickedImage != null && _imageBytes != null) {
                  // สร้างชื่อไฟล์ไม่ให้ซ้ำกัน โดยใช้วันที่และเวลา
                  final fileExt = _pickedImage!.name.split('.').last.isEmpty
                      ? 'png'
                      : _pickedImage!.name.split('.').last;
                  final fileName =
                      '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                  final filePath =
                      '${user.id}/$fileName'; // เก็บในโฟลเดอร์ชื่อ ID ลูกค้า

                  // โยนรูปขึ้น Storage
                  await Supabase.instance.client.storage
                      .from('booking_images')
                      .uploadBinary(
                        filePath,
                        _imageBytes!,
                        fileOptions: FileOptions(contentType: 'image/$fileExt'),
                      );

                  // ขอลิงก์รูป (Public URL) กลับมาเพื่อเอาไปเก็บในตาราง Bookings
                  imageUrl = Supabase.instance.client.storage
                      .from('booking_images')
                      .getPublicUrl(filePath);
                }

                final dateStr =
                    '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
                final timeStr =
                    '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

                // ยิงข้อมูลขึ้นตาราง bookings
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
                  'image_url':
                      imageUrl, // ส่งลิงก์รูปภาพไปเก็บในตารางด้วย! (ถ้าไม่ได้แนบก็จะเป็น null)
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
