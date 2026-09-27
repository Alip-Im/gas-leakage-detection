import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('gas_sensor');

  int _threshold = 1000;

  static const Color darkGreen = Color(0xFF0B261B);
  static const Color mediumGreen = Color(0xFF174C36);
  static const Color backgroundGreen = Color(0xFFD6E1DB);
  static const Color cardGreen = Color(0xFFE3EBE6);
  static const Color borderGreen = Color(0xFF9FAFA5);
  static const Color mutedGreen = Color(0xFFBFCFC5);

  @override
  void initState() {
    super.initState();
    _listenToSettings();
  }

  void _listenToSettings() {
    _dbRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;

      if (data is Map) {
        final map = Map<dynamic, dynamic>.from(data);

        final int newThreshold =
            _toInt(map['threshold_limit'] ?? map['threshold']);

        if (newThreshold > 0) {
          setState(() {
            _threshold = newThreshold;
          });
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGreen,

    appBar: AppBar(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF0B261B),
    elevation: 0,
        title: const Text(
          'System Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PAGE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: mutedGreen,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderGreen,
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: darkGreen,
                    size: 26,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Configuration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'View the current safety configuration used by the gas leakage detection system.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF4F5C55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Safety Configuration',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
            ),

            const SizedBox(height: 10),

            // THRESHOLD CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderGreen,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC4D2CA),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: borderGreen,
                      ),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: darkGreen,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Limit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Triggers the gas alert, buzzer and exhaust fan when the limit is reached.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF56635C),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: darkGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_threshold PPM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // INFO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFC8D6CE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderGreen,
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: mediumGreen,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The threshold value is currently managed by the system and is displayed here for monitoring purposes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF46524C),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}