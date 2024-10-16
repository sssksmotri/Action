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
  bool allNotificationsEnabled = true; // Статус всех уведомлений
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
    List<Map<String, dynamic>> fetchedHabits = await dbHelper.queryAllHabits();

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
          color: Colors.white, // Белый фон для контейнера
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Смещение тени
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Все уведомления",
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
                      'active': value ? 0 : 1,
                    };
                  }).toList();

                  _updateAllHabitsNotificationState(value);

                  if (value) {
                    for (var habit in habits) {
                      _showNotificationDaysMenu(habit);
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
              activeTrackColor: const Color(0xFF5F33E1), // Цвет фона при включении
              inactiveTrackColor: const Color(0xFFEEE9FF), // Цвет фона при выключении
              inactiveThumbColor: const Color(0xFF5F33E1), // Цвет кнопки при выключении
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
                    });

                    if (value) {
                      _showNotificationDaysMenu(habit);
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
    List<Map<String, dynamic>> habitReminders = notificationTimes
        .where((reminder) => reminder['habitId'] == habit['id'])
        .toList();

    if (habitReminders.isEmpty) {
      habitReminders = [{'time': '08:00', 'days': List<bool>.filled(7, false)}];
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

    // Получаем id привычки из объекта habit
    int habitId = habit['id'];

    // Фильтруем уведомления для конкретной привычки
    List<Map<String, dynamic>> notificationsForHabit = notificationTimes
        .where((entry) => entry['habitId'] == habitId)
        .toList();

    // Проверка на последнее уведомление
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
                textAlign: TextAlign.center,
                initialValue: selectedHour.toString().padLeft(2, '0'),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: InputBorder.none),
                style: TextStyle(fontSize: 20, color: Colors.black),
                onChanged: (String value) {
                  setState(() {
                    int? hour = int.tryParse(value);
                    if (hour != null && hour >= 0 && hour < 24) {
                      reminder['time'] =
                      '${hour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                      _updateReminderInDatabase(reminder['id'], newTime: reminder['time']);

                    } else {
                      print("Invalid hour input.");
                    }
                  });
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
                textAlign: TextAlign.center,
                initialValue: selectedMinute.toString().padLeft(2, '0'),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: InputBorder.none),
                style: TextStyle(fontSize: 20, color: Colors.black),
                onChanged: (String value) {
                  setState(() {
                    int? minute = int.tryParse(value);
                    if (minute != null && minute >= 0 && minute < 60) {
                      reminder['time'] =
                      '${selectedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                      _updateReminderInDatabase(reminder['id'], newTime: reminder['time']);

                    } else {
                      print("Invalid minute input.");
                    }
                  });
                },
              ),
            ),
            SizedBox(width: 12), // Отступ между полем времени и кнопкой "+"
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
                    notificationTimes.removeAt(index);
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
        const SizedBox(height: 12), // Увеличение отступа между временем и днями недели
        _buildDaysOfWeekCheckboxes(reminder, habit),
      ],
    );
  }


  Widget _buildDaysOfWeekCheckboxes(Map<String, dynamic> reminder, Map<String, dynamic> habit) {
    // Получаем startDate и endDate из habit
    DateTime startDate = DateTime.parse(habit['start_date']);
    DateTime endDate = habit['end_date'] != null
        ? DateTime.parse(habit['end_date'])
        : startDate.add(Duration(days: 6)); // Предположим, если endDate не задан, то это 6 дней после startDate

    // Убедимся, что 'days' инициализирован как список булевых значений
    List<bool> selectedDays = reminder['days'] != null
        ? List<bool>.from(reminder['days'])
        : [false, false, false, false, false, false, false];

    List<String> days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    // Сбрасываем недопустимые дни
    _resetInvalidDays(startDate, endDate, selectedDays, reminder);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (dayIndex) {
        // Проверяем, входит ли день в диапазон привычки
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
                  selectedDays[dayIndex] = !selectedDays[dayIndex];  // Меняем состояние выбранного дня
                  _updateReminderInDatabase(reminder['id'], selectedDays: selectedDays);
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

  void _resetInvalidDays(DateTime startDate, DateTime endDate, List<bool> selectedDays, Map<String, dynamic> reminder) {
    final int startDayIndex = startDate.weekday % 7;
    final int endDayIndex = endDate.weekday % 7;

    // Сбрасываем дни вне диапазона
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




  bool _isWithinDateRange(DateTime start, DateTime end, int selectedIndex) {
    final int difference = end.difference(start).inDays;

    // Если период больше недели, все дни доступны для выбора
    if (difference >= 7) {
      return true;
    }

    // Преобразуем дни недели в индексы от 0 (Воскресенье) до 6 (Суббота)
    final int startDayIndex = start.weekday % 7;
    final int endDayIndex = end.weekday % 7;

    // Возвращаем true, если день находится в диапазоне
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

  void _showNotificationDaysMenu(Map<String, dynamic> habit) {
    final existingNotifications = notificationTimes.where((entry) => entry['habitId'] == habit['id']).toList();

    if (existingNotifications.isNotEmpty) {
    } else {
      _addNewReminder(habit);
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
    List<bool> defaultDays = List<bool>.filled(7, false); // Все дни по умолчанию выключены

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
