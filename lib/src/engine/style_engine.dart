import 'dart:ui' show Color;

import '../models/profile.dart';
import '../models/wardrobe_item.dart';
import 'color_analysis.dart';

// ---------------------------------------------------------------------------
// Color harmony
// ---------------------------------------------------------------------------

class HarmonyResult {
  final String scheme;
  final double score; // 0..100
  final List<String> notes;

  const HarmonyResult(this.scheme, this.score, this.notes);
}

/// Groups accent hues that sit within 28 degrees of each other.
List<double> _clusterHues(List<PaletteColor> accents) {
  final clusters = <List<double>>[]; // [hue, weight]
  for (final a in accents) {
    final h = hueOf(a.color);
    var placed = false;
    for (final c in clusters) {
      if (hueDistance(h, c[0]) <= 28) {
        final w = c[1] + a.fraction;
        // Weighted circular-ish average (fine for close hues).
        var h0 = c[0];
        var diff = h - h0;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        c[0] = (h0 + diff * (a.fraction / w)) % 360;
        c[1] = w;
        placed = true;
        break;
      }
    }
    if (!placed) clusters.add([h, a.fraction]);
  }
  clusters.sort((a, b) => b[1].compareTo(a[1]));
  return clusters.map((c) => c[0]).toList();
}

HarmonyResult analyzeHarmony(List<PaletteColor> palette) {
  if (palette.isEmpty) {
    return const HarmonyResult('Unknown', 55, ['Could not read enough color.']);
  }
  final accents = palette.where((p) => !isNeutralColor(p.color)).toList();
  final neutrals = palette.where((p) => isNeutralColor(p.color)).toList();
  final notes = <String>[];

  double score;
  String scheme;

  if (accents.isEmpty) {
    scheme = 'All-neutral';
    score = 84;
    notes.add('A clean neutral canvas — timeless and hard to get wrong.');
    final lights = neutrals.map((n) => _lightness(n.color)).toList()..sort();
    if (lights.length > 1 && (lights.last - lights.first) < 0.18) {
      score -= 8;
      notes.add('Tones are very similar — mix light and dark neutrals for depth.');
    }
  } else {
    final hues = _clusterHues(accents);
    if (hues.length == 1) {
      if (neutrals.isNotEmpty) {
        scheme = 'Accent + neutrals';
        score = 88;
        notes.add('One accent color against neutrals — a stylist favorite.');
      } else {
        scheme = 'Monochrome';
        score = 84;
        notes.add('Single-hue dressing looks intentional and elongating.');
        final lights = accents.map((a) => _lightness(a.color)).toList()..sort();
        if (lights.length > 1 && (lights.last - lights.first) < 0.15) {
          score -= 8;
          notes.add('Add tonal contrast — vary the shade within the same hue.');
        }
      }
    } else if (hues.length == 2) {
      final d = hueDistance(hues[0], hues[1]);
      if (d <= 42) {
        scheme = 'Analogous';
        score = 85;
        notes.add('Neighboring hues blend smoothly — harmonious and easy.');
      } else if (d >= 150) {
        scheme = 'Complementary';
        score = 86;
        notes.add('Opposite hues create striking, confident contrast.');
        final avgSat = accents.map((a) => _saturation(a.color)).reduce((a, b) => a + b) /
            accents.length;
        if (avgSat > 0.75) {
          score -= 6;
          notes.add('Both sides are very saturated — mute one to let the other lead.');
        }
      } else if (d >= 80) {
        scheme = 'Contrast pair';
        score = 74;
        notes.add('An unexpected pairing — grounding it with neutrals helps.');
        if (neutrals.isNotEmpty) score += 5;
      } else {
        scheme = 'Near-clash';
        score = 62;
        notes.add('These hues sit awkwardly close — shift one warmer or cooler.');
      }
    } else if (hues.length == 3) {
      final sorted = [...hues]..sort();
      final gaps = [
        sorted[1] - sorted[0],
        sorted[2] - sorted[1],
        360 - sorted[2] + sorted[0],
      ];
      if (gaps.every((g) => g >= 80 && g <= 160)) {
        scheme = 'Triadic';
        score = 78;
        notes.add('A balanced three-color story — bold but coherent.');
      } else {
        scheme = 'Multicolor';
        score = 60;
        notes.add('Three-plus accent hues compete. Keep two and neutralize the rest.');
      }
    } else {
      scheme = 'Rainbow mix';
      score = 48;
      notes.add('Too many competing colors — pick one hero color and support it.');
    }

    // Sophistication bonus for muted palettes.
    final avgSat =
        accents.map((a) => _saturation(a.color)).reduce((a, b) => a + b) /
            accents.length;
    if (avgSat >= 0.2 && avgSat <= 0.55) {
      score += 4;
      notes.add('Muted saturation reads elevated and expensive.');
    }
  }

  return HarmonyResult(scheme, score.clamp(0, 100).toDouble(), notes);
}

double _lightness(Color c) {
  final v = c.toARGB32();
  final r = ((v >> 16) & 0xFF) / 255.0;
  final g = ((v >> 8) & 0xFF) / 255.0;
  final b = (v & 0xFF) / 255.0;
  final maxc = [r, g, b].reduce((a, x) => a > x ? a : x);
  final minc = [r, g, b].reduce((a, x) => a < x ? a : x);
  return (maxc + minc) / 2;
}

double _saturation(Color c) {
  final v = c.toARGB32();
  final r = ((v >> 16) & 0xFF) / 255.0;
  final g = ((v >> 8) & 0xFF) / 255.0;
  final b = (v & 0xFF) / 255.0;
  final maxc = [r, g, b].reduce((a, x) => a > x ? a : x);
  final minc = [r, g, b].reduce((a, x) => a < x ? a : x);
  final l = (maxc + minc) / 2;
  if (maxc == minc) return 0;
  final d = maxc - minc;
  return l > 0.5 ? d / (2 - maxc - minc) : d / (maxc + minc);
}

// ---------------------------------------------------------------------------
// Outfit rating (photo)
// ---------------------------------------------------------------------------

class RatingFactor {
  final String label;
  final double delta;

  const RatingFactor(this.label, this.delta);
}

class OutfitRating {
  final double score; // 0..10
  final String scheme;
  final List<PaletteColor> palette;
  final List<RatingFactor> factors;
  final List<String> tips;

  const OutfitRating({
    required this.score,
    required this.scheme,
    required this.palette,
    required this.factors,
    required this.tips,
  });
}

bool _flattersUndertone(Color color, Undertone tone) {
  if (tone == Undertone.neutral) return true;
  final h = hueOf(color);
  final warm = h < 130 || h >= 350;
  return tone == Undertone.warm ? warm : !warm;
}

OutfitRating rateOutfit(List<PaletteColor> palette, Profile profile) {
  final harmony = analyzeHarmony(palette);
  final factors = <RatingFactor>[
    RatingFactor('Color harmony · ${harmony.scheme}', harmony.score - 70),
  ];
  final tips = <String>[...harmony.notes];
  var score = harmony.score;

  final accents = palette.where((p) => !isNeutralColor(p.color)).toList();
  if (accents.isNotEmpty) {
    final matched = accents
        .where((a) => _flattersUndertone(a.color, profile.undertone))
        .fold(0.0, (s, a) => s + a.fraction);
    final total = accents.fold(0.0, (s, a) => s + a.fraction);
    final ratio = total == 0 ? 1.0 : matched / total;
    if (profile.undertone != Undertone.neutral) {
      if (ratio >= 0.7) {
        score += 6;
        factors.add(RatingFactor(
            'Flatters your ${profile.undertone.label.toLowerCase()} undertone', 6));
      } else if (ratio <= 0.3) {
        score -= 6;
        factors.add(RatingFactor(
            'Colors fight your ${profile.undertone.label.toLowerCase()} undertone', -6));
        tips.add(profile.undertone == Undertone.warm
            ? 'Swap toward warm shades: rust, camel, olive, mustard, coral.'
            : 'Swap toward cool shades: navy, emerald, lavender, berry, icy gray.');
      }
    }

    // Contrast check between the two biggest colors.
    if (palette.length >= 2) {
      final l1 = _lightness(palette[0].color);
      final l2 = _lightness(palette[1].color);
      if ((l1 - l2).abs() >= 0.35) {
        score += 3;
        factors.add(const RatingFactor('Strong light–dark contrast', 3));
      }
    }
  }

  score = score.clamp(20, 100).toDouble();
  return OutfitRating(
    score: (score / 10 * 10).roundToDouble() / 10,
    scheme: harmony.scheme,
    palette: palette,
    factors: factors,
    tips: tips,
  );
}

// ---------------------------------------------------------------------------
// Outfit suggestions from the wardrobe
// ---------------------------------------------------------------------------

class OutfitSuggestion {
  final List<WardrobeItem> items;
  final double score; // 0..10
  final String title;
  final String note;

  const OutfitSuggestion({
    required this.items,
    required this.score,
    required this.title,
    required this.note,
  });
}

double _comboScore(List<WardrobeItem> items, Season season, Profile profile) {
  final palette = items
      .map((i) => PaletteColor(Color(i.colorValue), 1 / items.length))
      .toList();
  var score = analyzeHarmony(palette).score;

  // Formality coherence.
  final f = items.map((i) => i.formality.index).toList();
  final spread = f.reduce((a, b) => a > b ? a : b) - f.reduce((a, b) => a < b ? a : b);
  if (spread == 0) {
    score += 6;
  } else if (spread == 2) {
    score -= 12;
  }

  // Season fit.
  final offSeason = items.where((i) => !i.seasons.contains(season)).length;
  score -= offSeason * 5;

  // Pattern mixing: one statement piece max.
  final bold = items.where((i) => i.pattern.isBold).length;
  if (bold == 1) score += 3;
  if (bold > 1) score -= 10;

  // Undertone flattery on non-neutral pieces.
  if (profile.undertone != Undertone.neutral) {
    for (final i in items) {
      final c = Color(i.colorValue);
      if (isNeutralColor(c)) continue;
      score += _flattersUndertone(c, profile.undertone) ? 2 : -3;
    }
  }

  // Favorites nudge.
  score += items.where((i) => i.favorite).length.clamp(0, 2) * 2;

  return score.clamp(0, 100).toDouble();
}

String _comboTitle(List<WardrobeItem> items) {
  final maxF = items.map((i) => i.formality.index).reduce((a, b) => a > b ? a : b);
  return switch (Formality.values[maxF]) {
    Formality.casual => 'Effortless casual',
    Formality.smart => 'Smart casual',
    Formality.formal => 'Polished formal',
  };
}

List<OutfitSuggestion> suggestOutfits(
  List<WardrobeItem> wardrobe,
  Profile profile, {
  Formality? occasion,
  int max = 12,
}) {
  final season = SeasonX.current();
  var pool = wardrobe;
  if (occasion != null) {
    pool = wardrobe
        .where((i) => (i.formality.index - occasion.index).abs() <= 1)
        .toList();
  }

  List<WardrobeItem> byCat(ItemCategory c) =>
      pool.where((i) => i.category == c).toList();

  var tops = byCat(ItemCategory.top);
  var bottoms = byCat(ItemCategory.bottom);
  var dresses = byCat(ItemCategory.dress);
  var shoes = byCat(ItemCategory.shoes);
  final outer = byCat(ItemCategory.outerwear);
  final extras = [...byCat(ItemCategory.bag), ...byCat(ItemCategory.accessory)];

  // Keep the search space sane.
  if (tops.length > 18) tops = tops.sublist(0, 18);
  if (bottoms.length > 18) bottoms = bottoms.sublist(0, 18);
  if (shoes.length > 12) shoes = shoes.sublist(0, 12);
  if (dresses.length > 18) dresses = dresses.sublist(0, 18);

  final scored = <OutfitSuggestion>[];

  void addCombo(List<WardrobeItem> base) {
    var items = base;
    var score = _comboScore(items, season, profile);

    // Try elevating with outerwear in colder months, or if it helps.
    final cold = season == Season.autumn || season == Season.winter;
    WardrobeItem? bestExtra;
    var bestScore = score;
    for (final o in [...outer, ...extras]) {
      final trial = [...items, o];
      final s = _comboScore(trial, season, profile) +
          (cold && o.category == ItemCategory.outerwear ? 3 : 0);
      if (s > bestScore) {
        bestScore = s;
        bestExtra = o;
      }
    }
    if (bestExtra != null) {
      items = [...items, bestExtra];
      score = _comboScore(items, season, profile);
    }

    if (occasion != null && items.every((i) => i.formality != occasion)) return;

    final palette = items
        .map((i) => PaletteColor(Color(i.colorValue), 1 / items.length))
        .toList();
    final scheme = analyzeHarmony(palette).scheme;
    scored.add(OutfitSuggestion(
      items: items,
      score: (score / 10 * 10).roundToDouble() / 10,
      title: _comboTitle(items),
      note: scheme,
    ));
  }

  for (final d in dresses) {
    if (shoes.isEmpty) {
      addCombo([d]);
    } else {
      for (final s in shoes) {
        addCombo([d, s]);
      }
    }
  }
  for (final t in tops) {
    for (final b in bottoms) {
      if (shoes.isEmpty) {
        addCombo([t, b]);
      } else {
        for (final s in shoes) {
          addCombo([t, b, s]);
        }
      }
    }
  }

  scored.sort((a, b) => b.score.compareTo(a.score));

  // Diversify: avoid returning near-duplicate combos.
  final result = <OutfitSuggestion>[];
  for (final s in scored) {
    if (result.length >= max) break;
    final tooSimilar = result.any((r) {
      final shared = r.items.where((i) => s.items.any((j) => j.id == i.id)).length;
      return shared >= (s.items.length - 1).clamp(1, 3);
    });
    if (!tooSimilar) result.add(s);
  }
  // If diversity filter starved us, top up with best remaining.
  if (result.length < max) {
    for (final s in scored) {
      if (result.length >= max) break;
      if (!result.contains(s)) result.add(s);
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Body type & undertone knowledge base
// ---------------------------------------------------------------------------

class BodyTypeGuide {
  final List<String> wear;
  final List<String> avoid;
  final List<String> necklines;
  final List<String> tips;

  const BodyTypeGuide({
    required this.wear,
    required this.avoid,
    required this.necklines,
    required this.tips,
  });
}

const Map<BodyType, BodyTypeGuide> bodyTypeGuides = {
  BodyType.hourglass: BodyTypeGuide(
    wear: [
      'Wrap dresses & tops',
      'High-waisted bottoms',
      'Belted outerwear',
      'Fitted knits',
      'Pencil & A-line skirts',
    ],
    avoid: [
      'Boxy, shapeless cuts',
      'Drop-waist dresses',
      'Oversized everything',
    ],
    necklines: ['V-neck', 'Sweetheart', 'Scoop', 'Wrap'],
    tips: [
      'Your waist is your superpower — define it with belts, wraps and tucks.',
      'Choose stretch fabrics that follow your lines rather than stiff ones that hide them.',
      'If you go oversized on top, balance with something fitted below (and vice versa).',
    ],
  ),
  BodyType.pear: BodyTypeGuide(
    wear: [
      'Structured shoulders',
      'Boat-neck & wide necklines',
      'A-line skirts',
      'Bright or detailed tops',
      'Dark straight/bootcut bottoms',
    ],
    avoid: [
      'Skinny pants with tight tops',
      'Hip-level pockets & embellishment',
      'Clingy pencil skirts in shine fabrics',
    ],
    necklines: ['Boat neck', 'Off-shoulder', 'Square', 'Cowl'],
    tips: [
      'Draw the eye upward: color, pattern and structure live on your top half.',
      'A-line shapes skim the hip and create instant balance.',
      'Slightly padded or extended shoulders visually widen the frame up top.',
    ],
  ),
  BodyType.apple: BodyTypeGuide(
    wear: [
      'Empire waists',
      'Open V-necklines',
      'Straight & wide-leg pants',
      'Longline blazers & cardigans',
      'Flowy (not clingy) fabrics',
    ],
    avoid: [
      'Tight waistbands at the middle',
      'Clingy jersey around the midsection',
      'Cropped boxy jackets',
    ],
    necklines: ['Deep V', 'Scoop', 'Surplice', 'Cascading collars'],
    tips: [
      'Show off your legs and neckline — they are your best assets.',
      'Vertical lines (open jackets, long necklaces, plackets) lengthen the torso.',
      'Choose fabrics with drape that glide over the middle instead of gripping it.',
    ],
  ),
  BodyType.rectangle: BodyTypeGuide(
    wear: [
      'Peplum tops',
      'Belted dresses & coats',
      'Layered looks',
      'Ruffles, pockets & texture',
      'Cropped jackets',
    ],
    avoid: [
      'Straight shift dresses without a belt',
      'Head-to-toe skin-tight fits',
    ],
    necklines: ['Sweetheart', 'Scoop', 'Halter', 'Collared'],
    tips: [
      'Create curves: belts, peplums and wrap shapes carve out a waist.',
      'Play with volume — a full skirt or wide-leg pant adds dimension.',
      'Layering is your friend; it builds shape and visual interest.',
    ],
  ),
  BodyType.invertedTriangle: BodyTypeGuide(
    wear: [
      'Wide-leg & flared pants',
      'A-line and full skirts',
      'V-necks & vertical detail',
      'Hip-detail bottoms',
      'Soft, unstructured tops',
    ],
    avoid: [
      'Shoulder pads & epaulettes',
      'Boat necks & halter tops',
      'Skinny bottoms with bulky tops',
    ],
    necklines: ['V-neck', 'Scoop', 'U-neck', 'Narrow lapels'],
    tips: [
      'Add volume below: flares, pleats and pocket details balance strong shoulders.',
      'Keep the top half simple and the neckline vertical.',
      'Darker tops with brighter bottoms invert attention beautifully.',
    ],
  ),
};

class UndertoneColor {
  final String name;
  final Color color;
  const UndertoneColor(this.name, this.color);
}

const Map<Undertone, List<UndertoneColor>> undertonePalettes = {
  Undertone.warm: [
    UndertoneColor('Camel', Color(0xFFC19A6B)),
    UndertoneColor('Rust', Color(0xFFB7410E)),
    UndertoneColor('Olive', Color(0xFF708238)),
    UndertoneColor('Mustard', Color(0xFFDBA400)),
    UndertoneColor('Terracotta', Color(0xFFE2725B)),
    UndertoneColor('Coral', Color(0xFFFF7F50)),
    UndertoneColor('Cream', Color(0xFFF7F0DC)),
    UndertoneColor('Chocolate', Color(0xFF5D4037)),
    UndertoneColor('Warm Gold', Color(0xFFD4AF37)),
    UndertoneColor('Tomato Red', Color(0xFFC1440E)),
  ],
  Undertone.cool: [
    UndertoneColor('Navy', Color(0xFF1F3A5F)),
    UndertoneColor('Emerald', Color(0xFF2E8B57)),
    UndertoneColor('Sapphire', Color(0xFF0F52BA)),
    UndertoneColor('Lavender', Color(0xFFB57EDC)),
    UndertoneColor('Fuchsia', Color(0xFFC154C1)),
    UndertoneColor('Berry', Color(0xFF6D2E46)),
    UndertoneColor('Icy Gray', Color(0xFFD6DBE0)),
    UndertoneColor('True White', Color(0xFFFFFFFF)),
    UndertoneColor('Cool Pink', Color(0xFFE56B8C)),
    UndertoneColor('Charcoal', Color(0xFF36454F)),
  ],
  Undertone.neutral: [
    UndertoneColor('Soft White', Color(0xFFF5F2EA)),
    UndertoneColor('Taupe', Color(0xFF8B8589)),
    UndertoneColor('Teal', Color(0xFF367588)),
    UndertoneColor('Blush', Color(0xFFDE9DA6)),
    UndertoneColor('Jade', Color(0xFF00A86B)),
    UndertoneColor('Denim Blue', Color(0xFF4E6E9E)),
    UndertoneColor('Mauve', Color(0xFF915F6D)),
    UndertoneColor('Stone', Color(0xFFA99F94)),
    UndertoneColor('Forest', Color(0xFF33604A)),
    UndertoneColor('Black', Color(0xFF1A1A1A)),
  ],
};

const Map<Undertone, String> undertoneAdvice = {
  Undertone.warm:
      'Golden, peachy or olive skin glows in earthy, sun-baked shades. Gold jewelry over silver; ivory over stark white.',
  Undertone.cool:
      'Pink or bluish undertones shine in jewel tones and icy shades. Silver jewelry flatters; pure white beats cream.',
  Undertone.neutral:
      'Lucky you — most colors work. Lean into muted, mid-tone shades and mix metals freely.',
};

const Map<StyleVibe, String> vibeAdvice = {
  StyleVibe.minimal:
      'Build around neutrals with impeccable fit. One silhouette statement per outfit; no more than two colors.',
  StyleVibe.classic:
      'Invest in tailoring: blazers, crisp shirts, straight trousers. Timeless beats trendy every time.',
  StyleVibe.casual:
      'Elevate basics — quality tees, well-fitted denim, clean sneakers. Layering makes casual look styled.',
  StyleVibe.streetwear:
      'Play with proportion: oversized top, tapered bottom. Let one statement piece anchor the outfit.',
  StyleVibe.romantic:
      'Soft fabrics, florals, blush tones and flowing silhouettes. Balance sweetness with one structured piece.',
  StyleVibe.edgy:
      'Black-forward palettes, leather textures, asymmetric cuts. Contrast hard pieces with something soft.',
  StyleVibe.sporty:
      'Athleisure works when it is intentional: matching sets, sleek trainers, technical fabrics kept monochrome.',
  StyleVibe.formal:
      'Fit is everything — tailor your suits and dresses. Keep accessories refined and colors deep.',
};
