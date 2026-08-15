import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/wardrobe_item.dart';

class AppDb {
  AppDb._();

  static final AppDb instance = AppDb._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'aura_stylist'));
    await folder.create(recursive: true);
    final path = p.join(folder.path, 'aura.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category INTEGER NOT NULL,
            colorValue INTEGER NOT NULL,
            pattern INTEGER NOT NULL,
            formality INTEGER NOT NULL,
            seasonMask INTEGER NOT NULL,
            imagePath TEXT,
            favorite INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE looks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT,
            score REAL NOT NULL,
            scheme TEXT NOT NULL,
            summary TEXT NOT NULL,
            date INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  // Wardrobe items -----------------------------------------------------------

  Future<List<WardrobeItem>> getItems() async {
    final db = await database;
    final rows = await db.query('items', orderBy: 'createdAt DESC');
    return rows.map(WardrobeItem.fromMap).toList();
  }

  Future<WardrobeItem> insertItem(WardrobeItem item) async {
    final db = await database;
    final id = await db.insert('items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<void> updateItem(WardrobeItem item) async {
    final db = await database;
    await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // Looks ---------------------------------------------------------------------

  Future<List<Look>> getLooks() async {
    final db = await database;
    final rows = await db.query('looks', orderBy: 'date DESC', limit: 50);
    return rows.map(Look.fromMap).toList();
  }

  Future<Look> insertLook(Look look) async {
    final db = await database;
    final id = await db.insert('looks', look.toMap());
    return Look(
      id: id,
      imagePath: look.imagePath,
      score: look.score,
      scheme: look.scheme,
      summary: look.summary,
      date: look.date,
    );
  }

  Future<void> deleteLook(int id) async {
    final db = await database;
    await db.delete('looks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('items');
    await db.delete('looks');
  }
}
