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
  String _currentScreenName = "AddNotesPage";
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

      // Загружаем заметки из базы данных
      for (var note in notesFromDb) {
        _questions.add({
          "selectedOption": note['question'],
          "isNoteInputVisible": true,
          "noteController": TextEditingController(text: note['note']),
          "id": note['id'],  // Уникальный идентификатор заметки
          "isSaveButtonVisible": false,  // Кнопка "Сохранить" скрыта для загруженных заметок
          "isDropdownVisible": false,
          "isQuestionBlockVisible": false
        });
        _questions.add({
          "selectedOption": null,
          "isNoteInputVisible": false,
          "noteController": TextEditingController(),
          "id": null,
          "isSaveButtonVisible": true, // Кнопка "Сохранить" видима для новой заметки
          "isDropdownVisible": true,
          "isQuestionBlockVisible": false // Открываем блок выбора вопроса
        });
      }

      // Если нет заметок, добавляем пустую заметку и открываем блок выбора
      if (_questions.isEmpty) {
        _questions.add({
          "selectedOption": null,
          "isNoteInputVisible": false,
          "noteController": TextEditingController(),
          "id": null,
          "isSaveButtonVisible": true, // Кнопка "Сохранить" видима для новой заметки
          "isDropdownVisible": true,
          "isQuestionBlockVisible": false // Открываем блок выбора вопроса
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

  void _removeNoteWidget(int index) {
    setState(() {
      final noteId = _questions[index]['id'];

      // Если заметка была сохранена в БД (id != null и тип int), удаляем её из БД
      if (noteId != null && noteId is int) {
        _deleteNoteFromDb(noteId);
      }

      // Удаляем элемент из списка _questions, если в нем больше одного элемента
      if (_questions.length > 0) {
        _questions.removeAt(index);
      } else {
        print('Ошибка: невозможно удалить последний вопрос.');
      }
    });
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
                DatabaseHelper.instance.logAction(
                    _currentSessionId!,
                    "Пользователь нажал кнопку назад и вернулся в NotesPage из: $_currentScreenName"
                );
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




  void _addNewQuestion() {
    setState(() {

      // Добавляем новый вопрос с null id для не сохранённой заметки
      _questions.add({
        "selectedOption": null,
        "isNoteInputVisible": false,
        "noteController": TextEditingController(),
        "isSaveButtonVisible": true,
        "isDropdownVisible": true,
        "isQuestionBlockVisible": false,
        "id": null  // Новый элемент, еще не добавленный в базу, поэтому id = null
      });
    });
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


    }
  }

  Widget _buildQuestionDropdown(int index) {
    // Проверяем, нужно ли отображать данный виджет
    if (!(_questions[index]["isDropdownVisible"] ?? false)) {
      return SizedBox.shrink(); // Возвращаем пустое пространство, если dropdown скрыт
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      isTextVisible=false;
                      _saveTextVisibility(false);
                      // Переключаем видимость текущего блока вопросов
                      _questions[index]["isQuestionBlockVisible"] =
                      !(_questions[index]["isQuestionBlockVisible"] ?? false);
                    });
                    await DatabaseHelper.instance.logAction(
                        widget.sessionId,
                        "Пользователь ${_questions[index]["isQuestionBlockVisible"] ? "открыл" : "закрыл"} блок для выбора варианта вопроса №${index + 1} на экране: $_currentScreenName"
                    );
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _questions[index]["selectedOption"] ?? tr("What_do_I_want_to_get"),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _questions[index]["selectedOption"] != null
                                  ? Color(0xFF212121)
                                  : Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Image.asset(
                            'assets/images/arr_vn.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    // Добавляем новый вопрос в список
                    _addNewQuestion();
                    isTextVisible=false;
                    _saveTextVisibility(false);
                    // Логируем действие пользователя
                    await DatabaseHelper.instance.logAction(
                        widget.sessionId,
                        "Пользователь добавил новый вопрос на экране: $_currentScreenName"
                    );
                  },
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
          const SizedBox(height: 8),
          // Отображаем блок вопросов, если он видим
          if (_questions[index]["isQuestionBlockVisible"] ?? false)
            _buildQuestionBlock(index),
        ],
      ),
    );
  }



  Widget _buildNoteInputCard(int index) {
    return _questions[index]["isNoteInputVisible"] && _questions[index]["selectedOption"] != null
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9F9),
                      borderRadius: BorderRadius.circular(12),
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
                SizedBox(width: 6,),
                if (!(_questions[index]["isSaveButtonVisible"] ?? true)) ...[
                  // Plus icon appears if the note has been saved
                  GestureDetector(
                    onTap: () async {
                      // Add a new question after the current one
                      _addNewQuestion();
                      isTextVisible = false;
                      _saveTextVisibility(false);
                      await DatabaseHelper.instance.logAction(
                        widget.sessionId,
                        "Пользователь добавил новый вопрос на экране: $_currentScreenName",
                      );
                    },
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
                  SizedBox(width: 8),
                ],
                if (!(_questions[index]["isSaveButtonVisible"] ?? true))
                  GestureDetector(
                    onTap: () async
                    {
                      _removeNoteWidget(index);
                      await DatabaseHelper.instance.logAction(
                          widget.sessionId,
                          "Пользователь удалил вопрос №${index + 1} на экране: $_currentScreenName"
                      );
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
              minLines: 5,
              maxLines: 10,
              controller: _questions[index]["noteController"],
              decoration: InputDecoration(
                hintText: tr('Your_note'),
                filled: true,
                fillColor: Color(0xFFF8F9F9),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
                DatabaseHelper.instance.logAction(
                    _currentSessionId!,
                    "Пользователь завершил ввод текста для вопроса №${index + 1} с текстом: \"${_questions[index]["noteController"].text}\" на экране: $_currentScreenName"
                );
              },
            ),
            const SizedBox(height: 16),
            if (_questions[index]["isSaveButtonVisible"] ?? true)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        _addNoteToDbDirectly(index);
                        setState(() {
                          _questions[index]["isSaveButtonVisible"] = false;
                          _questions[index]["isDropdownVisible"] = false;
                        });
                        await DatabaseHelper.instance.logAction(
                            widget.sessionId,
                            "Пользователь сохранил заметку для вопроса №${index + 1} с текстом: \"${_questions[index]["noteController"].text}\" на экране: $_currentScreenName"
                        );
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
                    onTap: () async
                    {
                      _removeNoteWidget(index);
                      await DatabaseHelper.instance.logAction(
                          widget.sessionId,
                          "Пользователь удалил вопрос №${index + 1} на экране: $_currentScreenName"
                      );
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

  Widget _buildQuestionBlock(int index) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _options.asMap().entries.map((entry) {
          int optionIndex = entry.key;
          String option = entry.value;

          return GestureDetector(
            onTap: () async {
              setState(() {
                // Устанавливаем выбранный элемент и скрываем блок вопросов
                _questions[index]["selectedOption"] = option;
                _questions[index]["isNoteInputVisible"] = true;
                _questions[index]["isQuestionBlockVisible"] = false;
                isTextVisible=false;
                _saveTextVisibility(false);

                // Скрываем dropdown текущего вопроса после выбора опции
                _questions[index]["isDropdownVisible"] = true;


              });
              await DatabaseHelper.instance.logAction(
                  widget.sessionId,
                  "Пользователь выбрал вариант: \"$option\" для вопроса №${index + 1} на экране: $_currentScreenName"
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: optionIndex == 0
                    ? BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
                    : optionIndex == _options.length - 1
                    ? BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
                    : BorderRadius.zero,
                border: Border(
                  bottom: BorderSide.none,
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    color: _questions[index]["selectedOption"] == option
                        ? Color(0xFF5F33E1)
                        : Color(0xFF212121),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveTextVisibility(bool isVisible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTextVisible', isVisible);
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
}
