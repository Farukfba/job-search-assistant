// MatchScoreRing is no longer used in the redesigned Job Detail screen.
// The score is now displayed as a large Fraunces numeral in the
// dark-pine hero header. This file is kept to avoid breaking any
// imports, but the widget is effectively retired.
import 'package:flutter/material.dart';

class MatchScoreRing extends StatelessWidget {
  final int score;
  const MatchScoreRing({super.key, required this.score});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}