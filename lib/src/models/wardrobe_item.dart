enum ItemCategory { top, bottom, dress, outerwear, shoes, bag, accessory }

enum ItemPattern { solid, striped, plaid, floral, dotted, graphic, textured }

enum Formality { casual, smart, formal }

enum Season { spring, summer, autumn, winter }

extension ItemCategoryX on ItemCategory {
  String get label => switch (this) {
        ItemCategory.top => 'Top',
        ItemCategory.bottom => 'Bottom',
        ItemCategory.dress => 'Dress',
        ItemCategory.outerwear => 'Outerwear',
        ItemCategory.shoes => 'Shoes',
        ItemCategory.bag => 'Bag',
        ItemCategory.accessory => 'Accessory',
      };
}

extension ItemPatternX on ItemPattern {
  String get label => switch (this) {
        ItemPattern.solid => 'Solid',
        ItemPattern.striped => 'Striped',
        ItemPattern.plaid => 'Plaid',
        ItemPattern.floral => 'Floral',
        ItemPattern.dotted => 'Dotted',
        ItemPattern.graphic => 'Graphic',
        ItemPattern.textured => 'Textured',
      };

  bool get isBold => this != ItemPattern.solid && this != ItemPattern.textured;
}

extension FormalityX on Formality {
  String get label => switch (this) {
        Formality.casual => 'Casual',
        Formality.smart => 'Smart',
        Formality.formal => 'Formal',
      };
}

extension SeasonX on Season {
  String get label => switch (this) {
        Season.spring => 'Spring',
        Season.summer => 'Summer',
        Season.autumn => 'Autumn',
        Season.winter => 'Winter',
      };

  static Season current([DateTime? now]) {
    final m = (now ?? DateTime.now()).month;
    if (m >= 3 && m <= 5) return Season.spring;
    if (m >= 6 && m <= 8) return Season.summer;
    if (m >= 9 && m <= 11) return Season.autumn;
    return Season.winter;
  }
}

class WardrobeItem {
  final int? id;
  String name;
  ItemCategory category;
  int colorValue; // ARGB
  ItemPattern pattern;
  Formality formality;
  Set<Season> seasons;
  String? imagePath;
  bool favorite;
  final DateTime createdAt;

  WardrobeItem({
    this.id,
    required this.name,
    required this.category,
    required this.colorValue,
    this.pattern = ItemPattern.solid,
    this.formality = Formality.casual,
    Set<Season>? seasons,
    this.imagePath,
    this.favorite = false,
    DateTime? createdAt,
  })  : seasons = seasons ?? Season.values.toSet(),
        createdAt = createdAt ?? DateTime.now();

  int get seasonMask =>
      seasons.fold(0, (mask, s) => mask | (1 << s.index));

  static Set<Season> seasonsFromMask(int mask) => {
        for (final s in Season.values)
          if (mask & (1 << s.index) != 0) s,
      };

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category.index,
        'colorValue': colorValue,
        'pattern': pattern.index,
        'formality': formality.index,
        'seasonMask': seasonMask,
        'imagePath': imagePath,
        'favorite': favorite ? 1 : 0,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory WardrobeItem.fromMap(Map<String, dynamic> map) => WardrobeItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: ItemCategory.values[map['category'] as int],
        colorValue: map['colorValue'] as int,
        pattern: ItemPattern.values[map['pattern'] as int],
        formality: Formality.values[map['formality'] as int],
        seasons: seasonsFromMask(map['seasonMask'] as int),
        imagePath: map['imagePath'] as String?,
        favorite: (map['favorite'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );

  WardrobeItem copyWith({int? id}) => WardrobeItem(
        id: id ?? this.id,
        name: name,
        category: category,
        colorValue: colorValue,
        pattern: pattern,
        formality: formality,
        seasons: {...seasons},
        imagePath: imagePath,
        favorite: favorite,
        createdAt: createdAt,
      );
}

/// A saved outfit rating ("look").
class Look {
  final int? id;
  final String? imagePath;
  final double score;
  final String scheme;
  final String summary;
  final DateTime date;

  Look({
    this.id,
    this.imagePath,
    required this.score,
    required this.scheme,
    required this.summary,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'imagePath': imagePath,
        'score': score,
        'scheme': scheme,
        'summary': summary,
        'date': date.millisecondsSinceEpoch,
      };

  factory Look.fromMap(Map<String, dynamic> map) => Look(
        id: map['id'] as int?,
        imagePath: map['imagePath'] as String?,
        score: (map['score'] as num).toDouble(),
        scheme: map['scheme'] as String,
        summary: map['summary'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      );
}
