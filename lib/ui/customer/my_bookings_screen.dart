import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  // ========================================================
  // ฟังก์ชันกล่องยืนยันการยกเลิกคิว (Pop-up Confirm)
  // ========================================================
  Future<void> _showCancelDialog(
    BuildContext context,
    dynamic bookingId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการยกเลิก'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการยกเลิกการจองคิวนี้?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false), // ปิดกล่องและส่งค่า false
            child: const Text('ปิด', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true), // ปิดกล่องและส่งค่า true
            child: const Text(
              'ใช่, ยกเลิกการจอง',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // ถ้าลูกค้ากด "ใช่"
    if (confirm == true) {
      try {
        // ยิงคำสั่งอัปเดตสถานะเป็น cancelled ในฐานข้อมูล
        await Supabase.instance.client
            .from('bookings')
            .update({'status': 'cancelled'})
            .eq('id', bookingId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ยกเลิกการจองสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการจองของฉัน')),
      body: user == null
          ? const Center(child: Text('กรุณาล็อกอิน'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('bookings')
                  .stream(primaryKey: ['id'])
                  .eq('customer_id', user.id)
                  .order('created_at', ascending: false),
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

                if (bookings == null || bookings.isEmpty) {
                  return const Center(
                    child: Text(
                      'คุณยังไม่มีประวัติการจองบริการครับ',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final details = booking['service_details'] ?? {};
                    final imageUrl = booking['image_url'];

                    // แปลงสถานะให้เป็นภาษาไทยที่อ่านง่าย
                    String statusText = booking['status'];
                    Color statusColor = Colors.grey;

                    if (statusText == 'pending') {
                      statusText = 'รอช่างรับงาน';
                      statusColor = Colors.orange;
                    } else if (statusText == 'cancelled') {
                      statusText = 'ยกเลิกแล้ว';
                      statusColor = Colors.red;
                    } else if (statusText == 'accepted') {
                      statusText = 'ช่างรับงานแล้ว';
                      statusColor = Colors.blue;
                    } else if (statusText == 'completed') {
                      statusText = 'เสร็จสิ้น';
                      statusColor = Colors.green;
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: statusText == 'ยกเลิกแล้ว'
                                    ? Colors.grey.shade300
                                    : Colors.blueAccent,
                                child: Icon(
                                  Icons.build,
                                  color: statusText == 'ยกเลิกแล้ว'
                                      ? Colors.grey
                                      : Colors.white,
                                ),
                              ),
                              title: Text(
                                'บริการ: ${booking['service_type']} (${details['sub_type'] ?? ''})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: statusText == 'ยกเลิกแล้ว'
                                      ? TextDecoration.lineThrough
                                      : null, // ถ้าขีดฆ่าให้ดูรู้ว่ายกเลิก
                                  color: statusText == 'ยกเลิกแล้ว'
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    'วันที่: ${booking['booking_date']} | เวลา: ${booking['booking_time'].toString().substring(0, 5)}',
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Text('สถานะ: '),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  // ถ้ายกเลิกแล้ว ให้รูปภาพดูจางๆ ลง
                                  child: Opacity(
                                    opacity: statusText == 'ยกเลิกแล้ว'
                                        ? 0.4
                                        : 1.0,
                                    child: Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                              ),

                            // ========================================================
                            // ปุ่มยกเลิกคิว (โชว์เฉพาะคิวที่ยังเป็น pending)
                            // ========================================================
                            if (booking['status'] == 'pending') ...[
                              const Divider(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      _showCancelDialog(context, booking['id']),
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'ยกเลิกการจอง',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
