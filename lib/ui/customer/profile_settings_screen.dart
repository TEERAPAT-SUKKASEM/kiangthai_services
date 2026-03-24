import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<String> _savedAddresses = []; // เก็บลิสต์ที่อยู่
  bool _isLoading = true; // สถานะตอนกำลังโหลดข้อมูลตอนเปิดหน้า
  bool _isSaving = false; // สถานะตอนกำลังกดปุ่มเซฟ

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. ดึงข้อมูลจากตาราง profiles
  // ==========================================
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
        _isLoading = false;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ดึงข้อมูลล้มเหลว: $e')));
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 2. บันทึกข้อมูลกลับไปที่ตาราง profiles
  // ==========================================
  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'saved_addresses':
                _savedAddresses, // โยนลิสต์ที่อยู่ทั้งก้อนกลับไปทับของเดิม
          })
          .eq('id', user.id);

      if (mounted) {
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==========================================
  // 3. กล่อง Dialog สำหรับ เพิ่ม/แก้ไข ที่อยู่
  // ==========================================
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
            hintText: 'กรอกที่อยู่ของคุณ (บ้านเลขที่, ซอย, ตำบล)',
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

    // ถ้าพิมพ์เสร็จแล้วกดตกลง
    if (result != null && result.isNotEmpty) {
      setState(() {
        if (isEditing) {
          _savedAddresses[index] = result; // แก้ไขของเดิม
        } else {
          _savedAddresses.add(result); // เพิ่มของใหม่
        }
      });
    }
  }

  // ==========================================
  // 4. กล่อง Dialog ยืนยันการลบที่อยู่
  // ==========================================
  Future<void> _confirmDeleteAddress(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบที่อยู่นี้ออกจากรายการใช่หรือไม่?'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่าโปรไฟล์')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ----- ส่วนที่ 1: ข้อมูลส่วนตัว -----
                const Text(
                  'ข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 15),
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

                const Divider(height: 40, thickness: 2),

                // ----- ส่วนที่ 2: จัดการที่อยู่ -----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ที่อยู่ที่บันทึกไว้',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blueAccent,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showAddressDialog(), // กดเพื่อเพิ่มที่อยู่ใหม่
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มที่อยู่'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // แสดงลิสต์ที่อยู่
                if (_savedAddresses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
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
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            _savedAddresses[index],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () => _showAddressDialog(
                                  index: index,
                                ), // กดเพื่อแก้ไข
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _confirmDeleteAddress(index), // กดเพื่อลบ
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 30),

                // ----- ปุ่มบันทึกข้อมูล -----
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(55),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'บันทึกข้อมูลทั้งหมด',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
