import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';

class HelpAction extends StatelessWidget {
  const HelpAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(AppRoutes.userGuide),
      icon: const Icon(Icons.help_outline),
      tooltip: 'Mode d\'emploi',
    );
  }
}
