import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';

class ShareAppSheet extends StatelessWidget {
  const ShareAppSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => const ShareAppSheet(),
    );
  }

  Future<void> _sendSms(BuildContext context) async {
    final uri = Uri(
      scheme: 'sms',
      queryParameters: {'body': AppStrings.appShareMessage},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError(context);
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Cousinade 2.0',
        'body': AppStrings.appShareMessage,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError(context);
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: AppStrings.appDownloadLink),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copie')),
    );
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir l\'application')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Partager l\'application',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: const Text(
              'Choisis comment envoyer le lien a ta famille.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sms_outlined),
            title: const Text('SMS'),
            onTap: () => _sendSms(context),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            onTap: () => _sendEmail(context),
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copier le lien'),
            onTap: () => _copyLink(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
