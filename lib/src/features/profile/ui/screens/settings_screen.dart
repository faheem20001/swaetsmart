import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.psychology),
            title: Text('AI Preferences'),
            subtitle: Text('Customize your coaching style'),
          ),
          ListTile(
            leading: Icon(Icons.watch),
            title: Text('Connect Wearable'),
            subtitle: Text('Sync with Apple Health, Google Fit'),
          ),
          ListTile(
            leading: Icon(Icons.palette),
            title: Text('Theme'),
            subtitle: Text('Switch between light and dark mode'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
          ),
        ],
      ),
    );
  }
}