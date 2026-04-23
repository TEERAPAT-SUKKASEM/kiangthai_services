import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/chat_unread_service.dart';
import '../../services/notification_service.dart';
import '../customer/profile_settings_screen.dart';
import '../../data/models/booking.dart';
import '../chat/chat_screen.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/unread_badge.dart';

class TechnicianMainScreen extends StatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  State<TechnicianMainScreen> createState() => _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends State<TechnicianMainScreen> {
  final Set<dynamic> _processingJobs = {};
  bool _showHistory = false;
  RealtimeChannel? _newJobsChannel;
  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    _subscribeToNewJobs();
    _subscribeToIncomingMessages();
  }

  @override
  void dispose() {
    _newJobsChannel?.unsubscribe();
    _messagesChannel?.unsubscribe();
    super.dispose();
  }

  // Notify the technician when a new pending booking lands on the job board.
  void _subscribeToNewJobs() {
    final tech = Supabase.instance.client.auth.currentUser;
    if (tech == null) return;

    _newJobsChannel = Supabase.instance.client
        .channel('technician_new_jobs_${tech.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            final status = payload.newRecord['status'] as String?;
            if (status != 'pending') return;
            final serviceType =
                payload.newRecord['service_type'] as String? ?? 'service';
            NotificationService.showLocal(
              title: 'New job available',
              body: 'A new $serviceType booking is waiting for a technician.',
            );
          },
        )
        .subscribe();
  }

  void _subscribeToIncomingMessages() {
    final tech = Supabase.instance.client.auth.currentUser;
    if (tech == null) return;

    _messagesChannel = Supabase.instance.client
        .channel('technician_messages_${tech.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final senderId = payload.newRecord['sender_id'] as String?;
            if (senderId == tech.id) return; // my own message
            final bookingId = payload.newRecord['booking_id'];
            ChatUnreadService.instance.markUnread(bookingId);
            NotificationService.showLocal(
              title: 'New message',
              body: payload.newRecord['content'] as String? ?? '',
            );
          },
        )
        .subscribe();
  }

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job accepted')),
        );
      }
    } catch (e) {
      // On failure, restore the card
      setState(() => _processingJobs.remove(bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                      ),
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
                    child: UnreadBadge(
                      bookingId: booking.id,
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
    final greetingName = (tech?.userMetadata?['full_name'] as String?)?.split(' ').first
        ?? tech?.email?.split('@').first
        ?? 'there';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $greetingName',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your job board',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ],
                      ),
                    ),
                    PressableScale(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                          boxShadow: AppShadows.soft,
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            size: 22, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              if (tech != null) _TechStatsBanner(technicianId: tech.id),
              Container(
                color: AppColors.surface,
                child: const TabBar(
                  tabs: [
                    Tab(text: 'New Jobs'),
                    Tab(text: 'My Jobs'),
                  ],
                ),
              ),
              Expanded(
                child: tech == null
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
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final bookings = snapshot.data;
                              if (bookings == null || bookings.isEmpty) {
                                return const _TechEmptyState(
                                  icon: Icons.inbox_rounded,
                                  title: 'You\'re all caught up',
                                  subtitle: 'No new jobs right now.\nWe\'ll notify you when one comes in.',
                                );
                              }
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
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
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
                                        ? _TechEmptyState(
                                            icon: _showHistory
                                                ? Icons.history_rounded
                                                : Icons.work_outline_rounded,
                                            title: _showHistory
                                                ? 'No job history yet'
                                                : 'No active jobs',
                                            subtitle: _showHistory
                                                ? 'Completed jobs will appear here.'
                                                : 'Accept a job from the New Jobs tab to get started.',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _TechStatsBanner extends StatelessWidget {
  final String technicianId;
  const _TechStatsBanner({required this.technicianId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.brandGlow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.brand, AppColors.brandDark],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('bookings')
                      .stream(primaryKey: ['id'])
                      .eq('technician_id', technicianId),
                  builder: (context, snapshot) {
                    final bookings = snapshot.data ?? const [];
                    const activeStatuses = {
                      'accepted',
                      'on_the_way',
                      'in_progress',
                    };
                    final active = bookings
                        .where((b) => activeStatuses.contains(b['status']))
                        .length;
                    final completed = bookings
                        .where((b) => b['status'] == 'completed')
                        .length;

                    return Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Active',
                            value: '$active',
                            icon: Icons.bolt_rounded,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        Expanded(
                          child: _StatTile(
                            label: 'Completed',
                            value: '$completed',
                            icon: Icons.verified_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TechEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TechEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.brand, 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.brand, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
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
