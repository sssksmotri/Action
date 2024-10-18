import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'add.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'archive.dart';
import 'addpage.dart';
import 'stat.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:action_notes/Service/NotificationService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:action_notes/Service/HabitReminderService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  NotificationService notificationService = NotificationService();
  await notificationService.init();
  await DatabaseHelper.instance.database;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Localization Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Map<String, dynamic>> _habits = [];
  String? _selectedFilter;
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();
  final HabitReminderService habitReminderService = HabitReminderService();

  @override
  void initState() {
    super.initState();
    _loadHabits();
    habitReminderService.initializeReminders();// Фильтруем привычки при инициализации
    DatabaseHelper db = DatabaseHelper.instance;
    db.archiveExpiredHabits();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotesPage()),
      );
    }

    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddActionPage()),
      );
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StatsPage()),
      );
    }
  }


  // Метод для подтверждения удаления
  void _showDeleteDialog(BuildContext context, String taskTitle,int habitId,
      Function() onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          // Паддинг для внутреннего контента
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Are you sure you want to delete ",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  children: [
                    TextSpan(
                      text: taskTitle,
                      style: const TextStyle(
                        color: Color(0xFF5F33E1),
                        // Фиолетовый цвет для названия задачи
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: "?",
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Кнопка "No, leave it"
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Закрыть диалог
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFEEE9FF),
                      // Легкий фиолетовый фон
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "No, leave it",
                      style: TextStyle(
                        color: Color(0xFF5F33E1), // Фиолетовый текст
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Отступ между кнопками
                // Кнопка "Yes, delete"
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Закрыть диалог
                      _deleteHabit(habitId); // Вызов метода удаления
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red, // Красный фон
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Yes, delete",
                      style: TextStyle(
                        color: Colors.white, // Белый текст
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFFEEE9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_habits.length}', // Динамическое отображение количества привычек
                    style: TextStyle(
                      color: Color(0xFF5F33E1),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Image.asset('assets/images/Filter.png'),
                  onPressed: () {
                    _showPopupMenu(context);
                  },
                ),
                IconButton(
                  icon: Image.asset('assets/images/Folder.png'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArchivePage(),
                      ),
                    ).then((result) {
                      // Здесь вы можете обновить состояние, если нужно
                      if (result != null) {
                        setState(() {
                          _loadHabits();
                        });
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                onReorder: _onReorder, // Используем метод _onReorder
                itemCount: _habits.length, // Количество привычек
                itemBuilder: (context, index) {
                  final habit = _habits[index]; // Привычка
                  int habitType = int.parse(habit['type'].toString());

                  // Для привычек с типом "одно действие" (habitType == 0)
                  if (habitType == 0) {
                    bool isCompleted = habit['currentProgress'] == 1;

                    return _buildHabitItem(
                      habit['name'], // Название привычки
                      isCompleted, // Завершена ли привычка
                          () async {  if (!isSameDay(_selectedDate, _today)) {
                            return;
                          }
                        // Переключаем состояние завершения привычки
                        int newProgress = isCompleted ? 0 : 1; // Устанавливаем новое состояние: 0 - не завершено, 1 - завершено

                        await DatabaseHelper.instance.updateHabitProgress(
                          habit['id'],
                          newProgress.toDouble(), // Обновляем прогресс до нового значения
                          DateTime.now().toIso8601String().split('T')[0],
                        );

                        setState(() {
                          _habits = List.from(_habits);
                          _habits[index] = Map<String, dynamic>.from(_habits[index])
                            ..['currentProgress'] = newProgress; // Обновляем текущий прогресс
                        });
                      },
                      habit['id'], // Добавленный недостающий аргумент habitId
                      key: ValueKey(habit['id']), // Опциональный ключ
                    );
                  }


                  // Для привычек с количеством (habitType == 1)
                  else if (habitType == 1) {
                    int currentProgress = (habit['currentProgress'] ?? 0).toInt(); // Начальное значение текущего прогресса
                    int maxProgress = (habit['quantity'] ?? 10).toInt(); // Максимальное значение прогресса

                    return _buildCountItem(
                      habit['name'],
                      currentProgress, // Отображаем текущий прогресс
                      maxProgress,
                          () async {
                            if (!isSameDay(_selectedDate, _today)) {
                              return;
                            }
                        if (currentProgress < maxProgress) {
                          int newProgress = currentProgress + 1; // Увеличиваем прогресс на 1
                          await DatabaseHelper.instance.updateHabitProgress(
                            habit['id'],
                            newProgress.toDouble(),
                            DateTime.now().toIso8601String().split('T')[0],
                          );
                          setState(() {
                            _habits = List.from(_habits);
                            _habits[index] = Map<String, dynamic>.from(_habits[index])
                              ..['currentProgress'] = newProgress; // Обновляем текущий прогресс
                          });
                        }
                      },
                          () async {
                            if (!isSameDay(_selectedDate, _today)) {
                              return;
                            }
                        if (currentProgress > 0) {
                          int newProgress = currentProgress - 1; // Уменьшаем прогресс на 1
                          await DatabaseHelper.instance.updateHabitProgress(
                            habit['id'],
                            newProgress.toDouble(),
                            DateTime.now().toIso8601String().split('T')[0],
                          );
                          setState(() {
                            _habits = List.from(_habits);
                            _habits[index] = Map<String, dynamic>.from(_habits[index])
                              ..['currentProgress'] = newProgress; // Обновляем текущий прогресс
                          });
                        }
                      },
                          () {
                        _showDeleteDialog(context, habit['name'], habit['id'], () {});
                      },
                      habit['id'],
                      key: ValueKey(habit['id']),
                    );
                  }
                  // Для привычек с объёмом (habitType == 2)
                  else if (habitType == 2) {
                    double currentProgress = habit['currentProgress'] ?? 0.0;
                    double maxProgress = habit['volume_specified'] ?? 1.0; // Общий объем

                    return _buildPressCountHabit(
                      habit,
                          () async {
                            if (!isSameDay(_selectedDate, _today)) {
                              return;
                            }
                        if (currentProgress < maxProgress) {
                          double newProgress = currentProgress + (habit['volume_per_press'] ?? 0.1);
                          await DatabaseHelper.instance.updateHabitProgress(
                            habit['id'],
                            newProgress.toDouble(),
                            DateTime.now().toIso8601String().split('T')[0],
                          );
                          setState(() {
                            // Создаем копию и обновляем прогресс
                            _habits = List.from(_habits);
                            _habits[index] = Map<String, dynamic>.from(_habits[index])
                              ..['currentProgress'] = newProgress;
                          });
                        }
                      },
                          () async {
                            if (!isSameDay(_selectedDate, _today)) {
                              return;
                            }
                        if (currentProgress > 0) {
                          double newProgress = currentProgress - (habit['volume_per_press'] ?? 0.1);
                          await DatabaseHelper.instance.updateHabitProgress(
                            habit['id'],
                            newProgress.toDouble(),
                            DateTime.now().toIso8601String().split('T')[0],
                          );
                          setState(() {
                            // Создаем копию и обновляем прогресс
                            _habits = List.from(_habits);
                            _habits[index] = Map<String, dynamic>.from(_habits[index])
                              ..['currentProgress'] = newProgress;
                          });
                        }
                      },
                          () {
                        // Логика редактирования привычки
                      },
                          () {
                        _showDeleteDialog(context, habit['name'],habit['id'], () {});
                      },
                      habit['id'],
                      key: ValueKey(habit['id']),
                    );
                  } else {
                    return Container(); // Для других типов
                  }
                },
              ),
            ),
            _buildBottomDateSelector(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 30, right: 16, left: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEE9FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'assets/images/Home.png', isSelected: true),
            _buildNavItem(1, 'assets/images/Edit.png'),
            _buildNavItem(2, 'assets/images/Plus.png'),
            _buildNavItem(3, 'assets/images/Calendar.png'),
            _buildNavItem(4, 'assets/images/Setting.png'),
          ],
        ),
      ),
    );
  }





  Future<void> _loadHabits() async {
    // Создаем экземпляр DatabaseHelper для работы с базой данных
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    // Получаем все активные привычки
    List<Map<String, dynamic>> habits = await dbHelper.queryActiveHabits();

    // Получаем список id всех привычек
    List<int> habitIds = habits.map((habit) => habit['id'] as int).toList();

    // Получаем прогресс привычек из таблицы HabitLog за текущий день
    String today = DateTime.now().toIso8601String().split('T')[0];
    Map<int, double> habitProgress = await dbHelper.getHabitsProgressForDay(habitIds, today);

    // Обновляем состояние приложения
    setState(() {
      _habits = habits.map((habit) {
        int habitId = habit['id'] as int;
        double currentProgress = habitProgress[habitId] ?? 0.0;
        return {
          ...habit,
          'currentProgress': currentProgress,  // Добавляем прогресс
        };
      }).toList();
    });
  }

  Future<void> _loadHabitsForSelectedDate() async {
    // Создаем экземпляр DatabaseHelper для работы с базой данных
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    // Получаем все активные привычки
    List<Map<String, dynamic>> habits = await dbHelper.queryActiveHabits();

    // Получаем список id всех привычек
    List<int> habitIds = habits.map((habit) => habit['id'] as int).toList();

    // Получаем прогресс привычек из таблицы HabitLog за выбранную дату (_selectedDate)
    String selectedDate = _selectedDate.toIso8601String().split('T')[0];
    Map<int, double> habitProgress = await dbHelper.getHabitsProgressForDay(habitIds, selectedDate);

    // Фильтруем привычки, чтобы показывать только те, которые активны в выбранный день
    List<Map<String, dynamic>> filteredHabits = habits.where((habit) {
      // Проверяем наличие startDate и endDate
      String? startDateStr = habit['start_date'];
      String? endDateStr = habit['end_date'];

      // Если нет даты начала, игнорируем эту привычку
      if (startDateStr == null) return false;

      // Парсим startDate
      DateTime startDate = DateTime.parse(startDateStr);

      // Если endDate есть, парсим её, если нет, оставляем как null
      DateTime? endDate = endDateStr != null ? DateTime.parse(endDateStr) : null;

      // Проверяем, входит ли выбранная дата в период действия привычки
      if (_selectedDate.isAfter(startDate) || isSameDay(_selectedDate, startDate)) {
        if (endDate == null || _selectedDate.isBefore(endDate) || isSameDay(_selectedDate, endDate)) {
          return true; // Привычка должна отображаться
        }
      }
      return false; // Привычка не показывается
    }).toList();

    // Обновляем состояние приложения с привычками и их прогрессом за выбранную дату
    setState(() {
      _habits = filteredHabits.map((habit) {
        int habitId = habit['id'] as int;
        double currentProgress = habitProgress[habitId] ?? 0.0;
        return {
          ...habit,
          'currentProgress': currentProgress,  // Прогресс за выбранный день
        };
      }).toList();
    });
  }



  bool isSameDay(DateTime date1, DateTime date2) {
    return DateUtils.isSameDay(date1, date2);
  }


  void _onReorder(int oldIndex, int newIndex) async {
    // Корректируем индекс, если перемещение сверху вниз
    if (oldIndex < newIndex) {
      newIndex--;
    }

    // Проверяем индексы, чтобы они находились в пределах списка
    print('Before reorder: _habits length: ${_habits.length}, oldIndex: $oldIndex, newIndex: $newIndex');

    if (oldIndex < 0 || oldIndex >= _habits.length || newIndex < 0 || newIndex >= _habits.length) {
      print('Invalid indices: oldIndex = $oldIndex, newIndex = $newIndex');
      return;
    }

    // Создаем изменяемую копию списка _habits
    List<Map<String, dynamic>> updatedHabits = List.from(_habits);

    // Удаляем привычку из старой позиции и вставляем в новую
    final habit = updatedHabits.removeAt(oldIndex); // Удаляем привычку
    updatedHabits.insert(newIndex, habit); // Вставляем в новое место

    // Обновляем состояние с новым списком
    setState(() {
      _habits = updatedHabits;
      _selectedFilter='Custom';
    });

    // Сохраняем обновленные позиции в базе данных
    await _updateHabitPositionsInDb();
  }


  Future<void> _updateHabitPositionsInDb() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    for (int i = 0; i < _habits.length; i++) {
      Map<String, dynamic> habit = _habits[i];
      // Обновляем позицию в базе данных
      await dbHelper.updateHabitPosition(habit['id'], i);
    }
  }



  void _showPopupMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 50, 0),
      items: [
        PopupMenuItem<String>(
          value: 'Completed first',
          child: Text('Completed first',
              style: TextStyle(
                  color: _selectedFilter == 'Completed first'
                      ? Color(0xFF5F33E1)
                      : Colors.black)),
        ),
        PopupMenuItem<String>(
          value: 'Not completed at first',
          child: Text('Not completed at first',
              style: TextStyle(
                  color: _selectedFilter == 'Not completed at first'
                      ? Color(0xFF5F33E1)
                      : Colors.black)),
        ),
        PopupMenuItem<String>(
          value: 'Custom',
          child: Text('Custom',
              style: TextStyle(
                  color: _selectedFilter == 'Custom'
                      ? Color(0xFF5F33E1)
                      : Colors.black)),
        ),
      ],
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedFilter = value; // Применяем новый фильтр
          _filterHabits(); // Фильтруем привычки
          print('Выбран фильтр: $_selectedFilter');
        });
      }
    });
  }


  void _filterHabits() {
    if (_selectedFilter == 'Completed first') {
      _habits.sort((a, b) {
        bool aCompleted = a['currentProgress'] == 1;
        bool bCompleted = b['currentProgress'] == 1;
        return aCompleted ? (bCompleted ? 0 : -1) : (bCompleted ? 1 : 0);
      });
    } else if (_selectedFilter == 'Not completed at first') {
      _habits.sort((a, b) {
        bool aCompleted = a['currentProgress'] == 1;
        bool bCompleted = b['currentProgress'] == 1;
        // Сначала незавершенные (false) должны идти выше завершенных (true)
        if (!aCompleted && bCompleted) {
          return -1; // a выше b
        } else if (aCompleted && !bCompleted) {
          return 1; // b выше a
        } else {
          return 0; // Оба имеют одинаковый статус завершенности
        }
      });
    } else if (_selectedFilter == 'Custom') {
      // Добавьте свою логику для "Custom" фильтра
    }
  }




  Widget _buildNavItem(int index, String assetPath, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF5F33E1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 28,
            height: 28,
            color: isSelected ? Colors.white : Color(0xFF5F33E1),
          ),
        ),
      ),
    );
  }

  // Функция для создания карточки привычки
  Widget _buildHabitItem(String title, bool isCompleted, VoidCallback onTap, int habitId, {Key? key}) {
    // Проверяем, выполнена ли привычка
    bool isChecked = isCompleted;

    return _buildCard(
      key: key,
      child: GestureDetector(
        onTap: onTap, // При нажатии обновляем состояние привычки
        child: Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Если привычка выполнена - показываем галочку
                if (isChecked)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: const Icon(Icons.check, color: Colors.green, size: 28),
                  )
                // Если привычка не выполнена в конце дня - показываем крестик
                else if (DateTime.now().hour >= 23)  // Крестик если день закончился
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: const Icon(Icons.close, color: Colors.red, size: 28),
                  ),
                // Иначе показываем пустое место для нажатия
                Transform.rotate(
                  angle: -90 * (3.141592653589793238 / 180),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'Delete') {
                        _showDeleteDialog(context, title, habitId, () {});
                      } else if (value == 'Archive') {
                        _archiveHabit(habitId);
                      } else {
                        print('Selected: $value');
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem<String>(
                          value: 'Archive',
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('Archive'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Edit',
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('Edit'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Delete',
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ];
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// И аналогичные изменения для _buildCountItem
  Widget _buildCountItem(String title, int count, int maxCount,
      VoidCallback onIncrement, VoidCallback onDecrement, VoidCallback onDelete,
      int habitId, {Key? key}) {

    bool isCompleted = count >= maxCount;

    return _buildCard(
      key: key,
      child: GestureDetector(
        onTap: () => onIncrement(),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Если привычка выполнена - показываем галочку
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: const Icon(Icons.check, color: Colors.green, size: 28),
                      )
                    // Если день закончился и привычка не выполнена - показываем крестик
                    else if (DateTime.now().hour >= 23 && count < maxCount)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: const Icon(Icons.close, color: Colors.red, size: 28),
                      )
                    // Если привычка в процессе выполнения - показываем цифры прогресса
                    else
                      Text(
                        '$count/$maxCount',
                        style: TextStyle(
                          fontSize: 20,
                          color: isCompleted ? Colors.green : Colors.red,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Transform.rotate(
                      angle: -90 * (3.141592653589793238 / 180),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'Delete') {
                            _showDeleteDialog(context, title, habitId, onDelete);
                          } else if (value == 'Archive') {
                            _archiveHabit(habitId);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            const PopupMenuItem<String>(
                              value: 'Archive',
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Archive'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Edit',
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Edit'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Delete',
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ),
                          ];
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
                child: TextButton(
                  onPressed: count > 0 ? onDecrement : null,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5F33E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPressCountHabit(Map<String, dynamic> habit,
      VoidCallback onIncrement, VoidCallback onDecrement,
      VoidCallback onEdit, VoidCallback onDelete, int habitId, {Key? key}) {

    String title = habit['name'];
    double currentProgress = habit['currentProgress'] ?? 0.0;
    double maxProgress = habit['volume_specified'] ?? 1.0;
    bool isCompleted = currentProgress >= maxProgress;

    return _buildCard(
      key: key,
      child: GestureDetector(
        onTap: onIncrement,
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Галочка при достижении цели
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: const Icon(Icons.check, color: Colors.green, size: 28),
                      )
                    // Крестик при окончании дня и недостижении цели
                    else if (DateTime.now().hour >= 23 && currentProgress < maxProgress)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: const Icon(Icons.close, color: Colors.red, size: 28),
                      )
                    // Прогресс до достижения цели
                    else
                      Text(
                        '${currentProgress.toStringAsFixed(1)}/${maxProgress.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 20,
                          color: isCompleted ? Colors.green : Colors.red,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Transform.rotate(
                      angle: -90 * (3.141592653589793238 / 180), // Поворот для отображения меню
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                           if (value == 'Archive') {
                          _archiveHabit(habitId); // Передаем habitId в функцию архивирования
                          }
                           else if (value == 'Delete') {
                            _showDeleteDialog(context, title,habitId, onDelete);
                          } else if (value == 'Edit') {
                            onEdit(); // Открываем форму для редактирования
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            const PopupMenuItem<String>(
                              value: 'Archive',
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Archive'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Edit',
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Edit'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Delete',
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ),

                          ];
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
                child: TextButton(
                  onPressed: currentProgress > 0 ? onDecrement : null, // Уменьшаем прогресс
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5F33E1), // Фон кнопки
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    foregroundColor: Colors.white, // Цвет текста
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _archiveHabit(int habitId) async {
        DatabaseHelper db = DatabaseHelper.instance; // Получаем экземпляр вашего помощника по базе данных

        // Обновляем привычку в базе данных, устанавливая archived в 1
        await db.updateHabit({'id': habitId, 'archived': 1}); // Архивируем привычку

        // Обновляем состояние
        setState(() {
          // Создаем новый список на основе существующего, чтобы избежать ошибок с изменяемыми объектами
          _habits = List.from(_habits)..removeWhere((habit) => habit['id'] == habitId);
          _loadHabits();
        });
      }



//Карточки тени
  Widget _buildCard({Key? key, required Widget child}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTodayButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedDate = _today;
          });
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text('go_to_today'.tr()),
      ),
    );
  }

  Future<void> _deleteHabit(int habitId) async {
    DatabaseHelper db = DatabaseHelper.instance; // Получаем экземпляр вашего помощника по базе данных

    // Удаляем привычку из базы данных
    await db.deleteHabit(habitId);

    setState(() {
      _habits = List.from(_habits)..removeWhere((habit) => habit['id'] == habitId);
      _loadHabits();
      habitReminderService.cancelAllReminders(habitId);
    });

  }

  Widget _buildBottomDateSelector() {
    // Форматируем дату в виде "July, 15" с учетом локализации
    String formattedDate = DateFormat('MMMM, d', Localizations.localeOf(context).toString()).format(_selectedDate);

    return GestureDetector(
      onTap: () {
        _showCalendarDialog(); // Показываем календарь при нажатии на область с датой
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Центрируем все элементы
          children: [
            // Левая стрелка
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF5F33E1)),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  _loadHabitsForSelectedDate();  // Загружаем привычки за новый выбранный день
                });
              },
            ),

            // Дата
            Text(
              formattedDate,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Правая стрелка
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF5F33E1)),
              onPressed: isSameDay(_selectedDate, _today)
                  ? null  // Блокируем стрелку, если выбранная дата — сегодняшняя
                  : () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                  _loadHabitsForSelectedDate();  // Загружаем привычки за новый выбранный день
                });
              },
            ),

            // Кнопка возврата к сегодняшней дате, если выбранная дата не сегодняшняя
            if (!isSameDay(_selectedDate, _today))
              Container(
                width: 35,
                height: 35,
                margin: const EdgeInsets.only(left: 10), // Отступ от стрелки
                decoration: const BoxDecoration(
                  color: Color(0xFF5F33E1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/images/ar_back.png',
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _today; // Возвращаем сегодняшнюю дату
                      _loadHabitsForSelectedDate();  // Перезагружаем привычки для сегодняшнего дня
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }


  // Функция для показа календаря в виде прозрачного окна
  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              bottom: 90, // Отступ выше BottomNavigationBar
              left: 10, // Отступы для более узкого окна
              right: 10,
              child: Opacity(
                opacity: 1, // Делаем окно полупрозрачным
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2010, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: _selectedDate,
                          calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: const Color(0xFF5F33E1),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: Colors.transparent, // Без фона
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF5F33E1), // Цвет контура
                                width: 1, // Толщина контура
                              ),
                            ),
                            todayTextStyle: TextStyle(
                              color: Colors.black, // Цвет текста для сегодняшнего дня
                            ),
                            outsideDaysVisible: false,
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            leftChevronIcon: const Icon(
                                Icons.chevron_left, color: Color(0xFF5F33E1)),
                            rightChevronIcon: const Icon(
                                Icons.chevron_right, color: Color(0xFF5F33E1)),
                          ),
                          daysOfWeekVisible: true,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDate, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (selectedDay.isBefore(_today)) {
                              setState(() {
                                _selectedDate = selectedDay;
                                _loadHabitsForSelectedDate();
                              });
                              // Закрываем диалог сразу после выбора даты
                              Navigator.pop(context);
                            }
                          },
                          enabledDayPredicate: (day) {
                            return day.isBefore(
                                _today); // Блокируем завтрашние дни
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
