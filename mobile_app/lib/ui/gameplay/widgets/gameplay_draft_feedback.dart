import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

class GameplayDraftFeedback extends StatelessWidget {
  const GameplayDraftFeedback({
    required this.isValid,
    required this.message,
    super.key,
  });

  final bool isValid;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!isValid) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Center(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 11.5,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    final parts = message.split('•');
    final title = parts.first.trim();
    final score = parts.length > 1 ? parts.sublist(1).join('•').trim() : '';

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    color: Color(0xFF302B2B),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (score.isNotEmpty)
                  TextSpan(
                    text: '  $score',
                    style: const TextStyle(
                      color: AppColors.brandGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
