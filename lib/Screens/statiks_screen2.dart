import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String selectedPeriod = 'Week';
  DateTimeRange? selectedDateRange;

  final List<Map<String, dynamic>> tasks = [
    {'task': 'Drink 2 liters of water', 'progress': 1.0, 'completed': '7/7', 'color': Colors.orange},
    {'task': 'Take pills', 'progress': 0.4, 'completed': '4/14', 'color': Colors.red},
    {'task': 'Read 100 pages', 'progress': 0.625, 'completed': '10/30', 'color': Colors.blue},
    {'task': 'Go to gym', 'progress': 0.7, 'completed': '60/60', 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () => _selectDateRange(context),
          ),
          DropdownButton<String>(
            value: selectedPeriod,
            items: ['Week', '2 Weeks', 'Month', 'Custom'].map((String period) {
              return DropdownMenuItem<String>(
                value: period,
                child: Text(period, style: TextStyle(color: Colors.black)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPeriod = value!;
                if (selectedPeriod == 'Custom') {
                  _selectDateRange(context);
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period buttons (similar to tabs)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPeriodButton('Week', Icons.calendar_today),
                _buildPeriodButton('2 Weeks', Icons.calendar_today),
                _buildPeriodButton('Month', Icons.calendar_today),
                _buildPeriodButton('Custom', Icons.calendar_today),
              ],
            ),
            SizedBox(height: 20),
            // List of tasks with progress bars and dots
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['task'],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(task['completed'], style: TextStyle(color: Colors.grey)),
                            Text(selectedPeriod, style: TextStyle(color: Colors.black)),
                          ],
                        ),
                        SizedBox(height: 8),
                        _buildProgressBar(task['progress'], task['color'], task['completed']),
                        SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          selectedPeriod = label;
        });
      },
      icon: Icon(icon, size: 16, color: Colors.black),
      label: Text(label, style: TextStyle(color: Colors.black)),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        side: BorderSide(color: selectedPeriod == label ? Colors.blue : Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color, String completed) {
    final parts = completed.split('/');
    final completedCount = int.parse(parts[0]);
    final totalCount = int.parse(parts[1]);

    // Определяем количество овальных фигур
    int totalDots = totalCount; // Общее количество точек
    int filledDots = (completedCount / totalCount * totalDots).round();

    // Размеры для овальных фигур
    double baseWidth;
    double height = 10.0; // Фиксированная высота

    // Определяем ширину овальных фигур в зависимости от totalCount
    if (totalCount == 7) {
      baseWidth = 50.0; // Длинные овалы для 7/7
    } else if (totalCount == 14) {
      baseWidth = 23.0; // Чуть короче для 14/14
    } else if (totalCount == 30) {
      baseWidth = 8.5; // Еще меньше для 30/30
    } else if (totalCount == 60) {
      baseWidth = 8.5; // Самые маленькие для 60/60
    } else {
      baseWidth = 15.0; // По умолчанию
    }

    return Wrap(
      spacing: 4.0, // Отступ между овальными фигурами
      runSpacing: 4.0, // Отступ между строками
      children: List.generate(totalDots, (index) {
        bool isFilled = index < filledDots;
        return Container(
          width: isFilled ? baseWidth : baseWidth, // Динамическая ширина
          height: height, // Фиксированная высота
          decoration: BoxDecoration(
            color: isFilled ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(5), // Овальная форма
          ),
        );
      }),
    );
  }
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }
}