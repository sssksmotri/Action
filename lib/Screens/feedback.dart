import 'package:flutter/material.dart';
import 'main.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _selectedIndex = 4;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
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
        title: const Text(
          'FeedBack',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
              'If you liked everything, please ',
              'leave a review',
              ' in the AppStore.',
              'AppStore',
                  () {
                // TODO: Add your action for the AppStore button here
              },
            ),
            const SizedBox(height: 40), // Space between sections
            // Second set of text and button
            _buildFeedbackSection(
              'If you are dissatisfied with something, ',
              ' write to us, ',
              'we will fix the error.',
              'Suggest imrovements',
                  () {
                // TODO: Add your action for the Suggest button here
              },
              isSecondSection: true, // Indicate it's the second section for styling
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
              offset: const Offset(0, -2),
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

  Widget _buildFeedbackSection(String text1, String text2, String text3, String buttonText, VoidCallback onPressed, {bool isSecondSection = false}) {
    return Column(
      children: [
        Center(
          child: RichText(
            textAlign: TextAlign.center, // Center align the text
            text: TextSpan(
              style: const TextStyle(
                fontSize: 18,
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5F33E1), // Button color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22), // Rounded corners
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50), // Padding inside button
      ),
      onPressed: onPressed,
      child: Text(
        buttonText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
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
