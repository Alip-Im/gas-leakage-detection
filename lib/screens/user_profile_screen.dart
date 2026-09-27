import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final TextEditingController _fullNameController =
      TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController();
  final TextEditingController _addressController =
      TextEditingController();
  final TextEditingController _postcodeController =
      TextEditingController();
  final TextEditingController _cityController =
      TextEditingController();
  final TextEditingController _stateController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  static const Color darkGreen = Color(0xFF0B261B);
  static const Color mediumGreen = Color(0xFF174C36);
  static const Color mainGreen = Color(0xFF216B4A);
  static const Color backgroundGreen = Color(0xFFD6E1DB);
  static const Color cardGreen = Color(0xFFE3EBE6);
  static const Color borderGreen = Color(0xFF9FAFA5);
  static const Color mutedGreen = Color(0xFFC4D2CA);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await _database
          .ref('users/${user.uid}')
          .get();

      if (snapshot.exists && snapshot.value is Map) {
        final data =
            Map<dynamic, dynamic>.from(snapshot.value as Map);

        _fullNameController.text =
            data['full_name']?.toString() ?? '';

        _phoneController.text =
            data['phone_number']?.toString() ?? '';

        _addressController.text =
            data['address_line']?.toString() ?? '';

        _postcodeController.text =
            data['postcode']?.toString() ?? '';

        _cityController.text =
            data['city']?.toString() ?? '';

        _stateController.text =
            data['state']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load profile information.'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _database.ref('users/${user.uid}').update({
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address_line': _addressController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update profile.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: backgroundGreen,

      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: mediumGreen,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // PROFILE SUMMARY
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: mutedGreen,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: borderGreen,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: darkGreen,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fullNameController.text.trim().isEmpty
                                    ? 'User Profile'
                                    : _fullNameController.text.trim(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: darkGreen,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                user?.email ?? 'No email available',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4F5C55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PERSONAL INFORMATION SECTION
                  _buildSection(
                    title: 'Personal Information',
                    children: [
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ADDRESS SECTION
                  _buildSection(
                    title: 'Location & Address',
                    children: [
                      _buildTextField(
                        controller: _addressController,
                        label: 'Street Address',
                        icon: Icons.home_outlined,
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _postcodeController,
                              label: 'Postcode',
                              icon: Icons.pin_drop_outlined,
                              keyboardType:
                                  TextInputType.number,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              icon: Icons.location_city_outlined,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _stateController,
                        label: 'State',
                        icon: Icons.map_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mediumGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.save_outlined,
                            ),
                      label: Text(
                        _isSaving
                            ? 'SAVING...'
                            : 'SAVE CHANGES',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(0xFF8A2924),
                        side: const BorderSide(
                          color: Color(0xFF8A2924),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      icon: const Icon(
                        Icons.logout_rounded,
                      ),
                      label: const Text(
                        'LOG OUT',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderGreen,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: darkGreen,
            ),
          ),

          const SizedBox(height: 14),

          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF1D2923),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,

        labelStyle: const TextStyle(
          color: Color(0xFF56635C),
        ),

        prefixIcon: Icon(
          icon,
          color: mediumGreen,
          size: 21,
        ),

        filled: true,
        fillColor: const Color(0xFFD8E2DC),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: borderGreen,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: borderGreen,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: mediumGreen,
            width: 1.7,
          ),
        ),
      ),
    );
  }
}