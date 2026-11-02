import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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

  String? _selectedState;
  String? _selectedCity;

  bool _isLoading = true;
  bool _isSaving = false;

  // =========================================================
  // COLORS
  // =========================================================

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);
  static const Color backgroundBlue = Color(0xFFF4FAFF);
  static const Color cardBorder = Color(0xFFD8EAF6);

  // =========================================================
  // MALAYSIA STATES & CITIES
  // =========================================================

  final Map<String, List<String>> _stateCities = {
    'Johor': [
      'Johor Bahru',
      'Batu Pahat',
      'Kluang',
      'Kota Tinggi',
      'Mersing',
      'Muar',
      'Pontian',
      'Segamat',
    ],
    'Kedah': [
      'Alor Setar',
      'Baling',
      'Jitra',
      'Kulim',
      'Langkawi',
      'Sungai Petani',
    ],
    'Kelantan': [
      'Kota Bharu',
      'Gua Musang',
      'Kuala Krai',
      'Machang',
      'Pasir Mas',
      'Tanah Merah',
      'Tumpat',
    ],
    'Melaka': [
      'Alor Gajah',
      'Jasin',
      'Melaka City',
    ],
    'Negeri Sembilan': [
      'Seremban',
      'Port Dickson',
      'Nilai',
      'Kuala Pilah',
      'Bahau',
    ],
    'Pahang': [
      'Kuantan',
      'Bentong',
      'Cameron Highlands',
      'Jerantut',
      'Pekan',
      'Raub',
      'Temerloh',
    ],
    'Penang': [
      'George Town',
      'Bayan Lepas',
      'Butterworth',
      'Bukit Mertajam',
      'Seberang Perai',
    ],
    'Perak': [
      'Ipoh',
      'Batu Gajah',
      'Kampar',
      'Kuala Kangsar',
      'Lumut',
      'Sitiawan',
      'Taiping',
      'Teluk Intan',
    ],
    'Perlis': [
      'Kangar',
      'Arau',
      'Kuala Perlis',
    ],
    'Sabah': [
      'Kota Kinabalu',
      'Keningau',
      'Kudat',
      'Lahad Datu',
      'Sandakan',
      'Semporna',
      'Tawau',
    ],
    'Sarawak': [
      'Kuching',
      'Bintulu',
      'Kapit',
      'Miri',
      'Sibu',
      'Sri Aman',
    ],
    'Selangor': [
      'Ampang',
      'Bangi',
      'Cyberjaya',
      'Kajang',
      'Klang',
      'Petaling Jaya',
      'Puchong',
      'Rawang',
      'Sepang',
      'Shah Alam',
      'Subang Jaya',
    ],
    'Terengganu': [
      'Kuala Terengganu',
      'Besut',
      'Dungun',
      'Kemaman',
      'Marang',
    ],
    'Kuala Lumpur': [
      'Kuala Lumpur',
    ],
    'Putrajaya': [
      'Putrajaya',
    ],
    'Labuan': [
      'Labuan',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // =========================================================
  // LOAD PROFILE FROM FIREBASE
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

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(
          snapshot.value as Map,
        );

        _fullNameController.text =
            data['full_name']?.toString() ?? '';

        _phoneController.text =
            data['phone_number']?.toString() ?? '';

        _addressController.text =
            data['address_line']?.toString() ?? '';

        _postcodeController.text =
            data['postcode']?.toString() ?? '';

        final savedState =
            data['state']?.toString();

        final savedCity =
            data['city']?.toString();

        // Load existing state if valid
        if (savedState != null &&
            _stateCities.containsKey(savedState)) {
          _selectedState = savedState;

          // Load existing city if it belongs to that state
          if (savedCity != null &&
              _stateCities[savedState]!.contains(savedCity)) {
            _selectedCity = savedCity;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load profile.',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    if (_fullNameController.text.trim().isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Please enter your phone number.');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showMessage('Please enter your street address.');
      return;
    }

    if (_selectedState == null) {
      _showMessage('Please select your state.');
      return;
    }

    if (_selectedCity == null) {
      _showMessage('Please select your city.');
      return;
    }

    if (_postcodeController.text.trim().isEmpty) {
      _showMessage('Please enter your postcode.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _database
          .ref('users/${user.uid}')
          .update({
        'full_name':
            _fullNameController.text.trim(),
        'phone_number':
            _phoneController.text.trim(),
        'address_line':
            _addressController.text.trim(),
        'postcode':
            _postcodeController.text.trim(),
        'state': _selectedState,
        'city': _selectedCity,
        'updated_at':
            DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Return TRUE to Profile page.
      // Profile page can use this to reload the new data.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to update profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: darkBlue,
            fontSize: 19,
            fontWeight: FontWeight.w800,
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
                20,
                18,
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 700,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // =====================================
                      // PERSONAL INFORMATION
                      // =====================================

                      _section(
                        title: 'Personal Information',
                        children: [
                          _textField(
                            controller:
                                _fullNameController,
                            label: 'Full Name',
                            icon:
                                Icons.person_outline_rounded,
                          ),

                          const SizedBox(height: 14),

                          _textField(
                            controller:
                                _phoneController,
                            label: 'Phone Number',
                            icon:
                                Icons.phone_outlined,
                            keyboardType:
                                TextInputType.phone,
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // =====================================
                      // LOCATION & ADDRESS
                      // =====================================

                      _section(
                        title: 'Location & Address',
                        children: [
                          // STREET ADDRESS
                          _textField(
                            controller:
                                _addressController,
                            label: 'Street Address',
                            icon:
                                Icons.home_outlined,
                          ),

                          const SizedBox(height: 14),

                          // =================================
                          // STATE DROPDOWN
                          // =================================

                          _dropdownField(
                            label: 'State',
                            hint: 'Select State',
                            icon: Icons.map_outlined,
                            value: _selectedState,
                            items:
                                _stateCities.keys.toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value;

                                // Clear city whenever
                                // state changes.
                                _selectedCity = null;
                              });
                            },
                          ),

                          const SizedBox(height: 14),

                          // =================================
                          // CITY DROPDOWN
                          // =================================

                          _dropdownField(
                            label: 'City',
                            hint: _selectedState == null
                                ? 'Select State First'
                                : 'Select City',
                            icon: Icons
                                .location_city_outlined,
                            value: _selectedCity,
                            items: _selectedState == null
                                ? []
                                : _stateCities[
                                    _selectedState]!,
                            onChanged: _selectedState == null
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedCity =
                                          value;
                                    });
                                  },
                          ),

                          const SizedBox(height: 14),

                          // =================================
                          // POSTCODE
                          // =================================

                          _textField(
                            controller:
                                _postcodeController,
                            label: 'Postcode',
                            icon:
                                Icons.pin_drop_outlined,
                            keyboardType:
                                TextInputType.number,
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // =====================================
                      // SAVE BUTTON
                      // =====================================

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : _saveProfile,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                steelBlue,
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                steelBlue.withOpacity(
                              0.5,
                            ),
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                8,
                              ),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                  size: 20,
                                ),
                          label: Text(
                            _isSaving
                                ? 'SAVING...'
                                : 'SAVE CHANGES',
                            style:
                                const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
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
  // SECTION
  // =========================================================

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 18),

          ...children,
        ],
      ),
    );
  }

  // =========================================================
  // NORMAL TEXT FIELD
  // =========================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          icon,
          color: steelBlue,
        ),

        filled: true,
        fillColor: backgroundBlue,

        labelStyle: const TextStyle(
          color: Color(0xFF52606D),
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide:
              const BorderSide(
            color: cardBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide:
              const BorderSide(
            color: cardBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: steelBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DROPDOWN FIELD
  // =========================================================

  Widget _dropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,

      isExpanded: true,

      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: steelBlue,
      ),

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          icon,
          color: steelBlue,
        ),

        filled: true,
        fillColor: backgroundBlue,

        labelStyle: const TextStyle(
          color: Color(0xFF52606D),
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide:
              const BorderSide(
            color: cardBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide:
              const BorderSide(
            color: cardBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: steelBlue,
            width: 1.5,
          ),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.blueGrey.shade100,
          ),
        ),
      ),

      hint: Text(
        hint,
        style: TextStyle(
          color: Colors.blueGrey.shade400,
        ),
      ),

      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow:
                TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: onChanged,
    );
  }
}