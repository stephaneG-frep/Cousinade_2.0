import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/help_action.dart';
import '../providers/profile_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: const [HelpAction()],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucune notification',
              subtitle: 'Tu verras ici les actualites de ta famille.',
              icon: Icons.notifications_none,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(notificationsProvider.future),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return ListTile(
                  leading: Icon(
                    item.isRead
                        ? Icons.notifications_none
                        : Icons.notifications,
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.body}\n${DateFormatter.shortDateTime(item.createdAt)}',
                  ),
                  isThreeLine: true,
                  onTap: () => ref
                      .read(profileControllerProvider.notifier)
                      .markNotificationRead(item.id),
                );
              },
            ),
          );
        },
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        loading: () => const LoadingWidget(),
      ),
    );
  }
}
