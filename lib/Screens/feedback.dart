import 'package:action_notes/Screens/suggest.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'add.dart';
import 'notes.dart';
import 'stat.dart';
import 'settings_screen.dart';
import 'package:action_notes/Widgets/loggable_screen.dart';
import 'package:action_notes/Service/database_helper.dart';
class FeedbackPage extends StatefulWidget {
  final int sessionId;
  const FeedbackPage({Key? key, required this.sessionId}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _selectedIndex = 4;
  int? _currentSessionId;
  String _currentScreenName = "FeedbackPage";
  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
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
        leading: IconButton(
          icon: Image.asset(
            'assets/images/ar_back.png',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            DatabaseHelper.instance.logAction(
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
                'feedback'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // First set of text and button
            _buildFeedbackSection(
              'appstore_review'.tr(),  // Локализованная часть "If you liked everything, please "
              'leave_a_review'.tr(),  // Локализованная часть "leave a review"
              'in_the_AppStore'.tr(),  // Локализованная часть "in the AppStore."
              'appstore'.tr(),  // Локализованное название кнопки "AppStore"
                  () {
                // TODO: Добавьте действие для кнопки AppStore здесь
              },
            ),
            const SizedBox(height: 40), // Пробел между секциями
            _buildFeedbackSection(
              'contact_us_part1'.tr(),  // Локализованная часть "If you are dissatisfied with something, "
              'write_to_us'.tr(),  // Локализованная часть "write to us"
              'we_will_fix'.tr(),  // Локализованная часть "we will fix the error."
              'suggest_improvements'.tr(),  // Локализованная кнопка "Suggest improvements"
                  () {
                    DatabaseHelper.instance.logAction(
                        _currentSessionId!,
                        "Пользователь нажал кнопку и переместился на экран  SuggestPage из: $_currentScreenName"
                    );
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
              isSecondSection: true,  // Указывает, что это вторая секция для стилизации
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

  Widget _buildFeedbackSection(String text1, String text2, String text3, String buttonText, VoidCallback onPressed, {bool isSecondSection = false}) {
    return Column(
      children: [
        Center(
          child: RichText(
            textAlign: TextAlign.center, // Center align the text
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold, // Bold text
                color: Colors.black,
              ),
              children: [
                TextSpan(text: text1),
                TextSpan(
                  text: text2,
                  style: const TextStyle(
                    color: Color(0xFF5F33E1), // Purple color
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
                TextSpan(text: text3),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20), // Space between text and button
        _buildActionButton(buttonText, onPressed),
      ],
    );
  }

  Widget _buildActionButton(String buttonText, VoidCallback onPressed) {
    return Container(
      width: 200,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5F33E1), // Цвет кнопки
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18), // Закругленные углы
          ),
        ),
        onPressed: onPressed,
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
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
