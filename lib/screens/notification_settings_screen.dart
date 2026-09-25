import 'package:flutter/material.dart';
import '../services/app_settings.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SwitchRow(
              notifier: settings.verificationAlerts,
              icon: Icons.fact_check_outlined,
              title: 'Verification updates',
              subtitle: 'Alerts when a verification is completed',
            ),
            _SwitchRow(
              notifier: settings.reminderAlerts,
              icon: Icons.alarm_rounded,
              title: 'Reminders',
              subtitle: 'Reminders for pending visits',
            ),
            _SwitchRow(
              notifier: settings.soundAlerts,
              icon: Icons.volume_up_outlined,
              title: 'Sound',
              subtitle: 'Play a sound for new alerts',
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final ValueNotifier<bool> notifier;
  final IconData icon;
  final String title;
  final String subtitle;

  const _SwitchRow({
    required this.notifier,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, value, child) => SwitchListTile(
          value: value,
          onChanged: (v) => notifier.value = v,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          tileColor: theme.colorScheme.surfaceContainerHigh,
          secondary: Icon(icon, color: theme.colorScheme.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}
