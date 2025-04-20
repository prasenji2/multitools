import 'package:flutter/material.dart';
import 'package:multi_utility_tools/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark theme'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable or disable notifications'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Implement notification settings
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Premium Features'),
            subtitle: const Text('Upgrade to access premium features'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to premium features screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium features coming soon!'),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Learn more about the app'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Multi-Utility Tools',
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 32),
                applicationLegalese: '© 2025 Multi-Utility Tools',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'A multi-utility tools app providing various online tools in one platform.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
