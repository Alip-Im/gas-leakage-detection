import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceRegistrationScreen extends StatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState
    extends State<DeviceRegistrationScreen> {
  final TextEditingController _deviceIdController =
      TextEditingController();

  final TextEditingController _deviceNameController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  bool _isSaving = false;

  // =========================================================
  // BLUE THEME
  // =========================================================

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);
  static const Color backgroundBlue = Color(0xFFF4FAFF);
  static const Color cardBorder = Color(0xFFD8EAF6);

  // =========================================================
  // REGISTER DEVICE
  // =========================================================

  Future<void> _registerDevice() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('You must be logged in to register a device.');
      return;
    }

    // Convert Device ID to uppercase.
    // Example: gld-001 becomes GLD-001.
    final String deviceId =
        _deviceIdController.text.trim().toUpperCase();

    final String deviceName =
        _deviceNameController.text.trim();

    // =======================================================
    // VALIDATION
    // =======================================================

    if (deviceId.isEmpty) {
      _showMessage('Please enter the Device ID.');
      return;
    }

    if (deviceName.isEmpty) {
      _showMessage('Please enter the Device Name.');
      return;
    }

    // Firebase keys cannot contain these characters.
    if (deviceId.contains('.') ||
        deviceId.contains('#') ||
        deviceId.contains('\$') ||
        deviceId.contains('[') ||
        deviceId.contains(']') ||
        deviceId.contains('/')) {
      _showMessage(
        'Device ID contains invalid characters.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // =====================================================
      // REFERENCES
      // =====================================================

      final DatabaseReference userRef =
          _database.ref('users/${user.uid}');

      final DatabaseReference userDeviceRef =
          userRef.child('devices/$deviceId');

      final DatabaseReference deviceRef =
          _database.ref('devices/$deviceId');

      // =====================================================
      // CHECK IF THIS USER ALREADY REGISTERED THE DEVICE
      // =====================================================

      final DataSnapshot existingUserDevice =
          await userDeviceRef.get();

      if (existingUserDevice.exists) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }

        _showMessage(
          'This device is already registered to your account.',
        );
        return;
      }

      // =====================================================
      // CREATE / CHECK MAIN DEVICE
      // =====================================================

      final DataSnapshot existingDevice =
          await deviceRef.get();

      if (!existingDevice.exists) {
        // Create the main device record.
        await deviceRef.set({
          'device_id': deviceId,
          'device_name': deviceName,
          'current_ppm': 0,
          'threshold': 1200,
          'fan_status': false,
          'buzzer_status': false,
          'online': false,
          'last_seen': 'N/A',
          'created_at':
              DateTime.now().toIso8601String(),
        });
      }

      // =====================================================
      // REGISTER DEVICE TO USER
      // =====================================================

      await userDeviceRef.set({
        'device_id': deviceId,
        'device_name': deviceName,
        'registered_at':
            DateTime.now().toIso8601String(),
      });

      // =====================================================
      // CHECK CURRENT SELECTED DEVICE
      // =====================================================

      final DataSnapshot selectedSnapshot =
          await userRef.child('selected_device').get();

      // If the user has no selected device yet,
      // automatically select the first registered device.
      if (!selectedSnapshot.exists ||
          selectedSnapshot.value == null ||
          selectedSnapshot.value
              .toString()
              .trim()
              .isEmpty) {
        await userRef.update({
          'selected_device': deviceId,
        });
      }

      // =====================================================
      // SUCCESS
      // =====================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$deviceName registered successfully.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to register device. Please try again.',
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
    if (!mounted) return;

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
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  // =========================================================
  // UI
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
          'Sign Up Your Device',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),
            child: Column(
              children: [
                // =================================================
                // HEADER
                // =================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        darkBlue,
                        steelBlue,
                        lightBlue,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.add_to_home_screen_rounded,
                        color: Colors.white,
                        size: 45,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'REGISTER YOUR DEVICE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Connect a Gas Leakage Detector to your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // DEVICE INFORMATION CARD
                // =================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: cardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Information',
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ===========================================
                      // DEVICE ID
                      // ===========================================

                      _field(
                        controller:
                            _deviceIdController,
                        label: 'Device ID',
                        hint: 'Example: GLD-001',
                        icon:
                            Icons.qr_code_rounded,
                      ),

                      const SizedBox(height: 15),

                      // ===========================================
                      // DEVICE NAME
                      // ===========================================

                      _field(
                        controller:
                            _deviceNameController,
                        label: 'Device Name',
                        hint:
                            'Example: Kitchen Detector',
                        icon:
                            Icons.sensors_rounded,
                      ),

                      const SizedBox(height: 14),

                      // ===========================================
                      // INFO
                      // ===========================================

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightBlue
                              .withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(
                            7,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons
                                  .info_outline_rounded,
                              color: steelBlue,
                              size: 18,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Enter the unique Device ID assigned to your Gas Leakage Detector. You can register multiple devices and choose which one to monitor from the Dashboard.',
                                style: TextStyle(
                                  color:
                                      Colors.blueGrey,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===========================================
                      // REGISTER BUTTON
                      // ===========================================

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : _registerDevice,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                steelBlue,
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                steelBlue
                                    .withOpacity(0.5),
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
                                  Icons
                                      .add_circle_outline_rounded,
                                ),
                          label: Text(
                            _isSaving
                                ? 'REGISTERING...'
                                : 'REGISTER DEVICE',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
  // TEXT FIELD
  // =========================================================

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: steelBlue,
        ),

        filled: true,
        fillColor: backgroundBlue,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: cardBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide: const BorderSide(
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
}