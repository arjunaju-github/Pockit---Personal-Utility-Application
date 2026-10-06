import '../database/db_helper.dart';

class NoteService {

  final dbHelper = DBHelper.instance; // 👈 use your singleton

  // ➕ CREATE NOTE
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await dbHelper.database;

    return await db.insert('notes', note);
  }

  // 📄 GET ALL NOTES (for a user)
  Future<List<Map<String, dynamic>>> getNotes(int userId) async {
    final db = await dbHelper.database;

    return await db.query(
      'notes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }

  // ✏️ UPDATE NOTE
  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    final db = await dbHelper.database;

    return await db.update(
      'notes',
      note,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ❌ DELETE SINGLE NOTE
  Future<int> deleteNote(int id) async {
    final db = await dbHelper.database;

    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔥 DELETE ALL NOTES (for reset)
  Future<void> deleteAllNotes(int userId) async {
    final db = await dbHelper.database;

    await db.delete(
      'notes',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}