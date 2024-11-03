import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'notes.dart';
import '../main.dart';
import 'add.dart';
import 'stat_tabl.dart';
import 'archive.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';
import 'package:action_notes/Widgets/loggable_screen.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
class StatsPage extends StatefulWidget {
  final int sessionId;
  const StatsPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();
  String _selectedPeriod = tr('week');
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String? value;
  String? _selectedFilter;

  // Список задач (привычек)
  final List<Map<String, dynamic>> tasks = [];
  int? _currentSessionId;
  String _currentScreenName = "StatsPage";
  @override
  void initState() {
    super.initState();
    _updateDates();
    _loadTasks();
    _currentSessionId = widget.sessionId;
  }

  void _updateDates() {
    setState(() {
      if (_selectedPeriod == 'week'.tr()) {
        _startDate = _today.subtract(const Duration(days: 6));  // 7-дневный период
        _endDate = _today;
        _loadTasks();
      } else if (_selectedPeriod == 'two_weeks'.tr()) {
        _startDate = _today.subtract(const Duration(days: 13));  // 14-дневный период
        _endDate = _today;
        _loadTasks();
      } else if (_selectedPeriod == 'month'.tr()) {
        // Для расчета месяца учитываем текущий месяц и его количество дней
        _startDate = DateTime(_today.year, _today.month - 1, _today.day);  // Минус 1 месяц от текущей даты
        _endDate = _today;
        _loadTasks();
      } else if (_selectedPeriod == 'another_period'.tr()) {
        _loadTasks();
      }
    });
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


  // Загрузка данных о привычках
  Future<void> _loadTasks() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    // Приведение _startDate и _endDate к началу дня
    DateTime startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    DateTime endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);

    // Загружаем привычки
    final habits = await dbHelper.getHabitsForDateRange(
      DateFormat('yyyy-MM-dd').format(startDate),
      DateFormat('yyyy-MM-dd').format(endDate),
    );

    print('Loaded Habits: $habits');

    // Загружаем логи привычек
    final habitLogs = await dbHelper.getHabitLogsForDateRange(
      DateFormat('yyyy-MM-dd').format(startDate),
      DateFormat('yyyy-MM-dd').format(endDate),
    );

    print('Loaded Habit Logs: $habitLogs');

    setState(() {
      tasks.clear();

      for (var habit in habits) {
        // Количество дней в периоде
        int totalDays = endDate.difference(startDate).inDays + 1;

        // Если totalDays меньше или равно 0, продолжаем (избегаем ошибок с отрицательными значениями)
        if (totalDays <= 0) {
          print('Invalid totalDays: $totalDays');
          continue;
        }

        // Инициализация isCompleted как списка из false
        List<bool> isCompleted = List<bool>.filled(totalDays, false);

        // Заполняем isCompleted на основе логов
        for (var log in habitLogs) {
          if (log['habit_id'] == habit['id'] && log['status'] == 'completed') {
            DateTime logDate = DateTime.parse(log['date']).toLocal();
            logDate = DateTime(logDate.year, logDate.month, logDate.day);

            // Индекс дня относительно _startDate
            int dayIndex = logDate.difference(startDate).inDays;

            // Проверка на допустимость индекса
            if (dayIndex >= 0 && dayIndex < totalDays) {
              isCompleted[dayIndex] = true;
            } else {
              print('Invalid dayIndex: $dayIndex');
            }
          }
        }

        // Проверяем, что isCompleted заполнен
        print('isCompleted for task ${habit['name']}: $isCompleted');

        // Вычисляем количество завершённых дней
        int completedCount = isCompleted.where((completed) => completed).length;

        // Добавляем задачу в список с корректно инициализированным isCompleted
        tasks.add({
          'task': habit['name'],
          'completedCount': completedCount,
          'totalDays': totalDays,
          'isCompleted': List<bool>.from(isCompleted),
          'index': habit['id'],
        });

        print('Task Added: ${habit['name']}, Completed: $completedCount/$totalDays');
      }

      print('Final Tasks List: $tasks');
    });
    await dbHelper.logAction(
        _currentSessionId!,
        "Загрузка задач завершена на экране: $_currentScreenName. Итоговый список задач: $tasks"
    );
  }




  // Форматирование диапазона дат
  String _formatDateRange() {
    return '${DateFormat('MMM d', Localizations.localeOf(context).toString()).format(_startDate)} - ${DateFormat('MMM d', Localizations.localeOf(context).toString()).format(_endDate)}';
  }

  // Карточка с прогрессом выполнения привычки
  Widget _buildTaskCard(Map<String, dynamic> task) {
    List<bool> isCompleted = task['isCompleted'] ?? [];

    // Проверка длины списка
    print('Building card for task: ${task['task']} with isCompleted: $isCompleted');

    // Если isCompleted по-прежнему пустой, возвращаем заглушку
    if (isCompleted.isEmpty) {
      print('isCompleted is empty for task: ${task['task']}');
      return Card(
        child: Column(
          children: [
            Text(task['task']),
            Text('No completion data available'),  // Заглушка на случай отсутствия данных
          ],
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task['task'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                // Отображение звездочки при 100% выполнении
                if (task['completedCount'] == task['totalDays'])
                  const Icon(Icons.star, color: Color(0xFFFB6A37), size: 35),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFB6A37),
                  ),
                  child: Text(
                    '${task['completedCount']}/${task['totalDays']}', // Дробь выполненных дней
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildProgressBar(task['completedCount'], task['totalDays'], task['isCompleted']),
          ],
        ),
      ),
    );
  }


  Widget _buildProgressBar(int completed, int total, List<bool> isCompleted) {
    // Логика для разных состояний
    if (total <= 14) {
      // Для 14 и меньше элементов — прямоугольные, расположенные в 1 или 2 строки
      int maxItemsPerRow = total <= 7 ? total : (total / 1).ceil();
      int numberOfRows = total <= 7 ? 1 : 2;

      return Column(
        children: List.generate(numberOfRows, (rowIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(maxItemsPerRow, (index) {
              int currentIndex = rowIndex * maxItemsPerRow + index;
              if (currentIndex >= total) return Container();

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                  child: Container(
                    height: 15,
                    decoration: BoxDecoration(
                      color: isCompleted[currentIndex]
                          ? const Color(0xFF5F33E1)
                          : Colors.grey[300],
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      );
    } else if (total <= 30) {
      // Для 15-30 элементов — круги, расположенные в 2 строки
      int maxItemsPerRow = (total / 2).ceil();
      int numberOfRows = 2;

      return Column(
        children: List.generate(numberOfRows, (rowIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(maxItemsPerRow, (index) {
              int currentIndex = rowIndex * maxItemsPerRow + index;
              if (currentIndex >= total) return Container();

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: isCompleted[currentIndex]
                          ? const Color(0xFF5F33E1)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      );
    } else {
      // Для больше 30 элементов — круги в одной строке с возможностью прокрутки
      int maxItemsPerRow = (total / 2).ceil();
      int numberOfRows = 2;

      return Column(
        children: List.generate(numberOfRows, (rowIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(maxItemsPerRow, (index) {
              int currentIndex = rowIndex * maxItemsPerRow + index;
              if (currentIndex >= total) return Container();

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: isCompleted[currentIndex]
                          ? const Color(0xFF5F33E1)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F9),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('statistics'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  iconSize: 32,
                  icon: Image.asset('assets/images/Chart.png'),
                  onPressed: () async {
                   await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь нажал кнопку графики и перешел в ChartScreen из: $_currentScreenName"
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoggableScreen(
                          screenName: 'ChartScreen',
                          child: ChartScreen(
                            sessionId: _currentSessionId!, // Передаем sessionId в ChartScreen
                          ),
                          currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                        ),
                      ),
                    );

                  },
                ),
                IconButton(
                  iconSize: 32,
                  icon: Image.asset('assets/images/Folder.png'),
                  onPressed: () async {
                   await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь нажал кнопку архив и перешел в ArchivePage из: $_currentScreenName"
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoggableScreen(
                          screenName: 'ArchivePage',
                          child: ArchivePage(
                            sessionId: _currentSessionId!, // Передаем sessionId в ArchivePage
                          ),
                          currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBottomDateSelector(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskCard(task); // Отображаем каждую карточку привычки
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF8F9F9),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Панель выбора даты
  Widget _buildBottomDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Кнопка стрелка влево
              if (_selectedPeriod != tr('another_period')) // Проверяем выбранный период
                IconButton(
                  icon: Image.asset(
                    'assets/images/arr_left.png',
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () async {
                    await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь нажал на стрелку влево для изменения даты на экране: $_currentScreenName"
                    );
                    setState(() {
                      if (_startDate != null && _startDate!.subtract(Duration(days: 7)).isBefore(_today)) {
                        _startDate = _startDate!.subtract(Duration(days: 7));
                        _endDate = _endDate!.subtract(Duration(days: 7));
                      }
                      _loadTasks();
                    });
                  },
                ),
              Expanded(
                child: Center(
                  // Проверяем, выбран ли другой период
                  child: _selectedPeriod == tr('another_period')
                      ? Container() // Пустое пространство для "другого периода"
                      : Text(
                    _formatDateRange(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Кнопка стрелка вправо
              if (_selectedPeriod != tr('another_period')) // Проверяем выбранный период
                IconButton(
                  icon: Image.asset(
                    'assets/images/arr_right.png',
                    width: 20,
                    height: 20,
                    color: (_endDate != null && _endDate!.add(Duration(days: 7)).isBefore(DateTime.now().add(Duration(days: 1))))
                        ? const Color(0xFF5F33E1)
                        : const Color(0x4D5F33E1),
                  ),
                  onPressed: (_endDate != null && _endDate!.add(Duration(days: 7)).isBefore(DateTime.now().add(Duration(days: 1))))
                      ? () async {
                    await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь нажал на стрелку вправо для изменения даты на экране: $_currentScreenName"
                    );
                    setState(() {
                      _startDate = _startDate!.add(Duration(days: 7));
                      _endDate = _endDate!.add(Duration(days: 7));
                      _loadTasks();
                    });
                  }
                      : null,
                ),
              // Кнопка фильтра

                IconButton(
                  icon: Image.asset('assets/images/Filter.png', width: 24, height: 24),
                  onPressed: () async {
                    _showPopupMenu(context);
                    // Логирование действия
                    await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь открыл меню фильтров на экране: $_currentScreenName"
                    );
                  },
                ),
              // Выпадающий список
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: _selectedPeriod, // Текущее выбранное значение
                    isDense: true,
                    items: <String>[
                      tr('week'),
                      tr('two_weeks'),
                      tr('month'),
                      tr('another_period')
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0), // Уменьшение высоты элемента
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: _selectedPeriod == value ? Color(0xFF5F33E1) : Colors.black, // Цвет текста в зависимости от выбора
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPeriod = newValue!; // Обновляем выбранное значение
                        _updateDates();
                      });
                        DatabaseHelper.instance.logAction(
                          _currentSessionId!,
                          "Пользователь изменил период на $_selectedPeriod из: $_currentScreenName"
                      );
                    },
                    menuItemStyleData: const MenuItemStyleData(
                      height: 30, // Устанавливаем высоту элемента
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        color: Colors.white, // Цвет фона
                        borderRadius: BorderRadius.circular(8), // Радиус границ
                      ),
                    ),
                    iconStyleData: IconStyleData(
                      icon: Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: Image.asset(
                          'assets/images/arr_vn.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return <String>[
                        tr('week'),
                        tr('two_weeks'),
                        tr('month'),
                        tr('another_period')
                      ].map<Widget>((String value) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0.0),
                          child: Text(
                            value,
                            style: TextStyle(
                              color: _selectedPeriod == value ? Color(0xFF5F33E1) : Colors.black, // Цвет для выбранного элемента
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ],
      ),
          const SizedBox(height: 3),
          // Логика для "Неделя"
          if (_selectedPeriod == tr('week'))
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _generateDaysForPeriod(_startDate!).map((day) {
                int completedHabits = _getCompletedHabitsForDate(day);

                return Container(
                  width: 45,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('dd.MM').format(day),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedHabits',
                        style: const TextStyle(
                          color: Color(0xFF5F33E1),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 3),
          // Логика для "Другого периода"
          if (_selectedPeriod == tr('another_period')) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await DatabaseHelper.instance.logAction(
                          _currentSessionId!,
                          "Пользователь нажал выбрать начальную дату в режиме 'Другой период' на экране: $_currentScreenName"
                      );
                      _showCalendarDialog(isStartDate: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _startDate != null
                                ? DateFormat('dd.MM').format(_startDate!)
                                : 'On',
                            style: TextStyle(color: _startDate == null ? Colors.black54 : Colors.black),
                          ),
                          Image.asset('assets/images/Calendar.png', width: 20, height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await DatabaseHelper.instance.logAction(
                          _currentSessionId!,
                          "Пользователь нажал выбрать конечную дату в режиме 'Другой период' на экране: $_currentScreenName"
                      );
                      _showCalendarDialog(isStartDate: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _endDate != null
                                ? DateFormat('dd.MM').format(_endDate!)
                                : 'To',
                            style: TextStyle(color: _endDate == null ? Colors.black54 : Colors.black),
                          ),
                          Image.asset('assets/images/Calendar.png', width: 20, height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }





  int _getCompletedHabitsForDate(DateTime day) {
    String dayString = DateFormat('yyyy-MM-dd').format(day);
    int completedCount = 0;

    for (var task in tasks) {
      int dayIndex = day.difference(_startDate).inDays;
      if (dayIndex >= 0 && dayIndex < task['isCompleted'].length && task['isCompleted'][dayIndex]) {
        completedCount++;
      }
    }

    return completedCount;
  }
  List<DateTime> _generateDaysForPeriod(DateTime startDate) {
    return List.generate(7, (index) => startDate.add(Duration(days: index)));
  }

  void _showCalendarDialog({required bool isStartDate}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      barrierDismissible: true,
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
                color: Colors.white,
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
                      todayTextStyle: const TextStyle(
                        color: Colors.black,
                      ),
                      outsideDaysVisible: false,
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
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDate, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (selectedDay.isBefore(_today)) {
                        setState(() {
                          _selectedDate = selectedDay;
                          if (isStartDate) {
                            _startDate = selectedDay;
                          } else {
                            _endDate = selectedDay;
                          }
                           DatabaseHelper.instance.logAction(
                              _currentSessionId!,
                              "Пользователь выбрал ${isStartDate ? 'начальную' : 'конечную'} дату ${DateFormat('dd.MM.yyyy').format(selectedDay)} на экране: $_currentScreenName"
                          );
                          _loadTasks();
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


  void _showPopupMenu(BuildContext context) {
    showMenu(
      constraints: BoxConstraints.tightFor(
        width: context.locale.languageCode == 'en' ? 115 : 160, // Используем locale от Easy Localization
      ),
      context: context,
      position: RelativeRect.fromLTRB(100, 170, 50, 0), // Позиция попапа
      items: [
        PopupMenuItem<String>(
          value: 'Ascending',
          height: 25, // Фиксированная высота
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8), // Уменьшенные отступы
            child: Text(
              tr('ascending'),
              style: TextStyle(
                color: _selectedFilter == 'Ascending' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight:  FontWeight.bold,
                fontSize: 12, // Уменьшенный размер шрифта
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Descending',
          height: 25, // Фиксированная высота
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8), // Уменьшенные отступы
            child: Text(
              tr('descending'),
              style: TextStyle(
                color: _selectedFilter == 'Descending' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight: FontWeight.bold ,
                fontSize: 12, // Уменьшенный размер шрифта
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Custom',
          height: 25, // Фиксированная высота
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8), // Уменьшенные отступы
            child: Text(
              tr('custom'),
              style: TextStyle(
                color: _selectedFilter == 'Custom' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight: FontWeight.bold ,
                fontSize: 12, // Уменьшенный размер шрифта
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
          _updateTasks(); // Обновляем задачи при изменении фильтра
        });
         DatabaseHelper.instance.logAction(
            _currentSessionId!,
            "Пользователь выбрал фильтр: $_selectedFilter на экране: $_currentScreenName"
        );
      }
    });
  }


  Future<void> _updateTasks() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    // Приведение _startDate и _endDate к началу дня
    DateTime startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    DateTime endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);

    final habits = await dbHelper.getHabitsForDateRange(
      DateFormat('yyyy-MM-dd').format(startDate),
      DateFormat('yyyy-MM-dd').format(endDate),
    );

    final habitLogs = await dbHelper.getHabitLogsForDateRange(
      DateFormat('yyyy-MM-dd').format(startDate),
      DateFormat('yyyy-MM-dd').format(endDate),
    );

    setState(() {
      tasks.clear();

      // Используем Map для устранения дублирования
      final taskMap = <int, Map<String, dynamic>>{};

      for (var habit in habits) {
        int totalDays = endDate.difference(startDate).inDays + 1;

        // Приведение logDate к началу дня для корректного сравнения
        List<bool> isCompleted = List<bool>.filled(totalDays, false);

        for (var log in habitLogs) {
          if (log['habit_id'] == habit['id'] && log['status'] == 'completed') {
            DateTime logDate = DateTime.parse(log['date']).toLocal();
            // Приведение logDate к началу дня для корректного расчёта
            logDate = DateTime(logDate.year, logDate.month, logDate.day);

            int dayIndex = logDate.difference(startDate).inDays;
            if (dayIndex >= 0 && dayIndex < totalDays) {
              isCompleted[dayIndex] = true;
            }
          }
        }

        int completedCount = isCompleted.where((completed) => completed).length;

        // Убеждаемся, что задача добавляется только один раз
        if (!taskMap.containsKey(habit['id'])) {
          taskMap[habit['id']] = {
            'task': habit['name'],
            'completedCount': completedCount,
            'totalDays': totalDays,
            'isCompleted': List<bool>.from(isCompleted),
            'index': habit['id'],
          };
        }
      }

      // Добавляем задачи без дублирования
      tasks.addAll(taskMap.values);

      // Применяем сортировку в зависимости от выбранного фильтра
      if (_selectedFilter == 'Ascending') {
        tasks.sort((a, b) => a['completedCount'].compareTo(b['completedCount']));
      } else if (_selectedFilter == 'Descending') {
        tasks.sort((a, b) => b['completedCount'].compareTo(a['completedCount']));
      } else if (_selectedFilter == 'Custom') {
        tasks.sort((a, b) => a['task'].compareTo(b['task']));
      }

      print('Final Tasks List: $tasks');
    });
  }

  // Нижняя навигационная панель
  Widget _buildBottomNavigationBar() {
    return Container(
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
          _buildNavItem(3, 'assets/images/Calendar.png', isSelected: true),
          _buildNavItem(4, 'assets/images/Setting.png'),
        ],
      ),
    );
  }

  // Нижняя навигационная кнопка
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


}
