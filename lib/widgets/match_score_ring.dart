import 'package:flutter/material.dart';

class MatchScoreRing extends StatelessWidget {
  final int score;

  const MatchScoreRing({super.key, required this.score});

  Color get _color {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          Text(
            '$score%',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _color),
          ),
        ],
      ),
    );
  }
}