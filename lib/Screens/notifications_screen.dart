import 'package:flutter/material.dart';
import 'main.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:action_notes/Service/HabitReminderService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedIndex = 4;
  bool allNotificationsEnabled = false; // Статус всех уведомлений
  List<Map<String, dynamic>> habits = []; // Список привычек
  List<Map<String, dynamic>> notificationTimes = []; // Времена уведомлений для каждой привычки
  final HabitReminderService habitReminderService = HabitReminderService();

  @override
  void initState() {
    super.initState();
    _fetchHabits();
    _loadNotifications();
  }

  Future<void> _fetchHabits() async {
    final dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> fetchedHabits = await dbHelper.queryActiveHabits();

    setState(() {
      habits = fetchedHabits;
    });

    // Загружаем уведомления после того, как привычки загружены
    await _loadNotifications();

    // Проверяем состояние основного тумблера
    _updateAllNotificationsState();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Image.asset(
            'assets/images/ar_back.png',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(

        child: Column(
          children: [
            // Тумблер для всех уведомлений
            _buildMainNotificationToggle(),
            const SizedBox(height: 8),

            // Отображение уведомлений для привычек
            if (allNotificationsEnabled) ...[
              ...habits.map((habit) {
                return _buildHabitNotificationSection(habit);
              }).toList(),
            ],
          ],
        ),
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 30, right: 16, left: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEE9FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'assets/images/Home.png'),
            _buildNavItem(1, 'assets/images/Edit.png'),
            _buildNavItem(2, 'assets/images/Plus.png'),
            _buildNavItem(3, 'assets/images/Calendar.png'),
            _buildNavItem(4, 'assets/images/Setting.png', isSelected: true),
          ],
        ),
      ),
    );
  }

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

  Widget _buildNavItem(int index, String assetPath, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F33E1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 28,
            height: 28,
            color: isSelected ? Colors.white : const Color(0xFF5F33E1),
          ),
        ),
      ),
    );
  }

  Widget _buildMainNotificationToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "All notifications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Switch(
              value: allNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  allNotificationsEnabled = value;


                  habits = habits.map((habit) {
                    return {
                      ...habit,
                      'notifications_enabled': value ? 1 : 0, // Обновляем состояние привычек
                    };
                  }).toList();
                  print('значение $value');

                  _updateAllHabitsNotificationState(value);

                  if (value) {
                    for (var habit in habits) {
                      HabitReminderService().initializeReminders();
                    }
                  } else {
                    for (var habit in habits) {
                      HabitReminderService().cancelAllReminders(habit['id']);
                    }
                  }
                });
              },
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF5F33E1),
              inactiveTrackColor: const Color(0xFFEEE9FF),
              inactiveThumbColor: const Color(0xFF5F33E1),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHabitNotificationSection(Map<String, dynamic> habit) {
    bool isHabitNotificationEnabled = habit['notifications_enabled'] == 1;

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    habit['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: isHabitNotificationEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      habit['notifications_enabled'] = value ? 1 : 0;
                      _updateHabitInDatabase(habit);
                      // Обновляем состояние основного тумблера
                      if (value && !allNotificationsEnabled) {
                        allNotificationsEnabled = true;

                      } else if (!value && habits.every((h) => h['notifications_enabled'] == 0)) {
                        allNotificationsEnabled = false;

                      }
                    });

                    if (value) {
                      await habitReminderService.initializeReminders();
                    } else {
                      await habitReminderService.cancelAllReminders(habit['id']);
                    }
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF5F33E1),
                  inactiveTrackColor: const Color(0xFFEEE9FF),
                  inactiveThumbColor: const Color(0xFF5F33E1),
                ),
              ],
            ),
            if (isHabitNotificationEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    _buildNotificationSettings(habit),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildNotificationSettings(Map<String, dynamic> habit) {
    // Получаем диапазон дат привычки
    DateTime startDate = DateTime.parse(habit['start_date']);
    DateTime endDate = habit['end_date'] != null
        ? DateTime.parse(habit['end_date'])
        : startDate.add(Duration(days: 6)); // Если endDate не задан, используем 6 дней после startDate

    // Генерация напоминаний с учетом диапазона дней
    List<Map<String, dynamic>> habitReminders = notificationTimes
        .where((reminder) => reminder['habitId'] == habit['id'])
        .toList();

    // Если нет напоминаний, создаем одно с временем по умолчанию и днями недели в пределах диапазона
    if (habitReminders.isEmpty) {
      // Инициализируем дни, которые входят в диапазон, как выбранные
      List<bool> defaultDays = List.generate(7, (dayIndex) {
        // Используем DateTime.now().weekday (1=понедельник, 7=воскресенье) для точного определения индекса дня недели
        int currentDay = (startDate.add(Duration(days: dayIndex)).weekday - 1) % 7;
        bool isSelected = currentDay >= startDate.weekday - 1 && currentDay <= endDate.weekday - 1;
        print("Day index: $dayIndex, isSelected: $isSelected"); // Логируем индексы и значения
        return isSelected; // Выбираем только дни в диапазоне
      });

      print("Default days for new reminder: $defaultDays"); // Логируем результат

      habitReminders = [
        {
          'time': '08:00',
          'days': defaultDays, // Все дни, попадающие в диапазон, выбраны
          'habitId': habit['id'], // Привязываем уведомление к привычке
        }
      ];

      setState(() {
        notificationTimes.addAll(habitReminders);
      });
    }

    return Column(
      children: List.generate(habitReminders.length, (index) {
        return Column(
          children: [
            _buildTimePicker(habitReminders[index], habit, index),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }



  Widget _buildTimePicker(Map<String, dynamic> reminder, Map<String, dynamic> habit, int index) {
    String selectedTime = reminder['time'];
    List<String> timeParts = selectedTime.split(":");
    int selectedHour = int.parse(timeParts[0]);
    int selectedMinute = int.parse(timeParts[1]);

    TextEditingController hourController = TextEditingController(text: selectedHour.toString().padLeft(2, '0'));
    TextEditingController minuteController = TextEditingController(text: selectedMinute.toString().padLeft(2, '0'));

    int habitId = habit['id'];
    List<Map<String, dynamic>> notificationsForHabit = notificationTimes
        .where((entry) => entry['habitId'] == habitId)
        .toList();

    bool isLastNotification = notificationsForHabit.length == 1;

    return Column(
      children: [
        Row(
          children: [
            // Поле для ввода часов
            Container(
              width: 60,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(0xFFF8F9F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                controller: hourController, // Используем контроллер
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: InputBorder.none),
                style: TextStyle(fontSize: 20, color: Colors.black),
                onFieldSubmitted: (String value) {
                  _updateHour(reminder, habit, hourController, minuteController);
                },
              ),
            ),
            Text(' : ', style: TextStyle(fontSize: 24, color: Colors.black)),
            // Поле для ввода минут
            Container(
              width: 60,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(0xFFF8F9F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                controller: minuteController, // Используем контроллер
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: InputBorder.none),
                style: TextStyle(fontSize: 20, color: Colors.black),
                onFieldSubmitted: (String value) {
                  _updateHour(reminder, habit, hourController, minuteController);
                },
              ),
            ),
            SizedBox(width: 12),
            // Кнопка "+" для добавления уведомления
            GestureDetector(
              onTap: () async {
                await _addNewReminder(habit);
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(0xFFEEE9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add, color: Color(0xFF5F33E1), size: 24),
              ),
            ),
            Spacer(),
            // Условие для отображения крестика
            if (!isLastNotification)
              GestureDetector(
                onTap: () async {
                  _removeNotification(reminder);
                  setState(() {
                    notificationTimes.removeWhere((entry) => entry['id'] == reminder['id']);
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE7E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close, color: Color(0xFFFF3B30), size: 24),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDaysOfWeekCheckboxes(reminder, habit),
      ],
    );
  }

// Обновление времени при завершении ввода
  void _updateHour(Map<String, dynamic> reminder, Map<String, dynamic> habit, TextEditingController hourController, TextEditingController minuteController) {
    setState(() {
      int? hour = int.tryParse(hourController.text);
      int? minute = int.tryParse(minuteController.text);

      if (hour != null && hour >= 0 && hour < 24 && minute != null && minute >= 0 && minute < 60) {
        // Обновляем копию списка
        notificationTimes = notificationTimes.map((entry) {
          if (entry['id'] == reminder['id']) {
            return {...entry, 'time': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'};
          }
          return entry;
        }).toList();
        _updateReminderInDatabase(reminder['id'], newTime: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      } else {
        print("Invalid time input.");
      }
    });
  }


  Widget _buildDaysOfWeekCheckboxes(Map<String, dynamic> reminder, Map<String, dynamic> habit) {
    // Получаем startDate и endDate из habit
    DateTime startDate = DateTime.parse(habit['start_date']);
    DateTime endDate = habit['end_date'] != null
        ? DateTime.parse(habit['end_date'])
        : startDate.add(Duration(days: 6)); // Если endDate не задан, используем 6 дней после startDate

    // Убедимся, что 'days' инициализирован как список булевых значений
    List<bool> selectedDays = reminder['days'] != null
        ? List<bool>.from(reminder['days'])
        : [false, false, false, false, false, false, false];

    List<String> days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    // Устанавливаем начальные и конечные даты для диапазона
    _resetInvalidDays(startDate, endDate, selectedDays, reminder);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (dayIndex) {
        // Проверяем, можно ли выбрать день в соответствии с диапазоном
        bool isWithinRange = _isWithinDateRange(startDate, endDate, dayIndex);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                days[dayIndex],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF212121),  // Цвет текста всегда активен
                ),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: isWithinRange // Если день вне диапазона, не разрешаем его выбирать
                  ? () {
                setState(() {
                  int selectedCount = selectedDays.where((day) => day).length;

                  // Проверяем, остается ли хотя бы один выбранный день
                  if (selectedDays[dayIndex] && selectedCount == 1) {
                    // Показываем ошибку, если пытаются снять последний день
                    _showError('Должен быть выбран хотя бы один день');
                  } else {
                    // Мгновенное обновление состояния чекбокса
                    selectedDays[dayIndex] = !selectedDays[dayIndex];
                    reminder['days'] = selectedDays;

                    // Обновляем напоминание в базе данных асинхронно
                    _updateReminderInDatabase(reminder['id'], selectedDays: selectedDays);
                  }
                });
              }
                  : null, // Если день не входит в диапазон, отключаем нажатие
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selectedDays[dayIndex] ? const Color(0xFF5F33E1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isWithinRange // Изменяем цвет в зависимости от доступности выбора
                        ? (selectedDays[dayIndex] ? const Color(0xFF5F33E1) : Colors.grey)
                        : Colors.red, // Если день вне диапазона, подсвечиваем красным
                    width: 1,
                  ),
                ),
                child: selectedDays[dayIndex]
                    ? const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.white,
                )
                    : null,
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }



  void _resetInvalidDays(DateTime startDate, DateTime endDate, List<bool> selectedDays, Map<String, dynamic> reminder) {
    final int totalDaysRange = endDate.difference(startDate).inDays;

    // Если диапазон больше недели, все дни можно выбрать, не сбрасываем
    if (totalDaysRange >= 7) {
      return;
    }

    final int startDayIndex = startDate.weekday % 7;
    final int endDayIndex = endDate.weekday % 7;

    // Сбрасываем дни вне диапазона (если диапазон меньше недели)
    for (int i = 0; i < 7; i++) {
      if (i < startDayIndex || i > endDayIndex) {
        selectedDays[i] = false; // Сбрасываем дни вне диапазона
      }
    }

    // Обновляем состояние родительского виджета
    setState(() {
      reminder['days'] = selectedDays; // Сохраняем изменения
    });
  }

// Проверяем, находится ли выбранный индекс дня недели в пределах диапазона
  bool _isWithinDateRange(DateTime start, DateTime end, int selectedIndex) {
    final int totalDaysRange = end.difference(start).inDays;

    // Если диапазон больше недели, возвращаем true для всех дней
    if (totalDaysRange >= 7) {
      return true;
    }

    // Преобразуем дни недели в индексы от 0 (Воскресенье) до 6 (Суббота)
    final int startDayIndex = start.weekday % 7;
    final int endDayIndex = end.weekday % 7;

    // Возвращаем true, если день находится в диапазоне, иначе false
    return selectedIndex >= startDayIndex && selectedIndex <= endDayIndex;
  }

  Future<void> _loadNotifications() async {
    try {
      List<Map<String, dynamic>> reminders = await DatabaseHelper.instance.queryAllReminders();

      setState(() {
        notificationTimes = reminders.map((reminder) {
          return {
            'habitId': reminder['habit_id'],
            'time': reminder['time'],
            'days': [
              reminder['monday'] == 1,
              reminder['tuesday'] == 1,
              reminder['wednesday'] == 1,
              reminder['thursday'] == 1,
              reminder['friday'] == 1,
              reminder['saturday'] == 1,
              reminder['sunday'] == 1,
            ],
            'id': reminder['id'],
          };
        }).toList();
      });

      print('Уведомления загружены: $notificationTimes');
    } catch (e) {
      print('Ошибка при загрузке уведомлений: $e');
    }
  }





  void _removeNotification(Map<String, dynamic> timeEntry) async {
    setState(() {
      // Удаляем уведомление из списка по уникальному идентификатору
      notificationTimes.removeWhere((entry) => entry['id'] == timeEntry['id']);
    });

    // Проверяем, есть ли ID у напоминания
    int? reminderId = timeEntry['id']; // Получаем идентификатор напоминания
    if (reminderId == null) {
      print('Ошибка: reminderId равно null.');
      return;
    }

    // Удаляем напоминание через сервис HabitReminderService
    await habitReminderService.deleteReminder(reminderId);

    // Проверяем, остались ли другие уведомления для этой привычки
    int habitId = timeEntry['habitId']; // Получаем id привычки
    bool hasOtherNotifications = notificationTimes.any((entry) => entry['habitId'] == habitId);

    // Если других уведомлений нет, отключаем тумблер для этой привычки
    if (!hasOtherNotifications) {
      setState(() {
        habits = habits.map((habit) {
          if (habit['id'] == habitId) {
            return {
              ...habit,
              'archived': 0, // Отключаем уведомления для этой привычки
            };
          }
          return habit;
        }).toList();
      });
    }
  }

  void _updateAllNotificationsState() {
    setState(() {
      allNotificationsEnabled = habits.any((habit) => habit['active'] == 0); // Set to true if any habit is active
    });
  }
  Future<void> _updateAllHabitsNotificationState(bool enabled) async {
    final dbHelper = DatabaseHelper.instance;
    for (var habit in habits) {
      await dbHelper.updateHabitNotificationState(habit['id'], enabled ? 0 : 1);
    }
  }

  Future<void> _addNewReminder(Map<String, dynamic> habit) async {
    String defaultTime = '08:00'; // Время по умолчанию

    // Получаем диапазон дат привычки
    DateTime startDate = DateTime.parse(habit['start_date']);
    DateTime endDate = habit['end_date'] != null
        ? DateTime.parse(habit['end_date'])
        : startDate.add(Duration(days: 6)); // Если endDate не задан, используем 6 дней после startDate

    // Инициализируем дни по умолчанию: только те, которые входят в диапазон дат привычки, будут включены
    List<bool> defaultDays = List.generate(7, (dayIndex) {
      return _isWithinDateRange(startDate, endDate, dayIndex);
    });

    print("Default days for new reminder: $defaultDays"); // Логируем результат

    // Добавляем новое напоминание в БД
    await habitReminderService.addNewReminder(habit['id'], defaultTime, defaultDays);

    // Перезагружаем уведомления
    await _loadNotifications();
  }

  Future<void> _updateHabitInDatabase(Map<String, dynamic> habit) async {
    await DatabaseHelper.instance.updateHabit(habit);
    print('Привычка обновлена: ${habit['name']}');
  }

  // Метод обновления напоминания
  Future<void> _updateReminderInDatabase(int reminderId, {String? newTime, List<bool>? selectedDays}) async {
    // Создаем карту для обновления данных
    Map<String, dynamic> updateData = {};

    // Получаем текущее напоминание для перепланирования
    Map<String, dynamic>? existingReminder = await DatabaseHelper.instance.queryReminderById(reminderId);

    if (existingReminder == null) {
      print('Напоминание с ID $reminderId не найдено.');
      return;
    }

    int habitId = existingReminder['habit_id'];

    // Если передано новое время, добавляем его в данные для обновления
    if (newTime != null) {
      updateData['time'] = newTime;
      print('Новое время: $newTime');
    }

    // Если переданы выбранные дни или они уже были установлены ранее, добавляем их
    if (selectedDays != null) {
      Map<String, dynamic> daysOfWeek = {
        'monday': selectedDays[0] ? 1 : 0,
        'tuesday': selectedDays[1] ? 1 : 0,
        'wednesday': selectedDays[2] ? 1 : 0,
        'thursday': selectedDays[3] ? 1 : 0,
        'friday': selectedDays[4] ? 1 : 0,
        'saturday': selectedDays[5] ? 1 : 0,
        'sunday': selectedDays[6] ? 1 : 0,
      };
      updateData.addAll(daysOfWeek);
      print('Обновленные дни недели: $daysOfWeek');
    } else {
      // Если selectedDays не переданы, берем существующие дни из базы данных
      Map<String, dynamic> daysOfWeek = {
        'monday': existingReminder['monday'],
        'tuesday': existingReminder['tuesday'],
        'wednesday': existingReminder['wednesday'],
        'thursday': existingReminder['thursday'],
        'friday': existingReminder['friday'],
        'saturday': existingReminder['saturday'],
        'sunday': existingReminder['sunday'],
      };
      updateData.addAll(daysOfWeek);
      print('Используем существующие дни недели: $daysOfWeek');
    }

    // Если есть данные для обновления, обновляем в базе
    if (updateData.isNotEmpty) {
      await DatabaseHelper.instance.updateReminder(reminderId, updateData);
      print('Напоминание обновлено с ID: $reminderId с данными: $updateData');

      HabitReminderService habitReminderService = HabitReminderService();

      // Отменяем старые напоминания
      print('Отменяю старые уведомления для привычки с ID $habitId');
      await habitReminderService.cancelAllReminders(habitId);
      print('Все старые уведомления отменены для привычки с ID $habitId');

      // Перепланируем новое уведомление
      await habitReminderService.scheduleReminder(
          habitId,
          newTime ?? existingReminder['time'], // Используем новое или существующее время
          (await DatabaseHelper.instance.queryHabitById(habitId))['name'], // Получаем имя привычки
          updateData.isNotEmpty ? updateData : existingReminder // Используем обновленные или существующие данные
      );
    } else {
      print('Нет данных для обновления.');
    }
  }










}
