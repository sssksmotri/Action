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

class ArchivePage extends StatefulWidget {
  const ArchivePage({Key? key}) : super(key: key);

  @override
  _ArchivePageState createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  int _selectedIndex = 4;
  bool _isFolderPressed = true; // Состояние для кнопки папки (сразу нажатая)
  List<Map<String, dynamic>> _archivedHabits = []; // Список архивированных привычек

  @override
  void initState() {
    super.initState();
    _loadArchivedHabits(); // Загружаем архивированные привычки
  }

  // Метод для загрузки архивированных привычек из БД
  void _loadArchivedHabits() async {
    DatabaseHelper db = DatabaseHelper.instance; // Создаем экземпляр класса БД
    List<Map<String, dynamic>> habits = await db.getArchivedHabits(); // Получаем архивированные привычки
    setState(() {
      _archivedHabits = habits; // Обновляем состояние
    });
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
                        fontSize: 18,
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
                        onPressed: () {
                          Navigator.of(context).pop(); // Закрыть диалог
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEEE9FF), // Легкий фиолетовый фон
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
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
                        onPressed: () {
                          Navigator.of(context).pop(); // Закрыть диалог
                          _deleteHabit(habitId); // Вызов метода удаления
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red, // Красный фон
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
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
            Navigator.of(context).pop(true);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'archive'.tr(),
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
                  iconSize: 32,
                  padding: EdgeInsets.zero,
                  icon: Image.asset(
                    'assets/images/Chart.png',
                    width: 32,
                    height: 32,
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen()));
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
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
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
                  _activeHabit(habitId); // Выводим сообщение в консоль при нажатии
                },
                child: Image.asset(
                  'assets/images/Upload.png',
                  width: 24,
                  height: 24,
                ),
              ),
              Transform.rotate(
                angle: -90 * (3.141592653589793238 / 180),
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'Delete') {
                      _showDeleteDialog(context, title, habitId, () {});
                    } else {
                      print('Selected: $value');
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                       PopupMenuItem<String>(
                        value: 'Edit',
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(tr('edit')),
                        ),
                      ),
                       PopupMenuItem<String>(
                        value: 'Delete',
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(tr('delete'), style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ];
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
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
    DatabaseHelper db = DatabaseHelper.instance; // Получаем экземпляр вашего помощника по базе данных

    // Обновляем привычку в базе данных, устанавливая archived в 1
    await db.updateHabit({'id': habitId, 'archived': 0}); // Архивируем привычку

    // Обновляем состояние
    setState(() {
      // Создаем новый список на основе существующего, чтобы избежать ошибок с изменяемыми объектами
     _loadArchivedHabits();
    });
  }

}
