import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // =========================================================
  // COLORS
  // =========================================================

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);
  static const Color backgroundBlue = Color(0xFFF4FAFF);
  static const Color cardBorder = Color(0xFFD8EAF6);

  // =========================================================
  // EMAIL REGISTRATION
  // =========================================================

  Future<void> _registerWithEmail() async {
    FocusScope.of(context).unfocus();

    final String email =
        _emailController.text.trim();

    final String password =
        _passwordController.text.trim();

    final String confirmPassword =
        _confirmPasswordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        'Please complete all fields.',
      );
      return;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must contain at least 6 characters.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Passwords do not match.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create Firebase account.
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message:
              'Unable to create your account.',
        );
      }

      // Send verification email.
      await user.sendEmailVerification();

      if (!mounted) return;

      // Show verification page.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: email,
          ),
        ),
      );

      // Check verification again after
      // returning from verification screen.
      await user.reload();

      final User? refreshedUser =
          _auth.currentUser;

      if (refreshedUser?.emailVerified ==
          true) {
        if (!mounted) return;

        // Close RegisterScreen.
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message =
          e.message ?? 'Registration failed.';

      if (e.code == 'email-already-in-use') {
        message =
            'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message =
            'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message =
            'Please use a stronger password.';
      } else if (e.code ==
          'operation-not-allowed') {
        message =
            'Email registration is currently unavailable.';
      }

      if (mounted) {
        _showMessage(message);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // GOOGLE
  // =========================================================

Future<void> _continueWithGoogle() async {
  if (_isLoading) return;

  setState(() {
    _isLoading = true;
  });

  try {
    UserCredential userCredential;

    // =====================================================
    // WEB - EDGE / CHROME
    // =====================================================

    if (kIsWeb) {
      final GoogleAuthProvider googleProvider =
          GoogleAuthProvider();

      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      userCredential =
          await FirebaseAuth.instance.signInWithPopup(
        googleProvider,
      );
    }

    // =====================================================
    // ANDROID / IOS
    // =====================================================

    else {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      userCredential =
          await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
    }

    final User? user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-user-not-found',
        message: 'Unable to sign in with Google.',
      );
    }

    if (!mounted) return;

    _showMessage(
      'Welcome ${user.displayName ?? user.email ?? ''}!',
    );

    // DO NOT manually navigate to Dashboard.
    //
    // AuthWrapper detects the Firebase user and automatically
    // opens MainNavigationScreen.
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message =
        e.message ?? 'Google Sign-In failed.';

    if (e.code == 'popup-closed-by-user') {
      message = 'Google Sign-In was cancelled.';
    } else if (e.code == 'account-exists-with-different-credential') {
      message =
          'An account already exists with this email using another sign-in method.';
    }

    _showMessage(message);
  } catch (e) {
    if (!mounted) return;

    _showMessage(
      'Google Sign-In failed. Please try again.',
    );

    debugPrint(
      'Google Sign-In Error: $e',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 0,
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // HEADER
                  // ==========================================

                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          lightBlue.withOpacity(
                        0.22,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .shield_outlined,
                      color: steelBlue,
                      size: 32,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Create your account',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 26,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'Create an account to monitor your gas leakage detector and receive safety alerts.',
                    style: TextStyle(
                      color: Colors
                          .blueGrey.shade500,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==========================================
                  // GOOGLE BUTTON
                  // ==========================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : _continueWithGoogle,
                      style:
                          OutlinedButton.styleFrom(
                        backgroundColor:
                            Colors.white,
                        foregroundColor:
                            darkBlue,
                        side: const BorderSide(
                          color: cardBorder,
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
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Text(
                            'G',
                            style: TextStyle(
                              color: Color(
                                0xFF4285F4,
                              ),
                              fontSize: 20,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==========================================
                  // OR
                  // ==========================================

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors
                              .blueGrey
                              .shade100,
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 15,
                        ),
                        child: Text(
                          'OR CONTINUE WITH EMAIL',
                          style: TextStyle(
                            color: Colors
                                .blueGrey
                                .shade400,
                            fontSize: 9,
                            fontWeight:
                                FontWeight
                                    .w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors
                              .blueGrey
                              .shade100,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ==========================================
                  // EMAIL
                  // ==========================================

                  const Text(
                    'Email Address',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller:
                        _emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        _inputDecoration(
                      hint:
                          'Enter your email address',
                      icon: Icons
                          .email_outlined,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // PASSWORD
                  // ==========================================

                  const Text(
                    'Password',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller:
                        _passwordController,
                    obscureText:
                        _obscurePassword,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        _inputDecoration(
                      hint:
                          'Minimum 6 characters',
                      icon:
                          Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                          color: Colors
                              .blueGrey
                              .shade400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // CONFIRM PASSWORD
                  // ==========================================

                  const Text(
                    'Confirm Password',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller:
                        _confirmPasswordController,
                    obscureText:
                        _obscureConfirmPassword,
                    textInputAction:
                        TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isLoading) {
                        _registerWithEmail();
                      }
                    },
                    decoration:
                        _inputDecoration(
                      hint:
                          'Enter your password again',
                      icon:
                          Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                          color: Colors
                              .blueGrey
                              .shade400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons
                            .verified_user_outlined,
                        size: 15,
                        color: Colors
                            .blueGrey.shade400,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'A verification link will be sent to your email after registration.',
                          style: TextStyle(
                            color: Colors
                                .blueGrey
                                .shade400,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ==========================================
                  // CREATE ACCOUNT
                  // ==========================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _registerWithEmail,
                      style:
                          ElevatedButton.styleFrom(
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color: Colors
                                    .white,
                              ),
                            )
                          : const Text(
                              'CREATE ACCOUNT',
                              style:
                                  TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                letterSpacing:
                                    0.4,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==========================================
                  // SIGN IN
                  // ==========================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Colors
                              .blueGrey
                              .shade500,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: steelBlue,
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INPUT STYLE
  // =========================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color:
            Colors.blueGrey.shade300,
        fontSize: 12,
      ),
      prefixIcon: Icon(
        icon,
        color: steelBlue,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: cardBorder,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: steelBlue,
          width: 1.5,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(8),
        borderSide:
            const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }
}

// =============================================================
// VERIFY EMAIL SCREEN
// =============================================================

class VerifyEmailScreen
    extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailScreen>
      createState() =>
          _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends State<VerifyEmailScreen> {
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

  // =========================================================
  // CHECK VERIFICATION
  // =========================================================

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
    });

    try {
      await _auth.currentUser?.reload();

      final User? user =
          _auth.currentUser;

      if (user?.emailVerified == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Email verified successfully.',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Your email has not been verified yet. Please check your inbox.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  // =========================================================
  // RESEND
  // =========================================================

  Future<void> _resendEmail() async {
    setState(() {
      _resending = true;
    });

    try {
      await _auth.currentUser
          ?.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Verification email sent again.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Unable to resend verification email.',
          ),
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
  // PAGE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 0,
        title: const Text(
          'Verify Email',
          style: TextStyle(
            color: darkBlue,
            fontSize: 18,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(25),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 500,
            ),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(
                30,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: const Color(
                    0xFFD8EAF6,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration:
                        BoxDecoration(
                      color: lightBlue
                          .withOpacity(
                        0.20,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .mark_email_read_outlined,
                      color: steelBlue,
                      size: 40,
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  const Text(
                    'Check your email',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w800,
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
                    widget.email,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: darkBlue,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    'Open the email and click the verification link. Then return here and press the button below.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors
                          .blueGrey
                          .shade400,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  SizedBox(
                    width: double.infinity,
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
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color: Colors
                                    .white,
                              ),
                            )
                          : const Text(
                              'I HAVE VERIFIED MY EMAIL',
                              style:
                                  TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextButton(
                    onPressed: _resending
                        ? null
                        : _resendEmail,
                    child: Text(
                      _resending
                          ? 'Sending...'
                          : 'Resend verification email',
                      style:
                          const TextStyle(
                        color: steelBlue,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}