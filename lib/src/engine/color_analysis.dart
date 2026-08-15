import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/painting.dart' show HSLColor;
import 'package:image/image.dart' as img;

/// A dominant color extracted from a photo with its share of the garment area.
class PaletteColor {
  final Color color;
  final double fraction;

  const PaletteColor(this.color, this.fraction);
}

/// Extracts the dominant clothing colors from a photo, fully on-device.
/// Downscales the image, center-weights samples (the subject is usually
/// centered) and clusters pixels with a small k-means pass.
Future<List<PaletteColor>> extractPalette(Uint8List bytes) async {
  final raw = await compute(_extractRaw, bytes);
  return raw
      .map((e) => PaletteColor(Color(e[0]), e[1] / 10000.0))
      .toList(growable: false);
}

/// Isolate entry point. Returns [ [argb, fraction*10000], ... ].
List<List<int>> _extractRaw(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return const [];

  final image = img.copyResize(decoded, width: 80);
  final w = image.width, h = image.height;

  final samples = <_Sample>[];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = image.getPixel(x, y);
      if (p.a < 128) continue;
      // Center-weight: outfit subjects sit in the middle of the frame,
      // edges are usually background.
      final edge = x < w * 0.15 || x > w * 0.85 || y < h * 0.12 || y > h * 0.88;
      samples.add(_Sample(p.r.toDouble(), p.g.toDouble(), p.b.toDouble(),
          edge ? 0.3 : 1.0));
    }
  }
  if (samples.isEmpty) return const [];

  // Seed centroids from luminance quantiles for determinism.
  const k = 6;
  samples.sort((a, b) => a.lum.compareTo(b.lum));
  final centroids = List.generate(k, (i) {
    final s = samples[(samples.length - 1) * i ~/ (k - 1)];
    return [s.r, s.g, s.b];
  });

  final assignment = List<int>.filled(samples.length, 0);
  for (var iter = 0; iter < 10; iter++) {
    var moved = false;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      var best = 0;
      var bestD = double.infinity;
      for (var c = 0; c < k; c++) {
        final d = _dist2(s.r, s.g, s.b, centroids[c]);
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
      if (assignment[i] != best) {
        assignment[i] = best;
        moved = true;
      }
    }
    final sums = List.generate(k, (_) => [0.0, 0.0, 0.0, 0.0]);
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final acc = sums[assignment[i]];
      acc[0] += s.r * s.w;
      acc[1] += s.g * s.w;
      acc[2] += s.b * s.w;
      acc[3] += s.w;
    }
    for (var c = 0; c < k; c++) {
      if (sums[c][3] > 0) {
        centroids[c] = [
          sums[c][0] / sums[c][3],
          sums[c][1] / sums[c][3],
          sums[c][2] / sums[c][3],
        ];
      }
    }
    if (!moved) break;
  }

  // Weighted cluster sizes.
  final weights = List<double>.filled(k, 0);
  var total = 0.0;
  for (var i = 0; i < samples.length; i++) {
    weights[assignment[i]] += samples[i].w;
    total += samples[i].w;
  }

  // Merge near-identical clusters.
  final merged = <List<double>>[]; // r,g,b,weight
  for (var c = 0; c < k; c++) {
    if (weights[c] <= 0) continue;
    var found = false;
    for (final m in merged) {
      if (_dist2(centroids[c][0], centroids[c][1], centroids[c][2], m) < 900) {
        final wSum = m[3] + weights[c];
        m[0] = (m[0] * m[3] + centroids[c][0] * weights[c]) / wSum;
        m[1] = (m[1] * m[3] + centroids[c][1] * weights[c]) / wSum;
        m[2] = (m[2] * m[3] + centroids[c][2] * weights[c]) / wSum;
        m[3] = wSum;
        found = true;
        break;
      }
    }
    if (!found) {
      merged.add([centroids[c][0], centroids[c][1], centroids[c][2], weights[c]]);
    }
  }

  merged.sort((a, b) => b[3].compareTo(a[3]));
  final out = <List<int>>[];
  for (final m in merged) {
    final frac = m[3] / total;
    if (frac < 0.05 || out.length >= 5) continue;
    final argb = 0xFF000000 |
        (m[0].round().clamp(0, 255) << 16) |
        (m[1].round().clamp(0, 255) << 8) |
        m[2].round().clamp(0, 255);
    out.add([argb, (frac * 10000).round()]);
  }
  return out;
}

double _dist2(double r, double g, double b, List<double> c) {
  final dr = r - c[0], dg = g - c[1], db = b - c[2];
  // Perceptual-ish weighting.
  return dr * dr * 0.9 + dg * dg * 1.2 + db * db * 0.8;
}

class _Sample {
  final double r, g, b, w;
  _Sample(this.r, this.g, this.b, this.w);

  double get lum => 0.299 * r + 0.587 * g + 0.114 * b;
}

// ---------------------------------------------------------------------------
// Color utilities
// ---------------------------------------------------------------------------

bool isNeutralColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  if (hsl.lightness > 0.92 || hsl.lightness < 0.10) return true;
  if (hsl.saturation < 0.16) return true;
  // Muted warm browns / beiges behave as neutrals in outfits.
  if (hsl.saturation < 0.35 && hsl.hue >= 15 && hsl.hue <= 50) return true;
  return false;
}

double hueOf(Color color) => HSLColor.fromColor(color).hue;

/// Smallest angular distance between two hues (0..180).
double hueDistance(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

/// Human-friendly name for a color, used across the app.
String nameColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  final h = hsl.hue, s = hsl.saturation, l = hsl.lightness;

  if (l > 0.94) return 'White';
  if (l < 0.09) return 'Black';
  if (s < 0.10) {
    if (l > 0.78) return 'Off-white';
    if (l > 0.55) return 'Light Gray';
    if (l > 0.3) return 'Gray';
    return 'Charcoal';
  }
  if (s < 0.35 && h >= 15 && h <= 50) {
    if (l > 0.72) return 'Cream';
    if (l > 0.55) return 'Beige';
    if (l > 0.38) return 'Taupe';
    return 'Brown';
  }
  if (h >= 15 && h <= 45 && l < 0.35) return 'Chocolate';
  if (h >= 15 && h <= 45 && l < 0.6 && s > 0.4) return 'Camel';

  String base;
  if (h < 12 || h >= 348) {
    base = l < 0.32 ? 'Burgundy' : 'Red';
  } else if (h < 22) {
    base = 'Rust';
  } else if (h < 40) {
    base = 'Orange';
  } else if (h < 52) {
    base = 'Mustard';
  } else if (h < 68) {
    base = 'Yellow';
  } else if (h < 92) {
    base = s < 0.5 ? 'Olive' : 'Lime';
  } else if (h < 150) {
    base = l < 0.35 ? 'Forest Green' : 'Green';
  } else if (h < 180) {
    base = 'Teal';
  } else if (h < 200) {
    base = 'Cyan';
  } else if (h < 250) {
    base = l < 0.3 ? 'Navy' : 'Blue';
  } else if (h < 275) {
    base = 'Indigo';
  } else if (h < 300) {
    base = 'Purple';
  } else if (h < 330) {
    base = 'Magenta';
  } else {
    base = 'Pink';
  }

  if (l > 0.75 && base != 'Navy' && base != 'Burgundy') return 'Light $base';
  if (l < 0.28 && base != 'Navy' && base != 'Burgundy' && base != 'Forest Green') {
    return 'Deep $base';
  }
  return base;
}
