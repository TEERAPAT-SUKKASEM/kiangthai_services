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
          // 2. ใช้ StreamBuilder เพื่อให้ข้อมูลอัปเดตแบบ Real-time
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
                    final imageUrl =
                        booking['image_url']; // ดึง URL รูปภาพออกมา

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // แสดงข้อมูลหลักของการจอง
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.build, color: Colors.white),
                              ),
                              title: Text(
                                'บริการ: ${booking['service_type']} (${details['sub_type'] ?? ''})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'วันที่: ${booking['booking_date']} เวลา: ${booking['booking_time']}\nสถานะ: ${booking['status'] == 'pending' ? 'รอช่างรับงาน' : booking['status']}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                            ),

                            // ========================================================
                            // ✅ ✅ ✅ ส่วนแสดงรูปภาพหน้างาน (ถ้ามี) ✅ ✅ ✅
                            // ========================================================
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 200, // กำหนดความสูงรูปภาพ
                                    fit: BoxFit
                                        .cover, // ให้รูปภาพเต็มพื้นที่โดยไม่เสียสัดส่วน
                                    // แสดงตัวโหลดขณะกำลังโหลดรูปภาพ
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            width: double.infinity,
                                            height: 200,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                    // แสดงไอคอน Error ถ้าโหลดรูปภาพล้มเหลว
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            // ========================================================
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
