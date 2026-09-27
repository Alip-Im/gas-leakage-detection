import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  StreamSubscription<DatabaseEvent>? _selectedDeviceSubscription;
  StreamSubscription<DatabaseEvent>? _deviceSubscription;
  StreamSubscription<DatabaseEvent>? _settingsSubscription;

  String? _selectedDeviceId;
  String _selectedDeviceName = 'No Device Selected';

  bool _loadingDevice = true;

  int _threshold = 1200;

  bool _buzzerEnabled = true;
  bool _gasNotifications = true;
  bool _fanNotifications = true;
  bool _offlineNotifications = true;

  bool _hardwareOnline = false;
  bool _fanOn = false;
  bool _buzzerOn = false;

  String _lastSeen = 'N/A';

  bool _testingBuzzer = false;

  // =========================================================
  // BLUE APP THEME
  // =========================================================

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);
  static const Color backgroundBlue = Color(0xFFF4FAFF);
  static const Color cardBorder = Color(0xFFD8EAF6);

  static const Color successGreen = Color(0xFF2E7D32);
  static const Color dangerRed = Color(0xFFC62828);

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _listenToSelectedDevice();
  }

  // =========================================================
  // SELECTED DEVICE LISTENER
  // =========================================================

  void _listenToSelectedDevice() {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _loadingDevice = false;
      });
      return;
    }

    final ref = _database.ref(
      'users/${user.uid}/selected_device',
    );

    _selectedDeviceSubscription =
        ref.onValue.listen((event) async {
      final String? deviceId =
          event.snapshot.value?.toString();

      if (deviceId == null ||
          deviceId.trim().isEmpty) {
        await _deviceSubscription?.cancel();
        await _settingsSubscription?.cancel();

        if (!mounted) return;

        setState(() {
          _selectedDeviceId = null;
          _selectedDeviceName =
              'No Device Selected';
          _loadingDevice = false;

          _threshold = 1200;
          _hardwareOnline = false;
          _fanOn = false;
          _buzzerOn = false;
          _lastSeen = 'N/A';
        });

        return;
      }

      await _changeDevice(deviceId);
    });
  }

  // =========================================================
  // CHANGE DEVICE
  // =========================================================

  Future<void> _changeDevice(
    String deviceId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _deviceSubscription?.cancel();
    await _settingsSubscription?.cancel();

    String deviceName = deviceId;

    try {
      final snapshot = await _database
          .ref(
            'users/${user.uid}/devices/$deviceId',
          )
          .get();

      if (snapshot.exists &&
          snapshot.value is Map) {
        final data =
            Map<dynamic, dynamic>.from(
          snapshot.value as Map,
        );

        deviceName =
            data['device_name']?.toString() ??
                deviceId;
      } else {
        final mainSnapshot = await _database
            .ref('devices/$deviceId')
            .get();

        if (mainSnapshot.exists &&
            mainSnapshot.value is Map) {
          final data =
              Map<dynamic, dynamic>.from(
            mainSnapshot.value as Map,
          );

          deviceName =
              data['device_name']?.toString() ??
                  deviceId;
        }
      }
    } catch (_) {
      deviceName = deviceId;
    }

    if (!mounted) return;

    setState(() {
      _selectedDeviceId = deviceId;
      _selectedDeviceName = deviceName;
      _loadingDevice = false;

      _threshold = 1200;
      _hardwareOnline = false;
      _fanOn = false;
      _buzzerOn = false;
      _lastSeen = 'N/A';

      _buzzerEnabled = true;
      _gasNotifications = true;
      _fanNotifications = true;
      _offlineNotifications = true;
    });

    _listenToDevice(deviceId);
    _listenToDeviceSettings(deviceId);
  }

  // =========================================================
  // DEVICE DATA LISTENER
  // =========================================================

  void _listenToDevice(String deviceId) {
    final ref =
        _database.ref('devices/$deviceId');

    _deviceSubscription =
        ref.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;

      if (data is! Map) return;

      final map =
          Map<dynamic, dynamic>.from(data);

      final int newThreshold = _toInt(
        map['threshold'] ??
            map['threshold_limit'],
      );

      final bool newHardwareOnline =
          _toBool(
        map['online'] ??
            map['is_online'] ??
            map['hardware_status'],
      );

      final bool newFanOn = _toBool(
        map['fan_status'] ?? map['fan'],
      );

      final bool newBuzzerOn = _toBool(
        map['buzzer_status'] ??
            map['buzzer'],
      );

      final dynamic lastSeen =
          map['last_seen'] ??
              map['lastseen'] ??
              map['last_update'];

      setState(() {
        if (newThreshold > 0) {
          _threshold = newThreshold;
        }

        _hardwareOnline =
            newHardwareOnline;

        _fanOn = newFanOn;
        _buzzerOn = newBuzzerOn;

        if (lastSeen != null) {
          _lastSeen =
              lastSeen.toString();
        }
      });
    });
  }

  // =========================================================
  // DEVICE-SPECIFIC SETTINGS
  // =========================================================

  void _listenToDeviceSettings(
    String deviceId,
  ) {
    final user = _auth.currentUser;

    if (user == null) return;

    final ref = _database.ref(
      'users/${user.uid}/device_settings/$deviceId',
    );

    _settingsSubscription =
        ref.onValue.listen((event) async {
      if (!mounted) return;

      final data = event.snapshot.value;

      // First time this device has no
      // settings: create defaults.
      if (data == null) {
        await ref.set({
          'buzzer_enabled': true,
          'gas_notifications': true,
          'fan_notifications': true,
          'offline_notifications': true,
        });

        return;
      }

      if (data is Map) {
        final map =
            Map<dynamic, dynamic>.from(
          data,
        );

        setState(() {
          _buzzerEnabled =
              _toBoolWithDefault(
            map['buzzer_enabled'],
            true,
          );

          _gasNotifications =
              _toBoolWithDefault(
            map['gas_notifications'],
            true,
          );

          _fanNotifications =
              _toBoolWithDefault(
            map['fan_notifications'],
            true,
          );

          _offlineNotifications =
              _toBoolWithDefault(
            map['offline_notifications'],
            true,
          );
        });
      }
    });
  }

  // =========================================================
  // CONVERTERS
  // =========================================================

  int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is double) {
      return value.round();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final text =
          value.toLowerCase();

      return text == 'true' ||
          text == 'on' ||
          text == '1';
    }

    return false;
  }

  bool _toBoolWithDefault(
    dynamic value,
    bool defaultValue,
  ) {
    if (value == null) {
      return defaultValue;
    }

    return _toBool(value);
  }

  // =========================================================
  // UPDATE DEVICE SETTING
  // =========================================================

  Future<void> _updateSetting(
    String key,
    bool value,
  ) async {
    final user = _auth.currentUser;

    if (user == null ||
        _selectedDeviceId == null) {
      return;
    }

    try {
      await _database
          .ref(
            'users/${user.uid}/device_settings/$_selectedDeviceId',
          )
          .update({
        key: value,
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to update setting.',
      );
    }
  }

  // =========================================================
  // TEST BUZZER
  // =========================================================

  Future<void> _testBuzzer() async {
    if (_testingBuzzer) return;

    if (_selectedDeviceId == null) {
      _showMessage(
        'No monitoring device selected.',
      );
      return;
    }

    if (!_buzzerEnabled) {
      _showMessage(
        'Enable the buzzer before testing it.',
      );
      return;
    }

    setState(() {
      _testingBuzzer = true;
    });

    final ref = _database.ref(
      'devices/$_selectedDeviceId',
    );

    try {
      await ref.update({
        'buzzer_status': true,
      });

      if (mounted) {
        _showMessage(
          'Buzzer test started for $_selectedDeviceName.',
        );
      }

      await Future.delayed(
        const Duration(seconds: 2),
      );

      await ref.update({
        'buzzer_status': false,
      });
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to test buzzer.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _testingBuzzer = false;
        });
      }
    }
  }

  // =========================================================
  // CLEAR SELECTED DEVICE HISTORY
  // =========================================================

  Future<void> _clearHistory() async {
    if (_selectedDeviceId == null) {
      _showMessage(
        'No monitoring device selected.',
      );
      return;
    }

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
                Icons.delete_outline_rounded,
                color: dangerRed,
              ),
              SizedBox(width: 10),
              Text(
                'Clear History',
                style: TextStyle(
                  color: darkBlue,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete all gas leakage history for $_selectedDeviceName?\n\n'
            'This action cannot be undone.',
            style: const TextStyle(
              color: Color(0xFF607D8B),
              height: 1.5,
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
                  fontWeight:
                      FontWeight.w700,
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
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    dangerRed,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'DELETE',
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _database
            .ref(
              'device_history/$_selectedDeviceId',
            )
            .remove();

        if (!mounted) return;

        _showMessage(
          '$_selectedDeviceName history cleared.',
        );
      } catch (e) {
        if (!mounted) return;

        _showMessage(
          'Unable to clear history.',
        );
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        duration:
            const Duration(seconds: 2),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _selectedDeviceSubscription?.cancel();
    _deviceSubscription?.cancel();
    _settingsSubscription?.cancel();

    super.dispose();
  }

  // =========================================================
  // PAGE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: TextStyle(
                color: darkBlue,
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage monitoring and safety preferences',
              style: TextStyle(
                color: steelBlue,
                fontSize: 11,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],
        ),
      ),

      body: _loadingDevice
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: steelBlue,
              ),
            )
          : _selectedDeviceId == null
              ? _buildNoDevice()
              : _buildSettingsContent(),
    );
  }

  // =========================================================
  // SETTINGS CONTENT
  // =========================================================

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        30,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 900,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =================================================
              // HEADER
              // =================================================

              _buildHeaderBanner(),

              const SizedBox(height: 18),

              // =================================================
              // CURRENT DEVICE
              // =================================================

              _selectedDeviceCard(),

              const SizedBox(height: 28),

              // =================================================
              // SAFETY CONFIGURATION
              // =================================================

              _sectionHeader(
                'Safety Configuration',
                Icons.shield_outlined,
              ),

              const SizedBox(height: 12),

              _card(
                children: [
                  _informationRow(
                    icon:
                        Icons.speed_rounded,
                    title:
                        'Danger Threshold',
                    subtitle:
                        'System-defined LPG safety limit',
                    value:
                        '$_threshold PPM',
                    trailingIcon: Icons
                        .lock_outline_rounded,
                  ),

                  _divider(),

                  _informationRow(
                    icon: Icons
                        .warning_amber_rounded,
                    title:
                        'Warning Level',
                    subtitle:
                        'Warning begins at 70% of danger limit',
                    value:
                        '${(_threshold * 0.7).round()} PPM',
                    trailingIcon: Icons
                        .lock_outline_rounded,
                  ),

                  _divider(),

                  _informationRow(
                    icon:
                        Icons.sensors_rounded,
                    title: 'Gas Sensor',
                    subtitle:
                        'LPG gas detection sensor',
                    value: 'MQ-6',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _infoMessage(
                'Safety limits are managed by the system and '
                'cannot be changed by the user.',
              ),

              const SizedBox(height: 28),

              // =================================================
              // BUZZER
              // =================================================

              _sectionHeader(
                'Buzzer Control',
                Icons
                    .notifications_active_outlined,
              ),

              const SizedBox(height: 12),

              _card(
                children: [
                  _switchRow(
                    icon: Icons
                        .volume_up_outlined,
                    title:
                        'Enable Buzzer',
                    subtitle:
                        'Allow audible alerts during gas danger',
                    value:
                        _buzzerEnabled,
                    onChanged: (value) {
                      setState(() {
                        _buzzerEnabled =
                            value;
                      });

                      _updateSetting(
                        'buzzer_enabled',
                        value,
                      );
                    },
                  ),

                  _divider(),

                  _informationRow(
                    icon: _buzzerOn
                        ? Icons
                            .notifications_active_rounded
                        : Icons
                            .notifications_none_rounded,
                    title:
                        'Current Status',
                    subtitle:
                        'Current hardware buzzer state',
                    value: _buzzerOn
                        ? 'ON'
                        : 'OFF',
                    valueColor: _buzzerOn
                        ? dangerRed
                        : Colors
                            .blueGrey,
                  ),

                  _divider(),

                  Padding(
                    padding:
                        const EdgeInsets
                            .all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Test Buzzer',
                                style:
                                    TextStyle(
                                  color:
                                      darkBlue,
                                  fontSize:
                                      13,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Activate the buzzer briefly to test the selected device',
                                style:
                                    TextStyle(
                                  color: Colors
                                      .blueGrey,
                                  fontSize:
                                      10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          width: 15,
                        ),

                        OutlinedButton.icon(
                          onPressed:
                              _testingBuzzer
                                  ? null
                                  : _testBuzzer,
                          style: OutlinedButton
                              .styleFrom(
                            foregroundColor:
                                steelBlue,
                            side:
                                const BorderSide(
                              color:
                                  steelBlue,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                7,
                              ),
                            ),
                          ),
                          icon: _testingBuzzer
                              ? const SizedBox(
                                  width: 14,
                                  height:
                                      14,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        steelBlue,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .play_arrow_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _testingBuzzer
                                ? 'TESTING'
                                : 'TEST',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w700,
                              fontSize:
                                  11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // =================================================
              // NOTIFICATIONS
              // =================================================

              _sectionHeader(
                'Notifications',
                Icons
                    .notifications_outlined,
              ),

              const SizedBox(height: 12),

              _card(
                children: [
                  _switchRow(
                    icon: Icons
                        .warning_amber_rounded,
                    title:
                        'Gas Leakage Alerts',
                    subtitle:
                        'Receive alerts when dangerous gas is detected',
                    value:
                        _gasNotifications,
                    onChanged: (value) {
                      setState(() {
                        _gasNotifications =
                            value;
                      });

                      _updateSetting(
                        'gas_notifications',
                        value,
                      );
                    },
                  ),

                  _divider(),

                  _switchRow(
                    icon:
                        Icons.air_rounded,
                    title:
                        'Fan Activation Alerts',
                    subtitle:
                        'Receive updates when the exhaust fan changes',
                    value:
                        _fanNotifications,
                    onChanged: (value) {
                      setState(() {
                        _fanNotifications =
                            value;
                      });

                      _updateSetting(
                        'fan_notifications',
                        value,
                      );
                    },
                  ),

                  _divider(),

                  _switchRow(
                    icon: Icons
                        .wifi_off_rounded,
                    title:
                        'Hardware Offline Alerts',
                    subtitle:
                        'Receive alerts if the monitoring device goes offline',
                    value:
                        _offlineNotifications,
                    onChanged: (value) {
                      setState(() {
                        _offlineNotifications =
                            value;
                      });

                      _updateSetting(
                        'offline_notifications',
                        value,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _infoMessage(
                'Notification preferences shown here apply only to $_selectedDeviceName.',
              ),

              const SizedBox(height: 28),

              // =================================================
              // DEVICE & CONNECTION
              // =================================================

              _sectionHeader(
                'Device & Connection',
                Icons.memory_rounded,
              ),

              const SizedBox(height: 12),

              _card(
                children: [
                  _informationRow(
                    icon: Icons
                        .sensors_rounded,
                    title: 'Device',
                    subtitle:
                        'Currently selected monitoring device',
                    value:
                        _selectedDeviceName,
                  ),

                  _divider(),

                  _informationRow(
                    icon:
                        Icons.qr_code_rounded,
                    title: 'Device ID',
                    subtitle:
                        'Unique detector identifier',
                    value:
                        _selectedDeviceId ??
                            'N/A',
                  ),

                  _divider(),

                  _informationRow(
                    icon: Icons
                        .developer_board_rounded,
                    title: 'ESP32',
                    subtitle:
                        'Gas monitoring controller',
                    value:
                        _hardwareOnline
                            ? 'ONLINE'
                            : 'OFFLINE',
                    valueColor:
                        _hardwareOnline
                            ? successGreen
                            : dangerRed,
                  ),

                  _divider(),

                  _informationRow(
                    icon: Icons
                        .cloud_done_outlined,
                    title: 'Firebase',
                    subtitle:
                        'Realtime Database connection',
                    value: 'CONNECTED',
                    valueColor:
                        successGreen,
                  ),

                  _divider(),

                  _informationRow(
                    icon:
                        Icons.air_rounded,
                    title:
                        'Exhaust Fan',
                    subtitle:
                        'Current ventilation status',
                    value: _fanOn
                        ? 'ON'
                        : 'OFF',
                    valueColor: _fanOn
                        ? steelBlue
                        : Colors
                            .blueGrey,
                  ),

                  _divider(),

                  _informationRow(
                    icon: Icons
                        .access_time_rounded,
                    title: 'Last Update',
                    subtitle:
                        'Latest update from the device',
                    value: _lastSeen,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // =================================================
              // DATA MANAGEMENT
              // =================================================

              _sectionHeader(
                'Data Management',
                Icons.storage_rounded,
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  border: Border.all(
                    color: cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration:
                          BoxDecoration(
                        color: const Color(
                          0xFFFFEBEE,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .delete_outline_rounded,
                        color:
                            dangerRed,
                      ),
                    ),

                    const SizedBox(
                      width: 13,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Clear Leakage History',
                            style:
                                TextStyle(
                              color:
                                  darkBlue,
                              fontSize:
                                  13,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            'Delete all recorded events for $_selectedDeviceName',
                            style:
                                const TextStyle(
                              color: Colors
                                  .blueGrey,
                              fontSize:
                                  10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    OutlinedButton(
                      onPressed:
                          _clearHistory,
                      style: OutlinedButton
                          .styleFrom(
                        foregroundColor:
                            dangerRed,
                        side:
                            const BorderSide(
                          color:
                              dangerRed,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            7,
                          ),
                        ),
                      ),
                      child: const Text(
                        'CLEAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .w800,
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
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
        boxShadow: [
          BoxShadow(
            color:
                steelBlue.withOpacity(0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -45,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withOpacity(0.08),
              ),
            ),
          ),

          const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'SYSTEM CONFIGURATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Configure alerts, safety features and system preferences',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SELECTED DEVICE CARD
  // =========================================================

  Widget _selectedDeviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color: cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.025,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color:
                  lightBlue.withOpacity(
                0.18,
              ),
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: steelBlue,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Configuring',
                  style: TextStyle(
                    color: Colors
                        .blueGrey
                        .shade400,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  _selectedDeviceName,
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Device ID: $_selectedDeviceId',
                  style: TextStyle(
                    color: Colors
                        .blueGrey
                        .shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
                  lightBlue.withOpacity(
                0.18,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: const Text(
              'SELECTED',
              style: TextStyle(
                color: steelBlue,
                fontSize: 9,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NO DEVICE
  // =========================================================

  Widget _buildNoDevice() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 900,
          ),
          child: Column(
            children: [
              _buildHeaderBanner(),

              const SizedBox(
                height: 30,
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 25,
                  vertical: 55,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                  border: Border.all(
                    color: cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration:
                          BoxDecoration(
                        color: lightBlue
                            .withOpacity(
                          0.18,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .device_unknown_rounded,
                        color:
                            steelBlue,
                        size: 38,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'No Device Selected',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 19,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Select a monitoring device from the Dashboard first.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors
                            .blueGrey
                            .shade500,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UI HELPERS
  // =========================================================

  Widget _sectionHeader(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: steelBlue,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: darkBlue,
            fontSize: 16,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _card({
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
                Colors.black.withOpacity(
              0.035,
            ),
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

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 65,
      color:
          Colors.blueGrey.shade50,
    );
  }

  Widget _informationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    IconData? trailingIcon,
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.all(16),
      child: Row(
        children: [
          _settingIcon(icon),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: darkBlue,
                    fontSize: 13,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors
                        .blueGrey
                        .shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                color:
                    valueColor ??
                        steelBlue,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          if (trailingIcon !=
              null) ...[
            const SizedBox(width: 6),
            Icon(
              trailingIcon,
              color: Colors
                  .blueGrey.shade300,
              size: 15,
            ),
          ],
        ],
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return Padding(
      padding:
          const EdgeInsets.all(16),
      child: Row(
        children: [
          _settingIcon(icon),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: darkBlue,
                    fontSize: 13,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors
                        .blueGrey
                        .shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            activeThumbColor:
                Colors.white,
            activeTrackColor:
                steelBlue,
            inactiveThumbColor:
                Colors.white,
            inactiveTrackColor:
                Colors
                    .blueGrey
                    .shade200,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _settingIcon(
    IconData icon,
  ) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color:
            lightBlue.withOpacity(
          0.16,
        ),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: steelBlue,
        size: 21,
      ),
    );
  }

  Widget _infoMessage(
    String text,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            lightBlue.withOpacity(
          0.12,
        ),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color:
              lightBlue.withOpacity(
            0.40,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons
                .info_outline_rounded,
            color: steelBlue,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors
                    .blueGrey
                    .shade600,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}