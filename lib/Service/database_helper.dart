import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseHelper {
  // Путь к базе данных
  static final _databaseName = "habit_tracker.db";
  static final _databaseVersion = 1;

  // Названия таблиц
  static final tableHabits = 'Habits';
  static final tableReminders = 'Reminders';
  static final tableHabitLog = 'HabitLog';
  static final tableHabitNotes = 'HabitNotes';
  static final tableAppUsageLog = "AppUsageLog";
  final Uuid uuid = Uuid();


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
    return await openDatabase(
        path, version: _databaseVersion, onCreate: _onCreate);
  }

  // Создание таблиц
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableHabits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        quantity INTEGER,
        volume_per_press REAL,
        volume_specified REAl,
        start_date TEXT NOT NULL,
        end_date TEXT,
        notifications_enabled INTEGER DEFAULT 0,
        archived INTEGER DEFAULT 0,
        position INTEGER NOT NULL DEFAULT 0
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
      status TEXT DEFAULT 'not_completed',  
      progress INTEGER,
      FOREIGN KEY (habit_id) REFERENCES $tableHabits (id) ON DELETE CASCADE
    )
''');


      await db.execute('''
  CREATE TABLE $tableAppUsageLog (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE,
    user_id TEXT,
    language TEXT,
    login_date TEXT, 
    login_time TEXT,
    end_time TEXT,
    total_duration TEXT,
    habit_count INTEGER DEFAULT 0,
    deviceInfo TEXT,
    section_times TEXT,
    action TEXT,
    datetime_action TEXT
  );
''');


    await db.execute('''
      CREATE TABLE $tableHabitNotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        question TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES $tableHabits (id) ON DELETE CASCADE
      )
    ''');
  }

  // CRUD операции (например, вставка новой привычки)
  Future<int> insertHabit(Map<String, dynamic> row) async {
    Database db = await instance.database;

    // Получаем максимальное значение позиции
    final maxPositionResult = await db.rawQuery(
        'SELECT MAX(position) as max_position FROM $tableHabits');
    int maxPosition = maxPositionResult.first['max_position'] != null
        ? maxPositionResult.first['max_position'] as int
        : 0;

    // Устанавливаем следующую позицию для новой привычки
    row['position'] = maxPosition + 1;

    return await db.insert(tableHabits, row);
  }

  Future<int> updateHabitPosition(int habitId, int newPosition) async {
    final db = await database;
    return await db.update(
      'Habits', // Таблица
      {'position': newPosition}, // Новое значение позиции
      where: 'id = ?', // Обновляем по id
      whereArgs: [habitId],
    );
  }

  // Получение всех привычек
  Future<List<Map<String, dynamic>>> queryAllHabits() async {
    final db = await database;
    return await db.query(
        'Habits', orderBy: 'position ASC'); // Сортировка по полю position
  }

  Future<List<Map<String, dynamic>>> queryActiveHabits() async {
    final db = await database;
    // Запрос для получения привычек с archived = 0
    return await db.query(
        'Habits', // Таблица привычек
        where: 'archived = ?', // Условие отбора
        whereArgs: [0], // Значение для поля archived
        orderBy: 'position ASC' // Сортируем по позиции
    );
  }

  Future<List<Map<String, dynamic>>> getArchivedHabits() async {
    final db = await database; // Получаем базу данных
    return await db.query('habits', where: 'archived = ?',
        whereArgs: [1]); // Получаем архивированные привычки
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

    // Логируем данные перед обновлением
    print('Обновляем привычку с данными: $row');

    // Проверяем, существует ли ID
    int? id = row['id'];

    if (id == null) {
      print('Ошибка: ID не найден в переданных данных.');
      return 0; // Или выбросьте исключение
    }

    // Проверяем наличие обязательных полей
    if (row['type'] == null) {
      print('Ошибка: type не может быть null');
      return 0; // Или выбросьте исключение
    }

    // Обновление записи в БД
    int result;
    try {
      result = await db.update(tableHabits, row, where: 'id = ?', whereArgs: [id]);
      print('Успешно обновлено. Изменения: $result'); // Логируем количество обновленных строк
    } catch (e) {
      print('Ошибка при обновлении привычки: $e'); // Логируем ошибку, если она произошла
      return 0; // Или выбросьте исключение
    }

    return result; // Возвращаем результат обновления
  }




  Future<int> updateHabitQuantity(int habitId, int newQuantity) async {
    final db = await database;

    // Обновляем поле quantity для конкретной привычки по её id
    return await db.update(
      tableHabits, // Имя таблицы
      {'quantity': newQuantity}, // Обновляемое значение
      where: 'id = ?', // Условие
      whereArgs: [habitId], // Значение для условия
    );
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
    print(
        'Queried reminders: $reminders'); // Логирование полученных напоминаний
    return reminders;
  }

  Future<List<Map<String, dynamic>>> queryReminders(int habitId) async {
    Database db = await instance.database;
    return await db.query(
        tableReminders, where: 'habit_id = ?', whereArgs: [habitId]);
  }

  Future<int> updateReminder(int reminderId,
      Map<String, dynamic> reminderData) async {
    final db = await database;
    return await db.update(
      'reminders', // Имя таблицы
      reminderData, // Данные для обновления
      where: 'id = ?', // Условие для обновления
      whereArgs: [reminderId], // Аргументы для условия
    );
  }

  // Добавляем метод для обновления состояния уведомлений конкретной привычки
  Future<void> updateHabitNotificationState(int id,
      int notificationsEnabled) async {
    final db = await database;
    await db.update(
      'Habits',
      {'notifications_enabled': notificationsEnabled},
      where: 'id = ?',
      whereArgs: [id],
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
      return null; // Если напоминание не найдено
    }
  }

  Future<int> insertHabitNote(Map<String, dynamic> noteData) async {
    Database db = await instance.database;
    return await db.insert(tableHabitNotes, noteData);
  }


  Future<void> updateHabitProgress(int habitId, double newProgress,
      String date) async {
    final db = await database;

    // Проверяем, есть ли запись для данной привычки в HabitLog
    final List<Map<String, dynamic>> results = await db.query(
      'HabitLog',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );

    if (results.isNotEmpty) {
      // Если запись существует, обновляем её
      await db.update(
        'HabitLog',
        {'progress': newProgress},
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, date],
      );
    } else {
      // Если запись не существует, создаем новую
      await db.insert(
        'HabitLog',
        {
          'habit_id': habitId,
          'date': date,
          'progress': newProgress,
        },
      );
    }
  }

  Future<Map<int, double>> getHabitsProgress(List<int> habitIds) async {
    final db = await database;

    // Подготовка строки запроса для IN
    final placeholders = List.generate(habitIds.length, (_) => '?').join(', ');
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT habit_id, SUM(progress) as total_progress FROM HabitLog WHERE habit_id IN ($placeholders) GROUP BY habit_id',
      habitIds,
    );

    // Создаем карту с прогрессом
    Map<int, double> progressMap = {};
    for (var row in results) {
      progressMap[row['habit_id']] = row['total_progress']?.toDouble() ?? 0.0;
    }
    return progressMap;
  }

  Future<Map<int, double>> getHabitsProgressForDay(List<int> habitIds,
      String date) async {
    final db = await database;

    // Подготовка строки запроса для IN
    final placeholders = List.generate(habitIds.length, (_) => '?').join(', ');
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT habit_id, progress FROM HabitLog WHERE habit_id IN ($placeholders) AND date = ?',
      [...habitIds, date], // Передаем список идентификаторов привычек и дату
    );

    // Создаем карту с прогрессом
    Map<int, double> progressMap = {};
    for (var row in results) {
      progressMap[row['habit_id']] = row['progress']?.toDouble() ?? 0.0;
    }
    return progressMap;
  }

  Future<void> updateHabitStatus(int habitId, String status, String date) async {
    final db = await database;

    // Печатаем информацию перед обновлением
    print('Updating habit status...');
    print('Habit ID: $habitId');
    print('Status: $status');
    print('Date: $date');

    await db.update(
      'HabitLog',
      {'status': status},
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );

    // Подтверждение успешного обновления
    print('Status updated successfully for habit ID $habitId on date $date');
  }



  Future<void> archiveExpiredHabits() async {
    final db = await database;

    // Получаем текущую дату в формате, который используется в базе данных
    String currentDate = DateTime
        .now()
        .toIso8601String()
        .split('T')
        .first;

    // Обновляем привычки, срок которых истек (end_date меньше текущей даты)
    await db.update(
      tableHabits, // Название таблицы
      {'archived': 1}, // Устанавливаем флаг архивирования
      where: 'end_date < ? AND archived = 0',
      // Условие: дата завершения меньше текущей и привычка не архивирована
      whereArgs: [currentDate],
    );
  }

  Future<List<Map<String, dynamic>>> getHabitsForDateRange(String startDate,
      String endDate) async {
    final db = await database;

    // Запрос всех привычек, которые активны в выбранный диапазон дат
    return await db.query(
      'Habits',
      where: 'start_date <= ? AND end_date >= ?',
      whereArgs: [endDate, startDate],
      // Привычки, которые активны в этот период
      orderBy: 'start_date ASC', // Сортировка по дате
    );
  }


  Future<List<Map<String, dynamic>>> queryNotesByHabitId(int habitId) async {
    final db = await database;
    return await db.query(
      tableHabitNotes,
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
  }

  Future<int> deleteHabitNote(int id) async {
    Database db = await instance.database;
    print("Deleting note with id: $id"); // Выводим ID удаляемой заметки
    return await db.delete(tableHabitNotes, where: 'id = ?', whereArgs: [id]);
  }


  Future<List<Map<String, dynamic>>> getHabitLogsForDateRange(String startDate,
      String endDate) async {
    final db = await database;

    // Запрос данных из таблицы habit_logs за указанный диапазон дат
    return await db.query(
      'HabitLog',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC', // Сортировка по дате
    );
  }

  Future<List<Map<String, dynamic>>> getHabitNotes(int habitId) async {
    final db = await database;
    final List<Map<String, dynamic>> notes = await db.query(
      tableHabitNotes,
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );

    return notes.map((note) {
      return {
        'id': note['id'],
        'habit_id': note['habit_id'],
        'note': note['note'] ?? '', // Текст заметки
        'question': note['question'] ?? '', // Вопрос
        'created_at': note['created_at'] ?? '',
      };
    }).toList();
  }
  Future<String> generateUserId() async {
    final db = await database;
    String userId = uuid.v4();
    await db.insert('AppUsageLog', {'user_id': userId});
    return userId;
  }

  Future<List<Map<String, dynamic>>> queryAllAppUsageLogs() async {
    final db = await instance.database;
    return await db.query('AppUsageLog');
  }

  Future<int> insertAppUsageLog(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('AppUsageLog', row);
  }

  Future<void> addDeviceInfo(String deviceInfo) async {
    final db = await database;

    await db.insert(
      'AppUsageLog', // Замени на актуальное имя таблицы
      {
        'deviceInfo': deviceInfo, // Поле для информации о девайсе
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Обновляем запись в случае конфликта
    );
  }

  Future<int> logSessionStart(String language, String deviceInfo, int userId) async {
    final db = await database;
    String sessionId = uuid.v4();
    String loginDate = DateTime.now().toIso8601String().split("T")[0];
    String loginTime = DateTime.now().toIso8601String().split("T")[1];

    int id = await db.insert(
      'AppUsageLog',
      {
        'session_id': sessionId,
        'user_id': userId,
        'language': language,
        'login_date': loginDate,
        'login_time': loginTime,
        'deviceInfo': deviceInfo,
      },
    );
    return id;
  }


  Future<void> logSessionEnd(int sessionId) async {
    final db = await database;
    final result = await db.query(
      'AppUsageLog',
      columns: ['login_date', 'login_time'],
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (result.isNotEmpty) {
      final loginDate = result.first['login_date'] as String?;
      final loginTime = result.first['login_time'] as String?;

      if (loginDate != null && loginTime != null) {
        // Объединяем дату и время в одну строку
        final loginDateTimeString = '$loginDate $loginTime';
        DateTime parsedLoginTime;

        // Попробуйте распарсить время входа
        try {
          parsedLoginTime = DateTime.parse(loginDateTimeString); // Парсим полное значение даты и времени
        } catch (e) {
          print('Ошибка парсинга времени входа: $e');
          return; // Выход из метода, если формат неверный
        }

        final duration = DateTime.now().difference(parsedLoginTime);
        String formattedDuration = _formatDuration(duration); // Форматируем продолжительность

        await db.update(
          'AppUsageLog',
          {
            'total_duration': formattedDuration,
            'end_time': DateTime.now().toIso8601String(), // Сохраняем полное время завершения
          },
          where: 'id = ?',
          whereArgs: [sessionId],
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }


  Future<void> logSectionTime(int sessionId, String sectionName, int timeSpent) async {
    final db = await database;

    // Запрашиваем текущее значение section_times
    final result = await db.query(
      'AppUsageLog',
      columns: ['section_times'],
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    // Инициализируем пустую строку для section_times
    String sectionTimes = '';

    if (result.isNotEmpty && result.first['section_times'] is String) {
      // Получаем текущее значение section_times
      sectionTimes = result.first['section_times'] as String;
    }

    // Проверяем, существует ли уже запись для текущего раздела
    bool sectionFound = false;

    // Разбиваем существующие записи на отдельные секции
    List<String> sectionEntries = sectionTimes.split(',').map((e) => e.trim()).toList();

    for (int i = 0; i < sectionEntries.length; i++) {
      // Проверяем, содержит ли запись имя текущего раздела
      if (sectionEntries[i].startsWith(sectionName)) {
        // Если раздел найден, прибавляем время
        int existingTimeInSeconds = _parseTimeToSeconds(sectionEntries[i]);
        int updatedTimeInSeconds = existingTimeInSeconds + timeSpent;
        String updatedEntry = _formatSecondsToTime(updatedTimeInSeconds);
        sectionEntries[i] = '$sectionName-$updatedEntry'; // Обновляем запись
        sectionFound = true;
        break;
      }
    }

    // Если раздел не найден, добавляем новую запись
    if (!sectionFound) {
      String newEntry = _formatSecondsToTime(timeSpent);
      if (sectionTimes.isNotEmpty) {
        sectionEntries.add('$sectionName-$newEntry'); // Добавляем с запятой только если есть существующие записи
      } else {
        sectionEntries.add('$sectionName-$newEntry'); // Если строка пустая, просто добавляем
      }
    }

    // Удаляем пустые записи и убираем лишние запятые
    sectionEntries = sectionEntries.where((entry) => entry.isNotEmpty).toList();

    // Объединяем записи обратно в строку через запятую
    String updatedSectionTimes = sectionEntries.join(',').trim(); // Используем trim() чтобы убрать пробелы по краям

    await db.update(
      'AppUsageLog',
      {'section_times': updatedSectionTimes},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }



// Пример функции для форматирования секунд в формат часы:минуты:секунды
  String _formatSecondsToTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

// Пример функции для парсинга времени из строки
  int _parseTimeToSeconds(String entry) {
    final parts = entry.split('-');
    if (parts.length < 2) return 0;

    final timePart = parts[1];
    final timeParts = timePart.split(':');

    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);
    int seconds = int.parse(timeParts[2]);

    return hours * 3600 + minutes * 60 + seconds;
  }


  Future<void> logAction(int sessionId, String actionName) async {
    final db = await database;

    // Получаем текущее значение action
    final result = await db.query(
      'AppUsageLog',
      columns: ['action'],
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    // Инициализируем пустой список для действий
    List<String> actionList = [];

    if (result.isNotEmpty) {
      // Получаем значение поля action
      String? currentActions = result.first['action'] as String?;

      if (currentActions != null) {
        // Если значение не null, разбиваем его по новой строке
        actionList = currentActions.split('\n').toList();
      }
    }

    // Формируем запись для текущего действия
    String actionTime = '$actionName - ${DateTime.now().toIso8601String().split("T")[1].split('.').first}'; // Убираем миллисекунды

    // Добавляем новое действие
    actionList.add(actionTime);

    // Объединяем список обратно в строку через новую строку
    String updatedActions = actionList.join('\n');

    await db.update(
      'AppUsageLog',
      {'action': updatedActions},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }



  Future<void> incrementHabitCount(int sessionId) async {
    final db = await database;

    final result = await db.query(
      'AppUsageLog',
      columns: ['habit_count'],
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    int habitCount = (result.isNotEmpty && result.first['habit_count'] != null)
        ? result.first['habit_count'] as int
        : 0;

    habitCount += 1;

    await db.update(
      'AppUsageLog',
      {'habit_count': habitCount},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }


  Future<void> sendAnalyticsDataForLast12Hours() async {
    final db = await instance.database;
    final now = DateTime.now();

    // Форматируем текущую дату в нужный формат
    final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final apiKey = dotenv.env['API_KEY'];
    final dbUrl = dotenv.env['DATABASE_URL_SEND12H'];
    // Задаем начало и конец временного интервала в зависимости от времени суток
    String startTime;
    String endTime;

    if (now.hour < 12) {
      // Время от 00:00 до 12:00
      startTime = "00:00:00";
      endTime = "12:00:00";
    } else {
      // Время от 12:00 до 23:59
      startTime = "12:00:00";
      endTime = "23:59:59";
    }

    // Делаем запрос по текущей дате и времени в заданном интервале
    final result = await db.query(
      'AppUsageLog',
      where: 'login_date = ? AND login_time BETWEEN ? AND ?',
      whereArgs: [formattedDate, startTime, endTime],
    );

    // Проверяем и обрабатываем записи
    if (result.isNotEmpty) {
      for (var logEntry in result) {
        final userId = logEntry['user_id'];
        final device = logEntry['deviceInfo'] as String? ?? '';
        final language = logEntry['language'] as String? ?? '';

        if (userId == null || device.isEmpty || language.isEmpty) {
          print('Ошибка: недостающие данные для отправки. user_id: $userId, device: $device, language: $language');
          continue; // Пропустить этот лог, если данные недоступны
        }

        String action = logEntry['action'] as String? ?? '';
        String loginDate = logEntry['login_date'] as String;
        String loginTime = logEntry['login_time'] as String;
        String lastLogin = '$loginDate' + 'T' + loginTime.split('.').first; // Убираем миллисекунды

        final data = {
          'user_id': userId.toString(),
          'device': device,
          'action': action,
          'language': language,
          'last_login': lastLogin,
          'activity_duration': logEntry['total_duration'] as String? ?? '',
          'section_time': logEntry['section_times'] as String? ?? '',
          'habits_added': logEntry['habit_count']?.toString() ?? '0',

        };

        final url = Uri.parse(dbUrl!);

        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json',
            'X-API-Key':apiKey!},
            body: jsonEncode(data),
          );

          if (response.statusCode == 201) {
            print('Данные успешно отправлены: ${response.body}');
            // Покажите пользователю сообщение о успешной отправке
            _showSuccessDialog('Данные успешно отправлены!');
          }
          if (response.statusCode == 200) {
            print('Данные успешно отправлены: ${response.body}');
            // Покажите пользователю сообщение о успешной отправке
            _showSuccessDialog('Данные успешно отправлены!');
          }
          else {
            print('Ошибка при отправке данных: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          print('Ошибка: $e');
        }
      }
    } else {
      print('Записей за указанный интервал сегодня не найдено.');
    }
  }


// Метод для отображения диалогового окна с успешным сообщением
  void _showSuccessDialog(String message) {
    // Реализуйте показ сообщения пользователю
  }




}




