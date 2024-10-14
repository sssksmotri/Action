import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Путь к базе данных
  static final _databaseName = "habit_tracker.db";
  static final _databaseVersion = 1;

  // Названия таблиц
  static final tableHabits = 'Habits';
  static final tableReminders = 'Reminders';
  static final tableHabitLog = 'HabitLog';
  static final tableHabitNotes = 'HabitNotes';


  // Создание базы данных
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Инициализация базы данных
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    print('Initializing database at $path'); // Логирование пути к базе данных
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  // Создание таблиц
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableHabits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        quantity INTEGER,
        volume_per_press TEXT,
        volume_specified TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        days_of_week TEXT,
        notifications_enabled INTEGER DEFAULT 0,
        archived INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
  CREATE TABLE $tableReminders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    habit_id INTEGER NOT NULL,
    time TEXT NOT NULL,
    monday INTEGER NOT NULL DEFAULT 0,
    tuesday INTEGER NOT NULL DEFAULT 0,
    wednesday INTEGER NOT NULL DEFAULT 0,
    thursday INTEGER NOT NULL DEFAULT 0,
    friday INTEGER NOT NULL DEFAULT 0,
    saturday INTEGER NOT NULL DEFAULT 0,
    sunday INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT 0,
    FOREIGN KEY (habit_id) REFERENCES $tableHabits (id) ON DELETE CASCADE
  )
''');

    await db.execute('''
      CREATE TABLE $tableHabitLog (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        progress INTEGER,
        FOREIGN KEY (habit_id) REFERENCES $tableHabits (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableHabitNotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES $tableHabits (id) ON DELETE CASCADE
      )
    ''');

  }

  // CRUD операции (например, вставка новой привычки)
  Future<int> insertHabit(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableHabits, row);
  }

  // Получение всех привычек
  Future<List<Map<String, dynamic>>> queryAllHabits() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> habits = await db.query(tableHabits);
    print('Queried habits: $habits'); // Логирование полученных привычек
    return habits;
  }
  Future<Map<String, dynamic>> queryHabitById(int id) async {
    final Database db = await database; // Используйте await database для получения базы данных
    final List<Map<String, dynamic>> maps = await db.query(
      tableHabits, // используем имя таблицы
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first; // Возвращаем первую запись (если есть)
    } else {
      throw Exception('Habit with id $id not found');
    }
  }

  // Обновление привычки
  Future<int> updateHabit(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableHabits, row, where: 'id = ?', whereArgs: [id]);
  }

  // Удаление привычки
  Future<int> deleteHabit(int id) async {
    Database db = await instance.database;
    return await db.delete(tableHabits, where: 'id = ?', whereArgs: [id]);
  }
  Future<int> insertReminder(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableReminders, row);
  }

  Future<List<Map<String, dynamic>>> queryAllReminders() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> reminders = await db.query(tableReminders);
    print('Queried reminders: $reminders'); // Логирование полученных напоминаний
    return reminders;
  }

  Future<List<Map<String, dynamic>>> queryReminders(int habitId) async {
    Database db = await instance.database;
    return await db.query(tableReminders, where: 'habit_id = ?', whereArgs: [habitId]);
  }

  Future<int> updateReminder(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableReminders, row, where: 'id = ?', whereArgs: [id]);
  }

  // Добавляем метод для обновления состояния уведомлений конкретной привычки
  Future<int> updateHabitNotificationState(int habitId, int isActive) async {
    Database db = await instance.database;

    // Обновляем поле active (0 - включено, 1 - выключено) для конкретной привычки
    return await db.update(
      tableHabits,
      {'active': isActive}, // обновляем только поле активного уведомления
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }


  Future<int> deleteReminder(int id) async {
    Database db = await instance.database;
    return await db.delete(tableReminders, where: 'id = ?', whereArgs: [id]);
  }
  Future<Map<String, dynamic>?> queryReminderById(int reminderId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
        'reminders', // Таблица напоминаний
        where: 'id = ?',
        whereArgs: [reminderId]
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;  // Если напоминание не найдено
    }
  }
}
