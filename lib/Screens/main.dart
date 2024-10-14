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
  List<Map<String, dynamic>> _filteredHabits = [];
  String? _selectedFilter;
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadHabits();
    _loadSelectedFilter().then((value) {
      setState(() {
        _selectedFilter = value; // Устанавливаем загруженный фильтр
        _filterHabits(); // Фильтруем привычки при инициализации
      });
    });
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


  // Метод для переключения состояния активности
  void _toggleCheck(bool isChecked, Function(bool) callback) {
    setState(() {
      callback(!isChecked);
    });
  }


  // Метод для подтверждения удаления
  void _showDeleteDialog(BuildContext context, String taskTitle,
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
                      onDelete(); // Вызов метода удаления
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
  @override
// Добавляем переменную состояния для контроля над видимостью текста
  bool _isTextVisible = true;

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
                    '${_filteredHabits.length}', // Динамическое отображение количества отфильтрованных привычек
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
                    );
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
                itemCount: _filteredHabits.length, // Изменено на отфильтрованные привычки
                itemBuilder: (context, index) {
                  final habit = _filteredHabits[index]; // Используем отфильтрованный список
                  int habitType = int.parse(habit['type'].toString());
                  if (habitType == 0) {
                    return _buildHabitItem(
                      habit['name'],
                      (habit['archived'] ?? 0) == 1,
                          () {
                        _toggleCheck((habit['archived'] ?? 0) == 1, (value) {
                          setState(() {
                            habit['archived'] = value ? 1 : 0;
                          });
                        });
                      },
                      key: ValueKey(habit['id']), // Убедитесь, что habit['id'] уникален
                    );
                  }
                  if (habitType == 1) {
                    return _buildCountItem(
                      habit['name'],
                      habit['quantity'] ?? 0, // Текущее количество
                      10, // Максимальное количество (например, 10, если это фиксированное значение)
                          () {
                        setState(() {
                          // Увеличиваем количество, если оно меньше максимального
                          if ((habit['quantity'] ?? 0) < 10) { // Заменить 10 на нужное максимальное количество
                            habit['quantity'] = (habit['quantity'] ?? 0) + 1; // Увеличиваем количество
                          }
                        });
                      },
                          () {
                        if ((habit['quantity'] ?? 0) > 0) {
                          setState(() {
                            habit['quantity'] = (habit['quantity'] ?? 0) - 1; // Уменьшаем количество
                          });
                        }
                      },
                          () {
                        _showDeleteDialog(context, habit['name'], () {});
                      },
                      key: ValueKey(habit['id']),
                    );
                  }
                  else if (habitType == 2) {
                    return _buildCountItem(
                      habit['name'],
                      habit['quantity'] ?? 0,
                      int.tryParse(habit['volume_specified'] ?? '1') ?? 1, // Обработка объема нажатия
                          () {
                        setState(() {
                          habit['quantity'] = (habit['quantity'] ?? 0) + 1; // Увеличиваем количество
                        });
                      },
                          () {
                        if ((habit['quantity'] ?? 0) > 0) {
                          setState(() {
                            habit['quantity'] = (habit['quantity'] ?? 0) - 1; // Уменьшаем количество
                          });
                        }
                      },
                          () {
                        _showDeleteDialog(context, habit['name'], () {});
                      },
                      key: ValueKey(habit['id']), // Убедитесь, что habit['id'] уникален
                    );
                  } else {
                    return Container();
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
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> habits = await dbHelper.queryAllHabits();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? habitsJson = prefs.getString('habits');
    String? selectedFilter = await _loadSelectedFilter();

    setState(() {
      if (habitsJson != null) {
        List<Map<String, dynamic>> loadedHabits = List<Map<String, dynamic>>.from(json.decode(habitsJson));
        _habits = loadedHabits.isNotEmpty ? loadedHabits : habits; // Здесь нужно использовать loadedHabits
      } else {
        _habits = habits; // Загрузите привычки из базы данных, если в SharedPreferences ничего нет
      }


      if (selectedFilter != null && selectedFilter.isNotEmpty) {
        _selectedFilter = selectedFilter;
        _filteredHabits = List.from(_habits);
        _filterHabits();
      }
    });
  }


  Future<void> _saveHabits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('habits', json.encode(_habits));
  }


  void _onReorder(int oldIndex, int newIndex) {
    // Проверяем, действительны ли индексы
    if (oldIndex < 0 || oldIndex >= _filteredHabits.length || newIndex < 0 || newIndex >= _filteredHabits.length) {
      print('Invalid indices: oldIndex = $oldIndex, newIndex = $newIndex');
      return;
    }

    print('Before reorder: $_filteredHabits');
    print('Reordering from index $oldIndex to index $newIndex');

    setState(() {
      // Если перемещение сверху вниз, смещаем индекс нового положения
      if (oldIndex < newIndex) {
        newIndex--; // Уменьшаем индекс, если перемещение вниз
      }

      // Удаляем и вставляем привычку в новую позицию
      final habit = _filteredHabits.removeAt(oldIndex);
      _filteredHabits.insert(newIndex, habit);

      // Обновляем основное состояние
      _habits = List.from(_filteredHabits); // Обновляем _habits

      print('After reorder: $_filteredHabits');
      // Сохраняем изменения в базе данных или SharedPreferences
      _saveHabits(); // Убедитесь, что вы сохраняете обновленный список привычек
    });
  }



  void _showPopupMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 50, 0),
      items: [
        PopupMenuItem<String>(
          value: 'Completed first',
          child: Text('Completed first', style: TextStyle(color: _selectedFilter == 'Completed first' ? Color(0xFF5F33E1) : Colors.black)),
        ),
        PopupMenuItem<String>(
          value: 'Not completed at first',
          child: Text('Not completed at first', style: TextStyle(color: _selectedFilter == 'Not completed at first' ? Color(0xFF5F33E1) : Colors.black)),
        ),
        PopupMenuItem<String>(
          value: 'Custom',
          child: Text('Custom', style: TextStyle(color: _selectedFilter == 'Custom' ? Color(0xFF5F33E1) : Colors.black)),
        ),
        PopupMenuItem<String>(
          value: 'Reset',
          child: Text('Reset Filters', style: TextStyle(color: Colors.red)),
        ),
      ],
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          if (value == 'Reset') {
            _selectedFilter = null; // Сброс фильтра
            _filteredHabits = List.from(_habits); // Показываем все привычки
            print('Фильтр сброшен');
          } else {
            _selectedFilter = value; // Применяем новый фильтр
            _filterHabits(); // Важно: фильтрация привычек после выбора
            print('Выбран фильтр: $_selectedFilter');
          }
        });

        _saveSelectedFilter(value); // Сохраняем выбранный фильтр
      }
    });
  }

  Future<void> _saveSelectedFilter(String filter) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFilter', filter); // Сохраняем выбранный фильтр
  }

  Future<String?> _loadSelectedFilter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedFilter'); // Загружаем выбранный фильтр
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
  Widget _buildHabitItem(String title, bool checked, VoidCallback onTap, {Key? key}) {
    return _buildCard(
      key: key,
      child: ListTile(
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка галочки, если задача выполнена
            if (checked)
              Padding(
                padding: const EdgeInsets.only(right: 8.0), // Отступ справа от галочки
                child: const Icon(Icons.check, color: Colors.green, size: 28), // Увеличиваем размер иконки
              ),
            // Кнопка с троеточием
            Transform.rotate(
              angle: -90 * (3.141592653589793238 / 180),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Delete') {
                    _showDeleteDialog(context, title, () {});
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
        onTap: onTap,
      ),
    );
  }

// Функция для создания карточки с количеством выполнений
  Widget _buildCountItem(String title, int count, int maxCount,
      VoidCallback onIncrement, VoidCallback onDecrement, VoidCallback onDelete, {Key? key}) {
    bool isCompleted = count >= maxCount; // Измените на >=, чтобы учитывать завершенные привычки
    return _buildCard(
      key: key,
      child: GestureDetector(
        onTap: () => onIncrement(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(title),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count/$maxCount', // Показываем текущее количество и максимум
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
                          _showDeleteDialog(context, title, () {});
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
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
              child: TextButton(
                onPressed: count > 0 ? onDecrement : null, // Деактивируем кнопку, если count равно 0
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
    );
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

  void _filterHabits() {
    setState(() {
      if (_selectedFilter == null || _selectedFilter!.isEmpty) {
        _filteredHabits = List.from(_habits);
        print('Фильтр не установлен, показываем все привычки: $_filteredHabits');
      } else if (_selectedFilter == 'Completed first') {
        _filteredHabits = _habits.where((habit) => habit['type'] == 1).toList();
        print('Применен фильтр: Completed first, привычки: $_filteredHabits');
      } else if (_selectedFilter == 'Not completed at first') {
        _filteredHabits = _habits.where((habit) => habit['type'] == 2).toList();
        print('Применен фильтр: Not completed at first, привычки: $_filteredHabits');
      } else if (_selectedFilter == 'Custom') {
        _filteredHabits = _habits.where((habit) => habit['type'] == 3).toList();
        print('Применен фильтр: Custom, привычки: $_filteredHabits');
      }
    });
  }




  Widget _buildBottomDateSelector() {
    // Форматируем дату в виде "July, 15" с учетом локализации
    String formattedDate = DateFormat('MMMM, d', Localizations.localeOf(context).toString()).format(_selectedDate);

    return GestureDetector(
      onTap: () {
        _showCalendarDialog();
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
              onPressed: () {
                if (_selectedDate.isBefore(_today)) {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                }
              },
            ),

            // Кнопка "назад", если дата не сегодняшняя
            if (_selectedDate != _today) // Появление кнопки "назад" только если дата не сегодня
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
                      _selectedDate = _today; // Возвращаем сегодняшнюю дату при нажатии
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
