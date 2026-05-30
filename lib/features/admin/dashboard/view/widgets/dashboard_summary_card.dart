import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class DashboardSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.detail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.detail,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail!,
                        style: const TextStyle(
                          color: AppColors.detail,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.detail,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
