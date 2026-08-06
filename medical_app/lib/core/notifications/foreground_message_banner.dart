import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 앱이 포그라운드일 때 푸시가 오면 카카오톡처럼 화면 상단에 잠깐 떴다가 사라지는 배너.
/// FcmService.incomingMessage를 구독해서, 지금 어떤 화면에 있든 위에 겹쳐서 보여줌.
class ForegroundMessageBanner extends StatefulWidget {
  final ValueListenable<RemoteMessage?> incomingMessage;
  final void Function(RemoteMessage message)? onTapMessage;

  const ForegroundMessageBanner({
    super.key,
    required this.incomingMessage,
    this.onTapMessage,
  });

  @override
  State<ForegroundMessageBanner> createState() => _ForegroundMessageBannerState();
}

class _ForegroundMessageBannerState extends State<ForegroundMessageBanner> {
  RemoteMessage? _visibleMessage;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    widget.incomingMessage.addListener(_onIncomingMessage);
  }

  @override
  void dispose() {
    widget.incomingMessage.removeListener(_onIncomingMessage);
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onIncomingMessage() {
    final message = widget.incomingMessage.value;
    if (message?.notification == null) return;

    _dismissTimer?.cancel();
    setState(() => _visibleMessage = message);
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (!mounted) return;
    setState(() => _visibleMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final notification = _visibleMessage?.notification;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          offset: notification == null ? const Offset(0, -1.2) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: notification == null ? 0 : 1,
            child: GestureDetector(
              onTap: () {
                final message = _visibleMessage;
                _dismiss();
                if (message != null) widget.onTapMessage?.call(message);
              },
              onVerticalDragEnd: (_) => _dismiss(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppTheme.brandGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                notification?.title ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (notification?.body != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  notification!.body!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
