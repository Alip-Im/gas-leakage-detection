import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC54U2VaMpbgiNGmcaIhvWwOnS157xrojs",
      authDomain: "gas-leakage-detection-9391e.firebaseapp.com",
      databaseURL:
          "https://gas-leakage-detection-9391e-default-rtdb.firebaseio.com",
      projectId: "gas-leakage-detection-9391e",
      storageBucket:
          "gas-leakage-detection-9391e.firebasestorage.app",
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
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
