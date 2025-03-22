import 'package:flutter/material.dart';

class UserScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const UserScreen({super.key, required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              'https://source.unsplash.com/random/200x200?portrait',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'John Doe',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'john.doe@example.com',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: 'Settings',
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('App Theme'),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (bool value) {
                    onThemeToggle();

                    // Get the messenger from the current context
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Switched to ${value ? 'dark' : 'light'} theme',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('Notifications'),
                trailing: Icon(Icons.chevron_right),
              ),
              const ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Privacy'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Content',
            children: [
              const ListTile(
                leading: Icon(Icons.photo_library_outlined),
                title: Text('My Albums'),
                trailing: Icon(Icons.chevron_right),
              ),
              const ListTile(
                leading: Icon(Icons.favorite_outline),
                title: Text('Favorites'),
                trailing: Icon(Icons.chevron_right),
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archived'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'System',
            children: [
              const ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help & Support'),
                trailing: Icon(Icons.chevron_right),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About'),
                trailing: Icon(Icons.chevron_right),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () {
                  // Handle sign out
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Card(elevation: 0, child: Column(children: children)),
      ],
    );
  }
}
