// lib/main.dart 업데이트
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
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
      ),
      // 테스트용으로 MainScreen을 홈으로 설정 (나중에 LoginScreen으로 변경)
      home: const MainScreen(),
      // home: const LoginScreen(),
    );
  }
}