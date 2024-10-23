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

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 4;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddActionPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StatsPage()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                    height: 30, // Высота контейнера
                    width: 50, // Ширина контейнера
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.white, // Цвет ободка
                        width: 2, // Ширина ободка
                      ),
                      borderRadius: BorderRadius.circular(15), // Скругление углов
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          // Переключение языка между английским и русским
                          final isEnglish = context.locale.languageCode == 'en';
                          context.setLocale(isEnglish ? const Locale('ru') : const Locale('en'));
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: context.locale.languageCode == 'en' ? const Color(0xFF5F33E1) : const Color(0xFFEEE9FF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          Positioned(
                            left: context.locale.languageCode == 'en' ? null : 2, // Отступ слева
                            right: context.locale.languageCode == 'en' ? 2 : null, // Отступ справа
                            top: 2, // Отступ сверху
                            child: Container(
                              width: 22, // Ширина шарика
                              height: 22,
                              decoration: BoxDecoration(
                                color: context.locale.languageCode == 'en' ? const Color(0xFFFFFFFF) : const Color(0xFF5F33E1),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
              child: _buildSettingContainer('notifications'.tr()),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const legalPage(),
                  ),
                );
              },
              child: _buildSettingContainer('legal_information'.tr()),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbackPage(),
                  ),
                );
              },
              child: _buildSettingContainer('feedback'.tr()),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuggestPage(),
                  ),
                );
              },
              child: _buildSettingContainer('suggest_improvements'.tr()),
            ),
          ],
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
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 22,
            color: Color(0xFF5F33E1),
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
