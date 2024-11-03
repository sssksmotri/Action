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
import 'dart:ui';
import 'package:action_notes/Widgets/loggable_screen.dart';

class ChartScreen extends StatefulWidget {
  final int sessionId;
  const ChartScreen({Key? key, required this.sessionId}) : super(key: key);
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

  List<_ChartData> data = [];
  List<_ChartData> weekData = [];

  List<_ChartData> twoWeeksData = [];

  List<_ChartData> monthData = [];
  int? _currentSessionId;
  String _currentScreenName = "ChartScreen";

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
    data = weekData; // По умолчанию показываем данные за неделю
    loadChartData();

  }

  void loadChartData() async {
    String startDate = DateFormat('yyyy-MM-dd').format(_selectedDateRangeStart);
    String endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRangeEnd);
    data = await getDailyHabitCounts(startDate, endDate);
    print("Loaded data: $data"); // Для проверки загруженных данных
    setState(() {});
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

      DateTime parsedDate = DateTime.parse(date);

      chartData.add(_ChartData(
          parsedDate,
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
      DatabaseHelper.instance.logAction(
          _currentSessionId!,
          "Пользователь выбрал период: ${tabIndex == 0 ? 'неделя' : tabIndex == 1 ? 'две недели' : 'месяц'} на экране: $_currentScreenName"
      );
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
            DatabaseHelper.instance.logAction(
                _currentSessionId!,
                "Пользователь нажал кнопку назад и вернулся в StatsPage из: $_currentScreenName"
            );
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Transform.translate(
                  offset: Offset(-16, 0), // Сдвиг текста влево
                  child: Text(
                    tr('chart'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
                    DatabaseHelper.instance.logAction(
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
        backgroundColor: const Color(0xFFF8F9F9),
      ),
      body: Column(
        children: <Widget>[
          _buildCustomToggle(),
          _buildChartCard(),
          // График с Trackball для отображения подсказок при касании

          Expanded(
            child: Container(
                padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0), // Увеличили верхний отступ
                height: MediaQuery.of(context).size.height * 0.35,
              child: _selectedChart == 0
                  ? Stack(
                children: [
                  // Светло-фиолетовый столбец на заднем фоне
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        majorGridLines: MajorGridLines(width: 0),
                        dateFormat: DateFormat('dd.MM'),
                        interval: _selectedTab == 0 ? 1 : (_selectedTab == 1 ? 2 : 5),
                        intervalType: DateTimeIntervalType.days,
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: _showPercent ? 109 : 10.9,
                        interval: _showPercent ? 10 : 1,
                        majorGridLines: MajorGridLines(width: 0),
                      ),
                      plotAreaBorderWidth: 0,
                      series: <CartesianSeries>[
                        ColumnSeries<_ChartData, DateTime>(
                          dataSource: data,
                          xValueMapper: (_ChartData sales, _) => sales.day,
                          yValueMapper: (_ChartData sales, _) => _showPercent ? 100 : 10,
                          color: Color(0xFFECEAFF),
                          borderRadius: BorderRadius.circular(10),
                          width: 0.9,
                          spacing: 0.0,
                          opacity: 0.6,
                        ),
                      ],
                    ),
                  ),
                  // Темно-фиолетовый столбец с данными
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        majorGridLines: MajorGridLines(width: 0),
                        dateFormat: DateFormat('dd.MM'),
                        interval: _selectedTab == 0 ? 1 : (_selectedTab == 1 ? 2 : 5),
                        intervalType: DateTimeIntervalType.days,
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: _showPercent ? 109 : 10.9,
                        interval: _showPercent ? 10 : 1,
                        majorGridLines: MajorGridLines(width: 0),
                      ),
                      plotAreaBorderWidth: 0,
                      series: <CartesianSeries>[
                        ColumnSeries<_ChartData, DateTime>(
                          dataSource: data,
                          xValueMapper: (_ChartData sales, _) => sales.day,
                          yValueMapper: (_ChartData sales, _) =>
                          _showPercent ? sales.percent : sales.completed,
                          color: Color(0xFF5F33E1),
                          borderRadius: BorderRadius.circular(10),
                          width: 0.9,
                          spacing: 0.0,
                          dataLabelSettings: DataLabelSettings(isVisible: false),
                        ),

                      ],
                    ),
                  ),
                  if(_selectedTab==0)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(
                          majorGridLines: MajorGridLines(width: 0), // Убрать основные сеточные линии
                          axisLine: AxisLine(width: 1, color: Colors.white), // Белая ось X
                          dateFormat: DateFormat('dd.MM'),
                          interval: _selectedTab == 0 ? 1 : (_selectedTab == 1 ? 2 : 5),
                          intervalType: DateTimeIntervalType.days,
                          labelStyle: TextStyle(color: Colors.transparent), // Прозрачный цвет меток на оси X
                          majorTickLines: MajorTickLines(size: 0), // Убрать тире на оси X
                        ),
                        primaryYAxis: NumericAxis(
                          minimum: 0,
                          maximum: _showPercent ? 110 : 10.9,
                          interval: _showPercent ? 10 : 1,
                          majorGridLines: MajorGridLines(width: 0), // Убрать основные сеточные линии
                          axisLine: AxisLine(color: Colors.transparent), // Прозрачная ось Y
                          labelStyle: TextStyle(color: Colors.transparent), // Прозрачный цвет меток на оси Y
                          majorTickLines: MajorTickLines(size: 0), // Убрать тире на оси Y
                        ),
                        plotAreaBorderWidth: 0,
                        series: <CartesianSeries>[
                          ColumnSeries<_ChartData, DateTime>(
                            dataSource: data,
                            xValueMapper: (_ChartData sales, _) => sales.day,
                            yValueMapper: (_ChartData sales, _) =>
                            _showPercent ? sales.percent : sales.completed,
                            color: Colors.transparent, // Полностью прозрачный цвет
                            borderRadius: BorderRadius.circular(10),
                            width: 0.9,
                            spacing: 0.0,
                          ),
                        ],
                        annotations: data.map((entry) {
                          return CartesianChartAnnotation(
                            widget: Container(
                              width: 35, // Установите фиксированную ширину
                              height: 17, // Установите фиксированную высоту
                              padding: EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFECEAFF), // Цвет фона аннотаций
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center( // Центрируем содержимое
                                child: Text(
                                  _showPercent ? '${entry.percent}%' : '${entry.completed}',
                                  style: TextStyle(
                                    color: Color(0xFF5F33E1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            coordinateUnit: CoordinateUnit.point,
                            x: entry.day,
                            // Установите y над графиком
                            y: (_showPercent ? 106 : 10.5), // Установите фиксированное значение Y, превышающее максимальное значение графика
                          );
                        }).toList(),
                        trackballBehavior: TrackballBehavior(
                          enable: true,
                          activationMode: ActivationMode.singleTap,
                          tooltipSettings: InteractiveTooltip(
                            enable: true,
                            color: Colors.white, // основной фон тултипа белый
                            textStyle: TextStyle(color: Color(0xFF5F33E1), fontSize: 12),
                          ),

                          lineWidth: 0,
                          lineColor: Colors.transparent,
                          builder: (BuildContext context, TrackballDetails details) {
                            final date = DateFormat('dd.MM').format(details.point!.x);
                            final value = _showPercent
                                ? '${details.point!.y}%' // Процентное значение
                                : details.point!.y.toString(); // Количество

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                  color: Color(0xFFEEE9FF), // задний фон тултипа #EEE9FF
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1), // subtle shadow
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ]
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    date,
                                    style: TextStyle(color: Colors.black, fontSize: 10), // Дата черным цветом, размер 8 пикселей
                                  ),
                                  Text(
                                    value,
                                    style: TextStyle(
                                      color: Color(0xFF5F33E1), // Цвет темно-фиолетовый для значения
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                ],
              )
              : SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  majorGridLines: MajorGridLines(width: 0),
                  dateFormat: DateFormat('dd.MM'),
                  interval: _selectedTab == 0 ? 1 : (_selectedTab == 1 ? 2 : 5),
                  intervalType: DateTimeIntervalType.days,
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  maximum: data.isNotEmpty
                      ? data.last.day.add(Duration(days: 0, hours: 12))
                      : DateTime.now(),
                  minimum: data.isNotEmpty
                      ? data.first.day.subtract(Duration(days: 0, hours: 10))
                      : DateTime.now(),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: _showPercent ? 109 : 10.9,
                  interval: _showPercent ? 10 : 1,
                  majorGridLines: MajorGridLines(width: 1),
                  axisLine: AxisLine(width: 0),
                ),
                plotAreaBackgroundColor: Color(0xFFFFF0EC),
                plotAreaBorderWidth: 0,
                margin: EdgeInsets.only(right: 10),
                series: <CartesianSeries>[
                  LineSeries<_ChartData, DateTime>(
                    dataSource: data,
                    xValueMapper: (_ChartData sales, _) => sales.day,
                    yValueMapper: (_ChartData sales, _) {
                      final yValue = _showPercent ? sales.percent : sales.completed;
                      print('Point for ${sales.day}: Y-Value = $yValue');
                      return yValue;
                    },
                    color: Color(0xFFFB6A37),
                    width: 2,
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      color: Color(0xFFFB6A37),
                      shape: DataMarkerType.circle,
                      borderWidth: 1,
                      borderColor: Color(0xFFFB6A37),
                    ),
                  ),
                ],
                annotations: [
                  if(_selectedTab==0) ...[
                    if (_showPercent) ...[
                      CartesianChartAnnotation(
                        widget: Container(
                          width: double.infinity,
                          height: 46,
                          color: Color(0xFFF8F9F9), // Цвет фона для значений процентов выше 110
                        ),
                        coordinateUnit: CoordinateUnit.point,
                        x: data.isNotEmpty ? data.first.day : DateTime.now(),
                        y: 110,
                      ),
                      CartesianChartAnnotation(
                        widget: Container(
                          width: double.infinity,
                          height: 46,
                          color: Color(0xFFF8F9F9), // Цвет фона для значений процентов выше 110
                        ),
                        coordinateUnit: CoordinateUnit.point,
                        y: 110,
                        x: data.isNotEmpty ? data.last.day : DateTime.now(),
                      ),
                    ],
                    if (!_showPercent) ...[
                      CartesianChartAnnotation(
                        widget: Container(
                          width: double.infinity,
                          height: 46,
                          color: Color(0xFFF8F9F9), // Цвет фона для значений количества выше 10
                          child: Center(
                          ),
                        ),
                        coordinateUnit: CoordinateUnit.point,
                        x: data.isNotEmpty ? data.first.day : DateTime.now(),
                        y: 11, // Задайте Y, когда значение количества превышает 10
                      ),
                      CartesianChartAnnotation(
                        widget: Container(
                          width: double.infinity,
                          height: 46,
                          color: Color(0xFFF8F9F9), // Цвет фона для значений количества выше 10
                          child: Center(
                          ),
                        ),
                        coordinateUnit: CoordinateUnit.point,
                        y: 11,
                        x: data.isNotEmpty ? data.last.day : DateTime.now(),
                      ),
                    ],
                    ...data.map((entry) {
                      return CartesianChartAnnotation(
                        widget: Container(
                          width: 45, // Установите фиксированную ширину
                          height: 17, // Установите фиксированную высоту
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Можно оставить один вариант
                          decoration: BoxDecoration(
                            color: Color(0xFFECEAFF), // Цвет фона аннотации
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center( // Центрируем содержимое
                            child: Text(
                              _showPercent ? '${entry.percent}%' : '${entry.completed}',
                              style: TextStyle(
                                color: Color(0xFF5F33E1),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        coordinateUnit: CoordinateUnit.point,
                        x: entry.day,
                        y: _showPercent ? 105 : 10.55,
                      );
                    }).toList(),
                  ],
                ],
                trackballBehavior: TrackballBehavior(
                  enable: true,
                  activationMode: ActivationMode.singleTap,
                  tooltipSettings: InteractiveTooltip(
                    enable: true,
                    color: Colors.white,
                    textStyle: TextStyle(color: Color(0xFF5F33E1), fontSize: 12),
                  ),
                  lineDashArray: [8, 3],
                  lineColor: Color(0xFFFB6A37),
                  lineWidth: 1.5,
                  builder: (BuildContext context, TrackballDetails details) {
                    final date = DateFormat('dd.MM').format(details.point!.x);
                    final value = _showPercent
                        ? '${details.point!.y}%'
                        : details.point!.y.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF5F0),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            date,
                            style: TextStyle(color: Colors.black, fontSize: 10),
                          ),
                          Text(
                            value,
                            style: TextStyle(
                              color: Color(0xFFFF6B3C),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),


              )
            ),
          ),


          _buildBottomDateSelector(), // Выбор даты
        ],
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
            _buildNavItem(3, 'assets/images/Calendar.png', isSelected: true),
            _buildNavItem(4, 'assets/images/Setting.png'),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomToggle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8), // Уменьшены отступы для карточки
      child: Card(
        elevation: 0, // Тень для карточки
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
        child: TextButton(
          onPressed: () {
            setState(() {
              _selectedIndex = index; // Обновляем выбранную кнопку
              _updateData(index); // Вызываем соответствующую функцию по индексу
            });
          },
          style: TextButton.styleFrom(
            backgroundColor: isSelected ? Color(0xFF5F33E1) : Color(0xFFF3EDFF), // Цвет фона кнопки
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20), // Уменьшение горизонтальных отступов
          ),
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
    );
  }




  Widget _buildChartCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
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
                        onTap: () async {
                          DatabaseHelper.instance.logAction(
                              _currentSessionId!,
                              "Пользователь выбрал график: Гистограмма на экране: $_currentScreenName"
                          );
                          setState(() {
                            _selectedChart = 0; // Гистограмма
                          });
                        },
                        child: Container(
                          width: 55,
                          decoration: BoxDecoration(
                            color: _selectedChart == 0 ? Color(0xFF5F33E1) : Colors.transparent, // Цвет фона
                            borderRadius: BorderRadius.circular(24), // Закругление углов
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
                        onTap: () async {
                         await DatabaseHelper.instance.logAction(
                              _currentSessionId!,
                              "Пользователь выбрал график: Линейный график на экране: $_currentScreenName"
                          );
                          setState(() {
                            _selectedChart = 1; // Линейный график
                          });
                        },
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: _selectedChart == 1 ? Color(0xFF5F33E1) : Colors.transparent, // Цвет фона
                            borderRadius: BorderRadius.circular(24), // Закругление углов
                            border: Border.all(
                              color: _selectedChart == 1 ? Color(0xFF5F33E1) : Color(0xFF5F33E1), // Цвет рамки
                              width: 2,
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
                    side: BorderSide(
                      color: Color(0xFF5F33E1), // Цвет рамки
                      width: 1, // Ширина рамки
                    ),
                  ),
                  onPressed: () async {
                   await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь выбрал отображение: Количество на экране: $_currentScreenName"
                    );
                    setState(() {
                      _showPercent = false; // Показать количество
                      loadChartData();
                    });
                  },
                  child: Text(
                    tr('quantity'), // Кнопка для количества
                    style: TextStyle(
                      fontSize: 16, // Увеличенный размер шрифта
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
                    side: BorderSide(
                      color: Color(0xFF5F33E1), // Цвет рамки
                      width: 1, // Ширина рамки
                    ),
                  ),
                  onPressed: () async {
                   await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь выбрал отображение: Процент на экране: $_currentScreenName"
                    );
                    setState(() {
                      _showPercent = true; // Показать процент
                      loadChartData();
                    });
                  },
                  child: Text(
                    tr('percent'), // Кнопка для процентов
                    style: TextStyle(
                      fontSize: 16, // Увеличенный размер шрифта
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

  Widget _buildBottomDateSelector() {
    String formattedStartDate = DateFormat('MMMM d', Localizations.localeOf(context).toString()).format(_selectedDateRangeStart);
    String formattedEndDate = DateFormat('MMMM d', Localizations.localeOf(context).toString()).format(_selectedDateRangeEnd);
    String formattedDateRange = '$formattedStartDate - $formattedEndDate';

    return GestureDetector(
      onTap: () async {
        DatabaseHelper.instance.logAction(
            _currentSessionId!,
            "Пользователь открыл календарь на экране: $_currentScreenName"
        );
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
            // Левая стрелка
            GestureDetector(
              onTap: () async {
                await DatabaseHelper.instance.logAction(
                    _currentSessionId!,
                    "Пользователь нажал на стрелку влево для изменения даты на экране: $_currentScreenName"
                );
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
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Отступ вокруг изображения
                child: Image.asset(
                  'assets/images/arr_left.png', // Путь к вашему изображению
                  width: 22, // Ширина изображения
                  height: 22, // Высота изображения
                  color: Color(0xFF5F33E1), // Цвет изображения, если требуется
                ),
              ),
            ),


            // Текущий диапазон дат
            Text(
              formattedDateRange,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Правая стрелка
            GestureDetector(
              onTap: _isForwardNavigationAllowed()
                  ? () async {
                await DatabaseHelper.instance.logAction(
                    _currentSessionId!,
                    "Пользователь нажал на стрелку вправо для изменения даты на экране: $_currentScreenName"
                );
                setState(() {
                  // Логика для перехода на следующий период (неделя, 2 недели, месяц)
                  if (_selectedTab == 0) {
                    _selectedDateRangeStart = _selectedDateRangeStart.add(Duration(days: 7));
                    _selectedDateRangeEnd = _selectedDateRangeEnd.add(Duration(days: 7));
                  } else if (_selectedTab == 1) {
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
              }
                  : null, // Если кнопка недоступна, обработчик нажатия будет равен null
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Отступ вокруг изображения
                child: Image.asset(
                  'assets/images/arr_right.png', // Путь к вашему изображению
                  width: 22, // Ширина изображения
                  height: 22, // Высота изображения
                  color: _isForwardNavigationAllowed() ? Color(0xFF5F33E1) : Color(0x4D5F33E1), // Цвет изображения
                ),
              ),
            ),

            // Кнопка возврата к сегодняшнему дню, если текущий день не включен
            if (!_isTodayInCurrentRange())
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
                  onPressed: () async {
                    await DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь выбрал вернуть сегодняшную дату на экране: $_currentScreenName"
                    );
                    setState(() {
                      _selectedDate = _today;

                      // Обновление диапазона дат в зависимости от выбранного периода
                      if (_selectedTab == 0) {
                        _selectedDateRangeStart = _today.subtract(Duration(days: _today.weekday - 1));
                        _selectedDateRangeEnd = _selectedDateRangeStart.add(Duration(days: 6));
                      } else if (_selectedTab == 1) {
                        _selectedDateRangeStart = _today.subtract(Duration(days: _today.weekday - 1));
                        _selectedDateRangeEnd = _selectedDateRangeStart.add(Duration(days: 13));
                      } else if (_selectedTab == 2) {
                        _selectedDateRangeStart = DateTime(_today.year, _today.month, 1);
                        _selectedDateRangeEnd = DateTime(_today.year, _today.month + 1, 0);
                      }

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

// Проверка, доступна ли навигация вперед
  bool _isForwardNavigationAllowed() {
    if (_selectedTab == 0) {
      // Для недельного периода
      return _selectedDateRangeEnd.add(Duration(days: 7)).isBefore(_today.add(Duration(days: 1)));
    } else if (_selectedTab == 1) {
      // Для двухнедельного периода
      return _selectedDateRangeEnd.add(Duration(days: 14)).isBefore(_today.add(Duration(days: 1)));
    } else if (_selectedTab == 2) {
      // Для месячного периода
      DateTime nextMonthStart = DateTime(_selectedDateRangeStart.year, _selectedDateRangeStart.month + 1, 1);
      return nextMonthStart.isBefore(_today.add(Duration(days: 1)));
    }
    return false;
  }

// Проверка, включен ли текущий день в диапазон
  bool _isTodayInCurrentRange() {
    // Изменение условий для проверки включения текущей даты в диапазон
    return _today.isAfter(_selectedDateRangeStart) && _today.isBefore(_selectedDateRangeEnd.add(Duration(days: 1))) || _today.isAtSameMomentAs(_selectedDateRangeStart) || _today.isAtSameMomentAs(_selectedDateRangeEnd);
  }



  void _showCalendarDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // Полупрозрачная заливка
      barrierDismissible: true, // Позволяем закрывать диалог при нажатии вне области
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Размытие фона
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white, // Цвет фона календаря
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
                      todayTextStyle: TextStyle(
                        color: Colors.black,
                      ),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 18, // Размер шрифта для месяца
                        fontWeight: FontWeight.bold, // Жирный шрифт
                        color: Colors.black, // Цвет текста для названия месяца
                      ),
                      titleTextFormatter: (date, locale) {
                        String formattedMonth = DateFormat.MMMM(locale).format(date);

                        // Преобразуем первую букву в верхний регистр только для русского языка
                        if (locale == 'ru') {
                          formattedMonth = formattedMonth[0].toUpperCase() + formattedMonth.substring(1);
                        }

                        return formattedMonth;
                      },
                      leftChevronIcon: Padding(
                        padding: const EdgeInsets.only(left: 35.0),
                        child: Image.asset(
                          'assets/images/arr_left.png', // Путь к изображению стрелки влево
                          width: 20,
                          height: 20,
                          color: const Color(0xFF5F33E1), // Цвет изображения
                        ),
                      ),
                      rightChevronIcon: Padding(
                        padding: const EdgeInsets.only(right: 35.0),
                        child: Image.asset(
                          'assets/images/arr_right.png', // Путь к изображению стрелки вправо
                          width: 20,
                          height: 20,
                          color: const Color(0xFF5F33E1), // Цвет изображения
                        ),
                      ),
                    ),
                    daysOfWeekVisible: true,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: const TextStyle(
                        fontSize: 13, // Размер шрифта для дней недели
                        fontWeight: FontWeight.normal, // Не жирный шрифт
                        color: Colors.grey, // Цвет текста для будних дней
                      ),
                      weekendStyle: const TextStyle(
                        fontSize: 13, // Размер шрифта для выходных
                        fontWeight: FontWeight.normal, // Не жирный шрифт
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
                          _selectedDateRangeStart = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
                          _selectedDateRangeEnd = _selectedDateRangeStart.add(Duration(days: 6));

                          loadChartData(); // Обновляем данные графика
                        });
                        DatabaseHelper.instance.logAction(
                            _currentSessionId!,
                            "Пользователь выбрал дату: ${DateFormat('yyyy-MM-dd').format(selectedDay)} на экране: $_currentScreenName"
                        );
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


}


class _ChartData {
  _ChartData(this.day, this.quantity, this.percent, this.completed);

  final DateTime  day; // Дата
  final int quantity; // Общее количество привычек
  final int percent; // Процент выполнения
  final int completed; // Количество выполненных привычек
  @override
  String toString() {
    return 'Day: $day, Quantity: $quantity, Completed: $completed, Percent: $percent%';
  }
}
