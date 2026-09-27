import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';
import '../widgets/realtime_ppm_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('gas_sensor');

  final DatabaseReference _historyRef =
      FirebaseDatabase.instance.ref('gas_leak_history');

  int _gasLevel = 0;
  int _threshold = 1000;

  bool _fanOn = false;
  bool _buzzerOn = false;
  bool _hardwareOnline = false;

  String _lastSeen = 'N/A';

  bool _dangerNotificationSent = false;

  // DARK GREEN THEME
  static const Color darkGreen = Color(0xFF0B261B);
  static const Color mediumGreen = Color(0xFF174C36);
  static const Color mainGreen = Color(0xFF216B4A);
  static const Color softGreen = Color(0xFFC7D9CF);
  static const Color backgroundGreen = Color(0xFFD6E1DB);
  static const Color cardGreen = Color(0xFFE3EBE6);
  static const Color borderGreen = Color(0xFF9FAFA5);

  @override
  void initState() {
    super.initState();
    _listenToGasSensor();
  }

  void _listenToGasSensor() {
    _dbRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;

      if (data is Map) {
        final map = Map<dynamic, dynamic>.from(data);

        final int newGasLevel =
            _toInt(map['ppm'] ?? map['gas_level'] ?? map['gasLevel']);

        final int newThreshold =
            _toInt(map['threshold_limit'] ?? map['threshold']);

        final bool newFanStatus =
            _toBool(map['fan_status'] ?? map['fan']);

        final bool newBuzzerStatus =
            _toBool(map['buzzer_status'] ?? map['buzzer']);

        final bool newHardwareStatus =
            _toBool(map['online'] ?? map['hardware_status']);

        final dynamic lastSeenValue = map['last_seen'];

        setState(() {
          _gasLevel = newGasLevel;

          if (newThreshold > 0) {
            _threshold = newThreshold;
          }

          _fanOn = newFanStatus;
          _buzzerOn = newBuzzerStatus;
          _hardwareOnline = newHardwareStatus;

          if (lastSeenValue != null) {
            _lastSeen = lastSeenValue.toString();
          }
        });

        _checkDangerStatus();
      }
    });
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      return value.toLowerCase() == 'true' ||
          value.toLowerCase() == 'on' ||
          value == '1';
    }

    return false;
  }

  void _checkDangerStatus() {
    if (_gasLevel >= _threshold) {
      if (!_dangerNotificationSent) {
        _dangerNotificationSent = true;

        NotificationService.showGasAlertNotification(
          title: 'Gas Leakage Warning',
          body: 'Dangerous LPG level detected: $_gasLevel PPM',
        );

        _saveDangerHistory();
      }
    } else {
      _dangerNotificationSent = false;
    }
  }

  Future<void> _saveDangerHistory() async {
    final String timestamp =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    await _historyRef.push().set({
      'ppm': _gasLevel,
      'status': 'DANGER',
      'timestamp': timestamp,
    });
  }

  Future<void> _toggleFan(bool value) async {
    await _dbRef.update({
      'fan_status': value,
    });

    if (mounted) {
      setState(() {
        _fanOn = value;
      });
    }
  }

  String get _gasStatus {
    if (_gasLevel >= _threshold) {
      return 'DANGER';
    }

    if (_gasLevel >= (_threshold * 0.7)) {
      return 'WARNING';
    }

    return 'SAFE';
  }

  Color get _statusColor {
    switch (_gasStatus) {
      case 'DANGER':
        return const Color(0xFFB3261E);

      case 'WARNING':
        return const Color(0xFFC17A00);

      default:
        return const Color(0xFF1B5E20);
    }
  }

  Color get _statusBackgroundColor {
    switch (_gasStatus) {
      case 'DANGER':
        return const Color(0xFFE7C1BE);

      case 'WARNING':
        return const Color(0xFFE4D2A6);

      default:
        return const Color(0xFFBFD5C4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundGreen,

appBar: AppBar(
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF0B261B),
  elevation: 0,
        title: const Text(
          'Gas Leakage Detector',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HARDWARE STATUS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: _hardwareOnline
                    ? const Color(0xFFB8CFBF)
                    : const Color(0xFFDAB7B7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _hardwareOnline
                      ? const Color(0xFF4D8061)
                      : const Color(0xFF9A4F4A),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _hardwareOnline
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFB3261E),
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _hardwareOnline
                          ? 'Hardware: ONLINE'
                          : 'Hardware: OFFLINE',
                      style: TextStyle(
                        color: _hardwareOnline
                            ? darkGreen
                            : const Color(0xFF7A1D19),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  Text(
                    'Last Seen: $_lastSeen',
                    style: const TextStyle(
                      color: Color(0xFF4A5750),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Logged in as: ${user?.email ?? 'User'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF3F4C45),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // GAS LEVEL CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 28,
              ),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderGreen,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: softGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.air_rounded,
                      color: darkGreen,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Current Gas Concentration',
                    style: TextStyle(
                      color: Color(0xFF3C4942),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '$_gasLevel PPM',
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _gasStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _statusBackgroundColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _statusColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _gasStatus == 'DANGER'
                              ? Icons.warning_rounded
                              : _gasStatus == 'WARNING'
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                          color: _statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _gasStatus == 'DANGER'
                              ? 'Dangerous gas level detected'
                              : _gasStatus == 'WARNING'
                                  ? 'Gas level is increasing'
                                  : 'Gas level is within safe range',
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // REAL-TIME GRAPH
            RealtimePpmChart(
              currentPpm: _gasLevel,
              threshold: _threshold,
            ),

            const SizedBox(height: 18),

            // EXHAUST FAN CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: borderGreen,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: softGreen,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.air,
                      color: darkGreen,
                    ),
                  ),

                  const SizedBox(width: 15),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exhaust Fan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Ventilation control',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5B665F),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    _fanOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: _fanOn
                          ? mediumGreen
                          : const Color(0xFF616A65),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Switch(
                    value: _fanOn,
                    activeThumbColor: Colors.white,
                    activeTrackColor: mainGreen,
                    inactiveThumbColor: const Color(0xFF67726B),
                    inactiveTrackColor: const Color(0xFFB8C4BD),
                    onChanged: _toggleFan,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // DANGER THRESHOLD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: borderGreen,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    color: darkGreen,
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Text(
                      'Danger Threshold',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                  ),

                  Text(
                    '$_threshold PPM',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: mediumGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // BUZZER
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: borderGreen,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _buzzerOn
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: _buzzerOn
                        ? const Color(0xFFB3261E)
                        : darkGreen,
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Text(
                      'Buzzer',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _buzzerOn
                          ? const Color(0xFFDAB7B7)
                          : softGreen,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _buzzerOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: _buzzerOn
                            ? const Color(0xFF8C221D)
                            : darkGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}