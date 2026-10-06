import 'package:sqflite/sqflite.dart';

import '../database/db_helper.dart';

class ProfileService {
  final dbHelper = DBHelper.instance;

  /// GET USER BY ID
  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// UPDATE PROFILE
  Future<int> updateProfile({
    required int userId,
    required String name,
    required String email,
    required String imagePath,
  }) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      {
        'name': name,
        'email': email,
        'profileImage': imagePath,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// DELETE ACCOUNT
  Future<int> deleteUser(int userId) async {
    final db = await dbHelper.database;

    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUser(int id, Map<String, dynamic> userData) async {
    final db = await dbHelper.database;

    final result = await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return result;
  }

  Future<void> updateMasterPassword(int userId, String newPassword) async {
    final db = await dbHelper.database;

    await db.update(
      'users',
      {
        'masterPassword': newPassword,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}