import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';
import '../engine/style_engine.dart';
import '../models/profile.dart';
import '../models/wardrobe_item.dart';

class AppState extends ChangeNotifier {
  Profile profile = Profile();
  List<WardrobeItem> items = [];
  List<Look> looks = [];
  ThemeMode themeMode = ThemeMode.system;
  bool loaded = false;

  static const _profileKey = 'profile';
  static const _themeKey = 'themeMode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw != null) {
      try {
        profile = Profile.decode(raw);
      } catch (_) {}
    }
    final theme = prefs.getInt(_themeKey);
    if (theme != null) themeMode = ThemeMode.values[theme];
    items = await AppDb.instance.getItems();
    looks = await AppDb.instance.getLooks();
    loaded = true;
    notifyListeners();
  }

  Future<void> saveProfile(Profile next) async {
    profile = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.encode());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  // Wardrobe ------------------------------------------------------------------

  Future<void> addItem(WardrobeItem item) async {
    final saved = await AppDb.instance.insertItem(item);
    items = [saved, ...items];
    notifyListeners();
  }

  Future<void> updateItem(WardrobeItem item) async {
    await AppDb.instance.updateItem(item);
    items = [for (final i in items) i.id == item.id ? item : i];
    notifyListeners();
  }

  Future<void> deleteItem(WardrobeItem item) async {
    if (item.id != null) await AppDb.instance.deleteItem(item.id!);
    if (item.imagePath != null) {
      try {
        await File(item.imagePath!).delete();
      } catch (_) {}
    }
    items = items.where((i) => i.id != item.id).toList();
    notifyListeners();
  }

  // Looks -----------------------------------------------------------------------

  Future<void> addLook(Look look) async {
    final saved = await AppDb.instance.insertLook(look);
    looks = [saved, ...looks];
    notifyListeners();
  }

  Future<void> deleteLook(Look look) async {
    if (look.id != null) await AppDb.instance.deleteLook(look.id!);
    if (look.imagePath != null) {
      try {
        await File(look.imagePath!).delete();
      } catch (_) {}
    }
    looks = looks.where((l) => l.id != look.id).toList();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await AppDb.instance.clearAll();
    for (final i in items) {
      if (i.imagePath != null) {
        try {
          await File(i.imagePath!).delete();
        } catch (_) {}
      }
    }
    for (final l in looks) {
      if (l.imagePath != null) {
        try {
          await File(l.imagePath!).delete();
        } catch (_) {}
      }
    }
    items = [];
    looks = [];
    notifyListeners();
  }

  // Suggestions -----------------------------------------------------------------

  List<OutfitSuggestion> suggestions({Formality? occasion, int max = 12}) =>
      suggestOutfits(items, profile, occasion: occasion, max: max);

  double get averageLookScore => looks.isEmpty
      ? 0
      : looks.fold(0.0, (s, l) => s + l.score) / looks.length;

  /// Copies a picked image into permanent app storage, returns new path.
  static Future<String> persistImage(File source, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'aura_stylist', 'images'));
    await folder.create(recursive: true);
    final ext = p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
    final dest = p.join(
        folder.path, '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext');
    await source.copy(dest);
    return dest;
  }
}
