import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'Screens/add.dart';
import 'Screens/settings_screen.dart';
import 'Screens/notes.dart';
import 'Screens/archive.dart';
import 'dart:ui';
import 'Screens/stat.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:action_notes/Service/NotificationService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:action_notes/Service/HabitReminderService.dart';
import 'package:action_notes/Screens/edit.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:action_notes/Widgets/loggable_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _currentSessionId;
  bool _sessionInitialized = false; // Добавляем флаг для контроля однократной инициализации

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Инициализируем сессию только один раз
    if (!_sessionInitialized) {
      _sessionInitialized = true;
      _startSession();
    }
  }

  Future<void> _startSession() async {
    // Получаем язык и устройство
    String language = context.locale.languageCode;
    String deviceInfo = await _getDeviceInfo();

    // Запуск сессии и запись sessionId
    int sessionId = await DatabaseHelper.instance.logSessionStart(language, deviceInfo);
    setState(() {
      _currentSessionId = sessionId;
    });
  }
  Future<void> _endSession() async {
    if (_currentSessionId != null) {
      await DatabaseHelper.instance.logSessionEnd(_currentSessionId!);
    }
  }

  @override
  void dispose() {
    _endSession();
    super.dispose();
  }

  Future<String> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        return 'Android: ${androidInfo.model}, ${androidInfo.brand}, Android version: ${androidInfo.version.release}';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        return 'iOS: ${iosInfo.name}, ${iosInfo.systemVersion}, Model: ${iosInfo.utsname.machine}';
      }
    } catch (e) {
      return 'Failed to get device info: $e';
    }
    return 'Unknown platform';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Localization Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      navigatorObservers: [routeObserver],
      home: _currentSessionId != null ? HomePage(sessionId: _currentSessionId!) : const Center(child: CircularProgressIndicator()),
    );
  }
}

class HomePage extends StatefulWidget {
  final int sessionId;

  const HomePage({super.key, required this.sessionId});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  bool _isTextVisible = false;
  List<Map<String, dynamic>> _habits = [];
  String? _selectedFilter;
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();
  final HabitReminderService habitReminderService = HabitReminderService();
  bool _showDragHint = true;
  bool _isDialogShownBefore = false;
  String deviceInfo = "Unknown";
  int? _currentSessionId;
  DateTime? _startTime;
  String _currentSection = 'HomePage';
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadHabitsForSelectedDate();
    habitReminderService.initializeReminders();// Фильтруем привычки при инициализации
    DatabaseHelper db = DatabaseHelper.instance;
    db.archiveExpiredHabits();
    _loadTextVisibility();
    _startTime = DateTime.now();
    _queryAppUsageLogs();
    _currentSessionId = widget.sessionId;
  }

  @override
  void dispose() {
    _logSectionTime();
    DatabaseHelper.instance.logSessionEnd(widget.sessionId);
    super.dispose();
  }



  Future<void> _queryAppUsageLogs() async {
    final logs = await DatabaseHelper.instance.queryAllAppUsageLogs();
    for (var log in logs) {
      print(log); // Выводим каждую запись лога в консоль
    }
  }

  Future<String> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        return 'Android: ${androidInfo.model}, ${androidInfo.brand}, Android version: ${androidInfo.version.release}';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        return 'iOS: ${iosInfo.name}, ${iosInfo.systemVersion}, Model: ${iosInfo.utsname.machine}';
      }
    } catch (e) {
      return 'Failed to get device info: $e';
    }
    return 'Unknown platform';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getDeviceInfo(); // Получаем информацию о устройстве
  }



  void _logSectionTime() async {
    if (_startTime != null) {
      final timeSpent = DateTime.now().difference(_startTime!).inMinutes;
      await DatabaseHelper.instance.logSectionTime(widget.sessionId, _currentSection, timeSpent);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Определим имя экрана вручную
    String screenName;
    Widget page;

    switch (index) {
      case 0:
        screenName = 'HomePage';
        page = HomePage(sessionId: widget.sessionId);
        break;
      case 1:
        screenName = 'NotesPage';
        page = NotesPage(sessionId: widget.sessionId);
        break;
      case 2:
        screenName = 'AddActionPage';
        page = AddActionPage(sessionId: widget.sessionId);
        break;
      case 3:
        screenName = 'StatsPage';
        page = StatsPage(sessionId: widget.sessionId);
        break;
      case 4:
        screenName = 'SettingsPage';
        page = SettingsPage(sessionId: widget.sessionId);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoggableScreen(
          screenName: screenName, // Передаем четко определенное имя экрана
          child: page,
          currentSessionId: widget.sessionId,
        ),
      ),
    );
  }



  // Метод для подтверждения удаления
  void _showDeleteDialog(BuildContext context, String taskTitle, int habitId,
      Function() onDelete) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Эффект размытия
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Эффект размытия
              child: Container(
                color: Colors.black.withOpacity(0), // Прозрачный контейнер для сохранения размытия
              ),
            ),
            // Основное содержимое диалогового окна
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              insetPadding: const EdgeInsets.all(10),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "are_you_sure".tr(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,

                      ),
                      children: [
                        TextSpan(
                          text: taskTitle,
                          style: const TextStyle(
                            color: Color(0xFF5F33E1), // Фиолетовый цвет для названия задачи
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
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          backgroundColor: const Color(0xFFEEE9FF), // Легкий фиолетовый фон
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Уменьшение горизонтальных отступов

                        ),
                        child: Text(
                          "no_leave_it".tr(),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Уменьшение горизонтальных отступов
                        ),
                        child: Text(
                          "yes_delete".tr(),
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
                  tr('actions'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFFEEE9FF),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_habits.length}',
                    style: TextStyle(
                      color: Color(0xFF5F33E1),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                    if (_currentSessionId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoggableScreen(
                            screenName: 'ArchivePage',
                            child: ArchivePage(sessionId: _currentSessionId!),
                            currentSessionId: _currentSessionId!,
                          ),
                        ),
                      ).then((result) {
                        // Check if the result is not null and then reload the habits
                        if (result != null && result == true) {
                          setState(() {
                            _loadHabitsForSelectedDate(); // Call a method to reload the habits
                          });
                        }
                      });
                    } else {
                      // Action when _currentSessionId is null
                      print("Error: session ID is null");
                      // Show a message to the user or perform another action
                    }
                  },
                ),
          ],
            ),
          ],
        ),
        backgroundColor: Color(0xFFF8F9F9),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Карточки привычек
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(), // Отключаем собственный скролл
                    onReorder: _onReorder, // Используем метод _onReorder
                    itemCount: _habits.length, // Количество привычек
                    itemBuilder: (context, index) {
                      final habit = _habits[index]; // Привычка
                      int habitType = int.parse(habit['type'].toString());

                      if (habitType == 0) {
                        bool isCompleted = habit['currentProgress'] == 1;

                        return _buildHabitItem(
                          habit['name'], // Название привычки
                          isCompleted, // Завершена ли привычка
                              () async {
                            if (!isSameDay(_selectedDate, _today)) {
                              return;
                            }

                            // Переключаем состояние завершения привычки
                            int newProgress = isCompleted ? 0 : 1; // 0 - не завершено, 1 - завершено

                            await DatabaseHelper.instance.updateHabitProgress(
                              habit['id'],
                              newProgress.toDouble(), // Обновляем прогресс до нового значения
                              DateTime.now().toIso8601String().split('T')[0],
                            );

                            if (newProgress == 1) {
                              // Если привычка завершена, обновляем статус в БД
                              await DatabaseHelper.instance.updateHabitStatus(
                                habit['id'],
                                'completed',
                                DateTime.now().toIso8601String().split('T')[0],
                              );
                            }
                            if (newProgress == 0) {
                              // Если привычка завершена, обновляем статус в БД
                              await DatabaseHelper.instance.updateHabitStatus(
                                habit['id'],
                                'not_completed',
                                DateTime.now().toIso8601String().split('T')[0],
                              );
                            }

                            setState(() {
                              _habits = List.from(_habits);
                              _habits[index] = Map<String, dynamic>.from(_habits[index])
                                ..['currentProgress'] = newProgress; // Обновляем текущий прогресс
                            });
                          },
                          habit['id'],
                          key: ValueKey(habit['id']),
                        );
                      }

                      // Для привычек с количеством (habitType == 1)
                      else if (habitType == 1) {
                        int currentProgress = (habit['currentProgress'] ?? 0).toInt();
                        int maxProgress = (habit['quantity'] ?? 10).toInt();

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

                              if (newProgress == maxProgress) {
                                // Если достигнут максимальный прогресс, обновляем статус
                                await DatabaseHelper.instance.updateHabitStatus(
                                  habit['id'],
                                  'completed',
                                  DateTime.now().toIso8601String().split('T')[0],
                                );
                              }

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
                              await DatabaseHelper.instance.updateHabitStatus(
                                habit['id'],
                                'not_completed',
                                DateTime.now().toIso8601String().split('T')[0],
                              );

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

                      else if (habitType == 2) {
                        double currentProgress = habit['currentProgress'] ?? 0.0;
                        double maxProgress = habit['volume_specified'] ?? 1.0;

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

                              if (newProgress >= maxProgress) {
                                // Обновляем статус, если достигнут максимальный прогресс
                                await DatabaseHelper.instance.updateHabitStatus(
                                  habit['id'],
                                  'completed',
                                  DateTime.now().toIso8601String().split('T')[0],
                                );
                              }

                              setState(() {
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
                              await DatabaseHelper.instance.updateHabitStatus(
                                habit['id'],
                                'not_completed',
                                DateTime.now().toIso8601String().split('T')[0],
                              );
                              await DatabaseHelper.instance.updateHabitProgress(
                                habit['id'],
                                newProgress.toDouble(),
                                DateTime.now().toIso8601String().split('T')[0],
                              );

                              setState(() {
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
                            _showDeleteDialog(context, habit['name'], habit['id'], () {});
                          },
                          habit['id'],
                          key: ValueKey(habit['id']),
                        );
                      }
                      else {
                        return Container(); // Для других типов
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Текст под карточками
                  if (_isTextVisible)

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30), // Отступы от краев экрана
                      child: Card(
                        color: const Color(0xFFEEE9FF),
                        elevation: 0, // Убираем тени
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18), // Углы карточки
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Отступы внутри карточки слева и справа
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  "Hold down the habit bar to move it around",
                                  style: TextStyle(
                                    color: const Color(0xFF5F33E1),
                                    fontWeight: FontWeight.w400, // Обычный текст
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isTextVisible = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0x995F33E1), // Прозрачный фон с 40% видимости
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Image.asset(
                                    'assets/images/krest.png', // Путь к вашему изображению
                                    width: 9,  // Размер изображения (как у иконки)
                                    height: 9,
                                    color: const Color(0xFF5F33E1),  // Цвет картинки (если нужно перекрасить)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )

                ],
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




  Future<void> _loadTextVisibility() async {
    // Получаем список привычек
    await _loadHabitsForSelectedDate(); // Загрузите привычки перед проверкой видимости текста

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isPreviouslyVisible = prefs.getBool('isTextVisible') ?? true;

    setState(() {
      // Устанавливаем видимость текста в зависимости от наличия привычек и состояния в SharedPreferences
      if (_habits.isNotEmpty && isPreviouslyVisible) {
        _isTextVisible = true; // Показываем текст, если есть привычки и состояние сохранено как true
      } else {
        _isTextVisible = false; // Скрываем текст, если привычек нет или состояние не true
      }
    });
  }
  Future<void> _saveTextVisibility() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTextVisible', _isTextVisible);
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
      _isTextVisible = false;
    });

    // Сохраняем обновленные позиции в базе данных
    await _updateHabitPositionsInDb();

    await _saveTextVisibility();
  }


  Future<void> _updateHabitPositionsInDb() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    for (int i = 0; i < _habits.length; i++) {
      Map<String, dynamic> habit = _habits[i];
      // Обновляем позицию в базе данных
      await dbHelper.updateHabitPosition(habit['id'], i);
      _isTextVisible = false;
      await _saveTextVisibility();
    }
  }



  void _showPopupMenu(BuildContext context) {
    showMenu(
      constraints: BoxConstraints.tightFor(
        width: context.locale.languageCode == 'en' ? 180 : 200, // Используем locale от Easy Localization
      ),
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 50, 0), // Позиция попапа
      items: [
        PopupMenuItem<String>(
          value: 'Completed first',
          height: 25, // Фиксированная высота для уменьшения отступов
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8), // Уменьшенные отступы
            child: Text(
              tr('completed_first'),
              style: TextStyle(
                color: _selectedFilter == 'Completed first' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight:FontWeight.bold,
                fontSize: 14, // Уменьшенный размер шрифта
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Not completed at first',
          height: 25, // Фиксированная высота для уменьшения отступов
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8), // Уменьшенные отступы
            child: Text(
              tr('not_completed_first'),
              style: TextStyle(
                color: _selectedFilter == 'Not completed at first' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight:FontWeight.bold,
                fontSize: 14, // Уменьшенный размер шрифта
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Custom',
          height: 25, // Фиксированная высота для уменьшения отступов
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8), // Уменьшенные отступы
            child: Text(
              tr('custom'),
              style: TextStyle(
                color: _selectedFilter == 'Custom' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight:FontWeight.bold,
                fontSize: 14, // Уменьшенный размер шрифта
              ),
            ),
          ),
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
    print('Фильтр перед применением: $_selectedFilter');
    print('Данные перед фильтрацией: $_habits');

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
        return !aCompleted && bCompleted ? -1 : (aCompleted && !bCompleted ? 1 : 0);
      });
    } else if (_selectedFilter == 'Custom') {
      _loadHabitsForSelectedDate();
    }

    print('Данные после фильтрации: $_habits');
  }





  Widget _buildNavItem(int index, String assetPath, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 50,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF5F33E1) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 24,
            height: 24,
            color: isSelected ? Colors.white : Color(0xFF5F33E1),
          ),
        ),
      ),
    );
  }

  // Функция для создания карточки привычки
  Widget _buildHabitItem(
      String title, bool isCompleted, VoidCallback onTap, int habitId, {Key? key}) {

    bool isChecked = isCompleted;

    return _buildCard(
      key: key,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Левая колонка с названием
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, top: 8.0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Галочка или крестик справа
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: isChecked
                    ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Тень иконки для эффекта "жирного" отображения
                    const Icon(
                      Icons.check,
                      size: 40,
                      color: Color(0xFF0AC70A),
                    ),
                    // Основная иконка
                    const Icon(
                      Icons.check,
                      color: Color(0xFF0AC70A),
                      size: 35,
                    ),
                  ],
                )
                    : (DateTime.now().hour == 23 && DateTime.now().minute > 55
                    ? const Icon(Icons.close, color: Colors.red, size: 28)
                    : const SizedBox.shrink()),
              ),
              // Кнопка с тремя точками по центру справа
              PopupMenuButton<String>(
                icon: Image.asset('assets/images/menu.png', width: 24, height: 24),
                onSelected: (value) {
                  if (value == 'Delete') {
                    _showDeleteDialog(context, title, habitId, () {});
                  } else if (value == 'Archive') {
                    _archiveHabit(habitId);
                  } else if (value == 'Edit') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoggableScreen(
                          screenName: 'EditPage',
                          child: EditPage(
                            habitId: habitId,
                            ActionName: title,
                            sessionId: _currentSessionId!,
                          ),
                          currentSessionId: _currentSessionId!,
                        ),
                      ),
                    );
                  }
                },
                constraints: BoxConstraints.tightFor(
                  width: context.locale.languageCode == 'en' ? 85 : 135,
                ),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'Archive',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('archive'.tr(), style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Edit',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('edit'.tr(), style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Delete',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('delete'.tr(), style: const TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                    ),
                  ];
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                offset: const Offset(0, 40),
              ),
            ],
          ),
        ),
      ),
    );
  }


// И аналогичные изменения для _buildCountItem
  Widget _buildCountItem(
      String title, int count, int maxCount,
      VoidCallback onIncrement, VoidCallback onDecrement, VoidCallback onDelete,
      int habitId, {Key? key}) {

    bool isCompleted = count >= maxCount;

    return _buildCard(
      key: key,
      child: GestureDetector(
        onTap: () => onIncrement(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Левая колонка с названием и кнопкой
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, top: 8.0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Кнопка "Cancel" под названием
                      TextButton(
                        onPressed: count > 0 ? onDecrement : null,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF5F33E1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size(80, 30),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Галочка справа, если задача выполнена, иначе показываем прогресс
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: isCompleted
                    ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Тень иконки для эффекта "жирного" отображения
                    const Icon(
                      Icons.check,
                      size: 40,
                      color: Color(0xFF0AC70A),
                    ),
                    // Основная иконка
                    const Icon(
                      Icons.check,
                      color: Color(0xFF0AC70A),
                      size: 35,
                    ),
                  ],
                )
                    : buildDiagonalText(count, maxCount, isCompleted),
              ),
              // Кнопка с тремя точками по центру справа
              PopupMenuButton<String>(
                icon: Image.asset('assets/images/menu.png', width: 24, height: 24),
                onSelected: (value) {
                  if (value == 'Delete') {
                    _showDeleteDialog(context, title, habitId, onDelete);
                  } else if (value == 'Archive') {
                    _archiveHabit(habitId);
                  } else if (value == 'Edit') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoggableScreen(
                          screenName: 'EditPage',
                          child: EditPage(
                            habitId: habitId,
                            ActionName: title,
                            sessionId: _currentSessionId!,
                          ),
                          currentSessionId: _currentSessionId!,
                        ),
                      ),
                    );
                  }
                },
                constraints: BoxConstraints.tightFor(
                  width: context.locale.languageCode == 'en' ? 85 : 140,
                ),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'Archive',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('archive'.tr(), style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Edit',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('edit'.tr(), style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Delete',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('delete'.tr(), style: const TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                    ),
                  ];
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                offset: const Offset(0, 40),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget buildDiagonalText(int count, int maxCount, bool isCompleted) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Линия
        Transform.rotate(
          angle: -0.785398, // угол в радианах (приблизительно -45 градусов)
          child: Container(
            width: 40, // длина линии
            height: 2, // толщина линии
            color: isCompleted ? Colors.green : Colors.red,
          ),
        ),
        // Числа сверху и снизу линии
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 24.0), // смещение влево
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24.0), // смещение вправо
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$maxCount',
                  style: TextStyle(
                    fontSize: 18,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildDiagonalTextdouble(double count, double maxCount, bool isCompleted) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Линия
        Transform.rotate(
          angle: -0.785398, // угол в радианах (приблизительно -45 градусов)
          child: Container(
            width: 40, // длина линии
            height: 2, // толщина линии
            color: isCompleted ? Colors.green : Colors.red,
          ),
        ),
        // Числа сверху и снизу линии
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 36.0), // смещение влево
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36.0), // смещение вправо
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$maxCount',
                  style: TextStyle(
                    fontSize: 18,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPressCountHabit(
      Map<String, dynamic> habit,
      VoidCallback onIncrement,
      VoidCallback onDecrement,
      VoidCallback onEdit,
      VoidCallback onDelete,
      int habitId, {Key? key}) {

    String title = habit['name'];
    double currentProgress = habit['currentProgress'] ?? 0.0;
    double maxProgress = habit['volume_specified'] ?? 1.0;
    bool isCompleted = currentProgress >= maxProgress;

    return _buildCard(
      key: key,
      child: GestureDetector(
        onTap: onIncrement,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Левая колонка с названием и кнопкой
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, top: 8.0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Кнопка "Cancel" под названием
                      TextButton(
                        onPressed: currentProgress > 0 ? onDecrement : null,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF5F33E1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size(80, 30),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Отображение галочки, если цель выполнена, либо прогресса
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: isCompleted
                    ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Тень иконки для эффекта "жирного" отображения
                    const Icon(
                      Icons.check,
                      size: 40,
                      color: Color(0xFF0AC70A),
                    ),
                    // Основная иконка
                    const Icon(
                      Icons.check,
                      color: Color(0xFF0AC70A),
                      size: 35,
                    ),
                  ],
                )
                    : buildDiagonalTextdouble(currentProgress, maxProgress, isCompleted),
              ),
              // Кнопка с тремя точками по центру справа
              PopupMenuButton<String>(
                icon: Image.asset('assets/images/menu.png', width: 24, height: 24),
                onSelected: (value) {
                  if (value == 'Archive') {
                    _archiveHabit(habitId);
                  } else if (value == 'Delete') {
                    _showDeleteDialog(context, title, habitId, onDelete);
                  } else if (value == 'Edit') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoggableScreen(
                          screenName: 'EditPage',
                          child: EditPage(
                            habitId: habitId,
                            ActionName: title,
                            sessionId: _currentSessionId!,
                          ),
                          currentSessionId: _currentSessionId!,
                        ),
                      ),
                    );
                  }
                },
                constraints: BoxConstraints.tightFor(
                  width: context.locale.languageCode == 'en' ? 85 : 140,
                ),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'Archive',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('archive'.tr(), style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Edit',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('edit'.tr(), style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Delete',
                      height: 25,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('delete'.tr(), style: const TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                    ),
                  ];
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                offset: const Offset(0, 40),
              ),
            ],
          ),
        ),
      ),
    );
  }




  void _archiveHabit(int habitId) async {
    DatabaseHelper db = DatabaseHelper.instance;

    // Fetch the current habit from the database to preserve other fields
    var currentHabit = await db.queryHabitById(habitId);
    if (currentHabit == null) {
      print('Ошибка: привычка с ID $habitId не найдена.');
      return;
    }

    // Merge the current habit with the updated values
    Map<String, dynamic> updatedHabit = {
      ...currentHabit,
      'archived': 1,
    };

    await db.updateHabit(updatedHabit); // Archive the habit with all fields intact
    habitReminderService.cancelAllReminders(habitId);

    setState(() {
      _habits = List.from(_habits)..removeWhere((habit) => habit['id'] == habitId);
    });
  }




//Карточки тени
  Widget _buildCard({Key? key, required Widget child}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),

      ),
      child: child,
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

  String capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }


  Widget _buildBottomDateSelector() {
    // Форматируем дату в виде "July, 15" с учетом локализации
    String formattedMonth = capitalize(
        DateFormat('MMMM', Localizations.localeOf(context).toString()).format(_selectedDate)
    );

    String formattedDay = DateFormat('d', Localizations.localeOf(context).toString()).format(_selectedDate);      // Пример: "23"

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
              icon: Image.asset(
                'assets/images/arr_left.png', // путь к вашей картинке
                color: const Color(0xFF5F33E1), // если нужно применить цвет
                width: 18, // установите ширину
                height: 18,
              ),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  _loadHabitsForSelectedDate();  // Загружаем привычки за новый выбранный день
                });
              },
            ),


            // Дата
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$formattedMonth, ", // Месяц
                    style: const TextStyle(
                      color: Colors.black, // Черный цвет для месяца
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: "$formattedDay", // Число с пробелом перед ним
                    style: const TextStyle(
                      color: Color(0xFF5F33E1), // Цвет для числа
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),


            // Правая стрелка
            IconButton(
              icon: Image.asset(
                'assets/images/arr_right.png', // путь к вашей картинке для стрелки вправо
                color: isSameDay(_selectedDate, _today)
                    ? const Color(0x4D5F33E1)  // Полупрозрачный цвет, если выбран сегодняшний день
                    : const Color(0xFF5F33E1), // Обычный цвет
                width: 18, // Устанавливаем ширину
                height: 18, // Устанавливаем высоту (необязательно)
              ),
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
      barrierColor: Colors.black.withOpacity(0.1),
      barrierDismissible: true, // Позволяем закрывать диалог при нажатии вне области
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white, // цвет фона календаря
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _selectedDate,
                    locale: Localizations.localeOf(context).toString(),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: const Color(0xFF5F33E1),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5F33E1),
                          width: 1,
                        ),
                      ),
                      todayTextStyle: TextStyle(
                        color: Colors.black,
                      ),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 18, // Размер шрифта для месяца
                        fontWeight: FontWeight.bold, // Жирный шрифт
                        color: Colors.black, // Цвет текста для названия месяца
                      ),
                      titleTextFormatter: (date, locale) {
                        String formattedMonth = DateFormat.MMMM(locale).format(date);

                        // Преобразуем первую букву в верхний регистр только для русского языка
                        if (locale == 'ru') {
                          formattedMonth = formattedMonth[0].toUpperCase() + formattedMonth.substring(1);
                        }

                        return formattedMonth;
                      },
                      leftChevronIcon: Padding(
                        padding: const EdgeInsets.only(left: 42.0),
                        child: Image.asset(
                          'assets/images/arr_left.png',
                          width: 20,
                          height: 20,
                          color: const Color(0xFF5F33E1),
                        ),
                      ),
                      rightChevronIcon: Padding(
                        padding: const EdgeInsets.only(right: 42.0),
                        child: Image.asset(
                          'assets/images/arr_right.png',
                          width: 20,
                          height: 20,
                          color: const Color(0xFF5F33E1),
                        ),
                      ),
                    ),
                    daysOfWeekVisible: true,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: const TextStyle(
                        fontSize: 13, // Размер шрифта для дней недели
                        fontWeight: FontWeight.normal, // Не жирный шрифт
                        color: Colors.grey, // Цвет текста для будних дней
                      ),
                      weekendStyle: const TextStyle(
                        fontSize: 13, // Размер шрифта для выходных
                        fontWeight: FontWeight.normal, // Не жирный шрифт
                        color: Colors.grey,
                      ),
                      dowTextFormatter: (date, locale) =>
                          DateFormat.E(locale).format(date).toUpperCase(),
                    ),
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDate, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (selectedDay.isBefore(_today)) {
                        setState(() {
                          _selectedDate = selectedDay;
                          _loadHabitsForSelectedDate();
                        });
                        Navigator.pop(context);
                      }
                    },
                    enabledDayPredicate: (day) {
                      return day.isBefore(_today);
                    },
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }


}
