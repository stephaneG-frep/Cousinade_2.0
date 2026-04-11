import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  String _friendlyMessage() {
    final raw = message.replaceFirst('Exception: ', '').trim();
    if (raw.contains('cloud_firestore/failed-precondition')) {
      return 'La base Firestore demande une configuration supplementaire (index).';
    }
    if (raw.contains('permission-denied')) {
      return 'Acces refuse. Verifie les regles Firestore et reconnecte-toi.';
    }
    if (raw.length > 220) {
      return 'Une erreur inattendue est survenue. Reessaye dans un instant.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32),
            const SizedBox(height: 8),
            Text(_friendlyMessage(), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
            ],
          ],
        ),
      ),
    );
  }
}
