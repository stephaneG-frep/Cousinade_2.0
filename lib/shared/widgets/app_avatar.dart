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

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.roseBeige,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              safeInitial,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.darkText),
            )
          : null,
    );
  }
}
