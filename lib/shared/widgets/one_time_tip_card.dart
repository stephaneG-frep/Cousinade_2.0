import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_card.dart';

class OneTimeTipCard extends StatefulWidget {
  const OneTimeTipCard({
    super.key,
    required this.storageKey,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.actionLabel = 'Compris',
  });

  final String storageKey;
  final String title;
  final String message;
  final IconData icon;
  final String actionLabel;

  @override
  State<OneTimeTipCard> createState() => _OneTimeTipCardState();
}

class _OneTimeTipCardState extends State<OneTimeTipCard> {
  bool? _visible;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(widget.storageKey) ?? false;
    if (!mounted) return;
    setState(() {
      _visible = !seen;
    });
  }

  Future<void> _dismiss() async {
    setState(() {
      _visible = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.storageKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_visible != true) return const SizedBox.shrink();

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(widget.message),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _dismiss,
                    child: Text(widget.actionLabel),
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
