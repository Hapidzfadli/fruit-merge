import 'package:flutter/material.dart';
import '../ui/theme.dart';

/// Port of backButton() (app.js:113-118). Shared between Settings & Shop headers.
class AppBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const AppBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(width: 38, height: 38, child: Icon(Icons.chevron_left_rounded, color: AppColors.text)),
      ),
    );
  }
}
