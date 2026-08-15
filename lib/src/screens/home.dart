import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wardrobe_item.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'settings.dart';
import 'suggestions.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onRateOutfit;
  final VoidCallback onOpenCloset;

  const HomeScreen({
    super.key,
    required this.onRateOutfit,
    required this.onOpenCloset,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final name = state.profile.name;
    final suggestions = state.suggestions(max: 1);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting().toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    letterSpacing: 2.4,
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              name.isEmpty ? 'Stylist mode on' : name,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Hero: rate my outfit
                  Material(
                    color: scheme.inverseSurface,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: onRateOutfit,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rate my outfit',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                            color: scheme.onInverseSurface),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Point the camera at your look and get an instant stylist verdict.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onInverseSurface
                                              .withValues(alpha: 0.75),
                                          height: 1.4,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.photo_camera_outlined,
                                  color: scheme.onPrimary, size: 28),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Pieces',
                          value: '${state.items.length}',
                          icon: Icons.checkroom,
                          onTap: onOpenCloset,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Looks rated',
                          value: '${state.looks.length}',
                          icon: Icons.photo_camera_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Avg score',
                          value: state.looks.isEmpty
                              ? '—'
                              : state.averageLookScore.toStringAsFixed(1),
                          icon: Icons.star_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (suggestions.isNotEmpty) ...[
                    const SectionTitle("Today's pick from your closet"),
                    OutfitCard(suggestion: suggestions.first),
                    const SizedBox(height: 24),
                  ],

                  if (state.looks.isNotEmpty) ...[
                    const SectionTitle('Recent looks'),
                    SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.looks.length.clamp(0, 10),
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) =>
                            _LookCard(look: state.looks[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard(
      {required this.label, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LookCard extends StatelessWidget {
  final Look look;

  const _LookCard({required this.look});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage =
        look.imagePath != null && File(look.imagePath!).existsSync();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: () async {
          final remove = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete this look?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete')),
              ],
            ),
          );
          if (remove == true && context.mounted) {
            await context.read<AppState>().deleteLook(look);
          }
        },
        child: SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: hasImage
                    ? Image.file(File(look.imagePath!), fit: BoxFit.cover)
                    : Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.checkroom,
                            color: scheme.onSurfaceVariant),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(look.score.toStringAsFixed(1),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: scheme.primary)),
                    Flexible(
                      child: Text(
                        look.scheme,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
