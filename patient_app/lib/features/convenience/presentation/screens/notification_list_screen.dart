import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/models/patient_notification.dart';
import '../../data/notification_deep_link_coordinator.dart';
import '../providers/notification_deep_link_provider.dart';
import '../providers/notification_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationsProvider);
    final processingNotificationIds = ref.watch(notificationReadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: SafeArea(
        child: notificationState.when(
          loading: () => const AppLoadingView(message: '알림을 불러오는 중입니다.'),
          error: (error, stackTrace) => AppErrorView(
            title: '알림을 불러오지 못했습니다.',
            message: _errorMessage(error),
            onRetry: () {
              ref.invalidate(notificationsProvider);
            },
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const AppEmptyView(
                icon: Icons.notifications_none_rounded,
                title: '새로운 알림이 없습니다.',
                description: '새로운 검사 결과나 예약 알림이 도착하면 이곳에서 확인할 수 있습니다.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
                await ref.read(notificationsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: notifications.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final isProcessing = processingNotificationIds.contains(
                    notification.id,
                  );

                  return _NotificationCard(
                    notification: notification,
                    isProcessing: isProcessing,
                    onTap: isProcessing
                        ? null
                        : () {
                            _handleNotificationTap(context, ref, notification);
                          },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  static Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    PatientNotification notification,
  ) async {
    if (!notification.isRead) {
      await _markAsRead(context, ref, notification.id);
      if (!context.mounted) return;
    }

    final result = ref
        .read(notificationDeepLinkCoordinatorProvider)
        .handleInAppDeepLink(notification.deepLink);
    if (result == NotificationNavigationResult.invalid ||
        result == NotificationNavigationResult.unsupported) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('해당 알림의 화면을 열 수 없습니다.')));
    }
  }

  static Future<void> _markAsRead(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
  ) async {
    try {
      await ref
          .read(notificationReadProvider.notifier)
          .markAsRead(notificationId);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_markAsReadErrorMessage(error))));
    }
  }

  static String _markAsReadErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }

      if (error.statusCode == 403) {
        return '알림을 변경할 권한이 없습니다.';
      }

      if (error.statusCode == 404) {
        return '해당 알림을 찾을 수 없습니다.';
      }

      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다.';
      }

      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해주세요.';
      }
    }

    return '알림을 읽음 처리하지 못했습니다.';
  }

  static String _errorMessage(Object error) {
    if (error is FormatException) {
      return '알림 형식을 확인할 수 없습니다.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }

      if (error.statusCode == 403) {
        return '알림을 조회할 권한이 없습니다.';
      }

      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다. 다시 시도해 주세요.';
      }

      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인한 후 다시 시도해 주세요.';
      }
    }

    return '알림을 불러오지 못했습니다. 다시 시도해 주세요.';
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isProcessing,
    required this.onTap,
  });

  final PatientNotification notification;
  final bool isProcessing;
  final VoidCallback? onTap;

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.year}.$month.$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor(context, notification.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isProcessing
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      ),
                    )
                  : Icon(_iconData(notification.category), color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                              ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatDateTime(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(String category) {
    switch (category) {
      case 'case_review':
        return Icons.description_outlined;
      case 'appointment':
        return Icons.calendar_month_outlined;
      case 'medication':
        return Icons.medication_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'triage':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _iconColor(BuildContext context, String category) {
    switch (category) {
      case 'case_review':
        return Colors.blue.shade700;
      case 'appointment':
        return Colors.green.shade700;
      case 'medication':
        return Colors.orange.shade700;
      case 'chat':
        return Colors.teal.shade700;
      case 'triage':
        return Colors.red.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
