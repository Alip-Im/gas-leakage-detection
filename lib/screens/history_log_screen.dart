import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryLogScreen extends StatefulWidget {
  const HistoryLogScreen({super.key});

  @override
  State<HistoryLogScreen> createState() => _HistoryLogScreenState();
}

class _HistoryLogScreenState extends State<HistoryLogScreen> {
  final DatabaseReference _historyRef =
      FirebaseDatabase.instance.ref('gas_leak_history');

  // DARK GREEN THEME
  static const Color darkGreen = Color(0xFF0B261B);
  static const Color mediumGreen = Color(0xFF174C36);
  static const Color backgroundGreen = Color(0xFFD6E1DB);
  static const Color cardGreen = Color(0xFFE3EBE6);
  static const Color borderGreen = Color(0xFF9FAFA5);

  static const Color dangerRed = Color(0xFF9E2A24);
  static const Color dangerBackground = Color(0xFFE3C5C2);

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          title: const Text(
            'Clear History',
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete all gas leakage history?',
            style: TextStyle(
              color: Color(0xFF3F4C45),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: mediumGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _historyRef.remove();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gas leakage history cleared.'),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGreen,

appBar: AppBar(
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF0B261B),
  elevation: 0,
        title: const Text(
          'Gas Leakage History',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear History',
            onPressed: _clearHistory,
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: StreamBuilder<DatabaseEvent>(
        stream: _historyRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: mediumGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load history.',
                style: TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final data = snapshot.data?.snapshot.value;

          if (data == null || data is! Map) {
            return _buildEmptyHistory();
          }

          final Map<dynamic, dynamic> historyMap =
              Map<dynamic, dynamic>.from(data);

          final List<Map<String, dynamic>> historyList = [];

          historyMap.forEach((key, value) {
            if (value is Map) {
              final item = Map<dynamic, dynamic>.from(value);

              historyList.add({
                'id': key.toString(),
                'ppm': _toInt(item['ppm']),
                'status': item['status']?.toString() ?? 'DANGER',
                'timestamp':
                    item['timestamp']?.toString() ?? 'Unknown time',
              });
            }
          });

          // NEWEST FIRST
          historyList.sort(
            (a, b) => b['timestamp']
                .toString()
                .compareTo(a['timestamp'].toString()),
          );

          if (historyList.isEmpty) {
            return _buildEmptyHistory();
          }

          return Column(
            children: [
              // SUMMARY HEADER
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC4D2CA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: borderGreen,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: darkGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Recorded Gas Leakage Events',
                        style: TextStyle(
                          fontSize: 15,
                          color: darkGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: darkGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${historyList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    20,
                  ),
                  itemCount: historyList.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (context, index) {
                    final item = historyList[index];

                    final int ppm = item['ppm'] as int;
                    final String timestamp =
                        item['timestamp'].toString();
                    final String status =
                        item['status'].toString();

                    return _buildHistoryCard(
                      ppm: ppm,
                      timestamp: timestamp,
                      status: status,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard({
    required int ppm,
    required String timestamp,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderGreen,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // WARNING ICON
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: dangerBackground,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: dangerRed.withOpacity(0.45),
              ),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: dangerRed,
              size: 27,
            ),
          ),

          const SizedBox(width: 15),

          // INFORMATION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gas Leakage Detected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17211C),
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 16,
                      color: mediumGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$ppm PPM',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: mediumGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: Color(0xFF5B665F),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        timestamp,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5B665F),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // STATUS
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: dangerRed,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFFC4D2CA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 38,
                color: darkGreen,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Leakage Records',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Gas leakage events will appear here when detected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF59665F),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}