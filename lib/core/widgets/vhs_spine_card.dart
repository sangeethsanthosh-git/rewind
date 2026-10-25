import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class VhsSpineCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color tabColor;
  final String? dateBadge;
  final VoidCallback onTap;
  final Widget? trailing;

  const VhsSpineCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tabColor,
    this.dateBadge,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF19191E), // Dark plastic VHS cassette edge
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E2E38), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.parchment, // Paper sticker label
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCCC5B8), width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tabColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cassetteHeader.copyWith(
                            color: AppColors.textOnCream,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF55555C),
                                fontSize: 12,
                              ),
                            ),
                            if (dateBadge != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•  $dateBadge',
                                style: AppTypography.monoSmall.copyWith(
                                  color: const Color(0xFF777780),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
