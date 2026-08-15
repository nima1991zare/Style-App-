import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../engine/color_analysis.dart';
import '../models/wardrobe_item.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'camera_capture.dart';

const _pickerColors = <Color>[
  Color(0xFFFFFFFF), Color(0xFFE8E2D6), Color(0xFFBDB6AA), Color(0xFF8A8177),
  Color(0xFF4A453D), Color(0xFF1A1A1A), Color(0xFFF7F0DC), Color(0xFFC19A6B),
  Color(0xFF8B5E3C), Color(0xFF5D4037), Color(0xFFC1440E), Color(0xFFB7410E),
  Color(0xFFD32F2F), Color(0xFF6D2E46), Color(0xFFE56B8C), Color(0xFFDE9DA6),
  Color(0xFFE2725B), Color(0xFFFF7F50), Color(0xFFE8A33D), Color(0xFFDBA400),
  Color(0xFFF2D16B), Color(0xFF708238), Color(0xFF4E6B3A), Color(0xFF33604A),
  Color(0xFF2E8B57), Color(0xFF00A86B), Color(0xFF367588), Color(0xFF1F7A8C),
  Color(0xFF4E6E9E), Color(0xFF0F52BA), Color(0xFF1F3A5F), Color(0xFF3F51B5),
  Color(0xFF7E57C2), Color(0xFFB57EDC), Color(0xFFC154C1), Color(0xFF36454F),
];

class ItemEditorScreen extends StatefulWidget {
  final WardrobeItem? item;

  const ItemEditorScreen({super.key, this.item});

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  final _picker = ImagePicker();
  late final TextEditingController _name;

  ItemCategory _category = ItemCategory.top;
  Color _color = const Color(0xFF1A1A1A);
  ItemPattern _pattern = ItemPattern.solid;
  Formality _formality = Formality.casual;
  late Set<Season> _seasons;
  bool _favorite = false;
  String? _imagePath;
  List<PaletteColor> _detected = [];
  bool _detecting = false;

  bool get _isNew => widget.item == null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    if (item != null) {
      _category = item.category;
      _color = Color(item.colorValue);
      _pattern = item.pattern;
      _formality = item.formality;
      _seasons = {...item.seasons};
      _favorite = item.favorite;
      _imagePath = item.imagePath;
    } else {
      _seasons = Season.values.toSet();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Part 1: shoot with the in-app camera.
  Future<void> _takePhoto() async {
    final path = await CameraCaptureScreen.capture(context);
    if (path == null || !mounted) return;
    await _usePhoto(path);
  }

  /// Part 2: pick an existing photo from the gallery.
  Future<void> _pickFromGallery() async {
    XFile? file;
    try {
      file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    } catch (_) {
      return;
    }
    if (file == null || !mounted) return;
    await _usePhoto(file.path);
  }

  Future<void> _usePhoto(String path) async {
    setState(() => _detecting = true);
    try {
      final source = File(path);
      final saved = await AppState.persistImage(source, 'item');
      final palette = await extractPalette(await source.readAsBytes());
      if (!mounted) return;
      setState(() {
        _imagePath = saved;
        _detected = palette;
        if (palette.isNotEmpty) _color = palette.first.color;
        _detecting = false;
      });
    } catch (_) {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim().isEmpty
        ? '${nameColor(_color)} ${_category.label}'
        : _name.text.trim();
    final state = context.read<AppState>();
    final item = WardrobeItem(
      id: widget.item?.id,
      name: name,
      category: _category,
      colorValue: _color.toARGB32(),
      pattern: _pattern,
      formality: _formality,
      seasons: _seasons.isEmpty ? Season.values.toSet() : _seasons,
      imagePath: _imagePath,
      favorite: _favorite,
      createdAt: widget.item?.createdAt,
    );
    if (_isNew) {
      await state.addItem(item);
    } else {
      await state.updateItem(item);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove piece?'),
        content: Text('“${widget.item!.name}” will be removed from your closet.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AppState>().deleteItem(widget.item!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add piece' : 'Edit piece'),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: () => setState(() => _favorite = !_favorite),
            icon: Icon(
              _favorite ? Icons.favorite : Icons.favorite_border,
              color: _favorite ? scheme.tertiary : null,
            ),
          ),
          if (!_isNew)
            IconButton(
              tooltip: 'Delete',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 180,
                    child: _detecting
                        ? const Center(child: CircularProgressIndicator())
                        : _imagePath != null && File(_imagePath!).existsSync()
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(_imagePath!),
                                      fit: BoxFit.cover),
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: FilledButton.tonalIcon(
                                      onPressed: () =>
                                          _photoSourceSheet(context),
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Change'),
                                    ),
                                  ),
                                ],
                              )
                            : InkWell(
                                onTap: () => _photoSourceSheet(context),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        size: 34, color: scheme.primary),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Add a photo — the color is detected automatically',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: scheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),
                if (_detected.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const SectionTitle('Detected colors — tap to choose'),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final p in _detected)
                        GestureDetector(
                          onTap: () => setState(() => _color = p.color),
                          child: ColorDot(p.color,
                              size: 40,
                              selected:
                                  _color.toARGB32() == p.color.toARGB32()),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Silk camel blouse',
                  ),
                ),
                const SizedBox(height: 20),
                const SectionTitle('Category'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in ItemCategory.values)
                      ChoiceChip(
                        label: Text(c.label),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionTitle('Color'),
                Row(
                  children: [
                    ColorDot(_color, size: 44, selected: true),
                    const SizedBox(width: 12),
                    Text(nameColor(_color),
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _pickerColors)
                      GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: ColorDot(c,
                            size: 34,
                            selected: _color.toARGB32() == c.toARGB32()),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionTitle('Pattern'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in ItemPattern.values)
                      ChoiceChip(
                        label: Text(p.label),
                        selected: _pattern == p,
                        onSelected: (_) => setState(() => _pattern = p),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionTitle('Dress code'),
                SegmentedButton<Formality>(
                  segments: [
                    for (final f in Formality.values)
                      ButtonSegment(value: f, label: Text(f.label)),
                  ],
                  selected: {_formality},
                  onSelectionChanged: (s) =>
                      setState(() => _formality = s.first),
                ),
                const SizedBox(height: 20),
                const SectionTitle('Seasons'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in Season.values)
                      FilterChip(
                        label: Text(s.label),
                        selected: _seasons.contains(s),
                        onSelected: (v) => setState(() {
                          v ? _seasons.add(s) : _seasons.remove(s);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _save,
                  child: Text(_isNew ? 'Add to closet' : 'Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _photoSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              subtitle: const Text('Use the in-app camera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Pick an existing photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}
