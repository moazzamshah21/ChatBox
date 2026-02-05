import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFD4A574),       // brandy / warm amber
          onPrimary: const Color(0xFF2C1810),
          primaryContainer: const Color(0xFF4A3728),
          onPrimaryContainer: const Color(0xFFF5E6D6),
          secondary: const Color(0xFFC9B896),
          onSecondary: const Color(0xFF2C1810),
          surface: const Color(0xFF1A1512),
          onSurface: const Color(0xFFEDE6DF),
          surfaceContainerHighest: const Color(0xFF2C2520),
          onSurfaceVariant: const Color(0xFFC4B5A4),
          outline: const Color(0xFF8B7B6A),
          error: const Color(0xFFE07D6A),
          onError: const Color(0xFF2C1810),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1512),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF231C18),
          foregroundColor: Color(0xFFEDE6DF),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2C2520),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2520),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF3D342C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFD4A574), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF8B7B6A)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFEDE6DF), height: 1.45),
          bodyMedium: TextStyle(color: Color(0xFFC4B5A4), height: 1.45),
          titleMedium: TextStyle(color: Color(0xFFEDE6DF), fontWeight: FontWeight.w600),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFFD4A574),
            backgroundColor: const Color(0xFF4A3728),
          ),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
