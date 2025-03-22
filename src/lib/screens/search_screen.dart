import 'package:flutter/material.dart';
import '../widgets/top_app_bar.dart';

class SearchScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const SearchScreen({super.key, required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(title: 'Search', onThemeToggle: onThemeToggle),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search photos...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3 * 255),
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Searches',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Center(child: Text('No recent searches')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
