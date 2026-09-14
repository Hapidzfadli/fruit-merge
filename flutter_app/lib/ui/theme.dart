import 'package:flutter/material.dart';

/// Port of the CSS custom properties from style.css:1-15.
class AppColors {
  static const coral = Color(0xFFFF6B4A);
  static const coralLight = Color(0xFFFF8B6B);
  static const coralDark = Color(0xFFD6482B);
  static const cream = Color(0xFFFFF6EA);
  static const peach = Color(0xFFFFD9C2);
  static const mint = Color(0xFFC9F2E1);
  static const pink = Color(0xFFFFB6C8);
  static const sunny = Color(0xFFFFC845);
  static const bg = Color(0xFFF7F3EC);
  static const text = Color(0xFF5B4636);
  static const muted = Color(0xFF8A7360);
  static const label = Color(0xFFA58F79);
  static const line = Color(0x0F000000);
}

/// Port of .screen-gradient (style.css:82).
const kScreenGradient = LinearGradient(
  begin: Alignment(-0.3, -1),
  end: Alignment(0.3, 1),
  colors: [Color(0xFFFFE9D9), Color(0xFFFFF6EA), Color(0xFFD9F5E7)],
  stops: [0, 0.45, 1],
);

/// Port of .btn-primary (style.css:86-99).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double fontSize;
  final EdgeInsets padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.coralLight, AppColors.coral],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: AppColors.coralDark, offset: const Offset(0, 5)),
              BoxShadow(color: AppColors.coral.withValues(alpha: 0.3), offset: const Offset(0, 8), blurRadius: 14),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: fontSize, letterSpacing: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Port of .btn-secondary (style.css:101-113).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double fontSize;
  final EdgeInsets padding;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFFFD3C4), width: 2),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: Color(0xFFF0DDD1), offset: Offset(0, 3))],
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: fontSize)),
        ),
      ),
    );
  }
}

/// Port of .switch (style.css:151-176).
class ToggleSwitch extends StatelessWidget {
  final bool value;
  final VoidCallback onToggle;

  const ToggleSwitch({super.key, required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value ? const Color(0xFFFF9F1C) : const Color(0xFFE5DED2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}
