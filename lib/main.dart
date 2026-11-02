import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4682B4),
          primary: const Color(0xFF4682B4),
          secondary: const Color(0xFF82CAFF),
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF4FAFF),
        useMaterial3: true,
      ),

      home: const AuthWrapper(),
    );
  }
}

// =============================================================
// AUTH WRAPPER
// =============================================================

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // =====================================================
        // LOADING
        // =====================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
                Color(0xFFF4FAFF),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4682B4),
              ),
            ),
          );
        }

        // =====================================================
        // NOT LOGGED IN
        // =====================================================

        final User? user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        // =====================================================
        // CHECK SIGN-IN PROVIDER
        // =====================================================

        final bool signedInWithPassword =
            user.providerData.any(
          (provider) =>
              provider.providerId == 'password',
        );

        // =====================================================
        // EMAIL/PASSWORD ACCOUNT IS NOT VERIFIED
        // =====================================================

        if (signedInWithPassword &&
            !user.emailVerified) {
          return const UnverifiedEmailScreen();
        }

        // =====================================================
        // VERIFIED USER
        // =====================================================

        return const MainNavigationScreen();
      },
    );
  }
}

// =============================================================
// UNVERIFIED EMAIL SCREEN
// =============================================================

class UnverifiedEmailScreen
    extends StatefulWidget {
  const UnverifiedEmailScreen({
    super.key,
  });

  @override
  State<UnverifiedEmailScreen>
      createState() =>
          _UnverifiedEmailScreenState();
}

class _UnverifiedEmailScreenState
    extends State<UnverifiedEmailScreen> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _checking = false;
  bool _resending = false;

  static const Color lightBlue =
      Color(0xFF82CAFF);

  static const Color steelBlue =
      Color(0xFF4682B4);

  static const Color darkBlue =
      Color(0xFF234E70);

  static const Color backgroundBlue =
      Color(0xFFF4FAFF);

  static const Color cardBorder =
      Color(0xFFD8EAF6);

  // =========================================================
  // CHECK EMAIL VERIFICATION
  // =========================================================

  Future<void> _checkVerification() async {
    if (_checking) return;

    setState(() {
      _checking = true;
    });

    try {
      await _auth.currentUser?.reload();

      final User? refreshedUser =
          _auth.currentUser;

      if (refreshedUser == null) {
        return;
      }

      if (refreshedUser.emailVerified) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Email verified successfully.',
            ),
          ),
        );

        // idTokenChanges will cause AuthWrapper
        // to rebuild after token refresh.
        await refreshedUser
            .getIdToken(true);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Your email has not been verified yet. '
              'Please open the verification link sent to your email.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Unable to check verification status.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  // =========================================================
  // RESEND VERIFICATION EMAIL
  // =========================================================

  Future<void> _resendVerification() async {
    if (_resending) return;

    final User? user =
        _auth.currentUser;

    if (user == null) return;

    setState(() {
      _resending = true;
    });

    try {
      await user.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Verification email sent to ${user.email ?? 'your email'}.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message =
          e.message ??
              'Unable to resend verification email.';

      if (e.code ==
          'too-many-requests') {
        message =
            'Too many requests. Please wait before trying again.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  // =========================================================
  // LOG OUT
  // =========================================================

  Future<void> _logout() async {
    await _auth.signOut();

    // AuthWrapper automatically shows
    // LoginScreen after sign out.
  }

  // =========================================================
  // PAGE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final User? user =
        _auth.currentUser;

    final String email =
        user?.email ??
            'your email address';

    return Scaffold(
      backgroundColor: backgroundBlue,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 500,
              ),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  28,
                  34,
                  28,
                  30,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    12,
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
                      blurRadius: 18,
                      offset:
                          const Offset(
                        0,
                        5,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // =========================================
                    // ICON
                    // =========================================

                    Container(
                      width: 82,
                      height: 82,
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
                            .mark_email_unread_outlined,
                        color:
                            steelBlue,
                        size: 40,
                      ),
                    ),

                    const SizedBox(
                      height: 23,
                    ),

                    // =========================================
                    // TITLE
                    // =========================================

                    const Text(
                      'Verify your email',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 23,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'We sent a verification link to',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors
                            .blueGrey
                            .shade500,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      email,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: darkBlue,
                        fontSize: 13,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Text(
                      'Open your email and click the verification link. '
                      'After verifying your email, return to the app '
                      'and press the button below.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors
                            .blueGrey
                            .shade400,
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    // =========================================
                    // CHECK BUTTON
                    // =========================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 50,
                      child:
                          ElevatedButton(
                        onPressed: _checking
                            ? null
                            : _checkVerification,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              darkBlue,
                          foregroundColor:
                              Colors.white,
                          disabledBackgroundColor:
                              darkBlue
                                  .withOpacity(
                            0.5,
                          ),
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                        ),
                        child: _checking
                            ? const SizedBox(
                                width: 20,
                                height:
                                    20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors
                                          .white,
                                ),
                              )
                            : const Text(
                                'I HAVE VERIFIED MY EMAIL',
                                style:
                                    TextStyle(
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                  letterSpacing:
                                      0.3,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =========================================
                    // RESEND
                    // =========================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 48,
                      child:
                          OutlinedButton(
                        onPressed:
                            _resending
                                ? null
                                : _resendVerification,
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              steelBlue,
                          side:
                              const BorderSide(
                            color:
                                cardBorder,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                        ),
                        child: Text(
                          _resending
                              ? 'SENDING...'
                              : 'RESEND VERIFICATION EMAIL',
                          style:
                              const TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 13,
                    ),

                    // =========================================
                    // LOGOUT
                    // =========================================

                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons
                            .logout_rounded,
                        size: 17,
                      ),
                      label: const Text(
                        'Use a different account',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                      style:
                          TextButton.styleFrom(
                        foregroundColor:
                            Colors
                                .blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}