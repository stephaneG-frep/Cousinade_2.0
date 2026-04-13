import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../../../shared/widgets/help_action.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/presentation/providers/events_providers.dart';
import '../../../feed/presentation/providers/feed_providers.dart';
import '../../../family/presentation/providers/family_providers.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final postsAsync = ref.watch(familyPostsProvider);
    final eventsAsync = ref.watch(familyEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: const [HelpAction()],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const ErrorStateWidget(message: 'Utilisateur introuvable');
          }
          if (user.role != 'admin') {
            return const ErrorStateWidget(
              message: 'Acces reserve aux administrateurs',
            );
          }

          final membersCount = membersAsync.valueOrNull?.length;
          final postsCount = postsAsync.valueOrNull?.length;
          final eventsCount = eventsAsync.valueOrNull?.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: familyAsync.when(
                  data: (family) {
                    if (family == null) {
                      return const Text('Famille introuvable');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('Code famille: ${family.inviteCode}'),
                        const SizedBox(height: 6),
                        Text('Membres: ${family.membersCount}'),
                      ],
                    );
                  },
                  error: (error, _) =>
                      ErrorStateWidget(message: error.toString()),
                  loading: () => const LoadingWidget(),
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatChip(context, 'Membres', membersCount),
                    _buildStatChip(context, 'Posts', postsCount),
                    _buildStatChip(context, 'Evenements', eventsCount),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: membersAsync.when(
                  data: (members) {
                    if (members.isEmpty) {
                      return const Text('Aucun membre');
                    }
                    final adminsCount = members
                        .where((member) => member.role == 'admin')
                        .length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membres de la famille',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...members.map((member) {
                          return UserTile(
                            user: member,
                            trailing: member.id == user.id
                                ? null
                                : PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'promote' ||
                                          value == 'demote') {
                                        final newRole = value == 'promote'
                                            ? 'admin'
                                            : 'member';
                                        if (newRole == 'member' &&
                                            member.role == 'admin' &&
                                            adminsCount <= 1) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Il faut garder au moins un admin',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        final error = await ref
                                            .read(
                                              familyControllerProvider.notifier,
                                            )
                                            .updateMemberRole(
                                              memberId: member.id,
                                              role: newRole,
                                            );
                                        if (!context.mounted) return;
                                        if (error != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(error)),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                newRole == 'admin'
                                                    ? 'Admin attribue'
                                                    : 'Role membre attribue',
                                              ),
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      if (value == 'remove') {
                                        final confirm =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Retirer le membre',
                                              ),
                                              content: Text(
                                                'Retirer ${member.displayName} de la famille ?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text('Annuler'),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: const Text('Retirer'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (confirm != true) return;
                                        final error = await ref
                                            .read(
                                              familyControllerProvider.notifier,
                                            )
                                            .removeMember(member.id);
                                        if (!context.mounted) return;
                                        if (error != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(error)),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Membre retire'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (member.role != 'admin')
                                        const PopupMenuItem<String>(
                                          value: 'promote',
                                          child: Text('Passer admin'),
                                        ),
                                      if (member.role == 'admin')
                                        PopupMenuItem<String>(
                                          value: 'demote',
                                          enabled: adminsCount > 1,
                                          child: Text(
                                            adminsCount > 1
                                                ? 'Passer membre'
                                                : 'Gardez un admin',
                                          ),
                                        ),
                                      const PopupMenuItem<String>(
                                        value: 'remove',
                                        child: Text('Retirer'),
                                      ),
                                    ],
                                  ),
                          );
                        }),
                      ],
                    );
                  },
                  error: (error, _) =>
                      ErrorStateWidget(message: error.toString()),
                  loading: () => const LoadingWidget(),
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return const Text('Aucune publication');
                    }
                    final limited = posts.take(12).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publications recentes',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...limited.map((post) {
                          final text = (post.text ?? '').trim();
                          final preview = text.isEmpty
                              ? 'Publication media'
                              : text;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preview,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${post.authorName} · ${DateFormatter.shortDateTime(post.createdAt)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Supprimer la publication',
                                          ),
                                          content: const Text(
                                            'Cette action est definitive.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Annuler'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text('Supprimer'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (confirm != true) return;
                                    final error = await ref
                                        .read(feedControllerProvider.notifier)
                                        .deletePost(post);
                                    if (!context.mounted) return;
                                    if (error != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Publication supprimee',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  error: (error, _) =>
                      ErrorStateWidget(message: error.toString()),
                  loading: () => const LoadingWidget(),
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const Text('Aucun evenement');
                    }
                    final limited = events.take(8).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evenements',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...limited.map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormatter.shortDateTime(
                                          event.startDate,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Supprimer l\'evenement',
                                          ),
                                          content: const Text(
                                            'Cette action est definitive.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Annuler'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text('Supprimer'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (confirm != true) return;
                                    final error = await ref
                                        .read(
                                          eventsControllerProvider.notifier,
                                        )
                                        .deleteEvent(event);
                                    if (!context.mounted) return;
                                    if (error != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Evenement supprime',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  error: (error, _) =>
                      ErrorStateWidget(message: error.toString()),
                  loading: () => const LoadingWidget(),
                ),
              ),
            ],
          );
        },
        error: (error, _) => ErrorStateWidget(message: error.toString()),
        loading: () => const LoadingWidget(),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    int? value,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value == null ? '...' : value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
