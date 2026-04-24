import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';

class TechStatsBanner extends StatelessWidget {
  final String technicianId;
  const TechStatsBanner({super.key, required this.technicianId});

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
                            value: active,
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
                            value: completed,
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
  final int value;
  final IconData icon;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

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
              '$value',
              key: ValueKey<int>(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -0.3,
              ),
            )
                .animate(key: ValueKey<String>('$label-$value'))
                .fadeIn(duration: const Duration(milliseconds: 240))
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
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
