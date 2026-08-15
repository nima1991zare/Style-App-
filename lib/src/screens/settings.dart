import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../state/app_state.dart';
import 'onboarding.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Style profile'),
            subtitle: Text(
              '${state.profile.bodyType.label} · ${state.profile.undertone.label} undertone',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(editing: true)),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'APPEARANCE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 2,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          RadioGroup<ThemeMode>(
            groupValue: state.themeMode,
            onChanged: (m) {
              if (m != null) state.setThemeMode(m);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text('Follow system'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text('Ivory (light)'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text('Noir (dark)'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_outline, color: scheme.error),
            title: Text('Clear all data', style: TextStyle(color: scheme.error)),
            subtitle: const Text('Removes every closet piece and rated look'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear everything?'),
                  content: const Text(
                      'Your closet, rated looks and their photos will be permanently deleted. Your style profile is kept.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete all')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<AppState>().clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data cleared.')),
                  );
                }
              }
            },
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Aura Stylist',
            applicationVersion: '1.0.0',
            applicationLegalese:
                'Your personal stylist camera.\nAll analysis runs on-device — photos never leave your phone.',
            child: Text('About Aura Stylist'),
          ),
        ],
      ),
    );
  }
}
