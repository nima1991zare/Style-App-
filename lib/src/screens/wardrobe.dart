import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wardrobe_item.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'item_editor.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  ItemCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = _filter == null
        ? state.items
        : state.items.where((i) => i.category == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Closet')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'wardrobe_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ItemEditorScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add piece'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final c in ItemCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c.label),
                      selected: _filter == c,
                      onSelected: (_) => setState(
                          () => _filter = _filter == c ? null : c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.checkroom,
                    title: 'Your closet is empty',
                    message:
                        'Add your pieces — tops, bottoms, shoes and more. The stylist will combine them into outfits made for you.',
                    action: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ItemEditorScreen()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first piece'),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _ItemCard(item: items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final WardrobeItem item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ItemEditorScreen(item: item)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ItemThumb(item, size: double.infinity, radius: BorderRadius.zero),
                  if (item.favorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite,
                            size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ColorDot(Color(item.colorValue), size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.category.label} · ${item.formality.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
