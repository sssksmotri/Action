import 'package:flutter/material.dart';
import '../Service/database_helper.dart';
import '../main.dart'; // Импорт routeObserver и _currentSessionId

class LoggableScreen extends StatefulWidget {
  final String screenName;
  final Widget child;
  final int currentSessionId;

  const LoggableScreen({
    Key? key,
    required this.screenName,
    required this.child,
    required this.currentSessionId,
  }) : super(key: key);

  @override
  _LoggableScreenState createState() => _LoggableScreenState();
}

class _LoggableScreenState extends State<LoggableScreen> with RouteAware {
  DateTime? _startTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    _logTimeSpent();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // Логируем время входа на экран
    _startTime = DateTime.now();
  }

  @override
  void didPop() {
    // Логируем время покидания экрана
    _logTimeSpent();
  }

  @override
  void didPushNext() {
    // Логируем время при переходе на следующий экран
    _logTimeSpent();
  }

  void _logTimeSpent() async {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      final totalSeconds = duration.inSeconds; // Total seconds spent
      final totalMinutes = duration.inMinutes; // Total minutes spent

      // Форматируем вывод
      String formattedTime = '${totalSeconds % 60} seconds'; // Остаток секунд
      if (totalMinutes > 0) {
        formattedTime = '$totalMinutes minutes and ${totalSeconds % 60} seconds';
      }

      print('Logged time for ${widget.screenName}: $formattedTime');

      // Log the time in seconds, which is fine for your existing code
      await DatabaseHelper.instance.logSectionTime(
          widget.currentSessionId, widget.screenName, totalSeconds);
    }
  }


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
