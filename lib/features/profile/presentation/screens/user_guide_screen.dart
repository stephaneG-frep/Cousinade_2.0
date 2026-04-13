import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/user_guide_provider.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/help_action.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class UserGuideScreen extends ConsumerStatefulWidget {
  const UserGuideScreen({super.key});

  @override
  ConsumerState<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends ConsumerState<UserGuideScreen> {
  late final PageController _controller;
  int _index = 0;

  final List<_GuideStep> _steps = const [
    _GuideStep(
      title: 'Bienvenue sur Cousinade 2.0',
      description:
          'Ce guide t\'explique l\'application simplement. '
          'Prends 2 minutes et tu seras a l\'aise.',
      icon: Icons.family_restroom_rounded,
    ),
    _GuideStep(
      title: 'Se connecter',
      description:
          'Entre ton email et ton mot de passe. '
          'Si besoin, utilise "Mot de passe oublie ?".',
      icon: Icons.login_rounded,
    ),
    _GuideStep(
      title: 'Entrer dans ta famille',
      description:
          'Si c\'est la premiere fois, cree ta famille ou rejoins-la '
          'avec le code invitation.',
      icon: Icons.groups_2_rounded,
    ),
    _GuideStep(
      title: 'Utiliser les 5 onglets',
      description:
          'Accueil, Famille, Publier, Evenements et Profil '
          'sont en bas de l\'ecran.',
      icon: Icons.space_dashboard_rounded,
    ),
    _GuideStep(
      title: 'Publier un message',
      description:
          'Ouvre "Publier", ecris ton message, '
          'ajoute une photo ou une video puis appuie sur Publier.',
      icon: Icons.edit_note_rounded,
    ),
    _GuideStep(
      title: 'Lire et reagir',
      description:
          'Dans Accueil, ouvre une publication pour lire, '
          'commenter et liker.',
      icon: Icons.favorite_border_rounded,
    ),
    _GuideStep(
      title: 'Discuter en prive',
      description:
          'Va dans Famille puis appuie sur la bulle de discussion '
          'a cote d\'un membre.',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    _GuideStep(
      title: 'Creer un evenement',
      description:
          'Dans Evenements, appuie sur "Nouvel evenement", '
          'puis renseigne date, lieu et description.',
      icon: Icons.event_note_rounded,
    ),
    _GuideStep(
      title: 'Petits conseils utiles',
      description:
          'Appuie une seule fois puis attends 1 a 2 secondes. '
          'Si internet est lent, tire vers le bas pour actualiser. '
          'En cas de doute, va dans Profil > Parametres.',
      icon: Icons.tips_and_updates_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishGuide() async {
    await ref.read(userGuideProvider.notifier).markGuideSeen();
    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    final authUser = ref.read(currentFirebaseUserProvider);
    context.go(authUser == null ? AppRoutes.login : AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _steps.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode d\'emploi'),
        actions: const [HelpAction()],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: AppCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step.icon,
                            size: 34,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _index == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _index == i
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (_index > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      },
                      child: const Text('Retour'),
                    ),
                  )
                else
                  Expanded(
                    child: TextButton(
                      onPressed: _finishGuide,
                      child: const Text('Passer'),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (isLast) {
                        await _finishGuide();
                        return;
                      }
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                    icon: Icon(
                      isLast ? Icons.check_circle_outline : Icons.arrow_forward,
                    ),
                    label: Text(isLast ? 'J\'ai compris' : 'Suivant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  const _GuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
