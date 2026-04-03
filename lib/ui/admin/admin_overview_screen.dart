import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, int>> _fetchStats() async {
    final db = Supabase.instance.client;
    final results = await Future.wait([
      db.from('bookings').select('id').count(),
      db.from('bookings').select('id').eq('status', 'pending').count(),
      db.from('profiles').select('id').eq('role', 'technician').count(),
      db.from('profiles').select('id').eq('role', 'customer').count(),
    ]);
    return {
      'total': results[0].count,
      'pending': results[1].count,
      'technicians': results[2].count,
      'customers': results[3].count,
    };
  }

  void _refresh() => setState(() => _statsFuture = _fetchStats());

  Widget _buildStatCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ภาพรวม'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final stats = snapshot.data!;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                label: 'การจองทั้งหมด',
                value: stats['total']!,
                icon: Icons.receipt_long,
                color: Colors.blueAccent,
              ),
              _buildStatCard(
                label: 'รอช่างรับงาน',
                value: stats['pending']!,
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              _buildStatCard(
                label: 'ช่างเทคนิค',
                value: stats['technicians']!,
                icon: Icons.build,
                color: Colors.green,
              ),
              _buildStatCard(
                label: 'ลูกค้า',
                value: stats['customers']!,
                icon: Icons.people,
                color: Colors.purple,
              ),
            ],
          );
        },
      ),
    );
  }
}
