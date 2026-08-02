import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelText = '취소',
  String confirmText = '확인',
  bool isDanger = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(
          title,
          style: AppTextStyles.titleLarge,
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDanger
                  ? AppColors.danger
                  : AppColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );

  return result ?? false;
}