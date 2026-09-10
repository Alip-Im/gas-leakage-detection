import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() =>
      _UserProfileScreenState();
}

class _UserProfileScreenState
    extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final ref =
          FirebaseDatabase.instance.ref('users/${user.uid}');

      final snapshot = await ref.get();

      if (snapshot.exists && mounted) {
        final data =
            snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _nameController.text =
              data['full_name'] ?? '';

          _phoneController.text =
              data['phone_number'] ?? '';

          _addressController.text =
              data['address_line'] ?? '';

          _postcodeController.text =
              data['postcode'] ?? '';

          _cityController.text =
              data['city'] ?? '';

          _stateController.text =
              data['state'] ?? '';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _saveUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ref =
          FirebaseDatabase.instance.ref('users/${user.uid}');

      await ref.set({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address_line': _addressController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'updated_at':
            DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: _isFetching
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Colors.indigo,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          user?.email ?? 'No Email',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon:
                          Icon(Icons.person_outline),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _phoneController,
                    keyboardType:
                        TextInputType.phone,
                    decoration:
                        const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon:
                          Icon(Icons.phone),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Location & Address Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        _addressController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Street Address',
                      prefixIcon:
                          Icon(Icons.home),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              _postcodeController,
                          keyboardType:
                              TextInputType.number,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Postcode',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: TextField(
                          controller:
                              _cityController,
                          decoration:
                              const InputDecoration(
                            labelText: 'City',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        _stateController,
                    decoration:
                        const InputDecoration(
                      labelText: 'State',
                      prefixIcon:
                          Icon(Icons.map),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : _saveUserProfile,
                    icon: const Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    label: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'SAVE PROFILE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                    style:
                        ElevatedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(50),
                      backgroundColor:
                          Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () {
                      FirebaseAuth.instance
                          .signOut();
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'LOG OUT',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(50),
                      side: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}