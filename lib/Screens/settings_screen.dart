import 'package:action_notes/Screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'feedback.dart';
import 'notifications_screen.dart';
import 'main.dart';
import 'legal.dart';
import 'feedback.dart';
import 'suggest.dart';
import 'notes.dart';
import 'add.dart';

// Import other necessary pages


class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 4;
  bool isEnglish = true; // Track if the language is English

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
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddActionPage()),
      );
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotesPage()),
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
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          // Container for language toggle switch with labels
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Text(
                  'Ru',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5F33E1),
                  ),
                ),
                Switch(
                  value: isEnglish,
                  onChanged: (bool value) {
                    setState(() {
                      isEnglish = value;
                    });
                  },
                  activeColor: const Color(0xFF5F33E1),
                  inactiveThumbColor: const Color(0xFF5F33E1),
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                ),
                const Text(
                  'En',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5F33E1),
                  ),
                ),
              ],
            ),
          ),
        ],
        elevation: 0,
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
              child: _buildSettingContainer('Notifications'),
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
              child: _buildSettingContainer('Legal Information'),
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
              child: _buildSettingContainer('Feedback'),
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
              child: _buildSettingContainer('Suggest Improvements'),
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
}
