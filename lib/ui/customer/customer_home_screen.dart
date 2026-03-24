import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'air_booking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final List<Map<String, dynamic>> services = const [
    {'name': 'แอร์', 'icon': Icons.ac_unit, 'color': Colors.blue},
    {
      'name': 'ไฟฟ้า',
      'icon': Icons.electrical_services,
      'color': Colors.orange,
    },
    {'name': 'โซล่า', 'icon': Icons.wb_sunny, 'color': Colors.yellow},
    {'name': 'กล้องวงจรปิด', 'icon': Icons.videocam, 'color': Colors.red},
    {'name': 'ปั๊มน้ำ', 'icon': Icons.water_drop, 'color': Colors.cyan},
    {
      'name': 'อิเล็กทรอนิกส์',
      'icon': Icons.devices_other,
      'color': Colors.purple,
    },
  ];

  // ==========================================
  // 🌟 🌟 🌟 ส่วนจัดการข้อมูลโปรไฟล์ 🌟 🌟 🌟
  // ==========================================
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  List<String> _savedAddresses = [];
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData(); // ดึงข้อมูลโปรไฟล์มาเตรียมไว้ทันทีที่เปิดแอป
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- 1. ดึงข้อมูลจากตาราง profiles (ดึงมาเก็บไว้ล่วงหน้า) ---
  Future<void> _fetchProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      setState(() {
        _nameController.text = data['full_name'] ?? '';
        _phoneController.text = data['phone_number'] ?? '';
        if (data['saved_addresses'] != null) {
          _savedAddresses = List<String>.from(data['saved_addresses']);
        }
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ดึงข้อมูลโปรไฟล์ล้มเหลว: $e')));
      setState(() => _isLoadingProfile = false);
    }
  }

  // --- 2. บันทึกข้อมูลกลับไปที่ตาราง profiles ---
  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSavingProfile = true);

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'saved_addresses': _savedAddresses,
          })
          .eq('id', user.id);

      if (mounted) {
        Navigator.pop(context); // ปิดการ์ดตั้งค่า
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลโปรไฟล์สำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('บันทึกข้อมูลล้มเหลว: $e')));
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  // --- 3. Dialog สำหรับ เพิ่ม/แก้ไข ที่อยู่ (ลอยขึ้นมาซ้อนอีกที) ---
  Future<void> _showAddressDialog({int? index}) async {
    final isEditing = index != null;
    final addressController = TextEditingController(
      text: isEditing ? _savedAddresses[index] : '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'แก้ไขที่อยู่' : 'เพิ่มที่อยู่ใหม่'),
        content: TextField(
          controller: addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'กรอกที่อยู่ของคุณ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, addressController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (isEditing) {
          _savedAddresses[index] = result;
        } else {
          _savedAddresses.add(result);
        }
      });
    }
  }

  // --- 4. Dialog ยืนยันการลบที่อยู่ ---
  Future<void> _confirmDeleteAddress(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบที่อยู่นี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ลบ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _savedAddresses.removeAt(index);
      });
    }
  }

  // ==========================================
  // ✅ ✅ ✅ ฟังก์ชันพระเอก: การ์ดตั้งค่าโปรไฟล์ลอยๆ ✅ ✅ ✅
  // ==========================================
  void _showProfileSettingsBottomSheet() {
    // ถ้ายังโหลดข้อมูลไม่เสร็จ ไม่ให้เปิด (กันบั๊ก)
    if (_isLoadingProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังโหลดข้อมูลโปรไฟล์ กรุณารอสักครู่...'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // กำหนดให้ยืดความสูงได้
      builder: (context) {
        // ใช้ StatefulBuilder เพื่อให้หน้าจอการ์ดอัปเดตสถานะ (setState) ได้ในตัวเอง
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              // ดันการ์ดให้ลอยขึ้นมาจากขอบล่างของจอ
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 15,
                right: 15,
                top:
                    MediaQuery.of(context).padding.top +
                    30, // เว้นระยะขอบบนนิดนึง
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ให้ความสูงพอดีกับเนื้อหา
                  children: [
                    // 1. หัวข้อการ์ด พร้อมปุ่มปิด
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 15,
                        left: 15,
                        right: 10,
                        bottom: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ตั้งค่าโปรไฟล์และที่อยู่',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // 2. เนื้อหาการ์ดแบบเลื่อนได้ (จำเป็นเพราะฟอร์มยาว)
                    Flexible(
                      child: ListView(
                        shrinkWrap: true, // ให้ ListView สูงพอดีเนื้อหา
                        padding: const EdgeInsets.all(20),
                        children: [
                          // ----- ข้อมูลส่วนตัว -----
                          const Text(
                            'ข้อมูลส่วนตัว',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อ-นามสกุล',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'เบอร์โทรศัพท์',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),

                          const SizedBox(height: 25),
                          const Divider(),
                          const SizedBox(height: 10),

                          // ----- จัดการที่อยู่ -----
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ที่อยู่ที่บันทึกไว้',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await _showAddressDialog();
                                  // สำคัญ: ต้องสั่งให้การ์ดอัปเดตลิสต์ที่อยู่ (StatefulBuilder)
                                  modalSetState(() {});
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('เพิ่มที่อยู่'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_savedAddresses.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'ยังไม่มีที่อยู่ที่บันทึกไว้',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(), // ปิดการเลื่อนซ้อนกัน
                              itemCount: _savedAddresses.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  elevation: 0,
                                  color: Colors.grey.shade100,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.location_on,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    title: Text(
                                      _savedAddresses[index],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            await _showAddressDialog(
                                              index: index,
                                            );
                                            modalSetState(() {});
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            await _confirmDeleteAddress(index);
                                            modalSetState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 25),
                          const Divider(),
                          const SizedBox(height: 20),

                          // ----- ปุ่มออกจากระบบ (ย้ายมาอยู่ในการ์ดตั้งค่า) -----
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text('ออกจากระบบ'),
                            onPressed: () async {
                              Navigator.pop(context); // ปิดการ์ด
                              await Supabase.instance.client.auth.signOut();
                              if (mounted)
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // 3. ปุ่มบันทึกข้อมูล (ตรึงไว้ด้านล่างสุดของการ์ด)
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(55),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSavingProfile ? null : _saveProfile,
                        child: _isSavingProfile
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'บันทึกข้อมูลทั้งหมด',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกบริการ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed:
                _showProfileSettingsBottomSheet, // กดยิงฟังก์ชันการ์ดลอยๆ
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return InkWell(
            onTap: () {
              if (service['name'] == 'แอร์')
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AirBookingScreen(),
                  ),
                );
            },
            child: Card(
              color: service['color'].withOpacity(0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(service['icon'], size: 50, color: service['color']),
                  const SizedBox(height: 10),
                  Text(
                    service['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
