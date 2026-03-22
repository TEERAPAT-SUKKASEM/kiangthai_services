import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/shared_booking_fields.dart';

class AirBookingScreen extends StatefulWidget {
  const AirBookingScreen({super.key});

  @override
  State<AirBookingScreen> createState() => _AirBookingScreenState();
}

class _AirBookingScreenState extends State<AirBookingScreen> {
  // 1. ตัวแปรสำหรับฟอร์มจองแอร์ (เฉพาะของแอร์)
  String _selectedService = 'ล้างแอร์';
  final _btuController = TextEditingController();
  final _countController = TextEditingController(text: '1');

  // 2. ตัวแปรสำหรับชิ้นส่วนส่วนกลาง (เวลา, สถานที่, รูปภาพ)
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  bool _hasImage = false;

  @override
  void dispose() {
    // ควรล้างข้อมูลใน Controller เมื่อออกจากหน้าจอเพื่อป้องกัน Memory Leak
    _btuController.dispose();
    _countController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
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

          // --- เรียกใช้งาน SharedBookingFields (ส่งค่าให้ครบถ้วน) ---
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
            onImageTap: () {
              // ตอนนี้ทำปุ่มให้กดสลับสถานะได้ก่อน เดี๋ยวเรามาใส่โค้ดกล้องทีหลัง
              setState(() => _hasImage = !_hasImage);
            },
          ),

          // --------------------------------------------------------
          const SizedBox(height: 30),

          // ปุ่มยืนยัน
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // 1. ป้องกันคนลืมกรอกข้อมูล
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

              // 2. ขอตรวจสอบก่อนว่าใครเป็นคนกดจอง (ดึง ID ของลูกค้าที่ล็อกอินอยู่)
              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) return; // ถ้าไม่ได้ล็อกอินให้หยุดการทำงาน

              try {
                // ขึ้นข้อความบอกผู้ใช้ให้รอแป๊บ
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังส่งข้อมูลการจอง...')),
                );

                // 3. แปลงร่าง วันที่ และ เวลา ให้อยู่ในฟอร์แมตที่ Database เข้าใจ (YYYY-MM-DD และ HH:MM:00)
                final dateStr =
                    '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
                final timeStr =
                    '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

                // 4. ยิงข้อมูลขึ้นฟ้า! (ส่งเข้าตาราง bookings)
                await Supabase.instance.client.from('bookings').insert({
                  'customer_id': user.id,
                  'service_type': 'แอร์',
                  // ข้อมูลยิบย่อย เรายัดใส่ JSONB ตามที่ออกแบบ Schema ไว้เป๊ะๆ!
                  'service_details': {
                    'sub_type': _selectedService,
                    'btu': _btuController.text,
                    'count': _countController.text,
                    'address': _addressController.text,
                    'note': _noteController.text,
                  },
                  'booking_date': dateStr,
                  'booking_time': timeStr,
                  'status': 'pending', // สถานะเริ่มต้นคือ "รอการยืนยัน"
                });

                // 5. ถ้าพ้นบรรทัดบนมาได้ แปลว่าสำเร็จ! เด้งกลับไปหน้าแรกเลย
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'จองคิวสำเร็จ! ระบบบันทึกข้อมูลแล้ว',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(
                    context,
                  ); // สั่งปิดหน้าฟอร์มนี้ กลับไปหน้าเลือกบริการ
                }
              } catch (e) {
                // ถ้าเน็ตหลุด หรือมี Error จะโชว์ตรงนี้ครับ
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
