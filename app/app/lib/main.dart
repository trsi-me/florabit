import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_settings.dart';
import 'app_theme.dart';
import 'notification_service.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await NotificationService.initialize();
  }
  final settings = AppSettings();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  runApp(
    ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: const FlorabitApp(),
    ),
  );
  // تحميل التفضيلات بعد أول إطار حتى تكون قنوات المنصّة جاهزة (يُقلّل أخطاء Pigeon بعد Hot Restart).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    settings.load();
  });
}

class FlorabitApp extends StatelessWidget {
  const FlorabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, _) {
        final dark = settings.darkMode;
        if (!kIsWeb) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: dark ? const Color(0xFF121B16) : Colors.white,
              systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            ),
          );
        }
        return MaterialApp(
          title: 'فلورابيت',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}
