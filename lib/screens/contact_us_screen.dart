import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const Color lightBlue = Color(0xFF82CAFF);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color darkBlue = Color(0xFF234E70);
  static const Color backgroundBlue = Color(0xFFF4FAFF);
  static const Color cardBorder = Color(0xFFD8EAF6);

  static const String phoneNumber = '0169124146';
  static const String displayPhone = '016-912 4146';
  static const String emailAddress = 'gasdetector7@gmail.com';

  // =========================================================
  // CALL
  // =========================================================

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      final bool launched = await launchUrl(phoneUri);

      if (!launched && context.mounted) {
        _showMessage(
          context,
          'Unable to open the phone application.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'Unable to make the phone call.',
        );
      }
    }
  }

  // =========================================================
  // EMAIL
  // =========================================================

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {
        'subject': 'Gas Leakage Detector Support',
      },
    );

    try {
      final bool launched = await launchUrl(emailUri);

      if (!launched && context.mounted) {
        _showMessage(
          context,
          'Unable to open the email application.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'Unable to open the email application.',
        );
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // BUILD
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
          'Contact Us',
          style: TextStyle(
            color: darkBlue,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          24,
          18,
          35,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =============================================
                // HEADER
                // =============================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        darkBlue,
                        steelBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'How Can We Help?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Contact our support team if you need assistance '
                        'or would like to report an issue with your '
                        'Gas Leakage Detector system.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // =============================================
                // CONTACT INFORMATION
                // =============================================

                const Text(
                  'Contact Information',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                // PHONE
                _contactCard(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: displayPhone,
                  description:
                      'Call our support team for assistance.',
                  buttonText: 'CALL US',
                  onPressed: () => _makePhoneCall(context),
                ),

                const SizedBox(height: 12),

                // EMAIL
                _contactCard(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: emailAddress,
                  description:
                      'Send us an email for support or enquiries.',
                  buttonText: 'SEND EMAIL',
                  onPressed: () => _sendEmail(context),
                ),

                const SizedBox(height: 25),

                // =============================================
                // SUPPORT
                // =============================================

                const Text(
                  'We Can Help With',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cardBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      _supportItem(
                        Icons.sensors_outlined,
                        'Device or sensor issues',
                      ),

                      _divider(),

                      _supportItem(
                        Icons.wifi_outlined,
                        'Device connection problems',
                      ),

                      _divider(),

                      _supportItem(
                        Icons.phone_android_outlined,
                        'Application issues',
                      ),

                      _divider(),

                      _supportItem(
                        Icons.person_outline_rounded,
                        'Account support',
                      ),

                      _divider(),

                      _supportItem(
                        Icons.report_problem_outlined,
                        'Report a system problem',
                      ),

                      _divider(),

                      _supportItem(
                        Icons.help_outline_rounded,
                        'General enquiries',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // =============================================
                // NOTE
                // =============================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cardBorder,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: steelBlue,
                        size: 20,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'When reporting a device problem, please include '
                          'your Device ID and a short description of the issue. '
                          'This will help us identify the problem more quickly.',
                          style: TextStyle(
                            color: Color(0xFF52606D),
                            fontSize: 10,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CONTACT CARD
  // =========================================================

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lightBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: steelBlue,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: steelBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: steelBlue,
              side: const BorderSide(
                color: cardBorder,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUPPORT ITEM
  // =========================================================

  Widget _supportItem(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: lightBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              color: steelBlue,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Icon(
            Icons.check_circle_outline_rounded,
            color: steelBlue,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 47,
      color: Colors.blueGrey.shade50,
    );
  }
}