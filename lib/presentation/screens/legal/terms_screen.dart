import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _termsUrl = 'https://personalhaven.megnifylabs.com/terms-and-conditions/';
const _privacyPolicyUrl =
    'https://personalhaven.megnifylabs.com/privacy-policy/';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ExternalLegalLink(
      title: 'Terms & Conditions',
      url: _termsUrl,
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ExternalLegalLink(
      title: 'Privacy Policy',
      url: _privacyPolicyUrl,
    );
  }
}

Future<void> openTermsAndConditions(BuildContext context) {
  return _openLegalUrl(context, _termsUrl);
}

Future<void> openPrivacyPolicy(BuildContext context) {
  return _openLegalUrl(context, _privacyPolicyUrl);
}

class _ExternalLegalLink extends StatefulWidget {
  const _ExternalLegalLink({required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<_ExternalLegalLink> createState() => _ExternalLegalLinkState();
}

class _ExternalLegalLinkState extends State<_ExternalLegalLink> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openLegalUrl(context, widget.url);
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.title)));
  }
}

Future<void> _openLegalUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri.parse(url);
  final opened =
      await _tryLaunch(uri, LaunchMode.externalApplication) ||
      await _tryLaunch(uri, LaunchMode.platformDefault);

  if (!opened) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Could not open web address')),
    );
  }
}

Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
  try {
    return await launchUrl(uri, mode: mode);
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
