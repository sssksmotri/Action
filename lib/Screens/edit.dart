import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'notes.dart';
import '../main.dart';
import 'dart:ui';
import 'stat.dart';
import 'package:action_notes/Service/HabitReminderService.dart';
import 'package:easy_localization/easy_localization.dart';
import 'add.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:action_notes/Widgets/loggable_screen.dart';
class EditPage extends StatefulWidget {
  final int habitId;
  final String ActionName;
  final int sessionId;
  const EditPage({super.key, required this.habitId, required this.ActionName, required this.sessionId});
  @override
  _EditActionPageState createState() => _EditActionPageState();

}

class _EditActionPageState extends State<EditPage> {
  late int habitId;
  DateTime? startDate;
  DateTime? endDate;
  String taskTitle = "My Task";
  int selectedType = -1; // Для отслеживания выбранного элемента
  List<bool> selectedDays = [false, false, false, false, false, false, false];
  bool notificationsEnabled = false;
  int selectedHour = 8; // Время по умолчанию: 8 часов
  int selectedMinute = 0; // Время по умолчанию: 0 минут
  int _selectedIndex = 0;
  String? nameError;
  String? dateError;
  String? quantityError;
  String? volumeError;
  String? periodError;
  String? typeError;
  bool allDaysSelected = false;

  List<Map<String, dynamic>> notificationWidgets = [
    {'hour': 8, 'minute': 0, 'days': List<bool>.filled(7, false)}
  ];
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController volumePerPressController = TextEditingController();
  final TextEditingController volumeSpecifiedController = TextEditingController();
  late TextEditingController actionNameController;
  List<Map<String, dynamic>> notificationTimes = []; // Времена уведомлений для каждой привычки
  final HabitReminderService habitReminderService = HabitReminderService();
  final DatabaseHelper habitService = DatabaseHelper.instance;
  int _selectedpos=0 ;
  final List<int> hours = List.generate(24, (index) => index);
  final List<int> minutes = List.generate(60, (index) => index);
  FocusNode hourFocusNode = FocusNode();
  FocusNode minuteFocusNode = FocusNode();
  int? _currentSessionId;

  @override
  void initState() {
    super.initState();
    habitId = widget.habitId;
    actionNameController = TextEditingController(text: widget.ActionName);
    _loadHabitData(habitId);
    _currentSessionId = widget.sessionId;
  }

  @override
  void dispose() {
    actionNameController.dispose();
    quantityController.dispose();
    volumePerPressController.dispose();
    volumeSpecifiedController.dispose();
    hourFocusNode.dispose();
    minuteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHabitData(int habitId) async {
    try {
      // Запрос данных о привычке по ID
      final habitData = await habitService.queryHabitById(habitId);

      // Запрос данных напоминаний по habit_id
      final remindersData = await habitService.queryReminders(habitId);

      setState(() {
        // Заполнение полей привычки
        actionNameController.text = habitData['name'] as String;
        selectedType = habitData['type'] as int;
        startDate = DateTime.parse(habitData['start_date'] as String);
        endDate = habitData['end_date'] != null
            ? DateTime.parse(habitData['end_date'] as String)
            : null;
        notificationsEnabled = habitData['notifications_enabled'] == 1;
        quantityController.text = habitData['quantity']?.toString() ?? '';
        volumePerPressController.text = habitData['volume_per_press']?.toString() ?? '';
        volumeSpecifiedController.text = habitData['volume_specified']?.toString() ?? '';
        allDaysSelected = remindersData.every((reminder) => reminder['is_active'] == 1);
        _selectedpos = habitData['position'] as int;

        // Обновление списка дней недели на основе remindersData
        notificationWidgets = remindersData.map((reminder) {
          return {
            'hour': int.parse(reminder['time'].split(':')[0]),
            'minute': int.parse(reminder['time'].split(':')[1]),
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

        // Первая запись уведомлений для инициализации времени и дней
        if (notificationWidgets.isNotEmpty) {
          selectedHour = notificationWidgets[0]['hour'] ?? 8;
          selectedMinute = notificationWidgets[0]['minute'] ?? 0;
          // Здесь заменяем `selectedDays` на индивидуальный список из первого уведомления
          selectedDays = List<bool>.from(notificationWidgets[0]['days']);
        }
      });
    } catch (e) {
      // Обработка ошибки, если привычка не найдена
      print('Error loading habit data: $e');
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


  void _showDeleteDialog(BuildContext context, String taskTitle, Function() onDelete) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // Легкое затемнение вместе с размытием
      builder: (BuildContext context) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Эффект размытия
              child: Container(
                color: Colors.black.withOpacity(0), // Прозрачный контейнер для сохранения размытия
              ),
            ),
            Center(
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                insetPadding: const EdgeInsets.all(15), // Отступ от краев
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "update_successful".tr(), // Локализованный текст
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 24, // Размер шрифта уменьшен для лучшей адаптации
                        ),
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка "Home"
                      SizedBox(
                        width: 165, // Увеличиваем ширину кнопки
                        height: 45, // Увеличил высоту для улучшения размещения текста
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoggableScreen(
                                  screenName: 'HomePage',
                                  child: HomePage(
                                    sessionId: _currentSessionId!, // Передаем sessionId в HomePage
                                  ),
                                  currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEEE9FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Скорректированные паддинги
                          ),
                          child: Text(
                            "home".tr(), // Локализованный текст
                            style: const TextStyle(
                              color: Color(0xFF5F33E1),
                              fontWeight: FontWeight.bold,
                              fontSize: 16, // Размер текста для кнопки
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // Отступ между кнопками
                      // Кнопка "Create a new action"
                      SizedBox(
                        width: 165, // Увеличиваем ширину кнопки
                        height: 45, // Увеличил высоту
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoggableScreen(
                                  screenName: 'AddActionPage',
                                  child: AddActionPage(
                                    sessionId: _currentSessionId!, // Передаем sessionId в AddActionPage
                                  ),
                                  currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF5F33E1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Скорректированные паддинги
                          ),
                          child: Text(
                            "update_action".tr(), // Локализованный текст
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // Увеличен размер текста для улучшения читабельности
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
        backgroundColor: const Color(0xFFF8F9F9),

        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          tr('edit_action'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false, // Заголовок слева
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Отступ справа
            child: GestureDetector(
              onTap: () {
                // Возврат на главную страницу и удаление всех предыдущих страниц
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoggableScreen(
                      screenName: 'HomePage',
                      child: HomePage(
                        sessionId: _currentSessionId!, // Передаем sessionId в HomePage
                      ),
                      currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                    ),
                  ),
                      (Route<dynamic> route) => false, // Удаляем все предыдущие страницы
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6.0), // Отступы вокруг крестика
                decoration: BoxDecoration(
                  color: const Color(0xFFEEE9FF), // Фоновый цвет вокруг крестика
                  borderRadius: BorderRadius.circular(8), // Скругление углов
                ),
                child: Image.asset(
                  'assets/images/krest.png', // Путь к вашему изображению
                  width: 14,  // Размер изображения (как у иконки)
                  height: 14,
                  color: const Color(0xFF5F33E1),  // Цвет картинки (если нужно перекрасить)
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildActionNameCard(),
              // Карточка с названием действия
              const SizedBox(height: 12),
              _buildTypeSelectionCard(),
              // Карточка с типом выполнения
              const SizedBox(height: 12),
              _buildDateSelectionCard(),
              // Карточка с выбором дат
              const SizedBox(height: 12),
              _buildDaysAndNotifications(),
              // Чекбоксы с днями и тумблер для уведомлений
              const SizedBox(height: 12),
              _buildNotificationToggle(),
              const SizedBox(height: 12),
              _buildAddButton(taskTitle),
              // Кнопка создания действия
              const SizedBox(height: 6),

            ],
          ),
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
            _buildNavItem(0, 'assets/images/Home.png'),
            _buildNavItem(1, 'assets/images/Edit.png'),
            _buildNavItem(2, 'assets/images/Plus.png', isSelected: true),
            _buildNavItem(3, 'assets/images/Calendar.png'),
            _buildNavItem(4, 'assets/images/Setting.png'),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildActionNameCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: actionNameController, // Подключение контроллера к полю ввода
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFFF8F9F9),
              labelText: 'Action Name',
              labelStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              // Обновляем значение в setState
              setState(() {
                actionNameController.text = value;
              });

            },
            textInputAction: TextInputAction.done, // Добавлено для завершения
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();
            },
          ),
        ],
      ),
    );
  }

  // Карточка с выбором типа выполнения
  Widget _buildTypeSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('type_of_fulfilment'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildCustomCheckbox(tr('one_off_execution'), 0),
              const SizedBox(height: 16),
              _buildCustomCheckbox(tr('execute_certain_times'), 1),
              const SizedBox(height: 16),
              _buildCustomCheckbox(tr('perform_certain_volume'), 2),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedType == 1) _buildQuantityTextField(errorMessage: quantityError),
          if (selectedType == 2) ...[
            _buildVolumeTextField(errorMessage: volumeError),
            const SizedBox(height: 16),
            _buildVolumePerPressTextField(errorMessage: volumeError), // Ошибка может быть та же
          ],
        ],
      ),
    );
  }

  void _resetErrorMessages() {
    setState(() {
      quantityError = null;
      volumeError = null;
    });
  }

  Widget _buildCustomCheckbox(String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = index;
          _resetErrorMessages();// Только один элемент может быть выбран
        });
      },
      child: Row(
        children: [
          // Внешний контейнер для круговой границы
          Container(
            width: 24, // Размер внешнего контейнера для отступов
            height: 24, // Размер внешнего контейнера для отступов
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedType == index ? const Color(0xFF5F33E1) : Colors
                    .grey,
                width: 2,
              ),
            ),
            child: Center(
              // Внутренний контейнер для создания эффекта отступов
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selectedType == index ? 14 : 0,
                // Ширина внутреннего контейнера
                height: selectedType == index ? 14 : 0,
                // Высота внутреннего контейнера
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedType == index
                      ? const Color(0xFF5F33E1)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold, // Жирный текст
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityTextField({String? errorMessage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: quantityController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            labelText: tr('label_specify_quantity'),
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done, // Добавлено для завершения
          onSubmitted: (value) {
            FocusScope.of(context).unfocus();
          },
        ),
        if (errorMessage != null && errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildVolumeTextField({String? errorMessage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: volumeSpecifiedController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            labelText: tr('label_specify_volume'),
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done, // Добавлено для завершения
          onSubmitted: (value) {
            FocusScope.of(context).unfocus();
          },
        ),
        if (errorMessage != null && errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildVolumePerPressTextField({String? errorMessage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: volumePerPressController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            labelText: tr('label_volume_per_press'),
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done, // Добавлено для завершения
          onSubmitted: (value) {
            FocusScope.of(context).unfocus();
          },
        ),
        if (errorMessage != null && errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }


  // Метод для отображения диалога календаря
  void _showCalendarDialog(DateTime initialDate, bool isStartDate, ValueChanged<DateTime> onDateSelected) {
    print("Showing calendar dialog with initial date: $initialDate");

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // Полупрозрачный барьер
      barrierDismissible: true, // Позволяем закрывать диалог при нажатии вне области
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Эффект размытия фона
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
                    focusedDay: initialDate,
                    locale: Localizations.localeOf(context).toString(),
                    selectedDayPredicate: (day) => isSameDay(day, initialDate),
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
                      todayTextStyle: const TextStyle(
                        color: Colors.black,
                      ),
                      outsideDaysVisible: false,
                      disabledTextStyle: const TextStyle(color: Colors.grey), // Отключенные дни серым
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      titleTextFormatter: (date, locale) {
                        String formattedMonth = DateFormat.MMMM(locale).format(date);
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
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      weekendStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      dowTextFormatter: (date, locale) =>
                          DateFormat.E(locale).format(date).toUpperCase(),
                    ),
                    enabledDayPredicate: (day) {
                      return day.isAfter(DateTime.now().subtract(const Duration(days: 1)));
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      print("Selected day: $selectedDay");

                      if (isStartDate) {
                        if (endDate != null && selectedDay.isAfter(endDate!)) {
                          _showError(tr("error_start_date_later_than_end"));
                        } else {
                          onDateSelected(selectedDay);
                          dateError = null;
                          _resetInvalidDays();
                        }
                      } else {
                        if (startDate != null && selectedDay.isBefore(startDate!)) {
                          _showError(tr("error_end_date_earlier_than_start"));
                        } else {
                          onDateSelected(selectedDay);
                          dateError = null;
                          _resetInvalidDays();
                        }
                      }
                      Navigator.pop(context);
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

// Метод для создания виджета выбора даты
  Widget _buildDatePicker(String label, String value, bool isStartDate, ValueChanged<DateTime?> onDatePicked) {
    return GestureDetector(
      onTap: () {
        DateTime initialDate = isStartDate
            ? (startDate ?? DateTime.now())
            : (endDate ?? DateTime.now());
        _showCalendarDialog(initialDate, isStartDate, (selectedDate) {
          onDatePicked(selectedDate);
        });
      },
      child: Container(
        width: 150,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value.isEmpty ? DateFormat('dd/MM/yyyy').format(DateTime.now()) : value,  // Отображаем сегодняшнюю дату если value пустое
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            Image.asset(
              'assets/images/Calendar.png',
              width: 24,
              height: 24,
              color: const Color(0xFF5F33E1),
            ),
          ],
        ),
      ),
    );
  }

// Метод для построения карточки выбора даты
  Widget _buildDateSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Цвет карточки
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Первый Column для начальной даты
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10), // Отступ справа
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('start_date'), // Заголовок для поля начальной даты
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8), // Отступ между заголовком и полем
                      _buildDatePicker(
                        tr('start_date'),
                        startDate != null
                            ? DateFormat('dd.MM.yy').format(startDate!)
                            : tr('from'), // Отображаем "From" если дата не выбрана
                        true, // Это начальная дата
                            (pickedDate) {
                          setState(() {
                            startDate = pickedDate;
                            _resetInvalidDays();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Второй Column для конечной даты
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10), // Отступ слева
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('end_date'), // Заголовок для поля конечной даты
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8), // Отступ между заголовком и полем
                      _buildDatePicker(
                        tr('end_date'),
                        endDate != null
                            ? DateFormat('dd.MM.yy').format(endDate!)
                            : tr('to'), // Отображаем "To" если дата не выбрана
                        false, // Это конечная дата
                            (pickedDate) {
                          setState(() {
                            endDate = pickedDate;
                            _resetInvalidDays();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Отображение ошибки для дат
          if (dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                dateError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }




  // Карточка с чекбоксами дней недели и тумблером для уведомлений
  Widget _buildDaysAndNotifications() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDaysOfWeekCheckboxes(), // Чекбоксы дней недели
        ],
      ),
    );
  }



  bool _isWithinDateRange(DateTime start, DateTime end, int selectedIndex) {
    // Получаем индексы дня недели (0 - понедельник, 6 - воскресенье)
    final int startDayIndex = start.weekday ; // Преобразуем weekday в индекс (1=понедельник -> 0)
    final int endDayIndex = end.weekday ;     // Преобразуем weekday в индекс

    // Если начальная и конечная дата совпадают, разрешаем выбрать только этот день
    if (start.isAtSameMomentAs(end)) {
      return selectedIndex == startDayIndex;
    }

    // Если диапазон больше 7 дней, разрешаем выбрать любые дни
    if (end.difference(start).inDays >= 7) {
      return true;
    }

    // Если диапазон находится в пределах одной недели
    if (start.isBefore(end) && startDayIndex <= endDayIndex) {
      return selectedIndex >= startDayIndex && selectedIndex <= endDayIndex;
    }

    // Если диапазон пересекает неделю (например, с пятницы по понедельник)
    if (start.isBefore(end) && startDayIndex > endDayIndex) {
      return selectedIndex >= startDayIndex || selectedIndex <= endDayIndex;
    }

    return false;
  }


  void _resetInvalidDays() {
    if (startDate != null && endDate != null) {
      final int startDayIndex = startDate!.weekday; // Индекс дня начала (понедельник - 1)
      final int endDayIndex = endDate!.weekday;     // Индекс дня конца
      final int periodLength = endDate!.difference(startDate!).inDays;

      setState(() {
        for (int i = 0; i < 7; i++) {
          if (periodLength >= 7) {
            // Если диапазон больше 7 дней, не сбрасываем чекбоксы
            selectedDays[i] = true;  // Разрешаем все дни
            notificationWidgets.forEach((widget) {
              widget['days'][i] = true; // Сбрасываем чекбоксы уведомлений
            });
          } else {
            if (startDayIndex <= endDayIndex) {
              selectedDays[i] = i >= startDayIndex && i <= endDayIndex;
              notificationWidgets.forEach((widget) {
                widget['days'][i] = i >= startDayIndex && i <= endDayIndex; // Сбрасываем чекбоксы уведомлений
              });
            } else {
              selectedDays[i] = i >= startDayIndex || i <= endDayIndex;
              notificationWidgets.forEach((widget) {
                widget['days'][i] = i >= startDayIndex || i <= endDayIndex; // Сбрасываем чекбоксы уведомлений
              });
            }
          }
        }
      });
    }
  }





  Widget _buildDaysOfWeekCheckboxes() {
    List<String> days = [
      tr('days.sunday'),
      tr('days.monday'),
      tr('days.tuesday'),
      tr('days.wednesday'),
      tr('days.thursday'),
      tr('days.friday'),
      tr('days.saturday'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            return Column(
              children: [
                Text(
                  days[index],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616060),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Проверяем, выбраны ли уже другие чекбоксы
                      int selectedCount = selectedDays.where((day) => day).length;

                      // Если текущий чекбокс выбран и это единственный выбранный день
                      if (selectedDays[index] && selectedCount == 1) {
                        _showError(tr('error_days_selection'));
                      } else {
                        // Либо переключаем чекбокс, если есть другие выбранные дни
                        if (startDate != null && endDate != null) {
                          if (_isWithinDateRange(startDate!, endDate!, index)) {
                            selectedDays[index] = !selectedDays[index];
                          } else {
                            _showError(tr('error_selected_day_out_of_range'));
                          }
                        } else {
                          _showError(tr('error_select_start_end_dates'));
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selectedDays[index]
                          ? const Color(0xFF5F33E1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: selectedDays[index]
                            ? const Color(0xFF5F33E1)
                            : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: selectedDays[index]
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
        ),
      ],
    );
  }


  // Тумблер для включения/выключения уведомлений
  bool _isValidTime(int hour, int minute) {
    return hour >= 0 && hour < 24 && minute >= 0 && minute < 60;
  }

  Widget _buildDaysOfWeekCheckboxesNot(int index) {
    List<String> days = [
      tr('days.sunday'),
      tr('days.monday'),
      tr('days.tuesday'),
      tr('days.wednesday'),
      tr('days.thursday'),
      tr('days.friday'),
      tr('days.saturday'),
    ];

    // Получаем дни для конкретного уведомления
    List<bool> selectedDays = notificationWidgets[index]['days'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (dayIndex) {
            bool isInRange = startDate != null && endDate != null && _isWithinDateRange(startDate!, endDate!, dayIndex);
            return Column(
              children: [
                Text(
                  days[dayIndex],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616060),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (isInRange) {
                      setState(() {
                        int selectedCount = selectedDays.where((day) => day).length;
                        if (selectedDays[dayIndex] && selectedCount == 1) {
                          _showError(tr('error_days_selection'));
                        } else {
                          selectedDays[dayIndex] = !selectedDays[dayIndex];
                        }
                      });
                    } else {
                      _showError(tr('error_selected_day_out_of_range'));
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selectedDays[dayIndex] ? const Color(0xFF5F33E1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isInRange ? (selectedDays[dayIndex] ? const Color(0xFF5F33E1) : Colors.grey) : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: selectedDays[dayIndex]
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }


  Widget _buildTimePicker(int index) {
    final Map<String, Object> timeEntry = Map<String, Object>.from(notificationWidgets[index]);
    int selectedHour = timeEntry['hour'] as int;
    int selectedMinute = timeEntry['minute'] as int;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 80,
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
                      if (hour != null && _isValidTime(hour, selectedMinute)) {
                        notificationWidgets[index]['hour'] = hour;
                        _resetInvalidDays();
                        hourFocusNode.unfocus();
                      }
                    });
                  },
                ),
              ),
              Text(' : ', style: TextStyle(fontSize: 24, color: Colors.black)),
              Container(
                width: 80,
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
                      if (minute != null && _isValidTime(selectedHour, minute)) {
                        notificationWidgets[index]['minute'] = minute;
                        minuteFocusNode.unfocus();
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  // Создаем список дней по умолчанию для нового уведомления
                  List<bool> newDays = List<bool>.generate(7, (dayIndex) {
                    return _isWithinDateRange(startDate!, endDate!, dayIndex);
                  });

                  // Добавляем новое уведомление в базу данных и получаем его ID
                  int newReminderId = await habitReminderService.addNewReminder(
                      habitId, // ID привычки
                      '08:00', // по умолчанию время 8:00
                      newDays // новый список дней
                  );

                  setState(() {
                    // Обновляем ID в списке для нового напоминания и добавляем его в `notificationWidgets`
                    notificationWidgets.add({
                      'hour': 8,
                      'minute': 0,
                      'days': newDays,
                      'id': newReminderId,
                    } as Map<String, Object>);
                    notificationTimes.add({
                      'habitId': habitId,
                      'time': '08:00',
                      'days': newDays,
                      'id': newReminderId,
                    });
                  });
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
              if (notificationWidgets.length > 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (notificationWidgets.length > 1) {
                        notificationWidgets.removeAt(index);
                        _removeNotification(timeEntry);
                      }
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
        ),
        _buildDaysOfWeekCheckboxesNot(index),
      ],
    );
  }



  Widget _buildNotificationToggle() {
    return Card(
      color: Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('notifications'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                      onTap: (startDate != null && endDate != null)
                          ? () {
                        setState(() {
                          notificationsEnabled = !notificationsEnabled;

                          // Обновляем дни для всех уведомлений при включении тумблера
                          if (notificationsEnabled) {
                             habitReminderService.initializeReminders();
                            for (var notification in notificationWidgets) {
                              notification['days'] = List<bool>.generate(7, (dayIndex) {
                                return _isWithinDateRange(startDate!, endDate!, dayIndex);
                              });
                            }
                          } else {
                            habitReminderService.cancelAllReminders(habitId);
                            for (var notification in notificationWidgets) {
                              notification['days'] = List<bool>.filled(7, false); // Сбрасываем дни, если уведомления выключены
                            }
                          }
                          _saveToggleState('habit_${habitId}_notifications_enabled', notificationsEnabled);
                        });
                      }
                          : () {
                        _showError(tr('error_select_start_end_dates')); // Показываем ошибку
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: notificationsEnabled ? const Color(0xFF5F33E1) : const Color(0xFFEEE9FF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          Positioned(
                            left: notificationsEnabled ? null : 2, // Отступ слева
                            right: notificationsEnabled ? 2 : null, // Отступ справа
                            top: 2, // Отступ сверху
                            child: Container(
                              width: 22, // Ширина шарика
                              height: 22,
                              decoration: BoxDecoration(
                                color: notificationsEnabled ? const Color(0xFFFFFFFF) : const Color(0xFF5F33E1),
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
            if (notificationsEnabled)
              Column(
                children: notificationWidgets
                    .asMap()
                    .entries
                    .map((entry) => _buildTimePicker(entry.key))
                    .toList(),
              ),
            const SizedBox(height: 10),

          ],
        ),
      ),
    );
  }

  Future<void> _saveToggleState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  //Кнопка
  Widget _buildAddButton(String taskTitle) {
    return ElevatedButton(
      onPressed: () {
        _updateHabit(taskTitle); // Передаем taskTitle в _addHabit
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5F33E1),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child:  Center(
        child: Text(
          tr('update_action'),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }



  void _removeNotification(Map<String, dynamic> timeEntry) async {
    int? reminderId = timeEntry['id'];
    if (reminderId == null) {
      print('Ошибка: reminderId равно null.');
      return;
    }

    // Удаляем уведомление из виджета
    setState(() {
      notificationTimes.removeWhere((entry) => entry['id'] == reminderId);
      notificationWidgets.removeWhere((entry) => entry['id'] == reminderId);
    });

    // Удаляем уведомление из базы данных
    await habitReminderService.deleteReminder(reminderId);
  }


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

  void _updateNotification(Map<String, dynamic> habit) async {
    Set<String> processedTimes = {};

    for (var i = 0; i < notificationWidgets.length; i++) {
      var timeEntry = notificationWidgets[i];
      String time = '${timeEntry['hour'].toString().padLeft(2, '0')}:${timeEntry['minute'].toString().padLeft(2, '0')}';

      // Проверяем, было ли это время уже обработано
      if (!processedTimes.contains(time)) {
        processedTimes.add(time);

        // Получаем дни из чекбоксов для текущего времени
        List<bool> selectedDays = timeEntry['days'];

        // Проверяем, выбраны ли хотя бы один день и существует ли идентификатор напоминания
        if (selectedDays.any((day) => day)) {
          int? reminderId = timeEntry['id']; // Проверяем, есть ли существующий ID


          if (reminderId != null) {
            // Если есть идентификатор напоминания, обновляем его
            print('Обновляем напоминание с ID $reminderId на время $time с днями $selectedDays');
            await _updateReminderInDatabase(reminderId, newTime: time, selectedDays: selectedDays);
          } else {
            // Если напоминания еще нет, создаем новое
            print('Создаем новое напоминание для привычки ${habit['id']} на время $time с днями $selectedDays');
            int newReminderId = await habitReminderService.addNewReminder(habit['id'], time, selectedDays);
            setState(() {
              // Обновляем ID в списке для нового напоминания
              notificationWidgets[i]['id'] = newReminderId;
              notificationTimes.add({
                'habitId': habit['id'],
                'time': time,
                'days': selectedDays,
                'id': newReminderId,
              });
            });
          }
        } else {
          print('Нет выбранных дней для времени $time. Пропускаем...');
        }
      } else {
        print('Время $time уже обработано. Пропускаем...');
      }
    }
  }

  Future<void> _updateHabit(String taskTitle) async {
    setState(() {
      // Валидация типа выполнения
      if (selectedType == -1) {
        typeError = tr('error_action_type_required');
      } else {
        typeError = null;
      }

      // Валидация названия действия
      String actionName = actionNameController.text.trim(); // Получаем значение из контроллера
      nameError = actionName.isEmpty || actionName.length < 2
          ? tr('error_name_too_short')
          : null;

      // Валидация дат
      if (startDate == null || endDate == null) {
        dateError = tr('error_date_selection');
      } else if (endDate!.isBefore(startDate!)) {
        dateError = tr('error_end_date_before_start');
      } else {
        dateError = null;
      }

      // Валидация количества для выбранного типа
      if (selectedType == 1) {
        String quantityText = quantityController.text.trim();
        if (quantityText.isEmpty) {
          quantityError = tr('error_quantity_integer');
        } else {
          int? quantityValue = int.tryParse(quantityText);
          quantityError = quantityValue == null ? tr('error_quantity_integer') : null; // Если всё в порядке, сбрасываем ошибку
        }
      }

      // Валидация объема для типа 2
      if (selectedType == 2) {
        double? volumePerPress = double.tryParse(volumePerPressController.text);
        double? volumeSpecified = double.tryParse(volumeSpecifiedController.text);
        volumeError = (volumePerPress == null || volumeSpecified == null)
            ? tr('error_volume_valid_numbers')
            : null;
      }

      // Валидация диапазона дат и выбранных дней
      if (startDate != null && endDate != null) {
        final int periodLength = endDate!.difference(startDate!).inDays;

        if (periodLength <= 7) {
          bool invalidDaySelected = false;
          bool anyDaySelected = false; // Флаг, чтобы проверить, выбран ли хотя бы один день

          // Проверяем, что не выбраны дни за пределами допустимого диапазона
          for (int i = 0; i < 7; i++) {
            if (selectedDays[i]) {
              anyDaySelected = true; // Устанавливаем флаг, если день выбран
            }
            if (selectedDays[i] && !_isWithinDateRange(startDate!, endDate!, i)) {
              invalidDaySelected = true;
              break;
            }
          }

          if (!anyDaySelected) {
            periodError = tr('error_days_selection');
          } else if (invalidDaySelected) {
            periodError = tr('error_invalid_days_for_period');
          } else {
            periodError = null; // Сброс ошибки, если всё в порядке
          }
        }
      }
    });

    // Проверка ошибок перед обновлением привычки
    if (nameError == null &&
        dateError == null &&
        quantityError == null &&
        volumeError == null &&
        periodError == null &&
        typeError == null) {

      int? quantity = int.tryParse(quantityController.text.trim());
      double? volumePerPress = double.tryParse(volumePerPressController.text);
      double? volumeSpecified = double.tryParse(volumeSpecifiedController.text);

      Map<String, dynamic> updatedHabit = {
        'id': habitId,
        'name': actionNameController.text.trim(),
        'type': selectedType,
        'start_date': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : null,
        'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
        'quantity': selectedType == 1 ? quantity : null,
        'volume_per_press': selectedType == 2 ? volumePerPress : null,
        'volume_specified': selectedType == 2 ? volumeSpecified : null,
        'position': _selectedpos,
        'notifications_enabled': notificationsEnabled// Добавьте это
      };

      // Обновление привычки в БД
      try {
        print('Обновляем привычку с ID: $habitId с данными: $updatedHabit');
        await habitService.updateHabit(updatedHabit);
        print('Привычка обновлена.');

        // Проверяем, включены ли уведомления и выбраны ли дни
        if (notificationsEnabled) {
          for (var timeEntry in notificationWidgets) {
            String time = '${timeEntry['hour'].toString().padLeft(2, '0')}:${timeEntry['minute'].toString().padLeft(2, '0')}';
            List<bool> days = List.from(selectedDays);

            // Добавляем уведомление только если хотя бы один день выбран
            if (days.any((day) => day)) {
              print('Обновляем уведомление для привычки ID $habitId на время $time с днями $days');
              _updateNotification({'id': habitId, 'time': time, 'days': days});
            } else {
              print('Нет выбранных дней для уведомления на время $time. Пропускаем...');
            }
          }
        }

        _showDeleteDialog(context, taskTitle, () {
          // Логика удаления
        });
      } catch (e) {
        print('Ошибка при обновлении привычки: $e');
      }
    } else {
      // Если есть ошибки, отображаем через SnackBar
      String errorMessage = 'Пожалуйста, исправьте ошибки:';
      if (typeError != null) errorMessage += '\n- $typeError';
      if (nameError != null) errorMessage += '\n- $nameError';
      if (dateError != null) errorMessage += '\n- $dateError';
      if (quantityError != null) errorMessage += '\n- $quantityError';
      if (volumeError != null) errorMessage += '\n- $volumeError';
      if (periodError != null) errorMessage += '\n- $periodError';

      _showError(errorMessage);
    }
  }


}