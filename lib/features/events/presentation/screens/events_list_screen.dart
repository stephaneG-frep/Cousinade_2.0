import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/event_card.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/events_providers.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(familyEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Evenements')),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return EmptyStateWidget(
              title: 'Aucun evenement',
              subtitle: 'Cree le prochain moment familial.',
              icon: Icons.event_available_outlined,
              action: FilledButton.icon(
                onPressed: () async {
                  final created = await context.push<bool>(
                    AppRoutes.createEvent,
                  );
                  if (created == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Evenement cree')),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Creer un evenement'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(familyEventsProvider.future),
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return EventCard(
                  event: event,
                  onTap: () =>
                      context.push(AppRoutes.eventDetailPath(event.id)),
                );
              },
            ),
          );
        },
        error: (error, _) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(familyEventsProvider),
        ),
        loading: () =>
            const LoadingWidget(message: 'Chargement des evenements...'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'events_create_fab',
        onPressed: () async {
          final created = await context.push<bool>(AppRoutes.createEvent);
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Evenement cree')));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvel evenement'),
      ),
    );
  }
}
