import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../customer/profile_settings_screen.dart';
import '../../data/models/booking.dart';
import '../chat/chat_screen.dart';

class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  State<TechnicianMainScreen> createState() => _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends State<TechnicianMainScreen> {
  final Set<dynamic> _processingJobs = {};
  bool _showHistory = false;

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
  // ฟังก์ชัน: ช่างกด "ปฏิเสธงาน"
  // ==========================================
  Future<void> _rejectJob(dynamic bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการปฏิเสธงาน'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการปฏิเสธงานนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ปฏิเสธงาน',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingJobs.add(bookingId));
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'rejected'})
          .eq('id', bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ปฏิเสธงานแล้ว')),
        );
      }
    } catch (e) {
      setState(() => _processingJobs.remove(bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==========================================
  // ฟังก์ชัน: อัปเดต stage ของงาน
  // ==========================================
  Future<void> _updateStage(dynamic bookingId, String newStatus) async {
    final isCompleting = newStatus == 'completed';
    if (isCompleting) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการปิดงาน'),
          content: const Text('ยืนยันว่างานเสร็จสมบูรณ์แล้วใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      setState(() => _processingJobs.add(bookingId));
    }

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);

      if (mounted) {
        final msg = switch (newStatus) {
          'on_the_way' => 'อัปเดต: กำลังเดินทางไปหาลูกค้า',
          'in_progress' => 'อัปเดต: เริ่มดำเนินการแล้ว',
          'completed' => 'ปิดงานเรียบร้อย เยี่ยมมาก!',
          _ => 'อัปเดตสถานะแล้ว',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isCompleting ? Colors.green : Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      if (isCompleting) setState(() => _processingJobs.remove(bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // แสดง progress bar ของขั้นตอนงาน
  Widget _buildStageIndicator(String status) {
    final stages = [
      ('accepted', 'รับงาน'),
      ('on_the_way', 'เดินทาง'),
      ('in_progress', 'ดำเนินการ'),
      ('completed', 'เสร็จสิ้น'),
    ];
    final currentIndex = stages.indexWhere((s) => s.$1 == status);

    return Row(
      children: List.generate(stages.length, (i) {
        final isDone = i <= currentIndex;
        final isLast = i == stages.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          isDone ? Colors.blueAccent : Colors.grey.shade300,
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stages[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDone ? Colors.blueAccent : Colors.grey,
                        fontWeight: isDone
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Divider(
                    thickness: 2,
                    color: i < currentIndex
                        ? Colors.blueAccent
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ปุ่มขั้นตอนถัดไป
  Widget _buildNextStageButton(Booking booking) {
    final (String label, String nextStatus, Color color) =
        switch (booking.status) {
      'accepted' => ('กำลังเดินทาง', 'on_the_way', Colors.orange),
      'on_the_way' => ('ถึงหน้างานแล้ว', 'in_progress', Colors.blue),
      'in_progress' => ('ปิดงาน', 'completed', Colors.green),
      _ => ('', '', Colors.grey),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: () => _updateStage(booking.id, nextStatus),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      icon: Icon(
        nextStatus == 'completed' ? Icons.check_circle : Icons.arrow_forward,
        size: 18,
      ),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Color _chipColor(String status) => switch (status) {
    'pending' => Colors.orange,
    'accepted' => Colors.blue,
    'completed' => Colors.green,
    _ => Colors.grey,
  };

  // ==========================================
  // ส่วนสร้างการ์ดแสดงรายละเอียดใบงาน
  // ==========================================
  Widget _buildJobCard(Map<String, dynamic> raw, bool isMyJob) {
    final booking = Booking.fromMap(raw);

    if (_processingJobs.contains(booking.id)) {
      return const SizedBox.shrink();
    }

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
                Expanded(
                  child: Text(
                    'งาน: ${booking.serviceType} (${booking.subType ?? ''})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    booking.statusLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _chipColor(booking.status),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('วันที่นัด: ${booking.bookingDate}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('เวลา: ${booking.bookingTime}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('ลูกค้า: ${booking.contactName ?? 'ไม่ระบุ'}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('เบอร์ติดต่อ: ${booking.contactPhone ?? 'ไม่ระบุ'}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                const SizedBox(width: 5),
                Expanded(child: Text('ที่อยู่: ${booking.address ?? 'ไม่ระบุ'}')),
              ],
            ),

            if (booking.btu != null || booking.symptoms != null) ...[
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
                    if (booking.btu != null)
                      Text('ขนาด: ${booking.btu} | จำนวน: ${booking.count} เครื่อง'),
                    if (booking.symptoms != null)
                      Text(
                        'อาการเสีย: ${booking.symptoms}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ],

            if (booking.imageUrl != null && booking.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    booking.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 15),
            if (!isMyJob) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptJob(booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.pan_tool),
                      label: const Text(
                        'รับงาน',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectJob(booking.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text(
                        'ปฏิเสธ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (booking.isActive) ...[
              _buildStageIndicator(booking.status),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final tech = Supabase.instance.client.auth.currentUser;
                        if (tech == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              bookingId: booking.id,
                              currentUserId: tech.id,
                              currentUserRole: 'technician',
                              otherPersonName: booking.contactName ?? 'ลูกค้า',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('แชท'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildNextStageButton(booking)),
                ],
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
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              ),
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
                      final bookings = snapshot.data ?? [];

                      const activeStatuses = {
                        'accepted',
                        'on_the_way',
                        'in_progress',
                      };
                      final displayed = _showHistory
                          ? bookings
                          : bookings
                              .where((b) =>
                                  activeStatuses.contains(b['status']))
                              .toList();

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                FilterChip(
                                  label: const Text('แสดงประวัติ'),
                                  selected: _showHistory,
                                  onSelected: (val) =>
                                      setState(() => _showHistory = val),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: displayed.isEmpty
                                ? Center(
                                    child: Text(
                                      _showHistory
                                          ? 'ยังไม่มีประวัติงาน'
                                          : 'ไม่มีงานที่กำลังดำเนินการ',
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: displayed.length,
                                    itemBuilder: (context, index) =>
                                        _buildJobCard(displayed[index], true),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
