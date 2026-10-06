import '../database/db_helper.dart';
import '../pages/task.dart';
import 'auth_service.dart';

class TaskService {
  final dbHelper = DBHelper.instance;

  Future<int> insertTask(Task task) async {
    final db = await dbHelper.database;

    final userId = await AuthService().getCurrentUserId();
    if (userId == null) throw Exception("User not logged in");

    return await db.insert(
      'tasks',
      {
        ...task.toMap(),
        'userId': userId,
      },
    );
  }

  Future<List<Task>> getTasks() async {
    final db = await dbHelper.database;

    final userId = await AuthService().getCurrentUserId();
    if (userId == null) return [];

    final maps = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dueDate ASC, dueTime ASC',
    );

    return maps.map((e) => Task.fromMap(e)).toList();
  }

  Future<int> deleteTask(int id) async {
    final db = await dbHelper.database;

    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTask(int id, Task task) async {
    final db = await dbHelper.database;

    return await db.update(
      'tasks',
      {
        "title": task.title,
        "description": task.description,
        "icon": task.icon,
        "dueDate": task.dueDate,
        "dueTime": task.dueTime,
        "isDone": task.isDone,
        "userId": task.userId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllTasks(int userId) async {
    final db = await dbHelper.database;

    await db.delete(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}