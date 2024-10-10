import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class ActionsScreen extends StatefulWidget {
  @override
  _ActionsScreenState createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('actions').tr(), // Локализуем заголовок
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionItem("go_to_gym".tr(), true),
            _buildActionItem("read_100_pages".tr(), true),
            _buildActionItem("take_pills".tr(), false, progress: "1/4"),
            _buildActionItem("drink_2_liters_of_water".tr(), false, progress: "0.4/2"),
            const Spacer(),
            if (!_isToday()) _buildTodayButton(), // Показать кнопку возврата, если дата не сегодня
            _buildBottomDateSelector(), // Кнопка выбора даты
          ],
        ),
      ),
    );
  }

  bool _isToday() {
    return _selectedDate.year == _today.year &&
        _selectedDate.month == _today.month &&
        _selectedDate.day == _today.day;
  }

  Widget _buildActionItem(String action, bool isCompleted, {String? progress}) {
    return ListTile(
      title: Text(action),
      trailing: isCompleted
          ? Icon(Icons.check_circle, color: Colors.green)
          : progress != null
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(progress, style: const TextStyle(color: Colors.orange)),
          const SizedBox(width: 8),
          const Icon(Icons.cancel, color: Colors.orange),
        ],
      )
          : const Icon(Icons.cancel, color: Colors.orange),
    );
  }

  Widget _buildBottomDateSelector() {
    // Форматируем дату в виде "October, 7" с учетом локализации
    String formattedDate = DateFormat('MMMM, d', Localizations.localeOf(context).toString()).format(_selectedDate);

    return GestureDetector(
      onTap: () {
        _showCalendarDialog(); // Показать диалог при нажатии
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.purple),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
              },
            ),
            Text(
              formattedDate,
              style: const TextStyle(color: Colors.purple, fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.purple),
              onPressed: () {
                if (_selectedDate.isBefore(_today)) {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedDate = _today; // Возвращаемся к сегодняшней дате
          });
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text('go_to_today'.tr()), // Локализуем текст кнопки
      ),
    );
  }

  // Функция для показа календаря в виде диалога
  void _showCalendarDialog() {
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
                TableCalendar(
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _selectedDate,
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.purple),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.purple),
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
                    return day.isBefore(_today); // Блокируем завтрашние дни
                  },
                  locale: Localizations.localeOf(context).toString(), // Устанавливаем локализацию для календаря
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
