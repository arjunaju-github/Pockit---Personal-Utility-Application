import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../utils/security.dart';

class AuthService {
  // ✅ SIGNUP
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String masterPassword,
    required String profileImage,
  }) async {
    final db = await DBHelper.instance.database;

    try {
      await db.insert('users', {
        'name': name,
        'email': email,
        'password': hashPassword(password),
        'masterPassword': hashPassword(masterPassword),
        'profileImage': profileImage,
        'coins': 0,
      });

      return null;
    } catch (e) {
      return "Email already exists";
    }
  }

  // ✅ LOGIN (FINAL LOGIC)
  Future<String?> login(String email, String password) async {
    final db = await DBHelper.instance.database;

    // 🔹 Check email
    final userResult = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (userResult.isEmpty) {
      return "Account does not exist";
    }

    final user = userResult.first;
    // 🔹 Check password
    if (user['password'] != hashPassword(password)) {
      return "Password is incorrect";
    }

    // 🔹 Save session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', user['id'] as int);

    return null; // success
  }

  // ✅ GET CURRENT USER ID
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('isLoggedIn');
  }

  // 🔐 VERIFY MASTER PASSWORD
  Future<bool> verifyMasterPassword(int userId, String input) async {
    final db = await DBHelper.instance.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isEmpty) return false;

    return result.first['masterPassword'] == hashPassword(input);
  }

  // ✅ CHECK EMAIL EXISTS
  Future<String?> checkEmailExists(String email) async {
    final db = await DBHelper.instance.database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return "Email already exists";
    }

    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await DBHelper.instance.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<void> updateCoins(int userId, int newCoins) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'users',
      {'coins': newCoins},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<String?> getMasterPassword() async {
    final db = await DBHelper.instance.database;

    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first['masterPassword'] as String;
    }

    return null;
  }

  Future<String?> getUserPassword(int userId) async {
    final db = await DBHelper.instance.database;

    final result = await db.query(
      'users',
      columns: ['password'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first['password'] as String;
    }
    return null;
  }

  Future<void> updatePassword(
      String email,
      String newPassword,
      ) async {
    final db = await DBHelper.instance.database;

    await db.update(
      'users',
      {
        'password': hashPassword(newPassword),
      },
      where: 'email = ?',
      whereArgs: [email],
    );
  }

}