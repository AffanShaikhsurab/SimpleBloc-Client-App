

// Add a Settings screen for additional functionality
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'), backgroundColor: Colors.black),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Security'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to Security settings
              },
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Language'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to Language settings
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to Notification settings
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help & Support'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to Help & Support screen
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to About screen
              },
            ),
          ],
        ),
      ),
    );
  }
}