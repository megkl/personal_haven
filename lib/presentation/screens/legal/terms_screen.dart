import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Terms & Conditions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _LegalContent(content: _termsContent),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _LegalContent(content: _privacyContent),
      ),
    );
  }
}

// ── Shared renderer ───────────────────────────────────────────────────────────

class _LegalContent extends StatelessWidget {
  final List<_Section> content;
  const _LegalContent({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in content) ...[
          if (section.heading != null) ...[
            Text(
              section.heading!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            section.body,
            style: TextStyle(
              fontSize: 14,
              color: context.colors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Last updated: April 2026',
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _Section {
  final String? heading;
  final String body;
  const _Section({this.heading, required this.body});
}

// ── Terms content ─────────────────────────────────────────────────────────────

const _termsContent = [
  _Section(
    body:
        'Welcome to Personal Haven. By creating an account or using our app, you agree to these Terms and Conditions. Please read them carefully.',
  ),
  _Section(
    heading: '1. Acceptance of Terms',
    body:
        'By accessing or using Personal Haven, you confirm that you are at least 13 years old and agree to be bound by these Terms. If you do not agree, please do not use the app.',
  ),
  _Section(
    heading: '2. Account & Security',
    body:
        'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorised use of your account. We use Firebase Authentication for secure sign-in via Google, Apple, or Microsoft.',
  ),
  _Section(
    heading: '3. Subscriptions & Payments',
    body:
        'Personal Haven offers a free 30-day trial on first sign-up. After the trial, continued access requires a paid subscription:\n\n'
        '• Weekly Plan: KES 30 per week\n'
        '• Monthly Plan: KES 100 per month\n\n'
        'Payments are processed via M-Pesa (Safaricom Daraja), card, or USDT. Subscriptions are non-refundable once activated. You may cancel at any time; access continues until the end of the current billing period.',
  ),
  _Section(
    heading: '4. Free Trial',
    body:
        'New users receive one free 30-day trial. The trial is limited to one per account. After expiry, a paid subscription is required to continue using premium features.',
  ),
  _Section(
    heading: '5. Acceptable Use',
    body:
        'You agree not to misuse Personal Haven. Prohibited activities include attempting to reverse-engineer the app, uploading harmful content, or using the service for any unlawful purpose.',
  ),
  _Section(
    heading: '6. Data & Privacy',
    body:
        'Your personal data is stored securely on Google Firebase. We do not sell your data to third parties. Please review our Privacy Policy for full details on how we collect, use, and protect your information.',
  ),
  _Section(
    heading: '7. Intellectual Property',
    body:
        'All content, design, and code within Personal Haven is the property of Personal Haven and is protected by applicable intellectual property laws.',
  ),
  _Section(
    heading: '8. Disclaimer of Warranties',
    body:
        'Personal Haven is provided "as is" without warranties of any kind. We do not guarantee uninterrupted or error-free service. The app is not a substitute for professional medical, financial, or psychological advice.',
  ),
  _Section(
    heading: '9. Limitation of Liability',
    body:
        'To the maximum extent permitted by law, Personal Haven shall not be liable for any indirect, incidental, or consequential damages arising from your use of the app.',
  ),
  _Section(
    heading: '10. Changes to Terms',
    body:
        'We may update these Terms from time to time. Continued use of the app after changes constitutes acceptance of the new Terms.',
  ),
  _Section(
    heading: '11. Contact',
    body:
        'For questions about these Terms, contact us at support@personalhaven.app.',
  ),
];

// ── Privacy Policy content ────────────────────────────────────────────────────

const _privacyContent = [
  _Section(
    body:
        'Personal Haven ("we", "our", "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information.',
  ),
  _Section(
    heading: '1. Information We Collect',
    body:
        'We collect the following information when you use Personal Haven:\n\n'
        '• Account information: name, email address, and profile photo from your chosen sign-in provider (Google, Apple, or Microsoft).\n'
        '• App data: journal entries, mood logs, goals, tasks, food diary entries, calendar events, and budget transactions you create.\n'
        '• Device information: device type and operating system for app functionality.\n'
        '• Payment information: M-Pesa transaction references (we do not store card numbers or M-Pesa PINs).',
  ),
  _Section(
    heading: '2. How We Use Your Information',
    body:
        'We use your information to:\n\n'
        '• Provide and improve the Personal Haven service.\n'
        '• Sync your data across devices via Firebase.\n'
        '• Process subscription payments.\n'
        '• Send important service notifications.\n'
        '• Respond to support requests.',
  ),
  _Section(
    heading: '3. Data Storage & Security',
    body:
        'Your data is stored on Google Firebase (Firestore), which is encrypted at rest and in transit. We implement industry-standard security measures including biometric app lock and Firebase security rules that ensure only you can access your data.',
  ),
  _Section(
    heading: '4. Data Sharing',
    body:
        'We do not sell, trade, or rent your personal information to third parties. We may share data with:\n\n'
        '• Firebase / Google: for data storage and authentication.\n'
        '• Safaricom: for M-Pesa payment processing.\n'
        '• Law enforcement: if required by applicable law.',
  ),
  _Section(
    heading: '5. Your Rights',
    body:
        'You have the right to:\n\n'
        '• Access the personal data we hold about you.\n'
        '• Request correction of inaccurate data.\n'
        '• Request deletion of your account and all associated data.\n'
        '• Export your data (feature coming soon).\n\n'
        'To exercise these rights, contact us at support@personalhaven.app.',
  ),
  _Section(
    heading: '6. Data Retention',
    body:
        'We retain your data for as long as your account is active. If you delete your account, all personal data is permanently removed within 30 days.',
  ),
  _Section(
    heading: '7. Children\'s Privacy',
    body:
        'Personal Haven is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
  ),
  _Section(
    heading: '8. Cookies & Analytics',
    body:
        'The app does not use cookies. We may use anonymised analytics to understand app usage patterns and improve the service.',
  ),
  _Section(
    heading: '9. Changes to This Policy',
    body:
        'We may update this Privacy Policy periodically. We will notify you of significant changes via the app. Continued use after changes constitutes acceptance.',
  ),
  _Section(
    heading: '10. Contact Us',
    body:
        'For privacy-related questions or requests, contact:\n\nsupport@personalhaven.app',
  ),
];
