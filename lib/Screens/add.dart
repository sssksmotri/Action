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
  TextEditingController quantityController = TextEditingController();
  TextEditingController volumePerPressController = TextEditingController();
  TextEditingController volumeSpecifiedController = TextEditingController();
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
                      backgroundColor: const Color(0xFFEEE9FF),
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
              _buildActionNameCard(), // Карточка с названием действия
              const SizedBox(height: 24),
              _buildTypeSelectionCard(), // Карточка с типом выполнения
              const SizedBox(height: 24),
              _buildDateSelectionCard(), // Карточка с выбором дат
              const SizedBox(height: 24),
              _buildDaysAndNotifications(), // Чекбоксы с днями и тумблер для уведомлений
              const SizedBox(height: 24),
              _buildNotificationToggle(),
              const SizedBox(height: 24),
              _buildAddButton(taskTitle), // Кнопка создания действия
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

  // Карточка с названием действия
  Widget _buildActionNameCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Белая карточка
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
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xFFF8F9F9), // Серый цвет текстбокса
          labelText: 'Name of action', // Серый заголовок
          labelStyle: const TextStyle(color: Colors.grey), // Серый цвет текста
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Скругленные углы для текстбокса
            borderSide: BorderSide.none, // Без границы
          ),
        ),
        onChanged: (value) {
          setState(() {
            actionName = value;
          });
        },
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
          if (selectedType == 1) _buildTextField('Specify the quantity'), // Одно поле для второго варианта
          if (selectedType == 2) ...[
            _buildTextField('Specify the quantity'), // Первое поле для третьего варианта
            const SizedBox(height: 16),
            _buildTextField('What volume does one press equal?'), // Второе поле для третьего варианта
          ],
        ],
      ),
    );
  }
  // Круглый чекбокс для типа выполнения
// Круглый чекбокс с отступами
  Widget _buildCustomCheckbox(String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = index; // Только один элемент может быть выбран
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
                color: selectedType == index ? const Color(0xFF5F33E1) : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              // Внутренний контейнер для создания эффекта отступов
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selectedType == index ? 14 : 0, // Ширина внутреннего контейнера
                height: selectedType == index ? 14 : 0, // Высота внутреннего контейнера
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedType == index ? const Color(0xFF5F33E1) : Colors.transparent,
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

  Widget _buildTextField(String label) {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200], // Серый цвет фона
        labelText: label, // Серый заголовок
        labelStyle: const TextStyle(color: Colors.grey), // Цвет текста
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Скругленные углы
          borderSide: BorderSide.none, // Без границ
        ),
      ),
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
                    return isSameDay(day, initialDate); // Проверяем, является ли день выбранным
                  },
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
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF5F33E1)),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF5F33E1)),
                  ),
                  daysOfWeekVisible: true,
                  onDaySelected: (selectedDay, focusedDay) {
                    // Выбор даты
                    onDateSelected(selectedDay); // Передаем выбранную дату
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

  // Метод для построения селектора даты
  Widget _buildDatePicker(String label, String value, ValueChanged<DateTime?> onDatePicked) {
    return GestureDetector(
      onTap: () {
        // Вызываем диалог выбора даты
        DateTime initialDate = label == 'Start Date' ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now());
        _showCalendarDialog(initialDate, (selectedDate) {
          onDatePicked(selectedDate);
        });
      },
      child: Container(
        width: 130, // Ширина контейнера
        height: 60, // Высота контейнера
        padding: const EdgeInsets.symmetric(horizontal: 8), // Отступы по горизонтали
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9F9), // Цвет фона поля даты
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Выравнивание по краям
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            Image.asset(
              'assets/images/Calendar.png', // Используем изображение календаря
              width: 24, // Ширина изображения
              height: 24, // Высота изображения
              color: const Color(0xFF5F33E1), // Устанавливаем цвет (если нужно)
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
        crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по левому краю
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание заголовка по левому краю
                  children: [
                    const Text(
                      'Start Date', // Заголовок для поля начальной даты
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8), // Отступ между заголовком и полем
                    _buildDatePicker(
                      'Start Date',
                      startDate != null ? DateFormat('dd.MM.yy').format(startDate!) : 'From',
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
                  crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание заголовка по левому краю
                  children: [
                    const Text(
                      'End Date', // Заголовок для поля конечной даты
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8), // Отступ между заголовком и полем
                    _buildDatePicker(
                      'End Date',
                      endDate != null ? DateFormat('dd.MM.yy').format(endDate!) : 'To',
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
                  days[index], // Текст сверху чекбокса
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF212121), // Текстовые надписи серого цвета
                  ),
                ),
                const SizedBox(height: 8), // Отступ между текстом и чекбоксом
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDays[index] = !selectedDays[index]; // Переключение состояния
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selectedDays[index]
                          ? const Color(0xFF5F33E1) // Фиолетовая заливка если выбрано
                          : Colors.transparent, // Прозрачная заливка если не выбрано
                      borderRadius: BorderRadius.circular(5), // Закругление рамки
                      border: Border.all(
                        color: selectedDays[index]
                            ? const Color(0xFF5F33E1) // Фиолетовая рамка если выбрано
                            : Colors.grey, // Серая рамка если не выбрано
                        width: 1, // Тонкая рамка
                      ),
                    ),
                    child: selectedDays[index]
                        ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white, // Галочка белого цвета на фиолетовом фоне
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
                  activeColor: Color(0xFFFFFFFF), // Цвет при включении
                  activeTrackColor: Color(0xFF5F33E1), // Трек при включении
                  inactiveTrackColor: Color(0xFFEEE9FF), // Трек при выключении
                  inactiveThumbColor: Color(0xFF5F33E1), // Шарик при выключении
                  splashRadius: 0.0, // Убираем эффект нажатия
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Уменьшаем высоту
                ),
              ],
            ),
            if (notificationsEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 16.0), // Отступ сверху для выборщика времени
                  child:Column(
                children:[
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
            textAlign: TextAlign.center, // Центрирование текста
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
    if (actionName.isNotEmpty) {
      // Получаем значения из новых текстовых полей
      int? quantity = int.tryParse(quantityController.text); // Получаем количество
      String volumePerPress = volumePerPressController.text; // Объем за один раз (в строковом формате)
      String volumeSpecified = volumeSpecifiedController.text; // Указанный объем (в строковом формате)

      Map<String, dynamic> newHabit = {
        'name': actionName,
        'type': selectedType.toString(),
        'start_date': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
        'days_of_week': selectedDays.map((isSelected) => isSelected ? 1 : 0).toList().join(','),
        'notifications_enabled': 0,
        // Если тип не "Выполнить определенный объем", quantity не добавляем
        'quantity': (selectedType != "Perform a certain volume") ? quantity ?? 0 : null,
        'volume_per_press': (selectedType == "Perform a certain volume") ? null : volumePerPress,
        'volume_specified': (selectedType == "Perform a certain volume") ? volumeSpecified : null,
        'archived': 0
      };

      try {
        int id = await DatabaseHelper.instance.insertHabit(newHabit);
        print('Inserted habit with id: $id');

        _showDeleteDialog(context, taskTitle, () {
          // Действия после подтверждения диалога
        });
      } catch (e) {
        print('Error inserting habit: $e');
      }
    } else {
      print('Habit name cannot be empty!');
    }
  }
}