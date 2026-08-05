import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/convenience/presentation/providers/notification_deep_link_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class SumItApp extends ConsumerStatefulWidget {
  const SumItApp({super.key});

  @override
  ConsumerState<SumItApp> createState() => _SumItAppState();
}

class _SumItAppState extends ConsumerState<SumItApp> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      return ref.read(notificationDeepLinkCoordinatorProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
