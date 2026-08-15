import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../engine/color_analysis.dart';
import '../engine/style_engine.dart';
import '../models/wardrobe_item.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'camera_capture.dart';

class RateOutfitScreen extends StatefulWidget {
  const RateOutfitScreen({super.key});

  @override
  State<RateOutfitScreen> createState() => _RateOutfitScreenState();
}

class _RateOutfitScreenState extends State<RateOutfitScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _imagePath;
  OutfitRating? _rating;

  /// Part 1: shoot with the in-app camera.
  Future<void> _takePhoto() async {
    final path = await CameraCaptureScreen.capture(context);
    if (path == null || !mounted) return;
    await _analyze(path);
  }

  /// Part 2: pick an existing photo from the gallery.
  Future<void> _pickFromGallery() async {
    XFile? file;
    try {
      file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the gallery.')),
        );
      }
      return;
    }
    if (file == null || !mounted) return;
    await _analyze(file.path);
  }

  Future<void> _analyze(String path) async {
    setState(() {
      _busy = true;
      _rating = null;
      _imagePath = null;
    });

    try {
      final bytes = await File(path).readAsBytes();
      final palette = await extractPalette(bytes);
      if (!mounted) return;
      final state = context.read<AppState>();
      final rating = rateOutfit(palette, state.profile);

      final saved = await AppState.persistImage(File(path), 'look');
      await state.addLook(Look(
        imagePath: saved,
        score: rating.score,
        scheme: rating.scheme,
        summary: rating.tips.isNotEmpty ? rating.tips.first : '',
      ));

      if (!mounted) return;
      setState(() {
        _imagePath = saved;
        _rating = rating;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not analyze that photo. Try another one.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate my outfit'),
        actions: [
          if (_rating != null)
            TextButton.icon(
              onPressed: () => setState(() {
                _rating = null;
                _imagePath = null;
              }),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('New'),
            ),
        ],
      ),
      body: _busy
          ? const _Analyzing()
          : _rating == null
              ? _pickView(context)
              : _resultView(context),
    );
  }

  Widget _pickView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.camera_alt_outlined, size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 24),
              Text("Today's look",
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Snap a full-length mirror photo in good light. The stylist reads your colors and scores the whole look — right on this device.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take a photo'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from gallery'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultView(BuildContext context) {
    final rating = _rating!;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      if (_imagePath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_imagePath!),
                            width: 110,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            ScoreDial(score: rating.score, size: 130),
                            Text(
                              rating.scheme,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: scheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Detected palette'),
              PaletteChips(rating.palette),
              const SizedBox(height: 20),
              const SectionTitle('Breakdown'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      for (final f in rating.factors)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                f.delta >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 20,
                                color: f.delta >= 0
                                    ? const Color(0xFF5E8C61)
                                    : scheme.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(f.label,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium)),
                              Text(
                                '${f.delta >= 0 ? '+' : ''}${f.delta.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: f.delta >= 0
                                          ? const Color(0xFF5E8C61)
                                          : scheme.error,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Stylist notes'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (var i = 0; i < rating.tips.length; i++) ...[
                        if (i > 0) const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 18, color: scheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(rating.tips[i],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.45)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => setState(() {
                  _rating = null;
                  _imagePath = null;
                }),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Rate another look'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Analyzing extends StatelessWidget {
  const _Analyzing();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text('Reading your look…',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Extracting colors and checking harmony',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
