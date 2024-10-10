import 'package:action_notes/Service/NotificationService.dart';
import 'database_helper.dart';

class HabitReminderService {
  final NotificationService notificationService = NotificationService();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<void> initializeReminders() async {
    List<Map<String, dynamic>> habits = await dbHelper.queryAllHabits();
    print('Fetched habits: $habits'); // Логируем загруженные привычки

    for (var habit in habits) {
      // Если привычка не архивирована, планируем уведомления для неё
      if (habit['archived'] == 0) {
        print('Planning reminders for habit: ${habit['name']}'); // Логируем, какую привычку обрабатываем
        List<Map<String, dynamic>> reminders = await dbHelper.queryReminders(habit['id']);
        print('Fetched reminders for habit ${habit['name']}: $reminders'); // Логируем загруженные напоминания

        // Если напоминаний нет, добавляем их в таблицу Reminders
        if (reminders.isEmpty) {
          print('No reminders found for habit ${habit['name']}.'); // Логируем отсутствие напоминаний
        } else {
          // Если напоминания есть, планируем их
          for (var reminder in reminders) {
            if (reminder['is_active'] == 1) {
              print('Scheduling reminder: ${reminder['time']} for habit: ${habit['name']}'); // Логируем планируемое напоминание
              await scheduleReminder(
                habit['id'],
                reminder['time'],
                habit['name'], // Передаем имя привычки
                reminder, // Передаем напоминание для проверки дней недели
              );
            } else {
              print('Reminder with ID ${reminder['id']} is inactive.'); // Логируем неактивные напоминания
            }
          }
        }
      } else {
        print('Habit ${habit['name']} is archived, skipping.'); // Логируем пропуск архивированных привычек
      }
    }
  }


  // Планирование уведомления
  Future<void> scheduleReminder(int habitId, String time, String habitName, Map<String, dynamic> reminder) async {
    DateTime now = DateTime.now();

    List<bool> days = [
      reminder['monday'] == 1,
      reminder['tuesday'] == 1,
      reminder['wednesday'] == 1,
      reminder['thursday'] == 1,
      reminder['friday'] == 1,
      reminder['saturday'] == 1,
      reminder['sunday'] == 1,
    ];

    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        DateTime scheduledDate = DateTime(
          now.year,
          now.month,
          now.day + ((i + 7 - now.weekday) % 7), // Calculate next occurrence of the day
          int.parse(time.split(':')[0]), // Hour
          int.parse(time.split(':')[1]), // Minute
        );

        await notificationService.scheduleNotification(
          habitId,
          'Время заняться привычкой!', // Updated title
          'Напоминание о привычке: $habitName', // Используем имя привычки
          scheduledDate,
        );
      }
    }
  }

  // Отмена всех уведомлений для привычки
  Future<void> cancelAllReminders(int habitId) async {
    print('Отмена всех напоминаний для привычки с ID: $habitId');
    List<Map<String, dynamic>> reminders = await dbHelper.queryReminders(habitId);
    for (var reminder in reminders) {
      int reminderId = reminder['id'];
      await notificationService.cancelNotification(habitId);
      print('Отменено напоминание с ID: $reminderId');
    }
  }

  // Добавление нового напоминания
  Future<int> addNewReminder(int habitId, String time, List<bool> days) async {
    // Создаем карту для дней недели
    Map<String, dynamic> daysOfWeek = {
      'monday': days[0] ? 1 : 0,
      'tuesday': days[1] ? 1 : 0,
      'wednesday': days[2] ? 1 : 0,
      'thursday': days[3] ? 1 : 0,
      'friday': days[4] ? 1 : 0,
      'saturday': days[5] ? 1 : 0,
      'sunday': days[6] ? 1 : 0,
    };

    // Получаем имя привычки
    String habitName = (await dbHelper.queryHabitById(habitId))['name'];

    int reminderId = await dbHelper.insertReminder({
      'habit_id': habitId,
      'time': time,
      ...daysOfWeek, // Добавляем значения для дней недели
      'is_active': 1,
    });

    print('Новое напоминание добавлено в таблицу Reminders с ID: $reminderId');

    // Планируем новое напоминание, передавая имя привычки
    await scheduleReminder(habitId, time, habitName, daysOfWeek);

    return reminderId; // Вернуть созданный идентификатор напоминания
  }

  // Удаление напоминания
  Future<void> deleteReminder(int reminderId) async {
    // Сначала получаем напоминание, чтобы узнать habit_id
    Map<String, dynamic>? reminder = await dbHelper.queryReminderById(reminderId); // Здесь нужен метод для получения напоминания

    if (reminder != null) {
      int habitId = reminder['habit_id'];

      // Отменяем уведомление для этого напоминания
      await notificationService.cancelNotification(habitId);

      // Удаляем напоминание из базы данных
      int deletedCount = await dbHelper.deleteReminder(reminderId);
      print('Уведомление с ID $reminderId отменено.');

      if (deletedCount > 0) {
        print('Reminder with ID $reminderId deleted successfully.');

        // Проверяем, остались ли другие напоминания для привычки
        List<Map<String, dynamic>> remainingReminders = await dbHelper.queryReminders(habitId);
        if (remainingReminders.isEmpty) {
          print('No reminders left for habit ID $habitId, disable its notification switch.');
        }
      } else {
        print('Failed to delete reminder with ID $reminderId.');
      }
    } else {
      print('Reminder with ID $reminderId not found.');
    }
  }
}
