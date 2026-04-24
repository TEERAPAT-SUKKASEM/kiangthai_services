import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../data/models/booking.dart';
import '../../services/chat_unread_service.dart';
import '../../services/notification_service.dart';
import '../customer/profile_settings_screen.dart';
import '../widgets/pressable_scale.dart';
import 'widgets/tech_empty_state.dart';
import 'widgets/tech_job_card.dart';
import 'widgets/tech_stats_banner.dart';

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
            if (senderId == tech.id) return;
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

  Future<void> _acceptJob(dynamic bookingId) async {
    final tech = Supabase.instance.client.auth.currentUser;
    if (tech == null) return;

    setState(() => _processingJobs.add(bookingId));

    try {
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
      setState(() => _processingJobs.remove(bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.completed,
              ),
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

  @override
  Widget build(BuildContext context) {
    final tech = Supabase.instance.client.auth.currentUser;
    final greetingName = (tech?.userMetadata?['full_name'] as String?)
            ?.split(' ')
            .first ??
        tech?.email?.split('@').first ??
        'there';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TechnicianHeader(greetingName: greetingName),
              if (tech != null) TechStatsBanner(technicianId: tech.id),
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
                          _PendingJobsTab(
                            processingJobs: _processingJobs,
                            onAccept: _acceptJob,
                            onReject: _rejectJob,
                          ),
                          _AssignedJobsTab(
                            technicianId: tech.id,
                            processingJobs: _processingJobs,
                            showHistory: _showHistory,
                            onToggleHistory: (v) =>
                                setState(() => _showHistory = v),
                            onUpdateStage: _updateStage,
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

class _TechnicianHeader extends StatelessWidget {
  final String greetingName;
  const _TechnicianHeader({required this.greetingName});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingJobsTab extends StatelessWidget {
  final Set<dynamic> processingJobs;
  final Future<void> Function(dynamic) onAccept;
  final Future<void> Function(dynamic) onReject;

  const _PendingJobsTab({
    required this.processingJobs,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _JobsSkeleton();
        }
        final raw = snapshot.data;
        if (raw == null || raw.isEmpty) {
          return const TechEmptyState(
            icon: Icons.inbox_rounded,
            title: 'You\'re all caught up',
            subtitle:
                'No new jobs right now.\nWe\'ll notify you when one comes in.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: raw.length,
          itemBuilder: (context, index) {
            final booking = Booking.fromMap(raw[index]);
            return JobCardPending(
              key: ValueKey(booking.id),
              booking: booking,
              isProcessing: processingJobs.contains(booking.id),
              onAccept: () => onAccept(booking.id),
              onReject: () => onReject(booking.id),
            );
          },
        );
      },
    );
  }
}

class _JobsSkeleton extends StatelessWidget {
  const _JobsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: 3,
        itemBuilder: (_, _) => Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Electrical Service',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text('Sub-service placeholder',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Jan 1 2026', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('10:00', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('Customer name placeholder',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('+66 81 234 5678',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('Address placeholder line that spans the row',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignedJobsTab extends StatelessWidget {
  final String technicianId;
  final Set<dynamic> processingJobs;
  final bool showHistory;
  final ValueChanged<bool> onToggleHistory;
  final Future<void> Function(dynamic, String) onUpdateStage;

  const _AssignedJobsTab({
    required this.technicianId,
    required this.processingJobs,
    required this.showHistory,
    required this.onToggleHistory,
    required this.onUpdateStage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _JobsSkeleton();
        }
        final bookings = snapshot.data ?? [];

        const activeStatuses = {'accepted', 'on_the_way', 'in_progress'};
        final displayed = showHistory
            ? bookings
            : bookings
                .where((b) => activeStatuses.contains(b['status']))
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
                    selected: showHistory,
                    onSelected: onToggleHistory,
                  ),
                ],
              ),
            ),
            Expanded(
              child: displayed.isEmpty
                  ? TechEmptyState(
                      icon: showHistory
                          ? Icons.history_rounded
                          : Icons.work_outline_rounded,
                      title: showHistory
                          ? 'No job history yet'
                          : 'No active jobs',
                      subtitle: showHistory
                          ? 'Completed jobs will appear here.'
                          : 'Accept a job from the New Jobs tab to get started.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: displayed.length,
                      itemBuilder: (context, index) {
                        final booking = Booking.fromMap(displayed[index]);
                        return JobCardAssigned(
                          key: ValueKey(booking.id),
                          booking: booking,
                          isProcessing:
                              processingJobs.contains(booking.id),
                          technicianId: technicianId,
                          onUpdateStage: (next) =>
                              onUpdateStage(booking.id, next),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
