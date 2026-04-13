import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.initial,
    this.radius = 22,
  });

  final String? imageUrl;
  final String initial;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final safeInitial = initial.trim().isEmpty
        ? '?'
        : initial.trim()[0].toUpperCase();

    final placeholder = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.roseBeige,
      child: Text(
        safeInitial,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: AppColors.darkText),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;

    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, e, _) => placeholder,
        ),
      ),
    );
  }
}
