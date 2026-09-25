import 'package:flutter/material.dart';

class NotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final bool unread;

  const NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = false,
  });
}

// Dummy placeholder data — wire this up to real data later.
const _dummyNotifications = [
  NotificationItem(
    icon: Icons.login_rounded,
    title: 'New login detected',
    subtitle: 'Your account was accessed from a new device.',
    time: '2m ago',
    unread: true,
  ),
  NotificationItem(
    icon: Icons.check_circle_outline_rounded,
    title: 'Registration successful',
    subtitle: 'Welcome aboard! Your account is ready.',
    time: '1h ago',
    unread: true,
  ),
  NotificationItem(
    icon: Icons.info_outline_rounded,
    title: 'App updated',
    subtitle: 'New features and fixes are now live.',
    time: 'Yesterday',
  ),
];

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: _dummyNotifications.isEmpty
          ? _EmptyState(theme: theme)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _dummyNotifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _dummyNotifications[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.unread
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                        child: Icon(item.icon, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.time,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.unread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}