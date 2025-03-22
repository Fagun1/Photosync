import 'package:flutter/material.dart';
import '../widgets/top_app_bar.dart';

class FoldersScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const FoldersScreen({super.key, required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(title: 'Folders', onThemeToggle: onThemeToggle),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Albums',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://source.unsplash.com/random/800x800?city=$index',
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Location ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(index + 1) * 5} items',
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Memories',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  height: 180,
                  child: Center(child: Text('Coming soon...')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
