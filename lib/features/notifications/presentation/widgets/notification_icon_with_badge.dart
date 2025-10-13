import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badges/badges.dart' as badges;
import 'package:piv_app/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:piv_app/features/notifications/presentation/bloc/notification_state.dart';
import 'package:piv_app/features/notifications/presentation/pages/notification_list_page.dart';

class NotificationIconWithBadge extends StatelessWidget {
  final Color iconColor;

  const NotificationIconWithBadge({
    super.key,
    this.iconColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationLoaded) {
          unreadCount = state.unreadCount;
        }

        return badges.Badge(
          position: badges.BadgePosition.topEnd(top: 0, end: 3),
          badgeContent: Text(
            unreadCount > 9 ? '9+' : unreadCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          showBadge: unreadCount > 0,
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: iconColor),
            onPressed: () {
              Navigator.of(context).push(NotificationListPage.route());
            },
          ),
        );
      },
    );
  }
}