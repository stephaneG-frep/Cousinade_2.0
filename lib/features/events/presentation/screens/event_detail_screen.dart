import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/help_action.dart';
import '../providers/events_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail evenement'),
        actions: const [HelpAction()],
      ),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Evenement introuvable'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(event.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined),
                  const SizedBox(width: 8),
                  Text(DateFormatter.shortDateTime(event.startDate)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location)),
                ],
              ),
              const SizedBox(height: 18),
              Text(event.description),
            ],
          );
        },
        error: (error, _) => ErrorStateWidget(message: error.toString()),
        loading: () => const LoadingWidget(),
      ),
    );
  }
}
