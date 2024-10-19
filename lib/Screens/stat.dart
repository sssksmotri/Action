import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'main.dart';
import 'add.dart';
import 'stat_tabl.dart';
import 'archive.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:table_calendar/table_calendar.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();
  String _selectedPeriod = 'Week';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String? value;
  String? _selectedFilter;

  // Список задач (привычек)
  final List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _updateDates();
    _loadTasks();
  }

  void _updateDates() {
    setState(() {
      if (_selectedPeriod == 'Week') {
        _startDate = _today.subtract(const Duration(days: 6));  // 7-дневный период
        _endDate = _today;
        _loadTasks();
      } else if (_selectedPeriod == '2 weeks') {
        _startDate = _today.subtract(const Duration(days: 13));  // 14-дневный период
        _endDate = _today;
        _loadTasks();
      } else if (_selectedPeriod == 'Month') {
        // Для расчета месяца учитываем текущий месяц и его количество дней
        _startDate = DateTime(_today.year, _today.month - 1, _today.day);  // Минус 1 месяц от текущей даты
        _endDate = _today;
        _loadTasks();
      } else if (_selectedPeriod == 'Another Period') {
        _loadTasks();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
    }
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesPage()));
    }
    if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
    }
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddActionPage()));
    }
    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsPage()));
    }
  }

  // Загрузка данных о привычках
  Future<void> _loadTasks() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    final habits = await dbHelper.getHabitsForDateRange(
      DateFormat('yyyy-MM-dd').format(_startDate),
      DateFormat('yyyy-MM-dd').format(_endDate),
    );

    final habitLogs = await dbHelper.getHabitLogsForDateRange(
      DateFormat('yyyy-MM-dd').format(_startDate),
      DateFormat('yyyy-MM-dd').format(_endDate),
    );

    setState(() {
      tasks.clear();
      for (var habit in habits) {
        int completedCount = habitLogs.where((log) => log['habit_id'] == habit['id']).length;
        int totalDays = _endDate.difference(_startDate).inDays + 1;

        tasks.add({
          'task': habit['name'],
          'completedCount': completedCount,
          'totalDays': totalDays,
          'index': habit['id'],
        });
      }
    });
  }

  // Форматирование диапазона дат
  String _formatDateRange() {
    return '${DateFormat('MMM d', Localizations.localeOf(context).toString()).format(_startDate)} - ${DateFormat('MMM d', Localizations.localeOf(context).toString()).format(_endDate)}';
  }

  // Карточка с прогрессом выполнения привычки
  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5,
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
            _buildProgressBar(task['completedCount'], task['totalDays']),
          ],
        ),
      ),
    );
  }

  // Прогресс-бар выполнения привычки (продолговатый вместо кругов)
  Widget _buildProgressBar(int completed, int total) {
    // Рассчитываем максимальное количество элементов в строке и количество строк
    int maxItemsPerRow;
    int numberOfRows;

    if (total <= 7) {
      maxItemsPerRow = total;  // Все элементы в одну строку, если элементов 7 или меньше
      numberOfRows = 1;
    } else if (total <= 14) {
      maxItemsPerRow = (total / 2).ceil();  // Для 14 дней делим на 2 строки по 7 элементов
      numberOfRows = 2;  // Две строки для 14 дней
    } else if (total <= 30) {
      maxItemsPerRow = (total / 2).ceil();  // Для 15-30 дней делим на 2 строки
      numberOfRows = 2;  // Две строки для 15-30 дней
    } else {
      maxItemsPerRow = (total / 3).ceil();  // Элементы распределяются на 3 строки для 30+
      numberOfRows = 3;  // Три строки для 30+ дней
    }

    // Рассчитываем количество заполненных точек
    int filledDots = completed; // Используем просто количество завершенных дней

    return Column(
      children: List.generate(numberOfRows, (rowIndex) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(maxItemsPerRow, (index) {
            int currentIndex = rowIndex * maxItemsPerRow + index;  // Рассчитываем текущий индекс элемента
            if (currentIndex >= total) return Container();  // Если индекс превышает общее число элементов, возвращаем пустое место

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),  // Отступы между элементами
              child: Container(
                width: total > 14 ? 18 : 40,  // Уменьшаем шарики для 14+ дней
                height: total > 14 ? 18 : 15,  // Одинаковая высота для всех элементов
                decoration: BoxDecoration(
                  color: currentIndex < filledDots ? Color(0xFF5F33E1) : Colors.grey[300],  // Цвет прогресса
                  shape: total > 14 ? BoxShape.circle : BoxShape.rectangle,  // Круглые элементы для 15+ дней, прямоугольные для 14 и меньше
                  borderRadius: total > 14 ? null : BorderRadius.circular(10),  // Закругленные углы для прямоугольных элементов
                ),
              ),
            );
          }),
        );
      }),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  iconSize: 32,
                  icon: Image.asset('assets/images/Chart.png'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen()));
                  },
                ),
                IconButton(
                  iconSize: 32,
                  icon: Image.asset('assets/images/Folder.png'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ArchivePage()));
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
      backgroundColor: Colors.white,
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
        boxShadow: const [
          BoxShadow(color: Colors.grey, blurRadius: 1, spreadRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Левая стрелка
              Container(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left,  color: Color(0xFF5F33E1)),
                  onPressed: () {
                    setState(() {
                      if (_startDate != null && _startDate!.subtract(Duration(days: 7)).isBefore(_today)) {
                        _startDate = _startDate!.subtract(Duration(days: 7));
                        _endDate = _endDate!.subtract(Duration(days: 7));
                      }
                    });
                  },
                ),
              ),

              // Текущий диапазон дат
              Expanded(
                child: Center(
                  child: Text(
                    _formatDateRange(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Правая стрелка
              Container(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF5F33E1)),
                  onPressed: () {
                    setState(() {
                      if (_endDate != null && _endDate!.add(Duration(days: 7)).isBefore(DateTime.now().add(Duration(days: 1)))) {
                        _startDate = _startDate!.add(Duration(days: 7));
                        _endDate = _endDate!.add(Duration(days: 7));
                      }
                    });
                  },
                ),
              ),

              // Кнопка фильтра
              Container(
                width: 40,
                child: IconButton(
                  icon: Image.asset('assets/images/Filter.png', width: 24, height: 24),
                  onPressed: () => _showPopupMenu(context), // Вызов метода при нажатии
                ),
              ),

              // Выпадающий список для выбора периода
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  items: <String>['Week', '2 weeks', 'Month', 'Another Period']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF5F33E1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPeriod = newValue!;
                      _updateDates(); // Обновляем даты при изменении периода
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF5F33E1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Добавьте здесь логику для "Another Period"
          if (_selectedPeriod == 'Another Period') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Показываем календарь для начальной даты
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
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Показываем календарь для конечной даты
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
          ],
        ],
      ),
    );
  }


  void _showCalendarDialog({required bool isStartDate}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              bottom: 90,
              left: 10,
              right: 10,
              child: Opacity(
                opacity: 1,
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2010, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: _selectedDate,
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
                            leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF5F33E1)),
                            rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF5F33E1)),
                          ),
                          daysOfWeekVisible: true,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDate, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (selectedDay.isBefore(_today)) {
                              setState(() {
                                _selectedDate = selectedDay;

                                if (isStartDate) {
                                  _startDate = selectedDay; // Устанавливаем начальную дату
                                } else {
                                  _endDate = selectedDay; // Устанавливаем конечную дату
                                }

                                // Здесь вы можете обновить диапазон дат или выполнить другие действия
                                _loadTasks(); // Обновляем данные графика
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
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPopupMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 50, 0), // Позиция попапа
      items: [
        PopupMenuItem<String>(
          value: 'Ascending',
          child: Container(
            padding: const EdgeInsets.all(8), // Отступы для удобства
            child: Text(
              'Ascending',
              style: TextStyle(
                color: _selectedFilter == 'Ascending' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight: _selectedFilter == 'Ascending' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Descending',
          child: Container(
            padding: const EdgeInsets.all(8), // Отступы для удобства
            child: Text(
              'Descending',
              style: TextStyle(
                color: _selectedFilter == 'Descending' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight: _selectedFilter == 'Descending' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Custom',
          child: Container(
            padding: const EdgeInsets.all(8), // Отступы для удобства
            child: Text(
              'Custom',
              style: TextStyle(
                color: _selectedFilter == 'Custom' ? Color(0xFF5F33E1) : Colors.black,
                fontWeight: _selectedFilter == 'Custom' ? FontWeight.bold : FontWeight.normal,
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
          print('Выбран фильтр: $_selectedFilter');
        });
      }
    });
  }

  Future<void> _updateTasks() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    final habits = await dbHelper.getHabitsForDateRange(
      DateFormat('yyyy-MM-dd').format(_startDate),
      DateFormat('yyyy-MM-dd').format(_endDate),
    );

    final habitLogs = await dbHelper.getHabitLogsForDateRange(
      DateFormat('yyyy-MM-dd').format(_startDate),
      DateFormat('yyyy-MM-dd').format(_endDate),
    );

    setState(() {
      tasks.clear();
      for (var habit in habits) {
        int completedCount = habitLogs.where((log) => log['habit_id'] == habit['id']).length;
        int totalDays = _endDate.difference(_startDate).inDays + 1;

        tasks.add({
          'task': habit['name'],
          'completedCount': completedCount,
          'totalDays': totalDays,
          'index': habit['id'],
        });
      }

      // Применяем сортировку в зависимости от выбранного фильтра
      if (_selectedFilter == 'Ascending') {
        tasks.sort((a, b) => a['completedCount'].compareTo(b['completedCount'])); // Сортировка по возрастанию
      } else if (_selectedFilter == 'Descending') {
        tasks.sort((a, b) => b['completedCount'].compareTo(a['completedCount'])); // Сортировка по убыванию
      } else if (_selectedFilter == 'Custom') {
        // Пример пользовательской сортировки: сортировка по названию задачи
        tasks.sort((a, b) => a['task'].compareTo(b['task'])); // Сортировка по имени задачи
      }
    });
  }




  // Нижняя навигационная панель
  Widget _buildBottomNavigationBar() {
    return Container(
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

  // Выбор периода (всплывающее меню)
  void _showPeriodSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('Week'),
                onTap: () {
                  setState(() {
                    _selectedPeriod = 'Week';
                    _updateDates();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Two weeks'),
                onTap: () {
                  setState(() {
                    _selectedPeriod = '2 weeks';
                    _updateDates();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Month'),
                onTap: () {
                  setState(() {
                    _selectedPeriod = 'Month';
                    _updateDates();
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
