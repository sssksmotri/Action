import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Для создания графиков

class ChartScreen extends StatefulWidget {
  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _selectedChart = 0; // 0 - BarChart, 1 - LineChart
  int _selectedTab = 0; // 0 - W, 1 - 2W, 2 - M
  bool _showPercent = false; // Переключение между количеством и процентами

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
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Statistics',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
      body: Column(
        children: <Widget>[
          // Переключение между вкладками W, 2W, M
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  fillColor: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text('W', style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text('2W', style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text('M', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                  isSelected: [_selectedTab == 0, _selectedTab == 1, _selectedTab == 2],
                  onPressed: (int index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),
              ],
            ),
          ),

          // Переключение между гистограммой и линейным графиком
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ToggleButtons(
              fillColor: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(Icons.bar_chart, color: _selectedChart == 0 ? Colors.purple : Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(Icons.show_chart, color: _selectedChart == 1 ? Colors.purple : Colors.grey),
                ),
              ],
              onPressed: (int index) {
                setState(() {
                  _selectedChart = index;
                });
              },
              isSelected: [_selectedChart == 0, _selectedChart == 1],
            ),
          ),

          // Переключение между количеством и процентами
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  fillColor: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text('Quantity', style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text('Percent', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                  isSelected: [_showPercent == false, _showPercent == true],
                  onPressed: (int index) {
                    setState(() {
                      _showPercent = index == 1;
                    });
                  },
                ),
              ],
            ),
          ),

          // Отображение графика в зависимости от выбора
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
                    color: Colors.purple,
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
                    color: Colors.purple,
                    width: 2,
                  )
                ],
              ),
            ),
          ),

          // Выбор даты
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              '< July, 11 - July, 17 >',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.day, this.quantity, this.percent);
  final String day;
  final double quantity;
  final double percent;
}
