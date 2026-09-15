import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

class NewGameContinueButton extends StatelessWidget {
  const NewGameContinueButton({
    required this.isFriend,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final bool isFriend;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = isFriend ? 'OYUN OLUŞTUR' : 'EŞLEŞMEYE KATIL';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.52,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF159447), Color(0xFF087737), Color(0xFF075D2E)],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.brandGreen.withValues(alpha: 0.27),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled && !isLoading ? onPressed : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    isFriend ? Icons.play_arrow_rounded : Icons.bolt_rounded,
                    color: const Color(0xFFFFD667),
                    size: 22,
                  ),
                const SizedBox(width: 9),
                Text(
                  isLoading ? 'OLUŞTURULUYOR...' : label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
