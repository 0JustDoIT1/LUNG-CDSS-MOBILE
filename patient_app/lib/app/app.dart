import 'package:flutter/material.dart';

import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class SumItApp extends StatelessWidget {
  const SumItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '숨잇',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}