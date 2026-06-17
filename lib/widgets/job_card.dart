import 'package:flutter/material.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final int? matchScore;

  const JobCard({super.key, required this.job, required this.onTap, this.matchScore});

  Color get _scoreColor {
    final score = matchScore ?? 0;
    if (score >= 75) return AppColors.pine;
    if (score >= 50) return AppColors.ember;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pineLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_center_outlined,
                    color: AppColors.pine, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.company,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.pine,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.stone),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            job.location,
                            style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 12, color: AppColors.stone),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (matchScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$matchScore%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor,
                    ),
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: AppColors.stone),
            ],
          ),
        ),
      ),
    );
  }
}