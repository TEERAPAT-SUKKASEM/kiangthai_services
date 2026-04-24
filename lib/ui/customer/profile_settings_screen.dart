import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../data/models/profile.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<String> _savedAddresses = [];
  bool _isLoading = true;
  bool _isSaving = false;

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

  Future<void> _fetchProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profile = Profile.fromMap(data);
      setState(() {
        _nameController.text = profile.fullName;
        _phoneController.text = profile.phoneNumber;
        _savedAddresses = List<String>.from(profile.savedAddresses);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'saved_addresses': _savedAddresses,
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showAddressDialog({int? index}) async {
    final isEditing = index != null;
    final addressController = TextEditingController(
      text: isEditing ? _savedAddresses[index] : '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
        content: TextField(
          controller: addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, addressController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
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

  Future<void> _confirmDeleteAddress(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Remove this address from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _savedAddresses.removeAt(index));
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    // main.dart's StreamBuilder handles navigation back to LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _SectionCard(
                  title: 'Personal Information',
                  icon: Icons.person_rounded,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Saved Addresses',
                  icon: Icons.bookmark_rounded,
                  trailing: TextButton.icon(
                    onPressed: _showAddressDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                  children: [
                    if (_savedAddresses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          children: [
                            Icon(Icons.location_off_outlined,
                                size: 32, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            Text(
                              'No saved addresses yet',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedAddresses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.tint(AppColors.brand, 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.brand,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                _savedAddresses[index],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    color: AppColors.textSecondary,
                                    onPressed: () =>
                                        _showAddressDialog(index: index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                    color: AppColors.rejected,
                                    onPressed: () =>
                                        _confirmDeleteAddress(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shadowColor: AppColors.brand.withValues(alpha: 0.45),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save All Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: BorderSide(color: AppColors.rejected.withValues(alpha: 0.5)),
                    foregroundColor: AppColors.rejected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  onPressed: _logout,
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.brand, 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.brand, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
