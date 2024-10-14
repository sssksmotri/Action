import 'package:flutter/material.dart';
import 'main.dart';
import 'note.dart';
import 'addpage.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'add.dart';
import 'main.dart';
import 'stat.dart';


class ArchivePage extends StatefulWidget {
  const ArchivePage({Key? key}) : super(key: key);

  @override
  _ArchivePageState createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  int _selectedIndex = 4;
  bool _isFolderPressed = true; // Состояние для кнопки папки (сразу нажатая)

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
  void _showDeleteDialog(BuildContext context, String taskTitle,
      Function() onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          // Паддинг для внутреннего контента
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Are you sure you want to delete ",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  children: [
                    TextSpan(
                      text: taskTitle,
                      style: const TextStyle(
                        color: Color(0xFF5F33E1),
                        // Фиолетовый цвет для названия задачи
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
          actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
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
                      backgroundColor: const Color(0xFFEEE9FF),
                      // Легкий фиолетовый фон
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "No, leave it",
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
                      onDelete(); // Вызов метода удаления
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red, // Красный фон
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Yes, delete",
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
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Archive',
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
                  },
                ),

                Container(
                  width: 32, // Ширина контейнера
                  height: 32, // Высота контейнера
                  decoration: BoxDecoration(
                    color: Color(0xFF5F33E1), // Цвет фона
                    shape: BoxShape.circle, // Круглая форма
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
                      padding: EdgeInsets.all(4.0), // Отступы вокруг изображения
                      child: Image.asset(
                        'assets/images/Folder2.png',
                        fit: BoxFit.cover, // Масштабируем изображение
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
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
              },
              child: _buildSettingContainer('Read 100 pages'),
            ),
            GestureDetector(
              onTap: () {
              },
              child: _buildSettingContainer('Read 100 pages'),
            ),
            GestureDetector(
              onTap: () {
              },
              child: _buildSettingContainer('Read 100 pages'),
            ),
            GestureDetector(
              onTap: () {
              },
              child: _buildSettingContainer('Read 100 pages'),
            ),
            GestureDetector(
              onTap: () {
              },
              child: _buildSettingContainer('Read 100 pages'),
            ),


          ],
        ),
      ),
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
  Widget _buildSettingContainer(String title) {
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
          // Текст заголовка
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
              // Иконка перед точками
              Image.asset(
                'assets/images/Upload.png', // Путь к вашей иконке
                width: 24,
                height: 24,
              ),
              Transform.rotate(
                angle: -90 * (3.141592653589793238 / 180), // Поворот на 90 градусов влево
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'Delete') {
                      _showDeleteDialog(context, title, () {
                        // Логика удаления
                      });
                    } else {
                      print('Selected: $value');
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'Edit',
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Edit'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Delete',
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
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
  }
}

