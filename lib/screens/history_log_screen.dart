import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryLogScreen extends StatefulWidget {
  const HistoryLogScreen({super.key});

  @override
  State<HistoryLogScreen> createState() =>
      _HistoryLogScreenState();
}

class _HistoryLogScreenState extends State<HistoryLogScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  StreamSubscription<DatabaseEvent>? _selectedDeviceSubscription;

  String? _selectedDeviceId;
  String _selectedDeviceName = 'No Device Selected';

  bool _loadingDevice = true;

  // =========================================================
  // BLUE APP THEME
  // =========================================================

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);
  static const Color backgroundBlue = Color(0xFFF4FAFF);
  static const Color cardBorder = Color(0xFFD8EAF6);

  static const Color dangerRed = Color(0xFFC62828);
  static const Color dangerBackground = Color(0xFFFFEBEE);

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _listenToSelectedDevice();
  }

  // =========================================================
  // LISTEN TO SELECTED DEVICE
  // =========================================================

  void _listenToSelectedDevice() {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _loadingDevice = false;
      });
      return;
    }

    final DatabaseReference selectedDeviceRef =
        _database.ref(
      'users/${user.uid}/selected_device',
    );

    _selectedDeviceSubscription =
        selectedDeviceRef.onValue.listen(
      (event) async {
        final String? deviceId =
            event.snapshot.value?.toString();

        if (deviceId == null ||
            deviceId.trim().isEmpty) {
          if (!mounted) return;

          setState(() {
            _selectedDeviceId = null;
            _selectedDeviceName = 'No Device Selected';
            _loadingDevice = false;
          });

          return;
        }

        await _loadDeviceInformation(deviceId);
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _loadingDevice = false;
        });
      },
    );
  }

  // =========================================================
  // LOAD DEVICE NAME
  // =========================================================

  Future<void> _loadDeviceInformation(
    String deviceId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      final DataSnapshot snapshot =
          await _database
              .ref(
                'users/${user.uid}/devices/$deviceId',
              )
              .get();

      String deviceName = deviceId;

      if (snapshot.exists &&
          snapshot.value is Map) {
        final Map<dynamic, dynamic> data =
            Map<dynamic, dynamic>.from(
          snapshot.value as Map,
        );

        deviceName =
            data['device_name']?.toString() ??
                deviceId;
      } else {
        // Fallback to main devices node.
        final DataSnapshot mainDeviceSnapshot =
            await _database
                .ref('devices/$deviceId')
                .get();

        if (mainDeviceSnapshot.exists &&
            mainDeviceSnapshot.value is Map) {
          final Map<dynamic, dynamic> data =
              Map<dynamic, dynamic>.from(
            mainDeviceSnapshot.value as Map,
          );

          deviceName =
              data['device_name']?.toString() ??
                  deviceId;
        }
      }

      if (!mounted) return;

      setState(() {
        _selectedDeviceId = deviceId;
        _selectedDeviceName = deviceName;
        _loadingDevice = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _selectedDeviceId = deviceId;
        _selectedDeviceName = deviceId;
        _loadingDevice = false;
      });
    }
  }

  // =========================================================
  // CLEAR HISTORY
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
                  fontWeight: FontWeight.w800,
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
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
                ),
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
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
  // CONVERT TO INT
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
    super.dispose();
  }

  // =========================================================
  // PAGE
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
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Gas Leakage History',
              style: TextStyle(
                color: darkBlue,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Previous gas leakage detection records',
              style: TextStyle(
                color: steelBlue,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // ===================================================
        // CLEAR BUTTON
        // ===================================================

        actions: [
          Container(
            margin:
                const EdgeInsets.only(
              right: 16,
            ),
            decoration: BoxDecoration(
              color: dangerBackground,
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip:
                  'Clear Device History',
              onPressed:
                  _selectedDeviceId == null
                      ? null
                      : _clearHistory,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: dangerRed,
              ),
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: _loadingDevice
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: steelBlue,
              ),
            )
          : _selectedDeviceId == null
              ? _buildNoDeviceSelected()
              : StreamBuilder<DatabaseEvent>(
                  // IMPORTANT:
                  // Only listen to the selected
                  // device's history.
                  stream: _database
                      .ref(
                        'device_history/$_selectedDeviceId',
                      )
                      .onValue,
                  builder:
                      (context, snapshot) {
                    if (snapshot
                            .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              steelBlue,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState();
                    }

                    final data = snapshot
                        .data
                        ?.snapshot
                        .value;

                    if (data == null ||
                        data is! Map) {
                      return _buildEmptyHistory();
                    }

                    final Map<dynamic, dynamic>
                        historyMap =
                        Map<dynamic, dynamic>.from(
                      data,
                    );

                    final List<
                            Map<String, dynamic>>
                        historyList = [];

                    historyMap.forEach(
                      (key, value) {
                        if (value is Map) {
                          final item =
                              Map<dynamic,
                                      dynamic>.from(
                            value,
                          );

                          historyList.add({
                            'id':
                                key.toString(),
                            'ppm': _toInt(
                              item['ppm'],
                            ),
                            'status':
                                item['status']
                                        ?.toString() ??
                                    'DANGER',
                            'timestamp': item[
                                        'timestamp']
                                    ?.toString() ??
                                'Unknown time',
                            'device_id': item[
                                        'device_id']
                                    ?.toString() ??
                                _selectedDeviceId,
                            'device_name': item[
                                        'device_name']
                                    ?.toString() ??
                                _selectedDeviceName,
                          });
                        }
                      },
                    );

                    // =======================================
                    // NEWEST FIRST
                    // =======================================

                    historyList.sort(
                      (a, b) => b[
                              'timestamp']
                          .toString()
                          .compareTo(
                            a['timestamp']
                                .toString(),
                          ),
                    );

                    if (historyList.isEmpty) {
                      return _buildEmptyHistory();
                    }

                    // =======================================
                    // HIGHEST PPM
                    // =======================================

                    int highestPpm = 0;

                    for (final item
                        in historyList) {
                      final int ppm =
                          item['ppm'] as int;

                      if (ppm > highestPpm) {
                        highestPpm = ppm;
                      }
                    }

                    return _buildHistoryContent(
                      historyList:
                          historyList,
                      highestPpm:
                          highestPpm,
                    );
                  },
                ),
    );
  }

  // =========================================================
  // HISTORY CONTENT
  // =========================================================

  Widget _buildHistoryContent({
    required List<Map<String, dynamic>>
        historyList,
    required int highestPpm,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 900,
        ),
        child: CustomScrollView(
          slivers: [
            // =================================================
            // HEADER CONTENT
            // =================================================

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                0,
              ),
              sliver: SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    // =========================================
                    // BLUE HEADER
                    // =========================================

                    _buildHeaderBanner(),

                    const SizedBox(height: 18),

                    // =========================================
                    // CURRENT DEVICE
                    // =========================================

                    _buildSelectedDeviceCard(),

                    const SizedBox(height: 26),

                    // =========================================
                    // SUMMARY TITLE
                    // =========================================

                    const Row(
                      children: [
                        Icon(
                          Icons
                              .analytics_outlined,
                          color: steelBlue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'History Summary',
                          style: TextStyle(
                            color: darkBlue,
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    // =========================================
                    // SUMMARY CARDS
                    // =========================================

                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            icon: Icons
                                .warning_amber_rounded,
                            title:
                                'Total Events',
                            value:
                                '${historyList.length}',
                            subtitle:
                                'Leakage records',
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: _summaryCard(
                            icon: Icons
                                .speed_rounded,
                            title:
                                'Highest PPM',
                            value:
                                '$highestPpm',
                            subtitle:
                                'Maximum detected',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // =========================================
                    // RECORD HEADER
                    // =========================================

                    Row(
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .history_rounded,
                                color:
                                    steelBlue,
                                size: 20,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Recent Leakage Events',
                                style:
                                    TextStyle(
                                  color:
                                      darkBlue,
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight
                                          .w800,
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
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color: lightBlue
                                .withOpacity(
                              0.20,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '${historyList.length} records',
                            style:
                                const TextStyle(
                              color:
                                  steelBlue,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),
                  ],
                ),
              ),
            ),

            // =================================================
            // HISTORY LIST
            // =================================================

            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                30,
              ),
              sliver:
                  SliverList.separated(
                itemCount:
                    historyList.length,
                separatorBuilder:
                    (context, index) {
                  return const SizedBox(
                    height: 11,
                  );
                },
                itemBuilder:
                    (context, index) {
                  final item =
                      historyList[index];

                  return _buildHistoryCard(
                    ppm:
                        item['ppm'] as int,
                    timestamp:
                        item['timestamp']
                            .toString(),
                    status:
                        item['status']
                            .toString(),
                    number: index + 1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER BANNER
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
                'LEAKAGE HISTORY',
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
                'Review previously detected LPG danger events',
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

  Widget _buildSelectedDeviceCard() {
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
                Colors.black.withOpacity(0.025),
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
                  lightBlue.withOpacity(0.18),
              borderRadius:
                  BorderRadius.circular(8),
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
                  'Currently Viewing',
                  style: TextStyle(
                    color: Colors
                        .blueGrey.shade400,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedDeviceName,
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Device ID: $_selectedDeviceId',
                  style: TextStyle(
                    color: Colors
                        .blueGrey.shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
                  lightBlue.withOpacity(0.18),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  Icons
                      .check_circle_rounded,
                  color: steelBlue,
                  size: 15,
                ),
                SizedBox(width: 5),
                Text(
                  'SELECTED',
                  style: TextStyle(
                    color: steelBlue,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  lightBlue.withOpacity(0.18),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: steelBlue,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors
                        .blueGrey.shade500,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors
                        .blueGrey.shade300,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HISTORY CARD
  // =========================================================

  Widget _buildHistoryCard({
    required int ppm,
    required String timestamp,
    required String status,
    required int number,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          // WARNING ICON

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dangerBackground,
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: dangerRed,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          // EVENT DETAILS

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Gas Leakage Event #$number',
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 15,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons
                              .speed_rounded,
                          size: 15,
                          color: steelBlue,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '$ppm PPM',
                          style:
                              const TextStyle(
                            color:
                                steelBlue,
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .access_time_rounded,
                          size: 14,
                          color: Colors
                              .blueGrey
                              .shade400,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          timestamp,
                          style: TextStyle(
                            color: Colors
                                .blueGrey
                                .shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // STATUS

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: dangerBackground,
              borderRadius:
                  BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: dangerRed,
                fontSize: 9,
                fontWeight:
                    FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY HISTORY
  // =========================================================

  Widget _buildEmptyHistory() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 900,
          ),
          child: Column(
            children: [
              // HEADER

              _buildHeaderBanner(),

              const SizedBox(height: 18),

              // SELECTED DEVICE

              _buildSelectedDeviceCard(),

              const SizedBox(height: 30),

              // EMPTY CARD

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 55,
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
                        0.035,
                      ),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 4),
                    ),
                  ],
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
                        Icons.history_rounded,
                        size: 38,
                        color: steelBlue,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'No Leakage Records',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 19,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'No leakage events have been recorded for $_selectedDeviceName.\n'
                      'Detected gas leakage events will appear here.',
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

                    const SizedBox(height: 20),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration:
                          BoxDecoration(
                        color: const Color(
                          0xFFEAF7ED,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .check_circle_outline_rounded,
                            color: Color(
                              0xFF2E7D32,
                            ),
                            size: 17,
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text(
                            'No danger events detected',
                            style:
                                TextStyle(
                              color: Color(
                                0xFF2E7D32,
                              ),
                              fontSize: 10,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
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
  // NO DEVICE SELECTED
  // =========================================================

  Widget _buildNoDeviceSelected() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 900,
          ),
          child: Column(
            children: [
              _buildHeaderBanner(),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 55,
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
                        color: steelBlue,
                        size: 38,
                      ),
                    ),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 8),

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
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: cardBorder,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: dangerRed,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              'Unable to Load History',
              style: TextStyle(
                color: darkBlue,
                fontWeight:
                    FontWeight.w800,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}