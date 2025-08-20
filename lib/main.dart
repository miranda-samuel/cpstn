import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_screen.dart';
import 'screens/select_language_screen.dart';
import 'screens/level_selection_screen.dart';
import 'screens/game_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

// Global route observer
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize SharedPreferences with error handling
  try {
    final prefs = await SharedPreferences.getInstance();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => AuthProvider(prefs: prefs)..init(),
          ),
        ],
        child: const CodeSnapApp(),
      ),
    );
  } catch (e) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize application. Please restart.',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class CodeSnapApp extends StatelessWidget {
  const CodeSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: Colors.tealAccent,
          backgroundColor: Colors.grey[50],
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/select_language': (context) => const SelectLanguageScreen(),
        '/levels': (context) => const LevelSelectionScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/game/') ?? false) {
          final uri = Uri.parse(settings.name!);
          final segments = uri.pathSegments;

          if (segments.length == 3) {
            final language = segments[1];
            final level = int.tryParse(segments[2]);

            if (level != null) {
              final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
              final username = authProvider.username ?? 'guest';

              return MaterialPageRoute(
                builder: (context) => GameScreen(
                  language: language,
                  level: level,
                  username: username,
                ),
                settings: settings,
              );
            }
          }
        }

        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Page not found: ${settings.name}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    child: const Text('Return Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: child!,
              ),
            ),
          ],
        );
      },
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
    );
  }
}