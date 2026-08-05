import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/convenience/presentation/providers/notification_deep_link_provider.dart';
import '../features/auth/presentation/providers/auth_dependency_providers.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'theme/app_theme.dart';

class SumItApp extends ConsumerStatefulWidget {
  const SumItApp({super.key});

  @override
  ConsumerState<SumItApp> createState() => _SumItAppState();
}

class _SumItAppState extends ConsumerState<SumItApp> {
  StreamSubscription<void>? _sessionExpirationSubscription;

  @override
  void initState() {
    super.initState();
    _sessionExpirationSubscription = ref
        .read(authSessionCoordinatorProvider)
        .onExpired
        .listen((_) => appRouter.go(RouteNames.login));
    Future<void>.microtask(() async {
      try {
        await ref.read(notificationDisplayServiceProvider).start();
      } catch (_) {
        // Notification presentation must not block deep-link initialization.
      }
      await ref.read(notificationDeepLinkCoordinatorProvider).start();
    });
  }

  @override
  void dispose() {
    unawaited(_sessionExpirationSubscription?.cancel());
    super.dispose();
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
