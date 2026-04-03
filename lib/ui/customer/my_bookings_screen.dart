import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/booking.dart';
import '../chat/chat_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  Color _statusColor(String status) => switch (status) {
    'pending' => Colors.orange,
    'accepted' => Colors.blue,
    'on_the_way' => Colors.orange,
    'in_progress' => Colors.blue,
    'completed' => Colors.green,
    'cancelled' || 'rejected' => Colors.red,
    _ => Colors.grey,
  };

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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ปิด', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ใช่, ยกเลิกการจอง',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
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

                final raw = snapshot.data ?? [];
                if (raw.isEmpty) {
                  return const Center(
                    child: Text(
                      'คุณยังไม่มีประวัติการจองบริการครับ',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final bookings = raw.map(Booking.fromMap).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final isCancelled = booking.status == 'cancelled' ||
                        booking.status == 'rejected';
                    final statusColor = _statusColor(booking.status);

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
                                backgroundColor: isCancelled
                                    ? Colors.grey.shade300
                                    : Colors.blueAccent,
                                child: Icon(
                                  Icons.build,
                                  color: isCancelled
                                      ? Colors.grey
                                      : Colors.white,
                                ),
                              ),
                              title: Text(
                                'บริการ: ${booking.serviceType} (${booking.subType ?? ''})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCancelled
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    'วันที่: ${booking.bookingDate} | เวลา: ${booking.bookingTime}',
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Text('สถานะ: '),
                                      Text(
                                        booking.statusLabel,
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

                            if (booking.imageUrl != null &&
                                booking.imageUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Opacity(
                                    opacity: isCancelled ? 0.4 : 1.0,
                                    child: Image.network(
                                      booking.imageUrl!,
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
                                            child: CircularProgressIndicator(),
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

                            if (booking.status == 'accepted') ...[
                              const Divider(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        bookingId: booking.id,
                                        currentUserId: user.id,
                                        currentUserRole: 'customer',
                                        otherPersonName: 'ช่างเทคนิค',
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.chat, color: Colors.blueAccent),
                                  label: const Text(
                                    'แชทกับช่าง',
                                    style: TextStyle(color: Colors.blueAccent),
                                  ),
                                ),
                              ),
                            ],
                            if (booking.status == 'pending') ...[
                              const Divider(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      _showCancelDialog(context, booking.id),
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
