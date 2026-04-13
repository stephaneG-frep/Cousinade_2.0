import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/one_time_tip_card.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../../../shared/widgets/help_action.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../providers/family_providers.dart';

class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() =>
      _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final conversationId = await ref
        .read(chatControllerProvider.notifier)
        .startConversationWith(userId);

    if (conversationId != null && context.mounted) {
      context.push(AppRoutes.chatPath(conversationId));
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir la conversation')),
      );
    }
  }

  bool _matches(String query, String text) {
    return text.toLowerCase().contains(query.toLowerCase());
  }

  Future<void> _copyInviteCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code famille copie')));
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final currentUser = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Famille'),
        actions: [
          const HelpAction(),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            final family = familyAsync.valueOrNull;
            return EmptyStateWidget(
              title: 'Aucun membre',
              subtitle: family == null
                  ? 'La famille est introuvable, on va la recreer.'
                  : 'Invite un proche avec ton code famille.',
              icon: Icons.group_outlined,
              action: family == null
                  ? FilledButton.icon(
                      onPressed: () async {
                        final error = await ref
                            .read(familyControllerProvider.notifier)
                            .autoJoinDefaultFamily();
                        if (!context.mounted) return;
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Famille recreee'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Recreer la famille'),
                    )
                  : FilledButton.icon(
                      onPressed: () =>
                          _copyInviteCode(context, family.inviteCode),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier le code'),
                    ),
            );
          }

          final filteredMembers = _query.isEmpty
              ? members
              : members.where((member) {
                  return _matches(_query, member.displayName) ||
                      _matches(_query, member.email);
                }).toList();
          if (filteredMembers.isEmpty) {
            return EmptyStateWidget(
              title: 'Aucun resultat',
              subtitle: 'Essaie un autre prenom.',
              icon: Icons.search_off_outlined,
            );
          }
          final adminsCount =
              members.where((member) => member.role == 'admin').length;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(familyMembersProvider.future),
            child: ListView.builder(
              itemCount: filteredMembers.length + 3,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const OneTimeTipCard(
                    storageKey: 'tip_family',
                    title: 'Espace famille',
                    message:
                        'Retrouve ici tous les membres. Appuie sur la bulle pour discuter en prive.',
                    icon: Icons.groups_2_outlined,
                  );
                }
                if (index == 1) {
                  final family = familyAsync.valueOrNull;
                  if (family == null) {
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Famille introuvable',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'On va recreer la famille principale.',
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              final error = await ref
                                  .read(
                                    familyControllerProvider.notifier,
                                  )
                                  .autoJoinDefaultFamily();
                              if (!context.mounted) return;
                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error)),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Famille recreee'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Recreer la famille'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                if (index == 2) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un membre...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  );
                }
                final member = filteredMembers[index - 3];
                final isAdmin = currentUser?.role == 'admin';
                return UserTile(
                  user: member,
                  trailing: member.id == currentUser?.id
                      ? const SizedBox.shrink()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () =>
                                  _openChat(context, ref, member.id),
                            ),
                            if (isAdmin)
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'promote' ||
                                      value == 'demote') {
                                    final newRole =
                                        value == 'promote' ? 'admin' : 'member';
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
                                  }
                                  if (value == 'remove') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title:
                                              const Text('Retirer le membre'),
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
                                                  Navigator.of(context).pop(
                                                true,
                                              ),
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
                          ],
                        ),
                );
              },
            ),
          );
        },
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(familyMembersProvider);
            ref.invalidate(currentFamilyProvider);
          },
        ),
        loading: () =>
            const LoadingWidget(message: 'Chargement des membres...'),
      ),
      floatingActionButton: null,
    );
  }
}
