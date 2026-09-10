import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// ==========================================
// 0. NOTIFICATION SERVICE CLASS
// ==========================================
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showGasAlertNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gas_leak_channel',
      'Gas Leak Alerts',
      channelDescription: 'Alert notifications for LPG gas leakages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}

// ==========================================
// WIDGET GRAF REAL-TIME PPM
// ==========================================
class RealtimePpmChart extends StatefulWidget {
  final int currentPpm;
  final int threshold;

  const RealtimePpmChart({
    super.key,
    required this.currentPpm,
    required this.threshold,
  });

  @override
  State<RealtimePpmChart> createState() => _RealtimePpmChartState();
}

class _RealtimePpmChartState extends State<RealtimePpmChart> {
  final List<FlSpot> _ppmSpots = [];
  int _timeIndex = 0;
  final int _maxDataPoints = 10;

  @override
  void initState() {
    super.initState();
    _addPoint(widget.currentPpm);
  }

  @override
  void didUpdateWidget(covariant RealtimePpmChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPpm != widget.currentPpm || _ppmSpots.isEmpty) {
      _addPoint(widget.currentPpm);
    }
  }

  void _addPoint(int ppm) {
    setState(() {
      _timeIndex++;
      _ppmSpots.add(FlSpot(_timeIndex.toDouble(), ppm.toDouble()));
      if (_ppmSpots.length > _maxDataPoints) {
        _ppmSpots.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time PPM Trend Chart',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: widget.threshold.toDouble(),
                        color: Colors.red,
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          labelResolver: (line) =>
                              'Limit (${widget.threshold})',
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _ppmSpots,
                      isCurved: true,
                      color: widget.currentPpm >= widget.threshold
                          ? Colors.red
                          : Colors.indigo,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (widget.currentPpm >= widget.threshold
                                ? Colors.red
                                : Colors.indigo)
                            .withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MAIN FUNCTION
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC54U2VaMpbgiNGmcaIhvWwOnS157xrojs",
      authDomain: "gas-leakage-detection-9391e.firebaseapp.com",
      databaseURL:
          "https://gas-leakage-detection-9391e-default-rtdb.firebaseio.com",
      projectId: "gas-leakage-detection-9391e",
      storageBucket: "gas-leakage-detection-9391e.firebasestorage.app",
      messagingSenderId: "146541742460",
      appId: "1:146541742460:web:65bb6176e2f5e58fbcbcf9",
      measurementId: "G-QXMSTK50MR",
    ),
  );

  await NotificationService.init();

  runApp(const GasLeakApp());
}

class GasLeakApp extends StatelessWidget {
  const GasLeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gas Leakage Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ==========================================
// 1. LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.indigo),
                const SizedBox(height: 16),
                const Text(
                  'Gas Leakage Detector',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.indigo,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LOG IN',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text('Register Here'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. REGISTER & FORGOT PASSWORD SCREEN
// ==========================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (minimum 6 characters)',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.indigo,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('REGISTER ACCOUNT',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset link has been sent to your email.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error sending reset email.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.indigo,
              ),
              child: const Text('SEND RESET EMAIL',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. MAIN NAVIGATION (BOTTOM NAVBAR)
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryLogScreen(),
    const SettingsScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.tune), label: 'Settings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ==========================================
// 4. DASHBOARD SCREEN WITH REAL-TIME GRAPH
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('gas_sensor');
  final DatabaseReference _historyRef =
      FirebaseDatabase.instance.ref('gas_leak_history');
  bool _hasNotified = false;

  void _toggleFan(bool currentValue) {
    _dbRef.update({'fan_status': !currentValue});
  }

  String _calculateStatus(int ppm, int threshold) {
    if (ppm >= threshold) return 'DANGER';
    if (ppm > threshold * 0.5) return 'WARNING';
    return 'SAFE';
  }

  Color _getStatusColor(int ppm, int threshold) {
    if (ppm >= threshold) return Colors.red;
    if (ppm > threshold * 0.5) return Colors.orange;
    return Colors.green;
  }

  Future<void> _logLeakIncident(int ppmLevel) async {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

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
        title: const Text('Gas Leakage Detector',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
          final int ppm = data?['ppm'] ?? 0;
          final int threshold = data?['threshold_limit'] ?? 1000;
          final String status = _calculateStatus(ppm, threshold);
          final bool isFanOn = data?['fan_status'] ?? false;
          final bool isBuzzerOn = data?['buzzer_status'] ?? false;
          final bool isOnline = data?['is_online'] ?? false;
          final String lastSeen = data?['last_seen']?.toString() ?? 'N/A';

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOnline
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 14,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Hardware: ONLINE' : 'Hardware: OFFLINE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOnline
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Last Seen: $lastSeen',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Logged in as: ${user?.email ?? 'Unknown'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Gas PPM Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('Current Gas Concentration',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 10),
                        Text(
                          '$ppm PPM',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(ppm, threshold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Chip(
                          label: Text(
                            status,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: _getStatusColor(ppm, threshold),
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
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.mode_fan_off_outlined,
                                  color: isFanOn ? Colors.blue : Colors.grey,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                const Text('Exhaust Fan',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Switch(
                              value: isFanOn,
                              activeTrackColor: Colors.blue.shade200,
                              activeThumbColor: Colors.blue,
                              onChanged: (_) => _toggleFan(isFanOn),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Alert Threshold: $threshold PPM'),
                            Text(
                              'Buzzer: ${isBuzzerOn ? "ON" : "OFF"}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isBuzzerOn ? Colors.red : Colors.grey,
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

// ==========================================
// 5. HISTORY LOG SCREEN
// ==========================================
class HistoryLogScreen extends StatelessWidget {
  const HistoryLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference historyRef =
        FirebaseDatabase.instance.ref('gas_leak_history');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Leakage History',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'Clear History',
            onPressed: () async {
              await historyRef.remove();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History log cleared.')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: historyRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;

          if (data == null || data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No gas leakage incidents recorded yet.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final List<Map<String, dynamic>> logs = [];
          data.forEach((key, value) {
            logs.add({
              'id': key,
              'ppm_level': value['ppm_level'] ?? 0,
              'timestamp': value['timestamp'] ?? 'N/A',
              'status': value['status'] ?? 'DANGER',
            });
          });

          logs.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.warning, color: Colors.white),
                  ),
                  title: Text(
                    'Gas Leakage Detected (${log['ppm_level']} PPM)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Time: ${log['timestamp']}'),
                  trailing: const Chip(
                    label: Text('DANGER',
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: Colors.red,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 6. SETTINGS SCREEN (READ-ONLY FOR USERS)
// ==========================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('gas_sensor');

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder(
        stream: dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
          final int threshold = data?['threshold_limit'] ?? 1000;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Threshold limits are managed by system administrators. Below are the current active configurations.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.admin_panel_settings, color: Colors.white),
                    ),
                    title: const Text('Safety Limit (Threshold)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Triggers automatic alarm & exhaust fan'),
                    trailing: Text(
                      '$threshold PPM',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo),
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

// ==========================================
// USER PROFILE SCREEN (SIMPLE ADDRESS ONLY)
// ==========================================
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // MENGAMBIL DATA PROFIL DARI FIREBASE
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _phoneController.text = data['phone_number'] ?? '';
          _addressController.text = data['address_line'] ?? '';
          _postcodeController.text = data['postcode'] ?? '';
          _cityController.text = data['city'] ?? '';
          _stateController.text = data['state'] ?? '';
        });
      }
    }
    setState(() => _isFetching = false);
  }

  // MENYIMPAN DATA PROFIL KE FIREBASE
  Future<void> _saveUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
      await ref.set({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address_line': _addressController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profile',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Avatar Header
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.indigo,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? 'No Email',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information Section
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location & Address Section
                  const Text(
                    'Location & Address Details',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _postcodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Postcode',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Profile Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveUserProfile,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SAVE PROFILE',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('LOG OUT',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}