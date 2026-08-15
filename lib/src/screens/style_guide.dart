import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/style_engine.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'onboarding.dart';

class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final guide = bodyTypeGuides[profile.bodyType]!;
    final palette = undertonePalettes[profile.undertone]!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style guide'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(editing: true)),
            ),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Edit profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_outline,
                              color: scheme.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name.isEmpty
                                    ? 'Your profile'
                                    : profile.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${profile.bodyType.label} · ${profile.undertone.label} undertone',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SectionTitle('Your best colors — ${profile.undertone.label} undertone'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          undertoneAdvice[profile.undertone]!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final c in palette)
                              SizedBox(
                                width: 64,
                                child: Column(
                                  children: [
                                    ColorDot(c.color, size: 40),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.name,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SectionTitle('Dress your ${profile.bodyType.label.toLowerCase()} shape'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _chipsBlock(context, 'Reach for', guide.wear,
                            const Color(0xFF5E8C61), Icons.check_circle_outline),
                        const SizedBox(height: 16),
                        _chipsBlock(context, 'Think twice about', guide.avoid,
                            scheme.error, Icons.remove_circle_outline),
                        const SizedBox(height: 16),
                        _chipsBlock(context, 'Flattering necklines',
                            guide.necklines, scheme.primary, Icons.expand_more),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const SectionTitle('Stylist tips'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < guide.tips.length; i++) ...[
                          if (i > 0) const Divider(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 18, color: scheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  guide.tips[i],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.45),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (profile.vibes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionTitle('For your vibe'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (var i = 0; i < profile.vibes.length; i++) ...[
                            if (i > 0) const Divider(height: 20),
                            Builder(builder: (context) {
                              final vibe = profile.vibes.elementAt(i);
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: scheme.primaryContainer
                                          .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      vibe.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              color:
                                                  scheme.onPrimaryContainer),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      vibeAdvice[vibe]!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(height: 1.45),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipsBlock(BuildContext context, String title, List<String> items,
      Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(item,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: color.withValues(alpha: 0.95))),
              ),
          ],
        ),
      ],
    );
  }
}
