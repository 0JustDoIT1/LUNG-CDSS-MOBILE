import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/convenience/presentation/providers/notification_deep_link_provider.dart';
import '../features/convenience/presentation/providers/security_settings_provider.dart';
import '../features/auth/presentation/providers/auth_dependency_providers.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/pin_lock_screen.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'theme/app_theme.dart';

class SumItApp extends ConsumerStatefulWidget {
  const SumItApp({super.key});

  @override
  ConsumerState<SumItApp> createState() => _SumItAppState();
}

class _SumItAppState extends ConsumerState<SumItApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _sessionExpirationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sessionExpirationSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    final authState = ref.read(authProvider).asData?.value;
    if (authState?.isLoggedIn == true) {
      ref.read(securitySettingsProvider.notifier).lock();
    }
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
      builder: (context, child) => _AppLockGate(child: child),
    );
  }
}

class _AppLockGate extends ConsumerWidget {
  const _AppLockGate({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(securitySettingsProvider);
    final auth = ref.watch(authProvider);
    return settings.when(
      loading: () => const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => ColoredBox(
        color: Colors.white,
        child: Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(securitySettingsProvider),
            child: const Text('보안 설정 다시 불러오기'),
          ),
        ),
      ),
      data: (value) {
        final loggedIn = auth.asData?.value.isLoggedIn == true;
        if (loggedIn && value.isLocked) {
          return PinLockScreen(onUnlocked: () {});
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
