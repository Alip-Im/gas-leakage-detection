import 'contact_us_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'edit_profile_screen.dart';
import 'device_registration_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() =>
      _UserProfileScreenState();
}

class _UserProfileScreenState
    extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database =
      FirebaseDatabase.instance;

  String _fullName = '';
  String _phoneNumber = '';
  String _city = '';
  String _state = '';

  bool _isLoading = true;

  // =========================================================
  // BLUE THEME
  // =========================================================

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);
  static const Color backgroundBlue = Color(0xFFF4FAFF);
  static const Color cardBorder = Color(0xFFD8EAF6);
  static const Color dangerRed = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

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
      final snapshot =
          await _database.ref('users/${user.uid}').get();

      if (snapshot.exists &&
          snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(
          snapshot.value as Map,
        );

        if (mounted) {
          setState(() {
            _fullName =
                data['full_name']?.toString() ?? '';

            _phoneNumber =
                data['phone_number']?.toString() ?? '';

            _city =
                data['city']?.toString() ?? '';

            _state =
                data['state']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load profile information.',
            ),
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

  // =========================================================
  // OPEN EDIT PROFILE
  // =========================================================

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EditProfileScreen(),
      ),
    );

    // If Save Changes was successful,
    // reload profile from Firebase.
    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      await _loadProfile();
    }
  }

  // =========================================================
  // OPEN DEVICE REGISTRATION
  // =========================================================

  Future<void> _openDeviceRegistration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const DeviceRegistrationScreen(),
      ),
    );
  }

  // =========================================================
// OPEN CONTACT US
// =========================================================

Future<void> _openContactUs() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          const ContactUsScreen(),
    ),
  );
}

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _confirmLogout() async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: dangerRed,
              ),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(
              color: Colors.blueGrey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: steelBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(7),
                ),
              ),
              child: const Text(
                'LOG OUT',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _auth.signOut();
    }
  }

  // =========================================================
  // BUILD PAGE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: backgroundBlue,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: darkBlue,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: steelBlue,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                18,
                25,
                18,
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 700,
                  ),
                  child: Column(
                    children: [
                      // =====================================
                      // PROFILE HEADER
                      // =====================================

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              const LinearGradient(
                            begin:
                                Alignment.topLeft,
                            end:
                                Alignment.bottomRight,
                            colors: [
                              darkBlue,
                              steelBlue,
                              lightBlue,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: steelBlue
                                  .withOpacity(0.18),
                              blurRadius: 14,
                              offset:
                                  const Offset(
                                0,
                                5,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // PROFILE ICON
                            Container(
                              width: 88,
                              height: 88,
                              decoration:
                                  BoxDecoration(
                                color: Colors.white,
                                shape:
                                    BoxShape.circle,
                                border:
                                    Border.all(
                                  color: Colors.white
                                      .withOpacity(
                                    0.7,
                                  ),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons
                                    .person_rounded,
                                color: steelBlue,
                                size: 50,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // NAME
                            Text(
                              _fullName
                                      .trim()
                                      .isEmpty
                                  ? 'User'
                                  : _fullName,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            // EMAIL
                            Text(
                              user?.email ??
                                  'No email available',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 12,
                              ),
                            ),

                            // LOCATION
                            if (_city.isNotEmpty ||
                                _state.isNotEmpty) ...[
                              const SizedBox(
                                height: 12,
                              ),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .white
                                      .withOpacity(
                                    0.14,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,
                                  children: [
                                    const Icon(
                                      Icons
                                          .location_on_outlined,
                                      color: Colors
                                          .white,
                                      size: 15,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      _locationText(),
                                      style:
                                          const TextStyle(
                                        color: Colors
                                            .white,
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // =====================================
                      // ACCOUNT TITLE
                      // =====================================

                      const Align(
                        alignment:
                            Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .manage_accounts_outlined,
                              color: steelBlue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Account',
                              style: TextStyle(
                                color: darkBlue,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // =====================================
                      // ACCOUNT MENU
                      // =====================================

                      _menuCard(
                        children: [
                          _menuItem(
                            icon: Icons
                                .person_outline_rounded,
                            title:
                                'Edit Profile',
                            subtitle:
                                'Update your personal information',
                            onTap:
                                _openEditProfile,
                          ),

                          _divider(),

                          _menuItem(
                            icon: Icons
                                .add_to_home_screen_rounded,
                            title:
                                'Sign Up Your Device',
                            subtitle:
                                'Register your Gas Leakage Detector',
                            onTap:
                                _openDeviceRegistration,
                          ),
                        ],
                      ),

                      _divider(),

                      _menuItem(
                      icon: Icons.support_agent_outlined,
                      title: 'Contact Us',
                      subtitle: 'Get help or report an issue',
                    onTap: _openContactUs,
                    ),

                      const SizedBox(height: 20),

                      // =====================================
                      // LOGOUT CARD
                      // =====================================

                      _menuCard(
                        children: [
                          _menuItem(
                            icon:
                                Icons.logout_rounded,
                            title: 'Logout',
                            subtitle:
                                'Sign out from this account',
                            iconColor:
                                dangerRed,
                            titleColor:
                                dangerRed,
                            onTap:
                                _confirmLogout,
                          ),
                        ],
                      ),

                      const SizedBox(height: 35),

                      // =====================================
                      // APP INFORMATION
                      // =====================================

                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: lightBlue
                              .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          color: steelBlue,
                          size: 27,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Gas Leakage Detector',
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Version 1.0',
                        style: TextStyle(
                          color: Colors
                              .blueGrey.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // =========================================================
  // LOCATION TEXT
  // =========================================================

  String _locationText() {
    if (_city.isNotEmpty &&
        _state.isNotEmpty) {
      return '$_city, $_state';
    }

    if (_city.isNotEmpty) {
      return _city;
    }

    if (_state.isNotEmpty) {
      return _state;
    }

    return '';
  }

  // =========================================================
  // MENU CARD
  // =========================================================

  Widget _menuCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // =========================================================
  // MENU ITEM
  // =========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = steelBlue,
    Color titleColor = darkBlue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(10),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        child: Row(
          children: [
            // ICON BOX
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color:
                    iconColor.withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 21,
              ),
            ),

            const SizedBox(width: 14),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors
                          .blueGrey.shade400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // ARROW
            Icon(
              Icons.chevron_right_rounded,
              color:
                  Colors.blueGrey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DIVIDER
  // =========================================================

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 73,
      color: Colors.blueGrey.shade50,
    );
  }
}