import 'package:flutter/material.dart';
import '../main.dart';
import 'settings_screen.dart';

class NotePage extends StatefulWidget {
  const NotePage({Key? key}) : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  int _selectedIndex = 4;
  bool isEnglish = true;

  // Controllers for the text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _suggestionController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
    if (index == 5) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    }
  }

  void _showSubmissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min, // Adjust the size of the dialog
            children: [
              const Text(
                'Your offer has been successfully submitted!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20), // Space between text and button
              SizedBox(
                width: double.infinity, // Full width for the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F33E1), // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15), // Vertical padding
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Return to previous screen
                  },
                  child: const Text(
                    'Home',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Bold text
                      color: Colors.white, // White text
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          'Read 100 pages',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Bold text
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // White card with shadow
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Text field for Name
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Name',
                  ),
                  const SizedBox(height: 10), // Space between fields

                  // Text field for Email
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'E-mail*',
                    suffixText: 'not necessary', // Suffix for not necessary
                  ),
                  const SizedBox(height: 10), // Space between fields

                  // Text field for Suggestions
                  _buildTextField(
                    controller: _suggestionController,
                    hintText: 'Your suggestion',
                    maxLines: 4, // Allow multiple lines
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // Space before button

            // Suggest button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F33E1), // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50), // Padding inside button
              ),
              onPressed: () {
                // Handle button press (send suggestion)
                // You can add your logic here
                print('Name: ${_nameController.text}');
                print('Email: ${_emailController.text}');
                print('Suggestion: ${_suggestionController.text}');
                // Show submission dialog
                _showSubmissionDialog();
              },
              child: const Text(
                'Send',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 24), // Space between button and text

            // Information text
            const Text(
              '*The answer will be provided to the specified mail',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
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
            _buildNavItem(1, 'assets/images/Edit.png', isSelected: true),
            _buildNavItem(2, 'assets/images/Plus.png'),
            _buildNavItem(3, 'assets/images/Calendar.png'),
            _buildNavItem(4, 'assets/images/Setting.png'),
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
        color: const Color(0xFFF8F9F9), // Light background color for text fields
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none, // No border
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding inside text field
          suffixText: suffixText, // Add suffix text to the right
          suffixStyle: const TextStyle(
            color: Color(0xFF5F33E1), // Color for suffix text
            fontSize: 12, // Font size for suffix text
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