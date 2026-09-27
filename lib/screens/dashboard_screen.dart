import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';
import '../widgets/realtime_ppm_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  StreamSubscription<DatabaseEvent>? _deviceSubscription;

  // =========================================================
  // DEVICE SELECTION
  // =========================================================

  Map<String, String> _registeredDevices = {};

  String? _selectedDeviceId;
  String _selectedDeviceName = 'No Device Selected';

  bool _loadingDevices = true;

  // =========================================================
  // SENSOR VALUES
  // =========================================================

  int _gasLevel = 0;
  int _threshold = 1200;

  bool _fanOn = false;
  bool _buzzerOn = false;
  bool _hardwareOnline = false;
  bool _fanUpdating = false;

  String _lastSeen = 'N/A';

  bool _dangerNotificationSent = false;

  // =========================================================
  // COLORS
  // =========================================================

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);
  static const Color backgroundBlue = Color(0xFFF4FAFF);
  static const Color cardBorder = Color(0xFFD8EAF6);

  @override
  void initState() {
    super.initState();

    _loadRegisteredDevices();
  }

  // =========================================================
  // LOAD USER'S REGISTERED DEVICES
  // =========================================================

  Future<void> _loadRegisteredDevices() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingDevices = false;
        });
      }
      return;
    }

    try {
      final userRef =
          _database.ref('users/${user.uid}');

      final devicesSnapshot =
          await userRef.child('devices').get();

      final selectedSnapshot =
          await userRef.child('selected_device').get();

      final Map<String, String> loadedDevices = {};

      if (devicesSnapshot.exists &&
          devicesSnapshot.value is Map) {
        final devicesMap =
            Map<dynamic, dynamic>.from(
          devicesSnapshot.value as Map,
        );

        devicesMap.forEach((key, value) {
          if (value is Map) {
            final data =
                Map<dynamic, dynamic>.from(value);

            final String deviceId =
                data['device_id']?.toString() ??
                    key.toString();

            final String deviceName =
                data['device_name']?.toString() ??
                    deviceId;

            loadedDevices[deviceId] = deviceName;
          }
        });
      }

      String? selectedId =
          selectedSnapshot.value?.toString();

      // If saved selected device no longer exists,
      // select the first registered device.
      if (selectedId == null ||
          !loadedDevices.containsKey(selectedId)) {
        if (loadedDevices.isNotEmpty) {
          selectedId = loadedDevices.keys.first;

          await userRef.update({
            'selected_device': selectedId,
          });
        } else {
          selectedId = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _registeredDevices = loadedDevices;
        _selectedDeviceId = selectedId;

        if (selectedId != null) {
          _selectedDeviceName =
              loadedDevices[selectedId] ??
                  selectedId;
        } else {
          _selectedDeviceName =
              'No Device Selected';
        }

        _loadingDevices = false;
      });

      if (selectedId != null) {
        _listenToSelectedDevice(selectedId);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingDevices = false;
      });

      _showMessage(
        'Unable to load registered devices.',
      );
    }
  }

  // =========================================================
  // LISTEN TO SELECTED DEVICE
  // =========================================================

  void _listenToSelectedDevice(String deviceId) {
    // Stop listening to the old device.
    _deviceSubscription?.cancel();

    // Reset old values so Device 1's information
    // doesn't remain while Device 2 loads.
    if (mounted) {
      setState(() {
        _gasLevel = 0;
        _threshold = 1200;
        _fanOn = false;
        _buzzerOn = false;
        _hardwareOnline = false;
        _lastSeen = 'N/A';
        _dangerNotificationSent = false;
      });
    }

    final DatabaseReference deviceRef =
        _database.ref('devices/$deviceId');

    _deviceSubscription =
        deviceRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;

      if (data is Map) {
        final map =
            Map<dynamic, dynamic>.from(data);

        final int newGasLevel = _toInt(
          map['current_ppm'] ??
              map['ppm'] ??
              map['gas_level'] ??
              map['gasLevel'],
        );

        final int newThreshold = _toInt(
          map['threshold_limit'] ??
              map['threshold'],
        );

        final bool newFanStatus = _toBool(
          map['fan_status'] ?? map['fan'],
        );

        final bool newBuzzerStatus = _toBool(
          map['buzzer_status'] ??
              map['buzzer'],
        );

        final bool newHardwareStatus = _toBool(
          map['online'] ??
              map['is_online'] ??
              map['hardware_status'],
        );

        final dynamic lastSeenValue =
            map['last_seen'] ??
                map['lastseen'] ??
                map['last_update'];

        setState(() {
          _gasLevel = newGasLevel;

          if (newThreshold > 0) {
            _threshold = newThreshold;
          }

          _fanOn = newFanStatus;
          _buzzerOn = newBuzzerStatus;
          _hardwareOnline =
              newHardwareStatus;

          if (lastSeenValue != null) {
            _lastSeen =
                lastSeenValue.toString();
          }
        });

        _checkDangerStatus();
      }
    });
  }

  // =========================================================
  // CHANGE SELECTED DEVICE
  // =========================================================

  Future<void> _selectDevice(
    String deviceId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) return;

    if (deviceId == _selectedDeviceId) {
      return;
    }

    try {
      await _database
          .ref('users/${user.uid}')
          .update({
        'selected_device': deviceId,
      });

      if (!mounted) return;

      setState(() {
        _selectedDeviceId = deviceId;
        _selectedDeviceName =
            _registeredDevices[deviceId] ??
                deviceId;
      });

      _listenToSelectedDevice(deviceId);

      _showMessage(
        'Now monitoring $_selectedDeviceName.',
      );
    } catch (e) {
      _showMessage(
        'Unable to change monitoring device.',
      );
    }
  }

  // =========================================================
  // DEVICE SELECTOR BOTTOM SHEET
  // =========================================================

  void _showDeviceSelector() {
    if (_registeredDevices.isEmpty) {
      _showMessage(
        'No registered devices found. Register a device from Profile first.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          Colors.blueGrey.shade100,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Select Monitoring Device',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Choose which Gas Leakage Detector you want to monitor.',
                  style: TextStyle(
                    color:
                        Colors.blueGrey.shade500,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 18),

                ..._registeredDevices.entries.map(
                  (entry) {
                    final bool selected =
                        entry.key ==
                            _selectedDeviceId;

                    return Container(
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? lightBlue
                                .withOpacity(0.12)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(9),
                        border: Border.all(
                          color: selected
                              ? steelBlue
                              : cardBorder,
                          width:
                              selected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () async {
                          Navigator.pop(
                            sheetContext,
                          );

                          await _selectDevice(
                            entry.key,
                          );
                        },
                        leading: Container(
                          width: 43,
                          height: 43,
                          decoration:
                              BoxDecoration(
                            color: selected
                                ? steelBlue
                                    .withOpacity(
                                      0.12,
                                    )
                                : backgroundBlue,
                            borderRadius:
                                BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: Icon(
                            Icons.sensors_rounded,
                            color: selected
                                ? steelBlue
                                : Colors
                                    .blueGrey
                                    .shade400,
                          ),
                        ),
                        title: Text(
                          entry.value,
                          style: TextStyle(
                            color: darkBlue,
                            fontWeight:
                                selected
                                    ? FontWeight
                                        .w800
                                    : FontWeight
                                        .w600,
                          ),
                        ),
                        subtitle: Text(
                          'Device ID: ${entry.key}',
                          style: TextStyle(
                            color: Colors
                                .blueGrey.shade500,
                            fontSize: 10,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons
                                    .check_circle_rounded,
                                color: steelBlue,
                              )
                            : const Icon(
                                Icons
                                    .radio_button_unchecked_rounded,
                                color: Colors
                                    .blueGrey,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // CONVERT VALUES
  // =========================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final String text =
          value.toLowerCase();

      return text == 'true' ||
          text == 'on' ||
          text == '1';
    }

    return false;
  }

  // =========================================================
  // DANGER CHECK
  // =========================================================

  void _checkDangerStatus() {
    if (_selectedDeviceId == null) {
      return;
    }

    if (_gasLevel >= _threshold) {
      if (!_dangerNotificationSent) {
        _dangerNotificationSent = true;

        NotificationService
            .showGasAlertNotification(
          title:
              'Gas Leakage Warning - $_selectedDeviceName',
          body:
              'Dangerous LPG level detected: $_gasLevel PPM',
        );

        _saveDangerHistory();
      }
    } else {
      _dangerNotificationSent = false;
    }
  }

  // =========================================================
  // SAVE DEVICE-SPECIFIC HISTORY
  // =========================================================

  Future<void> _saveDangerHistory() async {
    if (_selectedDeviceId == null) {
      return;
    }

    final String timestamp =
        DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(DateTime.now());

    await _database
        .ref(
          'device_history/$_selectedDeviceId',
        )
        .push()
        .set({
      'device_id': _selectedDeviceId,
      'device_name': _selectedDeviceName,
      'ppm': _gasLevel,
      'status': 'DANGER',
      'timestamp': timestamp,
    });
  }

  // =========================================================
  // FAN CONTROL
  // =========================================================

  Future<void> _toggleFan(bool value) async {
    if (_fanUpdating ||
        _selectedDeviceId == null) {
      return;
    }

    setState(() {
      _fanUpdating = true;
    });

    try {
      await _database
          .ref(
            'devices/$_selectedDeviceId',
          )
          .update({
        'fan_status': value,
      });

      if (!mounted) return;

      setState(() {
        _fanOn = value;
      });

      _showMessage(
        value
            ? '$_selectedDeviceName exhaust fan turned ON'
            : '$_selectedDeviceName exhaust fan turned OFF',
      );
    } catch (e) {
      _showMessage(
        'Unable to update exhaust fan.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _fanUpdating = false;
        });
      }
    }
  }

  // =========================================================
  // GAS STATUS
  // =========================================================

  String get _gasStatus {
    if (_gasLevel >= _threshold) {
      return 'DANGER';
    }

    if (_gasLevel >=
        (_threshold * 0.7)) {
      return 'WARNING';
    }

    return 'SAFE';
  }

  Color get _statusColor {
    switch (_gasStatus) {
      case 'DANGER':
        return const Color(0xFFC62828);

      case 'WARNING':
        return const Color(0xFFEF8D00);

      default:
        return const Color(0xFF2E7D32);
    }
  }

  Color get _statusBackground {
    switch (_gasStatus) {
      case 'DANGER':
        return const Color(0xFFFFEBEE);

      case 'WARNING':
        return const Color(0xFFFFF5E5);

      default:
        return const Color(0xFFEAF7ED);
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
    _deviceSubscription?.cancel();
    super.dispose();
  }

  // =========================================================
  // DASHBOARD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: backgroundBlue,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Gas Leakage Detector',
              style: TextStyle(
                color: darkBlue,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Real-Time Safety Monitoring',
              style: TextStyle(
                color: steelBlue,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin:
                const EdgeInsets.only(
              right: 8,
            ),
            decoration: BoxDecoration(
              color:
                  lightBlue.withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Logout',
              onPressed: () async {
                await _auth.signOut();
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: steelBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SingleChildScrollView(
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
                // ===========================================
                // OVERVIEW BANNER
                // ===========================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.centerLeft,
                      end:
                          Alignment.centerRight,
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
                        color: steelBlue
                            .withOpacity(0.20),
                        blurRadius: 14,
                        offset:
                            const Offset(0, 5),
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
                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape.circle,
                            color: Colors.white
                                .withOpacity(
                              0.08,
                            ),
                          ),
                        ),
                      ),
                      const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'SYSTEM MONITORING OVERVIEW',
                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight
                                      .w800,
                              letterSpacing:
                                  0.8,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Real-time LPG detection and ventilation control',
                            style: TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===========================================
                // DEVICE SELECTOR
                // ===========================================

                const Text(
                  'Currently Monitoring',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                _monitoringDeviceCard(),

                const SizedBox(height: 18),

                // ===========================================
                // USER + ONLINE STATUS
                // ===========================================

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Logged in as ${user?.email ?? 'User'}',
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors
                              .blueGrey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _onlineBadge(),
                  ],
                ),

                const SizedBox(height: 24),

                // ===========================================
                // NO DEVICE
                // ===========================================

                if (_registeredDevices.isEmpty &&
                    !_loadingDevices)
                  _noDeviceCard()
                else ...[
                  const Text(
                    'System Overview',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =========================================
                  // SYSTEM OVERVIEW
                  // =========================================

                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      border: Border.all(
                        color: cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                            0.03,
                          ),
                          blurRadius: 10,
                          offset:
                              const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior:
                        Clip.antiAlias,
                    child: Column(
                      children: [
                        _overviewRow(
                          icon:
                              Icons.air_rounded,
                          title:
                              'Current Gas Level',
                          subtitle:
                              'Live LPG concentration',
                          value:
                              '$_gasLevel',
                          unit: ' PPM',
                          iconColor:
                              steelBlue,
                        ),
                        _overviewRow(
                          icon: Icons
                              .shield_outlined,
                          title: 'Gas Status',
                          subtitle: _gasStatus ==
                                  'SAFE'
                              ? 'Gas level is within safe range'
                              : _gasStatus ==
                                      'WARNING'
                                  ? 'Gas concentration is increasing'
                                  : 'Dangerous gas concentration detected',
                          value:
                              _gasStatus,
                          iconColor:
                              _statusColor,
                          valueColor:
                              _statusColor,
                        ),
                        _overviewRow(
                          icon: Icons
                              .mode_fan_off_outlined,
                          title:
                              'Exhaust Fan',
                          subtitle:
                              'Ventilation system',
                          value: _fanOn
                              ? 'ON'
                              : 'OFF',
                          iconColor:
                              steelBlue,
                          valueColor: _fanOn
                              ? steelBlue
                              : Colors
                                  .blueGrey
                                  .shade500,
                        ),
                        _overviewRow(
                          icon: Icons
                              .sensors_rounded,
                          title: 'Hardware',
                          subtitle:
                              'ESP32 monitoring device',
                          value:
                              _hardwareOnline
                                  ? 'ONLINE'
                                  : 'OFFLINE',
                          iconColor:
                              _hardwareOnline
                                  ? steelBlue
                                  : Colors
                                      .blueGrey,
                          valueColor:
                              _hardwareOnline
                                  ? const Color(
                                      0xFF2E7D32,
                                    )
                                  : const Color(
                                      0xFFC62828,
                                    ),
                          showDivider:
                              false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================================
                  // CURRENT CONDITION
                  // =========================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _statusBackground,
                      borderRadius:
                          BorderRadius.circular(
                        9,
                      ),
                      border: Border.all(
                        color: _statusColor
                            .withOpacity(
                          0.25,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration:
                              BoxDecoration(
                            color: _statusColor
                                .withOpacity(
                              0.12,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                          child: Icon(
                            _gasStatus ==
                                    'DANGER'
                                ? Icons
                                    .warning_rounded
                                : _gasStatus ==
                                        'WARNING'
                                    ? Icons
                                        .warning_amber_rounded
                                    : Icons
                                        .check_circle_outline_rounded,
                            color:
                                _statusColor,
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Current Condition: $_gasStatus',
                                style:
                                    TextStyle(
                                  color:
                                      _statusColor,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                _gasStatus ==
                                        'DANGER'
                                    ? 'Immediate attention is required.'
                                    : _gasStatus ==
                                            'WARNING'
                                        ? 'Monitor the gas concentration closely.'
                                        : 'The environment is currently within the safe range.',
                                style:
                                    TextStyle(
                                  color:
                                      _statusColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =========================================
                  // CHART
                  // =========================================

                  _sectionHeader(
                    'Gas Level Overview',
                    Icons.show_chart_rounded,
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.fromLTRB(
                      12,
                      20,
                      12,
                      10,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                            0.04,
                          ),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        RealtimePpmChart(
                      // Key forces the graph to
                      // reset when another device
                      // is selected.
                      key: ValueKey(
                        _selectedDeviceId,
                      ),
                      currentPpm:
                          _gasLevel,
                      threshold:
                          _threshold,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =========================================
                  // FAN CONTROL
                  // =========================================

                  _sectionHeader(
                    'Exhaust Fan Control',
                    Icons.air_rounded,
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      18,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                            0.04,
                          ),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration:
                                  BoxDecoration(
                                color: lightBlue
                                    .withOpacity(
                                  0.20,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  9,
                                ),
                              ),
                              child: Icon(
                                _fanOn
                                    ? Icons
                                        .air_rounded
                                    : Icons
                                        .mode_fan_off_outlined,
                                color:
                                    steelBlue,
                                size: 27,
                              ),
                            ),
                            const SizedBox(
                              width: 14,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Text(
                                    'Exhaust Fan',
                                    style:
                                        TextStyle(
                                      color:
                                          darkBlue,
                                      fontSize:
                                          15,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    _fanOn
                                        ? 'Ventilation is currently running'
                                        : 'Ventilation is currently stopped',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .blueGrey
                                          .shade500,
                                      fontSize:
                                          12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _fanOn
                                  ? 'ON'
                                  : 'OFF',
                              style: TextStyle(
                                color: _fanOn
                                    ? steelBlue
                                    : Colors
                                        .blueGrey
                                        .shade500,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Switch(
                              value: _fanOn,
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
                              onChanged:
                                  _fanUpdating ||
                                          _selectedDeviceId ==
                                              null
                                      ? null
                                      : _toggleFan,
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                backgroundBlue,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              7,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .info_outline_rounded,
                                color:
                                    steelBlue,
                                size: 18,
                              ),
                              const SizedBox(
                                width: 9,
                              ),
                              Expanded(
                                child: Text(
                                  'This switch controls the exhaust fan for $_selectedDeviceName.',
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .blueGrey
                                        .shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =========================================
                  // SYSTEM INFORMATION
                  // =========================================

                  _sectionHeader(
                    'System Information',
                    Icons
                        .info_outline_rounded,
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
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
                    child: Column(
                      children: [
                        _informationRow(
                          icon: Icons
                              .sensors_rounded,
                          title: 'Device',
                          value:
                              _selectedDeviceName,
                        ),

                        _informationDivider(),

                        _informationRow(
                          icon:
                              Icons.qr_code_rounded,
                          title: 'Device ID',
                          value:
                              _selectedDeviceId ??
                                  'N/A',
                        ),

                        _informationDivider(),

                        _informationRow(
                          icon: Icons
                              .speed_rounded,
                          title:
                              'Danger Threshold',
                          value:
                              '$_threshold PPM',
                        ),

                        _informationDivider(),

                        _informationRow(
                          icon: _buzzerOn
                              ? Icons
                                  .notifications_active_rounded
                              : Icons
                                  .notifications_none_rounded,
                          title: 'Buzzer',
                          value: _buzzerOn
                              ? 'ON'
                              : 'OFF',
                          valueColor:
                              _buzzerOn
                                  ? const Color(
                                      0xFFC62828,
                                    )
                                  : Colors
                                      .blueGrey
                                      .shade600,
                        ),

                        _informationDivider(),

                        _informationRow(
                          icon: Icons
                              .access_time_rounded,
                          title:
                              'Last Update',
                          value: _lastSeen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MONITORING DEVICE CARD
  // =========================================================

  Widget _monitoringDeviceCard() {
    if (_loadingDevices) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
          border:
              Border.all(color: cardBorder),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: steelBlue,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading devices...',
              style: TextStyle(
                color: darkBlue,
              ),
            ),
          ],
        ),
      );
    }

    final bool hasDevice =
        _selectedDeviceId != null;

    return InkWell(
      onTap: _showDeviceSelector,
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: hasDevice
                ? steelBlue.withOpacity(0.45)
                : cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    lightBlue.withOpacity(0.18),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sensors_rounded,
                color: steelBlue,
                size: 25,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDevice
                        ? _selectedDeviceName
                        : 'No Device Registered',
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    hasDevice
                        ? 'Device ID: $_selectedDeviceId'
                        : 'Register a device from your Profile',
                    style: TextStyle(
                      color: Colors
                          .blueGrey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            if (_registeredDevices.length > 1)
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CHANGE',
                    style: TextStyle(
                      color: steelBlue,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                    color: steelBlue,
                  ),
                ],
              )
            else
              const Icon(
                Icons
                    .keyboard_arrow_down_rounded,
                color: steelBlue,
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NO DEVICE CARD
  // =========================================================

  Widget _noDeviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border:
            Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .device_unknown_rounded,
            color: steelBlue,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Monitoring Device',
            style: TextStyle(
              color: darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Register a Gas Leakage Detector from the Profile page first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Colors.blueGrey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ONLINE BADGE
  // =========================================================

  Widget _onlineBadge() {
    final Color color =
        _hardwareOnline
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _hardwareOnline
                ? 'ONLINE'
                : 'OFFLINE',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // OVERVIEW ROW
  // =========================================================

  Widget _overviewRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    String unit = '',
    required Color iconColor,
    Color? valueColor,
    bool showDivider = true,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration:
                      BoxDecoration(
                    color: iconColor
                        .withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 23,
                  ),
                ),

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
                        height: 2,
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

                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          color:
                              valueColor ??
                                  darkBlue,
                          fontSize: 20,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      TextSpan(
                        text: unit,
                        style: TextStyle(
                          color: Colors
                              .blueGrey
                              .shade500,
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
            ),
          ),

          if (showDivider)
            Divider(
              height: 1,
              indent: 70,
              color: Colors
                  .blueGrey.shade50,
            ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION HEADER
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
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INFORMATION ROW
  // =========================================================

  Widget _informationRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  lightBlue.withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              color: steelBlue,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    valueColor ?? steelBlue,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationDivider() {
    return Divider(
      height: 1,
      indent: 64,
      color: Colors.blueGrey.shade50,
    );
  }
}