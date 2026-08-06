import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/auth/session_controller.dart';
import 'core/notifications/foreground_message_banner.dart';
import 'core/router/app_router.dart';
import 'core/security/security_settings_controller.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'main.dart';

class MedicalApp extends StatelessWidget {
  const MedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()..restore()),
        ChangeNotifierProvider(create: (_) => AppSettingsController()..load()),
        ChangeNotifierProvider(create: (_) => SecuritySettingsController()),
      ],
      child: const _MedicalAppView(),
    );
  }
}

class _MedicalAppView extends StatefulWidget {
  const _MedicalAppView();

  @override
  State<_MedicalAppView> createState() => _MedicalAppViewState();
}

class _MedicalAppViewState extends State<_MedicalAppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(
      context.read<SessionController>(),
      context.read<SecuritySettingsController>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();

    return MaterialApp.router(
      title: '숨-잇 Soom-it',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: Stack(
            children: [
              child!,
              ForegroundMessageBanner(incomingMessage: fcmService.incomingMessage),
            ],
          ),
        );
      },
      routerConfig: _router,
    );
  }
}