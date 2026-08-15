import 'dart:convert';

enum BodyType { hourglass, pear, apple, rectangle, invertedTriangle }

enum Undertone { warm, cool, neutral }

enum StyleVibe { minimal, classic, casual, streetwear, romantic, edgy, sporty, formal }

extension BodyTypeX on BodyType {
  String get label => switch (this) {
        BodyType.hourglass => 'Hourglass',
        BodyType.pear => 'Pear',
        BodyType.apple => 'Apple',
        BodyType.rectangle => 'Rectangle',
        BodyType.invertedTriangle => 'Inverted Triangle',
      };

  String get description => switch (this) {
        BodyType.hourglass => 'Shoulders and hips balanced, with a defined waist.',
        BodyType.pear => 'Hips noticeably wider than the shoulders.',
        BodyType.apple => 'Fuller midsection with slimmer legs and arms.',
        BodyType.rectangle => 'Shoulders, waist and hips are about the same width.',
        BodyType.invertedTriangle => 'Shoulders broader than the hips.',
      };
}

extension UndertoneX on Undertone {
  String get label => switch (this) {
        Undertone.warm => 'Warm',
        Undertone.cool => 'Cool',
        Undertone.neutral => 'Neutral',
      };
}

extension StyleVibeX on StyleVibe {
  String get label => switch (this) {
        StyleVibe.minimal => 'Minimal',
        StyleVibe.classic => 'Classic',
        StyleVibe.casual => 'Casual',
        StyleVibe.streetwear => 'Streetwear',
        StyleVibe.romantic => 'Romantic',
        StyleVibe.edgy => 'Edgy',
        StyleVibe.sporty => 'Sporty',
        StyleVibe.formal => 'Formal',
      };
}

class Profile {
  String name;
  BodyType bodyType;
  Undertone undertone;
  Set<StyleVibe> vibes;
  bool onboarded;

  Profile({
    this.name = '',
    this.bodyType = BodyType.rectangle,
    this.undertone = Undertone.neutral,
    Set<StyleVibe>? vibes,
    this.onboarded = false,
  }) : vibes = vibes ?? {};

  Map<String, dynamic> toJson() => {
        'name': name,
        'bodyType': bodyType.index,
        'undertone': undertone.index,
        'vibes': vibes.map((v) => v.index).toList(),
        'onboarded': onboarded,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        name: json['name'] as String? ?? '',
        bodyType: BodyType.values[(json['bodyType'] as int?) ?? 3],
        undertone: Undertone.values[(json['undertone'] as int?) ?? 2],
        vibes: ((json['vibes'] as List?) ?? const [])
            .map((i) => StyleVibe.values[i as int])
            .toSet(),
        onboarded: json['onboarded'] as bool? ?? false,
      );

  String encode() => jsonEncode(toJson());

  factory Profile.decode(String raw) =>
      Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
