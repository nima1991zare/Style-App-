import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  /// When true, the screen edits the existing profile instead of first-run.
  final bool editing;

  const OnboardingScreen({super.key, this.editing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _step = 0;

  late final TextEditingController _name;
  BodyType? _bodyType;
  int? _veins; // 0 warm, 1 cool, 2 neutral
  int? _jewelry;
  final Set<StyleVibe> _vibes = {};

  static const _steps = 5;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _name = TextEditingController(text: profile.name);
    if (widget.editing) {
      _bodyType = profile.bodyType;
      _vibes.addAll(profile.vibes);
      _veins = profile.undertone.index == 0 ? 0 : (profile.undertone.index == 1 ? 1 : 2);
      _jewelry = _veins;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _page.dispose();
    super.dispose();
  }

  Undertone get _undertone {
    final votes = [_veins ?? 2, _jewelry ?? 2];
    final warm = votes.where((v) => v == 0).length;
    final cool = votes.where((v) => v == 1).length;
    if (warm > cool) return Undertone.warm;
    if (cool > warm) return Undertone.cool;
    return Undertone.neutral;
  }

  bool get _canContinue => switch (_step) {
        0 => true,
        1 => true,
        2 => _bodyType != null,
        3 => _veins != null && _jewelry != null,
        4 => _vibes.isNotEmpty,
        _ => true,
      };

  Future<void> _next() async {
    if (_step < _steps - 1) {
      setState(() => _step++);
      _page.animateToPage(_step,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      final state = context.read<AppState>();
      await state.saveProfile(Profile(
        name: _name.text.trim(),
        bodyType: _bodyType ?? BodyType.rectangle,
        undertone: _undertone,
        vibes: {..._vibes},
        onboarded: true,
      ));
      if (mounted && widget.editing) Navigator.of(context).pop();
    }
  }

  void _back() {
    if (_step == 0) {
      if (widget.editing) Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _page.animateToPage(_step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (_step > 0 || widget.editing)
                    IconButton(
                        onPressed: _back, icon: const Icon(Icons.arrow_back))
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _steps,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: scheme.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _welcome(context),
                  _nameStep(context),
                  _bodyStep(context),
                  _undertoneStep(context),
                  _vibesStep(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canContinue ? _next : null,
                  child: Text(_step == _steps - 1
                      ? (widget.editing ? 'Save profile' : 'Enter your atelier')
                      : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pad(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: child,
      );

  Widget _welcome(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _pad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.auto_awesome, size: 36, color: scheme.primary),
        ),
        const SizedBox(height: 28),
        Text('Aura Stylist', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 14),
        Text(
          'Your personal stylist, in your pocket.\n\nRate any outfit with the camera, get color and silhouette advice tuned to your body type, and discover new combinations hiding in your own wardrobe.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: scheme.onSurfaceVariant, height: 1.55),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Everything runs on your device. Your photos never leave it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _nameStep(BuildContext context) {
    return _pad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('What should we\ncall you?',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name (optional)'),
        ),
      ],
    ));
  }

  Widget _bodyStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _pad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your silhouette', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Pick the shape closest to yours — every recommendation is tailored to it.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        for (final type in BodyType.values) ...[
          _SelectCard(
            selected: _bodyType == type,
            title: type.label,
            subtitle: type.description,
            onTap: () => setState(() => _bodyType = type),
          ),
          const SizedBox(height: 10),
        ],
      ],
    ));
  }

  Widget _undertoneStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _pad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your undertone', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Two quick questions to find the colors that make you glow.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text('The veins on your wrist look…',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _SelectCard(
          selected: _veins == 0,
          title: 'Greenish',
          subtitle: 'Leaning olive or green',
          onTap: () => setState(() => _veins = 0),
        ),
        const SizedBox(height: 8),
        _SelectCard(
          selected: _veins == 1,
          title: 'Blue or purple',
          subtitle: 'Clearly blue-toned',
          onTap: () => setState(() => _veins = 1),
        ),
        const SizedBox(height: 8),
        _SelectCard(
          selected: _veins == 2,
          title: 'A mix / hard to tell',
          subtitle: 'Somewhere in between',
          onTap: () => setState(() => _veins = 2),
        ),
        const SizedBox(height: 24),
        Text('Which jewelry flatters you more?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _SelectCard(
          selected: _jewelry == 0,
          title: 'Gold',
          subtitle: 'Warm metals light up my skin',
          onTap: () => setState(() => _jewelry = 0),
        ),
        const SizedBox(height: 8),
        _SelectCard(
          selected: _jewelry == 1,
          title: 'Silver',
          subtitle: 'Cool metals look crisper on me',
          onTap: () => setState(() => _jewelry = 1),
        ),
        const SizedBox(height: 8),
        _SelectCard(
          selected: _jewelry == 2,
          title: 'Both look great',
          subtitle: 'No strong preference',
          onTap: () => setState(() => _jewelry = 2),
        ),
        if (_veins != null && _jewelry != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Your undertone: ${_undertone.label}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ],
    ));
  }

  Widget _vibesStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _pad(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your vibe', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Choose one or more styles you gravitate toward.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final vibe in StyleVibe.values)
              FilterChip(
                label: Text(vibe.label),
                selected: _vibes.contains(vibe),
                onSelected: (v) => setState(() {
                  v ? _vibes.add(vibe) : _vibes.remove(vibe);
                }),
              ),
          ],
        ),
      ],
    ));
  }
}

class _SelectCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
