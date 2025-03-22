import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'services/photo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize photo manager
  await PhotoManager.requestPermissionExtend();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final PhotoService _photoService = PhotoService();
  bool _isPermissionChecked = false;
  bool _isThemeLoaded = false;
  
  static const String _themePreferenceKey = 'theme_mode';

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
    _checkPermissions();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString(_themePreferenceKey);
      
      if (savedThemeMode != null) {
        setState(() {
          _themeMode = savedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
          _isThemeLoaded = true;
        });
      } else {
        setState(() {
          _isThemeLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading theme preference: $e');
      setState(() {
        _isThemeLoaded = true;
      });
    }
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  Future<void> _checkPermissions() async {
    // Check permissions when app starts
    await _photoService.checkPermission();
    setState(() {
      _isPermissionChecked = true;
    });
  }

  void toggleTheme() {
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setState(() {
      _themeMode = newMode;
    });
    _saveThemePreference(newMode);
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while theme is being loaded
    if (!_isThemeLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'PhotoSync',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a73e8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a73e8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        onThemeToggle: toggleTheme,
        photoService: _photoService,
      ),
    );
  }
}
