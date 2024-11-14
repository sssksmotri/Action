import 'package:flutter/material.dart';
import '../main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'add.dart';
import 'dart:ui';
import 'stat.dart';
import 'stat_tabl.dart';
import 'package:action_notes/Service/database_helper.dart'; // Импортируйте свой класс для работы с БД
import 'package:action_notes/Widgets/loggable_screen.dart';
class ArchivePage extends StatefulWidget {
  final int sessionId;

  const ArchivePage({Key? key, required this.sessionId}) : super(key: key);

  @override
  _ArchivePageState createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  int _selectedIndex = 4;
  bool _isFolderPressed = true; // Состояние для кнопки папки (сразу нажатая)
  List<Map<String, dynamic>> _archivedHabits = []; // Список архивированных привычек
  int? _currentSessionId;
  Map<int, bool> _menuStates = {};
  String _currentScreenName = "ArchivePage";
  @override
  void initState() {
    super.initState();
    _loadArchivedHabits(); // Загружаем архивированные привычки
    _currentSessionId = widget.sessionId;
  }

  // Метод для загрузки архивированных привычек из БД
  void _loadArchivedHabits() async {
    DatabaseHelper db = DatabaseHelper.instance; // Создаем экземпляр класса БД
    List<Map<String, dynamic>> habits = await db.getArchivedHabits(); // Получаем архивированные привычки

    // Выводим данные для отладки
    print("Archived habits loaded: $habits");

    setState(() {
      _archivedHabits = habits; // Обновляем состояние
    });
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


  void _showDeleteDialog(BuildContext context, String taskTitle, int habitId,
      Function() onDelete) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Эффект размытия
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Эффект размытия
              child: Container(
                color: Colors.black.withOpacity(0), // Прозрачный контейнер для сохранения размытия
              ),
            ),
            // Основное содержимое диалогового окна
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              insetPadding: const EdgeInsets.all(10),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "are_you_sure".tr(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,

                      ),
                      children: [
                        TextSpan(
                          text: taskTitle,
                          style: const TextStyle(
                            color: Color(0xFF5F33E1), // Фиолетовый цвет для названия задачи
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: "?",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Кнопка "No, leave it"
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await DatabaseHelper.instance.logAction(widget.sessionId, "Отменил удаление привычки на экране: $_currentScreenName");
                          Navigator.of(context).pop(); // Закрыть диалог
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEEE9FF), // Легкий фиолетовый фон
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Уменьшение горизонтальных отступов

                        ),
                        child: Text(
                          "no_leave_it".tr(),
                          style: TextStyle(
                            color: Color(0xFF5F33E1), // Фиолетовый текст
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // Отступ между кнопками
                    // Кнопка "Yes, delete"
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await DatabaseHelper.instance.logAction(widget.sessionId, "Удалил привычку на экране: $_currentScreenName");
                          Navigator.of(context).pop(); // Закрыть диалог
                          _deleteHabit(habitId); // Вызов метода удаления
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red, // Красный фон
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Уменьшение горизонтальных отступов
                        ),
                        child: Text(
                          "yes_delete".tr(),
                          style: TextStyle(
                            color: Colors.white, // Белый текст
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
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
                "Пользователь нажал кнопку назад и вернулся в HomePage из: $_currentScreenName"
            );
            Navigator.of(context).pop(true);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
              Transform.translate(
            offset: Offset(-16, 0), // Смещение текста влево
              child: Text(
                  'archive'.tr(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              ],
            ),
            Row(
              children: [
                IconButton(
                  iconSize: 32,
                  padding: EdgeInsets.zero,
                  icon: Image.asset(
                    'assets/images/Chart.png',
                    width: 28,
                    height: 28,
                  ),
                  onPressed: () {
                    DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь нажал кнопку графики и перешел в ChartScreen из: $_currentScreenName"
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoggableScreen(
                          screenName: 'ChartScreen',
                          child: ChartScreen(
                            sessionId: _currentSessionId!, // Передаем sessionId в ChartScreen
                          ),
                          currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(0xFF5F33E1),
                    shape: BoxShape.circle,
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
                      padding: EdgeInsets.all(4.0),
                      child: Image.asset(
                        'assets/images/Folder2.png',
                        height: 28,
                        width: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF8F9F9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _archivedHabits.length,
          itemBuilder: (context, index) {
            final habit = _archivedHabits[index];
            return GestureDetector(
              onTap: () {
                // Здесь можно добавить действие по нажатию на привычку
              },
              child: _buildSettingContainer(habit['name'], habit['id']),
            );
          },
        ),
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
            _buildNavItem(3, 'assets/images/Calendar.png'),
            _buildNavItem(4, 'assets/images/Setting.png'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingContainer(String title, int habitId) {

    return Container(
      padding: const EdgeInsets.all(12),
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  DatabaseHelper.instance.logAction(
                      _currentSessionId!,
                      "Пользователь вернул из архива действия: $habitId на экране: $_currentScreenName"
                  );
                  _activeHabit(habitId); // Обработка нажатия на иконку загрузки
                },
                child: Image.asset(
                  'assets/images/Upload.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 8), // Отступ между иконками
              PopupMenuButton<String>(
                icon: Transform.scale(
                  scale: _menuStates[habitId] != null && _menuStates[habitId]! ? 3.4 : 2.3,// Увеличение в 1.5 раза, если меню открыто
                  child: Image.asset(
                    _menuStates[habitId] != null && _menuStates[habitId]! ? 'assets/images/menu_open.png' : 'assets/images/menu.png',
                    width: 24, // Ширина остается постоянной
                    height: 24, // Высота остается постоянной
                  ),
                ),
                onSelected: (value) {
                  setState(() {

                    _menuStates[habitId] = false; // Закрываем меню после выбора
                  });
                  if (value == 'Delete') {
                    DatabaseHelper.instance.logAction(widget.sessionId, "Выбрал в меню действия: удаления у привычки на экране: $_currentScreenName");// Открываем меню
                    _showDeleteDialog(context, title, habitId, () {});
                  } else {
                    print('Selected: $value');
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'Delete',
                      height: 25,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          tr('delete'),
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ),
                  ];
                },
                constraints: BoxConstraints.tightFor(
                  width: context.locale.languageCode == 'en' ? 80 : 90, // Используем locale от Easy Localization
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                offset: const Offset(0, 30),
                onOpened: () async {
                  await DatabaseHelper.instance.logAction(widget.sessionId, "Открыл меню действия у привычки на экране:$_currentScreenName");// Открываем меню
                  setState(() {
                    _menuStates[habitId] = true;
                  });
                },
                onCanceled: () async  {
                  await DatabaseHelper.instance.logAction(widget.sessionId, "закрыл меню действия у привычки на экране:$_currentScreenName");
                  setState(() {
                    if (_menuStates[habitId] != null) {
                      _menuStates[habitId] = !_menuStates[habitId]!;
                    } else {
                      // Инициализируем состояние по умолчанию, если его еще нет
                      _menuStates[habitId] = true; // или false, в зависимости от вашей логики
                    } // Переключение состояния меню
                  });
                },
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

  Future<void> _deleteHabit(int habitId) async {
    DatabaseHelper db = DatabaseHelper.instance; // Получаем экземпляр вашего помощника по базе данных

    // Удаляем привычку из базы данных
    await db.deleteHabit(habitId);

    setState(() {
      _archivedHabits = List.from(_archivedHabits)..removeWhere((habit) => habit['id'] == habitId);
      _loadArchivedHabits();

    });

  }

  void _activeHabit(int habitId) async {
    DatabaseHelper db = DatabaseHelper.instance; // Get instance of the DatabaseHelper

    // Fetch the current habit from the database to preserve other fields
    var currentHabit = await db.queryHabitById(habitId);
    if (currentHabit == null) {
      print('Ошибка: привычка с ID $habitId не найдена.');
      return;
    }

    // Merge the current habit with the updated values
    Map<String, dynamic> updatedHabit = {
      ...currentHabit,
      'archived': 0,  // Unarchive the habit
    };

    // Attempt to update the habit in the database
    int result = await db.updateHabit(updatedHabit);
    if (result > 0) {
      print('Привычка с ID $habitId успешно активирована.');

      // Update the state by reloading the list of archived habits
      setState(() {
        _loadArchivedHabits();  // Reload archived habits to refresh the UI
      });
    } else {
      print('Ошибка при активации привычки.');
    }
  }


}
