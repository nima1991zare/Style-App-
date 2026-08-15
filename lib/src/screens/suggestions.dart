import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/style_engine.dart';
import '../models/wardrobe_item.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'item_editor.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  Formality? _occasion;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasBasics = state.items.any((i) =>
            i.category == ItemCategory.dress) ||
        (state.items.any((i) => i.category == ItemCategory.top) &&
            state.items.any((i) => i.category == ItemCategory.bottom));

    final suggestions =
        hasBasics ? state.suggestions(occasion: _occasion) : <OutfitSuggestion>[];

    return Scaffold(
      appBar: AppBar(title: const Text('For you')),
      body: !hasBasics
          ? EmptyState(
              icon: Icons.auto_awesome,
              title: 'Not enough pieces yet',
              message:
                  'Add at least a top and a bottom (or a dress) to your closet and the stylist will start composing outfits for you.',
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ItemEditorScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add pieces'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any occasion'),
                        selected: _occasion == null,
                        onSelected: (_) => setState(() => _occasion = null),
                      ),
                      for (final f in Formality.values)
                        ChoiceChip(
                          label: Text(f.label),
                          selected: _occasion == f,
                          onSelected: (_) => setState(
                              () => _occasion = _occasion == f ? null : f),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: suggestions.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'No outfits for this occasion',
                          message:
                              'Try another occasion, or add pieces with this dress code to your closet.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: suggestions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              OutfitCard(suggestion: suggestions[i], rank: i + 1),
                        ),
                ),
              ],
            ),
    );
  }
}

class OutfitCard extends StatelessWidget {
  final OutfitSuggestion suggestion;
  final int? rank;

  const OutfitCard({super.key, required this.suggestion, this.rank});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (rank != null) ...[
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$rank',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: scheme.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        suggestion.note,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    suggestion.score.toStringAsFixed(1),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: scheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in suggestion.items)
                  SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        ItemThumb(item, size: 64),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
