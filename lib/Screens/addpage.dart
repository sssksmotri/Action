import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'notes.dart';
import 'main.dart';
import 'stat.dart';
import 'add.dart';
import 'package:action_notes/Service/database_helper.dart';

class NoteAddPage extends StatefulWidget {
  final int habitId;

  const NoteAddPage({Key? key, required this.habitId}) : super(key: key);

  @override
  _NoteAddPageState createState() => _NoteAddPageState();
}

class _NoteAddPageState extends State<NoteAddPage> {
  String habitName = "";
  final TextEditingController _noteController = TextEditingController();
  String? _selectedOption;
  List<Map<String, dynamic>> _notes = [];
  bool _isNoteInputVisible = false;
  int _selectedIndex = 0;

  final List<String> _options = [
    'Why would I do that?',
    'How will I feel when I receive it?',
    'How will it contribute to the lives of others?',
    'How will my life change after a long time from doing this regular action?',
    'Free Note',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHabitName();   // Загружаем имя привычки
    _loadNotes();        // Загружаем заметки из базы данных
  }

  // Метод для получения имени привычки по ID
  Future<void> _fetchHabitName() async {
    final habit = await DatabaseHelper.instance.queryHabitById(widget.habitId);
    setState(() {
      habitName = habit['name'];
    });
  }

  // Метод для загрузки заметок из базы данных
  Future<void> _loadNotes() async {
    final notesFromDb = await DatabaseHelper.instance.getHabitNotes(widget.habitId);
    setState(() {
      _notes = notesFromDb; // Сохраняем полученные заметки в список
    });
  }
  Future<void> _saveNoteToDb(String noteText, String question) async {
    await DatabaseHelper.instance.insertHabitNote({
      'habit_id': widget.habitId,
      'note': noteText,
      'question': question,  // Сохраняем выбранный вопрос
      'created_at': DateTime.now().toString(),
    });
  }

  // Метод для добавления заметки
  void _addNote() async {
    final noteText = _noteController.text;
    if (noteText.isNotEmpty && _selectedOption != null) {
      await _saveNoteToDb(noteText, _selectedOption!); // Сохраняем заметку и вопрос
      _noteController.clear();
      setState(() {
        _selectedOption = null;
        _isNoteInputVisible = false;
      });
      _loadNotes(); // Перезагружаем заметки из базы данных
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a question and enter a note.')),
      );
    }
  }

  // Метод для удаления заметки
  void _removeNote(int index) async {
    final noteId = _notes[index]['id']; // Получаем id заметки
    await DatabaseHelper.instance.deleteHabitNote(noteId); // Удаляем из БД
    setState(() {
      _notes.removeAt(index); // Убираем заметку из списка
    });
  }

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
              habitName,
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
              _isNoteInputVisible ? _buildNoteInputCard() : Container(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    return _buildNoteCard(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildQuestionDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: Text("What do I want to get?"),
                value: _selectedOption,
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedOption = newValue;
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
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.add, color: Color(0xFF5F33E1)),
            onPressed: () {
              if (_selectedOption != null) {
                setState(() {
                  _isNoteInputVisible = true;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a question first.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Отображаем выбранную тему сверху карточки
          Container(
            padding: const EdgeInsets.all(12), // Устанавливаем отступы
            decoration: BoxDecoration(
              color: Color(0xFFF8F9F9), // Цвет фона
              borderRadius: BorderRadius.circular(12), // Закругленные углы
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              _selectedOption ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Your note',
              filled: true, // Включаем заполнение
              fillColor: Color(0xFFF8F9F9), // Устанавливаем цвет фона
              border: InputBorder.none, // Убираем обводку
              hintStyle: TextStyle(color: Colors.grey), // Цвет текста подсказки
            ),
            maxLines: 5, // Устанавливаем количество строк для ввода
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5F33E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isNoteInputVisible = false; // Закрываем карточку заметки
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE7E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close, color: Color(0xFFFF3B30), size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildNoteCard(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: ListTile(
        title: Text(_notes[index]['question']!), // Отображаем вопрос
        subtitle: Text(_notes[index]['note']!),  // Отображаем заметку
        trailing: IconButton(
          icon: Icon(Icons.close, color: Colors.red),
          onPressed: () => _removeNote(index),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
          color: isSelected ? const Color(0xFF5F33E1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 28,
            height: 28,
            color: isSelected ? Colors.white : const Color(0xFF5F33E1),
          ),
        ),
      ),
    );
  }

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
}
