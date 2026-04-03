import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _filter = 'ทั้งหมด';

  Future<void> _changeRole(Profile profile) async {
    final roles = ['customer', 'technician', 'admin'];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('เปลี่ยน role ของ ${profile.fullName}'),
        children: roles.map((role) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, role),
            child: Text(role, style: const TextStyle(fontSize: 16)),
          );
        }).toList(),
      ),
    );
    if (selected == null || selected == profile.role) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'role': selected})
        .eq('id', profile.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยน role เป็น $selected แล้ว')),
      );
    }
  }

  Color _roleColor(String role) => switch (role) {
    'technician' => Colors.orange,
    'admin' => Colors.red,
    _ => Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ผู้ใช้ทั้งหมด')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['ทั้งหมด', 'customer', 'technician', 'admin']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor:
                              Colors.blueAccent.withValues(alpha: 0.2),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('profiles')
                  .stream(primaryKey: ['id'])
                  .order('full_name', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final raw = snapshot.data ?? [];
                final filtered = _filter == 'ทั้งหมด'
                    ? raw
                    : raw.where((p) => p['role'] == _filter).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('ไม่มีผู้ใช้'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final profile = Profile.fromMap(filtered[index]);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _roleColor(profile.role)
                              .withValues(alpha: 0.15),
                          child: Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: _roleColor(profile.role),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : 'ไม่ระบุชื่อ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(profile.phoneNumber.isNotEmpty
                            ? profile.phoneNumber
                            : 'ไม่ระบุเบอร์'),
                        trailing: GestureDetector(
                          onTap: () => _changeRole(profile),
                          child: Chip(
                            label: Text(
                              profile.role,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _roleColor(profile.role),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
