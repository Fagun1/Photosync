import 'package:flutter/material.dart';
import '../screens/user_screen.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onThemeToggle;

  const TopAppBar({
    super.key,
    required this.title,
    required this.onThemeToggle,
  });

  void _navigateToUserScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserScreen(onThemeToggle: onThemeToggle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () => _navigateToUserScreen(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
