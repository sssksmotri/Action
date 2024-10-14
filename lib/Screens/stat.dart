import 'dart:math'; // Импортируем библиотеку для генерации случайных чисел
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'main.dart';
import 'add.dart';
import 'stat_tabl.dart';
import 'archive.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _selectedIndex = 0; // Инициализация с 0 (первый элемент)
  DateTime _selectedDate = DateTime.now(); // Выбранная дата
  DateTime _today = DateTime.now(); // Текущая дата
  String _selectedPeriod = 'Week'; // Текущий выбранный период
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now(); // Конечная дата

  // Изменен формат задач
  final List<Map<String, dynamic>> tasks = [
    {'task': 'Drink 2 liters of water', 'completed': '7/7'}, // 7/7
    {'task': 'Take pills', 'completed': '4/7'}, // 4/7
    {'task': 'Read 100 pages', 'completed': '5/7'}, // 5/8
    {'task': 'Go to gym', 'completed': '7/7'}, // 7/7
  ];
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

  @override
  void initState() {
    super.initState();
    _updateDates(); // Инициализация списка дат для отображения
  }

  // Обновление списка дат в зависимости от выбранного периода
  void _updateDates() {
    setState(() {
      if (_selectedPeriod == 'Week') {
        _startDate = _today.subtract(const Duration(days: 7));
        _endDate = _today;
      } else if (_selectedPeriod == '2 weeks') {
        _startDate = _today.subtract(const Duration(days: 14));
        _endDate = _today;
      } else if (_selectedPeriod == 'Month') {
        _startDate = _today.subtract(const Duration(days: 30));
        _endDate = _today;
      } else if (_selectedPeriod == 'Another Period') {
        _startDate = _today.subtract(const Duration(days: 10));
        _endDate = _today;
      }
    });
  }

  // Обработка нажатия на элемент нижней навигации


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
                    _updateDates(); // Обновление списка дат
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Two weeks'),
                onTap: () {
                  setState(() {
                    _selectedPeriod = '2 weeks';
                    _updateDates(); // Обновление списка дат
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Month'),
                onTap: () {
                  setState(() {
                    _selectedPeriod = 'Month';
                    _updateDates(); // Обновление списка дат
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

  // Форматирование диапазона дат
  String _formatDateRange() {
    return '${DateFormat('MMM d', Localizations.localeOf(context).toString()).format(_startDate)} - ${DateFormat('MMM d', Localizations.localeOf(context).toString()).format(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,

        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  iconSize: 32, // Увеличиваем размер иконки
                  padding: EdgeInsets.zero, // Убираем отступы
                  icon: Image.asset(
                    'assets/images/Chart.png', // Укажите путь к изображению
                    width: 32, // Ширина иконки
                    height: 32, // Высота иконки
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChartScreen(),
                      ),
                    );
                  },
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArchivePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBottomDateSelector(), // Верхняя панель выбора дат
            const SizedBox(height: 20),
            // Список задач с индикаторами прогресса
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskCard(task); // Используем метод для создания карточки задачи
                },
              ),
            ),
          ],
        ),
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

  // Получаем общее количество точек в зависимости от выбранного периода
  int _getTotalDots() {
    switch (_selectedPeriod) {
      case 'Week':
        return 7;
      case '2 weeks':
        return 14;
      case 'Month':
        return 30;
      default:
        return 7; // По умолчанию
    }
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
          // Первая строка: стрелки, дата, фильтр и комбобокс
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Левая стрелка
              Container(
                width: 40, // Увеличиваем ширину контейнера для стрелки
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 18, color: Color(0xFF5F33E1)),
                  onPressed: () {
                    setState(() {
                      _startDate = _startDate.subtract(Duration(days: 7)); // Перемещаем на неделю назад
                    });
                  },
                ),
              ),

              // Текущий диапазон дат
              Expanded(
                child: Center(
                  child: Text(
                    _formatDateRange(), // Форматирование диапазона дат
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // Центрируем текст
                  ),
                ),
              ),

              // Правая стрелка
              Container(
                width: 40, // Увеличиваем ширину контейнера для стрелки
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF5F33E1)),
                  onPressed: () {
                    setState(() {
                      _startDate = _startDate.add(Duration(days: 7)); // Перемещаем на неделю вперед
                    });
                  },
                ),
              ),

              // Кнопка фильтра
              Container(
                width: 40, // Ширина для кнопки фильтра
                child: IconButton(
                  icon: Image.asset('assets/images/Filter.png', width: 24, height: 24),
                  onPressed: _showPeriodSelectionDialog,
                ),
              ),

              // Выпадающий список (комбобокс)
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
                      _updateDates(); // Обновление диапазона дат
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

          if (_selectedPeriod == 'Week')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _generateDaysForPeriod(_startDate, _selectedPeriod).map((day) {
                // Изменение размера плиток в зависимости от периода
                double tileWidth = _selectedPeriod == '2 weeks' ? 45.0 : 60.0;

                return Container(
                  width: 40, // Динамический размер плиток
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(day).toUpperCase(), // День недели
                        style: const TextStyle(color: Colors.black54),
                      ),
                      Text(
                        DateFormat('d').format(day), // Число
                        style: const TextStyle(
                          color: Color(0xFF5F33E1),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else if (_selectedPeriod == 'Another Period')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9F9), // Новый цвет
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'On', // Текст для поля выбора начальной даты
                          style: TextStyle(color: Colors.black54),
                        ),
                        Image.asset('assets/images/Calendar.png', width: 20, height: 20), // Иконка календаря
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9F9), // Новый цвет
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'To', // Текст для поля выбора конечной даты
                          style: TextStyle(color: Colors.black54),
                        ),
                        Image.asset('assets/images/Calendar.png', width: 20, height: 20), // Иконка календаря
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }


  List<DateTime> _generateDaysForPeriod(DateTime startDate, String period) {
    int days = period == 'Week' ? 7 : period == '2 weeks' ? 14 : 30;
    return List.generate(days, (index) => startDate.add(Duration(days: index)));
  }

  // Метод для создания карточки задачи
  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5, // Тень
      margin: const EdgeInsets.symmetric(vertical: 8), // Отступы между карточками
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Отступы внутри карточки
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
                const SizedBox(width: 8), // Отступ между текстом задачи и выполненными задачами
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFB6A37),
                  ),
                  child: Text(
                    task['completed'], // Здесь отображается количество выполненных задач
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildProgressBar(task['completed']), // Обновляем метод прогресс-бара
          ],
        ),
      ),
    );
  }

  // Метод для построения прогресс-бара
  Widget _buildProgressBar(String completed) {
    final parts = completed.split('/');
    final completedCount = int.parse(parts[0]);
    final totalCount = int.parse(parts[1]);

    // Общее количество точек
    int totalDots = _getTotalDots(); // Используем динамическое количество точек
    int filledDots = (completedCount / totalCount * totalDots).round();

    double baseWidth = MediaQuery.of(context).size.width / (totalDots + 1); // Ширина овала
    double height = 10.0; // Высота овала

    return Wrap(
      spacing: 4.0, // Отступ между овальными фигурами
      runSpacing: 4.0, // Отступ между строками
      children: List.generate(totalDots, (index) {
        bool isFilled = index < filledDots; // Проверка, заполнена ли точка
        return Container(
          width: baseWidth, // Овалы имеют фиксированную ширину
          height: height,
          decoration: BoxDecoration(
            color: isFilled ? const Color(0xFF5F33E1) : const Color(0xFFEEE9FF), // Цвет заполненных и незаполненных
            borderRadius: BorderRadius.circular(5), // Закругленные углы
          ),
        );
      }),
    );
  }

  // Создание заголовка для AppBar
  Widget _buildAppBarTitle() {
    return const Text(
      'Statistics',
      style: TextStyle(color: Colors.black),
    );
  }

  // Нижняя навигационная панель
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
  }}
