import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'notes.dart';
import '../main.dart';
import 'stat.dart';
import 'add.dart';
import 'package:action_notes/Service/database_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:action_notes/Widgets/loggable_screen.dart';
class NoteAddPage extends StatefulWidget {
  final int habitId;
  final int sessionId;

  const NoteAddPage({Key? key, required this.habitId, required this.sessionId}) : super(key: key);

  @override
  _NoteAddPageState createState() => _NoteAddPageState();
}

class _NoteAddPageState extends State<NoteAddPage> {
  String habitName = "";
  final TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _questions = [
    {"selectedOption": null, "isNoteInputVisible": false, "noteController": TextEditingController()}
  ];
  final List<String> _options = [
    tr('why_would_I_do_that'), // локализованная строка
    tr('how_will_I_feel_when_I_receive_it'), // локализованная строка
    tr('how_will_it_contribute_to_the_lives_of_others'), // локализованная строка
    tr('how_will_my_life_change'), // локализованная строка
    tr('free_note'), // локализованная строка
  ];
  bool isTextVisible = true;
  int? _currentSessionId;
  @override
  void initState() {
    super.initState();
    _fetchHabitName();   // Загружаем имя привычки
    _loadNotes();        // Загружаем заметки из базы данных
    _loadTextVisibility();
    _currentSessionId = widget.sessionId;
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
      _notes = notesFromDb;
      _questions.clear();

      for (var note in notesFromDb) {
        _questions.add({
          "selectedOption": note['question'],
          "isNoteInputVisible": true,
          "noteController": TextEditingController(text: note['note']),
          "id": note['id'],  // Уникальный идентификатор заметки
          "isSaveButtonVisible": false  // Кнопка "Сохранить" скрыта для загруженных заметок
        });
      }

      // Если нет заметок, добавляем пустую заметку
      if (_questions.isEmpty) {
        _questions.add({
          "selectedOption": null,
          "isNoteInputVisible": false,
          "noteController": TextEditingController(),
          "id": null,
          "isSaveButtonVisible": true  // Кнопка "Сохранить" видима для новой заметки
        });
      }
    });
  }
  Future<void> _loadTextVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isTextVisible = prefs.getBool('isTextVisible') ?? true;
    });
  }

  // Метод для сохранения состояния текста в SharedPreferences
  Future<void> _hideTextPermanently() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTextVisible', false);
    setState(() {
      isTextVisible = false;
    });
  }

  Future<int> _saveNoteToDb(String noteText, String question) async {
    final id = await DatabaseHelper.instance.insertHabitNote({
      'habit_id': widget.habitId,
      'note': noteText,
      'question': question,
      'created_at': DateTime.now().toString(),
    });
    return id;
  }

  Future<void> _deleteNoteFromDb(int noteId) async {
    try {
      await DatabaseHelper.instance.deleteHabitNote(noteId);
      await _loadNotes(); // Обновление списка заметок после удаления
      print('Данные успешно удалены');
    } catch (e) {
      print('Ошибка при удалении данных: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        backgroundColor: const Color(0xFFF8F9F9),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Основное содержимое
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        return Column(
                          key: ValueKey(_questions[index]["id"]),
                          children: [
                            _buildQuestionDropdown(index),
                            const SizedBox(height: 16),
                            _buildNoteInputCard(index),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Текст в середине экрана, который исчезает после добавления инпута
            if (isTextVisible)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    tr("reinforcement_text"), // Используем локализованный ключ
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }




  void _addNoteToDbDirectly(int index) async {
    final note = _questions[index]["noteController"].text;
    final question = _questions[index]["selectedOption"];

    if (note.isNotEmpty && question != null) {
      final id = await _saveNoteToDb(note, question);

      setState(() {
        _questions[index]["id"] = id;
        _questions[index]["isSaveButtonVisible"] = false;
      });

      await _loadNotes();  // Перезагрузите все заметки после добавления
    }
  }




  void _addNewQuestion() {
    setState(() {
      _questions.add({
        "selectedOption": null,
        "isNoteInputVisible": false,
        "noteController": TextEditingController(),
        "isSaveButtonVisible": true,
        "id":null
      });
    });
  }


  Widget _buildQuestionDropdown(int index) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: Align(
                    alignment: Alignment.centerLeft, // Выравнивание текста
                    child: Text(
                      tr("What_do_I_want_to_get"),
                      style: const TextStyle(color: Color(0xFF212121)),
                    ),
                  ),
                  value: _questions[index]["selectedOption"],
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      _questions[index]["selectedOption"] = newValue;
                      _questions[index]["isNoteInputVisible"] = true;
                      _hideTextPermanently(); // Скрываем текст навсегда после добавления инпута
                    });
                  },
                  items: _options.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Align( // Выравнивание текста в выпадающем списке
                        alignment: Alignment.centerLeft, // Выравнивание текста
                        child: Text(
                          value,
                          style: TextStyle(
                            color: _questions[index]["selectedOption"] == value
                                ? Color(0xFF5F33E1)
                                : Color(0xFF212121),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  dropdownColor: Colors.white,
                  icon: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Image.asset(
                      'assets/images/arr_vn.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return _options.map((String value) {
                      return Align( // Выравнивание текста выбранного элемента
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: Color(0xFF212121),
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (index == _questions.length - 1)
            GestureDetector(
              onTap: _addNewQuestion,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(0xFFEEE9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Color(0xFF5F33E1),
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }




  Widget _buildNoteInputCard(int index) {
    return _questions[index]["isNoteInputVisible"] &&
        _questions[index]["selectedOption"] != null
        ? SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Текст вопроса и крестик рядом с ним, если кнопка "Сохранить" была нажата
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9F9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      _questions[index]["selectedOption"] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // Крестик появляется справа от вопроса только после нажатия кнопки "Сохранить"
                if (!(_questions[index]["isSaveButtonVisible"] ?? true))
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        final noteId = _questions[index]['id'];
                        if (noteId != null) {
                          _deleteNoteFromDb(noteId);
                          _questions.removeAt(index);
                        } else {
                          _questions.removeAt(index);
                          print('Ошибка: noteId равен null');
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
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
            const SizedBox(height: 16),
            TextField(
              controller: _questions[index]["noteController"],
              decoration: InputDecoration(
                hintText: tr('Your_note'),
                filled: true,
                fillColor: Color(0xFFF8F9F9),
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: 5,
              textInputAction: TextInputAction.done, // Добавлено для завершения
              onSubmitted: (value) {
                FocusScope.of(context).unfocus(); // Закрывает клавиатуру
              },
            ),
            const SizedBox(height: 16),
            // Кнопка "Сохранить" и крестик, который изначально находится рядом с кнопкой
            if (_questions[index]["isSaveButtonVisible"] ?? true)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _addNoteToDbDirectly(index);
                        setState(() {
                          // Скрываем кнопку "Сохранить" и перемещаем крестик к вопросу
                          _questions[index]["isSaveButtonVisible"] = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5F33E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        tr('save'),
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
                    onTap: () async {
                      setState(() {
                        final noteId = _questions[index]['id'];
                        if (noteId != null) {
                          _deleteNoteFromDb(noteId);
                          _questions.removeAt(index);
                        } else {
                          _questions.removeAt(index);
                          print('Ошибка: noteId равен null');
                        }
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
      ),
    )
        : SizedBox.shrink();
  }





  Widget _buildBottomNavigationBar() {
    return Container(
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

  void _onItemTapped(int index) {
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
}
