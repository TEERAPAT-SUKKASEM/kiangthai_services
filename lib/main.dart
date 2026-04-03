import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'ui/auth/login_screen.dart';
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

  runApp(const KiangThaiApp());
}

class KiangThaiApp extends StatelessWidget {
  const KiangThaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiang Thai Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
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

          // ดึง role จาก profiles เพื่อ route ไปหน้าที่ถูกต้อง
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
