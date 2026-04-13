import 'package:flutter/material.dart';

class ApkHelpSheet extends StatelessWidget {
  const ApkHelpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => const ApkHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Text('Installer l\'APK', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          const Text(
            '1. Recois le fichier APK par email ou Bluetooth.\n'
            '2. Ouvre le fichier depuis ton telephone.\n'
            '3. Si Android bloque, autorise "Sources inconnues" pour cette app.\n'
            '4. Appuie sur Installer.\n'
            '5. Ouvre Cousinade 2.0 et inscris-toi.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Astuce : l\'option "Sources inconnues" se trouve dans '
              'Parametres > Securite ou Parametres > Applications.',
            ),
          ),
        ],
      ),
    );
  }
}
