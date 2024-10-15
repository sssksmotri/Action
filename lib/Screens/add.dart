import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'main.dart';
import 'stat.dart';

class AddActionPage extends StatefulWidget {
  const AddActionPage({Key? key}) : super(key: key);

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
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController volumePerPressController = TextEditingController();
  final TextEditingController volumeSpecifiedController = TextEditingController();
  DateTime _selectedDate = DateTime.now();


  // Текущая дата
  DateTime get _today => DateTime.now();


  // Списки для выбора часов и минут
  final List<int> hours = List.generate(24, (index) => index);
  final List<int> minutes = List.generate(60, (index) => index);

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
                  text: "The action has been successfully created!",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),

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
                      backgroundColor: const Color(0xFFFFFFF),
                      // Легкий фиолетовый фон
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Home",
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
                      backgroundColor: Color(0xFF5F33E1), // Красный фон
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Create a new action",
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
      backgroundColor: Colors.white, // Установлен белый фон
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Action',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false, // Заголовок слева
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildActionNameCard(),
              // Карточка с названием действия
              const SizedBox(height: 24),
              _buildTypeSelectionCard(),
              // Карточка с типом выполнения
              const SizedBox(height: 24),
              _buildDateSelectionCard(),
              // Карточка с выбором дат
              const SizedBox(height: 24),
              _buildDaysAndNotifications(),
              // Чекбоксы с днями и тумблер для уведомлений
              const SizedBox(height: 24),
              _buildNotificationToggle(),
              const SizedBox(height: 24),
              _buildAddButton(taskTitle),
              // Кнопка создания действия
            ],
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFFF8F9F9),
              labelText: 'Название действия',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type of fulfilment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildCustomCheckbox('One-off execution', 0),
              const SizedBox(height: 16),
              _buildCustomCheckbox('Execute a certain number of times', 1),
              const SizedBox(height: 16),
              _buildCustomCheckbox('Perform a certain volume', 2),
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
              fontSize: 16,
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
            labelText: 'Specify the quantity',
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
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
            labelText: 'Specify the volume',
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
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
            labelText: 'What volume does one press equal?',
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
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

  // Карточка с выбором дат
  void _showCalendarDialog(DateTime initialDate, ValueChanged<DateTime> onDateSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ваш календарь
                TableCalendar(
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: initialDate,
                  selectedDayPredicate: (day) {
                    return isSameDay(day, initialDate);
                  },
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
                    leftChevronIcon: const Icon(
                        Icons.chevron_left, color: Color(0xFF5F33E1)),
                    rightChevronIcon: const Icon(
                        Icons.chevron_right, color: Color(0xFF5F33E1)),
                  ),
                  daysOfWeekVisible: true,
                  onDaySelected: (selectedDay, focusedDay) {
                    // Выбор даты
                    // Передаем выбранные даты в _onDateChanged
                    if (initialDate == startDate) {
                      _onDateChanged(selectedDay, endDate ?? selectedDay);
                    } else {
                      _onDateChanged(startDate ?? selectedDay, selectedDay);
                    }
                    Navigator.pop(context); // Закрываем диалог после выбора даты
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker(String label, String value,
      ValueChanged<DateTime?> onDatePicked) {
    return GestureDetector(
      onTap: () {
        DateTime initialDate = label == 'Start Date'
            ? (startDate ?? DateTime.now())
            : (endDate ?? DateTime.now());
        _showCalendarDialog(initialDate, (selectedDate) {
          onDatePicked(selectedDate);
        });
      },
      child: Container(
        width: 130,
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
              value,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        // Выравнивание по левому краю
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Выравнивание заголовка по левому краю
                  children: [
                    const Text(
                      'Start Date', // Заголовок для поля начальной даты
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Отступ между заголовком и полем
                    _buildDatePicker(
                      'Start Date',
                      startDate != null
                          ? DateFormat('dd.MM.yy').format(startDate!)
                          : 'From',
                          (pickedDate) {
                        setState(() {
                          startDate = pickedDate;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Выравнивание заголовка по левому краю
                  children: [
                    const Text(
                      'End Date', // Заголовок для поля конечной даты
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Отступ между заголовком и полем
                    _buildDatePicker(
                      'End Date',
                      endDate != null
                          ? DateFormat('dd.MM.yy').format(endDate!)
                          : 'To',
                          (pickedDate) {
                        setState(() {
                          endDate = pickedDate;
                        });
                      },
                    ),
                  ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDaysOfWeekCheckboxes(), // Чекбоксы дней недели
        ],
      ),
    );
  }

  // Чекбоксы дней недели
  // Метод для проверки, попадает ли выбранный день в диапазон дат
  bool _isWithinDateRange(DateTime start, DateTime end, int selectedIndex) {
    final difference = end.difference(start).inDays;

    // Если разница больше 7 дней, разрешаем все дни
    if (difference > 7) {
      return true;
    }

    // Иначе проверяем, входит ли день в диапазон
    final int startDayIndex = start.weekday - 1;
    final int endDayIndex = end.weekday - 1;

    return selectedIndex >= startDayIndex && selectedIndex <= endDayIndex;
  }

  void _resetInvalidDays() {
    if (startDate != null && endDate != null) {
      final int periodLength = endDate!.difference(startDate!).inDays;

      setState(() {
        if (periodLength > 7) {
          // Если период больше 7 дней, не сбрасываем дни
          // Можно оставить выбранные дни без изменений
        } else {
          final int startDayIndex = startDate!.weekday - 1;
          final int endDayIndex = endDate!.weekday - 1;

          // Сбрасываем дни вне диапазона
          for (int i = 0; i < 7; i++) {
            selectedDays[i] = (i >= startDayIndex && i <= endDayIndex) ? selectedDays[i] : false;
          }
        }
      });
    }
  }

  void _onDateChanged(DateTime newStartDate, DateTime newEndDate) {
    setState(() {
      startDate = newStartDate;
      endDate = newEndDate;
      _resetInvalidDays(); // Сбрасываем дни только если диапазон меньше 7 дней
    });
  }

  Widget _buildDaysOfWeekCheckboxes() {
    List<String> days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

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
                    fontSize: 16,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (startDate != null && endDate != null) {
                        if (_isWithinDateRange(startDate!, endDate!, index)) {
                          selectedDays[index] = !selectedDays[index];
                        } else {
                          _showError('Выбранный день не входит в диапазон');
                        }
                      } else {
                        _showError('Пожалуйста, выберите даты начала и окончания');
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
  Widget _buildNotificationToggle() {
    return Card(
      color: Color(0xFFFFFFFF), // Серая карточка
      elevation: 1, // Легкая тень для карточки
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Отступы внутри карточки
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18, // Увеличенный шрифт
                    fontWeight: FontWeight.bold, // Жирный текст
                  ),
                ),
                Switch(
                  value: notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                  activeColor: Color(0xFFFFFFFF),
                  // Цвет при включении
                  activeTrackColor: Color(0xFF5F33E1),
                  // Трек при включении
                  inactiveTrackColor: Color(0xFFEEE9FF),
                  // Трек при выключении
                  inactiveThumbColor: Color(0xFF5F33E1),
                  // Шарик при выключении
                  splashRadius: 0.0,
                  // Убираем эффект нажатия
                  materialTapTargetSize: MaterialTapTargetSize
                      .shrinkWrap, // Уменьшаем высоту
                ),
              ],
            ),
            if (notificationsEnabled)
              Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  // Отступ сверху для выборщика времени
                  child: Column(
                      children: [
                        _buildTimePicker(),
                        const SizedBox(height: 8),

                        _buildDaysOfWeekCheckboxes(),
                      ]
                  )
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Поле для ввода часов
        Container(
          width: 80,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFFF8F9F9), // Фон поля
            borderRadius: BorderRadius.circular(8), // Скругленные углы
          ),
          child: TextFormField(
            textAlign: TextAlign.center,
            // Центрирование текста
            initialValue: selectedHour.toString().padLeft(2, '0'),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: InputBorder.none, // Убираем стандартную границу
            ),
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
            onChanged: (String value) {
              setState(() {
                selectedHour = int.tryParse(value) ?? selectedHour;
              });
            },
          ),
        ),
        Text(
          ' : ',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        // Поле для ввода минут
        Container(
          width: 80,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFFF8F9F9), // Фон поля
            borderRadius: BorderRadius.circular(8), // Скругленные углы
          ),
          child: TextFormField(
            textAlign: TextAlign.center,
            initialValue: selectedMinute.toString().padLeft(2, '0'),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: InputBorder.none, // Убираем стандартную границу
            ),
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
            onChanged: (String value) {
              setState(() {
                selectedMinute = int.tryParse(value) ?? selectedMinute;
              });
            },
          ),
        ),
        SizedBox(width: 16), // Отступ между полями и кнопкой "+"
        // Кнопка "+"
        GestureDetector(
          onTap: () {
            // Логика при нажатии на "+"
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color(0xFFEEE9FF), // Светлый фон вокруг "+"
              borderRadius: BorderRadius.circular(10), // Скругленные углы
            ),
            child: Icon(
              Icons.add, // Иконка "+"
              color: Color(0xFF5F33E1), // Фиолетовый цвет иконки
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  //Кнопка
  Widget _buildAddButton(String taskTitle) {
    return ElevatedButton(
      onPressed: () {
        _addHabit(taskTitle); // Передаем taskTitle в _addHabit
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5F33E1),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Center(
        child: Text(
          'Create an action',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }


  Future<void> _addHabit(String taskTitle) async {
    setState(() {
      // Валидация типа выполнения
      if (selectedType == -1) {
        typeError = 'Необходимо выбрать тип выполнения';
      } else {
        typeError = null;
      }

      // Валидация названия действия
      nameError = actionName.isEmpty || actionName.length < 2
          ? 'Имя должно содержать не менее 2 символов'
          : null;

      // Валидация дат
      if (startDate == null || endDate == null) {
        dateError = 'Выберите начальную и конечную дату';
      } else if (endDate!.isBefore(startDate!)) {
        dateError = 'Дата завершения не может быть раньше даты начала';
      } else {
        dateError = null;
      }

      // Валидация количества для выбранного типа
      if (selectedType == 1) {
        String quantityText = quantityController.text.trim();
        if (quantityText.isEmpty) {
          quantityError = 'Количество должно быть целым числом';
        } else {
          int? quantityValue = int.tryParse(quantityText);
          if (quantityValue == null) {
            quantityError = 'Количество должно быть целым числом';
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
          volumeError = 'Поля объема должны содержать допустимые числа';
        } else {
          volumeError = null;
        }
      }

      // Проверка на выбор дней при одинаковом начале и конце или меньшем периоде
      if (startDate != null && endDate != null) {
        final int periodLength = endDate!.difference(startDate!).inDays;

        if (periodLength <= 7) {
          bool invalidDaySelected = false;

          // Проверяем, что не выбраны дни за пределами допустимого диапазона
          for (int i = 0; i < 7; i++) {
            if (selectedDays[i] && !_isWithinDateRange(startDate!, endDate!, i)) {
              invalidDaySelected = true;
              break;
            }
          }

          if (invalidDaySelected) {
            periodError = 'Выбраны недопустимые дни для выбранного периода';
          } else {
            periodError = null;
          }
        }
      }

      // Если даты не выбраны
      if (startDate == null || endDate == null) {
        periodError = 'Необходимо выбрать даты начала и завершения';
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

      Map<String, dynamic> newHabit = {
        'name': actionName,
        'type': selectedType.toString(),
        'start_date': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : null,
        'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
        'quantity': selectedType == 1 ? quantity : null,
        'volume_per_press': selectedType == 2 ? volumePerPress : null,
        'volume_specified': selectedType == 2 ? volumeSpecified : null,
      };

      // Логика добавления привычки
      try {
        _showDeleteDialog(context, taskTitle, () {
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
