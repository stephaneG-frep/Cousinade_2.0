import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/events_providers.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: now,
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (time == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _selectedDate = selected;
      _dateController.text =
          '${date.day}/${date.month}/${date.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selectionne une date')));
      return;
    }

    final error = await ref
        .read(eventsControllerProvider.notifier)
        .createEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          startDate: _selectedDate!,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Creer un evenement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Titre',
                validator: (value) =>
                    Validators.requiredField(value, label: 'Titre'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                validator: (value) =>
                    Validators.requiredField(value, label: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _locationController,
                label: 'Lieu',
                validator: (value) =>
                    Validators.requiredField(value, label: 'Lieu'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _dateController,
                label: 'Date et heure',
                validator: (value) =>
                    Validators.requiredField(value, label: 'Date'),
                readOnly: true,
                onTap: _pickDate,
                prefixIcon: Icons.calendar_month,
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Creer l\'evenement',
                icon: Icons.event,
                isLoading: eventState.isLoading,
                onPressed: _create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
