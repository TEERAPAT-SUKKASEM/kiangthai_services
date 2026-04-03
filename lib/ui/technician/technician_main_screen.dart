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

  // Function: technician accepts a job
  Future<void> _acceptJob(dynamic bookingId) async {
    final tech = Supabase.instance.client.auth.currentUser;
    if (tech == null) return;

    // 1. Optimistic UI: add ID to processing set to hide card immediately
    setState(() => _processingJobs.add(bookingId));

    try {
      // 2. Send update to backend silently
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'accepted', 'technician_id': tech.id})
          .eq('id', bookingId);

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted!'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      // On failure, restore the card
      setState(() => _processingJobs.remove(bookingId));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // Function: technician rejects a job
  Future<void> _rejectJob(dynamic bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text('Are you sure you want to reject this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reject Job',
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
          const SnackBar(content: Text('Job rejected')),
        );
      }
    } catch (e) {
      setState(() => _processingJobs.remove(bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function: update job stage
  Future<void> _updateStage(dynamic bookingId, String newStatus) async {
    final isCompleting = newStatus == 'completed';
    if (isCompleting) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Job Completion'),
          content: const Text('Mark this job as fully completed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
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
          'on_the_way' => 'Updated: On the way to customer',
          'in_progress' => 'Updated: Work in progress',
          'completed' => 'Job closed. Great work!',
          _ => 'Status updated',
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
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build job stage progress indicator
  Widget _buildStageIndicator(String status) {
    final stages = [
      ('accepted', 'Accepted'),
      ('on_the_way', 'On the Way'),
      ('in_progress', 'In Progress'),
      ('completed', 'Completed'),
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

  // Next stage button
  Widget _buildNextStageButton(Booking booking) {
    final (String label, String nextStatus, Color color) =
        switch (booking.status) {
      'accepted' => ('On My Way', 'on_the_way', Colors.orange),
      'on_the_way' => ('Arrived at Site', 'in_progress', Colors.blue),
      'in_progress' => ('Close Job', 'completed', Colors.green),
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

  // Build job detail card
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
                    'Job: ${booking.serviceType} (${booking.subType ?? ''})',
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
                Text('Date: ${booking.bookingDate}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Time: ${booking.bookingTime}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Customer: ${booking.contactName ?? 'N/A'}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Phone: ${booking.contactPhone ?? 'N/A'}'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                const SizedBox(width: 5),
                Expanded(child: Text('Address: ${booking.address ?? 'N/A'}')),
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
                      Text('Size: ${booking.btu} | Units: ${booking.count}'),
                    if (booking.symptoms != null)
                      Text(
                        'Issue: ${booking.symptoms}',
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
                        'Accept',
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
                        'Reject',
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
                              otherPersonName: booking.contactName ?? 'Customer',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
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
          title: const Text('Kiang Thai Service (Technician)'),
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
              Tab(icon: Icon(Icons.new_releases), text: 'New Jobs'),
              Tab(icon: Icon(Icons.engineering), text: 'My Jobs'),
            ],
          ),
        ),
        body: tech == null
            ? const Center(child: Text('Please log in'))
            : TabBarView(
                children: [
                  // Tab 1: New jobs
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
                          child: Text('No new jobs available'),
                        );
                      return ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) =>
                            _buildJobCard(bookings[index], false),
                      );
                    },
                  ),

                  // Tab 2: My jobs
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
                                  label: const Text('Show History'),
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
                                          ? 'No job history yet'
                                          : 'No active jobs',
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
