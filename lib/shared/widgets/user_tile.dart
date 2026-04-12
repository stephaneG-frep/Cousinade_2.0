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
    final isOnline = user.isOnlineNow;
    return ListTile(
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(initial: user.displayName, imageUrl: user.avatarUrl),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isOnline ? Colors.greenAccent.shade400 : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        user.displayName.trim().isEmpty ? user.email : user.displayName,
      ),
      subtitle: Text(
        isOnline
            ? 'En ligne'
            : (user.role == 'admin' ? 'Administrateur' : 'Membre'),
      ),
      trailing: trailing,
    );
  }
}
