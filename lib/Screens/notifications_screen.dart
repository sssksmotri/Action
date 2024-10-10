import 'package:flutter/material.dart';
import 'main.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:action_notes/Service/HabitReminderService.dart';

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
      habits = fetchedHabits; // Сохраняем привычки в состоянии
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
            _buildNotificationToggle('All notifications', allNotificationsEnabled, (value) {
              setState(() {
                allNotificationsEnabled = value;
              });
            }),
            const SizedBox(height: 16),

            // Отображение уведомлений для привычек
            if (allNotificationsEnabled) ...[
              ...habits.map((habit) {
                return _buildHabitNotificationSection(habit);
              }).toList(),
            ],
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

  Widget _buildNotificationToggle(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitNotificationSection(Map<String, dynamic> habit) {
    bool isHabitNotificationEnabled = habit['archived'] == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                habit['name'],
                style: const TextStyle(fontSize: 16),
              ),
              Switch(
                value: isHabitNotificationEnabled,
                onChanged: (bool value) async {
                  setState(() {
                    habits = habits.map((h) {
                      if (h['id'] == habit['id']) {
                        return {
                          ...h,
                          'archived': value ? 0 : 1, // 0 — включено, 1 — выключено
                        };
                      }
                      return h;
                    }).toList();
                  });

                  // Обновляем привычку в базе данных
                  await DatabaseHelper.instance.updateHabit({
                    'id': habit['id'],
                    'archived': value ? 0 : 1,
                  });

                  // Если тумблер включен, показываем выбор дней и времени
                  if (value) {
                    _showNotificationDaysMenu(habit); // Показать выбор времени и дней
                  }
                },
                activeColor: Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Карточка с уведомлением и кнопки добавления/удаления
          _buildNotificationTimesSelection(habit['id'], habit),
        ],
      ),
    );
  }

  Widget _buildNotificationTimesSelection(int habitId, Map<String, dynamic> habit) {
    List<Map<String, dynamic>> notificationsForHabit =
    notificationTimes.where((entry) => entry['habitId'] == habitId).toList();

    return Column(
      children: notificationsForHabit.map((timeEntry) {
        bool isLastNotification = notificationsForHabit.length == 1; // Проверка на последнее напоминание

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _selectTime(context, notificationTimes.indexOf(timeEntry)),
                    child: Text(timeEntry['time'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.purple),
                        onPressed: () => _addNewNotification(habit),
                      ),
                      if (!isLastNotification) // Показываем кнопку удаления, только если это не последнее напоминание
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeNotification(timeEntry),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDaysOfWeekCheckboxes(timeEntry['days'], habitId, timeEntry['id']),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    try {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        String formattedTime = '${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}';
        int? habitId = notificationTimes[index]['habitId'] as int?;
        int? reminderId = notificationTimes[index]['id'] as int?;

        if (habitId == null || reminderId == null) {
          print('Ошибка: habitId или reminderId равно null.');
          return;
        }

        // Обновляем время в локальном состоянии
        setState(() {
          notificationTimes[index]['time'] = formattedTime;
        });

        // Обновляем напоминание в базе данных
        await DatabaseHelper.instance.updateReminder({
          'id': reminderId,
          'time': formattedTime,
        });

        // Получаем имя привычки для уведомления
        String habitName = (await DatabaseHelper.instance.queryHabitById(habitId))['name'] ?? 'Неизвестная привычка';

        // Отменяем старые напоминания
        await HabitReminderService().cancelAllReminders(habitId);

        // Запланируем новое напоминание с обновленным временем и днями
        List<bool> days = notificationTimes[index]['days'];
        await HabitReminderService().scheduleReminder(
          habitId,
          formattedTime,
          habitName,
          {
            'monday': days[0] ? 1 : 0,
            'tuesday': days[1] ? 1 : 0,
            'wednesday': days[2] ? 1 : 0,
            'thursday': days[3] ? 1 : 0,
            'friday': days[4] ? 1 : 0,
            'saturday': days[5] ? 1 : 0,
            'sunday': days[6] ? 1 : 0,
          },
        );

        print('Напоминание обновлено: время $formattedTime, id привычки: $habitId');
      }
    } catch (e, stackTrace) {
      print('Ошибка в методе _selectTime: $e');
      print(stackTrace);
    }
  }

  Widget _buildDaysOfWeekCheckboxes(List<bool> days, int habitId, int reminderId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        return Column(
          children: [
            Checkbox(
              value: days[index],
              onChanged: (bool? value) async {
                setState(() {
                  days[index] = value ?? false;
                });

                // Обновляем данные в базе при изменении чекбокса
                await DatabaseHelper.instance.updateReminder({
                  'id': reminderId,
                  _getDayColumnName(index): value! ? 1 : 0,
                });

                // Отмена существующих напоминаний
                await HabitReminderService().cancelAllReminders(habitId);

                // Планирование новых уведомлений с обновленными данными
                await HabitReminderService().scheduleReminder(
                  habitId,
                  notificationTimes.firstWhere((reminder) => reminder['id'] == reminderId)['time'],
                  (await DatabaseHelper.instance.queryHabitById(habitId))['name'],
                  {
                    'monday': days[0] ? 1 : 0,
                    'tuesday': days[1] ? 1 : 0,
                    'wednesday': days[2] ? 1 : 0,
                    'thursday': days[3] ? 1 : 0,
                    'friday': days[4] ? 1 : 0,
                    'saturday': days[5] ? 1 : 0,
                    'sunday': days[6] ? 1 : 0,
                  },
                );
              },
            ),
            Text(['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][index]),
          ],
        );
      }),
    );
  }

// Вспомогательная функция для получения названия колонки дня
  String _getDayColumnName(int index) {
    switch (index) {
      case 0:
        return 'sunday';
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      default:
        return '';
    }
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
      _showExistingNotifications(existingNotifications);
    } else {
      _addNewNotification(habit);
    }
  }

  void _showExistingNotifications(List<Map<String, dynamic>> existingNotifications) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Existing Notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: existingNotifications.map((entry) {
              return Text('Notification at ${entry['time']}');
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _addNewNotification(Map<String, dynamic> habit) async {
    String defaultTime = '20:35';
    List<bool> defaultDays = List.generate(7, (index) => true);

    // Получаем reminderId от метода addNewReminder
    int reminderId = await habitReminderService.addNewReminder(habit['id'], defaultTime, defaultDays);

    // Добавляем новое уведомление в список
    setState(() {
      notificationTimes.add({
        'habitId': habit['id'],
        'time': defaultTime,
        'days': defaultDays,
        'id': reminderId, // Используем полученный reminderId
      });
    });
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

}
