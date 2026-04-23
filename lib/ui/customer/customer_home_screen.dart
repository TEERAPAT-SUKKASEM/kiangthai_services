import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import 'air_booking_screen.dart';
import 'service_booking_screen.dart';
import 'profile_settings_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  static const List<_ServiceTile> _services = [
    _ServiceTile(name: 'AC', icon: Icons.ac_unit_rounded, tint: Color(0xFF0EA5E9)),
    _ServiceTile(name: 'Electrical', icon: Icons.electrical_services_rounded, tint: Color(0xFFF59E0B)),
    _ServiceTile(name: 'Solar', icon: Icons.wb_sunny_rounded, tint: Color(0xFFF97316)),
    _ServiceTile(name: 'CCTV', icon: Icons.videocam_rounded, tint: Color(0xFFEF4444)),
    _ServiceTile(name: 'Water Pump', icon: Icons.water_drop_rounded, tint: Color(0xFF06B6D4)),
    _ServiceTile(name: 'Electronics', icon: Icons.devices_other_rounded, tint: Color(0xFF8B5CF6)),
  ];

  static final Map<String, ServiceConfig> _serviceConfigs = {
    'Electrical': electricalConfig,
    'Solar': solarConfig,
    'CCTV': cctvConfig,
    'Water Pump': waterPumpConfig,
    'Electronics': electronicsConfig,
  };

  void _onServiceTap(BuildContext context, _ServiceTile service) {
    if (service.name == 'AC') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AirBookingScreen()));
    } else {
      final config = _serviceConfigs[service.name];
      if (config != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ServiceBookingScreen(config: config)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final greetingName = (user?.userMetadata?['full_name'] as String?)?.split(' ').first
        ?? user?.email?.split('@').first
        ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
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
                            'What do you need today?',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ],
                      ),
                    ),
                    _ProfileButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _PromoBanner()),
            const SliverToBoxAdapter(child: _TrustStrip()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Our Services',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${_services.length} available',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final s = _services[index];
                    return _ServiceCard(tile: s, onTap: () => _onServiceTap(context, s));
                  },
                  childCount: _services.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile {
  final String name;
  final IconData icon;
  final Color tint;
  const _ServiceTile({required this.name, required this.icon, required this.tint});
}

class _ServiceCard extends StatelessWidget {
  final _ServiceTile tile;
  final VoidCallback onTap;
  const _ServiceCard({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tint(tile.tint, 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tile.icon, color: tile.tint, size: 24),
                ),
                const Spacer(),
                Text(tile.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Book now',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.person_outline_rounded, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: const [
          Expanded(child: _TrustStat(icon: Icons.verified_rounded, label: 'Verified', value: '100+')),
          SizedBox(width: 10),
          Expanded(child: _TrustStat(icon: Icons.star_rounded, label: 'Rating', value: '4.9')),
          SizedBox(width: 10),
          Expanded(child: _TrustStat(icon: Icons.bolt_rounded, label: 'Response', value: '<30m')),
        ],
      ),
    );
  }
}

class _TrustStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _TrustStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brand, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand, AppColors.brandDark],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trusted home services',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Book verified technicians in minutes.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
