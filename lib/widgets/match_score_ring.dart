import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MatchScoreRing extends StatelessWidget {
  final int score;

  const MatchScoreRing({super.key, required this.score});

  Color get _color {
    if (score >= 75) return AppColors.pine;
    if (score >= 50) return AppColors.ember;
    return AppColors.danger;
  }

  String get _label {
    if (score >= 85) return 'Excellent match';
    if (score >= 70) return 'Strong match';
    if (score >= 50) return 'Worth a look';
    return 'Limited match';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 9,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.sand),
                ),
              ),
              SizedBox(
                width: 132,
                height: 132,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'percent match',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.stone),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ),
      ],
    );
  }
}