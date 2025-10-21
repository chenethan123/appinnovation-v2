import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';
import 'services/course_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/background_sync_service.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase for cross-device sync
  if (ApiConfig.enableSync) {
    await Supabase.initialize(
      url: ApiConfig.supabaseUrl,
      anonKey: ApiConfig.supabaseAnonKey,
    );
    print('✅ Supabase initialized - cross-device sync enabled');
  }
  
  // Initialize notification service
  await NotificationService().initialize();
  
  // Load default courses from JSON into database
  await CourseService().loadDefaultCourses();
  
  // Auto-sync on launch if user is logged in
  if (ApiConfig.enableSync && AuthService().isLoggedIn) {
    print('🔄 Auto-syncing on launch...');
    SyncService().fullSync().then((result) {
      if (result.success) {
        print('✅ Launch sync complete: ${result.message}');
      } else {
        print('⚠️ Launch sync partial: ${result.message}');
      }
    }).catchError((e) {
      print('❌ Launch sync error: $e');
    });
    
    // Start background sync timer
    BackgroundSyncService().startBackgroundSync();
  }
  
  runApp(const ProviderScope(child: FormulaQuizzerApp()));
}

// Global Supabase client accessor
final supabase = Supabase.instance.client;

class FormulaQuizzerApp extends StatelessWidget {
  const FormulaQuizzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formula Quizzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AuthScreen(), // Show login first, then navigate to HomeScreen
    );
  }
}
