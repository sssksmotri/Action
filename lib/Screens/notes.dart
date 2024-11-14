import 'package:flutter/material.dart';
import 'settings_screen.dart';
import '../main.dart';
import 'add.dart';
import 'stat.dart';
import 'addpage.dart';
import 'package:action_notes/Service/database_helper.dart'; // Импортируйте ваш класс DatabaseHelper
import 'package:easy_localization/easy_localization.dart';
import 'package:action_notes/Widgets/loggable_screen.dart';

class NotesPage extends StatefulWidget {
  final int sessionId;
  const NotesPage({Key? key, required this.sessionId}) : super(key: key);
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  int _selectedIndex = 4;
  bool _showArchived = false; // Переменная для отслеживания состояния отображения архивных привычек
  int? _currentSessionId;
  String _currentScreenName = "NotesPage";
  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId; // Инициализируем _currentSessionId здесь
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


  // Получение привычек из базы данных
  Future<List<Map<String, dynamic>>> fetchHabits() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    return _showArchived
        ? await dbHelper.getArchivedHabits() // Получаем архивные привычки
        : await dbHelper.queryActiveHabits(); // Получаем активные привычки
  }

  // Получение архивированных привычек
  Future<List<Map<String, dynamic>>> getArchivedHabits() async {
    final db = await DatabaseHelper.instance.database; // Получаем базу данных
    return await db.query('habits', where: 'archived = ?', whereArgs: [1]); // Получаем архивированные привычки
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F9),
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            tr('Notes'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                'assets/images/Folder.png',
              ),
            ),     // Иконка архивной кнопки
            onPressed: () async {
              await DatabaseHelper.instance.logAction(widget.sessionId, "Пользователь нажал показать архивные привычки на экране: $_currentScreenName");
              setState(() {
                _showArchived = !_showArchived; // Переключаем состояние отображения
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchHabits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No habits found.'));
            } else {
              final habits = snapshot.data!;
              return ListView.builder(
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return GestureDetector(
                    onTap: () async {
                     await DatabaseHelper.instance.logAction(
                          _currentSessionId!,
                          "Пользователь перешел на экран: AddNotesPage для привычки с ID: ${habit['id']}, на экране: $_currentScreenName "
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoggableScreen(
                            screenName: 'NoteAddPage',
                            child: NoteAddPage(
                              habitId: habit['id'], // Передаем ID привычки
                              sessionId: _currentSessionId!, // Передаем sessionId в NoteAddPage
                            ),
                            currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                          ),
                        ),
                      );
                    },
                    child: _buildSettingContainer(habit['name']),
                  );
                },
              );
            }
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
            _buildNavItem(1, 'assets/images/Edit.png', isSelected: true),
            _buildNavItem(2, 'assets/images/Plus.png'),
            _buildNavItem(3, 'assets/images/Calendar.png'),
            _buildNavItem(4, 'assets/images/Setting.png'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingContainer(String title) {
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
          Image.asset(
            'assets/images/arr_right.png',
            width: 24,
            height: 24,
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
}
