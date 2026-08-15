import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';

import 'package:aura_stylist/src/engine/color_analysis.dart';
import 'package:aura_stylist/src/engine/style_engine.dart';
import 'package:aura_stylist/src/models/profile.dart';
import 'package:aura_stylist/src/models/wardrobe_item.dart';

void main() {
  group('color utilities', () {
    test('neutral detection', () {
      expect(isNeutralColor(const Color(0xFFFFFFFF)), isTrue); // white
      expect(isNeutralColor(const Color(0xFF1A1A1A)), isTrue); // black
      expect(isNeutralColor(const Color(0xFF8A8177)), isTrue); // taupe
      expect(isNeutralColor(const Color(0xFFD32F2F)), isFalse); // red
      expect(isNeutralColor(const Color(0xFF0F52BA)), isFalse); // sapphire
    });

    test('color naming', () {
      expect(nameColor(const Color(0xFFFFFFFF)), 'White');
      expect(nameColor(const Color(0xFF1F3A5F)), 'Navy');
      expect(nameColor(const Color(0xFFD32F2F)), contains('Red'));
    });
  });

  group('harmony analysis', () {
    test('all-neutral outfit scores well', () {
      final result = analyzeHarmony(const [
        PaletteColor(Color(0xFF1A1A1A), 0.5),
        PaletteColor(Color(0xFFFFFFFF), 0.5),
      ]);
      expect(result.scheme, 'All-neutral');
      expect(result.score, greaterThanOrEqualTo(80));
    });

    test('accent + neutrals is a top scheme', () {
      final result = analyzeHarmony(const [
        PaletteColor(Color(0xFF1A1A1A), 0.6),
        PaletteColor(Color(0xFFB7410E), 0.4), // rust accent
      ]);
      expect(result.scheme, 'Accent + neutrals');
      expect(result.score, greaterThanOrEqualTo(85));
    });

    test('rainbow mix scores poorly', () {
      final result = analyzeHarmony(const [
        PaletteColor(Color(0xFFD32F2F), 0.25), // red
        PaletteColor(Color(0xFFDBA400), 0.25), // yellow
        PaletteColor(Color(0xFF0F52BA), 0.25), // blue
        PaletteColor(Color(0xFF00A86B), 0.15), // green
        PaletteColor(Color(0xFFC154C1), 0.10), // magenta
      ]);
      expect(result.score, lessThan(60));
    });
  });

  group('outfit rating', () {
    test('produces score in range with tips', () {
      final profile = Profile(undertone: Undertone.warm);
      final rating = rateOutfit(const [
        PaletteColor(Color(0xFFC19A6B), 0.6), // camel
        PaletteColor(Color(0xFF708238), 0.4), // olive
      ], profile);
      expect(rating.score, inInclusiveRange(0, 10));
      expect(rating.tips, isNotEmpty);
      expect(rating.factors, isNotEmpty);
    });
  });

  group('outfit suggestions', () {
    WardrobeItem item(String name, ItemCategory cat, int color,
            {Formality f = Formality.casual}) =>
        WardrobeItem(
          id: name.hashCode,
          name: name,
          category: cat,
          colorValue: color,
          formality: f,
        );

    test('generates combos from top+bottom+shoes', () {
      final wardrobe = [
        item('White tee', ItemCategory.top, 0xFFFFFFFF),
        item('Navy trousers', ItemCategory.bottom, 0xFF1F3A5F),
        item('Black sneakers', ItemCategory.shoes, 0xFF1A1A1A),
        item('Rust knit', ItemCategory.top, 0xFFB7410E),
      ];
      final result = suggestOutfits(wardrobe, Profile());
      expect(result, isNotEmpty);
      expect(result.first.items.length, greaterThanOrEqualTo(3));
      expect(result.first.score, inInclusiveRange(0, 10));
      // Sorted descending.
      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].score, greaterThanOrEqualTo(result[i].score));
      }
    });

    test('dress + shoes combos work', () {
      final wardrobe = [
        item('Black dress', ItemCategory.dress, 0xFF1A1A1A, f: Formality.formal),
        item('Black heels', ItemCategory.shoes, 0xFF1A1A1A, f: Formality.formal),
      ];
      final result = suggestOutfits(wardrobe, Profile());
      expect(result, isNotEmpty);
      expect(result.first.items.length, 2);
    });

    test('occasion filter respects formality', () {
      final wardrobe = [
        item('Hoodie', ItemCategory.top, 0xFF8A8177),
        item('Joggers', ItemCategory.bottom, 0xFF1A1A1A),
        item('Sneakers', ItemCategory.shoes, 0xFFFFFFFF),
      ];
      final formalOnly = suggestOutfits(wardrobe, Profile(), occasion: Formality.formal);
      expect(formalOnly, isEmpty);
    });

    test('knowledge base covers all body types and undertones', () {
      for (final t in BodyType.values) {
        expect(bodyTypeGuides[t], isNotNull);
      }
      for (final u in Undertone.values) {
        expect(undertonePalettes[u], isNotNull);
        expect(undertoneAdvice[u], isNotNull);
      }
      for (final v in StyleVibe.values) {
        expect(vibeAdvice[v], isNotNull);
      }
    });
  });
}
