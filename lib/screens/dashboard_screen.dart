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

  bool _hasNotified = false;

  void _toggleFan(bool currentValue) {
    _dbRef.update({
      'fan_status': !currentValue,
    });
  }

  String _calculateStatus(int ppm, int threshold) {
    if (ppm >= threshold) {
      return 'DANGER';
    }

    if (ppm > threshold * 0.5) {
      return 'WARNING';
    }

    return 'SAFE';
  }

  Color _getStatusColor(int ppm, int threshold) {
    if (ppm >= threshold) {
      return Colors.red;
    }

    if (ppm > threshold * 0.5) {
      return Colors.orange;
    }

    return Colors.green;
  }

  Future<void> _logLeakIncident(int ppmLevel) async {
    final now = DateTime.now();

    final formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    await _historyRef.push().set({
      'ppm_level': ppmLevel,
      'timestamp': formattedDate,
      'status': 'DANGER',
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gas Leakage Detector',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (
          context,
          AsyncSnapshot<DatabaseEvent> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data?.snapshot.value
              as Map<dynamic, dynamic>?;

          final int ppm = data?['ppm'] ?? 0;

          final int threshold =
              data?['threshold_limit'] ?? 1000;

          final String status =
              _calculateStatus(ppm, threshold);

          final bool isFanOn =
              data?['fan_status'] ?? false;

          final bool isBuzzerOn =
              data?['buzzer_status'] ?? false;

          final bool isOnline =
              data?['is_online'] ?? false;

          final String lastSeen =
              data?['last_seen']?.toString() ?? 'N/A';

          if (ppm >= threshold) {
            if (!_hasNotified) {
              NotificationService.showGasAlertNotification(
                title: '🚨 GAS LEAKAGE WARNING!',
                body:
                    'Gas concentration reached $ppm PPM! Take immediate action.',
              );

              _logLeakIncident(ppm);

              _hasNotified = true;
            }
          } else {
            _hasNotified = false;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // Connection Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: isOnline
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 14,
                            color: isOnline
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline
                                ? 'Hardware: ONLINE'
                                : 'Hardware: OFFLINE',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              color: isOnline
                                  ? Colors
                                      .green.shade900
                                  : Colors
                                      .red.shade900,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Last Seen: $lastSeen',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Logged in as: ${user?.email ?? 'Unknown'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 12),

                // Gas PPM Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Current Gas Concentration',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '$ppm PPM',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                _getStatusColor(
                              ppm,
                              threshold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Chip(
                          label: Text(
                            status,
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          backgroundColor:
                              _getStatusColor(
                            ppm,
                            threshold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Real-Time Graph
                RealtimePpmChart(
                  currentPpm: ppm,
                  threshold: threshold,
                ),

                const SizedBox(height: 16),

                // Exhaust Fan Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons
                                      .mode_fan_off_outlined,
                                  color: isFanOn
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 28,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text(
                                  'Exhaust Fan',
                                  style:
                                      TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: isFanOn,
                              activeTrackColor:
                                  Colors
                                      .blue
                                      .shade200,
                              activeThumbColor:
                                  Colors.blue,
                              onChanged: (_) {
                                _toggleFan(
                                    isFanOn);
                              },
                            ),
                          ],
                        ),

                        const Divider(),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Text(
                              'Alert Threshold: $threshold PPM',
                            ),
                            Text(
                              'Buzzer: ${isBuzzerOn ? "ON" : "OFF"}',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    isBuzzerOn
                                        ? Colors
                                            .red
                                        : Colors
                                            .grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}