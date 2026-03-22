import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// นำเข้าไฟล์ตั้งค่า Firebase ที่เราใช้คำสั่งสร้างมา
import 'firebase_options.dart';

void main() async {
  // 1. ล็อคให้ Flutter เตรียม Engine ให้พร้อมก่อนรันคำสั่งอื่นๆ
  WidgetsFlutterBinding.ensureInitialized();

  // 2. โหลดไฟล์ .env เพื่อดึงค่า URL และ Key
  await dotenv.load(fileName: ".env");

  // 3. เริ่มต้นการทำงานของ Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4. เริ่มต้นการทำงานของ Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 5. สั่งรันแอปพลิเคชัน
  runApp(const KiangThaiApp());
}

class KiangThaiApp extends StatelessWidget {
  const KiangThaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiang Thai Service',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // ตอนนี้เราจะแสดงหน้าจอเปล่าๆ ไว้ก่อน เพื่อทดสอบว่าระบบไม่ Error
      home: const Scaffold(
        body: Center(
          child: Text(
            'Kiang Thai Service\nระบบฐานข้อมูลเชื่อมต่อสำเร็จแล้ว!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
