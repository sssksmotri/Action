import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'main.dart';
import 'stat.dart';
import 'add.dart';
class NoteAddPage extends StatefulWidget {
  const NoteAddPage({super.key});

  @override
  _NoteAddPageState createState() => _NoteAddPageState();
}

class _NoteAddPageState extends State<NoteAddPage> {
  bool _isNoteVisible = false;
  int _selectedIndex = 0;

  final TextEditingController _noteController = TextEditingController();
  String? _selectedOption;
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

  // Список вариантов для выпадающего списка
  final List<String> _options = [
    'Why would I do that?',
    'How will I feel when I receive it?',
    'How will it contribute to the lives of other?',
    'How will my life change after a long time from doing this regular action?',
    'Free Note',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
             IconButton(
              icon: Image.asset(
                'assets/images/ar_back.png',
                width: 30,
                height: 30,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Text(
              'Read 100 pages',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildQuestionDropdown(),
              const SizedBox(height: 16),
              if (_isNoteVisible) _buildNoteInput(),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    "Here you can add reinforcements by answering a series of questions or writing a note. These reinforcements will help you stick to doing the action. You can write your thoughts and attach links to materials.",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
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
            _buildNavItem(1, 'assets/images/Edit.png', isSelected: true),
            _buildNavItem(2, 'assets/images/Plus.png'),
            _buildNavItem(3, 'assets/images/Calendar.png'),
            _buildNavItem(4, 'assets/images/Setting.png'),
          ],
        ),
      ),

    );
  }

  Widget _buildQuestionDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: DropdownButton<String>(
            hint: Text("What do I want to get?"),
            value: _selectedOption,
            isExpanded: true, // Устанавливаем isExpanded в true
            onChanged: (String? newValue) {
              setState(() {
                _selectedOption = newValue; // Устанавливаем выбранное значение
                _isNoteVisible = true; // Показываем поле для заметки при выборе
              });
            },
            items: _options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() {
              _isNoteVisible = true; // Показываем поле для заметки
            });
          },
          icon: const Icon(Icons.add_outlined, color: Color(0xFF5F33E1)),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your note:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Your note',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Логика сохранения заметки
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5F33E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Save",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Устанавливаем жирность шрифта
                      color: Colors.white, // Устанавливаем цвет текста
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isNoteVisible = false; // Скрываем форму
                    _noteController.clear(); // Очищаем поле заметки
                  });
                },
                icon: Icon(Icons.close, color: Colors.red),
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
  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: Icon(Icons.home, color: Colors.purple), onPressed: () {}),
          IconButton(icon: Icon(Icons.edit, color: Colors.purple), onPressed: () {}),
          IconButton(icon: Icon(Icons.add, color: Colors.purple), onPressed: () {}),
          IconButton(icon: Icon(Icons.calendar_today, color: Colors.purple), onPressed: () {}),
          IconButton(icon: Icon(Icons.settings, color: Colors.purple), onPressed: () {}),
        ],
      ),
    );
  }
}
