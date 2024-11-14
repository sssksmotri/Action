import 'dart:math';

import 'package:flutter/material.dart';
import '../main.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:action_notes/Service/HabitReminderService.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stat.dart';
import 'add.dart';
import 'notes.dart';
import 'settings_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'package:action_notes/Widgets/loggable_screen.dart';
import 'package:flutter/cupertino.dart';
class NotificationsPage extends StatefulWidget {
  final int sessionId;
  const NotificationsPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedIndex = 4;
  bool allNotificationsEnabled = false; // Статус всех уведомлений
  List<Map<String, dynamic>> habits = []; // Список привычек
  List<Map<String, dynamic>> notificationTimes = []; // Времена уведомлений для каждой привычки
  final HabitReminderService habitReminderService = HabitReminderService();
  FocusNode hourFocusNode = FocusNode();
  FocusNode minuteFocusNode = FocusNode();
  int? _currentSessionId;
  String _currentScreenName = "NotificationsPage";
  @override
  void dispose() {
    hourFocusNode.dispose();
    minuteFocusNode.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    _loadNotifications();
    _fetchHabits().then((_) {
      // Загружаем состояние основного тумблера
      _loadToggleState('allNotificationsEnabled').then((value) {
        setState(() {
          allNotificationsEnabled = value;
        });
        print('Main toggle (All Notifications) state: $allNotificationsEnabled');
      });

      // Загружаем состояние каждого тумблера привычек
      for (var habit in habits) {
        _loadToggleState('habit_${habit['id']}_notifications_enabled').then((value) {
          // Вместо изменения объекта habit, создаем новый объект привычки
          setState(() {
            // Обновляем список привычек с новым значением для конкретной привычки
            habits = habits.map((h) {
              if (h['id'] == habit['id']) {
                return {
                  ...h,
                  'notifications_enabled': value ? 1 : 0, // Создаем копию объекта с обновленным полем
                };
              }
              return h;
            }).toList();
          });
          print('Habit "${habit['name']}" (ID: ${habit['id']}) notifications state: ${value ? 1 : 0}');
        });
      }
    });
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


  void _onItemTapped(int index) async {
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
    await DatabaseHelper.instance.logAction(widget.sessionId, "Переход с экрана: $_currentScreenName на экран: $screenName");
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F9),
        leading: IconButton(
          icon: Image.asset(
            'assets/images/ar_back.png',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            DatabaseHelper.instance.logAction(
                _currentSessionId!,
                "Пользователь нажал кнопку назад и вернулся в SetingPage из: $_currentScreenName"
            );
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
        title: Row(
          children: [
            Transform.translate(
              offset: Offset(-16, 0), // Смещение текста влево
              child: Text(
                'notifications'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
      backgroundColor: const Color(0xFFF8F9F9),
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

  Future<void> _checkNotificationPermission() async {
    var status = await Permission.notification.status;

    if (status.isDenied) {
      // Если статус "Denied", выводим диалог для запроса разрешения
      await _requestNotificationPermission();
    } else if (status.isPermanentlyDenied) {
      // Если статус "PermanentlyDenied", показываем диалог с предложением открыть настройки
      await _showSettingsDialog();
    }
  }

  Future<void> _requestNotificationPermission() async {
    var status = await Permission.notification.request();

    if (status.isGranted) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDialogShown', true);
      setState(() {
        allNotificationsEnabled=true;
      });
      await _saveToggleState('allNotificationsEnabled', true);
      await DatabaseHelper.instance.logAction(
        widget.sessionId,
        "Пользователь дал разрешение на уведомления на экране: $_currentScreenName",
      );
    }
  }



// Диалог для перенаправления в настройки
  Future<void> _showSettingsDialog() async {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Эффект размытия фона
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0)),
            ),
            // Основное содержимое диалогового окна
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              insetPadding: const EdgeInsets.all(16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined, // Иконка уведомлений
                    size: 50,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "notifications_denied_permanently".tr(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "please_enable_notifications_in_settings".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Кнопка "Нет, спасибо"
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await DatabaseHelper.instance.logAction(
                            widget.sessionId,
                            "Пользователь отказался открыть настройки для уведомлений на экране: $_currentScreenName",
                          );
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEEE9FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          "no_thanks".tr(),
                          style: TextStyle(
                            color: const Color(0xFF5F33E1),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Кнопка "Открыть настройки"
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await DatabaseHelper.instance.logAction(
                            widget.sessionId,
                            "Пользователь открыл настройки для уведомлений на экране: $_currentScreenName",
                          );
                          Navigator.of(context).pop();
                          await openAppSettings();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF5F33E1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          "open_settings".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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



  Widget _buildMainNotificationToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "All_Notifications".tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0), // Прямые отступы вокруг переключателя
              child: Container(
                height: 30, // Высота контейнера
                width: 50, // Ширина контейнера
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.white, // Цвет ободка
                    width: 2, // Ширина ободка
                  ),
                  borderRadius: BorderRadius.circular(15), // Скругление углов
                ),
                child: GestureDetector(
                  onTap: () async {
                    if (!allNotificationsEnabled) {
                      var status = await Permission.notification.status;
                      if (status.isGranted) {
                        await DatabaseHelper.instance.logAction(
                          _currentSessionId!,
                          "Пользователь включил все уведомления на экране: $_currentScreenName",
                        );
                        setState(() {
                          allNotificationsEnabled = true;
                          _updateAllHabitsNotificationState(allNotificationsEnabled);
                        });
                        await _saveToggleState('allNotificationsEnabled', true); // Сохранение состояния
                      } else {
                        allNotificationsEnabled = false;
                        _checkNotificationPermission();
                      }
                    } else {
                      await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь отключил все уведомления на экране: $_currentScreenName",
                      );
                      setState(() {
                        allNotificationsEnabled = false;
                        _updateAllHabitsNotificationState(allNotificationsEnabled);
                      });
                      await _saveToggleState('allNotificationsEnabled', false); // Сохранение состояния
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: allNotificationsEnabled ? const Color(0xFF5F33E1) : const Color(0xFFEEE9FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      Positioned(
                        left: allNotificationsEnabled ? null : 2, // Отступ слева
                        right: allNotificationsEnabled ? 2 : null, // Отступ справа
                        top: 2, // Отступ сверху
                        child: Container(
                          width: 22, // Ширина шарика
                          height: 22,
                          decoration: BoxDecoration(
                            color: allNotificationsEnabled ? const Color(0xFFFFFFFF) : const Color(0xFF5F33E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                Padding(
                  padding: const EdgeInsets.all(4.0), // Прямые отступы вокруг переключателя
                  child: Container(
                    height: 30, // Высота контейнера
                    width: 50, // Ширина контейнера
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.white, // Цвет ободка
                        width: 2, // Ширина ободка
                      ),
                      borderRadius: BorderRadius.circular(15), // Скругление углов
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        bool newValue = !isHabitNotificationEnabled; // Переключаем значение
                        setState(() {
                          habit['notifications_enabled'] = newValue ? 1 : 0;
                          _updateHabitInDatabase(habit);

                          // Обновляем состояние основного тумблера
                          if (newValue && !allNotificationsEnabled) {
                            allNotificationsEnabled = true;
                          } else if (!newValue && habits.every((h) => h['notifications_enabled'] == 0)) {
                            allNotificationsEnabled = false;
                          }
                        });

                        if (newValue) {
                          await DatabaseHelper.instance.logAction(
                            _currentSessionId!,
                            "Пользователь включил уведомления для привычки '${habit['name']}' на экране: $_currentScreenName",
                          );
                          await habitReminderService.initializeReminders();
                        } else {
                          await DatabaseHelper.instance.logAction(
                            _currentSessionId!,
                            "Пользователь отключил уведомления для привычки '${habit['name']}' на экране: $_currentScreenName",
                          );
                          await habitReminderService.cancelAllReminders(habit['id']);
                        }
                        _saveToggleState('habit_${habit['id']}_notifications_enabled', newValue);
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isHabitNotificationEnabled ? const Color(0xFF5F33E1) : const Color(0xFFEEE9FF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          Positioned(
                            left: isHabitNotificationEnabled ? null : 2, // Отступ слева
                            right: isHabitNotificationEnabled ? 2 : null, // Отступ справа
                            top: 2, // Отступ сверху
                            child: Container(
                              width: 22, // Ширина шарика
                              height: 22,
                              decoration: BoxDecoration(
                                color: isHabitNotificationEnabled ? const Color(0xFFFFFFFF) : const Color(0xFF5F33E1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
      _addNewReminder(habit);
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
            // Квадрат для часов
            GestureDetector(
              onTap: () {
                DatabaseHelper.instance.logAction(
                  _currentSessionId!,
                  "Пользователь выбрал, выбрать часы уведомление для привычки '${habit['name']}' на экране: $_currentScreenName",
                );
                _showTimePicker(reminder,habit);
              }, // Показываем таймпикер
              child: Container(
                width: 70,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hourController.text, // Показываем час
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            ),
            SizedBox(width: 4),
            Text(' : ', style: TextStyle(fontSize: 24, color: Colors.black)),
            SizedBox(width: 4),
            // Квадрат для минут
            GestureDetector(
              onTap: () {
                DatabaseHelper.instance.logAction(
                  _currentSessionId!,
                  "Пользователь выбрал, выбрать минуты уведомление для привычки '${habit['name']}' на экране: $_currentScreenName",
                );
                _showTimePicker(reminder,habit);
                }, // Показываем таймпикер
              child: Container(
                width: 70,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9F9),
                  borderRadius: BorderRadius.circular(8),

                ),
                child: Text(
                  minuteController.text, // Показываем минуту
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Кнопка "+" для добавления уведомления
            GestureDetector(
              onTap: () async {
                await DatabaseHelper.instance.logAction(
                  _currentSessionId!,
                  "Пользователь добавил новое уведомление для привычки '${habit['name']}' на экране: $_currentScreenName",
                );
                await _addNewReminder(habit);
              },
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: Color(0xFFEEE9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add, color: Color(0xFF5F33E1), size: 20),
              ),
            ),
            Spacer(),
            // Условие для отображения крестика
            if (!isLastNotification)
              GestureDetector(
                onTap: () async {
                  await DatabaseHelper.instance.logAction(
                    _currentSessionId!,
                    "Пользователь удалил уведомление для привычки '${habit['name']}' на экране: $_currentScreenName",
                  );
                  _removeNotification(reminder);
                  setState(() {
                    notificationTimes.removeWhere((entry) => entry['id'] == reminder['id']);
                  });
                },
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE7E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close, color: Color(0xFFFF3B30), size: 20),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDaysOfWeekCheckboxes(reminder, habit),
      ],
    );
  }

  void _showTimePicker(Map<String, dynamic> reminder,Map<String, dynamic> habit) {
    String selectedTime = reminder['time'];
    List<String> timeParts = selectedTime.split(":");
    int selectedHour = int.parse(timeParts[0]);
    int selectedMinute = int.parse(timeParts[1]);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,  // Transparent background for blur effect
      barrierColor: Colors.black.withOpacity(0.5), // Dimming the background
      isScrollControlled: true, // Allows controlling the height of the modal
      builder: (BuildContext builder) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),  // Rounded top corners
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,  // White background for the modal
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),  // Rounded top corners
            ),
            height: MediaQuery.of(context).size.height / 3,  // Modal height
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(0, 0, 0, selectedHour, selectedMinute),
              use24hFormat: true,  // Forces 24-hour format (no AM/PM)
              onDateTimeChanged: (newTime) {
                setState(() {
                   DatabaseHelper.instance.logAction(
                    _currentSessionId!,
                    "Пользователь выбрал время уведомление для привычки '${habit['name']}' на экране: $_currentScreenName",
                  );
                  // Update the time in reminder
                  reminder['time'] = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
                  _updateHour(reminder, habit, newTime.hour, newTime.minute);
                });
              },
            ),
          ),
        );
      },
    );
  }
// Обновление времени при завершении ввода
  void _updateHour(Map<String, dynamic> reminder, Map<String, dynamic> habit, int hour, int minute) {
    setState(() {
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        // Обновляем копию списка уведомлений
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
                     DatabaseHelper.instance.logAction(
                      _currentSessionId!,
                      "Пользователь ${selectedDays[dayIndex] ? 'выбрал' : 'снял выбор'} день '${days[dayIndex]}' для привычки '${habit['name']}' на экране: $_currentScreenName.",
                    );
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

  Future<void> _saveToggleState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> _loadToggleState(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }


  void _resetInvalidDays(DateTime startDate, DateTime endDate, List<bool> selectedDays, Map<String, dynamic> reminder) {
    final int totalDaysRange = endDate.difference(startDate).inDays;

    // Если диапазон больше недели, все дни можно выбрать, не сбрасываем
    if (totalDaysRange >= 7) {
      return;
    }

    // Преобразуем дни недели в индексы от 0 (Воскресенье) до 6 (Суббота)
    final int startDayIndex = startDate.weekday % 7;
    final int endDayIndex = endDate.weekday % 7;

    // Сбрасываем дни вне диапазона (если диапазон меньше недели)
    for (int i = 0; i < 7; i++) {
      if (startDayIndex <= endDayIndex) {
        // Когда диапазон не "переходит" через воскресенье
        if (i < startDayIndex || i > endDayIndex) {
          selectedDays[i] = false; // Сбрасываем дни вне диапазона
        }
      } else {
        // Когда диапазон "переходит" через воскресенье
        if (i < startDayIndex && i > endDayIndex) {
          selectedDays[i] = false; // Сбрасываем дни вне диапазона
        }
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

    // Печатаем диапазон дат и общее количество дней
    print('Start date: $start, End date: $end, Total days range: $totalDaysRange');

    // Если диапазон больше недели, возвращаем true для всех дней
    if (totalDaysRange >= 7) {
      print('Total days range is greater than or equal to 7, returning true.');
      return true;
    }

    // Преобразуем дни недели в индексы от 0 (Воскресенье) до 6 (Суббота)
    final int startDayIndex = start.weekday % 7;
    final int endDayIndex = end.weekday % 7;

    // Печатаем индексы начала и конца диапазона
    print('Start day index: $startDayIndex, End day index: $endDayIndex, Selected index: $selectedIndex');

    // Проверяем, попадает ли выбранный индекс в диапазон
    bool isWithinRange;
    if (startDayIndex <= endDayIndex) {
      isWithinRange = selectedIndex >= startDayIndex && selectedIndex <= endDayIndex;
    } else {
      isWithinRange = selectedIndex >= startDayIndex || selectedIndex <= endDayIndex;
    }

    print('Is selected index within range: $isWithinRange');

    return isWithinRange;
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
