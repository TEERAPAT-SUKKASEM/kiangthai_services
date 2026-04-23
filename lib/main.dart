import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/admin/admin_main_screen.dart';
import 'ui/customer/customer_main_screen.dart';
import 'package:kiangthai_services/ui/technician/technician_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  await NotificationService.initialize();

  runApp(const KiangThaiApp());
}

class KiangThaiApp extends StatelessWidget {
  const KiangThaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiang Thai Service',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        if (!kIsWeb) return child ?? const SizedBox.shrink();
        return ColoredBox(
          color: const Color(0xFF1E1E1E),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(
                width: 390,
                height: 844,
                child: child,
              ),
            ),
          ),
        );
      },
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen();
          }

          final session = snapshot.hasData ? snapshot.data!.session : null;

          if (session == null) {
            return const LoginScreen();
          }

          // Fetch role from profiles to route to the correct screen
          return FutureBuilder<Map<String, dynamic>?>(
            future: Supabase.instance.client
                .from('profiles')
                .select('role')
                .eq('id', session.user.id)
                .maybeSingle(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen();
              }

              final role = profileSnapshot.data?['role'] as String?;

              if (role == 'technician') {
                return const TechnicianMainScreen();
              }
              if (role == 'admin') {
                return const AdminMainScreen();
              }
              return const CustomerMainScreen();
            },
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
