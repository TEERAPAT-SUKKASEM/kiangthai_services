import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/booking.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _filter = 'all';

  final _filters = ['all', 'pending', 'accepted', 'completed', 'cancelled'];

  final _filterLabels = {
    'all': 'All',
    'pending': 'Pending',
    'accepted': 'In Progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  Color _statusColor(String status) => switch (status) {
    'pending' => Colors.orange,
    'accepted' => Colors.blue,
    'completed' => Colors.green,
    'cancelled' || 'rejected' => Colors.red,
    _ => Colors.grey,
  };

  Future<void> _forceCancelBooking(dynamic bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Cancel this booking as admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await Supabase.instance.client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabels[f]!),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: Colors.blueAccent.withValues(alpha: 0.2),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('bookings')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final raw = snapshot.data ?? [];
                final filtered = _filter == 'all'
                    ? raw
                    : raw.where((b) => b['status'] == _filter).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No bookings found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final booking = Booking.fromMap(filtered[index]);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(booking.status).withValues(alpha: 0.15),
                          child: Icon(
                            Icons.build,
                            color: _statusColor(booking.status),
                          ),
                        ),
                        title: Text(
                          '${booking.serviceType} (${booking.subType ?? ''})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${booking.contactName ?? 'N/A'} | ${booking.bookingDate} ${booking.bookingTime}\nStatus: ${booking.statusLabel}',
                        ),
                        isThreeLine: true,
                        trailing: booking.status != 'cancelled' &&
                                booking.status != 'completed'
                            ? IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Cancel',
                                onPressed: () =>
                                    _forceCancelBooking(booking.id),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
