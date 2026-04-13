import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/last_seen_service.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/event_card.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/one_time_tip_card.dart';
import '../../../../shared/widgets/help_action.dart';
import '../providers/events_providers.dart';

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _loadLastSeen();
  }

  Future<void> _loadLastSeen() async {
    final lastSeen = await LastSeenService.getLastSeen(
      LastSeenService.eventsKey,
    );
    if (!mounted) return;
    setState(() {
      _lastSeen = lastSeen;
    });
    await LastSeenService.setLastSeen(
      LastSeenService.eventsKey,
      DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(familyEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evenements'),
        actions: const [HelpAction()],
      ),
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
              itemCount: events.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const OneTimeTipCard(
                    storageKey: 'tip_events',
                    title: 'Evenements',
                    message:
                        'Cree un evenement pour reunir la famille et partage les details ici.',
                    icon: Icons.event_available_outlined,
                  );
                }

                final event = events[index - 1];
                final isNew =
                    _lastSeen != null && event.createdAt.isAfter(_lastSeen!);
                return EventCard(
                  event: event,
                  isNew: isNew,
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
