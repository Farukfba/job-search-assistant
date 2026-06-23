import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final int? matchScore;

  const JobCard({super.key, required this.job, required this.onTap, this.matchScore});

  Color get _scoreColor {
    final s = matchScore ?? 0;
    if (s >= 75) return AppColors.pine;
    if (s >= 50) return AppColors.ember;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: TextStyle(fontFamily: sans, fontSize: 14.5,
                          fontWeight: FontWeight.w600, color: AppColors.ink),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${job.company} · ${job.location}',
                      style: TextStyle(fontFamily: sans, fontSize: 12.5, color: AppColors.stone),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (matchScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$matchScore%',
                    style: TextStyle(fontFamily: sans, fontSize: 12,
                        fontWeight: FontWeight.w700, color: _scoreColor)),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.stone, size: 20),
          ],
        ),
      ),
    );
  }
}