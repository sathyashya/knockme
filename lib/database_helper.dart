import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

class DatabaseHelper {

  static Database? db;

  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE items(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
      title TEXT,
      description TEXT,
      date TEXT,
      time TEXT,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)"""
    );
  }

  static Future openDatabase() async {
    db = await sql.openDatabase(
      'code.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<int> createItem(String? title, String? descrption, String? date, String? time) async {
    final data = {'title': title, 'description': descrption, 'date': date, 'time': time};
    final id = await db!.insert('items', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items
  static Future<List<Map<String, dynamic>>> getItems() async {
    return db!.query('items', orderBy: "id");
  }

  // Update an item by id
  static Future<int> updateItem(int id, String title, String? descrption, String? date, String? time) async {
    final data = {
      'title': title,
      'description': descrption,
      'date': date,
      'time': time,
      'createdAt': DateTime.now().toString()
    };
    final result = await db!.update('items', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  // Delete item by id
  static Future<void> deleteItem(int id) async {
    try {
      await db!.delete("items", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  static Future closeDatabase() async => db!.close();
}

