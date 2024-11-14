import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'feedback.dart';
import 'notifications_screen.dart';
import 'legal.dart';
import 'suggest.dart';
import '../main.dart';
import 'add.dart';
import 'notes.dart';
import 'stat.dart';
import 'package:action_notes/Widgets/loggable_screen.dart';
import 'package:action_notes/Service/database_helper.dart';

class SettingsPage extends StatefulWidget {
  final int sessionId;
  const SettingsPage({Key? key, required this.sessionId}) : super(key: key);
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 4;
  int? _currentSessionId;
  String _currentScreenName = "SettingPage";

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F9),
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Settings'.tr(), // Локализованный текст
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  'Ru'.tr(), // Локализованная метка для русского
                  style: const TextStyle(fontSize: 16),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0), // Прямые отступы вокруг переключателя
                  child: Container(
                    height: 25, // Высота контейнера
                    width: 50, // Ширина контейнера
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Color(0xFF5F33E1), // Цвет ободка
                        width: 1, // Ширина ободка
                      ),
                      borderRadius: BorderRadius.circular(15), // Скругление углов
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          // Переключение языка между английским и русским
                          final isEnglish = context.locale.languageCode == 'en';
                          context.setLocale(isEnglish ? const Locale('ru') : const Locale('en'));
                        });
                        await DatabaseHelper.instance.logAction(
                          _currentSessionId!,
                          "Пользователь переключил язык на '${context.locale.languageCode}' на экране: $_currentScreenName.",
                        );
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: context.locale.languageCode == 'en' ? const Color(0xFFEEE9FF) : const Color(0xFFEEE9FF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          Positioned(
                            left: context.locale.languageCode == 'en' ? null : 2, // Отступ слева
                            right: context.locale.languageCode == 'en' ? 2 : null, // Отступ справа
                            top: 2, // Отступ сверху
                            child: Container(
                              width: 18, // Ширина шарика
                              height: 18,
                              decoration: BoxDecoration(
                                color: context.locale.languageCode == 'en' ? const Color(0xFF5F33E1) : const Color(0xFF5F33E1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Text(
                  'En'.tr(), // Локализованная метка для английского
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                await DatabaseHelper.instance.logAction(widget.sessionId, "Переход с экрана: $_currentScreenName на экран: NotificationsPage");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoggableScreen(
                      screenName: 'NotificationsPage',
                      child: NotificationsPage(
                        sessionId: _currentSessionId!, // Передаем sessionId в NotificationsPage
                      ),
                      currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                    ),
                  ),
                );
              },
              child: _buildSettingContainer('notifications'.tr()),
            ),
            GestureDetector(
              onTap: () async {
                await DatabaseHelper.instance.logAction(widget.sessionId, "Переход с экрана: $_currentScreenName на экран: LegalPage");
                // Переход на LegalPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoggableScreen(
                      screenName: 'LegalPage',
                      child: legalPage(
                        sessionId: _currentSessionId!, // Передаем sessionId в LegalPage
                      ),
                      currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                    ),
                  ),
                );
              },
              child: _buildSettingContainer('legal_information'.tr()),
            ),
            GestureDetector(
              onTap: () async {
                await DatabaseHelper.instance.logAction(widget.sessionId, "Переход с экрана: $_currentScreenName на экран: FeedbackPage");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoggableScreen(
                      screenName: 'FeedbackPage',
                      child: FeedbackPage(
                        sessionId: _currentSessionId!, // Передаем sessionId в FeedbackPage
                      ),
                      currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                    ),
                  ),
                );
              },
              child: _buildSettingContainer('feedback'.tr()),
            ),
            GestureDetector(
              onTap: () async {
                await DatabaseHelper.instance.logAction(widget.sessionId, "Переход с экрана: $_currentScreenName на экран: SuggestPage");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoggableScreen(
                      screenName: 'SuggestPage',
                      child: SuggestPage(
                        sessionId: _currentSessionId!, // Передаем sessionId в SuggestPage
                      ),
                      currentSessionId: _currentSessionId!, // Передаем currentSessionId в LoggableScreen
                    ),
                  ),
                );
              },
              child: _buildSettingContainer('suggest_improvements'.tr()),
            ),
          ],
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
