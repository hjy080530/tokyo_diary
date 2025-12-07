// lib/main.dart 업데이트
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'services/mongo_service.dart';
import 'services/notification_service.dart';
import 'core/theme/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  try {
    await mongoService.connect();
  } catch (e) {
    debugPrint('Mongo init failed: $e');
  }
  await notificationService.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '懂慌日誌',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansKR',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.primary,
          onSecondary: Colors.white,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,
        splashColor: AppColors.background,
        highlightColor: AppColors.background,
        hoverColor: AppColors.background,
        focusColor: AppColors.background,
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: AppColors.background,
          selectionHandleColor: AppColors.primary,
          cursorColor: AppColors.primary,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
