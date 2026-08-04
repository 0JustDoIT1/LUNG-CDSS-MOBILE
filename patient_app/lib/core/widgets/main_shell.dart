import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes/route_names.dart';
import '../../app/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    required this.child,
    super.key,
  });

  final Widget child;

  static const List<String> _locations = [
    RouteNames.symptoms,
    RouteNames.appointments,
    RouteNames.home,
    RouteNames.results,
    RouteNames.more,
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    final int index = _locations.indexWhere(
      (path) => location.startsWith(path),
    );

    return index < 0 ? 2 : index;
  }

  void _onDestinationSelected(
    BuildContext context,
    int index,
  ) {
    context.go(_locations[index]);
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          _onDestinationSelected(context, index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: '증상·복약',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '예약',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '검사',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: '더보기',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(RouteNames.chatbot);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }
}