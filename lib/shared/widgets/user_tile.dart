import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'app_avatar.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, this.trailing, this.onTap});

  final UserModel user;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AppAvatar(initial: user.displayName, imageUrl: user.avatarUrl),
      title: Text(user.displayName),
      subtitle: Text(user.role == 'admin' ? 'Administrateur' : 'Membre'),
      trailing: trailing,
    );
  }
}
