import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
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
          const SnackBar(content: Text('Job accepted')),
        );
    } catch (e) {
      // On failure, restore the card
      setState(() => _processingJobs.remove(bookingId));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
    }
  }

  // Function: technician rejects a job
  Future<void> _rejectJob(dynamic bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject this job?'),
        content: const Text('You won\'t be able to undo this action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rejected),
            child: const Text('Reject'),
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
          SnackBar(content: Text('Error: $e')),
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
          title: const Text('Complete this job?'),
          content: const Text('Mark this job as fully completed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.completed),
              child: const Text('Complete'),
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
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (isCompleting) setState(() => _processingJobs.remove(bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.brand : AppColors.fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: isDone
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stages[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDone ? AppColors.brand : AppColors.textMuted,
                        fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                SizedBox(
                  width: 20,
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22),
                    color: i < currentIndex ? AppColors.brand : AppColors.border,
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
      'accepted' => ('On My Way', 'on_the_way', AppColors.onTheWay),
      'on_the_way' => ('Arrived', 'in_progress', AppColors.inProgress),
      'in_progress' => ('Close Job', 'completed', AppColors.completed),
      _ => ('', '', AppColors.textMuted),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: () => _updateStage(booking.id, nextStatus),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      icon: Icon(
        nextStatus == 'completed' ? Icons.check_rounded : Icons.arrow_forward_rounded,
        size: 18,
      ),
      label: Text(label),
    );
  }

  // Build job detail card
  Widget _buildJobCard(Map<String, dynamic> raw, bool isMyJob) {
    final booking = Booking.fromMap(raw);

    if (_processingJobs.contains(booking.id)) {
      return const SizedBox.shrink();
    }

    final statusColor = AppColors.forStatus(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceType,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if ((booking.subType ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          booking.subType!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusPill(label: booking.statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(icon: Icons.event_rounded, text: booking.bookingDate),
            _InfoRow(icon: Icons.schedule_rounded, text: booking.bookingTime),
            _InfoRow(icon: Icons.person_outline_rounded, text: booking.contactName ?? 'N/A'),
            _InfoRow(icon: Icons.phone_outlined, text: booking.contactPhone ?? 'N/A'),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: booking.address ?? 'N/A',
              multiline: true,
            ),

            if (booking.btu != null || booking.symptoms != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (booking.btu != null)
                      Text(
                        '${booking.btu} BTU · ${booking.count} unit(s)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    if (booking.symptoms != null) ...[
                      if (booking.btu != null) const SizedBox(height: 4),
                      Text(
                        booking.symptoms!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (booking.imageUrl != null && booking.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    booking.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 16),
            if (!isMyJob) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectJob(booking.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.rejected,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptJob(booking.id),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Accept Job'),
                    ),
                  ),
                ],
              ),
            ] else if (booking.isActive) ...[
              _buildStageIndicator(booking.status),
              const SizedBox(height: 14),
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
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _buildNextStageButton(booking)),
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
          title: const Text('Technician'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New Jobs'),
              Tab(text: 'My Jobs'),
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tint(color, 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool multiline;
  const _InfoRow({required this.icon, required this.text, this.multiline = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
