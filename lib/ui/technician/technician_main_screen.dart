import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  State<TechnicianMainScreen> createState() => _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends State<TechnicianMainScreen> {
  // 🌟 พระเอกของเรา: ตัวเก็บ ID ของงานที่กำลังกดรับ/ปิด (เพื่อเอาไปซ่อนทันที)
  final Set<dynamic> _processingJobs = {};

  // ==========================================
  // ฟังก์ชัน: ช่างกด "รับงาน"
  // ==========================================
  Future<void> _acceptJob(dynamic bookingId) async {
    final tech = Supabase.instance.client.auth.currentUser;
    if (tech == null) return;

    // 1. หลอกตา: เอา ID ใส่ในลิสต์กำลังประมวลผล เพื่อซ่อนการ์ดทันทีที่กด!
    setState(() => _processingJobs.add(bookingId));

    try {
      // 2. ส่งข้อมูลไปอัปเดตหลังบ้านเงียบๆ
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'accepted', 'technician_id': tech.id})
          .eq('id', bookingId);

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รับงานสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      // ถ้าพัง ให้เอาการ์ดกลับมาโชว์เหมือนเดิม
      setState(() => _processingJobs.remove(bookingId));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // ==========================================
  // ฟังก์ชัน: ช่างกด "ปิดงาน" (เสร็จสิ้น)
  // ==========================================
  Future<void> _completeJob(dynamic bookingId) async {
    // 1. หลอกตา: ซ่อนการ์ดทันทีที่กด!
    setState(() => _processingJobs.add(bookingId));

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'completed'})
          .eq('id', bookingId);

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปิดงานเรียบร้อย เยี่ยมมาก!'),
            backgroundColor: Colors.blue,
          ),
        );
    } catch (e) {
      setState(() => _processingJobs.remove(bookingId));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // ==========================================
  // ส่วนสร้างการ์ดแสดงรายละเอียดใบงาน
  // ==========================================
  Widget _buildJobCard(Map<String, dynamic> booking, bool isMyJob) {
    // 🌟 🌟 🌟 เช็กว่าถ้างายนี้กำลังกดรับ/กดปิด ให้ซ่อนไปเลย (วาดกล่องเปล่าๆ แทน)
    if (_processingJobs.contains(booking['id'])) {
      return const SizedBox.shrink();
    }

    final details = booking['service_details'] ?? {};
    final imageUrl = booking['image_url'];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'งาน: ${booking['service_type']} (${details['sub_type']})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(
                    booking['status'] == 'pending'
                        ? 'รอช่างรับงาน'
                        : (booking['status'] == 'accepted'
                              ? 'กำลังดำเนินการ'
                              : 'เสร็จสิ้น'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: booking['status'] == 'pending'
                      ? Colors.orange
                      : (booking['status'] == 'accepted'
                            ? Colors.blue
                            : Colors.green),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('วันที่นัด: ${booking['booking_date']}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'เวลา: ${booking['booking_time'].toString().substring(0, 5)}',
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('ลูกค้า: ${details['contact_name'] ?? 'ไม่ระบุ'}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('เบอร์ติดต่อ: ${details['contact_phone'] ?? 'ไม่ระบุ'}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text('ที่อยู่: ${details['address'] ?? 'ไม่ระบุ'}'),
                ),
              ],
            ),

            if (details['btu'] != null || details['symptoms'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (details['btu'] != null)
                      Text(
                        'ขนาด: ${details['btu']} | จำนวน: ${details['count']} เครื่อง',
                      ),
                    if (details['symptoms'] != null)
                      Text(
                        'อาการเสีย: ${details['symptoms']}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ],

            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 15),
            if (!isMyJob) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _acceptJob(booking['id']), // ไม่ต้องส่ง context แล้ว
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.pan_tool),
                  label: const Text(
                    'กดรับงานนี้',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ] else if (booking['status'] == 'accepted') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeJob(booking['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'ทำงานเสร็จสิ้น (ปิดงาน)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tech = Supabase.instance.client.auth.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kiang Thai Service (ช่าง)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted)
                  Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(icon: Icon(Icons.new_releases), text: 'งานใหม่ (รอรับ)'),
              Tab(icon: Icon(Icons.engineering), text: 'งานของฉัน'),
            ],
          ),
        ),
        body: tech == null
            ? const Center(child: Text('กรุณาล็อกอิน'))
            : TabBarView(
                children: [
                  // แท็บ 1: งานใหม่
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('bookings')
                        .stream(primaryKey: ['id'])
                        .eq('status', 'pending')
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      final bookings = snapshot.data;
                      if (bookings == null || bookings.isEmpty)
                        return const Center(
                          child: Text('ยังไม่มีงานใหม่เข้ามาครับ'),
                        );
                      return ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) =>
                            _buildJobCard(bookings[index], false),
                      );
                    },
                  ),

                  // แท็บ 2: งานของฉัน
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('bookings')
                        .stream(primaryKey: ['id'])
                        .eq('technician_id', tech.id)
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      final bookings = snapshot.data;
                      if (bookings == null || bookings.isEmpty)
                        return const Center(
                          child: Text('คุณยังไม่มีงานที่รับผิดชอบครับ'),
                        );

                      // ดึงเฉพาะงานที่ยังไม่เสร็จสิ้นมาโชว์ (หรืออยากโชว์ completed ด้วยก็ได้)
                      final activeBookings = bookings
                          .where((b) => b['status'] != 'completed')
                          .toList();
                      if (activeBookings.isEmpty)
                        return const Center(
                          child: Text('เคลียร์งานหมดแล้ว ยอดเยี่ยมมากครับ!'),
                        );

                      return ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: activeBookings.length,
                        itemBuilder: (context, index) =>
                            _buildJobCard(activeBookings[index], true),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
