import 'package:flutter/material.dart';

import '../screens/settings_screen.dart';

Widget settingsAppBarAction(BuildContext context) {
  return IconButton(
    tooltip: 'Configurações',
    icon: const Icon(Icons.settings),
    onPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    },
  );
}
