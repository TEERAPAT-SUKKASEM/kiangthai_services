import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';
import '../../../data/models/booking.dart';
import '../../chat/chat_screen.dart';
import '../../widgets/unread_badge.dart';

/// Pending-job card shown in the "New Jobs" tab.
///
/// Shows an urgency badge (Fresh → Waiting → Urgent) based on how long the
/// booking has been waiting for a technician.
class JobCardPending extends StatelessWidget {
  final Booking booking;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const JobCardPending({
    super.key,
    required this.booking,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const SizedBox.shrink();
    }

    final urgency = _Urgency.forBooking(booking.createdAt);

    final card = Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JobHeader(
              booking: booking,
              accent: urgency.color,
              badge: urgency.label,
            ),
            const SizedBox(height: 14),
            _InfoRow(icon: Icons.event_rounded, text: booking.bookingDate),
            _InfoRow(icon: Icons.schedule_rounded, text: booking.bookingTime),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: booking.contactName ?? 'N/A',
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              text: booking.contactPhone ?? 'N/A',
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: booking.address ?? 'N/A',
              multiline: true,
            ),
            if (booking.btu != null || booking.symptoms != null) ...[
              const SizedBox(height: 12),
              _ExtrasBlock(booking: booking),
            ],
            if (booking.imageUrl != null && booking.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _JobImage(url: booking.imageUrl!),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
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
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      shadowColor: AppColors.accent.withValues(alpha: 0.4),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accept Job'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return card
        .animate()
        .fadeIn(duration: AppDurations.med)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppDurations.med,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Assigned / in-flight job card shown in the "My Jobs" tab.
class JobCardAssigned extends StatelessWidget {
  final Booking booking;
  final bool isProcessing;
  final String technicianId;
  final void Function(String nextStatus) onUpdateStage;

  const JobCardAssigned({
    super.key,
    required this.booking,
    required this.isProcessing,
    required this.technicianId,
    required this.onUpdateStage,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const SizedBox.shrink();
    }

    final statusColor = AppColors.forStatus(booking.status);

    final card = Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JobHeader(
              booking: booking,
              accent: statusColor,
              badge: booking.statusLabel,
            ),
            const SizedBox(height: 14),
            _InfoRow(icon: Icons.event_rounded, text: booking.bookingDate),
            _InfoRow(icon: Icons.schedule_rounded, text: booking.bookingTime),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: booking.contactName ?? 'N/A',
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              text: booking.contactPhone ?? 'N/A',
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: booking.address ?? 'N/A',
              multiline: true,
            ),
            if (booking.btu != null || booking.symptoms != null) ...[
              const SizedBox(height: 12),
              _ExtrasBlock(booking: booking),
            ],
            if (booking.imageUrl != null && booking.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _JobImage(url: booking.imageUrl!),
              ),
            if (booking.isActive) ...[
              const SizedBox(height: 16),
              _StageIndicator(status: booking.status),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: UnreadBadge(
                      bookingId: booking.id,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              bookingId: booking.id,
                              currentUserId: technicianId,
                              currentUserRole: 'technician',
                              otherPersonName:
                                  booking.contactName ?? 'Customer',
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Chat'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _NextStageButton(
                      booking: booking,
                      onUpdate: onUpdateStage,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return card.animate().fadeIn(duration: AppDurations.med);
  }
}

class _Urgency {
  final Color color;
  final String label;
  const _Urgency(this.color, this.label);

  static _Urgency forBooking(String createdAtStr) {
    final created = DateTime.tryParse(createdAtStr)?.toLocal();
    if (created == null) {
      return const _Urgency(AppColors.pending, 'New');
    }
    final age = DateTime.now().difference(created);
    if (age.inMinutes < 2) {
      return const _Urgency(AppColors.completed, 'Fresh');
    }
    if (age.inMinutes < 5) {
      return const _Urgency(AppColors.pending, 'Waiting');
    }
    return const _Urgency(AppColors.urgentPending, 'Urgent');
  }
}

class _JobHeader extends StatelessWidget {
  final Booking booking;
  final Color accent;
  final String badge;
  const _JobHeader({
    required this.booking,
    required this.accent,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.tint(accent, 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                badge,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool multiline;
  const _InfoRow({
    required this.icon,
    required this.text,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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

class _ExtrasBlock extends StatelessWidget {
  final Booking booking;
  const _ExtrasBlock({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _JobImage extends StatelessWidget {
  final String url;
  const _JobImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        memCacheHeight: 360,
        fadeInDuration: AppDurations.med,
        placeholder: (context, u) => Container(
          height: 150,
          color: AppColors.fieldFill,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, u, e) => Container(
          height: 150,
          color: AppColors.fieldFill,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _StageIndicator extends StatelessWidget {
  final String status;
  const _StageIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    const stages = [
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
                    AnimatedContainer(
                      duration: AppDurations.med,
                      curve: Curves.easeOutCubic,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.brand : AppColors.fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stages[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDone ? AppColors.brand : AppColors.textMuted,
                        fontWeight:
                            isDone ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                SizedBox(
                  width: 20,
                  child: AnimatedContainer(
                    duration: AppDurations.med,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22),
                    color: i < currentIndex
                        ? AppColors.brand
                        : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _NextStageButton extends StatelessWidget {
  final Booking booking;
  final void Function(String nextStatus) onUpdate;
  const _NextStageButton({required this.booking, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final (String label, String nextStatus, Color color) =
        switch (booking.status) {
      'accepted' => ('On My Way', 'on_the_way', AppColors.onTheWay),
      'on_the_way' => ('Arrived', 'in_progress', AppColors.inProgress),
      'in_progress' => ('Close Job', 'completed', AppColors.completed),
      _ => ('', '', AppColors.textMuted),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: () => onUpdate(nextStatus),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      icon: Icon(
        nextStatus == 'completed'
            ? Icons.check_rounded
            : Icons.arrow_forward_rounded,
        size: 18,
      ),
      label: Text(label),
    );
  }
}
