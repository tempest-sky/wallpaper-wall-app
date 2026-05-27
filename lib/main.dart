import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/app_settings_state.dart';
import 'models/wallpaper_state.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WallpaperWallApp());
}

class WallpaperWallApp extends StatelessWidget {
  const WallpaperWallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WallpaperState>(create: (_) => WallpaperState()),
        ChangeNotifierProvider<AppSettingsState>(create: (_) => AppSettingsState()),
      ],
      child: Consumer<AppSettingsState>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Wallpaper Wall',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C3AED),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF080A12) : const Color(0xFFF7F3FF),
      appBarTheme: const AppBarTheme(centerTitle: false),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          minimumSize: const Size(0, 42),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          minimumSize: const Size(0, 42),
        ),
      ),
    );
  }
}