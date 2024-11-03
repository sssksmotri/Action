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
import 'package:action_notes/Widgets/loggable_screen.dart';

class AddActionPage extends StatefulWidget {
  final int sessionId;
  const AddActionPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  _AddActionPageState createState() => _AddActionPageState();
}

class _AddActionPageState extends State<AddActionPage> {
  String actionName = '';
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
  List<Map<String, dynamic>> notificationTimes = []; // Времена уведомлений для каждой привычки
  final HabitReminderService habitReminderService = HabitReminderService();
  final DatabaseHelper habitService = DatabaseHelper.instance;
  // Списки для выбора часов и минут
  final List<int> hours = List.generate(24, (index) => index);
  final List<int> minutes = List.generate(60, (index) => index);
  FocusNode hourFocusNode = FocusNode();
  FocusNode minuteFocusNode = FocusNode();
  FocusNode quantityNode = FocusNode();
  int? _currentSessionId;
  String _currentScreenName = "AddActionPage";

  @override
  void dispose() {
    hourFocusNode.dispose();
    minuteFocusNode.dispose();
    quantityNode.dispose();
    super.dispose();
  }

  @override
  void initState()  {
    super.initState();
    _currentSessionId = widget.sessionId; // Инициализируем _currentSessionId здесь
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


  void _showDeleteDialog(BuildContext context, String taskTitle, Function() onDelete)  {
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
                  borderRadius: BorderRadius.circular(20),
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
                        text: "action_successful".tr(), // Локализованный текст
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20, // Размер шрифта уменьшен для лучшей адаптации
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
                          onPressed: () async {
                            await DatabaseHelper.instance.logAction(widget.sessionId, "Пользователь выбрал вернуться на экран HomePage с экрана: $_currentScreenName");
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
                              fontSize: 14, // Размер текста для кнопки
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
                          onPressed: () async {
                            await DatabaseHelper.instance.logAction(widget.sessionId, "Пользователь нажал добавить новую привычку на экране: $_currentScreenName");
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
                            "create_action".tr(), // Локализованный текст
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Увеличен размер текста для улучшения читабельности
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
          tr('add_action'),
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
                DatabaseHelper.instance.logAction(
                    _currentSessionId!,
                    "Пользователь нажал кнопку крестик и вернулся в HomePage из: $_currentScreenName"
                );
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
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFFF8F9F9),
              labelText: tr('label_action_name'),
              labelStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                actionName = value;
              });

              // Логируем начало ввода имени действия
              if (value.isNotEmpty) {
                DatabaseHelper.instance.logAction(
                    _currentSessionId!,
                    "Пользователь начал вводить название действия: $value на экране: $_currentScreenName"
                );
              }
            },
            textInputAction: TextInputAction.done, // Добавлено для завершения
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();

              // Логируем завершение ввода имени действия
              DatabaseHelper.instance.logAction(
                  _currentSessionId!,
                  "Пользователь ввел название действия: $value на экране: $_currentScreenName"
              );
            },
          ),

          if (nameError != null) // Отображение ошибки под полем ввода
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                nameError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
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
          _resetErrorMessages();
          DatabaseHelper.instance.logAction(
              _currentSessionId!,
              "Пользователь выбрал тип выполнения: $label на экране: $_currentScreenName"
          );
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
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            // Логируем ввод количества пользователем
            DatabaseHelper.instance.logAction(
                _currentSessionId!,
                "Пользователь начал вводить количество: $value на экране: $_currentScreenName"
            );
          },// Добавлено для завершения
          onSubmitted: (value) {
        FocusScope.of(context).unfocus();
        DatabaseHelper.instance.logAction(
            _currentSessionId!,
            "Пользователь завершил вводить количество: $value на экране: $_currentScreenName"
        );
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
      textInputAction: TextInputAction.done,
          onChanged: (value) {
            // Логируем ввод объема пользователем
            DatabaseHelper.instance.logAction(
                _currentSessionId!,
                "Пользователь начал вводить объем: $value на экране: $_currentScreenName"
            );
          },// Добавлено для завершения
      onSubmitted: (value) {
        DatabaseHelper.instance.logAction(
            _currentSessionId!,
            "Пользователь завершил вводить объем: $value на экране: $_currentScreenName"
        );
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
      textInputAction: TextInputAction.done,
          onChanged: (value) {
            // Логируем ввод объема на нажим
            DatabaseHelper.instance.logAction(
                _currentSessionId!,
                "Пользователь начал вводить объем на нажатие: $value на экране: $_currentScreenName"
            );
          },
          // Добавлено для завершения
      onSubmitted: (value) {
        DatabaseHelper.instance.logAction(
            _currentSessionId!,
            "Пользователь завершил вводить объем на нажатие: $value на экране: $_currentScreenName"
        );
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
                        padding: const EdgeInsets.only(left: 35.0),
                        child: Image.asset(
                          'assets/images/arr_left.png',
                          width: 20,
                          height: 20,
                          color: const Color(0xFF5F33E1),
                        ),
                      ),
                      rightChevronIcon: Padding(
                        padding: const EdgeInsets.only(right: 35.0),
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
                          DatabaseHelper.instance.logAction(
                              _currentSessionId!,
                              "Пользователь выбрал дату начала: $selectedDay на экране: $_currentScreenName"
                          );
                          dateError = null;
                          _resetInvalidDays();
                        }
                      } else {
                        if (startDate != null && selectedDay.isBefore(startDate!)) {
                          _showError(tr("error_end_date_earlier_than_start"));
                        } else {
                          onDateSelected(selectedDay);
                          DatabaseHelper.instance.logAction(
                              _currentSessionId!,
                              "Пользователь выбрал дату окончания: $selectedDay на экране: $_currentScreenName"
                          );
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
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value.isEmpty ? (isStartDate ? tr('from') : tr('to')) : value,  // Отображаем "From" или "To" если значение пустое
              style: TextStyle(
                fontSize: 16,
                color: value.isEmpty ? Colors.grey : Colors.black, // Цвет текста: серый если пусто, черный если выбрано
              ),
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
                            : '', // Значение пустое, если дата не выбрана
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
                            : '', // Значение пустое, если дата не выбрана
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
                    DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "пользователь ${selectedDays[index] ? 'выбрал' : 'убрал'} ${days[index]} на экране: $_currentScreenName"
                    );
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
                    DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "пользователь ${selectedDays[dayIndex] ? 'выбрал' : 'убрал'} день у уведомления: $index: ${days[dayIndex]} на экране: $_currentScreenName"
                    );
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
    final timeEntry = notificationWidgets[index];
    int selectedHour = timeEntry['hour'];
    int selectedMinute = timeEntry['minute'];

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
                      DatabaseHelper.instance.logAction(
                          _currentSessionId!,
                          "Пользователь изменил час уведомления на ${hour.toString().padLeft(2, '0')} на экране: $_currentScreenName"
                      );
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
                      DatabaseHelper.instance.logAction(
                          _currentSessionId!,
                          "Пользователь изменил минуту уведомления на ${minute.toString().padLeft(2, '0')} на экране: $_currentScreenName"
                      );
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
                onTap: () {
                  setState(() {
                    DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь добавил новое уведомление на экране: $_currentScreenName"
                    );
                    // Создаем новый элемент с доступными днями
                    List<bool> newDays = List<bool>.generate(7, (dayIndex) {
                      return _isWithinDateRange(startDate!, endDate!, dayIndex);
                    });
                    notificationWidgets.add({
                      'hour': 8,
                      'minute': 0,
                      'days': newDays,
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
                    DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь удалил уведомление на экране: $_currentScreenName"
                    );
                    setState(() {
                      if (notificationWidgets.length > 1) {
                        notificationWidgets.removeAt(index);
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
                            DatabaseHelper.instance.logAction(
                                _currentSessionId!,
                                "пользователь ${notificationsEnabled ? 'включил' : 'выключил'} уведомления на экране: $_currentScreenName"
                            );
                            for (var notification in notificationWidgets) {
                              notification['days'] = List<bool>.generate(7, (dayIndex) {
                                return _isWithinDateRange(startDate!, endDate!, dayIndex);
                              });
                            }
                          } else {
                            for (var notification in notificationWidgets) {
                              notification['days'] = List<bool>.filled(7, false); // Сбрасываем дни, если уведомления выключены
                            }
                          }
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



  //Кнопка
  Widget _buildAddButton(String taskTitle) {
    return ElevatedButton(
      onPressed: () {
        DatabaseHelper.instance.logAction(
            _currentSessionId!,
            "Пользователь добавил привычку на экране: $_currentScreenName"
        );
        _addHabit(taskTitle); // Передаем taskTitle в _addHabit
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
          tr('create_action'),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<int> _getMaxHabitPosition() async {
    final List<Map<String, dynamic>> result = await habitService.queryActiveHabits();
    if (result.isNotEmpty) {
      return result.map((habit) => habit['position'] as int).reduce((a, b) => a > b ? a : b);
    }
    return 0; // Если привычек нет, возвращаем 0
  }

  void _addNewNotification(Map<String, dynamic> habit) async {
    Set<String> addedTimes = {};

    for (var timeEntry in notificationWidgets) {
      String time = '${timeEntry['hour'].toString().padLeft(2, '0')}:${timeEntry['minute'].toString().padLeft(2, '0')}';

      // Проверяем, было ли это время уже добавлено
      if (!addedTimes.contains(time)) {
        addedTimes.add(time);

        // Получаем дни из чекбоксов для текущего времени
        List<bool> selectedDays = timeEntry['days'];

        // Добавляем новое уведомление в список только если хотя бы один день выбран
        if (selectedDays.any((day) => day)) {
          int reminderId = await habitReminderService.addNewReminder(habit['id'], time, selectedDays);

          // Добавляем новое уведомление в список
          setState(() {
            notificationTimes.add({
              'habitId': habit['id'],
              'time': time,
              'days': selectedDays,
              'id': reminderId, // Используем полученный reminderId
            });
          });
        }
      }
    }
  }


  Future<void> _addHabit(String taskTitle) async {
    setState(() {
      // Валидация типа выполнения
      if (selectedType == -1) {
        typeError = tr('error_action_type_required');
      } else {
        typeError = null;
      }

      // Валидация названия действия
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
          if (quantityValue == null) {
            quantityError = tr('error_quantity_integer');
          } else {
            quantityError = null; // Если всё в порядке, сбрасываем ошибку
          }
        }
      }

      // Валидация объема для типа 2
      if (selectedType == 2) {
        double? volumePerPress = double.tryParse(volumePerPressController.text);
        double? volumeSpecified = double.tryParse(volumeSpecifiedController.text);
        if (volumePerPress == null || volumeSpecified == null) {
          volumeError = tr('error_volume_valid_numbers');
        } else {
          volumeError = null;
        }
      }

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

    // Проверка ошибок перед добавлением привычки
    if (nameError == null &&
        dateError == null &&
        quantityError == null &&
        volumeError == null &&
        periodError == null &&
        typeError == null) {
      int? quantity = int.tryParse(quantityController.text.trim());
      double? volumePerPress = double.tryParse(volumePerPressController.text);
      double? volumeSpecified = double.tryParse(volumeSpecifiedController.text);
      int maxPosition = await _getMaxHabitPosition();
      Map<String, dynamic> newHabit = {
        'name': actionName,
        'type': selectedType.toString(),
        'start_date': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : null,
        'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
        'quantity': selectedType == 1 ? quantity : null,
        'volume_per_press': selectedType == 2 ? volumePerPress : null,
        'volume_specified': selectedType == 2 ? volumeSpecified : null,
        'position': maxPosition + 1,
      };

      // Логика добавления привычки в БД
      try {
        // Здесь добавляем привычку в БД
        int habitId = await habitService.insertHabit(newHabit);; // Предполагается, что у вас есть метод добавления привычки
        await DatabaseHelper.instance.incrementHabitCount(_currentSessionId!);
        // Проверяем, включены ли уведомления и выбраны ли дни
        if (notificationsEnabled) {
          for (var timeEntry in notificationWidgets) {
            String time = '${timeEntry['hour'].toString().padLeft(2, '0')}:${timeEntry['minute'].toString().padLeft(2, '0')}';
            List<bool> days = List.from(selectedDays);

            // Добавляем уведомление только если хотя бы один день выбран
            if (days.any((day) => day)) {
              _addNewNotification({'id': habitId, 'time': time, 'days': days});
            }
          }
        }
        _showDeleteDialog(context, taskTitle, () {
          // Логика удаления
        });
      } catch (e) {
        print('Error inserting habit: $e');
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
