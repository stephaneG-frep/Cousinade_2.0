import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/user_guide_provider.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class UserGuideScreen extends ConsumerWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode d\'emploi')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _GuideIntroCard(),
          _GuideStepCard(
            number: 1,
            title: 'Se connecter',
            description:
                'Entre ton email et ton mot de passe. Si besoin, utilise "Mot de passe oublie ?".',
            icon: Icons.login_rounded,
          ),
          _GuideStepCard(
            number: 2,
            title: 'Entrer dans ta famille',
            description:
                'Si c\'est la premiere fois, cree ta famille ou rejoins-la avec le code invitation.',
            icon: Icons.groups_2_rounded,
          ),
          _GuideStepCard(
            number: 3,
            title: 'Utiliser les 5 onglets',
            description:
                'Accueil, Famille, Publier, Evenements et Profil sont en bas de l\'ecran.',
            icon: Icons.space_dashboard_rounded,
          ),
          _GuideFeatureCard(
            title: 'Publier un message',
            description:
                'Ouvre "Publier", ecris ton message, ajoute une photo ou une video puis appuie sur Publier.',
            icon: Icons.edit_note_rounded,
          ),
          _GuideFeatureCard(
            title: 'Lire et reagir',
            description:
                'Dans Accueil, ouvre une publication pour voir les details, commenter et liker.',
            icon: Icons.favorite_border_rounded,
          ),
          _GuideFeatureCard(
            title: 'Discuter en prive',
            description:
                'Va dans Famille puis appuie sur la bulle de discussion a cote d\'un membre.',
            icon: Icons.chat_bubble_outline_rounded,
          ),
          _GuideFeatureCard(
            title: 'Creer un evenement',
            description:
                'Dans Evenements, appuie sur "Nouvel evenement", puis renseigne date, lieu et description.',
            icon: Icons.event_note_rounded,
          ),
          _GuideTipsCard(),
          _GuideFaqCard(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton.icon(
          onPressed: () async {
            await ref.read(userGuideProvider.notifier).markGuideSeen();
            if (!context.mounted) return;

            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }

            final authUser = ref.read(currentFirebaseUserProvider);
            context.go(authUser == null ? AppRoutes.login : AppRoutes.home);
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('J\'ai compris'),
        ),
      ),
    );
  }
}

class _GuideIntroCard extends StatelessWidget {
  const _GuideIntroCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue sur Cousinade 2.0',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 6),
                Text(
                  'Ce guide t\'explique l\'application simplement. '
                  'Prends 2 minutes et tu seras a l\'aise.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  final int number;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideFeatureCard extends StatelessWidget {
  const _GuideFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTipsCard extends StatelessWidget {
  const _GuideTipsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined),
              SizedBox(width: 8),
              Text(
                'Petits conseils utiles',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('• Appuie une seule fois puis attends 1 a 2 secondes.'),
          SizedBox(height: 4),
          Text('• Si internet est lent, tire vers le bas pour actualiser.'),
          SizedBox(height: 4),
          Text('• En cas de doute, retourne dans Profil > Parametres.'),
        ],
      ),
    );
  }
}

class _GuideFaqCard extends StatelessWidget {
  const _GuideFaqCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions frequentes',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Je me suis trompe de bouton, que faire ?'),
            children: const [
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Pas grave. Reviens en arriere avec la fleche en haut a gauche ou le bouton retour du telephone.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Je ne vois pas les nouvelles publications'),
            children: const [
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Va dans Accueil et tire la liste vers le bas pour rafraichir.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('J\'ai oublie mon mot de passe'),
            children: const [
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Dans l\'ecran Connexion, appuie sur "Mot de passe oublie ?" puis suis les instructions.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
