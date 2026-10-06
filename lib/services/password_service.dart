import '../database/db_helper.dart';
import '../utils/security.dart';
import 'auth_service.dart';
import '../pages/password.dart';

class PasswordService {
  Future<int> insertPassword(PasswordItem item) async {
    final db = await DBHelper.instance.database;
    final userId = await AuthService().getCurrentUserId();

    if (userId == null) {
      throw Exception("User not logged in");
    }

    final encrypted = encryptPassword(item.password);

    final data = item.toMap();
    data.remove('id');

    return await db.insert('passwords', {
      ...data,
      'userId': userId,
      'password': encrypted,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<PasswordItem>> getPasswords() async {
    final db = await DBHelper.instance.database;
    final userId = await AuthService().getCurrentUserId();

    if (userId == null) {
      return [];
    }

    final result = await db.query(
      'passwords',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    return result.map((e) {
      try {
        return PasswordItem(
          id: e['id'] as int,
          title: e['title'] as String,
          username: e['username'] as String? ?? '',
          password: decryptPassword(e['password'] as String),
          description: e['description'] as String? ?? '',
        );
      } catch (err) {
        return PasswordItem(
          id: e['id'] as int,
          title: e['title'] as String,
          username: e['username'] as String? ?? '',
          password: e['password'] as String,
          description: e['description'] as String? ?? '',
        );
      }
    }).toList();
  }

  Future<void> deletePassword(int id) async {
    final db = await DBHelper.instance.database;

    await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePassword(PasswordItem item) async {
    final db = await DBHelper.instance.database;

    final encrypted = encryptPassword(item.password);

    final data = item.toMap();
    data.remove('id');

    await db.update(
      'passwords',
      {...data, 'password': encrypted},
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteAllPasswords(int userId) async {
    final db = await DBHelper.instance.database;

    await db.delete('passwords', where: 'userId = ?', whereArgs: [userId]);
  }
}
