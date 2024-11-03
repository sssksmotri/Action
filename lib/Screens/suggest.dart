import 'package:flutter/material.dart';
import 'package:action_notes/main.dart';
import 'settings_screen.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'add.dart';
import 'notes.dart';
import 'stat.dart';
import 'package:action_notes/Widgets/loggable_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:action_notes/Service/database_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class SuggestPage extends StatefulWidget {
  final int sessionId;
  const SuggestPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  _SuggestPageState createState() => _SuggestPageState();
}

class _SuggestPageState extends State<SuggestPage> {
  int _selectedIndex = 4;
  final _formKey = GlobalKey<FormState>();
  bool isEnglish = true;
  bool _showSuffix = true;
  // Controllers for the text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _suggestionController = TextEditingController();
  int? _currentSessionId;
  String _currentScreenName = "SuggestPage";


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

  Future<void> _submitForm() async {
    final apiKey = dotenv.env['API_KEY'];
    final dbUrl = dotenv.env['DATABASE_SUG'];
    // Проверка валидации
    if (_nameController.text.isEmpty) {
      _showValidationDialog('Пожалуйста, введите ваше имя.');
      return;
    }

    // Проверка валидности электронной почты только если она не пустая
    if (_emailController.text.isNotEmpty && !_isValidEmail(_emailController.text)) {
      _showValidationDialog('Пожалуйста, введите корректный адрес электронной почты.');
      return;
    }

    if (_suggestionController.text.isEmpty) {
      _showValidationDialog('Пожалуйста, введите ваше предложение.');
      return;
    }

    final url = Uri.parse(dbUrl!);

    // Подготавливаем данные для отправки
    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'text': _suggestionController.text,
    };

      // Отправка POST-запроса с JSON-данными
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json','X-API-Key':apiKey!},
        body: jsonEncode(data),
      );

      // Выводим статус и тело ответа для отладки
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Проверка кода ответа от сервера
      if (response.statusCode == 201) {
        _showSubmissionDialog(); // Успешная отправка
      } else if (response.statusCode >= 500) {
        // Ошибки сервера (5xx)
        _showErrorDialog('Ошибка сервера. Попробуйте позже.');
      } else if (response.statusCode >= 400) {
        // Ошибки клиента (4xx)
        // Возможно, вы получите информацию о конкретных ошибках из тела ответа
        final errorMessage = jsonDecode(response.body)['detail'] ?? 'Ошибка отправки данных. Проверьте введенные данные и повторите попытку.';
        _showErrorDialog(errorMessage);
      } else {
        // Другие коды ошибок
        _showErrorDialog('Неожиданная ошибка: ${response.statusCode}.');
      }
    }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ошибка'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }



  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ошибка валидации'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  bool _isValidEmail(String email) {
    // Простой паттерн для проверки корректности адреса электронной почты
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
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
          onPressed: () async {
            await DatabaseHelper.instance.logAction(
                _currentSessionId!,
                "Пользователь нажал кнопку назад и вернулся в SetingPage из: $_currentScreenName"
            );
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
                    _submitForm();
                    DatabaseHelper.instance.logAction(widget.sessionId, "Пользователь нажал кнопку отправить предложение на экране: $_currentScreenName");
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
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    // Логируем, когда пользователь начал вводить текст
                    DatabaseHelper.instance.logAction(widget.sessionId, "Пользователь начал вводить текст в поле: $hintText на экране: $_currentScreenName" );
                  } else {
                    // Логируем, когда пользователь закончил вводить текст
                    DatabaseHelper.instance.logAction(widget.sessionId, "Пользователь закончил вводить текст в поле: $hintText на экране: $_currentScreenName");
                  }
                },

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
                onSubmitted: (text) {
                  // Логируем, когда пользователь завершил ввод текста
                  DatabaseHelper.instance.logAction(widget.sessionId, "Пользователь завершил ввод текста: $text в поле: $hintText на экране: $_currentScreenName");
                },
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
