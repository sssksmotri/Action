import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'main.dart';
import 'add.dart';
import 'stat.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

class ChartScreen extends StatefulWidget {
  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _selectedIndex = 0;

  int _selectedChart = 0; // 0 - BarChart, 1 - LineChart
  int _selectedTab = 0; // 0 - W, 1 - 2W, 2 - M
  bool _showPercent = false; // Переключение между количеством и процентами
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
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();
  List<_ChartData> data = [
    _ChartData('Mon', 8, 80),
    _ChartData('Tue', 10, 100),
    _ChartData('Wed', 14, 140),
    _ChartData('Thu', 15, 150),
    _ChartData('Fri', 13, 130),
    _ChartData('Sat', 10, 100),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Chart',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 32, // Ширина контейнера
                  height: 32, // Высота контейнера
                  decoration: BoxDecoration(
                    color: Color(0xFF5F33E1), // Цвет фона
                    shape: BoxShape.circle, // Круглая форма
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 3,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(4.0), // Отступы вокруг изображения
                      child: Image.asset(
                        'assets/images/Chart2.png',
                        fit: BoxFit.cover, // Масштабируем изображение
                      ),
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 32, // Увеличиваем размер иконки
                  padding: EdgeInsets.zero, // Убираем отступы
                  icon: Image.asset(
                    'assets/images/Folder.png', // Укажите путь к изображению
                    width: 32, // Ширина иконки
                    height: 32, // Высота иконки
                  ),
                  onPressed: () {
                  },
                ),


              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          _buildChartCard(), // Вызов карточки графика
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _selectedChart == 0
                  ? SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData sales, _) => sales.day,
                    yValueMapper: (_ChartData sales, _) =>
                    _showPercent ? sales.percent : sales.quantity,
                    color: Color(0xFF5F33E1),
                    borderRadius: BorderRadius.circular(5),
                  )
                ],
              )
                  : SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  LineSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData sales, _) => sales.day,
                    yValueMapper: (_ChartData sales, _) =>
                    _showPercent ? sales.percent : sales.quantity,
                    color: Color(0xFF5F33E1),
                    width: 2,
                  )
                ],
              ),
            ),
          ),

          // Выбор даты
          _buildBottomDateSelector(),
        ],
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
      ),
    );
  }


  Widget _buildChartCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Первая строка: текст "Chart" и кнопки для выбора графиков
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Изображение, отображающее выбранный график
              Text(
                'Chart',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Текст "Chart"

                  Row(
                    children: [
                      // Кнопка для первого графика
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedChart = 0; // Гистограмма
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedChart == 0 ? Color(0xFF5F33E1) : Colors.transparent, // Цвет фона
                            borderRadius: BorderRadius.circular(8), // Закругление углов
                            border: Border.all(
                              color: _selectedChart == 0 ? Color(0xFF5F33E1) : Color(0xFF5F33E1), // Цвет рамки
                            ),
                          ),
                          padding: EdgeInsets.all(8), // Отступ внутри контейнера
                          child: Image.asset(
                            _selectedChart == 0 ? 'assets/images/Chart2.png' : 'assets/images/Chart.png', // Изображение для первого графика
                            width: 30, // Ширина кнопки
                            height: 30, // Высота кнопки
                          ),
                        ),
                      ),
                      SizedBox(width: 8), // Отступ между кнопками
                      // Кнопка для второго графика
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedChart = 1; // Линейный график
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedChart == 1 ? Color(0xFF5F33E1) : Colors.transparent, // Цвет фона
                            borderRadius: BorderRadius.circular(8), // Закругление углов
                            border: Border.all(
                              color: _selectedChart == 1 ? Color(0xFF5F33E1) : Colors.grey, // Цвет рамки
                            ),
                          ),
                          padding: EdgeInsets.all(8), // Отступ внутри контейнера
                          child: Image.asset(
                            _selectedChart == 1 ? 'assets/images/Chart1.png' : 'assets/images/Chart3.png', // Изображение для второго графика
                            width: 30, // Ширина кнопки
                            height: 30, // Высота кнопки
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16), // Отступ между строками

          // Вторая строка: кнопки для изменения графиков (количество/процент)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(

                    backgroundColor: !_showPercent ? Color(0xFF5F33E1) : Colors.white, // Закрашенная при выборе, иначе белая
                    shadowColor: Colors.transparent, // Убираем тень
                  ),
                  onPressed: () {
                    setState(() {
                      _showPercent = false; // Показать количество
                    });
                  },
                  child: Text(
                    'Quantity', // Кнопка для количества
                    style: TextStyle(
                      fontSize: 18, // Увеличенный размер шрифта
                      fontWeight: FontWeight.bold, // Жирный шрифт
                      color: !_showPercent ? Colors.white : Color(0xFF5F33E1), // Цвет текста в зависимости от выбора
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8), // Отступ между кнопками
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showPercent ? Color(0xFF5F33E1) : Colors.white,
                    shadowColor: Colors.transparent, // Убираем тень
                  ),
                  onPressed: () {
                    setState(() {
                      _showPercent = true; // Показать процент
                    });
                  },
                  child: Text(
                    'Percent', // Кнопка для процентов
                    style: TextStyle(
                      fontSize: 18, // Увеличенный размер шрифта
                      fontWeight: FontWeight.bold, // Жирный шрифт
                      color: _showPercent ? Colors.white : Color(0xFF5F33E1), // Цвет текста в зависимости от выбора
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildBottomDateSelector() {
    // Получаем начало и конец недели
    DateTime startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)); // Понедельник
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6)); // Воскресенье

    // Форматируем даты
    String formattedStartDate = DateFormat('MMMM, d', Localizations.localeOf(context).toString()).format(startOfWeek);
    String formattedEndDate = DateFormat('MMMM, d', Localizations.localeOf(context).toString()).format(endOfWeek);

    String formattedDateRange = '$formattedStartDate - $formattedEndDate'; // Форматированный диапазон

    return GestureDetector(
      onTap: () {
        _showCalendarDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Центрируем все элементы
          children: [
            // Левая стрелка
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF5F33E1)),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 7)); // Уменьшаем на неделю
                });
              },
            ),

            // Дата
            Text(
              formattedDateRange,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Правая стрелка
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF5F33E1)),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 7)); // Увеличиваем на неделю
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Функция для показа календаря в виде прозрачного окна
  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              bottom: 90, // Отступ выше BottomNavigationBar
              left: 10, // Отступы для более узкого окна
              right: 10,
              child: Opacity(
                opacity: 1, // Делаем окно полупрозрачным
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
                            leftChevronIcon: const Icon(
                                Icons.chevron_left, color: Color(0xFF5F33E1)),
                            rightChevronIcon: const Icon(
                                Icons.chevron_right, color: Color(0xFF5F33E1)),
                          ),
                          daysOfWeekVisible: true,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDate, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (selectedDay.isBefore(_today)) {
                              setState(() {
                                _selectedDate = selectedDay;
                              });
                              // Закрываем диалог сразу после выбора даты
                              Navigator.pop(context);
                            }
                          },
                          enabledDayPredicate: (day) {
                            return day.isBefore(
                                _today); // Блокируем завтрашние дни
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
}

class _ChartData {
  _ChartData(this.day, this.quantity, this.percent);
  final String day;
  final double quantity;
  final double percent;
}
