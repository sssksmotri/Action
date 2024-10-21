import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:action_notes/Screens/archive.dart';
import 'package:action_notes/main.dart';
import 'package:action_notes/Screens/notes.dart';
import 'package:action_notes/Screens/settings_screen.dart';
import 'package:action_notes/Screens/add.dart';
import 'package:action_notes/Screens/stat.dart';
import 'package:easy_localization/easy_localization.dart';
class ChartScreen extends StatefulWidget {
  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _selectedChart = 0; // 0 - BarChart, 1 - LineChart
  int _selectedTab = 0; // 0 - Неделя, 1 - 2 недели, 2 - Месяц
  bool _showPercent = false; // Переключение между количеством и процентами
  DateTime _selectedDate = DateTime.now(); // Объявление переменной
  DateTime _today = DateTime.now(); // Объявление переменной для ограничения выбора дат
  int _selectedIndex = 0;
  DateTime _selectedDateRangeStart = DateTime.now().subtract(Duration(days: 7)); // Инициализация начальной даты на 7 дней раньше
  DateTime _selectedDateRangeEnd = DateTime.now(); // Инициализация конечной даты
  late TrackballBehavior _trackballBehavior;
  List<_ChartData> data = [];
  List<_ChartData> weekData = [];

  List<_ChartData> twoWeeksData = [];

  List<_ChartData> monthData = [];


  @override
  void initState() {
    super.initState();
    data = weekData; // По умолчанию показываем данные за неделю
    loadChartData();
    _trackballBehavior = TrackballBehavior(
        enable: true, // Включаем trackball
        activationMode: ActivationMode.singleTap, // Режим активации при одиночном нажатии
        tooltipSettings: InteractiveTooltip(
        enable: true, // Включаем отображение всплывающей подсказки
        color: Colors.black,
        format: _showPercent ? 'День: point.x\nПроцент: point.y%' : 'День: point.x\nВыполнено: point.y',
        ),
    );
  }

  void loadChartData() async {
    String startDate = DateFormat('yyyy-MM-dd').format(_selectedDateRangeStart);
    String endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRangeEnd);
    data = await getDailyHabitCounts(startDate, endDate);
    print("Loaded data: $data"); // Для проверки загруженных данных
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesPage()),
      );
    }

    if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddActionPage()),
      );
    }
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StatsPage()),
      );
    }
  }



  Future<List<_ChartData>> getDailyHabitCounts(String startDate, String endDate) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    // Получаем все привычки, которые активны хотя бы в один день в диапазоне
    final List<Map<String, dynamic>> habits = await dbHelper.getHabitsForDateRange(startDate, endDate);

    // Получаем логи привычек за выбранный диапазон
    final List<Map<String, dynamic>> habitLogs = await dbHelper.getHabitLogsForDateRange(startDate, endDate);

    // Подсчет общего количества и выполненных привычек для каждого дня в диапазоне
    Map<String, int> totalHabits = {};
    Map<String, int> completedHabits = {};
    final habitLogs2 = await dbHelper.getHabitLogsForDateRange(startDate, endDate);
    print('Loaded Habit Logs: $habitLogs2'); // Вывод логов привычек


    // Проходим по каждой привычке
    for (var habit in habits) {
      String habitStartDate = habit['start_date'];
      DateTime habitStartDateTime = DateTime.parse(habitStartDate);

      // Привычка должна быть включена, если она началась до конца диапазона
      if (habitStartDateTime.isBefore(DateTime.parse(endDate).add(Duration(days: 1)))) {
        DateTime currentDate = DateTime.parse(startDate);

        while (currentDate.isBefore(DateTime.parse(endDate).add(Duration(days: 1)))) {
          String date = DateFormat('yyyy-MM-dd').format(currentDate);

          // Увеличиваем общее количество привычек на этот день
          totalHabits[date] = (totalHabits[date] ?? 0) + 1;

          // Фильтруем логи для конкретной привычки и конкретного дня
          var logsForDay = habitLogs.where((log) => log['habit_id'] == habit['id'] && log['date'] == date).toList();

          // Проверяем, есть ли лог с `completed` статусом
          bool isCompleted = logsForDay.any((log) => log['status'] == 'completed');

          if (isCompleted) {
            completedHabits[date] = (completedHabits[date] ?? 0) + 1;
          }

          // Переходим к следующему дню
          currentDate = currentDate.add(Duration(days: 1));
        }
      }
    }

    // Формируем данные для графика
    List<_ChartData> chartData = [];
    totalHabits.forEach((date, total) {
      int completed = completedHabits[date] ?? 0;
      int completionPercentage = (total > 0) ? ((completed / total) * 100).round() : 0;

      String formattedDate = DateFormat('d.MM').format(DateTime.parse(date));

      chartData.add(_ChartData(
          formattedDate,
          total, // Общее количество привычек
          completionPercentage, // Процент выполнения
          completed // Количество выполненных привычек
      ));
    });

    // Сортировка по датам
    chartData.sort((a, b) => a.day.compareTo(b.day));

    return chartData;
  }


  void _updateData(int tabIndex) {
    setState(() {
      _selectedTab = tabIndex;

      // Обновляем данные в зависимости от выбранного периода
      if (tabIndex == 0) {
        data = weekData;
        _selectedDateRangeStart = _today.subtract(Duration(days: _today.weekday - 1)); // Начало текущей недели
        _selectedDateRangeEnd = _selectedDateRangeStart.add(Duration(days: 6));
        loadChartData();
      } else if (tabIndex == 1) {
        data = twoWeeksData;
        _selectedDateRangeStart = _today.subtract(Duration(days: _today.weekday - 1)); // Начало текущей недели
        _selectedDateRangeEnd = _selectedDateRangeStart.add(Duration(days: 13));
        loadChartData();
      } else {
        data = monthData;
        _selectedDateRangeStart = DateTime(_today.year, _today.month, 1); // Первое число месяца
        _selectedDateRangeEnd = DateTime(_today.year, _today.month + 1, 0);
        loadChartData();
      }
    });
  }

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
                  tr('chart'),
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
                    'assets/images/Folder.png',
                    // Укажите путь к изображению
                    width: 32, // Ширина иконки
                    height: 32, // Высота иконки
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ArchivePage()));
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
          _buildCustomToggle(),
          _buildChartCard(),
          _buildStatsRow(),
          // График с Trackball для отображения подсказок при касании
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.35,
              child: _selectedChart == 0
                  ? SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData sales, _) => sales.day,
                    yValueMapper: (_ChartData sales, _) =>
                    _showPercent ? sales.percent : sales.completed,
                    color: Color(0xFF5F33E1),
                    borderRadius: BorderRadius.circular(5),
                    width: 0.8,
                    spacing: 0.1,
                    dataLabelSettings: DataLabelSettings(isVisible: false),
                  )
                ],
                trackballBehavior: _trackballBehavior, // Подключаем Trackball для подсказок
              )
                  : SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  LineSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData sales, _) => sales.day,
                    yValueMapper: (_ChartData sales, _) =>
                    _showPercent ? sales.percent : sales.completed,
                    color: Color(0xFF5F33E1),
                    width: 0.8,
                  )
                ],
                trackballBehavior: _trackballBehavior, // Подключаем Trackball для подсказок
              ),
            ),
          ),
          _buildBottomDateSelector(), // Выбор даты
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

  Widget _buildCustomToggle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16), // Отступы только справа и слева для карточки
      child: Card(
        elevation: 1, // Тень для карточки
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Закругленные углы карточки
        ),
        color: Colors.white, // Цвет карточки
        child: Padding(
          padding: EdgeInsets.all(12), // Отступы внутри карточки
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Равномерное размещение кнопок
            children: [
              _buildToggleButton(0, tr('W')), // Первая кнопка
              _buildToggleButton(1, tr('2W')), // Вторая кнопка
              _buildToggleButton(2, tr('M')),  // Третья кнопка
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(int index, String label) {
    final bool isSelected = _selectedIndex == index; // Проверяем, выбрана ли кнопка

    // Определяем радиусы для каждой кнопки
    BorderRadius borderRadius;
    if (index == 0) {
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(12),
        bottomLeft: Radius.circular(12),
      );
    } else if (index == 2) {
      borderRadius = BorderRadius.only(
        topRight: Radius.circular(12),
        bottomRight: Radius.circular(12),
      );
    } else {
      borderRadius = BorderRadius.zero; // Центр без закруглений
    }

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4), // Отступ между кнопками
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = index; // Обновляем выбранную кнопку
              _updateData(index); // Вызываем соответствующую функцию по индексу
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200), // Плавная анимация
            curve: Curves.easeInOut, // Эффект плавного переключения
            padding: EdgeInsets.symmetric(vertical: 12), // Отступы для кнопок
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF5F33E1) : Color(0xFFF3EDFF), // Цвет фона кнопки
              borderRadius: borderRadius,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF5F33E1), // Цвет текста
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // Метод для создания ряда с овальными виджетами
  Widget _buildStatsRow() {
    if (_selectedIndex == 1 || _selectedIndex == 2) {
      return SizedBox.shrink();  // Возвращаем пустой контейнер, если выбран 1 или 2
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((item) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _showPercent = !_showPercent; // Переключение между количеством и процентами
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
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
                children: [
                  SizedBox(height: 4),
                  Text(
                    _showPercent
                        ? '${item.percent.toInt()}%' // Процент выполнения
                        : '${item.completed.toInt()}', // Количество выполненных из общего количества
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F33E1),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
                tr('chart'),
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
                  style: ElevatedButton.styleFrom(backgroundColor: !_showPercent ? Color(0xFF5F33E1) : Colors.white, // Закрашенная при выборе, иначе белая
                    shadowColor: Colors.transparent, // Убираем тень
                  ),
                  onPressed: () {
                    setState(() {
                      _showPercent = false; // Показать количество
                    });
                  },
                  child: Text(
                    tr('quantity'), // Кнопка для количества
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
                    tr('percent'), // Кнопка для процентов
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
      onTap: () {
        _onItemTapped(index);
      },
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
    String formattedStartDate = DateFormat('MMMM d', Localizations.localeOf(context).toString()).format(_selectedDateRangeStart);
    String formattedEndDate = DateFormat('MMMM d', Localizations.localeOf(context).toString()).format(_selectedDateRangeEnd);

    String formattedDateRange = '$formattedStartDate - $formattedEndDate';

    return GestureDetector(
      onTap: () {
        _showCalendarDialog(); // Открытие диалога выбора даты
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF5F33E1)),
              onPressed: () {
                setState(() {
                  // Логика для перехода на предыдущий период (неделя, 2 недели, месяц)
                  if (_selectedTab == 0) {
                    _selectedDateRangeStart = _selectedDateRangeStart.subtract(Duration(days: 7));
                    _selectedDateRangeEnd = _selectedDateRangeEnd.subtract(Duration(days: 7));
                  } else if (_selectedTab == 1) {
                    _selectedDateRangeStart = _selectedDateRangeStart.subtract(Duration(days: 14));
                    _selectedDateRangeEnd = _selectedDateRangeEnd.subtract(Duration(days: 14));
                  } else {
                    // Переход на предыдущий месяц
                    if (_selectedDateRangeStart.month == 1) {
                      _selectedDateRangeStart = DateTime(_selectedDateRangeStart.year - 1, 12, 1);
                    } else {
                      _selectedDateRangeStart = DateTime(_selectedDateRangeStart.year, _selectedDateRangeStart.month - 1, 1);
                    }
                    _selectedDateRangeEnd = DateTime(_selectedDateRangeStart.year, _selectedDateRangeStart.month + 1, 0);
                  }

                  if (_selectedDateRangeEnd.isAfter(_today)) {
                    _selectedDateRangeEnd = _today;
                  }

                  loadChartData(); // Обновляем данные графика
                });
              },
            ),
            Text(
              formattedDateRange,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF5F33E1)),
              onPressed: () {
                setState(() {
                  // Логика для перехода на следующий период (неделя, 2 недели, месяц)
                  if (_selectedTab == 0 && _selectedDateRangeEnd.add(Duration(days: 7)).isBefore(_today.add(Duration(days: 1)))) {
                    _selectedDateRangeStart = _selectedDateRangeStart.add(Duration(days: 7));
                    _selectedDateRangeEnd = _selectedDateRangeEnd.add(Duration(days: 7));
                  } else if (_selectedTab == 1 && _selectedDateRangeEnd.add(Duration(days: 14)).isBefore(_today.add(Duration(days: 1)))) {
                    _selectedDateRangeStart = _selectedDateRangeStart.add(Duration(days: 14));
                    _selectedDateRangeEnd = _selectedDateRangeEnd.add(Duration(days: 14));
                  } else if (_selectedTab == 2) {
                    // Переход на следующий месяц
                    if (_selectedDateRangeStart.month == 12) {
                      _selectedDateRangeStart = DateTime(_selectedDateRangeStart.year + 1, 1, 1);
                    } else {
                      _selectedDateRangeStart = DateTime(_selectedDateRangeStart.year, _selectedDateRangeStart.month + 1, 1);
                    }
                    _selectedDateRangeEnd = DateTime(_selectedDateRangeStart.year, _selectedDateRangeStart.month + 1, 0);

                    if (_selectedDateRangeEnd.isAfter(_today)) {
                      _selectedDateRangeStart = DateTime(_today.year, _today.month, 1);

                    }
                  }

                  loadChartData(); // Обновляем данные графика
                });
              },
            ),
            // Кнопка возврата к сегодняшней дате, если диапазон не включает текущий день
            if (!isSameDay(_selectedDateRangeEnd, _today))
              Container(
                width: 35,
                height: 35,
                margin: const EdgeInsets.only(left: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF5F33E1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/images/ar_back.png',
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _today;
                      _selectedDateRangeStart = _today.subtract(Duration(days: _today.weekday - 1));
                      _selectedDateRangeEnd = _selectedDateRangeStart.add(Duration(days: 6));

                      loadChartData(); // Обновляем данные графика
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }


  void _showCalendarDialog() {
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
                                _selectedDateRangeStart = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
                                _selectedDateRangeEnd = _selectedDateRangeStart.add(Duration(days: 6));

                                loadChartData(); // Обновляем данные графика
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

}


class _ChartData {
  _ChartData(this.day, this.quantity, this.percent, this.completed);

  final String day; // Дата
  final int quantity; // Общее количество привычек
  final int percent; // Процент выполнения
  final int completed; // Количество выполненных привычек
  @override
  String toString() {
    return 'Day: $day, Quantity: $quantity, Completed: $completed, Percent: $percent%';
  }
}
