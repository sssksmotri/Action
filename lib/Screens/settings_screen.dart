import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isEnglish = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(tr('ru'), style: const TextStyle(color: Colors.black)),
                Switch(
                  value: isEnglish,
                  onChanged: (value) {
                    setState(() {
                      isEnglish = value;
                      context.setLocale(isEnglish ? const Locale('en') : const Locale('ru'));
                    });
                  },
                  activeColor: Colors.purple,
                ),
                Text(tr('en'), style: const TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildListTile(tr('notifications')),
          _buildListTile(tr('legal_information')),
          _buildListTile(tr('feedback')),
          _buildListTile(tr('suggest_improvements')),
        ],
      ),
    );
  }

  Widget _buildListTile(String title) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.purple),
      onTap: () {
        // Handle tile tap
      },
    );
  }
}
