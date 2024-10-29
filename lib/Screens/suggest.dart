import 'package:flutter/material.dart';
import 'package:action_notes/main.dart';
import 'settings_screen.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'add.dart';
import 'notes.dart';
import 'stat.dart';
import 'package:action_notes/Widgets/loggable_screen.dart';

class SuggestPage extends StatefulWidget {
  final int sessionId;
  const SuggestPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  _SuggestPageState createState() => _SuggestPageState();
}

class _SuggestPageState extends State<SuggestPage> {
  int _selectedIndex = 4;
  bool isEnglish = true;
  bool _showSuffix = true;
  // Controllers for the text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _suggestionController = TextEditingController();
  int? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId; // Инициализируем _currentSessionId здесь
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


  void _showSubmissionDialog() {
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
                mainAxisSize: MainAxisSize.min, // Настройка размера диалога
                children: [
                  Text(
                    'yourOfferSubmitted'.tr(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Отступ между текстом и кнопкой
                  SizedBox(
                    width: double.infinity, // Полная ширина для кнопки
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F33E1), // Цвет кнопки
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18), // Закругленные углы
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10), // Вертикальный отступ
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoggableScreen(
                              screenName: 'HomePage',
                              child: HomePage(
                                sessionId: _currentSessionId!, // Передаем sessionId в HomePage
                              ),
                              currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'home'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Жирный текст
                          color: Colors.white, // Белый текст
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents UI shift when keyboard appears
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F9),
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
        elevation: 0,
        title: Row(
          children: [
            Transform.translate(
              offset: Offset(-16, 0), // Смещение текста влево
              child: Text(
                'suggest_improvements'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Жирный текст
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView( // Allows content to scroll when keyboard is open
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // Text field for Name
                    _buildTextField(
                      controller: _nameController,
                      hintText: tr('name'),
                    ),
                    const SizedBox(height: 10), // Space between fields

                    // Text field for Email
                    // Пример использования
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'email'.tr(),
                      suffixText: 'not_necessary'.tr(), // Suffix for not necessary
                    ),



                    const SizedBox(height: 10), // Space between fields

                    // Text field for Suggestions
                    _buildTextField(
                      controller: _suggestionController,
                      hintText: 'your_suggestion'.tr(),
                      maxLines: 4, // Allow multiple lines
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12), // Space before button

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Отступы по бокам
                width: double.infinity, // Ширина на весь экран
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F33E1), // Цвет кнопки
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10), // Высота кнопки
                  ),
                  onPressed: () {
                    // Действие при нажатии на кнопку
                    print('Name: ${_nameController.text}');
                    print('Email: ${_emailController.text}');
                    print('Suggestion: ${_suggestionController.text}');
                    _showSubmissionDialog();
                  },
                  child: Text(
                    'send'.tr(), // Локализованный текст
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.white, // Белый текст
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18), // Space between button and text

              // Information text
              Text(
                'answerProvided'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
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
            _buildNavItem(4, 'assets/images/Setting.png', isSelected: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? suffixText, // Optional suffix text
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9F9), // Серый цвет фона для текстового поля
        borderRadius: BorderRadius.circular(15), // Закругленные углы
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              onChanged: (text) {
                // Скрыть суффикс, если пользователь начал вводить текст
                setState(() {
                  _showSuffix = text.isEmpty; // Показывать суффикс, только если текст пустой
                });
              },
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey), // Цвет подсказки (hint text)
                border: InputBorder.none, // Без границы
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Отступы внутри текстового поля
              ),
            ),
          ),
          // Отображение суффикса всегда
          if (suffixText != null && _showSuffix) // Показывать текст суффикса, если он предоставлен и _showSuffix == true
            Padding(
              padding: const EdgeInsets.only(right: 8.0), // Добавить отступ справа
              child: Text(
                suffixText,
                style: const TextStyle(
                  color: Colors.grey, // Цвет для текста суффикса
                  fontSize: 12, // Размер шрифта для текста суффикса
                ),
              ),
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
