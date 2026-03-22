import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. ดึง ID ของลูกค้าที่ล็อกอินอยู่
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการจองของฉัน')),
      body: user == null
          ? const Center(child: Text('กรุณาล็อกอิน'))
          // 2. ใช้ StreamBuilder เพื่อให้ข้อมูลอัปเดตแบบ Real-time (ถ้าช่างรับงาน สถานะจะเปลี่ยนทันทีไม่ต้องรีเฟรช!)
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('bookings')
                  .stream(primaryKey: ['id'])
                  .eq(
                    'customer_id',
                    user.id,
                  ) // ดึงเฉพาะงานของลูกค้าคนนี้เท่านั้น
                  .order(
                    'created_at',
                    ascending: false,
                  ), // เรียงจากงานใหม่ล่าสุดขึ้นก่อน
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }

                final bookings = snapshot.data;

                // 3. ถ้ายังไม่มีคิวจองเลย
                if (bookings == null || bookings.isEmpty) {
                  return const Center(
                    child: Text(
                      'คุณยังไม่มีประวัติการจองบริการครับ',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                // 4. ถ้ามีคิวจอง ให้นำมาสร้างเป็นรายการ (ListView)
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final details =
                        booking['service_details'] ?? {}; // แกะกล่อง JSON ออกมา

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.build, color: Colors.white),
                        ),
                        title: Text(
                          'บริการ: ${booking['service_type']} (${details['sub_type'] ?? ''})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'วันที่: ${booking['booking_date']} เวลา: ${booking['booking_time']}\nสถานะ: ${booking['status'] == 'pending' ? 'รอช่างรับงาน' : booking['status']}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
